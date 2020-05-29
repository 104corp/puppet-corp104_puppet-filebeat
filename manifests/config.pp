# corp104_filebeat::config
#
# Manage the configuration files for filebeat
#
# @summary A private class to manage the filebeat config file
class corp104_filebeat::config {
  $major_version = $corp104_filebeat::major_version

  if has_key($corp104_filebeat::setup, 'ilm.policy') {
    file {"${corp104_filebeat::config_dir}/ilm_policy.json":
      content => to_json({'policy' => $corp104_filebeat::setup['ilm.policy']}),
      notify  => Service['filebeat'],
      require => File['filebeat-config-dir'],
    }
    $setup = $corp104_filebeat::setup - 'ilm.policy' + {'ilm.policy_file' => "${corp104_filebeat::config_dir}/ilm_policy.json"}
  } else {
    $setup = $corp104_filebeat::setup
  }

  if versioncmp($major_version, '6') >= 0 {
    $filebeat_config_temp = delete_undef_values({
      'shutdown_timeout'  => $corp104_filebeat::shutdown_timeout,
      'name'              => $corp104_filebeat::beat_name,
      'tags'              => $corp104_filebeat::tags,
      'max_procs'         => $corp104_filebeat::max_procs,
      'fields'            => $corp104_filebeat::fields,
      'fields_under_root' => $corp104_filebeat::fields_under_root,
      'filebeat'          => {
        'config.inputs' => {
          'enabled' => true,
          'path'    => "${corp104_filebeat::config_dir}/*.yml",
        },
        'config.modules' => {
          'enabled' => $corp104_filebeat::enable_conf_modules,
          'path'    => "${corp104_filebeat::modules_dir}/*.yml",
        },
        'shutdown_timeout'   => $corp104_filebeat::shutdown_timeout,
        'modules'           => $corp104_filebeat::modules,
      },
      'http'              => $corp104_filebeat::http,
      'output'            => $corp104_filebeat::outputs,
      'shipper'           => $corp104_filebeat::shipper,
      'logging'           => $corp104_filebeat::logging,
      'runoptions'        => $corp104_filebeat::run_options,
      'processors'        => $corp104_filebeat::processors,
      'monitoring'        => $corp104_filebeat::monitoring,
      'setup'             => $setup,
    })
    # Add the 'xpack' section if supported (version >= 6.1.0) and not undef
    if $corp104_filebeat::xpack and versioncmp($corp104_filebeat::package_ensure, '6.1.0') >= 0 {
      $filebeat_config = deep_merge($filebeat_config_temp, {'xpack' => $corp104_filebeat::xpack})
    }
    else {
      $filebeat_config = $filebeat_config_temp
    }
  } else {
    $filebeat_config_temp = delete_undef_values({
      'shutdown_timeout'  => $corp104_filebeat::shutdown_timeout,
      'name'              => $corp104_filebeat::beat_name,
      'tags'              => $corp104_filebeat::tags,
      'queue_size'        => $corp104_filebeat::queue_size,
      'max_procs'         => $corp104_filebeat::max_procs,
      'fields'            => $corp104_filebeat::fields,
      'fields_under_root' => $corp104_filebeat::fields_under_root,
      'filebeat'          => {
        'spool_size'       => $corp104_filebeat::spool_size,
        'idle_timeout'     => $corp104_filebeat::idle_timeout,
        'registry_file'    => $corp104_filebeat::registry_file,
        'publish_async'    => $corp104_filebeat::publish_async,
        'config_dir'       => $corp104_filebeat::config_dir,
        'shutdown_timeout' => $corp104_filebeat::shutdown_timeout,
      },
      'output'            => $corp104_filebeat::outputs,
      'shipper'           => $corp104_filebeat::shipper,
      'logging'           => $corp104_filebeat::logging,
      'runoptions'        => $corp104_filebeat::run_options,
      'processors'        => $corp104_filebeat::processors,
    })
    # Add the 'modules' section if supported (version >= 5.2.0)
    if versioncmp($corp104_filebeat::package_ensure, '5.2.0') >= 0 {
      $filebeat_config = deep_merge($filebeat_config_temp, {'modules' => $corp104_filebeat::modules})
    }
    else {
      $filebeat_config = $filebeat_config_temp
    }
  }

  if 'filebeat_ver' in $facts and $facts['filebeat_ver'] != false {
    $skip_validation = versioncmp($facts['filebeat_ver'], $corp104_filebeat::major_version) ? {
      -1      => true,
      default => false,
    }
  } else {
    $skip_validation = false
  }

