# frozen_string_literal: true

# Code common to all services

# Set SSH port

def set_ssh_port(values)
  case values['type']
  when /packer/
    values['sshport'] = if values['method'].to_s.match(/vs/)
                          '22'
                        else
                          '2222'
                        end
  end
  values
end

# Get architecture from model

def get_arch_from_model(values)
  values['arch'] = if values['model'].to_s.downcase.match(/^t/)
                     'sun4v'
                   else
                     'sun4u'
                   end
  values
end

# Parse memory

def process_memory_value(values)
  memory = values['memory'].to_s
  unless memory.match(/[A-Z]$|[a-z]$/)
    memory = if memory.to_i < 100
               "#{memory}G"
             else
               "#{memory}M"
             end
  end
  values['memory'] = memory
  values
end

# Set hostonly information

def set_hostonly_info(values)
  host_ip        = get_my_ip(values)
  host_subnet    = host_ip.split('.')[2]
  install_subnet = values['ip'].split('.')[2]
  hostonly_base  = '192.168'
  case values['vm']
  when /vmware|vmx|fusion/
    hostonly_subnet = if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 10
                        if values['vmnetwork'].to_s.match(/nat/)
                          '158'
                        elsif values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 11
                          '2'
                        else
                          '104'
                        end
                      else
                        '52'
                      end
  when /parallels/
    hostonly_base = '10.211'
    hostonly_subnet = if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 10
                        '55'
                      else
                        '54'
                      end
  when /vbox|virtualbox/
    hostonly_subnet = '56'
  when /kvm/
    hostonly_subnet = '122'
  else
    hostonly_subnet = '58' unless values['vm'] == values['empty']
  end
  if hostonly_subnet == host_subnet
    output = "Warning:\tHost and Hostonly network are the same"
    verbose_message(values, output)
    hostonly_subnet = host_subnet.to_i + 10
    hostonly_subnet = hostonly_subnet.to_s
    output = "Information:\tChanging hostonly network to #{hostonly_base}.#{hostonly_subnet}.0"
    verbose_message(values, output)
    values['force'] = true
  end
  if (install_subnet == host_subnet) && (values['dhcp'] == false)
    output = "Warning:\tHost and client network are the same"
    verbose_message(values, output)
    install_subnet = host_subnet.to_i + 10
    install_subnet = install_subnet.to_s
    values['ip'] =
      "#{values['ip'].split('.')[0]}.#{values['ip'].split('.')[1]}.#{install_subnet}.#{values['ip'].split('.')[3]}"
    output = "Information:\tChanging Client IP to #{hostonly_base}.#{hostonly_subnet}.0"
    verbose_message(values, output)
    values['force'] = true
  end
  values['vmgateway']  = "#{hostonly_base}.#{hostonly_subnet}.1"
  values['hostonlyip'] = "#{hostonly_base}.#{hostonly_subnet}.1"
  values['hostonlyip'] = "#{hostonly_base}.#{hostonly_subnet}.1"
  values['ip']         = "#{hostonly_base}.#{hostonly_subnet}.101"
  check_vm_network(values)
end

# Get my IP - Useful when running in server mode

def get_my_ip(values)
  message = "Information:\tDetermining IP of local machine"
  values['host-os-uname'] = `uname` unless values['host-os-uname'].to_s.match(/[a-z]/)
  command = if values['host-os-uname'].to_s.match(/Darwin/)
              'ipconfig getifaddr en0'
            elsif values['host-os-uname'].to_s.match(/SunOS/)
              "/usr/sbin/ifconfig -a | awk \"BEGIN { count=0; } { if ( \\\$1 ~ /inet/ ) { count++; if( count==2 ) { print \\\$2; } } }\""
            elsif File.exist?('/usr/bin/ip')
              "ip addr |grep 'inet ' |grep -v 127 |head -1 |awk '{print \$2}' |cut -f1 -d/"
            elsif values['vm'].to_s == 'kvm'
              "hostname -I |awk \"{print \\\$2}\""
            else
              "hostname -I |awk \"{print \\\$1}\""
            end
  output = execute_command(values, message, command)
  output = output.chomp
  output = output.strip
  output = output.gsub(/\s+|\n/, '')
  output.strip
end

# Get the NIC name from the service name - Now trying to use biosdevname=0 everywhere

def get_nic_name_from_install_service(_values)
  'eth0'
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
end

# Calculate CIDR

def netmask_to_cidr(netmask)
  Integer(32 - Math.log2((IPAddr.new(netmask, Socket::AF_INET).to_i ^ 0xffffffff) + 1))
end

# values['cidr'] = netmask_to_cidr(values['netmask'])

# Code to run on quiting

def quit(values)
  if values['output'].to_s.match(/html/)
    values['stdout'].push('</body>')
    values['stdout'].push('</html>')
    puts values['stdout'].join("\n")
  end
  return unless values['dryrun'] == false

  exit
end

# Get valid switches and put in an array

