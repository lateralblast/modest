
# Server code for Kickstart

# Unconfigure Linux repo

def unconfigure_ks_repo(options)
  remove_apache_alias(options['service'])
  options['repodir'] = options['baserepodir']+"/"+options['service']
  if File.symlink?(options['repodir'])
    options['netbootdir'] = options['tftpdir']+"/"+options['service']
    destroy_zfs_fs(options['netbootdir'])
    File.delete(options['repodir'])
  else
    destroy_zfs_fs(options['repodir'])
  end
  return
end

# Set ZFS mount point for filesystem

def set_zfs_mount(options)
  zfs_name = options['zpoolname']+options['repodir']
  message  = "Information:\tSetting "+zfs_name+" mount point to "+options['repodir']
  command  = "zfs set mountpoint=#{options['netbootdir']} #{zfs_name}"
  execute_command(options,message,command)
  return
end

# Copy Linux ISO contents to repo

def configure_ks_repo(options)
  options['netbootdir'] = options['tftpdir']+"/"+options['service']
  if options['host-os-name'].to_s.match(/SunOS/)
    if options['host-os-version'].to_i < 11
      check_fs_exists(options,options['repodir'])
      if not File.symlink?(options['netbootdir'])
        File.symlink(options['repodir'],options['netbootdir'])
      end
    else
      check_fs_exists(options,options['repodir'])
      set_zfs_mount(options['repodir'],options['netbootdir'])
      if not File.symlink?(options['repodir'])
        Dir.delete(options['repodir'])
        File.symlink(options['netbootdir'],options['repodir'])
      end
    end
  end
  if options['host-os-name'].to_s.match(/Linux/)
    check_fs_exists(options,options['netbootdir'])
    if not File.symlink?(options['repodir'])
      check_dir_owner(options,options['baserepodir'],options['uid'])
      File.symlink(options['netbootdir'],options['repodir'])
    end
  end
  if options['repodir'].to_s.match(/sles/)
    check_dir = options['repodir']+"/boot"
  else
    check_dir = options['repodir']+"/isolinux"
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking directory #{check_dir} exits")
  end
  if not File.directory?(check_dir)
    mount_iso(options)
    copy_iso(options)
    umount_iso(options)
    if options['file'].to_s.match(/DVD1\.iso|1of2\.iso/)
      if options['file'].to_s.match(/DVD1/)
        options['file'] = options['file'].gsub(/1\.iso/,"2.iso")
      end
      if options['file'].to_s.match(/1of2/)
        options['file'] = options['file'].gsub(/1of2\.iso/,"2of2.iso")
      end
      mount_iso(options)
      copy_iso(options)
      umount_iso(options)
    end
  end
  return
end

# Unconfigure Kickstart server

def unconfigure_ks_server(options)
  unconfigure_ks_repo(options['service'])
end

# Configure PXE boot

