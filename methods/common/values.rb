# Hdle values

def handle_values(values)
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
  # Set up question associative array
  values['q_struct'] = {}
  values['q_order']  = []
  values['i_struct'] = {}
  values['i_order']  = []
  values['u_struct'] = {}
  values['u_order']  = []
  values['g_struct'] = {}
  values['g_order']  = []
  # Handle method switch
  if values['method'] != values['empty']
    values['method'] = values['method'].downcase
    values['method'] = values['method'].gsub(/vsphere/, "vs")
    values['method'] = values['method'].gsub(/jumpstart/, "js")
    values['method'] = values['method'].gsub(/kickstart/, "ks")
    values['method'] = values['method'].gsub(/preseed/, "ps")
    values['method'] = values['method'].gsub(/cloudinit|cloudconfig|subiquity/, "ci")
  end 
  # Handle hostname
  if values['name']
    if not values['hostname']
      values['hostname'] = values['name']
    end
  end
  # Handle groups
  if values['group']
    if not values['groups']
      value['groups'] = value['group']
    end
  end
  # Handle password/crypt
  [ 'adminpassword', 'rootpassword' ].each do |user_password|
    if not values[user_password]
      if values['userpassword']
        values[user_password] = values['userpassword']
      end
    end
  end
  [ 'admincrypt', 'rootcrypt' ].each do |user_crypt|
    if not values[user_crypt]
      if values['usercrypt']
        values[user_crypt] = values['usercrypt']
      end
    end
  end
  [ 'user', 'admin', 'root' ].each do |user|
    user_password = "#{user}password"
    user_crypt    = "#{user}crypt"
    if not values[user_crypt]
      if values[user_password]
        values[user_crypt] = get_password_crypt(values[user_password]) 
      end
    end
  end
  # Handle SSH key
  if not values['sshkey']
    if values['sshkeyfile']
      if File.exist?(values['sshkeyfile'])
        file_array = IO.readlines(values['sshkeyfile'])
        values['sshkey'] = file_array[0]
      end
    end
  end
  # Handle values switch
  if values['options'].to_s.match(/[a-z]/)
    if values['options'].to_s.match(/\,/)
      options = values['options'].to_s.split(",")
    else
      options = [ values['options'].to_s ]
    end
    options.each do |item|
      values[item] = true
    end
  end
  # Handle alternate values
  [ "list", "create", "delete", "start", "stop", "restart", "build" ].each do |switch|
    if values[switch] == true
      values['action'] = switch
    end
  end
  if values['netbridge']
    values['bridge'] = values['netbridge']
  end
  if values['disksize']
    values['size'] = values['disksize']
  end
  # Handle import
  if values['import'] == true
    if values['vm']
      if not values['vm'].to_s.match(/kvm/)
        values['action'] = "import"
      end
    else
      values['action'] = "import"
    end
  end
  return values  
end

# Clean up values

def cleanup_values(values, defaults)
  values['host-os-packages'] = defaults['host-os-packages']
  if values['vm'].to_s.match(/parallels/)
    values['vmapp'] = "Parallels Desktop"
  end
  if values['noreboot'] == true
    values['reboot'] = false
  end
  # Backward compatibility for old --client switch
  if values['client'] && values['client'] != values['empty']
    values['name'] = values['client'].to_s
  end
  # Handle OS option
  if values['os-type'] != values['empty']
    values['os-type'] = values['os-type'].to_s.downcase
    values['os-type'] = values['os-type'].gsub(/^win$/, "windows")
    values['os-type'] = values['os-type'].gsub(/^sol$/, "solaris")
  end
  # Some clean up of parameters
  if values['method'] != values['empty']
    values['method'] = values['method'].to_s.downcase
    values['method'] = values['method'].to_s.gsub(/kickstart/, "js")
    values['method'] = values['method'].to_s.gsub(/preseed/, "ps")
    values['method'] = values['method'].to_s.gsub(/jumpstart/, "js")
    values['method'] = values['method'].to_s.gsub(/autoyast/, "ay")
    values['method'] = values['method'].to_s.gsub(/vsphere|esx/, "vs")
  end
  # Handle OS switch
  if values['os-type'] != values['empty']
    values['os-type'] = values['os-type'].to_s.downcase
    values['os-type'] = values['os-type'].to_s.gsub(/windows/, "win")
    values['os-type'] = values['os-type'].to_s.gsub(/scientificlinux|scientific/, "sl")
    values['os-type'] = values['os-type'].to_s.gsub(/oel/, "oraclelinux")
    values['os-type'] = values['os-type'].to_s.gsub(/esx|esxi|vsphere/, "vmware")
    values['os-type'] = values['os-type'].to_s.gsub(/^suse$/, "opensuse")
    values['os-type'] = values['os-type'].to_s.gsub(/solaris/ ,"sol")
    values['os-type'] = values['os-type'].to_s.gsub(/redhat/, "rhel")
  end
  # Handle VMware Workstation
  if values['vm'].to_s.match(/vmware|workstation/)
    values['vm'] = "fusion"
  end
  if values['vm'].to_s.match(/fusion/) and values['vmnetwork'].to_s.match(/hostonly/)
    values = get_fusion_hostonly_network(values)
  end
  # Handle keys
  if values['nokeys'] == true
    values['copykeys'] = false
  else
    values['copykeys'] = true
  end
  # Handle port switch
  if values['ports'] != values['empty']
    values['from'] = values['ports'].to_s
    values['to']   = values['ports'].to_s
  end
  return values
