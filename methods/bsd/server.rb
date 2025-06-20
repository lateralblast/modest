# frozen_string_literal: true

# Server code for *BSD and other (e.g. CoreOS) PXE boot

# Configure BSD server

def configure_xb_server(values)
  if values['service'].to_s.match(/[a-z,A-Z]/)
    case values['service']
    when /openbsd/
      search_string = 'install'
    when /freebsd/
      search_string = 'FreeBSD'
    when /coreos/
      search_string = 'coreos'
    end
  else
    search_string = 'install|FreeBSD|coreos'
  end
  configure_other_server(values, search_string)
  nil
end

# Copy Linux ISO contents to repo

def configure_xb_repo(values)
  check_fs_exists(values, values['repodir'])
  case values['service'].to_s
  when /openbsd|freebsd/
    check_dir = "#{values['repodir']}/etc"
  when /coreos/
    check_dir = "#{values['repodir']}/coreos"
  end
  verbose_message(values, "Checking:\tDirectory #{check_dir} exits")
  unless File.directory?(check_dir)
    mount_iso(values)
    copy_iso(values)
    umount_iso(values)
  end
  nil
end

# Configure PXE boot

def configure_xb_pxe_boot(iso_arch, iso_version, values)
  if values['service'].to_s.match(/openbsd/)
    iso_arch = iso_arch.gsub(/x86_64/, 'amd64')
    pxe_boot_file = "#{values['pxebootdir']}/#{iso_version}/#{iso_arch}/pxeboot"
    unless File.exist?(pxe_boot_file)
      pxe_boot_url = "#{values['openbsdurl']}/#{iso_version}/#{iso_arch}/pxeboot"
      wget_file(values, pxe_boot_url, pxe_boot_file)
    end
  end
  nil
end

# Unconfigure BSD server

def unconfigure_xb_server(values)
  remove_apache_alias(values)
  values['pxebootdir'] = "#{values['tftpdir']}/#{values['service']}"
  values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
  destroy_zfs_fs(values['repodir'])
  File.delete(values['repodir']) if File.symlink?(values['repodir'])
  Dir.rmdir(values['pxebootdir']) if File.directory?(values['pxebootdir'])
  nil
end

# Configue BSD server

def configure_other_server(values, _search_string)
  iso_list = []
  check_dhcpd_config(values)
  if values['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(values['file'])
      if !values['file'].to_s.match(/install|FreeBSD|coreos/)
        warning_message(values, "ISO #{values['file']} does not appear to be a valid distribution")
        quit(values)
      else
        iso_list[0] = values['file']
      end
    else
      warning_message(values, "ISO file #{values['file']} does not exist")
    end
  else
    iso_list = get_base_dir_list(values)
  end
  if iso_list[0]
    iso_list.each do |file_name|
      values['file'] = file_name.chomp
      (other_distro, iso_version, iso_arch) = get_other_version_info(file_name)
      values['service'] = "#{other_distro.downcase}_#{iso_version.gsub(/\./, '_')}_#{iso_arch}"
      values['pxebootdir'] = "#{values['tftpdir']}/#{values['service']}"
      values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
      add_apache_alias(values, values['service'])
      configure_xb_repo(values)
      configure_xb_pxe_boot(iso_arch, iso_version, values)
    end
  elsif values['service'].to_s.match(/[a-z,A-Z]/)
    unless values['name'].to_s.match(/[a-z,A-Z]/)
      iso_info = values['service'].split(/_/)
      values['name'] = iso_info[-1]
    end
    add_apache_alias(values, values['service'])
    configure_xb_pxe_boot(values)
  else
    warning_message(values, 'ISO file and/or Service name not found')
    quit(values)
  end
  nil
end

# List kickstart services

def list_xb_services(values)
  dir_list = get_dir_item_list(values)
  message  = 'BSD Services:'
  verbose_message(values, message)
  dir_list.each do |service|
    verbose_message(values, service)
  end
  verbose_message(values, '')
  nil
end
