# frozen_string_literal: true

# Common routines for Multipass

# Check Multipass is installed

def check_multipass_is_installed(values)
  case values['host-os-uname'].to_s
  when /Darwin/
    install_brew_pkg(values, 'multipass') unless File.exist?('/usr/local/bin/multipass')
  when /Linux/
    install_snap_pkg(values, 'multipass') unless File.exist?('/snap/bin/multipass')
  end
  if_name = get_vm_if_name(values)
  check_multipass_hostonly_network(values, if_name)
  nil
end

# Connect Multipass VM

def connect_to_multipass_vm(values)
  exists = check_multipass_vm_exists(values)
  if exists == true
    output = "Information:\tTo connect to Multipass VM #{values['name']}"
    verbose_message(values, output)
    output = "multipass shell #{values['name']}"
    verbose_message(values, output)
  else
    warning_message(values, "Multipass VM #{values['name']} does not exist")
  end
  nil
end

# Check Multipass NATd

def check_multipass_natd(values, _vm_if_name)
  check_multipass_hostonly_network(values, if_name) if values['vmnetwork'].to_s.match(/hostonly/)
  values
end

# Check Multipass hostonly network

def check_multipass_hostonly_network(values, if_name)
  gw_if_name = get_gw_if_name(values)
  check_nat(values, gw_if_name, if_name)
  nil
end

# Multipass post install

def multipass_post_install(values)
  exists = check_multipass_vm_exists(values)
  return values if (values['nobuild'] == false) && (exists == false)

  install_locale = values['answers']['locale'].value
  install_locale = install_locale.split('.')[0] if install_locale.match(/\./)
  install_target = if values['livecd'] == true
                     '/target'
                   else
                     ''
                   end
  values['answers']['nameserver'].value
  values['hostip']
  values['name']
  install_locale.split('_')[0]
  install_locale.split('_')[1].downcase
  install_gateway = values['answers']['gateway'].value
  values['answers']['admin_shell'].value
  values['answers']['admin_sudo'].value
  disable_dhcp = values['answers']['disable_dhcp'].value
  values['answers']['hostname'].value
  values['answers']['admin_username'].value
  values['answers']['admin_username'].value
  values['answers']['admin_username'].value
  values['answers']['admin_crypt'].value
  install_nic = values['answers']['interface'].value
  install_ip = values['answers']['ip'].value if disable_dhcp.match(/true/)
  install_cidr = values['answers']['cidr'].value
  values['answers']['partition_disk'].value
  # netplan_file  = "#{install_target}/etc/netplan/01-netcfg.yaml"
  netplan_file = "#{install_target}/etc/netplan/50-cloud-init.yaml"
  host_name = values['name'].to_s
  exec_data = []
  if values['dnsmasq'] == true && values['vm'].to_s.match(/mp|multipass/)
    exec_data.push('/usr/bin/systemctl disable systemd-resolved')
    exec_data.push('/usr/bin/systemctl stop systemd-resolved')
    exec_data.push('rm /etc/resolv.conf')
    if values['answers']['nameserver'].value.to_s.match(/,/)
      nameservers = values['answers']['nameserver'].value.to_s.split("\,")
      nameservers.each do |nameserver|
        exec_data.push("echo 'nameserver #{nameserver}' >> /etc/resolv.conf")
      end
    else
      nameserver = values['answers']['nameserver'].value.to_s
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
    nameservers = values['answers']['nameserver'].value
    exec_data.push("echo '      nameservers:' >> #{netplan_file}")
    exec_data.push("echo '        addresses: [#{nameservers}]' >> #{netplan_file}")
  end
  exec_data.each do |shell_command|
    exec_command = "multipass exec #{host_name} -- sudo sh -c \"#{shell_command}\""
    if values['nobuild'] == true
      verbose_message(values, exec_command)
    else
      `#{exec_command}`
    end
  end
  values
end

# List Multipass instances

def list_multipass_vms(values)
  if values['name'] != values['empty']
    get_multipass_vm_info(values)
    return
  end
  if (values['search'] != values['empty']) || values['search'].to_s.match(/all/)
    search_string = values['search'].to_s
    command = "multipass list |grep #{search_string} |grep -v ^Name"
  else
    command = 'multipass list |grep -v ^Name'
  end
  message = "Informtion:\tGetting list of local Multipass instances"
  output  = execute_command(values, message, command)
  output.split("\n")
  verbose_message(values, "Image:\t\t\tState:\t\t  IPv4:\t\t   Image")
  vm_list = output.split("\n")
  vm_list.each do |line|
    verbose_message(values, line)
  end
  nil
end

# List available instances

