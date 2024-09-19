
# Code common to all services

# Set SSH port

def set_ssh_port(values)
  case values['type']
  when /packer/
    if values['method'].to_s.match(/vs/)
      values['sshport'] = "22"
    else
      values['sshport'] = "2222"
    end
  end
  return values
end

# Get architecture from model

def get_arch_from_model(values)
  if values['model'].to_s.downcase.match(/^t/)
    values['arch'] = "sun4v"
  else
    values['arch'] = "sun4u"
  end
  return values
end

# Parse memory

def process_memory_value(values)
  memory = values['memory'].to_s
  if not memory.match(/[A-Z]$|[a-z]$/)
    if memory.to_i < 100
      memory = memory+"G"
    else
      memory = memory+"M"
    end
  end
  values['memory'] = memory
  return values
end

# Set hostonly information

def set_hostonly_info(values)
  host_ip        = get_my_ip(values)
  host_subnet    = host_ip.split(".")[2]
  install_subnet = values['ip'].split(".")[2]
  hostonly_base  = "192.168"
  case values['vm']
  when /vmware|vmx|fusion/
    if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 10
      if values['vmnetwork'].to_s.match(/nat/)
        hostonly_subnet = "158"
      else
        if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 11
          hostonly_subnet = "2"
        else
          hostonly_subnet = "104"
        end
      end
    else
      hostonly_subnet = "52"
    end
  when /parallels/
    hostonly_base  = "10.211"
    if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 10
      hostonly_subnet = "55"
    else
      hostonly_subnet = "54"
    end
  when /vbox|virtualbox/
    hostonly_subnet = "56"
  when /kvm/
    hostonly_subnet = "122"
  else
    if not values['vm'] == values['empty']
      hostonly_subnet = "58"
    end
  end
  if hostonly_subnet == host_subnet
    output = "Warning:\tHost and Hostonly network are the same"
    verbose_output(values, output)
    hostonly_subnet = host_subnet.to_i+10
    hostonly_subnet = hostonly_subnet.to_s
    output = "Information:\tChanging hostonly network to "+hostonly_base+"."+hostonly_subnet+".0"
    verbose_output(values, output)
    values['force'] = true
  end
  if install_subnet == host_subnet
    if values['dhcp'] == false
      output = "Warning:\tHost and client network are the same"
      verbose_output(values, output)
      install_subnet = host_subnet.to_i+10
      install_subnet = install_subnet.to_s
      values['ip']  = values['ip'].split(".")[0]+"."+values['ip'].split(".")[1]+"."+install_subnet+"."+values['ip'].split(".")[3]
      output = "Information:\tChanging Client IP to "+hostonly_base+"."+hostonly_subnet+".0"
      verbose_output(values, output)
      values['force'] = true
    end
  end
  values['vmgateway']  = hostonly_base+"."+hostonly_subnet+".1"
  values['hostonlyip'] = hostonly_base+"."+hostonly_subnet+".1"
  values['hostonlyip'] = hostonly_base+"."+hostonly_subnet+".1"
  values['ip']         = hostonly_base+"."+hostonly_subnet+".101"
  values = check_vm_network(values)
  return values
end

# Get my IP - Useful when running in server mode

def get_my_ip(values)
  message = "Information:\tDetermining IP of local machine"
  if !values['host-os-uname'].to_s.match(/[a-z]/)
   values['host-os-uname'] = %x[uname]
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    command = "ipconfig getifaddr en0"
  else
    if values['host-os-uname'].to_s.match(/SunOS/)
      command = "/usr/sbin/ifconfig -a | awk \"BEGIN { count=0; } { if ( \\\$1 ~ /inet/ ) { count++; if( count==2 ) { print \\\$2; } } }\""
    else
      if File.exist?("/usr/bin/ip")
        command = "ip addr |grep 'inet ' |grep -v 127 |head -1 |awk '{print \$2}' |cut -f1 -d/"
      else
        if values['vm'].to_s == "kvm"
          command = "hostname -I |awk \"{print \\\$2}\""
        else
          command = "hostname -I |awk \"{print \\\$1}\""
        end
      end
    end
  end
  output = execute_command(values, message, command)
  output = output.chomp
  output = output.strip
  output = output.gsub(/\s+|\n/, "")
  output = output.strip
  return output
end

# Get the NIC name from the service name - Now trying to use biosdevname=0 everywhere

def get_nic_name_from_install_service(values)
  nic_name = "eth0"
#  case values['service']
#  when /ubuntu_18/
#    if values['vm'].to_s.match(/vbox/)
#      nic_name = "enp0s3"
#    else
#      if values['vm'].to_s.match(/kvm/)
#        nic_name = "ens3"
#      else
#        nic_name = "eth0"
#      end
#    end
#  when /rhel_7|centos_7|ubuntu/
#    nic_name = "enp0s3"
#  end
  return nic_name
end

# Calculate CIDR

def netmask_to_cidr(netmask)
  cidr = Integer(32-Math.log2((IPAddr.new(netmask,Socket::AF_INET).to_i^0xffffffff)+1))
  return cidr
end

# values['cidr'] = netmask_to_cidr(values['netmask'])

# Code to run on quiting

def quit(values)
  if values['output'].to_s.match(/html/)
    values['stdout'].push("</body>")
    values['stdout'].push("</html>")
    puts values['stdout'].join("\n")
  end
  exit
end

# Get valid switches and put in an array

