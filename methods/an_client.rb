# Ansible client code

# List ansible clients

def list_ansible_aws_clients()
  list_ansible_clients("aws")
  return
end

def list_ansible_clients(options)
  ansible_dir = options['clientdir']+"/ansible"
  if not options['vm'].to_s.match(/[a-z,A-Z]/) or options['vm'] == options['empty']
    vm_types = [ 'fusion', 'vbox', 'aws' ]
  else
    vm_types = []
    vm_types.push(options['vm'])
  end
  vm_types.each do |vm_type|
    vm_dir = ansible_dir+"/"+vm_type
    if File.directory?(vm_dir)
      handle_output(options,"")
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
        if options['output'].to_s.match(/html/)
          handle_output(options,"<h1>Available Packer #{vm_title} clients</h1>")
          handle_output(options,"<table border=\"1\">")
          handle_output(options,"<tr>")
          handle_output(options,"<th>VM</th>")
          handle_output(options,"<th>OS</th>")
          handle_output(options,"</tr>")
        else
          handle_output(options,"Ansible #{vm_title} clients:")
          handle_output(options,"")
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
              if options['output'].to_s.match(/html/)
                handle_output(options,"<tr>")
                handle_output(options,"<td>#{vm_name}</td>")
                handle_output(options,"<td>#{vm_os}</td>")
                handle_output(options,"</tr>")
              else
                handle_output(options,"#{vm_name} os=#{vm_os}")
              end
            end
          end
        end
        if options['output'].to_s.match(/html/)
          handle_output(options,"</table>")
        else
          handle_output(options,"")
        end
      end
    end
  end
  return
end

# Delete a packer image

def unconfigure_ansible_client(options)
  if options['verbose'] == true
    handle_output(options,"Information:\tDeleting Ansible Image for #{options['name']}")
  end
  packer_dir = options['clientdir']+"/ansible/"+options['vm']
  options['clientdir'] = packer_dir+"/"+options['name']
  host_file  = options['clientdir']+"/hosts"
  yaml_file  = options['clientdir']+"/"+options['name']+".yaml"
  [ host_file, yaml_file ].each do |file_name|
    if File.exist?(file_name)
      if options['verbose'] == true
        handle_output(options,"Information:\tDeleting file #{file_name}")
      end
      File.delete(file_name)
    end
  end
  return
end

# Get Ansible AWS instance information

def get_ansible_instance_info(options)
  info_file = "/tmp/"+options['name']+".output"
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
      handle_output(options,string)
    end
    File.delete(info_file)
  else
    handle_output(options,"Warning:\tNo instance information found")
  end 
  return
end

# Configure Ansible AWS client

def configure_ansible_aws_client(options)
  create_ansible_aws_install_files(options)
  return
end

# Create Ansible AWS client

def create_ansible_aws_install_files(options)
  if not options['number'].to_s.match(/[0,9]/)
    handle_output(options,"Warning:\tIncorrect number of instances specified: '#{options['number']}'")
    quit(options)
  end
  options = handle_aws_values(options)
  exists = check_aws_image_exists(options)
  if exists == "yes"
    handle_output(options,"Warning:\tAWS AMI already exists with name #{options['name']}")
    quit(options)
  end
  if not options['ami'].to_s.match(/^ami/)
    old_options['ami'] = options['ami']
    ec2,options['ami'] = get_aws_image(old_options['ami'],options['access'],options['secret'],options['region'])
    if options['ami'].to_s.match(/^none$/)
      handle_output(options,"Warning:\tNo AWS AMI ID found for #{old_options['ami']}")
      options['ami'] = options['ami']
      handle_output(options,"Information:\tSetting AWS AMI ID to #{options['ami']}")
    else
      handle_output(options,"Information:\tFound AWS AMI ID #{options['ami']} for #{old_options['ami']}")
    end
  end
  user_data_file = ""
  options['clientdir']     = options['clientdir']+"/ansible/aws/"+options['name']
  check_dir_exists(options,options['clientdir'])
  populate_aws_questions(options,user_data_file)
  options['service'] = "aws"
  process_questions(options)
  create_ansible_aws_yaml()
  return
end

# Build Ansible AWS client

def build_ansible_aws_config(options)
  exists = check_aws_image_exists(options)
  if exists == "yes"
    handle_output(options,"Warning:\tAWS image already exists for '#{options['name']}'")
    quit(options)
  end
  options['clientdir'] = options['clientdir']+"/ansible/aws/"+options['name']
  yaml_file  = options['clientdir']+"/"+options['name']+".yaml"
  if not File.exist?(yaml_file)
    handle_output(options,"Warning:\tAnsible AWS config file '#{yaml_file}' does not exist")
    quit(options)
  end
  message    = "Information:\tBuilding Ansible AWS instance using AMI name '#{options['name']}' using '#{yaml_file}'"
  command    = "cd #{options['clientdir']} ; ansible-playbook -i hosts #{yaml_file}"
  execute_command(options,message,command)
  get_ansible_instance_info(options['name'])
  return
end


