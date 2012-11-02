mconotify - orchestrating your systems autodynamagically using a Puppet report processor

This report processor uses tags on Puppet resource/class definitions to send mcollective RPC messages to nodes or classes of nodes to trigger configuration updates for dependent resource sets.

Consider this resource definition:

    file { '/tmp/testfile':
      ensure => file,
      tag  => ['mconotify--class--theclass','mconotify--node--ibroketheinternet.co.uk'],
      source => '/etc/passwd',
    }

When processing the agent report on the Puppet master, the mconotify report code will examine the tags on each resource in the report.  If the report has the status 'changed' and a resource that is appropriately tagged in the report (i.e. with 'mconotify--something--somethingelse') has also changed, then a mco client with appropriate filters will be built and a message sent to the collective.

You can set up debug and other stuff on the master by tuning 
    "#{puppet_confdir}/mconotify.yaml": 
 
    ---
    :mcoconfig: /tmp/client.cfg
    :mcotimeout: 5
    :debug: true
    :delimiter: --

:mcoconfig - this variable should point at a mcollective config file to be loaded by the report processor with appropriate message queue credentials, collective information and mcollective security provider configuration (default: /etc/puppetlabs/mcollective/client.cfg)
:mcoconfig - this variable determines how long the mcollective client app in the report processor should wait before timing out (default: 5)
:debug - this variable determines whether the puppet master will output debug to it's logs (default: false)
Prerequisites:
:collective - this variable determines which collective will be addressed (default: nil)
:delimiter - this variable customises the delimiter used when splitting the tag(default: '--')

* An mcollective
* An mcollective client.cfg for the user running Puppet to use to build the config
* Some resources, classes and nodes
