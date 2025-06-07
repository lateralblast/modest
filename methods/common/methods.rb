# frozen_string_literal: true

# Handle methods

def handle_install_method(values)
  # Handle install method switch
  if values['method'] != values['empty']
    case values['method']
    when /cloud/
      values['method'] = 'ci'
    when /suse|sles|yast|ay/
      values['method'] = 'ay'
    when /autoinstall|ai/
      values['method'] = 'ai'
    when /kickstart|redhat|rhel|fedora|sl_|scientific|ks|centos/
      values['method'] = 'ks'
    when /jumpstart|js/
      values['method'] = 'js'
    when /preseed|debian|ubuntu|purity/
      values['method'] = 'ps'
    when /vsphere|esx|vmware|vs/
      values['method'] = 'vs'
      values['controller'] = 'ide'
    when /bsd|xb/
      values['method'] = 'xb'
    end
  end
  # Try to determine install method if only specified OS
  if values['method'] == values['empty'] && !values['action'].to_s.match(/delete|running|reboot|restart|halt|shutdown|boot|stop|deploy|migrate|show|connect/)
    case values['os-type']
    when /sol|sunos/
      if values['release'].to_s.match(/[0-9]/)
        values['method'] = if values['release'] == '11'
                             'ai'
                           else
                             'js'
                           end
      end
    when /ubuntu|debian/
      values['method'] = 'ps'
    when /suse|sles/
      values['method'] = 'ay'
    when /redhat|rhel|scientific|sl|centos|fedora|vsphere|esx/
      values['method'] = 'ks'
    when /bsd/
      values['method'] = 'xb'
    when /vmware|esx|vsphere/
      values['method'] = 'vs'
      configure_vmware_esxi_defaults
    when 'windows'
      values['method'] = 'pe'
    else
      print_valid_list(values, "Warning:\tInvalid OS specified", values['valid-os']) if !values['action'].to_s.match(/list|info|check/) && !values['action'].to_s.match(/add|create/) && values['vm'] == values['empty']
    end
  end
  values
end