def get_valid_values()
  file_array  = IO.readlines $0
  option_list = file_array.grep(/\['--/)
  return option_list
end

# Handle IP

def single_install_ip(values)
  if values['ip'].to_s.match(/\,/)
    install_ip = values['ip'].to_s.split(/\,/)[0]
  else
    install_ip = values['ip'].to_s
  end
  return install_ip
end

# Print script usage information

def print_help(values)
  values['verbose'] = true
  switches     = []
  long_switch  = ""
  short_switch = ""
  help_info    = ""
  verbose_output(values, "")
  verbose_output(values, "Usage: #{values['script']}")
  verbose_output(values, "")
  option_list = get_valid_values()
  option_list.each do |line|
    if not line.match(/file_array/)
      help_info    = line.split(/# /)[1]
      switches     = line.split(/,/)
      long_switch  = switches[0].gsub(/\[/, "").gsub(/\s+/, "")
      short_switch = switches[1].gsub(/\s+/, "")
      if short_switch.match(/REQ|BOOL/)
        short_switch = ""
      end
      if long_switch.gsub(/\s+/, "").length < 7
        verbose_output(values, "#{long_switch},\t\t\t#{short_switch}\t#{help_info}")
      else
        if long_switch.gsub(/\s+/, "").length < 15
          verbose_output(values, "#{long_switch},\t\t#{short_switch}\t#{help_info}")
        else
          verbose_output(values, "#{long_switch},\t#{short_switch}\t#{help_info}")
        end
      end
    end
  end
  verbose_output(values, "")
  return
end

# Output if verbose flag set

#def verbose_output(values, text)
#  if values['verbose'] == true
#    values = verbose_output(values, text)
#  end
#  return values
#end

# HTML header

def html_header(pipe, title)
  pipe.push("<html>")
  pipe.push("<header>")
  pipe.push("<title>")
  pipe.push(title)
  pipe.push("</title>")
  pipe.push("</header>")
  pipe.push("<body>")
  return pipe
end

# HTML footer

def html_footer(pipe)
  pipe.push("</body>")
  pipe.push("</html>")
  return pipe
end

# Get version

def get_version()
  file_array = IO.readlines $0
  version    = file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/, '').chomp
  packager   = file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/, '').chomp
  name       = file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/, '').chomp
  return version,packager, name
end

# Print script version information

def print_version(values)
  (version, packager, name) = get_version()
  verbose_output(values, "#{name} v. #{version} #{packager}")
  return
end

# Set file perms

def set_file_perms(file_name, file_perms)
  message = "Information:\tSetting permissions on file '#{file_name}' to '#{file_perms}'"
  command = "chmod #{file_perms} \"#{file_name}\""
  execute_command(values, message, command)
  return
end

# Write array to file

def write_array_to_file(values, file_array, file_name, file_mode)
  dir_name = Pathname.new(file_name).dirname
  if !Dir.exist?(dir_name)
    FileUtils.mkpath(dir_name)
  end
  if file_mode.match(/a/)
    file_mode = "a"
  else
    file_mode = "w"
  end
  file = File.open(file_name, file_mode)
  file_array.each do |line|
    if not line.match(/\n/)
      line = line+"\n"
    end
    file.write(line)
  end
  file.close
  print_contents_of_file(values, "", file_name)
  return
end

# Get SSH config

def get_user_ssh_config(values)
  user_ssh_config = ConfigFile.new
  if values['ip'].to_s.match(/[0-9]/)
    host_list = user_ssh_config.search(/#{values['id']}/)
  end
  if values['id'].to_s.match(/[0-9]/)
    host_list = user_ssh_config.search(/#{values['ip']}/)
  end
  if values['name'].to_s.match(/[0-9]|[a-z]/)
    host_list = user_ssh_config.search(/#{values['name']}/)
  end
  if not host_list
    host_list = "none"
  else
    if not host_list.match(/[A-Z]|[a-z]|[0-9]/)
      host_list = "none"
    end
  end
  return host_list
end


# List hosts in SSH config

def list_user_ssh_config(values)
  host_list = get_user_ssh_config(values)
  if not host_list == values['empty']
    verbose_output(host_list)
  end
  return
end

# Update SSH config

def update_user_ssh_config(values)
  host_list   = get_user_ssh_config(values)
  if host_list == values['empty']
    host_string = "Host "
    ssh_config  = values['sshconfig']
    if values['name'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      host_string = host_string+" "+values['name']
    end
    if values['id'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      host_string = host_string+" "+values['id']
    end
    if not File.exist?(ssh_config)
      file = File.open(ssh_config, "w")
    else
      file = File.open(ssh_config, "a")
    end
    file.write(host_string+"\n")
    if values['sshkeyfile'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      file.write("    IdentityFile "+values['sshkeyfile']+"\n")
    end
    if values['adminuser'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      file.write("    User "+values['adminuser']+"\n")
    end
    if values['ip'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      file.write("    HostName "+values['ip']+"\n")
    end
    file.close
  end
  return
end

# Remove SSH config

def delete_user_ssh_config(values)
  host_list   = get_user_ssh_config(values)
  if not host_list == values['empty']
    host_info  = host_list.split(/\n/)[0].chomp
    verbose_output(values, "Warning:\tRemoving entries for '#{host_info}'")
    ssh_config = values['sshconfig']
    ssh_data   = File.readlines(ssh_config)
    new_data   = []
    found_host = 0
    ssh_data.each do |line|
      if line.match(/^Host/)
        if line.match(/#{values['name']}|#{values['id']}|#{values['ip']}/)
          found_host = true
        else
          found_host = 0
        end
      end
      if found_host == false
        new_data.push(line)
      end
    end
    file = File.open(ssh_config, "w")
    new_data.each do |line|
      file.write(line)
    end
    file.close
  end
  return
end

# Check VNC is installed

def check_vnc_install(values)
  if not File.directory?(values['novncdir'])
    message = "Information:\tCloning noVNC from "+$novnc_url
    command = "git clone #{$novnc_url}"
    execute_command(values, message, command)
  end
end

# Get Windows default interface name

def get_win_default_if_name(values)
  message = "Information:\tDeterming default interface name"
  command = "wmic nic where NetConnectionStatus=2 get NetConnectionID |grep -v NetConnectionID |head -1"
  default = execute_command(values, message, command)
  default = default.strip_control_and_extended_characters
  default = default.gsub(/^\s+|\s+$/, "")
  return(default)
end

# Get Windows interface MAC address

def get_win_if_mac(values, if_name)
  if values['host-os-uname'].to_s.match(/NT/) and if_name.match(/\s+/)
    if_name = if_name.split(/\s+/)[0]
    if_name = if_name.gsub(/"/, "")
    if_name = "%"+if_name+"%"
  end
  message = "Information:\tDeterming MAC address for '#{if_name}'"
  command = "wmic nic where \"netconnectionid like '#{if_name}'\" get macaddress"
  nic_mac = execute_command(values, message, command)
  nic_mac = nic_mac.strip_control_and_extended_characters
  nic_mac = nic_mac.split(/\s+/)[1]
  nic_mac = nic_mac.gsub(/^\s+|\s+$/, "")
  return(nic_mac)
end

# Get Windows IP from MAC

def get_win_ip_form_mac(values, nic_mac)
  message = "Information:\tDeterming IP address from MAC address '#{nic_mac}'"
  command = "wmic nicconfig get macaddress,ipaddress |grep \"#{nic_mac}\""
  host_ip = execute_command(values, message, command)
  host_ip = host_ip.strip_control_and_extended_characters
  host_ip = host_ip.split(/\s+/)[0]
  host_ip = host_ip.split(/"/)[1]
  return host_ip
end

# Get Windows default host IP

def get_win_default_host(values)
  if_name = get_win_default_if_name(values)
  nic_mac = get_win_if_mac(values, if_name)
  host_ip = get_win_ip_form_mac(values, nic_mac)
  return host_ip
end

# Get Windows IP from interface name

def get_win_ip_from_if_name(if_name)
  nic_mac = get_win_if_mac(values, if_name)
  host_ip = get_win_ip_form_mac(values, nic_mac)
  return host_ip
end

# Get default host

def get_default_host(values)
  if values['hostip'] == nil
    values['hostip'] = ""
  end
  if !values['hostip'].to_s.match(/[0-9]/)
    if values['host-os-uname'].to_s.match(/NT/)
      host_ip = get_win_default_host
    else
      message = "Information:\tDetermining Default host IP"
      case values['host-os-uname']
      when /SunOS/
        command = "/usr/sbin/ifconfig -a | awk \"BEGIN { count=0; } { if ( \\\$1 ~ /inet/ ) { count++; if( count==2 ) { print \\\$2; } } }\""
      when /Darwin/
        command = "ifconfig #{values['nic']} |grep inet |grep -v inet6"
      when /Linux/
        command = "ifconfig #{values['nic']} |grep inet |grep -v inet6"
      end
      host_ip = execute_command(values, message, command)
      if host_ip.match(/inet/)
        host_ip = host_ip.gsub(/^\s+/, "").split(/\s+/)[1]
      end
      if host_ip.match(/addr:/)
        host_ip = host_ip.split(/:/)[1].split(/ /)[0]
      end
    end
  else
    host_ip = values['hostip']
  end
  if host_ip
    host_ip = host_ip.strip
  end
  return host_ip
end

# Get default route IP

def get_gw_if_ip(values, gw_if_name)
  if values['host-os-uname'].to_s.match(/NT/)
    gw_if_ip = get_win_default_host
  else
    message = "Information:\tGetting IP of default router"
    if values['host-os-uname'].to_s.match(/Linux/)
      command = "sudo sh -c \"netstat -rn |grep UG |awk '{print \\\$2}'\""
    else
      command = "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$2}'\""
    end
    gw_if_ip = execute_command(values, message, command)
    gw_if_ip = gw_if_ip.chomp
  end
  return gw_if_ip
end

# Get default route interface

def get_gw_if_name(values)
  if values['host-os-uname'].to_s.match(/NT/)
    gw_if_ip = get_win_default_if_name(values)
  else
    message = "Information:\tGetting interface name of default router"
    if values['host-os-uname'].to_s.match(/Linux/)
      command = "sudo sh -c \"netstat -rn |grep UG |awk '{print \\\$8}' |head -1\""
    else
      if values['host-os-unamer'].to_s.match(/^19/)
        command = "sudo sh -c \"netstat -rn |grep ^default |grep UGS |tail -1 |awk '{print \\\$4}'\""
      else
        if values['host-os-version'].to_i > 10
          command = "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$4}'\""
        else
          command = "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$6}'\""
        end
      end
    end
    gw_if_name = execute_command(values, message, command)
    gw_if_name = gw_if_name.chomp
  end
  return gw_if_name
end

# Get interface name for VM networks

def get_vm_if_name(values)
  case values['vm']
  when /parallels/
    if_name = "prlsnet0"
  when /virtualbox|vbox/
    if values['host-os-uname'].to_s.match(/NT/)
      if_name = "\"VirtualBox Host-Only Ethernet Adapter\""
    else
      if_name = values['vmnet'].to_s
    end
  when /vmware|fusion/
    if values['host-os-uname'].to_s.match(/NT/)
      if_name = "\"VMware Network Adapter VMnet1\""
    else
      if_name = values['vmnet'].to_s
    end
  when /kvm|mp|multipass/
    if_name = values['vmnet'].to_s
  end
  return if_name
end

# Set config file locations

def set_local_config(values)
  if values['host-os-uname'].to_s.match(/Linux/)
#    values['tftpdir']   = "/var/lib/tftpboot"
    values['tftpdir']   = "/srv/tftp"
    values['dhcpdfile'] = "/etc/dhcp/dhcpd.conf"
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    values['tftpdir']   = "/private/tftpboot"
    values['dhcpdfile'] = "/usr/local/etc/dhcpd.conf"
  end
  if values['host-os'].to_s.match(/Docker/)
    values['tftpdir']   = "/export/tftpboot"
    values['dhcpdfile'] = "/export/etc/dhcpd.conf"
  end
  if values['host-os'].to_s.match(/SunOS/)
    values['tftpdir']   = "/etc/netboot"
    values['dhcpdfile'] = "/etc/inet/dhcpd4.conf"
  end
  return values
end

# Check local configuration
# Create work directory if it doesn't exist
# If not running on Solaris, run in test mode
# Useful for generating client config files

def check_local_config(values)
  # Check packer is installed
  if values['type'].to_s.match(/packer/)
    check_packer_is_installed(values)
  end
  # Check Docker is installed
  if values['type'].to_s.match(/docker/)
    check_docker_is_installed
  end
  if values['host-os'].to_s.downcase.match(/docker/)
    values['type'] = "docker"
    values['mode'] = "server"
  end
  # Set VMware Fusion/Workstation VMs
  if values['vm'].to_s.match(/fusion/)
    values = check_fusion_is_installed(values)
    values = set_vmrun_bin(values)
    values = set_fusion_dir(values)
  end
  # Check base dirs exist
  if values['verbose'] == true
    verbose_output(values, "Information:\tChecking base repository directory")
  end
  check_dir_exists(values, values['baserepodir'])
  check_dir_owner(values, values['baserepodir'], values['uid'])
  if values['vm'].to_s.match(/vbox/)
    values = set_vbox_bin(values)
  end
  if values['copykeys'] == true
    check_ssh_keys(values)
  end
  if values['verbose'] == true
    verbose_output(values, "Information:\tHome directory #{values['home']}")
  end
  if not values['workdir'].to_s.match(/[a-z,A-Z,0-9]/)
    dir_name = File.basename(values['script'], ".*")
    if values['uid'] == false
      values['workdir'] = "/opt/"+dir_name
    else
      values['workdir'] = values['home']+"/."+dir_name
    end
  end
  if values['verbose'] == true
    verbose_output(values, "Information:\tSetting work directory to #{values['workdir']}")
  end
  if not values['tmpdir'].match(/[a-z,A-Z,0-9]/)
    values['tmpdir'] = values['workdir']+"/tmp"
  end
  if values['verbose'] == true
    verbose_output(values, "Information:\tSetting temporary directory to #{values['workdir']}")
  end
  # Get OS name and set system settings appropriately
  if values['verbose'] == true
    verbose_output(values, "Information:\tChecking work directory")
  end
  check_dir_exists(values, values['workdir'])
  check_dir_owner(values, values['workdir'], values['uid'])
  check_dir_exists(values, values['tmpdir'])
  if values['host-os-uname'].to_s.match(/Linux/)
    values['host-os-unamer'] = %x[lsb_release -r |awk '{print $2}'].chomp
  end
  if values['host-os-unamea'].match(/Ubuntu/)
    values['lxcdir'] = "/var/lib/lxc"
  end
  values['hostip'] = get_default_host(values)
  if not values['apacheallow'].to_s.match(/[0-9]/)
    if values['hostnet'].to_s.match(/[0-9]/)
      values['apacheallow'] = values['hostip'].to_s.split(/\./)[0..2].join(".")+" "+values['hostnet']
    else
      values['apacheallow'] = values['hostip'].to_s.split(/\./)[0..2].join(".")
    end
  end
  if values['mode'].to_s.match(/server/)
    if values['host-os-uname'].to_s.match(/Darwin/)
      values['tftpdir']   = "/private/tftpboot"
      values['dhcpdfile'] = "/usr/local/etc/dhcpd.conf"
    end
    if values['host-os'].match(/Docker/)
      values['tftpdir']   = "/export/tftpboot"
      values['dhcpdfile'] = "/export/etc/dhcpd.conf"
    end
    if values['host-os-uname'].to_s.match(/SunOS/) and values['host-os-unamer'].match(/11/)
      check_dpool(values)
      check_tftpd(values)
      check_local_publisher(values)
      install_sol11_pkg(values, "pkg:/system/boot/network")
      install_sol11_pkg(values, "installadm")
      install_sol11_pkg(values, "lftp")
      check_dir_exists(values, "/etc/netboot")
    end
    if values['host-os-uname'].to_s.match(/SunOS/) and not values['host-os-unamer'].match(/11/)
      check_dir_exists(values, "/tftpboot")
    end
    if values['verbose'] == true
      verbose_output(values, "Information:\tSetting apache allow range to #{values['apacheallow']}")
    end
    if values['host-os-uname'].to_s.match(/SunOS/)
      if values['host-os-uname'].to_s.match(/SunOS/) and values['host-os-unamer'].match(/11/)
        check_dpool(values)
      end
      check_sol_bind(values)
    end
    if values['host-os-uname'].to_s.match(/Linux/)
      install_package(values, "apache2")
      if values['host-lsb-description'].to_s.match(/Endeavour|Arch/)
        install_package(values, "rpmextract")
      else
        install_package(values, "rpm2cpio")
      end
      install_package(values, "shim")
      install_package(values, "shim-signed")
      values['apachedir'] = "/etc/httpd"
      if values['host-os-unamea'].match(/RedHat|CentOS/)
        check_yum_xinetd(values)
        check_yum_tftpd(values)
        check_yum_dhcpd(values)
        check_yum_httpd(values)
        values['tftpdir']   = "/var/lib/tftpboot"
        values['dhcpdfile'] = "/etc/dhcp/dhcpd.conf"
      else
        check_apt_tftpd(values)
        check_apt_dhcpd(values)
        if values['host-os-unamea'].to_s.match(/Ubuntu/)
          values['tftpdir']   = "/srv/tftp"
        else
          values['tftpdir']   = "/var/lib/tftpboot"
        end
        values['dhcpdfile'] = "/etc/dhcp/dhcpd.conf"
      end
      check_dhcpd_config(values)
      check_tftpd_config(values)
    end
  else
    if values['host-os-uname'].to_s.match(/Linux/)
      values['tftpdir']   = "/var/lib/tftpboot"
      values['dhcpdfile'] = "/etc/dhcp/dhcpd.conf"
    end
    if values['host-os-uname'].to_s.match(/Darwin/)
      values['tftpdir']   = "/private/tftpboot"
      values['dhcpdfile'] = "/usr/local/etc/dhcpd.conf"
    end
    if values['host-os'].to_s.match(/Docker/)
      values['tftpdir']   = "/export/tftpboot"
      values['dhcpdfile'] = "/export/etc/dhcpd.conf"
    end
    if values['host-os-uname'].to_s.match(/SunOS/) and values['host-os-version'].to_s.match(/11/)
      check_dhcpd_config(values)
      check_tftpd_config(values)
    end
  end
  # If runnning on OS X check we have brew installed
  if values['host-os-uname'].to_s.match(/Darwin/)
    if !File.exist?("/usr/local/bin/brew") && !File.exist?("/opt/homebrew/bin/brew") && !File.exist?("/usr/homebrew/bin/brew")
      message = "Installing:\tBrew for OS X"
      command = "ruby -e \"$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)\""
      execute_command(values, message, command)
    end
  end
  if values['verbose'] == true
    verbose_output(values, "Information:\tChecking work bin directory")
  end
  work_bin_dir = values['workdir']+"/bin"
#  [ "rpm2cpio", "rpm" ].each do |pkg_name|
  [ "rpm2cpio" ].each do |pkg_name|
    option = pkg_name+"bin"
    installed = false
    [ "/bin", "/usr/local/bin", "/opt/local/bin", "/opt/homebrew/bin", work_bin_dir ].each do |bin_dir|
      pkg_bin = bin_dir+"/"+pkg_name
      if File.exist?(pkg_bin)
        installed = true
        values[option] = pkg_bin
        check_file_executable(values, pkg_bin)
      end
    end
    if installed == false
      install_package(values, pkg_name)
      [ "/bin", "/usr/local/bin", "/opt/local/bin", "/opt/homebrew/bin", work_bin_dir ].each do |bin_dir|
        pkg_bin = bin_dir+"/"+pkg_name
        if File.exist?(pkg_bin)
          values[option] = pkg_bin
          check_file_executable(values, pkg_bin)
        end
      end
    end
  end
  [ values['workdir'], values['bindir'], values['rpmdir'], values['backupdir'] ].each do |test_dir|
    if values['verbose'] == true
      verbose_output(values, "Information:\tChecking #{test_dir} directory")
    end
    check_dir_exists(values, test_dir)
    check_dir_owner(values, test_dir, values['uid'])
  end
  return values
end

# Check script is executable

def check_file_executable(values, file_name)
  if File.exist?(file_name)
    if not File.executable?(file_name)
      message = "Information:\tMaking '#{file_name}' executable"
      command = "chmod +x '#{file_name}'"
      execute_command(values, message, command)
    end
  end
  return
end

# Print valid list

def print_valid_list(values, message, valid_list)
  verbose_output(values, "")
  verbose_output(values, message)
  verbose_output(values, "")
  verbose_output(values, "Available values:")
  verbose_output(values, "")
  valid_list.each do |item|
    verbose_output(values, item)
  end
  verbose_output(values, "")
  return
end

# Print change log

def print_changelog()
  if File.exist?("changelog")
    changelog = File.readlines("changelog")
    changelog = changelog.reverse
    changelog.each_with_index do |line, index|
      line = line.gsub(/^# /, "")
      if line.match(/^[0-9]/)
        verbose_output(line)
        text = changelog[index-1].gsub(/^# /, "")
        verbose_output(values, text)
        verbose_output(values, "")
      end
    end
  end
  return
end

# Check default dpool

def check_dpool(values)
  message = "Information:\tChecking for alternate pool for LDoms"
  command = "zfs list |grep \"^#{values['dpool']}\""
  output  = execute_command(values, message, command)
  if not output.match(/dpool/)
    values['dpool'] = "rpool"
  end
  return
end

# Copy packages to local packages directory

def download_pkg(values, remote_file)
  local_file = File.basename(remote_file)
  if not File.exist?(local_file)
    message = "Information:\tFetching "+remote_file+" to "+local_file
    command = "wget #{remote_file} -O #{local_file}"
    execute_command(values, message, command)
  end
  return
end

# Get install type from file

def get_install_type_from_file(values)
  case values['file'].downcase
  when /vcsa/
    values['type'] = "vcsa"
  else
    values['type'] = File.extname(values['file']).downcase.split(/\./)[1]
  end
  return values['type']
end

# Check password

def check_password(install_password)
  if not install_password.match(/[A-Z]/)
    verbose_output(values, "Warning:\tPassword does not contain and upper case character")
    quit(values)
  end
  if not install_password.match(/[0-9]/)
    verbose_output(values, "Warning:\tPassword does not contain a number")
    quit(values)
  end
  return
end

# Check ovftool is installed

def check_ovftool_exists()
  if values['host-os-uname'].to_s.match(/Darwin/)
    check_osx_ovftool()
  end
  return
end

# Detach DMG

def detach_dmg(tmp_dir)
  %x[sudo hdiutil detach "#{tmp_dir}']
  return
end

# Attach DMG

def attach_dmg(pkg_file, app_name)
  tmp_dir = %x[sudo sh -c 'echo Y | hdiutil attach "#{pkg_file}" |tail -1 |cut -f3-'].chomp
  if not tmp_dir.match(/[a-z,A-Z]/)
    tmp_dir = %x[ls -rt /Volumes |grep "#{app_name}" |tail -1].chomp
    tmp_dir = "/Volumes/"+tmp_dir
  end
  if $werbose_mode == true
    verbose_output(values, "Information:\tDMG mounted on #{tmp_dir}")
  end
  return tmp_dir
end

# Check OSX ovftool

def check_osx_ovftool()
  values['ovfbin'] = "/Applications/VMware OVF Tool/ovftool"
  if not File.exist?(values['ovfbin'])
    verbose_output(values, "Warning:\tOVF Tool not installed")
    ovftool_dmg = values['ovfdmgurl'].split(/\?/)[0]
    ovftool_dmg = File.basename(ovftool_dmg)
    wget_file(values, values['ovfdmgurl'], ovftool_dmg)
    verbose_output(values, "Information:\tInstalling OVF Tool")
    app_name = "VMware OVF Tool"
    tmp_dir  = attach_dmg(ovftool_dmg, app_name)
    pkg_file = tmp_dir+"/VMware OVF Tool.pkg"
    message  = "Information:\tInstalling package "+pkg_file
    command  = "/usr/sbin/installer -pkg #{pkg_bin} -target /"
    execute_command(values, message, command)
    detach_dmg(tmp_dir)
  end
  return
end

# SCP file to remote host

def scp_file(values, local_file, remote_file)
  if values['verbose'] == true
    verbose_output(values, "Information:\tCopying file \""+local_file+"\" to \""+values['server']+":"+remote_file+"\"")
  end
  Net::SCP.start(values['server'], values['serveradmin'], :password => values['serverpassword'], :paranoid => false) do |scp|
    scp.upload! local_file, remote_file
  end
  return
end

# Execute SSH command

def execute_ssh_command(values, command)
  if values['verbose'] == true
    verbose_output(values, "Information:\tExecuting command \""+command+"\" on server "+values['server'])
  end
  Net::SSH.start(values['server'], values['serveradmin'], :password => values['serverpassword'], :paranoid => false) do |ssh|
    ssh.exec!(command)
  end
  return
end

# Get client config

def get_client_config(values)
  config_files  = []
  values['clientdir']    = ""
  config_prefix = ""
  if values['vm'].to_s.match(/[a-z]/)
    show_vm_config(values)
  else
    values['clientdir'] = get_client_dir(values)
    if values['type'].to_s.match(/packer/) or values['clientdir'].to_s.match(/packer/)
      values['method'] = "packer"
      values['clientdir']     = get_packer_client_dir(values)
    else
      if not values['service'].to_s.match(/[a-z]/)
        values['service'] = get_install_service_from_client_name(values)
      end
      if not values['method'].to_s.match(/[a-z]/)
        values['method']  = get_install_method(values)
      end
    end
    config_prefix = values['clientdir']+"/"+values['name']
    case values['method']
    when /packer/
      config_files[0] = config_prefix+".json"
      config_files[1] = config_prefix+".cfg"
      config_files[2] = config_prefix+"_first_boot.sh"
      config_files[3] = config_prefix+"_post.sh"
      config_files[4] = values['clientdir']+"/Autounattend.xml"
      config_files[5] = values['clientdir']+"/post_install.ps1"
    when /config|cfg|ks|Kickstart/
      config_files[0] = config_prefix+".cfg"
    when /post/
      case method
      when /ps/
        config_files[0] = config_prefix+"_post.sh"
      end
    when /first/
      case method
      when /ps/
        config_files[0] = config_prefix+"_first_boot.sh"
      end
    end
    config_files.each do |config_file|
      if File.exist?(config_file)
        print_contents_of_file(values, "", config_file)
      end
    end
  end
  return
end

# Get client install service for a client

def get_install_service(values)
  values['clientdir'] = get_client_dir(values)
  values['service']   = values['clientdir'].split(/\//)[-2]
  return values['service']
end

# Get install method from service

def get_install_method(values)
  if values['vm'].to_s.match(/mp|multipass/)
    if values['method'] == values['empty']
      values['method'] = "mp"
      return values['method']
    end
  end
  if not values['service'].to_s.match(/[a-z]/)
    values['service'] = get_install_service(values)
  end
  service_dir = values['baserepodir'].to_s+"/"+values['service'].to_s
  if File.directory?(service_dir) or File.symlink?(service_dir)
    if values['verbose'] == true
      verbose_output(values, "Information:\tFound directory #{service_dir}")
      verbose_output(values, "Information:\tDetermining service type")
    end
  else
    verbose_output(values, "Warning:\tService #{values['service']} does not exist")
  end
  values['method'] = ""
  test_file = service_dir+"/vmware-esx-base-osl.txt"
  if File.exist?(test_file)
    values['method'] = "vs"
  else
    test_file = service_dir+"/repodata"
    if File.exist?(test_file)
      values['method'] = "ks"
    else
      test_dir = service_dir+"/preseed"
      if File.directory?(test_dir)
        values['method'] = "ps"
      end
    end
  end
  return values['method']
end

# Unconfigure a server

def unconfigure_server(values)
  if values['method'] == values['empty']
    values['method'] = get_install_method(values)
  end
  if values['method'].to_s.match(/[a-z]/)
    case values['method']
    when /ai/
      unconfigure_ai_server(values)
    when /ay/
      unconfigure_ay_server(values)
    when /js/
      unconfigure_js_server(values)
    when /ks/
      unconfigure_ks_server(values)
    when /ldom/
      unconfigure_ldom_server(values)
    when /gdom/
      unconfigure_gdom_server(values)
    when /ps/
      unconfigure_ps_server(values)
    when /vs/
      unconfigure_vs_server(values)
    when /xb/
      unconfigure_xb_server(values)
    end
  else
    verbose_output(values, "Warning:\tCould not determine service type for #{values['service']}")
  end
  return
end

# list OS install ISOs

def list_os_isos(values)
  case values['os-type'].to_s
  when /linux/
    if not values['search'].to_s.match(/[a-z]/)
      values['search'] = "CentOS|OracleLinux|SUSE|SLES|SL|Fedora|ubuntu|debian|purity"
    end
  when /sol/
    search_string = "sol"
  when /esx|vmware|vsphere/
    search_string = "VMvisor"
  else
    list_all_isos(values)
    return
  end
  if values['os-type'].to_s.match(/linux/)
    list_linux_isos(values)
  end
  return
end

# List all isos

def list_all_isos(values)
  list_isos(values)
  return
end

# Get install method from service name

def get_install_method_from_service(values)
  case values['service']
  when /vmware/
    values['method'] = "vs"
  when /centos|oel|rhel|fedora|sl/
    values['method'] = "ks"
  when /ubuntu|debian/
    values['method'] = "ps"
  when /suse|sles/
    values['method'] = "ay"
  when /sol_6|sol_7|sol_8|sol_9|sol_10/
    values['method'] = "js"
  when /sol_11/
    values['method'] = "ai"
  end
  return values['method']
end

# Describe file

def describe_file(values)
  values = get_install_service_from_file(values)
  verbose_output(values, "")
  verbose_output(values, "Install File:\t\t#{values['file']}")
  verbose_output(values, "Install Service:\t#{values['service']}")
  verbose_output(values, "Install OS:\t\t#{values['os-type']}")
  verbose_output(values, "Install Method:\t\t#{values['method']}")
  verbose_output(values, "Install Release:\t#{values['release']}")
  verbose_output(values, "Install Architecture:\t#{values['arch']}")
  verbose_output(values, "Install Label:\t#{values['label']}")
  return
end

# Get install service from ISO file name

def get_install_service_from_file(values)
  service_version    = ""
  values['service'] = ""
  values['service'] = ""
  values['arch']    = ""
  values['release'] = ""
  values['method']  = ""
  values['label']   = ""
  if values['file'].to_s.match(/amd64|x86_64/) || values['vm'].to_s.match(/kvm/)
    values['arch'] = "x86_64"
  else
    if values['file'].to_s.match(/arm/)
      if values['file'].to_s.match(/64/)
        values['arch'] = "arm64"
      else
        values['arch'] = "arm"
      end
    else
      values['arch'] = "i386"
    end
  end
  case values['file'].to_s
  when /purity/
    values['service'] = "purity"
    values['release'] = values['file'].split(/_/)[1]
    values['arch']    = "x86_64"
    service_version = values['release']+"_"+values['arch']
    values['method']  = "ps"
  when /ubuntu|cloudimg|[a-z]-desktop|[a-z]-live-server/
    values['service'] = "ubuntu"
    if values['vm'].to_s.match(/kvm/)
      values['os-type'] = "linux"
    else
      values['os-type'] = "ubuntu"
    end
    if values['file'].to_s.match(/cloudimg|[a-z]-desktop|[a-z]-live-server/)
      values['method']  = "ci"
      values['release'] = get_release_version_from_code_name(values['file'].to_s)
      if values['release'].to_s.match(/[0-9][0-9]/)
        if values['file'].to_s.match(/-arm/)
          values['arch'] = values['file'].to_s.split(/-/)[-1].split(/\./)[0]
        else
          values['arch'] = values['file'].to_s.split(/-/)[3].split(/\./)[0].gsub(/amd64/, "x86_64")
        end
      else
        values['release'] = values['file'].to_s.split(/-/)[1].split(/\./)[0..1].join(".")
        values['arch']    = values['file'].to_s.split(/-/)[4].split(/\./)[0].gsub(/amd64/, "x86_64")
      end
      service_version = values['service'].to_s.+"_"+values['release'].to_s.gsub(/\./, "_")+values['arch']+to_s
      values['os-type'] = "linux"
      values['os-variant'] = "ubuntu"+values['release'].to_s
    else
      service_version = values['file'].to_s.split(/-/)[1].gsub(/\./, "_").gsub(/_iso/, "")
      if values['file'].to_s.match(/live/)
        values['method'] = "ci"
        service_version   = service_version+"_live_"+values['arch']
      else
        values['method'] = "ps"
        service_version   = service_version+"_"+values['arch']
      end
      values['release'] = values['file'].to_s.split(/-/)[1].split(/\./)[0..-1].join(".")
    end
#    if values['release'].to_s.split(".")[0].to_i > 20
#      values['release'] = "20.04"
#    end
    values['os-variant'] = "ubuntu"+values['release'].to_s
    if values['file'].to_s.match(/live/)
      values['livecd'] = true
    end
  when /purity/
    values['service'] = "purity"
    service_version = values['file'].to_s.split(/_/)[1]
    values['method']  = "ps"
    values['arch']    = "x86_64"
  when /vCenter-Server-Appliance|VCSA/
    values['service'] = "vcsa"
    service_version = values['file'].to_s.split(/-/)[3..4].join(".").gsub(/\./, "_").gsub(/_iso/, "")
    values['method']  = "image"
    values['release'] = values['file'].to_s.split(/-/)[3..4].join(".").gsub(/\.iso/, "")
    values['arch']    = "x86_64"
  when /VMvisor-Installer/
    values['service'] = "vmware"
    values['arch']    = "x86_64"
    service_version = values['file'].to_s.split(/-/)[3].gsub(/\./, "_")+"_"+values['arch']
    values['method']  = "vs"
    values['release'] = values['file'].to_s.split(/-/)[3].gsub(/update/, "")
    values['os-variant'] = "unknown"
  when /CentOS/
    values['service'] = "centos"
    service_version = values['file'].to_s.split(/-/)[1..2].join(".").gsub(/\./, "_").gsub(/_iso/, "")
    values['os-type'] = values['service']
    values['method']  = "ks"
    values['release'] = values['file'].to_s.split(/-/)[1]
    if values['release'].to_s.match(/^7/)
      case values['file']
      when /1406/
        values['release'] = "7.0"
      when /1503/
        values['release'] = "7.1"
      when /1511/
        values['release'] = "7.2"
      when /1611/
        values['release'] = "7.3"
      when /1708/
        values['release'] = "7.4"
      when /1804/
        values['release'] = "7.5"
      when /1810/
        values['release'] = "7.6"
      end
      service_version = values['release'].gsub(/\./, "_")+"_"+values['arch']
    end
  when /Fedora-Server/
    values['service'] = "fedora"
    if values['file'].to_s.match(/DVD/)
      service_version = values['file'].split(/-/)[-1].gsub(/\./, "_").gsub(/_iso/, "_")
      service_arch    = values['file'].split(/-/)[-2].gsub(/\./, "_").gsub(/_iso/, "_")
      values['release'] = values['file'].split(/-/)[-1].gsub(/\.iso/, "")
    else
      service_version = values['file'].split(/-/)[-2].gsub(/\./, "_").gsub(/_iso/, "_")
      service_arch    = values['file'].split(/-/)[-3].gsub(/\./, "_").gsub(/_iso/, "_")
      values['release'] = values['file'].split(/-/)[-2].gsub(/\.iso/, "")
    end
    service_version = service_version+"_"+service_arch
    values['method']  = "ks"
  when /OracleLinux/
    values['service'] = "oel"
    service_version = values['file'].split(/-/)[1..2].join(".").gsub(/\./, "_").gsub(/R|U/, "")
    service_arch    = values['file'].split(/-/)[-2]
    service_version = service_version+"_"+service_arch
    values['release'] = values['file'].split(/-/)[1..2].join(".").gsub(/[a-z,A-Z]/, "")
    values['method']  = "ks"
  when /openSUSE/
    values['service'] = "opensuse"
    service_version = values['file'].split(/-/)[1].gsub(/\./, "_").gsub(/_iso/, "")
    service_arch    = values['file'].split(/-/)[-1].gsub(/\./, "_").gsub(/_iso/, "")
    service_version = service_version+"_"+service_arch
    values['method']  = "ay"
    values['release'] = values['file'].split(/-/)[1]
  when /rhel/
    values['service'] = "rhel"
    values['method']  = "ks"
    if values['file'].to_s.match(/beta|8\.[0-9]/)
      service_version = values['file'].split(/-/)[1..2].join(".").gsub(/\./, "_").gsub(/_iso/, "")
      values['release'] = values['file'].split(/-/)[1]
    else
      if values['file'].to_s.match(/server/)
        service_version = values['file'].split(/-/)[2..3].join(".").gsub(/\./, "_").gsub(/_iso/, "")
        values['release'] = values['file'].split(/-/)[2]
      else
        service_version = values['file'].split(/-/)[1..2].join(".").gsub(/\./, "_").gsub(/_iso/, "")
        values['release'] = values['file'].split(/-/)[1]
      end
    end
  when /Rocky|Alma/
    values['service'] = File.basename(values['file']).to_s.split(/-/)[0].downcase.gsub(/linux/,"")
    values['method']  = "ks"
    service_version = values['file'].split(/-/)[1..2].join(".").gsub(/\./, "_").gsub(/_iso/, "")
    values['release'] = values['file'].split(/-/)[1]
  when /SLE/
    values['service'] = "sles"
    service_version = values['file'].split(/-/)[1..2].join("_").gsub(/[A-Z]/, "")
    service_arch    = values['file'].split(/-/)[4]
    if service_arch.match(/DVD/)
      service_arch = values['file'].split(/-/)[5]
    end
    service_version = service_version+"_"+service_arch
    values['method']  = "ay"
    values['release'] = values['file'].split(/-/)[1]
  when /sol/
    values['service'] = "sol"
    values['release'] = values['file'].split(/-/)[1].gsub(/_/, ".")
    if values['release'].to_i > 10
      if values['file'].to_s.match(/1111/)
        values['release'] = "11.0"
      end
      values['method'] = "ai"
      values['arch']   = "x86_64"
    else
      values['release'] = values['file'].split(/-/)[1..2].join(".").gsub(/u/, "")
      values['method']  = "js"
      values['arch']    = "i386"
    end
    service_version = values['release']+"_"+values['arch']
    service_version = service_version.gsub(/\./, "_")
  when /V[0-9][0-9][0-9][0-9][0-9]/
    isofile_bin = %[which isofile].chomp
    if isofile_bin.match(/not found/)
      values = install_package("cdrtools")
      isofile_bin = %x[which isofile].chomp
      if isofile_bin.match(/not found/)
        verbose_output(values, "Warning:\tUtility isofile not found")
        quit(values)
      end
    end
    values['service'] = "oel"
    values['method']  = "ks"
    volume_id_info  = %x[isoinfo -d -i "#{values['file']}" |grep "^Volume id" |awk '{print $3}'].chomp
    service_arch    = volume_id_info.split(/-/)[-1]
    service_version = volume_id_info.split(/-/)[1..2].join("_")
    service_version = service_version+"-"+service_arch
    values['release'] = volume_id_info.split(/-/)[1]
  when /[0-9][0-9][0-9][0-9]|Win|Srv/
    values['service'] = "windows"
    mount_iso(values)
    wim_file = values['mountdir']+"/sources/install.wim"
    if File.exist?(wim_file)
      wiminfo_bin = %x[which wiminfo]
      if not wiminfo_bin.match(/wiminfo/)
        message = "Information:\tInstall wiminfo (wimlib/wimtools)"
        if values['host-os-uname'].to_s.match(/Darwin/)
          install_package(values, "wimlib")
        else
          if values['host-lsb-description'].to_s.match(/Endeavour|Arch/)
            install_package(values, "wimlib")
          else
            install_package(values, "wimtools")
          end
        end
        wiminfo_bin = %x[which wiminfo]
        if not wiminfo_bin.match(/wiminfo/)
          verbose_output(values, "Warning:\tCannnot find wiminfo (required to determine version of windows from ISO)")
          quit(values)
        end
      end
      message = "Information:\tDeterming version of Windows from: "+wim_file
      command = "wiminfo \"#{wim_file}\" 1| grep ^Description"
      output  = execute_command(values, message, command)
      values['label']   = output.chomp.split(/\:/)[1].gsub(/^\s+/, "").gsub(/CORE/, "")
      service_version = output.split(/Description:/)[1].gsub(/^\s+|SERVER|Server/, "").downcase.gsub(/\s+/, "_").split(/_/)[1..-1].join("_")
      message = "Information:\tDeterming architecture of Windows from: "+wim_file
      command = "wiminfo \"#{wim_file}\" 1| grep ^Architecture"
      output  = execute_command(values, message, command)
      values['arch'] = output.chomp.split(/\:/)[1].gsub(/^\s+/, "")
      umount_iso(values)
    end
    service_version = service_version+"_"+values['release']+"_"+values['arch']
    service_version = service_version.gsub(/__/, "_")
    values['method'] = "pe"
  end
  if !values['vm'].to_s.match(/kvm/)
    values['service'] = values['service']+"_"+service_version.gsub(/__/, "_")
  else
    if values['file'].to_s.match(/cloudimg/) && values['file'].to_s.match(/ubuntu/)
      values['os-type'] = "linux"
    else
      if values['vm'].to_s.match(/kvm/)
        values['os-type'] = "linux"
      else
        values['os-type'] = values['service']
      end
    end
    values['service'] = values['service']+"_"+service_version.gsub(/__/, "_")
  end
  if values['file'].to_s.match(/-arm/) and values['service'].to_s.match(/ubuntu/)
    if values['file'].to_s.match(/live/)
      values['service'] = "ubuntu_"+values['release'].to_s+"_"+values['arch']+"_live"
    else
      values['service'] = "ubuntu_"+values['release'].to_s+"_"+values['arch']
    end
    values['service'] = values['service'].gsub(/\./, "_")
  end
  if values['verbose'] == true
    verbose_output(values, "Information:\tSetting service name to #{values['service']}")
    verbose_output(values, "Information:\tSetting OS name to #{values['os-type']}")
  end
  return(values)
end

# Get arch from ISO

def get_install_arch_from_file(values)
  if values['file'].to_s.match(/\//)
    iso_file = File.basename(values['file'])
  end
  case iso_file
  when /386/
    values['arch'] = "i386"
  when /amd64|x86/
    values['arch'] = "x86_64"
  when /arm64/
    values['arch'] = "arm64"
  when /arm/
    values['arch'] = "arm"
  when /sparc/
    values['arch'] = "sparc"
  end
  return values['arch']
end

# Get Install method from ISO file name

def get_install_method_from_iso(values)
  if values['file'].to_s.match(/\//)
    iso_file = File.basename(values['file'])
  end
  case iso_file
  when /VMware-VMvisor/
    values['method'] = "vs"
  when /CentOS|OracleLinux|^SL|Fedora|rhel|V[0-9][0-9][0-9][0-9]/
    values['method'] = "ks"
  when /ubuntu|debian|purity/
    values['method'] = "ps"
  when /SUSE|SLE/
    values['method'] = "ay"
  when /sol-6|sol-7|sol-8|sol-9|sol-10/
    values['method'] = "js"
  when /sol-11/
    values['method'] = "ai"
  when /Win|WIN|srv|EVAL|eval|win/
    values['method'] = "pe"
  end
  return values['method']
end

# Configure a service

def configure_server(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    check_osx_dhcpd_installed()
    create_osx_dhcpd_plist()
  end
  if not values['method'].to_s.match(/[a-z,A-Z]/)
    if not values['file'].to_s.match(/[a-z,A-Z]/)
      verbose_output(values, "Warning:\tCould not determine service name")
      quit(values)
    else
      values['method'] = get_install_method_from_iso(values)
    end
  end
  eval"[configure_#{values['method']}_server(values)]"
  return
end

# Generate MAC address

def generate_mac_address(values)
  if values['vm'].to_s.match(/fusion|vbox/)
    mac_address = "00:05:"+(1..4).map{"%0.2X"%rand(256)}.join(":")
  else
    if values['vm'].to_s.match(/kvm/)
      mac_address = "52:54:00:"+(1..3).map{"%0.2X"%rand(256)}.join(":")
    else
      mac_address = (1..6).map{"%0.2X"%rand(256)}.join(":")
    end
  end
  return mac_address
end

# List all image services - needs code

def list_image_services(values)
  return
end

# List all image ISOs - needs code

def list_image_isos(values)
  return
end

# List images

def list_images(values)
  case values['vm'].to_s
  when /aws/
    list_aws_images(values)
  when /docker/
    list_docker_images(values)
  when /kvm/
    list_kvm_images(values)
  else
    if values['dir'] != values['empty']
      list_items(values)
    end
  end
  return
end

# List all services

def list_all_services(values)
  verbose_output(values, "")
  list_ai_services(values)
  list_ay_services(values)
  list_image_services(values)
  list_js_services(values)
  list_ks_services(values)
  list_cdom_services(values)
  list_ldom_services(values)
  list_gdom_services(values)
  list_lxc_services(values)
  list_ps_services(values)
  list_cc_services(values)
  list_zone_services(values)
  list_vs_services(values)
  list_xb_services(values)
  return
end

# Check hostname validity

def check_hostname(values)
  host_chars = values['name'].split()
  host_chars.each do |char|
    if not char.match(/[a-z,A-Z,0-9]|-/)
      verbose_output(values, "Invalid hostname: #{values['name'].join()}")
      quit(values)
    end
  end
end

# Get ISO list

def get_dir_item_list(values)
  full_list = get_base_dir_list(values)
  if values['os-type'] == values['empty'] && values['search'] == values['empty'] && values['method'] == values['empty']
    return full_list
  end
  if values['search'] != values['empty']
    other_search = values['search']
  end
  temp_list = []
  iso_list  = []
  if values['os-type'] != values['empty']
    case values['os-type'].downcase
    when /pe|win/
      os_search = "OEM|win|Win|EVAL|eval"
    when /oel|oraclelinux/
      os_search = "OracleLinux"
    when /sles/
      os_search = "SLES"
    when /centos/
      os_search = "CentOS"
    when /suse/
      os_search = "openSUSE"
    when /ubuntu/
      if values['vm'].to_s.match(/kvm/)
        os_search = "linux"
      else
        os_search = "ubuntu"
      end
    when /debian/
      os_search = "debian"
    when /purity/
      os_search = "purity"
    when /fedora/
      os_search = "Fedora"
    when /scientific|sl/
      os_search = "SL"
    when /redhat|rhel/
      os_search = "rhel"
    when /sol/
      os_search = "sol"
    when /^linux/
      os_search = "CentOS|OracleLinux|SLES|openSUSE|ubuntu|debian|Fedora|rhel|SL"
    when /vmware|vsphere|esx/
      os_search = "VMware-VMvisor"
    end
  end
  if values['method'] != values['empty']
    case values['method'].to_s
    when /kick|ks/
      method_search = "CentOS|OracleLinux|Fedora|rhel|SL|VMware"
    when /jump|js/
      method_search = "sol-10"
    when /ai/
      method_search = "sol-11"
    when /yast|ay/
      method_search = "SLES|openSUSE"
    when /preseed|ps/
      method_search = "debian|ubuntu|purity"
    when /ci/
      method_search = "live"
    when /vs/
      method_search = "VMvisor"
    when /xb/
      method_search = "FreeBSD|install"
    end
  end
  if values['release'].to_s.match(/[0-9]/)
    case values['os-type']
    when "OracleLinux"
      if values['release'].to_s.match(/\./)
        (major, minor)   = values['release'].split(/\./)
        release_search = "-R"+major+"-U"+minor
      else
        release_search = "-R"+values['release']
      end
    when /sol/
      if values['release'].to_s.match(/\./)
        (major, minor)   = values['release'].split(/\./)
        if values['release'].to_s.match(/^10/)
          release_search = major+"-u"+minor
        else
          release_search = major+"_"+minor
        end
      end
      release_search = "-"+values['release']
    else
      release_search = "-"+values['release']
    end
  end
  if values['arch'] != values['empty']
    if values['arch'].to_s.match(/[a-z,A-Z]/)
     if values['os-type'].to_s.match(/sol/)
        arch_search = values['arch'].gsub(/i386|x86_64/, "x86")
      end
      if values['os-type'].to_s.match(/ubuntu/)
        arch_search = values['arch'].gsub(/x86_64/, "amd64")
      else
        arch_search = values['arch'].gsub(/amd64/, "x86_64")
      end
    end
  end
  results_list = full_list
  [ os_search, method_search, release_search, arch_search, other_search ].each do |search_string|
    if search_string
      if search_string != values['empty']
        if search_string.match(/[a-z,A-Z,0-9]/)
          results_list = results_list.grep(/#{search_string}/)
        end
      end
    end
  end
  if values['method'].to_s.match(/ps/)
    results_list = results_list.grep_v(/live/)
  end
  return results_list
end

# Get item version information (e.g. ISOs, images, etc)

def get_item_version_info(file_name)
  iso_info = File.basename(file_name)
  if file_name.match(/purity/)
    iso_info = iso_info.split(/_/)
  else
    iso_info = iso_info.split(/-/)
  end
  iso_distro = iso_info[0]
  iso_distro = iso_distro.downcase
  if file_name.match(/cloud/)
    iso_distro = "ubuntu"
  end
  if iso_distro.match(/^sle$/)
    iso_distro = "sles"
  end
  if iso_distro.match(/oraclelinux/)
    iso_distro = "oel"
  end
  if iso_distro.match(/centos|ubuntu|sles|sl|oel|rhel/)
    if file_name.match(/cloud/) and not file_name.match(/ubuntu/)
      iso_version = get_release_version_from_code_name(file_name)
    else
      if iso_distro.match(/sles/)
        if iso_info[2].to_s.match(/Server/)
          iso_version = iso_info[1]+".0"
        else
          iso_version = iso_info[1]+"."+iso_info[2]
          iso_version = iso_version.gsub(/SP/, "")
        end
      else
        if iso_distro.match(/sl$/)
          iso_version = iso_info[1].split(//).join(".")
          if iso_version.length == 1
            iso_version = iso_version+".0"
          end
        else
          if iso_distro.match(/oel|rhel/)
            if file_name =~ /-rc-/
              iso_version = iso_info[1..3].join(".")
              iso_version = iso_version.gsub(/server/, "")
            else
              iso_version = iso_info[1..2].join(".")
              iso_version = iso_version.gsub(/[a-z,A-Z]/, "")
            end
            iso_version = iso_version.gsub(/^\./, "")
          else
            iso_version = iso_info[1]
          end
        end
      end
    end
    if iso_version.match(/86_64/)
      iso_version = iso_info[1]
    end
    if file_name.match(/live/)
      iso_version = iso_version+"_live"
    end
    case file_name
    when /workstation|desktop/
      iso_version = iso_version+"_desktop"
    when /server/
      iso_version = iso_version+"_server"
    end
    if file_name.match(/cloud/)
      iso_version = iso_version+"_cloud"
    end
    case file_name
    when /i[3-6]86/
      iso_arch = "i386"
    when /x86_64|amd64/
      iso_arch = "x86_64"
    else
      if file_name.match(/ubuntu/)
        iso_arch = iso_info[-1].split(".")[0]
      else
        if iso_distro.match(/centos|sl$/)
          iso_arch = iso_info[2]
        else
          if iso_distro.match(/sles|oel/)
            iso_arch = iso_info[4]
          else
            iso_arch = iso_info[3]
          end
        end
      end
    end
  else
    case iso_distro
    when /fedora/
      iso_version = iso_info[1]
      iso_arch    = iso_info[2]
    when /purity/
      iso_version = iso_info[1]
      iso_arch    = "x86_64"
    when /vmware/
      iso_release = iso_info[3].gsub(/U/,".")
      iso_update  = iso_info[4].split(/\./)[0]
      iso_version = iso_release+"."+iso_update
      iso_arch    = "x86_64"
    else
      iso_version = iso_info[2]
      iso_arch    = iso_info[3]
    end
  end
  return iso_distro, iso_version, iso_arch
end

# List ISOs

def list_isos(values)
  list_items(values)
  return
end

# List items (ISOs, images, etc)

def list_items(values)
  if !values['output'].to_s.match(/html/) && !values['vm'].to_s.match(/mp|multipass/)
    string = "Information:\tDirectory #{values['isodir']}"
    verbose_output(values, string)
  end
  if values['file'] == values['empty']
    iso_list = get_base_dir_list(values)
  else
    iso_list    = []
    iso_list[0] = values['file']
  end
  if iso_list.length > 0
    if values['output'].to_s.match(/html/)
      verbose_output(values, "<h1>Available ISO(s)/Image(s):</h1>")
      verbose_output(values, "<table border=\"1\">")
      verbose_output(values, "<tr>")
      verbose_output(values, "<th>ISO/Image File</th>")
      verbose_output(values, "<th>Distribution</th>")
      verbose_output(values, "<th>Version</th>")
      verbose_output(values, "<th>Architecture</th>")
      verbose_output(values, "<th>Service Name</th>")
      verbose_output(values, "</tr>")
    else
      verbose_output(values, "Available ISO(s)/Images(s):")
      verbose_output(values, "")
    end
    iso_list.each do |file_name|
      file_name = file_name.chomp
      if values['vm'].to_s.match(/mp|multipass/)
        iso_arch     = values['host-os-unamem'].to_s
        linux_distro = file_name.split(/ \s+/)[-1]
        iso_version  = file_name.split(/ \s+/)[-2]
        file_name    = file_name.split(/ \s+/)[0]
      else
        (linux_distro, iso_version, iso_arch) = get_linux_version_info(file_name)
      end
      if values['output'].to_s.match(/html/)
        verbose_output(values, "<tr>")
        verbose_output(values, "<td>#{file_name}</td>")
        verbose_output(values, "<td>#{linux_distro}</td>")
        verbose_output(values, "<td>#{iso_version}</td>")
        verbose_output(values, "<td>#{iso_arch}</td>")
      else
        verbose_output(values, "ISO/Image file:\t#{file_name}")
        verbose_output(values, "Distribution:\t#{linux_distro}")
        verbose_output(values, "Version:\t#{iso_version}")
        verbose_output(values, "Architecture:\t#{iso_arch}")
      end
      iso_version = iso_version.gsub(/\./, "_")
      values['service'] = linux_distro.downcase.gsub(/\s+|\.|-/, "_").gsub(/_lts_/, "")+"_"+iso_version+"_"+iso_arch
      values['repodir'] = values['baserepodir']+"/"+values['service']
      if File.directory?(values['repodir'])
        if values['output'].to_s.match(/html/)
          verbose_output(values, "<td>#{values['service']} (exists)</td>")
        else
          verbose_output(values, "Service Name:\t#{values['service']} (exists)")
        end
      else
        if values['output'].to_s.match(/html/)
          verbose_output(values, "<td>#{values['service']}</td>")
        else
          verbose_output(values, "Service Name:\t#{values['service']}")
        end
      end
      if values['output'].to_s.match(/html/)
        verbose_output(values, "</tr>")
      else
        verbose_output(values, "")
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_output(values, "</table>")
    end
  end
  return
end

# Connect to virtual serial port

def connect_to_virtual_serial(values)
  if values['vm'].to_s.match(/ldom|gdom/)
    connect_to_gdom_console(values)
  else
    verbose_output(values, "")
    verbose_output(values, "Connecting to serial port of #{values['name']}")
    verbose_output(values, "")
    verbose_output(values, "To disconnect from this session use CTRL-Q")
    verbose_output(values, "")
    verbose_output(values, "If you wish to re-connect to the serial console of this machine,")
    verbose_output(values, "run the following command:")
    verbose_output(values, "")
    verbose_output(values, "#{values['script']} --action=console --vm=#{values['vm']} --name = #{values['name']}")
    verbose_output(values, "")
    verbose_output(values, "or:")
    verbose_output(values, "")
    verbose_output(values, "socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
    verbose_output(values, "")
    verbose_output(values, "")
    system("socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
  end
  return
end

# Set some VMware ESXi VM defaults

def configure_vmware_esxi_defaults()
  values['memory']     = "4096"
  values['vcpus']      = "4"
  values['os-type']    = "ESXi"
  values['controller'] = "ide"
  values['os-variant'] = "unknown"
  return
end

# Set some VMware vCenter defaults

def configure_vmware_vcenter_defaults()
  values['memory']     = "4096"
  values['vcpus']      = "4"
  values['os-type']    = "ESXi"
  values['controller'] = "ide"
  values['os-variant'] = "unknown"
  return
end

# Get Install Service from client name

def get_install_service_from_client_name(values)
  values['service'] = ""
  message = "Information:\tFinding client configuration directory for #{values['name']}"
  command = "find #{values['clientdir']} -name #{values['name']} |grep '#{values['name']}$'"
  values['clientdir'] = execute_command(values, message, command)
  values['clientdir'] = values['clientdir'].chomp
  if values['verbose'] == true
    if File.directory?(values['clientdir'])
      verbose_output(values, "Information:\tNo client directory found for #{values['name']}")
    else
      verbose_output(values, "Information:\tClient directory found #{values['clientdir']}")
      if values['clientdir'].to_s.match(/packer/)
        verbose_output = "Information:\tInstall method is Packer"
      end
    end
  end
  return values['service']
end


# Get client directory

def get_client_dir(values)
  message = "Information:\tFinding client configuration directory for #{values['name']}"
  command = "find #{values['clientdir']} -name #{values['name']} |grep '#{values['name']}$'"
  values['clientdir'] = execute_command(values, message, command).chomp
  if values['verbose'] == true
    if File.directory?(values['clientdir'])
      verbose_output(values, "Information:\tNo client directory found for #{values['name']}")
    else
      verbose_output(values, "Information:\tClient directory found #{values['clientdir']}")
    end
  end
  return values['clientdir']
end

# Delete client directory

def delete_client_dir(values)
  values['clientdir'] = get_client_dir(values)
  if File.directory?(values['clientdir'])
    if values['clientdir'].to_s.match(/[a-z]/)
      if values['host-os-uname'].to_s.match(/SunOS/)
        destroy_zfs_fs(values['clientdir'])
      else
        message = "Information:\tRemoving client configuration files for #{values['name']}"
        command = "rm #{values['clientdir']}/*"
        execute_command(values, message, command)
        message = "Information:\tRemoving client configuration directory #{values['clientdir']}"
        command = "rmdir #{values['clientdir']}"
        execute_command(values, message, command)
      end
    end
  end
  return
end

# Unconfigure client

def unconfigure_client(values)
  if values['type'].to_s.match(/packer|ansible/)
    if values['type'].to_s.match(/packer/)
      unconfigure_packer_client(values)
    else
      unconfigure_ansible_client(values)
    end
  else
    case values['method']
    when /ai/
      unconfigure_ai_client(values)
    when /ay/
      unconfigure_ay_client(values)
    when /js/
      unconfigure_js_client(values)
    when /ks/
      unconfigure_ks_client(values)
    when /ps/
      unconfigure_ps_client(values)
    when /ci/
      unconfigure_cc_client(values)
    when /vs/
      unconfigure_vs_client(values)
    when /xb/
      unconfigure_xb_client(values)
    end
  end
  return
end

# Configure client

def configure_client(values)
  if values['type'].to_s.match(/packer|ansible/)
    if values['type'].to_s.match(/packer/)
      configure_packer_client(values)
    else
      configure_ansible_client(values)
    end
  else
    case values['method']
    when /ai/
      configure_ai_client(values)
    when /ay/
      configure_ay_client(values)
    when /js/
      configure_js_client(values)
    when /ks/
      configure_ks_client(values)
    when /ps/
      configure_ps_client(values)
    when /ci/
      configure_cc_client(values)
    when /vs/
      configure_vs_client(values)
    when /xb/
      configure_xb_client(values)
    when /mp|multipass/
      configure_multipass_client(values)
    end
  end
  return
end

def configure_server(values)
  case values['method']
  when /ai/
    configure_ai_server(values)
  when /ay/
    configure_ay_server(values)
  when /docker/
    configure_docker_server(values)
  when /js/
    configure_js_server(values)
  when /ks/
    configure_ks_server(values)
  when /ldom/
    configure_ldom_server(values)
  when /cdom/
    configure_cdom_server(values)
  when /lxc/
    configure_lxc_server(values)
  when /ps/
    configure_ps_server(values)
  when /ci/
    configure_cc_server(values)
  when /vs/
    configure_vs_server(values)
  when /xb/
    configure_xb_server(values)
  end
  return
end

# List clients for an install service

def list_clients(values)
  case values['method'].downcase
  when /ai/
    list_ai_clients()
    return
  when /js|jumpstart/
    search_string = "sol_6|sol_7|sol_8|sol_9|sol_10"
  when /ks|kickstart/
    search_string = "centos|redhat|rhel|scientific|fedora"
  when /ps|preseed/
    search_string = "debian|ubuntu"
  when /ci/
    search_string = "live"
  when /vmware|vsphere|esx|vs/
    search_string = "vmware"
  when /ay|autoyast/
    search_string = "suse|sles"
  when /xb/
    search_string = "bsd|coreos"
  end
  service_list = Dir.entries(values['clientdir'])
  service_list = service_list.grep(/#{search_string}|#{values['service']}/)
  if service_list.length > 0
    if values['output'].to_s.match(/html/)
      if values['service'].to_s.match(/[a-z,A-Z]/)
        verbose_output(values, "<h1>Available #{values['service']} clients:</h1>")
      else
        verbose_output(values, "<h1>Available clients:</h1>")
      end
      verbose_output(values, "<table border=\"1\">")
      verbose_output(values, "<tr>")
      verbose_output(values, "<th>Client</th>")
      verbose_output(values, "<th>Service</th>")
      verbose_output(values, "<th>IP</th>")
      verbose_output(values, "<th>MAC</th>")
      verbose_output(values, "</tr>")
    else
      verbose_output(values, "")
      if values['service'].to_s.match(/[a-z,A-Z]/)
        verbose_output(values, "Available #{values['service']} clients:")
      else
        verbose_output(values, "Available clients:")
      end
      verbose_output(values, "")
    end
    service_list.each do |service_name|
      if service_name.match(/#{search_string}|#{service_name}/) and service_name.match(/[a-z,A-Z]/)
        values['repodir'] = values['clientdir']+"/"+values['service']
        if File.directory?(values['repodir']) or File.symlink?(values['repodir'])
          client_list = Dir.entries(values['repodir'])
          client_list.each do |client_name|
            if client_name.match(/[a-z,A-Z,0-9]/)
              values['clientdir']  = values['repodir']+"/"+client_name
              values['ip']  = get_install_ip(values)
              values['mac'] = get_install_mac(values)
              if File.directory?(values['clientdir'])
                if values['output'].to_s.match(/html/)
                  verbose_output(values, "<tr>")
                  verbose_output(values, "<td>#{client_name}</td>")
                  verbose_output(values, "<td>#{service_name}</td>")
                  verbose_output(values, "<td>#{client_ip}</td>")
                  verbose_output(values, "<td>#{client_mac}</td>")
                  verbose_output(values, "</tr>")
                else
                  verbose_output(values, "#{client_name}\t[ service = #{service_name}, ip = #{client_ip}, mac = #{client_mac} ] ")
                end
              end
            end
          end
        end
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_output(values,"</table>")
    end
  end
  verbose_output(values,"")
  return
end

# List appliances

def list_ovas()
  file_list = Dir.entries(values['isodir'])
  verbose_output(values, "")
  verbose_output(values, "Virtual Appliances:")
  verbose_output(values, "")
  file_list.each do |file_name|
    if file_name.match(/ova$/)
      verbose_output(file_name)
    end
  end
  verbose_output(values, "")
end

# Check directory user ownership

def check_dir_owner(values, dir_name, dir_uid)
  message = "Information:\tChecking directory #{dir_name} is owned by user #{dir_uid}"
  verbose_output(values, message)
  if dir_name.match(/^\/$/) or dir_name == ""
    verbose_output(values, "Warning:\tDirectory name not set")
    quit(values)
  end
  test_uid = File.stat(dir_name).uid
  if test_uid.to_i != dir_uid.to_i
    message = "Information:\tChanging ownership of "+dir_name+" to "+dir_uid.to_s
    if dir_name.to_s.match(/^\/etc/)
      command = "sudo chown -R #{dir_uid.to_s} \"#{dir_name}\""
    else
      command = "chown -R #{dir_uid.to_s} \"#{dir_name}\""
    end
    execute_command(values, message, command)
    message = "Information:\tChanging permissions of "+dir_name+" to "+dir_uid.to_s
    if dir_name.to_s.match(/^\/etc/)
      command = "sudo chmod -R u+w \"#{dir_name}\""
    else
      command = "chmod -R u+w \"#{dir_name}\""
    end
    execute_command(values, message, command)
  end
  return
end

# Check directory group read ownership

def check_dir_group(values, dir_name, dir_gid, dir_mode)
  if dir_name.match(/^\/$/) or dir_name == ""
    verbose_output(values, "Warning:\tDirectory name not set")
    quit(values)
  end
  if File.directory?(dir_name)
    test_gid = File.stat(dir_name).gid
    if test_gid.to_i != dir_gid.to_i
      message = "Information:\tChanging group ownership of "+dir_name+" to "+dir_gid.to_s
      if dir_name.to_s.match(/^\/etc/)
        command = "sudo chgrp -R #{dir_gid.to_s} \"#{dir_name}\""
      else
        command = "chgrp -R #{dir_gid.to_s} \"#{dir_name}\""
      end
      execute_command(values, message, command)
      message = "Information:\tChanging group permissions of "+dir_name+" to "+dir_gid.to_s
      if dir_name.to_s.match(/^\/etc/)
        command = "sudo chmod -R g+#{dir_mode} \"#{dir_name}\""
      else
        command = "chmod -R g+#{dir_mode} \"#{dir_name}\""
      end
      execute_command(values, message, command)
    end
  else
    message = "Warning:\tDirectory #{dir_name} does not exist"
    verbose_output(values, message)
  end
  return
end

# Check user member of group

def check_group_member(values, user_name, group_name)
  message = "Information:\tChecking user #{user_name} is a member group #{group_name}"
  if values['host-os-uname'].to_s.match(/Darwin/)
    command = "dscacheutil -q group -a name #{group_name} |grep users"
  else
    command = "getent group #{group_name}"
  end
  output  = execute_command(values, message, command)
  if not output.match(/#{user_name}/)
    message = "Information:\tAdding user #{user_name} to group #{group_name}"
    command = "usermod -a -G #{group_name} #{user_name}"
    execute_command(values, message, command)
  end
  return
end

# Check file permissions

def check_file_perms(values, file_name, file_perms)
  if File.exist?(file_name)
    message = "Information:\tChecking permissions of file #{file_name} and set to #{file_perms}"
    if values['host-os-uname'].to_s.match(/Darwin/)
      command = "stat -f %p #{file_name}"
    else
      command = "stat -c %a #{file_name}"
    end
    test_perms = execute_command(values, message, command)
    if not test_perms.match(/#{file_perms}$/)
      message = "Information:\tSetting permissions of file #{file_name} to #{file_perms}"
      command = "sudo chmod #{file_perms} #{file_name}"
      execute_command(values, message, command)
    end
  else
    message = "Warning:\tFile #{file_name} does not exist"
    verbose_output(values, message)
  end
  return
end

def check_file_mode(values, file_name, file_mode)
  check_file_perms(values, file_name, file_mode)
  return
end

# Check file user ownership

def check_file_owner(values, file_name, file_uid)
  message = "Information:\tChecking file #{file_name} is owned by user #{file_uid}"
  verbose_output(values, message)
  if file_uid.to_s.match(/[a-z]/)
    file_uid = %x[id -u #{file_uid}]
  end
  if File.exist?(file_name)
    test_uid = File.stat(file_name).uid
    if test_uid != file_uid.to_i
      message = "Information:\tChanging ownership of "+file_name+" to "+file_uid.to_s
      if file_name.to_s.match(/^\/etc/)
        command = "sudo chown #{file_uid.to_s} #{file_name}"
      else
        command = "chown #{file_uid.to_s} #{file_name}"
      end
      execute_command(values, message, command)
    end
  else
    message = "Warning:\tFile #{file_name} does not exist"
    verbose_output(values, message)
  end
  return
end

# Get group gid

def get_group_gid(values, group)
  message = "Information:\tGetting GID of "+group
  command = "getent group #{group} |cut -f3 -d:"
  output  = execute_command(values, message, command)
  output  = output.chomp
  return(output)
end

# Check file group ownership

def check_file_group(values, file_name, file_gid)
  message ="Information:\tChecking file #{file_name} is owned by group #{file_gid}"
  verbose_output(values, message)
  if file_gid.to_s.match(/[a-z]/)
    file_gid = get_group_gid(values, file_gid)
  end
  if File.exist?(file_name)
    test_gid = File.stat(file_name).gid
    if test_gid != file_gid.to_i
      message = "Information:\tChanging group ownership of "+file_name+" to "+file_gid.to_s
      command = "chgrp #{file_gid.to_s} \"#{file_name}\""
      execute_command(values, message, command)
    end
  else
    message = "Warning:\tFile #{file_name} does not exist"
    verbose_output(values, message)
  end
  return
end

# Check Python module is installed

def check_python_module_is_installed(install_module)
  exists = false
  module_list = %x[pip listi | awk '{print $1}'].split(/\n/)
  module_list.each do |module_name|
    if module_name.match(/^#{values['model']}$/)
      exists = true
    end
  end
  if exists == false
    message = "Information:\tInstalling python model '#{install_module}'"
    command = "pip install #{install_module}"
    execute_command(values, message, command)
  end
  return
end

# Mask contents of file

def mask_contents_of_file(file_name)
  input  = File.readlines(file_name)
  output = []
  input.each do |line|
    if line.match(/secret_key|access_key/) and not line.match(/\{\{/)
      (param, value) = line.split(/:/)
      value = value.gsub(/[A-Z]|[a-z]|[0-9]/, "X")
      line  = param+":"+value
    end
    output.push(line)
  end
  return output
end

# Print contents of file

def print_contents_of_file(values, message, file_name)
  if values['verbose'] == true or values['output'].to_s.match(/html/)
    if File.exist?(file_name)
      if values['unmasked'] == false
        output = mask_contents_of_file(file_name)
      else
        output = File.readlines(file_name)
      end
      if values['output'].to_s.match(/html/)
        verbose_output(values, "<table border=\"1\">")
        verbose_output(values, "<tr>")
        if message.length > 1
          verbose_output(values, "<th>#{message}</th>")
        else
          verbose_output(values, "<th>#{file_name}</th>")
        end
        verbose_output(values, "<tr>")
        verbose_output(values, "<td>")
        verbose_output(values, "<pre>")
        output.each do |line|
          verbose_output(values, "#{line}")
        end
        verbose_output(values, "</pre>")
        verbose_output(values, "</td>")
        verbose_output(values, "</tr>")
        verbose_output(values, "</table>")
      else
        if values['verbose'] == true
          verbose_output(values, "")
          if message.length > 1
            verbose_output(values, "Information:\t#{message}")
          else
            verbose_output(values, "Information:\tContents of file #{file_name}")
          end
          verbose_output(values, "")
          output.each do |line|
            verbose_output(values, line)
          end
          verbose_output(values, "")
        end
      end
    else
      verbose_output(values, "Warning:\tFile #{file_name} does not exist")
    end
  end
  return
end

# Show output of command

def show_output_of_command(message, output)
  if values['output'].to_s.match(/html/)
    verbose_output(values, "<table border=\"1\">")
    verbose_output(values, "<tr>")
    verbose_output(values, "<th>#{message}</th>")
    verbose_output(values, "<tr>")
    verbose_output(values, "<td>")
    verbose_output(values, "<pre>")
    verbose_output(values, "#{output}")
    verbose_output(values, "</pre>")
    verbose_output(values, "</td>")
    verbose_output(values, "</tr>")
    verbose_output(values, "</table>")
  else
    if values['verbose'] == true
      verbose_output(values, "")
      verbose_output(values, "Information:\t#{message}:")
      verbose_output(values, "")
      verbose_output(values, output)
      verbose_output(values, "")
    end
  end
  return
end

# Check TFTP server

def check_tftp_server(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['host-os-unamer'].match(/11/)
      if !File.exist?("/lib/svc/manifest/network/tftp-udp.xml")
        message = "Checking:\tTFTP entry in /etc/inetd.conf"
        command = "cat /etc/inetd.conf |grep '^tftp' |grep -v '^#'"
        output  = execute_command(values, message, command)
        if not output.match(/tftp/)
          message = "Information:\tCreating TFTP inetd entry"
          command = "echo \"tftp dgram udp wait root /usr/sbin/in.tftpd in.tftpd -s #{values['tftpdir']}\" >> /etc/inetd.conf"
          output  = execute_command(values, message, command)
          message = "Information:\tImporting TFTP inetd entry into service manifest"
          command = "inetconv -i /etc/inet/inetd.conf"
          output  = execute_command(values, message, command)
          message = "Information:\tImporting manifests"
          command = "svcadm restart svc:/system/manifest-import"
        end
      end
    end
  end
  return
end

# Check bootparams entry

def add_bootparams_entry(values)
  found1    = false
  found2    = false
  file_name = "/etc/bootparams"
  boot_info = "root=#{values['hostip']}:#{values['repodir']}/Solaris_#{values['release']}/Tools/Boot install=#{values['hostip']}:#{values['repodir']} boottype=:in sysid_config=#{values['clientdir']} install_config=#{values['clientdir']} rootopts=:rsize=8192"
  if !File.exist?(file_name)
    message = "Information:\tCreating #{file_name}"
    command = "touch #{file_name}"
    execute_command(values, message, command)
    check_file_owner(values, file_name, values['uid'])
    File.open(file_name, "w") { |f| f.write "#{values['mac']} #{values['name']}\n" }
    return
  else
    check_file_owner(values, file_name, values['uid'])
    file = IO.readlines(file_name)
    lines = []
    file.each do |line|
      if !line.match(/^#/)
        if line.match(/^#{values['name']}/)
          if line.match(/#{boot_info}/)
            found1 = true
            lines.push(line)
          else
            new_line = "#{values['name']} #{boot_info}\n"
            lines.push(new_line)
          end
        else
          lines.push(line)
        end
        if line.match(/^#{values['ip']}/)
          if line.match(/#{boot_info}/)
            found2 = true
            lines.push(line)
          else
            new_line = "#{values['ip']} #{boot_info}\n"
            lines.push(new_line)
          end
        else
          lines.push(line)
        end
      else
        lines.push(line)
      end
    end
  end
  if found1 == false or found2 == false
    File.open(file_name, "w") do |file|
      lines.each { |line| file.puts(line) }
    end
    if values['host-os-unamer'].to_s.match(/11/)
      message = "Information:\tRestarting bootparams service"
      command = "svcadm restart svc:/network/rpc/bootparams:default"
      execute_command(values, message, command)
    end
  end
  return
end

# Add NFS export

def add_nfs_export(values, export_name, export_dir)
  network_address = values['publisherhost'].split(/\./)[0..2].join(".")+".0"
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['host-os-unamer'].match(/11/)
      message = "Enabling:\tNFS share on "+export_dir
      command = "zfs set sharenfs=on #{values['zpoolname']}#{export_dir}"
      output  = execute_command(values, message, command)
      message = "Information:\tSetting NFS access rights on "+export_dir
      command = "zfs set share=name=#{export_name},path=#{export_dir},prot=nfs,anon=0,sec=sys,ro=@#{network_address}/24 #{values['zpoolname']}#{export_dir}"
      output  = execute_command(values, message, command)
    else
      dfs_file = "/etc/dfs/dfstab"
      message  = "Checking:\tCurrent NFS exports for "+export_dir
      command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
      output   = execute_command(values, message, command)
      if not output.match(/#{export_dir}/)
        backup_file(values, dfs_file)
        export  = "share -F nfs -o ro=@#{network_address},anon=0 #{export_dir}"
        message = "Adding:\tNFS export for "+export_dir
        command = "echo '#{export}' >> #{dfs_file}"
        execute_command(values, message, command)
        message = "Refreshing:\tNFS exports"
        command = "shareall -F nfs"
        execute_command(values, message, command)
      end
    end
  else
    dfs_file = "/etc/exports"
    message  = "Checking:\tCurrent NFS exports for "+export_dir
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(values, message, command)
    if not output.match(/#{export_dir}/)
      if values['host-os-uname'].to_s.match(/Darwin/)
        export = "#{export_dir} -alldirs -maproot=root -network #{network_address} -mask #{values['netmask']}"
      else
        export = "#{export_dir} #{network_address}/24(ro,no_root_squash,async,no_subtree_check)"
      end
      message = "Adding:\tNFS export for "+export_dir
      command = "echo '#{export}' >> #{dfs_file}"
      execute_command(values, message, command)
      message = "Refreshing:\tNFS exports"
      if values['host-os-uname'].to_s.match(/Darwin/)
        command = "nfsd stop ; nfsd start"
      else
        command = "/sbin/exportfs -a"
      end
      execute_command(values, message, command)
    end
  end
  return
end

# Remove NFS export

def remove_nfs_export(export_dir)
  if values['host-os-uname'].to_s.match(/SunOS/)
    zfs_test = %x[zfs list |grep #{export_dir}].chomp
    if zfs_test.match(/#{export_dir}/)
      message = "Disabling:\tNFS share on "+export_dir
      command = "zfs set sharenfs=off #{values['zpoolname']}#{export_dir}"
      execute_command(values, message, command)
    else
      if values['verbose'] == true
        verbose_output(values, "Information:\tZFS filesystem #{values['zpoolname']}#{export_dir} does not exist")
      end
    end
  else
    dfs_file = "/etc/exports"
    message  = "Checking:\tCurrent NFS exports for "+export_dir
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(values, message, command)
    if output.match(/#{export_dir}/)
      backup_file(values, dfs_file)
      tmp_file = "/tmp/dfs_file"
      message  = "Removing:\tExport "+export_dir
      command  = "cat #{dfs_file} |grep -v '#{export_dir}' > #{tmp_file} ; cat #{tmp_file} > #{dfs_file} ; rm #{tmp_file}"
      execute_command(values, message, command)
      if values['host-os-uname'].to_s.match(/Darwin/)
        message  = "Restarting:\tNFS daemons"
        command  = "nfsd stop ; nfsd start"
        execute_command(values, message, command)
      else
        message  = "Restarting:\tNFS daemons"
        command  = "service nfsd restart"
        execute_command(values, message, command)
      end
    end
  end
  return
end

# Check we are running on the right architecture

def check_same_arch(values)
  if not values['host-os-unamep'].to_s.match(/#{values['arch']}/)
    verbose_output(values, "Warning:\tSystem and Zone Architecture do not match")
    quit(values)
  end
  return
end

# Delete file

def delete_file(values, file_name)
  if File.exist?(file_name)
    message = "Removing:\tFile "+file_name
    command = "rm #{file_name}"
    execute_command(values, message, command)
  end
end

# Get root password crypt

def get_root_password_crypt(values)
  password = values['q_struct']['root_password'].value
  result   = get_password_crypt(password)
  return result
end

# Get account password crypt

def get_admin_password_crypt(values)
  password = values['q_struct']['admin_password'].value
  result   = get_password_crypt(password)
  return result
end

# Check SSH keys

def check_ssh_keys(values)
  ssh_key_file = values['sshkeyfile'].to_s
  ssh_key_type = values['sshkeytype'].to_s
  ssh_key_bits = values['sshkeybits'].to_s
  if not File.exist?(ssh_key_file)
    if values['verbose'] == true
      verbose_output(values, "Generating:\tPublic SSH key file #{ssh_key_file}")
    end
    command = "ssh-keygen -t #{ssh_key_type} -b #{ssh_key_bits} -f #{ssh_key_file}"
    system(command)
  end
  return
end

# Check IPS tools installed on OS other than Solaris

def check_ips(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    check_osx_ips(values)
  end
  return
end

# Check Apache enabled

def check_apache_config(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    service = "apache"
    check_osx_service_is_enabled(service)
  end
  return
end

# Check DHCPd config

def check_dhcpd_config(values)
  network_address   = values['hostip'].to_s.split(/\./)[0..2].join(".")+".0"
  broadcast_address = values['hostip'].to_s.split(/\./)[0..2].join(".")+".255"
  gateway_address   = values['hostip'].to_s.split(/\./)[0..2].join(".")+".1"
  output = ""
  if File.exist?(values['dhcpdfile'])
    message = "Checking:\tDHCPd config for subnet entry"
    command = "cat #{values['dhcpdfile']} | grep -v '^#' |grep 'subnet #{network_address}'"
    output  = execute_command(values, message, command)
  end
  if !output.match(/subnet/) && !output.match(/#{network_address}/)
    tmp_file    = "/tmp/dhcpd"
    backup_file = values['dhcpdfile']+values['backupsuffix']
    file = File.open(tmp_file, "w")
    file.write("\n")
    if values['host-os-uname'].to_s.match(/SunOS|Linux/)
      file.write("default-lease-time 900;\n")
      file.write("max-lease-time 86400;\n")
    end
    if values['host-os-uname'].to_s.match(/Linux/)
      file.write("option space pxelinux;\n")
      file.write("option pxelinux.magic code 208 = string;\n")
      file.write("option pxelinux.configfile code 209 = text;\n")
      file.write("option pxelinux.pathprefix code 210 = text;\n")
      file.write("option pxelinux.reboottime code 211 = unsigned integer 32;\n")
      file.write("option architecture-type code 93 = unsigned integer 16;\n")
    end
    file.write("\n")
    if values['host-os-uname'].to_s.match(/SunOS/)
      file.write("authoritative;\n")
      file.write("\n")
      file.write("option arch code 93 = unsigned integer 16;\n")
      file.write("option grubmenu code 150 = text;\n")
      file.write("\n")
      file.write("log-facility local7;\n")
      file.write("\n")
      file.write("class \"PXEBoot\" {\n")
      file.write("  match if (substring(option vendor-class-identifier, 0, 9) = \"PXEClient\");\n")
      file.write("  if option arch = 00:00 {\n")
      file.write("    filename \"default-i386/boot/grub/pxegrub2\";\n")
      file.write("  } else if option arch = 00:07 {\n")
      file.write("    filename \"default-i386/boot/grub/grub2netx64.efi\";\n")
      file.write("  }\n")
      file.write("}\n")
      file.write("\n")
      file.write("class \"SPARC\" {\n")
      file.write("  match if not (substring(option vendor-class-identifier, 0, 9) = \"PXEClient\");\n")
      file.write("  filename \"http://#{values['publisherhost'].to_s.strip}:5555/cgi-bin/wanboot-cgi\";\n")
      file.write("}\n")
      file.write("\n")
      file.write("allow booting;\n")
      file.write("allow bootp;\n")
    end
    if values['host-os-uname'].to_s.match(/Linux/)
      file.write("class \"pxeclients\" {\n")
      file.write("  match if substring (option vendor-class-identifier, 0, 9) = \"PXEClient\";\n")
      file.write("  if option architecture-type = 00:07 {\n")
      file.write("    filename \"shimx64.efi\";\n")
      file.write("  } else {\n")
      file.write("    filename \"pxelinux.0\";\n")
      file.write("  }\n")
      file.write("}\n")
    end
    file.write("\n")
    if values['host-os-uname'].to_s.match(/SunOS|Linux/)
      file.write("subnet #{network_address} netmask #{values['netmask']} {\n")
      if values['verbose'] == true

      end
      if values['dhcpdrange'] == values['empty']
        values['dhcpdrange'] = network_address.split(".")[0..-2].join(".")+".200"+" "+network_address.split(".")[0..-2].join(".")+".250"
      end
      file.write("  range #{values['dhcpdrange']};\n")
      file.write("  option broadcast-address #{broadcast_address};\n")
      file.write("  option routers #{gateway_address};\n")
      file.write("  next-server #{values['hostip']};\n")
      file.write("}\n")
    end
    file.write("\n")
    file.close
    if File.exist?(values['dhcpdfile'])
      message = "Information:\tArchiving DHCPd configuration file "+values['dhcpdfile']+" to "+backup_file
      command = "cp #{values['dhcpdfile']} #{backup_file}"
      execute_command(values, message, command)
    end
    message = "Information:\tCreating DHCPd configuration file "+values['dhcpdfile']
    command = "cp #{tmp_file} #{values['dhcpdfile']}"
    execute_command(values, message, command)
    if values['host-os-uname'].to_s.match(/SunOS/) and values['host-os-unamer'].match(/5\.11/)
      message = "Information:\tSetting DHCPd listening interface to "+values['nic']
      command = "svccfg -s svc:/network/dhcp/server:ipv4 setprop config/listen_ifnames = astring: #{values['nic']}"
      execute_command(values, message, command)
      message = "Information:\tRefreshing DHCPd service"
      command = "svcadm refresh svc:/network/dhcp/server:ipv4"
      execute_command(values, message, command)
    end
    restart_dhcpd(values)
  end
  return
end

# Check firewall is enabled

def check_rhel_service(values, service)
  message = "Information:\tChecking "+service+" is installed"
  command = "service #{service} status |grep dead"
  output  = execute_command(values, message, command)
  if output.match(/dead/)
    message = "Enabling:\t"+service
    if values['host-os-unamer'].match(/^7/)
      command = "systemctl enable #{service}.service"
      command = "systemctl start #{service}.service"
    else
      command = "chkconfig --level 345 #{service} on"
    end
    execute_command(values, message, command)
  end
  return
end

# Check service is enabled

def check_rhel_firewall(values, service, port_info)
  if values['host-os-unamer'].match(/^7/)
    message = "Information:\tChecking firewall configuration for "+service
    command = "firewall-cmd --list-services |grep #{service}"
    output  = execute_command(values, message, command)
    if not output.match(/#{service}/)
      message = "Information:\tAdding firewall rule for "+service
      command = "firewall-cmd --add-service=#{service} --permanent"
      execute_command(values, message, command)
    end
    if port_info.match(/[0-9]/)
      message = "Information:\tChecking firewall configuration for "+port_info
      command = "firewall-cmd --list-all |grep #{port_info}"
      output  = execute_command(values, message, command)
      if not output.match(/#{port_info}/)
        message = "Information:\tAdding firewall rule for "+port_info
        command = "firewall-cmd --zone=public --add-port=#{port_info} --permanent"
        execute_command(values, message, command)
      end
    end
  else
    if port_info.match(/[0-9]/)
      (port_no, protocol) = port_info.split(/\//)
      message = "Information:\tChecking firewall configuration for "+service+" on "+port_info
      command = "iptables --list-rules |grep #{protocol} |grep #{port_no}"
      output  = execute_command(values, message, command)
      if not output.match(/#{protocol}/)
        message = "Information:\tAdding firewall rule for "+service
        command = "iptables -I INPUT -p #{protocol} --dport #{port_no} -j ACCEPT ; iptables save"
        execute_command(values, message, command)
      end
    end
  end
  return
end

# Check httpd enabled on Centos / Redhat

def check_yum_xinetd(values)
  check_rhel_package(values, "xinetd")
  check_rhel_firewall(values, "xinetd", "")
  check_rhel_service(values, "xinetd")
  return
end

# Check TFTPd enabled on CentOS / RedHat

def check_yum_tftpd(values)
  check_dir_exists(values, values['tftpdir'])
  check_rhel_package(values, "tftp-server")
  check_rhel_firewall(values, "tftp", "")
  check_rhel_service(values, "tftp")
  return
end

# Check DHCPd enabled on CentOS / RedHat

def check_yum_dhcpd(values)
  check_rhel_package(values, "dhcp")
  check_rhel_firewall(values, "dhcp", "69/udp")
  check_rhel_service(values, "dhcpd")
  return
end

# Check httpd enabled on Centos / Redhat

def check_yum_httpd()
  check_rhel_package(values, "httpd")
  check_rhel_firewall(values, "http", "80/tcp")
  check_rhel_service(values, "httpd")
  return
end

# Check Ubuntu / Debian firewall

def check_apt_firewall(values, service, port_info)
  if File.exist?("/usr/bin/ufw")
    message = "Information:\tChecking "+service+" is allowed by firewall"
    command = "ufw status |grep #{service} |grep ALLOW"
    output = execute_command(values, message, command)
    if not output.match(/ALLOW/)
      message = "Information:\tAdding "+service+" to firewall allow rules"
      command = "ufw allow #{service} #{port_info}"
      execute_command(values, message, command)
    end
  end
  return
end

# Check Ubuntu / Debian service

def check_apt_service(values, service)
  message = "Information:\tChecking "+service+" is installed"
  command = "service #{service} status |grep dead"
  output  = execute_command(values, message, command)
  if output.match(/dead/)
    message = "Information:\tEnabling: "+service
    command = "systemctl enable #{service}.service"
    execute_command(values, message, command)
    message = "Information:\tStarting: "+service
    command = "systemctl start #{service}.service"
    execute_command(values, message, command)
  end
  return
end

# Check TFTPd enabled on Debian / Ubuntu

def check_apt_tftpd(values)
  check_dir_exists(values, values['tftpdir'])
  check_apt_package(values, "tftpd-hpa")
  check_apt_firewall(values, "tftp", "")
  check_apt_service(values, "tftp")
  return
end

# Check DHCPd enabled on Ubuntu / Debian

def check_apt_dhcpd(values)
  check_apt_package(values, "isc-dhcp-server")
  check_apt_firewall(values, "dhcp", "69/udp")
  check_apt_service(values, "isc-dhcp-server")
  return
end

# Check httpd enabled on Ubunut / Debian

def check_apt_httpd(values)
  check_apt_package(values, "httpd")
  check_apt_firewall(values, "http", "80/tcp")
  check_apt_service(values, "httpd")
  return
end

# Restart a service

def restart_service(values, service)
  refresh_service(values, service)
  return
end

# Restart xinetd

def restart_xinetd(values)
  service = "xinetd"
  service = get_service_name(values, service)
  refresh_service(values, service)
  return
end

# Restart tftpd

def restart_tftpd(values)
  if values['host-os-uname'].to_s.match(/Linux/)
    service = "tftpd-hpa"
    refresh_service(values, service)
  else
    service = "tftp"
    service = get_service_name(values, service)
    refresh_service(values, service)
  end
  return
end

# Restart forewalld

def restart_firewalld(values)
  service = "firewalld"
  service = get_service_name(values, service)
  refresh_service(values, service)
  return
end

# Check tftpd config for Linux(turn on in xinetd config file /etc/xinetd.d/tftp)

def check_tftpd_config(values)
  if values['host-os-uname'].to_s.match(/Linux/)
    tmp_file   = "/tmp/tftp"
    pxelinux_file = "/usr/lib/PXELINUX/pxelinux.0"
    if !File.exist?(pxelinux_file)
      values = install_package(values, "pxelinux")
      values = install_package(values, "syslinux")
    end
    syslinux_file = "/usr/lib/syslinux/modules/bios/ldlinux.c32"
    pxelinux_dir  = values['tftpdir']
    pxelinux_tftp = pxelinux_dir+"/pxelinux.0"
    syslinux_tftp = pxelinux_dir+"/ldlinux.c32"
    if values['verbose'] == true
      verbose_output(values, "Information:\tChecking PXE directory")
    end
    check_dir_exists(values, pxelinux_dir)
    check_dir_owner(values, pxelinux_dir, values['uid'])
    if !File.exist?(pxelinux_tftp)
      if !File.exist?(pxelinux_file)
        values = install_package(values, "pxelinux")
      end
      if File.exist?(pxelinux_file)
        message = "Information:\tCopying '#{pxelinux_file}' to '#{pxelinux_tftp}'"
        command = "cp #{pxelinux_file} #{pxelinux_tftp}"
        execute_command(values, message, command)
      else
        verbose_output(values, "Warning:\tTFTP boot file pxelinux.0 does not exist")
      end
    end
    if !File.exist?(syslinux_tftp)
      if !File.exist?(syslinux_tftp)
        values = install_package(values, "syslinux")
      end
      if File.exist?(syslinux_file)
        message = "Information:\tCopying '#{syslinux_file}' to '#{syslinux_tftp}'"
        command = "cp #{syslinux_file} #{syslinux_tftp}"
        execute_command(values, message, command)
      else
        verbose_output(values, "Warning:\tTFTP boot file ldlinux.c32 does not exist")
      end
    end
    if values['host-os-unamea'].match(/Ubuntu|Debian/)
      check_apt_tftpd(values)
    else
      check_yum_tftpd(values)
    end
    check_dir_exists(values, values['tftpdir'])
    if values['host-os-unamea'].match(/RedHat|CentOS/)
      if Integer(values['host-os-version']) > 6
        message = "Checking SELinux tftp permissions"
        command = "getsebool -a | grep tftp |grep home"
        output  = execute_command(values, message, command)
        if output.match(/off/)
          message = "Information:\ySetting SELinux tftp permissions"
          command = "setsebool -P tftp_home_dir 1"
          execute_command(values, message, command)
        end
        restart_firewalld(values)
      end
    end
  end
  restart_tftpd(values)
  return
end

# Check tftpd directory

def check_tftpd_dir(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    old_tftp_dir = "/tftpboot"
    if values['verbose'] == true
      verbose_output(values, "Information:\tChecking TFTP directory")
    end
    check_dir_exists(values, values['tftpdir'])
    check_dir_owner(values, values['tftpdir'], values['uid'])
    if not File.symlink?(old_tftp_dir)
      message = "Information:\tSymlinking #{old_tftp_dir} to #{values['tftpdir']}}"
      command = "ln -s #{values['tftpdir']} #{old_tftp_dir}"
      output  = execute_command(values, message, command)
#      File.symlink(values['tftpdir'], old_tftp_dir)
    end
    message = "Checking:\tTFTPd service boot directory configuration"
    command = "svcprop -p inetd_start/exec svc:network/tftp/udp"
    output  = execute_command(values, message, command)
    if not output.match(/netboot/)
      message = "Information:\tSetting TFTPd boot directory to "+values['tftpdir']
      command = "svccfg -s svc:network/tftp/udp setprop inetd_start/exec = astring: \"/usr/sbin/in.tftpd\\ -s\\ /etc/netboot\""
      execute_command(values, message, command)
    end
  end
  return
end

# Check network device exists

def check_network_device_exists(values)
  exists  = false
  net_dev = values['network'].to_s
  message = "Information:\tChecking network device #{net_dev} exists"
  command = "ifconfig #{net_dev} |grep ether"
  output  = execute_command(values, message, command)
  if output.match(/ether/)
    exists = true
  end
  return exists
end

# Check network bridge exists

def check_network_bridge_exists(values)
  exists  = false
  net_dev = values['bridge'].to_s
  message = "Information:\tChecking network device #{net_dev} exists"
  command = "ifconfig -a |grep #{net_dev}:"
  output  = execute_command(values, message, command)
  if output.match(/#{net_dev}/)
    exists = true
  end
  return exists
end

# Check NAT

def check_nat(values, gw_if_name, if_name)
  case values['host-os-uname'].to_s
  when /Darwin/
    if values['host-os-unamer'].split(".")[0].to_i < 14
      check_osx_nat(gw_if_name, if_name)
    else
      check_osx_pfctl(values, gw_if_name, if_name)
    end
  when /Linux/
    check_linux_nat(values, gw_if_name, if_name)
  end
  return
end

# Check tftpd

def check_tftpd(values)
  check_tftpd_dir(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    enable_service(values, "svc:/network/tftp/udp:default")
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    check_osx_tftpd()
  end
  return
end

# Get client IP

def get_install_ip(values)
  values['ip']  = ""
  hosts_file = "/etc/hosts"
  if File.exist?(hosts_file) or File.symlink?(hosts_file)
    file_array = IO.readlines(hosts_file)
    file_array.each do |line|
      line = line.chomp
      if line.match(/#{values['name']}\s+/)
        values['ip'] = line.split(/\s+/)[0]
      end
    end
  end
  return values['ip']
end

# Get client MAC

def get_install_mac(values)
  mac_address  = ""
  found_client = 0
  if File.exist?(values['dhcpdfile']) or File.symlink?(values['dhcpdfile'])
    file_array = IO.readlines(values['dhcpdfile'])
    file_array.each do |line|
      line = line.chomp
      if line.match(/#{values['name']} /)
        found_client = true
      end
      if line.match(/hardware ethernet/) and found_client == true
        mac_address = line.split(/\s+/)[3].gsub(/\;/, "")
        return mac_address
      end
    end
  end
  return mac_address
end

# Check dnsmasq

def check_dnsmasq(values)
  if values['host-os-uname'].to_s.match(/Linux/)
    check_linux_dnsmasq(values)
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    check_osx_dnsmasq(values)
  end
  return
end

# Add dnsmasq entry

def add_dnsmasq_entry(values)
  check_dnsmasq(values)
  config_file = "/etc/dnsmasq.conf"
  hosts_file  = "/etc/hosts." + values['scriptname'].to_s
  message = "Checking:\tChecking DNSmasq config file for hosts."+values['scriptname'].to_s
  command = "cat #{config_file} |grep -v '^#' |grep '#{values['scriptname'].to_s}' |grep 'addn-hosts'"
  output  = execute_command(values, message, command)
  if not output.match(/#{values['scriptname'].to_s}/)
    backup_file(values, config_file)
    message = "Information:\tAdding hosts file "+hosts_file+" to "+config_file
    command = "echo \"addn-hosts=#{hosts_file}\" >> #{config_file}"
    output  = execute_command(values, message, command)
  end
  message = "Checking:\tHosts file #{hosts_file}for #{values['name']}"
  command = "cat #{hosts_file} |grep -v '^#' |grep '#{values['name']}' |grep '#{values['ip']}'"
  output  = execute_command(values, message, command)
  if not output.match(/#{values['name'].to_s}/)
    backup_file(values, hosts_file)
    message = "Adding:\t\tHost "+values['name'].to_s+" to "+hosts_file
    command = "echo \"#{values['ip']}\\t#{values['name']}.local\\t#{values['name']}\\t# #{values['adminuser']}\" >> #{hosts_file}"
    output  = execute_command(values, message, command)
    if values['host-os-uname'].to_s.match(/Darwin/)
      pfile   = "/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist"
      if File.exist?(pfile)
        service = "dnsmasq"
        service = get_service_name(values, service)
        refresh_service(option, service)
      end
    else
      service = "dnsmasq"
      service = get_service_name(values, service)
      refresh_service(values, service)
    end
  end
  return
end

# Add hosts entry

def add_hosts_entry(values)
  hosts_file = "/etc/hosts"
  message    = "Checking:\tHosts file for "+values['name']
  command    = "cat #{hosts_file} |grep -v '^#' |grep '#{values['name']}' |grep '#{values['ip']}'"
  output     = execute_command(values, message, command)
  if not output.match(/#{values['name']}/)
    backup_file(values, hosts_file)
    message = "Adding:\t\tHost "+values['name']+" to "+hosts_file
    command = "echo \"#{values['ip']}\\t#{values['name']}.local\\t#{values['name']}\\t# #{values['adminuser']}\" >> #{hosts_file}"
    output  = execute_command(values, message, command)
  end
  if values['dnsmasq'] == true
    add_dnsmasq_entry(values)
  end
  return
end

# Remove hosts entry

def remove_hosts_entry(values)
  hosts_file = "/etc/hosts"
  remove_hosts_file_entry(values, hosts_file)
  if values['dnsmasq'] == true
    hosts_file = "/etc/hosts."+values['scriptname'].to_s
    remove_hosts_file_entry(values, hosts_file)
  end
  return
end

def remove_hosts_file_entry(values, hosts_file)
  tmp_file = "/tmp/hosts"
  message  = "Checking:\tHosts file for "+values['name']
  if values['ip'].to_s.match(/[0-9]/)
    command = "cat #{hosts_file} |grep -v '^#' |grep '#{values['name']}' |grep '#{values['ip']}'"
  else
    command = "cat #{hosts_file} |grep -v '^#' |grep '#{values['name']}'"
  end
  output = execute_command(values, message, command)
  copy   = []
  if output.match(/#{values['name']}/)
    file_info=IO.readlines(hosts_file)
    file_info.each do |line|
      if not line.match(/#{values['name']}/)
        if values['ip'].to_s.match(/[0-9]/)
          if not line.match(/^#{values['ip']}/)
            copy.push(line)
          end
        else
          copy.push(line)
        end
      end
    end
    File.open(tmp_file, "w") {|file| file.puts copy}
    message = "Updating:\tHosts file "+hosts_file
    if values['host-os-uname'].to_s.match(/Darwin/)
      command = "sudo sh -c 'cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}'"
    else
      command = "cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}"
    end
    execute_command(values, message, command)
  end
  return
end

# Add host to DHCP config

def add_dhcp_client(values)
  if not values['mac'].to_s.match(/:/)
    values['mac'] = values['mac'][0..1]+":"+values['mac'][2..3]+":"+values['mac'][4..5]+":"+values['mac'][6..7]+":"+values['mac'][8..9]+":"+values['mac'][10..11]
  end
  tmp_file = "/tmp/dhcp_"+values['name']
  if not values['arch'].to_s.match(/sparc/)
    tftp_pxe_file = values['mac'].gsub(/:/, "")
    tftp_pxe_file = tftp_pxe_file.upcase
    if values['service'].to_s.match(/sol/)
      suffix = ".bios"
    else
      if values['service'].to_s.match(/bsd/)
        suffix = ".pxeboot"
      else
        suffix = ".pxelinux"
      end
    end
    tftp_pxe_file = "01"+tftp_pxe_file+suffix
  else
    tftp_pxe_file = "http://#{values['publisherhost'].to_s.strip}:5555/cgi-bin/wanboot-cgi"
  end
  message = "Checking:\fIf DHCPd configuration contains "+values['name']
  command = "cat #{values['dhcpdfile']} | grep '#{values['name']}'"
  output  = execute_command(values, message, command)
  if not output.match(/#{values['name']}/)
    backup_file(values, values['dhcpdfile'])
    file = File.open(tmp_file, "w")
    file_info=IO.readlines(values['dhcpdfile'])
    file_info.each do |line|
      file.write(line)
    end
    file.write("\n")
    file.write("host #{values['name']} {\n")
    file.write("  fixed-address #{values['ip']};\n")
    file.write("  hardware ethernet #{values['mac']};\n")
    if values['service'].to_s.match(/[a-z,A-Z]/)
      #if values['biostype'].to_s.match(/efi/)
      #  if values['service'].to_s.match(/vmware|esx|vsphere/)
      #    file.write("  filename \"#{values['service'].to_s}/bootx64.efi\";\n")
      #  else
      #    file.write("  filename \"shimx64.efi\";\n")
      #  end
      #else
        file.write("  filename \"#{tftp_pxe_file}\";\n")
      #end
    end
    file.write("}\n")
    file.close
    message = "Updating:\tDHCPd file "+values['dhcpdfile']
    command = "cp #{tmp_file} #{values['dhcpdfile']} ; rm #{tmp_file}"
    execute_command(values, message, command)
    restart_dhcpd(values)
  end
  check_dhcpd(values)
  check_tftpd(values)
  return
end

# Remove host from DHCP config

def remove_dhcp_client(values)
  found     = 0
  copy      = []
  if !File.exist?(values['dhcpdfile'])
    if values['verbose'] == true
      verbose_output(values, "Warning:\tFile #{values['dhcpdfile']} does not exist")
    end
  else
    check_file_owner(values, values['dhcpdfile'], values['uid'])
    file_info = IO.readlines(values['dhcpdfile'])
    file_info.each do |line|
      if line.match(/^host #{values['name']}/)
        found = true
      end
      if found == false
        copy.push(line)
      end
      if found == true and line.match(/\}/)
        found=0
      end
    end
    File.open(values['dhcpdfile'], "w") {|file| file.puts copy}
  end
  return
end

# Backup file

def backup_file(values, file_name)
  date_string = get_date_string(values)
  backup_file = File.basename(file_name)+"."+date_string
  backup_file = values['backupdir'].to_s+"/"+backup_file
  message     = "Archiving:\tFile "+file_name+" to "+backup_file
  command     = "cp #{file_name} #{backup_file}"
  execute_command(values, message, command)
  return
end

# Wget a file

def wget_file(values, file_url, file_name)
  if values['download'] == true
    wget_test = %[which wget].chomp
    if wget_test.match(/bin/)
      command = "wget #{file_url} -O #{file_name}"
    else
      command = "curl -o #{file_name } #{file_url}"
    end
    file_dir = File.dirname(file_name)
    check_dir_exists(values, file_dir)
    message  = "Fetching:\tURL "+file_url+" to "+file_name
    execute_command(values, message, command)
  end
  return
end

# Add to ethers file

def add_to_ethers_file(values)
  found     = false
  file_name = "/etc/ethers"
  if !File.exist?(file_name)
    message = "Information:\tCreating #{file_name}"
    command = "touch #{file_name}"
    execute_command(values, message, command)
    check_file_owner(values, file_name, values['uid'])
    File.open(file_name, "w") { |f| f.write "#{values['mac']} #{values['name']}\n" }
    return
  else
    check_file_owner(values, file_name, values['uid'])
    file = IO.readlines(file_name)
    lines = []
    file.each do |line|
      if !line.match(/^#/)
        if line.match(/#{values['name']}/)
          if line.match(/#{values['mac']}/)
            found = true
            lines.push(line)
          else
            new_line = "#{values['name']} #{values['mac']}\n"
            lines.push(new_line)
          end
        else
          lines.push(line)
        end
      else
        lines.push(line)
      end
    end
  end
  if found == false
    File.open(file_name, "w") do |file|
      lines.each { |line| file.puts(line) }
    end
  end
  return
end

# Find client MAC

def get_install_mac(values)
  ethers_file = "/etc/ethers"
  output      = ""
  found       = 0
  if File.exist?(ethers_file)
    message = "Checking:\tFile "+ethers_file+" for "+values['name']+" MAC address"
    command = "cat #{ethers_file} |grep '#{values['name']} '|awk \"{print \\$2}\""
    mac_add = execute_command(values, message, command)
    mac_add = mac_add.chomp
  end
  if not output.match(/[0-9]/)
    file = IO.readlines(values['dhcpdfile'])
    file.each do |line|
      line = line.chomp
      if line.match(/#{values['name']}/)
        found = 1
      end
      if found == true
        if line.match(/ethernet/)
          mac_add = line.split(/ ethernet /)[1]
          mac_add = values['mac'].gsub(/\;/, "")
          return mac_add
        end
      end
    end
  end
  return mac_add
end

# Check if a directory exists
# If not create it

def check_dir_exists(values, dir_name)
  output = ""
  dir_name = dir_name.to_s
  if !File.directory?(dir_name) && !File.symlink?(dir_name)
    if dir_name.match(/[a-z]|[A-Z]/)
      message = "Information:\tCreating: "+dir_name
      if dir_name.match(/^\/etc/)
        command = "sudo mkdir -p \"#{dir_name}\""
      else
        command = "mkdir -p \"#{dir_name}\""
      end
      output  = execute_command(values, message, command)
    end
  end
  return output
end

# Check a filesystem / directory exists

def check_fs_exists(values, dir_name)
  output = ""
  if values['host-os-uname'].to_s.match(/SunOS/)
    output = check_zfs_fs_exists(values, dir_name)
  else
    check_dir_exists(values, dir_name)
  end
  return output
end

# Check if a ZFS filesystem exists
# If not create it

def check_zfs_fs_exists(values, dir_name)
  output = ""
  if not File.directory?(dir_name)
    if values['host-os-uname'].to_s.match(/SunOS/)
      if dir_name.match(/clients/)
        root_dir = dir_name.split(/\//)[0..-2].join("/")
        if not File.directory?(root_dir)
          check_zfs_fs_exists(root_dir)
        end
      end
      if dir_name.match(/ldoms|zones/)
        zfs_name = values['dpool']+dir_name
      else
        zfs_name = values['zpoolname']+dir_name
      end
      if dir_name.match(/vmware_|openbsd_|coreos_/) or values['host-os-unamer'].to_i > 10
        values['service'] = File.basename(dir_name)
        mount_dir    = values['tftpdir']+"/"+values['service']
        if not File.directory?(mount_dir)
          Dir.mkdir(mount_dir)
        end
      else
        mount_dir = dir_name
      end
      message = "Information:\tCreating "+dir_name+" with mount point "+mount_dir
      command = "zfs create -o mountpoint=#{mount_dir} #{zfs_name}"
      execute_command(values, message, command)
      if dir_name.match(/vmware_|openbsd_|coreos_/) or values['host-os-unamer'].to_i > 10
        message = "Information:\tSymlinking "+mount_dir+" to "+dir_name
        command = "ln -s #{mount_dir} #{dir_name}"
        execute_command(values, message, command)
      end
    else
      check_dir_exists(values, dir_name)
    end
  end
  return output
end

# Destroy a ZFS filesystem

def destroy_zfs_fs(values, dir_name)
  output = ""
  zfs_list = %x[zfs list |grep -v NAME |awk '{print $5}' |grep "^#{dir_name}$'].chomp
  if zfs_list.match(/#{dir_name}/)
    zfs_name = %x[zfs list |grep -v NAME |grep "#{dir_name}$" |awk '{print $1}'].chomp
    if values['yes'] == true
      if File.directory?(dir_name)
        if dir_name.match(/netboot/)
          service = "svc:/network/tftp/udp:default"
          disable_service(service)
        end
        message = "Warning:\tDestroying "+dir_name
        command = "zfs destroy -r -f #{zfs_name}"
        output  = execute_command(values, message, command)
        if dir_name.match(/netboot/)
          enable_service(service)
        end
      end
    end
  end
  if File.directory?(dir_name)
    Dir.rmdir(dir_name)
  end
  return output
end

# Routine to execute command
# Prints command if verbose switch is on
# Does not execute cerver/client import/create operations in test mode

def execute_command(values, message, command)
  if !command
    verbose_output(values, "Warning:\tEmpty command")
    return
  end
  if command.match(/prlctl/) and !values['host-os-uname'].to_s.match(/Darwin/)
    return
  else
    if command.match(/prlctl/)
      parallels_test = %x[which prlctl].chomp
      if not parallels_test.match(/prlctl/)
        return
      end
    end
  end
  output  = ""
  execute = 0
  if values['verbose'] == true
    if message.match(/[a-z,A-Z,0-9]/)
      verbose_output(values, message)
    end
  end
  if values['test'] == true
    if not command.match(/create|id|groups|update|import|delete|svccfg|rsync|cp|touch|svcadm|VBoxManage|vboxmanage|vmrun|docker/)
      execute = true
    end
  else
    execute = true
  end
  if execute == true
    if values['uid'] != 0
      if !command.match(/brew |sw_vers|id |groups|hg|pip|VBoxManage|vboxmanage|netstat|df|vmrun|noVNC|docker|packer|ansible-playbook|^ls|multipass/) && !values['host-os-uname'].to_s.match(/NT/)
        if values['sudo'] == true
          if command.match(/virsh/)
            if values['host-os-uname'].to_s.match(/Linux/)
              command = "sudo sh -c '"+command+"'"
            end
          else
            command = "sudo sh -c '"+command+"'"
          end
        else
          if command.match(/ufw|chown|chmod/)
            command = "sudo sh -c '"+command+"'"
          else
            if command.match(/ifconfig/) && command.match(/up$/)
              command = "sudo sh -c '"+command+"'"
            end
          end
        end
      else
        if command.match(/ifconfig/) && command.match(/up$/)
          command = "sudo sh -c '"+command+"'"
        end
        if command.match(/virt-install/)
          command = "sudo sh -c '"+command+"'"
        end
        if command.match(/snap/)
          if !File.exist?("/usr/bin/snap")
            check_apt_package(values, "snapd")
          end
          command = "sudo sh -c '"+command+"'"
        end
        if command.match(/qemu/) && command.match(/chmod|chgrp/)
          command = "sudo sh -c '"+command+"'"
        end
        if values['vm'].to_s.match(/kvm/) && command.match(/libvirt/) && command.match(/ls/)
          if values['host-os-uname'].to_s.match(/Linux/)
            command = "sudo sh -c '"+command+"'"
          end
        end
      end
      if values['host-os-uname'].to_s.match(/NT/) && command.match(/netsh/)
        batch_file = "/tmp/script.bat"
        File.write(batch_file, command)
        verbose_output(values, "Information:\tCreating batch file '#{batch_file}' to run command '#{command}"'')
        command = "cygstart --action=runas "+batch_file
      end
    end
    if command.match(/^sudo/)
      sudo_check = %x[ sudo -l |grep NOPASSWD ]
      if not sudo_check.match(/NOPASSWD/)
        if values['host-os-uname'].to_s.match(/Darwin/)
          sudo_check = %x[dscacheutil -q group -a name admin |grep users]
        else
          sudo_check = %x[getent group #{values['sudogroup']}].chomp
        end
        if !sudo_check.match(/#{values['user']}/)
          verbose_output(values, "Warning:\tUser #{values['user']} is not in sudoers group #{values['sudogroup']}")
          quit(values)
        end
      end
    end
    if values['verbose'] == true
      verbose_output(values, "Executing:\t#{command}")
    end
    if values['executehost'].to_s.match(/localhost/)
      if values['dryrun'] == true
        if command.match(/list|find/)
          output = %x[#{command}]
        end
      else
        output = %x[#{command}]
      end
    else
#      Net::SSH.start(values['server'], values['serveradmin'], :password => values['serverpassword'], :verify_host_key => "never") do |ssh_session|
#        output = ssh_session.exec!(command)
#      end
    end
  end
  if values['verbose'] == true
    if output.length > 1
      if not output.match(/\n/)
        verbose_output(values, "Output:\t\t#{output}")
      else
        multi_line_output = output.split(/\n/)
        multi_line_output.each do |line|
          verbose_output(values, "Output:\t\t#{line}")
        end
      end
    end
  end
  return output
end

# Convert current date to a string that can be used in file names

def get_date_string(values)
  time = Time.new
  time = time.to_a
  date = Time.utc(*time)
  date_string = date.to_s.gsub(/\s+/, "_")
  date_string = date_string.gsub(/:/, "_")
  date_string = date_string.gsub(/-/, "_")
  if values['verbose'] == true
    verbose_output(values, "Information:\tSetting date string to #{date_string}")
  end
  return date_string
end

# Create an encrypted password field entry for a give password

def get_password_crypt(password)
  crypt = UnixCrypt::MD5.build(password)
  return crypt
end

# Restart DHCPd

def restart_dhcpd(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    function = "refresh"
    service  = "svc:/network/dhcp/server:ipv4"
    output   = handle_smf_service(values, function, service)
  else
    if values['host-os-uname'].to_s.match(/Linux/)
      service = "isc-dhcp-server"
    else
      service = "dhcpd"
    end
    refresh_service(values, service)
  end
  return output
end

# Check DHPCPd is running

def check_dhcpd(values)
  message = "Checking:\tDHCPd is running"
  if values['host-os-uname'].to_s.match(/SunOS/)
    command = "svcs -l svc:/network/dhcp/server:ipv4"
    output  = execute_command(values, message, command)
    if output.match(/disabled/)
      function         = "enable"
      smf_install_service = "svc:/network/dhcp/server:ipv4"
      output           = handle_smf_service(function, smf_install_service)
    end
    if output.match(/maintenance/)
      function         = "refresh"
      smf_install_service = "svc:/network/dhcp/server:ipv4"
      output           = handle_smf_service(function, smf_install_service)
    end
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    command = "ps aux |grep '/usr/local/bin/dhcpd' |grep -v grep"
    output  = execute_command(values, message, command)
    if not output.match(/dhcp/)
      service = "dhcp"
      check_osx_service_is_enabled(values, service)
      service = "dhcp"
      refresh_service(values, service)
    end
    check_osx_tftpd()
  end
  return output
end

# Get service basename

def get_service_base_name(values)
  base_service = values['service'].to_s.gsub(/_i386|_x86_64|_sparc/, "")
  return base_service
end

# Get service name

def get_service_name(values, service)
  if values['host-os-uname'].to_s.match(/SunOS/)
    if service.to_s.match(/apache/)
      service = "svc:/network/http:apache22"
    end
    if service.to_s.match(/dhcp/)
      service = "svc:/network/dhcp/server:ipv4"
    end
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    if service.to_s.match(/apache/)
      service = "org.apache.httpd"
    end
    if service.to_s.match(/dhcp/)
      service = "homebrew.mxcl.isc-dhcp"
    end
    if service.to_s.match(/dnsmasq/)
      service = "homebrew.mxcl.dnsmasq"
    end
  end
  return service
end

# Enable service

def enable_service(values, service_name)
  if values['host-os-uname'].to_s.match(/SunOS/)
    output = enable_smf_service(values, service_name)
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    output = enable_osx_service(values, service_name)
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    output = enable_linux_service(values, service_name)
  end
  return output
end

# Start service

def start_service(values, service_name)
  if values['host-os-uname'].to_s.match(/Linux/)
    output = start_linux_service(values, service_name)
  end
  return output
end


# Disable service

def disable_service(values, service_name)
  if values['host-os-uname'].to_s.match(/SunOS/)
    output = disable_smf_service(values, service_name)
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    output = disable_osx_service(values, service_name)
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    output = disable_linux_service(values, service_name)
  end
  return output
end

# Refresh / Restart service

def refresh_service(values, service_name)
  if values['host-os-uname'].to_s.match(/SunOS/)
    output = refresh_smf_service(values, service_name)
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    output = refresh_osx_service(values, service_name)
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    restart_linux_service(values, service_name)
  end
  return output
end

# Calculate route

def get_ipv4_default_route(values)
  if !values['gateway'].to_s.match(/[0-9]/)
    if values['host-os-uname'].to_s.match(/Darwin/)
      message = "Information:\tDetermining default route"
      command = "route -n get default |grep gateway |cut -f2 -d:"
      output  = execute_command(values, message, command)
      ipv4_default_route = output.chomp.gsub(/\s+/, "")
    else
      octets    = values['ip'].split(/\./)
      octets[3] = values['gatewaynode']
      ipv4_default_route = octets.join(".")
    end
  else
    ipv4_default_route = values['gateway']
  end
  return ipv4_default_route
end

# Create a ZFS filesystem for ISOs if it doesn't exist
# Eg /export/isos
# This could be an NFS mount from elsewhere
# If a directory already exists it will do nothing
# It will check that there are ISOs in the directory
# If none exist it will exit

def get_base_dir_list(values)
  if values['vm'].to_s.match(/mp|multipass/)
    iso_list = get_multipass_iso_list(values)
    return iso_list
  end
  search_string = values['search']
  if values['isodir'] == nil or values['isodir'] == "none" and values['file'] == values['empty']
    verbose_output(values, "Warning:\tNo valid ISO directory specified")
    quit(values)
  end
  iso_list = []
  if values['file'] == values['empty']
    check_fs_exists(values, values['isodir'])
    case values['type'].to_s
    when /iso/
      iso_list = Dir.entries(values['isodir']).grep(/iso$|ISO$/)
    when /image|img/
      iso_list = Dir.entries(values['isodir']).grep(/img$|IMG$|image$|IMAGE$/)
    when /service/
      iso_list = Dir.entries(values['repodir']).grep(/[a-z]|[A-Z]/)
    end
    if values['method'].to_s.match(/ps/)
      iso_list = iso_list.grep_v(/live/)
    end
    if values['method'].to_s.match(/ci/)
      iso_list = iso_list.grep(/live/)
    end
    if search_string.match(/sol_11/)
      if not iso_list.grep(/full/)
        verbose_output(values, "Warning:\tNo full repository ISO images exist in #{values['isodir']}")
        if values['test'] != true
          quit(values)
        end
      end
    end
    iso_list
  else
    iso_list[0] = values['file']
  end
  return iso_list
end

# Check client architecture

def check_client_arch(values, opt)
  if not values['arch'].to_s.match(/i386|sparc|x86_64/)
    if opt['F'] or opt['O']
      if opt['A']
        verbose_output(values, "Information:\tSetting architecture to x86_64")
        values['arch'] = "x86_64"
      end
    end
    if opt['n']
      values['service'] = opt['n']
      service_arch = values['service'].split("_")[-1]
      if service_arch.match(/i386|sparc|x86_64/)
        values['arch'] = service_arch
      end
    end
  end
  if not values['arch'].to_s.match(/i386|sparc|x86_64/)
    verbose_output(values, "Warning:\tInvalid architecture specified")
    verbose_output(values, "Warning:\tUse --arch i386, --arch x86_64 or --arch sparc")
    quit(values)
  end
  return values['arch']
end

# Check client MAC

def check_install_mac(values)
  if !values['mac'].to_s.match(/:/)
    if values['mac'].to_s.split(":").length != 6
      verbose_output(values, "Warning:\tInvalid MAC address")
      values['mac'] = generate_mac_address(values['vm'])
      verbose_output(values, "Information:\tGenerated new MAC address: #{values['mac']}")
    else
      charsi = values['mac'].split(//)
      values['mac'] = chars[0..1].join+":"+chars[2..3].join+":"+chars[4..5].join+":"+chars[6..7].join+":"+chars[8..9].join+":"+chars[10..11].join
    end
  end
  macs = values['mac'].split(":")
  if macs.length != 6
    verbose_output(values, "Warning:\tInvalid MAC address")
    quit(values)
  end
  macs.each do |mac|
    if mac =~ /[G-Z]|[g-z]/
      verbose_output(values, "Warning:\tInvalid MAC address")
      values['mac'] = generate_mac_address(values['vm'])
      verbose_output(values, "Information:\tGenerated new MAC address: #{values['mac']}")
    end
  end
  return values['mac']
end

# Check install IP

def check_install_ip(values)
  values['ips'] = []
  if values['ip'].to_s.match(/,/)
    values['ips'] = values['ip'].split(",")
  else
    values['ips'][0] = values['ip']
  end
  values['ips'].each do |test_ip|
    ips = test_ip.split(".")
    if ips.length != 4
      verbose_output(values, "Warning:\tInvalid IP Address")
    end
    ips.each do |ip|
      if ip =~ /[a-z,A-Z]/ or ip.length > 3 or ip.to_i > 254
        verbose_output(values, "Warning:\tInvalid IP Address")
      end
    end
  end
  return
end


# Add apache proxy

def add_apache_proxy(values, service_base_name)
  service = "apache"
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['osverstion'].to_s.match(/11/) && values['host-os-update'].to_s.match(/4/)
      apache_config_file = values['apachedir']+"/2.4/httpd.conf"
      service = "apache24"
    else
      apache_config_file = values['apachedir']+"/2.2/httpd.conf"
      service = "apache22"
    end
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    apache_config_file = values['apachedir']+"/httpd.conf"
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    apache_config_file = values['apachedir']+"/conf/httpd.conf"
    if !File.exist?(apache_config_file)
      values = install_package(values, "apache2")
    end
  end
  a_check = %x[cat #{apache_config_file} |grep #{service_base_name}]
  if not a_check.match(/#{service_base_name}/)
    message = "Information:\tArchiving "+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
    command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
    execute_command(values, message, command)
    message = "Adding:\t\tProxy entry to "+apache_config_file
    command = "echo 'ProxyPass /"+service_base_name+" http://"+values['publisherhost']+":"+values['publisherport']+" nocanon max=200' >>"+apache_config_file
    execute_command(values, message, command)
    enable_service(values, service)
    refresh_service(values, service)
  end
  return
end

# Remove apache proxy

def remove_apache_proxy(service_base_name)
  service = "apache"
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['osverstion'].to_s.match(/11/) && values['host-os-update'].to_s.match(/4/)
      apache_config_file = values['apachedir']+"/2.4/httpd.conf"
      service = "apache24"
    else
      apache_config_file = values['apachedir']+"/2.2/httpd.conf"
      service = "apache22"
    end
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    apache_config_file = values['apachedir']+"/httpd.conf"
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    apache_config_file = values['apachedir']+"/conf/httpd.conf"
  end
  message = "Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
  command = "cat #{apache_config_file} |grep '#{service_base_name}'"
  a_check = execute_command(values, message, command)
  if a_check.match(/#{service_base_name}/)
    restore_file = apache_config_file+".no_"+service_base_name
    if File.exist?(restore_file)
      message = "Restoring:\t"+restore_file+" to "+apache_config_file
      command = "cp #{restore_file} #{apache_config_file}"
      execute_command(values, message, command)
      service = "apache"
      refresh_service(values, service)
    end
  end
end

# Add apache alias

def add_apache_alias(values, service_base_name)
  values = install_package(values, "apache2")
  if service_base_name.match(/^\//)
    apache_alias_dir  = service_base_name
    service_base_name = File.basename(service_base_name)
  else
    apache_alias_dir = values['baserepodir']+"/"+service_base_name
  end
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['host-os-version'].to_s.match(/11/) && values['host-os-update'].to_s.match(/4/)
      apache_config_file = values['apachedir']+"/2.4/httpd.conf"
    else
      apache_config_file = values['apachedir']+"/2.2/httpd.conf"
    end
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    apache_config_file = values['apachedir']+"/httpd.conf"
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    if values['host-os-unamea'].match(/CentOS|RedHat/)
      apache_config_file = values['apachedir']+"/conf/httpd.conf"
      apache_doc_root = "/var/www/html"
      apache_doc_dir  = apache_doc_root+"/"+service_base_name
    else
      apache_config_file = "/etc/apache2/apache2.conf"
    end
  end
  if values['host-os-uname'].to_s.match(/SunOS|Linux/)
    tmp_file = "/tmp/httpd.conf"
    message  = "Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
    command  = "cat #{apache_config_file} |grep '/#{service_base_name}'"
    a_check  = execute_command(values, message, command)
    message  = "Information:\tChecking Apache Version"
    command  = "apache2 -V 2>&1 |grep version |tail -1"
    a_vers   = execute_command(values, message, command)
    if not a_check.match(/#{service_base_name}/)
      message = "Information:\tArchiving Apache config file "+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
      command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
      execute_command(values, message, command)
      if values['verbose'] == true
        verbose_output(values, "Adding:\t\tDirectory and Alias entry to #{apache_config_file}")
      end
      message = "Copying:\tApache config file so it can be edited"
      command = "cp #{apache_config_file} #{tmp_file} ; chown #{values['uid']} #{tmp_file}"
      execute_command(values, message, command)
      output = File.open(tmp_file, "a")
      output.write("<Directory #{apache_alias_dir}>\n")
      output.write("values Indexes FollowSymLinks\n")
      if a_vers.match(/2\.4/)
        output.write("Require ip #{values['apacheallow']}\n")
      else
        output.write("Allow from #{values['apacheallow']}\n")
      end
      output.write("</Directory>\n")
      output.write("Alias /#{service_base_name} #{apache_alias_dir}\n")
      output.close
      message = "Updating:\tApache config file"
      command = "cp #{tmp_file} #{apache_config_file} ; rm #{tmp_file}"
      execute_command(values, message, command)
    end
    if values['host-os-uname'].to_s.match(/SunOS|Linux/)
      if values['host-os-uname'].to_s.match(/Linux/)
        if values['host-os-unamea'].to_s.match(/CentOS|RedHat/)
          service = "httpd"
        else
          service = "apache2"
        end
      else
        if values['host-os-uname'].match(/SunOS/) && values['host-os-version'].to_s.match(/11/)
          if values['host-os-update'].to_s.match(/4/)
            service = "apache24"
          else
            service = "apache2"
          end
        else
          service = "apache"
        end
      end
      enable_service(values, service)
      refresh_service(values, service)
    end
    if values['host-os-uname'].to_s.match(/Linux/)
      if values['host-os-unamea'].match(/RedHat/)
        if values['host-os-version'].match(/^7|^6\.7/)
          httpd_p = "httpd_sys_rw_content_t"
          message = "Information:\tFixing permissions on "+values['clientdir']
          command = "chcon -R -t #{httpd_p} #{values['clientdir']}"
          execute_command(values, message, command)
        end
      end
    end
  end
  return
end

# Remove apache alias

def remove_apache_alias(service_base_name)
  remove_apache_proxy(service_base_name)
end

def mount_udf(values)
  return
end

# Mount full repo isos under iso directory
# Eg /export/isos
# An example full repo file name
# /export/isos/sol-11_1-repo-full.iso
# It will attempt to mount them
# Eg /cdrom
# If there is something mounted there already it will unmount it

def mount_iso(values)
  verbose_output(values, "Information:\tProcessing: #{values['file']}")
  output  = check_dir_exists(values, values['mountdir'])
  message = "Checking:\tExisting mounts"
  command = "df |awk '{print $NF}' |grep '^#{values['mountdir']}$'"
  output  = execute_command(values, message, command)
  if output.match(/[a-z,A-Z]/)
    message = "Information:\tUnmounting: "+values['mountdir']
    command = "umount "+values['mountdir']
    output  = execute_command(values, message, command)
  end
  message = "Information:\tMounting ISO "+values['file']+" on "+values['mountdir']
  if values['host-os-uname'].to_s.match(/SunOS/)
    command = "mount -F hsfs "+values['file']+" "+values['mountdir']
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    command = "hdiutil attach -nomount \"#{values['file']}\" |head -1 |awk \"{print \\\$1}\""
    if values['verbose'] == true
      verbose_output(values, "Executing:\t#{command}")
    end
    disk_id = %x[#{command}]
    disk_id = disk_id.chomp
    file_du = %x[du "#{values['file'].to_s}" |awk '{print $1}']
    file_du = file_du.chomp.to_i
    if file_du < 700000
      command = "mount -t cd9660 -o ro "+disk_id+" "+values['mountdir']
    else
      command = "sudo mount -t udf -o ro "+disk_id+" "+values['mountdir']
    end
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    file_du = %x[du "#{values['file'].to_s}" |awk '{print $1}']
    file_du = file_du.chomp.to_i
    if file_du < 700000
      command = "mount -t iso9660 -o loop "+values['file']+" "+values['mountdir']
    else
      command = "sudo mount -t udf -o ro "+values['file']+" "+values['mountdir']
    end
  end
  output  = execute_command(values, message, command)
  readme1 = values['mountdir']+"/README.TXT"
  readme2 = values['mountdir']+"/readme.txt"
  if File.exist?(readme1) || File.exist?(readme2)
    text = IO.readlines(readme)
    if text.grep(/UDF/)
      umount_iso(values)
      if values['host-os-uname'].to_s.match(/Darwin/)
        command = "hdiutil attach -nomount \"#{values['file']}\" |head -1 |awk \"{print \\\$1}\""
        if values['verbose'] == true
          verbose_output(values, "Executing:\t#{command}")
        end
        disk_id = %x[#{command}]
        disk_id = disk_id.chomp
        command = "sudo mount -t udf -o ro "+disk_id+" "+values['mountdir']
        output  = execute_command(values, message, command)
      end
    end
  end
  if values['file'].to_s.match(/sol/)
    if values['file'].to_s.match(/\-ga\-/)
      if values['file'].to_s.match(/sol\-10/)
        iso_test_dir = values['mountdir']+"/boot"
      else
        iso_test_dir = values['mountdir']+"/installer"
      end
    else
      iso_test_dir = values['mountdir']+"/repo"
    end
  else
    case values['file']
    when /VM/
      iso_test_dir = values['mountdir']+"/upgrade"
    when /Win|Srv|[0-9][0-9][0-9][0-9]/
      iso_test_dir = values['mountdir']+"/sources"
    when /SLE/
      iso_test_dir = values['mountdir']+"/suse"
    when /CentOS|SL/
      iso_test_dir = values['mountdir']+"/repodata"
    when /rhel|OracleLinux|Fedora/
      if values['file'].to_s.match(/rhel-server-5/)
        iso_test_dir = values['mountdir']+"/Server"
      else
        if values['file'].to_s.match(/rhel-[8,9]/)
          iso_test_dir = values['mountdir']+"/BaseOS/Packages"
        else
          iso_test_dir = values['mountdir']+"/Packages"
        end
      end
    when /VCSA/
      iso_test_dir = values['mountdir']+"/vcsa"
    when /install|FreeBSD/
      iso_test_dir = values['mountdir']+"/etc"
    when /coreos/
      iso_test_dir = values['mountdir']+"/coreos"
    else
      iso_test_dir = values['mountdir']+"/install"
    end
  end
  if not File.directory?(iso_test_dir) and not File.exist?(iso_test_dir) and not values['file'].to_s.match(/DVD2\.iso|2of2\.iso|repo-full|VCSA/)
    verbose_output(values, "Warning:\tISO did not mount, or this is not a repository ISO")
    verbose_output(values, "Warning:\t#{iso_test_dir} does not exist")
    if values['test'] != true
      umount_iso(values)
      quit(values)
    end
  end
  return
end

# Check my directory exists

def check_my_dir_exists(values, dir_name)
  if not File.directory?(dir_name) and not File.symlink?(dir_name)
    if values['verbose'] == true
      verbose_output(values, "Information:\tCreating directory '#{dir_name}'")
    end
    system("mkdir #{dir_name}")
  else
    if values['verbose'] == true
      verbose_output(values, "Information:\tDirectory '#{dir_name}' already exists")
    end
  end
  return
end

# Check ISO mounted for OS X based server

def check_osx_iso_mount(values)
  check_dir_exists(values, values['mountdir'])
  test_dir = values['mountdir']+"/boot"
  if not File.directory?(test_dir)
    message = "Mounting:\ISO "+values['file']+" on "+values['mountdir']
    command = "hdiutil mount #{values['file']} -mountpoint #{values['mountdir']}"
    output  = execute_command(values, message, command)
  end
  return output
end

# Copy repository from ISO to local filesystem

def copy_iso(values)
  if values['verbose'] == true
    verbose_output(values, "Checking:\tIf we can copy data from full repo ISO")
  end
  if values['file'].to_s.match(/sol/)
    iso_test_dir = values['mountdir']+"/repo"
    if File.directory?(iso_test_dir)
      iso_repo_dir = iso_test_dir
    else
      iso_test_dir = values['mountdir']+"/publisher"
      if File.directory?(iso_test_dir)
        iso_repo_dir = values['mountdir']
      else
        verbose_output(values, "Warning:\tRepository source directory does not exist")
        if values['test'] != true
          quit(values)
        end
      end
    end
    test_dir = values['repodir']+"/publisher"
  else
    iso_repo_dir = values['mountdir']
    case values['file']
    when /CentOS|rhel|OracleLinux|Fedora/
      test_dir = values['repodir']+"/isolinux"
    when /VCSA/
      test_dir = values['repodir']+"/vcsa"
    when /VM/
      test_dir = values['repodir']+"/upgrade"
    when /install|FreeBSD/
      test_dir = values['repodir']+"/etc"
    when /coreos/
      test_dir = values['repodir']+"/coreos"
    when /SLES/
      test_dir = values['repodir']+"/suse"
    else
      test_dir = values['repodir']+"/install"
    end
  end
  if not File.directory?(values['repodir']) and not File.symlink?(values['repodir']) and not values['file'].to_s.match(/\.iso/)
    verbose_output(values, "Warning:\tRepository directory #{values['repodir']} does not exist")
    if values['test'] != true
      quit(values)
    end
  end
  if not File.directory?(test_dir) or values['file'].to_s.match(/DVD2\.iso|2of2\.iso/)
    if values['file'].to_s.match(/sol/)
      if not File.directory?(iso_repo_dir)
        verbose_output(values, "Warning:\tRepository source directory #{iso_repo_dir} does not exist")
        if values['test'] != true
          quit(values)
        end
      end
      message = "Copying:\t"+iso_repo_dir+" contents to "+values['repodir']
      command = "rsync -a #{iso_repo_dir}/. #{values['repodir']}"
      output  = execute_command(values, message, command)
      if values['host-os-uname'].to_s.match(/SunOS/)
        message = "Rebuilding:\tRepository in "+values['repodir']
        command = "pkgrepo -s #{values['repodir']} rebuild"
        output  = execute_command(values, message, command)
      end
    else
      check_dir_exists(values, test_dir)
      message = "Copying:\t"+iso_repo_dir+" contents to "+values['repodir']
      command = "rsync -a #{iso_repo_dir}/. #{values['repodir']}"
      if values['repodir'].to_s.match(/sles_12/)
        if not values['file'].to_s.match(/2\.iso/)
          output  = execute_command(values, message, command)
        end
      else
        verbose_output(values, message)
        output  = execute_command(values, message, command)
      end
    end
  end
  return
end

# List domains/zones/etc instances

def list_doms(values, dom_type, dom_command)
  message = "Information:\nAvailable #{dom_type}(s)"
  command = dom_command
  output  = execute_command(values, message, command)
  output  = output.split("\n")
  if output.length > 0
    if values['output'].to_s.match(/html/)
      verbose_output(values, "<h1>Available #{dom_type}(s)</h1>")
      verbose_output(values, "<table border=\"1\">")
      verbose_output(values, "<tr>")
      verbose_output(values, "<th>Service</th>")
      verbose_output(values, "</tr>")
    else
      verbose_output(values, "")
      verbose_output(values, "Available #{dom_type}(s):")
      verbose_output(values, "")
    end
    output.each do |line|
      line = line.chomp
      line = line.gsub(/\s+$/, "")
      if values['output'].to_s.match(/html/)
        verbose_output(values, "<tr>")
        verbose_output(values, "<td>#{line}</td>")
        verbose_output(values, "</tr>")
      else
        verbose_output(values, line)
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_output(values, "</table>")
    end
  end
  return
end

# List services

def list_services(values)
  if values['os-type'].to_s != values['empty'].to_s
    search = values['os-type'].to_s
  else
    if values['method'].to_s != values['empty'].to_s
      search = values['method'].to_s
    else
      if values['search'].to_s != values['empty'].to_s
        search = values['search'].to_s
      else
        search = "all"
      end
    end
  end
  case search
  when /ai/
    list_ai_services(values)
  when /ay|sles/
    list_ay_services(values)
  when /image/
    list_image_services(values)
  when /all/
    list_all_services(values)
  when /js/
    list_js_services(values)
  when /ks|rhel|centos|scientific/
    list_ks_services(values)
  when /cdom/
    list_cdom_services(values)
  when /ldom/
    list_ldom_services(values)
  when /gdom/
    list_gdom_services(values)
  when /lxc/
    list_lxc_services(values)
  when /ps|ubuntu|debian/
    list_ps_services(values)
  when /ci/
    list_cc_services(values)
  when /zone/
    list_zone_services(values)
  when /vs|vmware|vsphere/
    list_vs_services(values)
  when /xb/
    list_xb_services(values)
  end
  return
end

# Unmount ISO

def umount_iso(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    command = "df |grep \"#{values['mountdir']}$\" |head -1 |awk \"{print \\\$1}\""
    if values['verbose'] == true
      verbose_output(values, "Executing:\t#{command}")
    end
    disk_id = %x[#{command}]
    disk_id = disk_id.chomp
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    message = "Detaching:\tISO device "+disk_id
    command = "sudo hdiutil detach #{disk_id}"
    execute_command(values, message, command)
  else
    message = "Unmounting:\tISO mounted on "+values['mountdir']
    command = "umount #{values['mountdir']}"
    execute_command(values, message, command)
  end
  return
end

# Clear a service out of maintenance mode

def clear_service(values, smf_service)
  message = "Checking:\tStatus of service "+smf_service
  command = "sleep 5 ; svcs -a |grep \"#{values['service']}\" |awk \"{print \\\$1}\""
  output  = execute_command(values, message, command)
  if output.match(/maintenance/)
    message = "Clearing:\tService "+smf_service
    command = "svcadm clear #{smf_service}"
    output  = execute_command(values, message, command)
  end
  return
end


# Occassionally DHCP gets stuck if it's restart to often
# Clear it out of maintenance mode

def clear_solaris_dhcpd(values)
  smf_service = "svc:/network/dhcp/server:ipv4"
  clear_service(values, smf_service)
  return
end

# Brew install a package on OS X

def brew_install(values, pkg_name)
  command = "brew install #{pkg_name}"
  message = "Information:\tInstalling #{pkg_name}"
  execute_command(values, message, command)
  return
end

# Get method from service

def get_method_from_service(service)
  case service
  when /rhel|fedora|centos/
    method = "ks"
  when /sol_10/
    method = "js"
  when /sol_11/
    method = "ai"
  when /ubuntu|debian/
    if service.match(/live/)
      method = "ci"
    else
      method = "ps"
    end
  when /sles|suse/
    method = "ay"
  when /vmware/
    method = "vs"
  end
  return method
end

def check_perms(values)
  if values['verbose'] == true
    verbose_output(values, "Information:\tChecking client directory")
  end
  check_dir_exists(values, values['clientdir'])
  check_dir_owner(values, values['clientdir'], values['uid'])
  return
end
