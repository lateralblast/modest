# Server code for *BSD and other (e.g. CoreOS) PXE boot

# Configure BSD server

def configure_xb_server(options)
  if options['service'].to_s.match(/[a-z,A-Z]/)
    case options['service']
    when /openbsd/
      search_string = "install"
    when /freebsd/
      search_string = "FreeBSD"
    when /coreos/
      search_string = "coreos"
    end
  else
    search_string = "install|FreeBSD|coreos"
  end
  configure_other_server(options,search_string)
  return
end

# Copy Linux ISO contents to repo

def configure_xb_repo(options)
  check_fs_exists(options,options['repodir'])
  case options['service'].to_s
  when /openbsd|freebsd/
    check_dir = options['repodir'].to_s+"/etc"
  when /coreos/
    check_dir = options['repodir'].to_s+"/coreos"
  end
  if options['verbose'] == true
    handle_output(options,"Checking:\tDirectory #{check_dir} exits")
  end
  if !File.directory?(check_dir)
    mount_iso(options)
    copy_iso(options)
    umount_iso(options)
  end
  return
end

# Configure PXE boot

def configure_xb_pxe_boot(iso_arch,iso_version,options)
  if options['service'].to_s.match(/openbsd/)
    iso_arch = iso_arch.gsub(/x86_64/,"amd64")
    pxe_boot_file = options['pxebootdir'].to_s+"/"+iso_version+"/"+iso_arch+"/pxeboot"
    if !File.exist?(pxe_boot_file)
      pxe_boot_url = options['openbsdurl'].to_s+"/"+iso_version+"/"+iso_arch+"/pxeboot"
      wget_file(options,pxe_boot_url,pxe_boot_file)
    end
  end
  return
end

# Unconfigure BSD server

def unconfigure_xb_server(options)
  remove_apache_alias(options)
  options['pxebootdir'] = options['tftpdir'].to_s.+"/"+options['service'].to_s
  options['repodir'] = options['baserepodir'].to_s.+"/"+options['service'].to_s
  destroy_zfs_fs(options['repodir'])
  if File.symlink?(options['repodir'])
    File.delete(options['repodir'])
  end
  if File.directory?(options['pxebootdir'])
    Dir.rmdir(options['pxebootdir'])
  end
  return
end

# Configue BSD server

def configure_other_server(options,search_string)
  iso_list = []
  check_dhcpd_config(options)
  if options['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(options['file'])
      if not options['file'].to_s.match(/install|FreeBSD|coreos/)
        handle_output(options,"Warning:\tISO #{options['file']} does not appear to be a valid distribution")
        quit(options)
      else
        iso_list[0] = options['file']
      end
    else
      handle_output(options,"Warning:\tISO file #{options['file']} does not exist")
    end
  else
    iso_list = get_base_dir_list(options)
  end
  if iso_list[0]
    iso_list.each do |file_name|
      options['file'] = file_name.chomp
      (other_distro,iso_version,iso_arch) = get_other_version_info(file_name)
      options['service'] = other_distro.downcase+"_"+iso_version.gsub(/\./,"_")+"_"+iso_arch
      options['pxebootdir'] = options['tftpdir'].to_s+"/"+options['service'].to_s
      options['repodir']  = options['baserepodir'].to_s+"/"+options['service'].to_s
      add_apache_alias(options,options['service'])
      configure_xb_repo(options)
      configure_xb_pxe_boot(iso_arch,iso_version,options)
    end
  else
    if options['service'].to_s.match(/[a-z,A-Z]/)
      if !options['name'].to_s.match(/[a-z,A-Z]/)
        iso_info = options['service'].split(/_/)
        options['name'] = iso_info[-1]
      end
      add_apache_alias(options,options['service'])
      configure_xb_pxe_boot(options)
    else
      handle_output(options,"Warning:\tISO file and/or Service name not found")
      quit(options)
    end
  end
  return
end

# List kickstart services

def list_xb_services(options)
  dir_list = get_dir_item_list(options)
  message  = "BSD Services:"
  handle_output(options,message)
  dir_list.each do |service|
    handle_output(options,service)
  end
  handle_output(options,"")
  return
end
