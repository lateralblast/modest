# frozen_string_literal: true

# Common OS X routines

# Check IP forwarding is enabled

def check_osx_ip_forwarding(values, gw_if_name)
  message = "Information:\tChecking IP forwarding is enabled"
  command = "sudo sh -c \"sysctl -a net.inet.ip.forwarding |awk '{print $2}'\""
  verbose_message(values, message)
  execute_message(values, command)
  output = `#{command}`
  output = output.chomp.to_i
  if output.zero?
    message = "Information:\tEnabling IP forwarding"
    command = 'sudo sh -c "sysctl net.inet.ip.forwarding=1"'
    execute_command(values, message, command)
  end
  message = "Information:\tChecking rule for IP forwarding has been created"
  command = if values['host-os-unamer'].split(/\./)[0].to_i > 13
              "sudo sh -c \"pfctl -a '*' -sr 2>&1\""
            else
              "sudo sh -c \"ipfw list |grep 'any to any via #{gw_if_name}'\""
            end
  verbose_message(values, message)
  execute_message(values, command)
  `#{command}`
end

# Check PF is configure on OS X 10.10 and later

def check_osx_pfctl(values, gw_if_name, if_name)
  if values['vmnetwork'].to_s.match(/hostonly/) && (values['dryrun'] == false) && (values['checknat'] == true)
    pf_file = "#{values['workdir']}/pfctl_config"
    File.delete(pf_file) if File.exist?(pf_file)
    output = File.open(pf_file, 'w')
    information_message(values, "Enabling forwarding between #{gw_if_name} and #{if_name}")
    output.write("nat on #{gw_if_name} from #{if_name}:network to any -> (#{gw_if_name})\n")
    output.write("pass inet proto icmp all\n")
    output.write("pass in on #{if_name} proto udp from any to any port domain keep state\n")
    output.write("pass in on #{if_name} proto tcp from any to any port domain keep state\n")
    output.write("pass quick on #{gw_if_name} proto udp from any to any port domain keep state\n")
    output.write("pass quick on #{gw_if_name} proto tcp from any to any port domain keep state\n")
    output.close
    message = "Enabling:\tPacket filtering"
    command = 'sudo sh -c "pfctl -e"'
    execute_command(values, message, command)
    message = "Loading:\tFilters from #{pf_file}"
    command = "sudo sh -c \"pfctl -F all -f #{pf_file}\""
    execute_command(values, message, command)
  end
  nil
end

# check NATd is running and configured on OS X 10.9 and earlier
# Useful info on pfctl here http://patrik-en.blogspot.com.au/2009/10/nat-in-virtualbox-with-freebsd-and-pf.html

