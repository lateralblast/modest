# Linux specific functions

# Process ISO file to get details

def get_linux_version_info(file_name)
  iso_info = File.basename(file_name)
  if file_name.match(/purity/)
    iso_info    = iso_info.split(/_/)
  else
    iso_info     = iso_info.split(/-/)
  end
  linux_distro = iso_info[0]
  linux_distro = linux_distro.downcase
  if linux_distro.match(/^sle$/)
    linux_distro = "sles"
  end
  if linux_distro.match(/oraclelinux/)
    linux_distro = "oel"
  end
  if linux_distro.match(/centos|ubuntu|sles|sl|oel|rhel/)
    if linux_distro.match(/sles/)
      if iso_info[2].to_s.match(/Server/)
        iso_version = iso_info[1]+".0"
      else
        iso_version = iso_info[1]+"."+iso_info[2]
        iso_version = iso_version.gsub(/SP/,"")
      end
    else
      if linux_distro.match(/sl$/)
        iso_version = iso_info[1].split(//).join(".")
        if iso_version.length == 1
          iso_version = iso_version+".0"
        end
      else
        if linux_distro.match(/oel|rhel/)
          if file_name =~ /-rc-/
            iso_version = iso_info[1..3].join(".")
            iso_version = iso_version.gsub(/server/,"")
          else
            iso_version = iso_info[1..2].join(".")
            iso_version = iso_version.gsub(/[a-z,A-Z]/,"")
          end
          iso_version = iso_version.gsub(/^\./,"")
        else
          iso_version = iso_info[1]
        end
      end
    end
    if iso_version.match(/86_64/)
      iso_version = iso_info[1]
    end
    case file_name
    when /i[3-6]86/
      iso_arch = "i386"
    when /x86_64|amd64/
      iso_arch = "x86_64"
    else
      if linux_distro.match(/centos|sl$/)
        iso_arch = iso_info[2]
      else
        if linux_distro.match(/sles|oel/)
          iso_arch = iso_info[4]
        else
          iso_arch = iso_info[3]
        end
      end
    end
  else
    case linux_distro
    when /fedora/
      iso_version = iso_info[1]
      iso_arch    = iso_info[2]
    when /purity/
      iso_version = iso_info[1]
      iso_arch    = "x86_64"
    when /vmware/
      iso_version = iso_info[3].split(/\./)[0..-2].join(".")
      iso_update  = iso_info[3].split(/\./)[-1]
      iso_release = iso_info[4].split(/\./)[-3]
      iso_version = iso_version+"."+iso_update+"."+iso_release
      iso_arch    = "x86_64"
    else
      iso_version = iso_info[2]
      iso_arch    = iso_info[3]
    end
  end
  return linux_distro,iso_version,iso_arch
end

# List ISOs

def list_linux_isos(search_string,linux_type,options)
  if options['file'] == options['empty']
    iso_list = check_iso_base_dir(search_string,linux_type)
  else
    iso_list    = []
    iso_list[0] = options['file']
  end
  if iso_list.length > 0
    if options['output'].to_s.match(/html/)
      handle_output(options,"<h1>Available #{linux_type} ISOs:</h1>")
      handle_output(options,"<table border=\"1\">")
      handle_output(options,"<tr>")
      handle_output(options,"<th>ISO File</th>")
      handle_output(options,"<th>Distribution</th>")
      handle_output(options,"<th>Version</th>")
      handle_output(options,"<th>Architecture</th>")
      handle_output(options,"<th>Service Name</th>")
      handle_output(options,"</tr>")
    else
      handle_output(options,"Available #{linux_type} ISOs:")
      handle_output(options,"") 
    end
    iso_list.each do |file_name|
      file_name = file_name.chomp
      (linux_distro,iso_version,iso_arch) = get_linux_version_info(file_name)
      if options['output'].to_s.match(/html/)
        handle_output(options,"<tr>")
        handle_output(options,"<td>#{file_name}</td>")
        handle_output(options,"<td>#{linux_distro}</td>")
        handle_output(options,"<td>#{iso_version}</td>")
        handle_output(options,"<td>#{iso_arch}</td>")
      else
        handle_output(options,"ISO file:\t#{file_name}")
        handle_output(options,"Distribution:\t#{linux_distro}")
        handle_output(options,"Version:\t#{iso_version}")
        handle_output(options,"Architecture:\t#{iso_arch}")
      end
      iso_version      = iso_version.gsub(/\./,"_")
      options['service']     = linux_distro+"_"+iso_version+"_"+iso_arch
      options['repodir'] = options['baserepodir']+"/"+options['service']
      if File.directory?(options['repodir'])
        if options['output'].to_s.match(/html/)
          handle_output(options,"<td>#{options['service']} (exists)</td>")
        else
          handle_output(options,"Service Name:\t#{options['service']} (exists)")
        end
      else
        if options['output'].to_s.match(/html/)
          handle_output(options,"<td>#{options['service']}</td>")
        else
          handle_output(options,"Service Name:\t#{options['service']}")
        end
      end
      if options['output'].to_s.match(/html/)
        handle_output(options,"</tr>")
      else
        handle_output(options,"") 
      end
    end
    if options['output'].to_s.match(/html/)
      handle_output(options,"</table>")
    end
  end
  return
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
  message = "Information:\tSetting iptables firewall to allow traffic to internal VM network #{if_name}"
  command = "iptables --table nat --append POSTROUTING --out-interface #{gw_if_name} -j MASQUERADE ; iptables --append FORWARD --in-interface #{if_name} -j ACCEPT"
  output  = execute_command(options,message,command)
  return
end

# Check Linux NAT

def check_linux_nat(options,gw_if_name,if_name)
  message = "Information:\tChecking iptables firewall allows traffic to internal VM network #{if_name}"
  command = "iptables --list |grep #{if_name}"
  output  = execute_command(options,message,command)
  if !output.match(/#{if_name}/)
    enable_linux_iptables_nat(options,gw_if_name,if_name)
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
  output  = execute_command(options,message,command)
  return output
end
