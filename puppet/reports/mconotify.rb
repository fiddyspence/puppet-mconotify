require 'puppet'
require 'yaml'
require 'mcollective'

Puppet::Reports.register_report(:mconotify) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "mconotify.yaml"])
  raise(Puppet::ParseError, "mcoreport config file #{configfile} not available") unless File.exist?(configfile)
  config = YAML.load_file(configfile) 

  MCO_CONFIG = config[:mcoconfig] || '/etc/puppetlabs/mcollective/client.cfg'
  MCO_TIMEOUT = config[:mcotimeout] || 5
  MCO_CLASSES = config[:classes]
  MCO_NODES = config[:nodes] 
  MCO_DEBUG = config[:debug] || false

  if ! MCO_CLASSES and ! MCO_NODES
    raise(Puppet::ParseError, "mconotify: Either no classes or no nodes to notify on specified")
  end

  desc <<-DESC
Orchestrate puppet runs via mcollective on changed resources in classes, or on particular nodes
DESC

  def process
    a=File.open("/tmp/#{self.host}#{Time.now.to_i}",'w') if MCO_DEBUG
    a.write "MCONOTIFY CONFIG:\n\n#{config}\n" if MCO_DEBUG
    a.write self.resource_statuses if MCO_DEBUG
    if self.status == 'changed' 
      svcs = MCollective::RPC::Client.new("puppetd", :configfile => MCO_CONFIG, :options => {:verbose=>false, :progress_bar=>false , :timeout=> MCO_TIMEOUT, :mcollective_limit_targets=>false, :config=> MCO_CONFIG, :filter=>{"cf_class"=>[], "agent"=>["puppetd"], "identity"=>[], "fact"=>[]}, :collective=>nil, :disctimeout=>2} )
      svcs.progress = false
      svcs.runonce(:forcerun=> "true")
      svcs.disconnect
      a.write self.resource_statuses if MCO_DEBUG
    end
  end
end
