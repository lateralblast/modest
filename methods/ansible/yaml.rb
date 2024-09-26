# Ansible YAML

# Create Ansible YAML file

def create_ansible_aws_yaml(values)
  values['access']    = values['answers']['access_key'].value
  values['secret']    = values['answers']['secret_key'].value
  values['ami']       = values['answers']['source_ami'].value
  values['region']    = values['answers']['region'].value
  values['size']      = values['answers']['instance_type'].value
  values['adminuser'] = values['answers']['ssh_username'].value
  values['key']       = values['answers']['key_name'].value
  values['ports']     = values['answers']['open_ports'].value
  values['group']     = values['answers']['security_group'].value
  values['keyfile']   = File.basename(values['answers']['keyfile'].value,".pem")+".key.pub"
  values['name']      = values['answers']['ami_name'].value
  values['cidr']      = values['answers']['default_cidr'].value
  tmp_keyfile = "/tmp/"+values['keyfile']
  ansible_dir = values['clientdir']+"/ansible"
  values['clientdir']  = ansible_dir+"/aws/"+values['name']
  hosts_file  = values['clientdir']+"/hosts"
  prov_file   = values['clientdir']+"/"+values['name']+".yaml"
  hosts_file  = values['clientdir']+"/hosts"
  if values['verbose'] == true
    verbose_output(values,"Information:\tChecking Client directory")
  end
  check_dir_exists(values,values['clientdir'])
  uid = values['uid']
  check_dir_owner(values,values['clientdir'],uid)
  prov_data =[]
  prov_data.push("---\n")
  prov_data.push("- name: Provision EC2 instances\n")
  prov_data.push("  hosts: localhost\n")
  prov_data.push("  connection: local\n")
  prov_data.push("  gather_facts: false\n")
  prov_data.push("\n")
  prov_data.push("  vars:\n")
  prov_data.push("    ec2_access_key: #{values['access']}\n")
  prov_data.push("    ec2_secret_key: #{values['secret']}\n")
  prov_data.push("    ec2_region: #{values['region']}\n")
  prov_data.push("    ec2_type: #{values['size']}\n")
  prov_data.push("    ec2_name: #{values['name']}\n")
  prov_data.push("    ec2_image: #{values['ami']}\n")
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
  if values['ports'].to_s.match(/,/)
    values['ports'] = values['ports'].split(",")
  else
    values['ports'] = [ values['ports'] ]
  end
  values['ports'].each do |install_port|
    prov_data.push("      - proto: tcp\n")
    prov_data.push("        from_port: #{install_port}\n")
    prov_data.push("        to_port: #{install_port}\n")
    prov_data.push("        cidr_ip: #{values['cidr']}\n")
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
  write_array_to_file(values, prov_data, prov_file, "w")
  write_array_to_file(values, hosts_data, hosts_file, "w")
  [ prov_file, hosts_file ].each do |file_name|
    check_file_owner(values,file_name, uid)
  end
  set_file_perms(prov_file, "600")
	return
end

