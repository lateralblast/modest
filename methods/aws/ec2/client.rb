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

def create_aws_user_data_file(values, output_file)
  yaml = populate_aws_user_data_yaml()
  file = File.open(output_file, "w")
  yaml.each do |item|
    line = item+"\n"
    file.write(line)
  end
  file.close
  print_contents_of_file(values, "", output_file)
  return
end

# Build AWS client

def build_aws_config(values)
  exists = check_aws_image_exists(values)
  if exists == true
    verbose_output(values, "Warning:\tAWS image already exists for '#{values['name']}'")
    quit(values)
  end
  client_dir = values['clientdir']+"/packer/aws/"+values['name']
  json_file  = client_dir+"/"+values['name']+".json"
  message    = "Information:\tBuilding Packer AWS instance using AMI name '#{values['name']}' using '#{json_file}'"
  command    = "packer build #{json_file}"
  execute_command(values, message, command)
  return
end

# List AWS instances

def list_aws_vms(values)
  return
end

# Connect to AWS VM

def connect_to_aws_vm(values)
  if $strict_mode == true
    ssh_command = "ssh"
  else
    ssh_command = "ssh -o StrictHostKeyChecking=no"
  end 
  if not values['ip'].to_s.match(/[0-9]/) and not values['id'].to_s.match(/[0-9]/)
    verbose_output(values, "Warning:\tNo IP or Instance ID specified")
    quit(values)
  end
  if values['adminuser']== values['empty']
    verbose_output(values, "Warning:\tNo user specified")
    quit(values)
  end
  if values['key']== values['empty'] and values['keyfile']== values['empty']
    if values['id'].to_s.match(/[0-9]/)
      values['key'] = get_aws_instance_key_name(values['access'], values['secret'], values['region'], values['id'])
      verbose_output(values, "Information:\tFound key '#{values['key']}' from Instance ID '#{values['id']}'")
    else
      verbose_output(values, "Warning:\tNo key specified")
      quit(values)
    end
  end
  if not values['ip'].to_s.match(/[0-9]/)
    values['ip'] = get_aws_instance_ip(values['access'], values['secret'], values['region'], values['id'])
  end
  if values['keyfile']== values['empty']
    values['keyfile'] = values['keydir']+"/"+values['key']+".pem"
  end
  if not File.exist?(values['keyfile'])
    verbose_output(values, "Warning:\tCould not find AWS SSH Key file '#{values['keyfile']}'")
    quit(values)
  end
  command = "#{ssh_command} -i #{values['keyfile']} #{values['adminuser']}@#{values['ip']}" 
  update_user_ssh_config(values)
  if values['verbose'] == true
    verbose_output(values, "Information:\tExecuting '#{command}'")
  end
  exec "#{command}"
  return
end

# Stop AWS instance

def stop_aws_vm(values)
  if values['id'] == "all"
    ec2, reservations = get_aws_reservations(values['access'], values['secret'], values['region'])
    reservations.each do |reservation|
      reservation['instances'].each do |instance|
        values['id'] = instance.instance_id
        status        = instance.state.name
        if status.match(/running/)
          verbose_output(values, "Information:\tStopping Instance ID #{values['id']}")
          ec2 = initiate_aws_ec2_client(values['access'], values['secret'], values['region'])
          ec2.stop_instances(instance_ids:[values['id']])
        end
      end
    end
  else
    if values['id'].to_s.match(/[0-9]/)
      if values['id'].to_s.match(/,/)
        values['ids']= values['id'].split(/,/)
      else
        values['ids'][0] = values['id']
      end
      values['ids'].each do |id|
        verbose_output(values, "Information:\tStopping Instance ID #{id}")
        ec2 = initiate_aws_ec2_client(values)
        ec2.stop_instances(instance_ids:[id])
      end
    end
  end
  return values
end

# Start AWS instance

def boot_aws_vm(values)
  if values['id'] == "all"
    ec2, reservations = get_aws_reservations(values)
    reservations.each do |reservation|
      reservation['instances'].each do |instance|
        values['id'] = instance.instance_id
        status = instance.state.name
        if not status.match(/running|terminated/)
          verbose_output(values, "Information:\tStarting Instance ID #{values['id']}")
          ec2 = initiate_aws_ec2_client(values)
          ec2.start_instances(instance_ids:[values['id']])
        end
      end
    end
  else
    if values['id'].to_s.match(/[0-9]/)
      if values['id'].to_s.match(/,/)
        values['ids'] = values['id'].split(/,/)
      else
        values['ids'][0] = values['id']
      end
      values['ids'].each do |id|
        verbose_output(values, "Information:\tStarting Instance ID #{id}")
        ec2 = initiate_aws_ec2_client(values)
        ec2.start_instances(instance_ids:[id])
      end
    else
      if not values['ami']== values['empty']
        values = configure_aws_client(values)
      end
    end
  end
  return values
end

# Delete AWS instance

def delete_aws_vm(values)
  if values['id'].to_s.match(/[0-9]/)
    if values['id'].to_s.match(/,/)
      values['ids']= values['id'].split(/,/)
    else
      values['ids'][0] = values['id']
    end
    values['ids'].each do |id|
      if not values['id'].to_s.match(/^i/)
        verbose_output(values, "Warning:\tInvalid Instance ID '#{id}'")
        quit(values)
      end
      ec2 = initiate_aws_ec2_client(values)
      verbose_output(values, "Information:\tTerminating Instance ID #{id}")
      ec2.terminate_instances(instance_ids:[id])
    end
  else
    if values['id'].to_s.match(/all/)
      ec2, reservations = get_aws_reservations(values)
      reservations.each do |reservation|
        reservation['instances'].each do |instance|
          values['id'] = instance.instance_id
          status        = instance.state.name
          if not status.match(/terminated/)
            verbose_output(values, "Information:\tTerminating Instance ID #{values['id']}")
            ec2.terminate_instances(instance_ids:[values['id']])
          else
            verbose_output(values, "Information:\tInstance ID #{values['id']} already terminated")
          end
        end
      end
    end
  end
  return values
