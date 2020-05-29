# corp104_filebeat::install::linux
#
# Install the linux filebeat package
#
# @summary A simple class to install the filebeat package
#
class corp104_filebeat::install::linux {
  if $::kernel != 'Linux' {
    fail('corp104_filebeat::install::linux shouldn\'t run on Windows')
  }

  package {'filebeat':
    ensure => $corp104_filebeat::package_ensure,
  }
}
