# Common KVM functions

# Check KVM NAT

def check_kvm_natd(options,if_name)
  return
end

# Check KVM hostonly network

def check_kvm_hostonly_network(options,if_name)
  gw_if_name = get_gw_if_name(options)
  check_nat(options,gw_if_name,if_name)
  return
end

# Check network bridge exists

def check_kvm_network_bridge_exists(options)
  exists  = false
  net_dev = options['bridge'].to_s
  message = "Information:\tChecking KVM network device #{net_dev} exists"
  command = "virsh net-list --all |grep #{net_dev}"
  output  = execute_command(options,message,command)
  if output.match(/#{net_dev}/)
    exists = true
  end
  return exists
end

# Connect to KVM VM

def connect_to_kvm_vm(options)
  exists  = check_kvm_vm_exists(options)
  vm_name = options['name'].to_s
  if exists == true
    handle_output(options, "Information:\t Connecting to KVM VM #{vm_name}")
    exec("virsh console #{vm_name}")
  else
    handle_output(options,"Warning:\tKVM VM #{vm_name} doesn't exist")
    quit(options)
  end
end

# Import Packer KVM image

def import_packer_kvm_vm(options)
  (exists,images_dir) = check_packer_vm_image_exists(options)
  if exists == false
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

# Check KVM is installed

def check_kvm_is_installed(options)
  if_name = get_vm_if_name(options)
  if options['vmnet'].to_s.match(/hostonly/) && options['bridge'].to_s.match(/virbr/)
    check_kvm_hostonly_network(options,if_name)
  end
  if not options['host-os-name'].match(/Linux/)
    handle_output(options,"Warning:\tPlatform does not support KVM")
    quit(options)
  end
  gw_if_name = get_gw_if_name(options)
  message = "Information:\tChecking KVM is installed"
  command = "ifconfig -a |grep #{gw_if_name}"
  output  = execute_command(options,message,command)
  if !output.match(/#{gw_if_name}/) || !File.exist?("/usr/bin/virt-install")
    message = "Information:\tInstalling KVM"
    handle_output(options,message)
    pkg_list = [ "qemu-kvm", "qemu-utils", "libvirt-clients", "libvirt-daemon-system", "bridge-utils", "virt-manager", "cloud-image-utils", "libosinfo-bin" ]
    pkg_list.each do |pkg_name|
      install_linux_package(options,pkg_name)
    end
  else
    if_name = get_vm_if_name(options)
    check_linux_nat(options,gw_if_name,if_name)
  end
  if !File.exist?("/usr/bin/cloud-localds")
    pkg_name = "cloud-image-utils"
    install_linux_package(options,pkg_name)
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
  dir_name   = "/etc/qemu"
  file_name  = "/etc/qemu/bridge.conf"
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
  input_file = options['inputfile'].to_s
  if !File.exist?(input_file) or options['inputfile'] == options['empty']
    handle_output(options,"Warning:\tFile #{input_file} does not exist")
    quit(options)
  end
  if options['outputfile'] == options['empty'] or not options['input_file'].to_s.match(/#{options['name'].to_s}/)
    handle_output(options,"Warning:\tNo output file specified")
    if options['name'] == options['empty']
      handle_output(options,"Warning:\tNo client name specified")
      quit(options)
    else
      file_name = options['imagedir'].to_s+"/"+options['name'].to_s+".qcow2" 
      options['outputfile'] = file_name
      output_file = options['outputfile']
      handle_output(options,"Information:\tSetting output file to #{output_file}")
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
    command = "qemu-img convert -O qcow2 -f qcow2 #{input_file} #{output_file}"
    output  = execute_command(options,message,command)
  else
    handle_output(options,"Warning:\tFile #{output_file} already exists")
    handle_output(options,"Information:\tUse --force option to delete file")
    quit(options)
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

# Check KVM network bridge

def check_kvm_network_bridge(options)
  exists = check_network_bridge_exists(options)
  if exists == false
    net_dev = options['bridge'].to_s
    handle_output(options,"Warning:\tNetwork bridge #{net_dev} doesn't exist")
    quit(options)
  end
  exists = check_kvm_network_bridge_exists(options)
  if exists == true 
    message = "Warning:\tKVM VM #{options['bridge']} already exists"
    handle_output(options,message)
    quit(options)
  end
  kvm_bridge  = options['bridge'].to_s
  bridge_file = "/tmp/"+kvm_bridge.to_s+"_bridge.xml"
  if File.exist?(bridge_file)
    File.delete(bridge_file)
  end
  file = File.open(bridge_file,"w")
  file.write("<network>\n")
  file.write("  <name>#{kvm_bridge}</name>\n")
  file.write("  <forward mode=\"bridge\"/>\n")
  file.write("  <bridge name=\"#{kvm_bridge}\" />\n")
  file.write("</network>\n")
  file.close
  print_contents_of_file(options,"",bridge_file)
  if File.exist?(bridge_file)
    message = "Information:\tImporting KVM bridge config for #{kvm_bridge}" 
    command = "virsh net-define #{bridge_file}"
    execute_command(options,message,command)
    message = "Information:\tStarting KVM bridge #{kvm_bridge} config"
    command = "virsh net-start #{kvm_bridge}"
    execute_command(options,message,command)
    message = "Information:\tSetting KVM bridge #{kvm_bridge} config to autostart"
    command = "virsh net-autostart #{kvm_bridge}"
    execute_command(options,message,command)
  end
end

# Configure a KVM client

def configure_kvm_client(options)
  add_hosts_entry(options)
  exists = check_kvm_vm_exists(options)
  if exists == true
    message = "Warning:\t KVM VM #{options['name']} already exists"
    handle_output(options,message)
    quit(options)
  end
  exists = check_kvm_network_bridge_exists(options)
  if exists == false 
    message = "Warning:\tKVM VM #{options['bridge']} doesn't exists"
    handle_output(options,message)
    quit(options)
  end
  exists = check_network_bridge_exists(options)
  if exists == false
    net_dev = options['bridge'].to_s
    handle_output(options,"Warning:\tNetwork bridge #{net_dev} doesn't exist")
    quit(options)
  end
  if options['import'] == true
    optons = configure_kvm_import_client(options)
  else
    if options['type'].to_s.match(/packer/)
      options = configure_packer_client(options)
    else
      handle_output(options,"Warning:\tNo KVM VM type specified")
      quit(options)
    end
  end
  return options
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
  command = "sudo qemu-img create -O qcow2 -f qcow2 #{disk_file} #{disk_size}"
  execute_command(options,message,command)
  return
end

# Configure a KVM VM via import

def configure_kvm_import_client(options)
  if options['file'] == options['empty'] || !File.exist?(options['file'].to_s)
    handle_output(options,"Warning:\tNo file specified")
    quit(options)
  end
  if options['os-type'] == options['empty'] or options['os-variant'] == options['empty'] or options['method'] == options['empty']
    options = get_install_service_from_file(options)
  end
  check_kvm_is_installed(options)
  if !options['disk1'] == options['none']
    options['disk'] = options['disk1'].to_s+" "+options['disk2'].to_s
  else
    if options['disk'].to_s.match(/ /)
      if !options['disk'].to_s.match(/--disk/)
        if options['file'].to_s.match(/cloud/)
          options['disk1'] = options['virtdir']+"/"+options['name'].to_s+"-seed.qcow2,device=cdrom"
          options['disk2'] = options['virtdir']+"/"+options['name'].to_s+".qcow2,device=disk"
          options['disk']  = options['disk1']+" --disk "+options['disk2']
          options['disk1'] = options['disk1'].split(/\,/)[0]
          options['disk2'] = options['disk2'].split(/\,/)[0]
        else
          temp_disk = options['disk'].to_s.split(/ /)[0]+" --disk "+options['disk'].to_s.split(/ /)[1]
          options['disk'] = temp_disk
        end
      end
    else
      if options['file'].to_s.match(/cloud/)
        options['disk1'] = options['virtdir']+"/"+options['name'].to_s+"-seed.qcow2,device=cdrom"
      else
        options['disk1'] = options['file']+",device=cdrom"
      end
      options['disk2'] = options['virtdir']+"/"+options['name'].to_s+".qcow2,device=disk"
      if !options['type'].to_s.match(/packer/)
        options['disk'] = options['disk2']
      else
        options['disk'] = options['disk1']+" --disk "+options['disk2']
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
    else
      if !options['cloudfile'].to_s.match(/#{options['name'].to_s}/)
        options['cloudfile'] = options['virtdir'].to_s+"/"+options['name']+"-seed.qcow2"
      end
    end
    if options['outputfile'] == options['empty']
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
        if options['method'] == "ci"
#          options['inputfile'] = options['disk1']
#        else
          options['inputfile'] = options['file']
        convert_kvm_image(options)
        end
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
    case options['os-variant'].to_s
    when /ubuntu/
      options = populate_ps_questions(options)
    when /rhel/
      options = populate_ks_questions(options)
    when /vs/
      options = populate_vs_questions(options)
    when /win/
      options = populate_pe_questions(options)
    else
      handle_output(options,"Warning:\tNo OS Variant specified")
      quit(options)
    end
    file = File.open(config_file, 'w')
    file.write("#cloud-config\n")
    file.write("hostname: #{options['q_struct']['hostname'].value}\n")
    file.write("groups:\n")
    file.write("  - #{options['q_struct']['admin_username'].value}: #{options['q_struct']['admin_username'].value}\n")
    file.write("users:\n")
    file.write("  - default\n")
    file.write("  - name: #{options['q_struct']['admin_username'].value}\n")
    file.write("    gecos: #{options['q_struct']['admin_fullname'].value}\n")
    file.write("    primary_group: #{options['q_struct']['admin_username'].value}\n")
    file.write("    groups: users\n")
    file.write("    shell: /bin/bash\n")
    file.write("    passwd: #{options['q_struct']['admin_crypt'].value}\n")
    file.write("    sudo: ALL=(ALL) NOPASSWD:ALL\n")
    file.write("    lock_passwd: false\n")
    file.write("packages:\n")
    packages = options['q_struct']['additional_packages'].value.split(" ")
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
    if options['dnsmasq'] == true
      file.write("late_commands:\n")
      file.write("  - sudo systemctl disable systemd-resolved\n")
      file.write("  - sudo systemctl stop systemd-resolved\n")
      file.write("  - sudo rm /etc/resolv.conf\n")
      if options['nameserver'].to_s.match(/\,/)
        nameservers = options['nameserver'].to_s.split("\,")
        nameservers.each do |nameserver|
          file.write("  - echo 'nameserver #{nameserver}' > /etc/resolv.conf\n")
        end
      else
        nameserver = options['nameserver'].to_s
        file.write("  - echo 'nameserver #{nameserver}' > /etc/resolv.conf\n")
      end
    end
    file.close
    print_contents_of_file(options,"",config_file)
    check_file_owner(options,config_file,options['uid'])
    if options['q_struct']['static'].value == "true"
      file = File.open(network_file, 'w')
        file.write("version: 2\n")
        file.write("ethernets:\n")
        file.write("  #{options['q_struct']['interface'].value}:\n")
        file.write("    dhcp4: false\n")
        file.write("    addresses: [ #{options['q_struct']['ip'].value}/#{options['cidr']} ]\n")
        file.write("    gateway4: #{options['q_struct']['gateway'].value}\n")
        file.write("    nameservers:\n")
        file.write("      addresses: [ #{options['q_struct']['nameserver'].value} ]\n")
        file.write("\n")
      file.close
      print_contents_of_file(options,"",network_file)
      check_file_owner(options,network_file,options['uid'])
      command = "cloud-localds --network-config "+network_file+" "+options['cloudfile'].to_s+" "+config_file
    else
      input_file = File.basename(options['inputfile'].to_s)
      input_file = options['imagedir'].to_s+"/"+input_file
      command = "cloud-localds "+input_file+" "+config_file
    end
    message = "Information:\tConfiguring image file #{options['inputfile'].to_s}"
    output  = execute_command(options,message,command)
    if !File.exist?(options['cloudfile'].to_s) 
      if options['q_struct']['static'].value == "true"
        handle_output(options,"Warning:\tFile #{options['cloudfile'].to_s} does not exist")
        quit(options)
      end
    end
  end
  if options['pxe'] == true
    options['boot'] = "network,menu=on"
  end
  if options['network'].to_s.match(/bridge/)
    if !options['network'].to_s.match(/br[0-9]/)
      handle_output(options,"Warning:\tBridge not set")
      quit(options)
    end
  end
  params  = [ "name", "vcpus", "memory", "cdrom", "cpu", "os-variant", "host-device", "machine", "mac", "import",
              "extra-args", "connect", "metadata", "initrd-inject", "unattended", "install", "boot", "idmap", "disk", "network",
              "graphics", "controller", "serial", "parallel", "channel", "console", "hostdev", "filesystem", "sound",
              "watchdog", "video", "smartcard", "redirdev", "memballoon", "tpm", "rng", "panic", "memdev", "vsock", "iothreads",
              "seclabel", "cputune", "memtune", "blkiotune", "memorybacking", "features", "clock", "pm", "events", "resource",
              "sysinfo", "qemu-commandline", "launchSecurity", "hvm", "paravirt", "container", "virt-type", "arch", "machine",
              "autostart", "transient", "destroy-on-exit", "wait", "noautoconsole", "noreboot", "print-xml", "dry-run", "check" ]
  message = "Information:\tChecking virt-install version"
  command = "virt-install --version"
  version = execute_command(options,message,command)
  if !version.match(/4\.[0-9]/)
    params.append("os-type")
  end
  command = "virt-install"
  params.each do |param|
    if options[param] != options['empty'] && options[param] != "text"
      if options[param] != true && options[param] != false
        command = command + " --"+param+" "+options[param].to_s
        if !options['param'].to_s.match(/[0-9]|[a-z]|[A-Z]/)
          handle_output(options,"Warning:\tOption #{param} not set")
          quit(options)
        end
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
  if options['nobuild'] == false
    output  = execute_command(options,message,command)
  else
    handle_output(options,"Information:\tNot building VM #{options['name'].to_s}")
    handle_output(options,"Information:\tTo build VM execute comannd below")
    handle_output(options,"Command:\t#{command}")
  end 
  return options
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
  if options['search'] == "all" or options['search'] == options['empty']
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
