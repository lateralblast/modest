
# Jumpstart client routines

# Create sysid file

def create_js_sysid_file(options)
  tmp_file = "/tmp/sysid_"+options['name']
  file=File.open(tmp_file,"w")
  $q_order.each do |key|
    if $q_struct[key].type == "output"
      if $q_struct[key].parameter == ""
        output = $q_struct[key].value+"\n"
      else
        output = $q_struct[key].parameter+"="+$q_struct[key].value+"\n"
      end
    end
    file.write(output)
  end
  file.close
  message = "Information:\tCreating configuration file "+options['sysid']+" for "+options['name']
  command = "cp #{tmp_file} #{options['sysid']} ; rm #{tmp_file}"
  execute_command(options,message,command)
  print_contents_of_file(options,"",options['sysid'])
  return
end

# Create machine file

def create_js_machine_file(options)
  tmp_file = "/tmp/machine_"+options['name']
  file=File.open(tmp_file,"w")
  $q_order.each do |key|
    if $q_struct[key].parameter.to_s.match(/install_type|system_type|cluster|partitioning|pool|bootenv/)
      if $q_struct[key].type == "output" 
        if $q_struct[key].parameter == ""
          output = $q_struct[key].value+"\n"
        else
          output = $q_struct[key].parameter+" "+$q_struct[key].value+"\n"
        end
      end
    end
    file.write(output)
  end
  file.close
  message = "Information:\tCreating configuration file "+options['machine']+" for "+options['name']
  command = "cp #{tmp_file} #{options['machine']} ; rm #{tmp_file}"
  execute_command(options,message,command)
  print_contents_of_file(options,"",options['machine'])
  return
end

# Get rules karch line

