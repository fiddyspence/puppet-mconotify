require 'mcollective'
require 'puppetdb/connection'
Puppet::Reports.register_report(:mconotify) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "mconotify.yaml"])
  raise(Puppet::ParseError, "mcoreport config file #{configfile} not available") unless File.exist?(configfile)
  CONFIG=YAML.load_file(configfile) 
  raise(Puppet::ParseError, "mcoreport config file #{configfile} not available") unless CONFIG

  MCO_CONFIG = CONFIG[:mcoconfig] || '/etc/puppetlabs/mcollective/client.cfg'
  MCO_TIMEOUT = CONFIG[:mcotimeout] || 5
  MCO_DEBUG = CONFIG[:debug] || false
  MCO_COLLECTIVE = CONFIG[:collective] || 'mcollective'
  MCO_DELIMITER = CONFIG[:delimiter] || "--"
  MCO_CLASSDELIMITER = CONFIG[:classdelimiter]

  desc <<-DESC
Orchestrate puppet runs via mcollective on changed resources in classes, or on particular nodes
DESC

  def process
    notifystuff = []
    Puppet.notice "MCONOTIFY #{self.name}: CONFIG:#{CONFIG.inspect}" if MCO_DEBUG
    options = MCollective::Util.default_options
    options[:agent] = 'puppet'
    options[:config] = MCO_CONFIG
    options[:verbose] = false
    options[:progress_bar] = false
    options[:process_results] = false
    options[:mcollective_limit_targets] = false
    options[:disctimeout] = 2
    options[:timeout] = MCO_TIMEOUT
    options[:collective] = MCO_COLLECTIVE

    if self.status == 'changed' 
      begin
        self.resource_statuses.each do |theresource,resource_status|
          matching_tags=resource_status.tags.grep(/mconotify/) 
         if resource_status.changed and ! resource_status.failed and ! resource_status.skipped and ! matching_tags.empty?
            matching_tags.each do |tag|
              unless notifystuff.member?(tag)
                notifystuff << tag unless notifystuff.member?(tag)
                Puppet.notice "MCONOTIFY #{self.name}: Added mconotify tag #{matching_tags.join(',')}" if MCO_DEBUG
              end
            end
          end
        end
        Puppet.notice "MCONOTIFY #{self.name}: End of tag matching" if MCO_DEBUG
      rescue => cow
        Puppet.notice "MCONOTIFY #{self.name}: couldn't output resource statuses #{cow}" if MCO_DEBUG
      end

      factfilter=[]
      nodefilter=[]
      classfilter=[]

      notifystuff.each do |filter|
       if filter.to_s =~ /#{MCO_DELIMITER}node#{MCO_DELIMITER}/
          Puppet.notice "MCONOTIFY #{self.name}: matched #{filter} to a node" if MCO_DEBUG
          nodefilter << "#{filter.to_s.split(MCO_DELIMITER)[2]}"
        end
       if filter.to_s =~  /#{MCO_DELIMITER}class#{MCO_DELIMITER}/
          Puppet.notice "MCONOTIFY #{self.name}: matched #{filter} to a class" if MCO_DEBUG
          if MCO_CLASSDELIMITER 
            thisfilter = "#{filter.to_s.split(MCO_DELIMITER)[2].gsub(MCO_CLASSDELIMITER,'::')}"
          else
            thisfilter = "#{filter.to_s.split(MCO_DELIMITER)[2]}"
          end
          classfilter << thisfilter
          
        end
      end

      Puppet.notice "MCONOTIFY #{self.name}: Filters: node #{nodefilter.count} class #{classfilter.count}" if MCO_DEBUG

      if nodefilter.count > 0

        Puppet.notice "MCONOTIFY #{self.name}: Doing an mco run for #{nodefilter.join(',')}" if MCO_DEBUG
        thefilter="/#{nodefilter.join('|')}/"
        Puppet.notice "MCONOTIFY #{self.name}: #{thefilter}"
        if MCollective.version.to_i == 1
         svcs = MCollective::RPC::Client.new("puppetd", :configfile => MCO_CONFIG, :options => {:verbose=>false, :progress_bar=>false , :timeout=> MCO_TIMEOUT, :mcollective_limit_targets=>false, :config=> MCO_CONFIG, :filter=>{"cf_class"=>[], "agent"=>["puppetd"], "identity"=>thefilter, "fact"=>factfilter}, :collective=>MCO_COLLECTIVE, :disctimeout=>2} )
          svcs.runonce(:forcerun=> true, :process_results => false)
        else
          Puppet.notice "MCONOTIFY #{self.name}: Mcollective version #{MCollective.version}"

          nodefilter.each do |thenode|
            Puppet.notice "MCONOTIFY #{self.name}: running for #{thenode}" if MCO_DEBUG
            Puppet.notice "MCONOTIFY #{self.name}: #{options.inspect}" if MCO_DEBUG
            begin
              svcs = MCollective::RPC::Client.new("puppet", :options => options)
            rescue => e
              Puppet.notice "MCONOTIFY #{self.name}: went wrong on client creation #{e.message}" if MCO_DEBUG
            end
            svcs.identity_filter thenode
            svcs.runonce(:force=> true, :process_results => false)
            svcs = nil
          end

        end

# updating with ':process_results => false' per RIP
      end
      if classfilter.count > 0

        Puppet.notice "MCONOTIFY #{self.name}: Doing an mco run for #{classfilter}" if MCO_DEBUG
        thefilter="/#{classfilter.join('|')}/"

        if MCollective.version.to_i == 1
          Puppet.notice "MCONOTIFY #{self.name}: Doing mco1" if MCO_DEBUG
          svcs = MCollective::RPC::Client.new("puppetd", :configfile => MCO_CONFIG, :options => {:verbose=>false, :progress_bar=>false , :timeout=> MCO_TIMEOUT, :mcollective_limit_targets=>false, :config=> MCO_CONFIG, :filter=>{"cf_class"=>[thefilter], "agent"=>["puppetd"], "identity"=>[], "fact"=>factfilter}, :collective=>MCO_COLLECTIVE, :disctimeout=>2} )
          svcs.runonce(:forcerun=> true, :process_results => false)
        else
          Puppet.notice "MCONOTIFY #{self.name}: Doing mco2" if MCO_DEBUG
          classfilter.each do |theclass|
            Puppet.notice "MCONOTIFY #{self.name}: Triggering #{theclass}" if MCO_DEBUG
            begin
              svcs = MCollective::RPC::Client.new("puppet", :options => options)
            rescue => e
              Puppet.notice "MCONOTIFY #{self.name}: went wrong on client creation #{e.message}" if MCO_DEBUG
            end
            svcs.class_filter theclass
            svcs.runonce(:force=> true, :process_results => false)
            svcs = nil
          end
        end
      end
    end
  end
end
