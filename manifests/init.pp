class mconotify (
  $mco_clientcfg = '/var/opt/lib/pe-puppet/.mcollective',
  $mco_timeout = 5,
  $mco_debug = 'false',
  $mco_delimiter = '--',
  $mco_classdelimiter = '__',
  $configfromtemplate = 'false',
){

  $template = str2bool($configfromtemplate)

  file { "${::puppet_confdir}/mconotify.yaml":
    ensure  => present,
    source  => $template ? {
                 false => "puppet:///modules/${module_name}/mconotify.yaml",
                 true  => undef
               },
    content => $template ? {
                 false => undef,
                 true  => template('mconotify/mconotify.yaml.erb')
               },
    owner   => '0',
    group   => '0',
    mode    => '0644',
  }
  file { $mco_clientcfg:
    ensure  => file,
    content => template('mconotify/client.cfg.erb'),
    mode    => '0600',
    owner   => 'pe-puppet',
    group   => 'pe-puppet',
  }

  file { '/etc/puppetlabs/mconotify':
    ensure => directory,
  }
  file { '/etc/puppetlabs/mconotify/peadmin-private.pem':
    ensure => file,
    source => '/etc/puppetlabs/puppet/ssl/private_keys/pe-internal-peadmin-mcollective-client.pem',
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
  file { '/etc/puppetlabs/mconotify/peadmin-public.pem':
    ensure => file,
    source => '/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-peadmin-mcollective-client.pem',
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
  file { '/etc/puppetlabs/mconotify/mcollective-public.pem':
    ensure => file,
    source => '/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-mcollective-servers.pem',
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
  file { '/etc/puppetlabs/mconotify/peadmin-cacert.pem':
    ensure => file,
    source => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
  file { '/etc/puppetlabs/mconotify/peadmin-cert.pem':
    ensure => file,
    source => '/etc/puppetlabs/puppet/ssl/certs/pe-internal-peadmin-mcollective-client.pem',
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
}
