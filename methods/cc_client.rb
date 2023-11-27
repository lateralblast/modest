# Code for Cloud Config client config
# E.g. installations via Ubuntu live CD

# Populate Cloud Config/Init User data file

def populate_cc_user_data(options)
  install_locale = options['q_struct']['locale'].value
  if install_locale.match(/\./)
    install_locale = install_locale.split(".")[0]
  end
  if options['livecd'] == true
    install_target = "/target"
  else
    install_target = ""
  end
  install_nameserver = options['q_struct']['nameserver'].value
  install_base_url   = "http://"+options['hostip']+"/"+options['name']
  if options['service'].to_s.match(/ubuntu_2[2-4]/)
    install_layout = options['q_struct']['locale'].value.split(".")[0]
  else
    install_layout = install_locale.split("_")[0]
  end
  install_variant = install_locale.split("_")[1].downcase
  install_country = install_variant
  install_gateway = options['q_struct']['gateway'].value
  admin_shell   = options['q_struct']['admin_shell'].value
  admin_sudo    = options['q_struct']['admin_sudo'].value
  disable_dhcp  = options['q_struct']['disable_dhcp'].value
  install_name  = options['q_struct']['hostname'].value
  resolved_conf = "/etc/systemd/resolved.conf"
  admin_user    = options['q_struct']['admin_username'].value
  admin_group   = options['q_struct']['admin_username'].value
  admin_home    = "/home/"+options['q_struct']['admin_username'].value
  admin_crypt   = options['q_struct']['admin_crypt'].value
  install_nic   = options['q_struct']['interface'].value
  if disable_dhcp.match(/true/)
    install_ip  = options['q_struct']['ip'].value
  end
  install_cidr  = options['q_struct']['cidr'].value
  install_disk  = options['q_struct']['partition_disk'].value
  if install_disk.match(/\//)
    install_disk = install_disk.split(/\//)[-1]
  end
  #netplan_file  = "#{install_target}/etc/netplan/01-netcfg.yaml"
  grub_file = "#{install_target}/etc/default/grub"
  ssh_dir   = "#{install_target}/home/#{admin_user}/.ssh"
  auth_file = "#{ssh_dir}/authorized_keys"
  sudo_file = "#{install_target}/etc/sudoers.d/#{admin_user}"
  linux_kernel = options['kernel'].to_s
  netplan_file = "#{install_target}/etc/netplan/50-cloud-init.yaml"
  locale_file  = "#{install_target}/etc/default/locales"
  package_update   = options['installupdates'].to_s
  package_upgrade  = options['installupgrades'].to_s
  install_drivers  = options['installdrivers'].to_s
  install_security = options['installsecurity'].to_s
  install_timezone = options['timezone'].to_s
  preserve_sources = options['preservesources'].to_s
  install_codename = options['codename'].to_s
  install_ssh_port = options['packersshport'].to_s
  if !install_codename.to_s.match(/[a-z]/)
    install_codename = get_code_name_from_release_version(options['release'])
  end
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
  early_exec_data = []
  late_exec_data  = []
  user_data.push("#cloud-config")
  if !options['vm'].to_s.match(/mp|multipass/)
    in_target = "curtin in-target --target=/target -- "
    user_data.push("autoinstall:")
    user_data.push("  version: 1")
    user_data.push("  apt:")
#    user_data.push("    preferences:")
#    user_data.push("    - package: \"*\"")
#    user_data.push("      pin: \"release a=#{install_codename}-security\"")
#    user_data.push("      pin-priority: 200")
#    user_data.push("    disable_components: []")
#    user_data.push("    geoip: true")
    user_data.push("    preserve_sources_list: #{preserve_sources}")
    user_data.push("    source_list: |")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename} restricted")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename}-updates main restricted")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename} universe")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename}-updates universe")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename} multiverse")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename}-updates multiverse")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename}-backports main restricted universe multiverse")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename}-security main restricted")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename}-security universe")
    user_data.push("      deb [trusted=yes] http://#{install_country}.archive.ubuntu.com/ubuntu #{install_codename}-security multiverse")
    user_data.push("    conf: |")
    user_data.push("      Acquire::https::::Verify-Peer \"false\";")
    user_data.push("      Acquire::https::::Verify-Host \"false\";")
    user_data.push("    primary:")
    if options['arch'].to_s.match(/arm/)
      user_data.push("    - arches: [arm64, arm]")
    else
      user_data.push("    - arches: [amd64, i386]")
    end
    user_data.push("      uri: http://archive.ubuntu.com/ubuntu")
    user_data.push("    - arches: [default]")
    user_data.push("      uri: http://ports.ubuntu.com/ubuntu-ports")
    user_data.push("  package_update: #{package_update}")
    user_data.push("  package_upgrade: #{package_upgrade}")
