# Code for Preseed clients

# List Preseed clients

def list_ps_clients()
  service_type = "Preseed"
  list_clients(options)
end

# Configure Preseed client

def configure_ps_client(options)
  options = configure_ks_client(options)
  return options
end

# Unconfigure Preseed client

def unconfigure_ps_client(options)
  unconfigure_ks_client(options)
  return
end

# Output the Preseed file contents

def output_ps_header(options, output_file)
  dir_name = File.dirname(output_file)
  check_dir_exists(options, dir_name)
  check_dir_owner(options, dir_name, options['uid'])
  ps_file = options['preseedfile'].to_s
  if ps_file.match(/[a-z]/) and File.exist?(ps_file)
    message = "Information:\tCopying preseed file #{cc_file} to #{output_file}"
    command = "cp #{cc_file} #{output_file}"
  else
    tmp_file = "/tmp/preseed_"+options['name'].to_s
    file = File.open(tmp_file, 'w')
    options['q_order'].each do |key|
      if options['q_struct'][key].parameter.match(/[a-z,A-Z]/)
        output = "d-i "+options['q_struct'][key].parameter+" "+options['q_struct'][key].type+" "+options['q_struct'][key].value+"\n"
        file.write(output)
      end
    end
    file.close
    message = "Information:\tCreating preseed file #{output_file} for #{options['name']}"
    command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  end
  execute_command(options, message, command)
  print_contents_of_file(options, "", output_file)
  check_file_owner(options, output_file, options['uid'])
  return
end

# Populate first boot commands

