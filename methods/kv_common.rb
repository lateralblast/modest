# KVM functions

# Check KVM NAT

def check_kvm_natd(if_name,options)
  return
end

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

# Unconfigure KVM VM

def unconfigure_kvm_vm(options)
  exists = check_kvm_vm_exists(options)
  if exists == "yes"
    stop_kvm_vm(options)
    message = "Warning:\tDeleting KVM VM \"#{options['name']}\""
    command = "virsh undefine --domain \"#{options['name']}\""
    execute_command(options,message,command)
  end
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
  if exists.match(/yes/)
    message          = "Starting:\tVM "+options['name']
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
  if exists.match(/yes/)
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
  if exists.match(/yes/)
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

# Check KVM hostonly network

def check_kvm_hostonly_network(if_name)
  gw_if_name = get_gw_if_name(options)
  check_linux_nat(gw_if_name,if_name)
  return
end

# Import Packer KVM image

def import_packer_kvm_vm(options)
  (exists,images_dir) = check_packer_vm_image_exists(options)
  if exists.match(/no/)
    handle_output(options,"Warning:\tPacker KVM VM QCOW image for #{options['name']} does not exist")
    quit(options)
  end
  qcow_file = images_dir+"/"+options['name']
  if File.exist?(qcow_file)
    message = "Information:\tImporting QCOW file for Packer KVM VM "+options['name']
    if options['text'] == true or options['headless'] == true or options['serial'] == true
      command = "virt-install --import --noreboot --name #{options['name']} --memory #{options['memory']} --disk \"#{qcow_file}\" --graphics none --network bridge=#{options['bridge']}"
    else
      command = "virt-install --import --noreboot --name #{options['name']} --memory #{options['memory']} --disk \"#{qcow_file}\" --graphics vnc --network bridge=#{options['bridge']}"
    end
    execute_command(options,message,command)
  else
    handle_output(options,"Warning:\tQCOW file for Packer KVM VM #{options['name']} does not exist")
    quit(options)
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

# Check KVM is installed

