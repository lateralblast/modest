# Ansible YAML

# Create Ansible YAML file

def create_ansible_aws_yaml(options)
  options['access']    = options['q_struct']['access_key'].value
  options['secret']    = options['q_struct']['secret_key'].value
  options['ami']       = options['q_struct']['source_ami'].value
  options['region']    = options['q_struct']['region'].value
  options['size']      = options['q_struct']['instance_type'].value
  options['adminuser'] = options['q_struct']['ssh_username'].value
  options['key']       = options['q_struct']['key_name'].value
  options['ports']     = options['q_struct']['open_ports'].value
  options['group']     = options['q_struct']['security_group'].value
  options['keyfile']   = File.basename(options['q_struct']['keyfile'].value,".pem")+".key.pub"
  options['name']      = options['q_struct']['ami_name'].value
  options['cidr']      = options['q_struct']['default_cidr'].value
  tmp_keyfile = "/tmp/"+options['keyfile']
  ansible_dir = options['clientdir']+"/ansible"
  options['clientdir']  = ansible_dir+"/aws/"+options['name']
  hosts_file  = options['clientdir']+"/hosts"
  prov_file   = options['clientdir']+"/"+options['name']+".yaml"
  hosts_file  = options['clientdir']+"/hosts"
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking Client directory")
  end
  check_dir_exists(options,options['clientdir'])
  uid = options['uid']
  check_dir_owner(options,options['clientdir'],uid)
  prov_data =[]
  prov_data.push("---\n")
  prov_data.push("- name: Provision EC2 instances\n")
  prov_data.push("  hosts: localhost\n")
  prov_data.push("  connection: local\n")
  prov_data.push("  gather_facts: false\n")
  prov_data.push("\n")
  prov_data.push("  vars:\n")
  prov_data.push("    ec2_access_key: #{options['access']}\n")
  prov_data.push("    ec2_secret_key: #{options['secret']}\n")
  prov_data.push("    ec2_region: #{options['region']}\n")
  prov_data.push("    ec2_type: #{options['size']}\n")
  prov_data.push("    ec2_name: #{options['name']}\n")
  prov_data.push("    ec2_image: #{options['ami']}\n")
  prov_data.push("\n")
  prov_data.push("  tasks:\n")
  prov_data.push("\n")
  prov_data.push("  - name: Handling EC2 group {{ ec2_name }}\n")
  prov_data.push("    ec2_group:\n")
  prov_data.push("      name: \"{{ ec2_name }}\"\n")
  prov_data.push("      description: \"{{ ec2_name }}\"\n")
  prov_data.push("      region: \"{{ ec2_region }}\"\n")
  prov_data.push("      ec2_access_key: \"{{ ec2_access_key }}\"\n")
  prov_data.push("      ec2_secret_key: \"{{ ec2_secret_key }}\"\n")
  prov_data.push("      rules:\n")
  if options['ports'].to_s.match(/,/)
    options['ports'] = options['ports'].split(",")
  else
    options['ports'] = [ options['ports'] ]
  end
  options['ports'].each do |install_port|
    prov_data.push("      - proto: tcp\n")
    prov_data.push("        from_port: #{install_port}\n")
    prov_data.push("        to_port: #{install_port}\n")
    prov_data.push("        cidr_ip: #{options['cidr']}\n")
  end
  prov_data.push("\n")
  prov_data.push("  - name: Create instance for {{ ec2_name }}\n")
  prov_data.push("    ec2:\n")
  prov_data.push("      region: \"{{ ec2_region }}\"\n")
  prov_data.push("      ec2_access_key: \"{{ ec2_access_key }}\"\n")
  prov_data.push("      ec2_secret_key: \"{{ ec2_secret_key }}\"\n")
  prov_data.push("      keypair: \"{{ ec2_name }}\"\n")
  prov_data.push("      group: \"{{ ec2_name }}\"\n")
  prov_data.push("      instance_type: \"{{ ec2_type }}\"\n")
  prov_data.push("      image: \"{{ ec2_image }}\"\n")
  prov_data.push("      exact_count: 1\n")
  prov_data.push("      count_tag:\n")
  prov_data.push("        Name: \"{{ ec2_name }}\"\n")
  prov_data.push("      instance_tags:\n")
  prov_data.push("        Name: \"{{ ec2_name }}\"\n")
  prov_data.push("      wait: true\n")
  prov_data.push("    register: ec2\n")
  prov_data.push("\n")
  prov_data.push("  - name: Gathering instance information for {{ ec2_name }}\n")
  prov_data.push("    local_action: copy content={{ ec2 }} dest=/tmp/{{ ec2_name }}.output\n")
  hosts_data = []
  hosts_data.push("---\n")
  hosts_data.push("[local]\n")
  hosts_data.push("localhost\n")
  write_array_to_file(options, prov_data, prov_file, "w")
  write_array_to_file(options, hosts_data, hosts_file, "w")
  [ prov_file, hosts_file ].each do |file_name|
    check_file_owner(options,file_name, uid)
  end
  set_file_perms(prov_file, "600")
	return
end