def populate_ps_first_boot_list(options)
  if options['service'].to_s.match(/live/) || options['vm'].to_s.match(/mp|multipass/)
    install_target = "/target"
  else
    install_target = ""
  end
  post_list  = []
  admin_user = options['q_struct']['admin_username'].value
  options['ip'] = options['q_struct']['ip'].value
  if options['copykeys'] == true
    ssh_keyfile = options['sshkeyfile']
    if File.exist?(ssh_keyfile)
      ssh_key = %x[cat #{ssh_keyfile}].chomp
      ssh_dir = "#{install_target}/home/"+admin_user+"/.ssh"
    end
  end
  if options['service'].to_s.match(/ubuntu/)
    if options['service'].to_s.match(/16_10|18_|19_|20_/)
      client_nic = "eth0"
    else
      client_nic = options['q_struct']['nic'].value
    end
  else
    client_nic = options['q_struct']['nic'].value
  end
  client_gateway    = options['q_struct']['gateway'].value
  client_netmask    = options['q_struct']['netmask'].value
  client_network    = options['q_struct']['network_address'].value
  client_broadcast  = options['q_struct']['broadcast'].value
  client_nameserver = options['q_struct']['nameserver'].value
  client_domain     = options['q_struct']['domain'].value
  client_mirrorurl  = options['q_struct']['mirror_hostname'].value+options['q_struct']['mirror_directory'].value
  post_list.push("")
  post_list.push("export TERM=vt100")
  post_list.push("export LANGUAGE=en_US.UTF-8")
  post_list.push("export LANG=en_US.UTF-8")
  post_list.push("export LC_ALL=en_US.UTF-8")
  post_list.push("curtin in-target --target=/target -- /usr/sbin/locale-gen en_US.UTF-8")
  post_list.push("echo 'LC_ALL=en_US.UTF-8' > #{install_target}/etc/default/locales")
  post_list.push("echo 'LANG=en_US.UTF-8' >> #{install_target}/etc/default/locales")
  post_list.push("")
  if options['copykeys'] == true and File.exist?(ssh_keyfile)
    post_list.push("# Setup SSH keys")
    post_list.push("")
    post_list.push("mkdir -p #{ssh_dir}")
    post_list.push("chown #{admin_user}:#{admin_user} #{ssh_dir}")
    post_list.push("chmod 700 #{ssh_dir}")
    post_list.push("echo \"#{ssh_key}\" > #{ssh_dir}/authorized_keys")
    post_list.push("chown #{admin_user}:#{admin_user} #{ssh_dir}/authorized_keys")
    post_list.push("chmod 600 #{ssh_dir}/authorized_keys")
    post_list.push("")
  end
  post_list.push("# Setup sudoers")
  post_list.push("")
  post_list.push("echo \"#{admin_user} ALL=(ALL) NOPASSWD:ALL\" >> #{install_target}/etc/sudoers.d/#{admin_user}")
#  post_list.push("")
#  post_list.push("# Enable serial console")
#  post_list.push("")
#  post_list.push("echo 'start on stopped rc or RUNLEVEL=[12345]' > /etc/init/ttyS0.conf")
#  post_list.push("echo 'stop on runlevel [!12345]' >> /etc/init/ttyS0.conf")
#  post_list.push("echo 'respawn' >> /etc/init/ttyS0.conf")
#  post_list.push("echo 'exec /sbin/getty -L 115200 ttyS0 vt100' >> /etc/init/ttyS0.conf")
#  post_list.push("start ttyS0")
  post_list.push("")
  post_list.push("# Fix ethernet names to be ethX style and enable serial")
  post_list.push("")
  if options['service'].to_s.match(/live/) || options['vm'].to_s.match(/mp|multipass/)
    if options['biosdevnames'] == true
      post_list.push("echo 'GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0 console=tty0 console=ttyS0\"' >> #{install_target}/etc/default/grub")
    else
      post_list.push("echo 'GRUB_CMDLINE_LINUX=\"console=tty0 console=ttyS0\"' >> #{install_target}/etc/default/grub")
    end
    post_list.push("echo \"GRUB_TERMINAL_INPUT=\\\"console serial\\\"\" >> #{install_target}/etc/default/grub")
    post_list.push("echo \"GRUB_TERMINAL_OUTPUT=\\\"console serial\\\"\" >> #{install_target}/etc/default/grub")
    post_list.push("curtin in-target --target=/target -- update-grub")
  else
    post_list.push("# Configure apt mirror")
    post_list.push("")
    post_list.push("cp #{install_target}/etc/apt/sources.list #{install_target}/etc/apt/sources.list.orig")
    #post_list.push("sed -i 's,archive.ubuntu.com,#{options['mirror']},g' /etc/apt/sources.list")
    post_list.push("")
    if options['vm'] == options['empty']
      post_list.push("SERIALTTY=`/usr/bin/setserial -g /dev/ttyS[012345] |grep -v unknown |tail -1 |cut -f1 -d, |cut -f3 -d/`")
      post_list.push("SERIALPORT=`/usr/bin/setserial -g /dev/ttyS[012345] |grep -v unknown |tail -1 |cut -f3 -d, |awk '{print $2}'`")
      post_list.push("echo 'GRUB_DEFAULT=0' > #{install_target}/etc/default/grub")
      post_list.push("echo 'GRUB_TIMEOUT_STYLE=menu' >> #{install_target}/etc/default/grub")
      post_list.push("echo 'GRUB_TIMEOUT=5' >> #{install_target}/etc/default/grub")
      post_list.push("echo 'GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`' >> #{install_target}/etc/default/grub")
      post_list.push("echo \"GRUB_SERIAL_COMMAND=\\\"serial --speed=115200 --port=$SERIALPORT\\\"\" >> #{install_target}/etc/default/grub")
      if options['biosdevnames'] == true
        post_list.push("echo \"GRUB_CMDLINE_LINUX=\\\"net.ifnames=0 biosdevname=0 console=tty0 console=$SERIALTTY,115200\\\"\" >> #{install_target}/etc/default/grub")
      else
        post_list.push("echo \"GRUB_CMDLINE_LINUX=\\\"console=tty0 console=$SERIALTTY,115200\\\"\" >> #{install_target}/etc/default/grub")
      end
      post_list.push("echo \"GRUB_TERMINAL_INPUT=\\\"console serial\\\"\" >> #{install_target}/etc/default/grub")
      post_list.push("echo \"GRUB_TERMINAL_OUTPUT=\\\"console serial\\\"\" >> #{install_target}/etc/default/grub")
      post_list.push("echo 'GRUB_GFXPAYLOAD_LINUX=text' >> #{install_target}/etc/default/grub")
    else
      if options['biosdevnames'] == true
        post_list.push("echo 'GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0 console=tty0 console=ttyS0\"' >> #{install_target}/etc/default/grub")
      else
        post_list.push("echo 'GRUB_CMDLINE_LINUX=\"console=tty0 console=ttyS0\"' >> #{install_target}/etc/default/grub")
      end
      post_list.push("echo \"GRUB_TERMINAL_INPUT=\\\"console serial\\\"\" >> #{install_target}/etc/default/grub")
      post_list.push("echo \"GRUB_TERMINAL_OUTPUT=\\\"console serial\\\"\" >> #{install_target}/etc/default/grub")
      post_list.push("echo \"GRUB_CMDLINE_LINUX_DEFAULT=\\\"nomodeset\\\"\" >> #{install_target}/etc/default/grub")
      post_list.push("systemctl disable openipmi.service")
      post_list.push("systemctl stop openipmi.service")
      post_list.push("systemctl enable serial-getty@ttyS0.service")
      post_list.push("systemctl start serial-getty@ttyS0.service")
      post_list.push("/usr/sbin/update-grub")
    end
  end
  post_list.push("")
  post_list.push("# Configure network")
  post_list.push("")
  net_config = "#{install_target}/etc/network/interfaces"
  post_list.push("echo '# The loopback network interface' > #{net_config}")
  post_list.push("echo 'auto lo' >> #{net_config}")
  post_list.push("echo 'iface lo inet loopback' >> #{net_config}")
  if options['service'].to_s.match(/ubuntu_17_10|ubuntu_18|ubuntu_20/)
    net_config = "/etc/netplan/01-netcfg.yaml"
    post_list.push("echo '# This file describes the network interfaces available on your system' > #{net_config}")
    post_list.push("echo '# For more information, see netplan(5).' >> #{net_config}")
    post_list.push("echo 'network:' >> #{net_config}")
    post_list.push("echo '  version: 2' >> #{net_config}")
    post_list.push("echo '  renderer: networkd' >> #{net_config}")
    post_list.push("echo '  ethernets:' >> #{net_config}")
    post_list.push("echo '    #{client_nic}:' >> #{net_config}")
    if options['vmnetwork'].to_s.match(/hostonly|bridged/) && options['dhcp'] == false
      post_list.push("echo '      addresses: [#{options['ip']}/#{options['cidr']}]' >> #{net_config}")
      post_list.push("echo '      gateway4: #{client_gateway}' >> #{net_config}")
      post_list.push("echo '      nameservers:' >> #{net_config}")
      post_list.push("echo '        addresses: [#{client_nameserver}]' >> #{net_config}")
    else
      post_list.push("echo '      dhcp4: true' >> #{net_config}")
    end
  else
    post_list.push("echo '# The primary network interface' >> #{net_config}")
    post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
    post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
    post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
    post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
    post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
    post_list.push("echo 'network #{client_network}' >> #{net_config}")
    post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}")
    post_list.push("echo 'dns-search #{client_domain}' >> #{net_config}")
    post_list.push("echo 'dns-nameservers #{client_nameserver}' >> #{net_config}")
    if options['service'].to_s.match(/purity/)
      if options['q_struct']['eth1_ip'].value.match(/0-9/)
        options['ip'] = options['q_struct']['eth1_ip'].value
        post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
        post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
        post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
        post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
        post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
        post_list.push("echo 'network #{client_network}' >> #{net_config}")
        post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}") 
      end
      if options['q_struct']['eth2_ip'].value.match(/0-9/)
        options['ip'] = options['q_struct']['eth2_ip'].value
        post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
        post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
        post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
        post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
        post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
        post_list.push("echo 'network #{client_network}' >> #{net_config}")
        post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}") 
      end
      if options['q_struct']['eth3_ip'].value.match(/0-9/)
        options['ip'] = options['q_struct']['eth3_ip'].value
        post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
        post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
        post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
        post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
        post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
        post_list.push("echo 'network #{client_network}' >> #{net_config}")
        post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}") 
      end
      if options['q_struct']['eth4_ip'].value.match(/0-9/)
        options['ip'] = options['q_struct']['eth4_ip'].value
        post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
        post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
        post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
        post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
        post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
        post_list.push("echo 'network #{client_network}' >> #{net_config}")
        post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}") 
      end
      if options['q_struct']['eth5_ip'].value.match(/0-9/)
        options['ip'] = options['q_struct']['eth5_ip'].value
        post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
        post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
        post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
        post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
        post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
        post_list.push("echo 'network #{client_network}' >> #{net_config}")
        post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}") 
      end
    end
  end
  post_list.push("")
  if options['type'].to_s.match(/packer/)
    if not options['vmnetwork'].to_s.match(/hostonly/)
      post_list.push("echo 'Port 22' >> #{install_target}/etc/ssh/sshd_config")
      post_list.push("echo 'Port 2222' >> #{install_target}/etc/ssh/sshd_config")
      post_list.push("")
    end
  end
  if options['service'].to_s.match(/live/) || options['vm'].to_s.match(/mp|multipass/)
    post_list.push("curtin in-target --target=/target -- apt install setserial net-tools")
  else
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      resolv_conf = "#{install_target}/etc/resolv.conf"
      post_list.push("# Configure hosts file")
      post_list.push("")
      if options['service'].to_s.match(/ubuntu_18|ubuntu_20/)
