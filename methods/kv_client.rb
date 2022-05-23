# KVM client functions

# Get KVM list

def list_all_kvm_vms(options)
  options['search'] = "all"
  list_kvm_vms(options)
  return
end

# Get list of running vms

def get_running_kvm_vms(options)
  message = "Information:\tGetting list of running KVM VMs"
  command = "virsh list --all|grep running"
  output  = execute_command(options,message,command)
  vm_list = output.split("\n")
  return vm_list
end

# List running VMs

def list_running_kvm_vms(options)
  vm_list = get_running_kvm_vms(options)
  handle_output(options,"")
  handle_output(options,"Running VMs:")
  handle_output(options,"")
  vm_list.each do |entry|
    (header,options['id'],options['name'],options['status']) = entry.split(/\s+/)
    handle_output(options,"")
  end
  handle_output(options,"")
  return
end

# Check KVM VM is running

def check_kvm_vm_is_running(options)
  list_vms = get_running_kvm_vms(options)
  if list_vms.to_s.match(/#{options['name']}/)
    running = "yes"
  else
    running = "no"
  end
  return running
end

# Get KVM interface Information

def get_kvm_vm_if_info(options)
  if_info = %x[virsh domifaddr #{options['name']} |grep #{options['name']}].chomp
  return if_info
end

# Configure KVM VM

def configure_kvm_vm(options)
  options = configure_kvm_client(options)
end

# Unconfigure KVM VM

def unconfigure_kvm_vm(options)
  exists = check_kvm_vm_exists(options)
  if exists == true
    stop_kvm_vm(options)
    message = "Warning:\tDeleting KVM VM \"#{options['name']}\""
    command = "virsh undefine --domain \"#{options['name']}\""
    execute_command(options,message,command)
  else
    disk_file = options['imagedir'].to_s+"/"+options['name'].to_s+".qcow2"
    if File.exist?(disk_file)
      if options['force'] == true
        message = "Information:\tDeleting VM disk #{disk_file}"
        command = "rm #{disk_file}"
        output  = execute_command(options,message,command)
      else
        handle_output(options,"Warning:\tFile #{disk_file} already exists")
        handle_output(options,"Information:\tUse --force option to delete file")
        quit(options)
      end
    end
  end
  remove_hosts_entry(options)
  return
end

# Get KVM IP address

def get_kvm_vm_ip(options)
  options = get_kvm_vm_mac(options)
  if !options['mac'].to_s.match(/[0-9]|[A-Z]|[a-z]/)
    options['mac'] = ""
  else
    options['ip']  = %x[arp -an |grep "#{options['mac']}" |awk '{print $2}' |tr -d '()'|head -1].chomp
  end
  return options
end

# Get KVM MAC address

def get_kvm_vm_mac(options)
  message = "Information:\tGetting MAC address for #{options['name']}"
  command = "virsh domiflist \"#{options['name']}\" |grep network"
  output  = execute_command(options,message,command)
  options['mac'] = output.chomp.split()[4]
  return options
end

# Boot KVM VM

def boot_kvm_vm(options)
  exists = check_kvm_vm_exists(options)
  if exists == true
    message = "Starting:\tVM "+options['name']
    if options['text'] == true or options['headless'] == true
      command = "virsh start #{options['name']}"
    else
      command = "virsh start #{options['name']}"
    end
    execute_command(options,message,command)
    if options['serial'] == true
      if options['verbose'] == true
        handle_output(options,"Information:\tConnecting to serial port of #{options['name']}")
      end
      begin
        socket = UNIXSocket.open("/tmp/#{options['name']}")
        socket.each_line do |line|
          handle_output(line)
        end
      rescue
        handle_output(options,"Warning:\tCannot open socket")
        quit(options)
      end
    end
  else
    handle_output(options,"Warning:\tVMware KVM VM #{options['name']} does not exist")
  end
  return
end

# Destroy KVM VM

def destroy_kvm_vm(options)
  exists = check_kvm_vm_exists(options)
  if exists == true
    message = "Starting:\tVM "+options['name']
    if options['text'] == true or options['headless'] == true
      command = "virsh destroy --domain #{options['name']}"
    else
      command = "virsh destroy --domain #{options['name']}"
    end
    execute_command(options,message,command)
  else
    string = "Information:\tKVM client #{options['name']} does not exist"
    handle_output(options,string)
  end
  return
end

# Stop KVM VM

def stop_kvm_vm(options)
  exists = check_kvm_vm_exists(options)
  if exists == true
    running = check_kvm_vm_is_running(options)
    if running.match(/yes/)
      message = "Stopping:\tVM "+options['name']
      command = "virsh shutdown #{options['name']}"
      execute_command(options,message,command)
    else
      string = "Information:\tKVM client #{options['name']} is not running"
      handle_output(options,string)
    end
  else
    string = "Information:\tKVM client #{options['name']} does not exist"
    handle_output(options,string)
  end
  return
end

# Import OVA into KVM

def import_kvm_ova(options)
  base_dir = options['imagedir']+"/kvm"
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking KVM image directory")
  end
  check_dir_exists(options,base_dir)
  check_dir_owner(options,base_dir,options['uid'])
  image_dir = options['imagedir']+"/kvm/"+options['name']
  check_dir_exists(options,image_dir)
  check_dir_owner(options,image_dir,options['uid'])
  qcow_file = image_dir+"/"+options['name']+".qcow2"
  if File.exist?(options['file'])
    message  = "Information:\tDetermining name of vmdk disk image"
    command  = "tar -tf \"#{options['file']}\" |grep \"vmdk$\""
    output   = execute_command(options,message,command)
    v_disk   = output.chomp()
    v_disk   = image_dir+"/"+v_disk
    message  = "Information:\tDetermining name of ovf file"
    command  = "tar -tf \"#{options['file']}\" |grep \"ovf$\""
    output   = execute_command(options,message,command)
    ovf_file = output.chomp()
    ovf_file = image_dir+"/"+ovf_file
    if !File.exist?(v_disk)
      message = "Information:\tExtracting image file \"#{options['file']}\""
      command = "cd \"#{image_dir}\" ; tar -xf \"#{options['file']}\""
      execute_command(options,message,command)
    end
    if File.exist?(v_disk)
      check_file_owner(options,v_disk,options['uid'])
      if !File.exist?(qcow_file)
        message = "Information:\tConverting vmdk disk file \"#{v_disk}\" to qcow2 disk file \"#{qcow_file}\""
        command = "qemu-img convert -O qcow2 \"#{v_disk}\" \"#{qcow_file}\""
        execute_command(options,message,command)
      end
      check_file_owner(options,qcow_file,options['uid'])
      check_file_owner(options,ovf_file,options['uid'])
      if File.exist?(ovf_file)
        message = "Information:\tGetting memory information from OVF file \"ovf_file\""
        command = "cat \"#{ovf_file}\" |grep \"Memory RAMSize\" |awk \"{print $2}\" |cut -f2 -d= |cut -f1 -d/"
        output  = execute_command(options,message,command)
        options['memory']  = output.gsub(/"/,"").chomp
      else
        options['memory'] =options['memory']
      end
      if File.exist?(qcow_file)
        message = "Information:\tImporting QCOW file for Packer KVM VM "+options['name']
        if options['text'] == true or options['headless'] == true or options['serial'] == true
          command = "virt-install --import --name #{options['name']} --memory #{options['memory']} --disk \"#{qcow_file}\" --graphics vnc &"
        else
          command = "virt-install --import --name #{options['name']} --memory #{options['memory']} --disk \"#{qcow_file}\" &"
        end
        execute_command(options,message,command)
      end
    else
      handle_output(options,"Warning:\tFailed to extract disk image \"#{v_disk}\" from \"#{options['file']}\"")
    end
  else
    handle_output(options,"Warning:\tImage file \"#{options['file']}\" for KVM VM does not exist")
  end
  return
end

# List KVM images

def list_kvm_images(options)
  img_dir = options["imagedir"].to_s
  message = "Information:\tKVM images:"
  command = "ls #{img_dir}"
  output  = execute_command(options,message,command)
  handle_output(options,output)
  return
end

