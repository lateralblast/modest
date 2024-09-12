# Usage information

def print_error_header(type)
  verbose_output(values, "")
  if type.length > 2
    verbose_output(values, "Warning:\tInvalid #{type.capitalize} specified")
  else
    verbose_output(values, "Warning:\tInvalid #{type.upcase} specified")
  end
  verbose_output(values, "")
  return
end

def error_message(type, values)
  print_error_header(type) 
  eval"[print_#{type}_types(option)]"
  quit(values)
end

def print_arch_types(values)
  verbose_output(values, "")
  verbose_output(values, "Available Architectures:")
  verbose_output(values, "")
  verbose_output(values, "i386   - 32 bit Intel/AMD")
  verbose_output(values, "x86_64 - 64 bit Intel/AMD")
  if values['vm'] =~ /ldom|zone/
    verbose_output(values, "sparc  - 64 bit SPARC")
  end
  verbose_output(values, "")
  verbose_output(values, "Example:")
  verbose_output(values, "")
  verbose_output(values, "--arch=x86_64")
  verbose_output(values, "")
  return
end

def print_client_types(values)
  verbose_output(values, "")
  verbose_output(values, "Refer to RFC1178 for valid host names")
  verbose_output(values, "")
  verbose_output(values, "Example:")
  verbose_output(values, "")
  verbose_output(values, "--name = hostname")
  verbose_output(values, "")
  return
end

def print_vm_types(values)
  verbose_output(values, "Available VM types:")
  verbose_output(values, "")
  verbose_output(values, "vbox   - VirtualBox")
  verbose_output(values, "fusion - VMware Fusion")
  verbose_output(values, "ldom   - Solaris 10/11 LDom (Logical Domain")
  verbose_output(values, "lxc    - Linux Container")
  verbose_output(values, "zone   - Solaris 10/11 Zone/Container")
  verbose_output(values, "")
  return
end

def print_install_types(values)
  verbose_output(values, "Available OS Install Types:")
  verbose_output(values, "")
  verbose_output(values, "ai             - Automated Installer (Solaris 11)")
  verbose_output(values, "ks/kickstart   - Kickstart (RedHat, CentOS, Scientific, Fedora)")
  verbose_output(values, "js/jumpstart   - Jumpstart (Solaris 10 or earlier")
  verbose_output(values, "ps/preseed     - Preseed (Ubuntu, Debian)")
  verbose_output(values, "ay/autoyast    - Autoyast (SLES, SuSE, OpenSuSE)")
  verbose_output(values, "vs/vsphere/esx - VSphere/ESX Kickstart")
  verbose_output(values, "container      - Container (Sets install type to Zone on Solaris and LXC on Linux")
  verbose_output(values, "zone           - Zone (Sets install type to Zone on Solaris and LXC on Linux")
  verbose_output(values, "lxc            - Linux Container")
  verbose_output(values, "xb/bsd         - OpenBSD/NetBSD")
  verbose_output(values, "")
  return
end

def print_os_types(values)
  verbose_output(values, "Available OS Types:")
  verbose_output(values, "")
  verbose_output(values, "solaris       - Solaris (Sets install type to Jumpstart on Solaris 10, and AI on Solaris 11)")
  verbose_output(values, "ubuntu        - Ubuntu Linux (Sets install type to Preseed)")
  verbose_output(values, "debian        - Debian Linux (Sets install type to Preseed)")
  verbose_output(values, "suse          - SuSE Linux (Sets install type to Autoyast)")
  verbose_output(values, "sles          - SuSE Linux (Sets install type to Autoyast)")
  verbose_output(values, "redhat        - Redhat Linux (Sets install type to Kickstart)")
  verbose_output(values, "rhel          - Redhat Linux (Sets install type to Kickstart)")
  verbose_output(values, "centos        - CentOS Linux (Sets install type to Kickstart)")
  verbose_output(values, "fedora        - Fedora Linux (Sets install type to Kickstart)")
  verbose_output(values, "scientific/sl - Scientific Linux (Sets install type to Kickstart)")
  verbose_output(values, "vsphere/esx   - vSphere (Sets install type to Kickstart)")
  verbose_output(values, "windows       - Windows (Incomplete)")
  verbose_output(values, "")
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
            verbose_output(line)
          end
        end
      end
    else
      if values['verbose'] == true
        verbose_output(values, "Warning:\tFile: #{md_file} contains no information")
      end
    end
  else
    values['verbose'] = 1