#        post_list.push("sudo systemctl disable systemd-resolved.service")
#        post_list.push("sudo systemctl stop systemd-resolved")
        resolved_conf = "#{install_target}/etc/systemd/resolved.conf"
        post_list.push("echo 'DNS=#{client_nameserver}' >> #{resolved_conf}")
        post_list.push("sudo systemctl restart systemd-resolved")
      end
      post_list.push("rm /etc/resolv.conf")
      post_list.push("echo 'nameserver #{client_nameserver}' > #{resolv_conf}")
      post_list.push("echo 'search local' >> #{resolv_conf}")
    end
    post_list.push("")
    post_list.push("# Configure sources.list")
    post_list.push("")
    post_list.push("export UBUNTU_RELEASE=`lsb_release -sc`")
    post_list.push("")
    post_list.push("echo \"\" > #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"###### Ubuntu Main Repos\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"\" >> /etc/apt/sources.list")
    post_list.push("echo \"###### Ubuntu Update Repos\" >> /etc/apt/sources.list")
    post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE-security main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE-security main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE-updates main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE-updates main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE-proposed main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE-proposed main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE-backports main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE-backports main restricted universe multiverse\" >> #{install_target}/etc/apt/sources.list")
    post_list.push("")
    if options['vm'].to_s.match(/kvm/)
      post_list.push("# Configure console access")
      post_list.push("systemctl enable serial-getty@ttyS0.service")
      post_list.push("systemctl start serial-getty@ttyS0.service")
      post_list.push("")
    end
    post_list.push("# Disable script and reboot")
    post_list.push("")
    post_list.push("update-rc.d -f firstboot.sh remove")
    post_list.push("mv /etc/init.d/firstboot.sh /etc/init.d/_firstboot.sh")
    if options['reboot'] == true
      post_list.push("/sbin/reboot")
    end
  end
  post_list.push("")
  return post_list
