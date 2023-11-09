
# Clienbt code for AI

# List AI services

def list_ai_clients(options)
  message = "Information:\tAvailable AI clients"
  command = "installadm list -p |grep -v '^--' |grep -v '^Service'"
  output  = execute_command(options, message, command)
  client_info = output.split(/\n/)
  if client_info.length > 0
    if options['output'].to_s.match(/html/)
      handle_output(options, "<h1>Available AI clients:</h1>")
      handle_output(options, "<table border=\"1\">")
      handle_output(options, "<tr>")
      handle_output(options, "<th>Client</th>")
      handle_output(options, "<th>Service</th>")
      handle_output(options, "</tr>")
    else
      handle_output(options, "")
      handle_output(options, "Available AI clients:")
      handle_output(options, "")
    end
    service = ""
    client  = ""
    client_info.each do |line|
      if line.match(/^[a-z,A-Z]/)
        service = line
      else
        client = line
        client = client.gsub(/^\s+/, "")
        client = client.gsub(/\s+/, " ")
        if options['output'].to_s.match(/html/)
          handle_output(options, "<tr>")
          handle_output(options, "<td>#{client}</td>")
          handle_output(options, "<td>#{service}</td>")
          handle_output(options, "</tr>")
        else
          handle_output(options, "#{client} [ service = #{service} ]")
        end
      end
    end
    if options['output'].to_s.match(/html/)
      handle_output(options, "</table>")
    end
  end
  handle_output(options, "")
  return
end

# Get a list of valid shells

def get_valid_shells()
  vaild_shells = %x[ls /usr/bin |grep 'sh$' |awk '{print "/usr/bin/" $1 }']
  vaild_shells = vaild_shells.split("\n").join(",")
  return vaild_shells
end

# Make sure user ID is greater than 100

def check_valid_uid(options, answer)
  correct = 1
  if answer.match(/[a-z,A-Z]/)
    correct = 0
  else
    if Integer(answer) < 100
      correct = 0
      handle_output(options, "UID must be greater than 100")
    end
  end
  return correct
end

# Make sure user group is greater than 10

def check_valid_gid(options, answer)
  correct = 1
  if answer.match(/[a-z,A-Z]/)
    correct = 0
  else
    if Integer(answer) < 10
      correct = 0
      handle_output(options, "GID must be greater than 10")
    end
  end
  return correct
end

# Get the user home directory ZFS dataset name

def get_account_home_zfs_dataset()
  account_home_zfs_dataset = "/export/home/"+options['q_struct']['account_login'].value
  return account_home_zfs_dataset
end

# Get the user home directory mount point

def get_account_home_mountpoint()
  account_home_mountpoint = "/export/home/"+options['q_struct']['account_login'].value
  return account_home_mountpoint
end

# Import AI manifest
# This is done to change the default manifest so that it doesn't point
# to the Oracle one amongst other things
# Check the structs for settings and more information

def import_ai_manifest(output_file, options)
  date_string = get_date_string(options)
  arch_list   = []
  base_name   = get_service_base_name(options)
  if !options['service'].to_s.match(/i386|sparc/) && !options['arch'].to_s.match(/i386|sparc/)
    arch_list = ['i386", "SPARC']
  else
    if options['service'].to_s.match(/i386/)
      arch_list.push("i386")
    else
      if options['service'].to_s.match(/sparc/)
        arch_list.push("SPARC")
      end
    end
  end
  arch_list.each do |sys_arch|
    lc_arch = sys_arch.downcase
    backup  = options['workdir'].to_s+"/"+base_name+"_"+lc_arch+"_orig_default.xml."+date_string
    message = "Information:\tArchiving service configuration for "+base_name+"_"+lc_arch+" to "+backup
    command = "installadm export -n #{base_name}_#{lc_arch} -m orig_default > #{backup}"
    output  = execute_command(options, message, command)
    message = "Information:\tValidating service configuration "+output_file
    command = "AIM_MANIFEST=#{output_file} ; export AIM_MANIFEST ; aimanifest validate"
    output  = execute_command(options, message, command)
    if output.match(/[a-z,A-Z,0-9]/)
      handle_output(options, "AI manifest file #{output_file} does not contain a valid XML manifest")
      handle_output(options, output)
    else
      message = "Information:\tImporting "+output_file+" to service "+options['service'].to_s+" as manifest named "+options['manifest'].to_s
      command = "installadm create-manifest -n #{base_name}_#{lc_arch} -m #{options['manifest'].to_s} -f #{output_file}"
      output  = execute_command(options, message, command)
      message = "Information:\tSetting default manifest for service "+options['service'].to_s+" to "+options['manifest'].to_s
      command = "installadm set-service -o default-manifest=#{options['manifest'].to_s} #{base_name}_#{lc_arch}"
      output  = execute_command(options, message, command)
    end
  end
  return
