# frozen_string_literal: true

# Parallels VM support code

# Add CDROM to Parallels VM

def attach_file_to_parallels_vm(values)
  message = "Information:\tAttaching Image #{values['file']} to #{values['name']}"
  command = "prlctl set \"#{values['name']}\" --device-set cdrom0 --image \"#{values['file']}\""
  execute_command(values, message, command)
  nil
end

# Detach CDROM from Parallels VM

def detach_file_from_parallels_vm(values)
  message = "Information:\tAttaching Image #{values['file']} to #{values['name']}"
  command = "prlctl set \"#{values['name']}\" --device-set cdrom0 --disable\""
  execute_command(values, message, command)
  nil
end

# Get Parallels VM OS

def get_parallels_os(values, vm_name)
  message = "Information:\tDetermining OS for #{vm_name}"
  command = "prlctl list --info \"#{vm_name}\" |grep '^OS' |cut -f2 -d:"
  os_info = execute_command(values, message, command)
  case os_info
  when /rhel/
    os_info = 'RedHat Enterprise Linux'
  end
  os_info
end

# Get Parallels VM status

def get_parallels_vm_status(values)
  message = "Information:\tDetermining status of Parallels VM #{values['name']}"
  command = "prlctl list \"#{values['name']}\" --info |grep '^Status' |grep ^State |cut -f2 -d:"
  status  = execute_command(values, message, command)
  status.chomp.gsub(/\s+/, '')
end

# Get a list of all VMs

def get_all_parallels_vms(values)
  message = "Information:\tListing Parallels VMs"
  command = "prlctl list --all |grep -v UUID |awk '{print $4}'"
  vm_list = execute_command(values, message, command)
  vm_list.split("\n")
end

# List all VMs

def list_all_parallels_vms(values)
  vm_list = get_all_parallels_vms(values)
  verbose_message(values, '')
  verbose_message(values, 'Parallels VMS:')
  verbose_message(values, '')
  vm_list.each do |vm_name|
    os_info = `prlctl list --info "#{vm_name}" |grep '^OS' |cut -f2 -d:`.chomp.gsub(/^\s+/, '')
    case os_info
    when /rhel/
      os_info = 'RedHat Enterprise Linux'
    end
    verbose_message(values, "#{vm_name}\t#{os_info}")
  end
  verbose_message(values, '')
  nil
end

# List running VMs

def list_running_parallels_vms(values)
  message = "Information:\tListing running VMs"
  command = "prlctl list --all |grep running |awk '{print $4}'"
  vm_list = execute_command(values, message, command)
  vm_list = vm_list.split("\n")
  verbose_message(values, '')
  verbose_message(values, 'Running Parallels VMS:')
  verbose_message(values, '')
  vm_list.each do |vm_name|
    os_info = get_parallels_os(values, vm_name)
    verbose_message(values, "#{vm_name}\t#{os_info}")
  end
  verbose_message(values, '')
  nil
end

# List stopped VMs

def list_stopped_parallels_vms(values)
  message = "Information:\tListing stopped VMs"
  command = "prlctl list --all |grep stopped |awk '{print $4}'"
  vm_list = execute_command(values, message, command)
  vm_list.split("\n")
  vm_list = `prlctl list --all |grep stopped |awk '{print $4}'`.split("\n")
  verbose_message(values, '')
  verbose_message(values, 'Stopped Parallels VMS:')
  verbose_message(values, '')
  vm_list.each do |vm_name|
    os_info = get_parallels_os(values, vm_name)
    verbose_message(values, "#{vm_name}\t#{os_info}")
  end
  verbose_message(values, '')
  nil
end

# List Parallels VMs

def list_parallels_vms(values)
  dom_type = 'Parallels VM'
  if values['search']
    if (values['search'] == values['empty']) || values['search'].to_s.match(/all/)
      dom_command = "prlctl list --all |grep -v UUID |awk '{print $4}'"
    else
      search_string = values['search'].to_s
      dom_command   = "prlctl list --all |grep -v UUID |awk '{print $4}' |grep '#{search_string}'"
    end
  else
    dom_command = "prlctl list --all |grep -v UUID |awk '{print $4}'"
  end
  list_doms(values, dom_type, dom_command)
  nil