def get_multipass_iso_list(values)
  if (values['search'] != values['empty']) || values['search'].to_s.match(/all/)
    search_string = values['search'].to_s
    command = "multipass find |grep #{search_string} |grep -v ^Image"
  else
    command = 'multipass find |grep -v ^Image'
  end
  message  = "Informtion:\tGetting list of remote Multipass instances"
  output   = execute_command(values, message, command)
  output.split("\n")
end

# Get service name from release name

def get_multipass_service_from_release(values)
  release = values['release'].to_s
  machine = values['host-os-unamem'].to_s
  if values['service'] == values['empty']
    message = "Information:\tDetermining service name"
    command = "multipass find |grep '^#{release}'"
    output  = execute_command(values, message, command)
    output.chomp.gsub(/ LTS/, '')
  elsif release.match(/^[0-9]/)
    values['service'] = "ubuntu_#{release.gsub(/\./, '_')}_#{machine}"
  end
  values
end

# Check if Multipass instance exists

def check_multipass_vm_exists(values)
  exists = false
  if values['name'] == values['empty']
    warning_message(values, 'No client name specified')
    quit(values)
  end
  vm_name = values['name'].to_s
  message = "Information:\tChecking if VM #{vm_name} exists"
  command = "multipass list |grep #{vm_name}"
  output  = execute_command(values, message, command)
  exists = true if output.match(/#{vm_name}/)
  exists
end

# Execute command in Multipass VM

def execute_multipass_command(values)
  command = values['command'].to_s
  exists = check_multipass_vm_exists(values)
  if exists == true
    command = "multipass exec #{values['name']} -- bash -c \"#{command}\""
    output = `#{command}`
    verbose_message(values, output)
  else
    information_message(values, "Multipass instance #{values['name']} does not exist")
  end
  nil
end

# Create Multipass VM

def configure_multipass_vm(values)
  exists  = check_multipass_vm_exists(values)
  vm_name = values['name'].to_s
  values = process_memory_value(values)
  if exists == true
    warning_message(values, "Multipass VM #{vm_name} already exists")
    quit(values)
  else
    message = "Information:\tCreating Multipass VM #{vm_name}"
    if values['method'].to_s.match(/ci/)
      if values['file'] != values['empty']
        command = "cat #{values['file']} |multipass launch --name #{vm_name} --cloud-init -"
      else
        values = configure_ps_client(values)
        values = get_multipass_service_from_release(values)
        values['file'] = "#{values['clientdir']}/user-data"
        no_cpus = values['vcpu'].to_s
        vm_size = values['size'].to_s
        memory  = values['memory'].to_s
        command = "cat #{values['file']} |multipass launch --cpus #{no_cpus} --disk #{vm_size} --mem #{memory} --name #{vm_name} --cloud-init -"
      end
    else
      no_cpus = values['vcpu'].to_s
      vm_size = values['size'].to_s
      memory  = values['memory'].to_s
      command = "multipass launch --cpus #{no_cpus} --disk #{vm_size} --mem #{memory} --name #{vm_name}"
    end
    command = "#{command} #{values['release']}" unless values['release'] == values['empty']
    if values['nobuild'] == false
      execute_command(values, message, command)
    else
      verbose_message(values, 'Build Command:')
      verbose_message(values, command)
    end
  end
  multipass_post_install(values)
  nil
end

# Get Multipass VM info

def get_multipass_vm_info(values)
  exists  = check_multipass_vm_exists(values)
  vm_name = values['name'].to_s
  if exists == true && !values['action'].to_s.match(/list/)
    warning_message(values, "Multipass VM #{vm_name} already exists")
  else
    message = "Information:\Getting information for Multipass VM #{vm_name}"
    command = "multipass info #{vm_name}"
    output  = execute_command(values, message, command)
    lines   = output.split("\n")
    lines.each do |line|
      if values['search'] != values['empty']
        verbose_message(values, line) if line.downcase.match(/#{values['search'].to_s.downcase}/)
      else
        verbose_message(values, line)
      end
    end
  end
  nil
end

# Delete Multipass VM

def delete_multipass_vm(values)
  unconfigure_multipass_vm(values)
  nil
end

def unconfigure_multipass_vm(values)
  exists  = check_multipass_vm_exists(values)
  vm_name = values['name'].to_s
  if exists == true
    message = "Information:\tDeleting Mulipass VM #{vm_name}"
    command = "multipass delete #{vm_name}; multipass purge"
    execute_command(values, message, command)
  else
    warning_message(values, "Multipass VM #{vm_name} does not exist")
  end
  nil
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
    verbose_message("Warning:\tMultipass VM #{vm_name} does not exist")
  end
  nil
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
    verbose_message("Warning:\tMultipass VM #{vm_name} does not exist")
  end
  nil
end
