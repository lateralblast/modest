
# Server code for VSphere

# Unconfigure alternate packages

def unconfigure_vs_alt_repo(options)
  return
end

# Configure alternate packages

def configure_vs_alt_repo(options)
  rpm_list = build_vs_alt_rpm_list(options)
  alt_dir  = options['baserepodir']+"/"+options['service']+"/alt"
  check_dir_exists(options,alt_dir)
  rpm_list.each do |rpm_url|
    rpm_file = File.basename(rpm_url)
    rpm_file = alt_dir+"/"+rpm_file
    if not File.exist?(rpm_file)
      wget_file(options,rpm_url,rpm_file)
    end
  end
  return
end

# Unconfigure Linux repo

def unconfigure_vs_repo(options)
  remove_apache_alias(options)
  options['repodir'] = options['baserepodir']+"/"+options['service']
  if options['osname'].to_s.match(/SunOS/)
    if File.symlink?(options['repodir'])
      message = "Information:\tRemoving symlink "+options['repodir']
      command = "rm #{options['repodir']}"
      execute_command(options,message,command)
    else
      destroy_zfs_fs(options['repodir'])
    end
    options['netbootdir'] = options['tftpdir']+"/"+options['service']
    if File.directory?(options['netbootdir'])
      message = "Information:\tRemoving directory "+options['netbootdir']
      command = "rmdir #{options['netbootdir']}"
      execute_command(options,message,command)
    end
  else
    if File.directory?(options['repodir'])
      message = "Information:\tRemoving directory "+options['repodir']
      command = "rm #{options['repodir']}"
      execute_command(options,message,command)
    end
  end
  return
end

# Copy Linux ISO contents to

def configure_vs_repo(options)
  if options['osname'].to_s.match(/SunOS/)
    check_fs_exists(options,options['repodir'])
    options['netbootdir'] = options['tftpdir']+"/"+options['service']
    if not File.symlink?(options['repodir'])
      check_dir_owner(options,options['netbootdir'],options['uid'])
      File.symlink(options['repodir'],options['netbootdir'])
    end
  end
  if options['osname'].to_s.match(/Linux/)
    options['netbootdir'] = options['tftpdir']+"/"+options['service']
    check_fs_exists(options,options['netbootdir'])
    if !File.exist?(options['repodir'])
      check_dir_owner(options,options['netbootdir'],options['uid'])
      File.symlink(options['netbootdir'],options['repodir'])
    end
  end
  check_dir = options['repodir']+"/upgrade"
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking directory #{check_dir} exists")
  end
  if not File.directory?(check_dir)
    mount_iso(options)
    options['repodir'] = options['tftpdir']+"/"+options['service']
    copy_iso(options)
    umount_iso(options)
  end
  options['clientdir'] = options['clientdir']+"/"+options['service']
  ovf_file   = options['clientdir']+"/vmware-ovftools.tar.gz"
  if not File.exist?(ovf_file)
    wget_file(options,options['ovftarurl'],ovf_file)
    if options['osuname'].match(/RedHat/) and options['osversion'].match(/^7|^6\.7/)
      message = "Information:\tFixing permission on "+ovf_file
      command = "chcon -R -t httpd_sys_rw_content_t #{ovf_file}"
      execute_command(options,message,command)
    end
  end
  return
end

# Unconfigure VSphere server

def unconfigure_vs_server(options)
  unconfigure_vs_repo(options)
end

# Configure PXE boot

def configure_vs_pxe_boot(options)
  options['pxebootdir'] = options['tftpdir']+"/"+options['service']
  test_dir = options['pxebootdir']+"/usr"
  if not File.directory?(test_dir)
    rpm_dir = options['workdir']+"/rpms"
    check_dir_exists(options,rpm_dir)
    if File.directory?(rpm_dir)
      message  = "Information:\tLocating syslinux package"
      command  = "ls #{rpm_dir} |grep 'syslinux-[0-9]'"
      output   = execute_command(options,message,command)
      rpm_file = output.chomp
      if not rpm_file.match(/syslinux/)
        rpm_file = "syslinux-4.02-7.2.el5.i386.rpm"
        rpm_file = rpm_dir+"/"+rpm_file
        rpm_url  = "http://vault.centos.org/5.11/os/i386/CentOS/syslinux-4.02-7.2.el5.i386.rpm"
        wget_file(options,rpm_url,rpm_file)
      else
        rpm_file = rpm_dir+"/"+rpm_file
      end
      check_dir_exists(options,options['pxebootdir'])
      message = "Information:\tCopying PXE boot files from "+rpm_file+" to "+options['pxebootdir']
      command = "cd #{options['pxebootdir']} ; #{options['rpm2cpiobin'] } #{rpm_file} | cpio -iud"
      output  = execute_command(options,message,command)
    else
      handle_output(options,"Warning:\tSource directory #{rpm_dir} does not exist")
      quit(options)
    end
  end
  if not options['service'].to_s.match(/vmware/)
    pxe_image_dir=options['pxebootdir']+"/images"
    if not File.directory?(pxe_image_dir)
      iso_image_dir = options['baserepodir']+"/"+options['service']+"/images"
      message       = "Information:\tCopying PXE boot images from "+iso_image_dir+" to "+pxe_image_dir
      command       = "cp -r #{iso_image_dir} #{options['pxebootdir']}"
      output        = execute_command(options,message,command)
    end
  end
  pxe_cfg_dir = options['tftpdir']+"/pxelinux.cfg"
  check_dir_exists(options,pxe_cfg_dir)
  return
end

# Unconfigure PXE boot

def unconfigure_vs_pxe_boot(options)
  return
end

# Configure VSphere server

def configure_vs_server(options)
  search_string = "VMvisor"
  iso_list      = []
  if options['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(options['file'])
      if not options['file'].to_s.match(/VM/)
        handle_output(options,"Warning:\tISO #{options['file']} does not appear to be VMware distribution")
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
      file_name   = file_name.chomp
      iso_info    = File.basename(file_name)
      iso_info    = iso_info.split(/-/)
      vs_distro   = iso_info[0]
      vs_distro   = vs_distro.downcase
      iso_version = iso_info[3]
      iso_arch    = iso_info[4].split(/\./)[1]
      iso_version = iso_version.gsub(/\./,"_")
      options['service'] = vs_distro+"_"+iso_version+"_"+iso_arch
      options['repodir'] = options['baserepodir']+"/"+options['service']
      add_apache_alias(options,options['service'])
      configure_vs_repo(options)
      configure_vs_pxe_boot(options)
    end
  else
    add_apache_alias(options,options['service'])
    configure_vs_repo(options)
    configure_vs_pxe_boot(options)
  end
  return
end

# List vSphere kickstart services

def list_vs_services(options)
  message = "vSphere Services:"
  command = "ls #{options['baserepodir']}/ |egrep 'vmware|esx'"
  output  = execute_command(options,message,command)
  handle_output(options,message)
  handle_output(options,output)
  return
end