def create_js_rules_file(options)
  tmp_file1 = "/tmp/rule_"+options['name']
  tmp_file2 = "/tmp/rule_"+options['name']+".ok"
  ok_file   = options['rules']+".ok"
  if options['karch'].to_s.match(/sun4/)
    karch_line = "karch "+options['karch']+" - machine."+options['name']+" -"
  else
    if options['karch'].to_s.match(/packer/)
      karch_line = "any - - profile finish"
    else
      karch_line = "any - - machine."+options['name']+" -"
    end
  end
  file = File.open(tmp_file1,"w")
  file.write("#{karch_line}\n")
  file.close
  message = "Information:\tCreating configuration file "+options['rules']+" for "+options['name']
  command = "cp #{tmp_file1} #{options['rules']} ; rm #{tmp_file1}"
  execute_command(options,message,command)
  print_contents_of_file(options,"",options['rules'])
  check_sum = %x[sum #{options['rules']} |awk '{print $1}'].strip
  file = File.open(tmp_file2,"w")
  file.write("#{karch_line}\n")
  file.write("# version=2 checksum=#{check_sum}\n")
  file.close
  message = "Information:\tCreating configuration file "+ok_file+" for "+options['name']
  command = "cp #{tmp_file2} #{ok_file} ; rm #{tmp_file2}"
  execute_command(options,message,command)
  print_contents_of_file(options,"",ok_file)
  return karch_line
end

# List jumpstart clients

def list_js_clients()
  list_clients(options)
  return
end

# Create finish script

def create_js_finish_file(options)
  passwd_crypt = get_password_crypt(options['adminpassword']) 
  file_array   = []
  file_array.push("#!/bin/sh")
  file_array.push("")
  file_array.push("ADMINUSER='#{options['adminuser']}'")
  file_array.push("")
  file_array.push("# Selecting host name")
  file_array.push("echo '#{options['name']}' > /a/etc/nodename")
  file_array.push("")
  file_array.push("# Allowing root SSH")
  file_array.push("cat /a/etc/ssh/sshd_config | sed -e 's/PermitRootLogin\\ .*$/PermitRootLogin yes/g' > /tmp/sshd_config.$$")
  file_array.push("cat /tmp/sshd_config.$$ > /a/etc/ssh/sshd_config")
  file_array.push("")
  file_array.push("# Allow simple passwords")
  file_array.push("cat /a/etc/default/passwd | sed -e 's/^#NAMECHECK=.*$/NAMECHECK=NO/g' \\")
  file_array.push("    -e 's/^#MINNONALPHA=.*$/MINNONALPHA=0/g' > /tmp/passwd.$$")
  file_array.push("cat /tmp/passwd.$$ > /a/etc/default/passwd")
  file_array.push("")
  file_array.push("# Create user and group")
  file_array.push("")
  file_array.push("chroot /a /usr/sbin/groupadd ${ADMINUSER}")
  file_array.push("chroot /a /usr/sbin/useradd -m -d /export/home/${ADMINUSER} -s /usr/bin/bash -g ${ADMINUSER} ${ADMINUSER}")
  file_array.push("")
  file_array.push("# Create password")
  file_array.push("PASSWD=`perl -e 'print crypt($ARGV[0], substr(rand(data),2));' #{options['adminpassword']}`")
  file_array.push("cat /a/etc/shadow | sed -e 's#^'${ADMINUSER}':UP:#'${ADMINUSER}':'${PASSWD}'#g'  > /tmp/shadow.$$")
  file_array.push("cat /tmp/shadow.$$ > /a/etc/shadow")
  file_array.push("")
  file_array.push("# Install 'Primary Administrator' profile")
  file_array.push("")
  file_array.push("cat /cdrom/Solaris_10/Product/SUNWwbcor/reloc/etc/security/auth_attr >> /a/etc/security/auth_attr")
  file_array.push("cat /cdrom/Solaris_10/Product/SUNWwbcor/reloc/etc/security/exec_attr >> /a/etc/security/exec_attr")
  file_array.push("cat /cdrom/Solaris_10/Product/SUNWwbcor/reloc/etc/security/prof_attr >> /a/etc/security/prof_attr")
  file_array.push("")
  file_array.push("# Assign it to admin")
  file_array.push("chroot /a /usr/sbin/usermod -P'Primary Administrator' ${ADMINUSER}")
  file = File.open(options['finish'],"w")
  file_array.each do |line|
    line = line+"\n"
    file.write(line)
  end
  file.close()
  print_contents_of_file(options,"",options['finish'])
  return
end

# Check Jumpstart config

def check_js_config(options)
  file_name     = "check"
  check_script  = options['repodir']+"/Solaris_"+options['version']+"/Misc/jumpstart_sample/"+file_name
  if not File.exist?("#{options['clientdir']}/check")
    message = "Information:\tCopying check script "+check_script+" to "+options['clientdir']
    command = "cd #{options['clientdir']} ; cp -p #{check_script} ."
    output  = execute_command(options,message,command)
  end
  return
end

# Remove client

def remove_js_client(options)
  remove_dhcp_client(options)
  return
end

# Configure client PXE boot

def configure_js_pxe_client(options)
  if options['arch'].to_s.match(/i386/)
    tftp_pxe_file = options['mac'].gsub(/:/,"")
    tftp_pxe_file = tftp_pxe_file.upcase
    tftp_pxe_file = "01"+tftp_pxe_file+".bios"
    test_file     = options['tftpdir']+"/"+tftp_pxe_file
    if not File.exist?(test_file)
      pxegrub_file = options['service']+"/boot/grub/pxegrub"
      message      = "Information:\tCreating PXE boot file for "+options['name']+" with MAC address "+options['mac']
      command      = "cd #{options['tftpdir']} ; ln -s #{pxegrub_file} #{tftp_pxe_file}"
      execute_command(options,message,command)
    end
    pxe_cfg_file = options['mac'].gsub(/:/,"")
    pxe_cfg_file = "01"+pxe_cfg_file.upcase
    pxe_cfg_file = "menu.lst."+pxe_cfg_file
    pxe_cfg_file = options['tftpdir']+"/"+pxe_cfg_file
    sysid_dir    = options['clientdir']+"/"+options['service']+"/"+options['name']
    install_url  = options['publisherhost']+":"+options['repodir']
    sysid_url    = options['publisherhost']+":"+sysid_dir
    tmp_file     = "/tmp/pxe_"+options['name']
    file         = File.open(tmp_file,"w")
    file.write("default 0\n")
    file.write("timeout 3\n")
    file.write("title Oracle Solaris\n")
    if options['text'] == true
      if options['serial'] == true
        file.write("\tkernel$ #{options['service']}/boot/multiboot kernel/$ISADIR/unix - install nowin -B console=ttya,keyboard-layout=US-English,install_media=#{install_url},install_config = #{sysid_url},sysid_config = #{sysid_url}\n")
      else
        file.write("\tkernel$ #{options['service']}/boot/multiboot kernel/$ISADIR/unix - install nowin -B keyboard-layout=US-English,install_media=#{install_url},install_config = #{sysid_url},sysid_config = #{sysid_url}\n")
      end
    else
      file.write("\tkernel$ #{options['service']}/boot/multiboot kernel/$ISADIR/unix - install -B keyboard-layout=US-English,install_media=#{install_url},install_config = #{sysid_url},sysid_config = #{sysid_url}\n")
    end
    file.write("\tmodule$ #{options['service']}/boot/$ISADIR/x86.miniroot\n")
    file.close
    message = "Information:\tCreating PXE boot config file "+pxe_cfg_file
    command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
    execute_command(options,message,command)
    print_contents_of_file(options,"",pxe_cfg_file)
  end
  return
end

# Configure DHCP client

def configure_js_dhcp_client(options)
  options['ip'] = single_install_ip(options)
  add_dhcp_client(options)
  return
end

# Unconfigure DHCP client

def unconfigure_js_dhcp_client(options)
  remove_dhcp_client(options)
  return
end

# Unconfigure client

def unconfigure_js_client(options)
  if options['service'].to_s.match(/[a-z,A-Z]/)
    options['repodir']=options['baserepodir']+options['service']
    if File.directory(options['repodir'])
      remove_js_client(options)
    else
      handle_output(options,"Warning:\tClient #{options['name']} does not exist under service #{options['service']}")
    end
  end
  service_list = Dir.entries(options['baserepodir'])
  service_list.each do |temp_name|
    if temp_name.match(/sol/) and not temp_name.match(/sol_11/)
      options['repodir'] = options['baserepodir']+"/"+temp_name
      clients_dir      = options['repodir']+"/clients"
      if File.directory?(clients_dir)
        client_list = Dir.entries(clients_dir)
        client_list.each do |dir_name|
          if dir_name.match(/#{options['name']}/)
            remove_js_client(options['name'],options['repodir'],temp_name)
            return
          end
        end
      end
    end
  end
  options['ip'] = get_install_ip(options)
  remove_hosts_entry(options)
  return
end

# Add install client

def add_install_client(options)
  tool_dir = options['repodir']+"/Solaris_*/Tools"
  message  = "Information:\tAdding jumpstart client #{options['name']}"
  command  = "cd #{tool_dir} ; ./add_install_client -e #{options['mac']} -i #{options['ip']} -s #{options['hostip']}:#{options['repodir']} -c #{options['hostip']}:#{options['clientdir']} -p #{options['hostip']}:#{options['clientdir']} #{options['name']} #{options['karch']}"
  execute_command(options,message,command)
  return
end

# Configure client

def configure_js_client(options)
  if not options['arch'].to_s.match(/i386|sparc/)
    if options['file']
      if options['file'].to_s.match(/i386/)
        options['arch'] = "i386"
      else
        options['arch'] = "sparc"
      end
    end
    if options['service']
      if options['service'].to_s.match(/i386/)
        options['arch'] = "i386"
      else
        options['arch'] = "sparc"
      end
    end
  end
  if options['file'].to_s.match(/flar/)
    if not File.exist?(options['image'])
      handle_output(options,"Warning:\tFlar file #{options['file']} does not exist")
      quit(options)
    else
      message = "Information:\tMaking sure file is world readable"
      command = "chmod 755 #{options['file']}"
      execute_command(options,message,command)
    end
    export_dir  = Pathname.new(options['file'])
    export_dir  = export_dir.dirname.to_s
    add_apache_alias(options,export_dir)
    if not options['service'].to_s.match(/[a-z,A-Z]/)
      options['service'] = Pathname.new(options['file'])
      options['service'] = options['service'].basename.to_s.gsub(/\.flar/,"")
    end
  else
    if not options['service'].to_s.match(/i386|sparc/)
      options['service'] = options['service']+"_"+options['arch']
    end
    if not options['service'].to_s.match(/#{options['arch']}/)
      handle_output(options,"Information:\tService #{options['service']} and Client architecture #{options['arch']} do not match")
     quit(options)
    end
    options['repodir']=options['baserepodir']+"/"+options['service']
    if not File.directory?(options['repodir'])
      handle_output(options,"Warning:\tService #{options['service']} does not exist")
      handle_output(options,"") 
      list_js_services(options)
      quit(options)
    end
  end
  # Create clients directory
  clients_dir = options['clientdir']+"/"+options['service']
  check_dir_exists(options,clients_dir)
  # Create client directory
  options['clientdir'] = clients_dir+"/"+options['name']
  check_dir_exists(options,options['clientdir'])
  # Get release information
  options['repodir'] = options['baserepodir']+"/"+options['service']
  if options['osname'].to_s.match(/Darwin/)
    check_osx_iso_mount(options)
  end
  options['version'] = get_js_iso_version(options)
  options['update']  = get_js_iso_update(options)
  options['ip'] = single_install_ip(options)
  # Populate sysid questions and process them
  options = populate_js_sysid_questions(options)
  process_questions(options)
  if options['arch'].to_s.match(/i386/)
    options['karch'] = options['arch']
  else
    options['karch'] = $q_struct['system_karch'].value
  end
  # Create sysid file
  options['sysid'] = options['clientdir']+"/sysidcfg"
  create_js_sysid_file(options)
  # Populate machine questions
  options = populate_js_machine_questions(options)
  process_questions(options)
  options['machine'] = options['clientdir']+"/machine."+options['name']
  create_js_machine_file(options)
  # Create rules file
  options['rules'] = options['clientdir']+"/rules"
  create_js_rules_file(options)
  configure_js_pxe_client(options)
  configure_js_dhcp_client(options)
  check_js_config(options)
  add_hosts_entry(options)
  add_to_ethers_file(options)
  #export_name = "#{options['name']}_config"
  #add_nfs_export(options,export_name,options['clientrootdir'])
  add_install_client(options)
  check_tftp_server(options)
  return
end
