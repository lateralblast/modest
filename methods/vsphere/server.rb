
# Server code for VSphere

# Unconfigure alternate packages

def unconfigure_vs_alt_repo(values)
  return
end

# Configure alternate packages

def configure_vs_alt_repo(values)
  rpm_list = build_vs_alt_rpm_list(values)
  alt_dir  = values['baserepodir']+"/"+values['service']+"/alt"
  check_dir_exists(values, alt_dir)
  rpm_list.each do |rpm_url|
    rpm_file = File.basename(rpm_url)
    rpm_file = alt_dir+"/"+rpm_file
    if not File.exist?(rpm_file)
      wget_file(values, rpm_url, rpm_file)
    end
  end
  return
end

# Unconfigure Linux repo

def unconfigure_vs_repo(values)
  remove_apache_alias(values)
  values['repodir'] = values['baserepodir']+"/"+values['service']
  if values['host-os-uname'].to_s.match(/SunOS/)
    if File.symlink?(values['repodir'])
      message = "Information:\tRemoving symlink "+values['repodir']
      command = "rm #{values['repodir']}"
      execute_command(values, message, command)
    else
      destroy_zfs_fs(values['repodir'])
    end
    values['netbootdir'] = values['tftpdir']+"/"+values['service']
    if File.directory?(values['netbootdir'])
      message = "Information:\tRemoving directory "+values['netbootdir']
      command = "rmdir #{values['netbootdir']}"
      execute_command(values, message, command)
    end
  else
    if File.directory?(values['repodir'])
      message = "Information:\tRemoving directory "+values['repodir']
      command = "rm #{values['repodir']}"
      execute_command(values, message, command)
    end
  end
  return
end

# Copy Linux ISO contents to

def configure_vs_repo(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    check_fs_exists(values, values['repodir'])
    values['netbootdir'] = values['tftpdir']+"/"+values['service']
    if not File.symlink?(values['repodir'])
      if values['verbose'] == true
        handle_output(values, "Information:\tChecking vSphere net boot directory")
      end
      check_dir_owner(values, values['netbootdir'], values['uid'])
      File.symlink(values['repodir'], values['netbootdir'])
    end
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    values['netbootdir'] = values['tftpdir']+"/"+values['service']
    check_fs_exists(values, values['netbootdir'])
    if !File.exist?(values['repodir'])
      if values['verbose'] == true
        handle_output(values, "Information:\tChecking vSphere net boot directory")
      end
      check_dir_owner(values, values['netbootdir'], values['uid'])
      File.symlink(values['netbootdir'], values['repodir'])
    end
  end
  check_dir = values['repodir']+"/upgrade"
  if values['verbose'] == true
    handle_output(values, "Information:\tChecking directory #{check_dir} exists")
  end
  if not File.directory?(check_dir)
    mount_iso(values)
    values['repodir'] = values['tftpdir']+"/"+values['service']
    copy_iso(values)
    umount_iso(values)
  end
  values['clientdir'] = values['clientdir']+"/"+values['service']
  ovf_file = values['clientdir']+"/vmware-ovftools.tar.gz"
  if not File.exist?(ovf_file)
    wget_file(values, values['ovftarurl'], ovf_file)
    if values['host-os-unamea'].match(/RedHat/) and values['host-os-version'].match(/^7|^6\.7/)
      message = "Information:\tFixing permission on "+ovf_file
      command = "chcon -R -t httpd_sys_rw_content_t #{ovf_file}"
      execute_command(values, message, command)
    end
  end
  return
end

# Unconfigure VSphere server

def unconfigure_vs_server(values)
  unconfigure_vs_repo(values)
end

# Configure PXE boot

def configure_vs_pxe_boot(values)
  values['pxebootdir'] = values['tftpdir']+"/"+values['service']
  test_dir = values['pxebootdir']+"/usr"
  if not File.directory?(test_dir)
    rpm_dir = values['workdir']+"/rpms"
    check_dir_exists(values, rpm_dir)
    if File.directory?(rpm_dir)
      message  = "Information:\tLocating syslinux package"
      command  = "ls #{rpm_dir} |grep 'syslinux-[0-9]'"
      output   = execute_command(values, message, command)
      rpm_file = output.chomp
      if not rpm_file.match(/syslinux/)
        rpm_file = "syslinux-4.02-7.2.el5.i386.rpm"
        rpm_file = rpm_dir+"/"+rpm_file
        rpm_url  = "https://vault.centos.org/5.11/os/i386/CentOS/syslinux-4.02-7.2.el5.i386.rpm"
        wget_file(values, rpm_url, rpm_file)
      else
        rpm_file = rpm_dir+"/"+rpm_file
      end
      check_dir_exists(values, values['pxebootdir'])
      message = "Information:\tCopying PXE boot files from "+rpm_file+" to "+values['pxebootdir']
      command = "cd #{values['pxebootdir']} ; #{values['rpm2cpiobin'] } #{rpm_file} | cpio -iud"
      output  = execute_command(values, message, command)
    else
      handle_output(values, "Warning:\tSource directory #{rpm_dir} does not exist")
      quit(values)
    end
  end
  if not values['service'].to_s.match(/vmware/)
    pxe_image_dir=values['pxebootdir']+"/images"
    if not File.directory?(pxe_image_dir)
      iso_dir = values['baserepodir']+"/"+values['service']+"/images"
      message = "Information:\tCopying PXE boot images from "+iso_dir+" to "+pxe_image_dir
      command = "cp -r #{iso_dir} #{values['pxebootdir']}"
      output  = execute_command(values, message, command)
    end
  end
  pxe_cfg_dir = values['tftpdir']+"/pxelinux.cfg"
  check_dir_exists(values, pxe_cfg_dir)
  return
end

# Unconfigure PXE boot

def unconfigure_vs_pxe_boot(values)
  return
end

# Configure VSphere server

def configure_vs_server(values)
  iso_list = []
  values['search'] = "VMvisor"
  if values['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(values['file'])
      if not values['file'].to_s.match(/VM/)
        handle_output(values, "Warning:\tISO #{values['file']} does not appear to be VMware distribution")
        quit(values)
      else
        iso_list[0] = values['file']
      end
    else
      handle_output(values, "Warning:\tISO file #{values['file']} does not exist")
    end
  else
    iso_list = get_base_dir_list(values)
  end
  if iso_list[0]
    iso_list.each do |file_name|
      file_name   = file_name.chomp
      iso_info    = File.basename(file_name)
      iso_info    = iso_info.split(/-/)
      vs_distro   = iso_info[0]
      vs_distro   = vs_distro.downcase
      iso_version = iso_info[3]
      iso_arch    = iso_info[4].split(/\./)[1]
      iso_version = iso_version.gsub(/\./, "_")
      values['service'] = vs_distro+"_"+iso_version+"_"+iso_arch
      values['repodir'] = values['baserepodir']+"/"+values['service']
      add_apache_alias(values, values['service'])
      configure_vs_repo(values)
      configure_vs_pxe_boot(values)
    end
  else
    add_apache_alias(values, values['service'])
    configure_vs_repo(values)
    configure_vs_pxe_boot(values)
  end
  return
end

# List vSphere kickstart services

def list_vs_services(values)
  values['method'] = "vs"
  dir_list = get_dir_item_list(values)
  message  = "vSphere Services:"
  handle_output(values, message)
  dir_list.each do |service|
    handle_output(values, service)
  end
  handle_output(values, "")
  return
end