#    user_data.push("  drivers:")
#    user_data.push("    install: #{install_drivers}:")
#    user_data.push("  user-data:")
#    user_data.push("    disable-root: false")
#    user_data.push("    timezone: #{install_timezone}")
    user_data.push("  identity:")
    user_data.push("    hostname: #{install_name}")
    user_data.push("    password: #{admin_crypt}")
    user_data.push("    realname: #{admin_user}")
    user_data.push("    username: #{admin_user}")
    user_data.push("  kernel:")
    user_data.push("    package: #{linux_kernel}")
    user_data.push("  keyboard:")
    if options['service'].to_s.match(/ubuntu_22/)
      user_data.push("    layout: #{install_variant}")
    else
      user_data.push("    layout: #{install_layout}")
      user_data.push("    variant: #{install_variant}")
    end
    user_data.push("  locale: #{install_locale}.UTF-8")
    user_data.push("  network:")
    user_data.push("    network:")
    user_data.push("      version: 2")
    user_data.push("      ethernets:")
    user_data.push("        #{install_nic}:")
    user_data.push("          dhcp4: #{install_dhcp}")
    if install_dhcp.match(/no|false/)
      user_data.push("          addresses:")
      user_data.push("          - #{install_ip}/#{install_cidr}")
      user_data.push("          gateway4: #{install_gateway}")
      user_data.push("          nameservers:")
      user_data.push("            addresses:")
      user_data.push("            - #{install_nameserver}")
    end
    user_data.push("  ssh:")
    user_data.push("    install-server: true")
    user_data.push("    allow-pw: true")
    user_data.push("  storage:")
    user_data.push("    layout:")
    user_data.push("      name: lvm")
    if install_security.to_s.match(/true/)
      user_data.push("  updates: security")
    end
    user_data.push("  user-data:")
    user_data.push("    disable-root: false")
    if disable_dhcp.match(/true/)
      early_exec_data.push("ip addr add #{install_ip}/#{install_cidr} dev #{install_nic}")
    end
    early_exec_data.push("ip link set #{install_nic} up")
    early_exec_data.push("ip route add default via #{install_gateway}")
    early_exec_data.push("echo 'DNS=#{install_nameserver}' >> #{resolved_conf}")
    early_exec_data.push("systemctl restart systemd-resolved")
  else
    in_target = ""
    if options['method'].to_s.match(/ci/)
      user_data.push("hostname: #{install_name}")
      user_data.push("groups:")
      user_data.push("  - #{admin_user}: #{admin_group}")
      user_data.push("users:")
      user_data.push("  - default")
      user_data.push("  - name: #{admin_user}")
      user_data.push("    gecos: #{admin_user}")
      user_data.push("    primary_group: #{admin_group}")
      user_data.push("    shell: #{admin_shell}")
      user_data.push("    passwd: #{admin_crypt}")
      user_data.push("    sudo: #{admin_sudo}")
      user_data.push("    lock_passwd: false")
    end
  end
  if options['dnsmasq'] == true && options['vm'].to_s.match(/mp|multipass/)
    early_exec_data.push("/usr/bin/systemctl disable systemd-resolved")
    early_exec_data.push("/usr/bin/systemctl stop systemd-resolved")
    early_exec_data.push("rm /etc/resolv.conf")
    if options['q_struct']['nameserver'].value.to_s.match(/\,/)
      nameservers = options['q_struct']['nameserver'].value.to_s.split("\,")
      nameservers.each do |nameserver|
        early_exec_data.push("echo 'nameserver #{nameserver}' >> /etc/resolv.conf")
      end
    else
      nameserver = options['q_struct']['nameserver'].value.to_s
      early_exec_data.push("  - echo 'nameserver #{nameserver}' >> /etc/resolv.conf")
    end
  else  
    late_exec_data.push("echo 'DNS=#{install_nameserver}' >> #{install_target}#{resolved_conf}")
    late_exec_data.push("#{in_target}/usr/sbin/locale-gen #{install_locale}.UTF-8")
  end
  late_exec_data.push("echo 'LC_ALL=en_US.UTF-8' > #{locale_file}")
  late_exec_data.push("echo 'LANG=en_US.UTF-8' >> #{locale_file}")
  late_exec_data.push("echo '#{admin_user} ALL=(ALL) NOPASSWD:ALL' > #{sudo_file}")
  if options['copykeys'] == true and File.exist?(ssh_keyfile) and !options['vm'].to_s.match(/mp|multipass/)
    late_exec_data.push("#{in_target}groupadd #{admin_user}")
    late_exec_data.push("#{in_target}useradd -p '#{admin_crypt}' -g #{admin_user} -G #{admin_group} -d #{admin_home} -s /usr/bin/bash -m #{admin_user}")
    late_exec_data.push("mkdir -p #{ssh_dir}")
    late_exec_data.push("echo '#{ssh_key}'  > #{auth_file}")
    late_exec_data.push("chmod 600 #{auth_file}")
    late_exec_data.push("chmod 700 #{ssh_dir}")
    late_exec_data.push("#{in_target}chown -R #{admin_user}:#{admin_user} #{admin_home}")
  end
  if !options['vm'].to_s.match(/mp|multipass/)
    if options['vm'].to_s.match(/kvm/)
      early_exec_data.push("systemctl enable serial-getty@ttyS0.service")
      early_exec_data.push("systemctl start serial-getty@ttyS0.service")
    else
      if options['serial'] == true
        if options['biosdevnames'] == true
          late_exec_data.push("echo 'GRUB_CMDLINE_LINUX=\\\"net.ifnames=0 biosdevname=0 console=tty0 console=ttyS0\\\"' >> #{grub_file}")
        else
          late_exec_data.push("echo 'GRUB_CMDLINE_LINUX=\\\"console=tty0 console=ttyS0\\\"' >> #{grub_file}")
        end
        late_exec_data.push("echo 'GRUB_TERMINAL_INPUT=\\\"console serial\\\"' >> #{grub_file}")
        late_exec_data.push("echo 'GRUB_TERMINAL_OUTPUT=\\\"console serial\\\"' >> #{grub_file}")
      else
        if options['biosdevnames'] == true
          late_exec_data.push("echo 'GRUB_CMDLINE_LINUX=\\\"net.ifnames=0 biosdevname=0\\\"' >> #{grub_file}")
        end
      end
    end
    if !options['vm'].to_s.match(/mp|multipass/)
      late_exec_data.push("rm #{install_target}/etc/netplan/*")
      late_exec_data.push("echo '# This file describes the network interfaces available on your system' > #{netplan_file}")
      late_exec_data.push("echo '# For more information, see netplan(5).' >> #{netplan_file}")
      late_exec_data.push("echo 'network:' >> #{netplan_file}")
      late_exec_data.push("echo '  version: 2' >> #{netplan_file}")
