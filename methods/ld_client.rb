# Guest Domain support code

# Check Guest Domain is running

def check_gdom_is_running(options)
  message = "Information:\tChecking Guest Domain "+options['name']+" is running"
  command = "ldm list-bindings #{options['name']} |grep '^#{options['name']}'"
  output  = execute_command(options,message,command)
  if not output.match(/active/)
    handle_output(options,"Warning:\tGuest Domain #{options['name']} is not running")
    quit(options)
  end
  return
end

# Check Guest Domain isn't running

def check_gdom_isnt_running(options)
  message = "Information:\tChecking Guest Domain "+options['name']+" is running"
  command = "ldm list-bindings #{options['name']} |grep '^#{options['name']}'"
  output  = execute_command(options,message,command)
  if output.match(/active/)
    handle_output(options,"Warning:\tGuest Domain #{options['name']} is already running")
    quit(options)
  end
  return
end

# Get Guest domain MAC

def get_gdom_mac(options)
  message    = "Information:\tGetting guest domain "+options['name']+" MAC address"
  command    = "ldm list-bindings #{options['name']} |grep '#{options['vmnic']}' |awk '{print $5}'"
  output     = execute_command(options,message,command)
  options['mac'] = output.chomp
  return options['mac']
end

# List available LDoms

def list_gdoms(options)
  if options['osuname'].match(/SunOS/)
    if options['osrelease'].match(/10|11/)
      if options['osuname'].match(/sun4v/)
        ldom_type    = "Guest Domain"
        ldom_command = "ldm list |grep -v NAME |grep -v primary |awk '{print $1}'"
        list_doms(ldom_type,ldom_command)
      else
        if options['verbose'] == true
          handle_output(options,"") 
          handle_output(options,"Warning:\tThis service is only available on the Sun4v platform")
          handle_output(options,"") 
        end
      end
    else
      if options['verbose'] == true
        handle_output(options,"") 
        handle_output(options,"Warning:\tThis service is only available on Solaris 10 or later")
        handle_output(options,"") 
      end
    end
  else
    if options['verbose'] == true
      handle_output(options,"") 
      handle_output(options,"Warning:\tThis service is only available on Solaris")
      handle_output(options,"") 
    end
  end
  return
end

def list_gdom_vms(options)
  list_gdoms(options)
  return
end

def list_all_gdom_vms(options)
  list_gdoms(options)
  return
end

# Create Guest domain disk

