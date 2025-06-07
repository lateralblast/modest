# frozen_string_literal: true

# Usage information

def print_usage_info(values)
  values['verbose'] = true
  values['output']  = 'text'
  option = ''
  info   = ''
  verbose_message(values, '')
  verbose_message(values, 'Options:')
  verbose_message(values, '')
  option_list = get_valid_values(values)
  option_list.each do |line|
    next unless line.match(/BOOLEAN/)

    next if line.match(/file_array/)

    info   = line.split(/# /)[1]
    option = line.split(/# /)[0]
    option = option.split(/--/)[1]
    option = option.split(/'/)[0]
    if option.length < 7
      verbose_message(values, "#{option}:\t\t\t#{info}")
    elsif option.length < 15
      verbose_message(values, "#{option}:\t\t#{info}")
    else
      verbose_message(values, "#{option}:\t#{info}")
    end
  end
  nil
end

def print_usage(values)
  case values['usage'].to_s
  when /help/
    print_help(values)
  when /option/
    print_usage_info(values)
  else
    print_help(values)
  end
  nil
end

def print_error_header(type)
  verbose_message(values, '')
  if type.length > 2
    warning_message(values, "Invalid #{type.capitalize} specified")
  else
    warning_message(values, "Invalid #{type.upcase} specified")
  end
  verbose_message(values, '')
  nil
end

def error_message(type, values)
  print_error_header(type)
  eval "[print_#{type}_types(option)]"
  quit(values)
end

def print_arch_types(values)
  verbose_message(values, '')
  verbose_message(values, 'Available Architectures:')
  verbose_message(values, '')
  verbose_message(values, 'i386   - 32 bit Intel/AMD')
  verbose_message(values, 'x86_64 - 64 bit Intel/AMD')
  verbose_message(values, 'sparc  - 64 bit SPARC') if values['vm'] =~ /ldom|zone/
  verbose_message(values, '')
  verbose_message(values, 'Example:')
  verbose_message(values, '')
  verbose_message(values, '--arch=x86_64')
  verbose_message(values, '')
  nil
end

def print_client_types(values)
  verbose_message(values, '')
  verbose_message(values, 'Refer to RFC1178 for valid host names')
  verbose_message(values, '')
  verbose_message(values, 'Example:')
  verbose_message(values, '')
  verbose_message(values, '--name = hostname')
  verbose_message(values, '')
  nil
end

def print_vm_types(values)
  verbose_message(values, 'Available VM types:')
  verbose_message(values, '')
  verbose_message(values, 'vbox   - VirtualBox')
  verbose_message(values, 'fusion - VMware Fusion')
  verbose_message(values, 'ldom   - Solaris 10/11 LDom (Logical Domain')
  verbose_message(values, 'lxc    - Linux Container')
  verbose_message(values, 'zone   - Solaris 10/11 Zone/Container')
  verbose_message(values, '')
  nil
end

def print_install_types(values)
  verbose_message(values, 'Available OS Install Types:')
  verbose_message(values, '')
  verbose_message(values, 'ai             - Automated Installer (Solaris 11)')
  verbose_message(values, 'ks/kickstart   - Kickstart (RedHat, CentOS, Scientific, Fedora)')
  verbose_message(values, 'js/jumpstart   - Jumpstart (Solaris 10 or earlier')
  verbose_message(values, 'ps/preseed     - Preseed (Ubuntu, Debian)')
  verbose_message(values, 'ay/autoyast    - Autoyast (SLES, SuSE, OpenSuSE)')
  verbose_message(values, 'vs/vsphere/esx - VSphere/ESX Kickstart')
  verbose_message(values, 'container      - Container (Sets install type to Zone on Solaris and LXC on Linux')
  verbose_message(values, 'zone           - Zone (Sets install type to Zone on Solaris and LXC on Linux')
  verbose_message(values, 'lxc            - Linux Container')
  verbose_message(values, 'xb/bsd         - OpenBSD/NetBSD')
  verbose_message(values, '')
  nil
end

def print_os_types(values)
  verbose_message(values, 'Available OS Types:')
  verbose_message(values, '')
  verbose_message(values,
                  'solaris       - Solaris (Sets install type to Jumpstart on Solaris 10, and AI on Solaris 11)')
  verbose_message(values, 'ubuntu        - Ubuntu Linux (Sets install type to Preseed)')
  verbose_message(values, 'debian        - Debian Linux (Sets install type to Preseed)')
  verbose_message(values, 'suse          - SuSE Linux (Sets install type to Autoyast)')
  verbose_message(values, 'sles          - SuSE Linux (Sets install type to Autoyast)')
  verbose_message(values, 'redhat        - Redhat Linux (Sets install type to Kickstart)')
  verbose_message(values, 'rhel          - Redhat Linux (Sets install type to Kickstart)')
  verbose_message(values, 'centos        - CentOS Linux (Sets install type to Kickstart)')
  verbose_message(values, 'fedora        - Fedora Linux (Sets install type to Kickstart)')
  verbose_message(values, 'scientific/sl - Scientific Linux (Sets install type to Kickstart)')
  verbose_message(values, 'vsphere/esx   - vSphere (Sets install type to Kickstart)')
  verbose_message(values, 'windows       - Windows (Incomplete)')
  verbose_message(values, '')
  nil
end

# Print a .md file

def print_md(values, md_file)
  md_file = "#{values['wikidir']}/#{md_file}.md"
  if File.directory?(values['wikidir']) || File.symlink?(values['wikidir'])
    if File.exist?(md_file)
      md_info = File.readlines(md_file)
      md_info&.each_key do |line|
        verbose_message(line) unless line.match(/```/)
      end
    else
      warning_message(values, "File: #{md_file} contains no information")
    end
  else
    values['verbose'] = 1
    #    warning_message(values, "Wiki directory '#{values['wikidir']}' does not exist")
    #    values['sudo'] = false
    #    message    = "Attempting to clone Wiki dir from: '"+values['wikiurl']+"' to: '"+values['wikidir']
    #    command    = "cd #{values['scriptdir']} ; git clone #{values['wikiurl']}"
    #    execute_command(values, message, command)
    #    verbose_message(values, "")
    #    ptint_md(md_file)
    quit(values)
  end
  nil
end

# Detailed usage

def print_examples(values)
  verbose_message(values, '')
  examples = values['method'] + values['type'] + values['vm']
  examples = 'all' unless examples.match(/[a-z,A-Z]/)
  if examples.match(/iso|all/)
    print_md(values, 'ISOs')
    verbose_message(values, '')
  end
  if examples.match(/packer|all/)
    print_md(values, 'Packer')
    verbose_message(values, '')
  end
  if examples.match(/all|server|dist|setup/)
    print_md(values, 'Distribution-Server-Setup')
    verbose_message(values, '')
  end
  if examples.match(/vbox|all|virtualbox/)
    print_md(values, 'VirtualBox')
    verbose_message(values, '')
  end
  if examples.match(/fusion|all/)
    print_md(values, 'VMware-Fusion')
    verbose_message(values, '')
  end
  if examples.match(/server|ai|all/)
    print_md(values, 'AI-Server')
    verbose_message(values, '')
  end
  if examples.match(/server|ay|all/)
    print_md(values, 'AutoYast-Server')
    verbose_message(values, '')
  end
  if examples.match(/server|ks|all/)
    print_md(values, 'Kickstart-Server')
    verbose_message(values, '')
  end
  if examples.match(/server|ps|all/)
    print_md(values, 'Preseed-Server')
    verbose_message(values, '')
  end
  if examples.match(/server|xb|ob|nb|all/)
    verbose_message(values, '*BSD server related examples:')
    verbose_message(values, '')
    verbose_message(values, 'List all *BSD services:')
    verbose_message(values, "#{values['script']} -B -S -L")
    verbose_message(values, 'Configure all *BSD services:')
    verbose_message(values, "#{values['script']} -B -S")
    verbose_message(values, 'Configure a NetBSD service (from ISO):')
    verbose_message(values, "#{values['script']} -B -S -f /export/isos/install55-i386.iso")
    verbose_message(values, 'Configure a FreeBSD service (from ISO):')
    verbose_message(values, "#{values['script']} -B -S -f /export/isos/FreeBSD-10.0-RELEASE-amd64-dvd1.iso")
    verbose_message(values, '')
  end
  if examples.match(/server|js|all/)
    print_md(values, 'Jumpstart-Server')
    verbose_message(values, '')
  end
  if examples.match(/server|vs|all/)
    print_md(values, 'vSphere-Server')
    verbose_message(values, '')
  end
  if examples.match(/maint|all/)
    verbose_message(values, 'Maintenance related examples:')
    verbose_message(values, '')
    verbose_message(values, 'Configure AI client services:')
    verbose_message(values, "#{values['script']} -A -G -C -a i386")
    verbose_message(values, 'Enable AI proxy:')
    verbose_message(values, "#{values['script']} -A -G -W -n sol_11_1")
    verbose_message(values, 'Disable AI proxy:')
    verbose_message(values, "#{values['script']} -A -G -W -z sol_11_1")
    verbose_message(values, 'Configure AI alternate repo:')
    verbose_message(values, "#{values['script']} -A -G -R")
    verbose_message(values, 'Unconfigure AI alternate repo:')
    verbose_message(values, "#{values['script']} -A -G -R -z sol_11_1_alt")
    verbose_message(values, 'Configure Kickstart alternate repo:')
    verbose_message(values, "#{values['script']} -K -G -R -n centos_5_10_x86_64")
    verbose_message(values, 'Unconfigure Kickstart alternate repo:')
    verbose_message(values, "#{values['script']} -K -G -R -z centos_5_10_x86_64")
    verbose_message(values, 'Enable Kickstart alias:')
    verbose_message(values, "#{values['script']} -K -G -W -n centos_5_10_x86_64")
    verbose_message(values, 'Disable Kickstart alias:')
    verbose_message(values, "#{values['script']} -K -G -W -z centos_5_10_x86_64")
    verbose_message(values, 'Import Kickstart PXE files:')
    verbose_message(values, "#{values['script']} -K -G -P -n centos_5_10_x86_64")
    verbose_message(values, 'Delete Kickstart PXE files:')
    verbose_message(values, "#{values['script']} -K -G -P -z centos_5_10_x86_64")
    verbose_message(values, 'Unconfigure Kickstart client PXE:')
    verbose_message(values, "#{values['script']} -K -G -P -d centos510vm01")
    verbose_message(values, '')
  end
  if examples.match(/zone|all/)
    verbose_message(values, 'Solaris Zone related examples:')
    verbose_message(values, '')
    verbose_message(values, 'List Zones:')
    verbose_message(values, "#{values['script']} -Z -L")
    verbose_message(values, 'Configure Zone:')
    verbose_message(values, "#{values['script']} -Z -c sol11u01z01 -i 192.168.1.181")
    verbose_message(values, 'Configure Branded Zone:')
    verbose_message(values,
                    "#{values['script']} -Z -c sol10u11z01 -i 192.168.1.171 -f /export/isos/solaris-10u11-x86.bin")
    verbose_message(values, 'Configure Branded Zone:')
    verbose_message(values, "#{values['script']} -Z -c sol10u11z02 -i 192.168.1.172 -n sol_10_11_i386")
    verbose_message(values, 'Delete Zone:')
    verbose_message(values, "#{values['script']} -Z -d sol11u01z01")
    verbose_message(values, 'Boot Zone:')
    verbose_message(values, "#{values['script']} -Z -b sol11u01z01")
    verbose_message(values, 'Boot Zone (connect to console):')
    verbose_message(values, "#{values['script']} -Z -b sol11u01z01 -B")
    verbose_message(values, 'Halt Zone:')
    verbose_message(values, "#{values['script']} -Z -s sol11u01z01")
    verbose_message(values, '')
  end
  if examples.match(/ldom|all/)
    verbose_message(values, 'Oracle VM Server for SPARC related examples:')
    verbose_message(values, '')
    verbose_message(values, 'Configure Control Domain:')
    verbose_message(values, "#{values['script']} -O -S")
    verbose_message(values, 'List Guest Domains:')
    verbose_message(values, "#{values['script']} -O -L")
    verbose_message(values, 'Configure Guest Domain:')
    verbose_message(values, "#{values['script']} -O -c sol11u01gd01")
    verbose_message(values, '')
  end
  if examples.match(/lxc|all/)
    verbose_message(values, 'Linux Container related examples:')
    verbose_message(values, '')
    verbose_message(values, 'Configure Container Services:')
    verbose_message(values, "#{values['script']} -Z -S")
    verbose_message(values, 'List Containers:')
    verbose_message(values, "#{values['script']} -Z -L")
    verbose_message(values, 'Configure Standard Container:')
    verbose_message(values, "#{values['script']} -Z -c ubuntu1310lx01 -i 192.168.1.206")
    verbose_message(values, 'Execute post install script:')
    verbose_message(values, "#{values['script']} -Z -p ubuntu1310lx01")
    verbose_message(values, '')
  end
  if examples.match(/client|ks|all/)
    print_md(values, 'Kickstart-Client')
    verbose_message(values, '')
  end
  if examples.match(/client|ai|all/)
    print_md(values, 'AI-Client')
    verbose_message(values, '')
  end
  if examples.match(/client|xb|ob|nb|all/)
    verbose_message(values, '*BSD client related examples:')
    verbose_message(values, '')
    verbose_message(values, 'List *BSD clients:')
    verbose_message(values, "#{values['script']} -B -C -L")
    verbose_message(values, 'Create OpenBSD client:')
    verbose_message(values,
                    "#{values['script']} -B -C -c openbsd55vm01 -e 00:50:56:26:92:d8 -a x86_64 -i 192.168.1.193 -n openbsd_5_5_x86_64")
    verbose_message(values, 'Create FreeBSD client:')
    verbose_message(values,
                    "#{values['script']} -B -C -c freebsd10vm01 -e 00:50:56:26:92:d7 -a x86_64 -i 192.168.1.194 -n netbsd_10_0_x86_64")
    verbose_message(values, 'Delete FreeBSD client:')
    verbose_message(values, "#{values['script']} -B -C -d freebsd10vm01")
    verbose_message(values, '')
  end
  if examples.match(/client|ps|all/)
    print_md(values, 'Preseed-Client')
    verbose_message(values, '')
  end
  if examples.match(/client|js|all/)
    print_md(values, 'Jumpstart-Client')
    verbose_message(values, '')
  end
  if examples.match(/client|ay|all/)
    print_md(values, 'AutoYast-Client')
    verbose_message(values, '')
  end
  if examples.match(/client|vcsa|all/)
    print_md(values, 'VCSA-Deployment')
    verbose_message(values, '')
  end
  if examples.match(/client|vs|all/)
    print_md(values, 'vSphere-Client')
    verbose_message(values, '')
  end
  quit(values)
end
