# corp104_filebeat::input
#
# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   corp104_filebeat::input { 'namevar': }
define corp104_filebeat::input (
  Enum['absent', 'present'] $ensure        = present,
  Array[String] $paths                     = [],
  Array[String] $exclude_files             = [],
  Array[String] $containers_ids            = ['\'*\''],
  String $containers_path                  = '/var/lib/docker/containers',
  String $containers_stream                = 'all',
  Boolean $combine_partial                 = false,
  Enum['tcp', 'udp'] $syslog_protocol      = 'udp',
  String $syslog_host                      = 'localhost:5140',
  Boolean $cri_parse_flags                 = false,
  String $encoding                         = 'plain',
  String $input_type                       = 'log',
  Hash $fields                             = {},
  Boolean $fields_under_root               = $corp104_filebeat::fields_under_root,
  Optional[String] $ignore_older           = undef,
  Optional[String] $close_older            = undef,
  String $doc_type                         = 'log',
  String $scan_frequency                   = '10s',
  Integer $harvester_buffer_size           = 16384,
  Optional[Integer] $harvester_limit       = undef,
  Boolean $tail_files                      = false,
  String $backoff                          = '1s',
  String $max_backoff                      = '10s',
  Integer $backoff_factor                  = 2,
  String $close_inactive                   = '5m',
  Boolean $close_renamed                   = false,
  Boolean $close_removed                   = true,
  Boolean $close_eof                       = false,
  Variant[String, Integer] $clean_inactive = 0,
  Boolean $clean_removed                   = true,
  Integer $close_timeout                   = 0,
  Boolean $force_close_files               = false,
  Array[String] $include_lines             = [],
  Array[String] $exclude_lines             = [],
  String $max_bytes                        = '10485760',
  Hash $multiline                          = {},
  Hash $json                               = {},
  Array[String] $tags                      = [],
  Boolean $symlinks                        = false,
  Optional[String] $pipeline               = undef,
  Array $processors                        = [],
  Boolean $pure_array                      = false,
) {

  $input_template = $corp104_filebeat::major_version ? {
    '5'     => 'prospector.yml.erb',
    default => 'input.yml.erb',
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
    'Linux', 'OpenBSD' : {
      $validate_cmd = ($corp104_filebeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => $corp104_filebeat::major_version ? {
          '5'     => "\"${corp104_filebeat::filebeat_path}\" -N -configtest -c \"%\"",
          default => "\"${corp104_filebeat::filebeat_path}\" -c \"${corp104_filebeat::config_file}\" test config",
        },
      }
      file { "filebeat-${name}":
        ensure       => $ensure,
        path         => "${corp104_filebeat::config_dir}/${name}.yml",
        owner        => 'root',
        group        => '0',
        mode         => $::corp104_filebeat::config_file_mode,
        content      => template("${module_name}/${input_template}"),
        validate_cmd => $validate_cmd,
        notify       => Service['filebeat'],
        require      => File['filebeat.yml'],
      }
    }

    'FreeBSD' : {
      $validate_cmd = ($corp104_filebeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => '/usr/local/sbin/filebeat -N -configtest -c %',
      }
      file { "filebeat-${name}":
        ensure       => $ensure,
        path         => "${corp104_filebeat::config_dir}/${name}.yml",
        owner        => 'root',
        group        => 'wheel',
        mode         => $::corp104_filebeat::config_file_mode,
        content      => template("${module_name}/${input_template}"),
        validate_cmd => $validate_cmd,
        notify       => Service['filebeat'],
        require      => File['filebeat.yml'],
      }
    }

    'Windows' : {
      $cmd_install_dir = regsubst($corp104_filebeat::install_dir, '/', '\\', 'G')
      $filebeat_path = join([$cmd_install_dir, 'Filebeat', 'filebeat.exe'], '\\')

      $validate_cmd = ($corp104_filebeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => $facts['filebeat_ver'] ? {
          '5'     => "\"${filebeat_path}\" -N -configtest -c \"%\"",
          default => "\"${filebeat_path}\" -c \"${corp104_filebeat::config_file}\" test config",
        },
      }

      file { "filebeat-${name}":
        ensure       => $ensure,
        path         => "${corp104_filebeat::config_dir}/${name}.yml",
        content      => template("${module_name}/${input_template}"),
        validate_cmd => $validate_cmd,
        notify       => Service['filebeat'],
        require      => File['filebeat.yml'],
      }
    }

    default : {
      fail($corp104_filebeat::kernel_fail_message)
    }

  }
}
