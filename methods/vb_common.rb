# VirtualBox VM support code

def fix_vbox_mouse_integration(options)
  message = "Information:\tDisabling VirtualBox Mouse Integration Message"
  command = "#{options['vboxmanage']} setextradata global GUI/SuppressMessages remindAboutAutoCapture,confirmInputCapture,remindAboutMouseIntegrationOn,remindAboutWrongColorDepth,confirmGoingFullscreen,remindAboutMouseIntegrationOff,remindAboutMouseIntegration"
  execute_command(options,message,command)
  return
end

# Check VM status

def get_vbox_vm_status(options)
  exists = check_vbox_vm_exists(options)
  if exists == true
    vm_list = get_running_vbox_vms()
    if vm_list.to_s.match(/#{options['name']}/)
      handle_output(options,"Information:\tVirtualBox VM #{options['name']} is Running")
    else
      handle_output(options,"Information:\tVrtualBox VM #{options['name']} is Not Running")
    end
  else
    handle_output(options,"Warning:\tFusion VM #{options['name']} doesn't exist")
  end
  return
end

# Import Packer VirtualBox image

def import_packer_vbox_vm(options)
  (exists,images_dir) = check_packer_vm_image_exists(options)
  if exists == false
    handle_output(options,"Warning:\tPacker VirtualBox VM image for #{options['name']} does not exist")
    return exists
  end
  ovf_file = images_dir+"/"+options['name']+".ovf"
  options['file'] = images_dir+"/"+options['name']+".ova"
  if File.exist?(ovf_file) or File.exist?(options['file'])
    message = "Information:\tImporting OVF file for Packer VirtualBox VM "+options['name']
    if File.exist?(ovf_file)
      command = "#{options['vboxmanage']} import '#{ovf_file}'"
    else
      command = "#{options['vboxmanage']} import '#{options['file']}'"
    end
    execute_command(options,message,command)
  else
    handle_output(options,"Warning:\tOVF file for Packer VirtualBox VM #{options['name']} does not exist")
  end
  return exists
end

# Show Fusion VM config

def show_vbox_vm(options)
  exists = check_vbox_vm_exists(options)
  if exists == true
    output = %x[#{options['vboxmanage']} showvminfo '#{options['name']}']
    show_output_of_command("VirtualBox VM configuration",output)
  else
    handle_output(options,"Warning:\tVirtualBox VM #{options['name']} does not exist")
  end
  return exists
end

def show_vbox_vm_config(options)
  show_vbox_vm(options)
  return
end

# Set VirtualBox VM Parameter

def set_vbox_value(options)
  exists = check_vbox_vm_exists(options)
  if exists == true
    %x[#{options['vboxmanage']} modifyvm '#{options['name']}' --#{options['param']} #{options['value']}]
  else
    handle_output(options,"Warning:\tVirtualBox VM #{options['name']} does not exist")
  end
  return exists
end

# Get VirtualBox VM Parameter

def set_vbox_value(options)
  exists = check_vbox_vm_exists(options)
  if exists == true
    %x[#{options['vboxmanage']} showvminfo '#{options['name']}' | grep '#{options['param']}']
  else
    handle_output(options,"Warning:\tVirtualBox VM #{options['name']} does not exist")
  end
  return exist
end

# Add shared folder to VM

def add_shared_folder_to_vbox_vm(options)
  message = "Information:\tSharing \""+options['share']+"\" to VM "+options['name']+" as "+options['mount']
  command = "#{options['vboxmanage']} sharedfolder add '#{options['name']}' --name '#{options['mount']}' --hostpath '#{options['share']}'"
  execute_command(options,message,command)
  return
end

# Restore VirtualBox VM snapshot

def restore_vbox_vm_snapshot(options)
  if options['clone'].to_s.match(/[a-z,A-Z]/)
    message = "Information:\tRestoring snapshot "+options['clone']+" for "+options['name']
    command = "#{options['vboxmanage']} snapshot '#{options['name']}' restore '#{options['clone']}'"
  else
    message = "Information:\tRestoring latest snapshot for "+options['name']
    command = "#{options['vboxmanage']} snapshot '#{options['name']}'' restorecurrent"
  end
  execute_command(options,message,command)
  return
end

# Delete VirtualBox VM snapshot

def delete_vbox_vm_snapshot(options)
  clone_list = []
  if options['clone'].to_s.match(/\*/) or options['clone'].to_s.match(/all/)
    clone_list = get_vbox_vm_snapshots(options)
    clone_list = clone_list.split("\n")
  else
    clone_list[0] = options['clone']
  end
  clone_list.each do |clone_name|
    fusion_vmx_file = get_fusion_vm_vmx_file(options)
    message = "Information:\tDeleting snapshot "+clone_name+" for Fusion VM "+options['name']
    command = "#{options['vboxmanage']} snapshot '#{options['name']}' delete '#{clone_name}'"
    execute_command(options,message,command)
  end
  return
end

# Get a list of VirtualBox VM snapshots for a client

def get_vbox_vm_snapshots(options)
  message = "Information:\tGetting a list of snapshots for VirtualBox VM "+options['name']
  command = "#{options['vboxmanage']} snapshot '#{options['name']}' list |cut -f2 -d: |cut -f1 -d'(' |sed 's/^ //g' |sed 's/ $//g'"
  output  = execute_command(options,message,command)
  return output
end

# List all VirtualBox VM snapshots

def list_all_vbox_vm_snapshots()
  vm_list = get_available_vbox_vms()
  vm_list.each do |line|
    options['name'] = line.split(/"/)[1]
    list_vbox_vm_snapshots(options)
  end
  return
end

# List VirtualBox VM snapshots

def list_vbox_vm_snapshots(options)
  if options['name'] == "none"
    list_all_vbox_vm_snapshots()
  else
    snapshot_list = get_vbox_vm_snapshots(options)
    handle_output(options,"Snapshots for #{options['name']}:")
    handle_output(snapshot_list)
  end
  return
end

# Snapshot VirtualBox VM

def snapshot_vbox_vm(options)
  exists = check_vbox_vm_exists(options)
  if exists == true
    handle_output(options,"Warning:\tVirtualBox VM #{options['name']} does not exist")
    return exists
  end
  message = "Information:\tCloning VirtualBox VM "+options['name']+" to "+options['clone']
  command = "#{options['vboxmanage']} snapshot '#{options['name']}' take '#{options['clone']}'"
  execute_command(options,message,command)
  return exists
end

# Get a List of VirtualBox VMs

def get_available_vbox_vms(options)
  vm_list = []
  message = "Information:\tGetting list of VirtualBox VMs"
  command = "#{options['vboxmanage']} list vms |grep -v 'inaccessible'"
  output  = execute_command(options,message,command)
  if output.match(/[a-z]/)
    vm_list = output.split("\n")
  end
  return vm_list
end

# Get VirtualBox VM info

def get_vbox_vm_info(options)
  message = "Information:\tGetting value for "+options['search']+" from VirtualBox VM "+options['name']
  if options['search'].to_s.match(/MAC/)
    command = "#{options['vboxmanage']} showvminfo \"#{options['name']}\" |grep MAC |awk '{print $4}' |head -1"
  else
    command = "#{options['vboxmanage']} showvminfo \"#{options['name']}\" |grep \"#{options['search']}\" |cut -f2 -d:"
  end
  output  = execute_command(options,message,command)
  vm_info = output.chomp.gsub(/^\s+/,"")
  return vm_info
end

# Get VirtualBox VM OS

def get_vbox_vm_os(options)
  options['search'] = "^Guest OS"
  vm_os = get_vbox_vm_info(options)
  return vm_os
end

# List all VMs

def list_all_vbox_vms(options)
  options['search'] = "all"
  list_vbox_vms(options)
  return
end

# Get list of running VMs

def get_running_vbox_vms(options)
  vm_list = %x[#{options['vboxmanage']} list runningvms].split("\n")
  return vm_list
end

# List running VMs

def list_running_vbox_vms(options)
  set_vboxm_bin()
  if options['vboxmanage'].to_s.match(/[a-z]/)
    vm_list = get_running_vbox_vms()
    handle_output(options,"")
    handle_output(options,"Running VirtualBox VMs:")
    handle_output ("")
    vm_list.each do |vm_name|
      vm_name = vm_name.split(/"/)[1]
      os_info = %x[#{options['vboxmanage']} showvminfo "#{vm_name}" |grep '^Guest OS' |cut -f2 -d:].chomp.gsub(/^\s+/,"")
      handle_output(options,"#{vm_name}\t#{os_info}")
    end
    handle_output(options,"")
  end
  return
end

# Set VirtualBox ESXi options

def configure_vmware_vbox_vm(options)
  modify_vbox_vm(options['name'],"rtcuseutc","on")
  modify_vbox_vm(options['name'],"vtxvpid","on")
  modify_vbox_vm(options['name'],"vtxux","on")
  modify_vbox_vm(options['name'],"hwvirtex","on")
  setextradata_vbox_vm(options,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion","None")
  setextradata_vbox_vm(options,"VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor","Intel Corporation")
  setextradata_vbox_vm(options,"VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct","440BX Desktop Reference Platform")
  setextradata_vbox_vm(options,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor","VMware, Inc.")
  setextradata_vbox_vm(options,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct","VMware Virtual Platform")
  setextradata_vbox_vm(options,"VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor","Phoenix Technologies LTD")
  setextradata_vbox_vm(options,"VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion","6.0")
  setextradata_vbox_vm(options,"VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor","No Enclosure")
  vbox_vm_uuid = get_vbox_vm_uuid(options)
  vbox_vm_uuid = "VMware-"+vbox_vm_uuid
  setextradata_vbox_vm(options['name'],"VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial",vbox_vm_uuid)
  return
end

# Get VirtualBox UUID

def get_vbox_vm_uuid(options)
  options['search'] = "^UUID"
  install_uuid   = get_vbox_vm_info(options['name'],options['search'])
  return install_uuid
end

# Set VirtualBox ESXi options

def configure_vmware_esxi_vbox_vm(options)
  configure_vmware_esxi_defaults()
  modify_vbox_vm(options['name'],"cpus",options['vcpus'])
  configure_vmware_vbox_vm(options)
  return
end

# Set VirtualBox vCenter option

def configure_vmware_vcenter_vbox_vm(options)
  configure_vmware_vcenter_defaults()
  configure_vmware_vbox_vm(options)
  return
end

# Clone VirtualBox VM

def clone_vbox_vm(options)
  exists = check_vbox_vm_exists(options)
  if exists == true
    handle_output(options,"Warning:\tVirtualBox VM #{options['name']} does not exist")
    return exists
  end
  message = "Information:\tCloning VM "+options['name']+" to "+options['clone']
  command = "#{options['vboxmanage']} clonevm #{options['name']} --name #{options['clone']} --register"
  execute_command(options,message,command)
  if options['ip'].to_s.match(/[0-9]/)
    add_hosts_entry(options['clone'],options['ip'])
  end
  if options['mac'].to_s.match(/[0-9,a-z,A-Z]/)
    change_vbox_vm_mac(options['clone'],options['mac'])
  end
  return exists
end

# Export OVA

def export_vbox_ova(options)
  exists = check_vbox_vm_exists(options)
  if exists == true
    stop_vbox_vm(options)
    if not options['file'].to_s.match(/[0-9,a-z,A-Z]/)
      options['file'] = "/tmp/"+options['name']+".ova"
      handle_output(options,"Warning:\tNo ouput file given")
      handle_output(options,"Information:\tExporting VirtualBox VM #{options['name']} to #{options['file']}")
    end
    if not options['file'].to_s.match(/\.ova$/)
      options['file'] = options['file']+".ova"
    end
    message = "Information:\tExporting VirtualBox VM "+options['name']+" to "+options['file']
    command = "#{options['vboxmanage']} export \"#{options['name']}\" -o \"#{options['file']}\""
    execute_command(options,message,command)
  else
    handle_output(options,"Warning:\tVirtualBox VM #{options['name']} does not exist")
  end
  return exists
end

# Import OVA

def import_vbox_ova(options)
  exists = check_vbox_vm_exists(options)
  if exists == false
    exists = check_vbox_vm_config_exists(options)
  end
  if exists == true
    delete_vbox_vm_config(options)
  end
  if not options['file'].to_s.match(/\//)
    options['file'] = options['isodir']+"/"+options['file']
  end
  if File.exist?(options['file'])
    if options['name'].to_s.match(/[0-9,a-z,A-Z]/)
      options['vmdir']  = get_vbox_vm_dir(options)
      message = "Information:\tImporting VirtualBox VM "+options['name']+" from "+options['file']
      command = "#{options['vboxmanage']} import \"#{options['file']}\" --vsys 0 --vmname \"#{options['name']}\" --unit 20 --disk \"#{options['vmdir']}\""
      execute_command(options,message,command)
    else
      set_vbox_bin(options)
      if options['vboxmanage'].to_s.match(/[a-z]/)
        options['name'] = %x[#{options['vboxmanage']} import -n #{options['file']} |grep "Suggested VM name'].split(/\n/)[-1]
        if not options['name'].to_s.match(/[0-9,a-z,A-Z]/)
          handle_output(options,"Warning:\tCould not determine VM name for Virtual Appliance #{options['file']}")
          quit(options)
        else
          options['name'] = options['name'].split(/Suggested VM name /)[1].chomp
          message = "Information:\tImporting VirtualBox VM "+options['name']+" from "+options['file']
          command = "#{options['vboxmanage']} import \"#{options['file']}\""
          execute_command(options,message,command)
        end
      end
    end
  else
    handle_output(options,"Warning:\tVirtual Appliance #{options['file']} does not exist")
    return exists
  end
  if options['ip'].to_s.match(/[0-9]/)
    add_hosts_entry(options['name'],options['ip'])
  end
  options['socket'] = add_socket_to_vbox_vm(options)
  add_serial_to_vbox_vm(options)
  if options['vmnet'].to_s.match(/bridged/)
    vbox_nic = get_bridged_vbox_nic(options)
    add_bridged_network_to_vbox_vm(options,vbox_nic)
  else
    vbox_nic = check_vbox_hostonly_network(options)
    add_nonbridged_network_to_vbox_vm(options,vbox_nic)
  end
  if not options['mac'].to_s.match(/[0-9,a-z,A-Z]/)
    options['mac'] = get_vbox_vm_mac(options)
  else
    change_vbox_vm_mac(options['name'],options['mac'])
  end
  if options['file'].to_s.match(/VMware/)
    configure_vmware_vcenter_defaults()
    configure_vmware_vbox_vm(options)
  end
  handle_output(options,"Warning:\tVirtual Appliance #{options['file']} imported with VM name #{options['name']} and MAC address #{options['mac']}")
  return exists
end

# List Linux KS VirtualBox VMs

def list_ks_vbox_vms(options)
  options['search'] = "RedHat"
  list_vbox_vms(options)
  return
end

# List Linux Preseed VirtualBox VMs

def list_ps_vbox_vms(options)
  options['search'] = "Ubuntu"
  list_vbox_vms(options)
end

# List Solaris Kickstart VirtualBox VMs

def list_js_vbox_vms(options)
  options['search'] = "OpenSolaris"
  list_vbox_vms(options)
  return
end

# List Solaris AI VirtualBox VMs

def list_ai_vbox_vms(options)
  options['search'] = "Solaris 11"
  list_vbox_vms(options)
  return
end

# List Linux Autoyast VirtualBox VMs

def list_ay_vbox_vms(options)
  options['search'] = "OpenSUSE"
  list_vbox_vms(options)
  return
end

# List vSphere VirtualBox VMs

def list_vs_vbox_vms(options)
  options['search'] = "Linux"
  list_vbox_vms(options)
  return
end

# Get/set #{options['vboxmanage']} path

def set_vbox_bin(options)
  case options['host-os-name']
  when /Darwin|NT/
    if options['host-os-name'].to_s.match(/NT/)
      path = %x[echo $PATH]
      if not path.match(/VirtualBox/)
        handle_output(options,"Warning:\tVirtualBox directory not in PATH")
        options['vm'] = "none"
      end
    end
    options['vboxmanage'] = %x[which VBoxManage].chomp
    if not options['vboxmanage'].to_s.match(/VBoxManage/) or options['vboxmanage'].to_s.match(/no VBoxManage/)
      handle_output(options,"Warning:\tCould not find VBoxManage")
      options['vm'] = "none"
    end
  else
    options['vboxmanage'] = %x[which vboxmanage].chomp
    if !options['vboxmanage'].to_s.match(/vboxmanage/) || options['vboxmanage'].to_s.match(/no vboxmanage/)
      handle_output(options,"Warning:\tCould not find vboxmanage")
      options['vm'] = "none"
    end
  end
  return options
end

# Check VirtualBox VM exists

def check_vbox_vm_exists(options)
  message   = "Information:\tChecking VM "+options['name'].to_s+" exists"
  command   = "#{options['vboxmanage']} list vms |grep -v 'inaccessible'"
  host_list = execute_command(options,message,command)
  if not host_list.match(options['name'])
    if options['verbose'] == true
      handle_output(options,"Warning:\tVirtualBox VM #{options['name']} does not exist")
    end
    exists = false
  else
    exists = true
  end
  return exists
end

# Get VirtualBox bridged network interface

def get_bridged_vbox_nic(options)
  message  = "Information:\tChecking Bridged interfaces"
  command  = "#{options['vboxmanage']} list bridgedifs |grep '^Name' |head -1"
  nic_list = execute_command(options,message,command)
  if not nic_list.match(/[a-z,A-Z]/)
    nic_name = options['nic']
  else
    nic_list=nic_list.split(/\n/)
    nic_list.each do |line|
      line=line.chomp
      if line.match(/#{options['hostonlyip']}/)
        return nic_name
      end
      if line.match(/^Name/)
        nic_name = line.split(/:/)[1].gsub(/\s+/,"")
      end
    end
  end
  return nic_name
end

# Add bridged network to VirtualBox VM

def add_bridged_network_to_vbox_vm(options,nic_name)
  message = "Information:\tAdding bridged network "+nic_name+" to "+options['name']
  command = "#{options['vboxmanage']} modifyvm #{options['name']} --nic1 bridged --bridgeadapter1 #{nic_name}"
  execute_command(options,message,command)
  return
end

# Add non-bridged network to VirtualBox VM

def add_nonbridged_network_to_vbox_vm(options,nic_name)
  message = "Information:\tAdding network "+nic_name+" to "+options['name']
  if nic_name.match(/vboxnet/)
    command = "#{options['vboxmanage']} modifyvm #{options['name']} --hostonlyadapter1 #{nic_name} ; #{options['vboxmanage']} modifyvm #{options['name']} --nic1 hostonly"
  else
    command = "#{options['vboxmanage']} modifyvm #{options['name']} --nic1 #{nic_name}"
  end
  execute_command(options,message,command)
  return
end

# Set boot priority to network

def set_vbox_vm_boot_priority(options)
  message = "Information:\tSetting boot priority for "+options['name']+" to disk then network"
  command = "#{options['vboxmanage']} modifyvm #{options['name']} --boot1 disk --boot2 net"
  execute_command(options,message,command)
  return
end

# Set boot device

def set_vbox_boot_device(options)
  message = "Information:\tSetting boot device for "+options['name']+" to "+options['boot']
  command = "#{options['vboxmanage']} modifyvm #{options['name']} --boot1 #{options['boot']}"
  execute_command(options,message,command)
  return
end

# Get VirtualBox VM OS

def get_vbox_vm_os(options)
  message = "Information:\tGetting VirtualBox VM OS for "+options['name']
  command = "#{options['vboxmanage']} showvminfo #{options['name']} |grep Guest |grep OS |head -1 |cut -f2 -d:"
  vm_os   = execute_command(options,message,command)
  vm_os   = vm_os.gsub(/^\s+/,"")
  vm_os   = vm_os.chomp
  return vm_os
end

# List VirtualBox VMs

def list_vbox_vms(options)
  vm_list = get_available_vbox_vms(options)
  search_string = options['search']
  if vm_list.length > 0
    if search_string == "all"
      type_string = "VirtualBox"
    else
      type_string = search_string+" VirtualBox"
    end
    if options['output'].to_s.match(/html/)
      handle_output(options,"<h1>Available #{type_string} VMs</h1>")
      handle_output(options,"<table border=\"1\">")
      handle_output(options,"<tr>")
      handle_output(options,"<th>VM</th>")
      handle_output(options,"<th>OS</th>")
      handle_output(options,"<th>MAC</th>")
      handle_output(options,"</tr>")
    else
      handle_output(options,"")
      handle_output(options,"Available #{type_string} VMs:")
      handle_output(options,"")
    end
    vm_list.each do |line|
      line = line.chomp
      vm_name = line.split(/\"/)[1]
      options['name'] = vm_name
      vm_mac = get_vbox_vm_mac(options)
      vm_os  = get_vbox_vm_os(options)
      if search_string == "all" or line.match(/#{search_string}/)
        if options['output'].to_s.match(/html/)
          handle_output(options,"<tr>")
          handle_output(options,"<td>#{vm_name}</td>")
          handle_output(options,"<td>#{vm_mac}</td>")
          handle_output(options,"<td>#{vm_os}</td>")
          handle_output(options,"</tr>")
        else
          output = vm_name+" os="+vm_os+" mac="+vm_mac
          handle_output(options,output)
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

# Get VirtualBox VM directory

def get_vbox_vm_dir(options)
  message          = "Information:\tGetting VirtualBox VM directory"
  command          = "#{options['vboxmanage']} list systemproperties |grep 'Default machine folder' |cut -f2 -d':' |sed 's/^[         ]*//g'"
  vbox_vm_base_dir = execute_command(options,message,command)
  vbox_vm_base_dir = vbox_vm_base_dir.chomp
  if not vbox_vm_base_dir.match(/[a-z,A-Z]/)
    vbox_vm_base_dir = options['home']+"/VirtualBox VMs"
  end
  vm_dir = "#{vbox_vm_base_dir}/#{options['name']}"
  return vm_dir
end

# Delete VirtualBox config file

def delete_vbox_vm_config(options)
  options['vmdir'] = get_vbox_vm_dir(options)
  config_file = options['vmdir']+"/"+options['name']+".vbox"
  if File.exist?(config_file)
    message = "Information:\tRemoving Virtualbox configuration file "+config_file
    command = "rm \"#{config_file}\""
    execute_command(options,message,command)
  end
  config_file = options['vmdir']+"/"+options['name']+".vbox-prev"
  if File.exist?(config_file)
    message = "Information:\tRemoving Virtualbox configuration file "+config_file
    command = "rm \"#{config_file}\""
    execute_command(options,message,command)
  end
  return
end

# Check if VirtuakBox config file exists

def check_vbox_vm_config_exists(options)
  exists = false
  vm_dir = get_vbox_vm_dir(options)
  config_file = vm_dir+"/"+options['name']+".vbox"
  prev_file   = vm_dir+"/"+options['name']+".vbox-prev"
  if File.exist?(config_file) or File.exist?(prev_file)
    exists = true
  else
    exists = false
  end
  return exists
end

# Check VM doesn't exist

def check_vbox_vm_doesnt_exist(options)
  message   = "Checking:\tVM "+options['name']+" doesn't exist"
  command   = "#{options['vboxmanage']} list vms"
  host_list = execute_command(options,message,command)
  if host_list.match(options)
    handle_output(options,"Information:\tVirtualBox VM #{options['name']} already exists")
    quit(options)
  end
  return
end

# Routine to register VM

def register_vbox_vm(options)
  message = "Information:\tRegistering VM "+options['name']
  command = "#{options['vboxmanage']} createvm --name \"#{options['name']}\" --ostype \"#{options['os-type']}\" --register"
  execute_command(options,message,command)
  return
end

# Get VirtualBox disk

def get_vbox_controller(options)
  if options['controller']=~/ide/
    options['controller'] = "PIIX4"
  end
  if options['controller']=~/sata/
    options['controller'] = "IntelAHCI"
  end
  if options['controller']=~/scsi/
    options['controller'] = "LSILogic"
  end
  if options['controller']=~/sas/
    options['controller'] = "LSILogicSAS"
  end
  return options['controller']
end

# Add controller to VM

def add_controller_to_vbox_vm(options)
  message = "Information:\tAdding controller to VirtualBox VM"
  command = "#{options['vboxmanage']} storagectl \"#{options['name']}\" --name \"#{defaults['controller']}\" --add \"#{defaults['controller']}\" --controller \"#{options['controller']}\""
  execute_command(options,message,command)
  return
end

# Create Virtual Bpx VM HDD

def create_vbox_hdd(options)
  message = "Information:\tCreating VM hard disk for "+options['name']
  command = "#{options['vboxmanage']} createhd --filename \"#{options['disk']}\" --size \"#{options['size']}\""
  execute_command(options,message,command)
  return
end

def detach_file_from_vbox_vm(options)
  if options['file'].to_s.match(/iso$/) or options['type'].to_s.match(/iso|cdrom/)
    message = "Information:\tDetaching CDROM from "+options['name']
    command = "#{options['vboxmanage']} storageattach \"#{options['name']}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium none"
    execute_command(options,message,command)
  end
  return
end

# Add hard disk to VirtualBox VM

def add_hdd_to_vbox_vm(options)
  message = "Information:\tAttaching storage \"#{options['disk']}\" of type \"#{defaults['controller']}\" to VM "+options['name']
  command = "#{options['vboxmanage']} storageattach \"#{options['name']}\" --storagectl \"#{defaults['controller']}\" --port 0 --device 0 --type hdd --medium \"#{options['disk']}\""
  execute_command(options,message,command)
  return
end

# Add guest additions ISO

def add_tools_to_vbox_vm(options)
  message = "Information:\tAttaching CDROM \""+options['vboxadditions']+"\" to VM "+options['name']
  command = "#{options['vboxmanage']} storagectl \"#{options['name']}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(options,message,command)
  if File.exist?(options['vboxadditions'])
    message = "Information:\tAttaching ISO "+options['vboxadditions']+" to VM "+options['name']
    command = "#{options['vboxmanage']} storageattach \"#{options['name']}\" --storagectl \"cdrom\" --port 1 --device 0 --type dvddrive --medium \"#{options['vboxadditions']}\""
    execute_command(options,message,command)
  end
  return
end

# Add hard disk to VirtualBox VM

def add_cdrom_to_vbox_vm(options)
  message = "Information:\tAttaching CDROM \""+options['file']+"\" to VM "+options['name']
  command = "#{options['vboxmanage']} storagectl \"#{options['name']}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(options,message,command)
  if File.exist?(options['vboxadditions'])
    message = "Information:\tAttaching ISO "+options['vboxadditions']+" to VM "+options['name']
    command = "#{options['vboxmanage']} storageattach \"#{options['name']}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium \"#{options['file']}\""
    execute_command(options,message,command)
  end
  return
end

# Add memory to Virtualbox VM

def add_memory_to_vbox_vm(options)
  message = "Information:\tAdding memory to VM "+options['name']
  command = "#{options['vboxmanage']} modifyvm \"#{options['name']}\" --memory \"#{options['memory']}\""
  execute_command(options,message,command)
  return
end

# Routine to add a socket to a VM

def add_socket_to_vbox_vm(options)
  socket_name = "/tmp/#{options['name']}"
  message     = "Information:\tAdding serial controller to "+options['name']
  command     = "#{options['vboxmanage']} modifyvm \"#{options['name']}\" --uartmode1 server #{socket_name}"
  execute_command(options,message,command)
  return socket_name
end

# Routine to add serial to a VM

def add_serial_to_vbox_vm(options)
  message = "Information:\tAdding serial Port to "+options['name']
  command = "#{options['vboxmanage']} modifyvm \"#{options['name']}\" --uart1 0x3F8 4"
  execute_command(options,message,command)
  return
end

# Get VirtualBox Guest OS name

def get_vbox_guest_os(options)
  case options['method']
  when /pe/
    vm_os = get_pe_vbox_guest_os(options)
  when /ai/
    vm_os = get_ai_vbox_guest_os(options)
  when /js/
    vm_os = get_js_vbox_guest_os(options)
  when /ks/
    vm_os = get_ks_vbox_guest_os(options)
  when /ps/
    vm_os = get_ps_vbox_guest_os(options)
  when /ay/
    vm_os = get_ay_vbox_guest_os(options)
  when /ob/
    vm_os = get_ob_vbox_guest_os(options)
  when /nb/
    vm_os = get_nb_vbox_guest_os(options)
  when /vs/
    vm_os = get_vs_vbox_guest_os(options)
  when /other/
    vm_os = get_other_vbox_guest_os(options)
  end
  return vm_os
end

# Get NT VirtualBox Guest OS name

def get_pe_vbox_guest_os(options)
  vm_os = "Windows2008"
  if options['arch'].to_s.match(/64/)
    vm_os = vm_os+"_64"
  end
  return vm_os
end

# Configure a NT Virtual Box VM

def configure_nt_vbox_vm(options)
  options['os-type'] = get_nt_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Get AI VirtualBox Guest OS name

def get_ai_vbox_guest_os(options)
  vm_os = "Solaris11_64"
  return vm_os
end

# Configure a AI Virtual Box VM

def configure_ai_vbox_vm(options)
  options['os-type'] = get_ai_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Get Jumpstart VirtualBox Guest OS name

def get_js_vbox_guest_os(options)
  vm_os = "OpenSolaris_64"
  return vm_os
end

# Configure a Jumpstart Virtual Box VM

def configure_js_vbox_vm(options)
  options['os-type'] = get_js_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Get Kicktart VirtualBox Guest OS name

def get_ks_vbox_guest_os(options)
  if options['arch'].to_s.match(/i386/)
    vm_os = "RedHat"
  else
    vm_os = "RedHat_64"
  end
  return vm_os
end

# Configure a RedHat or Centos Kickstart VirtualBox VM

def configure_ks_vbox_vm(options)
  options['os-type'] = get_ks_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Get VirtualBox Guest OS name

def get_ps_vbox_guest_os(options)
  if options['arch'].to_s.match(/i386/)
    vm_os = "Ubuntu"
  else
    vm_os = "Ubuntu_64"
  end
  return vm_os
end

# Configure a Preseed Ubuntu VirtualBox VM

def configure_ps_vbox_vm(options)
  options['os-type'] = get_ps_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Get VirtualBox Guest OS name

def get_ay_vbox_guest_os(options)
  if options['arch'].to_s.match(/i386/)
    options['os-type'] = "OpenSUSE"
  else
    options['os-type'] = "OpenSUSE_64"
  end
  return options['os-type']
end

# Configure a AutoYast SuSE VirtualBox VM

def configure_ay_vbox_vm(options)
  options['os-type'] = get_ay_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Get OpenBSD VirtualBox Guest OS name

def get_ob_vbox_guest_os(options)
  options['os-type'] = "Linux_64"
  return options['os-type']
end

# Configure an OpenBSD VM

def configure_ob_vbox_vm(options)
  options['os-type'] = get_ob_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Get NetBSD VirtualBox Guest OS name

def get_nb_vbox_guest_os(options)
  if options['arch'].to_s.match(/i386/)
    options['os-type'] = "NetBSD"
  else
    options['os-type'] = "NetBSD_64"
  end
  return options['os-type']
end

# Configure a NetBSD VM

def configure_nb_vbox_vm(options)
  options['os-type'] = get_nb_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Get vSphere VirtualBox Guest OS name

def get_vs_vbox_guest_os(options)
  options['os-type'] = "Linux_64"
  return options['os-type']
end

# Configure a ESX VirtualBox VM

def configure_vs_vbox_vm(options)
  options['os-type'] = get_vs_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Get Other VirtualBox Guest OS name

def get_other_vbox_guest_os(options)
  options['os-type'] = "Other"
  return options['os-type']
end

# Configure a other VirtualBox VM

def configure_other_vbox_vm(options)
  options['os-type'] = get_other_vbox_guest_os(options)
  configure_vbox_vm(options)
  return
end

# Modify a VirtualBox VM parameter

def modify_vbox_vm(options)
  message = "Information:\tSetting VirtualBox Parameter "+options['param']+" to "+options['value']
  command = "#{options['vboxmanage']} modifyvm #{options['name']} --#{options['param']} #{options['value']}"
  execute_command(options,message,command)
  return
end

def setextradata_vbox_vm(options)
  message = "Information:\tSetting VirtualBox Extradata "+options['param']+" to "+options['value']
  command = "#{options['vboxmanage']} setextradata #{options['name']} \"#{options['param']}\" \"#{options['value']}\""
  execute_command(options,message,command)
  return
end

# Change VirtualBox VM Cores

def change_vbox_vm_cpu(options)
  message = "Information:\tSetting VirtualBox VM "+options['name']+" CPUs to "+options['vcpus']
  command = "#{options['vboxmanage']} modifyvm #{options['name']} --cpus #{options['vcpus']}"
  execute_command(options,message,command)
  return
end

# Change VirtualBox VM UTC

def change_vbox_vm_utc(options)
  message = "Information:\tSetting VirtualBox VM "+options['name']+" RTC to "+options['utc']
  command = "#{options['vboxmanage']} modifyvm #{options['name']} --rtcuseutc #{options['utc']}"
  execute_command(options,message,command)
  return
end

# Change VirtualBox VM MAC address

def change_vbox_vm_mac(options)
  message = "Information:\tSetting VirtualBox VM "+options['name']+" MAC address to "+options['mac']
  if options['mac'].to_s.match(/:/)
    options['mac'] = options['mac'].gsub(/:/,"")
  end
  command = "#{options['vboxmanage']} modifyvm #{options['name']} --macaddress1 #{options['mac']}"
  execute_command(options,message,command)
  return
end

# Boot VirtualBox VM

def boot_vbox_vm(options)
  exists = check_vbox_vm_exists(options)
  if exists == false
    handle_output(options,"Warning:\tVirtualBox VM #{options['name']} does not exist")
    return exists
  end
  if options['boot'].to_s.match(/cdrom|net|dvd|disk/)
    options['boot'] = options['boot'].gsub(/cdrom/,"dvd")
    set_vbox_boot_device(options['name'],options['boot'])
  end
  message = "Starting:\tVM "+options['name']
  if options['text'] == true or options['serial'] == true or options['headless'] == true
    command = "#{options['vboxmanage']} startvm #{options['name']} --type headless ; sleep 1"
    handle_output(options,"")
    handle_output(options,"Information:\tBooting and connecting to virtual serial port of #{options['name']}")
    handle_output(options,"")
    handle_output(options,"To disconnect from this session use CTRL-Q")
    handle_output(options,"")
    handle_output(options,"If you wish to re-connect to the serial console of this machine,")
    handle_output(options,"run the following command")
    handle_output(options,"")
    handle_output(options,"socat UNIX-CONNECT:/tmp/#{options['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
    handle_output(options,"")
    handle_output(options,"Executing:\t #{command}")
    handle_output(options,"")
    set_vbox_bin(options)
    if options['vboxmanage'].to_s.match(/[a-z]/)
      %x[#{options['vboxmanage']} startvm #{options['name']} --type headless ; sleep 1]
    end
  else
    command = "#{options['vboxmanage']} startvm #{options['name']}"
    execute_command(options,message,command)
  end
  if options['serial'] == true
    system("socat UNIX-CONNECT:/tmp/#{options['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
  else
    handle_output(options,"")
    handle_output(options,"If you wish to connect to the serial console of this machine,")
    handle_output(options,"run the following command")
    handle_output(options,"")
    handle_output(options,"socat UNIX-CONNECT:/tmp/#{options['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
    handle_output(options,"")
    handle_output(options,"To disconnect from this session use CTRL-Q")
    handle_output(options,"")
    handle_output(options,"")
  end
  return exists
end

# Stop VirtualBox VM

def stop_vbox_vm(options)
  exists = check_vbox_vm_exists(options)
  if exists == true
    message = "Stopping:\tVM "+options['name']
    command = "#{options['vboxmanage']} controlvm #{options['name']} poweroff"
    execute_command(options,message,command)
  end
  return
end

# Get VirtualBox VM MAC address

def get_vbox_vm_mac(options)
  options['search'] = "MAC"
  options['mac']    = get_vbox_vm_info(options)
  options['mac']    = options['mac'].chomp.gsub(/\,/,"")
  return options['mac']
end

# Get VirtualBox hostonly network interface

def get_vbox_hostonly_interface(options)
  if_name = ""
  if options['vboxmanage'].match(/[a-z]/)
    message = "Information:\tFinding VirtualBox hostonly network name"
    command = "#{options['vboxmanage']} list hostonlyifs |grep '^Name' |head -1"
    if_name = execute_command(options,message,command)
    if_name = if_name.split(":")[1]
    if if_name
      if_name = if_name.gsub(/^\s+/,"")
      if_name = if_name.gsub(/'/,"")
    else
      if_name = "none"
    end
  end
  return if_name
end

# Check VirtualBox hostonly network

def check_vbox_hostonly_network(options)
  if_name  = options['vmnet']
  if_check = get_vbox_hostonly_interface(options)
  if options['host-os-name'].to_s.match(/NT/)
    string = "VirtualBox Host-Only Ethernet Adapter"
  else
    string = "vboxnet"
  end
  if !if_check.match(/#{string}/)
    message = "information:\tPlumbing VirtualBox hostonly network"
    command = "#{options['vboxmanage']} hostonlyif create"
    execute_command(options,message,command)
    if options['vmnetdhcp'] == false
      message = "Information:\tDisabling DHCP on "+if_name
      command = "#{options['vboxmanage']} dhcpserver remove --ifname \"#{if_name}\""
      execute_command(options,message,command)
    end
  end
  message = "Information:\tChecking VirtualBox hostonly network "+if_name+" has address "+options['hostonlyip']
  command = "#{options['vboxmanage']} list hostonlyifs |grep 'IPAddress' |awk '{print $2}' |head -1"
  host_ip = execute_command(options,message,command)
  host_ip = host_ip.chomp
  if not host_ip.match(/#{options['hostonlyip']}/)
    message = "Information:\tConfiguring VirtualBox hostonly network "+if_name+" with IP "+options['hostonlyip']
    command = "#{options['vboxmanage']} hostonlyif ipconfig \"#{if_name}\" --ip #{options['hostonlyip']} --netmask #{options['netmask']}"
    execute_command(options,message,command)
  end
  message = "Information:\tChecking VirtualBox DHCP Server is Disabled"
  command = "#{options['vboxmanage']} list dhcpservers"
  output  = execute_command(options,message,command)
  if output.match(/Enabled/)
    message = "Information:\tDisabling VirtualBox DHCP Server\t"
    command = "#{options['vboxmanage']} dhcpserver remove --ifname \"#{if_name}\""
  end
  gw_if_name = get_gw_if_name(options)
  case options['host-os-name']
  when /Darwin/
    if options['host-os-release'].split(".")[0].to_i < 14
      check_osx_nat(options,gw_if_name,if_name)
    else
      check_osx_pfctl(options,gw_if_name,if_name)
    end
  when /Linux/
    check_linux_nat(gw_if_name,if_name)
  when /Solaris/
    check_solaris_nat(if_name)
  end
  return if_name
end

# Check VirtualBox is installed

def check_vbox_is_installed(options)
  if options['host-os-name'].to_s.match(/Darwin/)
    app_dir = "/Applications/VirtualBox.app"
  else
    app_dir = "/usr/bin"
  end
  if File.directory?(app_dir)
    options = set_vbox_bin(options)
    if options['vboxmanage'].to_s.match(/[a-z]/)
      fix_vbox_mouse_integration(options)
    end
  end
  return options
end

# Add CPU to Virtualbox VM

def add_cpu_to_vbox_vm(options)
  if options['vcpus'].to_i > 1
    message = "Information:\tSetting number of CPUs to "+options['vcpus']
    command = "#{options['vboxmanage']} modifyvm \"#{options['name']}\" --cpus #{options['vcpus']}"
    execute_command(options,message,command)
  end
  return
end

# Configure VNC

def configure_vbox_vnc(options)
  message = "Information:\tEnabling VNC for VirtualBox"
  command = "#{options['vboxmanage']} setproperty vrdeextpack VNC"
  execute_command(options,message,command)
  message = "Information:\tEnabling VNC for VirtualBox VM "+options['name']
  command = "#{options['vboxmanage']} modifyvm '#{options['name']}' --vrdeproperty VNCPassword=#{options['vncpassword']}"
  execute_command(options,message,command)
  return
end

# Configure a VirtualBox VM

def configure_vbox_vm(options)
  options = check_vbox_is_installed(options)
  if options['vmnetwork'].to_s.match(/hostonly/)
    if_name = get_bridged_vbox_nic(options)
    options['vmnet'] = check_vbox_hostonly_network(options)
  end
  options['vmdir']      = get_box_vm_dir(options)
  options['disk']       = options['vmdir']+"/"+options['name']+".vdi"
  options['socket']     = "/tmp/#{options['name']}"
  options['controller'] = get_vbox_controller(options)
  check_vbox_vm_doesnt_exist(options)
  register_vbox_vm(options)
  add_controller_to_vbox_vm(options)
  if !options['file'].to_s.match(/ova$/)
    create_vbox_hdd(options['name'],options['disk'],options['size'])
    add_hdd_to_vbox_vm(options['name'],options['disk'])
  end
  add_memory_to_vbox_vm(options)
  options['socket'] = add_socket_to_vbox_vm(options)
  add_serial_to_vbox_vm(options)
  if options['vmnet'].to_s.match(/bridged/)
    options['vmnic'] = get_bridged_vbox_nic(options)
    add_bridged_network_to_vbox_vm(options)
  else
    add_nonbridged_network_to_vbox_vm(options)
  end
  set_vbox_vm_boot_priority(options)
  if options['file'].to_s.match(/iso$/)
    add_cdrom_to_vbox_vm(options)
  end
  add_tools_to_vbox_vm(options)
  if options['mac'].to_s.match(/[0-9]/)
    change_vbox_vm_mac(options)
  else
    options['mac'] = get_vbox_vm_mac(options)
  end
  if options['os-type'].to_s.match(/ESXi/)
    configure_vmware_esxi_vbox_vm(options)
  end
  add_cpu_to_vbox_vm(options)
  if options['vnc'] == true
    configure_vbox_vnc(options)
  end
  handle_output(options,"Information:\tCreated VirtualBox VM #{options['name']} with MAC address #{options['mac']}")
  return options
end

# Check VirtualBox NATd

def check_vbox_natd(options,if_name)
  options = check_vbox_is_installed(options)
  if options['vmnetwork'].to_s.match(/hostonly/)
    check_vbox_hostonly_network(options)
  end
  return options
end

# Unconfigure a Virtual Box VM

def unconfigure_vbox_vm(options)
  options = check_vbox_is_installed(options)
  exists  = check_vbox_vm_exists(options)
  if exists == false
    exists = check_vbox_vm_config_exists(options)
    if exists == true
      delete_vbox_vm_config(options)
    else
      handle_output(options,"Warning:\tVirtualBox VM #{options['name']} does not exist")
      return exists
    end
  end
  stop_vbox_vm(options)
  sleep(5)
  message = "Information:\tDeleting VirtualBox VM "+options['name']
  command = "#{options['vboxmanage']} unregistervm #{options['name']} --delete"
  execute_command(options,message,command)
  delete_vbox_vm_config(options)
  return exists
end
