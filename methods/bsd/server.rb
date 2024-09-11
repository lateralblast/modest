# Server code for *BSD and other (e.g. CoreOS) PXE boot

# Configure BSD server

def configure_xb_server(values)
  if values['service'].to_s.match(/[a-z,A-Z]/)
    case values['service']
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
  configure_other_server(values, search_string)
  return
end

# Copy Linux ISO contents to repo

def configure_xb_repo(values)
  check_fs_exists(values, values['repodir'])
  case values['service'].to_s
  when /openbsd|freebsd/
    check_dir = values['repodir'].to_s+"/etc"
  when /coreos/
    check_dir = values['repodir'].to_s+"/coreos"
  end
  if values['verbose'] == true
    handle_output(values, "Checking:\tDirectory #{check_dir} exits")
  end
  if !File.directory?(check_dir)
    mount_iso(values)
    copy_iso(values)
    umount_iso(values)
  end
  return
end

# Configure PXE boot

def configure_xb_pxe_boot(iso_arch, iso_version, values)
  if values['service'].to_s.match(/openbsd/)
    iso_arch = iso_arch.gsub(/x86_64/, "amd64")
    pxe_boot_file = values['pxebootdir'].to_s+"/"+iso_version+"/"+iso_arch+"/pxeboot"
    if !File.exist?(pxe_boot_file)
      pxe_boot_url = values['openbsdurl'].to_s+"/"+iso_version+"/"+iso_arch+"/pxeboot"
      wget_file(values, pxe_boot_url, pxe_boot_file)
    end
  end
  return
end

# Unconfigure BSD server

def unconfigure_xb_server(values)
  remove_apache_alias(values)
  values['pxebootdir'] = values['tftpdir'].to_s.+"/"+values['service'].to_s
  values['repodir'] = values['baserepodir'].to_s.+"/"+values['service'].to_s
  destroy_zfs_fs(values['repodir'])
  if File.symlink?(values['repodir'])
    File.delete(values['repodir'])
  end
  if File.directory?(values['pxebootdir'])
    Dir.rmdir(values['pxebootdir'])
  end
  return
end

# Configue BSD server

def configure_other_server(values, search_string)
  iso_list = []
  check_dhcpd_config(values)
  if values['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(values['file'])
      if not values['file'].to_s.match(/install|FreeBSD|coreos/)
        handle_output(values, "Warning:\tISO #{values['file']} does not appear to be a valid distribution")
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
      values['file'] = file_name.chomp
      (other_distro, iso_version, iso_arch) = get_other_version_info(file_name)
      values['service'] = other_distro.downcase+"_"+iso_version.gsub(/\./, "_")+"_"+iso_arch
      values['pxebootdir'] = values['tftpdir'].to_s+"/"+values['service'].to_s
      values['repodir']  = values['baserepodir'].to_s+"/"+values['service'].to_s
      add_apache_alias(values, values['service'])
      configure_xb_repo(values)
      configure_xb_pxe_boot(iso_arch, iso_version, values)
    end
  else
    if values['service'].to_s.match(/[a-z,A-Z]/)
      if !values['name'].to_s.match(/[a-z,A-Z]/)
        iso_info = values['service'].split(/_/)
        values['name'] = iso_info[-1]
      end
      add_apache_alias(values, values['service'])
      configure_xb_pxe_boot(values)
    else
      handle_output(values, "Warning:\tISO file and/or Service name not found")
      quit(values)
    end
  end
  return
end

# List kickstart services

def list_xb_services(values)
  dir_list = get_dir_item_list(values)
  message  = "BSD Services:"
  handle_output(values, message)
  dir_list.each do |service|
    handle_output(values, service)
  end
  handle_output(values, "")
  return
end
