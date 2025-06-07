# frozen_string_literal: true

# Handle LDOM values

def handle_ldom_values(values)
  if values['method'] != values['empty']
    if values['method'].to_s.match(/dom/)
      case values['method'].to_s
      when /cdom/
        values['mode'] = 'server'
        values['vm']   = 'cdom'
        if values['verbose'] == true
          varbose_output(values, "Information:\tSetting mode to server")
          information_message(values, 'Setting vm to cdrom')
        end
      when /gdom/
        values['mode'] = 'client'
        values['vm'] = 'gdom'
        if values['verbose'] == true
          information_message(values, 'Setting mode to client')
          information_message(values, 'Setting vm to gdom')
        end
      when /ldom/
        if values['name'] != values['empty']
          values['method'] = 'gdom'
          values['vm']     = 'gdom'
          values['mode']   = 'client'
          if values['verbose'] == true
            information_message(values, 'Setting mode to client')
            information_message(values, 'Setting method to gdom')
            information_message(values, 'Setting vm to gdom')
          end
        else
          warning_message(values, 'Could not determine whether to run in server of client mode')
          quit(values)
        end
      end
    elsif values['mode'].to_s.match(/client/)
      values['vm'] = 'gdom' if (values['vm'] != values['empty']) && values['method'].to_s.match(/ldom|gdom/)
    elsif values['mode'].to_s.match(/server/)
      values['vm'] = 'cdom' if (values['vm'] != values['empty']) && values['method'].to_s.match(/ldom|cdom/)
    end
  elsif values['mode'] != values['empty']
    if values['vm'].to_s.match(/ldom/)
      if values['mode'].to_s.match(/client/)
        values['vm']     = 'gdom'
        values['method'] = 'gdom'
        if values['verbose'] == true
          information_message(values, 'Setting method to gdom')
          information_message(values, 'Setting vm to gdom')
        end
      end
      if values['mode'].to_s.match(/server/)
        values['vm']     = 'cdom'
        values['method'] = 'cdom'
        if values['verbose'] == true
          information_message(values, 'Setting method to cdom')
          information_message(values, 'Setting vm to cdom')
        end
      end
    end
  end
  values
end
