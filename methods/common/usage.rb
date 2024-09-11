# Usage information

def print_error_header(type)
  handle_output(values, "")
  if type.length > 2
    handle_output(values, "Warning:\tInvalid #{type.capitalize} specified")
  else
    handle_output(values, "Warning:\tInvalid #{type.upcase} specified")
  end
  handle_output(values, "")
  return
end

def error_message(type, values)
  print_error_header(type) 
  eval"[print_#{type}_types(option)]"
  quit(values)
end

def print_arch_types(values)
  handle_output(values, "")
  handle_output(values, "Available Architectures:")
  handle_output(values, "")
  handle_output(values, "i386   - 32 bit Intel/AMD")
  handle_output(values, "x86_64 - 64 bit Intel/AMD")
  if values['vm'] =~ /ldom|zone/
    handle_output(values, "sparc  - 64 bit SPARC")
  end
  handle_output(values, "")
  handle_output(values, "Example:")
  handle_output(values, "")
  handle_output(values, "--arch=x86_64")
  handle_output(values, "")
  return
end

def print_client_types(values)
  handle_output(values, "")
  handle_output(values, "Refer to RFC1178 for valid host names")
  handle_output(values, "")
  handle_output(values, "Example:")
  handle_output(values, "")
  handle_output(values, "--name = hostname")
  handle_output(values, "")
  return
end

def print_vm_types(values)
  handle_output(values, "Available VM types:")
  handle_output(values, "")
  handle_output(values, "vbox   - VirtualBox")
  handle_output(values, "fusion - VMware Fusion")
  handle_output(values, "ldom   - Solaris 10/11 LDom (Logical Domain")
  handle_output(values, "lxc    - Linux Container")
  handle_output(values, "zone   - Solaris 10/11 Zone/Container")
  handle_output(values, "")
  return
end

def print_install_types(values)
  handle_output(values, "Available OS Install Types:")
  handle_output(values, "")
  handle_output(values, "ai             - Automated Installer (Solaris 11)")
  handle_output(values, "ks/kickstart   - Kickstart (RedHat, CentOS, Scientific, Fedora)")
  handle_output(values, "js/jumpstart   - Jumpstart (Solaris 10 or earlier")
  handle_output(values, "ps/preseed     - Preseed (Ubuntu, Debian)")
  handle_output(values, "ay/autoyast    - Autoyast (SLES, SuSE, OpenSuSE)")
  handle_output(values, "vs/vsphere/esx - VSphere/ESX Kickstart")
  handle_output(values, "container      - Container (Sets install type to Zone on Solaris and LXC on Linux")
  handle_output(values, "zone           - Zone (Sets install type to Zone on Solaris and LXC on Linux")
  handle_output(values, "lxc            - Linux Container")
  handle_output(values, "xb/bsd         - OpenBSD/NetBSD")
  handle_output(values, "")
  return
end

def print_os_types(values)
  handle_output(values, "Available OS Types:")
  handle_output(values, "")
  handle_output(values, "solaris       - Solaris (Sets install type to Jumpstart on Solaris 10, and AI on Solaris 11)")
  handle_output(values, "ubuntu        - Ubuntu Linux (Sets install type to Preseed)")
  handle_output(values, "debian        - Debian Linux (Sets install type to Preseed)")
  handle_output(values, "suse          - SuSE Linux (Sets install type to Autoyast)")
  handle_output(values, "sles          - SuSE Linux (Sets install type to Autoyast)")
  handle_output(values, "redhat        - Redhat Linux (Sets install type to Kickstart)")
  handle_output(values, "rhel          - Redhat Linux (Sets install type to Kickstart)")
  handle_output(values, "centos        - CentOS Linux (Sets install type to Kickstart)")
  handle_output(values, "fedora        - Fedora Linux (Sets install type to Kickstart)")
  handle_output(values, "scientific/sl - Scientific Linux (Sets install type to Kickstart)")
  handle_output(values, "vsphere/esx   - vSphere (Sets install type to Kickstart)")
  handle_output(values, "windows       - Windows (Incomplete)")
  handle_output(values, "")
  return
end

# Print a .md file

def print_md(values, md_file)
  md_file = values['wikidir']+"/"+md_file+".md"
  if File.directory?(values['wikidir']) or File.symlink?(values['wikidir'])
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
      if values['verbose'] == true
        handle_output(values, "Warning:\tFile: #{md_file} contains no information")
      end
    end
  else
    values['verbose'] = 1