  case $::kernel {
    'Linux'   : {
      $validate_cmd = ($corp104_filebeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => $major_version ? {
          '5'     => "${corp104_filebeat::filebeat_path} -N -configtest -c %",
          default => "${corp104_filebeat::filebeat_path} -c % test config",
        },
      }

      file {'filebeat.yml':
        ensure       => $corp104_filebeat::file_ensure,
        path         => $corp104_filebeat::config_file,
        content      => template($corp104_filebeat::conf_template),
        owner        => $corp104_filebeat::config_file_owner,
        group        => $corp104_filebeat::config_file_group,
        mode         => $corp104_filebeat::config_file_mode,
        validate_cmd => $validate_cmd,
        notify       => Service['filebeat'],
        require      => File['filebeat-config-dir'],
      }

      file {'filebeat-config-dir':
        ensure  => $corp104_filebeat::directory_ensure,
        path    => $corp104_filebeat::config_dir,
        owner   => $corp104_filebeat::config_dir_owner,
        group   => $corp104_filebeat::config_dir_group,
        mode    => $corp104_filebeat::config_dir_mode,
        recurse => $corp104_filebeat::purge_conf_dir,
        purge   => $corp104_filebeat::purge_conf_dir,
        force   => true,
      }
    } # end Linux

    'FreeBSD'   : {
      $validate_cmd = ($corp104_filebeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => '/usr/local/sbin/filebeat -N -configtest -c %',
      }

      file {'filebeat.yml':
        ensure       => $corp104_filebeat::file_ensure,
        path         => $corp104_filebeat::config_file,
        content      => template($corp104_filebeat::conf_template),
        owner        => $corp104_filebeat::config_file_owner,
        group        => $corp104_filebeat::config_file_group,
        mode         => $corp104_filebeat::config_file_mode,
        validate_cmd => $validate_cmd,
        notify       => Service['filebeat'],
        require      => File['filebeat-config-dir'],
      }

      file {'filebeat-config-dir':
        ensure  => $corp104_filebeat::directory_ensure,
        path    => $corp104_filebeat::config_dir,
        owner   => $corp104_filebeat::config_dir_owner,
        group   => $corp104_filebeat::config_dir_group,
        mode    => $corp104_filebeat::config_dir_mode,
        recurse => $corp104_filebeat::purge_conf_dir,
        purge   => $corp104_filebeat::purge_conf_dir,
        force   => true,
      }
    } # end FreeBSD

    'OpenBSD'   : {
      $validate_cmd = ($corp104_filebeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => $major_version ? {
          '5'     => "${corp104_filebeat::filebeat_path} -N -configtest -c %",
          default => "${corp104_filebeat::filebeat_path} -c % test config",
        },
      }

      file {'filebeat.yml':
        ensure       => $corp104_filebeat::file_ensure,
        path         => $corp104_filebeat::config_file,
        content      => template($corp104_filebeat::conf_template),
        owner        => $corp104_filebeat::config_file_owner,
        group        => $corp104_filebeat::config_file_group,
        mode         => $corp104_filebeat::config_file_mode,
        validate_cmd => $validate_cmd,
        notify       => Service['filebeat'],
        require      => File['filebeat-config-dir'],
      }

      file {'filebeat-config-dir':
        ensure  => $corp104_filebeat::directory_ensure,
        path    => $corp104_filebeat::config_dir,
        owner   => $corp104_filebeat::config_dir_owner,
        group   => $corp104_filebeat::config_dir_group,
        mode    => $corp104_filebeat::config_dir_mode,
        recurse => $corp104_filebeat::purge_conf_dir,
        purge   => $corp104_filebeat::purge_conf_dir,
        force   => true,
      }
    } # end OpenBSD

    'Windows' : {
      $cmd_install_dir = regsubst($corp104_filebeat::install_dir, '/', '\\', 'G')
      $filebeat_path = join([$cmd_install_dir, 'Filebeat', 'filebeat.exe'], '\\')

      $validate_cmd = ($corp104_filebeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => $major_version ? {
          '7'     => "\"${filebeat_path}\" test config -c \"%\"",
          default => "\"${filebeat_path}\" -N -configtest -c \"%\"",
        }
      }

      file {'filebeat.yml':
        ensure       => $corp104_filebeat::file_ensure,
        path         => $corp104_filebeat::config_file,
        content      => template($corp104_filebeat::conf_template),
        validate_cmd => $validate_cmd,
        notify       => Service['filebeat'],
        require      => File['filebeat-config-dir'],
      }

      file {'filebeat-config-dir':
        ensure  => $corp104_filebeat::directory_ensure,
        path    => $corp104_filebeat::config_dir,
        recurse => $corp104_filebeat::purge_conf_dir,
        purge   => $corp104_filebeat::purge_conf_dir,
        force   => true,
      }
    } # end Windows

    default : {
      fail($corp104_filebeat::kernel_fail_message)
    }
  }
}
