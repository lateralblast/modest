# Parallels VM support code

# Add CDROM to Parallels VM

def attach_file_to_parallels_vm(options)
  message = "Information:\tAttaching Image "+options['file']+" to "+options['name']
  command = "prlctl set \"#{options['name']}\" --device-set cdrom0 --image \"#{options['file']}\""
  execute_command(options,message,command)
  return
end

# Detach CDROM from Parallels VM

def detach_file_from_parallels_vm(options)
  message = "Information:\tAttaching Image "+options['file']+" to "+options['name']
  command = "prlctl set \"#{options['name']}\" --device-set cdrom0 --disable\""
  execute_command(options,message,command)
  return
end

# Get Parallels VM OS

def get_parallels_os(vm_name)
	message = "Information:\tDetermining OS for "+vm_name
	command = "prlctl list --info \"#{vm_name}\" |grep '^OS' |cut -f2 -d:"
	os_info = execute_command(options,message,command)
	case os_info
	when /rhel/
		os_info = "RedHat Enterprise Linux"
	end
	return os_info
end

# Get Parallels VM status

def get_parallels_vm_status(options)
  message = "Information:\tDetermining status of Parallels VM "+options['name']
  command = "prlctl list \"#{options['name']}\" --info |grep '^Status' |grep ^State |cut -f2 -d:"
  status  = execute_command(options,message,command)
  status  = status.chomp.gsub(/\s+/,"")
  return status
end

# Get a list of all VMs

def get_all_parallels_vms(options)
  message = "Information:\tListing Parallels VMs"
  command = "prlctl list --all |grep -v UUID |awk '{print $4}'"
  vm_list = execute_command(options,message,command)
  vm_list = vm_list.split("\n")
  return vm_list
end

# List all VMs

def list_all_parallels_vms(options)
  vm_list = get_all_parallels_vms(options)
  handle_output(options,"")
  handle_output(options,"Parallels VMS:")
  handle_output(options,"")
  vm_list.each do |vm_name|
    os_info = %x[prlctl list --info "#{vm_name}" |grep '^OS' |cut -f2 -d:].chomp.gsub(/^\s+/,"")
    case os_info
    when /rhel/
    	os_info = "RedHat Enterprise Linux"
    end
    handle_output(options,"#{vm_name}\t#{os_info}")
  end
  handle_output(options,"")
  return
end

# List running VMs

def list_running_parallels_vms(options)
  message = "Information:\tListing running VMs"
  command = "prlctl list --all |grep running |awk '{print $4}'"
	vm_list = execute_command(options,message,command)
  vm_list = vm_list.split("\n")
  handle_output(options,"")
  handle_output(options,"Running Parallels VMS:")
  handle_output(options,"")
  vm_list.each do |vm_name|
    os_info = get_parallels_os(vm_name)
    handle_output(options,"#{vm_name}\t#{os_info}")
  end
  handle_output(options,"")
  return
end

# List stopped VMs

def list_stopped_parallels_vms(options)
  message = "Information:\tListing stopped VMs"
  command = "prlctl list --all |grep stopped |awk '{print $4}'"
  vm_list = execute_command(options,message,command)
  vm_list = vm_list.split("\n")
  vm_list = %x[prlctl list --all |grep stopped |awk '{print $4}'].split("\n")
  handle_output(options,"")
  handle_output(options,"Stopped Parallels VMS:")
  handle_output(options,"")
  vm_list.each do |vm_name|
    os_info = get_parallels_os(vm_name)
    handle_output(options,"#{vm_name}\t#{os_info}")
  end
  handle_output(options,"")
  return
end

# List Parallels VMs

def list_parallels_vms(search_string)
  dom_type    = "Parallels VM"
  dom_command = "prlctl list --all |grep -v UUID |awk '{print $4}'"
  list_doms(dom_type,dom_command)
  return
end

# Clone Parallels VM

