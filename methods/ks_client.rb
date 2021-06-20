
# Kickstart client routines

# List ks clients

def list_ks_clients()
  service_type = "Kickstart"
  list_clients(options)
  return
end

# Configure client PXE boot

def configure_ks_pxe_client(options)
  options['ip'] = single_install_ip(options)
  tftp_pxe_file = options['mac'].gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
  test_file     = options['tftpdir']+"/"+tftp_pxe_file
  tmp_file      = "/tmp/pxecfg"
  if File.symlink?(test_file)
    message = "Information:\tRemoving old PXE boot file "+test_file
    command = "rm #{test_file}"
    execute_command(options,message,command)
  end
  pxelinux_file = "pxelinux.0"
  message = "Information:\tCreating PXE boot file for "+options['name']+" with MAC address "+options['mac']
  command = "cd #{options['tftpdir']} ; ln -s #{pxelinux_file} #{tftp_pxe_file}"
  execute_command(options,message,command)
  if options['biostype'].to_s.match(/efi/)
    shim_efi_file  = "/usr/lib/shim/shimx64.efi"
    if !File.exist?(shim_efi_file)
      install_package(options,"shim")
    end
    shim_grub_file = options['tftpdir']+"/shimx64.efi"
    net_efi_file   = "/usr/lib/grub/x86_64-efi/monolithic/grubnetx64.efi"
    if !File.exist?(net_efi_file)
      install_package(options,"grub-efi-amd64-bin")
    end
    net_grub_file  = options['tftpdir']+"/grubx64.efi"
    check_dir_exists(options,options['tftpdir'])
    check_dir_owner(options,options['tftpdir'],options['uid'])
    if !File.exist?(shim_efi_file)
      install_package(options,"shim-signed")
    end
    if !File.exist?(net_efi_file)
      install_package(options,"grub-efi-amd64-signed")
    end
    if !File.exist?(shim_grub_file)
      message = "Information:\tCopying #{shim_efi_file} to #{shim_grub_file}"
      command = "cp #{shim_efi_file} #{shim_grub_file}"
      execute_command(options,message,command)
      check_file_owner(options,shim_grub_file,options['uid'])
    end
    if !File.exist?(net_grub_file)
      message = "Information:\tCopying #{net_efi_file} to #{net_grub_file}"
      command = "cp #{net_efi_file} #{net_grub_file}"
      execute_command(options,message,command)
      check_file_owner(options,net_grub_file,options['uid'])
    end
    tmp_cfg_octs = options['ip'].split(".")
    pxe_cfg_octs = [] 
    tmp_cfg_octs.each do |octet|
      hextet = octet.convert_base(10, 16)
      if hextet.length < 2
        hextet = "0"+hextet
      end
      pxe_cfg_octs.push(hextet.upcase) 
    end
    pxe_cfg_txt  = pxe_cfg_octs.join
    pxe_cfg_file = "grub.cfg-"+pxe_cfg_txt
    pxe_cfg_dir  = options['tftpdir']+"/grub"
    check_dir_exists(options,pxe_cfg_dir)
    check_dir_owner(options,pxe_cfg_dir,options['uid'])
    pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  else
    pxe_cfg_dir  = options['tftpdir']+"/pxelinux.cfg"
    pxe_cfg_file = options['mac'].gsub(/:/,"-")
    pxe_cfg_file = "01-"+pxe_cfg_file
    pxe_cfg_file = pxe_cfg_file.downcase
    pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  end
  if options['service'].to_s.match(/sles/)
    vmlinuz_file = "/"+options['service']+"/boot/#{options['arch']}/loader/linux"
  else
    vmlinuz_file = "/"+options['service']+"/images/pxeboot/vmlinuz"
  end
  if options['service'].to_s.match(/ubuntu/)
    if options['service'].to_s.match(/x86_64/)
      initrd_file  = "/"+options['service']+"/images/pxeboot/netboot/ubuntu-installer/amd64/initrd.gz"
      linux_file  = "/"+options['service']+"/images/pxeboot/netboot/ubuntu-installer/amd64/linux"
    else
      initrd_file  = "/"+options['service']+"/images/pxeboot/netboot/ubuntu-installer/i386/initrd.gz"
    end
    ldlinux_link = options['tftpdir']+"/ldlinux.c32"
    if not File.exist?(ldlinux_link) and not File.symlink?(ldlinux_link)
      ldlinux_file = options['service']+"/images/pxeboot/netboot/ldlinux.c32"
      message = "Information:\tCreating symlink for ldlinux.c32"
      command = "ln -s #{ldlinux_file} #{ldlinux_link}"
      execute_command(options,message,command)
    end
  else
    if options['service'].to_s.match(/sles/)
      initrd_file  = "/"+options['service']+"/boot/#{options['arch']}/loader/initrd"
    else
      initrd_file  = "/"+options['service']+"/images/pxeboot/initrd.img"
    end
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    vmlinuz_file = vmlinuz_file.gsub(/^\//,"")
    initrd_file  = initrd_file.gsub(/^\//,"")
  end
  if options['service'].to_s.match(/packer/)
    host_info = options['vmgateway']+":"+options['httpport']
  else
    host_info = options['hostip']
  end
  #ks_url       = "http://"+host_info+"/clients/"+options['service']+"/"+options['name']+"/"+options['name']+".cfg"
  #autoyast_url = "http://"+host_info+"/clients/"+options['service']+"/"+options['name']+"/"+options['name']+".xml"
  ks_url       = "http://"+options['hostip']+"/"+options['name']+"/"+options['name']+".cfg"
  autoyast_url = "http://"+options['hostip']+"/"+options['name']+"/"+options['name']+".xml"
  install_url  = "http://"+host_info+"/"+options['service']
  file         = File.open(tmp_file,"w")
  if options['biostype'].to_s.match(/efi/)
    menuentry = "menuentry \""+options['name']+"\" {\n"
    file.write(menuentry)
  else
    if options['serial'] == true
      file.write("serial 0 115200\n")
      file.write("prompt 0\n")
    end
    file.write("DEFAULT LINUX\n")
    file.write("LABEL LINUX\n")
    file.write("  KERNEL #{vmlinuz_file}\n")
  end
  if options['service'].to_s.match(/ubuntu/)
    options['ip']         = $q_struct['ip'].value
    install_domain        = $q_struct['domain'].value
    install_nic           = $q_struct['nic'].value
    options['vmgateway']  = $q_struct['gateway'].value
    options['netmask']    = $q_struct['netmask'].value
    options['vmnetwork']  = $q_struct['network_address'].value
    options['nameserver'] = $q_struct['nameserver'].value
    disable_dhcp          = $q_struct['disable_dhcp'].value
    if disable_dhcp.match(/true/)
      if options['biostype'].to_s.match(/efi/)
        append_string = "  linux #{linux_file} --- auto=true priority=critical preseed/url=#{ks_url} console-keymaps-at/keymap=us locale=en_US hostname=#{options['name']} domain=#{install_domain} interface=#{install_nic} grub-installer/bootdev=#{options['rootdisk']} netcfg/get_ipaddress=#{options['ip']} netcfg/get_netmask=#{options['netmask']} netcfg/get_gateway=#{options['vmgateway']} netcfg/get_nameservers=#{options['nameserver']} netcfg/disable_dhcp=true initrd=#{initrd_file} net.ifnames=0 biosdevname=0"
        initrd_string = "  initrd #{initrd_file}"
      else
        append_string = "  APPEND auto=true priority=critical preseed/url=#{ks_url} console-keymaps-at/keymap=us locale=en_US hostname=#{options['name']} domain=#{install_domain} interface=#{install_nic} grub-installer/bootdev=#{options['rootdisk']} netcfg/get_ipaddress=#{options['ip']} netcfg/get_netmask=#{options['netmask']} netcfg/get_gateway=#{options['vmgateway']} netcfg/get_nameservers=#{options['nameserver']} netcfg/disable_dhcp=true initrd=#{initrd_file} net.ifnames=0 biosdevname=0"
      end
    else
      append_string = "  APPEND "
    end
  else
    if options['service'].to_s.match(/sles/)
      append_string = "  APPEND initrd=#{initrd_file} install=#{install_url} autoyast=#{autoyast_url} language=#{options['language']} net.ifnames=0 biosdevname=0"
    else
      if options['service'].to_s.match(/fedora_2[0-3]/)
        append_string = "  APPEND initrd=#{initrd_file} ks=#{ks_url} ip=#{options['ip']} netmask=#{options['netmask']} net.ifnames=0 biosdevname=0"
      else
        append_string = "  APPEND initrd=#{initrd_file} ks=#{ks_url} ksdevice=bootif ip=#{options['ip']} netmask=#{options['netmask']} net.ifnames=0 biosdevname=0"
      end
    end
  end
  if options['text'] == true
    if options['service'].to_s.match(/sles/)
      append_string = append_string+" textmode=1"
    else
      append_string = append_string+" text"
    end
  end
  if options['serial'] == true
    append_string = append_string+" serial console=ttyS0"
  end
  append_string = append_string+"\n"
  file.write(append_string)
  if options['biostype'].to_s.match(/efi/)
    initrd_string = initrd_string+"\n"
    file.write(initrd_string)
    file.write("}\n")
  end
  file.flush
  file.close
  if options['biostype'].to_s.match(/efi/)
    grub_file = pxe_cfg_dir+"/grub.cfg"
    if File.exist?(grub_file)
      File.delete(grub_file)
    end
    FileUtils.touch(grub_file)
    grub_file = File.open(grub_file, "w")
    file_list = Dir.entries(pxe_cfg_dir)
    file_list.each do |file_name|
      if file_name.match(/cfg\-/) and !file_name.match(/#{options['name'].to_s}/)
        temp_file  = pxe_cfg_dir+"/"+file_name
        temp_array = File.readlines(temp_file)
        temp_array.each do |temp_line|
          grub_file.write(temp_line)
        end
      end
    end
    menuentry = "menuentry \""+options['name']+"\" {\n"
    grub_file.write(menuentry)
    grub_file.write(append_string)
    grub_file.write(initrd_string)
    grub_file.write("}\n")
    grub_file.flush
    grub_file.close
    grub_file = pxe_cfg_dir+"/grub.cfg"
    FileUtils.touch(grub_file)
    print_contents_of_file(options,"",grub_file)
  end
  message = "Information:\tCreating PXE configuration file "+pxe_cfg_file
  command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
  execute_command(options,message,command)
  print_contents_of_file(options,"",pxe_cfg_file)
  return
end

# Unconfigure client PXE boot

def unconfigure_ks_pxe_client(options)
  options['mac'] = get_install_mac(options)
  if not options['mac']
    handle_output(options,"Warning:\tNo MAC Address entry found for #{options['name']}")
    quit(options)
  end
  if options['biostype'].to_s.match(/efi/)
    tmp_cfg_octs = options['ip'].split(".")
    pxe_cfg_octs = [] 
    tmp_cfg_octs.each do |octet|
      hextet = octet.convert_base(10, 16)
      if hextet.length < 2
        hextet = "0"+hextet
      end
      pxe_cfg_octs.push(hextet.upcase) 
    end
    pxe_cfg_txt  = pxe_cfg_octs.join
    pxe_cfg_file = "grub.cfg-"+pxe_cfg_txt
    pxe_cfg_dir  = options['tftpdir']+"/grub"
    check_dir_exists(options,pxe_cfg_dir)
    check_dir_owner(options,pxe_cfg_dir,options['uid'])
    pxe_cfg_file  = pxe_cfg_dir+"/"+pxe_cfg_file
    pxe_cfg_file  = pxe_cfg_dir+"/"+pxe_cfg_file
    tftp_pxe_file = pxe_cfg_file
  else
    tftp_pxe_file = options['mac'].gsub(/:/,"")
    tftp_pxe_file = tftp_pxe_file.upcase
    tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
    tftp_pxe_file = options['tftpdir']+"/"+tftp_pxe_file
  end
  if File.exist?(tftp_pxe_file)
    check_file_owner(options,ttftp_pxe_file,options['uid'])
    message = "Information:\tRemoving PXE boot file "+tftp_pxe_file+" for "+options['name']
    command = "rm #{tftp_pxe_file}"
    output  = execute_command(options,message,command)
  end
  pxe_cfg_dir  = options['tftpdir']+"/pxelinux.cfg"
  pxe_cfg_file = options['mac'].gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  if File.exist?(pxe_cfg_file)
    message = "Information:\tRemoving PXE boot config file "+pxe_cfg_file+" for "+options['name']
    command = "rm #{pxe_cfg_file}"
    output  = execute_command(options,message,command)
    if options['biostype'].to_s.match(/efi/)
      grub_file = pxe_cfg_dir+"/grub.cfg"
      grub_file = File.open(grub_file, "w")
      file_list = Dir.entries(pxe_cfg_dir)
      file_list.each do |file_name|
        if file_name.match(/cfg\-/)
          temp_file  = pxe_cfg_dir+"/"+file_name
          temp_array = File.readlines(temp_file)
          temp_array.each do |temp_line|
            grub_file.write(temp_line)
          end
        end
      end
      grub_file.close
    end
  end
  unconfigure_ks_dhcp_client(options)
  return
end

# Configure DHCP entry

def configure_ks_dhcp_client(options)
  add_dhcp_client(options)
  return
end

# Unconfigure DHCP client

def unconfigure_ks_dhcp_client(options)
  remove_dhcp_client(options)
  return
end

# Configure Kickstart client

def configure_ks_client(options)
  if not options['service'].to_s.match(/purity/)
    options['ip'] = single_install_ip(options)
  end
  if not options['arch'].to_s.match(/[a-z]/)
    if options['service'].to_s.match(/i386/)
      options['arch'] = "i386"
    else
      options['arch'] = "x86_64"
    end
  end
  configure_ks_pxe_boot(options)
  options['repodir'] = options['baserepodir']+"/"+options['service']
  add_apache_alias(options,options['clientdir'])
  options['clientdir'] = options['clientdir']+"/"+options['service']+"/"+options['name']
  check_fs_exists(options,options['clientdir'])
  if not File.directory?(options['repodir'])
    handle_output(options,"Warning:\tService #{options['service']} does not exist")
    handle_output(options,"")
    list_ks_services()
    quit(options)
  end
  check_dir_exists(options,options['clientdir'])
  check_dir_owner(options,options['clientdir'],options['uid'])
  if options['service'].to_s.match(/sles/)
    output_file = options['clientdir']+"/"+options['name']+".xml"
  else
    output_file = options['clientdir']+"/"+options['name']+".cfg"
  end
  delete_file(options,output_file)
  if options['service'].to_s.match(/fedora|rhel|centos|sl_|oel/)
    options = populate_ks_questions(options)
    process_questions(options)
    output_ks_header(options,output_file)
    pkg_list = populate_ks_pkg_list(options['service'])
    output_ks_pkg_list(options,pkg_list,output_file)
    post_list = populate_ks_post_list(options)
    output_ks_post_list(options,post_list,output_file)
  else
    if options['service'].to_s.match(/sles/)
      options = populate_ks_questions(options)
      process_questions(options)
      output_ay_client_profile(options,output_file)
    else
      if options['service'].to_s.match(/ubuntu|debian|purity/)
        options = populate_ps_questions(options)
        process_questions(options)
        if !options['service'].to_s.match(/purity/)
          output_ps_header(options,output_file)
          output_file = options['clientdir']+"/"+options['name']+"_post.sh"
          post_list   = populate_ps_post_list(options)
          output_ks_post_list(options,post_list,output_file)
          output_file = options['clientdir']+"/"+options['name']+"_first_boot.sh"
          post_list   = populate_ps_first_boot_list(options)
          output_ks_post_list(options,post_list,output_file)
        end
      end
    end
  end
  if !options['service'].to_s.match(/purity/)
    configure_ks_pxe_client(options)
    configure_ks_dhcp_client(options)
    add_apache_alias(options,options['clientdir'])
    add_hosts_entry(options)
  end
  return
end

# Unconfigure Kickstart client

def unconfigure_ks_client(options)
  unconfigure_ks_pxe_client(options)
  unconfigure_ks_dhcp_client(options)
  return
end

# Populate post commands

def populate_ks_post_list(options)
  gateway_ip  = options['vmgateway']
  post_list   = []
  admin_group = $q_struct['admin_group'].value
  admin_user  = $q_struct['admin_username'].value
  admin_crypt = $q_struct['admin_crypt'].value
  admin_home  = $q_struct['admin_home'].value
  admin_uid   = $q_struct['admin_uid'].value
  admin_gid   = $q_struct['admin_gid'].value
  nic_name    = $q_struct['nic'].value
  epel_file   = "/etc/yum.repos.d/epel.repo"
  beta_file   = "/etc/yum.repos.d/public-yum-ol6-beta.repo"
  post_list.push("")
  post_list.push("# Fix ethernet names to be ethX style")
  post_list.push("")
  post_list.push("echo 'GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"' >>/etc/default/grub")
  post_list.push("/usr/sbin/update-grub")
  post_list.push("")
  post_list.push("")
  post_list.push("# Fix timezone")
  post_list.push("")
  post_list.push("rm /etc/localtime")
  post_list.push("cd /etc ; ln -s ../usr/share/zoneinfo/#{options['timezone']} /etc/localtime")
  post_list.push("")
  post_list.push("# Add Admin user")
  post_list.push("")
  post_list.push("groupadd #{admin_group}")
  post_list.push("groupadd #{admin_user}")
  post_list.push("")
  post_list.push("# Add admin user")
  post_list.push("")
  post_list.push("useradd -p '#{admin_crypt}' -g #{admin_user} -G #{admin_group} -d #{admin_home} -m #{admin_user}")
  post_list.push("")
  post_list.push("# Setup sudoers")
  post_list.push("")
  post_list.push("echo \"#{admin_user} ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers")
  post_list.push("")
  resolv_conf = "/etc/resolv.conf"
  post_list.push("# Create #{resolv_conf}")
  post_list.push("")
  post_list.push("echo 'nameserver #{options['nameserver']}' >> #{resolv_conf}")
  post_list.push("echo 'search local' >> #{resolv_conf}")
  post_list.push("")
  post_list.push("route add default gw #{gateway_ip}")
  post_list.push("echo 'GATEWAY=#{gateway_ip}' > /etc/sysconfig/network")
  if options['service'].to_s.match(/rhel_[5,6]/)
    post_list.push("echo 'NETWORKING=yes' >> /etc/sysconfig/network")
    post_list.push("echo 'HOSTNAME=#{options['name']}' >> /etc/sysconfig/network")
    post_list.push("")
    post_list.push("echo 'default via #{gateway_ip} dev #{nic_name}' > /etc/sysconfig/network-scripts/route-eth0")
  end
  post_list.push("")
  if options['service'].to_s.match(/centos|fedora|sl_|el/)
    if options['service'].to_s.match(/centos_5|fedora_18|rhel_5|sl_5|oel_5/)
      epel_url = "http://"+options['epel']+"/pub/epel/5/i386/epel-release-5-4.noarch.rpm"
    end
    if options['service'].to_s.match(/centos_6|fedora_19|fedora_20|el_6|sl_6/)
      epel_url = "http://"+options['epel']+"/pub/epel/6/i386/epel-release-6-8.noarch.rpm"
    end
    if options['service'].to_s.match(/centos/)
      repo_file = "/etc/yum.repos.d/CentOS-Base.repo"
    end
    if options['service'].to_s.match(/sl_/)
      repo_file = "/etc/yum.repos.d/sl.repo"
    end
    if options['service'].to_s.match(/centos|sl_/)
      post_list.push("# Change mirror for yum")
      post_list.push("")
      post_list.push("echo 'Changing default mirror for yum'")
      post_list.push("cp #{repo_file} #{repo_file}.orig")
    end
  end
  if options['service'].to_s.match(/centos/)
    post_list.push("sed -i 's/^mirror./#&/g' #{repo_file}")
    post_list.push("sed -i 's/^#\\(baseurl\\)/\\1/g' #{repo_file}")
#    post_list.push("sed -i 's,#{$default_centos_mirror},#{$local_centos_mirror},g' #{repo_file}")
  end
  if options['service'].to_s.match(/sl_/)
    post_list.push("sed -i 's,#{$default_sl_mirror},#{$local_sl_mirror},g' #{repo_file}")
  end
  if options['service'].to_s.match(/_[5,6]/)
    if options['service'].to_s.match(/_5/)
      epel_url = "http://"+options['epel']+"/pub/epel/5/"+options['arch']+"/epel-release-5-4.noarch.rpm"
    end
    if options['service'].to_s.match(/_6/)
      epel_url = "http://"+options['epel']+"/pub/epel/6/"+options['arch']+"/epel-release-6-8.noarch.rpm"
    end
    if options['service'].to_s.match(/_7/)
      epel_url = "http://"+options['epel']+"/pub/epel/beta/7/"+options['arch']+"/epel-release-7-0.2.noarch.rpm"
    end
    post_list.push("")
    post_list.push("# Configure Epel repo")
    post_list.push("")
    post_list.push("rpm -i #{epel_url}")
    post_list.push("cp #{epel_file} #{epel_file}.orig")
    post_list.push("sed -i 's/^mirror./#&/g' #{epel_file}")
    post_list.push("sed -i 's/^#\\(baseurl\\)/\\1/g' #{epel_file}")
    post_list.push("sed -i 's/7/beta\\/7/g' #{epel_file}")
#    post_list.push("sed -i 's,#{$default_epel_mirror},#{options['epel']},g' #{epel_file}")
    post_list.push("yum -y update")
    post_list.push("")
  end
  if options['type'].to_s.match(/packer/)
    post_list.push("")
    post_list.push("echo 'UseDNS no' >> /etc/ssh/sshd_config")
    post_list.push("systemctl disable firewalld")
    post_list.push("")
    post_list.push("echo 'Port 22' >> /etc/ssh/sshd_config")
    post_list.push("echo 'Port 2222' >> /etc/ssh/sshd_config")
    post_list.push("")
  end
  if options['enable'].to_s.match(/packstack/)
    post_list.push("")
    post_list.push("# Configure Packstack")
    post_list.push("")
    if options['service'].to_s.match(/el_[7,8]|centos_7/)
      post_list.push("yum update -y")
      post_list.push("systemctl disable firewalld")
      post_list.push("systemctl stop firewalld")
      post_list.push("systemctl disable NetworkManager")
      post_list.push("systemctl enable network")
      post_list.push("systemctl start network")
      post_list.push("")
    end
    post_list.push("")
  end
  post_list.push("")
  if not options['service'].to_s.match(/fedora/)
    post_list.push("# Avahi daemon for mDNS")
    post_list.push("")
    post_list.push("chkconfig avahi-daemon on")
    post_list.push("service avahi-daemon start")
    post_list.push("")
  end
  if not options['type'].to_s.match(/packer/)
    post_list.push("# Install VM tools")
    post_list.push("")
    post_list.push("export OSREL=`lsb_release -r |awk '{print $2}' |cut -f1 -d'.'`")
    post_list.push("export OSARCH=`uname -p`")
    post_list.push("if [ \"`dmidecode |grep VMware`\" ]; then")
    post_list.push("  echo 'Installing VMware RPMs'")
    post_list.push("  echo -e \"[vmware-tools]\\nname = VMware Tools\\nbaseurl=http://#{options['publisherhost']}/vmware\\nenabled=1\\ngpgcheck=0\" >> /etc/yum.repos.d/vmware-tools.repo")
    post_list.push("  yum -y install vmware-tools-core")
    post_list.push("fi")
    post_list.push("")
  end
  post_list.push("# Enable serial console")
  post_list.push("")
  post_list.push("sed -i 's/9600/115200/' /etc/inittab")
  post_list.push("sed -i 's/kernel.*/& console=ttyS0,115200n8/' /etc/grub.conf")
  post_list.push("")
  if options['service'].to_s.match(/oel_6_5/)
    post_list.push("# OEL beta repo")
    post_list.push("")
    post_list.push("echo '[uek3_beta]' > #{beta_file}")
    post_list.push("echo 'name = Unbreakable Enterprise Kernel Release 3 for Oracle Linux 6 ($basearch)' >> #{beta_file}")
    post_list.push("echo 'baseurl=http://public-yum.oracle.com/beta/repo/OracleLinux/OL6/uek3/$basearch/' >> #{beta_file}")
    post_list.push("echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle' >> #{beta_file}")
    post_list.push("echo 'gpgcheck=1' >> #{beta_file}")
    post_list.push("echo 'enabled=1' >> #{beta_file}")
    post_list.push("")
    post_list.push("yum update")
    post_list.push("yum -y install dtrace-utils")
    post_list.push("yum -y install dtrace-modules")
    post_list.push("groupadd dtrace")
    post_list.push("usermod -a -G dtrace #{admin_user}")
    post_list.push("echo 'kernel==\"dtrace/dtrace\", GROUP=\"dtrace\" MODE=\"0660\"' > /etc/udev/rules.d/10-dtrace.rules")
    post_list.push("echo '/sbin/modprobe dtrace' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe profile' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe sdt' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe systrace' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe dt_test' >> /etc/rc.modules")
    post_list.push("chmod 755 /etc/rc.modules")
    post_list.push("")
  end
  if options['service'].to_s.match(/rhel_|centos_/)
    post_list.push("# Add host entry")
    post_list.push("")
    #post_list.push("echo '#{options['ip']} #{options['name']}' >> /etc/hosts")
    post_list.push("echo 'HOSTNAME=#{options['name']}' >> /etc/sysconfig/network")
    post_list.push("")
  end
  if options['copykeys'] == true
    post_list.push("# Copy SSH keys")
    post_list.push("")
    ssh_key = options['home']+"/.ssh/id_rsa.pub"
    key_dir = options['service']+"/keys"
    check_dir_exists(options,key_dir)
    auth_file = key_dir+"/authorized_keys"
    message   = "Copying:\tSSH keys"
    command   = "cp #{ssh_key} #{auth_file}"
    execute_command(options,message,command)
    ssh_dir   = admin_home+"/.ssh"
    ssh_url   = "http://#{options['publisherhost']}/#{options['service']}/keys/authorized_keys"
    auth_file = ssh_dir+"/authorized_keys"
    post_list.push("mkdir #{ssh_dir}/.ssh")
    post_list.push("chown #{admin_uid}:#{admin_gid} #{ssh_dir}")
    post_list.push("cd #{ssh_dir} ; wget #{ssh_url} -O #{auth_file}")
    post_list.push("chown #{admin_uid}:#{admin_gid} #{auth_file}")
    post_list.push("chmod 644 #{auth_file}")
    post_list.push("")
  end
  if options['vm'].to_s.match(/vbox/)
    post_list.push("# Install VirtualBox Tools")
    post_list.push("")
    post_list.push("mkdir /mnt/cdrom")
    post_list.push("if [ \"`dmidecode |grep VirtualBox`\" ]; then")
    post_list.push("  echo 'Installing VirtualBox Guest Additions'")
    post_list.push("  mount /dev/cdrom /mnt/cdrom")
    post_list.push("  /mnt/cdrom/VBoxLinuxAdditions.run")
    post_list.push("  umount /mnt/cdrom")
    post_list.push("fi")
    post_list.push("")
  end
  if options['service'].to_s.match(/rhel|centos/)
    post_list.push("# Enable serial console")
    post_list.push("")
    post_list.push("grubby --update-kernel=ALL --args=\"console=ttyS0\"")
    post_list.push("")
  end
  if $altrepo_mode == true
    post_list.push("mkdir /tmp/rpms")
    post_list.push("cd /tmp/rpms")
    alt_url  = "http://"+options['hostip']
    rpm_list = build_ks_alt_rpm_list(options['service'])
    alt_dir  = options['baserepodir']+"/"+options['service']+"/alt"
    if options['verbose'] == true
      handle_output(options,"Checking:\tAdditional packages")
    end
    if File.directory?(alt_dir)
      rpm_list.each do |rpm_url|
        rpm_file = File.basename(rpm_url)
        rpm_file = alt_dir+"/"+rpm_file
        rpm_url  = alt_url+"/"+rpm_file
        if File.exist?(rpm_file)
          post_list.push("wget #{rpm_url}")
        end
      end
    end
    post_list.push("rpm -i *.rpm")
    post_list.push("cd /tmp")
    post_list.push("rm -rf /tmp/rpms")
  end
  post_list.push("")
  return post_list
end

# Populat a list of additional packages to install

def populate_ks_pkg_list(options)
  pkg_list = []
  if options['service'].to_s.match(/centos|fedora|rhel|sl_|oel/)
    if not options['service'].to_s.match(/fedora/)
      pkg_list.push("@base")
    end
    pkg_list.push("@core")
    if options['service'].to_s.match(/[a-z]_6/)
      pkg_list.push("@console-internet")
      pkg_list.push("@system-admin-tools")
    end
    if not options['service'].to_s.match(/sl_6|[a-z]_5|fedora/)
      pkg_list.push("@network-file-system-client")
    end
    if options['service'].to_s.match(/centos_[6,7]|fedora|sl_[6,7]/)
      if not options['service'].to_s.match(/fedora_2[3-9]|centos_6/)
        pkg_list.push("redhat-lsb-core")
        if not options['service'].to_s.match(/rhel_[6,7]|oel_[6,7]|centos_7/)
          pkg_list.push("augeas")
          pkg_list.push("tk")
        end
      end
      if not options['service'].to_s.match(/fedora|_[6,7,8]/)
        pkg_list.push("ruby")
        pkg_list.push("ruby-irb")
        pkg_list.push("rubygems")
        pkg_list.push("ruby-rdoc")
        pkg_list.push("ruby-devel")
      end
      if not options['service'].to_s.match(/centos_6/)
        pkg_list.push("augeas-libs")
        pkg_list.push("ruby-libs")
      end
    end
    if not options['service'].to_s.match(/fedora|el_[7,8]|centos_[6,7,8]/)
      pkg_list.push("grub")
      pkg_list.push("libselinux-ruby")
    end
    if options['service'].to_s.match(/el_[7,8]|centos_[7,8]/)
      pkg_list.push("iscsi-initiator-utils")
    end
    if not options['service'].to_s.match(/centos_6/)
      pkg_list.push("e2fsprogs")
      pkg_list.push("lvm2")
    end
    if not options['service'].to_s.match(/fedora/)
      pkg_list.push("kernel-devel")
      if not options['service'].to_s.match(/centos_6/)
        pkg_list.push("automake")
        pkg_list.push("autoconf")
        pkg_list.push("lftp")
        pkg_list.push("avahi")
      end
    end
    pkg_list.push("kernel-headers")
    pkg_list.push("dos2unix")
    pkg_list.push("unix2dos")
    if not options['service'].to_s.match(/fedora_2[4-9]|centos_6/)
      pkg_list.push("zlib-devel")
    end
    if not options['service'].to_s.match(/fedora/)
      if not options['service'].to_s.match(/centos_6/)
        pkg_list.push("libgpg-error-devel")
        pkg_list.push("libxml2-devel")
        pkg_list.push("libgcrypt-devel")
        pkg_list.push("xz-devel")
        pkg_list.push("libxslt-devel")
        pkg_list.push("libstdc++-devel")
      end
      if not options['service'].to_s.match(/rhel_5|fedora|centos_6/)
        pkg_list.push("perl-TermReadKey")
        pkg_list.push("git")
        pkg_list.push("perl-Git")
      end
      pkg_list.push("gcc")
      pkg_list.push("gcc-c++")
      if not options['service'].to_s.match(/centos_|el_8/)
        pkg_list.push("dhcp")
      end
      pkg_list.push("xinetd")
      pkg_list.push("tftp-server")
    end
    if not options['service'].to_s.match(/el_|centos_/)
      pkg_list.push("libgnome-keyring")
    end
    if not options['service'].to_s.match(/rhel_5/)
      pkg_list.push("perl-Error")
    end
    pkg_list.push("httpd")
    if options['service'].to_s.match(/fedora/)
      pkg_list.push("net-tools")
      pkg_list.push("bind-utils")
    end
    if not options['service'].to_s.match(/fedora|el_8|centos_8/)
      pkg_list.push("ntp")
    end
    pkg_list.push("rsync")
    if options['service'].to_s.match(/sl_6/)
      pkg_list.push("-samba-client")
    end
  end
  return pkg_list
end

# Output the Kickstart file header

def output_ks_header(options,output_file)
  tmp_file = "/tmp/ks_"+options['name']
  file=File.open(tmp_file, 'w')
  $q_order.each do |key|
    if $q_struct[key].type.match(/output/)
      if not $q_struct[key].parameter.match(/[a-z,A-Z]/)
        output = $q_struct[key].value+"\n"
      else
        output = $q_struct[key].parameter+" "+$q_struct[key].value+"\n"
      end
      file.write(output)
    end
  end
  file.close
  message = "Creating:\tKickstart file "+output_file
  command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  execute_command(options,message,command)
  return
end

# Output the ks packages list

def output_ks_pkg_list(options,pkg_list,output_file)
  tmp_file = "/tmp/ks_pkg_"+options['name']
  file     = File.open(tmp_file, 'w')
  output   = "\n%packages\n"
  file.write(output)
  pkg_list.each do |pkg_name|
    output = pkg_name+"\n"
    file.write(output)
  end
  if options['service'].to_s.match(/fedora_[19,20]|[centos,rhel,oel,sl]_[7,8]/)
    output   = "\n%end\n"
    file.write(output)
  end
  file.close
  message = "Updating:\tKickstart file "+output_file
  command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  execute_command(options,message,command)
  return
end

# Output the ks packages list

def output_ks_post_list(options,post_list,output_file)
  tmp_file = "/tmp/postinstall_"+options['name']
  if options['service'].to_s.match(/centos|fedora|rhel|sl_|oel/)
    message = "Information:\tAppending post install script "+output_file
    command = "cp #{output_file} #{tmp_file}"
    file=File.open(tmp_file, 'a')
    output = "\n%post\n"
    command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  else
    file=File.open(tmp_file, 'w')
    output  = "#!/bin/sh\n"
    command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  end
  file.write(output)
  post_list.each do |line|
    output = line+"\n"
    file.write(output)
  end
  if options['service'].to_s.match(/fedora_[19,20]|[centos,el,sl]_[7,8]/)
    output   = "\n%end\n"
    file.write(output)
  end
  file.close
  message = "Information:\tCreating post install script "+output_file
#  command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  execute_command(options,message,command)
  print_contents_of_file(options,"",output_file)
  return
end

# Check service options['service']

def check_ks_install_service(options)
  if not options['service'].to_s.match(/[a-z,A-Z]/)
    handle_output(options,"Warning:\tService name not given")
    quit(options)
  end
  client_list = Dir.entries(options['baserepodir'])
  if not client_list.grep(options['service'])
    handle_output(options,"Warning:\tService name #{options['service']} does not exist")
    quit(options)
  end
  return
end