def create_gdom_disk(options)
  client_disk = $q_struct['gdom_disk'].value
  disk_size   = $q_struct['gdom_size'].value
  disk_size   = disk_size.downcase
  vds_disk    = options['name']+"_vdisk0"
  if not client_disk.match(/\/dev/)
    if not File.exist?(client_disk)
      message = "Information:\tCreating guest domain disk "+client_disk+" for client "+options['name']
      command = "mkfile -n #{disk_size} #{client_disk}"
      output = execute_command(options,message,command)
    end
  end
  message = "Information:\tChecking Virtual Disk Server device doesn't already exist"
  command = "ldm list-services |grep 'primary-vds0' |grep '#{vds_disk}'"
  output = execute_command(options,message,command)
  if not output.match(/#{options['name']}/)
    message = "Information:\tAdding disk device to Virtual Disk Server"
    command = "ldm add-vdsdev #{client_disk} #{vds_disk}@primary-vds0"
    output = execute_command(options,message,command)
  end
  return
end

# Check Guest domain doesn't exist

def check_gdom_doesnt_exist(options)
  message = "Information:\tChecking guest domain "+options['name']+" doesn't exist"
  command = "ldm list |grep #{options['name']}"
  output  = execute_command(options,message,command)
  if output.match(/#{options['name']}/)
    handle_output(options,"Warning:\tGuest domain #{options['name']} already exists")
    quit(options)
  end
  return
end

# Check Guest domain doesn't exist

def check_gdom_exists(options)
  message = "Information:\tChecking guest domain "+options['name']+" exist"
  command = "ldm list |grep #{options['name']}"
  output  = execute_command(options,message,command)
  if not output.match(/#{options['name']}/)
    handle_output(options,"Warning:\tGuest domain #{options['name']} doesn't exist")
    quit(options)
  end
  return
end

# Start Guest domain

def start_gdom(options)
  message = "Information:\tStarting guest domain "+options['name']
  command = "ldm start-domain #{options['name']}"
  execute_command(options,message,command)
  return
end

# Stop Guest domain

def stop_gdom(options)
  message = "Information:\tStopping guest domain "+options['name']
  command = "ldm stop-domain #{options['name']}"
  execute_command(options,message,command)
  return
end

# Bind Guest domain

def bind_gdom(options)
  message = "Information:\tBinding guest domain "+options['name']
  command = "ldm bind-domain #{options['name']}"
  execute_command(options,message,command)
  return
end

# Unbind Guest domain

def unbind_gdom(options)
  message = "Information:\tUnbinding guest domain "+options['name']
  command = "ldm unbind-domain #{options['name']}"
  execute_command(options,message,command)
  return
end

# Remove Guest domain

def remove_gdom(options)
  message = "Information:\tRemoving guest domain "+options['name']
  command = "ldm remove-domain #{options['name']}"
  execute_command(options,message,command)
  return
end

# Remove Guest domain disk

def remove_gdom_disk(options)
  vds_disk = options['name']+"_vdisk0"
  message = "Information:\tRemoving disk "+vds_disk+" from Virtual Disk Server"
  command = "ldm remove-vdisk #{vds_disk} #{options['name']}"
  execute_command(options,message,command)
  return
end

# Delete Guest domain disk

def delete_gdom_disk(options)
  gdom_dir    = $ldom_base_dir+"/"+options['name']
  client_disk = gdom_dir+"/vdisk0"
  message = "Information:\tRemoving disk "+client_disk
  command = "rm #{client_disk}"
  execute_command(options,message,command)
  return
end

# Delete Guest domain directory

def delete_gdom_dir(options)
  gdom_dir    = $ldom_base_dir+"/"+options['name']
  destroy_zfs_fs(gdom_dir)
  return
end

# Create Guest domain

def create_gdom(options)
  memory   = $q_struct['gdom_memory'].value
  vcpu     = $q_struct['gdom_vcpu'].value
  vds_disk = options['name']+"_vdisk0"
  message = "Information:\tCreating guest domain "+options['name']
  command = "ldm add-domain #{options['name']}"
  execute_command(options,message,command)
  message = "Information:\tAdding vCPUs to Guest domain "+options['name']
  command = "ldm add-vcpu #{vcpu} #{options['name']}"
  execute_command(options,message,command)
  message = "Information:\tAdding memory to Guest domain "+options['name']
  command = "ldm add-memory #{memory} #{options['name']}"
  execute_command(options,message,command)
  message = "Information:\tAdding network to Guest domain "+options['name']
  command = "ldm add-vnet #{options['vmnic']} primary-vsw0 #{options['name']}"
  execute_command(options,message,command)
  message = "Information:\tAdding isk to Guest domain "+options['name']
  command = "ldm add-vdisk vdisk0 #{vds_disk}@primary-vds0 #{options['name']}"
  execute_command(options,message,command)
  return
end

# Configure Guest domain

def configure_gdom(options)
  options['service'] = ""
  check_dpool()
  check_gdom_doesnt_exist(options)
  if not File.directory?($ldom_base_dir)
    check_fs_exists(options,$ldom_base_dir)
    message = "Information:\tSetting mount point for "+$ldom_base_dir
    command = "zfs set mountpoint=#{$ldom_base_dir} #{options['zpoolname']}#{$ldom_base_dir}"
    execute_command(options,message,command)
  end
  gdom_dir = $ldom_base_dir+"/"+options['name']
  if not File.directory?(gdom_dir)
    check_fs_exists(options,gdom_dir)
    message = "Information:\tSetting mount point for "+gdom_dir
    command = "zfs set mountpoint=#{gdom_dir} #{options['zpoolname']}#{gdom_dir}"
    execute_command(options,message,command)
  end
  populate_gdom_questions(options)
  process_questions(options)
  create_gdom_disk(options)
  create_gdom(options)
  bind_gdom(options)
  return
end

def configure_gdom_client(options)
  options['ip'] = single_install_ip(options)
  configure_gdom(options)
  return
end

def configure_ldom_client(options)
  options['ip'] = single_install_ip(options)
  configure_gdom(options)
  return
end

# Unconfigure Guest domain

def unconfigure_gdom(options)
  check_gdom_exists(options)
  stop_gdom(options)
  unbind_gdom(options)
  remove_gdom_disk(options)
  remove_gdom(options)
  delete_gdom_disk(options)
  delete_gdom_dir(options)
  return
end

# Boot Guest Domain

def boot_gdom_vm(options)
  check_gdom_exists(options) 
  check_gdom_isnt_running(options)
  start_gdom(options)
  return
end

# Stop Guest Domain

def stop_gdom_vm(options)
  check_gdom_exists(options) 
  check_gdom_is_running(options)
  stop_gdom(options)
  return
end

# Get Guest Domain Console Port

def get_gdom_console_port(options)
  message  = "Information:\tDetermining Virtual Console Port for Guest Domain "+options['name']
  command  = "ldm list-bindings #{options['name']} |grep vcc |awk '{print $3}'"
  vcc_port = execute_command(options,message,command)
  return vcc_port
end


# Connect to Guest Domain Console

def connect_to_gdom_console(options)
  check_cdom_vntsd()
  check_gdom_exists(options)
  check_gdom_is_running(options)
  vcc_port = get_gdom_console_port(options)
  vcc_port = vcc_port.chomp
  handle_output(options,"") 
  handle_output(options,"To connect to console of Guest Domain #{options['name']} type the following command: ")
  handle_output(options,"") 
  handle_output(options,"telnet localhost #{vcc_port}")
  handle_output(options,"") 
  return
end

# Set Guest Domain value

def set_gdom_value(options)
  check_gdom_exists(options)
  message = "Information:\tSetting "+options['param']+" for Guest Domain "+options['name']+" to "+options['value']
  if options['param'].to_s.match(/autoboot|auto-boot/)
    options['param'] = "auto-boot\?"
  end
  command = "ldm set-variable #{options['param']}=#{options['value']} #{options['name']}"
  execute_command(options,message,command)
  return
end

