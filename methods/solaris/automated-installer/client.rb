
# Clienbt code for AI

# List AI services

def list_ai_clients(values)
  message = "Information:\tAvailable AI clients"
  command = "installadm list -p |grep -v '^--' |grep -v '^Service'"
  output  = execute_command(values, message, command)
  client_info = output.split(/\n/)
  if client_info.length > 0
    if values['output'].to_s.match(/html/)
      verbose_output(values, "<h1>Available AI clients:</h1>")
      verbose_output(values, "<table border=\"1\">")
      verbose_output(values, "<tr>")
      verbose_output(values, "<th>Client</th>")
      verbose_output(values, "<th>Service</th>")
      verbose_output(values, "</tr>")
    else
      verbose_output(values, "")
      verbose_output(values, "Available AI clients:")
      verbose_output(values, "")
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
        if values['output'].to_s.match(/html/)
          verbose_output(values, "<tr>")
          verbose_output(values, "<td>#{client}</td>")
          verbose_output(values, "<td>#{service}</td>")
          verbose_output(values, "</tr>")
        else
          verbose_output(values, "#{client} [ service = #{service} ]")
        end
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_output(values, "</table>")
    end
  end
  verbose_output(values, "")
  return
end

# Get a list of valid shells

def get_valid_shells()
  vaild_shells = %x[ls /usr/bin |grep 'sh$' |awk '{print "/usr/bin/" $1 }']
  vaild_shells = vaild_shells.split("\n").join(",")
  return vaild_shells
end

# Make sure user ID is greater than 100

def check_valid_uid(values, answer)
  correct = 1
  if answer.match(/[a-z,A-Z]/)
    correct = 0
  else
    if Integer(answer) < 100
      correct = 0
      verbose_output(values, "UID must be greater than 100")
    end
  end
  return correct
end

# Make sure user group is greater than 10

def check_valid_gid(values, answer)
  correct = 1
  if answer.match(/[a-z,A-Z]/)
    correct = 0
  else
    if Integer(answer) < 10
      correct = 0
      verbose_output(values, "GID must be greater than 10")
    end
  end
  return correct
end

# Get the user home directory ZFS dataset name

def get_account_home_zfs_dataset()
  account_home_zfs_dataset = "/export/home/"+values['q_struct']['account_login'].value
  return account_home_zfs_dataset
end

# Get the user home directory mount point

def get_account_home_mountpoint()
  account_home_mountpoint = "/export/home/"+values['q_struct']['account_login'].value
  return account_home_mountpoint
end

# Import AI manifest
# This is done to change the default manifest so that it doesn't point
# to the Oracle one amongst other things
# Check the structs for settings and more information

def import_ai_manifest(output_file, values)
  date_string = get_date_string(values)
  arch_list   = []
  base_name   = get_service_base_name(values)
  if !values['service'].to_s.match(/i386|sparc/) && !values['arch'].to_s.match(/i386|sparc/)
    arch_list = ['i386", "SPARC']
  else
    if values['service'].to_s.match(/i386/)
      arch_list.push("i386")
    else
      if values['service'].to_s.match(/sparc/)
        arch_list.push("SPARC")
      end
    end
  end
  arch_list.each do |sys_arch|
    lc_arch = sys_arch.downcase
    backup  = values['workdir'].to_s+"/"+base_name+"_"+lc_arch+"_orig_default.xml."+date_string
    message = "Information:\tArchiving service configuration for "+base_name+"_"+lc_arch+" to "+backup
    command = "installadm export -n #{base_name}_#{lc_arch} -m orig_default > #{backup}"
    output  = execute_command(values, message, command)
    message = "Information:\tValidating service configuration "+output_file
    command = "AIM_MANIFEST=#{output_file} ; export AIM_MANIFEST ; aimanifest validate"
    output  = execute_command(values, message, command)
    if output.match(/[a-z,A-Z,0-9]/)
      verbose_output(values, "AI manifest file #{output_file} does not contain a valid XML manifest")
      verbose_output(values, output)
    else
      message = "Information:\tImporting "+output_file+" to service "+values['service'].to_s+" as manifest named "+values['manifest'].to_s
      command = "installadm create-manifest -n #{base_name}_#{lc_arch} -m #{values['manifest'].to_s} -f #{output_file}"
      output  = execute_command(values, message, command)
      message = "Information:\tSetting default manifest for service "+values['service'].to_s+" to "+values['manifest'].to_s
      command = "installadm set-service -o default-manifest=#{values['manifest'].to_s} #{base_name}_#{lc_arch}"
      output  = execute_command(values, message, command)
    end
  end
  return
end

# Import a profile and associate it with a client

def import_ai_client_profile(values, output_file)
  message = "Information:\tCreating profile for client "+values['name']+" with MAC address "+values['mac']
  command = "installadm create-profile -n #{values['service']} -f #{output_file} -p #{values['name']} -c mac='#{values['mac']}'"
  execute_command(values, message, command)
  return
end

# Code to change timeout and default menu entry in grub

def update_ai_client_grub_cfg(values)
  copy        = []
  netboot_mac = values['mac'].gsub(/:/, "")
  netboot_mac = "01"+netboot_mac
  netboot_mac = netboot_mac.upcase
  grub_file   = values['tftpdir']+"/grub.cfg."+netboot_mac
  if values['verbose'] == true
    verbose_output(values, "Updating:\tGrub config file #{grub_file}")
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
    print_contents_of_file(values, "", grub_file)
  end
