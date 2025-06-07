# frozen_string_literal: true

# Server code for Kickstart

# Unconfigure Linux repo

def unconfigure_ks_repo(values)
  remove_apache_alias(values['service'])
  values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
  if File.symlink?(values['repodir'])
    values['netbootdir'] = "#{values['tftpdir']}/#{values['service']}"
    destroy_zfs_fs(values['netbootdir'])
    File.delete(values['repodir'])
  else
    destroy_zfs_fs(values['repodir'])
  end
  nil
end

# Set ZFS mount point for filesystem

def set_zfs_mount(values)
  zfs_name = values['zpoolname'] + values['repodir']
  message  = "Information:\tSetting #{zfs_name} mount point to #{values['repodir']}"
  command  = "zfs set mountpoint=#{values['netbootdir']} #{zfs_name}"
  execute_command(values, message, command)
  nil
end

# Copy Linux ISO contents to repo

def configure_ks_repo(values)
  values['netbootdir'] = "#{values['tftpdir']}/#{values['service']}"
  if values['host-os-uname'].to_s.match(/SunOS/)
    check_fs_exists(values, values['repodir'])
    if values['host-os-version'].to_i < 11
      File.symlink(values['repodir'], values['netbootdir']) unless File.symlink?(values['netbootdir'])
    else
      set_zfs_mount(values['repodir'], values['netbootdir'])
      unless File.symlink?(values['repodir'])
        Dir.delete(values['repodir'])
        File.symlink(values['netbootdir'], values['repodir'])
      end
    end
  end
  if values['host-os-uname'].to_s.match(/Linux/)
    check_fs_exists(values, values['netbootdir'])
    unless File.symlink?(values['repodir'])
      check_dir_owner(values, values['baserepodir'], values['uid'])
      File.symlink(values['netbootdir'], values['repodir'])
    end
  end
  check_dir = if values['repodir'].to_s.match(/sles/)
                "#{values['repodir']}/boot"
              else
                "#{values['repodir']}/isolinux"
              end
  information_message(values, "Checking directory #{check_dir} exits")
  unless File.directory?(check_dir)
    mount_iso(values)
    copy_iso(values)
    umount_iso(values)
    if values['file'].to_s.match(/DVD1\.iso|1of2\.iso/)
      values['file'] = values['file'].gsub(/1\.iso/, '2.iso') if values['file'].to_s.match(/DVD1/)
      values['file'] = values['file'].gsub(/1of2\.iso/, '2of2.iso') if values['file'].to_s.match(/1of2/)
      mount_iso(values)
      copy_iso(values)
      umount_iso(values)
    end
  end
  if values['service'].to_s.match(/live/)
    orig_file = values['file'].to_s
    iso_file  = File.basename(orig_file)
    file_name = "#{values['repodir']}/#{iso_file}"
    unless File.exist?(file_name)
      message = "Information:\tCopying ISO file #{orig_file} to #{file_name}"
      command = "cp #{orig_file} #{file_name}"
      execute_command(values, message, command)
    end
  end
  nil
end

# Unconfigure Kickstart server

def unconfigure_ks_server(values)
  unconfigure_ks_repo(values['service'])
end

# Configure PXE boot

