# Common routines for Multipass

# Check Multipass is installed

def check_multipass_is_installed(options)
  case options['host-os-name'].to_s
  when /Darwin/
    if !File.exist?("/usr/local/bin/multipass")
      install_brew_pkg(options, "multipass")
    end
  when /Linux/
    if !File.exist?("/snap/bin/multipass")
      install_snap_pkg(options, "multipass")
    end
  end
  if_name = get_vm_if_name(options)
  check_multipass_hostonly_network(options, if_name)
  return
end

# Connect Multipass VM

def connect_to_multipass_vm(options)
  exists = check_multipass_vm_exists(options)
  if exists == true
    output = "Information:\tTo connect to Multipass VM #{options['name']}"
    handle_output(options, output)
    output = "multipass shell #{options['name']}"
    handle_output(options, output)
  else
    handle_output(options, "Warning:\tMultipass VM #{options['name']} does not exist")
  end
  return
end

# Check Multipass NATd

def check_multipass_natd(options, vm_if_name)
  if options['vmnetwork'].to_s.match(/hostonly/)
    check_multipass_hostonly_network(options, if_name)
  end
  return options
end

# Check Multipass hostonly network

def check_multipass_hostonly_network(options, if_name)
  gw_if_name = get_gw_if_name(options)
  check_nat(options, gw_if_name, if_name)
  return
end

# Multipass post install

