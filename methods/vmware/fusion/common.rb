# frozen_string_literal: true

# VMware Fusion support code

# Deploy Fusion VM

def deploy_fusion_vm(_values)
  nil
end

# Check VM Fusion Promisc Mode

def check_fusion_vm_promisc_mode(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    promisc_file = '/Library/Preferences/VMware Fusion/promiscAuthorized'
    `sudo sh -c 'touch "/Library/Preferences/VMware Fusion/promiscAuthorized"'` unless File.exist?(promisc_file)
  end
  nil
end

# Set Fusion VM directory

def set_fusion_vm_dir(values)
  values['fusiondir'] = "#{values['home']}/vmware" if values['host-os-uname'].to_s.match(/Linux/)
  values['vmapp'] = if values['host-os-uname'].to_s.match(/Linux|Win/)
                      'VMware Workstation'
                    else
                      'VMware Fusion'
                    end
  nil
end

# Add Fusion VM network

def add_fusion_vm_network(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    vm_list = get_running_fusion_vms(values)
    if !vm_list.to_s.match(/#{values['name']}/)
      fusion_vmx_file = get_fusion_vm_vmx_file(values)
      message = "Information:\tAdding network interface to #{values['name']}"
      command = "'#{values['vmrun']}' addNetworkAdapter '#{fusion_vmx_file}' #{values['vmnetwork']}"
      execute_command(values, message, command)
    else
      information_message(values, "#{values['vmapp']} VM #{values['name']} is Running")
    end
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
  end
  nil
end

# Delete Fusion VM network

def delete_fusion_vm_network(values, install_interface)
  exists = check_fusion_vm_exists(values)
  if exists == true
    vm_list = get_running_fusion_vms(values)
    if !vm_list.to_s.match(/#{values['name']}/)
      fusion_vmx_file = get_fusion_vm_vmx_file(values)
      if install_interface == values['empty']
        message = "Information:\tGetting network interface list for #{values['name']}"
        command = "'#{values['vmrun']}' listNetworkAdapters '#{fusion_vmx_file}' |grep ^Total |cut -f2 -d:"
        output  = execute_command(values, message, command)
        last_id = output.chomp.gsub(/\s+/, '')
        last_id = last_id.to_i
        if last_id.zero?
          warning_message(values, 'No network interfaces found')
          return
        else
          last_id -= 1
          install_interface = last_id.to_s
        end
      end
      message = "Information:\tDeleting network interface from #{values['name']}"
      command = "'#{values['vmrun']}' deleteNetworkAdapter '#{fusion_vmx_file}' #{install_interface}"
      execute_command(values, message, command)
    else
      information_message(values, "#{values['vmapp']} VM #{values['name']} is Running")
    end
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
  end
  nil
end

# Show Fusion VM network

def show_fusion_vm_network(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    fusion_vmx_file = get_fusion_vm_vmx_file(values)
    message = "Information:\tGetting network interface list for #{values['name']}"
    command = "'#{values['vmrun']}' listNetworkAdapters '#{fusion_vmx_file}'"
    output  = execute_command(values, message, command)
    verbose_message(values, output)
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
  end
  nil
end

# Check Fusion VM status

def get_fusion_vm_status(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    vm_list = get_running_fusion_vms(values)
    if vm_list.to_s.match(/#{values['name']}/)
      information_message(values, "#{values['vmapp']} VM #{values['name']} is Running")
    else
      information_message(values, "#{values['vmapp']} VM #{values['name']} is Not Running")
    end
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
  end
  nil
end

# Get Fusion VM sreencap

def get_fusion_vm_screen(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    vm_list = get_running_fusion_vms(values)
    if vm_list.to_s.match(/#{values['name']}/)
      fusion_vmx_file = get_fusion_vm_vmx_file(values)
      screencap_file  = "#{values['tmpdir']}/#{values['name']}.png"
      message = "Information:\tCapturing screen of #{values['name']} to #{screencap_file}"
      command = "'#{values['vmrun']}' captureScreen '#{fusion_vmx_file}' '#{screencap_file}''"
      execute_command(values, message, command)
    else
      information_message(values, "#{values['vmapp']} VM #{values['name']} is Not Running")
    end
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
  end
  nil
end

# Check VMware Fusion VM is running

def check_fusion_vm_is_running(values)
  list_vms = get_running_fusion_vms(values)
  if list_vms.to_s.match(/#{values['name']}.vmx/)
    'yes'
  else
    'no'
  end
end

# Get VMware Fusion VM IP

def get_fusion_vm_ip(values)
  values['ip'] = ''
  exists = check_fusion_vm_exists(values)
  if exists == true
    running = check_fusion_vm_is_running(values)
    if running.match(/yes/)
      fusion_vmx_file = get_fusion_vm_vmx_file(values)
      message    = "Information:\tDetermining IP for #{values['name']}"
      command    = "'#{values['vmrun']}' getGuestIPAddress '#{fusion_vmx_file}'"
      values['ip'] = execute_command(values, message, command)
    else
      warning_message(values, "#{values['vmapp']} VM #{values['name']} is not running")
    end
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
  end
  values['ip'].chomp
end

# Set Fusion dir

def set_fusion_dir(values)
  unless File.directory?(values['fusiondir'])
    values['fusiondir'] = "#{values['home']}/Virtual Machines.localized"
    values['fusiondir'] = "#{values['home']}/Documents/Virtual Machines" unless File.directory?(values['fusiondir'])
  end
  values
end

# Import Packer Fusion VM image

def import_packer_fusion_vm(values)
  (exists, images_dir) = check_packer_vm_image_exists(values)
  if exists == false
    warning_message(values, "Packer #{values['vmapp']} VM image for #{values['name']} does not exist")
    quit(values)
  end
  fusion_vm_dir, = check_fusion_vm_doesnt_exist(values)
  information_message(values, 'Checking Fusion client directory') if values['verbose'] == true
  information_message(values, 'Checking Packer Fusion VM configuration directory') if values['verbose'] == true
  check_dir_exists(values, fusion_vm_dir)
  uid = values['uid']
  check_dir_owner(values, fusion_vm_dir, uid)
  message = "Information:\tCopying Packer VM images from \"#{images_dir}\" to \"#{fusion_vm_dir}\""
  command = "cd '#{images_dir}' ; cp * '#{fusion_vm_dir}'"
  execute_command(values, message, command)
  nil
end

# Migrate Fusion VM

def migrate_fusion_vm(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
    quit(values)
  end
  local_vmx_file  = get_fusion_vm_vmx_file(values)
  local_vmdk_file = get_fusion_vm_vmdk_file(values)
  if !File.exist?(local_vmx_file) || !File.exist?(local_vmdk_file)
    warning_message(values, "VMware config or disk file for #{values['name']} does not exist")
    quit(values)
  end
  values['vmxfile'] = File.basename(local_vmx_file)
  values['vmxfile'] = "/vmfs/volumes/#{values['datastore']}/#{values['name']}/#{values['vmxfile']}"
  fixed_vmx_file = "#{local_vmx_file}.esx"
  create_fusion_vm_esx_file(values['name'], local_vmx_file, fixed_vmx_file)
  values['vmdkfile'] = File.basename(local_vmdk_file)
  remote_vmdk_dir = "/vmfs/volumes/#{values['datastore']}/#{values['name']}"
  values['vmdkfile'] = "#{remote_vmdk_dir}/#{values['vmdkfile']}.old"
  command = "mkdir #{remote_vmdk_dir}"
  execute_ssh_command(values, command)
  scp_file(values, fixed_vmx_file, values['vmxfile'])
  scp_file(values, local_vmdk_file, values['vmdkfile'])
  import_esx_disk(values)
  import_esx_vm(values)
  nil
end

# Delete Fusion VM snapshot

def delete_fusion_vm_snapshot(values)
  clone_list = []
  if values['clone'].to_s.match(/\*/) || values['clone'].to_s.match(/all/)
    clone_list = get_fusion_vm_snapshots(values)
    clone_list = clone_list.split("\n")[1..]
  else
    clone_list[0] = values['clone']
  end
  clone_list.each do |clone|
    fusion_vmx_file = get_fusion_vm_vmx_file(values)
    message = "Information:\tDeleting snapshot #{clone} for #{values['vmapp']} VM #{values['name']}"
    command = "'#{values['vmrun']}' -T fusion deleteSnapshot '#{fusion_vmx_file}' '#{clone}'"
    execute_command(values, message, command)
  end
  nil
end

# Get a list of Fusion VM snapshots for a client

def get_fusion_vm_snapshots(values)
  fusion_vmx_file = get_fusion_vm_vmx_file(values)
  message = "Information:\tGetting a list of snapshots for #{values['vmapp']} VM " + values['name']
  command = "'#{values['vmrun']}' -T fusion listSnapshots '#{fusion_vmx_file}'"
  execute_command(values, message, command)
end

# List all Fusion VM snapshots

def list_all_fusion_vm_snapshots(values)
  vm_list = get_available_fusion_vms(values)
  vm_list.each do |vmx_file|
    values['name'] = File.basename(vmx_file, '.vmx')
    list_fusion_vm_snapshots(values)
  end
  nil
end

# List Fusion VM snapshots

def list_fusion_vm_snapshots(values)
  snapshot_list = get_fusion_vm_snapshots(values)
  verbose_message(snapshot_list)
  nil
end

# Get a value from a Fusion VM vmx file

def get_fusion_vm_vmx_file_value(values)
  vm_value  = ''
  vmx_file  = get_fusion_vm_vmx_file(values)
  if File.exist?(vmx_file)
    if File.readable?(vmx_file)
      vm_config = ParseConfig.new(vmx_file)
      vm_value  = vm_config[values['search']]
    else
      vm_value = 'File Not Readable'
    end
  elsif values['verbose'] == true
    warning_message(values, "WMware configuration file \"#{vmx_file}\" not found for client")
  end
  vm_value
end

# Get Fusion VM OS

def get_fusion_vm_os(values)
  values['search']  = 'guestOS'
  values['os-type'] = get_fusion_vm_vmx_file_value(values)
  unless values['os-type']
    values['search']  = 'guestos'
    values['os-type'] = get_fusion_vm_vmx_file_value(values)
  end
  values['os-type'] = 'Unknown' unless values['os-type']
  values['os-type']
end

# Get Fusion VM rootdisk

def get_fusion_vm_rootdisk(values)
  values['rootdisk'] = '/dev/nvme0n1' if (values['file'].to_s.match(/ubuntu/) || values['service'].to_s.match(/ubuntu/)) && (values['hwversion'].to_i > 19)
  values
end

# List all Fusion VMs

def list_all_fusion_vms(values)
  values['search'] = 'all'
  list_fusion_vms(values)
  nil
end

# List available VMware Fusion VMs

def list_fusion_vms(values)
  search_string = values['search']
  search_string = 'all' if search_string == values['empty']
  file_list = Dir.entries(values['fusiondir'])
  type_string = if search_string == 'all'
                  values['vmapp']
                else
                  "#{search_string.capitalize} #{values['vmapp']}"
                end
  if file_list.length.positive?
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
    file_list.each do |entry|
      next unless entry.match(/^[a-z]|^[A-Z]/)

      vm_name = entry.gsub(/\.vmwarevm/, '')
      values['name'] = vm_name
      vm_mac = get_fusion_vm_mac(values)
      vm_os  = get_fusion_vm_os(values)
      if search_string == 'all' || entry.match(/#{search_string}/) || values['os-type'].to_s.match(/#{search_string}/)
        if values['output'].to_s.match(/html/)
          verbose_message(values, '<tr>')
          verbose_message(values, "<td>#{vm_name}</td>")
          verbose_message(values, "<td>#{vm_os}</td>")
          verbose_message(values, "<td>#{vm_mac}</td>")
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

# Get Fusion VM vmx file location

def get_fusion_vm_vmx_file(values)
  vm_list = get_running_fusion_vms(values)
  if vm_list.to_s.match(/#{values['name']}\.vmx/)
    fusion_vmx_file = vm_list.grep(/#{values['name']}\.vmx/)[0].chomp
  else
    fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                      "#{values['fusiondir']}/#{values['name']}"
                    else
                      "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                    end
    fusion_vmx_file = if File.directory?(fusion_vm_dir)
                        Dir.entries(fusion_vm_dir).grep(/vmx$/)[0].chomp
                      else
                        ''
                      end
    fusion_vmx_file = "#{fusion_vm_dir}/#{fusion_vmx_file}"
  end
  fusion_vmx_file
end

# Show Fusion VM config

def show_fusion_vm_config(values)
  fusion_vmx_file = ''
  exists = check_fusion_vm_exists(values)
  if exists == true
    fusion_vmx_file = get_fusion_vm_vmx_file(values)
    print_contents_of_file(values, "#{values['vmapp']} configuration", fusion_vmx_file) if File.exist?(fusion_vmx_file)
  end
  nil
end

# Set Fusion VM value

def set_fusion_value(values)
  exists = check_fusion_vm_exists(values)
  fusion_vmx_file = get_fusion_vm_vmx_file(values)
  if exists == true
    message = "Information:\tSetting Parameter #{values['param']} for #{values['name']} to #{values['value']}"
    command = "'#{values['vmrun']}' writeVariable '#{fusion_vmx_file}' runtimeConfig '#{values['param']}' '#{values['value']}'"
    execute_command(values, message, command)
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
    quit(values)
  end
  nil
end

# Set Fusion VM value

def get_fusion_value(values)
  exists = check_fusion_vm_exists(values)
  fusion_vmx_file = get_fusion_vm_vmx_file(values)
  if exists == true
    message = "Information:\tGetting Parameter #{values['param']} for #{values['name']}"
    command = "'#{values['vmrun']}' readVariable '#{fusion_vmx_file}' runtimeConfig '#{values['param']}'"
    output  = execute_command(values, message, command)
    verbose_message(values, output)
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
    quit(values)
  end
  nil
end

# Get Fusion VM vmdk file location

def get_fusion_vm_vmdk_file(values)
  fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                    "#{values['fusiondir']}/#{values['name']}"
                  else
                    "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                  end
  fusion_vmdk_file = if File.directory?(fusion_vm_dir)
                       Dir.entries(fusion_vm_dir).grep(/vmdk$/)[0].chomp
                     else
                       ''
                     end
  "#{fusion_vm_dir}/#{fusion_vmdk_file}"
end

# Snapshot Fusion VM

def snapshot_fusion_vm(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
    quit(values)
  end
  fusion_vmx_file = get_fusion_vm_vmx_file(values)
  message = "Information:	Cloning #{values['vmapp']} VM #{values['name']} to #{values['clone']}"
  command = "'#{values['vmrun']}' -T fusion snapshot '#{fusion_vmx_file}' '#{values['clone']}'"
  execute_command(values, message, command)
  nil
end

# Get VMware version

def get_fusion_version(values)
  hw_version = '12'
  message    = "Determining:\tVMware Version"
  command = if values['host-os-uname'].to_s.match(/Linux/)
              'vmware --version'
            else
              'defaults read "/Applications/VMware Fusion.app/Contents/Info.plist" CFBundleShortVersionString'
            end
  vf_version = execute_command(values, message, command)
  if vf_version.to_s.match(/^e/)
    hw_version = '18'
  else
    vf_version = vf_version.chomp
    vf_dotver  = vf_version.split('.')[1]
    vf_version = vf_version.split('.')[0]
    vf_version = vf_version.to_i
    vf_dotver  = vf_dotver.to_i
    if vf_version > 6
      if vf_version > 7
        hw_version = if vf_version >= 8
                       if vf_version >= 10
                         if vf_version >= 11
                           if vf_version >= 12
                             if vf_version >= 13
                               if vf_dotver >= 5
                                 '21'
                               else
                                 '20'
                               end
                             elsif (vf_version >= 12) && (vf_dotver >= 2)
                               '19'
                             elsif vf_dotver >= 1
                               '18'
                             else
                               '16'
                             end
                           else
                             '14'
                           end
                         else
                           '14'
                         end
                       else
                         '12'
                       end
                     else
                       '11'
                     end
      end
    else
      hw_version = '10'
    end
  end
  hw_version
end

# Get/set vmrun path

def set_vmrun_bin(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    if values['techpreview'] == true
      if File.directory?('/Applications/VMware Fusion Tech Preview.app')
        values['vmrun'] = '/Applications/VMware Fusion Tech Preview.app/Contents/Library/vmrun'
        values['vmbin'] = '/Applications/VMware Fusion Tech Preview.app/Contents/MacOS/VMware Fusion'
        values['vmapp'] = 'VMware Fusion Tech Preview'
      end
    elsif File.directory?('/Applications/VMware Fusion Tech Preview.app')
      values['vmrun'] = '/Applications/VMware Fusion Tech Preview.app/Contents/Library/vmrun'
      values['vmbin'] = '/Applications/VMware Fusion Tech Preview.app/Contents/MacOS/VMware Fusion'
      values['vmapp'] = 'VMware Fusion Tech Preview'
    elsif File.directory?('/Applications/VMware Fusion.app')
      values['vmrun'] = '/Applications/VMware Fusion.app/Contents/Library/vmrun'
      values['vmbin'] = '/Applications/VMware Fusion.app/Contents/MacOS/VMware Fusion'
      values['vmapp'] = 'VMware Fusion'
    end
  else
    values['vmrun'] = 'vmrun'
    values['vmbin'] = 'vmware'
    values['vmapp'] = 'VMware Workstation'
  end
  warning_message(values, 'Could not find vmrun') if values['vmrun'] && !File.exist?(values['vmrun']) && (values['verbose'] == true)
  values
end

# Get/set ovftool path

def set_ovfbin(values)
  values['ovfbin'] = if values['host-os-uname'].to_s.match(/Darwin/)
                       '/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool'
                     else
                       '/usr/bin/ovftool'
                     end
  unless File.exist?(values['ovfbin'])
    warning_message(values, 'Could not find ovftool')
    quit(values)
  end
  nil
end

# Get list of running vms

def get_running_fusion_vms(values)
  `'#{values['vmrun']}' list |grep vmx`.split("\n")
end

# List running VMs

def list_running_fusion_vms(values)
  vm_list = get_running_fusion_vms(values)
  verbose_message(values, '')
  verbose_message(values, 'Running VMs:')
  verbose_message(values, '')
  vm_list.each do |vm_name|
    vm_name = File.basename(vm_name, '.vmx')
    verbose_message(vm_name)
  end
  verbose_message(values, '')
  nil
end

# Export OVA

def export_fusion_ova(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    stop_fusion_vm(values)
    unless values['file'].to_s.match(/[0-9,a-z,A-Z]/)
      values['file'] = "/tmp/#{values['name']}.ova"
      warning_message(values, 'No ouput file given')
      information_message(values, "Exporting VM #{values['name']} to #{values['file']}")
    end
    values['file'] = "#{values['file']}.ova" unless values['file'].to_s.match(/\.ova$/)
  end
  message = "Information:	Exporting #{values['vmapp']} VM #{values['name']} to #{fusion_vmx_file}"
  command = "\"#{values['ovfbin']}\" --acceptAllEulas --name = \"#{values['name']}\" \"#{fusion_vmx_file}\" \"#{values['file']}\""
  execute_command(values, message, command)
  nil
end

# Import vmdk

def import_fusion_vmdk(values)
  values['ip'] = single_install_ip(values)
  create_vm(values)
end

# Import OVA

def import_fusion_ova(values)
  values['ip'] = single_install_ip(values)
  set_ovfbin(values)
  fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                    "#{values['fusiondir']}/#{values['name']}"
                  else
                    "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                  end
  fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
  warning_message(values, 'WMware configuration file for client does not exist') unless File.exist?(fusion_vmx_file)
  exists = check_fusion_vm_exists(values)
  if exists == false
    values['file'] = "#{values['isodir']}/#{values['file']}" unless values['file'].to_s.match(%r{/})
    if File.exist?(values['file'])
      if values['name'].to_s.match(/[0-9,a-z,A-Z]/)
        Dir.mkdir(fusion_vm_dir) unless File.directory?(fusion_vm_dir)
        message = "Information:	Importing #{values['vmapp']} VM #{values['name']} from #{fusion_vmx_file}"
        command = "\"#{values['ovfbin']}\" --acceptAllEulas --name = \"#{values['name']}\" \"#{values['file']}\" \"#{fusion_vmx_file}\""
        execute_command(values, message, command)
      else
        values['name'] = `'#{values['ovfbin']}" "#{values['file']}" |grep Name |tail -1 |cut -f2 -d:`.chomp
        values['name'] = values['name'].gsub(/\s+/, '')
        fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
        if !values['name'].to_s.match(/[0-9,a-z,A-Z]/)
          warning_message(values, "Could not determine VM name for Virtual Appliance #{values['file']}")
          quit(values)
        else
          values['name'] = values['name'].split(/Suggested VM name /)[1].chomp
          Dir.mkdir(fusion_vm_dir) unless File.directory?(fusion_vm_dir)
          message = "Information:	Importing #{values['vmapp']} VM #{values['name']} from #{fusion_vmx_file}"
          command = "\"#{values['ovfbin']}\" --acceptAllEulas --name = \"#{values['name']}\" \"#{values['file']}\" \"#{fusion_vmx_file}\""
          execute_command(values, message, command)
        end
      end
    else
      warning_message(values, "Virtual Appliance #{values['file']} does not exist")
    end
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
  end
  add_hosts_entry(values['name'], values['ip']) if values['ip'].to_s.match(/[0-9]/)
  if values['mac'].to_s.match(/[0-9]|[A-F]|[a-f]/)
    change_fusion_vm_mac(values['name'], values['mac'])
  else
    values['mac'] = get_fusion_vm_mac(values)
    unless values['mac']
      values['vm']  = 'fusion'
      values['mac'] = generate_mac_address(values['vm'])
    end
  end
  change_fusion_vm_network(values['name'], values['vmnet'])
  information_message(values,
                      "Virtual Appliance #{values['file']} imported with VM name #{values['name']} and MAC address #{values['mac']}")
  nil
end

# List Solaris ESX VirtualBox VMs

def list_vs_fusion_vms(values)
  values['search'] = 'vmware'
  list_fusion_vms(search_string)
  nil
end

# List Linux KS VMware Fusion VMs

def list_ks_fusion_vms(values)
  values['search'] = 'rhel|centos|oel'
  list_fusion_vms(search_string)
  nil
end

# List Linux Preseed VMware Fusion VMs

def list_ps_fusion_vms(values)
  values['search'] = 'ubuntu'
  list_fusion_vms(search_string)
  nil
end

# List Linux AutoYast VMware Fusion VMs

def list_ay_fusion_vms(values)
  values['search'] = 'sles|suse'
  list_fusion_vms(search_string)
  nil
end

# List Solaris Kickstart VMware Fusion VMs

def list_js_fusion_vms(values)
  values['search'] = 'solaris'
  list_fusion_vms(search_string)
  nil
end

# List Solaris AI VMware Fusion VMs

def list_ai_fusion_vms(values)
  values['search'] = 'solaris'
  list_fusion_vms(search_string)
  nil
end

# Check Fusion VM MAC address

def check_fusion_vm_mac(values)
  if values['mac'].gsub(/:/, '').match(/^08/)
    warning_message(values, "Invalid MAC address: #{values['mac']}")
    values['vm']  = 'fusion'
    values['mac'] = generate_mac_address(values['vm'])
    information_message(values, "Generated new MAC address: #{values['mac']}")
  end
  values['mac']
end

# Get Fusion VM MAC address

def get_fusion_vm_mac(values)
  values['mac']    = ''
  values['search'] = 'ethernet0.address'
  values['mac']    = get_fusion_vm_vmx_file_value(values)
  unless values['mac']
    values['search'] = 'ethernet0.generatedAddress'
    values['mac']    = get_fusion_vm_vmx_file_value(values)
  end
  values['mac']
end

# Change VMware Fusion VM MAC address

def change_fusion_vm_mac(values)
  (_, fusion_vmx_file,) = check_fusion_vm_doesnt_exist(values)
  unless File.exist?(fusion_vmx_file)
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist ")
    quit(values)
  end
  copy = []
  file = IO.readlines(fusion_vmx_file)
  file.each do |line|
    if line.match(/generatedAddress/)
      copy.push("ethernet0.address = \"#{values['mac']}\"\n")
    elsif line.match(/ethernet0\.address/)
      copy.push("ethernet0.address = \"#{values['mac']}\"\n")
    else
      copy.push(line)
    end
  end
  File.open(fusion_vmx_file, 'w') { |file_data| file_data.puts copy }
  nil
end

# Change VMware Fusion VM CDROM

def attach_file_to_fusion_vm(values)
  fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                    "#{values['fusiondir']}/#{values['name']}"
                  else
                    "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                  end
  fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
  unless File.exist?(fusion_vmx_file)
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist ")
    quit(values)
  end
  if values['verbose'] == true
    information_message(values, "Attaching file #{values['file']} to #{values['name']}")
    information_message(values, "Modifying file \"#{fusion_vmx_file}\"")
  end
  copy = []
  file = IO.readlines(fusion_vmx_file)
  file.each do |line|
    (item,) = line.split(/=/)
    item = item.gsub(/\s+/, '')
    case item
    when /ide0:0.deviceType|ide0:0.startConnected/
      copy.push("ide0:0.deviceType = cdrom-image\n")
    when /ide0:0.filename|ide0:0.autodetect/
      copy.push("ide0:0.filename = #{values['file']}\n")
    else
      copy.push(line)
    end
  end
  File.open(fusion_vmx_file, 'w') { |file_data| file_data.puts copy }
  nil
end

# Detach VMware Fusion VM CDROM

def detach_file_from_fusion_vm(values)
  information_message(values, "Detaching CDROM from #{values['name']}") if values['verbose'] == true
  fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                    "#{values['fusiondir']}/#{values['name']}"
                  else
                    "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                  end
  fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
  copy = []
  file = IO.readlines(fusion_vmx_file)
  file.each do |line|
    (item,) = line.split(/=/)
    item = item.gsub(/\s+/, '')
    case item
    when 'ide0:0.deviceType'
      copy.push("ide0:0.startConnected = TRUE\n")
    when 'ide0:0.filename'
      copy.push("\n")
    else
      copy.push(line)
    end
  end
  File.open(fusion_vmx_file, 'w') { |file_data| file_data.puts copy }
  nil
end

# Get Fushion hostonly IP address

def get_fusion_hostonly_network(values)
  hostonly_ip = ''
  case values['host-os-uname']
  when /Darwin/
    config_file = '/Library/Preferences/VMware Fusion/networking'
  when /Linux/
    config_file = '/etc/vmware/locations'
  when /NT/
    config_file = '/cygdrive/c/ProgramData/VMware/vmnetdhcp.conf'
  end
  if File.exist?(config_file)
    file = IO.readlines(config_file)
    file.each do |line|
      case line
      when /answer VNET_1_HOSTONLY_SUBNET/
        hostonly_ip = line.split(' ')[-1]
      end
    end
  end
  if hostonly_ip.match(/[0-9]/)
    hostonly_ip = hostonly_ip.split('.')[0..2].join('.')
    hostonly_ip += '.1'
    values['hostonlyip'] = hostonly_ip
    values['vmgateway']  = hostonly_ip
    message = "Information:\tFinding network interface name with IP #{hostonly_ip}"
    command = "ifconfig -a |grep -B3 '#{hostonly_ip}' |head -1 |cut -f1 -d:"
    output  = execute_command(values, message, command).chomp
    values['vmnet'] = output
  end
  values
end

# Check Fusion hostonly networking

def check_fusion_hostonly_network(values, if_name)
  case values['host-os-uname']
  when /Darwin/
    config_file = '/Library/Preferences/VMware Fusion/networking'
  when /Linux/
    config_file = '/etc/vmware/locations'
  when /NT/
    config_file = '/cygdrive/c/ProgramData/VMware/vmnetdhcp.conf'
  end
  network_address = "#{values['hostonlyip'].split(/\./)[0..2].join('.')}.0"
  gw_if_name = get_gw_if_name(values)
  dhcp_test  = 0
  vmnet_test = 0
  copy = []
  file = IO.readlines(config_file)
  if values['host-os-uname'].to_s.match(/Darwin/)
    file.each do |line|
      case line
      when /answer VNET_1_DHCP /
        if !line.match(/no/)
          dhcp_test = 1
          copy.push('answer VNET_1_DHCP no')
        else
          copy.push(line)
        end
      when /answer VNET_1_HOSTONLY_SUBNET/
        if !line.match(/#{network_address}/)
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
  command = if values['host-os-uname'].to_s.match(/NT/)
              "ipconfig /all |grep -i #{values['vmnet']}"
            else
              "ifconfig -a |grep -i #{values['vmnet']}"
            end
  output = execute_command(values, message, command)
  vmnet_test = 1 unless output.match(/#{values['vmnet']}/)
  if dhcp_test == 1 || vmnet_test == 1 && values['host-os-uname'].to_s.match(/Darwin/)
    message = "Information:\tStarting #{values['vmapp']}"
    if values['host-os-uname'].to_s.match(/Darwin/)
      vmnet_cli = "/Applications/#{values['vmapp']}.app/Contents/Library/vmnet-cli"
      command   = "cd /Applications ; open \"#{values['vmapp']}.app\""
    else
      command   = "#{values['vmapp']} &"
      vmnet_cli = 'vmnetcfg'
    end
    execute_command(values, message, command)
    sleep 3
    temp_file = '/tmp/networking'
    File.open(temp_file, 'w') { |file_data| file_data.puts copy }
    message = "Information:\tConfiguring host only network on #{if_name} for network #{network_address}"
    command = "cp #{temp_file} \"#{config_file}\""
    if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_s.match(/^11/)
      `sudo sh -c '#{command}'`
    else
      execute_command(values, message, command)
    end
    message = "Information:\tConfiguring VMware network"
    command = "\"#{vmnet_cli}\" --configure"
    if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_s.match(/^11/)
      `sudo sh -c '#{command}'`
    else
      execute_command(values, message, command)
    end
    message = "Information:\tStopping VMware network"
    command = "\"#{vmnet_cli}\" --stop"
    if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_s.match(/^11/)
      `sudo sh -c '#{command}'`
    else
      execute_command(values, message, command)
    end
    message = "Information:\tStarting VMware network"
    command = "\"#{vmnet_cli}\" --start"
    if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_s.match(/^11/)
      `sudo sh -c '#{command}'`
    else
      execute_command(values, message, command)
    end
  end
  if values['host-os-uname'].to_s.match(/NT/)
    if_name = 'VMware Network Adapter VMnet1'
    output  = get_win_ip_from_if_name(if_name)
  else
    message = "Information:\tChecking vmnet interface address"
    command = "ifconfig #{values['vmnet']} |grep inet"
    output  = execute_command(values, message, command)
  end
  hostonly_ip = output.chomp.split(' ')[1]
  if hostonly_ip != values['hostonlyip']
    message = "Information:\tSetting #{values['vmnet']} address to #{values['hostonlyip']}"
    command = if values['host-os-uname'].to_s.match(/NT/)
                "netsh interface ip set address {if_name} static #{values['hostonlyip']} #{values['netmask']}"
              else
                "ifconfig #{values['vmnet']} inet #{values['hostonlyip']} up"
              end
    execute_command(values, message, command)
  end
  check_nat(values, gw_if_name, if_name)
  nil
end

# Change VMware Fusion VM network type

def change_fusion_vm_network(values, client_network)
  fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                    "#{values['fusiondir']}/#{values['name']}"
                  else
                    "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                  end
  fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
  test = 0
  copy = []
  file = IO.readlines(fusion_vmx_file)
  file.each do |line|
    if line.match(/ethernet0\.connectionType/)
      if !line.match(/#{client_network}/)
        test = 1
        copy.push("ethernet0.connectionType = \"#{client_network}\"\n")
      else
        copy.push(line)
      end
    else
      copy.push(line)
    end
  end
  File.open(fusion_vmx_file, 'w') { |file_data| file_data.puts copy } if test == 1
  nil
end

# Boot VMware Fusion VM

def boot_fusion_vm(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                      "#{values['fusiondir']}/#{values['name']}"
                    else
                      "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                    end
    fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
    if File.exist?(fusion_vmx_file)
      message = "Information:\tChecking whether VM #{values['name']} has hostonly network"
      command = "grep hostonly '#{fusion_vmx_file}'"
      output  = execute_command(values, message, command)
      if output.to_s.match(/hostonly/)
        if_name = values['vmnet'].to_s
        gw_if_name = get_gw_if_name(values)
        check_nat(values, gw_if_name, if_name)
      end
    end
    message = "Starting:\tVM #{values['name']}"
    command = if (values['text'] == true) || (values['headless'] == true) || (values['serial'] == true)
                "\"#{values['vmrun']}\" -T fusion start \"#{fusion_vmx_file}\" nogui &"
              else
                "\"#{values['vmrun']}\" -T fusion start \"#{fusion_vmx_file}\" &"
              end
    execute_command(values, message, command)
    if values['serial'] == true
      information_message(values, "Connecting to serial port of #{values['name']}") if values['verbose'] == true
      begin
        socket = UNIXSocket.open("/tmp/#{values['name']}")
        socket.each_line do |line|
          verbose_message(line)
        end
      rescue StandardError
        warning_message(values, 'Cannot open socket')
        quit(values)
      end
    end
  else
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
  end
  nil
end

# Add share to VMware Fusion VM

def add_shared_folder_to_fusion_vm(values)
  vm_list = get_running_fusion_vms(values)
  if vm_list.to_s.match(/#{values['name']}/)
    fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                      "#{values['fusiondir']}/#{values['name']}"
                    else
                      "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                    end
    fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
    message = "Stopping:\tVirtual Box VM #{values['name']}"
    command = "'#{values['vmrun']}' -T fusion addSharedFolder '#{fusion_vmx_file}' #{values['mount']} #{values['share']}"
    execute_command(values, message, command)
  elsif values['verbose'] == true
    information_message(values, "#{values['vmapp']} VM #{values['name']} not running")
  end
  nil
end

# Stop VMware Fusion VM

def halt_fusion_vm(values)
  stop_fusion_vm(values)
end

def stop_fusion_vm(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                      "#{values['fusiondir']}/#{values['name']}"
                    else
                      "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                    end
    fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
    message = "Stopping:\tVirtual Box VM #{values['name']}"
    command = "\"#{values['vmrun']}\" -T fusion stop \"#{fusion_vmx_file}\""
    execute_command(values, message, command)
  else
    fusion_vms = get_running_fusion_vms(values)
    fusion_vms.each do |fusion_vmx_file|
      fusion_vmx_file = fusion_vmx_file.chomp
      fusion_vm       = File.basename(fusion_vmx_file, '.vmx')
      next unless fusion_vm == values['name']

      message = "Stopping:\tVirtual Box VM #{values['name']}"
      command = "\"#{values['vmrun']}\" -T fusion stop \"#{fusion_vmx_file}\""
      execute_command(values, message, command)
      return
    end
    information_message(values, "#{values['vmapp']} VM #{values['name']} not running") if values['verbose'] == true
  end
  nil
end

# Reset VMware Fusion VM

def reboot_fusion_vm(values)
  reset_fusion_vm(values)
end

def reset_fusion_vm(values)
  vm_list = get_running_fusion_vms(values)
  if vm_list.to_s.match(/#{values['name']}/)
    fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                      "#{values['fusiondir']}/#{values['name']}"
                    else
                      "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                    end
    fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
    message = "Stopping:\tVirtual Box VM #{values['name']}"
    command = "'#{values['vmrun']}' -T fusion reset '#{fusion_vmx_file}'"
    execute_command(values, message, command)
  elsif values['verbose'] == true
    information_message(values, "#{values['vmapp']} VM #{values['name']} not running")
  end
  nil
end

# Suspend VMware Fusion VM

def suspend_fusion_vm(values)
  vm_list = get_running_fusion_vms(values)
  if vm_list.to_s.match(/#{values['name']}/)
    fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                      "#{values['fusiondir']}/#{values['name']}"
                    else
                      "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                    end
    fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
    message = "Stopping:\tVirtual Box VM #{values['name']}"
    command = "'#{values['vmrun']}' -T fusion suspend '#{fusion_vmx_file}'"
    execute_command(values, message, command)
  elsif values['verbose'] == true
    information_message(values, "#{values['vmapp']} VM #{values['name']} not running")
  end
  nil
end

# Create VMware Fusion VM disk

def create_fusion_vm_disk(values, fusion_vm_dir, fusion_disk_file)
  if File.exist?(fusion_disk_file)
    warning_message(values, "#{values['vmapp']} VM disk '#{fusion_disk_file}' already exists for #{values['name']}")
    quit(values)
  end
  check_dir_exists(values, fusion_vm_dir)
  vdisk_bin = if values['host-os-uname'].to_s.match(/Darwin/)
                '/Applications/VMware Fusion.app/Contents/Library/vmware-vdiskmanager'
              else
                '/usr/bin/vmware-vdiskmanager'
              end
  message = "Creating 	#{values['vmapp']} disk '#{fusion_disk_file}' for #{values['name']}"
  command = "cd \"#{fusion_vm_dir}\" ; \"#{vdisk_bin}\" -c -s \"#{values['size']}\" -a LsiLogic -t 0 \"#{fusion_disk_file}\""
  execute_command(values, message, command)
  nil
end

# Check VMware Fusion VM exists

def check_fusion_vm_exists(values)
  set_vmrun_bin(values)
  fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                    "#{values['fusiondir']}/#{values['name']}"
                  else
                    "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                  end
  fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
  if !File.exist?(fusion_vmx_file)
    information_message(values, "#{values['vmapp']} VM #{values['name']} does not exist") if values['verbose'] == true
    exists = false
  else
    information_message(values, "#{values['vmapp']} VM #{values['name']} exists") if values['verbose'] == true
    exists = true
  end
  exists
end

# Check VMware Fusion VM does not exist

def check_fusion_vm_doesnt_exist(values)
  fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                    "#{values['fusiondir']}/#{values['name']}"
                  else
                    "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                  end
  fusion_vmx_file  = "#{fusion_vm_dir}/#{values['name']}.vmx"
  fusion_disk_file = "#{fusion_vm_dir}/#{values['name']}.vmdk"
  if File.exist?(fusion_vmx_file)
    information_message(values, "#{values['vmapp']} VM #{values['name']} already exists")
    quit(values)
  end
  [fusion_vm_dir, fusion_vmx_file, fusion_disk_file]
end

# Get a list of available VMware Fusion VMs

def get_available_fusion_vms(values)
  vm_list = []
  vm_list = `find "#{values['fusiondir']}/" -name "*.vmx'`.split("\n") if File.directory?(values['fusiondir']) || File.symlink?(values['fusiondir'])
  vm_list
end

# Get VMware Fusion Guest OS name

def get_fusion_guest_os(values)
  case values['method']
  when /ai/
    get_ai_fusion_guest_os(values)
  when /js/
    get_js_fusion_guest_os(values)
  when /ay/
    get_ay_fusion_guest_os(values)
  when /nb/
    get_nb_fusion_guest_os(values)
  when /ob/
    get_ob_fusion_guest_os(values)
  when /ps|ci/
    get_ps_fusion_guest_os(values)
  when /pe/
    get_pe_fusion_guest_os(values)
  when /ks/
    get_ks_fusion_guest_os(values)
  when /vs/
    get_vs_fusion_guest_os(values)
  else
    get_other_fusion_guest_os(values)
  end
end

# Get VMware Fusion Guest OS name

def get_ai_fusion_guest_os(_values)
  'solaris10-64'
end

# Configure a AI VMware Fusion VM

def configure_ai_fusion_vm(values)
  values['os-type'] = get_ai_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Get VMware Fusion Guest OS name

def get_js_fusion_guest_os(values)
  values['os-type'] = 'solaris10-64'
  values['os-type']
end

# Configure a Jumpstart VMware Fusion VM

def configure_js_fusion_vm(values)
  values['os-type'] = get_js_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Get VMware Fusion Guest OS name

def get_ay_fusion_guest_os(values)
  guest_os = 'sles11'
  guest_os += '-64' if !values['arch'].to_s.match(/i386/) && !values['arch'].to_s.match(/64/)
  guest_os
end

# configure an AutoYast (Suse) VMware Fusion VM

def configure_ay_fusion_vm(values)
  values['os-type'] = get_ay_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Get VMware Fusion Guest OS name

def get_nb_fusion_guest_os(values)
  guest_os = 'freebsd'
  guest_os += '-64' if !values['arch'].to_s.match(/i386/) && !values['arch'].to_s.match(/64/)
  guest_os
end

# Configure a NetBSB VMware Fusion VM

def configure_nb_fusion_vm(values)
  values['os-type'] = get_nb_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Get VMware Fusion Guest OS name

def get_ob_fusion_guest_os(_values)
  'otherlinux-64'
end

# Configure an OpenBSD VMware Fusion VM

def configure_ob_fusion_vm(values)
  values['os-type'] = get_ob_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Get VMware Fusion Guest OS name for Ubuntu/Debian VMs

def get_ps_fusion_guest_os(values)
  guest_os = 'ubuntu'
  guest_os += '-64' if values['arch'].to_s.match(/64/)
  guest_os = "arm-#{guest_os}" if values['arch'].to_s.match(/arm/) || values['host-os-unamep'].to_s.match(/arm/)
  guest_os
end

# Configure an Ubuntu VMware Fusion VM

def configure_ps_fusion_vm(values)
  values['os-type'] = get_ps_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Get VMware Fusion Guest OS name for Windows VMs

def get_pe_fusion_guest_os(_values)
  'windows7srv-64'
end

# Configure a Windows VMware Fusion VM

def configure_pe_fusion_vm(values)
  values['os-type'] = get_pe_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Get VMware Fusion Guest OS name

def get_other_fusion_guest_os(_values)
  'otherguest'
end

# Configure another VMware Fusion VM

def configure_other_fusion_vm(values)
  values['os-type'] = get_other_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Get VMware Fusion Guest OS name

def get_ks_fusion_guest_os(values)
  guest_os = 'rhel6'
  if values['arch'].to_s.match(/64/)
    guest_os += '-64'
  elsif !values['arch'].to_s.match(/i386/) && !values['arch'].to_s.match(/64/)
    guest_os += '-64'
  end
  guest_os
end

# Configure a Kickstart VMware Fusion VM

def configure_ks_fusion_vm(values)
  values['os-type'] = get_ks_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Get VMware Fusion Guest OS name

def get_vs_fusion_guest_os(values)
  values['os-type'] = 'vmkernel5'
  values['os-type']
end

# Configure a ESX VMware Fusion VM

def configure_vs_fusion_vm(values)
  values['os-type'] = get_vs_fusion_guest_os(values)
  configure_fusion_vm(values)
  nil
end

# Check VMware Fusion is installed

def check_fusion_is_installed(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    values['vmapp'] = 'VMware Fusion'
    app_dir = '/Applications/VMware Fusion.app'
    unless File.directory?(app_dir)
      app_dir = '/Applications/VMware Fusion Tech Preview.app'
      unless File.directory?(app_dir)
        warning_message(values, 'VMware Fusion not installed')
        quit(values)
      end
    end
  else
    values['vmapp'] = 'VMware Workstation'
    values['vmrun'] = `which vmrun`.chomp
    if !values['vmrun'].to_s.match(/vmrun/) && !values['vmrun'].to_s.match(/no vmrun/)
      warning_message(values, "#{values['vmapp']} not installed")
      quit(values)
    end
  end
  values
end

# check VMware Fusion NAT

def check_fusion_natd(values, if_name)
  check_fusion_hostonly_network(values, if_name) if values['vmnetwork'].to_s.match(/hostonly/)
  values
end

# Unconfigure a VMware Fusion VM

def unconfigure_fusion_vm(values)
  stop_fusion_vm(values)
  exists = check_fusion_vm_exists(values)
  if exists == true
    stop_fusion_vm(values)
    fusion_vm_dir = if values['host-os-uname'].to_s.match(/Linux/)
                      "#{values['fusiondir']}/#{values['name']}"
                    else
                      "#{values['fusiondir']}/#{values['name']}.vmwarevm"
                    end
    fusion_vmx_file = "#{fusion_vm_dir}/#{values['name']}.vmx"
    message = "Deleting:\t#{values['vmapp']} VM " + values['name']
    command = "'#{values['vmrun']}' -T fusion deleteVM '#{fusion_vmx_file}'"
    execute_command(values, message, command)
    vm_dir  = "#{values['name']}.vmwarevm"
    message = "Removing:	#{values['vmapp']} VM #{values['name']} directory"
    command = "cd \"#{values['fusiondir']}\" ; rm -rf \"#{vm_dir}\""
    execute_command(values, message, command)
  elsif values['verbose'] == true
    warning_message(values, "#{values['vmapp']} VM #{values['name']} does not exist")
  end
  nil
end

# Create VMware Fusion VM vmx file

def create_fusion_vm_vmx_file(values, fusion_vmx_file)
  values['os-type'] = get_fusion_guest_os(values) if values['os-type'] == values['empty']
  values, vmx_info = populate_fusion_vm_vmx_info(values)
  if !fusion_vmx_file.match(%r{/packer/})
    fusion_vm_dir, fusion_vmx_file, = check_fusion_vm_doesnt_exist(values)
  else
    fusion_vm_dir = File.dirname(fusion_vmx_file)
  end
  file = File.open(fusion_vmx_file, 'w')
  information_message(values, 'Checking Fusion VMX configuration directory') if values['verbose'] == true
  check_dir_exists(values, fusion_vm_dir)
  uid = values['uid']
  check_dir_owner(values, fusion_vm_dir, uid)
  vmx_info.each do |vmx_line|
    (vmx_param, vmx_value) = vmx_line.split(/,/)
    vmx_value ||= ''
    output = "#{vmx_param} = \"#{vmx_value}\"\n"
    file.write(output)
  end
  file.close
  print_contents_of_file(values, '', fusion_vmx_file)
  values
end

# Create ESX VM vmx file

def create_fusion_vm_esx_file(values, local_vmx_file, fixed_vmx_file)
  fusion_vm_dir, = check_fusion_vm_doesnt_exist(values)
  information_message(values, 'Checking Fusion ESX configuration directory') if values['verbose'] == true
  check_dir_exists(values, fusion_vm_dir)
  uid = values['uid']
  check_dir_owner(values, fusion_vm_dir, uid)
  vmx_info = []
  old_vmx_info = File.readlines(local_vmx_file)
  old_vmx_info.each do |line|
    vmx_line = line.chomp
    (vmx_param, vmx_value) = vmx_line.split(/=/)
    vmx_param = vmx_param.gsub(/\s+/, '')
    vmx_value = vmx_value.gsub(/^\s+/, '')
    vmx_value = vmx_value.gsub(/"/, '')
    vmx_line  = "#{vmx_param},#{vmx_value}"
    case vmx_line
    when /virtualHW\.version/
      vmx_info.push('virtualHW.version,11')
    else
      vmx_info.push(vmx_line) unless vmx_param.match(/^serial|^shared|^hgfs/)
    end
  end
  file = File.open(fixed_vmx_file, 'w')
  vmx_info.each do |vmx_line|
    (vmx_param, vmx_value) = vmx_line.split(/,/)
    vmx_value ||= ''
    output = "#{vmx_param} = \"#{vmx_value}\"\n"
    file.write(output)
  end
  file.close
  print_contents_of_file(values, '', fixed_vmx_file)
  nil
end

# Configure a VMware Fusion VM

def configure_fusion_vm(values)
  (fusion_vm_dir, fusion_vmx_file, fusion_disk_file) = check_fusion_vm_doesnt_exist(values)
  information_message(values, 'Checking Fusion VM configuration directory') if values['verbose'] == true
  check_dir_exists(values, fusion_vm_dir)
  uid = values['uid']
  check_dir_owner(values, fusion_vm_dir, uid)
  unless values['mac'].to_s.match(/[0-9]/)
    values['vm']  = 'fusion'
    values['mac'] = generate_mac_address(values['vm'])
  end
  values = create_fusion_vm_vmx_file(values, fusion_vmx_file)
  unless values['file'].to_s.match(/ova$/)
    create_fusion_vm_disk(values, fusion_vm_dir, fusion_disk_file)
    check_file_owner(values, fusion_disk_file, values['uid'])
  end
  verbose_message(values, '')
  information_message(values, "Client:     #{values['name']} created with MAC address #{values['mac']}")
  verbose_message(values, '')
  values
end

# Populate VMware Fusion VM vmx information

def populate_fusion_vm_vmx_info(values)
  guest_os = case values['os-type'].to_s
             when /vmware|esx|vsphere/
               if values['release'].to_s.match(/[0-9]/)
                 if values['release'].to_s.match(/\./)
                   "vmkernel#{values['release'].to_s.split('.')[0]}"
                 else
                   "vmkernel#{values['release']}"
                 end
               else
                 'vmkernel7'
               end
             else
               get_fusion_guest_os(values)
               #    guest_os = values['os-type'].to_s
             end
  if (values['uuid'] == values['empty']) || !values['uuid'].to_s.match(/[0-9]/)
    values['uuid'] =
      "#{values['mac'].to_s.downcase.gsub(/:/, ' ')} 00 00-00 00 #{values['mac'].to_s.downcase.gsub(/:/, ' ')}"
  end
  version  = values['hwversion'].to_s
  version  = version.to_i
  vmx_info = []
  vmx_info.push('.encoding,UTF-8')
  vmx_info.push('config.version,8')
  if version > 6
    if version > 7
      if version >= 8
        if version >= 9
          if version >= 10
            if version >= 13
              if version >= 21
                vmx_info.push('virtualHW.version,21')
                values['hwversion'] = '21'
              else
                vmx_info.push('virtualHW.version,20')
                values['hwversion'] = '20'
              end
            else
              vmx_info.push('virtualHW.version,18')
              values['hwversion'] = '18'
            end
          else
            vmx_info.push('virtualHW.version,16')
            values['hwversion'] = '16'
          end
        else
          vmx_info.push('virtualHW.version,12')
          values['hwversion'] = '12'
        end
      else
        vmx_info.push('virtualHW.version,11')
        values['hwversion'] = '11'
      end
    end
  else
    vmx_info.push('virtualHW.version,10')
    values['hwversion'] = '10'
  end
  #  vmx_info.push("vcpu.hotadd,FALSE")
  vmx_info.push('scsi0.present,TRUE')
  if values['service'].to_s.match(/el_8|vsphere|esx|vmware/) || values['os-type'].to_s.match(/vsphere|esx|vmware|el_6/)
    vmx_info.push('scsi0.virtualDev,pvscsi')
  elsif values['os-type'].to_s.match(/windows7srv-64/)
    vmx_info.push('scsi0.virtualDev,lsisas1068')
  else
    vmx_info.push('scsi0.virtualDev,lsilogic')
  end
  vmx_info.push('firmware,efi') if values['biostype'].to_s.match(/efi/)
  vmx_info.push('scsi0:0.present,TRUE')
  vmx_info.push("scsi0:0.fileName,#{values['name']}.vmdk")
  vmx_info.push("memsize,#{values['memory']}")
  #  vmx_info.push("mem.hotadd,FALSE")
  if values['file'] != values['empty']
    if values['hwversion'].to_i >= 20
      vmx_info.push('sata0.pciSlotNumber,37')
      vmx_info.push('sata0.present,TRUE')
      vmx_info.push('sata0:1.present,TRUE')
      vmx_info.push('sata0:1.deviceType,cdrom-image')
      vmx_info.push("sata0:1.filename,#{values['file']}")
    #      vmx_info.push("nvme0.pciSlotNumber,224")
    #      vmx_info.push("nvme0.present,TRUE")
    #      vmx_info.push("nvme0.subnqnUUID,#{values['uuid']}")
    #      vmx_info.push("nvme0:0.fileName,#{values['file']}")
    #      vmx_info.push("nvme0:0.present,TRUE")
    #      vmx_info.push("nvme0:0.redo,")
    else
      vmx_info.push('ide0.present,TRUE')
      vmx_info.push('ide0:0.present,TRUE')
      vmx_info.push('ide0:0.deviceType,cdrom-image')
      vmx_info.push("ide0:0.filename,#{values['file']}")
    end
  else
    # vmx_info.push("ide0:0.deviceType,none")
    # vmx_info.push("ide0:0.filename,")
  end
  vmx_info.push('ide0:0.startConnected,TRUE')
  vmx_info.push('ide0:0.autodetect,TRUE')
  #  vmx_info.push("sata0:1.present,FALSE")
  #  vmx_info.push("floppy0.fileType,device")
  #  vmx_info.push("floppy0.fileName,")
  #  vmx_info.push("floppy0.clientDevice,FALSE")
  vmx_info.push('ethernet0.present,TRUE')
  #  vmx_info.push("ethernet0.noPromisc,FALSE")
  vmx_info.push("ethernet0.connectionType,#{values['vmnetwork']}")
  if values['os-type'].to_s.match(/vmware|esx|vsphere/)
    vmx_info.push('ethernet0.virtualDev,vmxnet3')
  elsif values['host-os-unamep'].to_s.match(/arm/)
    vmx_info.push('ethernet0.virtualDev,e1000e')
  else
    vmx_info.push('ethernet0.virtualDev,e1000')
  end
  #  vmx_info.push("ethernet0.wakeOnPcktRcv,FALSE")
  if values['dhcp'] == false
    vmx_info.push('ethernet0.addressType,static')
  elsif values['service'].to_s.match(/vmware|vsphere|esx/)
    vmx_info.push('ethernet0.addressType,vpx')
  else
    vmx_info.push('ethernet0.addressType,generated')
  end
  if !values['mac'] == values['empty']
    if values['dhcp'] == false
      vmx_info.push("ethernet0.address,#{values['mac']}")
    else
      vmx_info.push("ethernet0.GeneratedAddress,#{values['mac']}")
    end
  end
  vmx_info.push('ethernet0.linkStatePropagation.enable,TRUE')
  #  vmx_info.push("usb.present,TRUE")
  if values['service'].to_s.match(/el_8|vsphere|esx|vmware/) || values['os-type'].to_s.match(/vsphere|esx|vmware|el_6|ubuntu/)
    vmx_info.push('ehci.present,TRUE')
    vmx_info.push('ehci.pciSlotNumber,35')
    vmx_info.push('ehci:0.deviceType,video')
    vmx_info.push('ehci:0.parent,-1')
    vmx_info.push('ehci:0.port,0')
    vmx_info.push('ehci:0.present,TRUE')
  end
  vmx_info.push('sound.present,TRUE')
  vmx_info.push('sound.virtualDev,hdaudio') if values['os-type'].to_s.match(/windows7srv-64/)
  vmx_info.push('sound.fileName,-1')
  vmx_info.push('sound.autodetect,TRUE')
  #  vmx_info.push("mks.enable3d,TRUE")
  vmx_info.push('pciBridge0.present,TRUE')
  vmx_info.push('pciBridge4.present,TRUE')
  vmx_info.push('pciBridge4.virtualDev,pcieRootPort')
  vmx_info.push('pciBridge4.functions,8')
  vmx_info.push('pciBridge5.present,TRUE')
  vmx_info.push('pciBridge5.virtualDev,pcieRootPort')
  vmx_info.push('pciBridge5.functions,8')
  vmx_info.push('pciBridge6.present,TRUE')
  vmx_info.push('pciBridge6.virtualDev,pcieRootPort')
  vmx_info.push('pciBridge6.functions,8')
  vmx_info.push('pciBridge7.present,TRUE')
  vmx_info.push('pciBridge7.virtualDev,pcieRootPort')
  vmx_info.push('pciBridge7.functions,8')
  vmx_info.push('vmci0.present,TRUE')
  vmx_info.push('hpet0.present,TRUE')
  #  vmx_info.push("usb.vbluetooth.startConnected,FALSE")
  vmx_info.push('tools.syncTime,TRUE')
  vmx_info.push("guestOS,#{guest_os}")
  vmx_info.push("nvram,#{values['name']}.nvram")
  vmx_info.push('virtualHW.productCompatibility,hosted')
  vmx_info.push('tools.upgrade.policy,upgradeAtPowerCycle')
  vmx_info.push('powerType.powerOff,soft')
  vmx_info.push('powerType.powerOn,soft')
  vmx_info.push('powerType.suspend,soft')
  vmx_info.push('powerType.reset,soft')
  vmx_info.push("displayName,#{values['name']}")
  vmx_info.push("extendedConfigFile,#{values['name']}.vmxf")
  vmx_info.push("uuid.bios,#{values['uuid']}")
  vmx_info.push("uuid.location,#{values['uuid']}")
  #  vmx_info.push("uuid.action,keep")
  #  vmx_info.push("replay.supported,FALSE")
  #  vmx_info.push("replay.filename,")
  vmx_info.push('pciBridge0.pciSlotNumber,17')
  vmx_info.push('pciBridge4.pciSlotNumber,21')
  vmx_info.push('pciBridge5.pciSlotNumber,22')
  vmx_info.push('pciBridge6.pciSlotNumber,23')
  vmx_info.push('pciBridge7.pciSlotNumber,24')
  vmx_info.push('scsi0.pciSlotNumber,16')
  #  vmx_info.push("usb.pciSlotNumber,32")
  vmx_info.push('ethernet0.pciSlotNumber,33')
  vmx_info.push('sound.pciSlotNumber,34')
  #  vmx_info.push("vmci0.pciSlotNumber,36")
  if values['host-os-unamep'].to_s.match(/arm/)
    vmx_info.push('monitor.phys_bits_used,36')
    vmx_info.push('cpuid.coresPerSocket,1')
    vmx_info.push('usb.pciSlotNumber,32')
    vmx_info.push('usb.present,TRUE')
    vmx_info.push('usb.vbluetooth.startConnected,TRUE')
    vmx_info.push('usb:1.deviceType,hub')
    vmx_info.push('usb:1.parent,-1')
    vmx_info.push('usb:1.port,1')
    vmx_info.push('usb:1.present,TRUE')
    vmx_info.push('usb:1.speed,2')
    vmx_info.push('usb_xhci.pciSlotNumber,192')
    vmx_info.push('usb_xhci.present,TRUE')
    vmx_info.push('usb_xhci:4.deviceType,hid')
    vmx_info.push('usb_xhci:4.parent,-1')
    vmx_info.push('usb_xhci:4.port,4')
    vmx_info.push('usb_xhci:4.present,TRUE')
    vmx_info.push('usb_xhci:6.deviceType,hub')
    vmx_info.push('usb_xhci:6.parent,-1')
    vmx_info.push('usb_xhci:6.port,6')
    vmx_info.push('usb_xhci:6.present,TRUE')
    vmx_info.push('usb_xhci:6.speed,2')
    vmx_info.push('usb_xhci:7.deviceType,hub')
    vmx_info.push('usb_xhci:7.parent,-1')
    vmx_info.push('usb_xhci:7.port,7')
    vmx_info.push('usb_xhci:7.present,TRUE')
    vmx_info.push('usb_xhci:7.speed,4')
  end
  #  if version >= 8
  #    vmx_info.push("sata0.pciSlotNumber,-1")
  #  else
  #    vmx_info.push("sata0.pciSlotNumber,37")
  #  end
  vmx_info.push('scsi0.sasWWID,50 05 05 63 9c 8f c0 c0') if values['os-type'].to_s.match(/windows7srv-64/)
  vmx_info.push('ethernet0.generatedAddressOffset,0')
  vmx_info.push('vmci0.id,-1176557972')
  #  vmx_info.push("vmotion.checkpointFBSize,134217728")
  vmx_info.push('cleanShutdown,TRUE')
  vmx_info.push('softPowerOff,FALSE')
  #  vmx_info.push("usb:1.speed,2")
  #  vmx_info.push("usb:1.present,TRUE")
  #  vmx_info.push("usb:1.deviceType,hub")
  #  vmx_info.push("usb:1.port,1")
  #  vmx_info.push("usb:1.parent,-1")
  #  vmx_info.push("checkpoint.vmState,")
  #  vmx_info.push("sata0:1.startConnected,FALSE")
  #  vmx_info.push("usb:0.present,TRUE")
  #  vmx_info.push("usb:0.deviceType,hid")
  #  vmx_info.push("usb:0.port,0")
  #  vmx_info.push("usb:0.parent,-1")
  if values['dhcp'] == true
    vmx_info.push("ethernet0.GeneratedAddress,#{values['mac']}")
  else
    vmx_info.push("ethernet0.address,#{values['mac']}")
  end
  vmx_info.push('floppy0.present,FALSE')
  #  vmx_info.push("serial0.present,TRUE")
  #  vmx_info.push("serial0.fileType,pipe")
  #  vmx_info.push("serial0.yieldOnMsrRead,TRUE")
  #  vmx_info.push("serial0.startConnected,TRUE")
  #  vmx_info.push("serial0.fileName,/tmp/#{values['name']}")
  #  vmx_info.push("scsi0:0.redo,")
  vmx_info.push('vmotion.checkpointFBSize,134217728')
  vmx_info.push('vmotion.checkpointSVGAPrimarySize,268435456')
  vmx_info.push('vmotion.svga.graphicsMemoryKB,262144')
  vmx_info.push('vmotion.svga.mobMaxSize,268435456')
  vmx_info.push('vsvga.vramSize,268435456')
  if values['os-type'].to_s.match(/vmkernel/)
    vmx_info.push('monitor.virtual_mmu,hardware')
    vmx_info.push('monitor.virtual_exec,hardware')
    vmx_info.push('vhv.enable,TRUE')
    vmx_info.push('monitor_control.restrict_backdoor,TRUE')
  end
  vmx_info.push("numvcpus,#{values['vcpus']}") if values['vcpus'].to_i > 1
  #  vmx_info.push("isolation.tools.hgfs.disable,FALSE")
  #  vmx_info.push("hgfs.mapRootShare,TRUE")
  #  vmx_info.push("hgfs.linkRootShare,TRUE")
  if version >= 8
    vmx_info.push('acpi.smbiosVersion2.7,FALSE') unless values['host-os-unamep'].to_s.match(/arm/)
    vmx_info.push('numa.autosize.vcpu.maxPerVirtualNode,2')
    vmx_info.push('numa.autosize.cookie,10001')
    vmx_info.push("migrate.hostlog,#{values['name']}-#{values['mac']}.hlog")
  end
  if values['sharedfolder'].to_s.match(/[a-z,A-Z]/)
    vmx_info.push('sharedFolder0.present,TRUE')
    vmx_info.push('sharedFolder0.enabled,TRUE')
    vmx_info.push('sharedFolder0.readAccess,TRUE')
    vmx_info.push('sharedFolder0.writeAccess,TRUE')
    vmx_info.push("sharedFolder0.hostPath,#{values['sharedfolder']}")
    vmx_info.push("sharedFolder0.guestName,#{values['sharedmount']}")
    vmx_info.push('sharedFolder0.expiration,never')
    vmx_info.push('sharedFolder.maxNum,1')
  end
  if values['enablevnc'] == true
    vmx_info.push('RemoteDisplay.vnc.enabled,TRUE')
    vmx_info.push('RemoteDisplay.vnc.port,5900')
    vmx_info.push("RemoteDisplay.vnc.password,#{values['vncpassword']}")
    #    vmx_info.push("signal.suspendOnHUP=TRUE"  )
    #    vmx_info.push("signal.powerOffOnTERM,TRUE")
  end
  vmx_info.push("vmxstats.filename,#{values['name']}.scoreboard")
  [values, vmx_info]
end
