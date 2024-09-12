
# Jumpstart server code

# Configure NFS service

def configure_js_nfs_service(values)
  export_name = "client_configs"
  values['repodir'] = values['baserepodir']+"/"+values['service']
  if values['host-os-uname'].to_s.match(/SunOS/) && values['host-os-unamer'].match(/11/)
      check_fs_exists(values, values['clientdir'])
      add_nfs_export(values, export_name, values['repodir'])
  else
    check_dir_exists(values, values)
    add_nfs_export(values, export_name, values['repodir'])
  end
  return
end

# Unconfigure NFS services

def unconfigure_js_nfs_service(values)
  values['repodir'] = values['baserepodir']+"/"+values['service']
  remove_nfs_export(values['repodir'])
  return
end

# Configure tftpboot services

def configure_js_tftp_service(values)
  boot_dir   = values['tftpdir']+"/"+values['service']+"/boot"
  source_dir = values['repodir']+"/boot"
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['host-os-unamer'].match(/11/)
      pkg_name = "system/boot/network"
      message  = "Information:\tChecking boot server package is installed"
      command  = "pkg info #{pkg_name} |grep Name |awk \"{print \\\$2}\""
      output   = execute_command(values, message, command)
      if not output.match(/#{pkg_name}/)
        message = "Information:\tInstalling boot server package"
        command = "pkg install #{pkg_name}"
        output  = execute_command(values, message, command)
      end
      old_tftp_dir="/tftpboot"
      if not File.symlink?(values['tftpdir'])
        message = "Information:\tSymlinking directory "+old_tftp_dir+" to "+values['tftpdir']
        command = "ln -s #{old_tftp_dir} #{values['tftpdir']}"
        output  = execute_command(values, message, command)
      end
      smf_install_service="svc:/network/tftp/udp6:default"
      message = "Information:\tChecking TFTP service is installed"
      command = "svcs -a |grep '#{smf_install_service}'"
      output  = execute_command(values, message, command)
      if not output.match(/#{smf_install_service}/)
        message = "Information:\tCreating TFTP service information"
        command = "echo 'tftp  dgram  udp6  wait  root  /usr/sbin/in.tftpd  in.tftpd -s /tftpboot' >> /tmp/tftp"
        output  = execute_command(values, message, command)
        message = "Information:\tCreating TFTP service manifest"
        command = "inetconv -i /tmp/tftp"
        output  = execute_command(values, message, command)
      end
      enable_smf_service(values, smf_install_service)
    end
  end
  if values['host-os-uname'].to_s.match(/Darwin/)
    check_osx_tftpd()
  end
  if values['host-os-uname'].to_s.match(/Linux/)
  end
  if not File.directory?(boot_dir)
    check_dir_exists(values, boot_dir)
    message = "Information:\tCopying boot files from "+source_dir+" to "+boot_dir
    command = "cp -r #{source_dir}/* #{boot_dir}"
    output  = execute_command(values, message, command)
  end
  return
end

# Unconfigure jumpstart tftpboot services

def unconfigure_js_tftp_service()
  return
end

# Copy SPARC boot images to /tftpboot

def copy_js_sparc_boot_images(values)
  boot_list=[]
  values['tftpdir']="/tftpboot"
  boot_list.push("sun4u")
  if values['version'] == "10"
    boot_list.push("sun4v")
  end
  boot_list.each do |boot_arch|
    boot_file = values['repodir']+"/Solaris_"+values['version']+"/Tools/Boot/platform/"+boot_arch+"/inetboot"
    tftp_file = values['tftpdir']+"/"+boot_arch+".inetboot.sol_"+values['version']+"_"+values['update']
    if not File.exist?(boot_file)
      message = "Information:\tCopying boot image "+boot_file+" to "+tftp_file
      command = "cp #{boot_file} #{tftp_file}"
      execute_command(values, message, command)
    end
  end
  return
end

# Unconfigure jumpstart repo

def unconfigure_js_repo(values)
  values['repodir'] = values['baserepodir']+"/"+values['service']
  destroy_zfs_fs(values['repodir'])
  return
end

# Configure Jumpstart repo

def configure_js_repo(values)
  if values['host-os-uname'].to_s.match(/SunOS|Linux/)
    check_fs_exists(values, values['repodir'])
  else
    check_dir_exists(values, values['repodir'])
  end
  check_dir = values['repodir']+"/boot"
  if values['verbose'] == true
    verbose_output(values, "Checking:\tDirectory #{check_dir} exists")
  end
  if not File.directory?(check_dir)
    if values['host-os-uname'].to_s.match(/SunOS/)
      mount_iso(values)
      if values['file'].to_s.match(/sol\-10/)
        check_dir = values['mountdir']+"/boot"
      else
        check_dir = values['mountdir']+"/installer"
      end
      if values['verbose'] == true
        verbose_output(values, "Checking:\tDirectory #{check_dir} exists")
      end
      if File.directory?(check_dir) or File.exist?(check_dir)
        iso_update = get_js_iso_update(values)
        if not iso_update.match(/#{values['update']}/)
          verbose_output(values, "Warning:\tISO update version does not match ISO name")
          quit(values)
        end
        message = "Information:\tCopying ISO file "+values['file']+" contents to "+values['repodir']
        if values['host-os-uname'].to_s.match(/SunOS/)
          if values['file'].to_s.match(/sol\-10/)
            command = "cd /cdrom/Solaris_#{values['version']}/Tools ; ./setup_install_server #{values['repodir']}"
          else
            ufs_file = values['file'].gsub(/\-ga\-/, "-s0-")
            if not File.exist?(ufs_file)
              dd_message = "Extracting VTOC from #{values['file']}" 
              dd_command = "dd if=#{values['file']} of=/tmp/vtoc bs=512 count=1"
              execute_command(values, dd_message, dd_command)
              dd_message = "Processing VTOC information for #{values['file']}"
              dd_command = "od -D -j 452 -N 8 < /tmp/vtoc |head -1"
              output     = execute_command(values, dd_message, dd_command)
              (header, start_block, no_blocks) = output.split(/\s+/)
              start_block = start_block.gsub(/^0/, "")
              start_block = start_block.to_i*640
              start_block = start_block.to_s
              no_blocks   = no_blocks(/^0/, "")
              dd_message  = "Extracting UFS partition from #{values['file']} to #{ufs_file}"
              dd_command  = "dd if=#{iso_info} of=#{ufs_file} bs=512 skip=#{start_block} count=#{no_blocks}"
              execute_command(dd_message, dd_command)
            end
            command = "(cd /cdrom ; tar -cpf - . ) | (cd #{values['repodir']} ; tar -xpf - )"
          end
        else
          command = "(cd /cdrom ; tar -cpf - . ) | (cd #{values['repodir']} ; tar -xpf - )"
        end
        execute_command(values, message, command)
      else
        verbose_output(values, "Warning:\tISO #{values['file']} is not mounted")
        return
      end
      umount_iso(values)
      if not values['file'].to_s.match(/sol\-10/)
        check_dir = values['repodir']+"/boot"
        if not File.directory?(check_dir)
          message = "Mounting UFS partition from #{ufs_file}"
          command = "mount -F ufs -o ro #{ufs_file} /cdrom"
          execute_command(values, message, command)
          message = "Copying ISO file #{ufs_file} contents to #{values['repodir']}"
          command = "(cd /cdrom ; tar -cpf - . ) | (cd #{values['repodir']} ; tar -xpf - )"
          execute_command(values, message, command)
          message = "Unmounting #{ufs_file} from /cdrom"
          command = "umount /cdrom"
          execute_command(values, message, command)
        end
      end
    else
      if not File.directory?(check_dir)
        check_osx_iso_mount(values['repodir'], values)
      end
    end
  end
  return
end

# Fix rm_install_client script

def fix_js_rm_client(values)
  file_name   = "rm_install_client"
  rm_script   = values['repodir']+"/Solaris_"+values['version']+"/Tools/"+file_name
  backup_file = rm_script+".modest"
  check_file_owner(values, rm_script, values['uid'])
  if not File.exist?(backup_file)
    message = "Information:\tArchiving remove install script "+rm_script+" to "+backup_file
    command = "cp #{rm_script} #{backup_file}"
    execute_command(values, message, command)
    text = IO.readlines(rm_script)
    copy = []
    if text
      text.each do |line|
        if line.match(/ANS/) and line.match(/sed/) and not line.match(/\{/)
          line=line.gsub(/#/, ' #')
        end
        if line.match(/nslookup/) and not line.match(/sed/)
          line="ANS=`nslookup ${K} | /bin/sed '/^;;/d' 2>&1`"
        end
        copy.push(line)
      end
    end
    File.open(rm_script, "w") {|file| file.puts copy}
  end
  return
end

# List Jumpstart services

def list_js_services(values)
  values['method'] = "js"
  dir_list = get_dir_item_list(values)
  message  = "Jumpstart Services:"
  verbose_output(values, message)
  dir_list.each do |service|
    verbose_output(values, service)
  end
  verbose_output(values, "")
  return
end

# Fix check script

def fix_js_check(values)
  file_name    = "check"
  check_script = values['repodir']+"/Solaris_"+values['version']+"/Misc/jumpstart_sample/"+file_name
  backup_file  = check_script+".modest"
  if not File.exist?(backup_file)
    message = "Information:\tArchiving check script "+check_script+" to "+backup_file
    command = "cp #{check_script} #{backup_file}"
    execute_command(values, message, command)
    text     = File.read(check_script)
    copy     = text
    copy[0]  = "#!/usr/sbin/sh\n"
    tmp_file = "/tmp/check_script"
    File.open(tmp_file, "w") {|file| file.puts copy}
    message  = "Information:\tUpdating check script"
    command  = "cp #{tmp_file} #{check_script} ; chmod +x #{check_script} ; rm #{tmp_file}"
    execute_command(values, message, command)
  end
  return
end

# Unconfigure jumpstart server

def unconfigure_js_server(values)
  unconfigure_js_nfs_service(values)
  unconfigure_js_repo(values)
  unconfigure_js_tftp_service()
  return
end

# Configure jumpstart server

def configure_js_server(values)
  check_dhcpd_config(values)
  iso_list = []
  values['search'] = "\\-ga\\-|_ga_"
  if values['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(values['file'])
      if not values['file'].to_s.match(/sol/)
        verbose_output(values, "Warning:\tISO #{values['file']} does not appear to be a valid Solaris distribution")
        quit(values)
      else
        iso_list[0] = values['file']
      end
    else
      verbose_output(values, "Warning:\tISO file #{values['file']} does not exist")
    end
  else
    iso_list = get_base_dir_list(values)
  end
  if values['file'].class == String
    iso_list[0] = values['file']
  end
  iso_list.each do |file_name|
    file_name   = file_name.chomp
    iso_info    = File.basename(file_name)
    iso_info    = iso_info.split(/\-/)
    iso_version = iso_info[1]
    iso_update  = iso_info[2]
    iso_update  = iso_update.gsub(/u/, "")
    iso_arch    = iso_info[4]
    if not iso_arch.match(/sparc/)
      if iso_arch.match(/x86/)
        iso_arch = "i386"
      else
        verbose_output(values, "Warning:\tCould not determine architecture from ISO name")
        quit(values)
      end
    end
    service_base_name  = "sol_"+iso_version+"_"+iso_update+"_"+iso_arch
    values['service'] = service_base_name
    values['repodir'] = values['baserepodir'].to_s+"/"+values['service'].to_s
    values['file']    = file_name
    values['version'] = iso_version
    values['update']  = iso_update
    values['arch']    = iso_arch
    add_apache_alias(values, service_base_name)
    configure_js_repo(values)
    configure_js_tftp_service(values)
    configure_js_nfs_service(values)
    if iso_arch.match(/sparc/)
      copy_js_sparc_boot_images(values)
    end
    if !values['host-os-uname'].to_s.match(/Darwin/)
      fix_js_rm_client(values)
      fix_js_check(values)
    else
      tune_osx_nfs()
    end
  end
  return
end
