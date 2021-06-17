# VMware Fusion support code

# Deploy Fusion VM

def deploy_fusion_vm(options)
  return
end

# Check VM Fusion Promisc Mode

def check_fusion_vm_promisc_mode(options)
	if options['osname'].to_s.match(/Darwin/)
	  promisc_file="/Library/Preferences/VMware Fusion/promiscAuthorized"
    if !File.exist?(promisc_file)
	    %x[sudo sh -c 'touch "/Library/Preferences/VMware Fusion/promiscAuthorized"']
	  end
	end
  return
end

# Set Fusion VM directory

def set_fusion_vm_dir(options)
  if options['osname'].to_s.match(/Linux/)
    options['fusiondir'] = options['home']+"/vmware"
  end
  if options['osname'].to_s.match(/Linux|Win/)
    options['vmapp'] = "VMware Workstation"
  else
    options['vmapp'] = "VMware Fusion"
  end
  return
end

# Add Fusion VM network

def add_fusion_vm_network(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    vm_list = get_running_fusion_vms(options)
    if !vm_list.to_s.match(/#{options['name']}/)
      fusion_vmx_file = get_fusion_vm_vmx_file(options)
      message = "Information:\tAdding network interface to "+options['name']
      command = "'#{options['vmrun']}' addNetworkAdapter '#{fusion_vmx_file}' #{options['vmnetwork']}"
      execute_command(options,message,command)
    else
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} is Running")
    end
  else
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} doesn't exist")
  end
  return
end

# Delete Fusion VM network

def delete_fusion_vm_network(options,install_interface)
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    vm_list = get_running_fusion_vms(options)
    if !vm_list.to_s.match(/#{options['name']}/)
      fusion_vmx_file = get_fusion_vm_vmx_file(options)
      if install_interface == options['empty']
        message = "Information:\tGetting network interface list for "+options['name']
        command = "'#{options['vmrun']}' listNetworkAdapters '#{fusion_vmx_file}' |grep ^Total |cut -f2 -d:"
        output  = execute_command(options,message,command)
        last_id = output.chomp.gsub(/\s+/,"")
        last_id = last_id.to_i
        if last_id == 0
          handle_output(options,"Warning:\tNo network interfaces found")
          return
        else
          last_id = last_id-1
          install_interface = last_id.to_s
        end
      end
      message = "Information:\tDeleting network interface from "+options['name']
      command = "'#{options['vmrun']}' deleteNetworkAdapter '#{fusion_vmx_file}' #{install_interface}"
      execute_command(options,message,command)
    else
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} is Running")
    end
  else
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} doesn't exist")
  end
  return
end

# Show Fusion VM network

def show_fusion_vm_network(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    fusion_vmx_file = get_fusion_vm_vmx_file(options)
    message = "Information:\tGetting network interface list for "+options['name']
    command = "'#{options['vmrun']}' listNetworkAdapters '#{fusion_vmx_file}'"
    output  = execute_command(options,message,command)
    handle_output(options,output)
  else
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} doesn't exist")
  end
  return
end

# Check Fusion VM status

def get_fusion_vm_status(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    vm_list = get_running_fusion_vms(options)
    if vm_list.to_s.match(/#{options['name']}/)
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} is Running")
    else
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} is Not Running")
    end
  else
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} doesn't exist")
  end
  return
end

# Get Fusion VM sreencap

def get_fusion_vm_screen(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    vm_list = get_running_fusion_vms(options)
    if vm_list.to_s.match(/#{options['name']}/)
      fusion_vmx_file = get_fusion_vm_vmx_file(options)
      screencap_file  = options['tmpdir']+"/"+options['name']+".png"
      message = "Information:\tCapturing screen of "+options['name']+" to "+screencap_file
      command = "'#{options['vmrun']}' captureScreen '#{fusion_vmx_file}' '#{screencap_file}''"
      execute_command(options,message,command)
    else
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} is Not Running")
    end
  else
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} doesn't exist")
  end
  return
end

# Check VMware Fusion VM is running

def check_fusion_vm_is_running(options)
  list_vms = get_running_fusion_vms(options)
  if list_vms.to_s.match(/#{options['name']}.vmx/)
    running = "yes"
  else
    running = "no"
  end
  return running
end

# Get VMware Fusion VM IP

def get_fusion_vm_ip(options)
  options['ip'] = ""
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    running = check_fusion_vm_is_running(options)
    if running.match(/yes/)
      fusion_vmx_file = get_fusion_vm_vmx_file(options)
      message    = "Information:\tDetermining IP for "+options['name']
      command    = "'#{options['vmrun']}' getGuestIPAddress '#{fusion_vmx_file}'"
      options['ip'] = execute_command(options,message,command)
    else
      handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} is not running")
    end
  else
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} doesn't exist")
  end
  return options['ip'].chomp
end

# Set Fusion dir

def set_fusion_dir(options)
  if not File.directory?(options['fusiondir'])
    options['fusiondir'] = options['home']+"/Virtual Machines.localized"
    if not File.directory?(options['fusiondir'])
      options['fusiondir'] = options['home']+"/Documents/Virtual Machines"
    end
  end
  return options
end

# Import Packer Fusion VM image

def import_packer_fusion_vm(options)
  (exists,images_dir) = check_packer_vm_image_exists(options)
  if exists.match(/no/)
    handle_output(options,"Warning:\tPacker #{options['vmapp']} VM image for #{options['name']} does not exist")
    quit(options)
  end
  fusion_vm_dir,fusion_vmx_file,fusion_disk_file = check_fusion_vm_doesnt_exist(options)
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking Fusion client directory")
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking Packer Fusion VM configuration directory")
  end
  check_dir_exists(options,fusion_vm_dir)
  uid = options['uid']
  check_dir_owner(options,fusion_vm_dir,uid)
  message = "Information:\tCopying Packer VM images from \""+images_dir+"\" to \""+fusion_vm_dir+"\""
  command = "cd '#{images_dir}' ; cp * '#{fusion_vm_dir}'"
  execute_command(options,message,command)
  return
end

# Migrate Fusion VM

def migrate_fusion_vm(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/no/)
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} does not exist")
    quit(options)
  end
  local_vmx_file   = get_fusion_vm_vmx_file(options)
  local_vmdk_file  = get_fusion_vm_vmdk_file(options)
  if not File.exist?(local_vmx_file) or not File.exist?(local_vmdk_file)
    handle_output(options,"Warning:\tVMware config or disk file for #{options['name']} does not exist")
    quit(options)
  end
  options['vmxfile']  = File.basename(local_vmx_file)
  options['vmxfile']  = "/vmfs/volumes/"+options['datastore']+"/"+options['name']+"/"+options['vmxfile']
  fixed_vmx_file   = local_vmx_file+".esx"
  create_fusion_vm_esx_file(options['name'],local_vmx_file,fixed_vmx_file)
  options['vmdkfile'] = File.basename(local_vmdk_file)
  remote_vmdk_dir  = "/vmfs/volumes/"+options['datastore']+"/"+options['name']
  options['vmdkfile'] = remote_vmdk_dir+"/"+options['vmdkfile']+".old"
  command = "mkdir "+remote_vmdk_dir
  execute_ssh_command(options,command)
  scp_file(options,fixed_vmx_file,options['vmxfile'])
  scp_file(options,local_vmdk_file,options['vmdkfile'])
  import_esx_disk(options)
  import_esx_vm(options)
  return
end

# Delete Fusion VM snapshot