def configure_ks_pxe_boot(options)
  iso_arch = options['arch']
  options['pxebootdir'] = options['tftpdir']+"/"+options['service']
  if options['service'].to_s.match(/centos|rhel|fedora|sles|sl_|oel/)
    test_dir = options['pxebootdir']+"/usr"
    if not File.directory?(test_dir)
      if options['service'].to_s.match(/centos/)
        rpm_dir = options['baserepodir']+"/"+options['service']+"/CentOS"
        if not File.directory?(rpm_dir)
          rpm_dir = options['baserepodir']+"/"+options['service']+"/Packages"
        end
      end
      if options['service'].to_s.match(/sles/)
        rpm_dir = options['baserepodir']+"/"+options['service']+"/suse"
      end
      if options['service'].to_s.match(/sl_/)
        rpm_dir = options['baserepodir']+"/"+options['service']+"/Scientific"
        if not File.directory?(rpm_dir)
          rpm_dir = options['baserepodir']+"/"+options['service']+"/Packages"
        end
      end
      if options['service'].to_s.match(/oel|rhel|fedora/)
        if options['service'].to_s.match(/rhel_5/)
          rpm_dir = options['baserepodir']+"/"+options['service']+"/Server"
        else
          if options['service'].to_s.match(/rhel_8/)
            rpm_dir = options['baserepodir']+"/"+options['service']+"/BaseOS/Packages"
          else
            rpm_dir = options['baserepodir']+"/"+options['service']+"/Packages"
          end
        end
      end
      if File.directory?(rpm_dir)
        if not options['service'].to_s.match(/sl_|fedora_19|rhel_6/)
          message  = "Information:\tLocating syslinux package"
          command  = "cd #{rpm_dir} ; find . -name 'syslinux-[0-9]*' |grep '#{iso_arch}'"
          output   = execute_command(options,message,command)
          rpm_file = output.chomp
          rpm_file = rpm_file.gsub(/\.\//,"")
          rpm_file = rpm_dir+"/"+rpm_file
          check_dir_exists(options,options['pxebootdir'])
        else
          rpm_dir  = options['workdir']+"/rpm"
          if not File.directory?(rpm_dir)
            check_dir_exists(options,rpm_dir)
          end
          rpm_url  = "http://vault.centos.org/5.11/os/i386/CentOS/syslinux-4.02-7.2.el5.i386.rpm"
          rpm_file = rpm_dir+"/syslinux-4.02-7.2.el5.i386.rpm"
          if not File.exist?(rpm_file)
            wget_file(options,rpm_url,rpm_file)
          end
        end
        check_dir_exists(options,options['pxebootdir'])
        message = "Information:\tCopying PXE boot files from "+rpm_file+" to "+options['pxebootdir']
        command = "cd #{options['pxebootdir']} ; #{options['rpm2cpiobin'] } #{rpm_file} | cpio -iud"
        output  = execute_command(options,message,command)
        if options['host-os-uname'].match(/RedHat/) and options['host-os-release'].match(/^7/) and options['pxebootdir'].to_s.match(/[a-z]/)
          httpd_p = "httpd_sys_rw_content_t"
          tftpd_p = "unconfined_u:object_r:system_conf_t:s0"
          message = "Information:\tFixing permissions on "+options['pxebootdir']
          command = "chcon -R -t #{httpd_p} #{options['pxebootdir']} ; chcon #{tftpd_p} #{options['pxebootdir']}"
          execute_command(options,message,command)
          message = "Information:\tFixing permissions on "+options['pxebootdir']+"/usr and "+options['pxebootdir']+"/images"
          command = "chcon -R #{options['pxebootdir']}/usr ; chcon -R #{options['pxebootdir']}/images"
          execute_command(options,message,command)
        end
      else
        handle_output(options,"Warning:\tSource directory #{rpm_dir} does not exist")
        quit(options)
      end
    end
    if options['service'].to_s.match(/sles/)
      pxe_image_dir=options['pxebootdir']+"/boot"
    else
      pxe_image_dir=options['pxebootdir']+"/images"
    end
    if not File.directory?(pxe_image_dir)
      if options['service'].to_s.match(/sles/)
        iso_image_dir = options['baserepodir']+"/"+options['service']+"/boot"
      else
        iso_image_dir = options['baserepodir']+"/"+options['service']+"/images"
      end
      message       = "Information:\tCopying PXE boot images from "+iso_image_dir+" to "+pxe_image_dir
      command       = "cp -r #{iso_image_dir} #{options['pxebootdir']}"
      output        = execute_command(options,message,command)
    end
  else
    check_dir_exists(options,options['pxebootdir'])
    pxe_image_dir = options['pxebootdir']+"/images"
    check_dir_exists(options,pxe_image_dir)
    pxe_image_dir = options['pxebootdir']+"/images/pxeboot"
    check_dir_exists(options,pxe_image_dir)
    test_file = pxe_image_dir+"/vmlinuz"
    if options['service'].to_s.match(/ubuntu/)
      iso_image_dir = options['baserepodir']+"/"+options['service']+"/install"
    else
      iso_image_dir = options['baserepodir']+"/"+options['service']+"/isolinux"
    end
    if not File.exist?(test_file)
      message = "Information:\tCopying PXE boot files from "+iso_image_dir+" to "+pxe_image_dir
      command = "cd #{pxe_image_dir} ; cp -r #{iso_image_dir}/* . "
      output  = execute_command(options,message,command)
    end
  end
  pxe_cfg_dir = options['tftpdir']+"/pxelinux.cfg"
  check_dir_exists(options,pxe_cfg_dir)
  return
end

# Unconfigure PXE boot

def unconfigure_ks_pxe_boot(options)
  return
end

# Configure Kickstart server

def configure_ks_server(options)
  if options['service'].to_s.match(/[a-z,A-Z]/)
    if options['service'].downcase.match(/centos/)
      search_string = "CentOS"
    end
    if options['service'].downcase.match(/redhat/)
      search_string = "rhel"
    end
    if options['service'].downcase.match(/scientific|sl_/)
      search_string = "sl"
    end
    if options['service'].downcase.match(/oel/)
      search_string = "OracleLinux"
    end
  else
    search_string = "CentOS|rhel|SL|OracleLinux|Fedora"
  end
  configure_linux_server(options,search_string)
  return
end

# Configure local VMware repo

def configure_ks_vmware_repo(options)
  vmware_dir   = $pkg_base_dir+"/vmware"
  add_apache_alias(options,vmware_dir)
  repodata_dir = vmware_dir+"/repodata"
  vmware_url   = "http://packages.vmware.com/tools/esx/latest"
  if options['service'].to_s.match(/centos_5|rhel_5|sl_5|oel_5|fedora_18/)
    vmware_url   = vmware_url+"/rhel5/"+options['arch']+"/"
    repodata_url = vmware_url+"repodata/"
  end
  if options['service'].to_s.match(/centos_6|rhel_[6,7]|sl_6|oel_6|fedora_[19,20]/)
    vmware_url   = vmware_url+"/rhel6/"+options['arch']+"/"
    repodata_url = vmware_url+"repodata/"
  end
  if options['download'] == true
    if not File.directory?(vmware_dir)
      check_dir_exists(options,vmware_dir)
      message = "Information:\tFetching VMware RPMs"
      command = "cd #{vmware_dir} ; lftp -e 'mget * ; quit' #{vmware_url}"
      execute_command(options,message,command)
      check_dir_exists(options,repodata_dir)
      message = "Information:\tFetching VMware RPM repodata"
      command = "cd #{repodata_dir} ; lftp -e 'mget * ; quit' #{repodata_url}"
      execute_command(options,message,command)
    end
  end
  return
end

# Configue Linux server

def configure_linux_server(options,search_string)
  iso_list = []
  check_fs_exists(options,options['clientdir'])
  check_dhcpd_config(options)
  if options['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(options['file'])
      if not options['file'].to_s.match(/CentOS|rhel|Fedora|SL|OracleLinux|ubuntu/)
        handle_output(options,"Warning:\tISO #{options['file']} does not appear to be a valid Linux distribution")
        quit(options)
      else
        iso_list[0] = options['file']
      end
    else
      handle_output(options,"Warning:\tISO file #{options['file']} does not exist")
    end
  else
    iso_list = check_iso_base_dir(search_string)
  end
  if iso_list[0]
    iso_list.each do |file_name|
      file_name = file_name.chomp
      (linux_distro,iso_version,iso_arch) = get_linux_version_info(file_name)
      iso_version  = iso_version.gsub(/\./,"_")
      options['service'] = linux_distro+"_"+iso_version+"_"+iso_arch
      options['repodir']  = options['baserepodir']+"/"+options['service']
      if !file_name.match(/DVD[1,2]\.iso|2of2\.iso|dvd\.iso$/)
        add_apache_alias(options,options['service'])
        configure_ks_repo(options)
        configure_ks_pxe_boot(options)
        if options['service'].to_s.match(/centos|fedora|rhel|sl_|oel/)
          options['arch'] = iso_arch
          configure_ks_vmware_repo(options)
        end
      else
        mount_iso(options)
        copy_iso(options)
        umount_iso(options)
      end
    end
  else
    if options['service'].to_s.match(/[a-z,A-Z]/)
      if not options['arch'].to_s.match(/[a-z,A-Z]/)
        iso_info = options['service'].split(/_/)
        options['arch'] = iso_info[-1]
      end
      add_apache_alias(options,options['service'])
      configure_ks_pxe_boot(options)
      if options['service'].to_s.match(/centos|fedora|rhel|sl_|oel/)
        configure_ks_vmware_repo(options)
      end
    else
      handle_output(options,"Warning:\tISO file and/or Service name not found")
      quit(options)
    end
  end
  return
end

# List kickstart services

def list_ks_services(options)
  message = "Kickstart Services"
  command = "ls #{options['baserepodir']}/ |egrep 'centos|fedora|rhel|sl_|oel'"
  output  = execute_command(options,message,command)
  handle_output(options,message)
  handle_output(options,output)
  return
end
