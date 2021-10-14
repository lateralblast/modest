# Common routines for Multipass

# Check Multipass is installed

def check_multipass_is_installed(options)
  if !File.exist?("/usr/local/bin/multipass")
    case options['host-os-name'].to_s
    when /Darwin/
      install_brew_pkg(options,"multipass")
    when /Linux/
      install_snap_pkg(options,"multipass")
    end
  end
  return
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
  output  = execute_command(options,message,command)
  vm_list = output.split("\n")
  handle_output(options,"Image:\t\t\tState:\t\t  IPv4:\t\t   Image")
  vm_list = output.split("\n")
  vm_list.each do |line|
    handle_output(options,line)
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
  output   = execute_command(options,message,command)
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
    output  = execute_command(options,message,command)
    output  = output.chomp.gsub(/ LTS/,"")
  else
    if release.match(/^[0-9]/)
      options['service'] = "ubuntu_"+release.gsub(/\./,"_")+"_"+machine
    end
  end
  return options
end

# Check if Multipass instance exists

def check_multipass_vm_exists(options)
  exists = "no"
  if options['name'] == options['empty']
    handle_output(options,"Warning:\tNo client name specified")
    quit(options)
  end
  vm_name = options['name'].to_s
  message = "Information:\tChecking if VM #{vm_name} exists"
  command = "multipass list |grep #{vm_name}"
  output  = execute_command(options,message,command)
  if output.match(/#{vm_name}/)
    exists = "yes"
  end
  return exists
end

# Create Multipass VM

def configure_multipass_vm(options)
  exists  = check_multipass_vm_exists(options)
  vm_name = options['name'].to_s
  options = process_memory_value(options)
  if exists == "yes"
    handle_output(options,"Warning:\tMultipass VM #{vm_name} already exists")
    quit(options)
  else
    message = "Information:\tCreating Multipass VM #{vm_name}"
    if options['method'].to_s.match(/ci/)
      if options['file'] != options['empty']
        command = "multipass launch --name #{vm_name} --cloud-init #{options['file'].to_s}"
      else
        configure_ps_client(options)
        options = get_multipass_service_from_release(options)
        options['file'] = options['clientdir'].to_s+"/user-data"
        command = "multipass launch --name #{vm_name} --cloud-init #{options['file'].to_s}"
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
    execute_command(options,message,command)
  end
  return
end

# Get Multipass VM info

def get_multipass_vm_info(options)
  exists  = check_multipass_vm_exists(options)
  vm_name = options['name'].to_s
  if exists == "yes" && !options['action'].to_s.match(/list/)
    handle_output(options,"Warning:\tMultipass VM #{vm_name} already exists")
  else
    message = "Information:\Getting information for Multipass VM #{vm_name}"
    command = "multipass info #{vm_name}"
    output  = execute_command(options,message,command)
    lines   = output.split("\n")
    lines.each do |line|
      if options['search'] != options['empty']
        if line.downcase.match(/#{options['search'].to_s.downcase}/)
          handle_output(options,line)
        end
      else
        handle_output(options,line)
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
  if exists == "yes"
    message = "Information:\tDeleting Mulipass VM #{vm_name}"
    command = "multipass delete #{vm_name}; multipass purge"
    execute_command(options,message,command)
  else
    handle_output(options,"Warning:\tMultipass VM #{vm_name} does not exist")
  end
  return
end

# Start Multipass instance

def boot_multipass_vm(options)
  exists  = check_multipass_vm_exists(options)
  vm_name = options['name'].to_s
  if exists == "yes"
    message = "Information:\tStarting Mulipass VM #{vm_name}"
    command = "multipass start #{vm_name}"
    execute_command(options,message,command)
  else
    handle_output("Warning:\tMultipass VM #{vm_name} does not exist")
  end
  return
end

# Stop Multipass instance

def stop_multipass_vm(options)
  exists  = check_multipass_vm_exists(options)
  vm_name = options['name'].to_s
  if exists == "yes"
    message = "Information:\tStopping Mulipass VM #{vm_name}"
    command = "multipass start #{vm_name}"
    execute_command(options,message,command)
  else
    handle_output("Warning:\tMultipass VM #{vm_name} does not exist")
  end
  return
end