def configure_ks_pxe_boot(values)
  iso_arch = values['arch']
  values['pxebootdir'] = "#{values['tftpdir']}/#{values['service']}"
  if values['service'].to_s.match(/centos|rhel|fedora|sles|sl_|oel/)
    test_dir = "#{values['pxebootdir']}/usr"
    unless File.directory?(test_dir)
      if values['service'].to_s.match(/centos/)
        rpm_dir = "#{values['baserepodir']}/#{values['service']}/CentOS"
        rpm_dir = "#{values['baserepodir']}/#{values['service']}/Packages" unless File.directory?(rpm_dir)
      end
      rpm_dir = "#{values['baserepodir']}/#{values['service']}/suse" if values['service'].to_s.match(/sles/)
      if values['service'].to_s.match(/sl_/)
        rpm_dir = "#{values['baserepodir']}/#{values['service']}/Scientific"
        rpm_dir = "#{values['baserepodir']}/#{values['service']}/Packages" unless File.directory?(rpm_dir)
      end
      if values['service'].to_s.match(/oel|rhel|fedora/)
        rpm_dir = if values['service'].to_s.match(/rhel_5/)
                    "#{values['baserepodir']}/#{values['service']}/Server"
                  elsif values['service'].to_s.match(/rhel_[8,9]/)
                    "#{values['baserepodir']}/#{values['service']}/BaseOS/Packages"
                  else
                    "#{values['baserepodir']}/#{values['service']}/Packages"
                  end
      end
      if File.directory?(rpm_dir)
        if !values['service'].to_s.match(/sl_|fedora_19|rhel_6/)
          message  = "Information:\tLocating syslinux package"
          command  = "cd #{rpm_dir} ; find . -name 'syslinux-[0-9]*' |grep '#{iso_arch}'"
          output   = execute_command(values, message, command)
          rpm_file = output.chomp
          rpm_file = rpm_file.gsub(%r{\./}, '')
          rpm_file = "#{rpm_dir}/#{rpm_file}"
          check_dir_exists(values, values['pxebootdir'])
        else
          rpm_dir = "#{values['workdir']}/rpm"
          check_dir_exists(values, rpm_dir) unless File.directory?(rpm_dir)
          rpm_url  = 'http://vault.centos.org/5.11/os/i386/CentOS/syslinux-4.02-7.2.el5.i386.rpm'
          rpm_file = "#{rpm_dir}/syslinux-4.02-7.2.el5.i386.rpm"
          wget_file(values, rpm_url, rpm_file) unless File.exist?(rpm_file)
        end
        check_dir_exists(values, values['pxebootdir'])
        message = "Information:\tCopying PXE boot files from #{rpm_file} to #{values['pxebootdir']}"
        command = "cd #{values['pxebootdir']} ; #{values['rpm2cpiobin']} #{rpm_file} | cpio -iud"
        execute_command(values, message, command)
        if values['host-os-unamea'].match(/RedHat/) && values['host-os-unamer'].match(/^7/) && values['pxebootdir'].to_s.match(/[a-z]/)
          httpd_p = 'httpd_sys_rw_content_t'
          tftpd_p = 'unconfined_u:object_r:system_conf_t:s0'
          message = "Information:\tFixing permissions on #{values['pxebootdir']}"
          command = "chcon -R -t #{httpd_p} #{values['pxebootdir']} ; chcon #{tftpd_p} #{values['pxebootdir']}"
          execute_command(values, message, command)
          message = "Information:\tFixing permissions on #{values['pxebootdir']}/usr and #{values['pxebootdir']}/images"
          command = "chcon -R #{values['pxebootdir']}/usr ; chcon -R #{values['pxebootdir']}/images"
          execute_command(values, message, command)
        end
      else
        warning_message(values, "Source directory #{rpm_dir} does not exist")
        quit(values)
      end
    end
    pxe_image_dir = if values['service'].to_s.match(/sles/)
                      "#{values['pxebootdir']}/boot"
                    else
                      "#{values['pxebootdir']}/images"
                    end
    unless File.directory?(pxe_image_dir)
      iso_image_dir = if values['service'].to_s.match(/sles/)
                        "#{values['baserepodir']}/#{values['service']}/boot"
                      else
                        "#{values['baserepodir']}/#{values['service']}/images"
                      end
      message = "Information:\tCopying PXE boot images from #{iso_image_dir} to #{pxe_image_dir}"
      command = "cp -r #{iso_image_dir} #{values['pxebootdir']}"
      execute_command(values, message, command)
    end
  else
    check_dir_exists(values, values['pxebootdir'])
    pxe_image_dir = "#{values['pxebootdir']}/images"
    check_dir_exists(values, pxe_image_dir)
    pxe_image_dir = "#{values['pxebootdir']}/images/pxeboot"
    check_dir_exists(values, pxe_image_dir)
    test_file = "#{pxe_image_dir}/vmlinuz"
    unless values['method'].to_s.match(/ci/)
      iso_image_dir = if values['service'].to_s.match(/ubuntu/)
                        "#{values['baserepodir']}/#{values['service']}/install"
                      else
                        "#{values['baserepodir']}/#{values['service']}/isolinux"
                      end
    end
    unless File.exist?(test_file)
      message = "Information:\tCopying PXE boot files from #{iso_image_dir} to #{pxe_image_dir}"
      command = "cd #{pxe_image_dir} ; cp -r #{iso_image_dir}/* . "
      execute_command(values, message, command)
    end
  end
  pxe_cfg_dir = "#{values['tftpdir']}/pxelinux.cfg"
  check_dir_exists(values, pxe_cfg_dir)
  nil
