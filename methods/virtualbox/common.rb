# frozen_string_literal: true

# VirtualBox VM support code

def fix_vbox_mouse_integration(values)
  message = "Information:\tDisabling VirtualBox Mouse Integration Message"
  command = "#{shell_arg(values['vboxmanage'])} setextradata global GUI/SuppressMessages remindAboutAutoCapture,confirmInputCapture,remindAboutMouseIntegrationOn,remindAboutWrongColorDepth,confirmGoingFullscreen,remindAboutMouseIntegrationOff,remindAboutMouseIntegration"
  execute_command(values, message, command)
  nil
end

# Check VM status

def get_vbox_vm_status(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    vm_list = get_running_vbox_vms(values)
    if vm_list.to_s.match(/#{values['name']}/)
      information_message(values, "VirtualBox VM #{values['name']} is Running")
    else
      information_message(values, "VrtualBox VM #{values['name']} is Not Running")
    end
  else
    warning_message(values, "Fusion VM #{values['name']} does not exist")
  end
  nil
end

# Import Packer VirtualBox image

def import_packer_vbox_vm(values)
  (exists, images_dir) = check_packer_vm_image_exists(values)
  if exists == false
    warning_message(values, "Packer VirtualBox VM image for #{values['name']} does not exist")
    return exists
  end
  ovf_file = "#{images_dir}/#{values['name']}.ovf"
  values['file'] = "#{images_dir}/#{values['name']}.ova"
  if File.exist?(ovf_file) || File.exist?(values['file'])
    message = "Information:\tImporting OVF file for Packer VirtualBox VM #{values['name']}"
    command = if File.exist?(ovf_file)
                "#{values['vboxmanage']} import '#{ovf_file}'"
              else
                "#{values['vboxmanage']} import '#{values['file']}'"
              end
    execute_command(values, message, command)
  else
    warning_message(values, "OVF file for Packer VirtualBox VM #{values['name']} does not exist")
  end
  exists
end

# Show Fusion VM config

def show_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    output = `#{shell_arg(values['vboxmanage'])} showvminfo '#{shell_sq(values['name'])}'`
    show_output_of_command('VirtualBox VM configuration', output)
  else
    warning_message(values, "VirtualBox VM #{values['name']} does not exist")
  end
  exists
end

def show_vbox_vm_config(values)
  show_vbox_vm(values)
  nil
end

# Set VirtualBox VM Parameter

def set_vbox_value(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    `#{shell_arg(values['vboxmanage'])} modifyvm '#{shell_sq(values['name'])}' --#{shell_arg(values['param'])} #{shell_arg(values['value'])}`
  else
    warning_message(values, "VirtualBox VM #{values['name']} does not exist")
  end
  exists
end

# Get VirtualBox VM Parameter

def set_vbox_value(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    `#{shell_arg(values['vboxmanage'])} showvminfo '#{shell_sq(values['name'])}' | grep '#{shell_sq(values['param'])}'`
  else
    warning_message(values, "VirtualBox VM #{values['name']} does not exist")
  end
  exist
end

# Add shared folder to VM

def add_shared_folder_to_vbox_vm(values)
  message = "Information:\tSharing \"#{values['share']}\" to VM #{values['name']} as #{values['mount']}"
  command = "#{shell_arg(values['vboxmanage'])} sharedfolder add '#{shell_sq(values['name'])}' --name '#{shell_sq(values['mount'])}' --hostpath '#{shell_sq(values['share'])}'"
  execute_command(values, message, command)
  nil
end

# Restore VirtualBox VM snapshot

def restore_vbox_vm_snapshot(values)
  if values['clone'].to_s.match(/[a-z,A-Z]/)
    message = "Information:\tRestoring snapshot #{values['clone']} for #{values['name']}"
    command = "#{shell_arg(values['vboxmanage'])} snapshot '#{shell_sq(values['name'])}' restore '#{shell_sq(values['clone'])}'"
  else
    message = "Information:\tRestoring latest snapshot for #{values['name']}"
    command = "#{shell_arg(values['vboxmanage'])} snapshot '#{shell_sq(values['name'])}' restorecurrent"
  end
  execute_command(values, message, command)
  nil
end

# Delete VirtualBox VM snapshot

def delete_vbox_vm_snapshot(values)
  clone_list = []
  if values['clone'].to_s.match(/\*/) || values['clone'].to_s.match(/all/)
    clone_list = get_vbox_vm_snapshots(values)
    clone_list = clone_list.split("\n")
  else
    clone_list[0] = values['clone']
  end
  clone_list.each do |clone_name|
    get_fusion_vm_vmx_file(values)
    message = "Information:\tDeleting snapshot #{clone_name} for Fusion VM #{values['name']}"
    command = "#{shell_arg(values['vboxmanage'])} snapshot '#{shell_sq(values['name'])}' delete '#{shell_sq(clone_name)}'"
    execute_command(values, message, command)
  end
  nil
end

# Get a list of VirtualBox VM snapshots for a client

def get_vbox_vm_snapshots(values)
  message = "Information:\tGetting a list of snapshots for VirtualBox VM #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} snapshot '#{shell_sq(values['name'])}' list |cut -f2 -d: |cut -f1 -d'(' |sed 's/^ //g' |sed 's/ $//g'"
  execute_command(values, message, command)
end

# List all VirtualBox VM snapshots

def list_all_vbox_vm_snapshots(values)
  vm_list = get_available_vbox_vms(values)
  vm_list.each do |line|
    values['name'] = line.split(/"/)[1]
    list_vbox_vm_snapshots(values)
  end
  nil
end

# List VirtualBox VM snapshots

def list_vbox_vm_snapshots(values)
  if values['name'] == 'none'
    list_all_vbox_vm_snapshots(values)
  else
    snapshot_list = get_vbox_vm_snapshots(values)
    verbose_message(values, "Snapshots for #{values['name']}:")
    verbose_message(snapshot_list)
  end
  nil
end

# Snapshot VirtualBox VM

def snapshot_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    warning_message(values, "VirtualBox VM #{values['name']} does not exist")
    return exists
  end
  message = "Information:\tCloning VirtualBox VM #{values['name']} to #{values['clone']}"
  command = "#{shell_arg(values['vboxmanage'])} snapshot '#{shell_sq(values['name'])}' take '#{shell_sq(values['clone'])}'"
  execute_command(values, message, command)
  exists
end

# Get a List of VirtualBox VMs

def get_available_vbox_vms(values)
  vm_list = []
  message = "Information:\tGetting list of VirtualBox VMs"
  command = "#{shell_arg(values['vboxmanage'])} list vms |grep -v 'inaccessible'"
  output  = execute_command(values, message, command)
  vm_list = output.split("\n") if output.match(/[a-z]/)
  vm_list
end

# Get VirtualBox VM info

def get_vbox_vm_info(values)
  message = "Information:\tGetting value for #{values['search']} from VirtualBox VM #{values['name']}"
  command = if values['search'].to_s.match(/MAC/)
              "#{values['vboxmanage']} showvminfo \"#{values['name']}\" |grep MAC |awk '{print $4}' |head -1"
            else
              "#{values['vboxmanage']} showvminfo \"#{values['name']}\" |grep \"#{values['search']}\" |cut -f2 -d:"
            end
  output = execute_command(values, message, command)
  output.chomp.gsub(/^\s+/, '')
end

# Get VirtualBox VM OS

def get_vbox_vm_os(values)
  values['search'] = '^Guest OS'
  get_vbox_vm_info(values)
end

# List all VMs

def list_all_vbox_vms(values)
  values['search'] = 'all'
  list_vbox_vms(values)
  nil
end

# Get list of running VMs

def get_running_vbox_vms(values)
  `#{shell_arg(values['vboxmanage'])} list runningvms`.split("\n")
end

# List running VMs

def list_running_vbox_vms(values)
  set_vboxm_bin(values)
  if values['vboxmanage'].to_s.match(/[a-z]/)
    vm_list = get_running_vbox_vms(values)
    verbose_message(values, '')
    verbose_message(values, 'Running VirtualBox VMs:')
    verbose_message('')
    vm_list.each do |vm_name|
      vm_name = vm_name.split(/"/)[1]
      os_info = `#{shell_arg(values['vboxmanage'])} showvminfo "#{shell_dq(vm_name)}" |grep '^Guest OS' |cut -f2 -d:`.chomp.gsub(/^\s+/,
                                                                                                            '')
      verbose_message(values, "#{vm_name}\t#{os_info}")
    end
    verbose_message(values, '')
  end
  nil
end

# Set VirtualBox ESXi values

def configure_vmware_vbox_vm(values)
  modify_vbox_vm(values['name'], 'rtcuseutc', 'on')
  modify_vbox_vm(values['name'], 'vtxvpid', 'on')
  modify_vbox_vm(values['name'], 'vtxux', 'on')
  modify_vbox_vm(values['name'], 'hwvirtex', 'on')
  setextradata_vbox_vm(values, 'VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion', 'None')
  setextradata_vbox_vm(values, 'VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor', 'Intel Corporation')
  setextradata_vbox_vm(values, 'VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct',
                       '440BX Desktop Reference Platform')
  setextradata_vbox_vm(values, 'VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor', 'VMware, Inc.')
  setextradata_vbox_vm(values, 'VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct', 'VMware Virtual Platform')
  setextradata_vbox_vm(values, 'VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor', 'Phoenix Technologies LTD')
  setextradata_vbox_vm(values, 'VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion', '6.0')
  setextradata_vbox_vm(values, 'VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor', 'No Enclosure')
  vbox_vm_uuid = get_vbox_vm_uuid(values)
  vbox_vm_uuid = "VMware-#{vbox_vm_uuid}"
  setextradata_vbox_vm(values['name'], 'VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial', vbox_vm_uuid)
  nil
end

# Get VirtualBox UUID

def get_vbox_vm_uuid(values)
  values['search'] = '^UUID'
  get_vbox_vm_info(values['name'], values['search'])
end

# Set VirtualBox ESXi values

def configure_vmware_esxi_vbox_vm(values)
  configure_vmware_esxi_defaults(values)
  modify_vbox_vm(values['name'], 'cpus', values['vcpus'])
  configure_vmware_vbox_vm(values)
  nil
end

# Set VirtualBox vCenter option

def configure_vmware_vcenter_vbox_vm(values)
  configure_vmware_vcenter_defaults(values)
  configure_vmware_vbox_vm(values)
  nil
end

# Clone VirtualBox VM

def clone_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    warning_message(values, "VirtualBox VM #{values['name']} does not exist")
    return exists
  end
  message = "Information:\tCloning VM #{values['name']} to #{values['clone']}"
  command = "#{shell_arg(values['vboxmanage'])} clonevm #{shell_arg(values['name'])} --name #{shell_arg(values['clone'])} --register"
  execute_command(values, message, command)
  add_hosts_entry(values['clone'], values['ip']) if values['ip'].to_s.match(/[0-9]/)
  change_vbox_vm_mac(values['clone'], values['mac']) if values['mac'].to_s.match(/[0-9,a-z,A-Z]/)
  exists
end

# Export OVA

def export_vbox_ova(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    stop_vbox_vm(values)
    unless values['file'].to_s.match(/[0-9,a-z,A-Z]/)
      values['file'] = "/tmp/#{values['name']}.ova"
      warning_message(values, 'No ouput file given')
      information_message(values, "Exporting VirtualBox VM #{values['name']} to #{values['file']}")
    end
    values['file'] = "#{values['file']}.ova" unless values['file'].to_s.match(/\.ova$/)
    message = "Information:\tExporting VirtualBox VM #{values['name']} to #{values['file']}"
    command = "#{shell_arg(values['vboxmanage'])} export \"#{shell_dq(values['name'])}\" -o \"#{shell_dq(values['file'])}\""
    execute_command(values, message, command)
  else
    warning_message(values, "VirtualBox VM #{values['name']} does not exist")
  end
  exists
end

# Import OVA

def import_vbox_ova(values)
  exists = check_vbox_vm_exists(values)
  exists = check_vbox_vm_config_exists(values) if exists == false
  delete_vbox_vm_config(values) if exists == true
  values['file'] = "#{values['isodir']}/#{values['file']}" unless values['file'].to_s.match(%r{/})
  if File.exist?(values['file'])
    if values['name'].to_s.match(/[0-9,a-z,A-Z]/)
      values['vmdir'] = get_vbox_vm_dir(values)
      message = "Information:\tImporting VirtualBox VM #{values['name']} from #{values['file']}"
      command = "#{shell_arg(values['vboxmanage'])} import \"#{shell_dq(values['file'])}\" --vsys 0 --vmname \"#{shell_dq(values['name'])}\" --unit 20 --disk \"#{shell_dq(values['vmdir'])}\""
      execute_command(values, message, command)
    else
      set_vbox_bin(values)
      if values['vboxmanage'].to_s.match(/[a-z]/)
        values['name'] =
          `#{shell_arg(values['vboxmanage'])} import -n #{shell_arg(values['file'])} |grep "Suggested VM name'`.split(/\n/)[-1]
        if !values['name'].to_s.match(/[0-9,a-z,A-Z]/)
          warning_message(values, "Could not determine VM name for Virtual Appliance #{values['file']}")
          quit(values)
        else
          values['name'] = values['name'].split(/Suggested VM name /)[1].chomp
          message = "Information:\tImporting VirtualBox VM #{values['name']} from #{values['file']}"
          command = "#{shell_arg(values['vboxmanage'])} import \"#{shell_dq(values['file'])}\""
          execute_command(values, message, command)
        end
      end
    end
  else
    warning_message(values, "Virtual Appliance #{values['file']} does not exist")
    return exists
  end
  add_hosts_entry(values['name'], values['ip']) if values['ip'].to_s.match(/[0-9]/)
  values['socket'] = add_socket_to_vbox_vm(values)
  add_serial_to_vbox_vm(values)
  if values['vmnet'].to_s.match(/bridged/)
    vbox_nic = get_bridged_vbox_nic(values)
    add_bridged_network_to_vbox_vm(values, vbox_nic)
  else
    vbox_nic = check_vbox_hostonly_network(values)
    add_nonbridged_network_to_vbox_vm(values, vbox_nic)
  end
  if !values['mac'].to_s.match(/[0-9,a-z,A-Z]/)
    values['mac'] = get_vbox_vm_mac(values)
  else
    change_vbox_vm_mac(values['name'], values['mac'])
  end
  if values['file'].to_s.match(/VMware/)
    configure_vmware_vcenter_defaults(values)
    configure_vmware_vbox_vm(values)
  end
  warning_message(values,
                  "Virtual Appliance #{values['file']} imported with VM name #{values['name']} and MAC address #{values['mac']}")
  exists
end

# List Linux KS VirtualBox VMs

def list_ks_vbox_vms(values)
  values['search'] = 'RedHat'
  list_vbox_vms(values)
  nil
end

# List Linux Preseed VirtualBox VMs

def list_ps_vbox_vms(values)
  values['search'] = 'Ubuntu'
  list_vbox_vms(values)
end

# List Solaris Kickstart VirtualBox VMs

def list_js_vbox_vms(values)
  values['search'] = 'OpenSolaris'
  list_vbox_vms(values)
  nil
end

# List Solaris AI VirtualBox VMs

def list_ai_vbox_vms(values)
  values['search'] = 'Solaris 11'
  list_vbox_vms(values)
  nil
end

# List Linux Autoyast VirtualBox VMs

def list_ay_vbox_vms(values)
  values['search'] = 'OpenSUSE'
  list_vbox_vms(values)
  nil
end

# List vSphere VirtualBox VMs

def list_vs_vbox_vms(values)
  values['search'] = 'Linux'
  list_vbox_vms(values)
  nil
end

# Get/set #{values['vboxmanage']} path

def set_vbox_bin(values)
  case values['host-os-uname']
  when /Darwin|NT/
    if values['host-os-uname'].to_s.match(/NT/)
      path = `echo $PATH`
      unless path.match(/VirtualBox/)
        warning_message(values, 'VirtualBox directory not in PATH')
        values['vm'] = 'none'
      end
    end
    values['vboxmanage'] = which_program('VBoxManage')
    if !values['vboxmanage'].to_s.match(/VBoxManage/) || values['vboxmanage'].to_s.match(/no VBoxManage/)
      warning_message(values, 'Could not find VBoxManage')
      values['vm'] = 'none'
    end
  else
    values['vboxmanage'] = which_program('vboxmanage')
    if !values['vboxmanage'].to_s.match(/vboxmanage/) || values['vboxmanage'].to_s.match(/no vboxmanage/)
      warning_message(values, 'Could not find vboxmanage')
      values['vm'] = 'none'
    end
  end
  values
end

# Check VirtualBox VM exists

def check_vbox_vm_exists(values)
  message   = "Information:\tChecking VM #{values['name']} exists"
  command   = "#{shell_arg(values['vboxmanage'])} list vms |grep -v 'inaccessible'"
  host_list = execute_command(values, message, command)
  if !host_list.match(values['name'])
    warning_message(values, "VirtualBox VM #{values['name']} does not exist")
    exists = false
  else
    exists = true
  end
  exists
end

# Get VirtualBox bridged network interface

def get_bridged_vbox_nic(values)
  message  = "Information:\tChecking Bridged interfaces"
  command  = "#{shell_arg(values['vboxmanage'])} list bridgedifs |grep '^Name' |head -1"
  nic_list = execute_command(values, message, command)
  if !nic_list.match(/[a-z,A-Z]/)
    nic_name = values['nic']
  else
    nic_list = nic_list.split(/\n/)
    nic_list.each do |line|
      line = line.chomp
      return nic_name if line.match(/#{values['hostonlyip']}/)

      nic_name = line.split(/:/)[1].gsub(/\s+/, '') if line.match(/^Name/)
    end
  end
  nic_name
end

# Add bridged network to VirtualBox VM

def add_bridged_network_to_vbox_vm(values, nic_name)
  message = "Information:\tAdding bridged network #{nic_name} to #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} modifyvm #{shell_arg(values['name'])} --nic1 bridged --bridgeadapter1 #{shell_arg(nic_name)}"
  execute_command(values, message, command)
  nil
end

# Add non-bridged network to VirtualBox VM

def add_nonbridged_network_to_vbox_vm(values, nic_name)
  message = "Information:\tAdding network #{nic_name} to #{values['name']}"
  command = if nic_name.match(/vboxnet/)
              "#{values['vboxmanage']} modifyvm #{values['name']} --hostonlyadapter1 #{nic_name} ; #{values['vboxmanage']} modifyvm #{values['name']} --nic1 hostonly"
            else
              "#{values['vboxmanage']} modifyvm #{values['name']} --nic1 #{nic_name}"
            end
  execute_command(values, message, command)
  nil
end

# Set boot priority to network

def set_vbox_vm_boot_priority(values)
  message = "Information:\tSetting boot priority for #{values['name']} to disk then network"
  command = "#{shell_arg(values['vboxmanage'])} modifyvm #{shell_arg(values['name'])} --boot1 disk --boot2 net"
  execute_command(values, message, command)
  nil
end

# Set boot device

def set_vbox_boot_device(values)
  message = "Information:\tSetting boot device for #{values['name']} to #{values['boot']}"
  command = "#{shell_arg(values['vboxmanage'])} modifyvm #{shell_arg(values['name'])} --boot1 #{shell_arg(values['boot'])}"
  execute_command(values, message, command)
  nil
end

# Get VirtualBox VM OS

def get_vbox_vm_os(values)
  message = "Information:\tGetting VirtualBox VM OS for #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} showvminfo #{shell_arg(values['name'])} |grep Guest |grep OS |head -1 |cut -f2 -d:"
  vm_os   = execute_command(values, message, command)
  vm_os   = vm_os.gsub(/^\s+/, '')
  vm_os.chomp
end

# List VirtualBox VMs

def list_vbox_vms(values)
  vm_list = get_available_vbox_vms(values)
  search_string = values['search']
  if vm_list.length.positive?
    type_string = if search_string == 'all'
                    'VirtualBox'
                  else
                    "#{search_string} VirtualBox"
                  end
    if values['output'].to_s.match(/html/)
      verbose_message(values, "<h1>Available #{type_string} VMs</h1>")
      verbose_message(values, '<table border="1">')
      verbose_message(values, '<tr>')
      verbose_message(values, '<th>VM</th>')
      verbose_message(values, '<th>OS</th>')
      verbose_message(values, '<th>MAC</th>')
      verbose_message(values, '</tr>')
    else
      verbose_message(values, '')
      verbose_message(values, "Available #{type_string} VMs:")
      verbose_message(values, '')
    end
    vm_list.each do |line|
      line = line.chomp
      vm_name = line.split(/"/)[1]
      values['name'] = vm_name
      vm_mac = get_vbox_vm_mac(values)
      vm_os  = get_vbox_vm_os(values)
      if (search_string == 'all') || line.match(/#{search_string}/)
        if values['output'].to_s.match(/html/)
          verbose_message(values, '<tr>')
          verbose_message(values, "<td>#{vm_name}</td>")
          verbose_message(values, "<td>#{vm_mac}</td>")
          verbose_message(values, "<td>#{vm_os}</td>")
          verbose_message(values, '</tr>')
        else
          output = "#{vm_name} os=#{vm_os} mac=#{vm_mac}"
          verbose_message(values, output)
        end
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_message(values, '</table>')
    else
      verbose_message(values, '')
    end
  end
  nil
end

# Get VirtualBox VM directory

def get_vbox_vm_dir(values)
  message = "Information:\tGetting VirtualBox VM directory"
  command = "#{shell_arg(values['vboxmanage'])} list systemproperties |grep 'Default machine folder' |cut -f2 -d':' |sed 's/^[         ]*//g'"
  vbox_vm_base_dir = execute_command(values, message, command)
  vbox_vm_base_dir = vbox_vm_base_dir.chomp
  vbox_vm_base_dir = "#{values['home']}/VirtualBox VMs" unless vbox_vm_base_dir.match(/[a-z,A-Z]/)
  "#{vbox_vm_base_dir}/#{values['name']}"
end

# Delete VirtualBox config file

def delete_vbox_vm_config(values)
  values['vmdir'] = get_vbox_vm_dir(values)
  config_file = "#{values['vmdir']}/#{values['name']}.vbox"
  if File.exist?(config_file)
    message = "Information:\tRemoving Virtualbox configuration file #{config_file}"
    command = "rm \"#{shell_dq(config_file)}\""
    execute_command(values, message, command)
  end
  config_file = "#{values['vmdir']}/#{values['name']}.vbox-prev"
  if File.exist?(config_file)
    message = "Information:\tRemoving Virtualbox configuration file #{config_file}"
    command = "rm \"#{shell_dq(config_file)}\""
    execute_command(values, message, command)
  end
  nil
end

# Check if VirtuakBox config file exists

def check_vbox_vm_config_exists(values)
  vm_dir = get_vbox_vm_dir(values)
  config_file = "#{vm_dir}/#{values['name']}.vbox"
  prev_file   = "#{vm_dir}/#{values['name']}.vbox-prev"
  if File.exist?(config_file) || File.exist?(prev_file)
    true
  else
    false
  end
end

# Check VM does not exist

def check_vbox_vm_doesnt_exist(values)
  message   = "Checking:\tVM #{values['name']} does not exist"
  command   = "#{shell_arg(values['vboxmanage'])} list vms"
  host_list = execute_command(values, message, command)
  if host_list.match(/"#{values['name']}"/)
    information_message(values, "VirtualBox VM #{values['name']} already exists")
    quit(values)
  end
  nil
end

# Routine to register VM

def register_vbox_vm(values)
  message = "Information:\tRegistering VM #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} createvm --name \"#{shell_dq(values['name'])}\" --ostype \"#{shell_dq(values['os-type'])}\" --register"
  execute_command(values, message, command)
  nil
end

# Get VirtualBox disk

def get_vbox_controller(values)
  values['controller'] = 'PIIX4' if values['controller'] =~ /ide/
  values['controller'] = 'IntelAHCI' if values['controller'] =~ /sata/
  values['controller'] = 'LSILogic' if values['controller'] =~ /scsi/
  values['controller'] = 'LSILogicSAS' if values['controller'] =~ /sas/
  values['controller']
end

# Add controller to VM

def add_controller_to_vbox_vm(values)
  message = "Information:\tAdding controller to VirtualBox VM"
  command = "#{shell_arg(values['vboxmanage'])} storagectl \"#{shell_dq(values['name'])}\" --name \"SATA\" --add \"sata\" --controller \"#{shell_dq(values['controller'])}\""
  execute_command(values, message, command)
  nil
end

# Create Virtual Bpx VM HDD

def create_vbox_hdd(values)
  message = "Information:\tCreating VM hard disk for #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} createhd --filename \"#{shell_dq(values['disk'])}\" --size \"#{shell_dq(values['size'])}\""
  execute_command(values, message, command)
  nil
end

def detach_file_from_vbox_vm(values)
  if values['file'].to_s.match(/iso$/) || values['type'].to_s.match(/iso|cdrom/)
    message = "Information:\tDetaching CDROM from #{values['name']}"
    command = "#{shell_arg(values['vboxmanage'])} storageattach \"#{shell_dq(values['name'])}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium none"
    execute_command(values, message, command)
  end
  nil
end

# Add hard disk to VirtualBox VM

def add_hdd_to_vbox_vm(values)
  message = "Information:\tAttaching storage \"#{values['disk']}\" of type \"sata\" to VM " + values['name']
  command = "#{shell_arg(values['vboxmanage'])} storageattach \"#{shell_dq(values['name'])}\" --storagectl \"SATA\" --port 0 --device 0 --type hdd --medium \"#{shell_dq(values['disk'])}\""
  execute_command(values, message, command)
  nil
end

# Add guest additions ISO

def add_tools_to_vbox_vm(values)
  message = "Information:\tAttaching CDROM \"#{values['vboxadditions']}\" to VM #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} storagectl \"#{shell_dq(values['name'])}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(values, message, command)
  if File.exist?(values['vboxadditions'])
    message = "Information:\tAttaching ISO #{values['vboxadditions']} to VM #{values['name']}"
    command = "#{shell_arg(values['vboxmanage'])} storageattach \"#{shell_dq(values['name'])}\" --storagectl \"cdrom\" --port 1 --device 0 --type dvddrive --medium \"#{shell_dq(values['vboxadditions'])}\""
    execute_command(values, message, command)
  end
  nil
end

# Add hard disk to VirtualBox VM

def add_cdrom_to_vbox_vm(values)
  message = "Information:\tAttaching CDROM \"#{values['file']}\" to VM #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} storagectl \"#{shell_dq(values['name'])}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(values, message, command)
  if File.exist?(values['vboxadditions'])
    message = "Information:\tAttaching ISO #{values['vboxadditions']} to VM #{values['name']}"
    command = "#{shell_arg(values['vboxmanage'])} storageattach \"#{shell_dq(values['name'])}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium \"#{shell_dq(values['file'])}\""
    execute_command(values, message, command)
  end
  nil
end

# Add memory to Virtualbox VM

def add_memory_to_vbox_vm(values)
  message = "Information:\tAdding memory to VM #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} modifyvm \"#{shell_dq(values['name'])}\" --memory \"#{shell_dq(values['memory'])}\""
  execute_command(values, message, command)
  nil
end

# Routine to add a socket to a VM

def add_socket_to_vbox_vm(values)
  socket_name = "/tmp/#{values['name']}"
  message     = "Information:\tAdding serial controller to #{values['name']}"
  command     = "#{shell_arg(values['vboxmanage'])} modifyvm \"#{shell_dq(values['name'])}\" --uartmode1 server #{shell_arg(socket_name)}"
  execute_command(values, message, command)
  socket_name
end

# Routine to add serial to a VM

def add_serial_to_vbox_vm(values)
  message = "Information:\tAdding serial Port to #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} modifyvm \"#{shell_dq(values['name'])}\" --uart1 0x3F8 4"
  execute_command(values, message, command)
  nil
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
  vm_os
end

# Get NT VirtualBox Guest OS name

def get_pe_vbox_guest_os(values)
  vm_os = 'Windows2008'
  vm_os += '_64' if values['arch'].to_s.match(/64/)
  vm_os
end

# Configure a NT Virtual Box VM

def configure_nt_vbox_vm(values)
  values['os-type'] = get_nt_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Get AI VirtualBox Guest OS name

def get_ai_vbox_guest_os(_values)
  'Solaris11_64'
end

# Configure a AI Virtual Box VM

def configure_ai_vbox_vm(values)
  values['os-type'] = get_ai_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Get Jumpstart VirtualBox Guest OS name

def get_js_vbox_guest_os(_values)
  'OpenSolaris_64'
end

# Configure a Jumpstart Virtual Box VM

def configure_js_vbox_vm(values)
  values['os-type'] = get_js_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Get Kicktart VirtualBox Guest OS name

def get_ks_vbox_guest_os(values)
  if values['arch'].to_s.match(/i386/)
    'RedHat'
  else
    'RedHat_64'
  end
end

# Configure a RedHat or Centos Kickstart VirtualBox VM

def configure_ks_vbox_vm(values)
  values['os-type'] = get_ks_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Get VirtualBox Guest OS name

def get_ps_vbox_guest_os(values)
  if values['arch'].to_s.match(/i386/)
    'Ubuntu'
  else
    'Ubuntu_64'
  end
end

# Configure a Preseed Ubuntu VirtualBox VM

def configure_ps_vbox_vm(values)
  values['os-type'] = get_ps_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Get VirtualBox Guest OS name

def get_ay_vbox_guest_os(values)
  values['os-type'] = if values['arch'].to_s.match(/i386/)
                        'OpenSUSE'
                      else
                        'OpenSUSE_64'
                      end
  values['os-type']
end

# Configure a AutoYast SuSE VirtualBox VM

def configure_ay_vbox_vm(values)
  values['os-type'] = get_ay_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Get OpenBSD VirtualBox Guest OS name

def get_ob_vbox_guest_os(values)
  values['os-type'] = 'Linux_64'
  values['os-type']
end

# Configure an OpenBSD VM

def configure_ob_vbox_vm(values)
  values['os-type'] = get_ob_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Get NetBSD VirtualBox Guest OS name

def get_nb_vbox_guest_os(values)
  values['os-type'] = if values['arch'].to_s.match(/i386/)
                        'NetBSD'
                      else
                        'NetBSD_64'
                      end
  values['os-type']
end

# Configure a NetBSD VM

def configure_nb_vbox_vm(values)
  values['os-type'] = get_nb_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Get vSphere VirtualBox Guest OS name

def get_vs_vbox_guest_os(values)
  values['os-type'] = 'Linux_64'
  values['os-type']
end

# Configure a ESX VirtualBox VM

def configure_vs_vbox_vm(values)
  values['os-type'] = get_vs_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Get Other VirtualBox Guest OS name

def get_other_vbox_guest_os(values)
  values['os-type'] = 'Other'
  values['os-type']
end

# Configure a other VirtualBox VM

def configure_other_vbox_vm(values)
  values['os-type'] = get_other_vbox_guest_os(values)
  configure_vbox_vm(values)
  nil
end

# Modify a VirtualBox VM parameter

def modify_vbox_vm(values)
  message = "Information:\tSetting VirtualBox Parameter #{values['param']} to #{values['value']}"
  command = "#{shell_arg(values['vboxmanage'])} modifyvm #{shell_arg(values['name'])} --#{shell_arg(values['param'])} #{shell_arg(values['value'])}"
  execute_command(values, message, command)
  nil
end

def setextradata_vbox_vm(values)
  message = "Information:\tSetting VirtualBox Extradata #{values['param']} to #{values['value']}"
  command = "#{shell_arg(values['vboxmanage'])} setextradata #{shell_arg(values['name'])} \"#{shell_dq(values['param'])}\" \"#{shell_dq(values['value'])}\""
  execute_command(values, message, command)
  nil
end

# Change VirtualBox VM Cores

def change_vbox_vm_cpu(values)
  message = "Information:\tSetting VirtualBox VM #{values['name']} CPUs to #{values['vcpus']}"
  command = "#{shell_arg(values['vboxmanage'])} modifyvm #{shell_arg(values['name'])} --cpus #{shell_arg(values['vcpus'])}"
  execute_command(values, message, command)
  nil
end

# Change VirtualBox VM UTC

def change_vbox_vm_utc(values)
  message = "Information:\tSetting VirtualBox VM #{values['name']} RTC to #{values['utc']}"
  command = "#{shell_arg(values['vboxmanage'])} modifyvm #{shell_arg(values['name'])} --rtcuseutc #{shell_arg(values['utc'])}"
  execute_command(values, message, command)
  nil
end

# Change VirtualBox VM MAC address

def change_vbox_vm_mac(values)
  message = "Information:\tSetting VirtualBox VM #{values['name']} MAC address to #{values['mac']}"
  values['mac'] = values['mac'].gsub(/:/, '') if values['mac'].to_s.match(/:/)
  command = "#{shell_arg(values['vboxmanage'])} modifyvm #{shell_arg(values['name'])} --macaddress1 #{shell_arg(values['mac'])}"
  execute_command(values, message, command)
  nil
end

# Boot VirtualBox VM

def boot_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == false
    warning_message(values, "VirtualBox VM #{values['name']} does not exist")
    return exists
  end
  if values['boot'].to_s.match(/cdrom|net|dvd|disk/)
    values['boot'] = values['boot'].gsub(/cdrom/, 'dvd')
    set_vbox_boot_device(values['name'], values['boot'])
  end
  message = "Starting:\tVM #{values['name']}"
  if (values['text'] == true) || (values['serial'] == true) || (values['headless'] == true)
    command = "#{shell_arg(values['vboxmanage'])} startvm #{shell_arg(values['name'])} --type headless ; sleep 1"
    verbose_message(values, '')
    information_message(values, "Booting and connecting to virtual serial port of #{values['name']}")
    verbose_message(values, '')
    verbose_message(values, 'To disconnect from this session use CTRL-Q')
    verbose_message(values, '')
    verbose_message(values, 'If you wish to re-connect to the serial console of this machine,')
    verbose_message(values, 'run the following command')
    verbose_message(values, '')
    verbose_message(values, "socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
    verbose_message(values, '')
    execute_message(values, command)
    verbose_message(values, '')
    set_vbox_bin(values)
    `#{shell_arg(values['vboxmanage'])} startvm #{shell_arg(values['name'])} --type headless ; sleep 1` if values['vboxmanage'].to_s.match(/[a-z]/)
  else
    command = "#{shell_arg(values['vboxmanage'])} startvm #{shell_arg(values['name'])}"
    execute_command(values, message, command)
  end
  if values['serial'] == true
    system("socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
  else
    verbose_message(values, '')
    verbose_message(values, 'If you wish to connect to the serial console of this machine,')
    verbose_message(values, 'run the following command')
    verbose_message(values, '')
    verbose_message(values, "socat UNIX-CONNECT:/tmp/#{values['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
    verbose_message(values, '')
    verbose_message(values, 'To disconnect from this session use CTRL-Q')
    verbose_message(values, '')
    verbose_message(values, '')
  end
  exists
end

# Stop VirtualBox VM

def stop_vbox_vm(values)
  exists = check_vbox_vm_exists(values)
  if exists == true
    message = "Stopping:\tVM #{values['name']}"
    command = "#{shell_arg(values['vboxmanage'])} controlvm #{shell_arg(values['name'])} poweroff"
    execute_command(values, message, command)
  end
  nil
end

# Get VirtualBox VM MAC address

def get_vbox_vm_mac(values)
  values['search'] = 'MAC'
  values['mac']    = get_vbox_vm_info(values)
  values['mac']    = values['mac'].chomp.gsub(/,/, '')
  values['mac']
end

# Get VirtualBox hostonly network interface

def get_vbox_hostonly_interface(values)
  if_name = ''
  if values['vboxmanage'].match(/[a-z]/)
    message = "Information:\tFinding VirtualBox hostonly network name"
    command = "#{shell_arg(values['vboxmanage'])} list hostonlyifs |grep '^Name' |head -1"
    if_name = execute_command(values, message, command)
    if_name = if_name.split(':')[1]
    if if_name
      if_name = if_name.gsub(/^\s+/, '')
      if_name = if_name.gsub(/'/, '')
    else
      if_name = 'none'
    end
  end
  if_name
end

# Check VirtualBox hostonly network

def check_vbox_hostonly_network(values)
  if_name  = values['vmnet']
  if_check = get_vbox_hostonly_interface(values)
  string = if values['host-os-uname'].to_s.match(/NT/)
             'VirtualBox Host-Only Ethernet Adapter'
           else
             'vboxnet'
           end
  unless if_check.match(/#{string}/)
    message = "information:\tPlumbing VirtualBox hostonly network"
    command = "#{shell_arg(values['vboxmanage'])} hostonlyif create"
    execute_command(values, message, command)
    if values['vmnetdhcp'] == false
      message = "Information:\tDisabling DHCP on #{if_name}"
      command = "#{shell_arg(values['vboxmanage'])} dhcpserver remove --ifname \"#{shell_dq(if_name)}\""
      execute_command(values, message, command)
    end
  end
  message = "Information:\tChecking VirtualBox hostonly network #{if_name} has address #{values['hostonlyip']}"
  command = "#{shell_arg(values['vboxmanage'])} list hostonlyifs |grep 'IPAddress' |awk '{print $2}' |head -1"
  host_ip = execute_command(values, message, command)
  host_ip = host_ip.chomp
  unless host_ip.match(/#{values['hostonlyip']}/)
    message = "Information:\tConfiguring VirtualBox hostonly network #{if_name} with IP #{values['hostonlyip']}"
    command = "#{shell_arg(values['vboxmanage'])} hostonlyif ipconfig \"#{shell_dq(if_name)}\" --ip #{shell_arg(values['hostonlyip'])} --netmask #{shell_arg(values['netmask'])}"
    execute_command(values, message, command)
  end
  message = "Information:\tChecking VirtualBox DHCP Server is Disabled"
  command = "#{shell_arg(values['vboxmanage'])} list dhcpservers"
  output  = execute_command(values, message, command)
  "#{values['vboxmanage']} dhcpserver remove --ifname \"#{if_name}\"" if output.match(/Enabled/)
  gw_if_name = get_gw_if_name(values)
  case values['host-os-uname']
  when /Darwin/
    if values['host-os-unamer'].split('.')[0].to_i < 14
      check_osx_nat(values, gw_if_name, if_name)
    else
      check_osx_pfctl(values, gw_if_name, if_name)
    end
  when /Linux/
    check_linux_nat(values, gw_if_name, if_name)
  when /Solaris/
    check_solaris_nat(if_name)
  end
  if_name
end

# Check VirtualBox is installed

def check_vbox_is_installed(values)
  app_dir = if values['host-os-uname'].to_s.match(/Darwin/)
              '/Applications/VirtualBox.app'
            else
              '/usr/bin'
            end
  if File.directory?(app_dir)
    values = set_vbox_bin(values)
    fix_vbox_mouse_integration(values) if values['vboxmanage'].to_s.match(/[a-z]/)
  end
  values
end

# Add CPU to Virtualbox VM

def add_cpu_to_vbox_vm(values)
  if values['vcpus'].to_i > 1
    message = "Information:\tSetting number of CPUs to #{values['vcpus']}"
    command = "#{shell_arg(values['vboxmanage'])} modifyvm \"#{shell_dq(values['name'])}\" --cpus #{shell_arg(values['vcpus'])}"
    execute_command(values, message, command)
  end
  nil
end

# Configure VNC

def configure_vbox_vnc(values)
  message = "Information:\tEnabling VNC for VirtualBox"
  command = "#{shell_arg(values['vboxmanage'])} setproperty vrdeextpack VNC"
  execute_command(values, message, command)
  message = "Information:\tEnabling VNC for VirtualBox VM #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} modifyvm '#{shell_sq(values['name'])}' --vrdeproperty VNCPassword=#{shell_arg(values['vncpassword'])}"
  execute_command(values, message, command)
  nil
end

# Configure a VirtualBox VM

def configure_vbox_vm(values)
  values = check_vbox_is_installed(values)
  if values['vmnetwork'].to_s.match(/hostonly/)
    get_bridged_vbox_nic(values)
    values['vmnet'] = check_vbox_hostonly_network(values)
  end
  values['vmdir']  = get_vbox_vm_dir(values)
  values['disk']   = "#{values['vmdir']}/#{values['name']}.vdi"
  values['socket'] = "/tmp/#{values['name']}"
  values['controller'] = get_vbox_controller(values)
  check_vbox_vm_doesnt_exist(values)
  register_vbox_vm(values)
  add_controller_to_vbox_vm(values)
  unless values['file'].to_s.match(/ova$/)
    create_vbox_hdd(values)
    add_hdd_to_vbox_vm(values)
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
  add_cdrom_to_vbox_vm(values) if values['file'].to_s.match(/iso$/)
  add_tools_to_vbox_vm(values)
  if values['mac'].to_s.match(/[0-9]/)
    change_vbox_vm_mac(values)
  else
    values['mac'] = get_vbox_vm_mac(values)
  end
  configure_vmware_esxi_vbox_vm(values) if values['os-type'].to_s.match(/ESXi/)
  add_cpu_to_vbox_vm(values)
  configure_vbox_vnc(values) if values['enablevnc'] == true
  information_message(values, "Created VirtualBox VM #{values['name']} with MAC address #{values['mac']}")
  values
end

# Check VirtualBox NATd

def check_vbox_natd(values, _if_name)
  values = check_vbox_is_installed(values)
  check_vbox_hostonly_network(values) if values['vmnetwork'].to_s.match(/hostonly/)
  values
end

# Unconfigure a Virtual Box VM

def unconfigure_vbox_vm(values)
  values = check_vbox_is_installed(values)
  exists = check_vbox_vm_exists(values)
  if exists == false
    exists = check_vbox_vm_config_exists(values)
    if exists == true
      delete_vbox_vm_config(values)
    else
      warning_message(values, "VirtualBox VM #{values['name']} does not exist")
      return exists
    end
  end
  stop_vbox_vm(values)
  sleep(5)
  message = "Information:\tDeleting VirtualBox VM #{values['name']}"
  command = "#{shell_arg(values['vboxmanage'])} unregistervm #{shell_arg(values['name'])} --delete"
  execute_command(values, message, command)
  delete_vbox_vm_config(values)
  exists
end

# Check VirtualBox is installed, reporting the location and version of VBoxManage

def check_virtualbox(values)
  information_message(values, 'Checking VirtualBox is installed')
  vboxmanage = find_vboxmanage
  if vboxmanage.empty?
    warning_message(values, 'VirtualBox is not installed (VBoxManage not found on PATH)')
    install_virtualbox(values) if values['install-check'] == true
    vboxmanage = find_vboxmanage
    return nil if vboxmanage.empty?
  end
  # Read-only, so it runs under --dryrun too (execute_command would skip it as a VBoxManage call)
  version = `#{shell_arg(vboxmanage)} --version`.strip
  information_message(values, "VirtualBox #{version} is installed at #{vboxmanage}")
  if extension_pack_installed?(values, vboxmanage)
    information_message(values, 'VirtualBox Extension Pack is installed')
  else
    warning_message(values, 'VirtualBox Extension Pack is not installed')
    install_virtualbox_extension_pack(values, version) if values['install-check'] == true
  end
  nil
end

# Return true if the Oracle VM VirtualBox Extension Pack is listed by VBoxManage (read-only, so it runs under --dryrun)

def extension_pack_installed?(_values, vboxmanage)
  # VirtualBox has used both "Oracle VM VirtualBox Extension Pack" and "Oracle VirtualBox Extension Pack"
  `#{shell_arg(vboxmanage)} list extpacks`.match?(/Oracle (VM )?VirtualBox Extension Pack/)
end

# Install the VirtualBox Extension Pack matching the installed version.
# Installing it accepts the Oracle VM VirtualBox Extension Pack licence (PUEL) on the user's behalf.

def install_virtualbox_extension_pack(values, version)
  if values['dryrun'] == true
    information_message(values, 'Dry run: would install the VirtualBox Extension Pack (accepting its licence)')
    return nil
  end
  if File.exist?('/etc/debian_version')
    # Pre-accept the licence so apt does not stop to ask
    message = "Information:\tAccepting the VirtualBox Extension Pack licence"
    command = "echo 'virtualbox-ext-pack virtualbox-ext-pack/license select true' | debconf-set-selections"
    execute_command(values, message, command)
    install_linux_package(values, 'virtualbox-ext-pack')
  else
    install_extension_pack_download(values, version)
  end
  nil
end

# Download the extension pack for this version from virtualbox.org and install it with VBoxManage

def install_extension_pack_download(values, version)
  require 'open3'
  base_version = version.split('r').first.to_s
  url = "https://download.virtualbox.org/virtualbox/#{base_version}/Oracle_VirtualBox_Extension_Pack-#{base_version}.vbox-extpack"
  dir = Dir.mktmpdir('modest-extpack')
  # VBoxManage checks the pack's internal name against the file name, so keep the official file name
  file = File.join(dir, File.basename(url))
  information_message(values, "Downloading the VirtualBox Extension Pack from #{url}")
  unless system('curl', '-fsSL', '-o', file, url)
    warning_message(values, "Could not download #{url}. Install the Extension Pack manually from https://www.virtualbox.org/wiki/Downloads")
    return nil
  end
  vboxmanage = find_vboxmanage
  # Installing writes under /Library, so run VBoxManage with sudo unless this process is already root.
  # Run in the terminal (stdin and stdout are not captured) so the Oracle licence is shown and answered
  # by the user, and sudo can ask for a password.
  command = Process.euid.zero? ? [vboxmanage] : ['sudo', vboxmanage]
  information_message(values, 'Installing the VirtualBox Extension Pack: you will be shown its licence to accept, and sudo may ask for your password')
  system(*command, 'extpack', 'install', '--replace', file)
  status = $?
  warning_message(values, "Installing the VirtualBox Extension Pack failed (exit #{status.exitstatus})") unless status.success?
  nil
ensure
  FileUtils.rm_rf(dir) if dir
end

# Find VBoxManage on the PATH, or an empty string

def find_vboxmanage
  vboxmanage = which_program('VBoxManage')
  vboxmanage.empty? ? which_program('vboxmanage') : vboxmanage
end

# Install VirtualBox with the package manager for the host (used by --check virtualbox --install)

def install_virtualbox(values)
  case values['host-os-uname'].to_s
  when /Darwin/
    if which_program('brew').empty?
      warning_message(values, 'Cannot install VirtualBox: Homebrew (brew) is not installed')
      return nil
    end
    if values['dryrun'] == true
      information_message(values, 'Dry run: would install VirtualBox with Homebrew (brew install --cask virtualbox)')
      return nil
    end
    message = "Information:\tInstalling VirtualBox with Homebrew"
    command = 'brew install --cask virtualbox'
    execute_command(values, message, command)
  when /Linux/
    if values['dryrun'] == true
      information_message(values, 'Dry run: would install the virtualbox package with the system package manager')
      return nil
    end
    install_linux_package(values, 'virtualbox')
  else
    warning_message(values, "Cannot install VirtualBox automatically on #{values['host-os-uname']}")
  end
  nil
end
