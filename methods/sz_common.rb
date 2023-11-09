
# Solaris Zones support code

# Check we are on Solaris 10 or later

def check_zone_is_installed()
  if options['host-os-name'].to_s.match(/SunOS/)
    if options['host-os-release'].split(/\./)[0].to_i > 10
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

def list_zone_services(options)
  if options['host-os-name'].to_s.match(/SunOS/)
    options['version'] = options['host-os-release'].split(/\./)[1]
    os_branded = options['version'].to_i-1
    os_branded = os_branded.to_s
    handle_output(options, "Supported containers:")
    handle_output(options, "") 
    handle_output(options, "Solaris #{options['version']} (native)")
    handle_output(options, "Solaris #{os_branded} (branded)")
  end
  return
end

def get_zone_image_info(option)
  image_info    = options['image'].split(/\-/)
  image_os      = image_info[0].split(//)[0..2].join
  image_version = image_info[1].gsub(/u/, ".")
  image_arch    = image_info[2]
  if image_arch.match(/x86/)
    image_arch = "i386"
  end
  options['service'] = image_os+"_"+image_version.gsub(/\./, "_")+"_"+image_arch
  return image_version, image_arch, options['service']
end

# List zone ISOs/Images

def list_zone_isos(options)
  iso_list = Dir.entries(options['isodir']).grep(/solaris/)
  if iso_list.length > 0
    if options['output'].to_s.match(/html/)
      handle_output(options, "<h1>Available branded zone images:</h1>")
      handle_output(options, "<table border=\"1\">")
      handle_output(options, "<tr>")
      handle_output(options, "<th>Image File</th>")
      handle_output(options, "<th>Distribution</th>")
      handle_output(options, "<th>Architecture</th>")
      handle_output(options, "<th>Service Name</th>")
      handle_output(options, "</tr>")
    else
      handle_output(options, "Available branded zone images:")
      handle_output(options, "") 
    end
    if options['host-os-arch'].to_s.match(/sparc/)
      search_arch = options['host-os-arch']
    else
      search_arch = "x86"
    end
    iso_list.each do |image_file|
      image_file = image_file.chomp
      if image_filematch(/^solaris/) and image_file.match(/bin$/)
        if image_file.match(/#{search_arch}/)
          (image_version, image_arch, options['service']) = get_zone_image_info(image_file)
          if options['output'].to_s.match(/html/)
            handle_output(options, "<tr>")
            handle_output(options, "<td>#{options['isodir']}/#{options['image']}</td>")
            handle_output(options, "<td>Solaris</td>")
            handle_output(options, "<td>#{image_version}</td>")
            handle_output(options, "<td>#{options['service']}</td>")
            handle_output(options, "</tr>")
          else
            handle_output(options, "Image file:\t#{options['isodir']}/#{options['image']}")
            handle_output(options, "Distribution:\tSolaris")
            handle_output(options, "Version:\t#{image_version}")
            handle_output(options, "Architecture:\t#{image_arch}")
            handle_output(options, "Service Name\t#{options['service']}")
          end
        end
      end
    end
    if options['output'].to_s.match(/html/)
      handle_output(options, "</table>")
    else
      handle_output(options, "")
    end
  end
  return
end

# List available zones

def list_zones()
  handle_output(options, "Available Zones:")
  handle_output(options, "") 
  message = ""
  command = "zoneadm list |grep -v global"
  output  = execute_command(options, message, command)
  handle_output(options, output)
  return
end

# List zones

def list_zone_vms(options)
  list_zones()
  return
end

# Print branded zone information

def print_branded_zone_info()
  branded_url = "http://www.oracle.com/technetwork/server-storage/solaris11/vmtemplates-zones-1949718.html"
  branded_dir = "/export/isos"
  handle_output(options, "Warning:\tBranded zone templates not found")
  handle_output(options, "Information:\tDownload them from #{branded_url}")
  handle_output(options, "Information:\tCopy them to #{branded_dir}")
  handle_output(options, "") 
  return
end

# Check branded zone support is installed

def check_branded_zone_pkg()
  if options['host-os-release'].match(/11/)
    message = "Information:\tChecking branded zone support is installed"
    command = "pkg info pkg:/system/zones/brand/brand-solaris10 |grep Version |awk \"{print \\\$2}\""
    output  = execute_command(options, message, command)
    if not output.match(/[0-9]/)
      message = "Information:\tInstalling branded zone packages"
      command = "pkg install pkg:/system/zones/brand/brand-solaris10"
      execute_command(options, message, command)
    end
  end
  return
end

# Standard zone post install

def standard_zone_post_install(options)
  options['zonedir'] = options['zonedir']+"/"+options['name']
  if File.directory?(options['zonedir'])
    options['clientdir'] = options['zonedir']+"/root"
    tmp_file       = "/tmp/zone_"+options['name']
    admin_username = options['q_struct']['admin_username'].value
    admin_uid      = options['q_struct']['admin_uid'].value
    admin_gid      = options['q_struct']['admin_gid'].value
    admin_crypt    = options['q_struct']['admin_crypt'].value
    root_crypt     = options['q_struct']['root_crypt'].value
    admin_fullname = options['q_struct']['admin_description'].value
    admin_home     = options['q_struct']['admin_home'].value
    admin_shell    = options['q_struct']['admin_shell'].value
    passwd_file    = options['clientdir']+"/etc/passwd"
    shadow_file    = options['clientdir']+"/etc/shadow"
    message = "Checking:\tUser "+admin_username+" doesn't exist"
    command = "cat #{passwd_file} | grep -v '#{admin_username}' > #{tmp_file}"
    execute_command(options, message, command)
    message    = "Adding:\tUser "+admin_username+" to "+passwd_file
    admin_info = admin_username+":x:"+admin_uid+":"+admin_gid+":"+admin_fullname+":"+admin_home+":"+admin_shell
    command    = "echo '#{admin_info}' >> #{tmp_file} ; cat #{tmp_file} > #{passwd_file} ; rm #{tmp_file}"
    execute_command(options, message, command)
    print_contents_of_file(options, "", passwd_file)
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
    execute_command(options, message, command)
    print_contents_of_file(options, "", shadow_file)
    client_home = options['clientdir']+admin_home
    message = "Information:\tCreating SSH directory for "+admin_username
    command = "mkdir -p #{client_home}/.ssh ; cd #{options['clientdir']}/export/home ; chown -R #{admin_uid}:#{admin_gid} #{admin_username}"
    execute_command(options, message, command)
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
        execute_command(options, message, command)
      end
    end
    message = "Information:\tCreating SSH directory for root"
    command = "mkdir -p #{options['clientdir']}/root/.ssh ; cd #{options['clientdir']} ; chown -R 0:0 root"
    execute_command(options, message, command)
    # Copy root keys
    rsa_file = "/root/.ssh/id_rsa.pub"
    dsa_file = "/root/.ssh/id_dsa.pub"
    key_file = options['clientdir']+"/root/.ssh/authorized_keys"
    if File.exist?(key_file)
      system("rm #{key_file}")
    end
    [rsa_file, dsa_file].each do |pub_file|
      if File.exist?(pub_file)
        message = "Information:\tCopying SSH public key "+pub_file+" to "+key_file
        command = "cat #{pub_file} >> #{key_file}"
        execute_command(options, message, command)
      end
    end
    # Fix permissions
    message = "Information:\tFixing SSH permissions for "+admin_username
    command = "cd #{options['clientdir']}/export/home ; chown -R #{admin_uid}:#{admin_gid} #{admin_username}"
    execute_command(options, message, command)
    message = "Information:\tFixing SSH permissions for root "
    command = "cd #{options['clientdir']} ; chown -R 0:0 root"
    execute_command(options, message, command)
    # Add sudoers entry
    sudoers_file = options['clientdir']+"/etc/sudoers"
    message = "Information:\tCreating sudoers file "+sudoers_file
    command = "cat #{sudoers_file} |grep -v '^#includedir' > #{tmp_file} ; cat #{tmp_file} > #{sudoers_file}"
    execute_command(options, message, command)
    message = "Information:\tAdding sudoers include to "+sudoers_file
    command = "echo '#includedir /etc/sudoers.d' >> #{sudoers_file} ; rm #{tmp_file}"
    execute_command(options, message, command)
    sudoers_dir  = options['clientdir']+"/etc/sudoers.d"
    check_dir_exists(options, sudoers_dir)
    sudoers_file = sudoers_dir+"/"+admin_username
    message = "Information:\tCreating sudoers file "+sudoers_file
    command = "echo '#{admin_username} ALL=(ALL) NOPASSWD:ALL' > #{sudoers_file}"
    execute_command(options, message, command)
  else
    handle_output(options, "Warning:\tZone #{options['name']} doesn't exist")
    quit(options)
  end
  return
end

# Branded zone post install

def branded_zone_post_install(options)
  options['zonedir'] = options['zonedir']+"/"+options['name']
  if File.directory?(options['zonedir'])
    options['clientdir'] = options['zonedir']+"/root"
    var_dir    = "/var/tmp"
    tmp_dir    = options['clientdir']+"/"+var_dir
    post_file  = tmp_dir+"/postinstall.sh"
    tmp_file   = "/tmp/zone_"+options['name']
    pkg_name   = "pkgutil.pkg"
    pkg_url    = $local_opencsw_mirror+"/"+pkg_name
    pkg_file   = tmp_dir+"/"+pkg_name
    wget_file(options, pkg_url, pkg_file)
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
    execute_command(options, message, command)
  else
    handle_output(options, "Warning:\tZone #{options['name']} doesn't exist")
    quit(options)
  end
  return
end

# Create branded zone

def create_branded_zone(option)
  check_branded_zone_pkg()
  if Files.exists?(options['image'])
    message = "Information:\tInstalling Branded Zone "+options['name']
    command = "cd /tmp ; #{options['image']} -p #{options['zonedir']} -i #{options['vmnic']} -z #{options['name']} -f"
    execute_command(options, message, command)
  else
    handle_output(options, "Warning:\tImage file #{options['image']} doesn't exist")
  end
  standard_zone_post_install(options['name'], options['release'])
  branded_zone_post_install(options['name'], options['release'])
  return
end

# Check zone doesn't exist

def check_zone_doesnt_exist(options)
  message = "Information:\tChecking Zone "+options['name']+" doesn't exist"
  command = "zoneadm list -cv |awk '{print $2}' |grep '#{options['name']}'"
  output  = execute_command(options, message, command)
  return output
end

# Create zone config

def create_zone_config(options)
  options['ip']    = single_install_ip(options)
  options['vmnic'] = options['q_struct']['ipv4_interface_name'].value
  virtual = false
  gateway = options['q_struct']['ipv4_default_route'].value
  options['vmnic'] = options['vmnic'].split(/\//)[0]
  zone_status = check_zone_doesnt_exist(options)
  if not zone_status.match(/#{options['name']}/)
    if options['host-os-arch'].to_s.match(/i386/)
      message = "Information:\tChecking Platform"
      command = "prtdiag -v |grep 'VMware'"
      output  = execute_command(options, message, command)
      if output.match(/VMware/)
        virtual = true
      end
    end
    options['zonedir'] = options['zonedir']+"/"+options['name']
    options['zone'] = "/tmp/zone_"+options['name']
    file = File.open(tmp_file, "w")
    file.write("create -b\n")
    file.write("set brand=solaris\n")
    file.write("set zonepath=#{options['zonedir']}\n")
    file.write("set autoboot=false\n")
    if virtual == true
      file.write("set ip-type=shared\n")
      file.write("add net\n")
      file.write("set address=#{options['ip']}/24\n")
      file.write("set configure-allowed-address=true\n")
      file.write("set physical=#{options['vmnic']}\n")
      file.write("set defrouter=#{gateway}\n")
    else
      file.write("set ip-type=exclusive\n")
      file.write("add anet\n")
      file.write("set linkname = #{options['vmnic']}\n")
      file.write("set lower-link=auto\n")
      file.write("set configure-allowed-address=false\n")
      file.write("set mac-address=random\n")
    end
    file.write("end\n")
    file.close
    print_contents_of_file(options, "", options['zone'])
  end
  return options['zone']
end

# Install zone

def install_zone(options)
  message = "Information:\tCreating Solaris "+options['release']+" Zone "+options['name']+" in "+options['zonedir']
  command = "zonecfg -z #{options['name']} -f #{options['zone']}"
  execute_command(options, message, command)
  message = "Information:\tInstalling Zone "+options['name']
  command = "zoneadm -z #{options['name']} install"
  execute_command(options, message, command)
  system("rm #{options['zone']}")
  return
end

# Create zone

def create_zone(options)
  options['ip'] = single_install_ip(options)
  virtual    = false
  message    = "Information:\tChecking Platform"
  command    = "prtdiag -v |grep 'VMware'"
  output     = execute_command(options, message, command)
  if output.match(/VMware/)
    virtual = true
  end
  if options['service'].to_s.match(/[a-z,A-Z]/)
    image_info    = options['service'].split(/_/)
    image_version = image_info[1]+"u"+image_info[2]
    image_arch    = image_info[3]
    if image_arch.match(/i386/)
      image_arch = "x86"
    end
    options['image'] = "solaris-"+image_version+"-"+image_arch+".bin"
  end
  if options['host-os-release'].match(/11/) and options['release'].to_s.match(/10/)
    if options['host-os-arch'].to_s.match(/i386/)
      branded_file = branded_dir+"solaris-10u11-x86.bin"
    else
      branded_file = branded_dir+"solaris-10u11-sparc.bin"
    end
    check_fs_exists(options, branded_dir)
    if not File.exists(branded_file)
      print_branded_zone_info()
    end
    create_branded_zone(options['image'], options['ip'], options['vmnic'], options['name'], options['release'])
  else
    if not options['image'].to_s.match(/[a-z,A-Z]/)
      options['zone'] = create_zone_config(options['name'], options['ip'])
      install_zone(options['name'], options['zone'])
      standard_zone_post_install(options['name'], options['release'])
    else
      if not File.exist?(options['image'])
        print_branded_zone_info()
      end
      create_zone_config(options['name'], options['ip'])
      if options['host-os-release'].match(/11/) and virtual == true
        handle_output(options, "Warning:\tCan't create branded zones with exclusive IPs in VMware")
        quit(options)
      else
        create_branded_zone(options['image'], options['ip'], options['vmnic'], options['name'], options['release'])
      end
    end
  end
  if options['serial'] == true
    boot_zone(options)
  end
  add_hosts_entry(options['name'], options['ip'])
  return
end

# Halt zone

def halt_zone(options)
  message = "Information:\tHalting Zone "+options['name']
  command = "zoneadm -z #{options['name']} halt"
  execute_command(options, message, command)
  return
end

# Delete zone

def unconfigure_zone(options)
  halt_zone(options)
  message = "Information:\tUninstalling Zone "+options['name']
  command = "zoneadm -z #{options['name']} uninstall -F"
  execute_command(options, message, command)
  message = "Information:\tDeleting Zone "+options['name']+" configuration"
  command = "zonecfg -z #{options['name']} delete -F"
  execute_command(options, message, command)
  if options['yes'] == true
    options['zonedir'] = options['zonedir']+"/"+options['name']
    destroy_zfs_fs(options['zonedir'])
  end
  options['ip'] = get_install_ip(options)
  remove_hosts_entry(options)
  return
end

# Get zone status

def get_zone_status(options)
  message = "Information:\tChecking Zone "+options['name']+" isn't running"
  command = "zoneadm list -cv |grep ' #{options['name']} ' |awk '{print $3}'"
  output  = execute_command(options, message, command)
  return output
end

# Boot zone

def boot_zone(options)
  message = "Information:\tBooting Zone "+options['name']
  command = "zoneadm -z #{options['name']} boot"
  execute_command(options, message, command)
  if options['serial'] == true
    system("zlogin #{options['name']}")
  end
  return
end

# Shutdown zone

def stop_zone(options)
  status  = get_zone_status(options)
  if not status.match(/running/)
    message = "Information:\tStopping Zone "+options['name']
    command = "zlogin #{options['name']} shutdown -y -g0 -i 0"
    execute_command(options, message, command)
  end
  return
end



# Configure zone

def configure_zone(options)
  if options['arch'].to_s.match(/[a-z,A-Z]/)
    check_same_arch(options['arch'])
  end
  if not options['image'].to_s.match(/[a-z,A-Z]/) and not options['service'].to_s.match(/[a-z,A-Z]/)
    if not options['release'].to_s.match(/[0-9]/)
      options['release'] = options['host-os-release']
    end
  end
  if options['release'].to_s.match(/11/)
    populate_ai_client_profile_questions(options['ip'], options['name'])
    process_questions(options)
  else
    populate_js_client_profile_questions(options['ip'], options['name'])
    process_questions(options)
    if options['image'].to_s.match(/[a-z,A-Z]/)
      (options['release'], options['arch'], options['service']) = get_zone_image_info(options['image'])
      check_same_arch(options['arch'])
    end
  end

  if !File.directory?(options['zonedir'])
    check_fs_exists(options, options['zonedir'])
    message = "Information:\tSetting mount point for "+options['zonedir']
    command = "zfs set #{options['zpoolname']}#{options['zonedir']} mountpoint=#{options['zonedir']}"
    execute_command(options, message, command)
  end
  options['zonedir'] = options['zonedir']+"/"+options['name']
  create_zone(options['name'], options['ip'], options['zonedir'], options['release'], options['image'], options['service'])
  return
end
