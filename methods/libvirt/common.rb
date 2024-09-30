# Common KVM functions

# Check KVM NAT

def check_kvm_natd(values, if_name)
  return
end

# Check KVM hostonly network

def check_kvm_hostonly_network(values, if_name)
  check_kvm_network_bridge(values)
  gw_if_name = get_gw_if_name(values)
  check_nat(values, gw_if_name, if_name)
  return
end

# Check network bridge exists

def check_kvm_network_bridge_exists(values)
  exists  = false
  net_dev = values['bridge'].to_s
  message = "Information:\tChecking KVM network device #{net_dev} exists"
  if values['vmnetwork'].to_s.match(/bridge/)
    command = "ip link show #{net_dev}"
    output  = execute_command(values, message, command)
    if output.match(/does not exist/)
      exists = false
    else
      exists = true
    end
  else
    command = "virsh net-list --all |grep #{net_dev}"
    output  = execute_command(values, message, command)
    if output.match(/#{net_dev}/)
      if output.match(/inactive/)
        warning_message(values, "Default KVM network #{net_dev}is not active")
        output  = execute_command(values,message, command)
        message = "Information:\tSetting KVM default network to autostart"
        command = "virsh net-autostart #{net_dev}"
        execute_command(values, message, command)
        message = "Information:\tStarting KVM default network"
        command = "virsh net-start #{net_dev}"
        execute_command(values, message, command)
      end
      exists = true
    end
  end
  return exists
end

# Connect to KVM VM

def connect_to_kvm_vm(values)
  exists  = check_kvm_vm_exists(values)
  vm_name = values['name'].to_s
  if exists == true
    information_message(values, " Connecting to KVM VM #{vm_name}")
    exec("virsh console #{vm_name}")
  else
    warning_message(values, "KVM VM #{vm_name} doesn't exist")
    quit(values)
  end
end

# Import Packer KVM image

def import_packer_kvm_vm(values)
  (exists, images_dir) = check_packer_vm_image_exists(values)
  if exists == false
    warning_message(values, "Packer KVM VM QCOW image for #{values['name']} does not exist")
    quit(values)
  end
  if not values['os-variant'].to_s.match(/[a-z]/) or values['os-variant'].to_s.match(/none/)
    warning_message(values, "OS Variant (--os-variant) not specified")
    quit(values)
  end
  qcow_file = images_dir+"/"+values['name']
  if File.exist?(qcow_file)
    message = "Information:\tImporting QCOW file for Packer KVM VM "+values['name']
    if values['text'] == true or values['headless'] == true or values['serial'] == true
      command = "virt-install --import --noreboot --os-variant #{values['os-variant']} --name #{values['name']} --memory #{values['memory']} --disk \"#{qcow_file}\" --graphics none --network bridge=#{values['bridge']}"
    else
      command = "virt-install --import --noreboot --os-variant #{values['os-variant']} --name #{values['name']} --memory #{values['memory']} --disk \"#{qcow_file}\" --graphics vnc --network bridge=#{values['bridge']}"
    end
    execute_command(values, message, command)
  else
    warning_message(values, "QCOW file for Packer KVM VM #{values['name']} does not exist")
    quit(values)
  end
  return
end

# Check KVM permissions

def check_kvm_permissions(values)
  user_name = values['user'].to_s
  group_names = [ "kvm", "libvirt", "libvirt-qemu", "libvirt-dnsmasq" ]
  for group_name in group_names
    check_group_member(values, user_name, group_name)
  end
  file_name  = "/dev/kvm"
  file_owner = "root"
  file_group = "kvm"
  file_perms = "660"
  check_file_owner(values, file_name, file_owner)
  check_file_group(values, file_name, file_group)
  check_file_perms(values, file_name, file_perms)
  file_name = "/etc/udev/rules.d/65-kvm.rules"
  file_owner = "root"
  file_group = "root"
  file_perms = "660"
  if not File.exist?(file_name)
    message = "Information:\tCreating file #{file_name}"
    verbose_message(values, message)
    %x[sudo sh -c "echo 'KERNEL==\"kvm\", GROUP=\"kvm\", MODE=\"0660\"' > #{file_name}"]
  end
  check_file_owner(values, file_name, file_owner)
  check_file_group(values, file_name, file_group)
  check_file_perms(values, file_name, file_perms)
  file_name = "/etc/firewalld/firewalld.conf"
  if values['host-lsb-description'].to_s.match(/Endeavour|Arch/) and File.exist?(file_name)
    temp_name = "/tmp/firewalld.conf"
    param = "FirewallBackend"
    value = "iptables"
    message = "Information:\tChecking #{param} is set to #{value} in #{file_name}"
    verbose_message(values, message)
    check = %x[cat #{file_name} |grep ^FirewallBackend ].chomp
    if not check.match(/#{value}/)
      message = "Warning:\tParameter #{param} is no set to #{value} in #{file_name}"
      verbose_message(values, message)
      message = "Information:\tSetting parameter #{param} to #{value} in #{file_name}"
      verbose_message(values, message)
      %x[sudo cp #{file_name} #{file_name}.orig]
      %x[sudo sh -c 'cat #{file_name} | grep -v "^#{param}=nftables" >> #{temp_name}']
      %x[sudo sh -c 'echo "#{param}=#{value}" >> #{temp_name}']
      %s[sudo sh -c 'cat #{temp_name} > #{file_name}']
    end
  end
  file_name = "/etc/modprobe.d/qemu-system-x86.conf"
  if not File.exist?(file_name)
    message = "Warning:\tFile #{file_name} does not exist"
    verbose_message(values, message)
    message = "Information:\tCreating #{file_name}"
    verbose_message(values, message)
    %x[sudo sh -c "echo \"values kvm ignore_msrs=1 report_ignored_msrs=0\" >> #{file_name}"]
    %x[sudo sh -c "echo \"values kvm_intel nested=1 enable_apicv=0 ept=1\" >> #{file_name}"]
  end
  return
end

# Check KVM is installed

def check_kvm_is_installed(values)
  pkg_list = []
  virt_bin = ""
  if values['host-os-unamea'].to_s.match(/Darwin/)
    [ "/usr/local/bin/virt-install", "/usr/local/homebrew/bin/virt-install", "/opt/homebrew/" ].each do |test_bin|
      if File.exist?(test_bin)
        virt_bin = test_bin
      end
    end
  else
    virt_bin="/usr/bin/virt-install"
  end
  if not File.exist?(virt_bin)
    message = "Information:\tInstalling KVM"
    verbose_message(values, message)
    if values['host-os-unamea'].to_s.match(/Ubuntu/)
      pkg_list= [ "qemu", "libvirt", "libvirt-glib", "libvirt-python", "virt-manager", "libosinfo" ]
    end
    if values['host-os-unamea'].to_s.match(/Ubuntu/)
      pkg_list = [ "qemu-kvm", "qemu-utils", "libvirt-clients", "libvirt-daemon-system", "bridge-utils", "virt-manager", "virt-viewer", "cloud-image-utils", "libosinfo-bin" ]
    end
    if values['host-lsb-description'].to_s.match(/Endeavour|Arch/)
      pkg_list = [ "qemu-full", "virt-manager", "virt-viewer", "dnsmasq", "bridge-utils", "libguestfs", "ebtables", "vde2", "openbsd-netcat", "cloud-image-utils", "libosinfo" ]
    end
    pkg_list.each do |pkg_name|
      install_linux_package(values, pkg_name)
    end
  end
  if not values['host-os-uname'].match(/Linux|Darwin/)
    warning_message(values, "Platform does not support KVM")
    quit(values)
  end
  if values['host-lsb-description'].to_s.match(/Endeavour|Arch/)
    enable_service(values, "libvirtd.service")
    start_service(values, "libvirtd.service")
  end
  if values['host-os-uname'].match(/Linux/)
    check_kvm_default_network(values)
    check_kvm_permissions(values)
    if_name = get_vm_if_name(values)
    if values['vmnet'].to_s.match(/hostonly/) and values['bridge'].to_s.match(/virbr/) or values['action'].to_s.match(/check/)
      check_kvm_hostonly_network(values, if_name)
    end
  end
  gw_if_name = get_gw_if_name(values)
  message = "Information:\tChecking KVM is installed"
  command = "ifconfig -a |grep #{gw_if_name}"
  output  = execute_command(values, message, command)
  if_name = get_vm_if_name(values)
  check_nat(values, gw_if_name, if_name)
  if !values['host-os-uname'].match(/Darwin/)
    if not File.exist?("/usr/bin/cloud-localds")
      pkg_name = "cloud-image-utils"
      install_linux_package(values, pkg_name)
    end
    message = "Information:\tChecking user is a member of the kvm group"
    command = "groups"
    output  = execute_command(values, message, command)
    if not output.match(/kvm/)
      message = "Information:\tAdding user to kvm group"
      command = "usermod -a -G #{values['kvmgroup']} #{values['user']}"
      output  = execute_command(values, message, command)
    end
    information_message(values, "Checking QEMU configuration directory")
    dir_name   = "/etc/qemu"
    file_name  = "/etc/qemu/bridge.conf"
    file_array = []
    file_line  = "allow "+values['bridge'].to_s
    file_array.append(file_line)
    if !File.exist?(file_name)
      file_mode = "w"
      check_dir_exists(values, dir_name)
      check_dir_owner(values, dir_name, values['uid'])
      check_file_perms(values, file_name, file_mode)
      write_array_to_file(values, file_array, file_name, file_mode)
      check_dir_owner(values, dir_name, "0")
      file_gid  = get_group_gid(values, values['kvmgroup'])
      file_mode = "w"
      check_file_group(values, file_name, file_gid)
      check_file_owner(values, file_name, "0")
      check_file_perms(values, file_name, file_mode)
      restart_linux_service(values, "libvirtd.service")
    else
      if !File.readlines(file_name).grep(/#{file_line}/).any?
        file_mode = "a"
        check_dir_owner(values, dir_name, values['uid'])
        check_file_owner(values, file_name, values['uid'])
        write_array_to_file(values, file_array, file_name, file_mode)
        check_dir_owner(values, dir_name, "0")
        check_file_owner(values, file_name, "0")
        restart_linux_service(values, "libvirtd.service")
      end
    end
    bridge_helper = "/usr/lib/qemu/qemu-bridge-helper"
    if !FileTest.setuid?(bridge_helper)
      message = "Information:\tSetting setuid bit on #{bridge_helper}"
      command = "chmod u+s #{bridge_helper}"
      output  = execute_command(values, message, command)
    end
  end
  return
end

def resize_kvm_image(values)
  file = values['file'].to_s
  size = values['size'].to_s
  size = size.gsub(/g/, "G")
  if !size.match(/G$/)
    size = size+"G"
  end
  if !File.exist?(file)
    warning_message(values, "File #{file} does not exist")
    quit(values)
  end
  message = "Information:\tResizing disk #{output} to #{size}"
  command = "qemu-img resize #{output} #{size}"
  output  = execute_command(values, message, command)
  return
end

def convert_kvm_image(values)
  input_file = values['inputfile'].to_s
  if !File.exist?(input_file) or values['inputfile'] == values['empty']
    warning_message(values, "File #{input_file} does not exist")
    quit(values)
  end
  if values['outputfile'] == values['empty'] or not values['input_file'].to_s.match(/#{values['name'].to_s}/)
    warning_message(values, "No output file specified")
    if values['name'] == values['empty']
      warning_message(values, "No client name specified")
      quit(values)
    else
      file_name = values['imagedir'].to_s+"/"+values['name'].to_s+".qcow2"
      values['outputfile'] = file_name
      output_file = values['outputfile']
      information_message(values, "Setting output file to #{output_file}")
    end
  end
  path_name = Pathname.new(values['outputfile'].to_s).dirname
  if !File.exist?(path_name)
    information_message(values, "Checking KVM output directory")
    check_dir_exists(values, path_name)
    check_dir_owner(values, path_name, values['uid'])
  end
  if !File.exist?(output_file) or values['force'] == true
    message = "Information:\tCreating VM disk #{output_file} from #{input_file}"
    command = "qemu-img convert -O qcow2 -f qcow2 #{input_file} #{output_file}"
    output  = execute_command(values, message, command)
  else
    warning_message(values, "File #{output_file} already exists")
    information_message(values, "Use --force option to delete file")
    quit(values)
  end
  size = values['size'].to_s
  size = size.gsub(/g/, "G")
  if !size.match(/G$/)
    size = size+"G"
  end
  message = "Information:\tResizing disk #{output_file} to #{size}"
  command = "qemu-img resize #{output_file} #{size}"
  output  = execute_command(values, message, command)
  return
end

# Check KVM network default interface

def check_kvm_default_network(values)
  message = "Information:\tChecking KVM default network is active"
  command = "virsh net-list --all |grep default"
  output  = execute_command(values,message, command)
  if output.match(/inactive/)
    warning_message(values, "Default KVM network is not active")
    output  = execute_command(values,message, command)
    message = "Information:\tSetting KVM default network to autostart"
    command = "virsh net-autostart default"
    execute_command(values, message, command)
    message = "Information:\tStarting KVM default network"
    command = "virsh net-start default"
    execute_command(values, message, command)
  end
  return
end

# Check KVM network bridge

def check_kvm_network_bridge(values)
  exists = check_kvm_network_bridge_exists(values)
  if exists == true
    message = "Information:\tKVM VM #{values['bridge']} already exists"
    verbose_message(values, message)
    exists = check_network_bridge_exists(values)
    if exists == false
      net_dev = values['bridge'].to_s
      warning_message(values, "Network bridge #{net_dev} does not exist")
      check_kvm_default_network(values)
    end
  else
    kvm_bridge  = values['bridge'].to_s
    bridge_file = "/tmp/"+kvm_bridge.to_s+"_bridge.xml"
    if File.exist?(bridge_file)
      File.delete(bridge_file)
    end
    file = File.open(bridge_file, "w")
    file.write("<network>\n")
    file.write("  <name>#{kvm_bridge}</name>\n")
    file.write("  <forward mode=\"bridge\"/>\n")
    file.write("  <bridge name=\"#{kvm_bridge}\" />\n")
    file.write("</network>\n")
    file.close
    print_contents_of_file(values, "", bridge_file)
    if File.exist?(bridge_file)
      message = "Information:\tImporting KVM bridge config for #{kvm_bridge}"
      command = "virsh net-define #{bridge_file}"
      execute_command(values, message, command)
      message = "Information:\tSetting KVM bridge #{kvm_bridge} config to autostart"
      command = "virsh net-autostart #{kvm_bridge}"
      execute_command(values, message, command)
      message = "Information:\tStarting KVM bridge #{kvm_bridge} config"
      command = "virsh net-start #{kvm_bridge}"
      execute_command(values, message, command)
    end
  end
end

# Configure a KVM client

def configure_kvm_client(values)
  if values['method'] = "ci"
    values = populate_ci_questions(values)
  else
    values = populate_ks_questions(values)
  end
  values = process_questions(values)
  add_hosts_entry(values)
  exists = check_kvm_vm_exists(values)
  if exists == true
    message = "Warning:\t KVM VM #{values['name']} already exists"
    verbose_message(values, message)
    quit(values)
  end
  if !values['host-os-uname'].match(/Darwin/)
    exists = check_kvm_network_bridge_exists(values)
    if exists == false
      message = "Warning:\tKVM network bridge #{values['bridge']} does not exists"
      verbose_message(values, message)
      quit(values)
    end
    exists = check_network_bridge_exists(values)
    if exists == false
      net_dev = values['bridge'].to_s
      warning_message(values, "Network bridge #{net_dev} does not exist")
      quit(values)
    end
  end
  if values['import'] == true
    optons = configure_kvm_import_client(values)
  else
    if values['type'].to_s.match(/packer/)
      values = configure_packer_client(values)
    else
      warning_message(values, "No KVM VM type specified")
      quit(values)
    end
  end
  return values
end

# Create a KVM disk

def create_kvm_disk(values)
  disk_size = values['size'].to_s
  if !values['outputfile'] == values['empty']
    disk_file = values['outputfile']
  else
    disk_file = values['virtdir']+"/"+values['name'].to_s+".qcow2"
  end
  message = "Information:\tCreating KVM disk #{disk_file} of size #{disk_size}"
  command = "sudo qemu-img create -O qcow2 -f qcow2 #{disk_file} #{disk_size}"
  execute_command(values, message, command)
  return
end

# Configure a KVM VM via import

def configure_kvm_import_client(values)
  if values['file'] == values['empty'] || !File.exist?(values['file'].to_s)
    values['notice'] = true
    warning_message(values, "No file specified")
    list_kvm_images(values)
    quit(values)
  end
  if values['os-type'] == values['empty'] or values['os-variant'] == values['empty'] or values['method'] == values['empty']
    values = get_install_service_from_file(values)
  end
  check_kvm_is_installed(values)
  if !values['disk1'] == values['none']
    values['disk'] = values['disk1'].to_s+" "+values['disk2'].to_s
  else
    if values['disk'].to_s.match(/ /)
      if !values['disk'].to_s.match(/--disk/)
        if values['file'].to_s.match(/cloud/)
          values['disk1'] = values['virtdir']+"/"+values['name'].to_s+"-seed.qcow2,device=cdrom"
          values['disk2'] = values['virtdir']+"/"+values['name'].to_s+".qcow2,device=disk"
          values['disk']  = values['disk1']+" --disk "+values['disk2']
          values['disk1'] = values['disk1'].split(/\,/)[0]
          values['disk2'] = values['disk2'].split(/\,/)[0]
        else
          temp_disk = values['disk'].to_s.split(/ /)[0]+" --disk "+values['disk'].to_s.split(/ /)[1]
          values['disk'] = temp_disk
        end
      end
    else
      if values['file'].to_s.match(/cloud/)
        values['disk1'] = values['virtdir']+"/"+values['name'].to_s+"-seed.qcow2,device=cdrom"
      else
        values['disk1'] = values['file']+",device=cdrom"
      end
      values['disk2'] = values['virtdir']+"/"+values['name'].to_s+".qcow2,device=disk"
      if !values['type'].to_s.match(/packer/)
        values['disk'] = values['disk2']
      else
        values['disk'] = values['disk1']+" --disk "+values['disk2']
      end
    end
  end
  if values['file'] == values['empty'] && values['pxe'] == false
    warning_message(values, "No install file specified")
    quit(values)
  end
  if values['import'] == true and values['method'] == "ci"
    if values['cloudfile'] == values['empty']
      if values['disk'].to_s.match(/ /)
        cloud_file = values['disk'].to_s.split(" ")[0]
        if cloud_file.match(/\,/)
          cloud_file = cloud_file.split(",")[0]
        end
        if cloud_file.match(/=/)
          cloud_file = cloud_file.split("=")[1]
        end
        values['cloudfile'] = cloud_file
      else
        warning_message(values, "No cloud config image specified")
      end
    else
      if !values['cloudfile'].to_s.match(/#{values['name'].to_s}/)
        values['cloudfile'] = values['virtdir'].to_s+"/"+values['name']+"-seed.qcow2"
      end
    end
    if values['outputfile'] == values['empty']
      output_file = values['disk'].to_s.split(" ")[2]
      if output_file.match(/,/)
        output_file = output_file.split(",")[0]
      end
      if output_file.match(/=/)
        output_file = output_file.split("=")[1]
      end
      values['outputfile'] = output_file
    end
    if values['inputfile'] != values['empty']
      convert_kvm_image(values)
    else
      if values['file'] != values['empty']
        if values['method'] == "ci"
#          values['inputfile'] = values['disk1']
#        else
          values['inputfile'] = values['file']
        convert_kvm_image(values)
        end
      end
    end
  else
    create_kvm_disk(values)
  end
  if values['method'] == "ci"
    values = populate_ps_questions(values)
    if values['configfile'] == values['empty']
      config_path = Pathname.new(values['outputfile'].to_s)
      config_path = config_path.dirname.to_s
      if values['dryrun'] == true
        config_file  = "#{values['tmpdir']}/#{values['name'].to_s}_cloud.cfg"
        network_file = "#{values['tmpdir']}/#{values['name'].to_s}_network.cfg"
      else
        config_file  = "#{config_path}/#{values['name'].to_s}_cloud.cfg"
        network_file = "#{config_path}/#{values['name'].to_s}_network.cfg"
      end
    end
    if values['networkfile'] == values['empty']
      config_path  = Pathname.new(values['outputfile'].to_s)
      config_path  = config_path.dirname.to_s
      if values['dryrun'] == true
        network_file = "#{values['tmpdir']}/#{values['name'].to_s}_network.cfg"
      else
        network_file = "#{config_path}/#{values['name'].to_s}_network.cfg"
      end
    end
    information_message(values, "Checking KVM output directory")
    check_dir_exists(values, config_path)
    check_dir_owner(values, config_path, values['uid'])
    if values['method'].to_s.match(/ci/)
      populate_ci_questions(values)
    else
      case values['os-variant'].to_s
      when /ubuntu/
        values = populate_ps_questions(values)
      when /rhel|esx|vmware/
        values = populate_ks_questions(values)
      when /vs/
        values = populate_vs_questions(values)
      when /win/
        values = populate_pe_questions(values)
      else
        warning_message(values, "No OS Variant specified")
        quit(values)
      end
    end
#    if values['method'].to_s.match(/ci/)
#      file = File.open(network_file, 'w')
#      file.write("ethernets:\n")
#      file.write("  #{values['answers']['vmnic'].value}\n")
#      file.write("    dhcp4: #{values['answers']['dhcp'].value}\n")
#      if values['answers']['dhcp'].value.to_s.match(/true/)
#        file.write("    addresses: [#{values['answers']['ip'].value}/#{values['answers']['cidr'].value}]\n")
#        file.write("      nameservers: #{values['answers']['nameserver'].value}\n")
#        file.write("    routes:\n")
#        file.write("    - to: default\n")
#        file.write("      via: #{values['answers']['vmgateway'].value}\n")
#      end
#      file.write("version: 2\n")
#      file.close
#
#    end    
    file = File.open(config_file, 'w')
    file.write("#cloud-config\n")
    file.write("hostname: #{values['answers']['hostname'].value}\n")
    file.write("groups:\n")
    file.write("  - #{values['answers']['admin_username'].value}: #{values['answers']['admin_username'].value}\n")
    file.write("users:\n")
    file.write("  - default\n")
    file.write("  - name: #{values['answers']['admin_username'].value}\n")
    file.write("    gecos: #{values['answers']['admin_fullname'].value}\n")
    file.write("    primary_group: #{values['answers']['admin_username'].value}\n")
    if values['method'].to_s.match(/ci/)
      file.write("    groups: #{values['answers']['groups'].value}\n")
      file.write("    shell: #{values['answers']['shell'].value}\n")
    else
      file.write("    groups: users\n")
      file.write("    shell: /bin/bash\n")
    end
    file.write("    passwd: \"#{values['answers']['admin_crypt'].value}\"\n")
    if values['method'].to_s.match(/ci/)
      file.write("    ssh-authorized-keys:\n")
      file.write("      - \"#{values['answers']['ssh-authorized-keys'].value}\"\n")
      file.write("    sudo: #{values['answers']['sudoers'].value}\n")
      file.write("    lock_passwd: #{values['answers']['lock_passwd'].value}\n")
    else
      file.write("    lock_passwd: false\n")
    end
    file.write("packages:\n")
    packages = values['answers']['additional_packages'].value.split(" ")
    packages.each do |package|
      file.write("  - #{package}\n")
    end
    file.write("growpart:\n")
    if values['method'].to_s.match(/ci/)
      file.write("  mode: #{values['answers']['growpartmode'].value}\n")
      growpart_device = values['answers']['growpartdevice'].value
      file.write("  devices: ['#{growpart_device}']\n")
      if values['reboot'] == true
        file.write("power_state:\n")
        file.write("  mode: #{values['answers']['powerstate'].value}\n")
      end
    else
      file.write("  mode: auto\n")
      file.write("  devices: ['/']\n")
      if values['reboot'] == true
        file.write("power_state:\n")
        file.write("  mode: reboot\n")
      end
    end
    if values['dnsmasq'] == true
      file.write("runcmd:\n")
      file.write("  - systemctl disable systemd-resolved\n")
      file.write("  - systemctl stop systemd-resolved\n")
      file.write("  - rm /etc/resolv.conf\n")
      if values['answers']['nameserver'].value.to_s.match(/\,/)
        nameservers = values['answers']['nameserver'].value.to_s.split("\,")
        nameservers.each do |nameserver|
          file.write("  - echo 'nameserver #{nameserver}' >> /etc/resolv.conf\n")
        end
      else
        nameserver = values['answers']['nameserver'].value.to_s
        file.write("  - echo 'nameserver #{nameserver}' >> /etc/resolv.conf\n")
      end
    end
    file.close
    print_contents_of_file(values, "", config_file)
    check_file_owner(values, config_file, values['uid'])
    if values['answers']['static'].value.to_s.match(/true/) or values['answers']['dhcp'].value.to_s.match(/false/)
      file = File.open(network_file, 'w')
        file.write("version: 2\n")
        file.write("ethernets:\n")
        file.write("  #{values['answers']['interface'].value}:\n")
        file.write("    dhcp4: false\n")
        file.write("    addresses: [ #{values['answers']['ip'].value}/#{values['cidr']} ]\n")
        file.write("    gateway4: #{values['answers']['gateway'].value}\n")
        file.write("    nameservers:\n")
        file.write("      addresses: [ #{values['answers']['nameserver'].value} ]\n")
        file.write("\n")
      file.close
      print_contents_of_file(values, "", network_file)
      check_file_owner(values, network_file, values['uid'])
      command = "cloud-localds --network-config "+network_file+" "+values['cloudfile'].to_s+" "+config_file
    else
      input_file = File.basename(values['inputfile'].to_s)
      input_file = values['imagedir'].to_s+"/"+input_file
      command = "cloud-localds "+input_file+" "+config_file
    end
    message = "Information:\tConfiguring image file #{values['inputfile'].to_s}"
    output  = execute_command(values, message, command)
    if !File.exist?(values['cloudfile'].to_s)
      if values['answers']['static'].value == "true"
        warning_message(values, "File #{values['cloudfile'].to_s} does not exist")
        quit(values)
      end
    end
  end
  if values['pxe'] == true
    values['boot'] = "network,menu=on"
  end
  if values['network'].to_s.match(/bridge/)
    if !values['network'].to_s.match(/br[0-9]/)
      warning_message(values, "Bridge not set")
      quit(values)
    end
  end
  params  = [ "name", "vcpus", "memory", "cdrom", "cpu", "os-variant", "host-device", "machine", "mac", "import",
              "extra-args", "connect", "metadata", "initrd-inject", "unattended", "install", "boot", "idmap", "disk", "network",
              "graphics", "controller", "serial", "parallel", "channel", "console", "hostdev", "filesystem", "sound",
              "watchdog", "video", "smartcard", "redirdev", "memballoon", "tpm", "rng", "panic", "memdev", "vsock", "iothreads",
              "seclabel", "cputune", "memtune", "blkiotune", "memorybacking", "features", "clock", "pm", "events", "resource",
              "sysinfo", "qemu-commandline", "launchSecurity", "hvm", "paravirt", "container", "virt-type", "arch", "machine",
              "autostart", "transient", "destroy-on-exit", "wait", "noautoconsole", "noreboot", "print-xml", "dryrun", "check" ]
  message = "Information:\tChecking virt-install version"
  command = "virt-install --version"
  version = execute_command(values, message, command)
  if !version.match(/4\.[0-9]/)
    params.append("os-type")
  end
  command = "virt-install"
  params.each do |param|
    if values[param] != values['empty'] && values[param] != "text"
      if values[param] != true && values[param] != false
        command = command + " --"+param+" "+values[param].to_s
        if !values['param'].to_s.match(/[0-9]|[a-z]|[A-Z]/)
          warning_message(values, "Option #{param} not set")
          quit(values)
        end
      else
        if values[param] != false
          command = command + " --"+param
        end
      end
    else
      if param.match(/graphics/)
        command = command + " --"+param+" "+values[param].to_s
      end
    end
  end
  if values['reboot'] == false
    command = command + " --noreboot"
  end
  message = "Information:\tCreating VM #{values['name'].to_s}"
  if values['build'] == true
    output  = execute_command(values, message, command)
  else
    information_message(values, "Not building VM #{values['name'].to_s}")
    information_message(values, "To build VM execute comannd below")
    verbose_message(values, "Command:\t#{command}")
  end
  return values
end

# List KVM VMs

def list_kvm_vms(values)
  if !values['host-os-uname'].match(/Linux|Darwin/)
    return
  end
  command   = "virsh list --all"
  message   = "Information:\tGetting list of KVM VMs"
  file_list = execute_command(values, message, command)
  file_list = file_list.split("\n")
  if values['search'] == "all" or values['search'] == values['empty']
    type_string = "KVM"
  else
    type_string = values['search'].capitalize+" KVM"
  end
  if file_list.length > 0
    if values['output'].to_s.match(/html/)
      verbose_message(values, "<h1>Available #{type_string} VMs</h1>")
      verbose_message(values, "<table border=\"1\">")
      verbose_message(values, "<tr>")
      verbose_message(values, "<th>VM</th>")
      verbose_message(values, "<th>IP</th>")
      verbose_message(values, "<th>MAC</th>")
      verbose_message(values, "<th>Status</th>")
      verbose_message(values, "</tr>")
    else
      verbose_message(values, "")
      verbose_message(values, "Available #{type_string} clients:")
      verbose_message(values, "")
    end
    file_list.each do |entry|
      if not entry.match(/^---|^ Id/)
        (header, values['id'], values['name'], values['status']) = entry.split(/\s+/)
        values = get_kvm_vm_mac(values)
        values = get_kvm_vm_ip(values)
        values['status'] = values['status'].to_s.gsub(/shut/, "shutdown")
        if values['mac'] == nil
          values['mac'] = ""
        end
        if values['ip'] == nil
          values['ip'] = ""
        end
        if values['search'] == "all" or values['search'] == "none" or entry.match(/#{values['search']}/)
          if values['output'].to_s.match(/html/)
            verbose_message(values, "<tr>")
            verbose_message(values, "<td>#{values['name'].to_s}</td>")
            verbose_message(values, "<td>#{values['ip'].to_s}</td>")
            verbose_message(values, "<td>#{values['mac'].to_s}</td>")
            verbose_message(values, "<td>#{values['status'].to_s}</td>")
            verbose_message(values, "</tr>")
          else
            output = values['name'].to_s+" ip="+values['ip'].to_s+" mac="+values['mac'].to_s+" status="+values['status'].to_s
            verbose_message(values, output)
          end
        end
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_message(values, "</table>")
    else
      verbose_message(values, "")
    end
  end
  return
end