end

# Main code to configure AI client services
# Called from main code

def configure_ai_client_services(values, service_base_name)
  verbose_output(values, "")
  verbose_output(values, "You will be presented with a set of questions followed by the default output")
  verbose_output(values, "If you are happy with the default output simply hit enter")
  verbose_output(values, "")
  service_list = []
  # Populate questions for AI manifest
  populate_ai_manifest_questions(values)
  # Process questions
  process_questions(values)
  # Set name of AI manifest file to create and import
  if service_base_name.to_s.match(/i386|sparc/)
    service_list[0] = get_service_base_name
  else
    service_list[0] = service_base_name+"_i386"
    service_list[1] = service_base_name+"_sparc"
  end
  service_list.each do |temp_name|
    output_file = values['workdir']+"/"+temp_name+"_ai_manifest.xml"
    # Create manifest
    create_ai_manifest(values, output_file)
    # Import AI manifest
    import_ai_manifest(output_file, temp_name)
  end
  return
end

# Fix entry for client so it is given a fixed IP rather than one from the range

def update_ai_client_dhcpd_entry(values)
  copy = []
  text = File.readlines(dhcpd_file)
  values['ip']  = single_install_ip(values)
  values['mac'] = values['mac'].to_s.gsub(/:/, "")
  values['mac'] = values['mac'].to_s.upcase
  dhcpd_file     = "/etc/inet/dhcpd4.conf"
  backup_file(values, dhcpd_file)
  text.each do |line|
    if line.match(/^host #{values['mac']}/)
      copy.push("host #{values['name']} {")
      copy.push("  fixed-address #{values['ip']};")
    else
      copy.push(line)
    end
  end
  File.open(dhcp_file, "w") {|file| file.puts copy}
  print_contents_of_file(values, "", dhcp_file)
  return
end

# Routine to actually add a client

def create_ai_client(values)
  values['ip'] = single_install_ip(values)
  message    = "Information:\tCreating client entry for #{values['name']} with architecture #{values['arch']} and MAC address #{values['mac']}"
  command    = "installadm create-client -n #{values['service']} -e #{values['mac']}"
   execute_command(values, message, command)
  if values['arch'].to_s.match(/i386/) || values['arch'].to_s.match(/i386/)
    update_ai_client_dhcpd_entry(values)
    update_ai_client_grub_cfg(values)
  else
   add_dhcp_client(values)
  end
  smf_service = "svc:/network/dhcp/server:ipv4"
  refresh_smf_service(values, smf_service)
  return
end

# Check AI client doesn't exist

def check_ai_client_doesnt_exist(values)
  values['mac'] = values['mac'].upcase
  message = "Information:\tChecking client "+values['name']+" doesn't exist"
  command = "installadm list -p |grep '#{values['mac']}'"
  output  = execute_command(values, message, command)
  if output.match(/#{values['name']}/)
    verbose_output(values, "Warning:\tProfile already exists for #{values['name']}")
    if values['yes'] == true
      verbose_output(values, "Deleting:\rtClient #{values['name']}")
      unconfigure_ai_client(values)
    else
      quit(values)
    end
  end
  return
end

# Main code to actually add a client

def configure_ai_client(values)
  # Populate questions for AI profile
  if not values['service'].to_s.match(/i386|sparc/)
    values['service'] = values['service']+"_"+values['arch']
  end
  values['ip'] = single_install_ip(values)
  check_ai_client_doesnt_exist(values)
  populate_ai_client_profile_questions(values)
  process_questions(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    tftp_version_dir = values['tftpdir']+"/"+values['service']
    check_osx_iso_mount(tftp_version_dir, values['file'])
  end
  output_file = values['workdir']+"/"+values['name']+"_ai_profile.xml"
  create_ai_client_profile(values, output_file)
  verbose_output(values, "Configuring:\tClient #{values['name']} with MAC address #{values['mac']}")
  import_ai_client_profile(values, output_file)
  print_contents_of_file(values, "", output_file)
  create_ai_client(values)
  if values['host-os-uname'].to_s.match(/SunOS/) and values['host-os-unamer'].match(/11/)
    clear_solaris_dhcpd(values)
  end
  return
end

# Unconfigure  AI client

def unconfigure_ai_client(values)
  if not values['mac'].to_s.match(/[a-z,A-Z,0-9]/) or not values['service'].to_s.match(/[a-z,A-Z,0-9]/)
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
            if temp_name.to_s.match(/^#{values['name']}/)
              if not values['service'].to_s.match(/[a-z,A-Z,0-9]/)
                values['service'] = temp_service
              end
              if not values['mac'].to_s.match(/[a-z,A-Z,0-9]/)
                values['mac'] = temp_mac
              end
            end
          end
        end
      end
    end
  end
  if values['name'].to_s.match(/[a-z,A-Z]/) 
    if values['service'].to_s.match(/[a-z,A-Z]/) 
      message = "Information:\tDeleting client profile "+values['name']+" from "+values['service']
      command = "installadm delete-profile -p #{values['name']} -n #{values['service']}"
      execute_command(values, message, command)
    else
      if values['mac'].to_s.match(/[0-9]/)
        message = "Information:\tDeleting client "+values['name']+" with from service "+values['service']
        command = "installadm delete-client "+values['mac']
        execute_command(values, message, command)
      end
    end
  else
    verbose_output(values, "Warning:\tService name not given for #{values['name']}")
    quit(values)
  end
  return
end