end

# Delete AWS instance

def reboot_aws_vm(values)
  if values['id'].to_s.match(/[0-9]/)
    if values['id'].to_s.match(/,/)
      values['ids'] = values['id'].split(/,/)
    else
      values['ids'][0] = values['id']
    end
    values['ids'].each do |id|
      verbose_output(values, "Information\tRebooting Instance ID #{id}")
      ec2 = initiate_aws_ec2_client(values)
      ec2.reboot_instances(instance_ids:[id])
    end
  end
  return values
end

# Create AWS image from instance

def create_aws_image(values)
  if not values['id'].to_s.match(/[0-9]/)
    verbose_output(values, "Warning:\tNo Instance ID specified")
    quit(values)
  end
  if values['name']== values['empty']
    ec2, images = get_aws_images(values)
    images.each do |image|
      image_name = image.name
      if image_name.match(/^#{values['name']}$/)
        verbose_output(values,"Warning:\tImage with name '#{values['name']}' already exists")
        quit(values)
      end
    end
  end
  ec2      = initiate_aws_ec2_client(values)
  image    = ec2.create_image({ dry_run: false, instance_id: values['id'], name: values['name'] })
  image_id = image.image_id
  verbose_output(values, "Information:\tCreated image #{image_id} with name '#{values['name']}' from instance #{values['id']}")
  return
end

# Create AWS instance string

def create_aws_instance(values)
  image_id        = values['q_struct']['source_ami'].value
  min_count       = values['q_struct']['min_count'].value
  max_count       = values['q_struct']['max_count'].value
  dry_run         = values['q_struct']['dry_run'].value
  instance_type   = values['q_struct']['instance_type'].value
  key_name        = values['q_struct']['key_name'].value
  security_groups = values['q_struct']['security_group'].value
  if security_groups.match(/,/)
    security_groups = security_groups.split(/,/)
  else
    security_groups = [ security_groups ]
  end
  if key_name == values['empty']
    verbose_output(values, "Warning:\tNo key specified")
    quit(values)
  end
  if not image_id.match(/^ami/)
    old_image_id = image_id
    ec2, image_id = get_aws_image(image_id, values)
    verbose_output(values, "Information:\tFound Image ID #{image_id} for #{old_image_id}")
  end
  ec2       = initiate_aws_ec2_client(values)
  instances = []
  begin
    reservations = ec2.run_instances(image_id: image_id, min_count: min_count, max_count: max_count, instance_type: instance_type, dry_run: dry_run, key_name: key_name, security_groups: security_groups,)
  rescue Aws::EC2::Errors::AccessDenied
    verbose_output(values, "Warning:\tUser needs to be specified appropriate rights in AWS IAM")
    quit(values)
  end
  reservations['instances'].each do |instance|
    instance_id = instance.instance_id
    instances.push(instance_id)
  end
  instances.each do |id|
    values['instance'] = id
    list_aws_instances(values)
  end
  return values
end

# Export AWS instance

def export_aws_image(values)
  if values['nosuffix'] == false
    values['bucket'] = get_aws_uniq_name(values)
  end
  s3  = create_aws_s3_bucket(values)
  ec2 = initiate_aws_ec2_client(values)
  begin
    ec2.create_instance_export_task({ description: values['comment'],  instance_id: values['id'],  target_environment: values['target'],  export_to_s3_task: { disk_image_format: values['format'],  container_format: values['containertype'],  s3_bucket: values['bucket'],  s3_prefix: values['prefix'], }, })
  rescue Aws::EC2::Errors::NotExportable
    verbose_output(values, "Warning:\tOnly imported instances can be exported")
  end
  return
end

# Configure Packer AWS client

def configure_aws_client(values)
  if not values['number'].to_s.match(/[0,9]/)
    verbose_output(values, "Warning:\tIncorrect number of instances specified: '#{values['number']}'")
    quit(values)
  end
  values = handle_aws_values(values)
  values = create_aws_install_files(values)
  return values
end

# Create AWS client

def create_aws_install_files(values)
  user_data_file     = ""
  if not values['ami'].to_s.match(/^ami/)
    ec2, values['ami'] = get_aws_image(values)
  end
  values = set_aws_key_file(values)
  populate_aws_questions(values, user_data_file)
  values['service'] = "aws"
  process_questions(values)
  exists = check_aws_key_pair_exists(values)
  if exists == false
    create_aws_key_pair(values)
  else
    exists = check_aws_ssh_key_file_exists(values)
    if exists == false
      verbose_output(values, "Warning:\tSSH Key file '#{aws_ssh_key_file}' for AWS Key Pair '#{values['key']}' does not exist")
      quit(values)
    end
  end
  values = create_aws_instance(values)
  return values
end

# List AWS instances

def list_aws_instances(values)
  if not values['id'].to_s.match(/[0-9]/)
    values['id'] = "all"
  end
  ec2, reservations = get_aws_reservations(values)
  reservations.each do |reservation|
    reservation['instances'].each do |instance|
      instance_id = instance.instance_id
      if instance_id.match(/#{values['id']}/) or values['id'] == "all"
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
        verbose_output(values, string)
      end
    end
  end
  return
end

