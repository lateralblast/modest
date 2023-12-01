
# AI server code

# Delecte a service
# This will also delete all the clients under it

def unconfigure_ai_server(options)
  if options['host-os-uname'].to_s.match(/SunOS/)
    service_base_name   = get_service_base_name(options['service'])
    smf_install_service = "svc:/application/pkg/server:"+service_base_name
    smf_service_test    = %x[svcs -a |grep "#{smf_install_service}']
    if smf_service_test.match(/pkg/)
      unconfigure_ai_pkg_repo(smf_install_service)
    end
    if not options['service'].to_s.match(/i386|sparc/)
      ['i386", "sparc'].each do |sys_arch|
        service_test = %x[installadm list |grep #{options['service']} |grep #{sys_arch}]
        if service_test.match(/[a-z,A-Z,0-9]/)
          message = "Information:\tDeleting service "+options['service']+"_"+sys_arch+" and all clients under it"
          command = "installadm delete-service "+options['service']+"_"+sys_arch+" -r -y"
          execute_command(options, message, command)
        end
      end
    else
      service_test=%x[installadm list |grep #{options['service']}]
      if service_test.match(/[a-z,A-Z,0-9]/)
        message = "Information:\tDeleting service "+options['service']+" and all clients under it"
        command = "installadm delete-service "+options['service']+" -r -y"
        execute_command(options, message, command)
      end
    end
    file="/etc/inet/dhcpd4.conf"
    if File.exist?(file)
      bu_file = file+".preai"
      message = "Information:\tRestoring file "+bu_file+" to "+file
      command = "cp #{bu_file} #{file}"
      execute_command(options, message, command)
      smf_install_service = "svc:/network/dhcp/server:ipv4"
      refresh_smf_service(smf_install_service)
    end
    remove_apache_proxy(options)
    repo_dir = options['baserepodir']+"/"+service_base_name
    test_dir = repo_dir+"/publisher"
    if File.directory?(test_dir) and options['yes'] == true
      destroy_zfs_fs(repo_dir)
    end
  else
    remove_apache_proxy(options)
  end
  return
end

# Check we've got a default route
# This is required for DHCPd to start

def check_default_route(options)
  message = "Getting:\tdefault route"
  command = "netstat -rn |grep default |awk '{print $2}'"
  output  = execute_command(options, message, command)
  if !output.match(/[0-9]/)
    handle_output(options, "Warning:\tNo default route exists")
    if options['test'] != true
      quit(options)
    end
  end
  return
end

# Touch /etc/inet/dhcpd4.conf if it doesn't exist
# If you don't do this it won't actually write to the file

def check_dhcpd4_conf(options)
  if options['host-os-uname'].to_s.match(/SunOS/)
    file="/etc/inet/dhcpd4.conf"
    if options['verbose'] == true
      handle_output(options, "Checking:\t#{file} exists")
    end
    if not File.exist?(file)
      message = "Information:\tCreating "+file
      command = "touch #{file}"
      output  = execute_command(options, message, command)
    else
      bu_file = file+".preai"
      message = "Information:\tArchiving file "+file+" to "+bu_file
      command = "cp #{file} #{bu_file}"
      output  = execute_command(options, message, command)
    end
  end
  return
end

# Create a ZFS file system for base directory if it doesn't exist
# Eg /export/auto_install

def check_ai_base_dir(options)
  if options['verbose'] == true
    handle_output(options, "Checking:\t#{options['aibasedir']}")
  end
  output = check_fs_exists(options, options['aibasedir'])
  return output
end

# Create a ZFS file system for repo directory if it doesn't exist
# Eg /export/repo/11_1 or /export/auto_install/11_1

def check_version_dir(options, dir_name, repo_version)
  full_version_dir = dir_name+repo_version
  handle_output(options, "Checking:\t#{full_version_dir}")
  check_fs_exists(options, full_version_dir)
  return full_version_dir
end

# Check AI service is running

def check_ai_service(options, service_name)
  message = "Information:\tChecking AI service "+service_name
  if options['host-os-uname'].to_s.match(/SunOS/)
    if options['service'].to_s.match(/alt/)
      command = "installadm list |grep '#{service_name}'"
    else
      command = "installadm list |grep '#{service_name}' |grep -v alt"
    end
  else
    command = "ls #{options['baserepodir']} |grep '#{service_name}'"
  end
  output = execute_command(options, message, command)
  return output
end

# Routine to create AI service

def configure_ai_services(options, iso_repo_version)
  handle_output(options, "Information:\tCreating AI services")
  arch_list= []
  if not options['arch'].downcase.match(/i386|sparc/)
    arch_list.append("i386")
    arch_list.append("SPARC")
  else
    arch_list[0] = options['arch']
  end
  message = "Information:\tChecking DHCP server is not in maintenance mode"
  command = "svcs -a |grep dhcp |grep server |grep maintenance"
  output  = execute_command(options, message, command)
  if output.to_s.match(/maintenance/)
    handle_output(options, "Warning:\tDHCP Server is in maintenance mode")
    quit(options)
  end
  arch_list.each do |sys_arch|
    lc_arch = sys_arch.downcase
    ai_dir  = options['aibasedir']+"/"+iso_repo_version+"_"+lc_arch
    service_name = iso_repo_version+"_"+lc_arch
    if options['host-os-uname'].to_s.match(/SunOS/)
      service_check = check_ai_service(options, service_name)
      if not service_check.match(/#{service_name}/)
        message = "Information:\tCreating AI service for #{lc_arch}"
        command = "installadm create-service -a #{lc_arch} -n #{service_name} -p solaris=#{options['publisherurl']} -d #{ai_dir}"
        execute_command(options, message, command)
      end
    else
      service_info    = service_name.split(/_/)
      service_version = service_info[1]
      service_release = service_info[2]
      ai_file = "sol-"+service_version+"_"+service_release+"-ai-"+lc_arch+".iso"
      ai_file = options['isodir']+"/"+ai_file
      if not File.exist?(ai_file)
        handle_output(options, "Warning:\tAI ISO file #{ai_file} not found for architecture #{lc_arch}")
      else
        if options['host-os-uname'].to_s.match(/Darwin/)
          tftp_version_dir = options['tftpdir']+"/"+options['service']
          output = check_osx_iso_mount(tftp_version_dir, ai_options['file'])
          if output.match(/Resource busy/)
            handle_output(options, "Warning:\t ISO already mounted")
            quit(options)
          end
        end
      end
    end
  end
  return
end

# Get repo version directory
# Determine the directory for the repo
# Eg /export/repo/solaris/11/X.X.X

def get_ai_repo_dir(options, iso_repo_version)
  repo_dir = options['baserepodir']+"/"+iso_repo_version
  return repo_dir
end

# Check ZFS filesystem or mount point exists for repo version directory

def check_ai_repo_dir(options)
  dir_list  = options['repodir'].split(/\//)
  check_dir = ""
  dir_list.each do |dir_name|
    check_dir = check_dir+"/"+dir_name
    check_dir = check_dir.gsub(/\/\//, "/")
    if dir_name.match(/[a-z,A-Z,0-9]/)
      check_fs_exists(options, check_dir)
    end
  end
  return
end

# Get a list of the installed AI services

def get_ai_install_services(options)
  message = "Information:\tGetting list of AI services"
  if options['host-os-uname'].to_s.match(/SunOS/)
    command = "installadm list |grep \"^sol_11\" |awk \"{print \\\$1}\""
  else
    command = "ls #{options['baserepodir']} |grep 'sol_11'"
  end
  output = execute_command(options, message, command)
  return output
end

# Code to get Solaris relase from file system under repository

def get_ai_solaris_release(options)
  iso_repo_version = ""
  manifest_dir     = options['repodir']+"/publisher/solaris/pkg/release%2Fname"
  if File.directory?(manifest_dir)
    message      = "Locating:\tRelease file"
    command      = "cat #{manifest_dir}/* |grep release |grep \"^file\" |head -1 |awk \"{print \\\$2}\""
    output       = execute_command(options, message, command)
    release_file = output.chomp
    release_dir  = release_file[0..1]
    release_file = options['repodir']+"publisher/solaris/file/"+release_dir+"/"+release_file
    if File.exist?(release_file)
      message          = "Getting\tRelease information"
      command          = "gzcat #{release_file} |head -1 |awk \"{print \\\$3}\""
      output           = execute_command(options, message, command)
      iso_repo_version = output.chomp.gsub(/\./, "_")
    else
      handle_output(options, "Warning:\tCould not find #{release_file}")
      handle_output(options, "Warning:\tCould not verify solaris release from repository")
      handle_output(options, "Information:\tSetting Solaris release to 11")
      iso_repo_version="11"
    end
  end
  iso_repo_version="sol_"+iso_repo_version
  return iso_repo_version
end

# Fix entry for client so it is given a fixed IP rather than one from the range

def fix_server_dhcpd_range(options)
  copy      = []
  dhcp_file = options['dhcpdfile'].to_s
  check_file_owner(options, dhcp_file, options['uid'])
  dhcpd_range = options['publisherhost'].split(/\./)[0..2]
  dhcpd_range = dhcpd_range.join(".")
  backup_file(options, dhcp_file)
  text        = File.readlines(dhcp_file)
  text.each do |line|
    if line.match(/range #{dhcpd_range}/) and not line.match(/^#/)
      line = "#"+line
      copy.push(line)
    else
      copy.push(line)
    end
  end
  File.open(dhcp_file, "w") {|file| file.puts copy}
  return
end

# Main server routine called from modest main code

def configure_ai_server(options)
  # Enable default package service
  clear_service(options, "svc:/system/install/server:default")
  enable_service(options, "svc:/system/install/server:default")
  iso_list = []
  # Check we have a default route (required for DHCPd to start)
  check_default_route(options)
  # Check that we have a DHCPd config file to write to
  check_dhcpd_config(options)
  check_dhcpd4_conf(options)
  # Get a list of installed services
  services_list = get_ai_install_services(options)
  # If given a service name check the service doesn't already exist
  if options['service'].to_s.match(/[a-z,A-Z]/)
    if services_list.match(/#{options['service']}/)
      handle_output(options, "Warning:\tService #{options['service']} already exists")
      quit(options)
    end
  end
  # Check we have ISO to get repository data from
  if options['file'] != options['empty']
    if options['service'].to_s.match(/[a-z,A-Z]/)
      search_string = options['service'].gsub(/i386|sparc/, "")
      search_string = search_string.gsub(/sol_/, "sol-")
      search_string = search_string.gsub(/_beta/, "-beta")
      search_string = search_string+"-repo"
    else
      search_string = "repo"
    end
    option['search'] = search_string
    iso_list = get_base_dir_list(options)
  else
    iso_list[0] = file_name
  end
  if not iso_list[0]
    handle_output(options, "Warning:\tNo suitable ISOs found")
    quit(options)
  end
  iso_list.each do |file_name|
    if File.exist?(file_name)
      if !file_name.match(/repo/)
        handle_output(options, "Warning:\tISO #{file_name} does not appear to be a valid Solaris distribution")
        quit(options)
      end
    else
      handle_output(options, "Warning:\tISO #{file_name}'' does} not exist")
      quit(options)
    end
    iso_repo_version = File.basename(options['file'], ".iso")
    iso_repo_version = iso_repo_version.split(/-/)[1]
    if file_name.match(/beta/)
      iso_repo_version = "sol_"+iso_repo_version+"_beta"
    else
      iso_repo_version = "sol_"+iso_repo_version
    end
    if !options['service'].to_s.match(/[a-z,A-Z,0-9]/)
      service_base_name = iso_repo_version
    else
      service_base_name = get_service_base_name(options)
    end
    options['repodir'] = get_ai_repo_dir(options, iso_repo_version)
    if !iso_repo_version.match(/11/)
      iso_repo_version = get_ai_solaris_release(options)
    end
    test_dir = options['repodir']+"/publisher"
    if !File.directory?(test_dir)
      check_ai_repo_dir(options)
      mount_iso(options)
      copy_iso(options)
    end
    check_ai_base_dir(options)
    read_only = "true"
    options   = check_ai_publisherport(options)
    configure_ai_pkg_repo(options, read_only)
    if $altrepo_mode == true
      alt_install_service = check_alt_install_service(options)
      configure_ai_alt_pkg_repo(options, alt_install_service)
    end
    options = get_ai_publisherurl(options)
    configure_ai_services(options, iso_repo_version)
    configure_ai_client_services(options, service_base_name)
  end
  fix_server_dhcpd_range(options)
end

# List AI services

def list_ai_services(options)
  if options['host-os-uname'].to_s.match(/SunOS/) and options['host-os-version'].to_i > 10
    options['method'] = "ai"
    message = "AI Services:"
    command = "installadm list |grep auto_install |grep -v default |awk \"{print \\\$1}\""
    output  = execute_command(options, message, command)
    handle_output(options ,message)
    handle_output(options, output)
  end
  return
end