def check_kvm_is_installed(options)
  gw_if_name = get_gw_if_name(options)
  message = "Information:\tChecking KVM is installed"
  command = "ifconfig -a |grep #{gw_if_name}"
  output  = execute_command(options,message,command)
  if not output.match(/#{gw_if_name}/)
    message = "Information:\tInstalling KVM"
    if File.exist?("/etc/redhat-release") or File.exist?("/etc/SuSE-release")
      command = "yum install qemu-kvm qemu-utils libvirt-clients libvirt-daemon-system bridge-utils virt-manager"
    else
      command = "apt-get install qemu-kvm qemu-utils libvirt-clients libvirt-daemon-system bridge-utils virt-manager"
    end
    output = execute_command(options,message,command)
  else
    if_name = get_vm_if_name(options)
    check_linux_nat(options,gw_if_name,if_name)
  end
  message = "Information:\tChecking user is a member of the kvm group"
  command = "groups"
  output  = execute_command(options,message,command)
  if not output.match(/kvm/)
    message = "Information:\tAdding user to kvm group"
    command = "usermod -a -G #{options['kvmgroup']} #{options['user']}"
    output  = execute_command(options,message,command)
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking QEMU configuration directory")
  end
  dir_name  = "/etc/qemu"
  file_name = "/etc/qemu/bridge.conf"
  file_array = []
  file_line  = "allow "+options['bridge'].to_s
  file_array.append(file_line)
  if !File.exist?(file_name)
    file_mode = "w"
    check_dir_exists(options,dir_name)
    check_dir_owner(options,dir_name,options['uid'])
    write_array_to_file(options,file_array,file_name,file_mode)
    check_dir_owner(options,dir_name,"0")
    file_gid  = get_group_gid(options,options['kvmgroup'])
    file_mode = "w"
    check_file_group(options,file_name,file_gid,file_mode)
    check_file_owner(options,file_name,"0")
    restart_linux_service(options,"libvirtd.service")
  else
    if !File.readlines(file_name).grep(/#{file_line}/).any?
      file_mode = "a"
      check_dir_owner(options,dir_name,options['uid'])
      check_file_owner(options,file_name,options['uid'])
      write_array_to_file(options,file_array,file_name,file_mode)
      check_dir_owner(options,dir_name,"0")
      check_file_owner(options,file_name,"0")
      restart_linux_service(options,"libvirtd.service")
    end
  end
  bridge_helper = "/usr/lib/qemu/qemu-bridge-helper"
  if !FileTest.setuid?(bridge_helper)
    message = "Information:\tSetting setuid bit on #{bridge_helper}"
    command = "chmod u+s #{bridge_helper}"
    output  = execute_command(options,message,command)
  end
  return
end

def resize_kvm_image(options)
  file = options['file'].to_s
  size = options['size'].to_s
  size = size.gsub(/g/,"G")
  if !size.match(/G$/)
    size = size+"G"
  end
  if !File.exist?(file)
    handle_output(options,"Warning:\tFile #{file} does not exist")
    quit(options)
  end
  message = "Information:\tResizing disk #{output} to #{size}"
  command = "qemu-img resize #{output} #{size}"
  output  = execute_command(options,message,command)
  return
end


def convert_kvm_image(options)
  if !File.exist?(input_file)
    handle_output(options,"Warning:\tFile #{input_file} does not exist")
    quit(options)
  end
  if options['outputfile'] == options['empty']
    handle_output(options,"Warning:\tNo output file specified")
    if options['name'] == options['empty']
      handle_output(options,"Warning:\tNo client name specified")
      quit(options)
    else
      path_name = Pathname.new(options['inputfile'].to_s).dirname
      file_name = path_name+" "+options['name'].to_s+".disk" 
      if !file_name.match(/^\/[a-z]/)
        file_name = options['libvirtdir']+"/"+file_name
      end
      options['outputfile'] = file_name
      output = options['outputfile']
      handle_output(options,"Information:\tSetting output file to #{output}")
    end
  end
  path_name = Pathname.new(options['outputfile'].to_s).dirname
  if !File.exist?(path_name)
    if options['verbose'] == true
      handle_output(options,"Information:\tChecking KVM output directory")
    end
    check_dir_exists(options,path_name)
    check_dir_owner(options,path_name,options['uid'])
  end
  if !File.exist?(output_file) or options['force'] == true
    message = "Information:\tCreating VM disk #{output_file} from #{input_file}"
    command = "qemu-img convert -f qcow2 #{input_file} #{output_file}"
    output  = execute_command(options,message,command)
  end
  size = options['size'].to_s
  size = size.gsub(/g/,"G")
  if !size.match(/G$/)
    size = size+"G"
  end
  message = "Information:\tResizing disk #{output_file} to #{size}"
  command = "qemu-img resize #{output_file} #{size}"
  output  = execute_command(options,message,command)
  return
end

# Configure a KVM client

def configure_kvm_client(options)
  exists = check_kvm_vm_exists(options)
  if exists == "yes"
    message = "Warning:\t KVM VM #{options['name']} already exists"
    handle_output(options,message)
    quit(options)
  end
  if options['import'] == true
    configure_kvm_import_client(options)
  else
    if options['type'].to_s.match(/packer/)
      configure_packer_client(options)
    end
  end
  return
end

# Create a KVM disk

def create_kvm_disk(options)
  disk_size = options['size'].to_s
  if !options['outputfile'] == options['empty']
    disk_file = options['outputfile']
  else
    disk_file = options['virtdir']+"/"+options['name'].to_s+".qcow2"
  end
  message = "Information:\tCreating KVM disk #{disk_file} of size #{disk_size}"
  command = "sudo qemu-img create -f qcow2 #{disk_file} #{disk_size}"
  execute_command(options,message,command)
  return
end

# Configure a KVM VM via import

def configure_kvm_import_client(options)
  if options['os-type'] == options['empty'] or options['os-variant'] == options['empty'] or options['method'] == options['empty']
    optons = get_install_service_from_file(options)
  end
  check_kvm_is_installed(options)
  if_name = get_vm_if_name(options)
  if options['vmnet'].to_s.match(/hostonly/)
    check_kvm_hostonly_network(if_name)
  end
  if !options['disk1'] == options['none']
    options['disk'] = options['disk1'].to_s+" "+options['disk2'].to_s
  else
    if options['disk'].to_s.match(/ /)
      if !options['disk'].to_s.match(/--disk/)
        temp_disk = options['disk'].to_s.split(/ /)[0]+" --disk "+options['disk'].to_s.split(/ /)[1]
        options['disk'] = temp_disk
      end
    else
      if options['file'].to_s.match(/cloud/)
        options['disk1'] = options['virtdir']+"/"+options['name'].to_s+"-seed.qcow2,device=cdrom"
      else
        options['disk1'] = options['file']+",device=cdrom"
      end
      options['disk2'] = options['virtdir']+"/"+options['name'].to_s+".qcow2,device=disk"
      if !options['type'].to_s.match(/packer/)
        options['disk']  = options['disk2']
      else
        options['disk']  = options['disk1']+" --disk "+options['disk2']
      end
    end
  end
  if options['file'] == options['empty'] && options['pxe'] == false
    handle_output(options,"Warning:\tNo install file specified")
    quit(options)
  end
  if options['import'] == true and options['method'] == "ci"
    if options['cloudfile'] == options['empty']
      if options['disk'].to_s.match(/ /)
        cloud_file = options['disk'].to_s.split(" ")[0]
        if cloud_file.match(/\,/)
          cloud_file = cloud_file.split(",")[0]
        end
        if cloud_file.match(/=/)
          cloud_file = cloud_file.split("=")[1]
        end
        options['cloudfile'] = cloud_file
      else
        handle_output(options,"Warning:\tNo cloud config image specified")
      end
    end
    if options['outputfile'] = options['empty']
      output_file = options['disk'].to_s.split(" ")[2]
      if output_file.match(/,/)
        output_file = output_file.split(",")[0]
      end
      if output_file.match(/=/)
        output_file = output_file.split("=")[1]
      end
      options['outputfile'] = output_file
    end
    if options['inputfile'] != options['empty']
      convert_kvm_image(options)
    else
      if options['file'] != options['empty']
        options['inputfile'] = options['file']
        convert_kvm_image(options)
      end
    end
  else
    create_kvm_disk(options)
  end
  if options['method'] == "ci"
    options = populate_ps_questions(options)
    if options['configfile'] == options['empty']
      config_path = Pathname.new(options['outputfile'].to_s)
      config_path = config_path.dirname.to_s
      config_file = "#{config_path}/#{options['name'].to_s}.cfg"
    end
    if options['networkfile'] == options['empty']
      config_path  = Pathname.new(options['outputfile'].to_s)
      config_path  = config_path.dirname.to_s
      network_file = "#{config_path}/#{options['name'].to_s}_network.cfg"
    end
    if options['verbose'] == true
      handle_output(options,"Information:\tChecking KVM output directory")
    end
    check_dir_exists(options,config_path)
    check_dir_owner(options,config_path,options['uid'])
    case options['os-variant']
    when /ubuntu/
      options = populate_ps_questions(options)
    when /rhel/
      options = populate_ks_questions(options)
    when /vs/
      options = populate_vs_questions(options)
    when /win/
      options = populate_pe_questions(options)
    end
    file = File.open(config_file, 'w')
    file.write("#cloud-config\n")
    file.write("hostname: #{$q_struct['hostname'].value}\n")
    file.write("groups:\n")
    file.write("  - #{$q_struct['admin_username'].value}: #{$q_struct['admin_username'].value}\n")
    file.write("users:\n")
    file.write("  - default\n")
    file.write("  - name: #{$q_struct['admin_username'].value}\n")
    file.write("    gecos: #{$q_struct['admin_fullname'].value}\n")
    file.write("    primary_group: #{$q_struct['admin_username'].value}\n")
    file.write("    groups: users\n")
    file.write("    shell: /bin/bash\n")
    file.write("    passwd: #{$q_struct['admin_crypt'].value}\n")
    file.write("    sudo: ALL=(ALL) NOPASSWD:ALL\n")
    file.write("    lock_passwd: false\n")
    file.write("packages:\n")
    packages = $q_struct['additional_packages'].value.split(" ")
    packages.each do |package|
      file.write("  - #{package}\n")
    end
    file.write("growpart:\n")
    file.write("  mode: auto\n")
    file.write("  devices: ['/']\n")
    if options['reboot'] == true
      file.write("power_state:\n")
      file.write("  mode: reboot\n")
    end
    file.close
    print_contents_of_file(options,"",config_file)
    check_file_owner(options,config_file,options['uid'])
    if $q_struct['static'].value == "true"
      file = File.open(network_file, 'w')
        file.write("version: 2\n")
        file.write("ethernets:\n")
        file.write("  #{$q_struct['interface'].value}:\n")
        file.write("    dhcp4: false\n")
        file.write("    addresses: [ #{$q_struct['ip'].value}/#{options['cidr']} ]\n")
        file.write("    gateway4: #{$q_struct['gateway'].value}\n")
        file.write("    nameservers:\n")
        file.write("      addresses: [ #{$q_struct['nameserver'].value} ]\n")
        file.write("\n")
      file.close
      print_contents_of_file(options,"",network_file)
      check_file_owner(options,network_file,options['uid'])
      command = "cloud-localds --network-config "+network_file+" "+options['cloudfile'].to_s+" "+config_file
    else
      command = "cloud-localds "+options['inputfile'].to_s+" "+config_file
    end
    message = "Information:\tConfiguring image file #{options['inputfile'].to_s}"
    output  = execute_command(options,message,command)
    if !File.exist?(options['cloudfile'].to_s)
      handle_output(options,"Warning:\tFile #{options['cloudfile'].to_s} does not exist")
      quit(options)
    end
  end
  if options['pxe'] == true
    options['boot'] = "network,menu=on"
  end
  command = "virt-install"
  params  = [ "name", "vcpus", "memory", "cdrom", "cpu", "os-type", "os-variant", "host-device", "machine", "mac", "import",
              "extra-args", "connect", "metadata", "initrd-inject", "unattended", "install", "boot", "idmap", "disk", "network",
              "graphics", "controller", "serial", "parallel", "channel", "console", "hostdev", "filesystem", "sound",
              "watchdog", "video", "smartcard", "redirdev", "memballoon", "tpm", "rng", "panic", "memdev", "vsock", "iothreads",
              "seclabel", "cputune", "memtune", "blkiotune", "memorybacking", "features", "clock", "pm", "events", "resource",
              "sysinfo", "qemu-commandline", "launchSecurity", "hvm", "paravirt", "container", "virt-type", "arch", "machine",
              "autostart", "transient", "destroy-on-exit", "wait", "noautoconsole", "noreboot", "print-xml", "dry-run", "check" ]
  params.each do |param|
    if options[param] != options['empty'] && options[param] != "text"
      if options[param] != true && options[param] != false
        command = command + " --"+param+" "+options[param].to_s
      else
        if options[param] != false
          command = command + " --"+param
        end
      end
    else
      if param.match(/graphics/)
        command = command + " --"+param+" "+options[param].to_s
      end
    end
  end
  command = command + " --noreboot"
  message = "Information:\tCreating VM #{options['name'].to_s}"
  output  = execute_command(options,message,command)
  return
end

# List KVM VMs

def list_kvm_vms(options)
  if !options['host-os-name'].match(/Linux/)
    return
  end
  command   = "virsh list --all"
  message   = "Information:\tGetting list of KVM VMs"
  file_list = execute_command(options,message,command)
  file_list = file_list.split("\n")
  if options['search'] == "all" or search_string == "none"
    type_string = "KVM"
  else
    type_string = options['search'].capitalize+" KVM"
  end
  if file_list.length > 0
    if options['output'].to_s.match(/html/)
      handle_output(options,"<h1>Available #{type_string} VMs</h1>")
      handle_output(options,"<table border=\"1\">")
      handle_output(options,"<tr>")
      handle_output(options,"<th>VM</th>")
      handle_output(options,"<th>IP</th>")
      handle_output(options,"<th>MAC</th>")
      handle_output(options,"<th>Status</th>")
      handle_output(options,"</tr>")
    else
      handle_output(options,"")
      handle_output(options,"Available #{type_string} clients:")
      handle_output(options,"")
    end
    file_list.each do |entry|
      if not entry.match(/^---|^ Id/)
        (header,options['id'],options['name'],options['status']) = entry.split(/\s+/)
        options = get_kvm_vm_mac(options)
        options = get_kvm_vm_ip(options)
        options['status'] = options['status'].to_s.gsub(/shut/,"shutdown")
        if options['mac'] == nil
          options['mac'] = ""
        end
        if options['ip'] == nil
          options['ip'] = ""
        end
        if options['search'] == "all" or options['search'] == "none" or entry.match(/#{options['search']}/)
          if options['output'].to_s.match(/html/)
            handle_output(options,"<tr>")
            handle_output(options,"<td>#{options['name'].to_s}</td>")
            handle_output(options,"<td>#{options['ip'].to_s}</td>")
            handle_output(options,"<td>#{options['mac'].to_s}</td>")
            handle_output(options,"<td>#{options['status'].to_s}</td>")
            handle_output(options,"</tr>")
          else
            output = options['name'].to_s+" ip="+options['ip'].to_s+" mac="+options['mac'].to_s+" status="+options['status'].to_s
            handle_output(options,output)
          end
        end
      end
    end
    if options['output'].to_s.match(/html/)
      handle_output(options,"</table>")
    else
      handle_output(options,"")
    end
  end
  return
end
