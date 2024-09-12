# Common routines for Multipass

# Check Multipass is installed

def check_multipass_is_installed(values)
  case values['host-os-uname'].to_s
  when /Darwin/
    if !File.exist?("/usr/local/bin/multipass")
      install_brew_pkg(values, "multipass")
    end
  when /Linux/
    if !File.exist?("/snap/bin/multipass")
      install_snap_pkg(values, "multipass")
    end
  end
  if_name = get_vm_if_name(values)
  check_multipass_hostonly_network(values, if_name)
  return
end

# Connect Multipass VM

def connect_to_multipass_vm(values)
  exists = check_multipass_vm_exists(values)
  if exists == true
    output = "Information:\tTo connect to Multipass VM #{values['name']}"
    verbose_output(values, output)
    output = "multipass shell #{values['name']}"
    verbose_output(values, output)
  else
    verbose_output(values, "Warning:\tMultipass VM #{values['name']} does not exist")
  end
  return
end

# Check Multipass NATd

def check_multipass_natd(values, vm_if_name)
  if values['vmnetwork'].to_s.match(/hostonly/)
    check_multipass_hostonly_network(values, if_name)
  end
  return values
end

# Check Multipass hostonly network

def check_multipass_hostonly_network(values, if_name)
  gw_if_name = get_gw_if_name(values)
  check_nat(values, gw_if_name, if_name)
  return
end

# Multipass post install