#      late_exec_data.push("echo '  renderer: networkd' >> #{netplan_file}")
      late_exec_data.push("echo '  ethernets:' >> #{netplan_file}")
      late_exec_data.push("echo '    #{install_nic}:' >> #{netplan_file}")
      if options['dhcp'] == false || options['dnsmasq'] == true
        late_exec_data.push("echo '      addresses: [#{install_ip}/#{install_cidr}]' >> #{netplan_file}")
        late_exec_data.push("echo '      gateway4: #{install_gateway}' >> #{netplan_file}")
      else
        late_exec_data.push("echo '      dhcp4: true' >> #{netplan_file}")
      end
      if options['type'].to_s.match(/packer/)
        if install_ssh_port.to_i != 22
          late_exec_data.push("echo 'Port #{install_ssh_port}' >> #{install_target}/etc/ssh/sshd_config")
        end
      end
      if options['serial'] == true || options['biosdevnames'] == true
        late_exec_data.push("#{in_target}update-grub")
      end
      if options['reboot'] == true
        late_exec_data.push("#{in_target}reboot")
      end
    end
  end
  return user_data, early_exec_data, late_exec_data
end

# Output Cloud Config/Init user data

def output_cc_user_data(options, user_data, early_exec_data, late_exec_data, output_file)
  if !options['vm'].to_s.match(/mp|multipass/)
    in_target = "curtin in-target --target=/target -- "
  else
    in_target = ""
  end
  check_dir = File.dirname(output_file)
  check_dir_exists(options, check_dir)
  tmp_file  = "/tmp/user_data_"+options['name']
  file      = File.open(tmp_file, 'w')
  end_char  = "\n"
  user_data.each do |line|
    output = line+end_char
    file.write(output)
  end
  pkg_list = options['q_struct']['additional_packages'].value
  if options['vm'].to_s.match(/mp|multipass/)
    file.write("packages:\n")
    pkg_list.split(" ").each do |line|
      output = "  - "+line+"\n"
      file.write(output)
    end
    file.write("runcmd:\n")
    exec_data.each do |line|
      output = "  - "+line+"\n"
      file.write(output)
    end
  else
    end_char = "\n"
    file.write("  early-commands:\n")
#    file.write("    [")
    early_exec_data.each do |line|
      output = "    - \""+line+"\""+end_char
      file.write(output)
    end
    file.write("  late-commands:\n")
#    file.write("    [")
    late_exec_data.each do |line|
      output = "    - \""+line+"\""+end_char
      file.write(output)
    end
#    file.write(" \"#{in_target}apt update\",")
#    output = " \"#{in_target}apt install -y "+pkg_list+"\","+end_char
#    file.write(output)
#    file.write(" \"date\" ]\n\n")
  end
  file.close
  message = "Creating:\tCloud user-data file "+output_file
  command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  execute_command(options, message, command)
  print_contents_of_file(options, "", output_file)
  return
end