#    handle_output(values, "Warning:\tWiki directory '#{values['wikidir']}' does not exist")
#    values['sudo'] = false
#    message    = "Attempting to clone Wiki dir from: '"+values['wikiurl']+"' to: '"+values['wikidir']
#    command    = "cd #{values['scriptdir']} ; git clone #{values['wikiurl']}"
#    execute_command(values, message, command)
#    handle_output(values, "")
#    ptint_md(md_file)
    quit(values)
  end
  return
end

# Detailed usage

def print_examples(values)
  handle_output(values, "")
  examples = values['method']+values['type']+values['vm']
  if !examples.match(/[a-z,A-Z]/)
    examples = "all"
  end
  if examples.match(/iso|all/)
    print_md(values, "ISOs")
    handle_output(values, "")
  end
  if examples.match(/packer|all/)
    print_md(values, "Packer")
    handle_output(values, "")
  end
  if examples.match(/all|server|dist|setup/)
    print_md(values, "Distribution-Server-Setup")
    handle_output(values, "")
  end
  if examples.match(/vbox|all|virtualbox/)
    print_md(values, "VirtualBox")
    handle_output(values, "")
  end
  if examples.match(/fusion|all/)
    print_md(values, "VMware-Fusion")
    handle_output(values, "")
  end
  if examples.match(/server|ai|all/)
    print_md(values, "AI-Server")
    handle_output(values, "")
  end
  if examples.match(/server|ay|all/)
    print_md(values, "AutoYast-Server")
    handle_output(values, "")
  end
  if examples.match(/server|ks|all/)
    print_md(values, "Kickstart-Server")
    handle_output(values, "")
  end
  if examples.match(/server|ps|all/)
    print_md(values, "Preseed-Server")
    handle_output(values, "")
  end
  if examples.match(/server|xb|ob|nb|all/)
    handle_output(values, "*BSD server related examples:")
    handle_output(values, "")
    handle_output(values, "List all *BSD services:")
    handle_output(values, "#{values['script']} -B -S -L")
    handle_output(values, "Configure all *BSD services:")
    handle_output(values, "#{values['script']} -B -S")
    handle_output(values, "Configure a NetBSD service (from ISO):")
    handle_output(values, "#{values['script']} -B -S -f /export/isos/install55-i386.iso")
    handle_output(values, "Configure a FreeBSD service (from ISO):")
    handle_output(values, "#{values['script']} -B -S -f /export/isos/FreeBSD-10.0-RELEASE-amd64-dvd1.iso")
    handle_output(values, "")
  end
  if examples.match(/server|js|all/)
    print_md(values, "Jumpstart-Server")
    handle_output(values, "")
  end
  if examples.match(/server|vs|all/)
    print_md(values, "vSphere-Server")
    handle_output(values, "")
  end
  if examples.match(/maint|all/)
    handle_output(values, "Maintenance related examples:")
    handle_output(values, "")
    handle_output(values, "Configure AI client services:")
    handle_output(values, "#{values['script']} -A -G -C -a i386")
    handle_output(values, "Enable AI proxy:")
    handle_output(values, "#{values['script']} -A -G -W -n sol_11_1")
    handle_output(values, "Disable AI proxy:")
    handle_output(values, "#{values['script']} -A -G -W -z sol_11_1")
    handle_output(values, "Configure AI alternate repo:")
    handle_output(values, "#{values['script']} -A -G -R")
    handle_output(values, "Unconfigure AI alternate repo:")
    handle_output(values, "#{values['script']} -A -G -R -z sol_11_1_alt")
    handle_output(values, "Configure Kickstart alternate repo:")
    handle_output(values, "#{values['script']} -K -G -R -n centos_5_10_x86_64")
    handle_output(values, "Unconfigure Kickstart alternate repo:")
    handle_output(values, "#{values['script']} -K -G -R -z centos_5_10_x86_64")
    handle_output(values, "Enable Kickstart alias:")
    handle_output(values, "#{values['script']} -K -G -W -n centos_5_10_x86_64")
    handle_output(values, "Disable Kickstart alias:")
    handle_output(values, "#{values['script']} -K -G -W -z centos_5_10_x86_64")
    handle_output(values, "Import Kickstart PXE files:")
    handle_output(values, "#{values['script']} -K -G -P -n centos_5_10_x86_64")
    handle_output(values, "Delete Kickstart PXE files:")
    handle_output(values, "#{values['script']} -K -G -P -z centos_5_10_x86_64")
    handle_output(values, "Unconfigure Kickstart client PXE:")
    handle_output(values, "#{values['script']} -K -G -P -d centos510vm01")
    handle_output(values, "")
  end
  if examples.match(/zone|all/)
    handle_output(values, "Solaris Zone related examples:")
    handle_output(values, "")
    handle_output(values, "List Zones:")
    handle_output(values, "#{values['script']} -Z -L")
    handle_output(values, "Configure Zone:")
    handle_output(values, "#{values['script']} -Z -c sol11u01z01 -i 192.168.1.181")
    handle_output(values, "Configure Branded Zone:")
    handle_output(values, "#{values['script']} -Z -c sol10u11z01 -i 192.168.1.171 -f /export/isos/solaris-10u11-x86.bin")
    handle_output(values, "Configure Branded Zone:")
    handle_output(values, "#{values['script']} -Z -c sol10u11z02 -i 192.168.1.172 -n sol_10_11_i386")
    handle_output(values, "Delete Zone:")
    handle_output(values, "#{values['script']} -Z -d sol11u01z01")
    handle_output(values, "Boot Zone:")
    handle_output(values, "#{values['script']} -Z -b sol11u01z01")
    handle_output(values, "Boot Zone (connect to console):")
    handle_output(values, "#{values['script']} -Z -b sol11u01z01 -B")
    handle_output(values, "Halt Zone:")
    handle_output(values, "#{values['script']} -Z -s sol11u01z01")
    handle_output(values, "")
  end
  if examples.match(/ldom|all/)
    handle_output(values, "Oracle VM Server for SPARC related examples:")
    handle_output(values, "")
    handle_output(values, "Configure Control Domain:")
    handle_output(values, "#{values['script']} -O -S")
    handle_output(values, "List Guest Domains:")
    handle_output(values, "#{values['script']} -O -L")
    handle_output(values, "Configure Guest Domain:")
    handle_output(values, "#{values['script']} -O -c sol11u01gd01")
    handle_output(values, "")
  end
  if examples.match(/lxc|all/)
    handle_output(values, "Linux Container related examples:")
    handle_output(values, "")
    handle_output(values, "Configure Container Services:")
    handle_output(values, "#{values['script']} -Z -S")
    handle_output(values, "List Containers:")
    handle_output(values, "#{values['script']} -Z -L")
    handle_output(values, "Configure Standard Container:")
    handle_output(values, "#{values['script']} -Z -c ubuntu1310lx01 -i 192.168.1.206")
    handle_output(values, "Execute post install script:")
    handle_output(values, "#{values['script']} -Z -p ubuntu1310lx01")
    handle_output(values, "")
  end
  if examples.match(/client|ks|all/)
    print_md(values, "Kickstart-Client")
    handle_output(values, "")
  end
  if examples.match(/client|ai|all/)
    print_md(values, "AI-Client")
    handle_output(values, "")
  end
  if examples.match(/client|xb|ob|nb|all/)
    handle_output(values, "*BSD client related examples:")
    handle_output(values, "")
    handle_output(values, "List *BSD clients:")
    handle_output(values, "#{values['script']} -B -C -L")
    handle_output(values, "Create OpenBSD client:")
    handle_output(values, "#{values['script']} -B -C -c openbsd55vm01 -e 00:50:56:26:92:d8 -a x86_64 -i 192.168.1.193 -n openbsd_5_5_x86_64")
    handle_output(values, "Create FreeBSD client:")
    handle_output(values, "#{values['script']} -B -C -c freebsd10vm01 -e 00:50:56:26:92:d7 -a x86_64 -i 192.168.1.194 -n netbsd_10_0_x86_64")
    handle_output(values, "Delete FreeBSD client:")
    handle_output(values, "#{values['script']} -B -C -d freebsd10vm01")
    handle_output(values, "")
  end
  if examples.match(/client|ps|all/)
    print_md(values, "Preseed-Client")
    handle_output(values, "")
  end
  if examples.match(/client|js|all/)
    print_md(values, "Jumpstart-Client")
    handle_output(values, "")
  end
  if examples.match(/client|ay|all/)
    print_md(values, "AutoYast-Client")
    handle_output(values, "")
  end
  if examples.match(/client|vcsa|all/)
    print_md(values, "VCSA-Deployment")
    handle_output(values, "")
  end
  if examples.match(/client|vs|all/)
    print_md(values, "vSphere-Client")
    handle_output(values, "")
  end
  quit(values)
end

