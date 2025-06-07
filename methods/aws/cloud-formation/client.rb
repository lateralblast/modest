# frozen_string_literal: true

# Code for CloudFormation Stacks

# List AWS CF stacks

def list_aws_cf_stacks(values)
  values['name'] = 'all' unless values['name'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
  stacks = get_aws_cf_stacks(values)
  stacks.each do |stack|
    stack_name = stack.stack_name
    next unless values['name'].to_s.match(/all/) || stack_name.match(/#{values['name']}/)

    stack_id     = stack.stack_id
    stack_status = stack.stack_status
    name_length  = stack_name.length
    name_spacer  = ''
    name_length.times do
      name_spacer += ' '
    end
    verbose_message(values, "#{stack_name} id=#{stack_id} stack_status=#{stack_status}")
    instance_id = ''
    public_ip   = ''
    region_id   = ''
    stack.outputs.each do |output|
      instance_id = output.output_value if output.output_key.match(/InstanceId/)
      public_ip = output.output_value if output.output_key.match(/PublicIP/)
      region_id = output.output_value if output.output_key.match(/AZ/)
      if output.output_key.match(/DNS/)
        public_dns = output.output_value
        verbose_message(values, "#{name_spacer} id=#{instance_id} ip=#{public_ip} dns=#{public_dns} az=#{region_id}")
      end
    end
  end
  nil
end

# Delete AWS CF Stack

def delete_aws_cf_stack(values)
  unless values['stack'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    warning_message(values, 'No AWS CloudFormation Stack Name given')
    quit(values)
  end
  stacks = get_aws_cf_stacks(values)
  stacks.each do |stack|
    stack_name = stack.stack_name
    next unless values['stack'].to_s.match(/all/) || stack_name.match(/#{values['stack']}/)

    cf = initiate_aws_cf_client(values['access'], values['secret'], values['region'])
    information_message(values, "Deleting AWS CloudFormation Stack '#{stack_name}'")
    begin
      cf.delete_stack({ stack_name: stack_name })
    rescue Aws::CloudFormation::Errors::AccessDenied
      warning_message(values, 'User needs to be given appropriate rights in AWS IAM')
      quit(values)
    end
  end
  nil
end

# Create AWS CF Stack

def create_aws_cf_stack(values)
  stack_name      = values['answers']['stack_name'].value
  instance_type   = values['answers']['instance_type'].value
  key_name        = values['answers']['key_name'].value
  ssh_location    = values['answers']['ssh_location'].value
  template_url    = values['answers']['template_url'].value
  values['answers']['security_groups'].value
  cf = initiate_aws_cf_client(values)
  information_message(values, "Creating AWS CloudFormation Stack '#{stack_name}'")
  begin
    stack_id = cf.create_stack({
                                 stack_name: stack_name,
                                 template_url: template_url,
                                 parameters: [
                                   {
                                     parameter_key: 'InstanceType',
                                     parameter_value: instance_type
                                   },
                                   {
                                     parameter_key: 'KeyName',
                                     parameter_value: key_name
                                   },
                                   {
                                     parameter_key: 'SSHLocation',
                                     parameter_value: ssh_location
                                   }
                                   # {
                                   #  parameter_key:    "SecurityGroups",
                                   #  parameter_value:  security_groups,
                                   # },
                                 ]
                               })
  rescue Aws::CloudFormation::Errors::AccessDenied
    warning_message(values, 'User needs to be given appropriate rights in AWS IAM')
    quit(values)
  end
  stack_id = stack_id.stack_id
  information_message(values, "Stack created with ID: #{stack_id}")
  nil
end

# Create AWS CF Stack Config

def create_aws_cf_stack_config(values)
  populate_aws_cf_questions(values)
  values['service'] = 'aws'
  process_questions(values)
  exists = check_if_aws_cf_stack_exists(values)
  if exists == true
    warning_message(values, "AWS CloudFormation Stack '#{values['name']}' already exists")
    quit(values)
  end
  exists = check_aws_key_pair_exists(values)
  if exists == false
    create_aws_key_pair(values)
  else
    exists = check_aws_ssh_key_file_exists(values)
    if exists == false
      warning_message(values, "SSH Key file '#{aws_ssh_key_file}' for AWS Key Pair '#{values['key']}' does not exist")
      quit(values)
    end
  end
end

# Create AWS CF Stack from template

def configure_aws_cf_stack(values)
  if !values['name'].to_s.match(/[A-Z]|[a-z]|[0-9]/) || values['name'].to_s.match(/^none$/)
    warning_message(values, 'No name specified for AWS CloudFormation Stack')
    quit(values)
  end
  unless values['file'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    if !values['bucket'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      unless values['object'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
        warning_message(values, 'No file, bucket, or object specified for AWS CloudFormation Stack')
        quit(values)
      end
    elsif !values['object'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      warning_message(values, 'No object specified for AWS CloudFormation Stack')
      quit(values)
    else
      values['file'] = get_s3_bucket_private_url(values)
    end
  end
  unless values['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    warning_message(values, 'No Key Name given')
    if !values['keyfile'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      values['key'] = values['name']
    else
      values['key'] = File.basename(values['keyfile'])
      values['key'] = values['key'].split(/\./)[0..-2].join
    end
    information_message(values, "Setting Key Name to #{values['key']}")
  end
  values['group'] = values['name'] unless values['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
  if values['nosuffix'] == false
    values['name']  = get_aws_uniq_name(values['name'], values['region'])
    values['key']   = get_aws_uniq_name(values['key'], values['region'])
    values['group'] = get_aws_uniq_name(values['group'], values['region'])
  end
  unless values['keyfile'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    values['keyfile'] = "#{values['keydir']}/#{values['key']}.pem"
    information_message(values, "Setting Key file to #{values['keyfile']}")
  end
  create_aws_cf_stack_config(values)
  create_aws_cf_stack(values)
  nil
end
