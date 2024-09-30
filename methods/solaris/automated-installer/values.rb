# Handle AI values

# Handle publisher values

def handle_publisher_values(values)
  if values['host-os-uname'].to_s.match(/SunOS/) and !values['publisher'] == values['empty']
    if values['mode'].to_s.match(/server/) || values['type'].to_s.match(/service/)
      values['publisherhost'] = values['publisher']
      if values['publisherhost'].to_s.match(/:/)
        (values['publisherhost'], values['publisherport']) = values['publisherhost'].split(/:/)
      end
      information_message(values, "Setting publisher host to #{values['publisherhost']}")
      information_message(values, "Setting publisher port to #{values['publisherport']}")
    else
      if values['mode'] == "server" || values['file'].to_s.match(/repo/)
        if values['host-os-uname'] == "SunOS"
          values['mode'] = "server"
          values = check_local_config(values)
          values['publisherhost'] = values['hostip']
          values['publisherport'] = $default_ai_port
          if values['verbose'] == true
            information_message(values, "Setting publisher host to #{values['publisherhost']}")
            information_message(values, "Setting publisher port to #{values['publisherport']}")
          end
        end
      else
        if values['vm'] == values['empty']
          if values['action'].to_s.match(/create/)
            values['mode'] = "server"
            values = check_local_config(values)
          end
        else
          values['mode'] = "client"
          values = check_local_config(values)
        end
        values['publisherhost'] = values['hostip']
      end
    end
  end
  return values
end