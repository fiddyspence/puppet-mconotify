class mconotify {

  file { "${::puppet_confdir}/mconotify.yaml":
    ensure => present,
    source => "puppet:///modules/${module_name}/mconotify.yaml",
    owner  => '0',
    group  => '0',
    mode   => '0644',
  }

}
