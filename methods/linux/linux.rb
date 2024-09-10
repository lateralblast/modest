# Linux specific functions

# Process ISO file to get details

def get_linux_version_info(file_name)
  iso_distro, iso_version, iso_arch = get_item_version_info(file_name)
  return iso_distro, iso_version, iso_arch
end

# List ISOs

def list_linux_isos(options)
  list_isos(options)
  return
end

# Get codename from Linux version

def get_code_name_from_release_version(release_version)
  case release_version
  when /^4\.10/
    code_name = "warty"
  when /^5\.04/
    code_name = "hoary"
  when /^5\.10/
    code_name = "breezy"
  when /^6\.04/
    code_name = "dapper"
  when /^6\.10/
    code_name = "edgy"
  when /^7\.04/
    code_name = "feisty"
  when /^7\.10/
    code_name = "putsy"
  when /^8\.04/
    code_name = "hardy"
  when /^8\.10/
    code_name = "intrepid"
  when /^9\.04/
    code_name = "jaunty"
  when /^9\.10/
    code_name = "karmic"
  when /10\.04/
    code_name = "lucid"
  when /10\.10/
    code_name = "maverick"
  when /11\.04/
    code_name = "natty"
  when /11\.10/
    code_name = "oneiric"
  when /12\.04/
    code_name = "precise"
  when /12\.10/
    code_name = "quantal"
  when /13\.04/
    code_name = "raring"
  when /13\.10/
    code_name = "saucy"
  when /14\.04/
    code_name = "trusty"
  when /14\.10/
    code_name = "utopic"
  when /15\.04/
    code_name = "vivid"
  when /15\.10/
    code_name = "willy"
  when /16\.04/
    code_name = "xenial"
  when /16\.10/
    code_name = "yakkety"
  when /17\.04/
    code_name = "zesty"
  when /17\.10/
    code_name = "artful"
  when /18\.04/
    code_name = "bionic"
  when /18\.10/
    code_name = "cosmic"
  when /19\.04/
    code_name = "disco"
  when /19\.10/
    code_name = "eoan"
  when /20\.04/
    code_name = "focal"
  when /20\.10/
    code_name = "groovy"
  when /21\.04/
    code_name = "hirsuite"
  when /21\.10/
    code_name = "impish"
  when /22\.04/
    code_name = "jammy"
  when /22\.10/
    code_name = "kinetic"
  when /23\.04/
    code_name = "lunar"
  when /23\.10/
    code_name = "mantic"
  when /24\.04/
    code_name = "noble"
  end
  return code_name
end

# Get Linux version from codename

def get_release_version_from_code_name(item_name)
  case item_name
  when /warty/
    distro_version = "4.10"
  when /hoary/
    distro_version = "5.04"
  when /breezy/
    distro_version = "5.10"
  when /dapper/
    distro_version = "6.04"
  when /edgy/
    distro_version = "6.10"
  when /feisty/
    distro_version = "7.04"
  when /gutsy/
    distro_version = "7.10"
  when /hardy/
    distro_version = "8.04"
  when /intrepid/
    distro_version = "8.10"
  when /jaunty/
    distro_version = "9.04"
  when /karmic/
    distro_version = "9.10"
  when /lucid/
    distro_version = "10.04"
  when /maverick/
    distro_version = "10.10"
  when /natty/
    distro_version = "11.04"
  when /oneiric/
    distro_version = "11.10"
  when /precise/
    distro_version = "12.04"
  when /quantal/
    distro_version = "12.10"
  when /raring/
    distro_version = "13.04"
  when /saucy/
    distro_version = "13.10"
  when /trusty/
    distro_version = "14.04"
  when /utopic/
    distro_version = "14.10"
  when /vivid/
    distro_version = "15.04"
  when /wily/
    distro_version = "15.10"
  when /xenial/
    distro_version = "16.04"
  when /yakkety/
    distro_version = "16.10"
  when /zesty/
    distro_version = "17.04"
  when /artful/
    distro_version = "17.10"
  when /bionic/
    distro_version = "18.04"
  when /cosmic/
    distro_version = "18.10"
  when /disco/
    distro_version = "19.04"
  when /eoan/
    distro_version = "19.10"
  when /focal/
    distro_version = "20.04"
  when /groovy/
    distro_version = "20.10"
  when /hirsuite/
    distro_version = "21.04"
  when /impish/
    distro_version = "21.10"
  when /jammy/
    distro_version = "22.04"
  when /kinetic/
    distro_version = "22.10"
  when /lunar/
    distro_version = "23.04"
  when /mantic/
    distro_version = "23.10"
  when /noble/
    distro_version = "24.04"
  end
  return distro_version
end

# Install Linux Package

def install_linux_package(options, pkg_name)
  if options['host-lsb-description'].to_s.match(/Endeavour|Arch/)
    check_arch_package(options, pkg_name)
  else
    if File.exist?("/etc/redhat-release") or File.exist?("/etc/SuSE-release")
      check_rhel_package(options, pkg_name)
    else
      check_apt_package(options, pkg_name)
    end
  end
  return
