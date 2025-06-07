# frozen_string_literal: true

# Post process values after handling defaults

def post_process_values(values)
  # Print help before anything if required
  if values['help']
    values['output'] = 'text'
    print_help(values)
    quit(values)
  end
  # Print version
  if values['version']
    values['output'] = 'text'
    print_version(values)
    quit(values)
  end
  # Handle when running in defaults (non interactive mode)
  if (values['defaults'] == true) && (values['dhcp'] == false)
    %w[cidr ip nameserver vmgateway].each do |item|
      unless values[item].to_s.match(/[0-9]/)
        warning_message(values, "No value for #{item} given")
        quit(values)
      end
    end
  end
  # Set up question associative array
  values['answers'] = {}
  values['order'] = []
  values['i_struct'] = {}
  values['i_order']  = []
  values['u_struct'] = {}
  values['u_order']  = []
  values['g_struct'] = {}
  values['g_order']  = []
  # Handle method switch
  if values['method'] != values['empty']
    values['method'] = values['method'].downcase
    values['method'] = values['method'].gsub(/vsphere/, 'vs')
    values['method'] = values['method'].gsub(/jumpstart/, 'js')
    values['method'] = values['method'].gsub(/kickstart/, 'ks')
    values['method'] = values['method'].gsub(/preseed/, 'ps')
    values['method'] = values['method'].gsub(/cloudinit|cloudconfig|subiquity/, 'ci')
  end
  # Handle hostname
  values['hostname'] = values['name'] if values['name'] && !values['hostname']
  # Handle groups
  values['groups'] = values['group'] if values['group'] && !values['groups']
  # Handle password/crypt
  %w[adminpassword rootpassword].each do |user_password|
    next if values[user_password]

    values[user_password] = values['userpassword'] if values['userpassword']
  end
  %w[admincrypt rootcrypt].each do |user_crypt|
    next if values[user_crypt]

    values[user_crypt] = values['usercrypt'] if values['usercrypt']
  end
  %w[user admin root].each do |user|
    user_password = "#{user}password"
    user_crypt    = "#{user}crypt"
    next if values[user_crypt]

    values[user_crypt] = get_password_crypt(values[user_password]) if values[user_password]
  end
  # Handle SSH key
  if !values['sshkey'] && values['sshkeyfile'] && File.exist?(values['sshkeyfile'])
    file_array = IO.readlines(values['sshkeyfile'])
    values['sshkey'] = file_array[0]
  end
  # Handle values switch
  if values['options'].to_s.match(/[a-z]/)
    options = if values['options'].to_s.match(/,/)
                values['options'].to_s.split(',')
              else
                [values['options'].to_s]
              end
    options.each do |item|
      values[item] = true
    end
  end
  # Handle alternate values
  %w[list create delete start stop restart build].each do |switch|
    values['action'] = switch if values[switch] == true
  end
  values['bridge'] = values['netbridge'] if values['netbridge']
  values['size'] = values['disksize'] if values['disksize']
  # Handle import
  if values['import'] == true
    if values['vm']
      values['action'] = 'import' unless values['vm'].to_s.match(/kvm/)
    else
      values['action'] = 'import'
    end
  end
  values
end

# Clean up values

