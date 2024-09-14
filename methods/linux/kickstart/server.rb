
# Server code for Kickstart

# Unconfigure Linux repo

def unconfigure_ks_repo(values)
  remove_apache_alias(values['service'])
  values['repodir'] = values['baserepodir']+"/"+values['service']
  if File.symlink?(values['repodir'])
    values['netbootdir'] = values['tftpdir']+"/"+values['service']
    destroy_zfs_fs(values['netbootdir'])
    File.delete(values['repodir'])
  else
    destroy_zfs_fs(values['repodir'])
  end
  return
end

# Set ZFS mount point for filesystem

def set_zfs_mount(values)
  zfs_name = values['zpoolname']+values['repodir']
  message  = "Information:\tSetting "+zfs_name+" mount point to "+values['repodir']
  command  = "zfs set mountpoint=#{values['netbootdir']} #{zfs_name}"
  execute_command(values, message, command)
  return
end

# Copy Linux ISO contents to repo

def configure_ks_repo(values)
  values['netbootdir'] = values['tftpdir']+"/"+values['service']
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['host-os-version'].to_i < 11
      check_fs_exists(values, values['repodir'])
      if not File.symlink?(values['netbootdir'])
        File.symlink(values['repodir'], values['netbootdir'])
      end
    else
      check_fs_exists(values, values['repodir'])
      set_zfs_mount(values['repodir'], values['netbootdir'])
      if not File.symlink?(values['repodir'])
        Dir.delete(values['repodir'])
        File.symlink(values['netbootdir'], values['repodir'])
      end
    end
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    check_fs_exists(values, values['netbootdir'])
    if not File.symlink?(values['repodir'])
      check_dir_owner(values, values['baserepodir'], values['uid'])
      File.symlink(values['netbootdir'], values['repodir'])
    end
  end
  if values['repodir'].to_s.match(/sles/)
    check_dir = values['repodir']+"/boot"
  else
    check_dir = values['repodir']+"/isolinux"
  end
  if values['verbose'] == true
    verbose_output(values, "Information:\tChecking directory #{check_dir} exits")
  end
  if not File.directory?(check_dir)
    mount_iso(values)
    copy_iso(values)
    umount_iso(values)
    if values['file'].to_s.match(/DVD1\.iso|1of2\.iso/)
      if values['file'].to_s.match(/DVD1/)
        values['file'] = values['file'].gsub(/1\.iso/, "2.iso")
      end
      if values['file'].to_s.match(/1of2/)
        values['file'] = values['file'].gsub(/1of2\.iso/, "2of2.iso")
      end
      mount_iso(values)
      copy_iso(values)
      umount_iso(values)
    end
  end
  if values['service'].to_s.match(/live/)
    orig_file = values['file'].to_s
    iso_file  = File.basename(orig_file)
    file_name = values['repodir'].to_s+"/"+iso_file
    if not File.exist?(file_name)
      message = "Information:\tCopying ISO file "+orig_file+" to "+file_name
      command = "cp #{orig_file} #{file_name}"
      execute_command(values, message, command)
    end
   end
  return
end

# Unconfigure Kickstart server

def unconfigure_ks_server(values)
  unconfigure_ks_repo(values['service'])
end

# Configure PXE boot

