# to manage filebeat installation on OpenBSD
class corp104_filebeat::install::openbsd {
  package {'filebeat':
    ensure => $corp104_filebeat::package_ensure,
  }
}
