require 'facter'
Facter.add('filebeat_ver') do
  confine 'kernel' => ['FreeBSD', 'OpenBSD', 'Linux', 'Windows']
  if File.executable?('/usr/bin/filebeat')
    filebeat_ver = Facter::Util::Resolution.exec('/usr/bin/filebeat version')
    if filebeat_ver.empty?
      filebeat_ver = Facter::Util::Resolution.exec('/usr/bin/filebeat --version')
    end
  elsif File.executable?('/usr/local/bin/filebeat')
    filebeat_ver = Facter::Util::Resolution.exec('/usr/local/bin/filebeat version')
    if filebeat_ver.empty?
      filebeat_ver = Facter::Util::Resolution.exec('/usr/local/bin/filebeat --version')
    end
  elsif File.executable?('/usr/share/filebeat/bin/filebeat')
    filebeat_ver = Facter::Util::Resolution.exec('/usr/share/filebeat/bin/filebeat --version')
  elsif File.executable?('/usr/local/sbin/filebeat')
    filebeat_ver = Facter::Util::Resolution.exec('/usr/local/sbin/filebeat --version')
  elsif File.exist?('c:\Program Files\Filebeat\filebeat.exe')
    filebeat_ver = Facter::Util::Resolution.exec('"c:\Program Files\Filebeat\filebeat.exe" version')
    if filebeat_ver.empty?
      filebeat_ver = Facter::Util::Resolution.exec('"c:\Program Files\Filebeat\filebeat.exe" --version')
    end
  end
  setcode do
    filebeat_ver.nil? ? false : %r{^filebeat version ([^\s]+)?}.match(filebeat_ver)[1]
  end
end
