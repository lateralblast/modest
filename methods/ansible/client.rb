# frozen_string_literal: true

# Ansible client code

# List ansible clients

def list_ansible_aws_clients(values)
  list_ansible_clients(values)
  nil
end

def list_ansible_clients(values)
  ansible_dir = "#{values['clientdir']}/ansible"
  if !values['vm'].to_s.match(/[a-z,A-Z]/) || (values['vm'] == values['empty'])
    vm_types = %w[fusion vbox aws]
  else
    vm_types = []
    vm_types.push(values['vm'])
  end
  vm_types.each do |vm_type|
    vm_dir = "#{ansible_dir}/#{vm_type}"
    next unless File.directory?(vm_dir)

    verbose_message(values, '')
    vm_title = case vm_type
               when /vbox/
                 'VirtualBox'
               when /aws/
                 'AWS'
               else
                 'VMware Fusion'
               end
    vm_list = Dir.entries(vm_dir)
    next unless vm_list.length.positive?

    if values['output'].to_s.match(/html/)
      verbose_message(values, "<h1>Available Packer #{vm_title} clients</h1>")
      verbose_message(values, '<table border="1">')
      verbose_message(values, '<tr>')
      verbose_message(values, '<th>VM</th>')
      verbose_message(values, '<th>OS</th>')
      verbose_message(values, '</tr>')
    else
      verbose_message(values, "Ansible #{vm_title} clients:")
      verbose_message(values, '')
    end
    vm_list.each do |vm_name|
      next unless vm_name.match(/[a-z,A-Z]/)

      yaml_file = "#{vm_dir}/#{vm_name}/#{vm_name}.yaml"
      next unless File.exist?(yaml_file)

      yaml = File.readlines(yaml_file)
      vm_os = if vm_type.match(/aws/)
                'AMI'
              else
                yaml.grep(/guest_os_type/)[0].split(/:/)[1].split(/"/)[1]
              end
      if values['output'].to_s.match(/html/)
        verbose_message(values, '<tr>')
        verbose_message(values, "<td>#{vm_name}</td>")
        verbose_message(values, "<td>#{vm_os}</td>")
        verbose_message(values, '</tr>')
      else
        verbose_message(values, "#{vm_name} os=#{vm_os}")
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_message(values, '</table>')
    else
      verbose_message(values, '')
    end
  end
  nil
end

# Delete a packer image

def unconfigure_ansible_client(values)
  information_message(values, "Deleting Ansible Image for #{values['name']}")
  packer_dir = "#{values['clientdir']}/ansible/#{values['vm']}"
  values['clientdir'] = "#{packer_dir}/#{values['name']}"
  host_file  = "#{values['clientdir']}/hosts"
  yaml_file  = "#{values['clientdir']}/#{values['name']}.yaml"
  [host_file, yaml_file].each do |file_name|
    if File.exist?(file_name)
      information_message(values, "Deleting file #{file_name}")
      File.delete(file_name)
    end
  end
  nil
end

# Get Ansible AWS instance information

def get_ansible_instance_info(values)
  info_file = "/tmp/#{values['name']}.output"
  if File.exist?(info_file)
    file_data    = File.readlines(info_file)
    reservations = JSON.parse(file_data.join("\n"))
    reservations['instances'].each do |instance|
      instance_id = instance['id']
      image_id    = instance['image_id']
      status      = instance['state']
      if !status.match(/terminated|shut/)
        if status.match(/running/)
          public_ip  = instance['public_ip']
          public_dns = instance['dns_name']
        else
          public_ip  = 'NA'
          public_dns = 'NA'
        end
        string = "id=#{instance_id} image=#{image_id} ip=#{public_ip} dns=#{public_dns} status=#{status}"
      else
        string = "id=#{instance_id} image=#{image_id} status=#{status}"
      end
      verbose_message(values, string)
    end
    File.delete(info_file)
  else
    warning_message(values, 'No instance information found')
  end
  nil
end

# Configure Ansible AWS client

def configure_ansible_aws_client(values)
  create_ansible_aws_install_files(values)
  nil
end

# Create Ansible AWS client

def create_ansible_aws_install_files(values)
  unless values['number'].to_s.match(/[0,9]/)
    warning_message(values, "Incorrect number of instances specified: '#{values['number']}'")
    quit(values)
  end
  values = handle_aws_values(values)
  exists = check_aws_image_exists(values)
  if exists == true
    warning_message(values, "AWS AMI already exists with name #{values['name']}")
    quit(values)
  end
  unless values['ami'].to_s.match(/^ami/)
    old_values['ami'] = values['ami']
    _, values['ami'] = get_aws_image(old_values['ami'], values['access'], values['secret'], values['region'])
    if values['ami'].to_s.match(/^none$/)
      warning_message(values, "No AWS AMI ID found for #{old_values['ami']}")
      old_values['ami'] = values['ami']
      information_message(values, "Setting AWS AMI ID to #{values['ami']}")
    else
      information_message(values, "Found AWS AMI ID #{values['ami']} for #{old_values['ami']}")
    end
  end
  user_data_file = ''
  values['clientdir'] = "#{values['clientdir']}/ansible/aws/#{values['name']}"
  check_dir_exists(values, values['clientdir'])
  values = set_aws_key_file(values)
  populate_aws_questions(values, user_data_file)
  values['service'] = 'aws'
  process_questions(values)
  create_ansible_aws_yaml(values)
  nil
end

# Build Ansible AWS client

def build_ansible_aws_config(values)
  exists = check_aws_image_exists(values)
  if exists == true
    warning_message(values, "AWS image already exists for '#{values['name']}'")
    quit(values)
  end
  values['clientdir'] = "#{values['clientdir']}/ansible/aws/#{values['name']}"
  yaml_file = "#{values['clientdir']}/#{values['name']}.yaml"
  unless File.exist?(yaml_file)
    warning_message(values, "Ansible AWS config file '#{yaml_file}' does not exist")
    quit(values)
  end
  message = "Information:\tBuilding Ansible AWS instance using AMI name '#{values['name']}' using '#{yaml_file}'"
  command = "cd #{values['clientdir']} ; ansible-playbook -i hosts #{yaml_file}"
  execute_command(values, message, command)
  get_ansible_instance_info(values['name'])
  nil
end
