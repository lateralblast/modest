# frozen_string_literal: true

# Guest Domain support code

# Check Guest Domain is running

def check_gdom_is_running(values)
  message = "Information:\tChecking Guest Domain #{values['name']} is running"
  command = "ldm list-bindings #{values['name']} |grep '^#{values['name']}'"
  output  = execute_command(values, message, command)
  unless output.match(/active/)
    warning_message(values, "Guest Domain #{values['name']} is not running")
    quit(values)
  end
  nil
end

# Check Guest Domain is not running

def check_gdom_isnt_running(values)
  message = "Information:\tChecking Guest Domain #{values['name']} is running"
  command = "ldm list-bindings #{values['name']} |grep '^#{values['name']}'"
  output  = execute_command(values, message, command)
  if output.match(/active/)
    warning_message(values, "Guest Domain #{values['name']} is already running")
    quit(values)
  end
  nil
end

# Get Guest domain MAC

def get_gdom_mac(values)
  message = "Information:\tGetting guest domain #{values['name']} MAC address"
  command = "ldm list-bindings #{values['name']} |grep '#{values['vmnic']}' |awk '{print $5}'"
  output  = execute_command(values, message, command)
  values['mac'] = output.chomp
  values['mac']
end

# List available LDoms

def list_gdoms(values)
  if values['host-os-unamea'].match(/SunOS/)
    if values['host-os-unamer'].match(/10|11/)
      if values['host-os-unamea'].match(/sun4v/)
        ldom_type    = 'Guest Domain'
        ldom_command = "ldm list |grep -v NAME |grep -v primary |awk '{print $1}'"
        list_doms(ldom_type, ldom_command)
      elsif values['verbose'] == true
        verbose_message(values, '')
        warning_message(values, 'This service is only available on the Sun4v platform')
        verbose_message(values, '')
      end
    elsif values['verbose'] == true
      verbose_message(values, '')
      warning_message(values, 'This service is only available on Solaris 10 or later')
      verbose_message(values, '')
    end
  elsif values['verbose'] == true
    verbose_message(values, '')
    warning_message(values, 'This service is only available on Solaris')
    verbose_message(values, '')
  end
  nil
end

def list_gdom_vms(values)
  list_gdoms(values)
  nil
end

def list_all_gdom_vms(values)
  list_gdoms(values)
  nil
end

# Create Guest domain disk