def cleanup_values(values, defaults)
  values['host-os-packages'] = defaults['host-os-packages']
  values['vmapp'] = 'Parallels Desktop' if values['vm'].to_s.match(/parallels/)
  values['reboot'] = false if values['noreboot'] == true
  # Backward compatibility for old --client switch
  values['name'] = values['client'].to_s if values['client'] && values['client'] != values['empty']
  # Handle OS option
  if values['os-type'] != values['empty']
    values['os-type'] = values['os-type'].to_s.downcase
    values['os-type'] = values['os-type'].gsub(/^win$/, 'windows')
    values['os-type'] = values['os-type'].gsub(/^sol$/, 'solaris')
  end
  # Some clean up of parameters
  if values['method'] != values['empty']
    values['method'] = values['method'].to_s.downcase
    values['method'] = values['method'].to_s.gsub(/kickstart/, 'js')
    values['method'] = values['method'].to_s.gsub(/preseed/, 'ps')
    values['method'] = values['method'].to_s.gsub(/jumpstart/, 'js')
    values['method'] = values['method'].to_s.gsub(/autoyast/, 'ay')
    values['method'] = values['method'].to_s.gsub(/vsphere|esx/, 'vs')
  end
  # Handle OS switch
  if values['os-type'] != values['empty']
    values['os-type'] = values['os-type'].to_s.downcase
    values['os-type'] = values['os-type'].to_s.gsub(/windows/, 'win')
    values['os-type'] = values['os-type'].to_s.gsub(/scientificlinux|scientific/, 'sl')
    values['os-type'] = values['os-type'].to_s.gsub(/oel/, 'oraclelinux')
    values['os-type'] = values['os-type'].to_s.gsub(/esx|esxi|vsphere/, 'vmware')
    values['os-type'] = values['os-type'].to_s.gsub(/^suse$/, 'opensuse')
    values['os-type'] = values['os-type'].to_s.gsub(/solaris/, 'sol')
    values['os-type'] = values['os-type'].to_s.gsub(/redhat/, 'rhel')
  end
  # Handle VMware Workstation
  values['vm'] = 'fusion' if values['vm'].to_s.match(/vmware|workstation/)
  values = get_fusion_hostonly_network(values) if values['vm'].to_s.match(/fusion/) && values['vmnetwork'].to_s.match(/hostonly/)
  # Handle keys
  values['copykeys'] = values['nokeys'] != true
  # Handle port switch
  if values['ports'] != values['empty']
    values['from'] = values['ports'].to_s
    values['to']   = values['ports'].to_s
  end
  values
end

# Process values based on defaults

