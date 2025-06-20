# frozen_string_literal: true

# Jumpstart client routines

# Create sysid file

def create_js_sysid_file(values)
  tmp_file = "/tmp/sysid_#{values['name']}"
  file = File.open(tmp_file, 'w')
  values['order'].each do |key|
    if values['answers'][key].type == 'output'
      output = if values['answers'][key].parameter == ''
                 "#{values['answers'][key].value}\n"
               else
                 "#{values['answers'][key].parameter}=#{values['answers'][key].value}\n"
               end
    end
    file.write(output)
  end
  file.close
  message = "Information:\tCreating configuration file #{values['sysid']} for #{values['name']}"
  command = "cp #{tmp_file} #{values['sysid']} ; rm #{tmp_file}"
  execute_command(values, message, command)
  print_contents_of_file(values, '', values['sysid'])
  nil
end

# Create machine file

def create_js_machine_file(values)
  tmp_file = "/tmp/machine_#{values['name']}"
  file = File.open(tmp_file, 'w')
  values['order'].each do |key|
    if values['answers'][key].parameter.to_s.match(/install_type|system_type|cluster|partitioning|pool|bootenv/) && (values['answers'][key].type == 'output')
      output = if values['answers'][key].parameter == ''
                 "#{values['answers'][key].value}\n"
               else
                 "#{values['answers'][key].parameter} #{values['answers'][key].value}\n"
               end
    end
    file.write(output)
  end
  file.close
  message = "Information:\tCreating configuration file #{values['machine']} for #{values['name']}"
  command = "cp #{tmp_file} #{values['machine']} ; rm #{tmp_file}"
  execute_command(values, message, command)
  print_contents_of_file(values, '', values['machine'])
  nil
end

# Get rules karch line

def create_js_rules_file(values)
  tmp_file1 = "/tmp/rule_#{values['name']}"
  tmp_file2 = "/tmp/rule_#{values['name']}.ok"
  ok_file   = "#{values['rules']}.ok"
  karch_line = if values['karch'].to_s.match(/sun4/)
                 "karch #{values['karch']} - machine.#{values['name']} -"
               elsif values['karch'].to_s.match(/packer/)
                 'any - - profile finish'
               else
                 "any - - machine.#{values['name']} -"
               end
  file = File.open(tmp_file1, 'w')
  file.write("#{karch_line}\n")
  file.close
  message = "Information:\tCreating configuration file #{values['rules']} for #{values['name']}"
  command = "cp #{tmp_file1} #{values['rules']} ; rm #{tmp_file1}"
  execute_command(values, message, command)
  print_contents_of_file(values, '', values['rules'])
  check_sum = `sum #{values['rules']} |awk '{print $1}'`.strip
  file = File.open(tmp_file2, 'w')
  file.write("#{karch_line}\n")
  file.write("# version=2 checksum=#{check_sum}\n")
  file.close
  message = "Information:\tCreating configuration file #{ok_file} for #{values['name']}"
  command = "cp #{tmp_file2} #{ok_file} ; rm #{tmp_file2}"
  execute_command(values, message, command)
  print_contents_of_file(values, '', ok_file)
  karch_line
end

# List jumpstart clients

def list_js_clients(values)
  list_clients(values)
  nil
end

# Create finish script

def create_js_finish_file(values)
  get_password_crypt(values['adminpassword'])
  file_array = []
  file_array.push('#!/bin/sh')
  file_array.push('')
  file_array.push("ADMINUSER='#{values['adminuser']}'")
  file_array.push('')
  file_array.push('# Selecting host name')
  file_array.push("echo '#{values['name']}' > /a/etc/nodename")
  file_array.push('')
  file_array.push('# Allowing root SSH')
  file_array.push("cat /a/etc/ssh/sshd_config | sed -e 's/PermitRootLogin\\ .*$/PermitRootLogin yes/g' > /tmp/sshd_config.$$")
  file_array.push('cat /tmp/sshd_config.$$ > /a/etc/ssh/sshd_config')
  file_array.push('')
  file_array.push('# Allow simple passwords')
  file_array.push("cat /a/etc/default/passwd | sed -e 's/^#NAMECHECK=.*$/NAMECHECK=NO/g' \\")
  file_array.push("    -e 's/^#MINNONALPHA=.*$/MINNONALPHA=0/g' > /tmp/passwd.$$")
  file_array.push('cat /tmp/passwd.$$ > /a/etc/default/passwd')
  file_array.push('')
  file_array.push('# Create user and group')
  file_array.push('')
  file_array.push('chroot /a /usr/sbin/groupadd ${ADMINUSER}')
  file_array.push('chroot /a /usr/sbin/useradd -m -d /export/home/${ADMINUSER} -s /usr/bin/bash -g ${ADMINUSER} ${ADMINUSER}')
  file_array.push('')
  file_array.push('# Create password')
  file_array.push("PASSWD=`perl -e 'print crypt($ARGV[0], substr(rand(data),2));' #{values['adminpassword']}`")
  file_array.push("cat /a/etc/shadow | sed -e 's#^'${ADMINUSER}':UP:#'${ADMINUSER}':'${PASSWD}'#g'  > /tmp/shadow.$$")
  file_array.push('cat /tmp/shadow.$$ > /a/etc/shadow')
  file_array.push('')
  file_array.push("# Install 'Primary Administrator' profile")
  file_array.push('')
  file_array.push('cat /cdrom/Solaris_10/Product/SUNWwbcor/reloc/etc/security/auth_attr >> /a/etc/security/auth_attr')
  file_array.push('cat /cdrom/Solaris_10/Product/SUNWwbcor/reloc/etc/security/exec_attr >> /a/etc/security/exec_attr')
  file_array.push('cat /cdrom/Solaris_10/Product/SUNWwbcor/reloc/etc/security/prof_attr >> /a/etc/security/prof_attr')
  file_array.push('')
  file_array.push('# Assign it to admin')
  file_array.push("chroot /a /usr/sbin/usermod -P'Primary Administrator' ${ADMINUSER}")
  file = File.open(values['finish'], 'w')
  file_array.each do |line|
    line += "\n"
    file.write(line)
  end
  file.close
  print_contents_of_file(values, '', values['finish'])
  nil
