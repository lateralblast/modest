# Code for Preseed clients

# List Preseed clients

def list_ps_clients()
  service_type = "Preseed"
  list_clients(options)
end

# Configure Preseed client

def configure_ps_client(options)
  configure_ks_client(options)
  return
end

# Unconfigure Preseed client

def unconfigure_ps_client(options)
  unconfigure_ks_client(options)
  return
end

# Output the Preseed file contents

def output_ps_header(options,output_file)
  dir_name = File.dirname(output_file)
  check_dir_exists(options,dir_name)
  check_dir_owner(options,dir_name,options['uid'])
  tmp_file = "/tmp/preseed_"+options['name'].to_s
  file = File.open(tmp_file, 'w')
  $q_order.each do |key|
    if $q_struct[key].parameter.match(/[a-z,A-Z]/)
      output = "d-i "+$q_struct[key].parameter+" "+$q_struct[key].type+" "+$q_struct[key].value+"\n"
      file.write(output)
    end
  end
  file.close
  message = "Creating:\tPreseed file "+output_file+" for "+options['name']
  command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  execute_command(options,message,command)
  print_contents_of_file(options,"",output_file)
  check_file_owner(options,output_file,options['uid'])
  return
end

# Populate first boot commands

def populate_ps_first_boot_list(options)
  post_list  = []
  options['ip']  = $q_struct['ip'].value
  admin_user = $q_struct['admin_username'].value
  if options['copykeys'] == true
    ssh_keyfile = options['sshkeyfile']
    if File.exist?(ssh_keyfile)
      ssh_key = %x[cat #{ssh_keyfile}].chomp
      ssh_dir = "/home/"+admin_user+"/.ssh"
    end
  end
  if options['service'].to_s.match(/ubuntu/)
    if options['service'].to_s.match(/16_10|18_|19_|20_/)
      client_nic = "eth0"
    else
      client_nic = $q_struct['nic'].value
    end
  else
    client_nic = $q_struct['nic'].value
  end
  client_gateway    = $q_struct['gateway'].value
  client_netmask    = $q_struct['netmask'].value
  client_network    = $q_struct['network_address'].value
  client_broadcast  = $q_struct['broadcast'].value
  client_nameserver = $q_struct['nameserver'].value
  client_domain     = $q_struct['domain'].value
  client_mirrorurl  = $q_struct['mirror_hostname'].value+$q_struct['mirror_directory'].value
  post_list.push("")
  post_list.push("export TERM=vt100")
  post_list.push("export LANGUAGE=en_US.UTF-8")
  post_list.push("export LANG=en_US.UTF-8")
  post_list.push("export LC_ALL=en_US.UTF-8")
  post_list.push("/usr/sbin/locale-gen en_US.UTF-8")
  post_list.push("echo 'LC_ALL=en_US.UTF-8' > /etc/default/locales")
  post_list.push("echo 'LANG=en_US.UTF-8' >> /etc/default/locales")
  post_list.push("")
  post_list.push("# Configure apt mirror")
  post_list.push("")
  post_list.push("cp /etc/apt/sources.list /etc/apt/sources.list.orig")
  #post_list.push("sed -i 's,archive.ubuntu.com,#{options['mirror']},g' /etc/apt/sources.list")
  post_list.push("")
  if options['copykeys'] == true and File.exist?(ssh_keyfile)
    post_list.push("# Setup SSH keys")
    post_list.push("")
    post_list.push("mkdir #{ssh_dir}")
    post_list.push("chown #{admin_user}:#{admin_user} #{ssh_dir}")
    post_list.push("chmod 700 #{ssh_dir}")
    post_list.push("echo \"#{ssh_key}\" > #{ssh_dir}/authorized_keys")
    post_list.push("chown #{admin_user}:#{admin_user} #{ssh_dir}/authorized_keys")
    post_list.push("chmod 600 #{ssh_dir}/authorized_keys")
    post_list.push("")
  end
  post_list.push("# Setup sudoers")
  post_list.push("")
  post_list.push("echo \"#{admin_user} ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/#{admin_user}")
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
  if options['vm'] == options['empty']
    post_list.push("SERIALTTY=`/usr/bin/setserial -g /dev/ttyS[012345] |grep -v unknown |tail -1 |cut -f1 -d, |cut -f3 -d/`")
    post_list.push("SERIALPORT=`/usr/bin/setserial -g /dev/ttyS[012345] |grep -v unknown |tail -1 |cut -f3 -d, |awk '{print $2}'`")
    post_list.push("echo 'GRUB_DEFAULT=0' > /etc/default/grub")
    post_list.push("echo 'GRUB_TIMEOUT_STYLE=menu' >> /etc/default/grub")
    post_list.push("echo 'GRUB_TIMEOUT=5' >> /etc/default/grub")
    post_list.push("echo 'GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`' >> /etc/default/grub")
    post_list.push("echo \"GRUB_SERIAL_COMMAND=\\\"serial --speed=115200 --port=$SERIALPORT\\\"\" >> /etc/default/grub")
    post_list.push("echo \"GRUB_CMDLINE_LINUX=\\\"net.ifnames=0 biosdevname=0 console=tty0 console=$SERIALTTY,115200\\\"\" >> /etc/default/grub")
    post_list.push("echo \"GRUB_TERMINAL_INPUT=\\\"console serial\\\"\" >> /etc/default/grub")
    post_list.push("echo \"GRUB_TERMINAL_OUTPUT=\\\"console serial\\\"\" >> /etc/default/grub")
    post_list.push("echo 'GRUB_GFXPAYLOAD_LINUX=text' >> /etc/default/grub")
  else
    post_list.push("echo 'GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0 console=tty0 console=ttyS0\"' >>/etc/default/grub")
    post_list.push("echo \"GRUB_TERMINAL_INPUT=\\\"console serial\\\"\" >> /etc/default/grub")
    post_list.push("echo \"GRUB_TERMINAL_OUTPUT=\\\"console serial\\\"\" >> /etc/default/grub")
    post_list.push("echo \"GRUB_CMDLINE_LINUX_DEFAULT=\\\"nomodeset\\\"\" >> /etc/default/grub")
    post_list.push("systemctl disable openipmi.service")
    post_list.push("systemctl stop openipmi.service")
    post_list.push("systemctl enable serial-getty@ttyS0.service")
    post_list.push("systemctl start serial-getty@ttyS0.service")
  end
  post_list.push("/usr/sbin/update-grub")
  post_list.push("")
  post_list.push("# Configure network")
  post_list.push("")
  net_config = "/etc/network/interfaces"
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
      if $q_struct['eth1_ip'].value.match(/0-9/)
        options['ip'] = $q_struct['eth1_ip'].value
        post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
        post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
        post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
        post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
        post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
        post_list.push("echo 'network #{client_network}' >> #{net_config}")
        post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}") 
      end
      if $q_struct['eth2_ip'].value.match(/0-9/)
        options['ip'] = $q_struct['eth2_ip'].value
        post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
        post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
        post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
        post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
        post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
        post_list.push("echo 'network #{client_network}' >> #{net_config}")
        post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}") 
      end
      if $q_struct['eth3_ip'].value.match(/0-9/)
        options['ip'] = $q_struct['eth3_ip'].value
        post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
        post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
        post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
        post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
        post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
        post_list.push("echo 'network #{client_network}' >> #{net_config}")
        post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}") 
      end
      if $q_struct['eth4_ip'].value.match(/0-9/)
        options['ip'] = $q_struct['eth4_ip'].value
        post_list.push("echo 'auto #{client_nic}' >> #{net_config}")
        post_list.push("echo 'iface #{client_nic} inet static' >> #{net_config}")
        post_list.push("echo 'address #{options['ip']}' >> #{net_config}")
        post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
        post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
        post_list.push("echo 'network #{client_network}' >> #{net_config}")
        post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}") 
      end
      if $q_struct['eth5_ip'].value.match(/0-9/)
        options['ip'] = $q_struct['eth5_ip'].value
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
    post_list.push("echo 'Port 22' >> /etc/ssh/sshd_config")
    post_list.push("echo 'Port 2222' >> /etc/ssh/sshd_config")
    post_list.push("")
  end
  if options['vmnetwork'].to_s.match(/hostonly|bridged/)
    resolv_conf = "/etc/resolv.conf"
    post_list.push("# Configure hosts file")
    post_list.push("")
    if options['service'].to_s.match(/ubuntu_18|ubuntu_20/)
      post_list.push("sudo systemctl disable systemd-resolved.service")
      post_list.push("sudo systemctl stop systemd-resolved")
      post_list.push("rm /etc/resolv.conf")
    end
    post_list.push("echo 'nameserver #{client_nameserver}' > #{resolv_conf}")
    post_list.push("echo 'search local' >> #{resolv_conf}")
  end
  post_list.push("")
  post_list.push("")
  post_list.push("# Configure sources.list")
  post_list.push("")
  post_list.push("export UBUNTU_RELEASE=`lsb_release -sc`")
  post_list.push("")
  post_list.push("echo \"\" > /etc/apt/sources.list")
  post_list.push("echo \"###### Ubuntu Main Repos\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"\" >> /etc/apt/sources.list")
  post_list.push("echo \"###### Ubuntu Update Repos\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE-security main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE-security main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE-updates main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE-updates main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE-proposed main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE-proposed main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb http://#{client_mirrorurl} $UBUNTU_RELEASE-backports main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("echo \"deb-src http://#{client_mirrorurl} $UBUNTU_RELEASE-backports main restricted universe multiverse\" >> /etc/apt/sources.list")
  post_list.push("")
  post_list.push("# Disable script and reboot")
  post_list.push("")
  post_list.push("update-rc.d -f firstboot.sh remove")
  post_list.push("mv /etc/init.d/firstboot.sh /etc/init.d/_firstboot.sh")
  if options['reboot'] == true
    post_list.push("/sbin/reboot")
  end
  post_list.push("")
  return post_list
end

# Populate post commands

def populate_ps_post_list(options)
  post_list = []
  gateway   = $q_struct['gateway'].value
  if options['type'].to_s.match(/packer/)
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      if options['host-os-name'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10 
        script_url = "http://"+options['hostip'].to_s+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_first_boot.sh"
      else
        script_url = "http://"+gateway+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_first_boot.sh"
      end  
    else
      if options['host-os-name'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10 
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