end

# Import a profile and associate it with a client

def import_ai_client_profile(options, output_file)
  message = "Information:\tCreating profile for client "+options['name']+" with MAC address "+options['mac']
  command = "installadm create-profile -n #{options['service']} -f #{output_file} -p #{options['name']} -c mac='#{options['mac']}'"
  execute_command(options, message, command)
  return
end

# Code to change timeout and default menu entry in grub

def update_ai_client_grub_cfg(options)
  copy        = []
  netboot_mac = options['mac'].gsub(/:/, "")
  netboot_mac = "01"+netboot_mac
  netboot_mac = netboot_mac.upcase
  grub_file   = options['tftpdir']+"/grub.cfg."+netboot_mac
  if options['verbose'] == true
    handle_output(options, "Updating:\tGrub config file #{grub_file}")
  end
  if File.exist?(grub_file)
    text=File.read(grub_file)
    text.each do |line|
      if line.match(/set timeout=30/)
        copy.push("set timeout=5")
        copy.push("set default=1")
      else
        copy.push(line)
      end
    end
    File.open(grub_file, "w") {|file| file.puts copy}
    print_contents_of_file(options, "", grub_file)
  end
end

# Main code to configure AI client services
# Called from main code

def configure_ai_client_services(options, service_base_name)
  handle_output(options, "")
  handle_output(options, "You will be presented with a set of questions followed by the default output")
  handle_output(options, "If you are happy with the default output simply hit enter")
  handle_output(options, "")
  service_list = []
  # Populate questions for AI manifest
  populate_ai_manifest_questions(options)
  # Process questions
  process_questions(options)
  # Set name of AI manifest file to create and import
  if service_base_name.to_s.match(/i386|sparc/)
    service_list[0] = get_service_base_name
  else
    service_list[0] = service_base_name+"_i386"
    service_list[1] = service_base_name+"_sparc"
  end
  service_list.each do |temp_name|
    output_file = options['workdir']+"/"+temp_name+"_ai_manifest.xml"
    # Create manifest
    create_ai_manifest(options, output_file)
    # Import AI manifest
    import_ai_manifest(output_file, temp_name)
  end
  return
end

# Fix entry for client so it is given a fixed IP rather than one from the range

