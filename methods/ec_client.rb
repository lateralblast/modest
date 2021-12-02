# Client routines for AWS

# Populate AWS User Data YAML

def populate_aws_user_data_yaml()
  yaml = []
  yaml.push("#cloud-config")
  yaml.push("write_files:")
  yaml.push("- path: /etc/sudoers.d/99-requiretty")
  yaml.push("  permissions: 440")
  yaml.push("  content: |")
  yaml.push("    Defaults !requiretty")
  return yaml
end

# Create Userdata yaml file

def create_aws_user_data_file(options,output_file)
  yaml = populate_aws_user_data_yaml()
  file = File.open(output_file,"w")
  yaml.each do |item|
    line = item+"\n"
    file.write(line)
  end
  file.close
  print_contents_of_file(options,"",output_file)
  return
end

# Build AWS client

def build_aws_config(options)
  exists = check_aws_image_exists(options)
  if exists == true
    handle_output(options,"Warning:\tAWS image already exists for '#{options['name']}'")
    quit(options)
  end
  client_dir = options['clientdir']+"/packer/aws/"+options['name']
  json_file  = client_dir+"/"+options['name']+".json"
  message    = "Information:\tBuilding Packer AWS instance using AMI name '#{options['name']}' using '#{json_file}'"
  command    = "packer build #{json_file}"
  execute_command(options,message,command)
  return
end

# List AWS instances

def list_aws_vms(options)
  return
end

# Connect to AWS VM

def connect_to_aws_vm(options)
  if $strict_mode == true
    ssh_command = "ssh"
  else
    ssh_command = "ssh -o StrictHostKeyChecking=no"
  end 
  if not options['ip'].to_s.match(/[0-9]/) and not options['id'].to_s.match(/[0-9]/)
    handle_output(options,"Warning:\tNo IP or Instance ID specified")
    quit(options)
  end
  if options['adminuser']== options['empty']
    handle_output(options,"Warning:\tNo user specified")
    quit(options)
  end
  if options['key']== options['empty'] and options['keyfile']== options['empty']
    if options['id'].to_s.match(/[0-9]/)
      options['key'] = get_aws_instance_key_name(options['access'],options['secret'],options['region'],options['id'])
      handle_output(options,"Information:\tFound key '#{options['key']}' from Instance ID '#{options['id']}'")
    else
      handle_output(options,"Warning:\tNo key specified")
      quit(options)
    end
  end
  if not options['ip'].to_s.match(/[0-9]/)
    options['ip'] = get_aws_instance_ip(options['access'],options['secret'],options['region'],options['id'])
  end
  if options['keyfile']== options['empty']
    options['keyfile'] = options['keydir']+"/"+options['key']+".pem"
  end
  if not File.exist?(options['keyfile'])
    handle_output(options,"Warning:\tCould not find AWS SSH Key file '#{options['keyfile']}'")
    quit(options)
  end
  command = "#{ssh_command} -i #{options['keyfile']} #{options['adminuser']}@#{options['ip']}" 
  update_user_ssh_config(options)
  if options['verbose'] == true
    handle_output(options,"Information:\tExecuting '#{command}'")
  end
  exec "#{command}"
  return
end

# Stop AWS instance

def stop_aws_vm(options)
  if options['id'] == "all"
    ec2,reservations = get_aws_reservations(options['access'],options['secret'],options['region'])
    reservations.each do |reservation|
      reservation['instances'].each do |instance|
        options['id'] = instance.instance_id
        status        = instance.state.name
        if status.match(/running/)
          handle_output(options,"Information:\tStopping Instance ID #{options['id']}")
          ec2 = initiate_aws_ec2_client(options['access'],options['secret'],options['region'])
          ec2.stop_instances(instance_ids:[options['id']])
        end
      end
    end
  else
    if options['id'].to_s.match(/[0-9]/)
      if options['id'].to_s.match(/,/)
        options['ids']= options['id'].split(/,/)
      else
        options['ids'][0] = options['id']
      end
      options['ids'].each do |id|
        handle_output(options,"Information:\tStopping Instance ID #{id}")
        ec2 = initiate_aws_ec2_client(options)
        ec2.stop_instances(instance_ids:[id])
      end
    end
  end
  return options