def multipass_post_install(options)
  exists = check_multipass_vm_exists(options)
  if options['nobuild'] == false
    if exists == false
      return options
    end
  end
  install_locale = options['q_struct']['locale'].value
  if install_locale.match(/\./)
    install_locale = install_locale.split(".")[0]
  end
  if options['livecd'] == true
    install_target  = "/target"
  else
    install_target  = ""
  end
  install_nameserver = options['q_struct']['nameserver'].value
  install_base_url   = "http://"+options['hostip']+"/"+options['name']
  install_layout  = install_locale.split("_")[0]
  install_variant = install_locale.split("_")[1].downcase
  install_gateway = options['q_struct']['gateway'].value
  admin_shell   = options['q_struct']['admin_shell'].value
  admin_sudo    = options['q_struct']['admin_sudo'].value
  disable_dhcp  = options['q_struct']['disable_dhcp'].value
  install_name  = options['q_struct']['hostname'].value
  resolved_conf = "/etc/systemd/resolved.conf"
  admin_user    = options['q_struct']['admin_username'].value
  admin_group   = options['q_struct']['admin_username'].value
  admin_home    = "/home/"+options['q_struct']['admin_username'].value
  admin_crypt   = options['q_struct']['admin_crypt'].value
  install_nic   = options['q_struct']['interface'].value
  if disable_dhcp.match(/true/)
    install_ip  = options['q_struct']['ip'].value
  end
  install_cidr  = options['q_struct']['cidr'].value
  install_disk  = options['q_struct']['partition_disk'].value
  #netplan_file  = "#{install_target}/etc/netplan/01-netcfg.yaml"
  netplan_file  = "#{install_target}/etc/netplan/50-cloud-init.yaml"
  locale_file   = "#{install_target}/etc/default/locales"
  grub_file = "#{install_target}/etc/default/grub"
  ssh_dir   = "#{install_target}/home/#{admin_user}/.ssh"
  auth_file = "#{ssh_dir}/authorized_keys"
  sudo_file = "#{install_target}/etc/sudoers.d/#{admin_user}"
  host_name = options['name'].to_s
  exec_data = []
  if options['dnsmasq'] == true && options['vm'].to_s.match(/mp|multipass/)
    exec_data.push("/usr/bin/systemctl disable systemd-resolved")
    exec_data.push("/usr/bin/systemctl stop systemd-resolved")
    exec_data.push("rm /etc/resolv.conf")
    if options['q_struct']['nameserver'].value.to_s.match(/\,/)
      nameservers = options['q_struct']['nameserver'].value.to_s.split("\,")
      nameservers.each do |nameserver|
        exec_data.push("echo 'nameserver #{nameserver}' >> /etc/resolv.conf")
      end
    else
      nameserver = options['q_struct']['nameserver'].value.to_s
      exec_data.push("  - echo 'nameserver #{nameserver}' >> /etc/resolv.conf")
    end
  end
  if options['dnsmasq'] == true || disable_dhcp.match(/true/)
    exec_data.push("echo '# This file describes the network interfaces available on your system' > #{netplan_file}")
    exec_data.push("echo '# For more information, see netplan(5).' >> #{netplan_file}")
    exec_data.push("echo 'network:' >> #{netplan_file}")
    exec_data.push("echo '  version: 2' >> #{netplan_file}")
    exec_data.push("echo '  renderer: networkd' >> #{netplan_file}")
    exec_data.push("echo '  ethernets:' >> #{netplan_file}")
    exec_data.push("echo '    #{install_nic}:' >> #{netplan_file}")
    exec_data.push("echo '      addresses: [#{install_ip}/#{install_cidr}]' >> #{netplan_file}")
    exec_data.push("echo '      gateway4: #{install_gateway}' >> #{netplan_file}")
    nameservers = options['q_struct']['nameserver'].value
    exec_data.push("echo '      nameservers:' >> #{netplan_file}")
    exec_data.push("echo '        addresses: [#{nameservers}]' >> #{netplan_file}")
  end 
  exec_data.each do |shell_command| 
    exec_command = "multipass exec #{host_name} -- sudo sh -c \"#{shell_command}\""
    if options['nobuild'] == true
      handle_output(options, exec_command)
    else
      %x[#{exec_command}]
    end
  end
  return options
end

# List Multipass instances

def list_multipass_vms(options)
  if options['name'] != options['empty']
    get_multipass_vm_info(options)
    return
  end
  if options['search'] != options['empty'] or options['search'].to_s.match(/all/)
    search_string = options['search'].to_s
    command = "multipass list |grep #{search_string} |grep -v ^Name"
  else
    command = "multipass list |grep -v ^Name"
  end
  message = "Informtion:\tGetting list of local Multipass instances"
  output  = execute_command(options, message, command)
  vm_list = output.split("\n")
  handle_output(options, "Image:\t\t\tState:\t\t  IPv4:\t\t   Image")
  vm_list = output.split("\n")
  vm_list.each do |line|
    handle_output(options, line)
  end
  return
end

# List available instances

def get_multipass_iso_list(options)
  if options['search'] != options['empty'] or options['search'].to_s.match(/all/)
    search_string = options['search'].to_s
    command = "multipass find |grep #{search_string} |grep -v ^Image"
  else
    command = "multipass find |grep -v ^Image"
  end
  message  = "Informtion:\tGetting list of remote Multipass instances"
  output   = execute_command(options, message, command)
  iso_list = output.split("\n")
  return iso_list
end

# Get service name from release name

def get_multipass_service_from_release(options)
  release = options['release'].to_s
  machine = options['host-os-machine'].to_s
  if options['service'] == options['empty']
    message = "Information:\tDetermining service name"
    command = "multipass find |grep '^#{release}'"
    output  = execute_command(options, message, command)
    output  = output.chomp.gsub(/ LTS/, "")
  else
    if release.match(/^[0-9]/)
      options['service'] = "ubuntu_"+release.gsub(/\./, "_")+"_"+machine
    end
  end
  return options
end

# Check if Multipass instance exists

def check_multipass_vm_exists(options)
  exists = false
  if options['name'] == options['empty']
    handle_output(options, "Warning:\tNo client name specified")
    quit(options)
  end
  vm_name = options['name'].to_s
  message = "Information:\tChecking if VM #{vm_name} exists"
  command = "multipass list |grep #{vm_name}"
  output  = execute_command(options, message, command)
  if output.match(/#{vm_name}/)
    exists = true
  end
  return exists
end

# Execute command in Multipass VM

def execute_multipass_command(options)
  command = options['command'].to_s 
	exists  = check_multipass_vm_exists(options)
	if exists == true
    command = "multipass exec #{options['name']} -- bash -c \"#{command}\""
		output  = %x[#{command}]
		handle_output(options, output)
	else
		handle_output(options, "Information:\tMultipass instance #{options['name']} does not exist")
	end
  return
end

# Create Multipass VM

def configure_multipass_vm(options)
  exists  = check_multipass_vm_exists(options)
  vm_name = options['name'].to_s
  options = process_memory_value(options)
  if exists == true
    handle_output(options, "Warning:\tMultipass VM #{vm_name} already exists")
    quit(options)
  else
    message = "Information:\tCreating Multipass VM #{vm_name}"
    if options['method'].to_s.match(/ci/)
      if options['file'] != options['empty']
        command = "cat #{options['file'].to_s} |multipass launch --name #{vm_name} --cloud-init -"
      else
        options = configure_ps_client(options)
        options = get_multipass_service_from_release(options)
        options['file'] = options['clientdir'].to_s+"/user-data"
        no_cpus = options['vcpu'].to_s
        vm_size = options['size'].to_s
        memory  = options['memory'].to_s
        command = "cat #{options['file'].to_s} |multipass launch --cpus #{no_cpus} --disk #{vm_size} --mem #{memory} --name #{vm_name} --cloud-init -"
      end
    else
      no_cpus = options['vcpu'].to_s
      vm_size = options['size'].to_s
      memory  = options['memory'].to_s
      command = "multipass launch --cpus #{no_cpus} --disk #{vm_size} --mem #{memory} --name #{vm_name}"
    end
    if not options['release'] == options['empty']
      command = command+" "+options['release'].to_s
    end
    if options['nobuild'] == false
      execute_command(options, message, command)
    else
      handle_output(options, "Build Command:")
      handle_output(options, command)
    end
  end
  options = multipass_post_install(options)
  return
end

# Get Multipass VM info

def get_multipass_vm_info(options)
  exists  = check_multipass_vm_exists(options)
  vm_name = options['name'].to_s
  if exists == true && !options['action'].to_s.match(/list/)
    handle_output(options, "Warning:\tMultipass VM #{vm_name} already exists")
  else
    message = "Information:\Getting information for Multipass VM #{vm_name}"
    command = "multipass info #{vm_name}"
    output  = execute_command(options, message, command)
    lines   = output.split("\n")
    lines.each do |line|
      if options['search'] != options['empty']
        if line.downcase.match(/#{options['search'].to_s.downcase}/)
          handle_output(options, line)
        end
      else
        handle_output(options, line)
      end
    end
  end
  return
end

# Delete Multipass VM

def delete_multipass_vm(options)
  unconfigure_multipass_vm(options)
  return
end

def unconfigure_multipass_vm(options)
  exists  = check_multipass_vm_exists(options)
  vm_name = options['name'].to_s
  if exists == true
    message = "Information:\tDeleting Mulipass VM #{vm_name}"
    command = "multipass delete #{vm_name}; multipass purge"
    execute_command(options, message, command)
  else
    handle_output(options, "Warning:\tMultipass VM #{vm_name} does not exist")
  end
  return
end

# Start Multipass instance

def boot_multipass_vm(options)
  exists  = check_multipass_vm_exists(options)
  vm_name = options['name'].to_s
  if exists == true
    message = "Information:\tStarting Mulipass VM #{vm_name}"
    command = "multipass start #{vm_name}"
    execute_command(options, message, command)
  else
    handle_output("Warning:\tMultipass VM #{vm_name} does not exist")
  end
  return
end

# Stop Multipass instance

def stop_multipass_vm(options)
  exists  = check_multipass_vm_exists(options)
  vm_name = options['name'].to_s
  if exists == true
    message = "Information:\tStopping Mulipass VM #{vm_name}"
    command = "multipass stop #{vm_name}"
    execute_command(options, message, command)
  else
    handle_output("Warning:\tMultipass VM #{vm_name} does not exist")
  end
  return
end
