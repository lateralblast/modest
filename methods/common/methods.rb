# Handle methods

def handle_install_method(values)
  # Handle install method switch
  if values['method'] != values['empty']
    case values['method']
    when /cloud/
      info_examples     = "ci"
      values['method'] = "ci"
    when /suse|sles|yast|ay/
      info_examples     = "ay"
      values['method'] = "ay"
      when /autoinstall|ai/
      info_examples     = "ai"
      values['method'] = "ai"
    when /kickstart|redhat|rhel|fedora|sl_|scientific|ks|centos/
      info_examples     = "ks"
      values['method'] = "ks"
    when /jumpstart|js/
      info_examples     = "js"
      values['method'] = "js"
    when /preseed|debian|ubuntu|purity/
      info_examples     = "ps"
      values['method'] = "ps"
    when /vsphere|esx|vmware|vs/
      info_examples     = "vs"
      values['method'] = "vs"
      values['controller'] = "ide"
    when /bsd|xb/
      info_examples     = "xb"
      values['method'] = "xb"
    end
  end
  # Try to determine install method if only specified OS
  if values['method'] == values['empty'] && !values['action'].to_s.match(/delete|running|reboot|restart|halt|shutdown|boot|stop|deploy|migrate|show|connect/)
    case values['os-type']
    when /sol|sunos/
      if values['release'].to_s.match(/[0-9]/)
        if values['release'] == "11"
          values['method'] = "ai"
        else
          values['method'] = "js"
        end
      end
    when /ubuntu|debian/
      values['method'] = "ps"
    when /suse|sles/
      values['method'] = "ay"
    when /redhat|rhel|scientific|sl|centos|fedora|vsphere|esx/
      values['method'] = "ks"
    when /bsd/
      values['method'] = "xb"
    when /vmware|esx|vsphere/
      values['method'] = "vs"
      configure_vmware_esxi_defaults
    when "windows"
      values['method'] = "pe"
    else
      if !values['action'].to_s.match(/list|info|check/)
        if !values['action'].to_s.match(/add|create/) && values['vm'] == values['empty']
          print_valid_list(values, "Warning:\tInvalid OS specified", values['valid-os'])
        end
      end
    end
  end
  return values
end