def create_gdom_disk(values)
  client_disk = values['answers']['gdom_disk'].value
  disk_size   = values['answers']['gdom_size'].value
  disk_size   = disk_size.downcase
  vds_disk    = "#{values['name']}_vdisk0"
  if !client_disk.match(%r{/dev}) && !File.exist?(client_disk)
    message = "Information:\tCreating guest domain disk #{client_disk} for client #{values['name']}"
    command = "mkfile -n #{disk_size} #{client_disk}"
    execute_command(values, message, command)
  end
  message = "Information:\tChecking Virtual Disk Server device does not already exist"
  command = "ldm list-services |grep 'primary-vds0' |grep '#{vds_disk}'"
  output = execute_command(values, message, command)
  unless output.match(/#{values['name']}/)
    message = "Information:\tAdding disk device to Virtual Disk Server"
    command = "ldm add-vdsdev #{client_disk} #{vds_disk}@primary-vds0"
    execute_command(values, message, command)
  end
  nil
end

# Check Guest domain does not exist

def check_gdom_doesnt_exist(values)
  message = "Information:\tChecking guest domain #{values['name']} does not exist"
  command = "ldm list |grep #{values['name']}"
  output  = execute_command(values, message, command)
  if output.match(/#{values['name']}/)
    warning_message(values, "Guest domain #{values['name']} already exists")
    quit(values)
  end
  nil
end

# Check Guest domain does not exist

def check_gdom_exists(values)
  message = "Information:\tChecking guest domain #{values['name']} exist"
  command = "ldm list |grep #{values['name']}"
  output  = execute_command(values, message, command)
  unless output.match(/#{values['name']}/)
    warning_message(values, "Guest domain #{values['name']} does not exist")
    quit(values)
  end
  nil
end

# Start Guest domain

def start_gdom(values)
  message = "Information:\tStarting guest domain #{values['name']}"
  command = "ldm start-domain #{values['name']}"
  execute_command(values, message, command)
  nil
end

# Stop Guest domain

def stop_gdom(values)
  message = "Information:\tStopping guest domain #{values['name']}"
  command = "ldm stop-domain #{values['name']}"
  execute_command(values, message, command)
  nil
end

# Bind Guest domain

def bind_gdom(values)
  message = "Information:\tBinding guest domain #{values['name']}"
  command = "ldm bind-domain #{values['name']}"
  execute_command(values, message, command)
  nil
end

# Unbind Guest domain

def unbind_gdom(values)
  message = "Information:\tUnbinding guest domain #{values['name']}"
  command = "ldm unbind-domain #{values['name']}"
  execute_command(values, message, command)
  nil
end

# Remove Guest domain

def remove_gdom(values)
  message = "Information:\tRemoving guest domain #{values['name']}"
  command = "ldm remove-domain #{values['name']}"
  execute_command(values, message, command)
  nil
end

# Remove Guest domain disk

def remove_gdom_disk(values)
  vds_disk = "#{values['name']}_vdisk0"
  message = "Information:\tRemoving disk #{vds_disk} from Virtual Disk Server"
  command = "ldm remove-vdisk #{vds_disk} #{values['name']}"
  execute_command(values, message, command)
  nil
end

# Delete Guest domain disk

def delete_gdom_disk(values)
  gdom_dir    = "#{$ldom_base_dir}/#{values['name']}"
  client_disk = "#{gdom_dir}/vdisk0"
  message = "Information:\tRemoving disk #{client_disk}"
  command = "rm #{client_disk}"
  execute_command(values, message, command)
  nil
end

# Delete Guest domain directory

def delete_gdom_dir(values)
  gdom_dir = "#{$ldom_base_dir}/#{values['name']}"
  destroy_zfs_fs(gdom_dir)
  nil
end

# Create Guest domain

def create_gdom(values)
  memory   = values['answers']['gdom_memory'].value
  vcpu     = values['answers']['gdom_vcpu'].value
  vds_disk = "#{values['name']}_vdisk0"
  message  = "Information:\tCreating guest domain #{values['name']}"
  command  = "ldm add-domain #{values['name']}"
  execute_command(values, message, command)
  message = "Information:\tAdding vCPUs to Guest domain #{values['name']}"
  command = "ldm add-vcpu #{vcpu} #{values['name']}"
  execute_command(values, message, command)
  message = "Information:\tAdding memory to Guest domain #{values['name']}"
  command = "ldm add-memory #{memory} #{values['name']}"
  execute_command(values, message, command)
  message = "Information:\tAdding network to Guest domain #{values['name']}"
  command = "ldm add-vnet #{values['vmnic']} primary-vsw0 #{values['name']}"
  execute_command(values, message, command)
  message = "Information:\tAdding isk to Guest domain #{values['name']}"
  command = "ldm add-vdisk vdisk0 #{vds_disk}@primary-vds0 #{values['name']}"
  execute_command(values, message, command)
  nil
end

# Configure Guest domain

def configure_gdom(values)
  values['service'] = ''
  check_dpool(values)
  check_gdom_doesnt_exist(values)
  unless File.directory?($ldom_base_dir)
    check_fs_exists(values, $ldom_base_dir)
    message = "Information:\tSetting mount point for #{$ldom_base_dir}"
    command = "zfs set mountpoint=#{$ldom_base_dir} #{values['zpoolname']}#{$ldom_base_dir}"
    execute_command(values, message, command)
  end
  gdom_dir = "#{$ldom_base_dir}/#{values['name']}"
  unless File.directory?(gdom_dir)
    check_fs_exists(values, gdom_dir)
    message = "Information:\tSetting mount point for #{gdom_dir}"
    command = "zfs set mountpoint=#{gdom_dir} #{values['zpoolname']}#{gdom_dir}"
    execute_command(values, message, command)
  end
  values = populate_gdom_questions(values)
  process_questions(values)
  create_gdom_disk(values)
  create_gdom(values)
  bind_gdom(values)
  nil
end

def configure_gdom_client(values)
  values['ip'] = single_install_ip(values)
  configure_gdom(values)
  nil
end

def configure_ldom_client(values)
  values['ip'] = single_install_ip(values)
  configure_gdom(values)
  nil
end

# Unconfigure Guest domain

def unconfigure_gdom(values)
  check_gdom_exists(values)
  stop_gdom(values)
  unbind_gdom(values)
  remove_gdom_disk(values)
  remove_gdom(values)
  delete_gdom_disk(values)
  delete_gdom_dir(values)
  nil
end

# Boot Guest Domain

def boot_gdom_vm(values)
  check_gdom_exists(values)
  check_gdom_isnt_running(values)
  start_gdom(values)
  nil
end

# Stop Guest Domain

def stop_gdom_vm(values)
  check_gdom_exists(values)
  check_gdom_is_running(values)
  stop_gdom(values)
  nil
end

# Get Guest Domain Console Port

def get_gdom_console_port(values)
  message  = "Information:\tDetermining Virtual Console Port for Guest Domain #{values['name']}"
  command  = "ldm list-bindings #{values['name']} |grep vcc |awk '{print $3}'"
  execute_command(values, message, command)
end

# Connect to Guest Domain Console

def connect_to_gdom_console(values)
  check_cdom_vntsd(values)
  check_gdom_exists(values)
  check_gdom_is_running(values)
  vcc_port = get_gdom_console_port(values)
  vcc_port = vcc_port.chomp
  verbose_message(values, '')
  verbose_message(values, "To connect to console of Guest Domain #{values['name']} type the following command: ")
  verbose_message(values, '')
  verbose_message(values, "telnet localhost #{vcc_port}")
  verbose_message(values, '')
  nil
end

# Set Guest Domain value

def set_gdom_value(values)
  check_gdom_exists(values)
  message = "Information:\tSetting #{values['param']} for Guest Domain #{values['name']} to #{values['value']}"
  values['param'] = "auto-boot\?" if values['param'].to_s.match(/autoboot|auto-boot/)
  command = "ldm set-variable #{values['param']}=#{values['value']} #{values['name']}"
  execute_command(values, message, command)
  nil
end
