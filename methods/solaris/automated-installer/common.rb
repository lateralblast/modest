
# Common routines for server and client configuration

# Get the running repository version
# If running in test mode use a default version so client creation
# code can be tested

def get_ai_repo_version(values)
  values = get_ai_publisherurl(values)
  if values['test'] == true || values['host-os-uname'].to_s.match(/Darwin/)
    version  = "0.175.1"
  else
    message = "Information:\tDetermining if available repository version from "+values['publisherurl']
    command = "pkg info -g #{values['publisherurl']} entire |grep Branch |awk \"{print \\\$2}\""
    version = execute_command(values, message, command)
    version = version.chomp
    version = version.split(/\./)[0..2].join(".")
  end
  return version
end

# Check the publisher port isn't being used

def check_ai_publisherport(values)
  message = "Information:\tDetermining if publisher port "+values['publisherport']+" is in use"
  command = "svcprop -a pkg/server |grep \"port count\" |grep -v #{values['service']}"
  in_use  = execute_command(values, message, command)
  if in_use.match(/#{values['publisherport']}/)
    if values['verbose'] == true
      handle_output(values, "Warning:\tPublisher port #{values['publisherport']} is in use")
      handle_output(values, "Information:\tFinding free publisher port")
    end
  end
  while in_use.match(/#{values['publisherport']}/)
    values['publisherport'] = values['publisherport'].to_i+1
    values['publisherport'] = values['publisherport'].to_s
  end
  if values['verbose'] == true
    handle_output(values, "Information: Setting publisher port to #{values['publisherport']}")
  end
  return values
end

# Get publisher port for service

def get_ai_publisherport(values)
  message = "Information:\tDetermining publisher port for service "+values['service']
  command = "svcprop -a pkg/server |grep 'port count'"
  in_use  = execute_command(values, message, command)
  return in_use
end

# Get the repository URL

def get_ai_repo_url(values)
  repo_ver = get_ai_repo_version(values)
  repo_url = "pkg:/entire@0.5.11-"+repo_ver
  return repo_url
end

# Get the publisher URL
# If running in test mode use the default Oracle one

def get_ai_publisherurl(values)
  values['publisherurl'] = "http://"+values['publisherhost']+":"+values['publisherport']
  return values
end

# Get alternate publisher url

def get_ai_alt_publisher_url(values)
  values['publisherport'] = values['publisherport'].to_i+1
  values['publisherport'] = values['publisherport'].to_s
  values['publisherurl']  = "http://"+values['publisherhost']+":"+values['publisherport']
  return values
end

# Get service base name

def get_ai_service_base_name(values)
  service_base_name = values['service']
  if service_base_name.match(/i386|sparc/)
    service_base_name = service_base_name.gsub(/i386/, "")
    service_base_name = service_base_name.gsub(/sparc/, "")
    service_base_name = service_base_name.gsub(/_$/, "")
  end
  return service_base_name
end

# Configure a package repository

def configure_ai_pkg_repo(values, read_only)
  service_base_name = get_ai_service_base_name(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    smf_name = "pkg/server:#{service_base_name}"
    message  = "Information:\tChecking if service "+smf_name+" exists"
    if values['service'].to_s.match(/alt/)
      command = "svcs -a |grep '#{smf_name}"
    else
      command = "svcs -a |grep '#{smf_name} |grep -v alt"
    end
    output = execute_command(values, message, command)
    if not output.match(/#{smf_name}/)
      message  = ""
      commands = []
      commands.push("svccfg -s pkg/server add #{values['service']}")
      commands.push("svccfg -s #{smf_name} addpg pkg application")
      commands.push("svccfg -s #{smf_name} setprop pkg/port=#{values['publisherport']}")
      commands.push("svccfg -s #{smf_name} setprop pkg/inst_root=#{values['repodir']}")
      commands.push("svccfg -s #{smf_name} addpg general framework")
      commands.push("svccfg -s #{smf_name} addpropvalue general/complete astring: #{values['service']}")
      commands.push("svccfg -s #{smf_name} setprop pkg/readonly=#{read_only}")
      commands.push("svccfg -s #{smf_name} setprop pkg/proxy_base = astring: http://#{values['publisherhost']}/#{values['service']}")
      commands.push("svccfg -s #{smf_name} addpropvalue general/enabled boolean: true")
      commands.each do |temp_command|
        execute_command(values, message, temp_command)
      end
      refresh_smf_service(values, smf_name)
      add_apache_proxy(values, service_base_name)
    end
  end
  return
end

# Delete a package repository

def unconfigure_ai_pkg_repo(values, smf_install_service)
  service = smf_install_service.split(":")[1]
  if values['host-os-uname'].to_s.match(/SunOS/)
    message  = "Information:\tChecking if repository service "+smf_install_service+" exists"
    if smf_install_service.match(/alt/)
      command  = "svcs -a |grep '#{smf_install_service}'"
    else
      command  = "svcs -a |grep '#{smf_install_service}' |grep -v alt"
    end
    output = execute_command(values, message, command)
    if output.match(/#{smf_install_service}/)
      disable_smf_service(smf_install_service)
      message = "Removing\tPackage repository service "+smf_install_service
      command = "svccfg -s pkg/server delete #{smf_install_service}"
      execute_command(values, message, command)
      service_base_name = get_ai_service_base_name(values)
      remove_apache_proxy(values, service_base_name)
    end
  end
  return
end

# List available ISOs

def list_ai_isos(values)
  values['search'] = "sol-11"
  iso_list = get_base_dir_list(values)
  if iso_list.length > 0
    if values['output'].to_s.match(/html/)
      handle_output(values, "<h1>Available AI ISOs:</h1>")
      handle_output(values, "<table border=\"1\">")
      handle_output(values, "<tr>")
      handle_output(values, "<th>ISO file</th>")
      handle_output(values, "<th>Distribution</th>")
      handle_output(values, "<th>Version</th>")
      handle_output(values, "<th>Architecture</th>")
      handle_output(values, "<th>Service Name</th>")
      handle_output(values, "</tr>")
    else
      handle_output(values, "Available AI ISOs:")
    end
    handle_output(values, "")
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
      repodir = values['baserepodir']+"/"+service
      if values['output'].to_s.match(/html/)
        handle_output(values, "<tr>")
        handle_output(values, "<td>#{file_name}</td>")
        handle_output(values, "<td>Solaris 11</td>")
        handle_output(values, "<td>#{iso_version.gsub(/_/,'.')}</td>")
        if values['file'].to_s.match(/repo/)
          handle_output(values, "<td>sparc and x86</td>")
        else
          handle_output(values, "<td>#{iso_arch}</td>")
        end
        if File.directory?(repodir)
          handle_output(values, "<td>#{service} (exists)</td>")
        else
          handle_output(values, "<td>#{service}</td>")
        end
        handle_output(values, "</tr>")
      else
        handle_output(values, "ISO file:\t#{values['file']}")
        handle_output(values, "Distribution:\tSolaris 11")
        handle_output(values, "Version:\t#{iso_version.gsub(/_/,'.')}")
        if values['file'].to_s.match(/repo/)
          handle_output(values, "Architecture:\tsparc and x86")
        else
          handle_output(values, "Architecture:\t#{iso_arch}")
        end
        if File.directory?(values['repodir'])
          handle_output(values, "Service Name:\t#{service} (exists)")
        else
          handle_output(values, "Service Name:\t#{service}")
        end
        handle_output(values, "")
      end
    end
    if values['output'].to_s.match(/html/)
      handle_output(values, "</table>")
    end
  end
  return
end
