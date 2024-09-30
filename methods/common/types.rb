# Handle packer type

def handle_packer_type(values)
  if values['type'].to_s.match(/vcsa|packer/)
    if values['service'] == values['empty'] || values['os-type'] == values['empty'] || values['method'] == values['empty'] || values['release'] == values['empty'] || values['arch'] == values['empty'] || values['label'] == values['empty']
      if values['file'] != values['empty']
        values = get_install_service_from_file(values)
      end
    end
  end
  if values['type'].to_s.match(/^packer$/)
    check_packer_is_installed(values)
    values['mode']    = "client"
    if values['method'] == values['empty'] && values['os-type'] == values['empty'] && !values['action'].to_s.match(/build|list|import|delete/) && !values['vm'].to_s.match(/aws/)
      warning_message(values, "No OS, or Install Method specified for build type #{values['service']}")
      quit(values)
    end
    if values['vm'] == values['empty'] && !values['action'].to_s.match(/list/)
      warning_message(values, "No VM type specified for build type #{values['service']}")
      quit(values)
    end
    if values['name'] == values['empty'] && !values['action'].to_s.match(/list/) && !values['vm'].to_s.match(/aws/)
      warning_message(values, "No Client name specified for build type #{values['service']}")
      quit(values)
    end
    if values['file'] == values['empty'] && !values['action'].to_s.match(/build|list|import|delete/) && !values['vm'].to_s.match(/aws/)
      warning_message(values, "No ISO file specified for build type #{values['service']}")
      quit(values)
    end
    if !values['ip'].to_s.match(/[0-9]/) && !values['action'].to_s.match(/build|list|import|delete/) && !values['vm'].to_s.match(/aws/)
      if values['vmnetwork'].to_s.match(/hostonly/)
        values = set_hostonly_info(values)
        information_message(values, "No IP Address specified, setting to #{values['ip']} ")
      else
        warning_message(values, "No IP Address specified ")
      end
    end
    if !values['mac'].to_s.match(/[0-9]|[A-F]|[a-f]/) && !values['action'].to_s.match(/build|list|import|delete/)
      warning_message(values, "No MAC Address specified")
      information_message(values, "Generating MAC Address")
      if values['vm'] != values['empty']
        if values['vm'] != values['empty']
          values['mac'] = generate_mac_address(values)
        else
          values['mac'] = generate_mac_address(values)
        end
      else
        values['mac'] = generate_mac_address(values)
      end
    end
  else
    if values['type'].to_s.match(/vcsa|packer/)
      if values['type'].to_s.match(/^packer$/)
        check_packer_is_installed(values)
        values['mode'] = "client"
        if values['method'] == values['empty'] && values['os-type'] == values['empty'] && !values['action'].to_s.match(/build|list|import|delete/)
          warning_message(values, "No OS, or Install Method specified for build type #{values['service']}")
          quit(values)
        end
        if values['vm'] == values['empty'] && !values['action'].to_s.match(/list/)
          warning_message(values, "No VM type specified for build type #{values['service']}")
          quit(values)
        end
        if values['name'] == values['empty'] && !values['action'].to_s.match(/list/)
          warning_message(values, "No Client name specified for build type #{values['service']}")
          quit(values)
        end
        if values['file'] == values['empty'] && !values['action'].to_s.match(/build|list|import|delete/)
          warning_message(values, "No ISO file specified for build type #{values['service']}")
          quit(values)
        end
        if !values['ip'].to_s.match(/[0-9]/) && !values['action'].to_s.match(/build|list|import|delete/) && !values['vmnetwork'].to_s.match(/nat/)
          if values['vmnetwork'].to_s.match(/hostonly/)
            values = set_hostonly_info(values)
            information_message(values, "No IP Address specified, setting to #{values['ip']} ")
          else
            warning_message(values, "No IP Address specified ")
            quit(values)
          end
        end
        if !values['mac'].to_s.match(/[0-9]|[A-F]|[a-f]/) && !values['action'].to_s.match(/build|list|import|delete/)
          warning_message(values, "No MAC Address specified")
          information_message(values, "Generating MAC Address")
          if values['vm'] == values['empty']
            values['vm'] = "none"
          end
          values['mac'] = generate_mac_address(values)
        end
      end
    else
      values['service'] = ""
    end
  end
  return values
end