#    verbose_output(values, "Warning:\tWiki directory '#{values['wikidir']}' does not exist")
#    values['sudo'] = false
#    message    = "Attempting to clone Wiki dir from: '"+values['wikiurl']+"' to: '"+values['wikidir']
#    command    = "cd #{values['scriptdir']} ; git clone #{values['wikiurl']}"
#    execute_command(values, message, command)
#    verbose_output(values, "")
#    ptint_md(md_file)
    quit(values)
  end
  return
end

# Detailed usage

def print_examples(values)
  verbose_output(values, "")
  examples = values['method']+values['type']+values['vm']
  if !examples.match(/[a-z,A-Z]/)
    examples = "all"
  end
  if examples.match(/iso|all/)
    print_md(values, "ISOs")
    verbose_output(values, "")
  end
  if examples.match(/packer|all/)
    print_md(values, "Packer")
    verbose_output(values, "")
  end
  if examples.match(/all|server|dist|setup/)
    print_md(values, "Distribution-Server-Setup")
    verbose_output(values, "")
  end
  if examples.match(/vbox|all|virtualbox/)
    print_md(values, "VirtualBox")
    verbose_output(values, "")
  end
  if examples.match(/fusion|all/)
    print_md(values, "VMware-Fusion")
    verbose_output(values, "")
  end
  if examples.match(/server|ai|all/)
    print_md(values, "AI-Server")
    verbose_output(values, "")
  end
  if examples.match(/server|ay|all/)
    print_md(values, "AutoYast-Server")
    verbose_output(values, "")
  end
  if examples.match(/server|ks|all/)
    print_md(values, "Kickstart-Server")
    verbose_output(values, "")
  end
  if examples.match(/server|ps|all/)
    print_md(values, "Preseed-Server")
    verbose_output(values, "")
  end
  if examples.match(/server|xb|ob|nb|all/)
    verbose_output(values, "*BSD server related examples:")
    verbose_output(values, "")
    verbose_output(values, "List all *BSD services:")
    verbose_output(values, "#{values['script']} -B -S -L")
    verbose_output(values, "Configure all *BSD services:")
    verbose_output(values, "#{values['script']} -B -S")
    verbose_output(values, "Configure a NetBSD service (from ISO):")
    verbose_output(values, "#{values['script']} -B -S -f /export/isos/install55-i386.iso")
    verbose_output(values, "Configure a FreeBSD service (from ISO):")
    verbose_output(values, "#{values['script']} -B -S -f /export/isos/FreeBSD-10.0-RELEASE-amd64-dvd1.iso")
    verbose_output(values, "")
  end
  if examples.match(/server|js|all/)
    print_md(values, "Jumpstart-Server")
    verbose_output(values, "")
  end
  if examples.match(/server|vs|all/)
    print_md(values, "vSphere-Server")
    verbose_output(values, "")
  end
  if examples.match(/maint|all/)
    verbose_output(values, "Maintenance related examples:")
    verbose_output(values, "")
    verbose_output(values, "Configure AI client services:")
    verbose_output(values, "#{values['script']} -A -G -C -a i386")
    verbose_output(values, "Enable AI proxy:")
    verbose_output(values, "#{values['script']} -A -G -W -n sol_11_1")
    verbose_output(values, "Disable AI proxy:")
    verbose_output(values, "#{values['script']} -A -G -W -z sol_11_1")
    verbose_output(values, "Configure AI alternate repo:")
    verbose_output(values, "#{values['script']} -A -G -R")
    verbose_output(values, "Unconfigure AI alternate repo:")
    verbose_output(values, "#{values['script']} -A -G -R -z sol_11_1_alt")
    verbose_output(values, "Configure Kickstart alternate repo:")
    verbose_output(values, "#{values['script']} -K -G -R -n centos_5_10_x86_64")
    verbose_output(values, "Unconfigure Kickstart alternate repo:")
    verbose_output(values, "#{values['script']} -K -G -R -z centos_5_10_x86_64")
    verbose_output(values, "Enable Kickstart alias:")
    verbose_output(values, "#{values['script']} -K -G -W -n centos_5_10_x86_64")
    verbose_output(values, "Disable Kickstart alias:")
    verbose_output(values, "#{values['script']} -K -G -W -z centos_5_10_x86_64")
    verbose_output(values, "Import Kickstart PXE files:")
    verbose_output(values, "#{values['script']} -K -G -P -n centos_5_10_x86_64")
    verbose_output(values, "Delete Kickstart PXE files:")
    verbose_output(values, "#{values['script']} -K -G -P -z centos_5_10_x86_64")
    verbose_output(values, "Unconfigure Kickstart client PXE:")
    verbose_output(values, "#{values['script']} -K -G -P -d centos510vm01")
    verbose_output(values, "")
  end
  if examples.match(/zone|all/)
    verbose_output(values, "Solaris Zone related examples:")
    verbose_output(values, "")
    verbose_output(values, "List Zones:")
    verbose_output(values, "#{values['script']} -Z -L")
    verbose_output(values, "Configure Zone:")
    verbose_output(values, "#{values['script']} -Z -c sol11u01z01 -i 192.168.1.181")
    verbose_output(values, "Configure Branded Zone:")
    verbose_output(values, "#{values['script']} -Z -c sol10u11z01 -i 192.168.1.171 -f /export/isos/solaris-10u11-x86.bin")
    verbose_output(values, "Configure Branded Zone:")
    verbose_output(values, "#{values['script']} -Z -c sol10u11z02 -i 192.168.1.172 -n sol_10_11_i386")
    verbose_output(values, "Delete Zone:")
    verbose_output(values, "#{values['script']} -Z -d sol11u01z01")
    verbose_output(values, "Boot Zone:")
    verbose_output(values, "#{values['script']} -Z -b sol11u01z01")
    verbose_output(values, "Boot Zone (connect to console):")
    verbose_output(values, "#{values['script']} -Z -b sol11u01z01 -B")
    verbose_output(values, "Halt Zone:")
    verbose_output(values, "#{values['script']} -Z -s sol11u01z01")
    verbose_output(values, "")
  end
  if examples.match(/ldom|all/)
    verbose_output(values, "Oracle VM Server for SPARC related examples:")
    verbose_output(values, "")
    verbose_output(values, "Configure Control Domain:")
    verbose_output(values, "#{values['script']} -O -S")
    verbose_output(values, "List Guest Domains:")
    verbose_output(values, "#{values['script']} -O -L")
    verbose_output(values, "Configure Guest Domain:")
    verbose_output(values, "#{values['script']} -O -c sol11u01gd01")
    verbose_output(values, "")
  end
  if examples.match(/lxc|all/)
    verbose_output(values, "Linux Container related examples:")
    verbose_output(values, "")
    verbose_output(values, "Configure Container Services:")
    verbose_output(values, "#{values['script']} -Z -S")
    verbose_output(values, "List Containers:")
    verbose_output(values, "#{values['script']} -Z -L")
    verbose_output(values, "Configure Standard Container:")
    verbose_output(values, "#{values['script']} -Z -c ubuntu1310lx01 -i 192.168.1.206")
    verbose_output(values, "Execute post install script:")
    verbose_output(values, "#{values['script']} -Z -p ubuntu1310lx01")
    verbose_output(values, "")
  end
  if examples.match(/client|ks|all/)
    print_md(values, "Kickstart-Client")
    verbose_output(values, "")
  end
  if examples.match(/client|ai|all/)
    print_md(values, "AI-Client")
    verbose_output(values, "")
  end
  if examples.match(/client|xb|ob|nb|all/)
    verbose_output(values, "*BSD client related examples:")
    verbose_output(values, "")
    verbose_output(values, "List *BSD clients:")
    verbose_output(values, "#{values['script']} -B -C -L")
    verbose_output(values, "Create OpenBSD client:")
    verbose_output(values, "#{values['script']} -B -C -c openbsd55vm01 -e 00:50:56:26:92:d8 -a x86_64 -i 192.168.1.193 -n openbsd_5_5_x86_64")
    verbose_output(values, "Create FreeBSD client:")
    verbose_output(values, "#{values['script']} -B -C -c freebsd10vm01 -e 00:50:56:26:92:d7 -a x86_64 -i 192.168.1.194 -n netbsd_10_0_x86_64")
    verbose_output(values, "Delete FreeBSD client:")
    verbose_output(values, "#{values['script']} -B -C -d freebsd10vm01")
    verbose_output(values, "")
  end
  if examples.match(/client|ps|all/)
    print_md(values, "Preseed-Client")
    verbose_output(values, "")
  end
  if examples.match(/client|js|all/)
    print_md(values, "Jumpstart-Client")
    verbose_output(values, "")
  end
  if examples.match(/client|ay|all/)
    print_md(values, "AutoYast-Client")
    verbose_output(values, "")
  end
  if examples.match(/client|vcsa|all/)
    print_md(values, "VCSA-Deployment")
    verbose_output(values, "")
  end
  if examples.match(/client|vs|all/)
    print_md(values, "vSphere-Client")
    verbose_output(values, "")
  end
  quit(values)
end

