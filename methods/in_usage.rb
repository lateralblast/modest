# Usage information

def print_error_header(type)
  handle_output(options, "")
  if type.length > 2
    handle_output(options, "Warning:\tInvalid #{type.capitalize} specified")
  else
    handle_output(options, "Warning:\tInvalid #{type.upcase} specified")
  end
  handle_output(options, "")
  return
end

def error_message(type, options)
  print_error_header(type) 
  eval"[print_#{type}_types(option)]"
  quit(options)
end

def print_arch_types(options)
  handle_output(options, "")
  handle_output(options, "Available Architectures:")
  handle_output(options, "")
  handle_output(options, "i386   - 32 bit Intel/AMD")
  handle_output(options, "x86_64 - 64 bit Intel/AMD")
  if options['vm'] =~ /ldom|zone/
    handle_output(options, "sparc  - 64 bit SPARC")
  end
  handle_output(options, "")
  handle_output(options, "Example:")
  handle_output(options, "")
  handle_output(options, "--arch=x86_64")
  handle_output(options, "")
  return
end

def print_client_types(options)
  handle_output(options, "")
  handle_output(options, "Refer to RFC1178 for valid host names")
  handle_output(options, "")
  handle_output(options, "Example:")
  handle_output(options, "")
  handle_output(options, "--name = hostname")
  handle_output(options, "")
  return
end

def print_vm_types(options)
  handle_output(options, "Available VM types:")
  handle_output(options, "")
  handle_output(options, "vbox   - VirtualBox")
  handle_output(options, "fusion - VMware Fusion")
  handle_output(options, "ldom   - Solaris 10/11 LDom (Logical Domain")
  handle_output(options, "lxc    - Linux Container")
  handle_output(options, "zone   - Solaris 10/11 Zone/Container")
  handle_output(options, "")
  return
end

def print_install_types(options)
  handle_output(options, "Available OS Install Types:")
  handle_output(options, "")
  handle_output(options, "ai             - Automated Installer (Solaris 11)")
  handle_output(options, "ks/kickstart   - Kickstart (RedHat, CentOS, Scientific, Fedora)")
  handle_output(options, "js/jumpstart   - Jumpstart (Solaris 10 or earlier")
  handle_output(options, "ps/preseed     - Preseed (Ubuntu, Debian)")
  handle_output(options, "ay/autoyast    - Autoyast (SLES, SuSE, OpenSuSE)")
  handle_output(options, "vs/vsphere/esx - VSphere/ESX Kickstart")
  handle_output(options, "container      - Container (Sets install type to Zone on Solaris and LXC on Linux")
  handle_output(options, "zone           - Zone (Sets install type to Zone on Solaris and LXC on Linux")
  handle_output(options, "lxc            - Linux Container")
  handle_output(options, "xb/bsd         - OpenBSD/NetBSD")
  handle_output(options, "")
  return
end

def print_os_types(options)
  handle_output(options, "Available OS Types:")
  handle_output(options, "")
  handle_output(options, "solaris       - Solaris (Sets install type to Jumpstart on Solaris 10, and AI on Solaris 11)")
  handle_output(options, "ubuntu        - Ubuntu Linux (Sets install type to Preseed)")
  handle_output(options, "debian        - Debian Linux (Sets install type to Preseed)")
  handle_output(options, "suse          - SuSE Linux (Sets install type to Autoyast)")
  handle_output(options, "sles          - SuSE Linux (Sets install type to Autoyast)")
  handle_output(options, "redhat        - Redhat Linux (Sets install type to Kickstart)")
  handle_output(options, "rhel          - Redhat Linux (Sets install type to Kickstart)")
  handle_output(options, "centos        - CentOS Linux (Sets install type to Kickstart)")
  handle_output(options, "fedora        - Fedora Linux (Sets install type to Kickstart)")
  handle_output(options, "scientific/sl - Scientific Linux (Sets install type to Kickstart)")
  handle_output(options, "vsphere/esx   - vSphere (Sets install type to Kickstart)")
  handle_output(options, "windows       - Windows (Incomplete)")
  handle_output(options, "")
  return
end

# Print a .md file

