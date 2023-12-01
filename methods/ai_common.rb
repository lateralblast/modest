
# Common routines for server and client configuration

# Get the running repository version
# If running in test mode use a default version so client creation
# code can be tested

def get_ai_repo_version(options)
  options = get_ai_publisherurl(options)
  if options['test'] == true || options['host-os-uname'].to_s.match(/Darwin/)
    version  = "0.175.1"
  else
    message = "Information:\tDetermining if available repository version from "+options['publisherurl']
    command = "pkg info -g #{options['publisherurl']} entire |grep Branch |awk \"{print \\\$2}\""
    version = execute_command(options, message, command)
    version = version.chomp
    version = version.split(/\./)[0..2].join(".")
  end
  return version
end

# Check the publisher port isn't being used

def check_ai_publisherport(options)
  message = "Information:\tDetermining if publisher port "+options['publisherport']+" is in use"
  command = "svcprop -a pkg/server |grep \"port count\" |grep -v #{options['service']}"
  in_use  = execute_command(options, message, command)
  if in_use.match(/#{options['publisherport']}/)
    if options['verbose'] == true
      handle_output(options, "Warning:\tPublisher port #{options['publisherport']} is in use")
      handle_output(options, "Information:\tFinding free publisher port")
    end
  end
  while in_use.match(/#{options['publisherport']}/)
    options['publisherport'] = options['publisherport'].to_i+1
    options['publisherport'] = options['publisherport'].to_s
  end
  if options['verbose'] == true
    handle_output(options, "Information: Setting publisher port to #{options['publisherport']}")
  end
  return options
end

# Get publisher port for service

def get_ai_publisherport(options)
  message = "Information:\tDetermining publisher port for service "+options['service']
  command = "svcprop -a pkg/server |grep 'port count'"
  in_use  = execute_command(options, message, command)
  return in_use
end

# Get the repository URL

def get_ai_repo_url(options)
  repo_ver = get_ai_repo_version(options)
  repo_url = "pkg:/entire@0.5.11-"+repo_ver
  return repo_url
end

# Get the publisher URL
# If running in test mode use the default Oracle one

def get_ai_publisherurl(options)
  options['publisherurl'] = "http://"+options['publisherhost']+":"+options['publisherport']
  return options
end

# Get alternate publisher url

def get_ai_alt_publisher_url(options)
  options['publisherport'] = options['publisherport'].to_i+1
  options['publisherport'] = options['publisherport'].to_s
  options['publisherurl']  = "http://"+options['publisherhost']+":"+options['publisherport']
  return options
end

# Get service base name

def get_ai_service_base_name(options)
  service_base_name = options['service']
  if service_base_name.match(/i386|sparc/)
    service_base_name = service_base_name.gsub(/i386/, "")
    service_base_name = service_base_name.gsub(/sparc/, "")
    service_base_name = service_base_name.gsub(/_$/, "")
  end
  return service_base_name
end

# Configure a package repository

def configure_ai_pkg_repo(options, read_only)
  service_base_name = get_ai_service_base_name(options)
  if options['host-os-uname'].to_s.match(/SunOS/)
    smf_name = "pkg/server:#{service_base_name}"
    message  = "Information:\tChecking if service "+smf_name+" exists"
    if options['service'].to_s.match(/alt/)
      command = "svcs -a |grep '#{smf_name}"
    else
      command = "svcs -a |grep '#{smf_name} |grep -v alt"
    end
    output = execute_command(options, message, command)
    if not output.match(/#{smf_name}/)
      message  = ""
      commands = []
      commands.push("svccfg -s pkg/server add #{options['service']}")
      commands.push("svccfg -s #{smf_name} addpg pkg application")
      commands.push("svccfg -s #{smf_name} setprop pkg/port=#{options['publisherport']}")
      commands.push("svccfg -s #{smf_name} setprop pkg/inst_root=#{options['repodir']}")
      commands.push("svccfg -s #{smf_name} addpg general framework")
      commands.push("svccfg -s #{smf_name} addpropvalue general/complete astring: #{options['service']}")
      commands.push("svccfg -s #{smf_name} setprop pkg/readonly=#{read_only}")
      commands.push("svccfg -s #{smf_name} setprop pkg/proxy_base = astring: http://#{options['publisherhost']}/#{options['service']}")
      commands.push("svccfg -s #{smf_name} addpropvalue general/enabled boolean: true")
      commands.each do |temp_command|
        execute_command(options, message, temp_command)
      end
      refresh_smf_service(options, smf_name)
      add_apache_proxy(options, service_base_name)
    end
  end
  return
end

# Delete a package repository

def unconfigure_ai_pkg_repo(options, smf_install_service)
  service = smf_install_service.split(":")[1]
  if options['host-os-uname'].to_s.match(/SunOS/)
    message  = "Information:\tChecking if repository service "+smf_install_service+" exists"
    if smf_install_service.match(/alt/)
      command  = "svcs -a |grep '#{smf_install_service}'"
    else
      command  = "svcs -a |grep '#{smf_install_service}' |grep -v alt"
    end
    output = execute_command(options, message, command)
    if output.match(/#{smf_install_service}/)
      disable_smf_service(smf_install_service)
      message = "Removing\tPackage repository service "+smf_install_service
      command = "svccfg -s pkg/server delete #{smf_install_service}"
      execute_command(options, message, command)
      service_base_name = get_ai_service_base_name(options)
      remove_apache_proxy(options, service_base_name)
    end
  end
  return
end

# List available ISOs

def list_ai_isos(options)
  options['search'] = "sol-11"
  iso_list = get_base_dir_list(options)
  if iso_list.length > 0
    if options['output'].to_s.match(/html/)
      handle_output(options, "<h1>Available AI ISOs:</h1>")
      handle_output(options, "<table border=\"1\">")
      handle_output(options, "<tr>")
      handle_output(options, "<th>ISO file</th>")
      handle_output(options, "<th>Distribution</th>")
      handle_output(options, "<th>Version</th>")
      handle_output(options, "<th>Architecture</th>")
      handle_output(options, "<th>Service Name</th>")
      handle_output(options, "</tr>")
    else
      handle_output(options, "Available AI ISOs:")
    end
    handle_output(options, "")
    iso_list.each do |file_name|
      file_name = file_namechomp
      iso_info = File.basename(file_name, ".iso")
      iso_info = iso_info.split(/-/)
      iso_arch = iso_info[3]
      if file_name.match(/beta/)
        iso_version = iso_info[1]+"_beta"
      else
        iso_version = iso_info[1]
      end
      service = "sol_"+iso_version
      repodir = options['baserepodir']+"/"+service
      if options['output'].to_s.match(/html/)
        handle_output(options, "<tr>")
        handle_output(options, "<td>#{file_name}</td>")
        handle_output(options, "<td>Solaris 11</td>")
        handle_output(options, "<td>#{iso_version.gsub(/_/,'.')}</td>")
        if options['file'].to_s.match(/repo/)
          handle_output(options, "<td>sparc and x86</td>")
        else
          handle_output(options, "<td>#{iso_arch}</td>")
        end
        if File.directory?(repodir)
          handle_output(options, "<td>#{service} (exists)</td>")
        else
          handle_output(options, "<td>#{service}</td>")
        end
        handle_output(options, "</tr>")
      else
        handle_output(options, "ISO file:\t#{options['file']}")
        handle_output(options, "Distribution:\tSolaris 11")
        handle_output(options, "Version:\t#{iso_version.gsub(/_/,'.')}")
        if options['file'].to_s.match(/repo/)
          handle_output(options, "Architecture:\tsparc and x86")
        else
          handle_output(options, "Architecture:\t#{iso_arch}")
        end
        if File.directory?(options['repodir'])
          handle_output(options, "Service Name:\t#{service} (exists)")
        else
          handle_output(options, "Service Name:\t#{service}")
        end
        handle_output(options, "")
      end
    end
    if options['output'].to_s.match(/html/)
      handle_output(options, "</table>")
    end
  end
  return
end
