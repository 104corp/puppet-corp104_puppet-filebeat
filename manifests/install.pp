# corp104_filebeat::install
#
# A private class to manage the installation of Filebeat
#
# @summary A private class that manages the install of Filebeat
class corp104_filebeat::install {
  anchor { 'corp104_filebeat::install::begin': }

  case $::kernel {
    'Linux':   {
      class{ '::corp104_filebeat::install::linux':
        notify => Class['corp104_filebeat::service'],
      }
      Anchor['corp104_filebeat::install::begin'] -> Class['corp104_filebeat::install::linux'] -> Anchor['corp104_filebeat::install::end']
      if $::corp104_filebeat::manage_repo {
        class { '::corp104_filebeat::repo': }
        Class['corp104_filebeat::repo'] -> Class['corp104_filebeat::install::linux']
      }
    }
    'FreeBSD': {
      class{ '::corp104_filebeat::install::freebsd':
        notify => Class['corp104_filebeat::service'],
      }
      Anchor['corp104_filebeat::install::begin'] -> Class['corp104_filebeat::install::freebsd'] -> Anchor['corp104_filebeat::install::end']
    }
    'OpenBSD': {
      class{'corp104_filebeat::install::openbsd':}
      Anchor['corp104_filebeat::install::begin'] -> Class['corp104_filebeat::install::openbsd'] -> Anchor['corp104_filebeat::install::end']
    }
    'Windows': {
      class{'::corp104_filebeat::install::windows':
        notify => Class['corp104_filebeat::service'],
      }
      Anchor['corp104_filebeat::install::begin'] -> Class['corp104_filebeat::install::windows'] -> Anchor['corp104_filebeat::install::end']
    }
    default:   {
      fail($corp104_filebeat::kernel_fail_message)
    }
  }

  anchor { 'corp104_filebeat::install::end': }

}