def update_ai_client_dhcpd_entry(options)
  copy = []
  text = File.readlines(dhcpd_file)
  options['ip']  = single_install_ip(options)
  options['mac'] = options['mac'].to_s.gsub(/:/, "")
  options['mac'] = options['mac'].to_s.upcase
  dhcpd_file     = "/etc/inet/dhcpd4.conf"
  backup_file(options, dhcpd_file)
  text.each do |line|
    if line.match(/^host #{options['mac']}/)
      copy.push("host #{options['name']} {")
      copy.push("  fixed-address #{options['ip']};")
    else
      copy.push(line)
    end
  end
  File.open(dhcp_file, "w") {|file| file.puts copy}
  print_contents_of_file(options, "", dhcp_file)
  return
end

# Routine to actually add a client

def create_ai_client(options)
  options['ip'] = single_install_ip(options)
  message    = "Information:\tCreating client entry for #{options['name']} with architecture #{options['arch']} and MAC address #{options['mac']}"
  command    = "installadm create-client -n #{options['service']} -e #{options['mac']}"
   execute_command(options, message, command)
  if options['arch'].to_s.match(/i386/) || options['arch'].to_s.match(/i386/)
    update_ai_client_dhcpd_entry(options)
    update_ai_client_grub_cfg(options)
  else
   add_dhcp_client(options)
  end
  smf_service = "svc:/network/dhcp/server:ipv4"
  refresh_smf_service(options, smf_service)
  return
end

# Check AI client doesn't exist

def check_ai_client_doesnt_exist(options)
  options['mac'] = options['mac'].upcase
  message = "Information:\tChecking client "+options['name']+" doesn't exist"
  command = "installadm list -p |grep '#{options['mac']}'"
  output  = execute_command(options, message, command)
  if output.match(/#{options['name']}/)
    handle_output(options, "Warning:\tProfile already exists for #{options['name']}")
    if options['yes'] == true
      handle_output(options, "Deleting:\rtClient #{options['name']}")
      unconfigure_ai_client(options)
    else
      quit(options)
    end
  end
  return
end

# Main code to actually add a client

def configure_ai_client(options)
  # Populate questions for AI profile
  if not options['service'].to_s.match(/i386|sparc/)
    options['service'] = options['service']+"_"+options['arch']
  end
  options['ip'] = single_install_ip(options)
  check_ai_client_doesnt_exist(options)
  populate_ai_client_profile_questions(options)
  process_questions(options)
  if options['host-os-name'].to_s.match(/Darwin/)
    tftp_version_dir = options['tftpdir']+"/"+options['service']
    check_osx_iso_mount(tftp_version_dir, options['file'])
  end
  output_file = options['workdir']+"/"+options['name']+"_ai_profile.xml"
  create_ai_client_profile(options, output_file)
  handle_output(options, "Configuring:\tClient #{options['name']} with MAC address #{options['mac']}")
  import_ai_client_profile(options, output_file)
  create_ai_client(options)
  if options['host-os-name'].to_s.match(/SunOS/) and options['host-os-release'].match(/11/)
    clear_solaris_dhcpd(options)
  end
  return
end

# Unconfigure  AI client

def unconfigure_ai_client(options)
  if not options['mac'].to_s.match(/[a-z,A-Z,0-9]/) or not options['service'].to_s.match(/[a-z,A-Z,0-9]/)
    repo_list = %x[installadm list -p |grep -v '^-' |grep -v '^Service']
    temp_name = ""
    temp_mac  = ""
    temp_service = ""
    repo_list.each do |line|
      line = line.chomp
      if line.match(/[a-z,A-Z,0-9]/)
        if line.match(/^[a-z,A-Z,0-9]/)
          line = line.gsub(/\s+/,"")
          temp_service = line
        else
          line = line.gsub(/\s+/, "")
          if line.match(/mac=/)
            (temp_name, temp_mac) = line.split(/mac=/)
            if temp_name.to_s.match(/^#{options['name']}/)
              if not options['service'].to_s.match(/[a-z,A-Z,0-9]/)
                options['service'] = temp_service
              end
              if not options['mac'].to_s.match(/[a-z,A-Z,0-9]/)
                options['mac'] = temp_mac
              end
            end
          end
        end
      end
    end
  end
  if options['name'].to_s.match(/[a-z,A-Z]/) 
    if options['service'].to_s.match(/[a-z,A-Z]/) 
      message = "Information:\tDeleting client profile "+options['name']+" from "+options['service']
      command = "installadm delete-profile -p #{options['name']} -n #{options['service']}"
      execute_command(options, message, command)
    else
      if options['mac'].to_s.match(/[0-9]/)
        message = "Information:\tDeleting client "+options['name']+" with from service "+options['service']
        command = "installadm delete-client "+options['mac']
        execute_command(options, message, command)
      end
    end
  else
    handle_output(options, "Warning:\tService name not given for #{options['name']}")
    quit(options)
  end
  return
end
