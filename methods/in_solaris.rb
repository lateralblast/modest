# Solaris common code

# List all solaris ISOs

def list_sol_isos(search_string)
  handle_output(options, "") 
  list_js_isos()
  list_ai_isos()
  return
end

# Install required packages

def check_solaris_install()
  pkgutil_bin  = "/opt/csw/bin/pkgutil"
  pkgutil_conf = "/opt/csw/etc/pkgutil.conf"
  ['git", "autoconf", "automake", "libtool'].each do |pkg_name|
    message = "Information:\tChecking package "+pkg_name+" is installed"
    command = "which #{pkg}"
    output  = execute_command(options, message, command)
    if not output.match(/^\//)
      install_sol11_pkg(options, pkg_name)
    end
  end
  if not File.exist(pkgutil_bin)
    pkg_file    = "pkgutil-"+options['host-os-unamep']+".pkg"
    local_file  = "/tmp/"+pkg_file
    remote_file = $local_opencsw_mirror+"/"+pkg_file
    wget_file(options, remote_file, local_file)
    if File.exist?(local_file)
      message = "Information:\tInstalling OpenCSW Package pkgutil"
      command = "pkgadd -d #{local_file}"
      execute_command(options, message, command)
    end
  end
  if File.exist?(pkgutil_conf)
    message = "Information:\tChecking mirror is set for OpenCSW"
    command = "cat #{pkgutil_conf} |grep \"^mirror\" |grep -v \"^#\""
    output  = execute_command(options, message, command)
    if not output.match(/#{$local_opencsw_mirror}/)
      mirror  = "mirror="+$local_opencsw_mirror
      message = "Information:\tAdding local OpenCSW Mirror"
      command = "echo '#{mirror}' >> #{pkgutil_conf}"
      execute_command(options, message, command)
    end
  end
  return
end

# Check Solaris NAT

def check_solaris_nat(if_name)
  message = "Information:\tChecking IPv4 Routing is Enabled"
  command = "routeadm |grep 'IPv4 routing'"
  output  = execute_command(options, message, command)
  if output.match(/disabled/)
    message = "Information:\tEnabling IPv4 Routing"
    command = "routeadm -e ipv4-routing -u"
    execute_command(options, message, command)
  end
  message = "Information:\tChecking IPv4 Forwarding is Enabled"
  command = "routeadm |grep 'IPv4 forwarding'"
  output  = execute_command(options, message, command)
  if output.match(/disabled/)
    message = "Information:\tEnabling IPv4 Forwarding"
    command = "routeadm -e ipv4-forwarding -u"
    execute_command(options, message, command)
  end
  message = "Information:\tChecking DHCP Server is listening on "+if_name
  command = "svccfg -s svc:/network/dhcp/server:ipv4 listprop config/listen_ifnames |grep #{if_name}"
  output  = execute_command(options, message, command)
  if not output.match(/#{if_name}/)
    message = "Information:\tSetting DHCP Server to listen on "+if_name
    command = "svccfg -s svc:/network/dhcp/server:ipv4 setprop config/listen_ifnames = astring: #{if_name} ; svcadm refresh svc:/network/dhcp/server:ipv4"
    execute_command(options, message, command)
  end
  return
end

# Check local publisher is configured

def check_local_publisher(options)
  message = "Information:\tChecking publisher is online"
  command = "pkg publisher | grep online"
  output  = execute_command(options, message, command)
  if not output.match(/online/)
    handle_output(options, "Warning:\tNo local publisher online")
    options['repodir'] = options['baserepodir']+"/sol_"+options['update'].gsub(/\./, "_")
    publisher_dir      = options['repodir']+"/publisher"
    if not File.directory?(publisher_dir)
      handle_output(options, "Warning:\tNo local repository")
      options['file'] = options['isodir']+"/sol-"+options['update'].gsub(/\./, "_")+"-repo-full.iso"
      if File.exist?(options['file'])
        mount_iso(options)
        copy_iso(options)
        if File.directory?(publisher_dir)
          message = "Information:\tRefreshing repository at "+options['repodir']
          command = "pkgrepo -s #{options['repodir']} refresh"
          execute_command(options, message, command)
          message = "Information:\tEnabling repository at "+options['repodir']
          command = "pkg set-publisher -G '*' -g #{options['repodir']} solaris"
          execute_command(options, message, command)
        else
          handle_output(options, "Warning:\tNo local publisher directory found at: #{publisher_dir}")
          quit(options)
        end
      else
        handle_output(options, "Warning:\tNo local repository ISO file #{options['file']}")
        quit(options)
      end
    end
  end
end

# Handle SMF service

def handle_smf_service(options,function, smf_service)
  if options['host-os-uname'].to_s.match(/SunOS/)
    uc_function = function.capitalize
    if function.match(/enable/)
      message = "Information:\tChecking status of service "+smf_service
      command = "svcs #{smf_service} |grep -v STATE"
      output  = execute_command(options, message, command)
      if output.match(/maintenance/)
        message = uc_function+":\tService "+smf_service
        command = "svcadm clear #{smf_service} ; sleep 5"
        output  = execute_command(options, message, command)
      end
      if not output.match(/online/)
        message = uc_function+":\tService "+smf_service
        command = "svcadm #{function} #{smf_service} ; sleep 5"
        output  = execute_command(options, message, command)
      end
    else
      message = uc_function+":\tService "+smf_service
      command = "svcadm #{function} #{smf_service} ; sleep 5"
      output  = execute_command(options, message, command)
    end
  end
  return output
end

# Disable SMF service

def disable_smf_service(options, smf_service)
  function = "disable"
  output   = handle_smf_service(options, function, smf_service)
  return output
end

# Enable SMF service

def enable_smf_service(options, smf_service)
  function = "enable"
  output   = handle_smf_service(options, function, smf_service)
  return output
end

# Refresh SMF service

def refresh_smf_service(options, smf_service)
  function = "refresh"
  output   = handle_smf_service(options, function, smf_service)
  return output
end

# Check SMF service

def check_smf_service(options, smf_service)
  if options['host-os-uname'].to_s.match(/SunOS/)
    message = "Information:\tChecking service "+smf_service
    command = "svcs -a |grep #{smf_service}"
    output  = execute_command(options, message, command)
  end
  return output
end

# Check Solaris 11 package

def install_sol11_pkg(options, pkg_name)
  pkg_test = %x[which #{pkg_name}]
  if pkg_test.match(/no #{pkg_name}/)
    message = "Information:\tChecking Package "+pkg_name+" is installed"
    command = "pkg info #{pkg_name} 2>&1| grep \"Name:\" |awk \"{print \\\$3}\""
    output  = execute_command(options, message, command)
    if not output.match(/#{pkg_name}/)
      message = "Information:\tChecking publisher is online"
      command = "pkg publisher | grep online"
      output  = execute_command(options, message, command)
      if output.match(/online/)
        message = "Information:\tInstalling Package "+pkg_name
        command = "pkg install #{pkg_name}"
        execute_command(options, message, command)
      end
    end
  end
  return
end

# Check Solaris 11 NTP

def check_sol11_ntp(options)
  ntp_file = "/etc/inet/ntp.conf"
  [0..3].each do |number|
    ntp_host = number+"."+options['country'].downcase+".ntp.pool.org"
    message  = "Information:\tChecking NTP server "+ntp_host+" is in "+ntp_file
    command  = "cat #{ntp_file} | grep \"#{ntp_host}\""
    output   = execute_command(options, message, command)
    ntp_test = output.chomp
    if not ntp_test.match(/#ntp_test/)
      message = "Information:\tAdding NTP host "+ntp_host+" to "+ntp_file
      command = "echo '#{ntp_host}' >> #{ntp_file}"
      execute_command(options, message, command)
    end
  end
  ['driftfile /var/ntp/ntp.drift", "statsdir /var/ntp/ntpstats/",
    "filegen peerstats file peerstats type day enable",
   "filegen loopstats file loopstats type day enable'].each do |ntp_entry|
    message  = "Information:\tChecking NTP entry "+ntp_entry+" is in "+ntp_file
    command  = "cat #{ntp_file} | grep \"#{ntp_entry}\""
    output   = execute_command(options, message, command)
    ntp_test = output.chomp
    if not ntp_test.match(/#{ntp_entry}/)
      message = "Information:\tAdding NTP entry "+ntp_entry+" to "+ntp_file
      command = "echo '#{ntp_entry}' >> #{ntp_file}"
      execute_command(options, message, command)
    end
  end
  enable_smf_service(smf_service)
  return
end

# Create named configuration file

def create_named_conf(options)
  named_conf   = "/etc/named.conf"
  tmp_file     = "/tmp/named_conf"
  forward_file = "/etc/namedb/master/local.db"
  if not options['hostip'].to_s.match(/[0-9]/)
    check_local_config(options)
  end
  net_info     = options['hostip'].split(".")
  net_address  = net_info[2]+"."+net_info[1]+"."+net_info[0]
  host_segment = options['hostip'].split(".")[3]
  reverse_file = "/etc/namedb/master/"+net_address+".db"
  if not File.exist?(named_conf)
    install_sol11_pkg(options, "service/network/dns/bind")
    file = File.open(tmp_file, "w")
    file.write("\n")
    file.write("# named config\n")
    file.write("\n")
    file.write("options {\n")
    file.write("  directory \"/etc/namedb/working\";\n")
    file.write("  pid-file  \"/var/run/named/pid\";\n")
    file.write("  dump-file \"/var/dump/named_dump.db\";\n")
    file.write("  statistics-file \"/var/stats/named.stats\";\n")
    file.write("  forwarders  {#{options['nameserver']};};\n")
    file.write("};\n")
    file.write("\n")
    file.write("zone \"local\" {\n")
    file.write("  type master;\n")
    file.write("  file \"/etc/namedb/master/local.db\";\n")
    file.write("};\n")
    file.write("\n")
    file.write("zone \"#{net_address}.in-addr.arpa\" {\n")
    file.write("  type master;\n")
    file.write("  file \"/etc/namedb/master/#{net_address}.db\";\n")
    file.write("};\n")
    file.write("\n")
    file.write("\n")
    file.close
    message = "Information:\tCreatingidrectories for named"
    command = "mkdir /var/dump ; mkdir /var/stats ; mkdir -p /var/run/namedb ; mkdir -p /etc/namedb/master ; mkdir -p /etc/namedb/working"
    execute_command(options, message, command)
    message = "Information:\tCreating named configuration file "+named_conf
    command = "cp #{tmp_file} #{named_conf} ; rm #{tmp_file}"
    execute_command(options, message, command)
    print_contents_of_file(options, "", named_conf)
  end
  serial_no = %x[date +%Y%m%d].chomp+"01"
  tmp_file  = "/tmp/forward"
  if not File.exist?(forward_file)
    file = File.open(tmp_file, "w")
    file.write("$TTL 3h\n")
    file.write("@\tIN\tSOA\t#{options['hostname']}.local. local. (\n")
    file.write("\t#{serial_no}\n")
    file.write("\t28800\n")
    file.write("\t3600\n")
    file.write("\t604800\n")
    file.write("\t38400\n")
    file.write(")\n")
    file.write("\n")
    file.write("local.\tIN\tNS\t#{options['hostname']}.\n")
    file.write("#{options['hostname']}\tIN\tA\t#{options['hostip']}\n")
    file.write("\n")
    file.close
    message = "Information:\tCreating named configuration file "+forward_file
    command = "cp #{tmp_file} #{forward_file} ; rm #{tmp_file}"
    execute_command(options, message, command)
    print_contents_of_file(options, "", forward_file)
  end
  tmp_file = "/tmp/reverse"
  if not File.exist?(reverse_file)
    file = File.open(tmp_file, "w")
    file.write("$TTL 3h\n")
    file.write("@\tIN\tSOA\t#{options['hostname']}.local. local. (\n")
    file.write("\t#{serial_no}\n")
    file.write("\t28800\n")
    file.write("\t3600\n")
    file.write("\t604800\n")
    file.write("\t38400\n")
    file.write(")\n")
    file.write("\n")
    file.write("\tIN\tNS\t#{options['hostname']}.local\n")
    file.write("\n")
    file.write("#{host_segment}\tIN\tPTR\t#{options['hostname']}.\n")
    file.write("\n")
    file.close
    message = "Information:\tCreating named configuration file "+reverse_file
    command = "cp #{tmp_file} #{reverse_file} ; rm #{tmp_file}"
    execute_command(options, message, command)
    print_contents_of_file(options, "", reverse_file)
  end
  return
end

# Import SMF file

def import_smf_manifest(options, service, xml_file)
  message = "Information:\tImporting service manifest for "+service
  command = "svccfg import #{xml_file}"
  execute_command(options, message, command)
  message = "Information:\tStarting service manifest for "+service
  command = "svcadm restart #{service}"
  execute_command(options, message, command)
  return
end

# Check Solaris DNS server

def check_sol_bind(options)
  if options['host-os-uname'].to_s.match(/11/)
    pkg_name = "service/network/dns/bind"
    install_sol11_pkg(options, pkg_name)
  end
  create_named_conf(options)
  return
end