end

# Start AWS instance

def boot_aws_vm(options)
  if options['id'] == "all"
    ec2,reservations = get_aws_reservations(options)
    reservations.each do |reservation|
      reservation['instances'].each do |instance|
        options['id'] = instance.instance_id
        status = instance.state.name
        if not status.match(/running|terminated/)
          handle_output(options,"Information:\tStarting Instance ID #{options['id']}")
          ec2 = initiate_aws_ec2_client(options)
          ec2.start_instances(instance_ids:[options['id']])
        end
      end
    end
  else
    if options['id'].to_s.match(/[0-9]/)
      if options['id'].to_s.match(/,/)
        options['ids'] = options['id'].split(/,/)
      else
        options['ids'][0] = options['id']
      end
      options['ids'].each do |id|
        handle_output(options,"Information:\tStarting Instance ID #{id}")
        ec2 = initiate_aws_ec2_client(options)
        ec2.start_instances(instance_ids:[id])
      end
    else
      if not options['ami']== options['empty']
        options = configure_aws_client(options)
      end
    end
  end
  return options
end

# Delete AWS instance

def delete_aws_vm(options)
  if options['id'].to_s.match(/[0-9]/)
    if options['id'].to_s.match(/,/)
      options['ids']= options['id'].split(/,/)
    else
      options['ids'][0] = options['id']
    end
    options['ids'].each do |id|
      if not options['id'].to_s.match(/^i/)
        handle_output(options,"Warning:\tInvalid Instance ID '#{id}'")
        quit(options)
      end
      ec2 = initiate_aws_ec2_client(options)
      handle_output(options,"Information:\tTerminating Instance ID #{id}")
      ec2.terminate_instances(instance_ids:[id])
    end
  else
    if options['id'].to_s.match(/all/)
      ec2,reservations = get_aws_reservations(options)
      reservations.each do |reservation|
        reservation['instances'].each do |instance|
          options['id'] = instance.instance_id
          status        = instance.state.name
          if not status.match(/terminated/)
            handle_output(options,"Information:\tTerminating Instance ID #{options['id']}")
            ec2.terminate_instances(instance_ids:[options['id']])
          else
            handle_output(options,"Information:\tInstance ID #{options['id']} already terminated")
          end
        end
      end
    end
  end
  return options
end

# Delete AWS instance

def reboot_aws_vm(options)
  if options['id'].to_s.match(/[0-9]/)
    if options['id'].to_s.match(/,/)
      options['ids'] = options['id'].split(/,/)
    else
      options['ids'][0] = options['id']
    end
    options['ids'].each do |id|
      handle_output(options,"Information\tRebooting Instance ID #{id}")
      ec2 = initiate_aws_ec2_client(options)
      ec2.reboot_instances(instance_ids:[id])
    end
  end
  return options
end

# Create AWS image from instance

