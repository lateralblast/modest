# Code for CloudFormation Stacks

# List AWS CF stacks

def list_aws_cf_stacks(options)
  if not options['name'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    options['name'] = "all"
  end
  stacks = get_aws_cf_stacks(options)
  stacks.each do |stack|
    stack_name  = stack.stack_name
    if options['name'].to_s.match(/all/) or stack_name.match(/#{options['name']}/)
      stack_id     = stack.stack_id
      stack_status = stack.stack_status
      name_length  = stack_name.length
      name_spacer  = ""
      name_length.times do
        name_spacer = name_spacer+" "
      end
      handle_output(options,"#{stack_name} id=#{stack_id} stack_status=#{stack_status}") 
      instance_id = ""
      public_ip   = ""
      region_id   = ""
      stack.outputs.each do |output|
        if output.output_key.match(/InstanceId/)
          instance_id = output.output_value
        end
        if output.output_key.match(/PublicIP/)
          public_ip = output.output_value
        end
        if output.output_key.match(/AZ/)
          region_id = output.output_value
        end
        if output.output_key.match(/DNS/)
          public_dns = output.output_value
          handle_output(options,"#{name_spacer} id=#{instance_id} ip=#{public_ip} dns=#{public_dns} az=#{region_id}") 
        end
      end
    end
  end
  return
end

# Delete AWS CF Stack

def delete_aws_cf_stack(options)
  if not options['stack'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output(options,"Warning:\tNo AWS CloudFormation Stack Name given")
    quit(options)
  end
  stacks = get_aws_cf_stacks(options)
  stacks.each do |stack|
    stack_name  = stack.stack_name
    if options['stack'].to_s.match(/all/) or stack_name.match(/#{options['stack']}/)
      cf = initiate_aws_cf_client(options['access'],options['secret'],options['region'])
      handle_output(options,"Information:\tDeleting AWS CloudFormation Stack '#{stack_name}'")
      begin
        cf.delete_stack({ stack_name: stack_name, })
      rescue Aws::CloudFormation::Errors::AccessDenied
        handle_output(options,"Warning:\tUser needs to be given appropriate rights in AWS IAM")
        quit(options)
      end
    end
  end
  return
end

# Create AWS CF Stack

def create_aws_cf_stack(options)
  stack_name      = options['q_struct']['stack_name'].value
  instance_type   = options['q_struct']['instance_type'].value
  key_name        = options['q_struct']['key_name'].value
  ssh_location    = options['q_struct']['ssh_location'].value
  template_url    = options['q_struct']['template_url'].value
  security_groups = options['q_struct']['security_groups'].value
  cf = initiate_aws_cf_client(options)
  handle_output(options,"Information:\tCreating AWS CloudFormation Stack '#{stack_name}'")
  begin
    stack_id = cf.create_stack({
      stack_name:   stack_name,
      template_url: template_url,
      parameters: [
        {
          parameter_key:    "InstanceType",
          parameter_value:  instance_type,
        },
        {
          parameter_key:    "KeyName",
          parameter_value:  key_name,
        },
        {
          parameter_key:    "SSHLocation",
          parameter_value:  ssh_location,
        },
        #{
        #  parameter_key:    "SecurityGroups",
        #  parameter_value:  security_groups,
        #},
      ],
    })
  rescue Aws::CloudFormation::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit(options)
  end
  stack_id = stack_id.stack_id
  handle_output(options,"Information:\tStack created with ID: #{stack_id}")
  return
end

# Create AWS CF Stack Config

def create_aws_cf_stack_config(options)
  populate_aws_cf_questions(options)
  options['service'] = "aws"
  process_questions(options)
  exists = check_if_aws_cf_stack_exists(options)
  if exists == "yes"
    handle_output(options,"Warning:\tAWS CloudFormation Stack '#{options['name']}' already exists")
    quit(options)
  end
  exists = check_aws_key_pair_exists(options)
  if exists == "no"
    create_aws_key_pair(options)
  else
    exists = check_aws_ssh_key_file_exists(options)
    if exists == "no"
      handle_output(options,"Warning:\tSSH Key file '#{aws_ssh_key_file}' for AWS Key Pair '#{options['key']}' does not exist")
      quit(options)
    end
  end
end

# Create AWS CF Stack from template

def configure_aws_cf_stack(options)
  if not options['name'].to_s.match(/[A-Z]|[a-z]|[0-9]/) or options['name'].to_s.match(/^none$/)
    handle_output(options,"Warning:\tNo name specified for AWS CloudFormation Stack")
    quit(options)
  end
  if not options['file'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    if not options['bucket'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      if not options['object'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
        handle_output(options,"Warning:\tNo file, bucket, or object specified for AWS CloudFormation Stack")
        quit(options)
      end
    else
      if not options['object'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
        handle_output(options,"Warning:\tNo object specified for AWS CloudFormation Stack")
        quit(options)
      else
        options['file'] = get_s3_bucket_private_url(options)
      end
    end
  end
  if not options['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output(options,"Warning:\tNo Key Name given")
    if not options['keyfile'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      options['key'] = options['name']
    else
      options['key'] = File.basename(options['keyfile'])
      options['key'] = options['key'].split(/\./)[0..-2].join
    end
    handle_output(options,"Information:\tSetting Key Name to #{options['key']}")
  end
  if not options['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    options['group'] = options['name']
  end
  if options['nosuffix'] == false
    options['name']  = get_aws_uniq_name(options['name'],options['region'])
    options['key']   = get_aws_uniq_name(options['key'],options['region'])
    options['group'] = get_aws_uniq_name(options['group'],options['region'])
  end
  if not options['keyfile'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    options['keyfile'] = options['keydir']+"/"+options['key']+".pem"
    handle_output(options,"Information:\tSetting Key file to #{options['keyfile']}")
  end
  create_aws_cf_stack_config(options)
  create_aws_cf_stack(options)
  return
end

