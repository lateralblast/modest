# Common routines for Multipass

# Check Multipass is installed

def check_multipass_is_installed(options)
  if !File.exist?("/usr/local/bin/multipass")
    case options['os-name'].to_s
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
  if options['search'] != options['empty'] or options['search'].to_s.match(/all/)
    search_string = options['search'].to_s
    command = "multipass list |grep #{search_string} |grep -v ^Name"
  else
    command = "multipass list |grep -v ^Name"
  end
  message = "Informtion:\tGetting list of Multipass instances"
  output  = execute_command(options,message,command)
  vm_list = output.split("\n")
  handle_output(options,"Name:\t\t\tState:\t\t  IPv4:\t\t   Image")
  vm_list.each do |line|
    handle_output(options,line)
  end
  return
end

# Check if Multipass instance exists

def check_multipass_vm_exists(options)
  exists = "no"
  if option['name'] == options['empty']
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
  if exists == "yes"
    handle_output(options,"Warning:\tMultipass VM #{vm_name} already exists")
  else
    message = "Information:\tCreating Multipass VM #{vm_name}"
    if options['method'].to_s.match(/ci/)
      command = "multipass launch --name #{vm_name} --cloud-init #{option['file'].to_s}"
    else
      command = "multipass launch --name #{vm_name}"
    end
    execute_command(options,message,command)
  end
  return
end

# Delete Multipass VM

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