def create_aws_image(options)
  if not options['id'].to_s.match(/[0-9]/)
    handle_output(options,"Warning:\tNo Instance ID specified")
    quit(options)
  end
  if options['name']== options['empty']
    ec2,images = get_aws_images(options)
    images.each do |image|
      image_name = image.name
      if image_name.match(/^#{options['name']}$/)
        handle_output(options,"Warning:\tImage with name '#{options['name']}' already exists")
        quit(options)
      end
    end
  end
  ec2      = initiate_aws_ec2_client(options)
  image    = ec2.create_image({ dry_run: false, instance_id: options['id'], name: options['name'] })
  image_id = image.image_id
  handle_output(options,"Information:\tCreated image #{image_id} with name '#{options['name']}' from instance #{options['id']}")
  return
end

# Create AWS instance string

def create_aws_instance(options)
  image_id        = options['q_struct']['source_ami'].value
  min_count       = options['q_struct']['min_count'].value
  max_count       = options['q_struct']['max_count'].value
  dry_run         = options['q_struct']['dry_run'].value
  instance_type   = options['q_struct']['instance_type'].value
  key_name        = options['q_struct']['key_name'].value
  security_groups = options['q_struct']['security_group'].value
  if security_groups.match(/,/)
    security_groups = security_groups.split(/,/)
  else
    security_groups = [ security_groups ]
  end
  if key_name == options['empty']
    handle_output(options,"Warning:\tNo key specified")
    quit(options)
  end
  if not image_id.match(/^ami/)
    old_image_id = image_id
    ec2,image_id = get_aws_image(image_id,options)
    handle_output(options,"Information:\tFound Image ID #{image_id} for #{old_image_id}")
  end
  ec2       = initiate_aws_ec2_client(options)
  instances = []
  begin
    reservations = ec2.run_instances(image_id: image_id, min_count: min_count, max_count: max_count, instance_type: instance_type, dry_run: dry_run, key_name: key_name, security_groups: security_groups,)
  rescue Aws::EC2::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be specified appropriate rights in AWS IAM")
    quit(options)
  end
  reservations['instances'].each do |instance|
    instance_id = instance.instance_id
    instances.push(instance_id)
  end
  instances.each do |id|
    options['instance'] = id
    list_aws_instances(options)
  end
  return options
end

# Export AWS instance

def export_aws_image(options)
  if options['nosuffix'] == false
    options['bucket'] = get_aws_uniq_name(options)
  end
  s3  = create_aws_s3_bucket(options)
  ec2 = initiate_aws_ec2_client(options)
  begin
    ec2.create_instance_export_task({ description: options['comment'], instance_id: options['id'], target_environment: options['target'], export_to_s3_task: { disk_image_format: options['format'], container_format: options['containertype'], s3_bucket: options['bucket'], s3_prefix: options['prefix'], }, })
  rescue Aws::EC2::Errors::NotExportable
    handle_output(options,"Warning:\tOnly imported instances can be exported")
  end
  return
end

# Configure Packer AWS client

def configure_aws_client(options)
  if not options['number'].to_s.match(/[0,9]/)
    handle_output(options,"Warning:\tIncorrect number of instances specified: '#{options['number']}'")
    quit(options)
  end
  options = handle_aws_values(options)
  options = create_aws_install_files(options)
  return options
end

# Create AWS client

def create_aws_install_files(options)
  user_data_file     = ""
  if not options['ami'].to_s.match(/^ami/)
    ec2,options['ami'] = get_aws_image(options)
  end
  options = set_aws_key_file(options)
  populate_aws_questions(options,user_data_file)
  options['service'] = "aws"
  process_questions(options)
  exists = check_aws_key_pair_exists(options)
  if exists == false
    create_aws_key_pair(options)
  else
    exists = check_aws_ssh_key_file_exists(options)
    if exists == false
      handle_output(options,"Warning:\tSSH Key file '#{aws_ssh_key_file}' for AWS Key Pair '#{options['key']}' does not exist")
      quit(options)
    end
  end
  options = create_aws_instance(options)
  return options
end

# List AWS instances

def list_aws_instances(options)
  if not options['id'].to_s.match(/[0-9]/)
    options['id'] = "all"
  end
  ec2,reservations = get_aws_reservations(options)
  reservations.each do |reservation|
    reservation['instances'].each do |instance|
      instance_id = instance.instance_id
      if instance_id.match(/#{options['id']}/) or options['id'] == "all"
        image_id    = instance.image_id
        status      = instance.state.name
        if not status.match(/terminated|shut/)
          group       = instance.security_groups[0].group_name
          if status.match(/running/)
            public_ip  = instance.public_ip_address
            public_dns = instance.public_dns_name
          else
            public_ip  = "NA"
            public_dns = "NA"
          end
          string = "id="+instance_id+" image="+image_id+" group="+group+" ip="+public_ip+" dns="+public_dns+" status="+status
        else
          string = "id="+instance_id+" image="+image_id+" status="+status
        end
        handle_output(options,string)
      end
    end
  end
  return
end