def delete_fusion_vm_snapshot(options)
  clone_list = []
  if options['clone'].to_s.match(/\*/) or options['clone'].to_s.match(/all/)
    clone_list = get_fusion_vm_snapshots(options)
    clone_list = clone_list.split("\n")[1..-1]
  else
    clone_list[0] = options['clone']
  end
  clone_list.each do |clone|
    fusion_vmx_file = get_fusion_vm_vmx_file(options)
    message = "Information:\tDeleting snapshot "+clone+" for #{options['vmapp']} VM "+options['name']
    command = "'#{options['vmrun']}' -T fusion deleteSnapshot '#{fusion_vmx_file}' '#{clone}'"
    execute_command(options,message,command)
  end
  return
end

# Get a list of Fusion VM snapshots for a client

def get_fusion_vm_snapshots(options)
  fusion_vmx_file = get_fusion_vm_vmx_file(options)
  message = "Information:\tGetting a list of snapshots for #{options['vmapp']} VM "+options['name']
  command = "'#{options['vmrun']}' -T fusion listSnapshots '#{fusion_vmx_file}'"
  output  = execute_command(options,message,command)
  return output
end

# List all Fusion VM snapshots

def list_all_fusion_vm_snapshots(options)
  vm_list = get_available_fusion_vms(options)
  vm_list.each do |vmx_file|
    options['name'] = File.basename(vmx_file,".vmx")
    list_fusion_vm_snapshots(options)
  end
  return
end

# List Fusion VM snapshots

def list_fusion_vm_snapshots(options)
  snapshot_list = get_fusion_vm_snapshots(options)
  handle_output(snapshot_list)
  return
end


# Get a value from a Fusion VM vmx file

def get_fusion_vm_vmx_file_value(options)
  vm_value  = ""
  vmx_file  = get_fusion_vm_vmx_file(options)
  if File.exist?(vmx_file)
    if File.readable?(vmx_file)
      vm_config = ParseConfig.new(vmx_file)
      vm_value  = vm_config[options['search']]
    else
      vm_value = "File Not Readable"
    end
  else
    if options['verbose'] == true
      handle_output(options,"Warning:\tWMware configuration file \"#{vmx_file}\" not found for client")
    end
  end
  return vm_value
end

# Get Fusion VM OS

def get_fusion_vm_os(options)
  options['search']  = "guestOS"
  options['os-type'] = get_fusion_vm_vmx_file_value(options)
  if not options['os-type']
    options['search'] = "guestos"
    options['os-type']     = get_fusion_vm_vmx_file_value(options)
  end
  if not options['os-type']
    options['os-type'] = "Unknown"
  end
  return options['os-type']
end

# List all Fusion VMs

def list_all_fusion_vms(options)
  options['search'] = "all"
  list_fusion_vms(options)
  return
end

# List available VMware Fusion VMs

def list_fusion_vms(options)
  search_string = options['search']
  file_list   = Dir.entries(options['fusiondir'])
  if search_string == "all"
    type_string = options['vmapp']
  else
    type_string = search_string.capitalize+" "+options['vmapp']
  end
  if file_list.length > 0
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
    file_list.each do |entry|
      if entry.match(/[a-z]|[A-Z]/)
        vm_name = entry.gsub(/\.vmwarevm/,"")
        options['name'] = vm_name
        vm_mac  = get_fusion_vm_mac(options)
        vm_os   = get_fusion_vm_os(options)
        if search_string == "all" || entry.match(/#{search_string}/) || options['os-type'].to_s.match(/#{search_string}/)
          if options['output'].to_s.match(/html/)
            handle_output(options,"<tr>")
            handle_output(options,"<td>#{vm_name}</td>")
            handle_output(options,"<td>#{vm_os}</td>")
            handle_output(options,"<td>#{vm_mac}</td>")
            handle_output(options,"</tr>")
          else
            output = vm_name+" os="+vm_os+" mac="+vm_mac
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

# Get Fusion VM vmx file location

def get_fusion_vm_vmx_file(options)
  vm_list = get_running_fusion_vms(options)
  if vm_list.to_s.match(/#{options['name']}\.vmx/)
    fusion_vmx_file = vm_list.grep(/#{options['name']}\.vmx/)[0].chomp
  else
    if options['osname'].to_s.match(/Linux/)
      fusion_vm_dir = options['fusiondir']+"/"+options['name']
    else
      fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
    end
    if File.directory?(fusion_vm_dir)
      fusion_vmx_file  = Dir.entries(fusion_vm_dir).grep(/vmx$/)[0].chomp
    else
      fusion_vmx_file = ""
    end
    fusion_vmx_file = fusion_vm_dir+"/"+fusion_vmx_file
  end
  return fusion_vmx_file
end

# Show Fusion VM config

def show_fusion_vm_config(options)
  fusion_vmx_file = ""
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    fusion_vmx_file = get_fusion_vm_vmx_file(options)
    if File.exist?(fusion_vmx_file)
      print_contents_of_file(options,"#{options['vmapp']} configuration",fusion_vmx_file)
    end
  end
  return
end

# Set Fusion VM value

def set_fusion_value(options)
  exists = check_fusion_vm_exists(options)
  fusion_vmx_file = get_fusion_vm_vmx_file(options)
  if exists.match(/yes/)
    message = "Information:\tSetting Parameter "+options['param']+" for "+options['name']+" to "+options['value']
    command = "'#{options['vmrun']}' writeVariable '#{fusion_vmx_file}' runtimeConfig '#{options['param']}' '#{options['value']}'"
    execute_command(options,message,command)
  else
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} does not exist")
    quit(options)
  end
  return
end

# Set Fusion VM value

def get_fusion_value(options)
  exists = check_fusion_vm_exists(options)
  fusion_vmx_file = get_fusion_vm_vmx_file(options)
  if exists.match(/yes/)
    message = "Information:\tGetting Parameter "+options['param']+" for "+options['name']
    command = "'#{options['vmrun']}' readVariable '#{fusion_vmx_file}' runtimeConfig '#{options['param']}'"
    output  = execute_command(options,message,command)
    handle_output(options,output)
  else
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} does not exist")
    quit(options)
  end
  return
end

# Get Fusion VM vmdk file location

def get_fusion_vm_vmdk_file(options)
  if options['osname'].to_s.match(/Linux/)
    fusion_vm_dir = options['fusiondir']+"/"+options['name']
  else
    fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
  end
  if File.directory?(fusion_vm_dir)
    fusion_vmdk_file = Dir.entries(fusion_vm_dir).grep(/vmdk$/)[0].chomp
  else
    fusion_vmdk_file = ""
  end
  fusion_vmdk_file = fusion_vm_dir+"/"+fusion_vmdk_file
  return fusion_vmdk_file
end

# Snapshot Fusion VM

def snapshot_fusion_vm(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/no/)
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} does not exist")
    quit(options)
  end
  fusion_vmx_file = get_fusion_vm_vmx_file(options)
  message = "Information:\tCloning #{options['vmapp']} VM "+options['name']+" to "+options['clone']
  command = "'#{options['vmrun']}' -T fusion snapshot '#{fusion_vmx_file}' '#{options['clone']}'"
  execute_command(options,message,command)
  return
end

# Get VMware version

