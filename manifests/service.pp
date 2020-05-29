# corp104_filebeat::service
#
# Manage the filebeat service
#
# @summary Manage the filebeat service
class corp104_filebeat::service {
  service { 'filebeat':
    ensure   => $corp104_filebeat::real_service_ensure,
    enable   => $corp104_filebeat::real_service_enable,
    provider => $corp104_filebeat::service_provider,
  }

  $major_version                  = $corp104_filebeat::major_version
  $systemd_beat_log_opts_override = $corp104_filebeat::systemd_beat_log_opts_override

  #make sure puppet client version 6.1+ with filebeat version 7+, running on systemd
  if ( versioncmp( $major_version, '7'   ) >= 0 and
    $::service_provider == 'systemd' ) {

    if ( versioncmp( $::clientversion, '6.1' ) >= 0 ) {

      unless $systemd_beat_log_opts_override == undef {
        $ensure_overide = 'present'
      } else {
        $ensure_overide = 'absent'
      }

      ensure_resource('file',
        $corp104_filebeat::systemd_override_dir,
        {
          ensure => 'directory',
        }
      )

      file { "${corp104_filebeat::systemd_override_dir}/logging.conf":
        ensure  => $ensure_overide,
        content => template($corp104_filebeat::systemd_beat_log_opts_template),
        require => File[$corp104_filebeat::systemd_override_dir],
        notify  => Service['filebeat'],
      }

    } else {

      unless $systemd_beat_log_opts_override == undef {
        $ensure_overide = 'present'
      } else {
        $ensure_overide = 'absent'
      }

      if !defined(File[$corp104_filebeat::systemd_override_dir]) {
        file{$corp104_filebeat::systemd_override_dir:
          ensure => 'directory',
        }
      }

      file { "${corp104_filebeat::systemd_override_dir}/logging.conf":
        ensure  => $ensure_overide,
        content => template($corp104_filebeat::systemd_beat_log_opts_template),
        require => File[$corp104_filebeat::systemd_override_dir],
        notify  => Service['filebeat'],
      }

      unless defined('systemd') {
        warning('You\'ve specified an $systemd_beat_log_opts_override varible on a system running puppet version < 6.1 and not declared "systemd" resource See README.md for more information') # lint:ignore:140chars
      }
    }
  }

}