def get_valid_values(_values)
  file_array = IO.readlines $PROGRAM_NAME
  file_array.grep(/\['--/)
end

# Handle IP

def single_install_ip(values)
  if values['ip'].to_s.match(/,/)
    values['ip'].to_s.split(/,/)[0]
  else
    values['ip'].to_s
  end
end

# Print script usage information

def print_help(values)
  values['verbose'] = true
  switches     = []
  long_switch  = ''
  short_switch = ''
  help_info    = ''
  verbose_message(values, '')
  verbose_message(values, "Usage: #{values['script']}")
  verbose_message(values, '')
  option_list = get_valid_values(values)
  option_list.each do |line|
    next if line.match(/file_array/)

    help_info    = line.split(/# /)[1]
    switches     = line.split(/,/)
    long_switch  = switches[0].gsub(/\[/, '').gsub(/\s+/, '')
    short_switch = switches[1].gsub(/\s+/, '')
    short_switch = '' if short_switch.match(/REQ|BOOL/)
    if long_switch.gsub(/\s+/, '').length < 7
      verbose_message(values, "#{long_switch},\t\t\t#{short_switch}\t#{help_info}")
    elsif long_switch.gsub(/\s+/, '').length < 15
      verbose_message(values, "#{long_switch},\t\t#{short_switch}\t#{help_info}")
    else
      verbose_message(values, "#{long_switch},\t#{short_switch}\t#{help_info}")
    end
  end
  verbose_message(values, '')
  nil
end

def html_header(pipe, title)
  pipe.push('<html>')
  pipe.push('<header>')
  pipe.push('<title>')
  pipe.push(title)
  pipe.push('</title>')
  pipe.push('</header>')
  pipe.push('<body>')
  pipe
end

# HTML footer

def html_footer(pipe)
  pipe.push('</body>')
  pipe.push('</html>')
  pipe
end

# Get version

def get_version(_values)
  file_array = IO.readlines $PROGRAM_NAME
  version    = file_array.grep(/^# Version/)[0].split(':')[1].gsub(/^\s+/, '').chomp
  packager   = file_array.grep(/^# Packager/)[0].split(':')[1].gsub(/^\s+/, '').chomp
  name       = file_array.grep(/^# Name/)[0].split(':')[1].gsub(/^\s+/, '').chomp
  [version, packager, name]
end

# Print script version information

def print_version(values)
  (version, packager, name) = get_version(values)
  values['verbose'] = true
  verbose_message(values, "#{name} v. #{version} #{packager}")
  nil
end

# Set file perms

def set_file_perms(file_name, file_perms)
  message = "Information:\tSetting permissions on file '#{file_name}' to '#{file_perms}'"
  command = "chmod #{file_perms} \"#{file_name}\""
  execute_command(values, message, command)
  nil
end

# Write array to file

def write_array_to_file(values, file_array, file_name, file_mode)
  dir_name = Pathname.new(file_name).dirname
  check_dir_exists(values, dir_name)
  file_mode = if file_mode.match(/a/)
                'a'
              else
                'w'
              end
  if values['dryrun'] == true
    file_name = File.basename(file_name)
    file_name = "#{values['tmpdir']}/#{file_name}"
  end
  file = File.open(file_name, file_mode)
  file_array.each do |line|
    line += "\n" unless line.match(/\n/)
    file.write(line)
  end
  file.close
  print_contents_of_file(values, '', file_name)
  nil
end

# Get SSH config

def get_user_ssh_config(values)
  user_ssh_config = ConfigFile.new
  host_list = user_ssh_config.search(/#{values['id']}/) if values['ip'].to_s.match(/[0-9]/)
  host_list = user_ssh_config.search(/#{values['ip']}/) if values['id'].to_s.match(/[0-9]/)
  host_list = user_ssh_config.search(/#{values['name']}/) if values['name'].to_s.match(/[0-9]|[a-z]/)
  if !host_list
    host_list = 'none'
  else
    host_list = 'none' unless host_list.match(/[A-Z]|[a-z]|[0-9]/)
  end
  host_list
end

# List hosts in SSH config

def list_user_ssh_config(values)
  host_list = get_user_ssh_config(values)
  verbose_message(host_list) unless host_list == values['empty']
  nil
end

# Update SSH config

def update_user_ssh_config(values)
  host_list = get_user_ssh_config(values)
  if host_list == values['empty']
    host_string = 'Host '
    ssh_config  = values['sshconfig']
    host_string = "#{host_string} #{values['name']}" if values['name'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    host_string = "#{host_string} #{values['id']}" if values['id'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    file = if !File.exist?(ssh_config)
             File.open(ssh_config, 'w')
           else
             File.open(ssh_config, 'a')
           end
    file.write("#{host_string}\n")
    file.write("    IdentityFile #{values['sshkeyfile']}\n") if values['sshkeyfile'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    file.write("    User #{values['adminuser']}\n") if values['adminuser'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    file.write("    HostName #{values['ip']}\n") if values['ip'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    file.close
  end
  nil
end

# Remove SSH config

def delete_user_ssh_config(values)
  host_list = get_user_ssh_config(values)
  unless host_list == values['empty']
    host_info = host_list.split(/\n/)[0].chomp
    warning_message(values, "Removing entries for '#{host_info}'")
    ssh_config = values['sshconfig']
    ssh_data   = File.readlines(ssh_config)
    new_data   = []
    found_host = 0
    ssh_data.each do |line|
      if line.match(/^Host/)
        found_host = if line.match(/#{values['name']}|#{values['id']}|#{values['ip']}/)
                       true
                     else
                       0
                     end
      end
      new_data.push(line) if found_host == false
    end
    file = File.open(ssh_config, 'w')
    new_data.each do |line|
      file.write(line)
    end
    file.close
  end
  nil
end

# Check VNC is installed

def check_vnc_install(values)
  return if File.directory?(values['novncdir'])

  message = "Information:\tCloning noVNC from #{$novnc_url}"
  command = "git clone #{$novnc_url}"
  execute_command(values, message, command)
end

# Get Windows default interface name

def get_win_default_if_name(values)
  message = "Information:\tDeterming default interface name"
  command = 'wmic nic where NetConnectionStatus=2 get NetConnectionID |grep -v NetConnectionID |head -1'
  default = execute_command(values, message, command)
  default = default.strip_control_and_extended_characters
  default.gsub(/^\s+|\s+$/, '')
end

# Get Windows interface MAC address

def get_win_if_mac(values, if_name)
  if values['host-os-uname'].to_s.match(/NT/) && if_name.match(/\s+/)
    if_name = if_name.split(/\s+/)[0]
    if_name = if_name.gsub(/"/, '')
    if_name = "%#{if_name}%"
  end
  message = "Information:\tDeterming MAC address for '#{if_name}'"
  command = "wmic nic where \"netconnectionid like '#{if_name}'\" get macaddress"
  nic_mac = execute_command(values, message, command)
  nic_mac = nic_mac.strip_control_and_extended_characters
  nic_mac = nic_mac.split(/\s+/)[1]
  nic_mac.gsub(/^\s+|\s+$/, '')
end

# Get Windows IP from MAC

def get_win_ip_form_mac(values, nic_mac)
  message = "Information:\tDeterming IP address from MAC address '#{nic_mac}'"
  command = "wmic nicconfig get macaddress,ipaddress |grep \"#{nic_mac}\""
  host_ip = execute_command(values, message, command)
  host_ip = host_ip.strip_control_and_extended_characters
  host_ip = host_ip.split(/\s+/)[0]
  host_ip.split(/"/)[1]
end

# Get Windows default host IP

def get_win_default_host(values)
  if_name = get_win_default_if_name(values)
  nic_mac = get_win_if_mac(values, if_name)
  get_win_ip_form_mac(values, nic_mac)
end

# Get Windows IP from interface name

def get_win_ip_from_if_name(if_name)
  nic_mac = get_win_if_mac(values, if_name)
  get_win_ip_form_mac(values, nic_mac)
end

# Get default host

def get_default_host(values)
  values['hostip'] = '' if values['hostip'].nil?
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
      host_ip = host_ip.gsub(/^\s+/, '').split(/\s+/)[1] if host_ip.match(/inet/)
      host_ip = host_ip.split(/:/)[1].split(/ /)[0] if host_ip.match(/addr:/)
    end
  else
    host_ip = values['hostip']
  end
  host_ip = host_ip.strip if host_ip
  host_ip
end

# Get default route IP

def get_gw_if_ip(values, _gw_if_name)
  if values['host-os-uname'].to_s.match(/NT/)
    gw_if_ip = get_win_default_host
  else
    message = "Information:\tGetting IP of default router"
    command = if values['host-os-uname'].to_s.match(/Linux/)
                "sudo sh -c \"netstat -rn |grep UG |awk '{print \\\$2}'\""
              else
                "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$2}'\""
              end
    gw_if_ip = execute_command(values, message, command)
    gw_if_ip = gw_if_ip.chomp
  end
  gw_if_ip
end

# Get default route interface

def get_gw_if_name(values)
  if values['host-os-uname'].to_s.match(/NT/)
    get_win_default_if_name(values)
  else
    message = "Information:\tGetting interface name of default router"
    command = if values['host-os-uname'].to_s.match(/Linux/)
                "sudo sh -c \"netstat -rn |grep UG |awk '{print \\\$8}' |head -1\""
              elsif values['host-os-unamer'].to_s.match(/^19/)
                "sudo sh -c \"netstat -rn |grep ^default |grep UGS |tail -1 |awk '{print \\\$4}'\""
              elsif values['host-os-version'].to_i > 10
                "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$4}'\""
              else
                "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$6}'\""
              end
    gw_if_name = execute_command(values, message, command)
    gw_if_name = gw_if_name.chomp
  end
  gw_if_name
end

# Get interface name for VM networks

def get_vm_if_name(values)
  case values['vm']
  when /parallels/
    if_name = 'prlsnet0'
  when /virtualbox|vbox/
    if_name = if values['host-os-uname'].to_s.match(/NT/)
                '"VirtualBox Host-Only Ethernet Adapter"'
              else
                values['vmnet'].to_s
              end
  when /vmware|fusion/
    if_name = if values['host-os-uname'].to_s.match(/NT/)
                '"VMware Network Adapter VMnet1"'
              else
                values['vmnet'].to_s
              end
  when /kvm|mp|multipass/
    if_name = values['vmnet'].to_s
  end
  if_name
end

# Set config file locations

def set_local_config(values)
  if values['host-os-uname'].to_s.match(/Linux/)
    #    values['tftpdir']   = "/var/lib/tftpboot"
    values['tftpdir']   = '/srv/tftp'
    values['dhcpdfile'] = '/etc/dhcp/dhcpd.conf'
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    values['tftpdir']   = '/private/tftpboot'
    values['dhcpdfile'] = '/usr/local/etc/dhcpd.conf'
  end
  if values['host-os'].to_s.match(/Docker/)
    values['tftpdir']   = '/export/tftpboot'
    values['dhcpdfile'] = '/export/etc/dhcpd.conf'
  end
  if values['host-os'].to_s.match(/SunOS/)
    values['tftpdir']   = '/etc/netboot'
    values['dhcpdfile'] = '/etc/inet/dhcpd4.conf'
  end
  values
end

# Check local configuration
# Create work directory if it does not exist
# If not running on Solaris, run in test mode
# Useful for generating client config files

def check_local_config(values)
  # Check packer is installed
  check_packer_is_installed(values) if values['type'].to_s.match(/packer/)
  # Check Docker is installed
  check_docker_is_installed if values['type'].to_s.match(/docker/)
  if values['host-os'].to_s.downcase.match(/docker/)
    values['type'] = 'docker'
    values['mode'] = 'server'
  end
  # Set VMware Fusion/Workstation VMs
  if values['vm'].to_s.match(/fusion/)
    values = check_fusion_is_installed(values)
    values = set_vmrun_bin(values)
    values = set_fusion_dir(values)
  end
  # Check base dirs exist
  information_message(values, 'Checking base repository directory')
  check_dir_exists(values, values['baserepodir'])
  check_dir_owner(values, values['baserepodir'], values['uid'])
  values = set_vbox_bin(values) if values['vm'].to_s.match(/vbox/)
  check_ssh_keys(values) if values['copykeys'] == true
  information_message(values, "Home directory #{values['home']}")
  unless values['workdir'].to_s.match(/[a-z,A-Z,0-9]/)
    dir_name = File.basename(values['script'], '.*')
    values['workdir'] = if values['uid'] == false
                          "/opt/#{dir_name}"
                        else
                          "#{values['home']}/.#{dir_name}"
                        end
  end
  information_message(values, "Setting work directory to #{values['workdir']}")
  values['tmpdir'] = "#{values['workdir']}/tmp" unless values['tmpdir'].match(/[a-z,A-Z,0-9]/)
  information_message(values, "Setting temporary directory to #{values['workdir']}")
  # Get OS name and set system settings appropriately
  information_message(values, 'Checking work directory')
  check_dir_exists(values, values['workdir'])
  check_dir_owner(values, values['workdir'], values['uid'])
  check_dir_exists(values, values['tmpdir'])
  values['host-os-unamer'] = `lsb_release -r |awk '{print $2}'`.chomp if values['host-os-uname'].to_s.match(/Linux/)
  values['lxcdir'] = '/var/lib/lxc' if values['host-os-unamea'].match(/Ubuntu/)
  values['hostip'] = get_default_host(values)
  unless values['apacheallow'].to_s.match(/[0-9]/)
    values['apacheallow'] = if values['hostnet'].to_s.match(/[0-9]/)
                              "#{values['hostip'].to_s.split(/\./)[0..2].join('.')} #{values['hostnet']}"
                            else
                              values['hostip'].to_s.split(/\./)[0..2].join('.')
                            end
  end
  if values['mode'].to_s.match(/server/)
    if values['host-os-uname'].to_s.match(/Darwin/)
      values['tftpdir']   = '/private/tftpboot'
      values['dhcpdfile'] = '/usr/local/etc/dhcpd.conf'
    end
    if values['host-os'].match(/Docker/)
      values['tftpdir']   = '/export/tftpboot'
      values['dhcpdfile'] = '/export/etc/dhcpd.conf'
    end
    if values['host-os-uname'].to_s.match(/SunOS/) && values['host-os-unamer'].match(/11/)
      check_dpool(values)
      check_tftpd(values)
      check_local_publisher(values)
      install_sol11_pkg(values, 'pkg:/system/boot/network')
      install_sol11_pkg(values, 'installadm')
      install_sol11_pkg(values, 'lftp')
      check_dir_exists(values, '/etc/netboot')
    end
    check_dir_exists(values, '/tftpboot') if values['host-os-uname'].to_s.match(/SunOS/) && !values['host-os-unamer'].match(/11/)
    information_message(values, "Setting apache allow range to #{values['apacheallow']}")
    if values['host-os-uname'].to_s.match(/SunOS/)
      check_dpool(values) if values['host-os-uname'].to_s.match(/SunOS/) && values['host-os-unamer'].match(/11/)
      check_sol_bind(values)
    end
    if values['host-os-uname'].to_s.match(/Linux/)
      install_package(values, 'apache2')
      if values['host-lsb-description'].to_s.match(/Endeavour|Arch/)
        install_package(values, 'rpmextract')
      else
        install_package(values, 'rpm2cpio')
      end
      install_package(values, 'shim')
      install_package(values, 'shim-signed')
      values['apachedir'] = '/etc/httpd'
      if values['host-os-unamea'].match(/RedHat|CentOS/)
        check_yum_xinetd(values)
        check_yum_tftpd(values)
        check_yum_dhcpd(values)
        check_yum_httpd(values)
        values['tftpdir'] = '/var/lib/tftpboot'
      else
        check_apt_tftpd(values)
        check_apt_dhcpd(values)
        values['tftpdir'] = if values['host-os-unamea'].to_s.match(/Ubuntu/)
                              '/srv/tftp'
                            else
                              '/var/lib/tftpboot'
                            end
      end
      values['dhcpdfile'] = '/etc/dhcp/dhcpd.conf'
      check_dhcpd_config(values)
      check_tftpd_config(values)
    end
  else
    if values['host-os-uname'].to_s.match(/Linux/)
      values['tftpdir']   = '/var/lib/tftpboot'
      values['dhcpdfile'] = '/etc/dhcp/dhcpd.conf'
    end
    if values['host-os-uname'].to_s.match(/Darwin/)
      values['tftpdir']   = '/private/tftpboot'
      values['dhcpdfile'] = '/usr/local/etc/dhcpd.conf'
    end
    if values['host-os'].to_s.match(/Docker/)
      values['tftpdir']   = '/export/tftpboot'
      values['dhcpdfile'] = '/export/etc/dhcpd.conf'
    end
    if values['host-os-uname'].to_s.match(/SunOS/) && values['host-os-version'].to_s.match(/11/)
      check_dhcpd_config(values)
      check_tftpd_config(values)
    end
  end
  # If runnning on OS X check we have brew installed
  if values['host-os-uname'].to_s.match(/Darwin/) && !File.exist?('/usr/local/bin/brew') && !File.exist?('/opt/homebrew/bin/brew') && !File.exist?('/usr/homebrew/bin/brew')
    message = "Installing:\tBrew for OS X"
    command = 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
    execute_command(values, message, command)
  end
  information_message(values, 'Checking work bin directory')
  work_bin_dir = "#{values['workdir']}/bin"
  #  [ "rpm2cpio", "rpm" ].each do |pkg_name|
  ['rpm2cpio'].each do |pkg_name|
    option = "#{pkg_name}bin"
    installed = false
    ['/bin', '/usr/local/bin', '/opt/local/bin', '/opt/homebrew/bin', work_bin_dir].each do |bin_dir|
      pkg_bin = "#{bin_dir}/#{pkg_name}"
      next unless File.exist?(pkg_bin)

      installed = true
      values[option] = pkg_bin
      check_file_executable(values, pkg_bin)
    end
    next unless installed == false

    install_package(values, pkg_name)
    ['/bin', '/usr/local/bin', '/opt/local/bin', '/opt/homebrew/bin', work_bin_dir].each do |bin_dir|
      pkg_bin = "#{bin_dir}/#{pkg_name}"
      if File.exist?(pkg_bin)
        values[option] = pkg_bin
        check_file_executable(values, pkg_bin)
      end
    end
  end
  [values['workdir'], values['bindir'], values['rpmdir'], values['backupdir']].each do |test_dir|
    information_message(values, "Checking #{test_dir} directory")
    check_dir_exists(values, test_dir)
    check_dir_owner(values, test_dir, values['uid'])
  end
  values
end

# Check script is executable

def check_file_executable(values, file_name)
  if File.exist?(file_name) && !File.executable?(file_name)
    message = "Information:\tMaking '#{file_name}' executable"
    command = "chmod +x '#{file_name}'"
    execute_command(values, message, command)
  end
  nil
end

# Print valid list

def print_valid_list(values, message, valid_list)
  verbose_message(values, '')
  verbose_message(values, message)
  verbose_message(values, '')
  verbose_message(values, 'Available values:')
  verbose_message(values, '')
  valid_list.each do |item|
    verbose_message(values, item)
  end
  verbose_message(values, '')
  nil
end

# Print change log

def print_changelog(values)
  if File.exist?('changelog')
    changelog = File.readlines('changelog')
    changelog = changelog.reverse
    changelog.each_with_index do |line, index|
      line = line.gsub(/^# /, '')
      next unless line.match(/^[0-9]/)

      verbose_message(line)
      text = changelog[index - 1].gsub(/^# /, '')
      verbose_message(values, text)
      verbose_message(values, '')
    end
  end
  nil
end

# Check default dpool

def check_dpool(values)
  message = "Information:\tChecking for alternate pool for LDoms"
  command = "zfs list |grep \"^#{values['dpool']}\""
  output  = execute_command(values, message, command)
  values['dpool'] = 'rpool' unless output.match(/dpool/)
  nil
end

# Copy packages to local packages directory

def download_pkg(values, remote_file)
  local_file = File.basename(remote_file)
  unless File.exist?(local_file)
    message = "Information:\tFetching #{remote_file} to #{local_file}"
    command = "wget #{remote_file} -O #{local_file}"
    execute_command(values, message, command)
  end
  nil
end

# Get install type from file

def get_install_type_from_file(values)
  values['type'] = case values['file'].downcase
                   when /vcsa/
                     'vcsa'
                   else
                     File.extname(values['file']).downcase.split(/\./)[1]
                   end
  values['type']
end

# Check password

def check_password(install_password)
  unless install_password.match(/[A-Z]/)
    warning_message(values, 'Password does not contain and upper case character')
    quit(values)
  end
  unless install_password.match(/[0-9]/)
    warning_message(values, 'Password does not contain a number')
    quit(values)
  end
  nil
end

# Check ovftool is installed

def check_ovftool_exists(values)
  check_osx_ovftool(values) if values['host-os-uname'].to_s.match(/Darwin/)
  nil
end

# Detach DMG

def detach_dmg(tmp_dir)
  `sudo hdiutil detach "#{tmp_dir}'`
  nil
end

# Attach DMG

def attach_dmg(pkg_file, app_name)
  tmp_dir = `sudo sh -c 'echo Y | hdiutil attach "#{pkg_file}" |tail -1 |cut -f3-'`.chomp
  unless tmp_dir.match(/[a-z,A-Z]/)
    tmp_dir = `ls -rt /Volumes |grep "#{app_name}" |tail -1`.chomp
    tmp_dir = "/Volumes/#{tmp_dir}"
  end
  information_message(values, "DMG mounted on #{tmp_dir}")
  tmp_dir
end

# Check OSX ovftool

def check_osx_ovftool(values)
  values['ovfbin'] = '/Applications/VMware OVF Tool/ovftool'
  unless File.exist?(values['ovfbin'])
    warning_message(values, 'OVF Tool not installed')
    ovftool_dmg = values['ovfdmgurl'].split(/\?/)[0]
    ovftool_dmg = File.basename(ovftool_dmg)
    wget_file(values, values['ovfdmgurl'], ovftool_dmg)
    information_message(values, 'Installing OVF Tool')
    app_name = 'VMware OVF Tool'
    tmp_dir  = attach_dmg(ovftool_dmg, app_name)
    pkg_file = "#{tmp_dir}/VMware OVF Tool.pkg"
    message  = "Information:\tInstalling package #{pkg_file}"
    command  = "/usr/sbin/installer -pkg #{pkg_bin} -target /"
    execute_command(values, message, command)
    detach_dmg(tmp_dir)
  end
  nil
end

# SCP file to remote host

def scp_file(values, local_file, remote_file)
  if values['verbose'] == true
    information_message(values,
                        "Copying file \"#{local_file}\" to \"#{values['server']}:#{remote_file}\"")
  end
  Net::SCP.start(values['server'], values['serveradmin'], password: values['serverpassword'],
                                                          paranoid: false) do |scp|
    scp.upload! local_file, remote_file
  end
  nil
end

# Execute SSH command

def execute_ssh_command(values, command)
  information_message(values, "Executing command \"#{command}\" on server #{values['server']}")
  Net::SSH.start(values['server'], values['serveradmin'], password: values['serverpassword'],
                                                          paranoid: false) do |ssh|
    ssh.exec!(command)
  end
  nil
end

# Get client config

def get_client_config(values)
  config_files = []
  values['clientdir'] = ''
  config_prefix = ''
  if values['vm'].to_s.match(/[a-z]/)
    show_vm_config(values)
  else
    values['clientdir'] = get_client_dir(values)
    if values['type'].to_s.match(/packer/) || values['clientdir'].to_s.match(/packer/)
      values['method'] = 'packer'
      values['clientdir'] = get_packer_client_dir(values)
    else
      values['service'] = get_install_service_from_client_name(values) unless values['service'].to_s.match(/[a-z]/)
      values['method']  = get_install_method(values) unless values['method'].to_s.match(/[a-z]/)
    end
    config_prefix = "#{values['clientdir']}/#{values['name']}"
    case values['method']
    when /packer/
      config_files[0] = "#{config_prefix}.json"
      config_files[1] = "#{config_prefix}.cfg"
      config_files[2] = "#{config_prefix}_first_boot.sh"
      config_files[3] = "#{config_prefix}_post.sh"
      config_files[4] = "#{values['clientdir']}/Autounattend.xml"
      config_files[5] = "#{values['clientdir']}/post_install.ps1"
    when /config|cfg|ks|Kickstart/
      config_files[0] = "#{config_prefix}.cfg"
    when /post/
      case method
      when /ps/
        config_files[0] = "#{config_prefix}_post.sh"
      end
    when /first/
      case method
      when /ps/
        config_files[0] = "#{config_prefix}_first_boot.sh"
      end
    end
    config_files.each do |config_file|
      print_contents_of_file(values, '', config_file) if File.exist?(config_file)
    end
  end
  nil
end

# Get client install service for a client

def get_install_service(values)
  values['clientdir'] = get_client_dir(values)
  values['service']   = values['clientdir'].split(%r{/})[-2]
  values['service']
end

# Get install method from service

def get_install_method(values)
  if values['vm'].to_s.match(/mp|multipass/) && (values['method'] == values['empty'])
    values['method'] = 'mp'
    return values['method']
  end
  values['service'] = get_install_service(values) unless values['service'].to_s.match(/[a-z]/)
  service_dir = "#{values['baserepodir']}/#{values['service']}"
  if File.directory?(service_dir) || File.symlink?(service_dir)
    information_message(values, "Found directory #{service_dir}")
    information_message(values, 'Determining service type')
  else
    warning_message(values, "Service #{values['service']} does not exist")
  end
  values['method'] = ''
  test_file = "#{service_dir}/vmware-esx-base-osl.txt"
  if File.exist?(test_file)
    values['method'] = 'vs'
  else
    test_file = "#{service_dir}/repodata"
    if File.exist?(test_file)
      values['method'] = 'ks'
    else
      test_dir = "#{service_dir}/preseed"
      values['method'] = 'ps' if File.directory?(test_dir)
    end
  end
  values['method']
end

# Unconfigure a server

def unconfigure_server(values)
  values['method'] = get_install_method(values) if values['method'] == values['empty']
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
    warning_message(values, "Could not determine service type for #{values['service']}")
  end
  nil
end

# list OS install ISOs

def list_os_isos(values)
  case values['os-type'].to_s
  when /linux/
    values['search'] = 'CentOS|OracleLinux|SUSE|SLES|SL|Fedora|ubuntu|debian|purity' unless values['search'].to_s.match(/[a-z]/)
  when /sol/
    'sol'
  when /esx|vmware|vsphere/
    'VMvisor'
  else
    list_all_isos(values)
    return
  end
  list_linux_isos(values) if values['os-type'].to_s.match(/linux/)
  nil
end

# List all isos

def list_all_isos(values)
  list_isos(values)
  nil
end

# Get install method from service name

def get_install_method_from_service(values)
  case values['service']
  when /vmware/
    values['method'] = 'vs'
  when /centos|oel|rhel|fedora|sl/
    values['method'] = 'ks'
  when /ubuntu|debian/
    values['method'] = 'ps'
  when /suse|sles/
    values['method'] = 'ay'
  when /sol_6|sol_7|sol_8|sol_9|sol_10/
    values['method'] = 'js'
  when /sol_11/
    values['method'] = 'ai'
  end
  values['method']
end

# Describe file

def describe_file(values)
  values = get_install_service_from_file(values)
  verbose_message(values, '')
  verbose_message(values, "Install File:\t\t#{values['file']}")
  verbose_message(values, "Install Service:\t#{values['service']}")
  verbose_message(values, "Install OS:\t\t#{values['os-type']}")
  verbose_message(values, "Install Method:\t\t#{values['method']}")
  verbose_message(values, "Install Release:\t#{values['release']}")
  verbose_message(values, "Install Architecture:\t#{values['arch']}")
  verbose_message(values, "Install Label:\t#{values['label']}")
  nil
end

# Get install service from ISO file name

def get_install_service_from_file(values)
  service_version = ''
  values['service'] = ''
  values['service'] = ''
  values['arch']    = ''
  values['release'] = ''
  values['method']  = ''
  values['label']   = ''
  values['arch'] = if values['file'].to_s.match(/amd64|x86_64/) || values['vm'].to_s.match(/kvm/)
                     'x86_64'
                   elsif values['file'].to_s.match(/arm/)
                     if values['file'].to_s.match(/64/)
                       'arm64'
                     else
                       'arm'
                     end
                   else
                     'i386'
                   end
  case values['file'].to_s
  when /purity/
    values['service'] = 'purity'
    values['release'] = values['file'].split(/_/)[1]
    values['arch']    = 'x86_64'
    service_version = "#{values['release']}_#{values['arch']}"
    values['method']  = 'ps'
  when /ubuntu|cloudimg|[a-z]-desktop|[a-z]-live-server/
    values['service'] = 'ubuntu'
    values['os-type'] = if values['vm'].to_s.match(/kvm/)
                          'linux'
                        else
                          'ubuntu'
                        end
    if values['file'].to_s.match(/cloudimg|[a-z]-desktop|[a-z]-live-server/)
      values['method']  = 'ci'
      values['release'] = get_release_version_from_code_name(values['file'].to_s)
      if values['release'].to_s.match(/[0-9][0-9]/)
        values['arch'] = if values['file'].to_s.match(/-arm/)
                           values['file'].to_s.split(/-/)[-1].split(/\./)[0]
                         else
                           values['file'].to_s.split(/-/)[3].split(/\./)[0].gsub(/amd64/, 'x86_64')
                         end
      else
        values['release'] = values['file'].to_s.split(/-/)[1].split(/\./)[0..1].join('.')
        values['arch']    = values['file'].to_s.split(/-/)[4].split(/\./)[0].gsub(/amd64/, 'x86_64')
      end
      service_version = "#{values['service']}_#{values['release'].to_s.gsub(/\./, '_')}#{values['arch']}#{self}"
      values['os-type'] = 'linux'
      values['os-variant'] = "ubuntu#{values['release']}"
    else
      service_version = values['file'].to_s.split(/-/)[1].gsub(/\./, '_').gsub(/_iso/, '')
      if values['file'].to_s.match(/live/)
        values['method'] = 'ci'
        service_version = "#{service_version}_live_#{values['arch']}"
      else
        values['method'] = 'ps'
        service_version   = "#{service_version}_#{values['arch']}"
      end
      values['release'] = values['file'].to_s.split(/-/)[1].split(/\./).join('.')
    end
    #    if values['release'].to_s.split(".")[0].to_i > 20
    #      values['release'] = "20.04"
    #    end
    values['os-variant'] = "ubuntu#{values['release']}"
    values['livecd'] = true if values['file'].to_s.match(/live/)
  when /purity/
    values['service'] = 'purity'
    service_version = values['file'].to_s.split(/_/)[1]
    values['method']  = 'ps'
    values['arch']    = 'x86_64'
  when /vCenter-Server-Appliance|VCSA/
    values['service'] = 'vcsa'
    service_version = values['file'].to_s.split(/-/)[3..4].join('.').gsub(/\./, '_').gsub(/_iso/, '')
    values['method']  = 'image'
    values['release'] = values['file'].to_s.split(/-/)[3..4].join('.').gsub(/\.iso/, '')
    values['arch']    = 'x86_64'
  when /VMvisor-Installer/
    values['service'] = 'vmware'
    values['arch']    = 'x86_64'
    service_version = "#{values['file'].to_s.split(/-/)[3].gsub(/\./, '_')}_#{values['arch']}"
    values['method']  = 'vs'
    values['release'] = values['file'].to_s.split(/-/)[3].gsub(/update/, '')
    values['os-variant'] = 'unknown'
  when /CentOS/
    values['service'] = 'centos'
    service_version = values['file'].to_s.split(/-/)[1..2].join('.').gsub(/\./, '_').gsub(/_iso/, '')
    values['os-type'] = values['service']
    values['method']  = 'ks'
    values['release'] = values['file'].to_s.split(/-/)[1]
    if values['release'].to_s.match(/^7/)
      case values['file']
      when /1406/
        values['release'] = '7.0'
      when /1503/
        values['release'] = '7.1'
      when /1511/
        values['release'] = '7.2'
      when /1611/
        values['release'] = '7.3'
      when /1708/
        values['release'] = '7.4'
      when /1804/
        values['release'] = '7.5'
      when /1810/
        values['release'] = '7.6'
      end
      service_version = "#{values['release'].gsub(/\./, '_')}_#{values['arch']}"
    end
  when /Fedora-Server/
    values['service'] = 'fedora'
    if values['file'].to_s.match(/DVD/)
      service_version = values['file'].split(/-/)[-1].gsub(/\./, '_').gsub(/_iso/, '_')
      service_arch    = values['file'].split(/-/)[-2].gsub(/\./, '_').gsub(/_iso/, '_')
      values['release'] = values['file'].split(/-/)[-1].gsub(/\.iso/, '')
    else
      service_version = values['file'].split(/-/)[-2].gsub(/\./, '_').gsub(/_iso/, '_')
      service_arch    = values['file'].split(/-/)[-3].gsub(/\./, '_').gsub(/_iso/, '_')
      values['release'] = values['file'].split(/-/)[-2].gsub(/\.iso/, '')
    end
    service_version = "#{service_version}_#{service_arch}"
    values['method']  = 'ks'
  when /OracleLinux/
    values['service'] = 'oel'
    service_version = values['file'].split(/-/)[1..2].join('.').gsub(/\./, '_').gsub(/R|U/, '')
    service_arch    = values['file'].split(/-/)[-2]
    service_version = "#{service_version}_#{service_arch}"
    values['release'] = values['file'].split(/-/)[1..2].join('.').gsub(/[a-z,A-Z]/, '')
    values['method']  = 'ks'
  when /openSUSE/
    values['service'] = 'opensuse'
    service_version = values['file'].split(/-/)[1].gsub(/\./, '_').gsub(/_iso/, '')
    service_arch    = values['file'].split(/-/)[-1].gsub(/\./, '_').gsub(/_iso/, '')
    service_version = "#{service_version}_#{service_arch}"
    values['method']  = 'ay'
    values['release'] = values['file'].split(/-/)[1]
  when /rhel/
    values['service'] = 'rhel'
    values['method']  = 'ks'
    if values['file'].to_s.match(/beta|8\.[0-9]/)
      service_version = values['file'].split(/-/)[1..2].join('.').gsub(/\./, '_').gsub(/_iso/, '')
      values['release'] = values['file'].split(/-/)[1]
    elsif values['file'].to_s.match(/server/)
      service_version = values['file'].split(/-/)[2..3].join('.').gsub(/\./, '_').gsub(/_iso/, '')
      values['release'] = values['file'].split(/-/)[2]
    else
      service_version = values['file'].split(/-/)[1..2].join('.').gsub(/\./, '_').gsub(/_iso/, '')
      values['release'] = values['file'].split(/-/)[1]
    end
  when /Rocky|Alma/
    values['service'] = File.basename(values['file']).to_s.split(/-/)[0].downcase.gsub(/linux/, '')
    values['method']  = 'ks'
    service_version = values['file'].split(/-/)[1..2].join('.').gsub(/\./, '_').gsub(/_iso/, '')
    values['release'] = values['file'].split(/-/)[1]
  when /SLE/
    values['service'] = 'sles'
    service_version = values['file'].split(/-/)[1..2].join('_').gsub(/[A-Z]/, '')
    service_arch    = values['file'].split(/-/)[4]
    service_arch = values['file'].split(/-/)[5] if service_arch.match(/DVD/)
    service_version = "#{service_version}_#{service_arch}"
    values['method']  = 'ay'
    values['release'] = values['file'].split(/-/)[1]
  when /sol/
    values['service'] = 'sol'
    values['release'] = values['file'].split(/-/)[1].gsub(/_/, '.')
    if values['release'].to_i > 10
      values['release'] = '11.0' if values['file'].to_s.match(/1111/)
      values['method'] = 'ai'
      values['arch']   = 'x86_64'
    else
      values['release'] = values['file'].split(/-/)[1..2].join('.').gsub(/u/, '')
      values['method']  = 'js'
      values['arch']    = 'i386'
    end
    service_version = "#{values['release']}_#{values['arch']}"
    service_version = service_version.gsub(/\./, '_')
  when /V[0-9][0-9][0-9][0-9][0-9]/
    isofile_bin = %(which isofile).chomp
    if isofile_bin.match(/not found/)
      values = install_package('cdrtools')
      isofile_bin = `which isofile`.chomp
      if isofile_bin.match(/not found/)
        warning_message(values, 'Utility isofile not found')
        quit(values)
      end
    end
    values['service'] = 'oel'
    values['method']  = 'ks'
    volume_id_info  = `isoinfo -d -i "#{values['file']}" |grep "^Volume id" |awk '{print $3}'`.chomp
    service_arch    = volume_id_info.split(/-/)[-1]
    service_version = volume_id_info.split(/-/)[1..2].join('_')
    service_version = "#{service_version}-#{service_arch}"
    values['release'] = volume_id_info.split(/-/)[1]
  when /[0-9][0-9][0-9][0-9]|Win|Srv/
    values['service'] = 'windows'
    mount_iso(values)
    wim_file = "#{values['mountdir']}/sources/install.wim"
    if File.exist?(wim_file)
      wiminfo_bin = `which wiminfo`
      unless wiminfo_bin.match(/wiminfo/)
        if values['host-os-uname'].to_s.match(/Darwin/)
          install_package(values, 'wimlib')
        elsif values['host-lsb-description'].to_s.match(/Endeavour|Arch/)
          install_package(values, 'wimlib')
        else
          install_package(values, 'wimtools')
        end
        wiminfo_bin = `which wiminfo`
        unless wiminfo_bin.match(/wiminfo/)
          warning_message(values, 'Cannnot find wiminfo (required to determine version of windows from ISO)')
          quit(values)
        end
      end
      message = "Information:\tDeterming version of Windows from: #{wim_file}"
      command = "wiminfo \"#{wim_file}\" 1| grep ^Description"
      output  = execute_command(values, message, command)
      values['label'] = output.chomp.split(/:/)[1].gsub(/^\s+/, '').gsub(/CORE/, '')
      service_version = output.split(/Description:/)[1].gsub(/^\s+|SERVER|Server/, '').downcase.gsub(/\s+/,
                                                                                                     '_').split(/_/)[1..].join('_')
      message = "Information:\tDeterming architecture of Windows from: #{wim_file}"
      command = "wiminfo \"#{wim_file}\" 1| grep ^Architecture"
      output  = execute_command(values, message, command)
      values['arch'] = output.chomp.split(/:/)[1].gsub(/^\s+/, '')
      umount_iso(values)
    end
    service_version = "#{service_version}_#{values['release']}_#{values['arch']}"
    service_version = service_version.gsub(/__/, '_')
    values['method'] = 'pe'
  end
  if values['vm'].to_s.match(/kvm/)
    values['os-type'] = if values['file'].to_s.match(/cloudimg/) && values['file'].to_s.match(/ubuntu/)
                          'linux'
                        elsif values['vm'].to_s.match(/kvm/)
                          'linux'
                        else
                          values['service']
                        end
  end
  values['service'] = "#{values['service']}_#{service_version.gsub(/__/, '_')}"
  if values['file'].to_s.match(/-arm/) && values['service'].to_s.match(/ubuntu/)
    values['service'] = if values['file'].to_s.match(/live/)
                          "ubuntu_#{values['release']}_#{values['arch']}_live"
                        else
                          "ubuntu_#{values['release']}_#{values['arch']}"
                        end
    values['service'] = values['service'].gsub(/\./, '_')
  end
  information_message(values, "Setting service name to #{values['service']}")
  information_message(values, "Setting OS name to #{values['os-type']}")
  values
end

# Get arch from ISO

def get_install_arch_from_file(values)
  iso_file = File.basename(values['file']) if values['file'].to_s.match(%r{/})
  case iso_file
  when /386/
    values['arch'] = 'i386'
  when /amd64|x86/
    values['arch'] = 'x86_64'
  when /arm64/
    values['arch'] = 'arm64'
  when /arm/
    values['arch'] = 'arm'
  when /sparc/
    values['arch'] = 'sparc'
  end
  values['arch']
end

# Get Install method from ISO file name

def get_install_method_from_iso(values)
  iso_file = File.basename(values['file']) if values['file'].to_s.match(%r{/})
  case iso_file
  when /VMware-VMvisor/
    values['method'] = 'vs'
  when /CentOS|OracleLinux|^SL|Fedora|rhel|V[0-9][0-9][0-9][0-9]/
    values['method'] = 'ks'
  when /ubuntu|debian|purity/
    values['method'] = 'ps'
  when /SUSE|SLE/
    values['method'] = 'ay'
  when /sol-6|sol-7|sol-8|sol-9|sol-10/
    values['method'] = 'js'
  when /sol-11/
    values['method'] = 'ai'
  when /Win|WIN|srv|EVAL|eval|win/
    values['method'] = 'pe'
  end
  values['method']
end

# Configure a service

def configure_server(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    check_osx_dhcpd_installed(values)
    create_osx_dhcpd_plist(values)
  end
  unless values['method'].to_s.match(/[a-z,A-Z]/)
    if !values['file'].to_s.match(/[a-z,A-Z]/)
      warning_message(values, 'Could not determine service name')
      quit(values)
    else
      values['method'] = get_install_method_from_iso(values)
    end
  end
  eval "[configure_#{values['method']}_server(values)]"
  nil
end

# Generate MAC address

def generate_mac_address(values)
  if values['vm'].to_s.match(/fusion|vbox/)
    '00:05:' + (1..4).map { '%0.2X' % rand(256) }.join(':')
  elsif values['vm'].to_s.match(/kvm/)
    '52:54:00:' + (1..3).map { '%0.2X' % rand(256) }.join(':')
  else
    (1..6).map { '%0.2X' % rand(256) }.join(':')
  end
end

# List all image services - needs code

def list_image_services(_values)
  nil
end

# List all image ISOs - needs code

def list_image_isos(_values)
  nil
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
    list_items(values) if values['dir'] != values['empty']
  end
  nil
end

# List all services

def list_all_services(values)
  verbose_message(values, '')
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
  nil
end

# Check hostname validity

def check_hostname(values)
  host_chars = values['name'].split
  host_chars.each do |char|
    unless char.match(/[a-z,A-Z,0-9]|-/)
      verbose_message(values, "Invalid hostname: #{values['name'].join}")
      quit(values)
    end
  end
end

# Get ISO list

def get_dir_item_list(values)
  full_list = get_base_dir_list(values)
  return full_list if values['os-type'] == values['empty'] && values['search'] == values['empty'] && values['method'] == values['empty']

  other_search = values['search'] if values['search'] != values['empty']
  if values['os-type'] != values['empty']
    case values['os-type'].downcase
    when /pe|win/
      os_search = 'OEM|win|Win|EVAL|eval'
    when /oel|oraclelinux/
      os_search = 'OracleLinux'
    when /sles/
      os_search = 'SLES'
    when /centos/
      os_search = 'CentOS'
    when /suse/
      os_search = 'openSUSE'
    when /ubuntu/
      os_search = if values['vm'].to_s.match(/kvm/)
                    'linux'
                  else
                    'ubuntu'
                  end
    when /debian/
      os_search = 'debian'
    when /purity/
      os_search = 'purity'
    when /fedora/
      os_search = 'Fedora'
    when /scientific|sl/
      os_search = 'SL'
    when /redhat|rhel/
      os_search = 'rhel'
    when /sol/
      os_search = 'sol'
    when /^linux/
      os_search = 'CentOS|OracleLinux|SLES|openSUSE|ubuntu|debian|Fedora|rhel|SL'
    when /vmware|vsphere|esx/
      os_search = 'VMware-VMvisor'
    end
  end
  if values['method'] != values['empty']
    case values['method'].to_s
    when /kick|ks/
      method_search = 'CentOS|OracleLinux|Fedora|rhel|SL|VMware'
    when /jump|js/
      method_search = 'sol-10'
    when /ai/
      method_search = 'sol-11'
    when /yast|ay/
      method_search = 'SLES|openSUSE'
    when /preseed|ps/
      method_search = 'debian|ubuntu|purity'
    when /ci/
      method_search = 'live'
    when /vs/
      method_search = 'VMvisor'
    when /xb/
      method_search = 'FreeBSD|install'
    end
  end
  if values['release'].to_s.match(/[0-9]/)
    case values['os-type']
    when 'OracleLinux'
      if values['release'].to_s.match(/\./)
        (major, minor) = values['release'].split(/\./)
        release_search = "-R#{major}-U#{minor}"
      else
        release_search = "-R#{values['release']}"
      end
    when /sol/
      if values['release'].to_s.match(/\./)
        (major, minor) = values['release'].split(/\./)
        release_search = if values['release'].to_s.match(/^10/)
                           "#{major}-u#{minor}"
                         else
                           "#{major}_#{minor}"
                         end
      end
      release_search = "-#{values['release']}"
    else
      release_search = "-#{values['release']}"
    end
  end
  if (values['arch'] != values['empty']) && values['arch'].to_s.match(/[a-z,A-Z]/)
    arch_search = values['arch'].gsub(/i386|x86_64/, 'x86') if values['os-type'].to_s.match(/sol/)
    arch_search = if values['os-type'].to_s.match(/ubuntu/)
                    values['arch'].gsub(/x86_64/, 'amd64')
                  else
                    values['arch'].gsub(/amd64/, 'x86_64')
                  end
  end
  results_list = full_list
  [os_search, method_search, release_search, arch_search, other_search].each do |search_string|
    next unless search_string

    next unless search_string != values['empty']

    results_list = results_list.grep(/#{search_string}/) if search_string.match(/[a-z,A-Z,0-9]/)
  end
  results_list = results_list.grep_v(/live/) if values['method'].to_s.match(/ps/)
  results_list
end

# Get item version information (e.g. ISOs, images, etc)

def get_item_version_info(file_name)
  iso_info = File.basename(file_name)
  iso_info = if file_name.match(/purity/)
               iso_info.split(/_/)
             else
               iso_info.split(/-/)
             end
  iso_distro = iso_info[0]
  iso_distro = iso_distro.downcase
  iso_distro = 'ubuntu' if file_name.match(/cloud/)
  iso_distro = 'sles' if iso_distro.match(/^sle$/)
  iso_distro = 'oel' if iso_distro.match(/oraclelinux/)
  if iso_distro.match(/centos|ubuntu|sles|sl|oel|rhel/)
    if file_name.match(/cloud/) && !file_name.match(/ubuntu/)
      iso_version = get_release_version_from_code_name(file_name)
    elsif iso_distro.match(/sles/)
      if iso_info[2].to_s.match(/Server/)
        iso_version = "#{iso_info[1]}.0"
      else
        iso_version = "#{iso_info[1]}.#{iso_info[2]}"
        iso_version = iso_version.gsub(/SP/, '')
      end
    elsif iso_distro.match(/sl$/)
      iso_version = iso_info[1].split(//).join('.')
      iso_version += '.0' if iso_version.length == 1
    elsif iso_distro.match(/oel|rhel/)
      if file_name =~ /-rc-/
        iso_version = iso_info[1..3].join('.')
        iso_version = iso_version.gsub(/server/, '')
      else
        iso_version = iso_info[1..2].join('.')
        iso_version = iso_version.gsub(/[a-z,A-Z]/, '')
      end
      iso_version = iso_version.gsub(/^\./, '')
    else
      iso_version = iso_info[1]
    end
    iso_version = iso_info[1] if iso_version.match(/86_64/)
    iso_version += '_live' if file_name.match(/live/)
    case file_name
    when /workstation|desktop/
      iso_version += '_desktop'
    when /server/
      iso_version += '_server'
    end
    iso_version += '_cloud' if file_name.match(/cloud/)
    iso_arch = case file_name
               when /i[3-6]86/
                 'i386'
               when /x86_64|amd64/
                 'x86_64'
               else
                 if file_name.match(/ubuntu/)
                   iso_info[-1].split('.')[0]
                 elsif iso_distro.match(/centos|sl$/)
                   iso_info[2]
                 elsif iso_distro.match(/sles|oel/)
                   iso_info[4]
                 else
                   iso_info[3]
                 end
               end
  else
    case iso_distro
    when /fedora/
      iso_version = iso_info[1]
      iso_arch    = iso_info[2]
    when /purity/
      iso_version = iso_info[1]
      iso_arch    = 'x86_64'
    when /vmware/
      iso_release = iso_info[3].gsub(/U/, '.')
      iso_update  = iso_info[4].split(/\./)[0]
      iso_version = "#{iso_release}.#{iso_update}"
      iso_arch    = 'x86_64'
    else
      iso_version = iso_info[2]
      iso_arch    = iso_info[3]
    end
  end
  [iso_distro, iso_version, iso_arch]
end

# List ISOs

def list_isos(values)
  list_items(values)
  nil
end

# List items (ISOs, images, etc)

def list_items(values)
  if !values['output'].to_s.match(/html/) && !values['vm'].to_s.match(/mp|multipass/)
    string = "Information:\tDirectory #{values['isodir']}"
    verbose_message(values, string)
  end
  if values['file'] == values['empty']
    iso_list = get_base_dir_list(values)
  else
    iso_list    = []
    iso_list[0] = values['file']
  end
  if iso_list.length.positive?
    if values['output'].to_s.match(/html/)
      verbose_message(values, '<h1>Available ISO(s)/Image(s):</h1>')
      verbose_message(values, '<table border="1">')
      verbose_message(values, '<tr>')
      verbose_message(values, '<th>ISO/Image File</th>')
      verbose_message(values, '<th>Distribution</th>')
      verbose_message(values, '<th>Version</th>')
      verbose_message(values, '<th>Architecture</th>')
      verbose_message(values, '<th>Service Name</th>')
      verbose_message(values, '</tr>')
    else
      verbose_message(values, 'Available ISO(s)/Images(s):')
      verbose_message(values, '')
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
        verbose_message(values, '<tr>')
        verbose_message(values, "<td>#{file_name}</td>")
        verbose_message(values, "<td>#{linux_distro}</td>")
        verbose_message(values, "<td>#{iso_version}</td>")
        verbose_message(values, "<td>#{iso_arch}</td>")
      else
        verbose_message(values, "ISO/Image file:\t#{file_name}")
        verbose_message(values, "Distribution:\t#{linux_distro}")
        verbose_message(values, "Version:\t#{iso_version}")
        verbose_message(values, "Architecture:\t#{iso_arch}")
      end
      iso_version = iso_version.gsub(/\./, '_')
      values['service'] =
        "#{linux_distro.downcase.gsub(/\s+|\.|-/, '_').gsub(/_lts_/, '')}_#{iso_version}_#{iso_arch}"
      values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
      if File.directory?(values['repodir'])
        if values['output'].to_s.match(/html/)
          verbose_message(values, "<td>#{values['service']} (exists)</td>")
        else
          verbose_message(values, "Service Name:\t#{values['service']} (exists)")
        end
      elsif values['output'].to_s.match(/html/)
        verbose_message(values, "<td>#{values['service']}</td>")
      else
        verbose_message(values, "Service Name:\t#{values['service']}")
      end
      if values['output'].to_s.match(/html/)
        verbose_message(values, '</tr>')
      else
        verbose_message(values, '')
      end
    end
    verbose_message(values, '</table>') if values['output'].to_s.match(/html/)
  end
  nil
end

# Connect to virtual serial port

def connect_to_virtual_serial(values)
  if values['vm'].to_s.match(/ldom|gdom/)
    connect_to_gdom_console(values)
  else
    verbose_message(values, '')
    verbose_message(values, "Connecting to serial port of #{values['name']}")
    verbose_message(values, '')
    verbose_message(values, 'To disconnect from this session use CTRL-Q')
    verbose_message(values, '')
    verbose_message(values, 'If you wish to re-connect to the serial console of this machine,')
    verbose_message(values, 'run the following command:')
    verbose_message(values, '')
    verbose_message(values, "#{values['script']} --action=console --vm=#{values['vm']} --name = #{values['name']}")
    verbose_message(values, '')
    verbose_message(values, 'or:')
    verbose_message(values, '')
    verbose_message(values, "socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
    verbose_message(values, '')
    verbose_message(values, '')
    system("socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
  end
  nil
end

# Set some VMware ESXi VM defaults

def configure_vmware_esxi_defaults(values)
  values['memory']     = '4096'
  values['vcpus']      = '4'
  values['os-type']    = 'ESXi'
  values['controller'] = 'ide'
  values['os-variant'] = 'unknown'
  nil
end

# Set some VMware vCenter defaults

def configure_vmware_vcenter_defaults(values)
  values['memory']     = '4096'
  values['vcpus']      = '4'
  values['os-type']    = 'ESXi'
  values['controller'] = 'ide'
  values['os-variant'] = 'unknown'
  nil
end

# Get Install Service from client name

def get_install_service_from_client_name(values)
  values['service'] = ''
  message = "Information:\tFinding client configuration directory for #{values['name']}"
  command = "find #{values['clientdir']} -name #{values['name']} |grep '#{values['name']}$'"
  values['clientdir'] = execute_command(values, message, command)
  values['clientdir'] = values['clientdir'].chomp
  if File.directory?(values['clientdir'])
    information_message(values, "No client directory found for #{values['name']}")
  else
    information_message(values, "Client directory found #{values['clientdir']}")
    information_message(values, 'Install method is packer') if values['clientdir'].to_s.match(/packer/)
  end
  values['service']
end

# Get client directory

def get_client_dir(values)
  message = "Information:\tFinding client configuration directory for #{values['name']}"
  command = "find #{values['clientdir']} -name #{values['name']} |grep '#{values['name']}$'"
  values['clientdir'] = execute_command(values, message, command).chomp
  if File.directory?(values['clientdir'])
    information_message(values, "No client directory found for #{values['name']}")
  else
    information_message(values, "Client directory found #{values['clientdir']}")
  end
  values['clientdir']
end

# Delete client directory

def delete_client_dir(values)
  values['clientdir'] = get_client_dir(values)
  if File.directory?(values['clientdir']) && values['clientdir'].to_s.match(/[a-z]/)
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
  nil
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
  nil
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
  nil
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
  nil
end

# List clients for an install service

def list_clients(values)
  case values['method'].downcase
  when /ai/
    list_ai_clients(values)
    return
  when /js|jumpstart/
    search_string = 'sol_6|sol_7|sol_8|sol_9|sol_10'
  when /ks|kickstart/
    search_string = 'centos|redhat|rhel|scientific|fedora'
  when /ps|preseed/
    search_string = 'debian|ubuntu'
  when /ci/
    search_string = 'live'
  when /vmware|vsphere|esx|vs/
    search_string = 'vmware'
  when /ay|autoyast/
    search_string = 'suse|sles'
  when /xb/
    search_string = 'bsd|coreos'
  end
  service_list = Dir.entries(values['clientdir'])
  service_list = service_list.grep(/#{search_string}|#{values['service']}/)
  if service_list.length.positive?
    if values['output'].to_s.match(/html/)
      if values['service'].to_s.match(/[a-z,A-Z]/)
        verbose_message(values, "<h1>Available #{values['service']} clients:</h1>")
      else
        verbose_message(values, '<h1>Available clients:</h1>')
      end
      verbose_message(values, '<table border="1">')
      verbose_message(values, '<tr>')
      verbose_message(values, '<th>Client</th>')
      verbose_message(values, '<th>Service</th>')
      verbose_message(values, '<th>IP</th>')
      verbose_message(values, '<th>MAC</th>')
      verbose_message(values, '</tr>')
    else
      verbose_message(values, '')
      if values['service'].to_s.match(/[a-z,A-Z]/)
        verbose_message(values, "Available #{values['service']} clients:")
      else
        verbose_message(values, 'Available clients:')
      end
      verbose_message(values, '')
    end
    service_list.each do |service_name|
      next unless service_name.match(/#{search_string}|#{service_name}/) && service_name.match(/[a-z,A-Z]/)

      values['repodir'] = "#{values['clientdir']}/#{values['service']}"
      next unless File.directory?(values['repodir']) || File.symlink?(values['repodir'])

      client_list = Dir.entries(values['repodir'])
      client_list.each do |client_name|
        next unless client_name.match(/[a-z,A-Z,0-9]/)

        values['clientdir'] = "#{values['repodir']}/#{client_name}"
        values['ip']  = get_install_ip(values)
        values['mac'] = get_install_mac(values)
        if File.directory?(values['clientdir'])
          if values['output'].to_s.match(/html/)
            verbose_message(values, '<tr>')
            verbose_message(values, "<td>#{client_name}</td>")
            verbose_message(values, "<td>#{service_name}</td>")
            verbose_message(values, "<td>#{client_ip}</td>")
            verbose_message(values, "<td>#{client_mac}</td>")
            verbose_message(values, '</tr>')
          else
            verbose_message(values,
                            "#{client_name}\t[ service = #{service_name}, ip = #{client_ip}, mac = #{client_mac} ] ")
          end
        end
      end
    end
    verbose_message(values, '</table>') if values['output'].to_s.match(/html/)
  end
  verbose_message(values, '')
  nil
end

# List appliances

def list_ovas(values)
  file_list = Dir.entries(values['isodir'])
  verbose_message(values, '')
  verbose_message(values, 'Virtual Appliances:')
  verbose_message(values, '')
  file_list.each do |file_name|
    verbose_message(file_name) if file_name.match(/ova$/)
  end
  verbose_message(values, '')
end

# Check directory user ownership

def check_dir_owner(values, dir_name, dir_uid)
  message = "Information:\tChecking directory #{dir_name} is owned by user #{dir_uid}"
  verbose_message(values, message)
  if dir_name.match(%r{^/$}) || (dir_name == '')
    warning_message(values, 'Directory name not set')
    quit(values)
  end
  if (values['dryrun'] == true) && !Dir.exist?(dir_name)
    message = "Warning:\tDirectory #{dir_name} does not exist"
    verbose_message(values, message)
  else
    test_uid = File.stat(dir_name).uid
    if test_uid.to_i != dir_uid.to_i
      message = "Information:\tChanging ownership of #{dir_name} to #{dir_uid}"
      command = if dir_name.to_s.match(%r{^/etc})
                  "sudo chown -R #{dir_uid} \"#{dir_name}\""
                else
                  "chown -R #{dir_uid} \"#{dir_name}\""
                end
      execute_command(values, message, command)
      message = "Information:\tChanging permissions of #{dir_name} to #{dir_uid}"
      command = if dir_name.to_s.match(%r{^/etc})
                  "sudo chmod -R u+w \"#{dir_name}\""
                else
                  "chmod -R u+w \"#{dir_name}\""
                end
      execute_command(values, message, command)
    end
  end
  nil
end

# Check directory group read ownership

def check_dir_group(values, dir_name, dir_gid, dir_mode)
  if dir_name.match(%r{^/$}) || (dir_name == '')
    warning_message(values, 'Directory name not set')
    quit(values)
  end
  if File.directory?(dir_name)
    test_gid = File.stat(dir_name).gid
    if test_gid.to_i != dir_gid.to_i
      message = "Information:\tChanging group ownership of #{dir_name} to #{dir_gid}"
      command = if dir_name.to_s.match(%r{^/etc})
                  "sudo chgrp -R #{dir_gid} \"#{dir_name}\""
                else
                  "chgrp -R #{dir_gid} \"#{dir_name}\""
                end
      execute_command(values, message, command)
      message = "Information:\tChanging group permissions of #{dir_name} to #{dir_gid}"
      command = if dir_name.to_s.match(%r{^/etc})
                  "sudo chmod -R g+#{dir_mode} \"#{dir_name}\""
                else
                  "chmod -R g+#{dir_mode} \"#{dir_name}\""
                end
      execute_command(values, message, command)
    end
  else
    message = "Warning:\tDirectory #{dir_name} does not exist"
    verbose_message(values, message)
  end
  nil
end

# Check user member of group

def check_group_member(values, user_name, group_name)
  message = "Information:\tChecking user #{user_name} is a member group #{group_name}"
  command = if values['host-os-uname'].to_s.match(/Darwin/)
              "dscacheutil -q group -a name #{group_name} |grep users"
            else
              "getent group #{group_name}"
            end
  output = execute_command(values, message, command)
  unless output.match(/#{user_name}/)
    message = "Information:\tAdding user #{user_name} to group #{group_name}"
    command = "usermod -a -G #{group_name} #{user_name}"
    execute_command(values, message, command)
  end
  nil
end

# Check file permissions

def check_file_perms(values, file_name, file_perms)
  if File.exist?(file_name)
    message = "Information:\tChecking permissions of file #{file_name} and set to #{file_perms}"
    command = if values['host-os-uname'].to_s.match(/Darwin/)
                "stat -f %p #{file_name}"
              else
                "stat -c %a #{file_name}"
              end
    test_perms = execute_command(values, message, command)
    unless test_perms.match(/#{file_perms}$/)
      message = "Information:\tSetting permissions of file #{file_name} to #{file_perms}"
      command = "sudo chmod #{file_perms} #{file_name}"
      execute_command(values, message, command)
    end
  else
    message = "Warning:\tFile #{file_name} does not exist"
    verbose_message(values, message)
  end
  nil
end

def check_file_mode(values, file_name, file_mode)
  check_file_perms(values, file_name, file_mode)
  nil
end

# Check file user ownership

def check_file_owner(values, file_name, file_uid)
  message = "Information:\tChecking file #{file_name} is owned by user #{file_uid}"
  verbose_message(values, message)
  file_uid = `id -u #{file_uid}` if file_uid.to_s.match(/[a-z]/)
  if File.exist?(file_name)
    test_uid = File.stat(file_name).uid
    if test_uid != file_uid.to_i
      message = "Information:\tChanging ownership of #{file_name} to #{file_uid}"
      command = if file_name.to_s.match(%r{^/etc})
                  "sudo chown #{file_uid} #{file_name}"
                else
                  "chown #{file_uid} #{file_name}"
                end
      execute_command(values, message, command)
    end
  else
    message = "Warning:\tFile #{file_name} does not exist"
    verbose_message(values, message)
  end
  nil
end

# Get group gid

def get_group_gid(values, group)
  message = "Information:\tGetting GID of #{group}"
  command = "getent group #{group} |cut -f3 -d:"
  output  = execute_command(values, message, command)
  output.chomp
end

# Check file group ownership

def check_file_group(values, file_name, file_gid)
  message = "Information:\tChecking file #{file_name} is owned by group #{file_gid}"
  verbose_message(values, message)
  file_gid = get_group_gid(values, file_gid) if file_gid.to_s.match(/[a-z]/)
  if File.exist?(file_name)
    test_gid = File.stat(file_name).gid
    if test_gid != file_gid.to_i
      message = "Information:\tChanging group ownership of #{file_name} to #{file_gid}"
      command = "chgrp #{file_gid} \"#{file_name}\""
      execute_command(values, message, command)
    end
  else
    message = "Warning:\tFile #{file_name} does not exist"
    verbose_message(values, message)
  end
  nil
end

# Check Python module is installed

def check_python_module_is_installed(install_module)
  exists = false
  module_list = `pip listi | awk '{print $1}'`.split(/\n/)
  module_list.each do |module_name|
    exists = true if module_name.match(/^#{values['model']}$/)
  end
  if exists == false
    message = "Information:\tInstalling python model '#{install_module}'"
    command = "pip install #{install_module}"
    execute_command(values, message, command)
  end
  nil
end

# Mask contents of file

def mask_contents_of_file(file_name)
  input  = File.readlines(file_name)
  output = []
  input.each do |line|
    if line.match(/secret_key|access_key/) && !line.match(/\{\{/)
      (param, value) = line.split(/:/)
      value = value.gsub(/[A-Z]|[a-z]|[0-9]/, 'X')
      line  = "#{param}:#{value}"
    end
    output.push(line)
  end
  output
end

# Print contents of file

def print_contents_of_file(values, message, file_name)
  if (values['verbose'] == true) || values['output'].to_s.match(/html/)
    if File.exist?(file_name)
      output = if values['unmasked'] == false
                 mask_contents_of_file(file_name)
               else
                 File.readlines(file_name)
               end
      if values['output'].to_s.match(/html/)
        verbose_message(values, '<table border="1">')
        verbose_message(values, '<tr>')
        if message.length > 1
          verbose_message(values, "<th>#{message}</th>")
        else
          verbose_message(values, "<th>#{file_name}</th>")
        end
        verbose_message(values, '<tr>')
        verbose_message(values, '<td>')
        verbose_message(values, '<pre>')
        output.each do |line|
          verbose_message(values, line.to_s)
        end
        verbose_message(values, '</pre>')
        verbose_message(values, '</td>')
        verbose_message(values, '</tr>')
        verbose_message(values, '</table>')
      elsif values['verbose'] == true
        verbose_message(values, '')
        if message.length > 1
          information_message(values, message.to_s)
        else
          information_message(values, "Contents of file #{file_name}")
        end
        verbose_message(values, '')
        output.each do |line|
          verbose_message(values, line)
        end
        verbose_message(values, '')
      end
    else
      warning_message(values, "File #{file_name} does not exist")
    end
  end
  nil
end

# Show output of command

def show_output_of_command(message, output)
  if values['output'].to_s.match(/html/)
    verbose_message(values, '<table border="1">')
    verbose_message(values, '<tr>')
    verbose_message(values, "<th>#{message}</th>")
    verbose_message(values, '<tr>')
    verbose_message(values, '<td>')
    verbose_message(values, '<pre>')
    verbose_message(values, output.to_s)
    verbose_message(values, '</pre>')
    verbose_message(values, '</td>')
    verbose_message(values, '</tr>')
    verbose_message(values, '</table>')
  elsif values['verbose'] == true
    verbose_message(values, '')
    information_message(values, "#{message}:")
    verbose_message(values, '')
    verbose_message(values, output)
    verbose_message(values, '')
  end
  nil
end

# Check TFTP server

def check_tftp_server(values)
  if values['host-os-uname'].to_s.match(/SunOS/) && values['host-os-unamer'].match(/11/) && !File.exist?('/lib/svc/manifest/network/tftp-udp.xml')
    message = "Checking:\tTFTP entry in /etc/inetd.conf"
    command = "cat /etc/inetd.conf |grep '^tftp' |grep -v '^#'"
    output  = execute_command(values, message, command)
    unless output.match(/tftp/)
      message = "Information:\tCreating TFTP inetd entry"
      command = "echo \"tftp dgram udp wait root /usr/sbin/in.tftpd in.tftpd -s #{values['tftpdir']}\" >> /etc/inetd.conf"
      execute_command(values, message, command)
      message = "Information:\tImporting TFTP inetd entry into service manifest"
      command = 'inetconv -i /etc/inet/inetd.conf'
      execute_command(values, message, command)
      'svcadm restart svc:/system/manifest-import'
    end
  end
  nil
end

# Check bootparams entry

def add_bootparams_entry(values)
  found1    = false
  found2    = false
  file_name = '/etc/bootparams'
  boot_info = "root=#{values['hostip']}:#{values['repodir']}/Solaris_#{values['release']}/Tools/Boot install=#{values['hostip']}:#{values['repodir']} boottype=:in sysid_config=#{values['clientdir']} install_config=#{values['clientdir']} rootopts=:rsize=8192"
  if !File.exist?(file_name)
    message = "Information:\tCreating #{file_name}"
    command = "touch #{file_name}"
    execute_command(values, message, command)
    check_file_owner(values, file_name, values['uid'])
    File.open(file_name, 'w') { |f| f.write "#{values['mac']} #{values['name']}\n" }
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
  if (found1 == false) || (found2 == false)
    File.open(file_name, 'w') do |file|
      lines.each { |line| file.puts(line) }
    end
    if values['host-os-unamer'].to_s.match(/11/)
      message = "Information:\tRestarting bootparams service"
      command = 'svcadm restart svc:/network/rpc/bootparams:default'
      execute_command(values, message, command)
    end
  end
  nil
end

# Add NFS export

def add_nfs_export(values, export_name, export_dir)
  network_address = "#{values['publisherhost'].split(/\./)[0..2].join('.')}.0"
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['host-os-unamer'].match(/11/)
      message = "Enabling:\tNFS share on #{export_dir}"
      command = "zfs set sharenfs=on #{values['zpoolname']}#{export_dir}"
      execute_command(values, message, command)
      message = "Information:\tSetting NFS access rights on #{export_dir}"
      command = "zfs set share=name=#{export_name},path=#{export_dir},prot=nfs,anon=0,sec=sys,ro=@#{network_address}/24 #{values['zpoolname']}#{export_dir}"
      execute_command(values, message, command)
    else
      dfs_file = '/etc/dfs/dfstab'
      message  = "Checking:\tCurrent NFS exports for #{export_dir}"
      command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
      output   = execute_command(values, message, command)
      unless output.match(/#{export_dir}/)
        backup_file(values, dfs_file)
        export  = "share -F nfs -o ro=@#{network_address},anon=0 #{export_dir}"
        message = "Adding:\tNFS export for #{export_dir}"
        command = "echo '#{export}' >> #{dfs_file}"
        execute_command(values, message, command)
        message = "Refreshing:\tNFS exports"
        command = 'shareall -F nfs'
        execute_command(values, message, command)
      end
    end
  else
    dfs_file = '/etc/exports'
    message  = "Checking:\tCurrent NFS exports for #{export_dir}"
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(values, message, command)
    unless output.match(/#{export_dir}/)
      export = if values['host-os-uname'].to_s.match(/Darwin/)
                 "#{export_dir} -alldirs -maproot=root -network #{network_address} -mask #{values['netmask']}"
               else
                 "#{export_dir} #{network_address}/24(ro,no_root_squash,async,no_subtree_check)"
               end
      message = "Adding:\tNFS export for #{export_dir}"
      command = "echo '#{export}' >> #{dfs_file}"
      execute_command(values, message, command)
      message = "Refreshing:\tNFS exports"
      command = if values['host-os-uname'].to_s.match(/Darwin/)
                  'nfsd stop ; nfsd start'
                else
                  '/sbin/exportfs -a'
                end
      execute_command(values, message, command)
    end
  end
  nil
end

# Remove NFS export

def remove_nfs_export(export_dir)
  if values['host-os-uname'].to_s.match(/SunOS/)
    zfs_test = `zfs list |grep #{export_dir}`.chomp
    if zfs_test.match(/#{export_dir}/)
      message = "Disabling:\tNFS share on #{export_dir}"
      command = "zfs set sharenfs=off #{values['zpoolname']}#{export_dir}"
      execute_command(values, message, command)
    else
      information_message(values, "ZFS filesystem #{values['zpoolname']}#{export_dir} does not exist")
    end
  else
    dfs_file = '/etc/exports'
    message  = "Checking:\tCurrent NFS exports for #{export_dir}"
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(values, message, command)
    if output.match(/#{export_dir}/)
      backup_file(values, dfs_file)
      tmp_file = '/tmp/dfs_file'
      message  = "Removing:\tExport #{export_dir}"
      command  = "cat #{dfs_file} |grep -v '#{export_dir}' > #{tmp_file} ; cat #{tmp_file} > #{dfs_file} ; rm #{tmp_file}"
      execute_command(values, message, command)
      message = "Restarting:\tNFS daemons"
      command = if values['host-os-uname'].to_s.match(/Darwin/)
                  'nfsd stop ; nfsd start'
                else
                  'service nfsd restart'
                end
      execute_command(values, message, command)
    end
  end
  nil
end

# Check we are running on the right architecture

def check_same_arch(values)
  unless values['host-os-unamep'].to_s.match(/#{values['arch']}/)
    warning_message(values, 'System and Zone Architecture do not match')
    quit(values)
  end
  nil
end

# Delete file

def delete_file(values, file_name)
  return unless File.exist?(file_name)

  message = "Removing:\tFile #{file_name}"
  command = "rm #{file_name}"
  execute_command(values, message, command)
end

# Get root password crypt

def get_root_password_crypt(values)
  password = values['answers']['root_password'].value
  get_password_crypt(password)
end

# Get account password crypt

def get_admin_password_crypt(values)
  password = values['answers']['admin_password'].value
  get_password_crypt(password)
end

# Check SSH keys

def check_ssh_keys(values)
  ssh_key_file = values['sshkeyfile'].to_s
  ssh_key_type = values['sshkeytype'].to_s
  ssh_key_bits = values['sshkeybits'].to_s
  unless File.exist?(ssh_key_file)
    verbose_message(values, "Generating:\tPublic SSH key file #{ssh_key_file}")
    command = "ssh-keygen -t #{ssh_key_type} -b #{ssh_key_bits} -f #{ssh_key_file}"
    system(command)
  end
  nil
end

# Check IPS tools installed on OS other than Solaris

def check_ips(values)
  check_osx_ips(values) if values['host-os-uname'].to_s.match(/Darwin/)
  nil
end

# Check Apache enabled

def check_apache_config(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    service = 'apache'
    check_osx_service_is_enabled(service)
  end
  nil
end

# Check DHCPd config

def check_dhcpd_config(values)
  network_address   = "#{values['hostip'].to_s.split(/\./)[0..2].join('.')}.0"
  broadcast_address = "#{values['hostip'].to_s.split(/\./)[0..2].join('.')}.255"
  gateway_address   = "#{values['hostip'].to_s.split(/\./)[0..2].join('.')}.1"
  output = ''
  if File.exist?(values['dhcpdfile'])
    message = "Checking:\tDHCPd config for subnet entry"
    command = "cat #{values['dhcpdfile']} | grep -v '^#' |grep 'subnet #{network_address}'"
    output  = execute_command(values, message, command)
  end
  if !output.match(/subnet/) && !output.match(/#{network_address}/)
    tmp_file    = '/tmp/dhcpd'
    backup_file = values['dhcpdfile'] + values['backupsuffix']
    file = File.open(tmp_file, 'w')
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
      if values['dhcpdrange'] == values['empty']
        values['dhcpdrange'] =
          "#{network_address.split('.')[0..-2].join('.')}.200 #{network_address.split('.')[0..-2].join('.')}.250"
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
      message = "Information:\tArchiving DHCPd configuration file #{values['dhcpdfile']} to #{backup_file}"
      command = "cp #{values['dhcpdfile']} #{backup_file}"
      execute_command(values, message, command)
    end
    message = "Information:\tCreating DHCPd configuration file #{values['dhcpdfile']}"
    command = "cp #{tmp_file} #{values['dhcpdfile']}"
    execute_command(values, message, command)
    if values['host-os-uname'].to_s.match(/SunOS/) && values['host-os-unamer'].match(/5\.11/)
      message = "Information:\tSetting DHCPd listening interface to #{values['nic']}"
      command = "svccfg -s svc:/network/dhcp/server:ipv4 setprop config/listen_ifnames = astring: #{values['nic']}"
      execute_command(values, message, command)
      message = "Information:\tRefreshing DHCPd service"
      command = 'svcadm refresh svc:/network/dhcp/server:ipv4'
      execute_command(values, message, command)
    end
    restart_dhcpd(values)
  end
  nil
end

# Check firewall is enabled

def check_rhel_service(values, service)
  message = "Information:\tChecking #{service} is installed"
  command = "service #{service} status |grep dead"
  output  = execute_command(values, message, command)
  if output.match(/dead/)
    message = "Enabling:\t#{service}"
    command = if values['host-os-unamer'].match(/^7/)
                "systemctl start #{service}.service"
              else
                "chkconfig --level 345 #{service} on"
              end
    execute_command(values, message, command)
  end
  nil
end

# Check service is enabled

def check_rhel_firewall(values, service, port_info)
  if values['host-os-unamer'].match(/^7/)
    message = "Information:\tChecking firewall configuration for #{service}"
    command = "firewall-cmd --list-services |grep #{service}"
    output  = execute_command(values, message, command)
    unless output.match(/#{service}/)
      message = "Information:\tAdding firewall rule for #{service}"
      command = "firewall-cmd --add-service=#{service} --permanent"
      execute_command(values, message, command)
    end
    if port_info.match(/[0-9]/)
      message = "Information:\tChecking firewall configuration for #{port_info}"
      command = "firewall-cmd --list-all |grep #{port_info}"
      output  = execute_command(values, message, command)
      unless output.match(/#{port_info}/)
        message = "Information:\tAdding firewall rule for #{port_info}"
        command = "firewall-cmd --zone=public --add-port=#{port_info} --permanent"
        execute_command(values, message, command)
      end
    end
  elsif port_info.match(/[0-9]/)
    (port_no, protocol) = port_info.split(%r{/})
    message = "Information:\tChecking firewall configuration for #{service} on #{port_info}"
    command = "iptables --list-rules |grep #{protocol} |grep #{port_no}"
    output  = execute_command(values, message, command)
    unless output.match(/#{protocol}/)
      message = "Information:\tAdding firewall rule for #{service}"
      command = "iptables -I INPUT -p #{protocol} --dport #{port_no} -j ACCEPT ; iptables save"
      execute_command(values, message, command)
    end
  end
  nil
end

# Check httpd enabled on Centos / Redhat

def check_yum_xinetd(values)
  check_rhel_package(values, 'xinetd')
  check_rhel_firewall(values, 'xinetd', '')
  check_rhel_service(values, 'xinetd')
  nil
end

# Check TFTPd enabled on CentOS / RedHat

def check_yum_tftpd(values)
  check_dir_exists(values, values['tftpdir'])
  check_rhel_package(values, 'tftp-server')
  check_rhel_firewall(values, 'tftp', '')
  check_rhel_service(values, 'tftp')
  nil
end

# Check DHCPd enabled on CentOS / RedHat

def check_yum_dhcpd(values)
  check_rhel_package(values, 'dhcp')
  check_rhel_firewall(values, 'dhcp', '69/udp')
  check_rhel_service(values, 'dhcpd')
  nil
end

# Check httpd enabled on Centos / Redhat

def check_yum_httpd(values)
  check_rhel_package(values, 'httpd')
  check_rhel_firewall(values, 'http', '80/tcp')
  check_rhel_service(values, 'httpd')
  nil
end

# Check Ubuntu / Debian firewall

def check_apt_firewall(values, service, port_info)
  if File.exist?('/usr/bin/ufw')
    message = "Information:\tChecking #{service} is allowed by firewall"
    command = "ufw status |grep #{service} |grep ALLOW"
    output = execute_command(values, message, command)
    unless output.match(/ALLOW/)
      message = "Information:\tAdding #{service} to firewall allow rules"
      command = "ufw allow #{service} #{port_info}"
      execute_command(values, message, command)
    end
  end
  nil
end

# Check Ubuntu / Debian service

def check_apt_service(values, service)
  message = "Information:\tChecking #{service} is installed"
  command = "service #{service} status |grep dead"
  output  = execute_command(values, message, command)
  if output.match(/dead/)
    message = "Information:\tEnabling: #{service}"
    command = "systemctl enable #{service}.service"
    execute_command(values, message, command)
    message = "Information:\tStarting: #{service}"
    command = "systemctl start #{service}.service"
    execute_command(values, message, command)
  end
  nil
end

# Check TFTPd enabled on Debian / Ubuntu

def check_apt_tftpd(values)
  check_dir_exists(values, values['tftpdir'])
  check_apt_package(values, 'tftpd-hpa')
  check_apt_firewall(values, 'tftp', '')
  check_apt_service(values, 'tftp')
  nil
end

# Check DHCPd enabled on Ubuntu / Debian

def check_apt_dhcpd(values)
  check_apt_package(values, 'isc-dhcp-server')
  check_apt_firewall(values, 'dhcp', '69/udp')
  check_apt_service(values, 'isc-dhcp-server')
  nil
end

# Check httpd enabled on Ubunut / Debian

def check_apt_httpd(values)
  check_apt_package(values, 'httpd')
  check_apt_firewall(values, 'http', '80/tcp')
  check_apt_service(values, 'httpd')
  nil
end

# Restart a service

def restart_service(values, service)
  refresh_service(values, service)
  nil
end

# Restart xinetd

def restart_xinetd(values)
  service = 'xinetd'
  service = get_service_name(values, service)
  refresh_service(values, service)
  nil
end

# Restart tftpd

def restart_tftpd(values)
  if values['host-os-uname'].to_s.match(/Linux/)
    service = 'tftpd-hpa'
  else
    service = 'tftp'
    service = get_service_name(values, service)
  end
  refresh_service(values, service)
  nil
end

# Restart forewalld

def restart_firewalld(values)
  service = 'firewalld'
  service = get_service_name(values, service)
  refresh_service(values, service)
  nil
end

# Check tftpd config for Linux(turn on in xinetd config file /etc/xinetd.d/tftp)

def check_tftpd_config(values)
  if values['host-os-uname'].to_s.match(/Linux/)
    pxelinux_file = '/usr/lib/PXELINUX/pxelinux.0'
    unless File.exist?(pxelinux_file)
      values = install_package(values, 'pxelinux')
      values = install_package(values, 'syslinux')
    end
    syslinux_file = '/usr/lib/syslinux/modules/bios/ldlinux.c32'
    pxelinux_dir  = values['tftpdir']
    pxelinux_tftp = "#{pxelinux_dir}/pxelinux.0"
    syslinux_tftp = "#{pxelinux_dir}/ldlinux.c32"
    information_message(values, 'Checking PXE directory')
    check_dir_exists(values, pxelinux_dir)
    check_dir_owner(values, pxelinux_dir, values['uid'])
    unless File.exist?(pxelinux_tftp)
      values = install_package(values, 'pxelinux') unless File.exist?(pxelinux_file)
      if File.exist?(pxelinux_file)
        message = "Information:\tCopying '#{pxelinux_file}' to '#{pxelinux_tftp}'"
        command = "cp #{pxelinux_file} #{pxelinux_tftp}"
        execute_command(values, message, command)
      else
        warning_message(values, 'TFTP boot file pxelinux.0 does not exist')
      end
    end
    unless File.exist?(syslinux_tftp)
      values = install_package(values, 'syslinux') unless File.exist?(syslinux_tftp)
      if File.exist?(syslinux_file)
        message = "Information:\tCopying '#{syslinux_file}' to '#{syslinux_tftp}'"
        command = "cp #{syslinux_file} #{syslinux_tftp}"
        execute_command(values, message, command)
      else
        warning_message(values, 'TFTP boot file ldlinux.c32 does not exist')
      end
    end
    if values['host-os-unamea'].match(/Ubuntu|Debian/)
      check_apt_tftpd(values)
    else
      check_yum_tftpd(values)
    end
    check_dir_exists(values, values['tftpdir'])
    if values['host-os-unamea'].match(/RedHat|CentOS/) && (Integer(values['host-os-version']) > 6)
      message = 'Checking SELinux tftp permissions'
      command = 'getsebool -a | grep tftp |grep home'
      output  = execute_command(values, message, command)
      if output.match(/off/)
        message = "Information:\ySetting SELinux tftp permissions"
        command = 'setsebool -P tftp_home_dir 1'
        execute_command(values, message, command)
      end
      restart_firewalld(values)
    end
  end
  restart_tftpd(values)
  nil
end

# Check tftpd directory

def check_tftpd_dir(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    old_tftp_dir = '/tftpboot'
    information_message(values, 'Checking TFTP directory')
    check_dir_exists(values, values['tftpdir'])
    check_dir_owner(values, values['tftpdir'], values['uid'])
    unless File.symlink?(old_tftp_dir)
      message = "Information:\tSymlinking #{old_tftp_dir} to #{values['tftpdir']}}"
      command = "ln -s #{values['tftpdir']} #{old_tftp_dir}"
      execute_command(values, message, command)
      #      File.symlink(values['tftpdir'], old_tftp_dir)
    end
    message = "Checking:\tTFTPd service boot directory configuration"
    command = 'svcprop -p inetd_start/exec svc:network/tftp/udp'
    output  = execute_command(values, message, command)
    unless output.match(/netboot/)
      message = "Information:\tSetting TFTPd boot directory to #{values['tftpdir']}"
      command = 'svccfg -s svc:network/tftp/udp setprop inetd_start/exec = astring: "/usr/sbin/in.tftpd\\ -s\\ /etc/netboot"'
      execute_command(values, message, command)
    end
  end
  nil
end

# Check network device exists

def check_network_device_exists(values)
  exists  = false
  net_dev = values['network'].to_s
  message = "Information:\tChecking network device #{net_dev} exists"
  command = "ifconfig #{net_dev} |grep ether"
  output  = execute_command(values, message, command)
  exists = true if output.match(/ether/)
  exists
end

# Check network bridge exists

def check_network_bridge_exists(values)
  exists  = false
  net_dev = values['bridge'].to_s
  message = "Information:\tChecking network device #{net_dev} exists"
  command = "ifconfig -a |grep #{net_dev}:"
  output  = execute_command(values, message, command)
  exists = true if output.match(/#{net_dev}/)
  exists
end

# Check NAT

def check_nat(values, gw_if_name, if_name)
  case values['host-os-uname'].to_s
  when /Darwin/
    if values['host-os-unamer'].split('.')[0].to_i < 14
      check_osx_nat(gw_if_name, if_name)
    else
      check_osx_pfctl(values, gw_if_name, if_name)
    end
  when /Linux/
    check_linux_nat(values, gw_if_name, if_name)
  end
  nil
end

# Check tftpd

def check_tftpd(values)
  check_tftpd_dir(values)
  enable_service(values, 'svc:/network/tftp/udp:default') if values['host-os-uname'].to_s.match(/SunOS/)
  check_osx_tftpd(values) if values['host-os-uname'].to_s.match(/Darwin/)
  nil
end

# Get client IP

def get_install_ip(values)
  values['ip'] = ''
  hosts_file = '/etc/hosts'
  if File.exist?(hosts_file) || File.symlink?(hosts_file)
    file_array = IO.readlines(hosts_file)
    file_array.each do |line|
      line = line.chomp
      values['ip'] = line.split(/\s+/)[0] if line.match(/#{values['name']}\s+/)
    end
  end
  values['ip']
end

# Get client MAC

def get_install_mac(values)
  mac_address  = ''
  found_client = 0
  if File.exist?(values['dhcpdfile']) || File.symlink?(values['dhcpdfile'])
    file_array = IO.readlines(values['dhcpdfile'])
    file_array.each do |line|
      line = line.chomp
      found_client = true if line.match(/#{values['name']} /)
      if line.match(/hardware ethernet/) && (found_client == true)
        mac_address = line.split(/\s+/)[3].gsub(/;/, '')
        return mac_address
      end
    end
  end
  mac_address
end

# Check dnsmasq

def check_dnsmasq(values)
  check_linux_dnsmasq(values) if values['host-os-uname'].to_s.match(/Linux/)
  check_osx_dnsmasq(values) if values['host-os-uname'].to_s.match(/Darwin/)
  nil
end

# Add dnsmasq entry

def add_dnsmasq_entry(values)
  check_dnsmasq(values)
  config_file = '/etc/dnsmasq.conf'
  hosts_file  = "/etc/hosts.#{values['scriptname']}"
  message = "Checking:\tChecking DNSmasq config file for hosts.#{values['scriptname']}"
  command = "cat #{config_file} |grep -v '^#' |grep '#{values['scriptname']}' |grep 'addn-hosts'"
  output  = execute_command(values, message, command)
  unless output.match(/#{values['scriptname']}/)
    backup_file(values, config_file)
    message = "Information:\tAdding hosts file #{hosts_file} to #{config_file}"
    command = "echo \"addn-hosts=#{hosts_file}\" >> #{config_file}"
    execute_command(values, message, command)
  end
  message = "Checking:\tHosts file #{hosts_file}for #{values['name']}"
  command = "cat #{hosts_file} |grep -v '^#' |grep '#{values['name']}' |grep '#{values['ip']}'"
  output  = execute_command(values, message, command)
  unless output.match(/#{values['name']}/)
    backup_file(values, hosts_file)
    message = "Adding:\t\tHost #{values['name']} to #{hosts_file}"
    command = "echo \"#{values['ip']}\\t#{values['name']}.local\\t#{values['name']}\\t# #{values['adminuser']}\" >> #{hosts_file}"
    execute_command(values, message, command)
    if values['host-os-uname'].to_s.match(/Darwin/)
      pfile = '/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist'
      if File.exist?(pfile)
        service = 'dnsmasq'
        service = get_service_name(values, service)
        refresh_service(option, service)
      end
    else
      service = 'dnsmasq'
      service = get_service_name(values, service)
      refresh_service(values, service)
    end
  end
  nil
end

# Add hosts entry

def add_hosts_entry(values)
  hosts_file = '/etc/hosts'
  message    = "Checking:\tHosts file for #{values['name']}"
  command    = "cat #{hosts_file} |grep -v '^#' |grep '#{values['name']}' |grep '#{values['ip']}'"
  output     = execute_command(values, message, command)
  unless output.match(/#{values['name']}/)
    backup_file(values, hosts_file)
    message = "Adding:\t\tHost #{values['name']} to #{hosts_file}"
    command = "echo \"#{values['ip']}\\t#{values['name']}.local\\t#{values['name']}\\t# #{values['adminuser']}\" >> #{hosts_file}"
    execute_command(values, message, command)
  end
  add_dnsmasq_entry(values) if values['dnsmasq'] == true
  nil
end

# Remove hosts entry

def remove_hosts_entry(values)
  hosts_file = '/etc/hosts'
  remove_hosts_file_entry(values, hosts_file)
  if values['dnsmasq'] == true
    hosts_file = "/etc/hosts.#{values['scriptname']}"
    remove_hosts_file_entry(values, hosts_file)
  end
  nil
end

def remove_hosts_file_entry(values, hosts_file)
  tmp_file = '/tmp/hosts'
  message  = "Checking:\tHosts file for #{values['name']}"
  command = if values['ip'].to_s.match(/[0-9]/)
              "cat #{hosts_file} |grep -v '^#' |grep '#{values['name']}' |grep '#{values['ip']}'"
            else
              "cat #{hosts_file} |grep -v '^#' |grep '#{values['name']}'"
            end
  output = execute_command(values, message, command)
  copy   = []
  if output.match(/#{values['name']}/)
    file_info = IO.readlines(hosts_file)
    file_info.each do |line|
      unless line.match(/#{values['name']}/)
        if values['ip'].to_s.match(/[0-9]/)
          copy.push(line) unless line.match(/^#{values['ip']}/)
        else
          copy.push(line)
        end
      end
    end
    File.open(tmp_file, 'w') { |file| file.puts copy }
    message = "Updating:\tHosts file #{hosts_file}"
    command = if values['host-os-uname'].to_s.match(/Darwin/)
                "sudo sh -c 'cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}'"
              else
                "cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}"
              end
    execute_command(values, message, command)
  end
  nil
end

# Add host to DHCP config

def add_dhcp_client(values)
  unless values['mac'].to_s.match(/:/)
    values['mac'] =
      "#{values['mac'][0..1]}:#{values['mac'][2..3]}:#{values['mac'][4..5]}:#{values['mac'][6..7]}:#{values['mac'][8..9]}:#{values['mac'][10..11]}"
  end
  tmp_file = "/tmp/dhcp_#{values['name']}"
  if !values['arch'].to_s.match(/sparc/)
    tftp_pxe_file = values['mac'].gsub(/:/, '')
    tftp_pxe_file = tftp_pxe_file.upcase
    suffix = if values['service'].to_s.match(/sol/)
               '.bios'
             elsif values['service'].to_s.match(/bsd/)
               '.pxeboot'
             else
               '.pxelinux'
             end
    tftp_pxe_file = "01#{tftp_pxe_file}#{suffix}"
  else
    tftp_pxe_file = "http://#{values['publisherhost'].to_s.strip}:5555/cgi-bin/wanboot-cgi"
  end
  message = "Checking:\fIf DHCPd configuration contains #{values['name']}"
  command = "cat #{values['dhcpdfile']} | grep '#{values['name']}'"
  output  = execute_command(values, message, command)
  unless output.match(/#{values['name']}/)
    backup_file(values, values['dhcpdfile'])
    file = File.open(tmp_file, 'w')
    file_info = IO.readlines(values['dhcpdfile'])
    file_info.each do |line|
      file.write(line)
    end
    file.write("\n")
    file.write("host #{values['name']} {\n")
    file.write("  fixed-address #{values['ip']};\n")
    file.write("  hardware ethernet #{values['mac']};\n")
    if values['service'].to_s.match(/[a-z,A-Z]/)
      # if values['biostype'].to_s.match(/efi/)
      #  if values['service'].to_s.match(/vmware|esx|vsphere/)
      #    file.write("  filename \"#{values['service'].to_s}/bootx64.efi\";\n")
      #  else
      #    file.write("  filename \"shimx64.efi\";\n")
      #  end
      # else
      file.write("  filename \"#{tftp_pxe_file}\";\n")
      # end
    end
    file.write("}\n")
    file.close
    message = "Updating:\tDHCPd file #{values['dhcpdfile']}"
    command = "cp #{tmp_file} #{values['dhcpdfile']} ; rm #{tmp_file}"
    execute_command(values, message, command)
    restart_dhcpd(values)
  end
  check_dhcpd(values)
  check_tftpd(values)
  nil
end

# Remove host from DHCP config

def remove_dhcp_client(values)
  found     = 0
  copy      = []
  if !File.exist?(values['dhcpdfile'])
    warning_message(values, "File #{values['dhcpdfile']} does not exist")
  else
    check_file_owner(values, values['dhcpdfile'], values['uid'])
    file_info = IO.readlines(values['dhcpdfile'])
    file_info.each do |line|
      found = true if line.match(/^host #{values['name']}/)
      copy.push(line) if found == false
      found = 0 if (found == true) && line.match(/\}/)
    end
    File.open(values['dhcpdfile'], 'w') { |file| file.puts copy }
  end
  nil
end

# Backup file

def backup_file(values, file_name)
  date_string = get_date_string(values)
  backup_file = "#{File.basename(file_name)}.#{date_string}"
  backup_file = "#{values['backupdir']}/#{backup_file}"
  message     = "Archiving:\tFile #{file_name} to #{backup_file}"
  command     = "cp #{file_name} #{backup_file}"
  execute_command(values, message, command)
  nil
end

# Wget a file

def wget_file(values, file_url, file_name)
  if values['download'] == true
    wget_test = %(which wget).chomp
    command = if wget_test.match(/bin/)
                "wget #{file_url} -O #{file_name}"
              else
                "curl -o #{file_name} #{file_url}"
              end
    file_dir = File.dirname(file_name)
    check_dir_exists(values, file_dir)
    message = "Fetching:\tURL #{file_url} to #{file_name}"
    execute_command(values, message, command)
  end
  nil
end

# Add to ethers file

def add_to_ethers_file(values)
  found     = false
  file_name = '/etc/ethers'
  if !File.exist?(file_name)
    message = "Information:\tCreating #{file_name}"
    command = "touch #{file_name}"
    execute_command(values, message, command)
    check_file_owner(values, file_name, values['uid'])
    File.open(file_name, 'w') { |f| f.write "#{values['mac']} #{values['name']}\n" }
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
    File.open(file_name, 'w') do |file|
      lines.each { |line| file.puts(line) }
    end
  end
  nil
end

# Find client MAC

def get_install_mac(values)
  ethers_file = '/etc/ethers'
  output      = ''
  found       = 0
  if File.exist?(ethers_file)
    message = "Checking:\tFile #{ethers_file} for #{values['name']} MAC address"
    command = "cat #{ethers_file} |grep '#{values['name']} '|awk \"{print \\$2}\""
    mac_add = execute_command(values, message, command)
    mac_add = mac_add.chomp
  end
  unless output.match(/[0-9]/)
    file = IO.readlines(values['dhcpdfile'])
    file.each do |line|
      line = line.chomp
      found = 1 if line.match(/#{values['name']}/)
      next unless found == true

      next unless line.match(/ethernet/)

      mac_add = line.split(/ ethernet /)[1]
      mac_add = values['mac'].gsub(/;/, '')
      return mac_add
    end
  end
  mac_add
end

# Check if a directory exists
# If not create it

def check_dir_exists(values, dir_name)
  output = ''
  if !File.directory?(dir_name) && !File.symlink?(dir_name) && dir_name.match(/[a-z]|[A-Z]/)
    message = "Information:\tCreating: #{dir_name}"
    command = if dir_name.match(%r{^/etc})
                "sudo mkdir -p \"#{dir_name}\""
              else
                "mkdir -p \"#{dir_name}\""
              end
    output = execute_command(values, message, command)
  end
  output
end

# Check a filesystem / directory exists

def check_fs_exists(values, dir_name)
  output = ''
  if values['host-os-uname'].to_s.match(/SunOS/)
    output = check_zfs_fs_exists(values, dir_name)
  else
    check_dir_exists(values, dir_name)
  end
  output
end

# Check if a ZFS filesystem exists
# If not create it

def check_zfs_fs_exists(values, dir_name)
  output = ''
  unless File.directory?(dir_name)
    if values['host-os-uname'].to_s.match(/SunOS/)
      if dir_name.match(/clients/)
        root_dir = dir_name.split(%r{/})[0..-2].join('/')
        check_zfs_fs_exists(root_dir) unless File.directory?(root_dir)
      end
      zfs_name = if dir_name.match(/ldoms|zones/)
                   values['dpool'] + dir_name
                 else
                   values['zpoolname'] + dir_name
                 end
      if dir_name.match(/vmware_|openbsd_|coreos_/) || (values['host-os-unamer'].to_i > 10)
        values['service'] = File.basename(dir_name)
        mount_dir = "#{values['tftpdir']}/#{values['service']}"
        Dir.mkdir(mount_dir) unless File.directory?(mount_dir)
      else
        mount_dir = dir_name
      end
      message = "Information:\tCreating #{dir_name} with mount point #{mount_dir}"
      command = "zfs create -o mountpoint=#{mount_dir} #{zfs_name}"
      execute_command(values, message, command)
      if dir_name.match(/vmware_|openbsd_|coreos_/) || (values['host-os-unamer'].to_i > 10)
        message = "Information:\tSymlinking #{mount_dir} to #{dir_name}"
        command = "ln -s #{mount_dir} #{dir_name}"
        execute_command(values, message, command)
      end
    else
      check_dir_exists(values, dir_name)
    end
  end
  output
end

# Destroy a ZFS filesystem

def destroy_zfs_fs(values, dir_name)
  output = ''
  zfs_list = `zfs list |grep -v NAME |awk '{print $5}' |grep "^#{dir_name}$'`.chomp
  if zfs_list.match(/#{dir_name}/)
    zfs_name = `zfs list |grep -v NAME |grep "#{dir_name}$" |awk '{print $1}'`.chomp
    if (values['yes'] == true) && File.directory?(dir_name)
      if dir_name.match(/netboot/)
        service = 'svc:/network/tftp/udp:default'
        disable_service(service)
      end
      message = "Warning:\tDestroying #{dir_name}"
      command = "zfs destroy -r -f #{zfs_name}"
      output  = execute_command(values, message, command)
      enable_service(service) if dir_name.match(/netboot/)
    end
  end
  Dir.rmdir(dir_name) if File.directory?(dir_name)
  output
end

# Routine to execute command
# Prints command if verbose switch is on
# Does not execute cerver/client import/create operations in test mode

def execute_command(values, message, command)
  unless command.match(/[a-z]|[A-Z]|[0-9]/)
    warning_message(values, 'Empty command')
    return
  end
  return if command.match(/prlctl/) && !values['host-os-uname'].to_s.match(/Darwin/)

  if command.match(/prlctl/)
    parallels_test = `which prlctl`.chomp
    return unless parallels_test.match(/prlctl/)
  end

  output  = ''
  execute = false
  verbose_message(values, message) if (values['verbose'] == true) && message.match(/[a-z,A-Z,0-9]/)
  if values['dryrun'] == true
    execute = true unless command.match(/create|id|groups|update|import|delete|svccfg|rsync|cp|touch|svcadm|VBoxManage|vboxmanage|vmrun|docker|rm|cp|convert|cloud-localds|chown|chmod|restart|stop|start|resize/)
  else
    execute = true
  end
  if execute == true
    if values['uid'] != 0
      if !command.match(/brew |sw_vers|id |groups|hg|pip|VBoxManage|vboxmanage|netstat|df|vmrun|noVNC|docker|packer|ansible-playbook|^ls|multipass/) && !values['host-os-uname'].to_s.match(/NT/)
        if values['sudo'] == true
          if command.match(/virsh/)
            command = "sudo sh -c '#{command}'" if values['host-os-uname'].to_s.match(/Linux/)
          else
            command = "sudo sh -c '#{command}'"
          end
        elsif command.match(/ufw|chown|chmod/)
          command = "sudo sh -c '#{command}'"
        elsif command.match(/ifconfig/) && command.match(/up$/)
          command = "sudo sh -c '#{command}'"
        end
      else
        command = "sudo sh -c '#{command}'" if command.match(/ifconfig/) && command.match(/up$/)
        command = "sudo sh -c '#{command}'" if command.match(/virt-install/)
        if command.match(/snap/)
          check_apt_package(values, 'snapd') unless File.exist?('/usr/bin/snap')
          command = "sudo sh -c '#{command}'"
        end
        command = "sudo sh -c '#{command}'" if command.match(/qemu/) && command.match(/chmod|chgrp/)
        command = "sudo sh -c '#{command}'" if values['vm'].to_s.match(/kvm/) && command.match(/libvirt/) && command.match(/ls/) && values['host-os-uname'].to_s.match(/Linux/)
      end
      if values['host-os-uname'].to_s.match(/NT/) && command.match(/netsh/)
        batch_file = '/tmp/script.bat'
        File.write(batch_file, command)
        information_message(values, "Creating batch file '#{batch_file}' to run command '#{command}")
        command = "cygstart --action=runas #{batch_file}"
      end
    end
    if command.match(/^sudo/)
      sudo_check = `sudo -l |grep NOPASSWD`
      unless sudo_check.match(/NOPASSWD/)
        sudo_check = if values['host-os-uname'].to_s.match(/Darwin/)
                       `dscacheutil -q group -a name admin |grep users`
                     else
                       `getent group #{values['sudogroup']}`.chomp
                     end
        unless sudo_check.match(/#{values['user']}/)
          warning_message(values, "User #{values['user']} is not in sudoers group #{values['sudogroup']}")
          quit(values)
        end
      end
    end
    execute_message(values, command)
    if values['executehost'].to_s.match(/localhost/)
      if (values['dryrun'] == true) && (execute == true)
        output = `#{command}`
      elsif values['drydun'] == false
        output = `#{command}`
      end
    else
      #      Net::SSH.start(values['server'], values['serveradmin'], :password => values['serverpassword'], :verify_host_key => "never") do |ssh_session|
      #        output = ssh_session.exec!(command)
      #      end
    end
  end
  if (values['verbose'] == true) && (output.length > 1)
    if !output.match(/\n/)
      verbose_message(values, "Output:\t\t#{output}")
    else
      multi_line_output = output.split(/\n/)
      multi_line_output.each do |line|
        verbose_message(values, "Output:\t\t#{line}")
      end
    end
  end
  output
end

# Convert current date to a string that can be used in file names

def get_date_string(values)
  time = Time.new
  time = time.to_a
  date = Time.utc(*time)
  date_string = date.to_s.gsub(/\s+/, '_')
  date_string = date_string.gsub(/:/, '_')
  date_string = date_string.gsub(/-/, '_')
  information_message(values, "Setting date string to #{date_string}")
  date_string
end

# Create an encrypted password field entry for a give password

def get_password_crypt(password)
  UnixCrypt::MD5.build(password)
end

# Restart DHCPd

def restart_dhcpd(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    function = 'refresh'
    service  = 'svc:/network/dhcp/server:ipv4'
    output   = handle_smf_service(values, function, service)
  else
    service = if values['host-os-uname'].to_s.match(/Linux/)
                'isc-dhcp-server'
              else
                'dhcpd'
              end
    refresh_service(values, service)
  end
  output
end

# Check DHPCPd is running

def check_dhcpd(values)
  message = "Checking:\tDHCPd is running"
  if values['host-os-uname'].to_s.match(/SunOS/)
    command = 'svcs -l svc:/network/dhcp/server:ipv4'
    output  = execute_command(values, message, command)
    if output.match(/disabled/)
      function = 'enable'
      smf_install_service = 'svc:/network/dhcp/server:ipv4'
      output = handle_smf_service(function, smf_install_service)
    end
    if output.match(/maintenance/)
      function = 'refresh'
      smf_install_service = 'svc:/network/dhcp/server:ipv4'
      output = handle_smf_service(function, smf_install_service)
    end
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    command = "ps aux |grep '/usr/local/bin/dhcpd' |grep -v grep"
    output  = execute_command(values, message, command)
    unless output.match(/dhcp/)
      service = 'dhcp'
      check_osx_service_is_enabled(values, service)
      service = 'dhcp'
      refresh_service(values, service)
    end
    check_osx_tftpd(values)
  end
  output
end

# Get service basename

def get_service_base_name(values)
  values['service'].to_s.gsub(/_i386|_x86_64|_sparc/, '')
end

# Get service name

def get_service_name(values, service)
  if values['host-os-uname'].to_s.match(/SunOS/)
    service = 'svc:/network/http:apache22' if service.to_s.match(/apache/)
    service = 'svc:/network/dhcp/server:ipv4' if service.to_s.match(/dhcp/)
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    service = 'org.apache.httpd' if service.to_s.match(/apache/)
    service = 'homebrew.mxcl.isc-dhcp' if service.to_s.match(/dhcp/)
    service = 'homebrew.mxcl.dnsmasq' if service.to_s.match(/dnsmasq/)
  end
  service
end

# Enable service

def enable_service(values, service_name)
  output = enable_smf_service(values, service_name) if values['host-os-uname'].to_s.match(/SunOS/)
  output = enable_osx_service(values, service_name) if values['host-os-uname'].to_s.match(/Darwin/)
  output = enable_linux_service(values, service_name) if values['host-os-uname'].to_s.match(/Linux/)
  output
end

# Start service

def start_service(values, service_name)
  output = start_linux_service(values, service_name) if values['host-os-uname'].to_s.match(/Linux/)
  output
end

# Disable service

def disable_service(values, service_name)
  output = disable_smf_service(values, service_name) if values['host-os-uname'].to_s.match(/SunOS/)
  output = disable_osx_service(values, service_name) if values['host-os-uname'].to_s.match(/Darwin/)
  output = disable_linux_service(values, service_name) if values['host-os-uname'].to_s.match(/Linux/)
  output
end

# Refresh / Restart service

def refresh_service(values, service_name)
  output = refresh_smf_service(values, service_name) if values['host-os-uname'].to_s.match(/SunOS/)
  output = refresh_osx_service(values, service_name) if values['host-os-uname'].to_s.match(/Darwin/)
  restart_linux_service(values, service_name) if values['host-os-uname'].to_s.match(/Linux/)
  output
end

# Calculate route

def get_ipv4_default_route(values)
  if !values['gateway'].to_s.match(/[0-9]/)
    if values['host-os-uname'].to_s.match(/Darwin/)
      message = "Information:\tDetermining default route"
      command = 'route -n get default |grep gateway |cut -f2 -d:'
      output  = execute_command(values, message, command)
      ipv4_default_route = output.chomp.gsub(/\s+/, '')
    else
      octets    = values['ip'].split(/\./)
      octets[3] = values['gatewaynode']
      ipv4_default_route = octets.join('.')
    end
  else
    ipv4_default_route = values['gateway']
  end
  ipv4_default_route
end

# Create a ZFS filesystem for ISOs if it does not exist
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
  if [nil, 'none'].include?(values['isodir']) && (values['file'] == values['empty'])
    warning_message(values, 'No valid ISO directory specified')
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
    iso_list = iso_list.grep_v(/live/) if values['method'].to_s.match(/ps/)
    iso_list = iso_list.grep(/live/) if values['method'].to_s.match(/ci/)
    if search_string.match(/sol_11/) && !iso_list.grep(/full/)
      warning_message(values, "No full repository ISO images exist in #{values['isodir']}")
      quit(values) if values['dryrun'] != true
    end
    iso_list
  else
    iso_list[0] = values['file']
  end
  iso_list
end

# Check client architecture

def check_client_arch(values, opt)
  unless values['arch'].to_s.match(/i386|sparc|x86_64/)
    if (opt['F'] || opt['O']) && opt['A']
      information_message(values, 'Setting architecture to x86_64')
      values['arch'] = 'x86_64'
    end
    if opt['n']
      values['service'] = opt['n']
      service_arch = values['service'].split('_')[-1]
      values['arch'] = service_arch if service_arch.match(/i386|sparc|x86_64/)
    end
  end
  unless values['arch'].to_s.match(/i386|sparc|x86_64/)
    warning_message(values, 'Invalid architecture specified')
    warning_message(values, 'Use --arch i386, --arch x86_64 or --arch sparc')
    quit(values)
  end
  values['arch']
end

# Check client MAC

def check_install_mac(values)
  unless values['mac'].to_s.match(/:/)
    if values['mac'].to_s.split(':').length != 6
      warning_message(values, 'Invalid MAC address')
      values['mac'] = generate_mac_address(values['vm'])
      information_message(values, "Generated new MAC address: #{values['mac']}")
    else
      values['mac'].split(//)
      values['mac'] =
        "#{chars[0..1].join}:#{chars[2..3].join}:#{chars[4..5].join}:#{chars[6..7].join}:#{chars[8..9].join}:#{chars[10..11].join}"
    end
  end
  macs = values['mac'].split(':')
  if macs.length != 6
    warning_message(values, 'Invalid MAC address')
    quit(values)
  end
  macs.each do |mac|
    next unless mac =~ /[G-Z]|[g-z]/

    warning_message(values, 'Invalid MAC address')
    values['mac'] = generate_mac_address(values['vm'])
    information_message(values, "Generated new MAC address: #{values['mac']}")
  end
  values['mac']
end

# Check valid IP

def check_ip_is_valid(values, ip_address, ip_text)
  spacer = if ip_text.match(/[a-z]/)
             "for parameter #{ip_text}: "
           else
             ': '
           end
  if IPAddress.valid?(ip_address)
    information_message(values, "Valid IP Address#{spacer}#{ip_address}")
  else
    warning_message(values, "Invalid IP Address#{spacer}#{ip_address}")
    quit(values)
  end
  nil
end

def check_mac_is_valid(values, mac_address)
  if mac_address.to_s.match(/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9a-fA-F]{4}\\.[0-9a-fA-F]{4}\\.[0-9a-fA-F]{4})$/)
    information_message(values, "Valid MAC Address: #{mac_address}")
  else
    warning_message(values, "Invalid MAC Address: #{mac_address}")
    quit(values)
  end
  nil
end

# Check install IP

def check_install_ip(values)
  values['ips'] = []
  if values['ip'].to_s.match(/,/)
    values['ips'] = values['ip'].split(',')
  else
    values['ips'][0] = values['ip']
  end
  values['ips'].each do |test_ip|
    ips = test_ip.split('.')
    warning_message(values, 'Invalid IP Address') if ips.length != 4
    ips.each do |ip|
      warning_message(values, 'Invalid IP Address') if ip =~ /[a-z,A-Z]/ || (ip.length > 3) || (ip.to_i > 254)
    end
  end
  nil
end

# Add apache proxy

def add_apache_proxy(values, service_base_name)
  service = 'apache'
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['osverstion'].to_s.match(/11/) && values['host-os-update'].to_s.match(/4/)
      apache_config_file = "#{values['apachedir']}/2.4/httpd.conf"
      service = 'apache24'
    else
      apache_config_file = "#{values['apachedir']}/2.2/httpd.conf"
      service = 'apache22'
    end
  end
  apache_config_file = "#{values['apachedir']}/httpd.conf" if values['host-os-uname'].to_s.match(/Darwin/)
  if values['host-os-uname'].to_s.match(/Linux/)
    apache_config_file = "#{values['apachedir']}/conf/httpd.conf"
    values = install_package(values, 'apache2') unless File.exist?(apache_config_file)
  end
  a_check = `cat #{apache_config_file} |grep #{service_base_name}`
  unless a_check.match(/#{service_base_name}/)
    message = "Information:\tArchiving #{apache_config_file} to #{apache_config_file}.no_#{service_base_name}"
    command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
    execute_command(values, message, command)
    message = "Adding:\t\tProxy entry to #{apache_config_file}"
    command = "echo 'ProxyPass /#{service_base_name} http://#{values['publisherhost']}:#{values['publisherport']} nocanon max=200' >>#{apache_config_file}"
    execute_command(values, message, command)
    enable_service(values, service)
    refresh_service(values, service)
  end
  nil
end

# Remove apache proxy

def remove_apache_proxy(service_base_name)
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['osverstion'].to_s.match(/11/) && values['host-os-update'].to_s.match(/4/)
      apache_config_file = "#{values['apachedir']}/2.4/httpd.conf"
      'apache24'
    else
      apache_config_file = "#{values['apachedir']}/2.2/httpd.conf"
      'apache22'
    end
  end
  apache_config_file = "#{values['apachedir']}/httpd.conf" if values['host-os-uname'].to_s.match(/Darwin/)
  apache_config_file = "#{values['apachedir']}/conf/httpd.conf" if values['host-os-uname'].to_s.match(/Linux/)
  message = "Checking:\tApache confing file #{apache_config_file} for #{service_base_name}"
  command = "cat #{apache_config_file} |grep '#{service_base_name}'"
  a_check = execute_command(values, message, command)
  return unless a_check.match(/#{service_base_name}/)

  restore_file = "#{apache_config_file}.no_#{service_base_name}"
  return unless File.exist?(restore_file)

  message = "Restoring:\t#{restore_file} to #{apache_config_file}"
  command = "cp #{restore_file} #{apache_config_file}"
  execute_command(values, message, command)
  service = 'apache'
  refresh_service(values, service)
end

# Add apache alias

def add_apache_alias(values, service_base_name)
  values = install_package(values, 'apache2')
  if service_base_name.match(%r{^/})
    apache_alias_dir  = service_base_name
    service_base_name = File.basename(service_base_name)
  else
    apache_alias_dir = "#{values['baserepodir']}/#{service_base_name}"
  end
  if values['host-os-uname'].to_s.match(/SunOS/)
    apache_config_file = if values['host-os-version'].to_s.match(/11/) && values['host-os-update'].to_s.match(/4/)
                           "#{values['apachedir']}/2.4/httpd.conf"
                         else
                           "#{values['apachedir']}/2.2/httpd.conf"
                         end
  end
  apache_config_file = "#{values['apachedir']}/httpd.conf" if values['host-os-uname'].to_s.match(/Darwin/)
  if values['host-os-uname'].to_s.match(/Linux/)
    if values['host-os-unamea'].match(/CentOS|RedHat/)
      apache_config_file = "#{values['apachedir']}/conf/httpd.conf"
      apache_doc_root = '/var/www/html'
      "#{apache_doc_root}/#{service_base_name}"
    else
      apache_config_file = '/etc/apache2/apache2.conf'
    end
  end
  if values['host-os-uname'].to_s.match(/SunOS|Linux/)
    tmp_file = '/tmp/httpd.conf'
    message  = "Checking:\tApache confing file #{apache_config_file} for #{service_base_name}"
    command  = "cat #{apache_config_file} |grep '/#{service_base_name}'"
    a_check  = execute_command(values, message, command)
    message  = "Information:\tChecking Apache Version"
    command  = 'apache2 -V 2>&1 |grep version |tail -1'
    a_vers   = execute_command(values, message, command)
    unless a_check.match(/#{service_base_name}/)
      message = "Information:\tArchiving Apache config file #{apache_config_file} to #{apache_config_file}.no_#{service_base_name}"
      command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
      execute_command(values, message, command)
      verbose_message(values, "Adding:\t\tDirectory and Alias entry to #{apache_config_file}")
      message = "Copying:\tApache config file so it can be edited"
      command = "cp #{apache_config_file} #{tmp_file} ; chown #{values['uid']} #{tmp_file}"
      execute_command(values, message, command)
      output = File.open(tmp_file, 'a')
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
      service = if values['host-os-uname'].to_s.match(/Linux/)
                  if values['host-os-unamea'].to_s.match(/CentOS|RedHat/)
                    'httpd'
                  else
                    'apache2'
                  end
                elsif values['host-os-uname'].match(/SunOS/) && values['host-os-version'].to_s.match(/11/)
                  if values['host-os-update'].to_s.match(/4/)
                    'apache24'
                  else
                    'apache2'
                  end
                else
                  'apache'
                end
      enable_service(values, service)
      refresh_service(values, service)
    end
    if values['host-os-uname'].to_s.match(/Linux/) && values['host-os-unamea'].match(/RedHat/) && values['host-os-version'].match(/^7|^6\.7/)
      httpd_p = 'httpd_sys_rw_content_t'
      message = "Information:\tFixing permissions on #{values['clientdir']}"
      command = "chcon -R -t #{httpd_p} #{values['clientdir']}"
      execute_command(values, message, command)
    end
  end
  nil
end

# Remove apache alias

def remove_apache_alias(service_base_name)
  remove_apache_proxy(service_base_name)
end

def mount_udf(_values)
  nil
end

# Mount full repo isos under iso directory
# Eg /export/isos
# An example full repo file name
# /export/isos/sol-11_1-repo-full.iso
# It will attempt to mount them
# Eg /cdrom
# If there is something mounted there already it will unmount it

def mount_iso(values)
  information_message(values, "Processing: #{values['file']}")
  check_dir_exists(values, values['mountdir'])
  message = "Checking:\tExisting mounts"
  command = "df |awk '{print $NF}' |grep '^#{values['mountdir']}$'"
  output  = execute_command(values, message, command)
  if output.match(/[a-z,A-Z]/)
    message = "Information:\tUnmounting: #{values['mountdir']}"
    command = "umount #{values['mountdir']}"
    execute_command(values, message, command)
  end
  message = "Information:\tMounting ISO #{values['file']} on #{values['mountdir']}"
  command = "mount -F hsfs #{values['file']} #{values['mountdir']}" if values['host-os-uname'].to_s.match(/SunOS/)
  if values['host-os-uname'].to_s.match(/Darwin/)
    command = "hdiutil attach -nomount \"#{values['file']}\" |head -1 |awk \"{print \\\$1}\""
    execute_message(values, command)
    disk_id = `#{command}`
    disk_id = disk_id.chomp
    file_du = `du "#{values['file']}" |awk '{print $1}'`
    file_du = file_du.chomp.to_i
    command = if file_du < 700_000
                "mount -t cd9660 -o ro #{disk_id} #{values['mountdir']}"
              else
                "sudo mount -t udf -o ro #{disk_id} #{values['mountdir']}"
              end
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    file_du = `du "#{values['file']}" |awk '{print $1}'`
    file_du = file_du.chomp.to_i
    command = if file_du < 700_000
                "mount -t iso9660 -o loop #{values['file']} #{values['mountdir']}"
              else
                "sudo mount -t udf -o ro #{values['file']} #{values['mountdir']}"
              end
  end
  execute_command(values, message, command)
  readme1 = "#{values['mountdir']}/README.TXT"
  readme2 = "#{values['mountdir']}/readme.txt"
  if File.exist?(readme1) || File.exist?(readme2)
    text = IO.readlines(readme)
    if text.grep(/UDF/)
      umount_iso(values)
      if values['host-os-uname'].to_s.match(/Darwin/)
        command = "hdiutil attach -nomount \"#{values['file']}\" |head -1 |awk \"{print \\\$1}\""
        execute_message(values, command)
        disk_id = `#{command}`
        disk_id = disk_id.chomp
        command = "sudo mount -t udf -o ro #{disk_id} #{values['mountdir']}"
        execute_command(values, message, command)
      end
    end
  end
  iso_test_dir = if values['file'].to_s.match(/sol/)
                   if values['file'].to_s.match(/-ga-/)
                     if values['file'].to_s.match(/sol-10/)
                       "#{values['mountdir']}/boot"
                     else
                       "#{values['mountdir']}/installer"
                     end
                   else
                     "#{values['mountdir']}/repo"
                   end
                 else
                   case values['file']
                   when /VM/
                     "#{values['mountdir']}/upgrade"
                   when /Win|Srv|[0-9][0-9][0-9][0-9]/
                     "#{values['mountdir']}/sources"
                   when /SLE/
                     "#{values['mountdir']}/suse"
                   when /CentOS|SL/
                     "#{values['mountdir']}/repodata"
                   when /rhel|OracleLinux|Fedora/
                     if values['file'].to_s.match(/rhel-server-5/)
                       "#{values['mountdir']}/Server"
                     elsif values['file'].to_s.match(/rhel-[8,9]/)
                       "#{values['mountdir']}/BaseOS/Packages"
                     else
                       "#{values['mountdir']}/Packages"
                     end
                   when /VCSA/
                     "#{values['mountdir']}/vcsa"
                   when /install|FreeBSD/
                     "#{values['mountdir']}/etc"
                   when /coreos/
                     "#{values['mountdir']}/coreos"
                   else
                     "#{values['mountdir']}/install"
                   end
                 end
  if !File.directory?(iso_test_dir) && !File.exist?(iso_test_dir) && !values['file'].to_s.match(/DVD2\.iso|2of2\.iso|repo-full|VCSA/)
    warning_message(values, 'ISO did not mount, or this is not a repository ISO')
    warning_message(values, "#{iso_test_dir} does not exist")
    if values['dryrun'] != true
      umount_iso(values)
      quit(values)
    end
  end
  nil
end

# Check my directory exists

def check_my_dir_exists(values, dir_name)
  if !File.directory?(dir_name) && !File.symlink?(dir_name)
    information_message(values, "Creating directory '#{dir_name}'")
    system("mkdir #{dir_name}")
  else
    information_message(values, "Directory '#{dir_name}' already exists")
  end
  nil
end

# Check ISO mounted for OS X based server

def check_osx_iso_mount(values)
  check_dir_exists(values, values['mountdir'])
  test_dir = "#{values['mountdir']}/boot"
  unless File.directory?(test_dir)
    message = "Mounting:ISO #{values['file']} on #{values['mountdir']}"
    command = "hdiutil mount #{values['file']} -mountpoint #{values['mountdir']}"
    output  = execute_command(values, message, command)
  end
  output
end

# Copy repository from ISO to local filesystem

def copy_iso(values)
  verbose_message(values, "Checking:\tIf we can copy data from full repo ISO")
  if values['file'].to_s.match(/sol/)
    iso_test_dir = "#{values['mountdir']}/repo"
    if File.directory?(iso_test_dir)
      iso_repo_dir = iso_test_dir
    else
      iso_test_dir = "#{values['mountdir']}/publisher"
      if File.directory?(iso_test_dir)
        iso_repo_dir = values['mountdir']
      else
        warning_message(values, 'Repository source directory does not exist')
        quit(values) if values['dryrun'] != true
      end
    end
    test_dir = "#{values['repodir']}/publisher"
  else
    iso_repo_dir = values['mountdir']
    test_dir = case values['file']
               when /CentOS|rhel|OracleLinux|Fedora/
                 "#{values['repodir']}/isolinux"
               when /VCSA/
                 "#{values['repodir']}/vcsa"
               when /VM/
                 "#{values['repodir']}/upgrade"
               when /install|FreeBSD/
                 "#{values['repodir']}/etc"
               when /coreos/
                 "#{values['repodir']}/coreos"
               when /SLES/
                 "#{values['repodir']}/suse"
               else
                 "#{values['repodir']}/install"
               end
  end
  if !File.directory?(values['repodir']) && !File.symlink?(values['repodir']) && !values['file'].to_s.match(/\.iso/)
    warning_message(values, "Repository directory #{values['repodir']} does not exist")
    quit(values) if values['dryrun'] != true
  end
  if !File.directory?(test_dir) || values['file'].to_s.match(/DVD2\.iso|2of2\.iso/)
    if values['file'].to_s.match(/sol/)
      unless File.directory?(iso_repo_dir)
        warning_message(values, "Repository source directory #{iso_repo_dir} does not exist")
        quit(values) if values['dryrun'] != true
      end
      message = "Copying:\t#{iso_repo_dir} contents to #{values['repodir']}"
      command = "rsync -a #{iso_repo_dir}/. #{values['repodir']}"
      execute_command(values, message, command)
      if values['host-os-uname'].to_s.match(/SunOS/)
        message = "Rebuilding:\tRepository in #{values['repodir']}"
        command = "pkgrepo -s #{values['repodir']} rebuild"
        execute_command(values, message, command)
      end
    else
      check_dir_exists(values, test_dir)
      message = "Copying:\t#{iso_repo_dir} contents to #{values['repodir']}"
      command = "rsync -a #{iso_repo_dir}/. #{values['repodir']}"
      if values['repodir'].to_s.match(/sles_12/)
        execute_command(values, message, command) unless values['file'].to_s.match(/2\.iso/)
      else
        verbose_message(values, message)
        execute_command(values, message, command)
      end
    end
  end
  nil
end

# List domains/zones/etc instances

def list_doms(values, dom_type, dom_command)
  message = "Information:\nAvailable #{dom_type}(s)"
  command = dom_command
  output  = execute_command(values, message, command)
  output  = output.split("\n")
  if output.length.positive?
    if values['output'].to_s.match(/html/)
      verbose_message(values, "<h1>Available #{dom_type}(s)</h1>")
      verbose_message(values, '<table border="1">')
      verbose_message(values, '<tr>')
      verbose_message(values, '<th>Service</th>')
      verbose_message(values, '</tr>')
    else
      verbose_message(values, '')
      verbose_message(values, "Available #{dom_type}(s):")
      verbose_message(values, '')
    end
    output.each do |line|
      line = line.chomp
      line = line.gsub(/\s+$/, '')
      if values['output'].to_s.match(/html/)
        verbose_message(values, '<tr>')
        verbose_message(values, "<td>#{line}</td>")
        verbose_message(values, '</tr>')
      else
        verbose_message(values, line)
      end
    end
    verbose_message(values, '</table>') if values['output'].to_s.match(/html/)
  end
  nil
end

# List services

def list_services(values)
  search = if values['os-type'].to_s != values['empty'].to_s
             values['os-type'].to_s
           elsif values['method'].to_s != values['empty'].to_s
             values['method'].to_s
           elsif values['search'].to_s != values['empty'].to_s
             values['search'].to_s
           else
             'all'
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
  nil
end

# Unmount ISO

def umount_iso(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    command = "df |grep \"#{values['mountdir']}$\" |head -1 |awk \"{print \\\$1}\""
    execute_message(values, command)
    disk_id = `#{command}`
    disk_id = disk_id.chomp
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    message = "Detaching:\tISO device #{disk_id}"
    command = "sudo hdiutil detach #{disk_id}"
  else
    message = "Unmounting:\tISO mounted on #{values['mountdir']}"
    command = "umount #{values['mountdir']}"
  end
  execute_command(values, message, command)
  nil
end

# Clear a service out of maintenance mode

def clear_service(values, smf_service)
  message = "Checking:\tStatus of service #{smf_service}"
  command = "sleep 5 ; svcs -a |grep \"#{values['service']}\" |awk \"{print \\\$1}\""
  output  = execute_command(values, message, command)
  if output.match(/maintenance/)
    message = "Clearing:\tService #{smf_service}"
    command = "svcadm clear #{smf_service}"
    execute_command(values, message, command)
  end
  nil
end

# Occassionally DHCP gets stuck if it's restart to often
# Clear it out of maintenance mode

def clear_solaris_dhcpd(values)
  smf_service = 'svc:/network/dhcp/server:ipv4'
  clear_service(values, smf_service)
  nil
end

# Brew install a package on OS X

def brew_install(values, pkg_name)
  command = "brew install #{pkg_name}"
  message = "Information:\tInstalling #{pkg_name}"
  execute_command(values, message, command)
  nil
end

# Get method from service

def get_method_from_service(service)
  case service
  when /rhel|fedora|centos/
    method = 'ks'
  when /sol_10/
    method = 'js'
  when /sol_11/
    method = 'ai'
  when /ubuntu|debian/
    method = if service.match(/live/)
               'ci'
             else
               'ps'
             end
  when /sles|suse/
    method = 'ay'
  when /vmware/
    method = 'vs'
  end
  method
end

def check_perms(values)
  information_message(values, 'Checking client directory')
  check_dir_exists(values, values['clientdir'])
  check_dir_owner(values, values['clientdir'], values['uid'])
  nil
end
