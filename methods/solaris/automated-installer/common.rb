# frozen_string_literal: true

# Common routines for server and client configuration

# Get the running repository version
# If running in test mode use a default version so client creation
# code can be tested

def get_ai_repo_version(values)
  values = get_ai_publisherurl(values)
  if values['dryrun'] == true || values['host-os-uname'].to_s.match(/Darwin/)
    version = '0.175.1'
  else
    message = "Information:\tDetermining if available repository version from #{values['publisherurl']}"
    command = "pkg info -g #{values['publisherurl']} entire |grep Branch |awk \"{print \\\$2}\""
    version = execute_command(values, message, command)
    version = version.chomp
    version = version.split(/\./)[0..2].join('.')
  end
  version
end

# Check the publisher port isn't being used

def check_ai_publisherport(values)
  message = "Information:\tDetermining if publisher port #{values['publisherport']} is in use"
  command = "svcprop -a pkg/server |grep \"port count\" |grep -v #{values['service']}"
  in_use  = execute_command(values, message, command)
  if in_use.match(/#{values['publisherport']}/) && (values['verbose'] == true)
    warning_message(values, "Publisher port #{values['publisherport']} is in use")
    information_message(values, 'Finding free publisher port')
  end
  while in_use.match(/#{values['publisherport']}/)
    values['publisherport'] = values['publisherport'].to_i + 1
    values['publisherport'] = values['publisherport'].to_s
  end
  verbose_message(values, "Information: Setting publisher port to #{values['publisherport']}") if values['verbose'] == true
  values
end

# Get publisher port for service

def get_ai_publisherport(values)
  message = "Information:\tDetermining publisher port for service #{values['service']}"
  command = "svcprop -a pkg/server |grep 'port count'"
  execute_command(values, message, command)
end

# Get the repository URL

def get_ai_repo_url(values)
  repo_ver = get_ai_repo_version(values)
  "pkg:/entire@0.5.11-#{repo_ver}"
end

# Get the publisher URL
# If running in test mode use the default Oracle one

def get_ai_publisherurl(values)
  values['publisherurl'] = "http://#{values['publisherhost']}:#{values['publisherport']}"
  values
end

# Get alternate publisher url

def get_ai_alt_publisher_url(values)
  values['publisherport'] = values['publisherport'].to_i + 1
  values['publisherport'] = values['publisherport'].to_s
  values['publisherurl']  = "http://#{values['publisherhost']}:#{values['publisherport']}"
  values
end

# Get service base name

def get_ai_service_base_name(values)
  service_base_name = values['service']
  if service_base_name.match(/i386|sparc/)
    service_base_name = service_base_name.gsub(/i386/, '')
    service_base_name = service_base_name.gsub(/sparc/, '')
    service_base_name = service_base_name.gsub(/_$/, '')
  end
  service_base_name
end

# Configure a package repository

def configure_ai_pkg_repo(values, read_only)
  service_base_name = get_ai_service_base_name(values)
  if values['host-os-uname'].to_s.match(/SunOS/)
    smf_name = "pkg/server:#{service_base_name}"
    message  = "Information:\tChecking if service #{smf_name} exists"
    command = if values['service'].to_s.match(/alt/)
                "svcs -a |grep '#{smf_name}"
              else
                "svcs -a |grep '#{smf_name} |grep -v alt"
              end
    output = execute_command(values, message, command)
    unless output.match(/#{smf_name}/)
      message  = ''
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
  nil
end

# Delete a package repository

def unconfigure_ai_pkg_repo(values, smf_install_service)
  smf_install_service.split(':')[1]
  if values['host-os-uname'].to_s.match(/SunOS/)
    message = "Information:\tChecking if repository service #{smf_install_service} exists"
    command = if smf_install_service.match(/alt/)
                "svcs -a |grep '#{smf_install_service}'"
              else
                "svcs -a |grep '#{smf_install_service}' |grep -v alt"
              end
    output = execute_command(values, message, command)
    if output.match(/#{smf_install_service}/)
      disable_smf_service(smf_install_service)
      message = "Removing\tPackage repository service #{smf_install_service}"
      command = "svccfg -s pkg/server delete #{smf_install_service}"
      execute_command(values, message, command)
      service_base_name = get_ai_service_base_name(values)
      remove_apache_proxy(values, service_base_name)
    end
  end
  nil
end

# List available ISOs

def list_ai_isos(values)
  values['search'] = 'sol-11'
  iso_list = get_base_dir_list(values)
  if iso_list.length.positive?
    if values['output'].to_s.match(/html/)
      verbose_message(values, '<h1>Available AI ISOs:</h1>')
      verbose_message(values, '<table border="1">')
      verbose_message(values, '<tr>')
      verbose_message(values, '<th>ISO file</th>')
      verbose_message(values, '<th>Distribution</th>')
      verbose_message(values, '<th>Version</th>')
      verbose_message(values, '<th>Architecture</th>')
      verbose_message(values, '<th>Service Name</th>')
      verbose_message(values, '</tr>')
    else
      verbose_message(values, 'Available AI ISOs:')
    end
    verbose_message(values, '')
    iso_list.each do |file_name|
      file_name = file_namechomp
      iso_info = File.basename(file_name, '.iso')
      iso_info = iso_info.split(/-/)
      iso_arch = iso_info[3]
      iso_version = if file_name.match(/beta/)
                      "#{iso_info[1]}_beta"
                    else
                      iso_info[1]
                    end
      service = "sol_#{iso_version}"
      repodir = "#{values['baserepodir']}/#{service}"
      if values['output'].to_s.match(/html/)
        verbose_message(values, '<tr>')
        verbose_message(values, "<td>#{file_name}</td>")
        verbose_message(values, '<td>Solaris 11</td>')
        verbose_message(values, "<td>#{iso_version.gsub(/_/, '.')}</td>")
        if values['file'].to_s.match(/repo/)
          verbose_message(values, '<td>sparc and x86</td>')
        else
          verbose_message(values, "<td>#{iso_arch}</td>")
        end
        if File.directory?(repodir)
          verbose_message(values, "<td>#{service} (exists)</td>")
        else
          verbose_message(values, "<td>#{service}</td>")
        end
        verbose_message(values, '</tr>')
      else
        verbose_message(values, "ISO file:\t#{values['file']}")
        verbose_message(values, "Distribution:\tSolaris 11")
        verbose_message(values, "Version:\t#{iso_version.gsub(/_/, '.')}")
        if values['file'].to_s.match(/repo/)
          verbose_message(values, "Architecture:\tsparc and x86")
        else
          verbose_message(values, "Architecture:\t#{iso_arch}")
        end
        if File.directory?(values['repodir'])
          verbose_message(values, "Service Name:\t#{service} (exists)")
        else
          verbose_message(values, "Service Name:\t#{service}")
        end
        verbose_message(values, '')
      end
    end
    verbose_message(values, '</table>') if values['output'].to_s.match(/html/)
  end
  nil
end
