mconotify - orchestrating your systems autodynamagically using a Puppet report processor

This report processor uses tags on Puppet resource/class definitions to send mcollective RPC messages to nodes or classes of nodes to trigger configuration updates for dependent resource sets.  When a resource is appropriately tagged (using mconotify--(class|node)--class/nodename), the report processor will send the equivalent of an `mco puppet runonce -I thenode` or `mco puppet runonce -C theclass` (it uses the ruby classes to do this, rather than shelling out of course).

Consider this resource definition:

    file { '/tmp/testfile':
      ensure => file,
      tag  => ['mconotify--class--theclass__fooclass','mconotify--node--ibroketheinternet.co.uk'],
      source => '/etc/passwd',
    }

When processing the agent report on the Puppet master, the mconotify report code will examine the tags on each resource in the report.  If the report has the status 'changed' and a resource that is appropriately tagged in the report (i.e. with 'mconotify--something--somethingelse') has also changed, then a mco client with appropriate filters will be built and a message sent to the collective.

The mconotify class will do most of the set up for you on a PE master by copying the peadmin user certs, but you still need to push a public key out for the application.  Something like:

    file { '/etc/puppetlabs/mcollective/ssl/clients/mconotify-public.pem':
      ensure  => file,
      require => File['/etc/puppetlabs/mcollective/ssl/clients/peadmin-public.pem'],
      source  => '/etc/puppetlabs/mcollective/ssl/clients/peadmin-public.pem',
    }

You should probably set up a proper unique key pair for it, but this is a hack to get it up and running quickly.

You can set up debug and other stuff on the master by tuning 
    "#{puppet_confdir}/mconotify.yaml": 
 
    ---
    :mcoconfig: /var/opt/lib/pe-puppet/.mcollective
    :mcotimeout: 5
    :debug: true
    :delimiter: --
    :classdelimiter: __

mconotify.yaml Variables
* :mcoconfig - this variable should point at a mcollective config file to be loaded by the report processor with appropriate message queue credentials, collective information and mcollective security provider configuration (default: /etc/puppetlabs/mcollective/client.cfg)
* :mcoconfig - this variable determines how long the mcollective client app in the report processor should wait before timing out (default: 5)
* :debug - this variable determines whether the puppet master will output debug to it's logs (default: false)
Prerequisites:
* :collective - this variable determines which collective will be addressed (default: nil)
* :delimiter - this variable customises the delimiter used when splitting the tag(default: '--')
* :classdelimiter - this variable customises the delimiter used when splitting class namespaces (no default)

Pre-requisites: 

* An mcollective
* An mcollective client.cfg for the user running Puppet to use to build the config
* Some resources, classes and nodes


Changelog:

    0.3.0: Adding class delimiter, and better Puppet code to set the thing up
    0.1.1: Update README.md for clarity
    0.1.0: Updated to accomodate mcollective 2.x puppet agent
