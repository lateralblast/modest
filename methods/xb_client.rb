# Code for *BSD and other PXE clients (e.g. CoreOS)

# List BSD clients

def list_xb_clients()
  return
end

# Configure client PXE boot

def configure_xb_pxe_client(options)
  options['version']    = options['service'].split(/_/)[1..2].join(".")
  tftp_pxe_file = options['mac'].gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tmp_file      = "/tmp/pxecfg"
  if options['service'].to_s.match(/openbsd/)
    tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
    test_file     = options['tftpdir']+"/"+tftp_pxe_file
    pxeboot_file  = options['service']+"/"+options['version']+"/"+options['arch'].gsub(/x86_64/,"amd64")+"/pxeboot"
  else
    tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
    test_file     = options['tftpdir']+"/"+tftp_pxe_file
    pxeboot_file  = options['service']+"/isolinux/pxelinux.0"
  end
  if File.symlink?(test_file)
    message = "Information:\tRemoving old PXE boot file "+test_file
    command = "rm #{test_file}"
    execute_command(options,message,command)
  end
  message = "Information:\tCreating PXE boot file for "+options['name']+" with MAC address "+options['mac']
  command = "cd #{options['tftpdir']} ; ln -s #{pxeboot_file} #{tftp_pxe_file}"
  execute_command(options,message,command)
  if options['service'].to_s.match(/coreos/)
    ldlinux_file = options['tftpdir']+"/"+options['service']+"/isolinux/ldlinux.c32"
    ldlinux_link = options['tftpdir']+"/ldlinux.c32"
    if not File.exist?(ldlinux_link)
      message = "Information:\tCopying file #{ldlinux_file} #{ldlinux_link}"
      command = "cp #{ldlinux_file} #{ldlinux_link}"
      execute_command(options,message,command)
    end
    options['clientdir']   = options['clientdir']+"/"+options['service']+"/"+options['name']
    client_file  = options['clientdir']+"/"+options['name']+".yml"
    client_url   = "http://"+options['publisherhost']+"/clients/"+options['service']+"/"+options['name']+"/"+options['name']+".yml"
    pxe_cfg_dir  = options['tftpdir']+"/pxelinux.cfg"
    pxe_cfg_file = options['mac'].gsub(/:/,"-")
    pxe_cfg_file = "01-"+pxe_cfg_file
    pxe_cfg_file = pxe_cfg_file.downcase
    pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
    vmlinuz_file = "/"+options['service']+"/coreos/vmlinuz"
    initrd_file  = "/"+options['service']+"/coreos/cpio.gz"
    file         = File.open(tmp_file,"w")
    file.write("default coreos\n")
    file.write("prompt 1\n")
    file.write("timeout 3\n")
    file.write("label coreos\n")
    file.write("  menu default\n")
    file.write("  kernel #{vmlinuz_file}\n")
    file.write("  append initrd=#{initrd_file} cloud-config-url=#{client_url}\n")
    file.close
    message = "Information:\tCreating PXE configuration file "+pxe_cfg_file
    command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
    execute_command(options,message,command)
    print_contents_of_file(options,"",pxe_cfg_file)
  end
  return
end

# Unconfigure BSD client

def unconfigure_xb_client(options)
  unconfigure_xb_pxe_client(options)
  unconfigure_xb_dhcp_client(options)
  return
end

# Configure DHCP entry

def configure_xb_dhcp_client(options)
  add_dhcp_client(options)
  return
end

# Unconfigure DHCP client

def unconfigure_xb_dhcp_client(options)
  remove_dhcp_client(options)
  return
end

# Unconfigure client PXE boot

def unconfigure_xb_pxe_client(options)
  options['mac'] = get_install_mac(options)
  if not options['mac']
    handle_output(options,"Warning:\tNo MAC Address entry found for #{options['name']}")
    quit(options)
  end
  tftp_pxe_file = options['mac'].gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
  tftp_pxe_file = options['tftpdir']+"/"+tftp_pxe_file
  if File.exist?(tftp_pxe_file)
    message = "Information:\tRemoving PXE boot file "+tftp_pxe_file+" for "+options['name']
    command = "rm #{tftp_pxe_file}"
    output  = execute_command(options,message,command)
  end
  unconfigure_xb_dhcp_client(options)
  return
end

# Output CoreOS client configuration file

def output_coreos_client_profile(options)
  options['clientdir'] = options['clientdir']+"/"+options['service']+"/"+options['name']
  check_dir_exists(options,options['clientdir'])
  output_file   = options['clientdir']+"/"+options['name']+".yml"
  root_crypt    = $q_struct['root_crypt'].value
  admin_group   = $q_struct['admin_group'].value
  admin_user    = $q_struct['admin_user'].value
  admin_crypt   = $q_struct['admin_crypt'].value
  admin_home    = $q_struct['admin_home'].value
  admin_uid     = $q_struct['admin_uid'].value
  admin_gid     = $q_struct['admin_gid'].value
  options['ip'] = $q_struct['ip'].value
  client_nic    = $q_struct['nic'].value
  network_ip    = options['ip'].split(".")[0..2].join(".")+".0"
  broadcast_ip  = options['ip'].split(".")[0..2].join(".")+".255"
  gateway_ip    = options['ip'].split(".")[0..2].join(".")+"."+options['gatewaynode']
  file = File.open(output_file,"w")
  file.write("\n")
  file.write("network-interfaces: |\n")
  file.write("  iface #{client_nic} inet static\n")
  file.write("  address #{options['ip']}\n")
  file.write("  network #{network_ip}\n")
  file.write("  netmask #{options['netmask']}\n")
  file.write("  broadcast #{broadcast_ip}\n")
  file.write("  gateway #{gateway_ip}\n")
  file.write("\n")
  file.write("hostname: #{options['name']}\n")
  file.write("\n")
  file.write("users:\n")
  file.write("  - name: root\n")
  file.write("    passwd: #{root_crypt}\n")
  file.write("  - name: #{admin_user}\n")
  file.write("    passwd: #{admin_crypt}\n")
  file.write("    groups: sudo\n")
  file.write("\n")
  return output_file
end

# Configure BSD client

def configure_xb_client(options)
  options['ip'] = single_install_ip(options)
  options['repodir'] = options['baserepodir']+"/"+options['service']
  if not File.directory?(options['repodir'])
    handle_output(options,"Warning:\tService #{options['service']} does not exist")
    handle_output(options,"")
    list_xb_services(options)
    quit(options)
  end
  if options['service'].to_s.match(/coreos/)
    populate_coreos_questions(options)
    process_questions(options)
    output_coreos_client_profile(options)
  end
  configure_xb_pxe_client(options)
  configure_xb_dhcp_client(options)
  add_hosts_entry(options)
  return
end