end

# Clone Parallels VM

def clone_parallels_vm(values)
  exists = check_parallels_vm_exists(values)
  if exists == false
    warning_message(values, "Parallels VM #{values['name']} does not exist")
    quit(values)
  end
  message = "Information:\tCloning Parallels VM #{values['name']} to #{values['clone']}"
  command = "prlctl clone \"#{values['name']}\" --name \"#{values['clone']}\""
  execute_command(values, message, command)
  add_hosts_entry(values['clone'], values['ip']) if values['ip'].to_s.match(/[0-9]/)
  change_parallels_vm_mac(values['clone'], values['mac']) if values['mac'].to_s.match(/[0-9,a-z,A-Z]/)
  nil
end

# Get Parallels VM disk

def get_parallels_disk(values)
  message = "Information:\tDetermining directory for Parallels VM #{values['name']}"
  command = "prlctl list #{values['name']} --info |grep image |awk '{print $4}' |cut -f2 -d="
  vm_dir  = execute_command(values, message, command)
  vm_dir.chomp.gsub(/'/, '')
end

# Get Parallels VM UUID

def get_parallels_vm_uuid(values)
  message = "Information:\tDetermining UUID for Parallels VM #{values['name']}"
  command = "prlctl list --info \"#{values['name']}\" |grep '^ID' |cut -f2 -d:"
  vm_uuid.chomp.gsub(/^\s+/, '')
  execute_command(values, message, command)
end

# Check Parallels hostonly network

def check_parallels_hostonly_network(values)
  message = "Information:\tChecking Parallels hostonly network exists"
  command = "prlsrvctl net list |grep ^prls |grep host-only |awk '{print $1}'"
  if_name = execute_command(values, message, command)
  if_name = if_name.chomp
  unless if_name.match(/prls/)
    message  = "Information:\tDetermining possible Parallels host-only network interface name"
    command  = 'prlsrvctl net list |grep ^prls'
    if_count = execute_command(values, message, command)
    if_count = if_count.grep(/prls/).count.to_s
    if_name  = "prlsnet#{if_count}"
    message = "Information:\tPlumbing Parallels hostonly network #{if_name}"
    command = "prlsrvctl net add #{if_name} --type host-only"
    execute_command(values, message, command)
  end
  message  = "Information:\tDetermining Parallels network interface name"
  command  = "prlsrvctl net list |grep ^#{if_name} |awk '{print $3}'"
  nic_name = execute_command(values, message, command)
  nic_name = nic_name.chomp
  message = "Information:\tChecking Parallels hostonly network #{nic_name} has address #{values['hostonlyip']}"
  command = "ifconfig #{nic_name} |grep inet |awk '{print $2}"
  host_ip = execute_command(values, message, command)
  host_ip = host_ip.chomp
  unless host_ip.match(/#{values['hostonlyip']}/)
    message = "Information:\tConfiguring Parallels hostonly network #{nic_name} with IP #{values['hostonlyip']}"
    command = "sudo sh -c 'ifconfig #{nic_name} inet #{values['hostonlyip']} netmask #{values['netmask']} up'"
    execute_command(values, message, command)
  end
  gw_if_name = get_gw_if_name(values)
  if values['host-os-unamer'].split('.')[0].to_i < 14
    check_osx_nat(gw_if_name, if_name)
  else
    check_osx_pfctl(values, gw_if_name, if_name)
  end
  nic_name
end

# Get Parallels VM directory

def get_parallels_vm_dir(values)
  values['vmdir']
end

# Control Parallels VM

def control_parallels_vm(values)
  current_status = get_parallels_vm_status(values)
  unless current_status.match(/#{values['status']}/)
    message = "Information:\tSetting Parallels VM status for " + values['name'] + ' to ' +
              command = if values['status'].to_s.match(/stop/)
                          "prlctl #{values['status']} \"#{values['name']}\" --kill"
                        else
                          "prlctl #{values['status']} \"#{values['name']}\""
                        end
    execute_command(values, message, command)
  end
  nil
end

# Stop Parallels VM

def stop_parallels_vm(values)
  values['status'] = 'stop'
  control_parallels_vm(values)
  nil
end

# Stop Parallels VM

def restart_parallels_vm(values)
  values['status'] = 'stop'
  control_parallels_vm(values)
  boot_parallels_vm(values)
  nil
end

# Routine to add serial to a VM

def add_serial_to_parallels_vm(values)
  message = "Information:\tAdding Serial Port to #{values['name']}"
  command = "prlctl set \"#{values['name']}\" --add-device serial --ouput /tmp/#{values['name']}"
  execute_command(values, message, command)
  nil
end

# Configure a Generic Virtual Box VM

def configure_other_parallels_vm(values)
  values['os-type'] = 'other'
  configure_parallels_vm(values)
  nil
end

# Configure a AI Virtual Box VM

def configure_ai_parallels_vm(values)
  values['os-type'] = 'solaris-11'
  configure_parallels_vm(values)
  nil
end

# Configure a Jumpstart Virtual Box VM

def configure_js_parallels_vm(values)
  values['os-type'] = 'solaris-10'
  configure_parallels_vm(values)
  nil
end

# Configure a RedHat or Centos Kickstart Parallels VM

def configure_ks_parallels_vm(values)
  values['os-type'] = 'rhel'
  configure_parallels_vm(values)
  nil
end

# Configure a Preseed Ubuntu Parallels VM

def configure_ps_parallels_vm(values)
  values['os-type'] = 'ubuntu'
  configure_parallels_vm(values)
  nil
end

# Configure a AutoYast SuSE Parallels VM

def configure_ay_parallels_vm(values)
  values['os-type'] = 'opensuse'
  configure_parallels_vm(values)
  nil
end

# Configure a vSphere Parallels VM

def configure_vs_parallels_vm(values)
  values['os-type'] = 'other'
  configure_parallels_vm(values)
  nil
end

# Configure an OpenBSD VM

def configure_ob_parallels_vm(values)
  values['os-type'] = 'freebsd-4'
  configure_parallels_vm(values)
  nil
end

# Configure a NetBSD VM

def configure_nb_parallels_vm(values)
  values['os-type'] = 'freebsd-4'
  configure_parallels_vm(values)
  nil
end

# Change Parallels VM Memory

def change_parallels_vm_mem(values)
  message = "Information:\tSetting Parallels VM #{values['name']} RAM to #{values['memory']}"
  command = "prlctl set #{values['name']} --memsize #{values['memory']}"
  execute_command(values, message, command)
  nil
end

# Change Parallels VM Cores

def change_parallels_vm_cpu(values)
  message = "Information:\tSetting Parallels VM #{values['name']} CPUs to #{values['vcpus']}"
  command = "prlctl set #{values['name']} --cpus #{values['vcpus']}"
  execute_command(values, message, command)
  nil
end

# Change Parallels VM MAC address

def change_parallels_vm_mac(values)
  message = "Information:\tSetting Parallels VM #{values['name']} MAC address to #{values['mac']}"
  values['mac'] = values['mac'].gsub(/:/, '') if values['mac'].to_s.match(/:/)
  command = "prlctl set #{values['name']} --device-set net0 #{values['mac']}"
  execute_command(values, message, command)
  nil
end

# Get Parallels VM MAC address

def get_parallels_vm_mac(values)
  message = "Information:\tGetting MAC address for #{values['name']}"
  command = "prlctl list --info #{values['name']} |grep net0 |grep mac |awk '{print $4}' |cut -f2 -d="
  vm_mac  = execute_command(values, message, command)
  vm_mac  = vm_mac.chomp
  vm_mac.gsub(/,/, '')
end

# Check Parallels is installed

def check_parallels_is_installed(values)
  values['status'] = 'no'
  app_dir = '/Applications/Parallels Desktop.app'
  if File.directory?(app_dir)
    values['status'] = 'yes'
    unless File.symlink?('/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/site-packages/prlsdkapi.pth')
      if !File.exist?('/Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages/prlsdkapi.pth')
        install_brew_pkg(values, 'parallels-virtualization-sdk')
      else
        command = 'ln -s /Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages/prlsdkapi.pth /Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/site-packages/prlsdkapi.pth'
        message = "Information:\tSymlinking Parallels SDK Library"
        execute_command(values, message, command)
      end
    end
  end
  values['status']
end

# Boot Parallels VM

def boot_parallels_vm(values)
  check_parallels_hostonly_network(values)
  exists = check_parallels_vm_exists(values)
  if exists == false
    warning_message(values, "Parallels VM #{values['name']} does not exist")
    quit(values)
  end
  message = "Starting:\tVM #{values['name']}"
  if (values['text'] == true) || (values['serial'] == true)
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
    `prlctl start #{values['name']}`
  else
    command = "prlctl start #{values['name']} ; open \"/Applications/Parallels Desktop.app\" &"
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
  nil
end

# Routine to register a Parallels VM

def register_parallels_vm(values)
  message = "Registering Parallels VM #{values['name']}"
  command = "prlctl create \"#{values['name']}\" --ostype \"#{values['os-type']}\""
  execute_command(values, message, command)
  nil
end

# Configure a Parallels VM

def configure_parallels_vm(values)
  check_parallels_is_installed(values)
  check_parallels_hostonly_network(values) if values['vmnet'].to_s.match(/hostonly/)
  get_parallels_disk(values)
  check_parallels_vm_doesnt_exist(values)
  register_parallels_vm(values['name'], values['os-type'])
  add_serial_to_parallels_vm(values)
  change_parallels_vm_mem(values['name'], values['memory'])
  change_parallels_vm_cpu(values['name'], values['vcpus'])
  attach_file_to_parallels_vm(values['name'], values['file']) if values['file'].to_s.match(/[0-9]|[a-z]/)
  if values['mac'].to_s.match(/[0-9]/)
    change_parallels_vm_mac(values['name'], values['mac'])
  else
    values['mac'] = get_parallels_vm_mac(values)
  end
  verbose_message(values, "Created Parallels VM #{values['name']} with MAC address #{values['mac']}")
  nil
end

# List Linux KS Parallels VMs

def list_ks_parallels_vms(values)
  values['search'] = 'rhel|fedora|fc|centos|redhat|mandriva'
  list_parallels_vms(values)
  nil
end

# List Linux Preseed Parallels VMs

def list_ps_parallels_vms(values)
  values['search'] = 'ubuntu|debian'
  list_parallels_vms(values)
end

# List Solaris Kickstart Parallels VMs

def list_js_parallels_vms(values)
  values['search'] = 'solaris-10'
  list_parallels_vms(values)
  nil
end

# List Solaris AI Parallels VMs

def list_ai_parallels_vms(values)
  values['search'] = 'solaris-11'
  list_parallels_vms(values)
  nil
end

# List Linux Autoyast Parallels VMs

def list_ay_parallels_vms(values)
  values['search'] = 'opensuse'
  list_parallels_vms(values)
  nil
end

# List vSphere Parallels VMs

def list_vs_parallels_vms(values)
  values['search'] = 'other'
  list_parallels_vms(values)
  nil
end

# Check Parallels VM does not exit

def check_parallels_vm_doesnt_exist(values)
  exists = check_parallels_vm_exists(values)
  if exists == true
    verbose_message(values, "Parallels VM #{values['name']} already exists")
    quit(values)
  end
  nil
end

# Check Parallels VM exists

def check_parallels_vm_exists(values)
  set_vmrun_bin(values)
  exists  = false
  vm_list = get_all_parallels_vms(values)
  vm_list.each do |vm_name|
    if vm_name.match(/^#{values['name']}$/)
      exists = true
      return exists
    end
  end
  exists
end

# Unconfigure a Parallels VM

def unconfigure_parallels_vm(values)
  check_parallels_is_installed(values)
  exists = check_parallels_vm_exists(values)
  if exists == false
    verbose_message(values, "Parallels VM #{values['name']} does not exist")
    quit(values)
  end
  stop_parallels_vm(values)
  sleep(5)
  message = "Deleting Parallels VM #{values['name']}"
  command = "prlctl delete #{values['name']}"
  execute_command(values, message, command)
  message = "Unregistering Parallels VM #{values['name']}"
  command = "prlctl unregister #{values['name']}"
  execute_command(values, message, command)
  nil
end
