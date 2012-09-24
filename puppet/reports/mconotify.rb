require 'puppet'
require 'yaml'
require 'mcollective'

Puppet::Reports.register_report(:mconotify) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "mconotify.yaml"])
  raise(Puppet::ParseError, "mcoreport config file #{configfile} not available") unless File.exist?(configfile)
  CONFIG= YAML.load_file(configfile) 
  raise(Puppet::ParseError, "mcoreport config file #{configfile} not available") unless CONFIG

  MCO_CONFIG = CONFIG[:mcoconfig] || '/etc/puppetlabs/mcollective/client.cfg'
  MCO_TIMEOUT = CONFIG[:mcotimeout] || 5
#  MCO_CLASSES = CONFIG[:classes]
#  MCO_NODES = CONFIG[:nodes] 
  MCO_DEBUG = CONFIG[:debug] || false
  MCO_COLLETIVE = CONFIG[:collective] || false

#  if ! MCO_CLASSES and ! MCO_NODES
#    raise(Puppet::ParseError, "mconotify: Either no classes or no nodes to notify on specified")
#  end

  desc <<-DESC
Orchestrate puppet runs via mcollective on changed resources in classes, or on particular nodes
DESC

  def process
    notifystuff = []
    a=File.open("/tmp/#{self.host}#{Time.now.to_i}",'w') if MCO_DEBUG
    a.write "MCONOTIFY CONFIG:\n\n#{CONFIG.inspect}\n\n" # if MCO_DEBUG
    a.flush if MCO_DEBUG

    if self.status == 'changed' 
      begin
        self.resource_statuses.each do |theresource,somestuff|
          matching_tags=somestuff.tags.grep(/mconotify/) 
          notifystuff << matching_tags unless matching_tags.empty?
          a.write "#{notifystuff}\n" if MCO_DEBUG
          a.flush if MCO_DEBUG
        end
        a.write "End of tag matching\n" if MCO_DEBUG
      rescue => cow
        a.write "couldn't output resource statuses #{cow}" if MCO_DEBUG
        a.flush if MCO_DEBUG
      end
      a.flush

      factfilter=[]
      nodefilter=[]
      classfilter=[]

      notifystuff.each do |filter|
        a.write "#{filter}\n"  if MCO_DEBUG
        a.flush  if MCO_DEBUG
        if filter.to_s =~ /:node:/
          a.write "matched #{filter} to a node\n"  if MCO_DEBUG
          nodefilter << "/#{filter.split(':')[2]}/"  if MCO_DEBUG
        end
        if filter.to_s =~ /:class:/
          a.write "matched #{filter} to a class\n"  if MCO_DEBUG
          classfilter << "/#{filter.split(':')[2]}/"  if MCO_DEBUG
        end
      end

      a.write "Filters: node #{nodefilter.count} class #{classfilter.count}\n"  if MCO_DEBUG
      a.flush

      if nodefilter.count > 0 or classfilter.count > 0
        a.write "doing an mco run for #{nodefilter} and #{classfilter}\n"  if MCO_DEBUG
        svcs = MCollective::RPC::Client.new("puppetd", :configfile => MCO_CONFIG, :options => {:verbose=>false, :progress_bar=>false , :timeout=> MCO_TIMEOUT, :mcollective_limit_targets=>false, :config=> MCO_CONFIG, :filter=>{"cf_class"=>classfilter.flatten, "agent"=>["puppetd"], "identity"=>nodefilter.flatten, "fact"=>factfilter}, :collective=>nil, :disctimeout=>2} )

        svcs.runonce(:forcerun=> true)
        svcs.disconnect
      end
    end
  end
end
