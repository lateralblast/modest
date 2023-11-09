
# Jumpstart server code

# Configure NFS service

def configure_js_nfs_service(options)
  export_name = "client_configs"
  options['repodir'] = options['baserepodir']+"/"+options['service']
  if options['host-os-name'].to_s.match(/SunOS/) && options['host-os-release'].match(/11/)
      check_fs_exists(options, options['clientdir'])
      add_nfs_export(options, export_name, options['repodir'])
  else
    check_dir_exists(options, options)
    add_nfs_export(options, export_name, options['repodir'])
  end
  return
end

# Unconfigure NFS services

def unconfigure_js_nfs_service(options)
  options['repodir'] = options['baserepodir']+"/"+options['service']
  remove_nfs_export(options['repodir'])
  return
end

# Configure tftpboot services

def configure_js_tftp_service(options)
  boot_dir   = options['tftpdir']+"/"+options['service']+"/boot"
  source_dir = options['repodir']+"/boot"
  if options['host-os-name'].to_s.match(/SunOS/)
    if options['host-os-release'].match(/11/)
      pkg_name = "system/boot/network"
      message  = "Information:\tChecking boot server package is installed"
      command  = "pkg info #{pkg_name} |grep Name |awk \"{print \\\$2}\""
      output   = execute_command(options, message, command)
      if not output.match(/#{pkg_name}/)
        message = "Information:\tInstalling boot server package"
        command = "pkg install #{pkg_name}"
        output  = execute_command(options, message, command)
      end
      old_tftp_dir="/tftpboot"
      if not File.symlink?(options['tftpdir'])
        message = "Information:\tSymlinking directory "+old_tftp_dir+" to "+options['tftpdir']
        command = "ln -s #{old_tftp_dir} #{options['tftpdir']}"
        output  = execute_command(options, message, command)
      end
      smf_install_service="svc:/network/tftp/udp6:default"
      message = "Information:\tChecking TFTP service is installed"
      command = "svcs -a |grep '#{smf_install_service}'"
      output  = execute_command(options, message, command)
      if not output.match(/#{smf_install_service}/)
        message = "Information:\tCreating TFTP service information"
        command = "echo 'tftp  dgram  udp6  wait  root  /usr/sbin/in.tftpd  in.tftpd -s /tftpboot' >> /tmp/tftp"
        output  = execute_command(options, message, command)
        message = "Information:\tCreating TFTP service manifest"
        command = "inetconv -i /tmp/tftp"
        output  = execute_command(options, message, command)
      end
      enable_smf_service(options, smf_install_service)
    end
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    check_osx_tftpd()
  end
  if options['host-os-name'].to_s.match(/Linux/)
  end
  if not File.directory?(boot_dir)
    check_dir_exists(options, boot_dir)
    message = "Information:\tCopying boot files from "+source_dir+" to "+boot_dir
    command = "cp -r #{source_dir}/* #{boot_dir}"
    output  = execute_command(options, message, command)
  end
  return
end

# Unconfigure jumpstart tftpboot services

def unconfigure_js_tftp_service()
  return
end

# Copy SPARC boot images to /tftpboot

def copy_js_sparc_boot_images(options)
  boot_list=[]
  options['tftpdir']="/tftpboot"
  boot_list.push("sun4u")
  if options['version'] == "10"
    boot_list.push("sun4v")
  end
  boot_list.each do |boot_arch|
    boot_file = options['repodir']+"/Solaris_"+options['version']+"/Tools/Boot/platform/"+boot_arch+"/inetboot"
    tftp_file = options['tftpdir']+"/"+boot_arch+".inetboot.sol_"+options['version']+"_"+options['update']
    if not File.exist?(boot_file)
      message = "Information:\tCopying boot image "+boot_file+" to "+tftp_file
      command = "cp #{boot_file} #{tftp_file}"
      execute_command(options, message, command)
    end
  end
  return
end

# Unconfigure jumpstart repo

def unconfigure_js_repo(options)
  options['repodir'] = options['baserepodir']+"/"+options['service']
  destroy_zfs_fs(options['repodir'])
  return
end

# Configure Jumpstart repo

def configure_js_repo(options)
  if options['host-os-name'].to_s.match(/SunOS|Linux/)
    check_fs_exists(options, options['repodir'])
  else
    check_dir_exists(options, options['repodir'])
  end
  check_dir = options['repodir']+"/boot"
  if options['verbose'] == true
    handle_output(options, "Checking:\tDirectory #{check_dir} exists")
  end
  if not File.directory?(check_dir)
    if options['host-os-name'].to_s.match(/SunOS/)
      mount_iso(options)
      if options['file'].to_s.match(/sol\-10/)
        check_dir = options['mountdir']+"/boot"
      else
        check_dir = options['mountdir']+"/installer"
      end
      if options['verbose'] == true
        handle_output(options, "Checking:\tDirectory #{check_dir} exists")
      end
      if File.directory?(check_dir) or File.exist?(check_dir)
        iso_update = get_js_iso_update(options)
        if not iso_update.match(/#{options['update']}/)
          handle_output(options, "Warning:\tISO update version does not match ISO name")
          quit(options)
        end
        message = "Information:\tCopying ISO file "+options['file']+" contents to "+options['repodir']
        if options['host-os-name'].to_s.match(/SunOS/)
          if options['file'].to_s.match(/sol\-10/)
            command = "cd /cdrom/Solaris_#{options['version']}/Tools ; ./setup_install_server #{options['repodir']}"
          else
            ufs_file = options['file'].gsub(/\-ga\-/, "-s0-")
            if not File.exist?(ufs_file)
              dd_message = "Extracting VTOC from #{options['file']}" 
              dd_command = "dd if=#{options['file']} of=/tmp/vtoc bs=512 count=1"
              execute_command(options, dd_message, dd_command)
              dd_message = "Processing VTOC information for #{options['file']}"
              dd_command = "od -D -j 452 -N 8 < /tmp/vtoc |head -1"
              output     = execute_command(options, dd_message, dd_command)
              (header, start_block, no_blocks) = output.split(/\s+/)
              start_block = start_block.gsub(/^0/, "")
              start_block = start_block.to_i*640
              start_block = start_block.to_s
              no_blocks   = no_blocks(/^0/, "")
              dd_message  = "Extracting UFS partition from #{options['file']} to #{ufs_file}"
              dd_command  = "dd if=#{iso_info} of=#{ufs_file} bs=512 skip=#{start_block} count=#{no_blocks}"
              execute_command(dd_message, dd_command)
            end
            command = "(cd /cdrom ; tar -cpf - . ) | (cd #{options['repodir']} ; tar -xpf - )"
          end
        else
          command = "(cd /cdrom ; tar -cpf - . ) | (cd #{options['repodir']} ; tar -xpf - )"
        end
        execute_command(options, message, command)
      else
        handle_output(options, "Warning:\tISO #{options['file']} is not mounted")
        return
      end
      umount_iso(options)
      if not options['file'].to_s.match(/sol\-10/)
        check_dir = options['repodir']+"/boot"
        if not File.directory?(check_dir)
          message = "Mounting UFS partition from #{ufs_file}"
          command = "mount -F ufs -o ro #{ufs_file} /cdrom"
          execute_command(options, message, command)
          message = "Copying ISO file #{ufs_file} contents to #{options['repodir']}"
          command = "(cd /cdrom ; tar -cpf - . ) | (cd #{options['repodir']} ; tar -xpf - )"
          execute_command(options, message, command)
          message = "Unmounting #{ufs_file} from /cdrom"
          command = "umount /cdrom"
          execute_command(options, message, command)
        end
      end
    else
      if not File.directory?(check_dir)
        check_osx_iso_mount(options['repodir'], options)
      end
    end
  end
  return
end

# Fix rm_install_client script

def fix_js_rm_client(options)
  file_name   = "rm_install_client"
  rm_script   = options['repodir']+"/Solaris_"+options['version']+"/Tools/"+file_name
  backup_file = rm_script+".modest"
  check_file_owner(options, rm_script, options['uid'])
  if not File.exist?(backup_file)
    message = "Information:\tArchiving remove install script "+rm_script+" to "+backup_file
    command = "cp #{rm_script} #{backup_file}"
    execute_command(options, message, command)
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

def list_js_services(options)
  options['method'] = "js"
  dir_list = get_dir_item_list(options)
  message  = "Jumpstart Services:"
  handle_output(options, message)
  dir_list.each do |service|
    handle_output(options, service)
  end
  handle_output(options, "")
  return
end

# Fix check script

def fix_js_check(options)
  file_name    = "check"
  check_script = options['repodir']+"/Solaris_"+options['version']+"/Misc/jumpstart_sample/"+file_name
  backup_file  = check_script+".modest"
  if not File.exist?(backup_file)
    message = "Information:\tArchiving check script "+check_script+" to "+backup_file
    command = "cp #{check_script} #{backup_file}"
    execute_command(options, message, command)
    text     = File.read(check_script)
    copy     = text
    copy[0]  = "#!/usr/sbin/sh\n"
    tmp_file = "/tmp/check_script"
    File.open(tmp_file, "w") {|file| file.puts copy}
    message  = "Information:\tUpdating check script"
    command  = "cp #{tmp_file} #{check_script} ; chmod +x #{check_script} ; rm #{tmp_file}"
    execute_command(options, message, command)
  end
  return
end

# Unconfigure jumpstart server

def unconfigure_js_server(options)
  unconfigure_js_nfs_service(options)
  unconfigure_js_repo(options)
  unconfigure_js_tftp_service()
  return
end

# Configure jumpstart server

def configure_js_server(options)
  check_dhcpd_config(options)
  iso_list = []
  options['search'] = "\\-ga\\-|_ga_"
  if options['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(options['file'])
      if not options['file'].to_s.match(/sol/)
        handle_output(options, "Warning:\tISO #{options['file']} does not appear to be a valid Solaris distribution")
        quit(options)
      else
        iso_list[0] = options['file']
      end
    else
      handle_output(options, "Warning:\tISO file #{options['file']} does not exist")
    end
  else
    iso_list = get_base_dir_list(options)
  end
  if options['file'].class == String
    iso_list[0] = options['file']
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
        handle_output(options, "Warning:\tCould not determine architecture from ISO name")
        quit(options)
      end
    end
    service_base_name  = "sol_"+iso_version+"_"+iso_update+"_"+iso_arch
    options['service'] = service_base_name
    options['repodir'] = options['baserepodir'].to_s+"/"+options['service'].to_s
    options['file']    = file_name
    options['version'] = iso_version
    options['update']  = iso_update
    options['arch']    = iso_arch
    add_apache_alias(options, service_base_name)
    configure_js_repo(options)
    configure_js_tftp_service(options)
    configure_js_nfs_service(options)
    if iso_arch.match(/sparc/)
      copy_js_sparc_boot_images(options)
    end
    if !options['host-os-name'].to_s.match(/Darwin/)
      fix_js_rm_client(options)
      fix_js_check(options)
    else
      tune_osx_nfs()
    end
  end
  return
end
