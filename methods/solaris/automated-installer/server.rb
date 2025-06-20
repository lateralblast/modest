# frozen_string_literal: true

# AI server code

# Delecte a service
# This will also delete all the clients under it

def unconfigure_ai_server(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    service_base_name   = get_service_base_name(values['service'])
    smf_install_service = "svc:/application/pkg/server:#{service_base_name}"
    smf_service_test    = `svcs -a |grep "#{smf_install_service}'`
    unconfigure_ai_pkg_repo(smf_install_service) if smf_service_test.match(/pkg/)
    if !values['service'].to_s.match(/i386|sparc/)
      ['i386", "sparc'].each do |sys_arch|
        service_test = `installadm list |grep #{values['service']} |grep #{sys_arch}`
        next unless service_test.match(/[a-z,A-Z,0-9]/)

        message = "Information:\tDeleting service #{values['service']}_#{sys_arch} and all clients under it"
        command = "installadm delete-service #{values['service']}_#{sys_arch} -r -y"
        execute_command(values, message, command)
      end
    else
      service_test = `installadm list |grep #{values['service']}`
      if service_test.match(/[a-z,A-Z,0-9]/)
        message = "Information:\tDeleting service #{values['service']} and all clients under it"
        command = "installadm delete-service #{values['service']} -r -y"
        execute_command(values, message, command)
      end
    end
    file = '/etc/inet/dhcpd4.conf'
    if File.exist?(file)
      bu_file = "#{file}.preai"
      message = "Information:\tRestoring file #{bu_file} to #{file}"
      command = "cp #{bu_file} #{file}"
      execute_command(values, message, command)
      smf_install_service = 'svc:/network/dhcp/server:ipv4'
      refresh_smf_service(smf_install_service)
    end
    remove_apache_proxy(values)
    repo_dir = "#{values['baserepodir']}/#{service_base_name}"
    test_dir = "#{repo_dir}/publisher"
    destroy_zfs_fs(repo_dir) if File.directory?(test_dir) && (values['yes'] == true)
  else
    remove_apache_proxy(values)
  end
  nil
end

# Check we've got a default route
# This is required for DHCPd to start

def check_default_route(values)
  message = "Getting:\tdefault route"
  command = "netstat -rn |grep default |awk '{print $2}'"
  output  = execute_command(values, message, command)
  unless output.match(/[0-9]/)
    warning_message(values, 'No default route exists')
    quit(values) if values['dryrun'] != true
  end
  nil
end

# Touch /etc/inet/dhcpd4.conf if it does not exist
# If you do not do this it will not actually write to the file

def check_dhcpd4_conf(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    file = '/etc/inet/dhcpd4.conf'
    verbose_message(values, "Checking:\t#{file} exists") if values['verbose'] == true
    if !File.exist?(file)
      message = "Information:\tCreating #{file}"
      command = "touch #{file}"
    else
      bu_file = "#{file}.preai"
      message = "Information:\tArchiving file #{file} to #{bu_file}"
      command = "cp #{file} #{bu_file}"
    end
    execute_command(values, message, command)
  end
  nil
end

# Create a ZFS file system for base directory if it does not exist
# Eg /export/auto_install

def check_ai_base_dir(values)
  verbose_message(values, "Checking:\t#{values['aibasedir']}") if values['verbose'] == true
  check_fs_exists(values, values['aibasedir'])
end

# Create a ZFS file system for repo directory if it does not exist
# Eg /export/repo/11_1 or /export/auto_install/11_1

def check_version_dir(values, dir_name, repo_version)
  full_version_dir = dir_name + repo_version
  verbose_message(values, "Checking:\t#{full_version_dir}")
  check_fs_exists(values, full_version_dir)
  full_version_dir
end

# Check AI service is running

def check_ai_service(values, service_name)
  message = "Information:\tChecking AI service #{service_name}"
  command = if values['host-os-uname'].to_s.match(/SunOS/)
              if values['service'].to_s.match(/alt/)
                "installadm list |grep '#{service_name}'"
              else
                "installadm list |grep '#{service_name}' |grep -v alt"
              end
            else
              "ls #{values['baserepodir']} |grep '#{service_name}'"
            end
  execute_command(values, message, command)
end

# Routine to create AI service

def configure_ai_services(values, iso_repo_version)
  information_message(values, 'Creating AI services')
  arch_list = []
  if !values['arch'].downcase.match(/i386|sparc/)
    arch_list.append('i386')
    arch_list.append('SPARC')
  else
    arch_list[0] = values['arch']
  end
  message = "Information:\tChecking DHCP server is not in maintenance mode"
  command = 'svcs -a |grep dhcp |grep server |grep maintenance'
  output  = execute_command(values, message, command)
  if output.to_s.match(/maintenance/)
    warning_message(values, 'DHCP Server is in maintenance mode')
    quit(values)
  end
  arch_list.each do |sys_arch|
    lc_arch = sys_arch.downcase
    ai_dir  = "#{values['aibasedir']}/#{iso_repo_version}_#{lc_arch}"
    service_name = "#{iso_repo_version}_#{lc_arch}"
    if values['host-os-uname'].to_s.match(/SunOS/)
      service_check = check_ai_service(values, service_name)
      unless service_check.match(/#{service_name}/)
        message = "Information:\tCreating AI service for #{lc_arch}"
        command = "installadm create-service -a #{lc_arch} -n #{service_name} -p solaris=#{values['publisherurl']} -d #{ai_dir}"
        execute_command(values, message, command)
      end
    else
      service_info    = service_name.split(/_/)
      service_version = service_info[1]
      service_release = service_info[2]
      ai_file = "sol-#{service_version}_#{service_release}-ai-#{lc_arch}.iso"
      ai_file = "#{values['isodir']}/#{ai_file}"
      if !File.exist?(ai_file)
        warning_message(values, "AI ISO file #{ai_file} not found for architecture #{lc_arch}")
      elsif values['host-os-uname'].to_s.match(/Darwin/)
        tftp_version_dir = "#{values['tftpdir']}/#{values['service']}"
        output = check_osx_iso_mount(tftp_version_dir, ai_values['file'])
        if output.match(/Resource busy/)
          warning_message(values, ' ISO already mounted')
          quit(values)
        end
      end
    end
  end
  nil
end

# Get repo version directory
# Determine the directory for the repo
# Eg /export/repo/solaris/11/X.X.X

def get_ai_repo_dir(values, iso_repo_version)
  "#{values['baserepodir']}/#{iso_repo_version}"
end

# Check ZFS filesystem or mount point exists for repo version directory

def check_ai_repo_dir(values)
  dir_list  = values['repodir'].split(%r{/})
  check_dir = ''
  dir_list.each do |dir_name|
    check_dir = "#{check_dir}/#{dir_name}"
    check_dir = check_dir.gsub(%r{//}, '/')
    check_fs_exists(values, check_dir) if dir_name.match(/[a-z,A-Z,0-9]/)
  end
  nil
end

# Get a list of the installed AI services

def get_ai_install_services(values)
  message = "Information:\tGetting list of AI services"
  command = if values['host-os-uname'].to_s.match(/SunOS/)
              "installadm list |grep \"^sol_11\" |awk \"{print \\\$1}\""
            else
              "ls #{values['baserepodir']} |grep 'sol_11'"
            end
  execute_command(values, message, command)
end

# Code to get Solaris relase from file system under repository

def get_ai_solaris_release(values)
  iso_repo_version = ''
  manifest_dir     = "#{values['repodir']}/publisher/solaris/pkg/release%2Fname"
  if File.directory?(manifest_dir)
    message      = "Locating:\tRelease file"
    command      = "cat #{manifest_dir}/* |grep release |grep \"^file\" |head -1 |awk \"{print \\\$2}\""
    output       = execute_command(values, message, command)
    release_file = output.chomp
    release_dir  = release_file[0..1]
    release_file = "#{values['repodir']}publisher/solaris/file/#{release_dir}/#{release_file}"
    if File.exist?(release_file)
      message          = "Getting\tRelease information"
      command          = "gzcat #{release_file} |head -1 |awk \"{print \\\$3}\""
      output           = execute_command(values, message, command)
      iso_repo_version = output.chomp.gsub(/\./, '_')
    else
      warning_message(values, "Could not find #{release_file}")
      warning_message(values, 'Could not verify solaris release from repository')
      information_message(values, 'Setting Solaris release to 11')
      iso_repo_version = '11'
    end
  end
  "sol_#{iso_repo_version}"
end

# Fix entry for client so it is given a fixed IP rather than one from the range

def fix_server_dhcpd_range(values)
  copy      = []
  dhcp_file = values['dhcpdfile'].to_s
  check_file_owner(values, dhcp_file, values['uid'])
  dhcpd_range = values['publisherhost'].split(/\./)[0..2]
  dhcpd_range = dhcpd_range.join('.')
  backup_file(values, dhcp_file)
  text = File.readlines(dhcp_file)
  text.each do |line|
    line = "##{line}" if line.match(/range #{dhcpd_range}/) && !line.match(/^#/)
    copy.push(line)
  end
  File.open(dhcp_file, 'w') { |file| file.puts copy }
  nil
end

# Main server routine called from modest main code

def configure_ai_server(values)
  # Enable default package service
  clear_service(values, 'svc:/system/install/server:default')
  enable_service(values, 'svc:/system/install/server:default')
  iso_list = []
  # Check we have a default route (required for DHCPd to start)
  check_default_route(values)
  # Check that we have a DHCPd config file to write to
  check_dhcpd_config(values)
  check_dhcpd4_conf(values)
  # Get a list of installed services
  services_list = get_ai_install_services(values)
  # If given a service name check the service does not already exist
  if values['service'].to_s.match(/[a-z,A-Z]/) && services_list.match(/#{values['service']}/)
    warning_message(values, "Service #{values['service']} already exists")
    quit(values)
  end
  # Check we have ISO to get repository data from
  if values['file'] != values['empty']
    if values['service'].to_s.match(/[a-z,A-Z]/)
      search_string = values['service'].gsub(/i386|sparc/, '')
      search_string = search_string.gsub(/sol_/, 'sol-')
      search_string = search_string.gsub(/_beta/, '-beta')
      search_string += '-repo'
    else
      search_string = 'repo'
    end
    option['search'] = search_string
    iso_list = get_base_dir_list(values)
  else
    iso_list[0] = file_name
  end
  unless iso_list[0]
    warning_message(values, 'No suitable ISOs found')
    quit(values)
  end
  iso_list.each do |file_name|
    if File.exist?(file_name)
      unless file_name.match(/repo/)
        warning_message(values, "ISO #{file_name} does not appear to be a valid Solaris distribution")
        quit(values)
      end
    else
      warning_message(values, "ISO #{file_name}'' does} not exist")
      quit(values)
    end
    iso_repo_version = File.basename(values['file'], '.iso')
    iso_repo_version = iso_repo_version.split(/-/)[1]
    iso_repo_version = if file_name.match(/beta/)
                         "sol_#{iso_repo_version}_beta"
                       else
                         "sol_#{iso_repo_version}"
                       end
    service_base_name = if !values['service'].to_s.match(/[a-z,A-Z,0-9]/)
                          iso_repo_version
                        else
                          get_service_base_name(values)
                        end
    values['repodir'] = get_ai_repo_dir(values, iso_repo_version)
    iso_repo_version = get_ai_solaris_release(values) unless iso_repo_version.match(/11/)
    test_dir = "#{values['repodir']}/publisher"
    unless File.directory?(test_dir)
      check_ai_repo_dir(values)
      mount_iso(values)
      copy_iso(values)
    end
    check_ai_base_dir(values)
    read_only = 'true'
    values = check_ai_publisherport(values)
    configure_ai_pkg_repo(values, read_only)
    if $altrepo_mode == true
      alt_install_service = check_alt_install_service(values)
      configure_ai_alt_pkg_repo(values, alt_install_service)
    end
    values = get_ai_publisherurl(values)
    configure_ai_services(values, iso_repo_version)
    configure_ai_client_services(values, service_base_name)
  end
  fix_server_dhcpd_range(values)
end

# List AI services

def list_ai_services(values)
  if values['host-os-uname'].to_s.match(/SunOS/) && (values['host-os-version'].to_i > 10)
    values['method'] = 'ai'
    message = 'AI Services:'
    command = "installadm list |grep auto_install |grep -v default |awk \"{print \\\$1}\""
    output  = execute_command(values, message, command)
    verbose_message(values, message)
    verbose_message(values, output)
  end
  nil
end