def multipass_post_install(values)
  exists = check_multipass_vm_exists(values)
  if values['nobuild'] == false
    if exists == false
      return values
    end
  end
  install_locale = values['q_struct']['locale'].value
  if install_locale.match(/\./)
    install_locale = install_locale.split(".")[0]
  end
  if values['livecd'] == true
    install_target  = "/target"
  else
    install_target  = ""
  end
  install_nameserver = values['q_struct']['nameserver'].value
  install_base_url   = "http://"+values['hostip']+"/"+values['name']
  install_layout  = install_locale.split("_")[0]
  install_variant = install_locale.split("_")[1].downcase
  install_gateway = values['q_struct']['gateway'].value
  admin_shell   = values['q_struct']['admin_shell'].value
  admin_sudo    = values['q_struct']['admin_sudo'].value
  disable_dhcp  = values['q_struct']['disable_dhcp'].value
  install_name  = values['q_struct']['hostname'].value
  resolved_conf = "/etc/systemd/resolved.conf"
  admin_user    = values['q_struct']['admin_username'].value
  admin_group   = values['q_struct']['admin_username'].value
  admin_home    = "/home/"+values['q_struct']['admin_username'].value
  admin_crypt   = values['q_struct']['admin_crypt'].value
  install_nic   = values['q_struct']['interface'].value
  if disable_dhcp.match(/true/)
    install_ip  = values['q_struct']['ip'].value
  end
  install_cidr  = values['q_struct']['cidr'].value
  install_disk  = values['q_struct']['partition_disk'].value
  #netplan_file  = "#{install_target}/etc/netplan/01-netcfg.yaml"
  netplan_file  = "#{install_target}/etc/netplan/50-cloud-init.yaml"
  locale_file   = "#{install_target}/etc/default/locales"
  grub_file = "#{install_target}/etc/default/grub"
  ssh_dir   = "#{install_target}/home/#{admin_user}/.ssh"
  auth_file = "#{ssh_dir}/authorized_keys"
  sudo_file = "#{install_target}/etc/sudoers.d/#{admin_user}"
  host_name = values['name'].to_s
  exec_data = []
  if values['dnsmasq'] == true && values['vm'].to_s.match(/mp|multipass/)
    exec_data.push("/usr/bin/systemctl disable systemd-resolved")
    exec_data.push("/usr/bin/systemctl stop systemd-resolved")
    exec_data.push("rm /etc/resolv.conf")
    if values['q_struct']['nameserver'].value.to_s.match(/\,/)
      nameservers = values['q_struct']['nameserver'].value.to_s.split("\,")
      nameservers.each do |nameserver|
        exec_data.push("echo 'nameserver #{nameserver}' >> /etc/resolv.conf")
      end
    else
      nameserver = values['q_struct']['nameserver'].value.to_s
      exec_data.push("  - echo 'nameserver #{nameserver}' >> /etc/resolv.conf")
    end
  end
  if values['dnsmasq'] == true || disable_dhcp.match(/true/)
    exec_data.push("echo '# This file describes the network interfaces available on your system' > #{netplan_file}")
    exec_data.push("echo '# For more information, see netplan(5).' >> #{netplan_file}")
    exec_data.push("echo 'network:' >> #{netplan_file}")
    exec_data.push("echo '  version: 2' >> #{netplan_file}")
    exec_data.push("echo '  renderer: networkd' >> #{netplan_file}")
    exec_data.push("echo '  ethernets:' >> #{netplan_file}")
    exec_data.push("echo '    #{install_nic}:' >> #{netplan_file}")
    exec_data.push("echo '      addresses: [#{install_ip}/#{install_cidr}]' >> #{netplan_file}")
    exec_data.push("echo '      gateway4: #{install_gateway}' >> #{netplan_file}")
    nameservers = values['q_struct']['nameserver'].value
    exec_data.push("echo '      nameservers:' >> #{netplan_file}")
    exec_data.push("echo '        addresses: [#{nameservers}]' >> #{netplan_file}")
  end 
  exec_data.each do |shell_command| 
    exec_command = "multipass exec #{host_name} -- sudo sh -c \"#{shell_command}\""
    if values['nobuild'] == true
      verbose_output(values, exec_command)
    else
      %x[#{exec_command}]
    end
  end
  return values
end

# List Multipass instances

def list_multipass_vms(values)
  if values['name'] != values['empty']
    get_multipass_vm_info(values)
    return
  end
  if values['search'] != values['empty'] or values['search'].to_s.match(/all/)
    search_string = values['search'].to_s
    command = "multipass list |grep #{search_string} |grep -v ^Name"
  else
    command = "multipass list |grep -v ^Name"
  end
  message = "Informtion:\tGetting list of local Multipass instances"
  output  = execute_command(values, message, command)
  vm_list = output.split("\n")
  verbose_output(values, "Image:\t\t\tState:\t\t  IPv4:\t\t   Image")
  vm_list = output.split("\n")
  vm_list.each do |line|
    verbose_output(values, line)
  end
  return
end

# List available instances

def get_multipass_iso_list(values)
  if values['search'] != values['empty'] or values['search'].to_s.match(/all/)
    search_string = values['search'].to_s
    command = "multipass find |grep #{search_string} |grep -v ^Image"
  else
    command = "multipass find |grep -v ^Image"
  end
  message  = "Informtion:\tGetting list of remote Multipass instances"
  output   = execute_command(values, message, command)
  iso_list = output.split("\n")
  return iso_list
end

# Get service name from release name

def get_multipass_service_from_release(values)
  release = values['release'].to_s
  machine = values['host-os-unamem'].to_s
  if values['service'] == values['empty']
    message = "Information:\tDetermining service name"
    command = "multipass find |grep '^#{release}'"
    output  = execute_command(values, message, command)
    output  = output.chomp.gsub(/ LTS/, "")
  else
    if release.match(/^[0-9]/)
      values['service'] = "ubuntu_"+release.gsub(/\./, "_")+"_"+machine
    end
  end
  return values
end

# Check if Multipass instance exists

def check_multipass_vm_exists(values)
  exists = false
  if values['name'] == values['empty']
    verbose_output(values, "Warning:\tNo client name specified")
    quit(values)
  end
  vm_name = values['name'].to_s
  message = "Information:\tChecking if VM #{vm_name} exists"
  command = "multipass list |grep #{vm_name}"
  output  = execute_command(values, message, command)
  if output.match(/#{vm_name}/)
    exists = true
  end
  return exists
end

# Execute command in Multipass VM

def execute_multipass_command(values)
  command = values['command'].to_s 
	exists  = check_multipass_vm_exists(values)
	if exists == true
    command = "multipass exec #{values['name']} -- bash -c \"#{command}\""
		output  = %x[#{command}]
		verbose_output(values, output)
	else
		verbose_output(values, "Information:\tMultipass instance #{values['name']} does not exist")
	end
  return
end

# Create Multipass VM

def configure_multipass_vm(values)
  exists  = check_multipass_vm_exists(values)
  vm_name = values['name'].to_s
  values = process_memory_value(values)
  if exists == true
    verbose_output(values, "Warning:\tMultipass VM #{vm_name} already exists")
    quit(values)
  else
    message = "Information:\tCreating Multipass VM #{vm_name}"
    if values['method'].to_s.match(/ci/)
      if values['file'] != values['empty']
        command = "cat #{values['file'].to_s} |multipass launch --name #{vm_name} --cloud-init -"
      else
        values = configure_ps_client(values)
        values = get_multipass_service_from_release(values)
        values['file'] = values['clientdir'].to_s+"/user-data"
        no_cpus = values['vcpu'].to_s
        vm_size = values['size'].to_s
        memory  = values['memory'].to_s
        command = "cat #{values['file'].to_s} |multipass launch --cpus #{no_cpus} --disk #{vm_size} --mem #{memory} --name #{vm_name} --cloud-init -"
      end
    else
      no_cpus = values['vcpu'].to_s
      vm_size = values['size'].to_s
      memory  = values['memory'].to_s
      command = "multipass launch --cpus #{no_cpus} --disk #{vm_size} --mem #{memory} --name #{vm_name}"
    end
    if not values['release'] == values['empty']
      command = command+" "+values['release'].to_s
    end
    if values['nobuild'] == false
      execute_command(values, message, command)
    else
      verbose_output(values, "Build Command:")
      verbose_output(values, command)
    end
  end
  values = multipass_post_install(values)
  return
end

# Get Multipass VM info

def get_multipass_vm_info(values)
  exists  = check_multipass_vm_exists(values)
  vm_name = values['name'].to_s
  if exists == true && !values['action'].to_s.match(/list/)
    verbose_output(values, "Warning:\tMultipass VM #{vm_name} already exists")
  else
    message = "Information:\Getting information for Multipass VM #{vm_name}"
    command = "multipass info #{vm_name}"
    output  = execute_command(values, message, command)
    lines   = output.split("\n")
    lines.each do |line|
      if values['search'] != values['empty']
        if line.downcase.match(/#{values['search'].to_s.downcase}/)
          verbose_output(values, line)
        end
      else
        verbose_output(values, line)
      end
    end
  end
  return
end

# Delete Multipass VM

def delete_multipass_vm(values)
  unconfigure_multipass_vm(values)
  return
end

def unconfigure_multipass_vm(values)
  exists  = check_multipass_vm_exists(values)
  vm_name = values['name'].to_s
  if exists == true
    message = "Information:\tDeleting Mulipass VM #{vm_name}"
    command = "multipass delete #{vm_name}; multipass purge"
    execute_command(values, message, command)
  else
    verbose_output(values, "Warning:\tMultipass VM #{vm_name} does not exist")
  end
  return
end

# Start Multipass instance

def boot_multipass_vm(values)
  exists  = check_multipass_vm_exists(values)
  vm_name = values['name'].to_s
  if exists == true
    message = "Information:\tStarting Mulipass VM #{vm_name}"
    command = "multipass start #{vm_name}"
    execute_command(values, message, command)
  else
    verbose_output("Warning:\tMultipass VM #{vm_name} does not exist")
  end
  return
end

# Stop Multipass instance

def stop_multipass_vm(values)
  exists  = check_multipass_vm_exists(values)
  vm_name = values['name'].to_s
  if exists == true
    message = "Information:\tStopping Mulipass VM #{vm_name}"
    command = "multipass stop #{vm_name}"
    execute_command(values, message, command)
  else
    verbose_output("Warning:\tMultipass VM #{vm_name} does not exist")
  end
  return
end
