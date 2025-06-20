# frozen_string_literal: true

# Kickstart client routines

# List ks clients

def list_ks_clients(values)
  list_clients(values)
  nil
end

# Configure client PXE boot

def configure_ks_pxe_client(values)
  values['ip'] = single_install_ip(values)
  tftp_pxe_file = values['mac'].gsub(/:/, '')
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01#{tftp_pxe_file}.pxelinux"
  test_file     = "#{values['tftpdir']}/#{tftp_pxe_file}"
  tmp_file      = '/tmp/pxecfg'
  if File.symlink?(test_file)
    message = "Information:\tRemoving old PXE boot file #{test_file}"
    command = "rm #{test_file}"
    execute_command(values, message, command)
  end
  pxelinux_file = 'pxelinux.0'
  message = "Information:\tCreating PXE boot file for #{values['name']} with MAC address #{values['mac']}"
  command = "cd #{values['tftpdir']} ; ln -s #{pxelinux_file} #{tftp_pxe_file}"
  execute_command(values, message, command)
  if values['service'].to_s.match(/live/)
    iso_dir  = "#{values['tftpdir']}/#{values['service']}"
    message  = "Information:\tDetermining install ISO location"
    command  = "ls #{iso_dir}/*.iso"
    iso_file = execute_command(values, message, command)
    iso_file = iso_file.chomp
    install_iso = File.basename(iso_file)
  end
  if values['biostype'].to_s.match(/efi/)
    shim_efi_file = '/usr/lib/shim/shimx64.efi'
    install_package(values, 'shim') unless File.exist?(shim_efi_file)
    shim_grub_file = "#{values['tftpdir']}/shimx64.efi"
    net_efi_file   = '/usr/lib/grub/x86_64-efi/monolithic/grubnetx64.efi'
    install_package(values, 'grub-efi-amd64-bin') unless File.exist?(net_efi_file)
    net_grub_file = "#{values['tftpdir']}/grubx64.efi"
    check_dir_exists(values, values['tftpdir'])
    check_dir_owner(values, values['tftpdir'], values['uid'])
    install_package(values, 'shim-signed') unless File.exist?(shim_efi_file)
    install_package(values, 'grub-efi-amd64-signed') unless File.exist?(net_efi_file)
    unless File.exist?(shim_grub_file)
      message = "Information:\tCopying #{shim_efi_file} to #{shim_grub_file}"
      command = "cp #{shim_efi_file} #{shim_grub_file}"
      execute_command(values, message, command)
      check_file_owner(values, shim_grub_file, values['uid'])
    end
    unless File.exist?(net_grub_file)
      message = "Information:\tCopying #{net_efi_file} to #{net_grub_file}"
      command = "cp #{net_efi_file} #{net_grub_file}"
      execute_command(values, message, command)
      check_file_owner(values, net_grub_file, values['uid'])
    end
    tmp_cfg_octs = values['ip'].split('.')
    pxe_cfg_octs = []
    tmp_cfg_octs.each do |octet|
      hextet = octet.convert_base(10, 16)
      hextet = "0#{hextet}" if hextet.length < 2
      pxe_cfg_octs.push(hextet.upcase)
    end
    pxe_cfg_txt  = pxe_cfg_octs.join
    pxe_cfg_file = "grub.cfg-#{pxe_cfg_txt}"
    pxe_cfg_dir  = "#{values['tftpdir']}/grub"
    check_dir_exists(values, pxe_cfg_dir)
    check_dir_owner(values, pxe_cfg_dir, values['uid'])
  else
    pxe_cfg_dir  = "#{values['tftpdir']}/pxelinux.cfg"
    pxe_cfg_file = values['mac'].gsub(/:/, '-')
    pxe_cfg_file = "01-#{pxe_cfg_file}"
    pxe_cfg_file = pxe_cfg_file.downcase
  end
  pxe_cfg_file = "#{pxe_cfg_dir}/#{pxe_cfg_file}"
  vmlinuz_file = if values['service'].to_s.match(/sles/)
                   "/#{values['service']}/boot/#{values['arch']}/loader/linux"
                 elsif values['service'].to_s.match(/live/)
                   "/#{values['service']}/casper/vmlinuz"
                 else
                   "/#{values['service']}/images/pxeboot/vmlinuz"
                 end
  if values['service'].to_s.match(/ubuntu/)
    if values['service'].to_s.match(/live/)
      initrd_file = "/#{values['service']}/casper/initrd"
    elsif values['service'].to_s.match(/x86_64/)
      initrd_file = "/#{values['service']}/images/pxeboot/netboot/ubuntu-installer/amd64/initrd.gz"
      linux_file = "/#{values['service']}/images/pxeboot/netboot/ubuntu-installer/amd64/linux"
    else
      initrd_file = "/#{values['service']}/images/pxeboot/netboot/ubuntu-installer/i386/initrd.gz"
    end
    ldlinux_link = "#{values['tftpdir']}/ldlinux.c32"
    if !File.exist?(ldlinux_link) && !File.symlink?(ldlinux_link)
      ldlinux_file = "#{values['service']}/images/pxeboot/netboot/ldlinux.c32"
      message = "Information:\tCreating symlink for ldlinux.c32"
      command = "ln -s #{ldlinux_file} #{ldlinux_link}"
      execute_command(values, message, command)
    end
  else
    initrd_file = if values['service'].to_s.match(/sles/)
                    "/#{values['service']}/boot/#{values['arch']}/loader/initrd"
                  else
                    "/#{values['service']}/images/pxeboot/initrd.img"
                  end
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    vmlinuz_file = vmlinuz_file.gsub(%r{^/}, '')
    initrd_file  = initrd_file.gsub(%r{^/}, '')
  end
  host_info = if values['service'].to_s.match(/packer/)
                "#{values['vmgateway']}:#{values['httpport']}"
              else
                values['hostip']
              end
  # ks_url       = "http://"+host_info+"/clients/"+values['service']+"/"+values['name']+"/"+values['name']+".cfg"
  # autoyast_url = "http://"+host_info+"/clients/"+values['service']+"/"+values['name']+"/"+values['name']+".xml"
  base_url = "http://#{values['hostip']}/#{values['name']}"
  iso_url = "http://#{values['hostip']}/#{values['service']}/#{install_iso}" if values['service'].to_s.match(/live/)
  ks_url       = "http://#{values['hostip']}/#{values['name']}/#{values['name']}.cfg"
  autoyast_url = "http://#{values['hostip']}/#{values['name']}/#{values['name']}.xml"
  install_url  = "http://#{host_info}/#{values['service']}"
  file         = File.open(tmp_file, 'w')
  if values['biostype'].to_s.match(/efi/)
    menuentry = "menuentry \"#{values['name']}\" {\n"
    file.write(menuentry)
  else
    if values['serial'] == true
      file.write("serial 0 115200\n")
      file.write("prompt 0\n")
    end
    file.write("DEFAULT LINUX\n")
    file.write("LABEL LINUX\n")
    file.write("  KERNEL #{vmlinuz_file}\n")
    file.write("  INITRD #{initrd_file}\n") if values['service'].to_s.match(/live/)
  end
  if values['service'].to_s.match(/ubuntu/)
    values['ip'] = values['answers']['ip'].value
    install_domain       = values['answers']['domain'].value
    install_nic          = values['answers']['nic'].value
    values['vmgateway'] = values['answers']['gateway'].value
    values['netmask']   = values['answers']['netmask'].value
    values['vmnetwork'] = values['answers']['network_address'].value
    disable_dhcp = values['answers']['disable_dhcp'].value
    if disable_dhcp.match(/true/)
      if values['biostype'].to_s.match(/efi/)
        if values['service'].to_s.match(/live/)
          linux_file    = "/#{values['service']}/casper/vmlinuz"
          initrd_file   = "/#{values['service']}/casper/initrd"
          append_string = if values['biosdevnames'] == true
                            "  linux #{linux_file} net.ifnames=0 biosdevname=0 root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=#{iso_url} autoinstall ds=nocloud-net;s=#{base_url}/"
                          else
                            "  linux #{linux_file} root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=#{iso_url} autoinstall ds=nocloud-net;s=#{base_url}/"
                          end
        elsif values['biosdevnames'] == true
          append_string = "  linux #{linux_file} --- auto=true priority=critical preseed/url=#{ks_url} console-keymaps-at/keymap=us locale=en_US hostname=#{values['name']} domain=#{install_domain} interface=#{install_nic} grub-installer/bootdev=#{values['rootdisk']} netcfg/get_ipaddress=#{values['ip']} netcfg/get_netmask=#{values['netmask']} netcfg/get_gateway=#{values['vmgateway']} netcfg/get_nameservers=#{values['nameserver']} netcfg/disable_dhcp=true initrd=#{initrd_file} net.ifnames=0 biosdevname=0"
        else
          append_string = "  linux #{linux_file} --- auto=true priority=critical preseed/url=#{ks_url} console-keymaps-at/keymap=us locale=en_US hostname=#{values['name']} domain=#{install_domain} interface=#{install_nic} grub-installer/bootdev=#{values['rootdisk']} netcfg/get_ipaddress=#{values['ip']} netcfg/get_netmask=#{values['netmask']} netcfg/get_gateway=#{values['vmgateway']} netcfg/get_nameservers=#{values['nameserver']} netcfg/disable_dhcp=true initrd=#{initrd_file}"
        end
        initrd_string = "  initrd #{initrd_file}"
      elsif values['service'].to_s.match(/live/)
        append_string = if values['biosdevnames'] == true
                          "  APPEND root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=#{iso_url} autoinstall ds=nocloud-net;s=#{base_url}/ net.ifnames=0 biosdevname=0"
                        else
                          "  APPEND root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=#{iso_url} autoinstall ds=nocloud-net;s=#{base_url}/"
                        end
      elsif values['biosdevnames'] == true
        append_string = "  APPEND auto=true priority=critical preseed/url=#{ks_url} console-keymaps-at/keymap=us locale=en_US hostname=#{values['name']} domain=#{install_domain} interface=#{install_nic} grub-installer/bootdev=#{values['rootdisk']} netcfg/get_ipaddress=#{values['ip']} netcfg/get_netmask=#{values['netmask']} netcfg/get_gateway=#{values['vmgateway']} netcfg/get_nameservers=#{values['nameserver']} netcfg/disable_dhcp=true initrd=#{initrd_file} net.ifnames=0 biosdevname=0"
      else
        append_string = "  APPEND auto=true priority=critical preseed/url=#{ks_url} console-keymaps-at/keymap=us locale=en_US hostname=#{values['name']} domain=#{install_domain} interface=#{install_nic} grub-installer/bootdev=#{values['rootdisk']} netcfg/get_ipaddress=#{values['ip']} netcfg/get_netmask=#{values['netmask']} netcfg/get_gateway=#{values['vmgateway']} netcfg/get_nameservers=#{values['nameserver']} netcfg/disable_dhcp=true initrd=#{initrd_file}"
      end
    else
      append_string = '  APPEND '
    end
  elsif values['service'].to_s.match(/sles/)
    append_string = if values['biosdevnames'] == true
                      "  APPEND initrd=#{initrd_file} install=#{install_url} autoyast=#{autoyast_url} language=#{values['language']} net.ifnames=0 biosdevname=0"
                    else
                      "  APPEND initrd=#{initrd_file} install=#{install_url} autoyast=#{autoyast_url} language=#{values['language']}"
                    end
  elsif values['service'].to_s.match(/fedora_2[0-3]/)
    append_string = if values['biosdevnames'] == true
                      "  APPEND initrd=#{initrd_file} ks=#{ks_url} ip=#{values['ip']} netmask=#{values['netmask']} net.ifnames=0 biosdevname=0"
                    else
                      "  APPEND initrd=#{initrd_file} ks=#{ks_url} ip=#{values['ip']} netmask=#{values['netmask']}"
                    end
  elsif values['service'].to_s.match(/live/)
    append_string = if values['biosdevnames'] == true
                      "  APPEND net.ifnames=0 biosdevname=0 root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=#{iso_url}"
                    else
                      "  APPEND root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=#{iso_url}"
                    end
  elsif values['biosdevnames'] == true
    append_string = "  APPEND initrd=#{initrd_file} ks=#{ks_url} ksdevice=bootif ip=#{values['ip']} netmask=#{values['netmask']} net.ifnames=0 biosdevname=0"
  else
    append_string = "  APPEND initrd=#{initrd_file} ks=#{ks_url} ksdevice=bootif ip=#{values['ip']} netmask=#{values['netmask']}"
  end
  if values['text'] == true
    append_string = if values['service'].to_s.match(/sles/)
                      "#{append_string} textmode=1"
                    else
                      "#{append_string} text"
                    end
  end
  append_string += ' serial console=ttyS0' if values['serial'] == true
  append_string += "\n"
  file.write(append_string)
  if values['biostype'].to_s.match(/efi/)
    initrd_string += "\n"
    file.write(initrd_string)
    file.write("}\n")
  end
  file.flush
  file.close
  if values['biostype'].to_s.match(/efi/)
    grub_file = "#{pxe_cfg_dir}/grub.cfg"
    File.delete(grub_file) if File.exist?(grub_file)
    FileUtils.touch(grub_file)
    grub_file = File.open(grub_file, 'w')
    file_list = Dir.entries(pxe_cfg_dir)
    file_list.each do |file_name|
      next unless file_name.match(/cfg-/) && !file_name.match(/#{values['name']}/)

      temp_file  = "#{pxe_cfg_dir}/#{file_name}"
      temp_array = File.readlines(temp_file)
      temp_array.each do |temp_line|
        grub_file.write(temp_line)
      end
    end
    menuentry = "menuentry \"#{values['name']}\" {\n"
    grub_file.write(menuentry)
    grub_file.write(append_string)
    grub_file.write(initrd_string)
    grub_file.write("}\n")
    grub_file.flush
    grub_file.close
    grub_file = "#{pxe_cfg_dir}/grub.cfg"
    FileUtils.touch(grub_file)
    print_contents_of_file(values, '', grub_file)
  end
  message = "Information:\tCreating PXE configuration file #{pxe_cfg_file}"
  command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  print_contents_of_file(values, '', pxe_cfg_file)
  nil
end

# Unconfigure client PXE boot

def unconfigure_ks_pxe_client(values)
  values['mac'] = get_install_mac(values)
  unless values['mac']
    warning_message(values, "No MAC Address entry found for #{values['name']}")
    quit(values)
  end
  if values['biostype'].to_s.match(/efi/)
    tmp_cfg_octs = values['ip'].split('.')
    pxe_cfg_octs = []
    tmp_cfg_octs.each do |octet|
      hextet = octet.convert_base(10, 16)
      hextet = "0#{hextet}" if hextet.length < 2
      pxe_cfg_octs.push(hextet.upcase)
    end
    pxe_cfg_txt  = pxe_cfg_octs.join
    pxe_cfg_file = "grub.cfg-#{pxe_cfg_txt}"
    pxe_cfg_dir  = "#{values['tftpdir']}/grub"
    check_dir_exists(values, pxe_cfg_dir)
    check_dir_owner(values, pxe_cfg_dir, values['uid'])
    pxe_cfg_file  = "#{pxe_cfg_dir}/#{pxe_cfg_file}"
    pxe_cfg_file  = "#{pxe_cfg_dir}/#{pxe_cfg_file}"
    tftp_pxe_file = pxe_cfg_file
  else
    tftp_pxe_file = values['mac'].gsub(/:/, '')
    tftp_pxe_file = tftp_pxe_file.upcase
    tftp_pxe_file = "01#{tftp_pxe_file}.pxelinux"
    tftp_pxe_file = "#{values['tftpdir']}/#{tftp_pxe_file}"
  end
  if File.exist?(tftp_pxe_file)
    check_file_owner(values, ttftp_pxe_file, values['uid'])
    message = "Information:\tRemoving PXE boot file #{tftp_pxe_file} for #{values['name']}"
    command = "rm #{tftp_pxe_file}"
    execute_command(values, message, command)
  end
  pxe_cfg_dir  = "#{values['tftpdir']}/pxelinux.cfg"
  pxe_cfg_file = values['mac'].gsub(/:/, '-')
  pxe_cfg_file = "01-#{pxe_cfg_file}"
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = "#{pxe_cfg_dir}/#{pxe_cfg_file}"
  if File.exist?(pxe_cfg_file)
    message = "Information:\tRemoving PXE boot config file #{pxe_cfg_file} for #{values['name']}"
    command = "rm #{pxe_cfg_file}"
    execute_command(values, message, command)
    if values['biostype'].to_s.match(/efi/)
      grub_file = "#{pxe_cfg_dir}/grub.cfg"
      grub_file = File.open(grub_file, 'w')
      file_list = Dir.entries(pxe_cfg_dir)
      file_list.each do |file_name|
        next unless file_name.match(/cfg-/)

        temp_file  = "#{pxe_cfg_dir}/#{file_name}"
        temp_array = File.readlines(temp_file)
        temp_array.each do |temp_line|
          grub_file.write(temp_line)
        end
      end
      grub_file.close
    end
  end
  unconfigure_ks_dhcp_client(values)
  nil
end

# Configure DHCP entry

def configure_ks_dhcp_client(values)
  add_dhcp_client(values)
  nil
end

# Unconfigure DHCP client

def unconfigure_ks_dhcp_client(values)
  remove_dhcp_client(values)
  nil
end

# Configure Kickstart client

def configure_ks_client(values)
  values['ip'] = single_install_ip(values) unless values['service'].to_s.match(/purity/)
  unless values['arch'].to_s.match(/[a-z]/)
    values['arch'] = if values['service'].to_s.match(/i386/)
                       'i386'
                     else
                       'x86_64'
                     end
  end
  if !values['vm'].to_s.match(/mp|multipass/)
    configure_ks_pxe_boot(values)
    values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
    add_apache_alias(values, values['clientdir'])
    values['clientdir'] = "#{values['clientdir']}/#{values['service']}/#{values['name']}"
    check_fs_exists(values, values['clientdir'])
    unless File.directory?(values['repodir'])
      warning_message(values, "Service #{values['service']} does not exist")
      verbose_message(values, '')
      list_ks_services(values)
      quit(values)
    end
  else
    values = get_multipass_service_from_release(values)
    values['clientdir'] = "#{values['clientdir']}/#{values['service']}/#{values['name']}"
  end
  check_dir_exists(values, values['clientdir'])
  check_dir_owner(values, values['clientdir'], values['uid'])
  if values['service'].to_s.match(/sles/)
    output_file = "#{values['clientdir']}/#{values['name']}.xml"
  elsif values['service'].to_s.match(/live/) || values['vm'].to_s.match(/mp|multipass/)
    output_file = "#{values['clientdir']}/user-data"
    meta_file   = "#{values['clientdir']}/meta-data"
  else
    output_file = "#{values['clientdir']}/#{values['name']}.cfg"
  end
  delete_file(values, output_file)
  if values['service'].to_s.match(/fedora|rhel|centos|sl_|oel|rocky|alma/)
    input_file = values['kickstartfile'].to_s
    if input_file.match(/[a-z]/) && File.exist(input_file)
      message = "Information:\tCopying #{input_file} to #{output_file}"
      command = "cp #{input_file} #{output_file}"
      execute_command(values, message, command)
    else
      values = populate_ks_questions(values)
      process_questions(values)
      output_ks_header(values, output_file)
      pkg_list = populate_ks_pkg_list(values['service'])
      output_ks_pkg_list(values, pkg_list, output_file)
      post_list = populate_ks_post_list(values)
      output_ks_post_list(values, post_list, output_file)
    end
  elsif values['service'].to_s.match(/sles/)
    input_file = values['autoyastfile'].to_s
    if input_file.match(/[a-z]/) && File.exist(input_file)
      message = "Information:\tCopying #{input_file} to #{output_file}"
      command = "cp #{input_file} #{output_file}"
      execute_command(values, message, command)
    else
      values = populate_ks_questions(values)
      process_questions(values)
      output_ay_client_profile(values, output_file)
    end
  elsif values['service'].to_s.match(/live/) || values['vm'].to_s.match(/mp|multipass/)
    values['cloudinitfile'].to_s
    values = populate_ps_questions(values)
    values = process_questions(values)
    (user_data, early_exec_data, late_exec_data) = populate_cc_user_data(values)
    output_cc_user_data(values, user_data, early_exec_data, late_exec_data, output_file)
    FileUtils.touch(meta_file)
  elsif values['service'].to_s.match(/ubuntu|debian|purity/)
    values = populate_ps_questions(values)
    process_questions(values)
    unless values['service'].to_s.match(/purity/)
      output_ps_header(values, output_file)
      output_file = "#{values['clientdir']}/#{values['name']}_post.sh"
      post_list   = populate_ps_post_list(values)
      output_ks_post_list(values, post_list, output_file)
      output_file = "#{values['clientdir']}/#{values['name']}_first_boot.sh"
      post_list   = populate_ps_first_boot_list(values)
      output_ks_post_list(values, post_list, output_file)
    end
  end
  if !values['service'].to_s.match(/purity/) && !values['vm'].to_s.match(/mp|multipass/)
    configure_ks_pxe_client(values)
    configure_ks_dhcp_client(values)
    add_apache_alias(values, values['clientdir'])
    add_hosts_entry(values)
  end
  values
end

# Unconfigure Kickstart client

def unconfigure_ks_client(values)
  unconfigure_ks_pxe_client(values)
  unconfigure_ks_dhcp_client(values)
  nil
end

# Populate post commands

def populate_ks_post_list(values)
  gateway_ip  = values['vmgateway']
  post_list   = []
  admin_group = values['answers']['admin_group'].value
  admin_user  = values['answers']['admin_username'].value
  admin_crypt = values['answers']['admin_crypt'].value
  admin_home  = values['answers']['admin_home'].value
  admin_uid   = values['answers']['admin_uid'].value
  admin_gid   = values['answers']['admin_gid'].value
  nic_name    = values['answers']['nic'].value
  epel_file   = '/etc/yum.repos.d/epel.repo'
  beta_file   = '/etc/yum.repos.d/public-yum-ol6-beta.repo'
  post_list.push('')
  post_list.push('# Fix ethernet names to be ethX style')
  post_list.push('')
  post_list.push("echo 'GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"' >>/etc/default/grub") if values['biosdevnames'] == true
  post_list.push('/usr/sbin/update-grub')
  post_list.push('')
  post_list.push('')
  post_list.push('# Fix timezone')
  post_list.push('')
  post_list.push('rm /etc/localtime')
  post_list.push("cd /etc ; ln -s ../usr/share/zoneinfo/#{values['timezone']} /etc/localtime")
  post_list.push('')
  post_list.push('# Add Admin user')
  post_list.push('')
  post_list.push("groupadd #{admin_group}")
  post_list.push("groupadd #{admin_user}")
  post_list.push('')
  post_list.push('# Add admin user')
  post_list.push('')
  post_list.push("useradd -p '#{admin_crypt}' -g #{admin_user} -G #{admin_group} -d #{admin_home} -m #{admin_user}")
  post_list.push('')
  post_list.push('# Setup sudoers')
  post_list.push('')
  post_list.push("echo \"#{admin_user} ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers")
  post_list.push('')
  resolv_conf = '/etc/resolv.conf'
  post_list.push("# Create #{resolv_conf}")
  post_list.push('')
  post_list.push("echo 'nameserver #{values['nameserver']}' >> #{resolv_conf}")
  post_list.push("echo 'search local' >> #{resolv_conf}")
  post_list.push('')
  post_list.push("route add default gw #{gateway_ip}")
  post_list.push("echo 'GATEWAY=#{gateway_ip}' > /etc/sysconfig/network")
  if values['service'].to_s.match(/rhel_[5,6]/)
    post_list.push("echo 'NETWORKING=yes' >> /etc/sysconfig/network")
    post_list.push("echo 'HOSTNAME=#{values['name']}' >> /etc/sysconfig/network")
    post_list.push('')
    post_list.push("echo 'default via #{gateway_ip} dev #{nic_name}' > /etc/sysconfig/network-scripts/route-eth0")
  end
  post_list.push('')
  if values['service'].to_s.match(/centos|fedora|sl_|el|alma|rocky/)
    epel_url = "http://#{values['epel']}/pub/epel/5/i386/epel-release-5-4.noarch.rpm" if values['service'].to_s.match(/centos_5|fedora_18|rhel_5|sl_5|oel_5/)
    epel_url = "http://#{values['epel']}/pub/epel/6/i386/epel-release-6-8.noarch.rpm" if values['service'].to_s.match(/centos_6|fedora_19|fedora_20|el_6|sl_6/)
    repo_file = '/etc/yum.repos.d/CentOS-Base.repo' if values['service'].to_s.match(/centos/)
    repo_file = '/etc/yum.repos.d/sl.repo' if values['service'].to_s.match(/sl_/)
    if values['service'].to_s.match(/centos|sl_/)
      post_list.push('# Change mirror for yum')
      post_list.push('')
      post_list.push("echo 'Changing default mirror for yum'")
      post_list.push("cp #{repo_file} #{repo_file}.orig")
    end
  end
  if values['service'].to_s.match(/centos/)
    post_list.push("sed -i 's/^mirror./#&/g' #{repo_file}")
    post_list.push("sed -i 's/^#\\(baseurl\\)/\\1/g' #{repo_file}")
    #    post_list.push("sed -i 's,#{$default_centos_mirror},#{$local_centos_mirror},g' #{repo_file}")
  end
  post_list.push("sed -i 's,#{$default_sl_mirror},#{$local_sl_mirror},g' #{repo_file}") if values['service'].to_s.match(/sl_/)
  if values['service'].to_s.match(/_[5,6,7]/)
    epel_url = "http://#{values['epel']}/pub/epel/5/#{values['arch']}/epel-release-5-4.noarch.rpm" if values['service'].to_s.match(/_5/)
    epel_url = "http://#{values['epel']}/pub/epel/6/#{values['arch']}/epel-release-6-8.noarch.rpm" if values['service'].to_s.match(/_6/)
    epel_url = "http://#{values['epel']}/pub/epel/beta/7/#{values['arch']}/epel-release-7-0.2.noarch.rpm" if values['service'].to_s.match(/_7/)
    post_list.push('')
    post_list.push('# Configure Epel repo')
    post_list.push('')
    post_list.push("rpm -i #{epel_url}")
    post_list.push("cp #{epel_file} #{epel_file}.orig")
    post_list.push("sed -i 's/^mirror./#&/g' #{epel_file}")
    post_list.push("sed -i 's/^#\\(baseurl\\)/\\1/g' #{epel_file}")
    post_list.push("sed -i 's/7/beta\\/7/g' #{epel_file}")
    #    post_list.push("sed -i 's,#{$default_epel_mirror},#{values['epel']},g' #{epel_file}")
    post_list.push('yum -y update')
    post_list.push('')
  end
  if values['type'].to_s.match(/packer/)
    post_list.push('')
    post_list.push("echo 'UseDNS no' >> /etc/ssh/sshd_config")
    post_list.push('systemctl disable firewalld')
    post_list.push('')
    unless values['vmnetwork'].to_s.match(/hostonly/)
      post_list.push("echo 'Port 22' >> /etc/ssh/sshd_config")
      post_list.push("echo 'Port 2222' >> /etc/ssh/sshd_config")
      post_list.push('')
    end
  end
  if values['enable'].to_s.match(/packstack/)
    post_list.push('')
    post_list.push('# Configure Packstack')
    post_list.push('')
    if values['service'].to_s.match(/[centos,el,rocky,alma]_[7,8,9]/)
      post_list.push('yum update -y')
      post_list.push('systemctl disable firewalld')
      post_list.push('systemctl stop firewalld')
      post_list.push('systemctl disable NetworkManager')
      post_list.push('systemctl enable network')
      post_list.push('systemctl start network')
      post_list.push('')
    end
    post_list.push('')
  end
  post_list.push('')
  unless values['service'].to_s.match(/fedora/)
    post_list.push('# Avahi daemon for mDNS')
    post_list.push('')
    post_list.push('chkconfig avahi-daemon on')
    post_list.push('service avahi-daemon start')
    post_list.push('')
  end
  unless values['type'].to_s.match(/packer/)
    post_list.push('# Install VM tools')
    post_list.push('')
    post_list.push("export OSREL=`lsb_release -r |awk '{print $2}' |cut -f1 -d'.'`")
    post_list.push('export OSARCH=`uname -p`')
    post_list.push('if [ "`dmidecode |grep VMware`" ]; then')
    post_list.push("  echo 'Installing VMware RPMs'")
    post_list.push("  echo -e \"[vmware-tools]\\nname = VMware Tools\\nbaseurl=http://#{values['publisherhost']}/vmware\\nenabled=1\\ngpgcheck=0\" >> /etc/yum.repos.d/vmware-tools.repo")
    post_list.push('  yum -y install vmware-tools-core')
    post_list.push('fi')
    post_list.push('')
  end
  post_list.push('# Enable serial console')
  post_list.push('')
  post_list.push("sed -i 's/9600/115200/' /etc/inittab")
  post_list.push("sed -i 's/kernel.*/& console=ttyS0,115200n8/' /etc/grub.conf")
  post_list.push('')
  if values['service'].to_s.match(/oel_6_5/)
    post_list.push('# OEL beta repo')
    post_list.push('')
    post_list.push("echo '[uek3_beta]' > #{beta_file}")
    post_list.push("echo 'name = Unbreakable Enterprise Kernel Release 3 for Oracle Linux 6 ($basearch)' >> #{beta_file}")
    post_list.push("echo 'baseurl=http://public-yum.oracle.com/beta/repo/OracleLinux/OL6/uek3/$basearch/' >> #{beta_file}")
    post_list.push("echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle' >> #{beta_file}")
    post_list.push("echo 'gpgcheck=1' >> #{beta_file}")
    post_list.push("echo 'enabled=1' >> #{beta_file}")
    post_list.push('')
    post_list.push('yum update')
    post_list.push('yum -y install dtrace-utils')
    post_list.push('yum -y install dtrace-modules')
    post_list.push('groupadd dtrace')
    post_list.push("usermod -a -G dtrace #{admin_user}")
    post_list.push("echo 'kernel==\"dtrace/dtrace\", GROUP=\"dtrace\" MODE=\"0660\"' > /etc/udev/rules.d/10-dtrace.rules")
    post_list.push("echo '/sbin/modprobe dtrace' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe profile' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe sdt' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe systrace' >> /etc/rc.modules")
    post_list.push("echo '/sbin/modprobe dt_test' >> /etc/rc.modules")
    post_list.push('chmod 755 /etc/rc.modules')
    post_list.push('')
  end
  if values['service'].to_s.match(/rhel_|centos_|rocky_|alma_/)
    post_list.push('# Add host entry')
    post_list.push('')
    # post_list.push("echo '#{values['ip']} #{values['name']}' >> /etc/hosts")
    post_list.push("echo 'HOSTNAME=#{values['name']}' >> /etc/sysconfig/network")
    post_list.push('')
  end
  if values['copykeys'] == true
    post_list.push('# Copy SSH keys')
    post_list.push('')
    ssh_key = "#{values['home']}/.ssh/id_rsa.pub"
    key_dir = "#{values['service']}/keys"
    check_dir_exists(values, key_dir)
    auth_file = "#{key_dir}/authorized_keys"
    message   = "Copying:\tSSH keys"
    command   = "cp #{ssh_key} #{auth_file}"
    execute_command(values, message, command)
    ssh_dir   = "#{admin_home}/.ssh"
    ssh_url   = "http://#{values['publisherhost']}/#{values['service']}/keys/authorized_keys"
    auth_file = "#{ssh_dir}/authorized_keys"
    post_list.push("mkdir #{ssh_dir}/.ssh")
    post_list.push("chown #{admin_uid}:#{admin_gid} #{ssh_dir}")
    post_list.push("cd #{ssh_dir} ; wget #{ssh_url} -O #{auth_file}")
    post_list.push("chown #{admin_uid}:#{admin_gid} #{auth_file}")
    post_list.push("chmod 644 #{auth_file}")
    post_list.push('')
  end
  if values['vm'].to_s.match(/vbox/)
    post_list.push('# Install VirtualBox Tools')
    post_list.push('')
    post_list.push('mkdir /mnt/cdrom')
    post_list.push('if [ "`dmidecode |grep VirtualBox`" ]; then')
    post_list.push("  echo 'Installing VirtualBox Guest Additions'")
    post_list.push('  mount /dev/cdrom /mnt/cdrom')
    post_list.push('  /mnt/cdrom/VBoxLinuxAdditions.run')
    post_list.push('  umount /mnt/cdrom')
    post_list.push('fi')
    post_list.push('')
  end
  if values['service'].to_s.match(/rhel|centos|rocky|alma/)
    post_list.push('# Enable serial console')
    post_list.push('')
    post_list.push('grubby --update-kernel=ALL --args="console=ttyS0"')
    post_list.push('')
  end
  if $altrepo_mode == true
    post_list.push('mkdir /tmp/rpms')
    post_list.push('cd /tmp/rpms')
    alt_url  = "http://#{values['hostip']}"
    rpm_list = build_ks_alt_rpm_list(values['service'])
    alt_dir  = "#{values['baserepodir']}/#{values['service']}/alt"
    verbose_message(values, "Checking:\tAdditional packages")
    if File.directory?(alt_dir)
      rpm_list.each do |rpm_url|
        rpm_file = File.basename(rpm_url)
        rpm_file = "#{alt_dir}/#{rpm_file}"
        rpm_url  = "#{alt_url}/#{rpm_file}"
        post_list.push("wget #{rpm_url}") if File.exist?(rpm_file)
      end
    end
    post_list.push('rpm -i *.rpm')
    post_list.push('cd /tmp')
    post_list.push('rm -rf /tmp/rpms')
  end
  post_list.push('')
  post_list
end

# Populat a list of additional packages to install

def populate_ks_pkg_list(values)
  pkg_list = []
  if values['service'].to_s.match(/centos|fedora|rhel|sl_|oel|rocky|alma/)
    pkg_list.push('@base') unless values['service'].to_s.match(/fedora/)
    pkg_list.push('@core')
    if values['service'].to_s.match(/[a-z]_6/)
      pkg_list.push('@console-internet')
      pkg_list.push('@system-admin-tools')
    end
    pkg_list.push('@network-file-system-client') unless values['service'].to_s.match(/sl_6|[a-z]_5|fedora/)
    if values['service'].to_s.match(/centos_[6,7]|fedora|sl_[6,7]/)
      unless values['service'].to_s.match(/fedora_2[3-9]|centos_6/)
        pkg_list.push('redhat-lsb-core')
        unless values['service'].to_s.match(/rhel_[6,7]|oel_[6,7]|centos_7/)
          pkg_list.push('augeas')
          pkg_list.push('tk')
        end
      end
      unless values['service'].to_s.match(/fedora|_[6,7,8,9]/)
        pkg_list.push('ruby')
        pkg_list.push('ruby-irb')
        pkg_list.push('rubygems')
        pkg_list.push('ruby-rdoc')
        pkg_list.push('ruby-devel')
      end
      unless values['service'].to_s.match(/centos_6/)
        pkg_list.push('augeas-libs')
        pkg_list.push('ruby-libs')
      end
    end
    unless values['service'].to_s.match(/fedora|[centos,el,rocky,alma]_[6,7,8,9]/)
      pkg_list.push('grub')
      pkg_list.push('libselinux-ruby')
    end
    pkg_list.push('iscsi-initiator-utils') if values['service'].to_s.match(/[centos,el,rocky,alma]_[7,8,9]/)
    unless values['service'].to_s.match(/centos_6/)
      pkg_list.push('e2fsprogs')
      pkg_list.push('lvm2')
    end
    unless values['service'].to_s.match(/fedora/)
      pkg_list.push('kernel-devel')
      unless values['service'].to_s.match(/centos_6/)
        pkg_list.push('automake')
        pkg_list.push('autoconf')
        pkg_list.push('lftp')
        pkg_list.push('avahi')
      end
    end
    pkg_list.push('kernel-headers')
    pkg_list.push('dos2unix')
    pkg_list.push('unix2dos')
    pkg_list.push('zlib-devel') unless values['service'].to_s.match(/fedora_2[4-9]|centos_6/)
    unless values['service'].to_s.match(/fedora/)
      unless values['service'].to_s.match(/centos_6/)
        pkg_list.push('libgpg-error-devel')
        pkg_list.push('libxml2-devel')
        pkg_list.push('libgcrypt-devel')
        pkg_list.push('xz-devel')
        pkg_list.push('libxslt-devel')
        pkg_list.push('libstdc++-devel')
      end
      unless values['service'].to_s.match(/rhel_5|fedora|centos_6/)
        pkg_list.push('perl-TermReadKey')
        pkg_list.push('git')
        pkg_list.push('perl-Git')
      end
      pkg_list.push('gcc')
      pkg_list.push('gcc-c++')
      pkg_list.push('dhcp') unless values['service'].to_s.match(/centos_|[el,rocky,alma]_[8,9]/)
      pkg_list.push('xinetd') unless values['service'].to_s.match(/[el,centos,rocky,alma]_9/)
      pkg_list.push('tftp-server')
    end
    pkg_list.push('libgnome-keyring') unless values['service'].to_s.match(/el_|centos_|rocky_|alma_/)
    pkg_list.push('perl-Error') unless values['service'].to_s.match(/rhel_5/)
    pkg_list.push('httpd')
    if values['service'].to_s.match(/fedora/)
      pkg_list.push('net-tools')
      pkg_list.push('bind-utils')
    end
    pkg_list.push('ntp') unless values['service'].to_s.match(/fedora|[centos,el,rocky,alma]_[8,9]/)
    pkg_list.push('rsync')
    pkg_list.push('-samba-client') if values['service'].to_s.match(/sl_6/)
  end
  pkg_list
end

# Output the Kickstart file header

def output_ks_header(values, output_file)
  tmp_file = "/tmp/ks_#{values['name']}"
  file = File.open(tmp_file, 'w')
  values['order'].each do |key|
    next unless values['answers'][key].type.match(/output/)

    output = if !values['answers'][key].parameter.match(/[a-z,A-Z]/)
               "#{values['answers'][key].value}\n"
             else
               "#{values['answers'][key].parameter} #{values['answers'][key].value}\n"
             end
    file.write(output)
  end
  file.close
  message = "Creating:\tKickstart file #{output_file}"
  command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  nil
end

# Output the ks packages list

def output_ks_pkg_list(values, pkg_list, output_file)
  tmp_file = "/tmp/ks_pkg_#{values['name']}"
  file     = File.open(tmp_file, 'w')
  output   = "\n%packages\n"
  file.write(output)
  pkg_list.each do |pkg_name|
    output = "#{pkg_name}\n"
    file.write(output)
  end
  if values['service'].to_s.match(/fedora_[19,20]|[centos,rhel,oel,sl,rocky,alma]_[7,8,9]/)
    output = "\n%end\n"
    file.write(output)
  end
  file.close
  message = "Updating:\tKickstart file #{output_file}"
  command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  nil
end

# Output the ks packages list

def output_ks_post_list(values, post_list, output_file)
  tmp_file = "/tmp/postinstall_#{values['name']}"
  if values['service'].to_s.match(/centos|fedora|rhel|sl_|oel|rocky|alma/)
    file = File.open(tmp_file, 'a')
    output = "\n%post\n"
    command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  else
    file = File.open(tmp_file, 'w')
    output  = "#!/bin/sh\n"
    command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  end
  file.write(output)
  post_list.each do |line|
    output = "#{line}\n"
    file.write(output)
  end
  if values['service'].to_s.match(/fedora_[19,20]|[centos,el,sl,rocky,alma]_[7,8,9]/)
    output = "\n%end\n"
    file.write(output)
  end
  file.close
  message = "Information:\tCreating post install script #{output_file}"
  #  command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  nil
end

# Check service values['service']

def check_ks_install_service(values)
  unless values['service'].to_s.match(/[a-z,A-Z]/)
    warning_message(values, 'Service name not given')
    quit(values)
  end
  client_list = Dir.entries(values['baserepodir'])
  unless client_list.grep(values['service'])
    warning_message(values, "Service name #{values['service']} does not exist")
    quit(values)
  end
  nil
end