def configure_ks_pxe_boot(values)
  iso_arch = values['arch']
  values['pxebootdir'] = values['tftpdir']+"/"+values['service']
  if values['service'].to_s.match(/centos|rhel|fedora|sles|sl_|oel/)
    test_dir = values['pxebootdir']+"/usr"
    if not File.directory?(test_dir)
      if values['service'].to_s.match(/centos/)
        rpm_dir = values['baserepodir']+"/"+values['service']+"/CentOS"
        if not File.directory?(rpm_dir)
          rpm_dir = values['baserepodir']+"/"+values['service']+"/Packages"
        end
      end
      if values['service'].to_s.match(/sles/)
        rpm_dir = values['baserepodir']+"/"+values['service']+"/suse"
      end
      if values['service'].to_s.match(/sl_/)
        rpm_dir = values['baserepodir']+"/"+values['service']+"/Scientific"
        if not File.directory?(rpm_dir)
          rpm_dir = values['baserepodir']+"/"+values['service']+"/Packages"
        end
      end
      if values['service'].to_s.match(/oel|rhel|fedora/)
        if values['service'].to_s.match(/rhel_5/)
          rpm_dir = values['baserepodir']+"/"+values['service']+"/Server"
        else
          if values['service'].to_s.match(/rhel_[8,9]/)
            rpm_dir = values['baserepodir']+"/"+values['service']+"/BaseOS/Packages"
          else
            rpm_dir = values['baserepodir']+"/"+values['service']+"/Packages"
          end
        end
      end
      if File.directory?(rpm_dir)
        if not values['service'].to_s.match(/sl_|fedora_19|rhel_6/)
          message  = "Information:\tLocating syslinux package"
          command  = "cd #{rpm_dir} ; find . -name 'syslinux-[0-9]*' |grep '#{iso_arch}'"
          output   = execute_command(values, message, command)
          rpm_file = output.chomp
          rpm_file = rpm_file.gsub(/\.\//, "")
          rpm_file = rpm_dir+"/"+rpm_file
          check_dir_exists(values, values['pxebootdir'])
        else
          rpm_dir  = values['workdir']+"/rpm"
          if not File.directory?(rpm_dir)
            check_dir_exists(values, rpm_dir)
          end
          rpm_url  = "http://vault.centos.org/5.11/os/i386/CentOS/syslinux-4.02-7.2.el5.i386.rpm"
          rpm_file = rpm_dir+"/syslinux-4.02-7.2.el5.i386.rpm"
          if not File.exist?(rpm_file)
            wget_file(values, rpm_url, rpm_file)
          end
        end
        check_dir_exists(values, values['pxebootdir'])
        message = "Information:\tCopying PXE boot files from "+rpm_file+" to "+values['pxebootdir']
        command = "cd #{values['pxebootdir']} ; #{values['rpm2cpiobin'] } #{rpm_file} | cpio -iud"
        output  = execute_command(values, message, command)
        if values['host-os-unamea'].match(/RedHat/) and values['host-os-unamer'].match(/^7/) and values['pxebootdir'].to_s.match(/[a-z]/)
          httpd_p = "httpd_sys_rw_content_t"
          tftpd_p = "unconfined_u:object_r:system_conf_t:s0"
          message = "Information:\tFixing permissions on "+values['pxebootdir']
          command = "chcon -R -t #{httpd_p} #{values['pxebootdir']} ; chcon #{tftpd_p} #{values['pxebootdir']}"
          execute_command(values, message, command)
          message = "Information:\tFixing permissions on "+values['pxebootdir']+"/usr and "+values['pxebootdir']+"/images"
          command = "chcon -R #{values['pxebootdir']}/usr ; chcon -R #{values['pxebootdir']}/images"
          execute_command(values, message, command)
        end
      else
        verbose_output(values, "Warning:\tSource directory #{rpm_dir} does not exist")
        quit(values)
      end
    end
    if values['service'].to_s.match(/sles/)
      pxe_image_dir=values['pxebootdir']+"/boot"
    else
      pxe_image_dir=values['pxebootdir']+"/images"
    end
    if not File.directory?(pxe_image_dir)
      if values['service'].to_s.match(/sles/)
        iso_image_dir = values['baserepodir']+"/"+values['service']+"/boot"
      else
        iso_image_dir = values['baserepodir']+"/"+values['service']+"/images"
      end
      message = "Information:\tCopying PXE boot images from "+iso_image_dir+" to "+pxe_image_dir
      command = "cp -r #{iso_image_dir} #{values['pxebootdir']}"
      output  = execute_command(values, message, command)
    end
  else
    check_dir_exists(values, values['pxebootdir'])
    pxe_image_dir = values['pxebootdir']+"/images"
    check_dir_exists(values, pxe_image_dir)
    pxe_image_dir = values['pxebootdir']+"/images/pxeboot"
    check_dir_exists(values, pxe_image_dir)
    test_file = pxe_image_dir+"/vmlinuz"
    if not values['method'].to_s.match(/ci/)
      if values['service'].to_s.match(/ubuntu/)
        iso_image_dir = values['baserepodir']+"/"+values['service']+"/install"
      else
        iso_image_dir = values['baserepodir']+"/"+values['service']+"/isolinux"
      end
    end
    if not File.exist?(test_file)
      message = "Information:\tCopying PXE boot files from "+iso_image_dir+" to "+pxe_image_dir
      command = "cd #{pxe_image_dir} ; cp -r #{iso_image_dir}/* . "
      output  = execute_command(values, message, command)
    end
  end
  pxe_cfg_dir = values['tftpdir']+"/pxelinux.cfg"
  check_dir_exists(values, pxe_cfg_dir)
  return
end

# Unconfigure PXE boot

def unconfigure_ks_pxe_boot(values)
  return
end

# Configure Kickstart server

def configure_ks_server(values)
  if values['service'].to_s.match(/[a-z,A-Z]/)
    if values['service'].downcase.match(/centos/)
      search_string = "CentOS"
    end
    if values['service'].downcase.match(/redhat/)
      search_string = "rhel"
    end
    if values['service'].downcase.match(/scientific|sl_/)
      search_string = "sl"
    end
    if values['service'].downcase.match(/oel/)
      search_string = "OracleLinux"
    end
  else
    search_string = "CentOS|rhel|SL|OracleLinux|Fedora"
  end
  configure_linux_server(values, search_string)
  return
end

# Configure local VMware repo

def configure_ks_vmware_repo(values)
  vmware_dir   = $pkg_base_dir+"/vmware"
  add_apache_alias(values, vmware_dir)
  repodata_dir = vmware_dir+"/repodata"
  vmware_url   = "http://packages.vmware.com/tools/esx/latest"
  if values['service'].to_s.match(/centos_5|rhel_5|sl_5|oel_5|fedora_18/)
    vmware_url   = vmware_url+"/rhel5/"+values['arch']+"/"
    repodata_url = vmware_url+"repodata/"
  end
  if values['service'].to_s.match(/centos_6|rhel_[6,7]|sl_6|oel_6|fedora_[19,20]/)
    vmware_url   = vmware_url+"/rhel6/"+values['arch']+"/"
    repodata_url = vmware_url+"repodata/"
  end
  if values['download'] == true
    if not File.directory?(vmware_dir)
      check_dir_exists(values, vmware_dir)
      message = "Information:\tFetching VMware RPMs"
      command = "cd #{vmware_dir} ; lftp -e 'mget * ; quit' #{vmware_url}"
      execute_command(values, message, command)
      check_dir_exists(values, repodata_dir)
      message = "Information:\tFetching VMware RPM repodata"
      command = "cd #{repodata_dir} ; lftp -e 'mget * ; quit' #{repodata_url}"
      execute_command(values, message, command)
    end
  end
  return
end

# Configue Linux server

def configure_linux_server(values, search_string)
  iso_list = []
  check_fs_exists(values, values['clientdir'])
  check_dhcpd_config(values)
  if values['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(values['file'])
      if not values['file'].to_s.match(/CentOS|rhel|Fedora|SL|OracleLinux|ubuntu/)
        verbose_output(values, "Warning:\tISO #{values['file']} does not appear to be a valid Linux distribution")
        quit(values)
      else
        iso_list[0] = values['file']
      end
    else
      verbose_output(values, "Warning:\tISO file #{values['file']} does not exist")
    end
  else
    values['search'] = "CentOS|rhel|Fedora|SL|OracleLinux|ubuntu"
    iso_list = get_base_dir_list(values)
  end
  if iso_list[0]
    iso_list.each do |file_name|
      file_name = file_name.chomp
      (linux_distro, iso_version, iso_arch) = get_linux_version_info(file_name)
      iso_version  = iso_version.gsub(/\./, "_")
      if file_name.match(/live/)
        values['service'] = linux_distro+"_"+iso_version+"_live_"+iso_arch
      else
        values['service'] = linux_distro+"_"+iso_version+"_"+iso_arch
      end
      values['repodir'] = values['baserepodir']+"/"+values['service']
      if !file_name.match(/DVD[1,2]\.iso|2of2\.iso|dvd\.iso$/)
        add_apache_alias(values, values['service'])
        configure_ks_repo(values)
        configure_ks_pxe_boot(values)
        if values['service'].to_s.match(/centos|fedora|rhel|sl_|oel/)
          values['arch'] = iso_arch
          configure_ks_vmware_repo(values)
        end
      else
        mount_iso(values)
        copy_iso(values)
        umount_iso(values)
      end
    end
  else
    if values['service'].to_s.match(/[a-z,A-Z]/)
      if not values['arch'].to_s.match(/[a-z,A-Z]/)
        iso_info = values['service'].split(/_/)
        values['arch'] = iso_info[-1]
      end
      add_apache_alias(values, values['service'])
      configure_ks_pxe_boot(values)
      if values['service'].to_s.match(/centos|fedora|rhel|sl_|oel/)
        configure_ks_vmware_repo(values)
      end
    else
      verbose_output(values, "Warning:\tISO file and/or Service name not found")
      quit(values)
    end
  end
  return
end

# List kickstart services

def list_ks_services(values)
  values['method'] = "ks"
  dir_list = get_dir_item_list(values)
  message  = "Kickstart Services"
  verbose_output(values, message)
  dir_list.each do |service|
    verbose_output(values, service)
  end
  verbose_output(values, "")
  return
end