def get_fusion_version(options)
  hw_version = "12"
  message    = "Determining:\tVMware Version"
  if options['osname'].to_s.match(/Linux/)
    command = "vmware --version"
  else
    command = "defaults read \"/Applications/VMware Fusion.app/Contents/Info.plist\" CFBundleShortVersionString"
  end
  vf_version = execute_command(options,message,command)
  vf_version = vf_version.chomp
  vf_dotver  = vf_version.split(".")[1]
  vf_version = vf_version.split(".")[0]
  vf_version = vf_version.to_i
  vf_dotver  = vf_dotver.to_i
  if vf_version > 6
    if vf_version > 7
      if vf_version >= 8
        if vf_version >= 10
          if vf_version >= 11
            if vf_dotver >= 1
              hw_version = "18"
            else
              hw_version = "16"
            end
          else
            hw_version = "14"
          end
        else
          hw_version = "12"
        end
      else
        hw_version = "11"
      end
    end
  else
    hw_version = "10"
  end
  return hw_version
end

# Get/set vmrun path

def set_vmrun_bin(options)
  if options['osname'].to_s.match(/Darwin/)
    if options['techpreview'] == true
      if File.directory?("/Applications/VMware Fusion Tech Preview.app")
        options['vmrun'] = "/Applications/VMware Fusion Tech Preview.app/Contents/Library/vmrun"
        options['vmbin'] = "/Applications/VMware Fusion Tech Preview.app/Contents/MacOS/VMware Fusion"
        options['vmapp'] = "VMware Fusion Tech Preview"
      end
    else
      if File.directory?("/Applications/VMware Fusion Tech Preview.app")
        options['vmrun'] = "/Applications/VMware Fusion Tech Preview.app/Contents/Library/vmrun"
        options['vmbin'] = "/Applications/VMware Fusion Tech Preview.app/Contents/MacOS/VMware Fusion"
        options['vmapp'] = "VMware Fusion Tech Preview"
      else
        if File.directory?("/Applications/VMware Fusion.app")
          options['vmrun'] = "/Applications/VMware Fusion.app/Contents/Library/vmrun"
          options['vmbin'] = "/Applications/VMware Fusion.app/Contents/MacOS/VMware Fusion"
          options['vmapp'] = "VMware Fusion"
        end
      end
    end
  else
    options['vmrun'] = "vmrun"
    options['vmbin'] = "vmware"
    options['vmapp'] = "VMware Workstation"
  end
  if options['vmrun']
    if not File.exist?(options['vmrun'])
      if options['verbose'] == true
        handle_output(options,"Warning:\tCould not find vmrun")
      end
    end
  end
  return options
end

# Get/set ovftool path

def set_ovfbin(options)
  if options['osname'].to_s.match(/Darwin/)
    options['ovfbin'] = "/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool"
  else
    options['ovfbin'] = "/usr/bin/ovftool"
  end
  if not File.exist?(options['ovfbin'])
    handle_output(options,"Warning:\tCould not find ovftool")
    quit(options)
  end
  return
end

# Get list of running vms

def get_running_fusion_vms(options)
  vm_list = %x['#{options['vmrun']}' list |grep vmx].split("\n")
  return vm_list
end

# List running VMs

def list_running_fusion_vms(options)
  vm_list = get_running_fusion_vms(options)
  handle_output(options,"")
  handle_output(options,"Running VMs:")
  handle_output(options,"")
  vm_list.each do |vm_name|
    vm_name = File.basename(vm_name,".vmx")
    handle_output(vm_name)
  end
  handle_output(options,"")
  return
end

# Export OVA

def export_fusion_ova(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    stop_fusion_vm(options)
    if not options['file'].to_s.match(/[0-9,a-z,A-Z]/)
      options['file'] = "/tmp/"+options['name']+".ova"
      handle_output(options,"Warning:\tNo ouput file given")
      handle_output(options,"Information:\tExporting VM #{options['name']} to #{options['file']}")
    end
    if not options['file'].to_s.match(/\.ova$/)
      options['file'] = options['file']+".ova"
    end
    message = "Information:\tExporting #{options['vmapp']} VM "+options['name']+" to "+fusion_vmx_file
    command = "\"#{options['ovfbin']}\" --acceptAllEulas --name = \"#{options['name']}\" \"#{fusion_vmx_file}\" \"#{options['file']}\""
    execute_command(options,message,command)
  else
    message = "Information:\tExporting #{options['vmapp']} VM "+options['name']+" to "+fusion_vmx_file
    command = "\"#{options['ovfbin']}\" --acceptAllEulas --name = \"#{options['name']}\" \"#{fusion_vmx_file}\" \"#{options['file']}\""
    execute_command(options,message,command)
  end
  return
end

# Import vmdk

def import_fusion_vmdk(options)
  options['ip'] = single_install_ip(options)
  create_vm(options)
end

# Import OVA

def import_fusion_ova(options)
  options['ip'] = single_install_ip(options)
  set_ovfbin(options)
  if options['osname'].to_s.match(/Linux/)
    fusion_vm_dir = options['fusiondir']+"/"+options['name']
  else
    fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
  end
  fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
  if not File.exist?(fusion_vmx_file)
    handle_output(options,"Warning:\tWMware configuration file for client does not exist")
  end
  exists = check_fusion_vm_exists(options)
  if exists.match(/no/)
    if not options['file'].to_s.match(/\//)
      options['file'] = options['isodir']+"/"+options['file']
    end
    if File.exist?(options['file'])
      if options['name'].to_s.match(/[0-9,a-z,A-Z]/)
        if not File.directory?(fusion_vm_dir)
          Dir.mkdir(fusion_vm_dir)
        end
        message = "Information:\tImporting #{options['vmapp']} VM "+options['name']+" from "+fusion_vmx_file
        command = "\"#{options['ovfbin']}\" --acceptAllEulas --name = \"#{options['name']}\" \"#{options['file']}\" \"#{fusion_vmx_file}\""
        execute_command(options,message,command)
      else
        options['name'] = %x['#{options['ovfbin']}" "#{options['file']}" |grep Name |tail -1 |cut -f2 -d:].chomp
        options['name'] = options['name'].gsub(/\s+/,"")
        fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
        if not options['name'].to_s.match(/[0-9,a-z,A-Z]/)
          handle_output(options,"Warning:\tCould not determine VM name for Virtual Appliance #{options['file']}")
          quit(options)
        else
          options['name'] = options['name'].split(/Suggested VM name /)[1].chomp
          if not File.directory?(fusion_vm_dir)
            Dir.mkdir(fusion_vm_dir)
          end
          message = "Information:\tImporting #{options['vmapp']} VM "+options['name']+" from "+fusion_vmx_file
          command = "\"#{options['ovfbin']}\" --acceptAllEulas --name = \"#{options['name']}\" \"#{options['file']}\" \"#{fusion_vmx_file}\""
          execute_command(options,message,command)
        end
      end
    else
      handle_output(options,"Warning:\tVirtual Appliance #{options['file']} does not exist")
    end
  else
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} does not exist")
  end
  if options['ip'].to_s.match(/[0-9]/)
    add_hosts_entry(options['name'],options['ip'])
  end
  if options['mac'].to_s.match(/[0-9]|[A-F]|[a-f]/)
    change_fusion_vm_mac(options['name'],options['mac'])
  else
    options['mac'] = get_fusion_vm_mac(options)
    if not options['mac']
      options['vm']  = "fusion"
      options['mac'] = generate_mac_address(options['vm'])
    end
  end
  change_fusion_vm_network(options['name'],options['vmnet'])
  handle_output(options,"Information:\tVirtual Appliance #{options['file']} imported with VM name #{options['name']} and MAC address #{options['mac']}")
  return
end

# List Solaris ESX VirtualBox VMs

def list_vs_fusion_vms(options)
  options['search'] = "vmware"
  list_fusion_vms(search_string)
  return
end

# List Linux KS VMware Fusion VMs

def list_ks_fusion_vms(options)
  options['search'] = "rhel|centos|oel"
  list_fusion_vms(search_string)
  return
end

# List Linux Preseed VMware Fusion VMs

def list_ps_fusion_vms(options)
  options['search'] = "ubuntu"
  list_fusion_vms(search_string)
  return
end

# List Linux AutoYast VMware Fusion VMs

def list_ay_fusion_vms(options)
  options['search'] = "sles|suse"
  list_fusion_vms(search_string)
  return
end

# List Solaris Kickstart VMware Fusion VMs

def list_js_fusion_vms(options)
  options['search'] = "solaris"
  list_fusion_vms(search_string)
  return
end

# List Solaris AI VMware Fusion VMs

def list_ai_fusion_vms(options)
  options['search'] = "solaris"
  list_fusion_vms(search_string)
  return
end

# Check Fusion VM MAC address

def check_fusion_vm_mac(options)
  if options['mac'].gsub(/:/,"").match(/^08/)
    handle_output(options,"Warning:\tInvalid MAC address: #{options['mac']}")
    options['vm']  = "fusion"
    options['mac'] = generate_mac_address(options['vm'])
    handle_output(options,"Information:\tGenerated new MAC address: #{options['mac']}")
  end
  return options['mac']
end

# Get Fusion VM MAC address

def get_fusion_vm_mac(options)
  options['mac']    = ""
  options['search'] = "ethernet0.address"
  options['mac']    = get_fusion_vm_vmx_file_value(options)
  if not options['mac']
    options['search'] = "ethernet0.generatedAddress"
    options['mac']    = get_fusion_vm_vmx_file_value(options)
  end
  return options['mac']
end

# Change VMware Fusion VM MAC address

def change_fusion_vm_mac(options)
  (fusion_vm_dir,fusion_vmx_file,fusion_disk_file) = check_fusion_vm_doesnt_exist(options)
  if not File.exist?(fusion_vmx_file)
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} does not exist ")
    quit(options)
  end
  copy=[]
  file=IO.readlines(fusion_vmx_file)
  file.each do |line|
    if line.match(/generatedAddress/)
      copy.push("ethernet0.address = \""+options['mac']+"\"\n")
    else
      if line.match(/ethernet0\.address/)
        copy.push("ethernet0.address = \""+options['mac']+"\"\n")
      else
        copy.push(line)
      end
    end
  end
  File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
  return
end

# Change VMware Fusion VM CDROM

def attach_file_to_fusion_vm(options)
  if options['osname'].to_s.match(/Linux/)
    fusion_vm_dir = options['fusiondir']+"/"+options['name']
  else
    fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
  end
  fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
  if not File.exist?(fusion_vmx_file)
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} does not exist ")
    quit(options)
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tAttaching file #{options['file']} to #{options['name']}")
    handle_output(options,"Information:\tModifying file \"#{fusion_vmx_file}\"")
  end
  copy=[]
  file=IO.readlines(fusion_vmx_file)
  file.each do |line|
    (item,value) = line.split(/\=/)
    item = item.gsub(/\s+/,"")
    case item
    when /ide0:0.deviceType|ide0:0.startConnected/
      copy.push("ide0:0.deviceType = cdrom-image\n")
    when /ide0:0.filename|ide0:0.autodetect/
      copy.push("ide0:0.filename = #{options['file']}\n")
    else
      copy.push(line)
    end
  end
  File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
  return