def print_md(options, md_file)
  md_file = options['wikidir']+"/"+md_file+".md"
  if File.directory?(options['wikidir']) or File.symlink?(options['wikidir'])
    if File.exist?(md_file)
      md_info = File.readlines(md_file)
      if md_info
        md_info.each do |line, index|
          if not line.match(/\`\`\`/)
            handle_output(line)
          end
        end
      end
    else
      if options['verbose'] == true
        handle_output(options, "Warning:\tFile: #{md_file} contains no information")
      end
    end
  else
    options['verbose'] = 1
#    handle_output(options, "Warning:\tWiki directory '#{options['wikidir']}' does not exist")
#    options['sudo'] = false
#    message    = "Attempting to clone Wiki dir from: '"+options['wikiurl']+"' to: '"+options['wikidir']
#    command    = "cd #{options['scriptdir']} ; git clone #{options['wikiurl']}"
#    execute_command(options, message, command)
#    handle_output(options, "")
#    ptint_md(md_file)
    quit(options)
  end
  return
end

# Detailed usage

def print_examples(options)
  handle_output(options, "")
  examples = options['method']+options['type']+options['vm']
  if !examples.match(/[a-z,A-Z]/)
    examples = "all"
  end
  if examples.match(/iso|all/)
    print_md(options, "ISOs")
    handle_output(options, "")
  end
  if examples.match(/packer|all/)
    print_md(options, "Packer")
    handle_output(options, "")
  end
  if examples.match(/all|server|dist|setup/)
    print_md(options, "Distribution-Server-Setup")
    handle_output(options, "")
  end
  if examples.match(/vbox|all|virtualbox/)
    print_md(options, "VirtualBox")
    handle_output(options, "")
  end
  if examples.match(/fusion|all/)
    print_md(options, "VMware-Fusion")
    handle_output(options, "")
  end
  if examples.match(/server|ai|all/)
    print_md(options, "AI-Server")
    handle_output(options, "")
  end
  if examples.match(/server|ay|all/)
    print_md(options, "AutoYast-Server")
    handle_output(options, "")
  end
  if examples.match(/server|ks|all/)
    print_md(options, "Kickstart-Server")
    handle_output(options, "")
  end
  if examples.match(/server|ps|all/)
    print_md(options, "Preseed-Server")
    handle_output(options, "")
  end
  if examples.match(/server|xb|ob|nb|all/)
    handle_output(options, "*BSD server related examples:")
    handle_output(options, "")
    handle_output(options, "List all *BSD services:")
    handle_output(options, "#{options['script']} -B -S -L")
    handle_output(options, "Configure all *BSD services:")
    handle_output(options, "#{options['script']} -B -S")
    handle_output(options, "Configure a NetBSD service (from ISO):")
    handle_output(options, "#{options['script']} -B -S -f /export/isos/install55-i386.iso")
    handle_output(options, "Configure a FreeBSD service (from ISO):")
    handle_output(options, "#{options['script']} -B -S -f /export/isos/FreeBSD-10.0-RELEASE-amd64-dvd1.iso")
    handle_output(options, "")
  end
  if examples.match(/server|js|all/)
    print_md(options, "Jumpstart-Server")
    handle_output(options, "")
  end
  if examples.match(/server|vs|all/)
    print_md(options, "vSphere-Server")
    handle_output(options, "")
  end
  if examples.match(/maint|all/)
    handle_output(options, "Maintenance related examples:")
    handle_output(options, "")
    handle_output(options, "Configure AI client services:")
    handle_output(options, "#{options['script']} -A -G -C -a i386")
    handle_output(options, "Enable AI proxy:")
    handle_output(options, "#{options['script']} -A -G -W -n sol_11_1")
    handle_output(options, "Disable AI proxy:")
    handle_output(options, "#{options['script']} -A -G -W -z sol_11_1")
    handle_output(options, "Configure AI alternate repo:")
    handle_output(options, "#{options['script']} -A -G -R")
    handle_output(options, "Unconfigure AI alternate repo:")
    handle_output(options, "#{options['script']} -A -G -R -z sol_11_1_alt")
    handle_output(options, "Configure Kickstart alternate repo:")
    handle_output(options, "#{options['script']} -K -G -R -n centos_5_10_x86_64")
    handle_output(options, "Unconfigure Kickstart alternate repo:")
    handle_output(options, "#{options['script']} -K -G -R -z centos_5_10_x86_64")
    handle_output(options, "Enable Kickstart alias:")
    handle_output(options, "#{options['script']} -K -G -W -n centos_5_10_x86_64")
    handle_output(options, "Disable Kickstart alias:")
    handle_output(options, "#{options['script']} -K -G -W -z centos_5_10_x86_64")
    handle_output(options, "Import Kickstart PXE files:")
    handle_output(options, "#{options['script']} -K -G -P -n centos_5_10_x86_64")
    handle_output(options, "Delete Kickstart PXE files:")
    handle_output(options, "#{options['script']} -K -G -P -z centos_5_10_x86_64")
    handle_output(options, "Unconfigure Kickstart client PXE:")
    handle_output(options, "#{options['script']} -K -G -P -d centos510vm01")
    handle_output(options, "")
  end
  if examples.match(/zone|all/)
    handle_output(options, "Solaris Zone related examples:")
    handle_output(options, "")
    handle_output(options, "List Zones:")
    handle_output(options, "#{options['script']} -Z -L")
    handle_output(options, "Configure Zone:")
    handle_output(options, "#{options['script']} -Z -c sol11u01z01 -i 192.168.1.181")
    handle_output(options, "Configure Branded Zone:")
    handle_output(options, "#{options['script']} -Z -c sol10u11z01 -i 192.168.1.171 -f /export/isos/solaris-10u11-x86.bin")
    handle_output(options, "Configure Branded Zone:")
    handle_output(options, "#{options['script']} -Z -c sol10u11z02 -i 192.168.1.172 -n sol_10_11_i386")
    handle_output(options, "Delete Zone:")
    handle_output(options, "#{options['script']} -Z -d sol11u01z01")
    handle_output(options, "Boot Zone:")
    handle_output(options, "#{options['script']} -Z -b sol11u01z01")
    handle_output(options, "Boot Zone (connect to console):")
    handle_output(options, "#{options['script']} -Z -b sol11u01z01 -B")
    handle_output(options, "Halt Zone:")
    handle_output(options, "#{options['script']} -Z -s sol11u01z01")
    handle_output(options, "")
  end
  if examples.match(/ldom|all/)
    handle_output(options, "Oracle VM Server for SPARC related examples:")
    handle_output(options, "")
    handle_output(options, "Configure Control Domain:")
    handle_output(options, "#{options['script']} -O -S")
    handle_output(options, "List Guest Domains:")
    handle_output(options, "#{options['script']} -O -L")
    handle_output(options, "Configure Guest Domain:")
    handle_output(options, "#{options['script']} -O -c sol11u01gd01")
    handle_output(options, "")
  end
  if examples.match(/lxc|all/)
    handle_output(options, "Linux Container related examples:")
    handle_output(options, "")
    handle_output(options, "Configure Container Services:")
    handle_output(options, "#{options['script']} -Z -S")
    handle_output(options, "List Containers:")
    handle_output(options, "#{options['script']} -Z -L")
    handle_output(options, "Configure Standard Container:")
    handle_output(options, "#{options['script']} -Z -c ubuntu1310lx01 -i 192.168.1.206")
    handle_output(options, "Execute post install script:")
    handle_output(options, "#{options['script']} -Z -p ubuntu1310lx01")
    handle_output(options, "")
  end
  if examples.match(/client|ks|all/)
    print_md(options, "Kickstart-Client")
    handle_output(options, "")
  end
  if examples.match(/client|ai|all/)
    print_md(options, "AI-Client")
    handle_output(options, "")
  end
  if examples.match(/client|xb|ob|nb|all/)
    handle_output(options, "*BSD client related examples:")
    handle_output(options, "")
    handle_output(options, "List *BSD clients:")
    handle_output(options, "#{options['script']} -B -C -L")
    handle_output(options, "Create OpenBSD client:")
    handle_output(options, "#{options['script']} -B -C -c openbsd55vm01 -e 00:50:56:26:92:d8 -a x86_64 -i 192.168.1.193 -n openbsd_5_5_x86_64")
    handle_output(options, "Create FreeBSD client:")
    handle_output(options, "#{options['script']} -B -C -c freebsd10vm01 -e 00:50:56:26:92:d7 -a x86_64 -i 192.168.1.194 -n netbsd_10_0_x86_64")
    handle_output(options, "Delete FreeBSD client:")
    handle_output(options, "#{options['script']} -B -C -d freebsd10vm01")
    handle_output(options, "")
  end
  if examples.match(/client|ps|all/)
    print_md(options, "Preseed-Client")
    handle_output(options, "")
  end
  if examples.match(/client|js|all/)
    print_md(options, "Jumpstart-Client")
    handle_output(options, "")
  end
  if examples.match(/client|ay|all/)
    print_md(options, "AutoYast-Client")
    handle_output(options, "")
  end
  if examples.match(/client|vcsa|all/)
    print_md(options, "VCSA-Deployment")
    handle_output(options, "")
  end
  if examples.match(/client|vs|all/)
    print_md(options, "vSphere-Client")
    handle_output(options, "")
  end
  quit(options)
end

