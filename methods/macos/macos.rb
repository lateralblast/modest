# Common OS X routines

# Check IP forwarding is enabled

def check_osx_ip_forwarding(options, gw_if_name)
  message = "Information:\tChecking IP forwarding is enabled"
  command = "sudo sh -c \"sysctl -a net.inet.ip.forwarding |awk '{print $2}'\""
  if options['verbose'] == true
    handle_output(options, message)
    handle_output(options, "Executing:\t"+command)
  end
  output = %x[#{command}]
  output = output.chomp.to_i
  if output == 0
    message = "Information:\tEnabling IP forwarding"
    command = "sudo sh -c \"sysctl net.inet.ip.forwarding=1\""
    execute_command(options, message, command)
  end
  message = "Information:\tChecking rule for IP forwarding has been created"
  if options['host-os-unamer'].split(/\./)[0].to_i > 13
    command = "sudo sh -c \"pfctl -a '*' -sr 2>&1\""
  else
    command = "sudo sh -c \"ipfw list |grep 'any to any via #{gw_if_name}'\""
  end
  if options['verbose'] == true
    handle_output(options, message)
    handle_output(options, "Executing:\t"+command)
  end
  output = %x[#{command}]
  return output
end

# Check PF is configure on OS X 10.10 and later

def check_osx_pfctl(options, gw_if_name, if_name)
  if options['vmnetwork'].to_s.match(/hostonly/)
    pf_file = options['workdir']+"/pfctl_config"
    if File.exist?(pf_file)
      File.delete(pf_file)
    end
    output = File.open(pf_file, "w")
    if options['verbose'] == true
      handle_output(options, "Information:\tEnabling forwarding between #{gw_if_name} and #{if_name}")
    end
    output.write("nat on #{gw_if_name} from #{if_name}:network to any -> (#{gw_if_name})\n")
    output.write("pass inet proto icmp all\n")
    output.write("pass in on #{if_name} proto udp from any to any port domain keep state\n")
    output.write("pass in on #{if_name} proto tcp from any to any port domain keep state\n")
    output.write("pass quick on #{gw_if_name} proto udp from any to any port domain keep state\n")
    output.write("pass quick on #{gw_if_name} proto tcp from any to any port domain keep state\n")
    output.close
    message = "Enabling:\tPacket filtering"
    command = "sudo sh -c \"pfctl -e\""
    execute_command(options, message, command)
    message = "Loading:\yFilters from "+pf_file
    command = "sudo sh -c \"pfctl -F all -f #{pf_file}\""
    execute_command(options, message, command)
  end
  return
end

# check NATd is running and configured on OS X 10.9 and earlier
# Useful info on pfctl here http://patrik-en.blogspot.com.au/2009/10/nat-in-virtualbox-with-freebsd-and-pf.html

def check_osx_nat(options, gw_if_name, if_name)
  output = check_osx_ip_forwarding(gw_if_name)
  if not output.match(/#{gw_if_name}/)
    message = "Information:\tEnabling NATd to forward traffic on "+gw_if_name
    if options['host-os-unamer'].split(".")[0].to_i < 14
      command = "sudo sh -c \"ipfw add 100 divert natd ip from any to any via #{gw_if_name}\""
      execute_command(options, message, command)
    else
      check_osx_pfctl(options, gw_if_name, if_name)
    end
  end
  if options['host-os-unamer'].split(/\./)[0].to_i < 13
    message = "Information:\tChecking NATd is running"
    command = "ps -ef |grep '#{gw_if_name}' |grep natd |grep 'same_ports'"
    output  = execute_command(options, message, command)
    if not output.match(/natd/)
      message = "Information:\tStarting NATd to foward packets between "+if_name+" and "+gw_if_name
      command = "sudo sh -c \"/usr/sbin/natd -interface #{gw_if_name} -use_sockets -same_ports -unregistered_only -dynamic -clamp_mss -enable_natportmap -natportmap_interface #{if_name}\""
      execute_command(options, message, command)
    end
  end
  return
end

# Tune OS X NFS

def tune_osx_nfs(options)
  nfs_file   = "/etc/nfs.conf"
  nfs_params = ['nfs.server.nfsd_threads = 64","nfs.server.reqcache_size = 1024","nfs.server.tcp = 1","nfs.server.udp = 0","nfs.server.fsevents = 0']
  nfs_params.each do |nfs_tune|
    nfs_tune = "nfs.client.nfsiod_thread_max = 64"
    message  = "Information:\tChecking NFS tuning"
    command  = "cat #{nfs_file} |grep '#{nfs_tune}'"
    output   = execute_command(options, message, command)
    if not output.match(/#{nfs_tune}/)
      backup_file(options, nfs_file)
      message = "Information:\tTuning NFS"
      command = "echo '#{nfs_tune}' >> #{nfs_file}"
      execute_command(options, message, command)
    end
  end
  return
end

# Get Mac disk name

def get_osx_disk_name(options)
  message = "Information:\tGetting root disk device ID"
  command = "df |grep '/$' |awk '{print \\$1}'"
  output  = execute_command(options, message, command)
  disk_id = output.chomp
  message = "Information:\tGetting volume name for "+disk_id
  command = "diskutil info #{disk_id} | grep 'Volume Name' |cut -f2 -d':'"
  output  = execute_command(options, message, command)
  volume  = output.chomp.gsub(/^\s+/, "")
  return volume
end

# Check OS X apache config

def check_osx_apache(options)
  ssl_dir = "/private/etc/apache2/ssl"
  check_dir_exists(options, ssl_dir)
  server_key = ssl_dir+"/server.key"
  if not File.exist?(server_key)
    message = "information:\tGenerating Apache SSL Server Key "+server_key
    command = "ssh-keygen -f #{server_key}"
    execute_command(options, message, command)
  end
  return
end

# Check OS X IPS

def check_osx_ips(options)
  python_bin = "/usr/bin/python"
  pip_bin    = "/usr/bin/pip"
  setup_url  = "https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py"
  if not File.symlink?(pip_bin)
    message = "Information:\tInstalling Pip"
    command = "/usr/bin/easy_install --prefix=/usr pip"
    execute_command(options, message, command)
    message = "Information:\tUpdating Setuptools"
    command = "wget #{setup_url} -O |sudo #{python_bin}"
    execute_command(options, message, command)
    ['simplejson", "coverage", "pyOpenSSL", "mercurial'].each do |module_name|
      message = "information:\tInstalling Python module "+module_name
      command = "#{pip_bin} install #{module_name}"
      execute_command(options, message, command)
    end
  end
  python_ver = %x[#{python_bin} --version |awk '{print $2}']
  python_ver = python_ver.chomp.split(/\./)[0..1].join(".")
  module_dir = "/usr/local/lin/python"+python_ver+"/site-packages"
  pkg_dest_dir = module_dir+"/pkg"
  check_dir_exists(options, pkg_dest_dir)
  hg_bin = "/usr/local/bin/hg"
  if not File.exist?(hg_bin)
    message = "Information:\tInstalling Mercurial"
    command = "brew install mercurial"
    execute_command(options, message, command)
  end
  pkgrepo_bin = "/usr/local/bin/pkgrepo"
  if not File.exist?(pkgrepo_bin)
    ips_url = "https://hg.java.net/hg/ips~pkg-gate"
    message = "Information:\tDownloading IPS source code"
    command = "cd #{options['workdir']} ; hg clone #{ips_url} ips"
    execute_command(options, message, command)
  end
  return
end

# Check OSX service is enabled

def check_osx_service_is_enabled(options, service)
  plist_file  = "/Library/LaunchDaemons/"+service+".plist"
  if not File.exist?(plist_file)
    plist_file = "/System"+plist_file
  end
  if not File.exist?(plist_file)
    handle_output(options, "Warning:\tLaunch Agent not found for #{service}")
    quit(options)
  end
  tmp_file = "/tmp/tmp.plist"
  message  = "Information:\tChecking service "+service+" is enabled"
  if service.match(/dhcp/)
    command = "cat #{plist_file} | grep Disabled |grep true"
  else
    command = "cat #{plist_file} | grep -C1 Disabled |grep true"
  end
  output = execute_command(options, message, command)
  if not output.match(/true/)
    if options['verbose'] == true
      handle_output(options, "Information:\t#{service} enabled")
    end
  else
    backup_file(options, plist_file)
    copy      = []
    check     = false
    file_info = IO.readlines(plist_file)
    file_info.each do |line|
      if line.match(/Disabled/)
        check = true
      end
      if line.match(/Label/)
        check = false
      end
      if check == true and line.match(/true/)
        copy.push(line.gsub(/true/, "false"))
      else
        copy.push(line)
      end
    end
    File.open(tmp_file, "w") {|file| file.puts copy}
    message = "Information:\tEnabling "+service
    command = "cp #{tmp_file} #{plist_file} ; rm #{tmp_file}"
    execute_command(options, message, command)
    message = "Information:\tLoading "+service+" profile"
    command = "launchctl load -w #{plist_file}"
    execute_command(options, message, command)
  end
  return
end

# Check TFTPd enabled on OS X

def check_osx_tftpd()
  service = "tftp"
  check_osx_service_is_enabled(service)
  return
end

# Check OS X brew package

def check_brew_pkg(options, pkg_name)
  message = "Information:\tChecking Brew package "+pkg_name
  command = "brew info #{pkg_name}"
  output  = execute_command(options, message, command)
  return output
end

# Install software package

def install_osx_package(options, pkg_name)
  install_brew_pkg(options, pkg_name)
  return
end

# Install package with brew

def install_brew_pkg(options, pkg_name)
  pkg_status = check_brew_pkg(options, pkg_name)
  if pkg_status.match(/Not installed/)
    message = "Information:\tInstalling Package "+pkg_name
    command = "brew install #{pkg_name}"
    execute_command(options, message, command)
  end
  return
end

# Check OS X dnsmasq (used for puppet)

def check_osx_dnsmasq(options)
  pkg_name = "dnsmasq"
  install_brew_pkg(pkg_name)
  plist_file   = "/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist"
  dnsmasq_file = "/usr/local/etc/dnsmasq.conf"
  if not File.exist?(plist_file)
    message = "Information:\tCreating Plist file "+plist_file+" for "+pkg_name
    command = "cp -fv /usr/local/opt/dnsmasq/*.plist /Library/LaunchDaemons"
    execute_command(options, message, command)
    message = "Information:\tCreating Configuration file "+plist_file
    command = "cp #{dnsmasq_file}.example #{dnsmasq_file}"
    execute_command(options, message, command)
    message = "Information:\tLoading Configuration for "+pkg_name
    command = "launchctl load -w #{plist_file}"
    execute_command(options, message, command)
  end
  return
end

# Check OSC DHCP installation on OS X

def check_osx_dhcpd_installed(options)
  brew_file   = "/usr/local/Library/Formula/isc-dhcp.rb"
  backup_file = brew_file+".orig"
  dhcpd_bin   = "/usr/local/sbin/dhcpd"
  if not File.symlink?(dhcpd_bin)
    pkg_name = "bind"
    install_brew_pkg(pkg_name)
    message  = "Information:\tUpdating Brew sources list"
    command  = "brew update"
    execute_command(options, message, command)
    message  = "Information:\tChecking OS X Version"
    command  = "sw_vers |grep ProductVersion |awk '{print $2}'"
    output   = execute_command(options, message, command)
    if output.match(/10\.9/)
      if File.exist?(brew_file)
        message = "Information:\tChecking version of ISC DHCPd"
        command = "cat #{brew_file} | grep url"
        output  = execute_command(options, message, command)
        if output.match(/4\.2\.5\-P1/)
          message = "Information:\tArchiving Brew file "+brew_file+" to "+backup_file
          command = "cp #{brew_file} #{backup_file}"
          execute_command(options, message, command)
          message = "Information:\tFixing Brew configuration file "+brew_file
          command = "cat #{backup_file} | grep -v sha1 | sed 's/4\.2\.5\-P1/4\.3\.0rc1/g' > #{brew_file}"
          execute_command(options, message, command)
        end
        pkg_name = "isc-dhcp"
        install_brew_pkg(pkg_name)
      end
        message = "Information:\tCreating Launchd service for ISC DHCPd"
        command = "cp -fv /usr/local/opt/isc-dhcp/*.plist /Library/LaunchDaemons"
        execute_command(options, message, command)
    end
    if not File.exist?(options['dhcpdfile'])
      message = "Information:\tCreating DHCPd configuration file "+options['dhcpdfile']
      command = "touch #{options['dhcpdfile']}"
      execute_command(options, message, command)
    end
  end
  return
end

# Build DHCP plist file

def create_osx_dhcpd_plist(options)
  xml_output = []
  tmp_file   = "/tmp/plist.xml"
  plist_name = "homebrew.mxcl.isc-dhcp"
  plist_file = "/Library/LaunchDaemons/homebrew.mxcl.isc-dhcp.plist"
  dhcpd_bin  = "/usr/local/sbin/dhcpd"
  if File.exist?(plist_file)
    message = "Information:\tChecking DHCPd configruation"
    command = "cat #{plist_file} | grep '#{options['nic']}'"
    output  = execute_command(options, message, command)
  else
    output = "Information:\tCreating #{plist_file}"
    handle_output(options, output)
  end
  if not output.match(/#{options['nic']}/)
    xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
    xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    xml.declare! :DOCTYPE, :plist, :PUBLIC, :'"-//Apple Computer//DTD PLIST 1.0//EN"', :'"http://www.apple.com/DTDs/PropertyList-1.0.dtd"'
    xml.plist(:version => "1.0") {
      xml.dict {
        xml.key("label")
        xml.string(plist_name)
        xml.key("ProgramArguments")
        xml.array {
          xml.string(dhcpd_bin)
          xml.string(options['nic'])
          xml.string("-4")
          xml.string("-f")
        }
      }
      xml.key("Disabled") ; xml.false
      xml.key("KeepAlive") ; xml.true
      xml.key("RunAtLoad") ; xml.true
      xml.key("LowPriorityID") ; xml.true
    }
    file=File.open(tmp_file, "w")
    xml_output.each do |item|
      file.write(item)
    end
    file.close
    message = "Information:\tCreating service file "+plist_file
    command = "cp #{tmp_file} #{plist_file} ; rm #{tmp_file}"
    execute_command(options, message, command)
  end
  return
end

# Check ISC DHCP installed on OS X

def check_osx_dhcpd(options)
  check_osx_dhcpd_installed()
  create_osx_dhcpd_plist()
  service = "dhcp"
  check_osx_service_is_enabled(service)
  return
end

# Enable OS X service

def refresh_osx_service(service_name)
  if not service_name.match(/\./)
    if service_name.match(/dhcp/)
      service_name = "homebrew.mxcl.isc-"+service_name
    else
      service_name= "com.apple."+service_name+"d"
    end
  end
  disable_osx_service(service_name)
  enable_osx_service(service_name)
  return
end

# Enable OS X service

def enable_osx_service(service_name)
  check_osx_service_is_enabled(service_name)
  message = "Information:\tEnabling service "+service_name
  command = "launchctl start #{service_name}"
  output  = execute_command(options, message, command)
  return output
end

# Enable OS X service

def disable_osx_service(service_name)
  message = "Information:\tDisabling service "+service_name
  command = "launchctl stop #{service_name}"
  output  = execute_command(options, message, command)
  return output
end
