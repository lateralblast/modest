# VirtualBox VM support code

def fix_vbox_mouse_integration(values)
  message = "Information:\tDisabling VirtualBox Mouse Integration Message"
  command = "#{values['vboxmanage']} setextradata global GUI/SuppressMessages remindAboutAutoCapture,confirmInputCapture,remindAboutMouseIntegrationOn,remindAboutWrongColorDepth,confirmGoingFullscreen,remindAboutMouseIntegrationOff,remindAboutMouseIntegration"
  execute_command(values, message, command)
  return
end

# Check VM status

def get_vbox_vm_status(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    vm_list = get_running_vbox_vms()
    if vm_list.to_s.match(/#{values['name']}/)
      verbose_output(values, "Information:\tVirtualBox VM #{values['name']} is Running")
    else
      verbose_output(values, "Information:\tVrtualBox VM #{values['name']} is Not Running")
    end
  else
    verbose_output(values, "Warning:\tFusion VM #{values['name']} doesn't exist")
  end
  return
end

# Import Packer VirtualBox image

def import_packer_vbox_vm(values)
  (exists, images_dir) = check_packer_vm_image_exists(values)
  if exists == false
    verbose_output(values, "Warning:\tPacker VirtualBox VM image for #{values['name']} does not exist")
    return exists
  end
  ovf_file = images_dir+"/"+values['name']+".ovf"
  values['file'] = images_dir+"/"+values['name']+".ova"
  if File.exist?(ovf_file) or File.exist?(values['file'])
    message = "Information:\tImporting OVF file for Packer VirtualBox VM "+values['name']
    if File.exist?(ovf_file)
      command = "#{values['vboxmanage']} import '#{ovf_file}'"
    else
      command = "#{values['vboxmanage']} import '#{values['file']}'"
    end
    execute_command(values, message, command)
  else
    verbose_output(values, "Warning:\tOVF file for Packer VirtualBox VM #{values['name']} does not exist")
  end
  return exists
end

# Show Fusion VM config

def show_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    output = %x[#{values['vboxmanage']} showvminfo '#{values['name']}']
    show_output_of_command("VirtualBox VM configuration", output)
  else
    verbose_output(values, "Warning:\tVirtualBox VM #{values['name']} does not exist")
  end
  return exists
end

def show_vbox_vm_config(values)
  show_vbox_vm(values)
  return
end

# Set VirtualBox VM Parameter

def set_vbox_value(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    %x[#{values['vboxmanage']} modifyvm '#{values['name']}' --#{values['param']} #{values['value']}]
  else
    verbose_output(values, "Warning:\tVirtualBox VM #{values['name']} does not exist")
  end
  return exists
end

# Get VirtualBox VM Parameter

def set_vbox_value(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    %x[#{values['vboxmanage']} showvminfo '#{values['name']}' | grep '#{values['param']}']
  else
    verbose_output(values, "Warning:\tVirtualBox VM #{values['name']} does not exist")
  end
  return exist
end

# Add shared folder to VM

def add_shared_folder_to_vbox_vm(values)
  message = "Information:\tSharing \""+values['share']+"\" to VM "+values['name']+" as "+values['mount']
  command = "#{values['vboxmanage']} sharedfolder add '#{values['name']}' --name '#{values['mount']}' --hostpath '#{values['share']}'"
  execute_command(values, message, command)
  return
end

# Restore VirtualBox VM snapshot

def restore_vbox_vm_snapshot(values)
  if values['clone'].to_s.match(/[a-z,A-Z]/)
    message = "Information:\tRestoring snapshot "+values['clone']+" for "+values['name']
    command = "#{values['vboxmanage']} snapshot '#{values['name']}' restore '#{values['clone']}'"
  else
    message = "Information:\tRestoring latest snapshot for "+values['name']
    command = "#{values['vboxmanage']} snapshot '#{values['name']}'' restorecurrent"
  end
  execute_command(values, message, command)
  return
end

# Delete VirtualBox VM snapshot

def delete_vbox_vm_snapshot(values)
  clone_list = []
  if values['clone'].to_s.match(/\*/) or values['clone'].to_s.match(/all/)
    clone_list = get_vbox_vm_snapshots(values)
    clone_list = clone_list.split("\n")
  else
    clone_list[0] = values['clone']
  end
  clone_list.each do |clone_name|
    fusion_vmx_file = get_fusion_vm_vmx_file(values)
    message = "Information:\tDeleting snapshot "+clone_name+" for Fusion VM "+values['name']
    command = "#{values['vboxmanage']} snapshot '#{values['name']}' delete '#{clone_name}'"
    execute_command(values, message, command)
  end
  return
end

# Get a list of VirtualBox VM snapshots for a client

def get_vbox_vm_snapshots(values)
  message = "Information:\tGetting a list of snapshots for VirtualBox VM "+values['name']
  command = "#{values['vboxmanage']} snapshot '#{values['name']}' list |cut -f2 -d: |cut -f1 -d'(' |sed 's/^ //g' |sed 's/ $//g'"
  output  = execute_command(values, message, command)
  return output
end

# List all VirtualBox VM snapshots

def list_all_vbox_vm_snapshots()
  vm_list = get_available_vbox_vms()
  vm_list.each do |line|
    values['name'] = line.split(/"/)[1]
    list_vbox_vm_snapshots(values)
  end
  return
end

# List VirtualBox VM snapshots

def list_vbox_vm_snapshots(values)
  if values['name'] == "none"
    list_all_vbox_vm_snapshots()
  else
    snapshot_list = get_vbox_vm_snapshots(values)
    verbose_output(values, "Snapshots for #{values['name']}:")
    verbose_output(snapshot_list)
  end
  return
end

# Snapshot VirtualBox VM

def snapshot_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    verbose_output(values, "Warning:\tVirtualBox VM #{values['name']} does not exist")
    return exists
  end
  message = "Information:\tCloning VirtualBox VM "+values['name']+" to "+values['clone']
  command = "#{values['vboxmanage']} snapshot '#{values['name']}' take '#{values['clone']}'"
  execute_command(values, message, command)
  return exists
end

# Get a List of VirtualBox VMs

def get_available_vbox_vms(values)
  vm_list = []
  message = "Information:\tGetting list of VirtualBox VMs"
  command = "#{values['vboxmanage']} list vms |grep -v 'inaccessible'"
  output  = execute_command(values, message, command)
  if output.match(/[a-z]/)
    vm_list = output.split("\n")
  end
  return vm_list
end

# Get VirtualBox VM info

def get_vbox_vm_info(values)
  message = "Information:\tGetting value for "+values['search']+" from VirtualBox VM "+values['name']
  if values['search'].to_s.match(/MAC/)
    command = "#{values['vboxmanage']} showvminfo \"#{values['name']}\" |grep MAC |awk '{print $4}' |head -1"
  else
    command = "#{values['vboxmanage']} showvminfo \"#{values['name']}\" |grep \"#{values['search']}\" |cut -f2 -d:"
  end
  output  = execute_command(values, message, command)
  vm_info = output.chomp.gsub(/^\s+/, "")
  return vm_info
end

# Get VirtualBox VM OS

def get_vbox_vm_os(values)
  values['search'] = "^Guest OS"
  vm_os = get_vbox_vm_info(values)
  return vm_os
end

# List all VMs

def list_all_vbox_vms(values)
  values['search'] = "all"
  list_vbox_vms(values)
  return
end

# Get list of running VMs

def get_running_vbox_vms(values)
  vm_list = %x[#{values['vboxmanage']} list runningvms].split("\n")
  return vm_list
end

# List running VMs

def list_running_vbox_vms(values)
  set_vboxm_bin()
  if values['vboxmanage'].to_s.match(/[a-z]/)
    vm_list = get_running_vbox_vms()
    verbose_output(values, "")
    verbose_output(values, "Running VirtualBox VMs:")
    verbose_output ("")
    vm_list.each do |vm_name|
      vm_name = vm_name.split(/"/)[1]
      os_info = %x[#{values['vboxmanage']} showvminfo "#{vm_name}" |grep '^Guest OS' |cut -f2 -d:].chomp.gsub(/^\s+/, "")
      verbose_output(values, "#{vm_name}\t#{os_info}")
    end
    verbose_output(values, "")
  end
  return
end

# Set VirtualBox ESXi values

def configure_vmware_vbox_vm(values)
  modify_vbox_vm(values['name'], "rtcuseutc", "on")
  modify_vbox_vm(values['name'], "vtxvpid", "on")
  modify_vbox_vm(values['name'], "vtxux", "on")
  modify_vbox_vm(values['name'], "hwvirtex", "on")
  setextradata_vbox_vm(values, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion", "None")
  setextradata_vbox_vm(values, "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor", "Intel Corporation")
  setextradata_vbox_vm(values, "VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct", "440BX Desktop Reference Platform")
  setextradata_vbox_vm(values, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor", "VMware, Inc.")
  setextradata_vbox_vm(values, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct", "VMware Virtual Platform")
  setextradata_vbox_vm(values, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor", "Phoenix Technologies LTD")
  setextradata_vbox_vm(values, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion", "6.0")
  setextradata_vbox_vm(values, "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor", "No Enclosure")
  vbox_vm_uuid = get_vbox_vm_uuid(values)
  vbox_vm_uuid = "VMware-"+vbox_vm_uuid
  setextradata_vbox_vm(values['name'], "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial", vbox_vm_uuid)
  return
end

# Get VirtualBox UUID

def get_vbox_vm_uuid(values)
  values['search'] = "^UUID"
  install_uuid   = get_vbox_vm_info(values['name'], values['search'])
  return install_uuid
end

# Set VirtualBox ESXi values

def configure_vmware_esxi_vbox_vm(values)
  configure_vmware_esxi_defaults()
  modify_vbox_vm(values['name'], "cpus", values['vcpus'])
  configure_vmware_vbox_vm(values)
  return
end

# Set VirtualBox vCenter option

def configure_vmware_vcenter_vbox_vm(values)
  configure_vmware_vcenter_defaults()
  configure_vmware_vbox_vm(values)
  return
end

# Clone VirtualBox VM

def clone_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    verbose_output(values, "Warning:\tVirtualBox VM #{values['name']} does not exist")
    return exists
  end
  message = "Information:\tCloning VM "+values['name']+" to "+values['clone']
  command = "#{values['vboxmanage']} clonevm #{values['name']} --name #{values['clone']} --register"
  execute_command(values, message, command)
  if values['ip'].to_s.match(/[0-9]/)
    add_hosts_entry(values['clone'], values['ip'])
  end
  if values['mac'].to_s.match(/[0-9,a-z,A-Z]/)
    change_vbox_vm_mac(values['clone'], values['mac'])
  end
  return exists
end

# Export OVA

def export_vbox_ova(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    stop_vbox_vm(values)
    if not values['file'].to_s.match(/[0-9,a-z,A-Z]/)
      values['file'] = "/tmp/"+values['name']+".ova"
      verbose_output(values, "Warning:\tNo ouput file given")
      verbose_output(values, "Information:\tExporting VirtualBox VM #{values['name']} to #{values['file']}")
    end
    if not values['file'].to_s.match(/\.ova$/)
      values['file'] = values['file']+".ova"
    end
    message = "Information:\tExporting VirtualBox VM "+values['name']+" to "+values['file']
    command = "#{values['vboxmanage']} export \"#{values['name']}\" -o \"#{values['file']}\""
    execute_command(values, message, command)
  else
    verbose_output(values, "Warning:\tVirtualBox VM #{values['name']} does not exist")
  end
  return exists
end

# Import OVA

def import_vbox_ova(values)
  exists = check_vbox_vm_exists(values)
  if exists == false
    exists = check_vbox_vm_config_exists(values)
  end
  if exists == true
    delete_vbox_vm_config(values)
  end
  if not values['file'].to_s.match(/\//)
    values['file'] = values['isodir']+"/"+values['file']
  end
  if File.exist?(values['file'])
    if values['name'].to_s.match(/[0-9,a-z,A-Z]/)
      values['vmdir']  = get_vbox_vm_dir(values)
      message = "Information:\tImporting VirtualBox VM "+values['name']+" from "+values['file']
      command = "#{values['vboxmanage']} import \"#{values['file']}\" --vsys 0 --vmname \"#{values['name']}\" --unit 20 --disk \"#{values['vmdir']}\""
      execute_command(values, message, command)
    else
      set_vbox_bin(values)
      if values['vboxmanage'].to_s.match(/[a-z]/)
        values['name'] = %x[#{values['vboxmanage']} import -n #{values['file']} |grep "Suggested VM name'].split(/\n/)[-1]
        if not values['name'].to_s.match(/[0-9,a-z,A-Z]/)
          verbose_output(values, "Warning:\tCould not determine VM name for Virtual Appliance #{values['file']}")
          quit(values)
        else
          values['name'] = values['name'].split(/Suggested VM name /)[1].chomp
          message = "Information:\tImporting VirtualBox VM "+values['name']+" from "+values['file']
          command = "#{values['vboxmanage']} import \"#{values['file']}\""
          execute_command(values, message, command)
        end
      end
    end
  else
    verbose_output(values, "Warning:\tVirtual Appliance #{values['file']} does not exist")
    return exists
  end
  if values['ip'].to_s.match(/[0-9]/)
    add_hosts_entry(values['name'], values['ip'])
  end
  values['socket'] = add_socket_to_vbox_vm(values)
  add_serial_to_vbox_vm(values)
  if values['vmnet'].to_s.match(/bridged/)
    vbox_nic = get_bridged_vbox_nic(values)
    add_bridged_network_to_vbox_vm(values, vbox_nic)
  else
    vbox_nic = check_vbox_hostonly_network(values)
    add_nonbridged_network_to_vbox_vm(values, vbox_nic)
  end
  if not values['mac'].to_s.match(/[0-9,a-z,A-Z]/)
    values['mac'] = get_vbox_vm_mac(values)
  else
    change_vbox_vm_mac(values['name'], values['mac'])
  end
  if values['file'].to_s.match(/VMware/)
    configure_vmware_vcenter_defaults()
    configure_vmware_vbox_vm(values)
  end
  verbose_output(values, "Warning:\tVirtual Appliance #{values['file']} imported with VM name #{values['name']} and MAC address #{values['mac']}")
  return exists
end

# List Linux KS VirtualBox VMs

def list_ks_vbox_vms(values)
  values['search'] = "RedHat"
  list_vbox_vms(values)
  return
end

# List Linux Preseed VirtualBox VMs

def list_ps_vbox_vms(values)
  values['search'] = "Ubuntu"
  list_vbox_vms(values)
end

# List Solaris Kickstart VirtualBox VMs

def list_js_vbox_vms(values)
  values['search'] = "OpenSolaris"
  list_vbox_vms(values)
  return
end

# List Solaris AI VirtualBox VMs

def list_ai_vbox_vms(values)
  values['search'] = "Solaris 11"
  list_vbox_vms(values)
  return
end

# List Linux Autoyast VirtualBox VMs

def list_ay_vbox_vms(values)
  values['search'] = "OpenSUSE"
  list_vbox_vms(values)
  return
end

# List vSphere VirtualBox VMs

def list_vs_vbox_vms(values)
  values['search'] = "Linux"
  list_vbox_vms(values)
  return
end

# Get/set #{values['vboxmanage']} path

def set_vbox_bin(values)
  case values['host-os-uname']
  when /Darwin|NT/
    if values['host-os-uname'].to_s.match(/NT/)
      path = %x[echo $PATH]
      if not path.match(/VirtualBox/)
        verbose_output(values, "Warning:\tVirtualBox directory not in PATH")
        values['vm'] = "none"
      end
    end
    values['vboxmanage'] = %x[which VBoxManage].chomp
    if not values['vboxmanage'].to_s.match(/VBoxManage/) or values['vboxmanage'].to_s.match(/no VBoxManage/)
      verbose_output(values, "Warning:\tCould not find VBoxManage")
      values['vm'] = "none"
    end
  else
    values['vboxmanage'] = %x[which vboxmanage].chomp
    if !values['vboxmanage'].to_s.match(/vboxmanage/) || values['vboxmanage'].to_s.match(/no vboxmanage/)
      verbose_output(values, "Warning:\tCould not find vboxmanage")
      values['vm'] = "none"
    end
  end
  return values
end

# Check VirtualBox VM exists

def check_vbox_vm_exists(values)
  message   = "Information:\tChecking VM "+values['name'].to_s+" exists"
  command   = "#{values['vboxmanage']} list vms |grep -v 'inaccessible'"
  host_list = execute_command(values, message, command)
  if not host_list.match(values['name'])
    if values['verbose'] == true
      verbose_output(values, "Warning:\tVirtualBox VM #{values['name']} does not exist")
    end
    exists = false
  else
    exists = true
  end
  return exists
end

# Get VirtualBox bridged network interface

def get_bridged_vbox_nic(values)
  message  = "Information:\tChecking Bridged interfaces"
  command  = "#{values['vboxmanage']} list bridgedifs |grep '^Name' |head -1"
  nic_list = execute_command(values, message, command)
  if not nic_list.match(/[a-z,A-Z]/)
    nic_name = values['nic']
  else
    nic_list=nic_list.split(/\n/)
    nic_list.each do |line|
      line=line.chomp
      if line.match(/#{values['hostonlyip']}/)
        return nic_name
      end
      if line.match(/^Name/)
        nic_name = line.split(/:/)[1].gsub(/\s+/, "")
      end
    end
  end
  return nic_name
end

# Add bridged network to VirtualBox VM

def add_bridged_network_to_vbox_vm(values, nic_name)
  message = "Information:\tAdding bridged network "+nic_name+" to "+values['name']
  command = "#{values['vboxmanage']} modifyvm #{values['name']} --nic1 bridged --bridgeadapter1 #{nic_name}"
  execute_command(values, message, command)
  return
end

# Add non-bridged network to VirtualBox VM

def add_nonbridged_network_to_vbox_vm(values, nic_name)
  message = "Information:\tAdding network "+nic_name+" to "+values['name']
  if nic_name.match(/vboxnet/)
    command = "#{values['vboxmanage']} modifyvm #{values['name']} --hostonlyadapter1 #{nic_name} ; #{values['vboxmanage']} modifyvm #{values['name']} --nic1 hostonly"
  else
    command = "#{values['vboxmanage']} modifyvm #{values['name']} --nic1 #{nic_name}"
  end
  execute_command(values, message, command)
  return
end

# Set boot priority to network

def set_vbox_vm_boot_priority(values)
  message = "Information:\tSetting boot priority for "+values['name']+" to disk then network"
  command = "#{values['vboxmanage']} modifyvm #{values['name']} --boot1 disk --boot2 net"
  execute_command(values, message, command)
  return
end

# Set boot device

def set_vbox_boot_device(values)
  message = "Information:\tSetting boot device for "+values['name']+" to "+values['boot']
  command = "#{values['vboxmanage']} modifyvm #{values['name']} --boot1 #{values['boot']}"
  execute_command(values, message, command)
  return
end

# Get VirtualBox VM OS

def get_vbox_vm_os(values)
  message = "Information:\tGetting VirtualBox VM OS for "+values['name']
  command = "#{values['vboxmanage']} showvminfo #{values['name']} |grep Guest |grep OS |head -1 |cut -f2 -d:"
  vm_os   = execute_command(values, message, command)
  vm_os   = vm_os.gsub(/^\s+/, "")
  vm_os   = vm_os.chomp
  return vm_os
end

# List VirtualBox VMs

def list_vbox_vms(values)
  vm_list = get_available_vbox_vms(values)
  search_string = values['search']
  if vm_list.length > 0
    if search_string == "all"
      type_string = "VirtualBox"
    else
      type_string = search_string+" VirtualBox"
    end
    if values['output'].to_s.match(/html/)
      verbose_output(values, "<h1>Available #{type_string} VMs</h1>")
      verbose_output(values, "<table border=\"1\">")
      verbose_output(values, "<tr>")
      verbose_output(values, "<th>VM</th>")
      verbose_output(values, "<th>OS</th>")
      verbose_output(values, "<th>MAC</th>")
      verbose_output(values, "</tr>")
    else
      verbose_output(values, "")
      verbose_output(values, "Available #{type_string} VMs:")
      verbose_output(values, "")
    end
    vm_list.each do |line|
      line = line.chomp
      vm_name = line.split(/\"/)[1]
      values['name'] = vm_name
      vm_mac = get_vbox_vm_mac(values)
      vm_os  = get_vbox_vm_os(values)
      if search_string == "all" or line.match(/#{search_string}/)
        if values['output'].to_s.match(/html/)
          verbose_output(values, "<tr>")
          verbose_output(values, "<td>#{vm_name}</td>")
          verbose_output(values, "<td>#{vm_mac}</td>")
          verbose_output(values, "<td>#{vm_os}</td>")
          verbose_output(values, "</tr>")
        else
          output = vm_name+" os="+vm_os+" mac="+vm_mac
          verbose_output(values, output)
        end
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_output(values, "</table>")
    else
      verbose_output(values, "")
    end
  end
  return
end

# Get VirtualBox VM directory

def get_vbox_vm_dir(values)
  message = "Information:\tGetting VirtualBox VM directory"
  command = "#{values['vboxmanage']} list systemproperties |grep 'Default machine folder' |cut -f2 -d':' |sed 's/^[         ]*//g'"
  vbox_vm_base_dir = execute_command(values, message, command)
  vbox_vm_base_dir = vbox_vm_base_dir.chomp
  if not vbox_vm_base_dir.match(/[a-z,A-Z]/)
    vbox_vm_base_dir = values['home']+"/VirtualBox VMs"
  end
  vm_dir = "#{vbox_vm_base_dir}/#{values['name']}"
  return vm_dir
end

# Delete VirtualBox config file

def delete_vbox_vm_config(values)
  values['vmdir'] = get_vbox_vm_dir(values)
  config_file = values['vmdir']+"/"+values['name']+".vbox"
  if File.exist?(config_file)
    message = "Information:\tRemoving Virtualbox configuration file "+config_file
    command = "rm \"#{config_file}\""
    execute_command(values, message, command)
  end
  config_file = values['vmdir']+"/"+values['name']+".vbox-prev"
  if File.exist?(config_file)
    message = "Information:\tRemoving Virtualbox configuration file "+config_file
    command = "rm \"#{config_file}\""
    execute_command(values, message, command)
  end
  return
end

# Check if VirtuakBox config file exists

def check_vbox_vm_config_exists(values)
  exists = false
  vm_dir = get_vbox_vm_dir(values)
  config_file = vm_dir+"/"+values['name']+".vbox"
  prev_file   = vm_dir+"/"+values['name']+".vbox-prev"
  if File.exist?(config_file) or File.exist?(prev_file)
    exists = true
  else
    exists = false
  end
  return exists
end

# Check VM doesn't exist

def check_vbox_vm_doesnt_exist(values)
  message   = "Checking:\tVM "+values['name']+" doesn't exist"
  command   = "#{values['vboxmanage']} list vms"
  host_list = execute_command(values, message, command)
  if host_list.match(values)
    verbose_output(values, "Information:\tVirtualBox VM #{values['name']} already exists")
    quit(values)
  end
  return
end

# Routine to register VM

def register_vbox_vm(values)
  message = "Information:\tRegistering VM "+values['name']
  command = "#{values['vboxmanage']} createvm --name \"#{values['name']}\" --ostype \"#{values['os-type']}\" --register"
  execute_command(values, message, command)
  return
end

# Get VirtualBox disk

def get_vbox_controller(values)
  if values['controller']=~/ide/
    values['controller'] = "PIIX4"
  end
  if values['controller']=~/sata/
    values['controller'] = "IntelAHCI"
  end
  if values['controller']=~/scsi/
    values['controller'] = "LSILogic"
  end
  if values['controller']=~/sas/
    values['controller'] = "LSILogicSAS"
  end
  return values['controller']
end

# Add controller to VM

def add_controller_to_vbox_vm(values)
  message = "Information:\tAdding controller to VirtualBox VM"
  command = "#{values['vboxmanage']} storagectl \"#{values['name']}\" --name \"#{defaults['controller']}\" --add \"#{defaults['controller']}\" --controller \"#{values['controller']}\""
  execute_command(values, message, command)
  return
end

# Create Virtual Bpx VM HDD

def create_vbox_hdd(values)
  message = "Information:\tCreating VM hard disk for "+values['name']
  command = "#{values['vboxmanage']} createhd --filename \"#{values['disk']}\" --size \"#{values['size']}\""
  execute_command(values, message, command)
  return
end

def detach_file_from_vbox_vm(values)
  if values['file'].to_s.match(/iso$/) or values['type'].to_s.match(/iso|cdrom/)
    message = "Information:\tDetaching CDROM from "+values['name']
    command = "#{values['vboxmanage']} storageattach \"#{values['name']}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium none"
    execute_command(values, message, command)
  end
  return
end

# Add hard disk to VirtualBox VM

def add_hdd_to_vbox_vm(values)
  message = "Information:\tAttaching storage \"#{values['disk']}\" of type \"#{defaults['controller']}\" to VM "+values['name']
  command = "#{values['vboxmanage']} storageattach \"#{values['name']}\" --storagectl \"#{defaults['controller']}\" --port 0 --device 0 --type hdd --medium \"#{values['disk']}\""
  execute_command(values, message, command)
  return
end

# Add guest additions ISO

def add_tools_to_vbox_vm(values)
  message = "Information:\tAttaching CDROM \""+values['vboxadditions']+"\" to VM "+values['name']
  command = "#{values['vboxmanage']} storagectl \"#{values['name']}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(values, message, command)
  if File.exist?(values['vboxadditions'])
    message = "Information:\tAttaching ISO "+values['vboxadditions']+" to VM "+values['name']
    command = "#{values['vboxmanage']} storageattach \"#{values['name']}\" --storagectl \"cdrom\" --port 1 --device 0 --type dvddrive --medium \"#{values['vboxadditions']}\""
    execute_command(values, message, command)
  end
  return
end

# Add hard disk to VirtualBox VM

def add_cdrom_to_vbox_vm(values)
  message = "Information:\tAttaching CDROM \""+values['file']+"\" to VM "+values['name']
  command = "#{values['vboxmanage']} storagectl \"#{values['name']}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(values, message, command)
  if File.exist?(values['vboxadditions'])
    message = "Information:\tAttaching ISO "+values['vboxadditions']+" to VM "+values['name']
    command = "#{values['vboxmanage']} storageattach \"#{values['name']}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium \"#{values['file']}\""
    execute_command(values, message, command)
  end
  return
end

# Add memory to Virtualbox VM

def add_memory_to_vbox_vm(values)
  message = "Information:\tAdding memory to VM "+values['name']
  command = "#{values['vboxmanage']} modifyvm \"#{values['name']}\" --memory \"#{values['memory']}\""
  execute_command(values, message, command)
  return
end

# Routine to add a socket to a VM

def add_socket_to_vbox_vm(values)
  socket_name = "/tmp/#{values['name']}"
  message     = "Information:\tAdding serial controller to "+values['name']
  command     = "#{values['vboxmanage']} modifyvm \"#{values['name']}\" --uartmode1 server #{socket_name}"
  execute_command(values, message, command)
  return socket_name
end

# Routine to add serial to a VM

def add_serial_to_vbox_vm(values)
  message = "Information:\tAdding serial Port to "+values['name']
  command = "#{values['vboxmanage']} modifyvm \"#{values['name']}\" --uart1 0x3F8 4"
  execute_command(values, message, command)
  return
end

# Get VirtualBox Guest OS name

def get_vbox_guest_os(values)
  case values['method']
  when /pe/
    vm_os = get_pe_vbox_guest_os(values)
  when /ai/
    vm_os = get_ai_vbox_guest_os(values)
  when /js/
    vm_os = get_js_vbox_guest_os(values)
  when /ks/
    vm_os = get_ks_vbox_guest_os(values)
  when /ps/
    vm_os = get_ps_vbox_guest_os(values)
  when /ay/
    vm_os = get_ay_vbox_guest_os(values)
  when /ob/
    vm_os = get_ob_vbox_guest_os(values)
  when /nb/
    vm_os = get_nb_vbox_guest_os(values)
  when /vs/
    vm_os = get_vs_vbox_guest_os(values)
  when /other/
    vm_os = get_other_vbox_guest_os(values)
  end
  return vm_os
end

# Get NT VirtualBox Guest OS name

def get_pe_vbox_guest_os(values)
  vm_os = "Windows2008"
  if values['arch'].to_s.match(/64/)
    vm_os = vm_os+"_64"
  end
  return vm_os
end

# Configure a NT Virtual Box VM

def configure_nt_vbox_vm(values)
  values['os-type'] = get_nt_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Get AI VirtualBox Guest OS name

def get_ai_vbox_guest_os(values)
  vm_os = "Solaris11_64"
  return vm_os
end

# Configure a AI Virtual Box VM

def configure_ai_vbox_vm(values)
  values['os-type'] = get_ai_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Get Jumpstart VirtualBox Guest OS name

def get_js_vbox_guest_os(values)
  vm_os = "OpenSolaris_64"
  return vm_os
end

# Configure a Jumpstart Virtual Box VM

def configure_js_vbox_vm(values)
  values['os-type'] = get_js_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Get Kicktart VirtualBox Guest OS name

def get_ks_vbox_guest_os(values)
  if values['arch'].to_s.match(/i386/)
    vm_os = "RedHat"
  else
    vm_os = "RedHat_64"
  end
  return vm_os
end

# Configure a RedHat or Centos Kickstart VirtualBox VM

def configure_ks_vbox_vm(values)
  values['os-type'] = get_ks_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Get VirtualBox Guest OS name

def get_ps_vbox_guest_os(values)
  if values['arch'].to_s.match(/i386/)
    vm_os = "Ubuntu"
  else
    vm_os = "Ubuntu_64"
  end
  return vm_os
end

# Configure a Preseed Ubuntu VirtualBox VM

def configure_ps_vbox_vm(values)
  values['os-type'] = get_ps_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Get VirtualBox Guest OS name

def get_ay_vbox_guest_os(values)
  if values['arch'].to_s.match(/i386/)
    values['os-type'] = "OpenSUSE"
  else
    values['os-type'] = "OpenSUSE_64"
  end
  return values['os-type']
end

# Configure a AutoYast SuSE VirtualBox VM

def configure_ay_vbox_vm(values)
  values['os-type'] = get_ay_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Get OpenBSD VirtualBox Guest OS name

def get_ob_vbox_guest_os(values)
  values['os-type'] = "Linux_64"
  return values['os-type']
end

# Configure an OpenBSD VM

def configure_ob_vbox_vm(values)
  values['os-type'] = get_ob_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Get NetBSD VirtualBox Guest OS name

def get_nb_vbox_guest_os(values)
  if values['arch'].to_s.match(/i386/)
    values['os-type'] = "NetBSD"
  else
    values['os-type'] = "NetBSD_64"
  end
  return values['os-type']
end

# Configure a NetBSD VM

def configure_nb_vbox_vm(values)
  values['os-type'] = get_nb_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Get vSphere VirtualBox Guest OS name

def get_vs_vbox_guest_os(values)
  values['os-type'] = "Linux_64"
  return values['os-type']
end

# Configure a ESX VirtualBox VM

def configure_vs_vbox_vm(values)
  values['os-type'] = get_vs_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Get Other VirtualBox Guest OS name

def get_other_vbox_guest_os(values)
  values['os-type'] = "Other"
  return values['os-type']
end

# Configure a other VirtualBox VM

def configure_other_vbox_vm(values)
  values['os-type'] = get_other_vbox_guest_os(values)
  configure_vbox_vm(values)
  return
end

# Modify a VirtualBox VM parameter

def modify_vbox_vm(values)
  message = "Information:\tSetting VirtualBox Parameter "+values['param']+" to "+values['value']
  command = "#{values['vboxmanage']} modifyvm #{values['name']} --#{values['param']} #{values['value']}"
  execute_command(values, message, command)
  return
end

def setextradata_vbox_vm(values)
  message = "Information:\tSetting VirtualBox Extradata "+values['param']+" to "+values['value']
  command = "#{values['vboxmanage']} setextradata #{values['name']} \"#{values['param']}\" \"#{values['value']}\""
  execute_command(values, message, command)
  return
end

# Change VirtualBox VM Cores

def change_vbox_vm_cpu(values)
  message = "Information:\tSetting VirtualBox VM "+values['name']+" CPUs to "+values['vcpus']
  command = "#{values['vboxmanage']} modifyvm #{values['name']} --cpus #{values['vcpus']}"
  execute_command(values, message, command)
  return
end

# Change VirtualBox VM UTC

def change_vbox_vm_utc(values)
  message = "Information:\tSetting VirtualBox VM "+values['name']+" RTC to "+values['utc']
  command = "#{values['vboxmanage']} modifyvm #{values['name']} --rtcuseutc #{values['utc']}"
  execute_command(values, message, command)
  return
end

# Change VirtualBox VM MAC address

def change_vbox_vm_mac(values)
  message = "Information:\tSetting VirtualBox VM "+values['name']+" MAC address to "+values['mac']
  if values['mac'].to_s.match(/:/)
    values['mac'] = values['mac'].gsub(/:/, "")
  end
  command = "#{values['vboxmanage']} modifyvm #{values['name']} --macaddress1 #{values['mac']}"
  execute_command(values, message, command)
  return
end

# Boot VirtualBox VM

def boot_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == false
    verbose_output(values, "Warning:\tVirtualBox VM #{values['name']} does not exist")
    return exists
  end
  if values['boot'].to_s.match(/cdrom|net|dvd|disk/)
    values['boot'] = values['boot'].gsub(/cdrom/, "dvd")
    set_vbox_boot_device(values['name'], values['boot'])
  end
  message = "Starting:\tVM "+values['name']
  if values['text'] == true or values['serial'] == true or values['headless'] == true
    command = "#{values['vboxmanage']} startvm #{values['name']} --type headless ; sleep 1"
    verbose_output(values, "")
    verbose_output(values, "Information:\tBooting and connecting to virtual serial port of #{values['name']}")
    verbose_output(values, "")
    verbose_output(values, "To disconnect from this session use CTRL-Q")
    verbose_output(values, "")
    verbose_output(values, "If you wish to re-connect to the serial console of this machine,")
    verbose_output(values, "run the following command")
    verbose_output(values, "")
    verbose_output(values, "socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
    verbose_output(values, "")
    verbose_output(values, "Executing:\t #{command}")
    verbose_output(values, "")
    set_vbox_bin(values)
    if values['vboxmanage'].to_s.match(/[a-z]/)
      %x[#{values['vboxmanage']} startvm #{values['name']} --type headless ; sleep 1]
    end
  else
    command = "#{values['vboxmanage']} startvm #{values['name']}"
    execute_command(values, message, command)
  end
  if values['serial'] == true
    system("socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
  else
    verbose_output(values, "")
    verbose_output(values, "If you wish to connect to the serial console of this machine,")
    verbose_output(values, "run the following command")
    verbose_output(values, "")
    verbose_output(values, "socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
    verbose_output(values, "")
    verbose_output(values, "To disconnect from this session use CTRL-Q")
    verbose_output(values, "")
    verbose_output(values, "")
  end
  return exists
end

# Stop VirtualBox VM

def stop_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    message = "Stopping:\tVM "+values['name']
    command = "#{values['vboxmanage']} controlvm #{values['name']} poweroff"
    execute_command(values, message, command)
  end
  return
end

# Get VirtualBox VM MAC address

def get_vbox_vm_mac(values)
  values['search'] = "MAC"
  values['mac']    = get_vbox_vm_info(values)
  values['mac']    = values['mac'].chomp.gsub(/\,/, "")
  return values['mac']
end

# Get VirtualBox hostonly network interface

def get_vbox_hostonly_interface(values)
  if_name = ""
  if values['vboxmanage'].match(/[a-z]/)
    message = "Information:\tFinding VirtualBox hostonly network name"
    command = "#{values['vboxmanage']} list hostonlyifs |grep '^Name' |head -1"
    if_name = execute_command(values, message, command)
    if_name = if_name.split(":")[1]
    if if_name
      if_name = if_name.gsub(/^\s+/, "")
      if_name = if_name.gsub(/'/, "")
    else
      if_name = "none"
    end
  end
  return if_name
end

# Check VirtualBox hostonly network

def check_vbox_hostonly_network(values)
  if_name  = values['vmnet']
  if_check = get_vbox_hostonly_interface(values)
  if values['host-os-uname'].to_s.match(/NT/)
    string = "VirtualBox Host-Only Ethernet Adapter"
  else
    string = "vboxnet"
  end
  if !if_check.match(/#{string}/)
    message = "information:\tPlumbing VirtualBox hostonly network"
    command = "#{values['vboxmanage']} hostonlyif create"
    execute_command(values, message, command)
    if values['vmnetdhcp'] == false
      message = "Information:\tDisabling DHCP on "+if_name
      command = "#{values['vboxmanage']} dhcpserver remove --ifname \"#{if_name}\""
      execute_command(values, message, command)
    end
  end
  message = "Information:\tChecking VirtualBox hostonly network "+if_name+" has address "+values['hostonlyip']
  command = "#{values['vboxmanage']} list hostonlyifs |grep 'IPAddress' |awk '{print $2}' |head -1"
  host_ip = execute_command(values, message, command)
  host_ip = host_ip.chomp
  if not host_ip.match(/#{values['hostonlyip']}/)
    message = "Information:\tConfiguring VirtualBox hostonly network "+if_name+" with IP "+values['hostonlyip']
    command = "#{values['vboxmanage']} hostonlyif ipconfig \"#{if_name}\" --ip #{values['hostonlyip']} --netmask #{values['netmask']}"
    execute_command(values, message, command)
  end
  message = "Information:\tChecking VirtualBox DHCP Server is Disabled"
  command = "#{values['vboxmanage']} list dhcpservers"
  output  = execute_command(values, message, command)
  if output.match(/Enabled/)
    message = "Information:\tDisabling VirtualBox DHCP Server\t"
    command = "#{values['vboxmanage']} dhcpserver remove --ifname \"#{if_name}\""
  end
  gw_if_name = get_gw_if_name(values)
  case values['host-os-uname']
  when /Darwin/
    if values['host-os-unamer'].split(".")[0].to_i < 14
      check_osx_nat(values, gw_if_name, if_name)
    else
      check_osx_pfctl(values, gw_if_name, if_name)
    end
  when /Linux/
    check_linux_nat(values, gw_if_name, if_name)
  when /Solaris/
    check_solaris_nat(if_name)
  end
  return if_name
end

# Check VirtualBox is installed

def check_vbox_is_installed(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    app_dir = "/Applications/VirtualBox.app"
  else
    app_dir = "/usr/bin"
  end
  if File.directory?(app_dir)
    values = set_vbox_bin(values)
    if values['vboxmanage'].to_s.match(/[a-z]/)
      fix_vbox_mouse_integration(values)
    end
  end
  return values
end

# Add CPU to Virtualbox VM

def add_cpu_to_vbox_vm(values)
  if values['vcpus'].to_i > 1
    message = "Information:\tSetting number of CPUs to "+values['vcpus']
    command = "#{values['vboxmanage']} modifyvm \"#{values['name']}\" --cpus #{values['vcpus']}"
    execute_command(values, message, command)
  end
  return
end

# Configure VNC

def configure_vbox_vnc(values)
  message = "Information:\tEnabling VNC for VirtualBox"
  command = "#{values['vboxmanage']} setproperty vrdeextpack VNC"
  execute_command(values, message, command)
  message = "Information:\tEnabling VNC for VirtualBox VM "+values['name']
  command = "#{values['vboxmanage']} modifyvm '#{values['name']}' --vrdeproperty VNCPassword=#{values['vncpassword']}"
  execute_command(values, message, command)
  return
end

# Configure a VirtualBox VM

def configure_vbox_vm(values)
  values = check_vbox_is_installed(values)
  if values['vmnetwork'].to_s.match(/hostonly/)
    if_name = get_bridged_vbox_nic(values)
    values['vmnet'] = check_vbox_hostonly_network(values)
  end
  values['vmdir']  = get_box_vm_dir(values)
  values['disk']   = values['vmdir']+"/"+values['name']+".vdi"
  values['socket'] = "/tmp/#{values['name']}"
  values['controller'] = get_vbox_controller(values)
  check_vbox_vm_doesnt_exist(values)
  register_vbox_vm(values)
  add_controller_to_vbox_vm(values)
  if !values['file'].to_s.match(/ova$/)
    create_vbox_hdd(values['name'], values['disk'], values['size'])
    add_hdd_to_vbox_vm(values['name'], values['disk'])
  end
  add_memory_to_vbox_vm(values)
  values['socket'] = add_socket_to_vbox_vm(values)
  add_serial_to_vbox_vm(values)
  if values['vmnet'].to_s.match(/bridged/)
    values['vmnic'] = get_bridged_vbox_nic(values)
    add_bridged_network_to_vbox_vm(values)
  else
    add_nonbridged_network_to_vbox_vm(values)
  end
  set_vbox_vm_boot_priority(values)
  if values['file'].to_s.match(/iso$/)
    add_cdrom_to_vbox_vm(values)
  end
  add_tools_to_vbox_vm(values)
  if values['mac'].to_s.match(/[0-9]/)
    change_vbox_vm_mac(values)
  else
    values['mac'] = get_vbox_vm_mac(values)
  end
  if values['os-type'].to_s.match(/ESXi/)
    configure_vmware_esxi_vbox_vm(values)
  end
  add_cpu_to_vbox_vm(values)
  if values['enablevnc'] == true
    configure_vbox_vnc(values)
  end
  verbose_output(values, "Information:\tCreated VirtualBox VM #{values['name']} with MAC address #{values['mac']}")
  return values
end

# Check VirtualBox NATd

def check_vbox_natd(values, if_name)
  values = check_vbox_is_installed(values)
  if values['vmnetwork'].to_s.match(/hostonly/)
    check_vbox_hostonly_network(values)
  end
  return values
end

# Unconfigure a Virtual Box VM

def unconfigure_vbox_vm(values)
  values = check_vbox_is_installed(values)
  exists  = check_vbox_vm_exists(values)
  if exists == false
    exists = check_vbox_vm_config_exists(values)
    if exists == true
      delete_vbox_vm_config(values)
    else
      verbose_output(values, "Warning:\tVirtualBox VM #{values['name']} does not exist")
      return exists
    end
  end
  stop_vbox_vm(values)
  sleep(5)
  message = "Information:\tDeleting VirtualBox VM "+values['name']
  command = "#{values['vboxmanage']} unregistervm #{values['name']} --delete"
  execute_command(values, message, command)
  delete_vbox_vm_config(values)
  return exists
end
