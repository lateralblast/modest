
# VSphere client routines

def get_vs_clients(values)
  client_list  = []
  service_list = Dir.entries(values['baserepodir'])
  service_list.each do |service_name|
    if values['service'].to_s.match(/vmware/)
      values['repodir'] = values['baserepodir']+"/"+service_name
      file_list        = Dir.entries(values['repodir'])
      file_list.each do |file_name|
        if file_name.match(/\.cfg$/) and !file_name.match(/boot\.cfg|isolinux\.cfg/)
          client_name = file_name.split(/\./)[0]
          client_info = client_name+" service = "+service_name
          client_list.push(client_info)
        end
      end
    end
  end
  return client_list
end

# List ks clients

def list_vs_clients(values)
  client_list = get_vs_clients()
  if client_list.length > 0
    if values['output'].to_s.match(/html/)
      handle_output(values, "<h1>Available vSphere clients:</h1>") 
      handle_output(values, "<table border=\"1\">")
      handle_output(values, "<tr>")
      handle_output(values, "<th>Client</th>")
      handle_output(values, "<th>Service</th>")
      handle_output(values, "</tr>")
    else
      handle_output(values, "")
      handle_output(values, "Available vSphere clients:")
      handle_output(values, "")
    end
    client_list.each do |client_info|
      if values['output'].to_s.match(/html/)
        (values['name'], values['service']) = client_info.split(/ service = /)
        handle_output(values, "<tr>")
        handle_output(values, "<td>#{values['name']}</td>")
        handle_output(values, "<td>#{values['service']}</td>")
        handle_output(values, "</tr>")
      else
        handle_output(client_info)
      end
    end
    if values['output'].to_s.match(/html/)
      handle_output(values, "</table>")
    else
      handle_output(values, "")
    end
  end
  return
end

# Configure client PXE boot