def process_values(values, defaults)
  # Process parameters
  raw_params = IO.readlines(defaults['scriptfile']).grep(/REQUIRED|BOOLEAN/).join.split(/\n/)
  raw_params.each do |raw_param|
    next unless raw_param.match(/\[/) && !raw_param.match(/stdout|^raw_params/)

    raw_param = raw_param.split(/--/)[1].split(/'/)[0]
    if values[raw_param].nil?
      values[raw_param] = if defaults[raw_param].to_s.match(%r{[A-Z]|[a-z]|[0-9]|^/})
                            defaults[raw_param]
                          else
                            defaults['empty']
                          end
    end
    values['output'] = 'text'
    information_message(values, "Setting value for #{raw_param} to #{values[raw_param]}")
  end
  # Do a final check through defaults
  defaults.each_key do |param|
    next unless values[param].nil?

    values[param] = defaults[param]
    values['output'] = 'text'
    information_message(values, "Setting value for #{param} to #{values[param]}")
  end
  if (values['action'] == 'info') && values['info'].match(/os/) && param.match(/^os/)
    values['output'] = 'text'
    values['verbose'] = true
    information_message(values, "Parameter #{param} is #{values[param]}")
    values['verbose'] = false
  end
  # Check some actions - We may be able to process without action switch
  %w[info check].each do |action|
    next unless values['action'] == values['empty']

    values['action'] = action if values[action] != values['empty']
  end
  values
end

# Hadnle OS values

def handle_os_values(values)
  # Check OS switch
  values = get_install_service_from_file(values) if (values['os-type'] == values['empty'] || values['method'] == values['empty'] || values['release'] == values['empty'] || values['arch'] == values['empty']) && (!values['file'] == values['empty'])
  if values['os-type'] != values['empty']
    case values['os-type']
    when /suse|sles/
      values['method'] = 'ay'
    when /vsphere|esx|vmware/
      values['method'] = 'vs'
    when /kickstart|redhat|rhel|fedora|sl|scientific|ks|centos/
      values['method'] = 'ks'
    when /ubuntu|debian/
      values['method'] = if values['file'].to_s.match(/cloudimg/)
                           'ci'
                         else
                           'ps'
                         end
    when /purity/
      values['method'] = 'ps'
      if values['memory'].to_s.match(/#{values['memory']}/)
        values['vcpus'] = '2'
        values['memory'] = if values['release'].to_s.match(/^5\.2/)
                             '12288'
                           else
                             '8192'
                           end
        values['memory'] = values['memory']
        values['vcpus']  = values['vcpus']
      end
    when /sol/
      values['method'] = if values['release'].to_i < 11
                           'js'
                         else
                           'ai'
                         end
    end
  end
  # Check we have a setup file for purity
  if (values['os-type'] == 'purity') && (values['setup'] == values['empty'])
    warning_message(values, 'No setup file specified')
    quit(values)
  end
  values
end

# Handle VM values

def handle_vm_values(values)
  if values['vm'] != values['empty']
    values['vm'] = values['vm'].gsub(/virtualbox/, 'vbox')
    values['vm'] = values['vm'].gsub(/mp/, 'multipass')
    values['service'] = $default_aws_type if values['vm'].to_s.match(/aws/) && (values['service'] == values['empty'])
  end
  if values['vm'] != values['empty']
    values['mode'] = 'client'
    values = check_local_config(values)
    case values['vm']
    when /parallels/
      values['status'] = check_parallels_is_installed(values)
      handle_vm_install_status(values)
      values['vm']   = 'parallels'
      values['sudo'] = false
      values['size'] = values['size'].gsub(/G/, '000')
      if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
        values['hostonlyip'] = '10.211.55.1'
        values['vmgateway']  = '10.211.55.1'
      else
        values['hostonlyip'] = '192.168.55.1'
        values['vmgateway']  = '192.168.55.1'
      end
    when /multipass|mp/
      values['vm'] = 'multipass'
      if values['os-name'].to_s.match(/Darwin/)
        values = check_vbox_is_installed(values)
        values['hostonlyip'] = '192.168.64.1'
        values['vmgateway']  = '192.168.64.1'
      end
      check_multipass_is_installed(values)
    when /virtualbox|vbox/
      values = check_vbox_is_installed(values)
      handle_vm_install_status(values)
      values['vm']   = 'vbox'
      values['sudo'] = false
      values['size'] = values['size'].gsub(/G/, '000')
      values['hostonlyip'] = '192.168.56.1'
      values['vmgateway']  = '192.168.56.1'
    when /kvm/
      values['status'] = check_kvm_is_installed(values)
      handle_vm_install_status(values)
      values['hostonlyip'] = '192.168.122.1'
      values['vmgateway']  = '192.168.122.1'
    when /vmware|fusion/
      handle_vm_install_status(values)
      check_fusion_vm_promisc_mode(values)
      values['sudo'] = false
      values['vm']   = 'fusion'
    when /zone|container|lxc/
      values['vm'] = if values['host-os-uname'].to_s.match(/SunOS/)
                       'zone'
                     else
                       'lxc'
                     end
    when /ldom|cdom|gdom/
      if $os_arch.downcase.match(/sparc/) && values['host-os-uname'].to_s.match(/SunOS/)
        values['release'] = values['host-os-unamer'] if values['release'] == values['empty']
        if values['host-os-unamer'].match(/10|11/)
          values['vm'] = 'gdom' if values['mode'].to_s.match(/client/)
          values['vm'] = 'cdom' if values['mode'].to_s.match(/server/)
        else
          warning_message(values, 'LDoms require Solaris 10 or 11')
        end
      else
        warning_message(values, 'LDoms require Solaris on SPARC')
        quit(values)
      end
    end
    print_valid_list(values, "Warning:\tInvalid VM type", values['valid-vm']) if !values['valid-vm'].to_s.downcase.match(/#{values['vm']}/) && !values['action'].to_s.match(/list/)
    information_message(values, "Setting VM type to #{values['vm']}")
  else
    values['vm'] = 'none'
  end
  if values['vm'] != values['empty'] || values['method'] != values['empty']
    values['model'] = if values['model'] != values['empty']
                        values['model'].downcase
                      elsif values['arch'].to_s.match(/i386|x86|x86_64|x64|amd64/)
                        'vmware'
                      else
                        ''
                      end
    information_message(values, "Setting model to #{values['model']}") if values['verbose'] == true && values['model']
  end
  # Handle gateway if not empty
  if values['vmgateway'] != values['empty']
    values['vmgateway'] = values['vmgateway']
  elsif values['vmnetwork'] == 'hostonly'
  end
  # Change VM disk size
  if values['size'] != values['empty']
    values['size'] = values['size']
    values['size'] = "#{values['size']}G" unless values['size'].to_s.match(/G$/)
  end
  # Get MAC address if specified
  if values['mac'] != values['empty']
    values['vm'] = 'none' unless values['vm']
    values['mac'] = check_install_mac(values)
    information_message(values, "Setting client MAC address to #{values['mac']}")
  else
    values['mac'] = ''
  end
  values
end

# Handle SSH key values

def handle_ssh_key_values(values)
  # Handle keyfile switch
  if (values['keyfile'] != values['empty']) && !File.exist?(values['keyfile'])
    warning_message(values, "Key file #{values['keyfile']} does not exist")
    quit(values) if values['action'].to_s.match(/create/) && !option['type'].to_s.match(/key/)
  end
  # Handle sshkeyfile switch
  if (values['sshkeyfile'] != values['empty']) && !File.exist?(values['sshkeyfile'])
    warning_message(values, "SSH Key file #{values['sshkeyfile']} does not exist")
    check_ssh_keys(values) if values['action'].to_s.match(/create/)
  end
  values
end

# Handle memory values

def handle_memory_values(values)
  if (values['memory'] == values['empty']) && (values['vm'] != values['empty'])
    values['memory'] = '4096' if values['os-type'].to_s.match(/vs|esx|vmware|vsphere/) || values['method'].to_s.match(/vs|esx|vmware|vsphere/)
    if values['os-type'] != values['empty']
      values['memory'] = '2048' if values['os-type'].to_s.match(/sol/) && (values['release'].to_i > 9)
    elsif values['method'] == 'ai'
      values['memory'] = '2048'
    end
  end
  values
end

# Handle OS values

def handle_os_values(values)
  if (values['os-type'] == values['empty']) && (values['vm'] != values['empty']) && values['action'].to_s.match(/add|create/) && (values['method'] == values['empty']) && !values['vm'].to_s.match(/ldom|cdom|gdom|aws|mp|multipass/) && !values['type'].to_s.match(/network/)
    warning_message(values, 'No OS or install method specified when creating VM')
    quit(values)
  end
  values
end

# Handle release values

def handle_release_values(values)
  if values['release'].to_s.match(/[0-9]/)
    if values['type'].to_s.match(/packer/) && values['action'].to_s.match(/build|delete|import/)
      values['release'] = ''
    else
      values['vm'] = 'none' if values['vm'] == values['empty']
      if values['vm'].to_s.match(/zone/) && values['host-os-unamer'].match(/10|11/) && !values['release'].to_s.match(/10|11/)
        warning_message(values, "Invalid release number: #{values['release']}")
        quit(values)
      end
    end
  elsif values['vm'].to_s.match(/zone/)
    values['release'] = values['host-os-unamer']
  else
    values['release'] = values['empty']
  end
  information_message(values, "Setting Operating System version to #{values['release']}") if values['verbose'] == true && values['release']
  values
end

# Handle console values

def handle_console_values(values)
  if values['console'] != values['empty']
    case values['console']
    when /x11/
      values['text'] = false
    when /serial/
      values['serial'] = true
      values['text']   = true
    when /headless/
      values['headless'] = true
    else
      values['text'] = true
    end
  else
    values['console'] = 'text'
    values['text']    = false
  end
  values
end

# Handle import/build action

def handle_import_build_action(values)
  if values['action'].to_s.match(/build|import/)
    if values['type'] == values['empty']
      information_message(values, 'Setting Install Service to Packer')
      values['type'] = 'packer'
    end
    if values['vm'] == values['empty']
      if values['name'] == values['empty']
        warning_message(values, 'No client name specified')
        quit(values)
      end
      values['vm'] = get_client_vm_type_from_packer(values)
    end
    if values['vm'] == values['empty']
      warning_message(values, 'VM type not specified')
      quit(values)
    elsif !values['vm'].to_s.match(/vbox|fusion|aws|kvm|parallels|qemu/)
      warning_message(values, 'Invalid VM type specified')
      quit(values)
    end
  end
  values
end

# Handle file values

def handle_file_values(values)
  if values['file'] != values['empty']
    values['file'] = values['vboxadditions'] if values['vm'] == 'vbox' && values['file'] == 'tools'
    if !values['action'].to_s.match(/download/) && !File.exist?(values['file']) && !values['file'].to_s.match(/^http/)
      warning_message(values, "File #{values['file']} does not exist")
      quit(values) if !values['test'] == true
    end
    values['type'] = get_install_type_from_file(values) if values['action'].to_s.match(/deploy/) && (values['type'] == values['empty'])
    if values['file'] != values['empty'] && values['action'].to_s.match(/create|add/)
      if values['method'] == values['empty']
        values['method'] = get_install_method_from_iso(values)
        if values['method'].nil?
          verbose_message(values, 'Could not determine install method')
          quit(values)
        end
      end
      if values['type'] == values['empty']
        values['type'] = get_install_type_from_file(values)
        information_message(values, "Setting install type to #{values['type']}")
      end
    end
  end
  values
end

# Handle mount values

def handle_mount_values(values, defaults)
  if values['file'].to_s.match(/[A-Z]|[a-z]|[0-9]/) && !values['action'].to_s.match(/list/)
    values['sudo'] = defaults['sudo']
    values['host-os-uname'] = defaults['host-os-uname']
    values['mountdir'] = defaults['mountdir'] unless values['mountdir']
    values['output'] = defaults['output'] unless values['output']
    values['executehost'] = defaults['executehost']
    values = get_install_service_from_file(values) if values['file'] != defaults['empty']
  end
  values
end

# Handle admin user values

def handle_admin_user_values(values)
  if values['adminuser'] == values['empty']
    if values['action']
      if values['action'].to_s.match(/connect|ssh/)
        values['adminuser'] = if values['vm']
                                if values['vm'].to_s.match(/aws/)
                                  values['awsuser']
                                else
                                  `whoami`.chomp
                                end
                              elsif values['id']
                                values['awsuser']
                              else
                                `whoami`.chomp
                              end
      end
    else
      values['adminuser'] = `whoami`.chomp
    end
  end
  values
end

# Handle arch values

def handle_arch_values(values)
  if values['arch'] != values['empty']
    values['arch'] = values['arch'].downcase
    values['arch'] = 'sparc' if values['arch'].to_s.match(/sun4u|sun4v/)
    values['arch'] = 'x86_64' if values['os-type'].to_s.match(/vmware/)
    values['arch'] = 'i386' if values['os-type'].to_s.match(/bsd/)
  end
  values
end

# Handle install shell values

def handle_install_shell_values(values)
  if values['shell'] == values['empty']
    values['shell'] = if values['os-type'].to_s.match(/win/)
                        'winrm'
                      else
                        'ssh'
                      end
  end
  values
end

# Handle share values

def handle_share_values(values)
  if values['share'] != values['empty']
    unless File.directory?(values['share'])
      warning_message(values, "Share point #{values['share']} does not exist")
      quit(values)
    end
    values['mount'] = File.basename(values['share']) if values['mount'] == values['empty']
    information_message(values, "Sharing #{values['share']}")
    information_message(values, "Setting mount point to #{values['mount']}")
  end
  values
end

# Handle timezone values

def handle_timezone_values(values)
  if (values['timezone'] == values['empty']) && (values['os-type'] != values['empty'])
    values['timezone'] = if values['os-type'].to_s.match(/win/)
                           values['time']
                         else
                           values['timezone']
                         end
  end
  values
end

# Handle clone values

def handle_clone_values(values)
  if values['clone'] == values['empty']
    if values['action'] == 'snapshot'
      clone_date = `date`.chomp.downcase.gsub(/ |:/, '_')
      values['clone'] = "#{values['name']}-#{clone_date}"
    end
    information_message(values, "Setting clone name to #{values['clone']}") if values['verbose'] == true && values['clone']
  end
  values
end

# Handle size values

def handle_size_values(values)
  if !values['size'] == values['empty']
    values['size'] = $default_vcsa_size if values['type'].to_s.match(/vcsa/) && !values['size'].to_s.match(/[0-9]/)
  elsif !values['vm'].to_s.match(/aws/) && !values['type'].to_s.match(/cloud|cf|stack/)
    values['size'] = if values['type'].to_s.match(/vcsa/)
                       $default_vcsa_size
                     else
                       values['size']
                     end
  end
  values
end

# Handle power state values

def handle_power_state_values(values)
  values['powerstate'] = 'reboot' if values['reboot'] == true
  values['powerstate'] = 'noreboot' if values['noreboot'] == true
  values
end

# Handle netowkr values

def handle_network_values(values)
  if (values['dhcp'] == false) && (values['defaults'] == true)
    %w[ip vmgateway nameserver].each do |address|
      check_ip_is_valid(values, values[address], address)
    end
    check_mac_is_valid(values, values['mac']) unless values['mac'] == values['empty']
  end
  values
end
