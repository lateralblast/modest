# KVM client functions

# Get KVM list

def list_all_kvm_vms(values)
  values['search'] = "all"
  list_kvm_vms(values)
  return
end

# Get list of running vms

def get_running_kvm_vms(values)
  message = "Information:\tGetting list of running KVM VMs"
  command = "virsh list --all|grep running"
  output  = execute_command(values, message, command)
  vm_list = output.split("\n")
  return vm_list
end

# List running VMs

def list_running_kvm_vms(values)
  vm_list = get_running_kvm_vms(values)
  verbose_message(values, "")
  verbose_message(values, "Running VMs:")
  verbose_message(values, "")
  vm_list.each do |entry|
    (header, values['id'], values['name'], values['status']) = entry.split(/\s+/)
    verbose_message(values, "")
  end
  verbose_message(values, "")
  return
end

# Check KVM VM is running

def check_kvm_vm_is_running(values)
  list_vms = get_running_kvm_vms(values)
  if list_vms.to_s.match(/#{values['name']}/)
    running = "yes"
  else
    running = "no"
  end
  return running
end

# Get KVM interface Information

def get_kvm_vm_if_info(values)
  if_info = %x[virsh domifaddr #{values['name']} |grep #{values['name']}].chomp
  return if_info
end

# Configure KVM VM

def configure_kvm_vm(values)
  values = configure_kvm_client(values)
end

# Unconfigure KVM VM

def unconfigure_kvm_vm(values)
  exists = check_kvm_vm_exists(values)
  if exists == true
    stop_kvm_vm(values)
    message = "Warning:\tDeleting KVM VM \"#{values['name']}\""
    command = "virsh undefine --domain \"#{values['name']}\""
    execute_command(values, message, command)
  else
    disk_file = values['imagedir'].to_s+"/"+values['name'].to_s+".qcow2"
    if File.exist?(disk_file)
      if values['force'] == true
        message = "Information:\tDeleting VM disk #{disk_file}"
        command = "rm #{disk_file}"
        output  = execute_command(values, message, command)
      else
        warning_message(values, "File #{disk_file} already exists")
        information_message(values, "Use --force option to delete file")
        quit(values)
      end
    end
  end
  remove_hosts_entry(values)
  return
end

# Get KVM IP address

def get_kvm_vm_ip(values)
  values = get_kvm_vm_mac(values)
  if !values['mac'].to_s.match(/[0-9]|[A-Z]|[a-z]/)
    values['mac'] = ""
  else
    values['ip']  = %x[arp -an |grep "#{values['mac']}" |awk '{print $2}' |tr -d '()'|head -1].chomp
  end
  return values
end

# Get KVM MAC address

def get_kvm_vm_mac(values)
  message = "Information:\tGetting MAC address for #{values['name']}"
  command = "virsh domiflist \"#{values['name']}\" |grep network"
  output  = execute_command(values, message, command)
  values['mac'] = output.chomp.split()[4]
  return values
end

# Boot KVM VM

def boot_kvm_vm(values)
  exists = check_kvm_vm_exists(values)
  if exists == true
    message = "Starting:\tVM "+values['name']
    if values['text'] == true or values['headless'] == true
      command = "virsh start #{values['name']}"
    else
      command = "virsh start #{values['name']}"
    end
    execute_command(values, message, command)
    if values['serial'] == true
      if values['verbose'] == true
        information_message(values, "Connecting to serial port of #{values['name']}")
      end
      begin
        socket = UNIXSocket.open("/tmp/#{values['name']}")
        socket.each_line do |line|
          verbose_message(line)
        end
      rescue
        warning_message(values, "Cannot open socket")
        quit(values)
      end
    end
  else
    warning_message(values, "VMware KVM VM #{values['name']} does not exist")
  end
  return
end

# Destroy KVM VM

def destroy_kvm_vm(values)
  exists = check_kvm_vm_exists(values)
  if exists == true
    message = "Starting:\tVM "+values['name']
    if values['text'] == true or values['headless'] == true
      command = "virsh destroy --domain #{values['name']}"
    else
      command = "virsh destroy --domain #{values['name']}"
    end
    execute_command(values, message, command)
  else
    string = "Information:\tKVM client #{values['name']} does not exist"
    verbose_message(values, string)
  end
  return
end

# Stop KVM VM

def stop_kvm_vm(values)
  exists = check_kvm_vm_exists(values)
  if exists == true
    running = check_kvm_vm_is_running(values)
    if running.match(/yes/)
      message = "Stopping:\tVM "+values['name']
      command = "virsh shutdown #{values['name']}"
      execute_command(values, message, command)
    else
      string = "Information:\tKVM client #{values['name']} is not running"
      verbose_message(values, string)
    end
  else
    string = "Information:\tKVM client #{values['name']} does not exist"
    verbose_message(values, string)
  end
  return
end

# Import OVA into KVM

def import_kvm_ova(values)
  base_dir = values['imagedir']+"/kvm"
  if values['verbose'] == true
    information_message(values, "Checking KVM image directory")
  end
  check_dir_exists(values, base_dir)
  check_dir_owner(values, base_dir, values['uid'])
  image_dir = values['imagedir']+"/kvm/"+values['name']
  check_dir_exists(values, image_dir)
  check_dir_owner(values, image_dir, values['uid'])
  qcow_file = image_dir+"/"+values['name']+".qcow2"
  if File.exist?(values['file'])
    message  = "Information:\tDetermining name of vmdk disk image"
    command  = "tar -tf \"#{values['file']}\" |grep \"vmdk$\""
    output   = execute_command(values, message, command)
    v_disk   = output.chomp()
    v_disk   = image_dir+"/"+v_disk
    message  = "Information:\tDetermining name of ovf file"
    command  = "tar -tf \"#{values['file']}\" |grep \"ovf$\""
    output   = execute_command(values, message, command)
    ovf_file = output.chomp()
    ovf_file = image_dir+"/"+ovf_file
    if !File.exist?(v_disk)
      message = "Information:\tExtracting image file \"#{values['file']}\""
      command = "cd \"#{image_dir}\" ; tar -xf \"#{values['file']}\""
      execute_command(values, message, command)
    end
    if File.exist?(v_disk)
      check_file_owner(values, v_disk, values['uid'])
      if !File.exist?(qcow_file)
        message = "Information:\tConverting vmdk disk file \"#{v_disk}\" to qcow2 disk file \"#{qcow_file}\""
        command = "qemu-img convert -O qcow2 \"#{v_disk}\" \"#{qcow_file}\""
        execute_command(values, message, command)
      end
      check_file_owner(values, qcow_file, values['uid'])
      check_file_owner(values, ovf_file, values['uid'])
      if File.exist?(ovf_file)
        message = "Information:\tGetting memory information from OVF file \"ovf_file\""
        command = "cat \"#{ovf_file}\" |grep \"Memory RAMSize\" |awk \"{print $2}\" |cut -f2 -d= |cut -f1 -d/"
        output  = execute_command(values, message, command)
        values['memory']  = output.gsub(/"/, "").chomp
      else
        values['memory'] =values['memory']
      end
      if File.exist?(qcow_file)
        message = "Information:\tImporting QCOW file for Packer KVM VM "+values['name']
        if values['text'] == true or values['headless'] == true or values['serial'] == true
          command = "virt-install --import --name #{values['name']} --memory #{values['memory']} --disk \"#{qcow_file}\" --graphics vnc &"
        else
          command = "virt-install --import --name #{values['name']} --memory #{values['memory']} --disk \"#{qcow_file}\" &"
        end
        execute_command(values, message, command)
      end
    else
      warning_message(values, "Failed to extract disk image \"#{v_disk}\" from \"#{values['file']}\"")
    end
  else
    warning_message(values, "Image file \"#{values['file']}\" for KVM VM does not exist")
  end
  return
end

# List KVM images

def list_kvm_images(values)
  img_dir = values["imagedir"].to_s
  message = "Information:\tKVM images:"
  verbose_message(values, message)
  command = "find #{img_dir} -name \"*.img\""
  output  = execute_command(values, message, command)
  verbose_message(values, output)
  return
end
