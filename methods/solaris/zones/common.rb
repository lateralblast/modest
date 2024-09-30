
# Solaris Zones support code

# Check we are on Solaris 10 or later

def check_zone_is_installed(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    if values['host-os-unamer'].split(/\./)[0].to_i > 10
      exists =  true
    else
      exists = false
    end
  else
    exists = false
  end
  return exists
end

# List zone services

def list_zone_services(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    values['version'] = values['host-os-unamer'].split(/\./)[1]
    os_branded = values['version'].to_i-1
    os_branded = os_branded.to_s
    verbose_message(values, "Supported containers:")
    verbose_message(values, "") 
    verbose_message(values, "Solaris #{values['version']} (native)")
    verbose_message(values, "Solaris #{os_branded} (branded)")
  end
  return
end

def get_zone_image_info(option)
  image_info    = values['image'].split(/\-/)
  image_os      = image_info[0].split(//)[0..2].join
  image_version = image_info[1].gsub(/u/, ".")
  image_arch    = image_info[2]
  if image_arch.match(/x86/)
    image_arch = "i386"
  end
  values['service'] = image_os+"_"+image_version.gsub(/\./, "_")+"_"+image_arch
  return image_version, image_arch, values['service']
end

# List zone ISOs/Images

def list_zone_isos(values)
  iso_list = Dir.entries(values['isodir']).grep(/solaris/)
  if iso_list.length > 0
    if values['output'].to_s.match(/html/)
      verbose_message(values, "<h1>Available branded zone images:</h1>")
      verbose_message(values, "<table border=\"1\">")
      verbose_message(values, "<tr>")
      verbose_message(values, "<th>Image File</th>")
      verbose_message(values, "<th>Distribution</th>")
      verbose_message(values, "<th>Architecture</th>")
      verbose_message(values, "<th>Service Name</th>")
      verbose_message(values, "</tr>")
    else
      verbose_message(values, "Available branded zone images:")
      verbose_message(values, "") 
    end
    if values['host-os-unamep'].to_s.match(/sparc/)
      search_arch = values['host-os-unamep']
    else
      search_arch = "x86"
    end
    iso_list.each do |image_file|
      image_file = image_file.chomp
      if image_filematch(/^solaris/) and image_file.match(/bin$/)
        if image_file.match(/#{search_arch}/)
          (image_version, image_arch, values['service']) = get_zone_image_info(image_file)
          if values['output'].to_s.match(/html/)
            verbose_message(values, "<tr>")
            verbose_message(values, "<td>#{values['isodir']}/#{values['image']}</td>")
            verbose_message(values, "<td>Solaris</td>")
            verbose_message(values, "<td>#{image_version}</td>")
            verbose_message(values, "<td>#{values['service']}</td>")
            verbose_message(values, "</tr>")
          else
            verbose_message(values, "Image file:\t#{values['isodir']}/#{values['image']}")
            verbose_message(values, "Distribution:\tSolaris")
            verbose_message(values, "Version:\t#{image_version}")
            verbose_message(values, "Architecture:\t#{image_arch}")
            verbose_message(values, "Service Name\t#{values['service']}")
          end
        end
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_message(values, "</table>")
    else
      verbose_message(values, "")
    end
  end
  return
end

# List available zones

def list_zones(values)
  verbose_message(values, "Available Zones:")
  verbose_message(values, "") 
  message = ""
  command = "zoneadm list |grep -v global"
  output  = execute_command(values, message, command)
  verbose_message(values, output)
  return
end

# List zones

def list_zone_vms(values)
  list_zones(values)
  return
end

# Print branded zone information

def print_branded_zone_info(values)
  branded_url = "http://www.oracle.com/technetwork/server-storage/solaris11/vmtemplates-zones-1949718.html"
  branded_dir = "/export/isos"
  warning_message(values, "Branded zone templates not found")
  information_message(values, "Download them from #{branded_url}")
  information_message(values, "Copy them to #{branded_dir}")
  verbose_message(values, "") 
  return
end

# Check branded zone support is installed

def check_branded_zone_pkg(values)
  if values['host-os-unamer'].match(/11/)
    message = "Information:\tChecking branded zone support is installed"
    command = "pkg info pkg:/system/zones/brand/brand-solaris10 |grep Version |awk \"{print \\\$2}\""
    output  = execute_command(values, message, command)
    if not output.match(/[0-9]/)
      message = "Information:\tInstalling branded zone packages"
      command = "pkg install pkg:/system/zones/brand/brand-solaris10"
      execute_command(values, message, command)
    end
  end
  return
end

# Standard zone post install

def standard_zone_post_install(values)
  values['zonedir'] = values['zonedir']+"/"+values['name']
  if File.directory?(values['zonedir'])
    values['clientdir'] = values['zonedir']+"/root"
    tmp_file       = "/tmp/zone_"+values['name']
    admin_username = values['answers']['admin_username'].value
    admin_uid      = values['answers']['admin_uid'].value
    admin_gid      = values['answers']['admin_gid'].value
    admin_crypt    = values['answers']['admin_crypt'].value
    root_crypt     = values['answers']['root_crypt'].value
    admin_fullname = values['answers']['admin_description'].value
    admin_home     = values['answers']['admin_home'].value
    admin_shell    = values['answers']['admin_shell'].value
    passwd_file    = values['clientdir']+"/etc/passwd"
    shadow_file    = values['clientdir']+"/etc/shadow"
    message = "Checking:\tUser "+admin_username+" doesn't exist"
    command = "cat #{passwd_file} | grep -v '#{admin_username}' > #{tmp_file}"
    execute_command(values, message, command)
    message    = "Adding:\tUser "+admin_username+" to "+passwd_file
    admin_info = admin_username+":x:"+admin_uid+":"+admin_gid+":"+admin_fullname+":"+admin_home+":"+admin_shell
    command    = "echo '#{admin_info}' >> #{tmp_file} ; cat #{tmp_file} > #{passwd_file} ; rm #{tmp_file}"
    execute_command(values, message, command)
    print_contents_of_file(values, "", passwd_file)
    info = IO.readlines(shadow_file)
    file = File.open(tmp_file, "w")
    info.each do |line|
      field = line.split(":")
      if field[0] != "root" and field[0] != "#{admin_username}"
        file.write(line)
      end
      if field[0].to_s.match(/root/)
        field[1] = root_crypt
        copy = field.join(":")
        file.write(copy)
      end
    end
    output = admin_username+":"+admin_crypt+":::99999:7:::\n"
    file.write(output)
    file.close
    message = "Information:\tCreating shadow file"
    command = "cat #{tmp_file} > #{shadow_file} ; rm #{tmp_file}"
    execute_command(values, message, command)
    print_contents_of_file(values, "", shadow_file)
    client_home = values['clientdir']+admin_home
    message = "Information:\tCreating SSH directory for "+admin_username
    command = "mkdir -p #{client_home}/.ssh ; cd #{values['clientdir']}/export/home ; chown -R #{admin_uid}:#{admin_gid} #{admin_username}"
    execute_command(values, message, command)
    # Copy admin user keys
    rsa_file = admin_home+"/.ssh/id_rsa.pub"
    dsa_file = admin_home+"/.ssh/id_dsa.pub"
    key_file = client_home+"/.ssh/authorized_keys"
    if File.exist?(key_file)
      system("rm #{key_file}")
    end
    [rsa_file, dsa_file].each do |pub_file|
      if File.exist?(pub_file)
        message = "Information:\tCopying SSH public key "+pub_file+" to "+key_file
        command = "cat #{pub_file} >> #{key_file}"
        execute_command(values, message, command)
      end
    end
    message = "Information:\tCreating SSH directory for root"
    command = "mkdir -p #{values['clientdir']}/root/.ssh ; cd #{values['clientdir']} ; chown -R 0:0 root"
    execute_command(values, message, command)
    # Copy root keys
    rsa_file = "/root/.ssh/id_rsa.pub"
    dsa_file = "/root/.ssh/id_dsa.pub"
    key_file = values['clientdir']+"/root/.ssh/authorized_keys"
    if File.exist?(key_file)
      system("rm #{key_file}")
    end
    [rsa_file, dsa_file].each do |pub_file|
      if File.exist?(pub_file)
        message = "Information:\tCopying SSH public key "+pub_file+" to "+key_file
        command = "cat #{pub_file} >> #{key_file}"
        execute_command(values, message, command)
      end
    end
    # Fix permissions
    message = "Information:\tFixing SSH permissions for "+admin_username
    command = "cd #{values['clientdir']}/export/home ; chown -R #{admin_uid}:#{admin_gid} #{admin_username}"
    execute_command(values, message, command)
    message = "Information:\tFixing SSH permissions for root "
    command = "cd #{values['clientdir']} ; chown -R 0:0 root"
    execute_command(values, message, command)
    # Add sudoers entry
    sudoers_file = values['clientdir']+"/etc/sudoers"
    message = "Information:\tCreating sudoers file "+sudoers_file
    command = "cat #{sudoers_file} |grep -v '^#includedir' > #{tmp_file} ; cat #{tmp_file} > #{sudoers_file}"
    execute_command(values, message, command)
    message = "Information:\tAdding sudoers include to "+sudoers_file
    command = "echo '#includedir /etc/sudoers.d' >> #{sudoers_file} ; rm #{tmp_file}"
    execute_command(values, message, command)
    sudoers_dir  = values['clientdir']+"/etc/sudoers.d"
    check_dir_exists(values, sudoers_dir)
    sudoers_file = sudoers_dir+"/"+admin_username
    message = "Information:\tCreating sudoers file "+sudoers_file
    command = "echo '#{admin_username} ALL=(ALL) NOPASSWD:ALL' > #{sudoers_file}"
    execute_command(values, message, command)
  else
    warning_message(values, "Zone #{values['name']} doesn't exist")
    quit(values)
  end
  return
end

# Branded zone post install

def branded_zone_post_install(values)
  values['zonedir'] = values['zonedir']+"/"+values['name']
  if File.directory?(values['zonedir'])
    values['clientdir'] = values['zonedir']+"/root"
    var_dir   = "/var/tmp"
    tmp_dir   = values['clientdir']+"/"+var_dir
    post_file = tmp_dir+"/postinstall.sh"
    tmp_file  = "/tmp/zone_"+values['name']
    pkg_name  = "pkgutil.pkg"
    pkg_url   = $local_opencsw_mirror+"/"+pkg_name
    pkg_file  = tmp_dir+"/"+pkg_name
    wget_file(values, pkg_url, pkg_file)
    file = File.open(tmp_file, "w")
    file.write("#!/usr/bin/bash\n")
    file.write("\n")
    file.write("# Post install script\n")
    file.write("\n")
    file.write("cd #{var_dir} ; echo y |pkgadd -d pkgutil.pkg CSWpkgutil\n")
    file.write("export PATH=/opt/csw/bin:$PATH\n")
    file.write("pkutil -i CSWwget\n")
    file.write("\n")
    file.close
    message = "Information:\tCreating post install script "+post_file
    command = "cp #{tmp_file} #{post_file} ; rm #{tmp_file}"
    execute_command(values, message, command)
  else
    warning_message(values, "Zone #{values['name']} doesn't exist")
    quit(values)
  end
  return
end

# Create branded zone

def create_branded_zone(option)
  check_branded_zone_pkg(values)
  if Files.exists?(values['image'])
    message = "Information:\tInstalling Branded Zone "+values['name']
    command = "cd /tmp ; #{values['image']} -p #{values['zonedir']} -i #{values['vmnic']} -z #{values['name']} -f"
    execute_command(values, message, command)
  else
    warning_message(values, "Image file #{values['image']} doesn't exist")
  end
  standard_zone_post_install(values['name'], values['release'])
  branded_zone_post_install(values['name'], values['release'])
  return
end

# Check zone doesn't exist

def check_zone_doesnt_exist(values)
  message = "Information:\tChecking Zone "+values['name']+" doesn't exist"
  command = "zoneadm list -cv |awk '{print $2}' |grep '#{values['name']}'"
  output  = execute_command(values, message, command)
  return output
end

# Create zone config

def create_zone_config(values)
  values['ip']    = single_install_ip(values)
  values['vmnic'] = values['answers']['ipv4_interface_name'].value
  virtual = false
  gateway = values['answers']['ipv4_default_route'].value
  values['vmnic'] = values['vmnic'].split(/\//)[0]
  zone_status = check_zone_doesnt_exist(values)
  if not zone_status.match(/#{values['name']}/)
    if values['host-os-unamep'].to_s.match(/i386/)
      message = "Information:\tChecking Platform"
      command = "prtdiag -v |grep 'VMware'"
      output  = execute_command(values, message, command)
      if output.match(/VMware/)
        virtual = true
      end
    end
    values['zonedir'] = values['zonedir']+"/"+values['name']
    values['zone'] = "/tmp/zone_"+values['name']
    file = File.open(tmp_file, "w")
    file.write("create -b\n")
    file.write("set brand=solaris\n")
    file.write("set zonepath=#{values['zonedir']}\n")
    file.write("set autoboot=false\n")
    if virtual == true
      file.write("set ip-type=shared\n")
      file.write("add net\n")
      file.write("set address=#{values['ip']}/24\n")
      file.write("set configure-allowed-address=true\n")
      file.write("set physical=#{values['vmnic']}\n")
      file.write("set defrouter=#{gateway}\n")
    else
      file.write("set ip-type=exclusive\n")
      file.write("add anet\n")
      file.write("set linkname = #{values['vmnic']}\n")
      file.write("set lower-link=auto\n")
      file.write("set configure-allowed-address=false\n")
      file.write("set mac-address=random\n")
    end
    file.write("end\n")
    file.close
    print_contents_of_file(values, "", values['zone'])
  end
  return values['zone']
end

# Install zone

def install_zone(values)
  message = "Information:\tCreating Solaris "+values['release']+" Zone "+values['name']+" in "+values['zonedir']
  command = "zonecfg -z #{values['name']} -f #{values['zone']}"
  execute_command(values, message, command)
  message = "Information:\tInstalling Zone "+values['name']
  command = "zoneadm -z #{values['name']} install"
  execute_command(values, message, command)
  system("rm #{values['zone']}")
  return
end

# Create zone

def create_zone(values)
  values['ip'] = single_install_ip(values)
  virtual = false
  message = "Information:\tChecking Platform"
  command = "prtdiag -v |grep 'VMware'"
  output  = execute_command(values, message, command)
  if output.match(/VMware/)
    virtual = true
  end
  if values['service'].to_s.match(/[a-z,A-Z]/)
    image_info    = values['service'].split(/_/)
    image_version = image_info[1]+"u"+image_info[2]
    image_arch    = image_info[3]
    if image_arch.match(/i386/)
      image_arch = "x86"
    end
    values['image'] = "solaris-"+image_version+"-"+image_arch+".bin"
  end
  if values['host-os-unamer'].match(/11/) and values['release'].to_s.match(/10/)
    if values['host-os-unamep'].to_s.match(/i386/)
      branded_file = branded_dir+"solaris-10u11-x86.bin"
    else
      branded_file = branded_dir+"solaris-10u11-sparc.bin"
    end
    check_fs_exists(values, branded_dir)
    if not File.exists(branded_file)
      print_branded_zone_info(values)
    end
    create_branded_zone(values['image'], values['ip'], values['vmnic'], values['name'], values['release'])
  else
    if not values['image'].to_s.match(/[a-z,A-Z]/)
      values['zone'] = create_zone_config(values['name'], values['ip'])
      install_zone(values['name'], values['zone'])
      standard_zone_post_install(values['name'], values['release'])
    else
      if not File.exist?(values['image'])
        print_branded_zone_info(values)
      end
      create_zone_config(values['name'], values['ip'])
      if values['host-os-unamer'].match(/11/) and virtual == true
        warning_message(values, "Can't create branded zones with exclusive IPs in VMware")
        quit(values)
      else
        create_branded_zone(values['image'], values['ip'], values['vmnic'], values['name'], values['release'])
      end
    end
  end
  if values['serial'] == true
    boot_zone(values)
  end
  add_hosts_entry(values['name'], values['ip'])
  return
end

# Halt zone

def halt_zone(values)
  message = "Information:\tHalting Zone "+values['name']
  command = "zoneadm -z #{values['name']} halt"
  execute_command(values, message, command)
  return
end

# Delete zone

def unconfigure_zone(values)
  halt_zone(values)
  message = "Information:\tUninstalling Zone "+values['name']
  command = "zoneadm -z #{values['name']} uninstall -F"
  execute_command(values, message, command)
  message = "Information:\tDeleting Zone "+values['name']+" configuration"
  command = "zonecfg -z #{values['name']} delete -F"
  execute_command(values, message, command)
  if values['yes'] == true
    values['zonedir'] = values['zonedir']+"/"+values['name']
    destroy_zfs_fs(values['zonedir'])
  end
  values['ip'] = get_install_ip(values)
  remove_hosts_entry(values)
  return
end

# Get zone status

def get_zone_status(values)
  message = "Information:\tChecking Zone "+values['name']+" isn't running"
  command = "zoneadm list -cv |grep ' #{values['name']} ' |awk '{print $3}'"
  output  = execute_command(values, message, command)
  return output
end

# Boot zone

def boot_zone(values)
  message = "Information:\tBooting Zone "+values['name']
  command = "zoneadm -z #{values['name']} boot"
  execute_command(values, message, command)
  if values['serial'] == true
    system("zlogin #{values['name']}")
  end
  return
end

# Shutdown zone

def stop_zone(values)
  status  = get_zone_status(values)
  if not status.match(/running/)
    message = "Information:\tStopping Zone "+values['name']
    command = "zlogin #{values['name']} shutdown -y -g0 -i 0"
    execute_command(values, message, command)
  end
  return
end



# Configure zone

def configure_zone(values)
  if values['arch'].to_s.match(/[a-z,A-Z]/)
    check_same_arch(values['arch'])
  end
  if not values['image'].to_s.match(/[a-z,A-Z]/) and not values['service'].to_s.match(/[a-z,A-Z]/)
    if not values['release'].to_s.match(/[0-9]/)
      values['release'] = values['host-os-unamer']
    end
  end
  if values['release'].to_s.match(/11/)
    populate_ai_client_profile_questions(values['ip'], values['name'])
    process_questions(values)
  else
    populate_js_client_profile_questions(values['ip'], values['name'])
    process_questions(values)
    if values['image'].to_s.match(/[a-z,A-Z]/)
      (values['release'], values['arch'], values['service']) = get_zone_image_info(values['image'])
      check_same_arch(values['arch'])
    end
  end

  if !File.directory?(values['zonedir'])
    check_fs_exists(values, values['zonedir'])
    message = "Information:\tSetting mount point for "+values['zonedir']
    command = "zfs set #{values['zpoolname']}#{values['zonedir']} mountpoint=#{values['zonedir']}"
    execute_command(values, message, command)
  end
  values['zonedir'] = values['zonedir']+"/"+values['name']
  create_zone(values['name'], values['ip'], values['zonedir'], values['release'], values['image'], values['service'])
  return
end
