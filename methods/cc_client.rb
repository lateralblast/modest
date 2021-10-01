# Code for Cloud Config client config
# E.g. installations via Ubuntu live CD

# Populate Cloud Config/Init User data file

def populate_cc_userdata(options)
  install_locale = $q_struct['locale'].value
  if install_locale.match(/\./)
    install_locale = install_locale.split(".")[0]
  end
  if options['livecd'] == true
    install_target  = "/target"
  else
    install_target  = ""
  end
  install_nameserver = $q_struct['nameserver'].value
  install_base_url   = "http://"+options['hostip']+"/"+options['name']
  install_target  = "/target"
  install_layout  = install_locale.split("_")[0]
  install_variant = install_locale.split("_")[1].downcase
  install_gateway = $q_struct['gateway'].value
  disable_dhcp  = $q_struct['disable_dhcp'].value
  install_name  = $q_struct['hostname'].value
  resolved_conf = "/etc/systemd/resolved.conf"
  admin_user    = $q_struct['admin_username'].value
  admin_group   = $q_struct['admin_username'].value
  admin_home    = "/home/"+$q_struct['admin_username'].value
  admin_crypt   = $q_struct['admin_crypt'].value
  install_nic   = $q_struct['interface'].value
  install_ip    = $q_struct['ip'].value
  install_cidr  = $q_struct['cidr'].value
  install_disk  = $q_struct['partition_disk'].value
  netplan_file  = "#{install_target}/etc/netplan/01-netcfg.yaml"
  locale_file   = "#{install_target}/etc/default/locales"
  grub_file = "#{install_target}/etc/default/grub"
  ssh_dir   = "#{install_target}/home/#{admin_user}/.ssh"
  auth_file = "#{ssh_dir}/authorized_keys"
  sudo_file = "#{install_target}/etc/sudoers.d/#{admin_user}"
  in_target = "curtin in-target --target=/target --"
  if options['vmnetwork'].to_s.match(/hostonly/)
    ks_ip = options['hostonlyip']
  else
    if disable_dhcp.match(/false/)
      ks_ip = options['hostonlyip']
    else
      ks_ip = options['hostip']
    end
  end
  if disable_dhcp.match(/false/)
    install_dhcp = "yes"
  else
    install_dhcp = "no"
  end
  if options['copykeys'] == true
    ssh_keyfile = options['sshkeyfile']
    if File.exist?(ssh_keyfile)
      ssh_key = %x[cat #{ssh_keyfile}].chomp
      ssh_dir = "#{install_target}/home/"+admin_user+"/.ssh"
    end
  end
  ks_port   = options['httpport']
  user_data = []
  exec_data = []
  user_data.push("#cloud-config")
  user_data.push("autoinstall:")
  user_data.push("  version: 1")
  user_data.push("  apt:")
  user_data.push("    geoip: true")
  user_data.push("    preserve_sources_list: false")
  user_data.push("    primary:")
  user_data.push("    - arches: [amd64, i386]")
  user_data.push("      uri: http://archive.ubuntu.com/ubuntu")
  user_data.push("    - arches: [default]")
  user_data.push("      uri: http://ports.ubuntu.com/ubuntu-ports")
  user_data.push("  identity:")
  user_data.push("    hostname: #{install_name}")
  user_data.push("    password: #{admin_crypt}")
  user_data.push("    realname: #{admin_user}")
  user_data.push("    username: #{admin_user}")
  user_data.push("  keyboard:")
  user_data.push("    layout: #{install_layout}")
  user_data.push("    variant: #{install_variant}")
  user_data.push("  locale: #{install_locale}.UTF-8")
  user_data.push("  network:")
  user_data.push("    network:")
  user_data.push("      version: 2")
  user_data.push("      ethernets:")
  user_data.push("        #{install_nic}:")
  user_data.push("          dhcp4: #{install_dhcp}")
  user_data.push("  ssh:")
  user_data.push("    install-server: true")
  user_data.push("    allow-pw: true")
  user_data.push("  storage:")
  user_data.push("    config:")
  user_data.push("    - grub_device: true")
  user_data.push("      id: disk-#{install_disk}")
  user_data.push("      path: /dev/#{install_disk}")
  user_data.push("      ptable: gpt")
  user_data.push("      type: disk")
  user_data.push("      wipe: superblock-recursive")
  user_data.push("    - device: disk-#{install_disk}")
  user_data.push("      flag: bios_grub")
  user_data.push("      id: partition-0")
  user_data.push("      number: 1")
  user_data.push("      size: 1048576")
  user_data.push("      type: partition")
  user_data.push("    - device: disk-#{install_disk}")
  user_data.push("      id: partition-1")
  user_data.push("      number: 2")
  user_data.push("      size: -1")
  user_data.push("      type: partition")
  user_data.push("      wipe: superblock")
  user_data.push("    - name: root_vg")
  user_data.push("      devices: [partition-1]")
  user_data.push("      preserve: false")
  user_data.push("      type: lvm_volgroup")
  user_data.push("      id: lvm_volgroup-0")
  user_data.push("    - name: root_lv")
  user_data.push("      volgroup: lvm_volgroup-0")
  user_data.push("      size: -1")
  user_data.push("      wipe: superblock")
  user_data.push("      preserve: false")
  user_data.push("      type: lvm_partition")
  user_data.push("      id: lvm_partition-0")
  user_data.push("    - fstype: ext4")
  user_data.push("      id: format-0")
  user_data.push("      type: format")
  user_data.push("      volume: lvm_partition-0")
  user_data.push("    - device: format-0")
  user_data.push("      id: mount-0")
  user_data.push("      path: /")
  user_data.push("      type: mount")
  user_data.push("  updates: security")
  user_data.push("  user-data:")
  user_data.push("    disable-root: false")
  exec_data.push("ip addr add #{install_ip}/#{install_cidr} dev #{install_nic}")
  exec_data.push("ip link set #{install_nic} up")
  exec_data.push("ip route add default via #{install_gateway}")
  exec_data.push("echo 'DNS=#{install_nameserver}' >> #{resolved_conf}")
  exec_data.push("echo 'DNS=#{install_nameserver}' >> #{install_target}#{resolved_conf}")
  exec_data.push("systemctl restart systemd-resolved")
  exec_data.push("#{in_target} /usr/sbin/locale-gen #{install_locale}.UTF-8")
  exec_data.push("echo 'LC_ALL=en_US.UTF-8' > #{locale_file}")
  exec_data.push("echo 'LANG=en_US.UTF-8' >> #{locale_file}")
  if options['copykeys'] == true and File.exist?(ssh_keyfile)
    exec_data.push("#{in_target} groupadd #{admin_user}")
    exec_data.push("#{in_target} useradd -p '#{admin_crypt}' -g #{admin_user} -G #{admin_group} -d #{admin_home} -s /usr/bin/bash -m #{admin_user}")
    exec_data.push("mkdir -p #{ssh_dir}")
    exec_data.push("echo '#{ssh_key}'  > #{auth_file}")
    exec_data.push("chmod 600 #{auth_file}")
    exec_data.push("chmod 700 #{ssh_dir}")
    exec_data.push("#{in_target} chown -R #{admin_user}:#{admin_user} #{admin_home}")
  end
  exec_data.push("echo '#{admin_user} ALL=(ALL) NOPASSWD:ALL' > #{sudo_file}")
  if options['serial'] == true
    if options['biosdevnames'] == true
      exec_data.push("echo 'GRUB_CMDLINE_LINUX=\\\"net.ifnames=0 biosdevname=0 console=tty0 console=ttyS0\\\"' >> #{grub_file}")
    else
      exec_data.push("echo 'GRUB_CMDLINE_LINUX=\\\"console=tty0 console=ttyS0\\\"' >> #{grub_file}")
    end
    exec_data.push("echo 'GRUB_TERMINAL_INPUT=\\\"console serial\\\"' >> #{grub_file}")
    exec_data.push("echo 'GRUB_TERMINAL_OUTPUT=\\\"console serial\\\"' >> #{grub_file}")
  else
    if options['biosdevnames'] == true
      exec_data.push("echo 'GRUB_CMDLINE_LINUX=\\\"net.ifnames=0 biosdevname=0\\\"' >> #{grub_file}")
    end
  end
  exec_data.push("#{in_target} update-grub")
  if disable_dhcp.match(/true/)
    exec_data.push("echo '# This file describes the network interfaces available on your system' > #{netplan_file}")
    exec_data.push("echo '# For more information, see netplan(5).' >> #{netplan_file}")
    exec_data.push("echo 'network:' >> #{netplan_file}")
    exec_data.push("echo '  version: 2' >> #{netplan_file}")
    exec_data.push("echo '  renderer: networkd' >> #{netplan_file}")
    exec_data.push("echo '  ethernets:' >> #{netplan_file}")
    exec_data.push("echo '    #{install_nic}:' >> #{netplan_file}")
    exec_data.push("echo '      addresses: [#{install_ip}/#{install_cidr}]' >> #{netplan_file}")
    exec_data.push("echo '      gateway4: #{install_gateway}' >> #{netplan_file}")
  end
  return user_data,exec_data
end

# Output Cloud Config/Init user data

def output_cc_user_data(options,user_data,exec_data,output_file)
  in_target = "curtin in-target --target=/target --"
  check_dir = File.dirname(output_file)
  check_dir_exists(options,check_dir)
  tmp_file  = "/tmp/user_data_"+options['name']
  file      = File.open(tmp_file, 'w')
  end_char  = "\n"
  user_data.each do |line|
    output = line+end_char
    file.write(output)
  end
  end_char = ""
  pkg_list = $q_struct['additional_packages'].value
  file.write("  late-commands:\n")
  file.write("    [")
  exec_data.each do |line|
    output = " \""+line+"\","+end_char
    file.write(output)
  end
  file.write(" \"#{in_target} apt update\",")
  output = " \"#{in_target} apt install -y "+pkg_list+"\","+end_char
  file.write(output)
  file.write(" \"date\" ]\n\n")
  file.close
  message = "Creating:\tCloud user-data file "+output_file
  command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  execute_command(options,message,command)
  print_contents_of_file(options,"",output_file)
  return
end

