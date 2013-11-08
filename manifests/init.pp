class mconotify (
  $mco_clientcfg = '/var/opt/lib/pe-puppet/.mcollective',
  $mco_vardir = '/etc/puppetlabs/mconotify',
  $mco_timeout = 5,
  $mco_debug = 'false',
  $mco_delimiter = '--',
  $mco_classdelimiter = '__',
  $configfromtemplate = 'false',
  $private_key = '/etc/puppetlabs/puppet/ssl/private_keys/pe-internal-peadmin-mcollective-client.pem',
  $public_key = '/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-peadmin-mcollective-client.pem',
  $mco_public_key = '/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-mcollective-servers.pem',
  $cert = '/etc/puppetlabs/puppet/ssl/certs/pe-internal-peadmin-mcollective-client.pem',
  $cacert = '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
) {

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

  file { $mco_vardir:
    ensure => directory,
  }
  file { "${mco_vardir}/mconotify-private.pem":
    ensure => file,
    source => $mconotify::private_key,
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
  file { "${mco_vardir}/mconotify-public.pem":
    ensure => file,
    source => $mconotify::public_key,
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
  file { "${mco_vardir}/mcollective-public.pem":
    ensure => file,
    source => $mconotify::mco_public_key,
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
  file { "${mco_vardir}/mconotify-cacert.pem":
    ensure => file,
    source => $mconotify::cacert,
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
  file { "${mco_vardir}/mconotify-cert.pem":
    ensure => file,
    source => $mconotify::cert,
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0600',
  }
}