end

# Check Jumpstart config

def check_js_config(values)
  file_name     = 'check'
  check_script  = "#{values['repodir']}/Solaris_#{values['version']}/Misc/jumpstart_sample/#{file_name}"
  unless File.exist?("#{values['clientdir']}/check")
    message = "Information:\tCopying check script #{check_script} to #{values['clientdir']}"
    command = "cd #{values['clientdir']} ; cp -p #{check_script} ."
    execute_command(values, message, command)
  end
  nil
end

# Remove client

def remove_js_client(values)
  remove_dhcp_client(values)
  nil
end

# Configure client PXE boot

def configure_js_pxe_client(values)
  if values['arch'].to_s.match(/i386/)
    tftp_pxe_file = values['mac'].gsub(/:/, '')
    tftp_pxe_file = tftp_pxe_file.upcase
    tftp_pxe_file = "01#{tftp_pxe_file}.bios"
    test_file     = "#{values['tftpdir']}/#{tftp_pxe_file}"
    unless File.exist?(test_file)
      pxegrub_file = "#{values['service']}/boot/grub/pxegrub"
      message      = "Information:\tCreating PXE boot file for #{values['name']} with MAC address #{values['mac']}"
      command      = "cd #{values['tftpdir']} ; ln -s #{pxegrub_file} #{tftp_pxe_file}"
      execute_command(values, message, command)
    end
    pxe_cfg_file = values['mac'].gsub(/:/, '')
    pxe_cfg_file = "01#{pxe_cfg_file.upcase}"
    pxe_cfg_file = "menu.lst.#{pxe_cfg_file}"
    pxe_cfg_file = "#{values['tftpdir']}/#{pxe_cfg_file}"
    sysid_dir    = "#{values['clientdir']}/#{values['service']}/#{values['name']}"
    install_url  = "#{values['publisherhost']}:#{values['repodir']}"
    sysid_url    = "#{values['publisherhost']}:#{sysid_dir}"
    tmp_file     = "/tmp/pxe_#{values['name']}"
    file         = File.open(tmp_file, 'w')
    file.write("default 0\n")
    file.write("timeout 3\n")
    file.write("title Oracle Solaris\n")
    if values['text'] == true
      if values['serial'] == true
        file.write("\tkernel$ #{values['service']}/boot/multiboot kernel/$ISADIR/unix - install nowin -B console=ttya,keyboard-layout=US-English,install_media=#{install_url},install_config = #{sysid_url},sysid_config = #{sysid_url}\n")
      else
        file.write("\tkernel$ #{values['service']}/boot/multiboot kernel/$ISADIR/unix - install nowin -B keyboard-layout=US-English,install_media=#{install_url},install_config = #{sysid_url},sysid_config = #{sysid_url}\n")
      end
    else
      file.write("\tkernel$ #{values['service']}/boot/multiboot kernel/$ISADIR/unix - install -B keyboard-layout=US-English,install_media=#{install_url},install_config = #{sysid_url},sysid_config = #{sysid_url}\n")
    end
    file.write("\tmodule$ #{values['service']}/boot/$ISADIR/x86.miniroot\n")
    file.close
    message = "Information:\tCreating PXE boot config file #{pxe_cfg_file}"
    command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
    execute_command(values, message, command)
    print_contents_of_file(values, '', pxe_cfg_file)
  end
  nil
end

# Configure DHCP client

def configure_js_dhcp_client(values)
  values['ip'] = single_install_ip(values)
  add_dhcp_client(values)
  nil
end

# Unconfigure DHCP client

