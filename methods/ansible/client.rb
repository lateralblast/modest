# Ansible client code

# List ansible clients

def list_ansible_aws_clients()
  list_ansible_clients("aws")
  return
end

def list_ansible_clients(values)
  ansible_dir = values['clientdir']+"/ansible"
  if not values['vm'].to_s.match(/[a-z,A-Z]/) or values['vm'] == values['empty']
    vm_types = [ 'fusion', 'vbox', 'aws' ]
  else
    vm_types = []
    vm_types.push(values['vm'])
  end
  vm_types.each do |vm_type|
    vm_dir = ansible_dir+"/"+vm_type
    if File.directory?(vm_dir)
      verbose_output(values, "")
      case vm_type
      when /vbox/
        vm_title = "VirtualBox"
      when /aws/
        vm_title = "AWS"
      else
        vm_title = "VMware Fusion"
      end
      vm_list = Dir.entries(vm_dir)
      if vm_list.length > 0
        if values['output'].to_s.match(/html/)
          verbose_output(values, "<h1>Available Packer #{vm_title} clients</h1>")
          verbose_output(values, "<table border=\"1\">")
          verbose_output(values, "<tr>")
          verbose_output(values, "<th>VM</th>")
          verbose_output(values, "<th>OS</th>")
          verbose_output(values, "</tr>")
        else
          verbose_output(values, "Ansible #{vm_title} clients:")
          verbose_output(values, "")
        end
        vm_list.each do |vm_name|
          if vm_name.match(/[a-z,A-Z]/)
            yaml_file = vm_dir+"/"+vm_name+"/"+vm_name+".yaml"
            if File.exist?(yaml_file)
              yaml = File.readlines(yaml_file)
              if vm_type.match(/aws/)
                vm_os = "AMI"
              else
                vm_os = yaml.grep(/guest_os_type/)[0].split(/:/)[1].split(/"/)[1]
              end
              if values['output'].to_s.match(/html/)
                verbose_output(values, "<tr>")
                verbose_output(values, "<td>#{vm_name}</td>")
                verbose_output(values, "<td>#{vm_os}</td>")
                verbose_output(values, "</tr>")
              else
                verbose_output(values, "#{vm_name} os=#{vm_os}")
              end
            end
          end
        end
        if values['output'].to_s.match(/html/)
          verbose_output(values, "</table>")
        else
          verbose_output(values, "")
        end
      end
    end
  end
  return
end

# Delete a packer image

def unconfigure_ansible_client(values)
  if values['verbose'] == true
    verbose_output(values, "Information:\tDeleting Ansible Image for #{values['name']}")
  end
  packer_dir = values['clientdir']+"/ansible/"+values['vm']
  values['clientdir'] = packer_dir+"/"+values['name']
  host_file  = values['clientdir']+"/hosts"
  yaml_file  = values['clientdir']+"/"+values['name']+".yaml"
  [ host_file, yaml_file ].each do |file_name|
    if File.exist?(file_name)
      if values['verbose'] == true
        verbose_output(values, "Information:\tDeleting file #{file_name}")
      end
      File.delete(file_name)
    end
  end
  return
end

# Get Ansible AWS instance information

def get_ansible_instance_info(values)
  info_file = "/tmp/"+values['name']+".output"
  if File.exist?(info_file)
    file_data    = File.readlines(info_file)
    reservations = JSON.parse(file_data.join("\n"))
    reservations['instances'].each do |instance|
      instance_id = instance['id']
      image_id    = instance['image_id']
      status      = instance['state']
      if not status.match(/terminated|shut/)
        if status.match(/running/)
          public_ip  = instance['public_ip']
          public_dns = instance['dns_name']
        else
          public_ip  = "NA"
          public_dns = "NA"
        end
        string = "id="+instance_id+" image="+image_id+" ip="+public_ip+" dns="+public_dns+" status="+status
      else
        string = "id="+instance_id+" image="+image_id+" status="+status
      end
      verbose_output(values, string)
    end
    File.delete(info_file)
  else
    verbose_output(values, "Warning:\tNo instance information found")
  end 
  return
end

# Configure Ansible AWS client

def configure_ansible_aws_client(values)
  create_ansible_aws_install_files(values)
  return
end

# Create Ansible AWS client

def create_ansible_aws_install_files(values)
  if not values['number'].to_s.match(/[0,9]/)
    verbose_output(values, "Warning:\tIncorrect number of instances specified: '#{values['number']}'")
    quit(values)
  end
  values = handle_aws_values(values)
  exists  = check_aws_image_exists(values)
  if exists == true
    verbose_output(values, "Warning:\tAWS AMI already exists with name #{values['name']}")
    quit(values)
  end
  if not values['ami'].to_s.match(/^ami/)
    old_values['ami'] = values['ami']
    ec2, values['ami'] = get_aws_image(old_values['ami'], values['access'], values['secret'], values['region'])
    if values['ami'].to_s.match(/^none$/)
      verbose_output(values, "Warning:\tNo AWS AMI ID found for #{old_values['ami']}")
      values['ami'] = values['ami']
      verbose_output(values, "Information:\tSetting AWS AMI ID to #{values['ami']}")
    else
      verbose_output(values, "Information:\tFound AWS AMI ID #{values['ami']} for #{old_values['ami']}")
    end
  end
  user_data_file = ""
  values['clientdir'] = values['clientdir']+"/ansible/aws/"+values['name']
  check_dir_exists(values, values['clientdir'])
  values = set_aws_key_file(values)
  populate_aws_questions(values, user_data_file)
  values['service'] = "aws"
  process_questions(values)
  create_ansible_aws_yaml()
  return
end

# Build Ansible AWS client

def build_ansible_aws_config(values)
  exists = check_aws_image_exists(values)
  if exists == true
    verbose_output(values, "Warning:\tAWS image already exists for '#{values['name']}'")
    quit(values)
  end
  values['clientdir'] = values['clientdir']+"/ansible/aws/"+values['name']
  yaml_file  = values['clientdir']+"/"+values['name']+".yaml"
  if not File.exist?(yaml_file)
    verbose_output(values, "Warning:\tAnsible AWS config file '#{yaml_file}' does not exist")
    quit(values)
  end
  message = "Information:\tBuilding Ansible AWS instance using AMI name '#{values['name']}' using '#{yaml_file}'"
  command = "cd #{values['clientdir']} ; ansible-playbook -i hosts #{yaml_file}"
  execute_command(values, message, command)
  get_ansible_instance_info(values['name'])
  return
end