def check_osx_nat(values, gw_if_name, if_name)
  output = check_osx_ip_forwarding(gw_if_name)
  unless output.match(/#{gw_if_name}/)
    message = "Information:\tEnabling NATd to forward traffic on #{gw_if_name}"
    if values['host-os-unamer'].split('.')[0].to_i < 14
      command = "sudo sh -c \"ipfw add 100 divert natd ip from any to any via #{gw_if_name}\""
      execute_command(values, message, command)
    else
      check_osx_pfctl(values, gw_if_name, if_name)
    end
  end
  if values['host-os-unamer'].split(/\./)[0].to_i < 13
    message = "Information:\tChecking NATd is running"
    command = "ps -ef |grep '#{gw_if_name}' |grep natd |grep 'same_ports'"
    output  = execute_command(values, message, command)
    unless output.match(/natd/)
      message = "Information:\tStarting NATd to foward packets between #{if_name} and #{gw_if_name}"
      command = "sudo sh -c \"/usr/sbin/natd -interface #{gw_if_name} -use_sockets -same_ports -unregistered_only -dynamic -clamp_mss -enable_natportmap -natportmap_interface #{if_name}\""
      execute_command(values, message, command)
    end
  end
  nil
end

# Tune OS X NFS

def tune_osx_nfs(values)
  nfs_file   = '/etc/nfs.conf'
  nfs_params = ['nfs.server.nfsd_threads = 64","nfs.server.reqcache_size = 1024","nfs.server.tcp = 1","nfs.server.udp = 0","nfs.server.fsevents = 0']
  nfs_params.each do |nfs_tune|
    nfs_tune = 'nfs.client.nfsiod_thread_max = 64'
    message  = "Information:\tChecking NFS tuning"
    command  = "cat #{nfs_file} |grep '#{nfs_tune}'"
    output   = execute_command(values, message, command)
    next if output.match(/#{nfs_tune}/)

    backup_file(values, nfs_file)
    message = "Information:\tTuning NFS"
    command = "echo '#{nfs_tune}' >> #{nfs_file}"
    execute_command(values, message, command)
  end
  nil
end

# Get Mac disk name

def get_osx_disk_name(values)
  message = "Information:\tGetting root disk device ID"
  command = "df |grep '/$' |awk '{print \\$1}'"
  output  = execute_command(values, message, command)
  disk_id = output.chomp
  message = "Information:\tGetting volume name for #{disk_id}"
  command = "diskutil info #{disk_id} | grep 'Volume Name' |cut -f2 -d':'"
  output  = execute_command(values, message, command)
  output.chomp.gsub(/^\s+/, '')
end

# Check OS X apache config

def check_osx_apache(values)
  ssl_dir = '/private/etc/apache2/ssl'
  check_dir_exists(values, ssl_dir)
  server_key = "#{ssl_dir}/server.key"
  unless File.exist?(server_key)
    message = "information:\tGenerating Apache SSL Server Key #{server_key}"
    command = "ssh-keygen -f #{server_key}"
    execute_command(values, message, command)
  end
  nil
end

# Check OS X IPS

def check_osx_ips(values)
  python_bin = '/usr/bin/python'
  pip_bin    = '/usr/bin/pip'
  setup_url  = 'https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py'
  unless File.symlink?(pip_bin)
    message = "Information:\tInstalling Pip"
    command = '/usr/bin/easy_install --prefix=/usr pip'
    execute_command(values, message, command)
    message = "Information:\tUpdating Setuptools"
    command = "wget #{setup_url} -O |sudo #{python_bin}"
    execute_command(values, message, command)
    ['simplejson", "coverage", "pyOpenSSL", "mercurial'].each do |module_name|
      message = "information:\tInstalling Python module #{module_name}"
      command = "#{pip_bin} install #{module_name}"
      execute_command(values, message, command)
    end
  end
  python_ver = `#{python_bin} --version |awk '{print $2}'`
  python_ver = python_ver.chomp.split(/\./)[0..1].join('.')
  module_dir = "/usr/local/lin/python#{python_ver}/site-packages"
  pkg_dest_dir = "#{module_dir}/pkg"
  check_dir_exists(values, pkg_dest_dir)
  hg_bin = '/usr/local/bin/hg'
  unless File.exist?(hg_bin)
    message = "Information:\tInstalling Mercurial"
    command = 'brew install mercurial'
    execute_command(values, message, command)
  end
  pkgrepo_bin = '/usr/local/bin/pkgrepo'
  unless File.exist?(pkgrepo_bin)
    ips_url = 'https://hg.java.net/hg/ips~pkg-gate'
    message = "Information:\tDownloading IPS source code"
    command = "cd #{values['workdir']} ; hg clone #{ips_url} ips"
    execute_command(values, message, command)
  end
  nil
end

# Check OSX service is enabled

def check_osx_service_is_enabled(values, service)
  plist_file = "/Library/LaunchDaemons/#{service}.plist"
  plist_file = "/System#{plist_file}" unless File.exist?(plist_file)
  unless File.exist?(plist_file)
    warning_message(values, "Launch Agent not found for #{service}")
    quit(values)
  end
  tmp_file = '/tmp/tmp.plist'
  message  = "Information:\tChecking service #{service} is enabled"
  command = if service.match(/dhcp/)
              "cat #{plist_file} | grep Disabled |grep true"
            else
              "cat #{plist_file} | grep -C1 Disabled |grep true"
            end
  output = execute_command(values, message, command)
  if !output.match(/true/)
    information_message(values, "#{service} enabled")
  else
    backup_file(values, plist_file)
    copy      = []
    check     = false
    file_info = IO.readlines(plist_file)
    file_info.each do |line|
      check = true if line.match(/Disabled/)
      check = false if line.match(/Label/)
      if (check == true) && line.match(/true/)
        copy.push(line.gsub(/true/, 'false'))
      else
        copy.push(line)
      end
    end
    File.open(tmp_file, 'w') { |file| file.puts copy }
    message = "Information:\tEnabling #{service}"
    command = "cp #{tmp_file} #{plist_file} ; rm #{tmp_file}"
    execute_command(values, message, command)
    message = "Information:\tLoading #{service} profile"
    command = "launchctl load -w #{plist_file}"
    execute_command(values, message, command)
  end
  nil
end

# Check TFTPd enabled on OS X

def check_osx_tftpd(values)
  service = 'tftp'
  check_osx_service_is_enabled(values, service)
  nil
end

# Check OS X brew package

def check_brew_pkg(values, pkg_name)
  message = "Information:\tChecking Brew package #{pkg_name}"
  command = "brew info #{pkg_name}"
  execute_command(values, message, command)
end

# Install software package

def install_osx_package(values, pkg_name)
  install_brew_pkg(values, pkg_name)
  nil
end

# Install package with brew

def install_brew_pkg(values, pkg_name)
  pkg_status = check_brew_pkg(values, pkg_name)
  if pkg_status.match(/Not installed/)
    message = "Information:\tInstalling Package #{pkg_name}"
    command = "brew install #{pkg_name}"
    execute_command(values, message, command)
  end
  nil
end

# Check OS X dnsmasq (used for puppet)

def check_osx_dnsmasq(values)
  pkg_name = 'dnsmasq'
  install_brew_pkg(pkg_name)
  plist_file   = '/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist'
  dnsmasq_file = '/usr/local/etc/dnsmasq.conf'
  unless File.exist?(plist_file)
    message = "Information:\tCreating Plist file #{plist_file} for #{pkg_name}"
    command = 'cp -fv /usr/local/opt/dnsmasq/*.plist /Library/LaunchDaemons'
    execute_command(values, message, command)
    message = "Information:\tCreating Configuration file #{plist_file}"
    command = "cp #{dnsmasq_file}.example #{dnsmasq_file}"
    execute_command(values, message, command)
    message = "Information:\tLoading Configuration for #{pkg_name}"
    command = "launchctl load -w #{plist_file}"
    execute_command(values, message, command)
  end
  nil
end

# Check OSC DHCP installation on OS X

def check_osx_dhcpd_installed(values)
  brew_file   = '/usr/local/Library/Formula/isc-dhcp.rb'
  backup_file = "#{brew_file}.orig"
  dhcpd_bin   = '/usr/local/sbin/dhcpd'
  unless File.symlink?(dhcpd_bin)
    pkg_name = 'bind'
    install_brew_pkg(pkg_name)
    message  = "Information:\tUpdating Brew sources list"
    command  = 'brew update'
    execute_command(values, message, command)
    message  = "Information:\tChecking OS X Version"
    command  = "sw_vers |grep ProductVersion |awk '{print $2}'"
    output   = execute_command(values, message, command)
    if output.match(/10\.9/)
      if File.exist?(brew_file)
        message = "Information:\tChecking version of ISC DHCPd"
        command = "cat #{brew_file} | grep url"
        output  = execute_command(values, message, command)
        if output.match(/4\.2\.5-P1/)
          message = "Information:\tArchiving Brew file #{brew_file} to #{backup_file}"
          command = "cp #{brew_file} #{backup_file}"
          execute_command(values, message, command)
          message = "Information:\tFixing Brew configuration file #{brew_file}"
          command = "cat #{backup_file} | grep -v sha1 | sed 's/4\.2\.5\-P1/4\.3\.0rc1/g' > #{brew_file}"
          execute_command(values, message, command)
        end
        pkg_name = 'isc-dhcp'
        install_brew_pkg(pkg_name)
      end
      message = "Information:\tCreating Launchd service for ISC DHCPd"
      command = 'cp -fv /usr/local/opt/isc-dhcp/*.plist /Library/LaunchDaemons'
      execute_command(values, message, command)
    end
    unless File.exist?(values['dhcpdfile'])
      message = "Information:\tCreating DHCPd configuration file #{values['dhcpdfile']}"
      command = "touch #{values['dhcpdfile']}"
      execute_command(values, message, command)
    end
  end
  nil
end

# Build DHCP plist file

def create_osx_dhcpd_plist(values)
  xml_output = []
  tmp_file   = '/tmp/plist.xml'
  plist_name = 'homebrew.mxcl.isc-dhcp'
  plist_file = '/Library/LaunchDaemons/homebrew.mxcl.isc-dhcp.plist'
  dhcpd_bin  = '/usr/local/sbin/dhcpd'
  if File.exist?(plist_file)
    message = "Information:\tChecking DHCPd configruation"
    command = "cat #{plist_file} | grep '#{values['nic']}'"
    output  = execute_command(values, message, command)
  else
    output = "Information:\tCreating #{plist_file}"
    verbose_message(values, output)
  end
  unless output.match(/#{values['nic']}/)
    xml = Builder::XmlMarkup.new(target: xml_output, indent: 2)
    xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
    xml.declare! :DOCTYPE, :plist, :PUBLIC, :'"-//Apple Computer//DTD PLIST 1.0//EN"', :'"http://www.apple.com/DTDs/PropertyList-1.0.dtd"'
    xml.plist(version: '1.0') do
      xml.dict do
        xml.key('label')
        xml.string(plist_name)
        xml.key('ProgramArguments')
        xml.array do
          xml.string(dhcpd_bin)
          xml.string(values['nic'])
          xml.string('-4')
          xml.string('-f')
        end
      end
      xml.key('Disabled')
      xml.false
      xml.key('KeepAlive')
      xml.true
      xml.key('RunAtLoad')
      xml.true
      xml.key('LowPriorityID')
      xml.true
    end
    file = File.open(tmp_file, 'w')
    xml_output.each do |item|
      file.write(item)
    end
    file.close
    message = "Information:\tCreating service file #{plist_file}"
    command = "cp #{tmp_file} #{plist_file} ; rm #{tmp_file}"
    execute_command(values, message, command)
  end
  nil
end

# Check ISC DHCP installed on OS X

def check_osx_dhcpd(values)
  check_osx_dhcpd_installed(values)
  create_osx_dhcpd_plist(values)
  service = 'dhcp'
  check_osx_service_is_enabled(values, service)
  nil
end

# Enable OS X service

def refresh_osx_service(service_name)
  unless service_name.match(/\./)
    service_name = if service_name.match(/dhcp/)
                     "homebrew.mxcl.isc-#{service_name}"
                   else
                     "com.apple.#{service_name}d"
                   end
  end
  disable_osx_service(service_name)
  enable_osx_service(service_name)
  nil
end

# Enable OS X service

def enable_osx_service(service_name)
  check_osx_service_is_enabled(values, service_name)
  message = "Information:\tEnabling service #{service_name}"
  command = "launchctl start #{service_name}"
  execute_command(values, message, command)
end

# Enable OS X service

def disable_osx_service(service_name)
  message = "Information:\tDisabling service #{service_name}"
  command = "launchctl stop #{service_name}"
  execute_command(values, message, command)
end
