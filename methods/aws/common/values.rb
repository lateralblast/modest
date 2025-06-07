# frozen_string_literal: true

# Handle AWS values

def handle_aws_vm_values(values)
  if (values['vm'] != values['empty']) && values['vm'].to_s.match(/aws/)
    if values['creds']
      values['access'], values['secret'] = get_aws_creds(values)
    else
      values['access'] = ENV['AWS_ACCESS_KEY'] if ENV['AWS_ACCESS_KEY']
      values['secret'] = ENV['AWS_SECRET_KEY'] if ENV['AWS_SECRET_KEY']
      values['access'], values['secret'] = get_aws_creds(values) if !values['secret'] || !values['access']
    end
    if values['access'] == values['empty'] || values['secret'] == values['empty']
      warning_message(values, 'AWS Access and Secret Keys not found')
      quit(values)
    elsif !File.exist?(values['creds'])
      create_aws_creds_file(values)
    end
  end
  values
end