def configure_vs_pxe_client(values)
  tftp_pxe_file  = values['mac'].gsub(/:/, "")
  tftp_pxe_file  = tftp_pxe_file.upcase
  tftp_boot_file = "boot.cfg.01"+tftp_pxe_file
  tftp_pxe_file  = "01"+tftp_pxe_file+".pxelinux"
  test_file      = values['tftpdir']+"/"+tftp_pxe_file
  if values['verbose'] == true
    handle_output(values, "Information:\tChecking vSphere TFTP directory")
  end
  check_dir_exists(values, values['tftpdir'])
  check_dir_owner(values, values['tftpdir'], values['uid'])
  if !File.exist?(test_file)
    message = "Information:\tCreating PXE boot file for "+values['name']+" with MAC address "+values['mac']
    if values['biostype'].to_s.match(/efi/)
      efi_boot_file = values['service'].to_s+"/efi/boot/bootx64.efi"
      command = "cd #{values['tftpdir']} ; ln -s #{efi_boot_file} #{tftp_pxe_file}"
    else
      pxelinux_file = values['service']+"/usr/share/syslinux/pxelinux.0"
      command = "cd #{values['tftpdir']} ; ln -s #{pxelinux_file} #{tftp_pxe_file}"
    end
    execute_command(values, message, command)
  end
  pxe_cfg_dir = values['tftpdir']+"/pxelinux.cfg"
  if values['verbose'] == true
    handle_output(values, "Information:\tChecking vSphere PXE configuration directory")
  end
  check_dir_exists(values, pxe_cfg_dir)
  check_dir_owner(values, pxe_cfg_dir, values['uid'])
  ks_url     = "http://"+values['hostip']+"/"+values['name']+"/"+values['name']+".cfg"
  #ks_url    = "http://"+values['hostip']+"/clients/"+values['service']+"/"+values['name']+"/"+values['name']+".cfg"
  mboot_file = values['service']+"/mboot.c32"
  if values['biostype'].to_s.match(/efi/)
    pxe_cfg_dir = values['tftpdir'].to_s+"/"+values['mac'].gsub(/:/, "-")
    check_dir_exists(values, pxe_cfg_dir)
    check_dir_owner(values, pxe_cfg_dir, values['uid'])
  else
    pxe_cfg_file1 = values['mac'].to_s.gsub(/:/, "-")
    pxe_cfg_file1 = "01-"+pxe_cfg_file1
    pxe_cfg_file1 = pxe_cfg_file1.downcase
    pxe_cfg_file1 = pxe_cfg_dir+"/"+pxe_cfg_file1
    pxe_cfg_file2 = values['mac'].split(":")[0..3].join+"-"+values['mac'].split(":")[4..5].join+"-0000-0000-"+values['mac'].gsub(/\:/, "")
    pxe_cfg_file2 = pxe_cfg_file2.downcase
    pxe_cfg_file2 = pxe_cfg_dir+"/"+pxe_cfg_file2
    for pxe_cfg_file in [ pxe_cfg_file1, pxe_cfg_file2 ]
      verbose_output(values, "Information:\tCreating Menu config file #{pxe_cfg_file}")
      file = File.open(pxe_cfg_file, "w")
      if values['serial'] == true
        file.write("serial 0 115200\n")
      end
      file.write("DEFAULT ESX\n")
      file.write("LABEL ESX\n")
      file.write("KERNEL #{mboot_file}\n")
      if values['text'] == true
        if values['serial'] == true
          file.write("APPEND -c #{tftp_boot_file} text gdbPort=none logPort=none tty2Port=com1 ks=#{ks_url} +++\n")
        else
          file.write("APPEND -c #{tftp_boot_file} text ks=#{ks_url} +++\n")
        end
      else
        file.write("APPEND -c #{tftp_boot_file} ks=#{ks_url} +++\n")
      end
      file.write("IPAPPEND 1\n")
      file.close
      print_contents_of_file(values, "", pxe_cfg_file)
    end
  end
  if values['biostype'].to_s.match(/efi/)
    tftp_boot_file = values['tftpdir'].to_s+"/01-"+values['mac'].to_s.gsub(/:/, "-").downcase+"/boot.cfg"
  else
    tftp_boot_file = values['tftpdir'].to_s+"/"+values['service'].to_s+"/"+tftp_boot_file
  end
  esx_boot_file = values['tftpdir'].to_s+"/"+values['service'].to_s+"/boot.cfg"
  if values['verbose'] == true
    handle_output(values, "Creating:\tBoot config file #{tftp_boot_file}")
  end
  copy=[]
  file=IO.readlines(esx_boot_file)
  file.each do |line|
    line=line.gsub(/\//, "")
    if values['text'] == true
      if line.match(/^kernelopt/)
        if not line.match(/text/)
          line = line.chomp+" text\n"
        end
      end
    end
    if line.match(/^kernelopt/)
      line = "kernelopt=ks=#{ks_url}\n"
    end
    if values['serial'] == true
      if line.match(/^kernelopt/)
        if not line.match(/nofb/)
          line = line.chomp+" nofb com1_baud=115200 com1_Port=0x3f8 tty2Port=com1 gdbPort=none logPort=none\n"
        end
      end
    end
    if line.match(/^title/)
      copy.push(line)
      copy.push("prefix=#{values['service']}\n")
    else
      if !line.match(/^prefix/)
        copy.push(line)
      end
    end
  end
  tftp_boot_file_dir = File.dirname(tftp_boot_file)
  if values['verbose'] == true
    handle_output(values, "Information:\tChecking vSphere TFTP boot file directory")
  end
  check_dir_exists(values, tftp_boot_file_dir)
  check_dir_owner(values, values['tftpdir'], values['uid'])
  check_dir_owner(values, tftp_boot_file_dir, values['uid'])
  File.open(tftp_boot_file, "w") {|file_data| file_data.puts copy}
  check_file_owner(values, tftp_boot_file, values['uid'])
  print_contents_of_file(values, "", tftp_boot_file)
  return
end

# Unconfigure client PXE boot

def unconfigure_vs_pxe_client(values)
  values['mac'] = get_install_nac(values)
  if not values['mac']
    handle_output(values, "Warning:\tNo MAC Address entry found for #{values['name']}")
    quit(values)
  end
  tftp_pxe_file = values['mac'].gsub(/:/, "")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
  tftp_pxe_file = values['tftpdir']+"/"+tftp_pxe_file
  if File.exist?(tftp_pxe_file)
    message = "Information:\tRemoving PXE boot file "+tftp_pxe_file+" for "+values['name']
    command = "rm #{tftp_pxe_file}"
    execute_command(values, message, command)
  end
  pxe_cfg_dir   = values['tftpdir']+"/pxelinux.cfg"
  pxe_cfg_file1 = values['mac'].gsub(/:/, "-")
  pxe_cfg_file1 = "01-"+pxe_cfg_file1
  pxe_cfg_file1 = pxe_cfg_file1.downcase
  pxe_cfg_file1 = pxe_cfg_dir+"/"+pxe_cfg_file1
  pxe_cfg_file2 = values['mac'].split(":")[0..3].join+"-"+values['mac'].split(":")[4..5].join+"-0000-0000-"+values['mac'].gsub(/\:/, "")
  pxe_cfg_file2 = pxe_cfg_file2.downcase
  pxe_cfg_file2 = pxe_cfg_dir+"/"+pxe_cfg_file2
  if File.exist?(pxe_cfg_file1)
    message = "Information:\tRemoving PXE boot config file "+pxe_cfg_file1+" for "+values['name']
    command = "rm #{pxe_cfg_file1}"
    execute_command(values, message, command)
  end
  if File.exist?(pxe_cfg_file2)
    message = "Information:\tRemoving PXE boot config file "+pxe_cfg_file2+" for "+values['name']
    command = "rm #{pxe_cfg_file2}"
    execute_command(values, message, command)
  end
  client_info        = get_vs_clients()
  values['service'] = client_info.grep(/#{values['name']}/)[0].split(/ = /)[1].chomp
  ks_dir             = values['tftpdir']+"/"+values['service']
  ks_cfg_file        = ks_dir+"/"+values['name']+".cfg"
  if File.exist?(ks_cfg_file)
    message = "Information:\tRemoving Kickstart boot config file "+ks_cfg_file+" for "+values['name']
    command = "rm #{ks_cfg_file}"
    execute_command(values, message, command)
  end
  unconfigure_vs_dhcp_client(values)
  return
end

# Configure DHCP entry

def configure_vs_dhcp_client(values)
  add_dhcp_client(values)
  return
end

# Unconfigure DHCP client

def unconfigure_vs_dhcp_client(values)
  remove_dhcp_client(values)
  return
end

# Configure VSphere client

def configure_vs_client(values)
  values['repodir'] = values['baserepodir']+"/"+values['service']
  if not File.directory?(values['repodir']) and not File.symlink?(values['repodir'])
    handle_output(values, "Information:\tWarning service #{values['service']} does not exist")
    handle_output(values, "")
    #list_vs_services(values)
    quit(values)
  end
  values['ip'] = single_install_ip(values)
  values = populate_vs_questions(values)
  process_questions(values)
  values['clientdir'] = values['clientdir']+"/"+values['service']+"/"+values['name']
  check_fs_exists(values, values['clientdir'])
  output_file = values['clientdir']+"/"+values['name']+".cfg"
  if File.exist?(output_file)
    File.delete(output_file)
  end
  ks_file = values['Kickstartfile'].to_s
  if ks_file.match(/[a-z]/) and File.exist?(ks_file)
    message = "Information:\tCopying #{ks_file} to #{output_file}"
    command = "cp #{ks_file} #{output_file}"
    execute_command(values, message, command)
  else
    output_vs_header(values, output_file)
    # Output firstboot list
    post_list = populate_vs_firstboot_list(values)
    output_vs_post_list(post_list, output_file)
    # Output post list
    post_list = populate_vs_post_list(values)
    output_vs_post_list(post_list, output_file)
  end
  if output_file
    %x[chmod 755 #{output_file}]
  end
  if values['verbose'] == true
    print_contents_of_file(values, "", output_file)
  end
  configure_vs_pxe_client(values)
  configure_vs_dhcp_client(values)
  add_apache_alias(values, values['clientdir'])
  add_hosts_entry(values)
  return
end

# Unconfigure VSphere client

def unconfigure_vs_client(values)
  unconfigure_vs_pxe_client(values)
  unconfigure_vs_dhcp_client(values)
  return
end

# Populate firstboot commands

def populate_vs_firstboot_list(values)
  post_list = []
  vm_network_name    = values['q_struct']['vm_network_name'].value 
  vm_network_vswitch = values['q_struct']['vm_network_vswitch'].value
  vm_network_vlanid  = values['q_struct']['vm_network_vlanid'].value
  datastore_name     = values['q_struct']['datastore'].value
  #post_list.push("%pre --interpreter=busybox")
  #post_list.push("echo '127.0.0.1 localhost' >> /etc/resolv.conf")
  #post_list.push("")
  post_list.push("%firstboot --interpreter=busybox")
  post_list.push("")
  post_list.push("# enable HV (Hardware Virtualization to run nested 64bit Guests + Hyper-V VM)")
  post_list.push("grep -i 'vhv.allow' /etc/vmware/config || echo 'vhv.allow = \"TRUE\"' >> /etc/vmware/config")
  post_list.push("")
  post_list.push("# set hostname and DNS")
  post_list.push("esxcli system hostname set --fqdn=#{values['name']}.#{values['domainname']}")
  post_list.push("esxcli network ip dns search add --domain=#{values['domainname']}")
  post_list.push("esxcli network ip dns server add --server=#{values['nameserver']}")
  post_list.push("")
  post_list.push("# enable & start remote ESXi Shell  (SSH)")
  post_list.push("vim-cmd hostsvc/enable_ssh")
  post_list.push("vim-cmd hostsvc/start_ssh")
  post_list.push("")
  post_list.push("# Allow root access to DCUI")
  post_list.push("vim-cmd hostsvc/advopt/update DCUI.Access string root")
  post_list.push("")
  post_list.push("# enable & start ESXi Shell (TSM)")
  post_list.push("vim-cmd hostsvc/enable_esx_shell")
  post_list.push("vim-cmd hostsvc/start_esx_shell")
  post_list.push("")
  post_list.push("vim-cmd hostsvc/enable_remote_tsm ")
  post_list.push("vim-cmd hostsvc/start_remote_tsm")
  post_list.push("")
  post_list.push("# Fix for network dropouts")
  post_list.push("esxcli system settings advanced set -o /Net/FollowHardwareMac -i 1")
#  post_list.push("")
#  post_list.push("vim-cmd hostsvc/net/refresh")
  post_list.push("")
  post_list.push("# supress ESXi Shell shell warning ")
  post_list.push("esxcli system settings advanced set -o /UserVars/SuppressShellWarning -i 1")
#  post_list.push("esxcli system settings advanced set -o /UserVars/ESXiShellTimeOut -i 1")
  post_list.push("")
  post_list.push("# rename local datastore to something more meaningful")
  post_list.push("vim-cmd hostsvc/datastore/rename datastore1 \"$(hostname -s)-local-storage-1\"")
#  post_list.push("")
#  post_list.push("# Server VM Network setup")
#  post_list.push("esxcli network vswitch standard portgroup add --portgroup-name #{vm_network_name} --vswitch-name #{vm_network_vswitch}")
#  post_list.push("esxcli network vswitch standard portgroup set --portgroup-name #{vm_network_name} --vlan-id #{vm_network_vlanid}")
  post_list.push("")
  if values['license'].to_s.match(/[a-z,A-Z]/)
    post_list.push("# assign license")
    post_list.push("vim-cmd vimsvc/license --set #{values['license']}")
    post_list.push("")
  end
  post_list.push("# enable management interface")
  post_list.push("cat > /tmp/enableVmkInterface.py << __ENABLE_MGMT_INT__")
  post_list.push("import sys,re,os,urllib,urllib2")
  post_list.push("")
  post_list.push("# connection info to MOB")
  post_list.push("")
  post_list.push("url = \"https://localhost/mob/?moid=ha-vnic-mgr&method=selectVnic\"")
  post_list.push("username = \"root\"")
  post_list.push("password = \"#{values['rootpassword']}\"")
  post_list.push("")
  post_list.push("# Create global variables")
  post_list.push("global passman,authhandler,opener,req,page,page_content,nonce,headers,cookie,params,e_params")
  post_list.push("")
  post_list.push("#auth")
  post_list.push("passman = urllib2.HTTPPasswordMgrWithDefaultRealm()")
  post_list.push("passman.add_password(None,url,username,password)")
  post_list.push("authhandler = urllib2.HTTPBasicAuthHandler(passman)")
  post_list.push("opener = urllib2.build_opener(authhandler)")
  post_list.push("urllib2.install_opener(opener)")
  post_list.push("")
  post_list.push("# Code to capture required page data and cookie required for post back to meet CSRF requirements  ###")
  post_list.push("req = urllib2.Request(url)")
  post_list.push("page = urllib2.urlopen(req)")
  post_list.push("page_content= page.read()")
  post_list.push("")
  post_list.push("# regex to get the vmware-session-nonce value from the hidden form entry")
  post_list.push("reg = re.compile('name=\"vmware-session-nonce\" type=\"hidden\" value=\"?([^\s^\"]+)\"')")
  post_list.push("nonce = reg.search(page_content).group(1)")
  post_list.push("")
  post_list.push("# get the page headers to capture the cookie")
  post_list.push("headers = page.info()")
  post_list.push("cookie = headers.get(\"Set-Cookie\")")
  post_list.push("")
  post_list.push("#execute method")
  post_list.push("params = {'vmware-session-nonce':nonce,'nicType':'management','device':'vmk0'}")
  post_list.push("e_params = urllib.urlencode(params)")
  post_list.push("req = urllib2.Request(url, e_params, headers={\"Cookie\":cookie})")
  post_list.push("page = urllib2.urlopen(req).read()")
  post_list.push("__ENABLE_MGMT_INT__")
  post_list.push("")
  post_list.push("python /tmp/enableVmkInterface.py")
  post_list.push("")
  post_list.push("# backup ESXi configuration to persist changes")
  post_list.push("/sbin/auto-backup.sh")
  post_list.push("")
#  post_list.push("# enter maintenance mode")
#  post_list.push("vim-cmd hostsvc/maintenance_mode_enter")
#  post_list.push("")
  post_list.push("# copy %first boot script logs to persisted datastore")
  post_list.push("cp /var/log/hostd.log \"/vmfs/volumes/$(hostname -s)-local-storage-1/firstboot-hostd.log\"")
  post_list.push("cp /var/log/esxi_install.log \"/vmfs/volumes/$(hostname -s)-local-storage-1/firstboot-esxi_install.log\"")
  post_list.push("")
  if values['serial'] == true
    post_list.push("# Fix bootloader to run in serial mode")
    post_list.push("sed -i '/no-auto-partition/ s/$/ text nofb com1_baud=115200 com1_Port=0x3f8 tty2Port=com1 gdbPort=none logPort=none/' /bootbank/boot.cfg")
    post_list.push("")
  end
  post_list.push("# enable & start ESXi Shell (TSM)")
  post_list.push("sed -i -E 's,^(PasswordAuthentication ).*,\1yes,g' /etc/ssh/sshd_config")
  post_list.push("vim-cmd hostsvc/enable_esx_shell")
  post_list.push("vim-cmd hostsvc/start_esx_shell")
  post_list.push("")
  post_list.push("reboot")
  return post_list
end

# Populate post commands

def populate_vs_post_list(values)
  post_list = []
  post_list.push("")
  return post_list
end

# Output the VSphere file header

def output_vs_header(values, output_file)
  if values['verbose'] == true
    handle_output(values, "Information:\tCreating vSphere file #{output_file}")
  end
  dir_name = File.dirname(output_file)
  top_dir  = dir_name.split(/\//)[0..-2].join("/")
  if values['verbose'] == true
    handle_output(values, "Information:\tChecking vSphere boot header file directory")
  end
  check_dir_owner(values, top_dir, values['uid'])
  check_dir_exists(values, dir_name)
  check_dir_owner(values, dir_name, values['uid'])
  file = File.open(output_file, 'w')
  values['q_order'].each do |key|
    if values['q_struct'][key].type.match(/output/)
      if not values['q_struct'][key].parameter.match(/[a-z,A-Z]/)
        output=values['q_struct'][key].value+"\n"
      else
        output=values['q_struct'][key].parameter+" "+values['q_struct'][key].value+"\n"
        if values['verbose'] == true
          handle_output(values, output)
        end
      end
      file.write(output)
    end
  end
  file.close
  return
end

# Output the ks packages list

def output_vs_post_list(post_list, output_file)
  file=File.open(output_file, 'a')
  post_list.each do |line|
    output=line+"\n"
    file.write(output)
  end
  file.close
  return
end

# Check service name

def check_vs_install_service(values)
  if !values['service'].to_s.match(/[a-z,A-Z]/)
    handle_output(values, "Warning:\tService name not given")
    quit(values)
  end
  client_list=Dir.entries(values['baserepodir'])
  if not client_list.grep(values['service'])
    handle_output(values, "Warning:\tService name #{values['service']} does not exist")
    quit(values)
  end
  return
end