def clone_parallels_vm(options)
  exists = check_parallels_vm_exists(options)
  if exists.match(/no/)
    handle_output(options,"Warning:\tParallels VM #{options['name']} does not exist")
    quit(options)
  end
  message = "Information:\tCloning Parallels VM "+options['name']+" to "+options['clone']
  command = "prlctl clone \"#{options['name']}\" --name \"#{options['clone']}\""
  execute_command(options,message,command)
  if options['ip'].to_s.match(/[0-9]/)
    add_hosts_entry(options['clone'],options['ip'])
  end
  if options['mac'].to_s.match(/[0-9,a-z,A-Z]/)
    change_parallels_vm_mac(options['clone'],options['mac'])
  end
  return
end

# Get Parallels VM disk

def get_parallels_disk(options)
  message = "Information:\tDetermining directory for Parallels VM "+options['name']
  command = "prlctl list #{options['name']} --info |grep image |awk '{print $4}' |cut -f2 -d="
  vm_dir  = execute_command(options,message,command)
  vm_dir  = vm_dir.chomp.gsub(/'/,"")
  return vm_dir
end

# Get Parallels VM UUID

def get_parallels_vm_uuid(options)
  message = "Information:\tDetermining UUID for Parallels VM "+options['name']
  command = "prlctl list --info \"#{options['name']}\" |grep '^ID' |cut -f2 -d:"
  vm_uuid = vm_uuid.chomp.gsub(/^\s+/,"")
  vm_uuid = execute_command(options,message,command)
  return vm_uuid
end

# Check Parallels hostonly network

def check_parallels_hostonly_network(options)
  message = "Information:\tChecking Parallels hostonly network exists"
  command = "prlsrvctl net list |grep ^prls |grep host-only |awk '{print $1}'"
  if_name = execute_command(options,message,command)
  if_name = if_name.chomp
  if not if_name.match(/prls/)
    message  = "Information:\tDetermining possible Parallels host-only network interface name"
    command  = "prlsrvctl net list |grep ^prls"
    if_count = execute_command(options,message,command)
    if_count = if_count.grep(/prls/).count.to_s
    if_name  = "prlsnet"+if_count
    message = "Information:\tPlumbing Parallels hostonly network "+if_name
    command = "prlsrvctl net add #{if_name} --type host-only"
    execute_command(options,message,command)
  end
  message  = "Information:\tDetermining Parallels network interface name"
  command  = "prlsrvctl net list |grep ^#{if_name} |awk '{print $3}'"
  nic_name = execute_command(options,message,command)
  nic_name = nic_name.chomp
  message = "Information:\tChecking Parallels hostonly network "+nic_name+" has address "+options['hostonlyip']
  command = "ifconfig #{nic_name} |grep inet |awk '{print $2}"
  host_ip = execute_command(options,message,command)
  host_ip = host_ip.chomp
  if not host_ip.match(/#{options['hostonlyip']}/)
    message = "Information:\tConfiguring Parallels hostonly network "+nic_name+" with IP "+options['hostonlyip']
    command = "sudo sh -c 'ifconfig #{nic_name} inet #{options['hostonlyip']} netmask #{options['netmask']} up'"
    execute_command(options,message,command)
  end
  gw_if_name = get_gw_if_name(options)
  if options['osrelease'].split(".")[0].to_i < 14
    check_osx_nat(gw_if_name,if_name)
  else
    check_osx_pfctl(options,gw_if_name,if_name)
  end
	return nic_name
end

# Get Parallels VM directory

def get_parallels_vm_dir(options)
	return options['vmdir']
end

# Control Parallels VM

def control_parallels_vm(options)
  current_status = get_parallels_vm_status(options)
  if not current_status.match(/#{options['status']}/)
    message = "Information:\tSetting Parallels VM status for "+options['name']+" to "+
    if options['status'].to_s.match(/stop/)
      command = "prlctl #{options['status']} \"#{options['name']}\" --kill"
    else
      command = "prlctl #{options['status']} \"#{options['name']}\""
    end
    execute_command(options,message,command)
  end
  return
end

# Stop Parallels VM

def stop_parallels_vm(options)
  control_parallels_vm(options['name'],"stop")
  return
end

# Stop Parallels VM

def restart_parallels_vm(options)
  control_parallels_vm(options['name'],"stop")
  boot_parallels_vm(options)
  return
end

# Routine to add serial to a VM

def add_serial_to_parallels_vm(options)
  message = "Information:\tAdding Serial Port to "+options['name']
  command = "prlctl set \"#{options['name']}\" --add-device serial --ouput /tmp/#{options['name']}"
  execute_command(options,message,command)
  return
end

# Configure a Generic Virtual Box VM

def configure_other_parallels_vm(options)
  options['os-type']="other"
  configure_parallels_vm(options)
  return
end

# Configure a AI Virtual Box VM

def configure_ai_parallels_vm(options)
  options['os-type']="solaris-11"
  configure_parallels_vm(options)
  return
end

# Configure a Jumpstart Virtual Box VM

def configure_js_parallels_vm(options)
  options['os-type'] = "solaris-10"
  configure_parallels_vm(options)
  return
end

# Configure a RedHat or Centos Kickstart Parallels VM

def configure_ks_parallels_vm(options)
  options['os-type'] = "rhel"
  configure_parallels_vm(options)
  return
end

# Configure a Preseed Ubuntu Parallels VM

def configure_ps_parallels_vm(options)
  options['os-type'] = "ubuntu"
  configure_parallels_vm(options)
  return
end

# Configure a AutoYast SuSE Parallels VM

def configure_ay_parallels_vm(options)
  options['os-type'] = "opensuse"
  configure_parallels_vm(options)
  return
end

# Configure a vSphere Parallels VM

def configure_vs_parallels_vm(options)
  options['os-type'] = "other"
  configure_parallels_vm(options)
  return
end

# Configure an OpenBSD VM

def configure_ob_parallels_vm(options)
  options['os-type'] = "freebsd-4"
  configure_parallels_vm(options)
  return
end

# Configure a NetBSD VM

def configure_nb_parallels_vm(options)
  options['os-type'] = "freebsd-4"
  configure_parallels_vm(options)
  return
end

# Change Parallels VM Memory

def change_parallels_vm_mem(options)
  message = "Information:\tSetting Parallels VM "+options['name']+" RAM to "+options['memory']
  command = "prlctl set #{options['name']} --memsize #{options['memory']}"
  execute_command(options,message,command)
  return
end

# Change Parallels VM Cores

def change_parallels_vm_cpu(options)
  message = "Information:\tSetting Parallels VM "+options['name']+" CPUs to "+options['vcpus']
  command = "prlctl set #{options['name']} --cpus #{options['vcpus']}"
  execute_command(options,message,command)
  return
end

# Change Parallels VM MAC address

def change_parallels_vm_mac(options)
  message = "Information:\tSetting Parallels VM "+options['name']+" MAC address to "+options['mac']
  if options['mac'].to_s.match(/:/)
    options['mac'] = options['mac'].gsub(/:/,"")
  end
  command = "prlctl set #{options['name']} --device-set net0 #{options['mac']}"
  execute_command(options,message,command)
  return
end

# Get Parallels VM MAC address

def get_parallels_vm_mac(options)
  message = "Information:\tGetting MAC address for "+options['name']
  command = "prlctl list --info #{options['name']} |grep net0 |grep mac |awk '{print $4}' |cut -f2 -d="
  vm_mac  = execute_command(options,message,command)
  vm_mac  = vm_mac.chomp
  vm_mac  = vm_mac.gsub(/\,/,"")
  return vm_mac
end

# Check Parallels is installed

def check_parallels_is_installed(options)
  options['status'] = "no"
  app_dir = "/Applications/Parallels Desktop.app"
  if File.directory?(app_dir)
    options['status'] = "yes"
  end
  return options['status']
end

# Boot Parallels VM

def boot_parallels_vm(options)
  check_parallels_hostonly_network(options)
  exists = check_parallels_vm_exists(options)
  if exists.match(/no/)
    handle_output(options,"Warning:\tParallels VM #{options['name']} does not exist")
    quit(options)
  end
  message = "Starting:\tVM "+options['name']
  if options['text'] == true or options['serial'] == true
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
    %x[prlctl start #{options['name']}]
  else
    command = "prlctl start #{options['name']} ; open \"/Applications/Parallels Desktop.app\" &"
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
  return
end

# Routine to register a Parallels VM

def register_parallels_vm(options)
  message = "Registering Parallels VM "+options['name']
  command = "prlctl create \"#{options['name']}\" --ostype \"#{options['os-type']}\""
  execute_command(options,message,command)
  return
end

# Configure a Parallels VM

def configure_parallels_vm(options)
  check_parallels_is_installed(options)
  if options['vmnet'].to_s.match(/hostonly/)
    nic_name = check_parallels_hostonly_network(options)
  end
  disk_name   = get_parallels_disk(options)
  socket_name = "/tmp/#{options['name']}"
  check_parallels_vm_doesnt_exist(options)
  register_parallels_vm(options['name'],options['os-type'])
  add_serial_to_parallels_vm(options)
  change_parallels_vm_mem(options['name'],options['memory'])
  change_parallels_vm_cpu(options['name'],options['vcpus'])
  if options['file'].to_s.match(/[0-9]|[a-z]/)
    attach_file_to_parallels_vm(options['name'],options['file'])
  end
  if options['mac'].to_s.match(/[0-9]/)
    change_parallels_vm_mac(options['name'],options['mac'])
  else
    options['mac'] = get_parallels_vm_mac(options)
  end
  handle_output(options,"Created Parallels VM #{options['name']} with MAC address #{options['mac']}")
  return
end

# List Linux KS Parallels VMs

def list_ks_parallels_vms(options)
  search_string = "rhel|fedora|fc|centos|redhat|mandriva"
  list_parallels_vms(search_string)
  return
end

# List Linux Preseed Parallels VMs

def list_ps_parallels_vms(options)
  search_string = "ubuntu|debian"
  list_parallels_vms(search_string)
end

# List Solaris Kickstart Parallels VMs

def list_js_parallels_vms(options)
  search_string = "solaris-10"
  list_parallels_vms(search_string)
  return
end

# List Solaris AI Parallels VMs

def list_ai_parallels_vms(options)
  search_string = "solaris-11"
  list_parallels_vms(search_string)
  return
end

# List Linux Autoyast Parallels VMs

def list_ay_parallels_vms(options)
  search_string = "opensuse"
  list_parallels_vms(search_string)
  return
end

# List vSphere Parallels VMs

def list_vs_parallels_vms(options)
  search_string = "other"
  list_parallels_vms(search_string)
  return
end

# Check Parallels VM doesn't exit

def check_parallels_vm_doesnt_exist(options)
  exists = check_parallels_vm_exists(options)
  if exists.match(/yes/)
    handle_output(options,"Parallels VM #{options['name']} already exists")
    quit(options)
  end
  return
end

# Check Parallels VM exists

def check_parallels_vm_exists(options)
  set_vmrun_bin(options)
  exists  = "no"
  vm_list = get_all_parallels_vms(options)
  vm_list.each do |vm_name|
    if vm_name.match(/^#{options['name']}$/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

# Unconfigure a Parallels VM

def unconfigure_parallels_vm(options)
  check_parallels_is_installed(options)
  exists = check_parallels_vm_exists(options)
  if exists.match(/no/)
    handle_output(options,"Parallels VM #{options['name']} does not exist")
    quit(options)
  end
  stop_parallels_vm(options)
  sleep(5)
  message = "Deleting Parallels VM "+options['name']
  command = "prlctl delete #{options['name']}"
  execute_command(options,message,command)
  return
end
