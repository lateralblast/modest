# Linux specific functions

# Process ISO file to get details

def get_linux_version_info(file_name)
  iso_distro,iso_version,iso_arch = get_item_version_info(file_name)
  return iso_distro,iso_version,iso_arch
end

# List ISOs

def list_linux_isos(options)
  list_isos(options)
  return
end

# Get Linux version from distro name

def get_distro_version_from_distro_name(item_name)
  case item_name
  when /trusty/
    distro_version = "14.04"
  when /xenial/
    distro_version = "16.04"
  when /bionic/
    distro_version = "18.04"
  when /focal/
    distro_version = "20.04"
  when /hirsuite/
    distro_version = "21.04"
  when /jammy/
    distro_version = "22.04"
  end
  return distro_version
end

# Install Linux Package

def install_linux_package(options,pkg_name)
  if File.exist?("/etc/redhat-release") or File.exist?("/etc/SuSE-release")
    check_rhel_package(options,pkg_name)
  else
    check_apt_package(options,pkg_name)
  end
  return
end

# Enable ufw NAT

def enable_linux_ufw_nat(options,gw_if_name,if_name)
  message = "Information:\tChecking ufw firewall is set to allow traffic to internal VM network #{if_name}"
  command = "ufw status |grep out |grep '#{if_name}'"
  output  = execute_command(options,message,command)
  if not output.match(/#{if_name}/)
    message = "Information:\tSetting ufw firewall to allow traffic to internal VM network #{if_name}"
    command = "ufw allow out on #{if_name} ; ufw allow in on #{if_name}"
    output  = execute_command(options,message,command)
    message = "Information:\tRestarting UFW"
    command = "ufw disable ; echo y |ufw enable"
    output  = execute_command(options,message,command)
  end
  return
end

def enable_linux_ufw_internal_network(options)
  install_ip = single_install_ip(options)
  install_net = install_ip.split(".")[0..2].join(".")+".0/24"
  message = "Information:\tChecking if internal network '#{install_net}' is able to access ports on server"
  command = "ufw status |grep '#{install_net}'"
  output  = execute_command(options,message,command)
  if not output.match(/#{install_net}/)
    message = "Information:\tSetting ufw firewal to allow internal network '#{install_net}' to access ports on server"
    command = "ufw allow from '#{install_net}' to any"
    output  = execute_command(options,message,command)
    message = "Information:\tRestarting UFW"
    command = "ufw disable ; echo y |ufw enable"
    output  = execute_command(options,message,command)
  end
  return
end

# Enable iptables NAT 

def enable_linux_iptables_nat(options,gw_if_name,if_name)
  install_package(options,"iptables-persistent")
  message = "Information:\tSetting iptables firewall to allow traffic to internal VM network #{if_name}"
  command = "iptables --table nat --append POSTROUTING --out-interface #{gw_if_name} -j MASQUERADE ; iptables --append FORWARD --in-interface #{if_name} -j ACCEPT ; iptables-save"
  output  = execute_command(options,message,command)
  return
end

# Check Linux NAT

def check_linux_nat(options,gw_if_name,if_name)
  if File.exist?("/etc/iptables/rules.v4")
    message = "Information:\tChecking iptables firewall allows traffic to internal VM network #{if_name}"
    command = "cat /etc/iptables/rules.v4 |grep #{if_name}"
    output  = execute_command(options,message,command)
    if !output.match(/#{if_name}/)
      enable_linux_iptables_nat(options,gw_if_name,if_name)
    end
  end
  if File.exist?("/usr/sbin/ufw")
    enable_linux_ufw_nat(options,gw_if_name,if_name)
  end
  message = "Information:\tChecking IP forwarding is enabled"
  command = "sysctl net.ipv4.ip_forward"
  output  = execute_command(options,message,command)
  if output.match(/0/)
    message = "Information:\tEnabling IP forwarding"
    command = "sysctl -w net.ipv4.ip_forward=1"
    output  = execute_command(options,message,command)
  end
  return
end

# Stop Linux service

def stop_linux_service(options,service)
  message = "Information:\tStopping Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl stop #{service}"
  else
    command = "service #{service} stop"
  end
  output  = execute_command(options,message,command)
  return output
end

# Start Linux service

def start_linux_service(options,service)
  message = "Information\tStarting Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl start #{service}"
  else
    command = "service #{service} start"
  end
  output  = execute_command(options,message,command)
  return output
end

# Enable Linux service

def enable_linux_service(options,service)
  message = "Information\tEnabling Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl enable #{service}"
  else
    command = "chkconfig #{service} on"
  end
  output  = execute_command(options,message,command)
  start_linux_service(options,service)
  return output
end

# Disable Linux service

def disable_linux_service(options,service)
  message = "Information\tDisabling Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl disable #{service}"
  else
    command = "chkconfig #{service} off"
  end
  output  = execute_command(options,message,command)
  stop_linux_service(options,service)
  return output
end

# Refresh OS X service

def refresh_linux_service(options,service)
  restart_service(options,service)
  return
end

# Restart Linux related services

def restart_linux_service(options,service)
  message = "Information:\tRestarting Service "+service
  if File.exist?("/bin/systemctl")
    command = "systemctl restart #{service}"
  else
    command = "service #{service} restart"
  end
  output = execute_command(options,message,command)
  return output
end

# Install Snap package

def install_snap_pkg(options,pkg_name)
  message = "Information:\tUsing Snap to install package #{pkg_name}"
  command = "snap install #{pkg_name}"
  output  = execute_command(options,message,command)
  return output
end