end

# Process values based on defaults

def process_values(values, defaults)
  # Process parameters
  raw_params = IO.readlines(defaults['scriptfile']).grep(/REQUIRED|BOOLEAN/).join.split(/\n/)
  raw_params.each do |raw_param|
    if raw_param.match(/\[/) && !raw_param.match(/stdout|^raw_params/)
      raw_param = raw_param.split(/--/)[1].split(/'/)[0]
      if !values[raw_param]
        if defaults[raw_param].to_s.match(/[A-Z]|[a-z]|[0-9]/)
          values[raw_param] = defaults[raw_param]
        else
          values[raw_param] = defaults['empty']
        end
      end
      if values['verbose'] == true
        values['output'] = "text"
        verbose_output(values, "Information:\tSetting option #{raw_param} to #{values[raw_param]}")
      end
    end
  end
  # Do a final check through defaults
  defaults.each do |param, value|
    if !values[param]
      values[param] = defaults[param]
      if values['verbose'] == true
        values['output'] = "text"
        verbose_output(values, "Information:\tSetting option #{param} to #{values[param]}")
      end
    end
    if values['action'] == "info"
      if values['info'].match(/os/)
        if param.match(/^os/)
          values['verbose'] = true
          verbose_output(values, "Information:\tParameter #{param} is #{values[param]}")
          values['verbose'] = false
        end
      end
    end
  end
  # Check some actions - We may be able to process without action switch
  [ "info", "check" ].each do |action|
    if values['action'] == values['empty']
      if values[action] != values['empty']
        values['action'] = action
      end
    end
  end
  # Do some more checks
  if values['vm'] != values['empty']
    if values['action'].to_s.match(/create/)
      if values['dhcp'] == false
        if values['file'] != values['empty']
          if values['type'] != "service"
            if values['ip'] == values['empty']
              if !values['vmnetwork'].to_s.match(/nat/)
                verbose_output(values, "Warning:\tNo IP specified and DHCP not specified")
                quit(values)
              end
            end
          end
        end
      end
    end
  end
  return values
end

# Hadnle OS values

def handle_os_values(values)
  # Check OS switch
  if values['os-type'] == values['empty'] || values['method'] == values['empty'] || values['release'] == values['empty'] || values['arch'] == values['empty']
    if !values['file'] == values['empty']
      values = get_install_service_from_file(values)
    end
  end
  if values['os-type'] != values['empty']
    case values['os-type']
    when /suse|sles/
      values['method'] = "ay"
    when /vsphere|esx|vmware/
      values['method'] = "vs"
    when /kickstart|redhat|rhel|fedora|sl|scientific|ks|centos/
      values['method'] = "ks"
    when /ubuntu|debian/
      if values['file'].to_s.match(/cloudimg/)
        values['method'] = "ci"
      else
        values['method'] = "ps"
      end
    when /purity/
      values['method'] = "ps"
      if values['memory'].to_s.match(/#{values['memory']}/)
        values['vcpus'] = "2"
        if values['release'].to_s.match(/^5\.2/)
          values['memory'] = "12288"
        else
          values['memory'] = "8192"
        end
        values['memory'] = values['memory']
        values['vcpus']  = values['vcpus']
      end
    when /sol/
      if values['release'].to_i < 11
        values['method'] = "js"
      else
        values['method'] = "ai"
      end
    end
  end
  # Check we have a setup file for purity
  if values['os-type'] == "purity"
    if values['setup'] == values['empty']
      verbose_output(values, "Warning:\tNo setup file specified")
      quit(values)
    end
  end
  return values
end

# Handle VM values

def handle_vm_values(values)
  if values['vm'] != values['empty']
    values['mode'] = "client"
    values = check_local_config(values)
    case values['vm']
    when /parallels/
      values['status'] = check_parallels_is_installed(values)
      handle_vm_install_status(values)
      values['vm']   = "parallels"
      values['sudo'] = false
      values['size'] = values['size'].gsub(/G/, "000")
      if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
        values['hostonlyip'] = "10.211.55.1"
        values['vmgateway']  = "10.211.55.1"
      else
        values['hostonlyip'] = "192.168.55.1"
        values['vmgateway']  = "192.168.55.1"
      end
    when /multipass|mp/
      values['vm'] = "multipass"
      if values['os-name'].to_s.match(/Darwin/)
        values = check_vbox_is_installed(values)
        values['hostonlyip'] = "192.168.64.1"
        values['vmgateway']  = "192.168.64.1"
      end
      check_multipass_is_installed(values)
    when /virtualbox|vbox/
      values = check_vbox_is_installed(values)
      handle_vm_install_status(values)
      values['vm']   = "vbox"
      values['sudo'] = false
      values['size'] = values['size'].gsub(/G/, "000")
      values['hostonlyip'] = "192.168.56.1"
      values['vmgateway']  = "192.168.56.1"
    when /kvm/
      values['status'] = check_kvm_is_installed(values)
      handle_vm_install_status(values)
      values['hostonlyip'] = "192.168.122.1"
      values['vmgateway']  = "192.168.122.1"
    when /vmware|fusion/
      handle_vm_install_status(values)
      check_fusion_vm_promisc_mode(values)
      values['sudo'] = false
      values['vm']   = "fusion"
    when /zone|container|lxc/
      if values['host-os-uname'].to_s.match(/SunOS/)
        values['vm'] = "zone"
      else
        values['vm'] = "lxc"
      end
    when /ldom|cdom|gdom/
      if $os_arch.downcase.match(/sparc/) && values['host-os-uname'].to_s.match(/SunOS/)
        if values['release'] == values['empty']
          values['release']   = values['host-os-unamer']
        end
        if values['host-os-unamer'].match(/10|11/)
          if values['mode'].to_s.match(/client/)
            values['vm'] = "gdom"
          end
          if values['mode'].to_s.match(/server/)
            values['vm'] = "cdom"
          end
        else
          verbose_output(values, "Warning:\tLDoms require Solaris 10 or 11")
        end
      else
        verbose_output(values, "Warning:\tLDoms require Solaris on SPARC")
        quit(values)
      end
    end
    if !values['valid-vm'].to_s.downcase.match(/#{values['vm'].to_s}/) && !values['action'].to_s.match(/list/)
      print_valid_list(values, "Warning:\tInvalid VM type", values['valid-vm'])
    end
    if values['verbose'] == true
      verbose_output(values, "Information:\tSetting VM type to #{values['vm']}")
    end
  else
    values['vm'] = "none"
  end
  if values['vm'] != values['empty'] || values['method'] != values['empty']
    if values['model'] != values['empty']
      values['model'] = values['model'].downcase
    else
      if values['arch'].to_s.match(/i386|x86|x86_64|x64|amd64/)
        values['model'] = "vmware"
      else
        values['model'] = ""
      end
    end
    if values['verbose'] == true && values['model']
      verbose_output(values, "Information:\tSetting model to #{values['model']}")
    end
  end
  # Handle gateway if not empty
  if values['vmgateway'] != values['empty']
    values['vmgateway'] = values['vmgateway']
  else
    if values['vmnetwork'] == "hostonly"
    end
  end
  # Change VM disk size
  if values['size'] != values['empty']
    values['size'] = values['size']
    if !values['size'].to_s.match(/G$/)
      values['size'] = values['size'] + "G"
    end
  end
  # Get MAC address if specified
  if values['mac'] != values['empty']
    if !values['vm']
      values['vm'] = "none"
    end
    values['mac'] = check_install_mac(values)
    if values['verbose'] == true
       verbose_output(values, "Information:\tSetting client MAC address to #{values['mac']}")
    end
  else
    values['mac'] = ""
  end
  return values
end

# Handle SSH key values

def handle_ssh_key_values(values)
  # Handle keyfile switch
  if values['keyfile'] != values['empty']
    if !File.exist?(values['keyfile'])
      verbose_output(values, "Warning:\tKey file #{values['keyfile']} does not exist")
      if values['action'].to_s.match(/create/) and !option['type'].to_s.match(/key/)
        quit(values)
      end
    end
  end
  # Handle sshkeyfile switch
  if values['sshkeyfile'] != values['empty']
    if !File.exist?(values['sshkeyfile'])
      verbose_output(values, "Warning:\tSSH Key file #{values['sshkeyfile']} does not exist")
      if values['action'].to_s.match(/create/)
        check_ssh_keys(values)
      end
    end
  end
  return values
end
