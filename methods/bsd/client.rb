# Code for *BSD and other PXE clients (e.g. CoreOS)

# List BSD clients

def list_xb_clients()
  return
end

# Configure client PXE boot

def configure_xb_pxe_client(values)
  values['version']    = values['service'].split(/_/)[1..2].join(".")
  tftp_pxe_file = values['mac'].gsub(/:/, "")
  tftp_pxe_file = tftp_pxe_file.upcase
  tmp_file      = "/tmp/pxecfg"
  if values['service'].to_s.match(/openbsd/)
    tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
    test_file     = values['tftpdir']+"/"+tftp_pxe_file
    pxeboot_file  = values['service']+"/"+values['version']+"/"+values['arch'].gsub(/x86_64/, "amd64")+"/pxeboot"
  else
    tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
    test_file     = values['tftpdir']+"/"+tftp_pxe_file
    pxeboot_file  = values['service']+"/isolinux/pxelinux.0"
  end
  if File.symlink?(test_file)
    message = "Information:\tRemoving old PXE boot file "+test_file
    command = "rm #{test_file}"
    execute_command(values, message, command)
  end
  message = "Information:\tCreating PXE boot file for "+values['name']+" with MAC address "+values['mac']
  command = "cd #{values['tftpdir']} ; ln -s #{pxeboot_file} #{tftp_pxe_file}"
  execute_command(values, message, command)
  if values['service'].to_s.match(/coreos/)
    ldlinux_file = values['tftpdir']+"/"+values['service']+"/isolinux/ldlinux.c32"
    ldlinux_link = values['tftpdir']+"/ldlinux.c32"
    if not File.exist?(ldlinux_link)
      message = "Information:\tCopying file #{ldlinux_file} #{ldlinux_link}"
      command = "cp #{ldlinux_file} #{ldlinux_link}"
      execute_command(values, message, command)
    end
    values['clientdir']   = values['clientdir']+"/"+values['service']+"/"+values['name']
    client_file  = values['clientdir']+"/"+values['name']+".yml"
    client_url   = "http://"+values['publisherhost']+"/clients/"+values['service']+"/"+values['name']+"/"+values['name']+".yml"
    pxe_cfg_dir  = values['tftpdir']+"/pxelinux.cfg"
    pxe_cfg_file = values['mac'].gsub(/:/, "-")
    pxe_cfg_file = "01-"+pxe_cfg_file
    pxe_cfg_file = pxe_cfg_file.downcase
    pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
    vmlinuz_file = "/"+values['service']+"/coreos/vmlinuz"
    initrd_file  = "/"+values['service']+"/coreos/cpio.gz"
    file         = File.open(tmp_file, "w")
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
    execute_command(values, message, command)
    print_contents_of_file(values, "", pxe_cfg_file)
  end
  return
end

# Unconfigure BSD client

def unconfigure_xb_client(values)
  unconfigure_xb_pxe_client(values)
  unconfigure_xb_dhcp_client(values)
  return
end

# Configure DHCP entry

def configure_xb_dhcp_client(values)
  add_dhcp_client(values)
  return
end

# Unconfigure DHCP client

def unconfigure_xb_dhcp_client(values)
  remove_dhcp_client(values)
  return
end

# Unconfigure client PXE boot

def unconfigure_xb_pxe_client(values)
  values['mac'] = get_install_mac(values)
  if not values['mac']
    handle_output(values, "Warning:\tNo MAC Address entry found for #{values['name']}")
    quit(values)
  end
  tftp_pxe_file = values['mac'].gsub(/:/, "")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
  tftp_pxe_file = values['tftpdir']+"/"+tftp_pxe_file
  if File.exist?(tftp_pxe_file)
    message = "Information:\tRemoving PXE boot file "+tftp_pxe_file+" for "+values['name']
    command = "rm #{tftp_pxe_file}"
    output  = execute_command(values, message, command)
  end
  unconfigure_xb_dhcp_client(values)
  return
end

# Output CoreOS client configuration file

def output_coreos_client_profile(values)
  values['clientdir'] = values['clientdir']+"/"+values['service']+"/"+values['name']
  check_dir_exists(values, values['clientdir'])
  output_file   = values['clientdir']+"/"+values['name']+".yml"
  root_crypt    = values['q_struct']['root_crypt'].value
  admin_group   = values['q_struct']['admin_group'].value
  admin_user    = values['q_struct']['admin_user'].value
  admin_crypt   = values['q_struct']['admin_crypt'].value
  admin_home    = values['q_struct']['admin_home'].value
  admin_uid     = values['q_struct']['admin_uid'].value
  admin_gid     = values['q_struct']['admin_gid'].value
  values['ip'] = values['q_struct']['ip'].value
  client_nic    = values['q_struct']['nic'].value
  network_ip    = values['ip'].split(".")[0..2].join(".")+".0"
  broadcast_ip  = values['ip'].split(".")[0..2].join(".")+".255"
  gateway_ip    = values['ip'].split(".")[0..2].join(".")+"."+values['gatewaynode']
  file = File.open(output_file, "w")
  file.write("\n")
  file.write("network-interfaces: |\n")
  file.write("  iface #{client_nic} inet static\n")
  file.write("  address #{values['ip']}\n")
  file.write("  network #{network_ip}\n")
  file.write("  netmask #{values['netmask']}\n")
  file.write("  broadcast #{broadcast_ip}\n")
  file.write("  gateway #{gateway_ip}\n")
  file.write("\n")
  file.write("hostname: #{values['name']}\n")
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

def configure_xb_client(values)
  values['ip'] = single_install_ip(values)
  values['repodir'] = values['baserepodir']+"/"+values['service']
  if not File.directory?(values['repodir'])
    handle_output(values, "Warning:\tService #{values['service']} does not exist")
    handle_output(values, "")
    list_xb_services(values)
    quit(values)
  end
  if values['service'].to_s.match(/coreos/)
    populate_coreos_questions(values)
    process_questions(values)
    output_coreos_client_profile(values)
  end
  configure_xb_pxe_client(values)
  configure_xb_dhcp_client(values)
  add_hosts_entry(values)
  return
end
