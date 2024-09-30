# Handle AWS values

def handle_aws_vm_values(values)
  if values['vm'] != values['empty']
    if values['vm'].to_s.match(/aws/)
      if values['creds']
        values['access'], values['secret'] = get_aws_creds(values)
      else
        if ENV['AWS_ACCESS_KEY']
          values['access'] = ENV['AWS_ACCESS_KEY']
        end
        if ENV['AWS_SECRET_KEY']
          values['secret'] = ENV['AWS_SECRET_KEY']
        end
        if !values['secret'] || !values['access']
          values['access'], values['secret'] = get_aws_creds(values)
        end
      end
      if values['access'] == values['empty'] || values['secret'] == values['empty']
        warning_message(values, "AWS Access and Secret Keys not found")
        quit(values)
      else
        if !File.exist?(values['creds'])
          create_aws_creds_file(values)
        end
      end
    end
  end
  return values
end