end

# Detach VMware Fusion VM CDROM

def detach_file_from_fusion_vm(options)
  if options['verbose'] == true
    handle_output(options,"Information:\tDetaching CDROM from #{options['name']}")
  end
  if options['osname'].to_s.match(/Linux/)
    fusion_vm_dir = options['fusiondir']+"/"+options['name']
  else
    fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
  end
  fusion_vmx_file  = fusion_vm_dir+"/"+options['name']+".vmx"
  copy=[]
  file=IO.readlines(fusion_vmx_file)
  file.each do |line|
    (item,value) = line.split(/\=/)
    item = item.gsub(/\s+/,"")
    case item
    when "ide0:0.deviceType"
      copy.push("ide0:0.startConnected = TRUE\n")
    when "ide0:0.filename"
      copy.push("\n")
    else
      copy.push(line)
    end
  end
  File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
  return
end

# Check Fusion hostonly networking

def check_fusion_hostonly_network(options,if_name)
  case options['osname']
  when /Darwin/
    config_file = "/Library/Preferences/VMware Fusion/networking"
  when /Linux/
    config_file = "/etc/vmware/locations"
  when /NT/
    config_file = "/cygdrive/c/ProgramData/VMware/vmnetdhcp.conf"
  end 
  network_address = options['hostonlyip'].split(/\./)[0..2].join(".")+".0"
  gw_if_name      = get_gw_if_name(options)
  dhcp_test  = 0
  vmnet_test = 0
  copy = []
  file = IO.readlines(config_file)
  if options['osname'].to_s.match(/Darwin/)
    file.each do |line|
      case line
      when /answer VNET_1_DHCP /
        if not line.match(/no/)
          dhcp_test = 1
          copy.push("answer VNET_1_DHCP no")
        else
          copy.push(line)
        end
      when /answer VNET_1_HOSTONLY_SUBNET/
        if not line.match(/#{network_address}/)
          dhcp_test = 1
          copy.push("answer VNET_1_HOSTONLY_SUBNET #{network_address}")
        else
          copy.push(line)
        end
      else
        copy.push(line)
      end
    end
  end
  message = "Information:\tChecking vmnet interfaces are plumbed"
  if options['osname'].to_s.match(/NT/)
    command = "ipconfig /all |grep -i "+options['vmnet'].to_s
  else
    command = "ifconfig -a |grep -i "+options['vmnet'].to_s
  end
  output  = execute_command(options,message,command)
  if not output.match(/#{options['vmnet'].to_s}/)
    vmnet_test = 1
  end
  if dhcp_test == 1 || vmnet_test == 1 && options['osname'].to_s.match(/Darwin/)
    message = "Information:\tStarting "+options['vmapp']
    if options['osname'].to_s.match(/Darwin/)
      vmnet_cli = "/Applications/"+options['vmapp'].to_s+".app/Contents/Library/vmnet-cli"
      command   = "cd /Applications ; open \"#{options['vmapp'].to_s}.app\""
    else
      command   = "#{options['vmapp']} &"
      vmnet_cli = "vmnetcfg"
    end
    execute_command(options,message,command)
    sleep 3
    temp_file = "/tmp/networking"
    File.open(temp_file,"w") {|file_data| file_data.puts copy}
    message = "Information:\tConfiguring host only network on #{if_name} for network #{network_address}"
    command = "cp #{temp_file} \"#{config_file}\""
    if options['osname'].to_s.match(/Darwin/) && options['osversion'].to_s.match(/^11/)
      %x[sudo sh -c '#{command}']
    else
      execute_command(options,message,command)
    end
    message = "Information:\tConfiguring VMware network"
    command = "\"#{vmnet_cli}\" --configure"
    if options['osname'].to_s.match(/Darwin/) && options['osversion'].to_s.match(/^11/)
      %x[sudo sh -c '#{command}']
    else
      execute_command(options,message,command)
    end
    message = "Information:\tStopping VMware network"
    command = "\"#{vmnet_cli}\" --stop"
    if options['osname'].to_s.match(/Darwin/) && options['osversion'].to_s.match(/^11/)
      %x[sudo sh -c '#{command}']
    else
      execute_command(options,message,command)
    end
    message = "Information:\tStarting VMware network"
    command = "\"#{vmnet_cli}\" --start"
    if options['osname'].to_s.match(/Darwin/) && options['osversion'].to_s.match(/^11/)
      %x[sudo sh -c '#{command}']
    else
      execute_command(options,message,command)
    end
  end
  if options['osname'].to_s.match(/NT/)
    if_name = "VMware Network Adapter VMnet1"
    output  = get_win_ip_from_if_name(if_name)
  else
    message = "Information:\tChecking vmnet interface address"
    command = "ifconfig "+options['vmnet'].to_s+" |grep inet"
    output  = execute_command(options,message,command)
  end
  hostonly_ip = output.chomp.split(" ")[1]
  if hostonly_ip != options['hostonlyip']
    message = "Information:\tSetting "+options['vmnet'].to_s+" address to "+options['hostonlyip']
    if options['osname'].to_s.match(/NT/)
      command = "netsh interface ip set address {if_name} static #{options['hostonlyip']} #{options['netmask']}"
    else
      command = "ifconfig "+options['vmnet'].to_s+" inet #{options['hostonlyip']} up"
    end
    execute_command(options,message,command)
  end
  case options['osname']
  when /Darwin/
    if options['osrelease'].split(".")[0].to_i < 14
      check_osx_nat(gw_if_name,if_name)
    else
      check_osx_pfctl(options,gw_if_name,if_name)
    end
  when /Linux/
    check_linux_nat(options,gw_if_name,if_name)
  end
  return
end

# Change VMware Fusion VM network type

def change_fusion_vm_network(options,client_network)
  if options['osname'].to_s.match(/Linux/)
    fusion_vm_dir = options['fusiondir']+"/"+options['name']
  else
    fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
  end
  fusion_vmx_file  = fusion_vm_dir+"/"+options['name']+".vmx"
  test = 0
  copy = []
  file = IO.readlines(fusion_vmx_file)
  file.each do |line|
    if line.match(/ethernet0\.connectionType/)
      if not line.match(/#{client_network}/)
        test = 1
        copy.push("ethernet0.connectionType = \""+client_network+"\"\n")
      else
        copy.push(line)
      end
    else
      copy.push(line)
    end
  end
  if test == 1
    File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
  end
  return
end

# Boot VMware Fusion VM

def boot_fusion_vm(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    if options['osname'].to_s.match(/Linux/)
      fusion_vm_dir = options['fusiondir']+"/"+options['name']
    else
      fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
    end
    fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
    message         = "Starting:\tVM "+options['name']
    if options['text'] == true or options['headless'] == true or options['serial'] == true
      command = "\"#{options['vmrun']}\" -T fusion start \"#{fusion_vmx_file}\" nogui &"
    else
      command = "\"#{options['vmrun']}\" -T fusion start \"#{fusion_vmx_file}\" &"
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
    handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} does not exist")
  end
  return
end

# Add share to VMware Fusion VM

def add_shared_folder_to_fusion_vm(options)
  vm_list = get_running_fusion_vms(options)
  if vm_list.to_s.match(/#{options['name']}/)
    if options['osname'].to_s.match(/Linux/)
      fusion_vm_dir = options['fusiondir']+"/"+options['name']
    else
      fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
    end
    fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
    message = "Stopping:\tVirtual Box VM "+options['name']
    command = "'#{options['vmrun']}' -T fusion addSharedFolder '#{fusion_vmx_file}' #{options['mount']} #{options['share']}"
    execute_command(options,message,command)
  else
    if options['verbose'] == true
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} not running")
    end
  end
  return
end

# Stop VMware Fusion VM

def halt_fusion_vm(options)
  stop_fusion_vm(options)
end

def stop_fusion_vm(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    if options['osname'].to_s.match(/Linux/)
      fusion_vm_dir = options['fusiondir']+"/"+options['name']
    else
      fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
    end
    fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
    message = "Stopping:\tVirtual Box VM "+options['name']
    command = "\"#{options['vmrun']}\" -T fusion stop \"#{fusion_vmx_file}\""
    execute_command(options,message,command)
  else
    fusion_vms = get_running_fusion_vms(options)
    fusion_vms.each do |fusion_vmx_file|
      fusion_vmx_file = fusion_vmx_file.chomp
      fusion_vm       = File.basename(fusion_vmx_file,".vmx")
      if fusion_vm == options['name']
        message = "Stopping:\tVirtual Box VM "+options['name']
        command = "\"#{options['vmrun']}\" -T fusion stop \"#{fusion_vmx_file}\""
        execute_command(options,message,command)
        return
      end
    end
    if options['verbose'] == true
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} not running")
    end
  end
  return
end

# Reset VMware Fusion VM

def reboot_fusion_vm(options)
  reset_fusion_vm(options)
end

def reset_fusion_vm(options)
  vm_list = get_running_fusion_vms(options)
  if vm_list.to_s.match(/#{options['name']}/)
    if options['osname'].to_s.match(/Linux/)
      fusion_vm_dir = options['fusiondir']+"/"+options['name']
    else
      fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
    end
    fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
    message = "Stopping:\tVirtual Box VM "+options['name']
    command = "'#{options['vmrun']}' -T fusion reset '#{fusion_vmx_file}'"
    execute_command(options,message,command)
  else
    if options['verbose'] == true
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} not running")
    end
  end
  return
end

# Suspend VMware Fusion VM

def suspend_fusion_vm(options)
  vm_list = get_running_fusion_vms(options)
  if vm_list.to_s.match(/#{options['name']}/)
    if options['osname'].to_s.match(/Linux/)
      fusion_vm_dir = options['fusiondir']+"/"+options['name']
    else
      fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
    end
    fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
    message = "Stopping:\tVirtual Box VM "+options['name']
    command = "'#{options['vmrun']}' -T fusion suspend '#{fusion_vmx_file}'"
    execute_command(options,message,command)
  else
    if options['verbose'] == true
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} not running")
    end
  end
  return
end

# Create VMware Fusion VM disk

def create_fusion_vm_disk(options,fusion_vm_dir,fusion_disk_file)
  if File.exist?(fusion_disk_file)
    handle_output(options,"Warning:\t#{options['vmapp']} VM disk '#{fusion_disk_file}' already exists for #{options['name']}")
    quit(options)
  end
  check_dir_exists(options,fusion_vm_dir)
  if options['osname'].to_s.match(/Darwin/)
    vdisk_bin = "/Applications/VMware Fusion.app/Contents/Library/vmware-vdiskmanager"
  else
    vdisk_bin = "/usr/bin/vmware-vdiskmanager"
  end
  message = "Creating \t#{options['vmapp']} disk '"+fusion_disk_file+"' for "+options['name']
  command = "cd \"#{fusion_vm_dir}\" ; \"#{vdisk_bin}\" -c -s \"#{options['size']}\" -a LsiLogic -t 0 \"#{fusion_disk_file}\""
  execute_command(options,message,command)
  return
end


# Check VMware Fusion VM exists

def check_fusion_vm_exists(options)
  set_vmrun_bin(options)
  if options['osname'].to_s.match(/Linux/)
    fusion_vm_dir = options['fusiondir']+"/"+options['name']
  else
    fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
  end
  fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
  if not File.exist?(fusion_vmx_file)
    if options['verbose'] == true
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} does not exist")
    end
    exists = "no"
  else
    if options['verbose'] == true
      handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} exists")
    end
    exists = "yes"
  end
  return exists
end

# Check VMware Fusion VM doesn't exist

def check_fusion_vm_doesnt_exist(options)
  if options['osname'].to_s.match(/Linux/)
    fusion_vm_dir = options['fusiondir']+"/"+options['name']
  else
    fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
  end
  fusion_vmx_file  = fusion_vm_dir+"/"+options['name']+".vmx"
  fusion_disk_file = fusion_vm_dir+"/"+options['name']+".vmdk"
  if File.exist?(fusion_vmx_file)
    handle_output(options,"Information:\t#{options['vmapp']} VM #{options['name']} already exists")
    quit(options)
  end
  return fusion_vm_dir,fusion_vmx_file,fusion_disk_file
end

# Get a list of available VMware Fusion VMs

def get_available_fusion_vms(options)
  vm_list = []
  if File.directory?(options['fusiondir']) or File.symlink?(options['fusiondir'])
    vm_list = %x[find "#{options['fusiondir']}/" -name "*.vmx'].split("\n")
  end
  return vm_list
end

# Get VMware Fusion Guest OS name

def get_fusion_guest_os(options)
  case options['method']
  when /ai/
    guest_os = get_ai_fusion_guest_os(options)
  when /js/
    guest_os = get_js_fusion_guest_os(options)
  when /ay/
    guest_os = get_ay_fusion_guest_os(options)
  when /nb/
    guest_os = get_nb_fusion_guest_os(options)
  when /ob/
    guest_os = get_ob_fusion_guest_os(options)
  when /ps/
    guest_os = get_ps_fusion_guest_os(options)
  when /pe/
    guest_os = get_pe_fusion_guest_os(options)
  when /ks/
    guest_os = get_ks_fusion_guest_os(options)
  when /vs/
    guest_os = get_vs_fusion_guest_os(options)
  else
    guest_os = get_other_fusion_guest_os(options)
  end
  return guest_os
end

# Get VMware Fusion Guest OS name

def get_ai_fusion_guest_os(options)
  guest_os = "solaris10-64"
  return guest_os
end

# Configure a AI VMware Fusion VM

def configure_ai_fusion_vm(options)
  options['os-type'] = get_ai_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Get VMware Fusion Guest OS name

def get_js_fusion_guest_os(options)
  options['os-type'] = "solaris10-64"
  return options['os-type']
end

# Configure a Jumpstart VMware Fusion VM

def configure_js_fusion_vm(options)
  options['os-type'] = get_js_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Get VMware Fusion Guest OS name

def get_ay_fusion_guest_os(options)
  guest_os = "sles11"
  if not options['arch'].to_s.match(/i386/) and not options['arch'].to_s.match(/64/)
    guest_os = guest_os+"-64"
  end
  return guest_os
end

# configure an AutoYast (Suse) VMware Fusion VM

def configure_ay_fusion_vm(options)
  options['os-type'] = get_ay_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Get VMware Fusion Guest OS name

def get_nb_fusion_guest_os(options)
  guest_os = "freebsd"
  if not options['arch'].to_s.match(/i386/) and not options['arch'].to_s.match(/64/)
    guest_os = guest_os+"-64"
  end
  return guest_os
end

# Configure a NetBSB VMware Fusion VM

def configure_nb_fusion_vm(options)
  options['os-type'] = get_nb_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Get VMware Fusion Guest OS name

def get_ob_fusion_guest_os(options)
  guest_os = "otherlinux-64"
  return guest_os
end

# Configure an OpenBSD VMware Fusion VM

def configure_ob_fusion_vm(options)
  options['os-type'] = get_ob_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Get VMware Fusion Guest OS name

def get_ps_fusion_guest_os(options)
  guest_os = "ubuntu"
  if not options['arch'].to_s.match(/i386/) and not options['arch'].to_s.match(/64/)
    guest_os = guest_os+"-64"
  end
  return guest_os
end

# Configure an Ubuntu VMware Fusion VM

def configure_ps_fusion_vm(options)
  options['os-type'] = get_ps_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Get VMware Fusion Guest OS name

def get_pe_fusion_guest_os(options)
  guest_os  = "windows7srv-64"
  return guest_os
end

# Configure a Windows VMware Fusion VM

def configure_pe_fusion_vm(options)
  options['os-type'] = get_pe_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Get VMware Fusion Guest OS name

def get_other_fusion_guest_os(options)
  guest_os = "otherguest"
  return guest_os
end

# Configure another VMware Fusion VM

def configure_other_fusion_vm(options)
  options['os-type'] = get_other_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Get VMware Fusion Guest OS name

def get_ks_fusion_guest_os(options)
  guest_os = "rhel6"
  if options['arch'].to_s.match(/64/)
    guest_os = guest_os+"-64"
  else
    if !options['arch'].to_s.match(/i386/) && !options['arch'].to_s.match(/64/)
      guest_os = guest_os+"-64"
    end
  end
  return guest_os
end

# Configure a Kickstart VMware Fusion VM

def configure_ks_fusion_vm(options)
  options['os-type'] = get_ks_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Get VMware Fusion Guest OS name

def get_vs_fusion_guest_os(options)
  options['os-type'] = "vmkernel5"
  return options['os-type']
end

# Configure a ESX VMware Fusion VM

def configure_vs_fusion_vm(options)
  options['os-type'] = get_vs_fusion_guest_os(options)
  configure_fusion_vm(options)
  return
end

# Check VMware Fusion is installed

def check_fusion_is_installed(options)
  if options['osname'].to_s.match(/Darwin/)
    options['vmapp'] = "VMware Fusion"
    app_dir = "/Applications/VMware Fusion.app"
    if !File.directory?(app_dir)
      app_dir = "/Applications/VMware Fusion Tech Preview.app"
      if !File.directory?(app_dir)
        handle_output(options,"Warning:\tVMware Fusion not installed")
        quit(options)
      end
    end
  else
    options['vmapp'] = "VMware Workstation"
    options['vmrun'] = %x[which vmrun].chomp
    if !options['vmrun'].to_s.match(/vmrun/) && !options['vmrun'].to_s.match(/no vmrun/)
      handle_output(options,"Warning:\t#{options['vmapp']} not installed")
      quit(options)
    end
  end
  return options
end

# check VMware Fusion NAT

def check_fusion_natd(options,if_name)
  if options['vmnetwork'].to_s.match(/hostonly/)
    check_fusion_hostonly_network(options,if_name)
  end
  return options
end

# Unconfigure a VMware Fusion VM

def unconfigure_fusion_vm(options)
  stop_fusion_vm(options)
  exists = check_fusion_vm_exists(options)
  if exists.match(/yes/)
    stop_fusion_vm(options)
    if options['osname'].to_s.match(/Linux/)
      fusion_vm_dir = options['fusiondir']+"/"+options['name']
    else
      fusion_vm_dir = options['fusiondir']+"/"+options['name']+".vmwarevm"
    end
    fusion_vmx_file = fusion_vm_dir+"/"+options['name']+".vmx"
    message         = "Deleting:\t#{options['vmapp']} VM "+options['name']
    command         = "'#{options['vmrun']}' -T fusion deleteVM '#{fusion_vmx_file}'"
    execute_command(options,message,command)
    vm_dir   = options['name']+".vmwarevm"
    message  = "Removing:\t#{options['vmapp']} VM "+options['name']+" directory"
    command  = "cd \"#{options['fusiondir']}\" ; rm -rf \"#{vm_dir}\""
    execute_command(options,message,command)
  else
    if options['verbose'] == true
      handle_output(options,"Warning:\t#{options['vmapp']} VM #{options['name']} does not exist")
    end
  end
  return
end

# Create VMware Fusion VM vmx file

def create_fusion_vm_vmx_file(options,fusion_vmx_file)
  if options['os-type'] == options['empty']
    options['os-type'] = get_fusion_guest_os(options)
  end
  vmx_info = populate_fusion_vm_vmx_info(options)
  if not fusion_vmx_file.match(/\/packer\//)
    fusion_vm_dir,fusion_vmx_file,fusion_disk_file = check_fusion_vm_doesnt_exist(options)
  else
    fusion_vm_dir = File.dirname(fusion_vmx_file)
  end
  file = File.open(fusion_vmx_file,"w")
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking Fusion VMX configuration directory")
  end
  check_dir_exists(options,fusion_vm_dir)
  uid = options['uid']
  check_dir_owner(options,fusion_vm_dir,uid)
  vmx_info.each do |vmx_line|
    (vmx_param,vmx_value) = vmx_line.split(/\,/)
    if not vmx_value
      vmx_value = ""
    end
    output = vmx_param+" = \""+vmx_value+"\"\n"
    file.write(output)
  end
  file.close
  print_contents_of_file(options,"",fusion_vmx_file)
  return
end

# Create ESX VM vmx file

def create_fusion_vm_esx_file(options,local_vmx_file,fixed_vmx_file)
  fusion_vm_dir,fusion_vmx_file,fusion_disk_file = check_fusion_vm_doesnt_exist(options)
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking Fusion ESX configuration directory")
  end
  check_dir_exists(options,fusion_vm_dir)
  uid = options['uid']
  check_dir_owner(options,fusion_vm_dir,uid)
  vmx_info = []
  old_vmx_info = File.readlines(local_vmx_file)
  old_vmx_info.each do |line|
    vmx_line = line.chomp()
    (vmx_param,vmx_value) = vmx_line.split(/\=/)
    vmx_param = vmx_param.gsub(/\s+/,"")
    vmx_value = vmx_value.gsub(/^\s+/,"")
    vmx_value = vmx_value.gsub(/"/,"")
    vmx_line  = vmx_param+","+vmx_value
    case vmx_line
    when /virtualHW\.version/
      vmx_info.push("virtualHW.version,11")
    else
      if not vmx_param.match(/^serial|^shared|^hgfs/)
        vmx_info.push(vmx_line)
      end
    end
  end
  file = File.open(fixed_vmx_file,"w")
  vmx_info.each do |vmx_line|
    (vmx_param,vmx_value) = vmx_line.split(/\,/)
    if not vmx_value
      vmx_value = ""
    end
    output = vmx_param+" = \""+vmx_value+"\"\n"
    file.write(output)
  end
  file.close
  print_contents_of_file(options,"",fixed_vmx_file)
  return
end

# Configure a VMware Fusion VM

def configure_fusion_vm(options)
  (fusion_vm_dir,fusion_vmx_file,fusion_disk_file) = check_fusion_vm_doesnt_exist(options)
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking Fusion VM configuration directory")
  end
  check_dir_exists(options,fusion_vm_dir)
  uid = options['uid']
  check_dir_owner(options,fusion_vm_dir,uid)
  if not options['mac'].to_s.match(/[0-9]/)
    options['vm']  = "fusion"
    options['mac'] = generate_mac_address(options['vm'])
  end
  create_fusion_vm_vmx_file(options,fusion_vmx_file)
  if not options['file'].to_s.match(/ova$/)
    create_fusion_vm_disk(options,fusion_vm_dir,fusion_disk_file)
    check_file_owner(options,fusion_disk_file,options['uid'])
  end
  handle_output(options,"")
  handle_output(options,"Information:\tClient:     #{options['name']} created with MAC address #{options['mac']}")
  handle_output(options,"")
  return
end

# Populate VMware Fusion VM vmx information

def populate_fusion_vm_vmx_info(options)
  case options['os-type'].to_s
  when /vmware|esx|vsphere/
    if options['release'].to_s.match(/[0-9]/)
      if options['release'].to_s.match(/\./)
        guest_os = "vmkernel"+options['release'].to_s.split(".")[0]
      else
        guest_os = "vmkernel"+options['release']
      end
    else
      guest_os = "vmkernel7"
    end
  else
    guest_os = options['os-type'].to_s
  end
  if options['uuid'] == options['empty'] or !options['uuid'].to_s.match(/[0-9]/)
    options['uuid'] = options['mac'].to_s.downcase.gsub(/\:/," ")+" 00 00-00 00 "+options['mac'].to_s.downcase.gsub(/\:/," ")
  end
  version  = get_fusion_version(options)
  version  = version.to_i
  vmx_info = []
  vmx_info.push(".encoding,UTF-8")
  vmx_info.push("config.version,8")
  if version > 6
    if version > 7
      if version >= 8
        if version >= 9
          if version >= 18
            vmx_info.push("virtualHW.version,18")
          else
            vmx_info.push("virtualHW.version,16")
          end
        else
          vmx_info.push("virtualHW.version,12")
        end
      else
        vmx_info.push("virtualHW.version,11")
      end
    end
  else
    vmx_info.push("virtualHW.version,10")
  end
  vmx_info.push("vcpu.hotadd,FALSE")
  vmx_info.push("scsi0.present,TRUE")
  if options['service'].to_s.match(/el_8/)
    vmx_info.push("scsi0.virtualDev,pvscsi")
  else
    if options['os-type'].to_s.match(/windows7srv-64/)
      vmx_info.push("scsi0.virtualDev,lsisas1068")
    else
      vmx_info.push("scsi0.virtualDev,lsilogic")
    end
  end
  vmx_info.push("scsi0:0.present,TRUE")
  vmx_info.push("scsi0:0.fileName,#{options['name']}.vmdk")
  vmx_info.push("memsize,#{options['memory']}")
  vmx_info.push("mem.hotadd,FALSE")
  if options['file'] != options['empty']
    vmx_info.push("ide0.present,TRUE")
    vmx_info.push("ide0:0.present,TRUE")
    vmx_info.push("ide0:0.deviceType,cdrom-image")
    vmx_info.push("ide0:0.filename,#{options['file']}")
  else
    #vmx_info.push("ide0:0.deviceType,none")
    #vmx_info.push("ide0:0.filename,")
  end
  vmx_info.push("ide0:0.startConnected,TRUE")
  vmx_info.push("ide0:0.autodetect,TRUE")
#  vmx_info.push("sata0:1.present,FALSE")
#  vmx_info.push("floppy0.fileType,device")
#  vmx_info.push("floppy0.fileName,")
#  vmx_info.push("floppy0.clientDevice,FALSE")
  vmx_info.push("ethernet0.present,TRUE")
  vmx_info.push("ethernet0.noPromisc,FALSE")
  vmx_info.push("ethernet0.connectionType,#{options['vmnetwork']}")
  if options['os-type'].to_s.match(/vmware|esx|vsphere/)
    vmx_info.push("ethernet0.virtualDev,vmxnet3")
  else
    vmx_info.push("ethernet0.virtualDev,e1000")
  end
  vmx_info.push("ethernet0.wakeOnPcktRcv,FALSE")
  if options['dhcp'] == false
    vmx_info.push("ethernet0.addressType,static")
  else
    vmx_info.push("ethernet0.addressType,vpx")
  end
  if !options['mac'] == options['empty']
    if options['dhcp'] == false
      vmx_info.push("ethernet0.address,#{options['mac']}")
    else
      vmx_info.push("ethernet0.GeneratedAddress,#{options['mac']}")
    end
  end
  vmx_info.push("ethernet0.linkStatePropagation.enable,TRUE")
#  vmx_info.push("usb.present,TRUE")
#  vmx_info.push("ehci.present,TRUE")
#  vmx_info.push("ehci.pciSlotNumber,35")
  vmx_info.push("sound.present,TRUE")
  if options['os-type'].to_s.match(/windows7srv-64/)
    vmx_info.push("sound.virtualDev,hdaudio")
  end
  vmx_info.push("sound.fileName,-1")
  vmx_info.push("sound.autodetect,TRUE")
  vmx_info.push("mks.enable3d,TRUE")
  vmx_info.push("pciBridge0.present,TRUE")
  vmx_info.push("pciBridge4.present,TRUE")
  vmx_info.push("pciBridge4.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge4.functions,8")
  vmx_info.push("pciBridge5.present,TRUE")
  vmx_info.push("pciBridge5.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge5.functions,8")
  vmx_info.push("pciBridge6.present,TRUE")
  vmx_info.push("pciBridge6.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge6.functions,8")
  vmx_info.push("pciBridge7.present,TRUE")
  vmx_info.push("pciBridge7.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge7.functions,8")
  vmx_info.push("vmci0.present,TRUE")
  vmx_info.push("hpet0.present,TRUE")
#  vmx_info.push("usb.vbluetooth.startConnected,FALSE")
  vmx_info.push("tools.syncTime,TRUE")
  vmx_info.push("displayName,#{options['name']}")
  vmx_info.push("guestOS,#{guest_os}")
  vmx_info.push("nvram,#{options['name']}.nvram")
  vmx_info.push("virtualHW.productCompatibility,hosted")
  vmx_info.push("tools.upgrade.policy,upgradeAtPowerCycle")
  vmx_info.push("powerType.powerOff,soft")
  vmx_info.push("powerType.powerOn,soft")
  vmx_info.push("powerType.suspend,soft")
  vmx_info.push("powerType.reset,soft")
  vmx_info.push("extendedConfigFile,#{options['name']}.vmxf")
  vmx_info.push("uuid.bios,#{options['uuid']}")
  vmx_info.push("uuid.location,#{options['uuid']}")
  vmx_info.push("uuid.action,keep")
  vmx_info.push("replay.supported,FALSE")
  vmx_info.push("replay.filename,")
  vmx_info.push("pciBridge0.pciSlotNumber,17")
  vmx_info.push("pciBridge4.pciSlotNumber,21")
  vmx_info.push("pciBridge5.pciSlotNumber,22")
  vmx_info.push("pciBridge6.pciSlotNumber,23")
  vmx_info.push("pciBridge7.pciSlotNumber,24")
  vmx_info.push("scsi0.pciSlotNumber,16")
#  vmx_info.push("usb.pciSlotNumber,32")
  vmx_info.push("ethernet0.pciSlotNumber,33")
  vmx_info.push("sound.pciSlotNumber,34")
  vmx_info.push("vmci0.pciSlotNumber,36")
#  if version >= 8
#    vmx_info.push("sata0.pciSlotNumber,-1")
#  else
#    vmx_info.push("sata0.pciSlotNumber,37")
#  end
  if options['os-type'].to_s.match(/windows7srv-64/)
    vmx_info.push("scsi0.sasWWID,50 05 05 63 9c 8f c0 c0")
  end
  vmx_info.push("ethernet0.generatedAddressOffset,0")
#  vmx_info.push("vmci0.id,-1176557972")
  vmx_info.push("vmotion.checkpointFBSize,134217728")
  vmx_info.push("cleanShutdown,TRUE")
  vmx_info.push("softPowerOff,FALSE")
#  vmx_info.push("usb:1.speed,2")
#  vmx_info.push("usb:1.present,TRUE")
#  vmx_info.push("usb:1.deviceType,hub")
#  vmx_info.push("usb:1.port,1")
#  vmx_info.push("usb:1.parent,-1")
  vmx_info.push("checkpoint.vmState,")
#  vmx_info.push("sata0:1.startConnected,FALSE")
#  vmx_info.push("usb:0.present,TRUE")
#  vmx_info.push("usb:0.deviceType,hid")
#  vmx_info.push("usb:0.port,0")
#  vmx_info.push("usb:0.parent,-1")
  if options['dhcp'] == true
    vmx_info.push("ethernet0.GeneratedAddress,#{options['mac']}")
  else
    vmx_info.push("ethernet0.address,#{options['mac']}")
  end
  vmx_info.push("floppy0.present,FALSE")
  vmx_info.push("serial0.present,TRUE")
  vmx_info.push("serial0.fileType,pipe")
  vmx_info.push("serial0.yieldOnMsrRead,TRUE")
  vmx_info.push("serial0.startConnected,TRUE")
  vmx_info.push("serial0.fileName,/tmp/#{options['name']}")
  vmx_info.push("scsi0:0.redo,")
  if options['os-type'].to_s.match(/vmkernel/)
    vmx_info.push("monitor.virtual_mmu,hardware")
    vmx_info.push("monitor.virtual_exec,hardware")
    vmx_info.push("vhv.enable,TRUE")
    vmx_info.push("monitor_control.restrict_backdoor,TRUE")
  end
  if options['vcpus'].to_i > 1
    vmx_info.push("numvcpus,#{options['vcpus']}")
  end
  vmx_info.push("isolation.tools.hgfs.disable,FALSE")
  vmx_info.push("hgfs.mapRootShare,TRUE")
  vmx_info.push("hgfs.linkRootShare,TRUE")
  if version >= 8
    vmx_info.push("acpi.smbiosVersion2.7,FALSE")
    vmx_info.push("numa.autosize.vcpu.maxPerVirtualNode,1")
    vmx_info.push("numa.autosize.cookie,10001")
    vmx_info.push("migrate.hostlog,#{options['name']}-#{options['mac']}.hlog")
  end
  if options['sharedfolder'].to_s.match(/[a-z,A-Z]/)
    vmx_info.push("sharedFolder0.present,TRUE")
    vmx_info.push("sharedFolder0.enabled,TRUE")
    vmx_info.push("sharedFolder0.readAccess,TRUE")
    vmx_info.push("sharedFolder0.writeAccess,TRUE")
    vmx_info.push("sharedFolder0.hostPath,#{options['sharedfolder']}")
    vmx_info.push("sharedFolder0.guestName,#{options['sharedmount']}")
    vmx_info.push("sharedFolder0.expiration,never")
    vmx_info.push("sharedFolder.maxNum,1")
  end
  if options['vnc'] == true
    vmx_info.push("RemoteDisplay.vnc.enabled,TRUE")
    vmx_info.push("RemoteDisplay.vnc.port,5900")
    vmx_info.push("RemoteDisplay.vnc.password,#{options['vncpassword']}")
#    vmx_info.push("signal.suspendOnHUP=TRUE"  )
#    vmx_info.push("signal.powerOffOnTERM,TRUE")
  end
  return vmx_info
end
