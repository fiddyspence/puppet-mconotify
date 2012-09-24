require 'puppet'
require 'yaml'
require 'mcollective'

Puppet::Reports.register_report(:mconotify) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "mconotify.yaml"])
  raise(Puppet::ParseError, "mcoreport config file #{configfile} not available") unless File.exist?(configfile)
  CONFIG=YAML.load_file(configfile) 
  raise(Puppet::ParseError, "mcoreport config file #{configfile} not available") unless CONFIG

  MCO_CONFIG = CONFIG[:mcoconfig] || '/etc/puppetlabs/mcollective/client.cfg'
  MCO_TIMEOUT = CONFIG[:mcotimeout] || 5
  MCO_DEBUG = CONFIG[:debug] || false
  MCO_COLLECTIVE = CONFIG[:collective] || nil

  desc <<-DESC
Orchestrate puppet runs via mcollective on changed resources in classes, or on particular nodes
DESC

  def process
    notifystuff = []
    Puppet.notice "MCONOTIFY: CONFIG:\n\n#{CONFIG.inspect}\n\n" if MCO_DEBUG

    if self.status == 'changed' 
      begin
        self.resource_statuses.each do |theresource,resource_status|
          matching_tags=resource_status.tags.grep(/mconotify/) 
          if resource_status.changed and ! resource_status.failed and ! resource_status.skipped and ! matching_tags.empty?
            matching_tags.each do |tag|
              notifystuff << tag unless notifystuff.member?(tag)
            end
            Puppet.notice "MCONOTIFY: Added mconotify tag #{matching_tags.class}"
          end
        end
        Puppet.notice "MCONOTIFY: End of tag matching\n" if MCO_DEBUG
      rescue => cow
        Puppet.notice "MCONOTIFY: couldn't output resource statuses #{cow}" if MCO_DEBUG
      end

      factfilter=[]
      nodefilter=[]
      classfilter=[]

      notifystuff.each do |filter|
        if filter.to_s =~ /:-node:-/
          Puppet.notice "MCONOTIFY: matched #{filter} to a node\n"  if MCO_DEBUG
          nodefilter << "/#{filter.to_s.split(':-')[2]}/"  if MCO_DEBUG
        end
        if filter.to_s =~ /:-class:-/
          Puppet.notice "MCONOTIFY: matched #{filter} to a class\n"  if MCO_DEBUG
          classfilter << "/#{filter.to_s.split(':-')[2]}/"  if MCO_DEBUG
        end
      end

      Puppet.notice "MCONOTIFY: Filters: node #{nodefilter.count} class #{classfilter.count}\n"  if MCO_DEBUG

      if nodefilter.count > 0 or classfilter.count > 0
        Puppet.notice "MCONOTIFY: Doing an mco run for #{nodefilter} and #{classfilter}\n"  if MCO_DEBUG
        svcs = MCollective::RPC::Client.new("puppetd", :configfile => MCO_CONFIG, :options => {:verbose=>false, :progress_bar=>false , :timeout=> MCO_TIMEOUT, :mcollective_limit_targets=>false, :config=> MCO_CONFIG, :filter=>{"cf_class"=>classfilter.flatten, "agent"=>["puppetd"], "identity"=>nodefilter.flatten, "fact"=>factfilter}, :collective=>MCO_COLLECTIVE, :disctimeout=>2} )

        svcs.runonce(:forcerun=> true)
        svcs.disconnect
      end
    end
  end
end