end

# Check DNSmasq

def check_linux_dnsmasq(options)
  pkg_name = "dnsmasq"
  install_linux_package(options, pkg_name)
  return
end

# Enable ufw NAT

def enable_linux_ufw_nat(options, gw_if_name, if_name)
  message = "Information:\tChecking ufw firewall is set to allow traffic to internal VM network #{if_name}"
  command = "ufw status |grep out |grep '#{if_name}'"
  output  = execute_command(options, message, command)
  if not output.match(/#{if_name}/)
    message = "Information:\tSetting ufw firewall to allow traffic to internal VM network #{if_name}"
    command = "ufw allow out on #{if_name} ; ufw allow in on #{if_name}"
    output  = execute_command(options, message, command)
    message = "Information:\tRestarting UFW"
    command = "ufw disable ; echo y |ufw enable"
    output  = execute_command(options, message, command)
  end
  return
end

def enable_linux_ufw_internal_network(options)
  install_ip  = single_install_ip(options)
  install_net = install_ip.split(".")[0..2].join(".")+".0/24"
  message = "Information:\tChecking if internal network '#{install_net}' is able to access ports on server"
  command = "ufw status |grep '#{install_net}'"
  output  = execute_command(options, message, command)
  if not output.match(/#{install_net}/)
    message = "Information:\tSetting ufw firewal to allow internal network '#{install_net}' to access ports on server"
    command = "ufw allow from '#{install_net}' to any"
    output  = execute_command(options, message, command)
    message = "Information:\tRestarting UFW"
    command = "ufw disable ; echo y |ufw enable"
    output  = execute_command(options, message, command)
  end
  return
end

# Enable iptables NAT 

def enable_linux_iptables_nat(options, gw_if_name, if_name)
  install_package(options, "iptables-persistent")
  message = "Information:\tSetting iptables firewall to allow traffic to internal VM network #{if_name}"
  command = "iptables --table nat --append POSTROUTING --out-interface #{gw_if_name} -j MASQUERADE ; iptables --append FORWARD --in-interface #{if_name} -j ACCEPT ; iptables-save"
  output  = execute_command(options, message, command)
  return
end

# Check Linux NAT

def check_linux_nat(options, gw_if_name, if_name)
  if File.exist?("/etc/iptables/rules.v4")
    message = "Information:\tChecking iptables firewall allows traffic to internal VM network #{if_name}"
    command = "cat /etc/iptables/rules.v4 |grep #{if_name}"
    output  = execute_command(options, message, command)
    if !output.match(/#{if_name}/)
      enable_linux_iptables_nat(options, gw_if_name, if_name)
    end
  end
  if File.exist?("/usr/sbin/ufw")
    if options['vm'].to_s.match(/kvm/)
      if options['bridge'].to_s.match(/virbr/)
        enable_linux_ufw_nat(options, gw_if_name, if_name)
      end
    else
      enable_linux_ufw_nat(options, gw_if_name, if_name)
    end
  end
  message = "Information:\tChecking IP forwarding is enabled"
  command = "sysctl net.ipv4.ip_forward"
  output  = execute_command(options, message, command)
  if output.match(/0/)
    message = "Information:\tEnabling IP forwarding"
    command = "sysctl -w net.ipv4.ip_forward=1"
    output  = execute_command(options, message, command)
  end
  return
end

# Stop Linux service

def stop_linux_service(options, service)
  message = "Information:\tStopping Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl stop #{service}"
  else
    command = "service #{service} stop"
  end
  output  = execute_command(options, message, command)
  return output
end

# Start Linux service

def start_linux_service(options, service)
  message = "Information\tStarting Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl start #{service}"
  else
    command = "service #{service} start"
  end
  output  = execute_command(options, message, command)
  return output
end

# Enable Linux service

def enable_linux_service(options, service)
  message = "Information\tEnabling Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl enable #{service}"
  else
    command = "chkconfig #{service} on"
  end
  output  = execute_command(options, message, command)
  start_linux_service(options, service)
  return output
end

# Disable Linux service

def disable_linux_service(options, service)
  message = "Information\tDisabling Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl disable #{service}"
  else
    command = "chkconfig #{service} off"
  end
  output  = execute_command(options, message, command)
  stop_linux_service(options, service)
  return output
end

# Refresh OS X service

def refresh_linux_service(options, service)
  restart_service(options, service)
  return
end

# Restart Linux related services

def restart_linux_service(options, service)
  message = "Information:\tRestarting Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl restart #{service}"
  else
    command = "service #{service} restart"
  end
  output = execute_command(options, message, command)
  return output
end

# Install Snap package

def install_snap_pkg(options, pkg_name)
  message = "Information:\tUsing Snap to install package #{pkg_name}"
  command = "snap install #{pkg_name}"
  output  = execute_command(options, message, command)
  return output
end
