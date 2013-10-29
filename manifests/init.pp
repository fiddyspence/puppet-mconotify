 mconotify (
  $mco_clientcfg = '/etc/puppetlabs/puppet/client.cfg',
  $mco_clientcfg = 5,
  $mco_debug = 'false',
  $mco_delimiter = '--',
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

}