end

# Populate post commands

def populate_ps_post_list(options)
  post_list = []
  gateway   = options['q_struct']['gateway'].value
  if options['type'].to_s.match(/packer/)
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      if options['host-os-uname'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10 
        script_url = "http://"+options['hostip'].to_s+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_first_boot.sh"
      else
        script_url = "http://"+gateway+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_first_boot.sh"
      end  
    else
      if options['host-os-uname'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10 
        script_url = "http://"+options['hostip'].to_s+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_first_boot.sh"
      else
        script_url = "http://"+options['hostonlyip'].to_s+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_first_boot.sh"
      end
    end
  else
    if options['server'] == options['empty']
      script_url = "http://"+options['hostip'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_first_boot.sh"
    else
      script_url = "http://"+options['server'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_first_boot.sh"
    end
  end
  post_list.push("/usr/bin/wget -O /root/firstboot.sh #{script_url}")
  first_boot = "/etc/init.d/firstboot.sh"
  post_list.push("chmod +x /root/firstboot.sh")
  post_list.push("echo '#!/bin/bash' > #{first_boot}")
  post_list.push("echo '' >> #{first_boot}")
  post_list.push("echo '### BEGIN INIT INFO' >> #{first_boot}")
  post_list.push("echo '# Provides:        firstboot' >> #{first_boot}")
  post_list.push("echo '# Required-Start:  $networking' >> #{first_boot}")
  post_list.push("echo '# Required-Stop:   $networking' >> #{first_boot}")
  post_list.push("echo '# Default-Start:   2 3 4 5' >> #{first_boot}")
  post_list.push("echo '# Default-Stop:    0 1 6' >> #{first_boot}")
  post_list.push("echo '# Short-Description: A script that runs once' >> #{first_boot}")
  post_list.push("echo '# Description: A script that runs once' >> #{first_boot}")
  post_list.push("echo '### END INIT INFO' >> #{first_boot}")
  post_list.push("echo '' >> #{first_boot}")
  post_list.push("echo 'cd /root ; /usr/bin/nohup sh -x /root/firstboot.sh > /var/log/firstboot.log' >> #{first_boot}")
  post_list.push("")
  post_list.push("chmod +x #{first_boot}")
  post_list.push("update-rc.d firstboot.sh defaults")
  post_list.push("")
  return post_list
end