def unconfigure_js_dhcp_client(values)
  remove_dhcp_client(values)
  nil
end

# Unconfigure client

def unconfigure_js_client(values)
  if values['service'].to_s.match(/[a-z,A-Z]/)
    values['repodir'] = values['baserepodir'] + values['service']
    if File.directory(values['repodir'])
      remove_js_client(values)
    else
      warning_message(values, "Client #{values['name']} does not exist under service #{values['service']}")
    end
  end
  service_list = Dir.entries(values['baserepodir'])
  service_list.each do |temp_name|
    next unless temp_name.match(/sol/) && !temp_name.match(/sol_11/)

    values['repodir'] = "#{values['baserepodir']}/#{temp_name}"
    clients_dir = "#{values['repodir']}/clients"
    next unless File.directory?(clients_dir)

    client_list = Dir.entries(clients_dir)
    client_list.each do |dir_name|
      if dir_name.match(/#{values['name']}/)
        remove_js_client(values['name'], values['repodir'], temp_name)
        return
      end
    end
  end
  values['ip'] = get_install_ip(values)
  remove_hosts_entry(values)
  nil
end

# Add install client

def add_install_client(values)
  tool_dir = "#{values['repodir']}/Solaris_*/Tools"
  message  = "Information:\tAdding jumpstart client #{values['name']}"
  command  = "cd #{tool_dir} ; ./add_install_client -e #{values['mac']} -i #{values['ip']} -s #{values['hostip']}:#{values['repodir']} -c #{values['hostip']}:#{values['clientdir']} -p #{values['hostip']}:#{values['clientdir']} #{values['name']} #{values['karch']}"
  execute_command(values, message, command)
  nil
end

# Configure client

def configure_js_client(values)
  unless values['arch'].to_s.match(/i386|sparc/)
    if values['file']
      values['arch'] = if values['file'].to_s.match(/i386/)
                         'i386'
                       else
                         'sparc'
                       end
    end
    if values['service']
      values['arch'] = if values['service'].to_s.match(/i386/)
                         'i386'
                       else
                         'sparc'
                       end
    end
  end
  if values['file'].to_s.match(/flar/)
    if !File.exist?(values['image'])
      warning_message(values, "Flar file #{values['file']} does not exist")
      quit(values)
    else
      message = "Information:\tMaking sure file is world readable"
      command = "chmod 755 #{values['file']}"
      execute_command(values, message, command)
    end
    export_dir = Pathname.new(values['file'])
    export_dir = export_dir.dirname.to_s
    add_apache_alias(values, export_dir)
    unless values['service'].to_s.match(/[a-z,A-Z]/)
      values['service'] = Pathname.new(values['file'])
      values['service'] = values['service'].basename.to_s.gsub(/\.flar/, '')
    end
  else
    values['service'] = "#{values['service']}_#{values['arch']}" unless values['service'].to_s.match(/i386|sparc/)
    unless values['service'].to_s.match(/#{values['arch']}/)
      information_message(values, "Service #{values['service']} and Client architecture #{values['arch']} do not match")
      quit(values)
    end
    values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
    unless File.directory?(values['repodir'])
      warning_message(values, "Service #{values['service']} does not exist")
      verbose_message(values, '')
      list_js_services(values)
      quit(values)
    end
  end
  # Create clients directory
  clients_dir = "#{values['clientdir']}/#{values['service']}"
  check_dir_exists(values, clients_dir)
  # Create client directory
  values['clientdir'] = "#{clients_dir}/#{values['name']}"
  check_dir_exists(values, values['clientdir'])
  # Get release information
  values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
  check_osx_iso_mount(values) if values['host-os-uname'].to_s.match(/Darwin/)
  values['version'] = get_js_iso_version(values)
  values['update']  = get_js_iso_update(values)
  values['ip'] = single_install_ip(values)
  # Populate sysid questions and process them
  values = populate_js_sysid_questions(values)
  process_questions(values)
  values['karch'] = if values['arch'].to_s.match(/i386/)
                      values['arch']
                    else
                      values['answers']['system_karch'].value
                    end
  # Create sysid file
  values['sysid'] = "#{values['clientdir']}/sysidcfg"
  create_js_sysid_file(values)
  # Populate machine questions
  values = populate_js_machine_questions(values)
  process_questions(values)
  values['machine'] = "#{values['clientdir']}/machine.#{values['name']}"
  create_js_machine_file(values)
  # Create rules file
  values['rules'] = "#{values['clientdir']}/rules"
  create_js_rules_file(values)
  configure_js_pxe_client(values)
  configure_js_dhcp_client(values)
  check_js_config(values)
  add_hosts_entry(values)
  add_to_ethers_file(values)
  # export_name = "#{values['name']}_config"
  # add_nfs_export(values, export_name, values['clientrootdir'])
  add_install_client(values)
  check_tftp_server(values)
  nil
end