end

# Unconfigure PXE boot

def unconfigure_ks_pxe_boot(_values)
  nil
end

# Configure Kickstart server

def configure_ks_server(values)
  if values['service'].to_s.match(/[a-z,A-Z]/)
    search_string = 'CentOS' if values['service'].downcase.match(/centos/)
    search_string = 'rhel' if values['service'].downcase.match(/redhat/)
    search_string = 'sl' if values['service'].downcase.match(/scientific|sl_/)
    search_string = 'OracleLinux' if values['service'].downcase.match(/oel/)
  else
    search_string = 'CentOS|rhel|SL|OracleLinux|Fedora'
  end
  configure_linux_server(values, search_string)
  nil
end

# Configure local VMware repo

def configure_ks_vmware_repo(values)
  vmware_dir = "#{$pkg_base_dir}/vmware"
  add_apache_alias(values, vmware_dir)
  repodata_dir = "#{vmware_dir}/repodata"
  vmware_url   = 'http://packages.vmware.com/tools/esx/latest'
  if values['service'].to_s.match(/centos_5|rhel_5|sl_5|oel_5|fedora_18/)
    vmware_url   = "#{vmware_url}/rhel5/#{values['arch']}/"
    repodata_url = "#{vmware_url}repodata/"
  end
  if values['service'].to_s.match(/centos_6|rhel_[6,7]|sl_6|oel_6|fedora_[19,20]/)
    vmware_url   = "#{vmware_url}/rhel6/#{values['arch']}/"
    repodata_url = "#{vmware_url}repodata/"
  end
  if (values['download'] == true) && !File.directory?(vmware_dir)
    check_dir_exists(values, vmware_dir)
    message = "Information:\tFetching VMware RPMs"
    command = "cd #{vmware_dir} ; lftp -e 'mget * ; quit' #{vmware_url}"
    execute_command(values, message, command)
    check_dir_exists(values, repodata_dir)
    message = "Information:\tFetching VMware RPM repodata"
    command = "cd #{repodata_dir} ; lftp -e 'mget * ; quit' #{repodata_url}"
    execute_command(values, message, command)
  end
  nil
end

# Configue Linux server

def configure_linux_server(values, _search_string)
  iso_list = []
  check_fs_exists(values, values['clientdir'])
  check_dhcpd_config(values)
  if values['file'].to_s.match(/[a-z,A-Z]/)
    if File.exist?(values['file'])
      if !values['file'].to_s.match(/CentOS|rhel|Fedora|SL|OracleLinux|ubuntu/)
        warning_message(values, "ISO #{values['file']} does not appear to be a valid Linux distribution")
        quit(values)
      else
        iso_list[0] = values['file']
      end
    else
      warning_message(values, "ISO file #{values['file']} does not exist")
    end
  else
    values['search'] = 'CentOS|rhel|Fedora|SL|OracleLinux|ubuntu'
    iso_list = get_base_dir_list(values)
  end
  if iso_list[0]
    iso_list.each do |file_name|
      file_name = file_name.chomp
      (linux_distro, iso_version, iso_arch) = get_linux_version_info(file_name)
      iso_version = iso_version.gsub(/\./, '_')
      values['service'] = if file_name.match(/live/)
                            "#{linux_distro}_#{iso_version}_live_#{iso_arch}"
                          else
                            "#{linux_distro}_#{iso_version}_#{iso_arch}"
                          end
      values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
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
  elsif values['service'].to_s.match(/[a-z,A-Z]/)
    unless values['arch'].to_s.match(/[a-z,A-Z]/)
      iso_info = values['service'].split(/_/)
      values['arch'] = iso_info[-1]
    end
    add_apache_alias(values, values['service'])
    configure_ks_pxe_boot(values)
    configure_ks_vmware_repo(values) if values['service'].to_s.match(/centos|fedora|rhel|sl_|oel/)
  else
    warning_message(values, 'ISO file and/or Service name not found')
    quit(values)
  end
  nil
end

# List kickstart services

def list_ks_services(values)
  values['method'] = 'ks'
  dir_list = get_dir_item_list(values)
  message  = 'Kickstart Services'
  verbose_message(values, message)
  dir_list.each do |service|
    verbose_message(values, service)
  end
  verbose_message(values, '')
  nil
end
