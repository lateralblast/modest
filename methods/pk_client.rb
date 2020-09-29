# Packer client related commands

# Get packer vm type

def get_client_vm_type_from_packer(options)
  packer_dir = options['clientdir']+"/packer"
  options['vm'] = ""
  [ "vbox", "fusion" ].each do |test_vm|
    test_dir = packer_dir+"/"+test_vm+"/"+options['name']
    if File.directory?(test_dir)
      return test_vm
    end
  end
  return options['vm']
end

# Get packer client directory

def get_packer_client_dir(options)
  if not options['vm'].to_s.match(/[a-z]/)
    options['vm'] = get_client_vm_type_from_packer(options)
  end
  packer_dir = options['clientdir']+"/packer"
  options['clientdir'] = packer_dir+"/"+options['vm']+"/"+options['name']
  return options['clientdir']
end

# check if packer VM image exists

def check_packer_vm_image_exists(options)
  images_dir = options['clientdir']+"/images"
  if File.directory?(images_dir)
    exists = "yes"
  else
    exists = "no"
  end
  return exists,images_dir
end

# List packer clients

def list_packer_aws_clients()
  list_packer_clients("aws")
  return
end

def list_packer_clients(options)
  packer_dir = options['clientdir']+"/packer"
  if not options['vm'].to_s.match(/[a-z,A-Z]/) or options['vm'] == options['empty']
    vm_types = [ 'fusion', 'vbox', 'aws' ]
  else
    vm_types = []
    vm_types.push(options['vm'])
  end
  vm_types.each do |vm_type|
    vm_dir = packer_dir+"/"+vm_type
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
          handle_output(options,"Packer #{vm_title} clients:")
          handle_output(options,"")
        end
        vm_list.each do |vm_name|
          if vm_name.match(/[a-z,A-Z]/)
            json_file = vm_dir+"/"+vm_name+"/"+vm_name+".json"
            if File.exist?(json_file)
              json  = File.readlines(json_file)
              if vm_type.match(/aws/)
                vm_os = "AMI"
              else
                vm_os = json.grep(/guest_os_type/)[0].split(/:/)[1].split(/"/)[1]
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

# Check if a packer image exists

def check_packer_image_exists(options)
	packer_dir = options['clientdir']+"/packer/"+options['vm']
  image_dir  = options['clientdir']+"/images"
  image_file = image_dir+"/"+options['name']+".ovf"
  if File.exist?(image_file)
  	exists = "yes"
  else
  	exists = "no"
  end
	return exists
end

# Delete a packer image

def unconfigure_packer_client(options)
	if options['verbose'] == true
		handle_output(options,"Information:\tDeleting Packer Image for #{options['name']}")
	end
	packer_dir = options['clientdir']+"/packer/"+options['vm']
  options['clientdir'] = packer_dir+"/"+options['name']
  image_dir  = options['clientdir']+"/images"
  ovf_file   = image_dir+"/"+options['name']+".ovf"
  cfg_file   = options['clientdir']+"/"+options['name']+".cfg"
  json_file  = options['clientdir']+"/"+options['name']+".json"
  disk_file  = image_dir+"/"+options['name']+"-disk1.vmdk"
  [ ovf_file, cfg_file, json_file, disk_file ].each do |file_name|
    if File.exist?(file_name)
    	if options['verbose'] == true
    		handle_output(options,"Information:\tDeleting file #{file_name}")
    	end
    	File.delete(file_name)
    end
  end
  if Dir.exist?(image_dir)
  	if options['verbose'] == true
  		handle_output(options,"Information:\tDeleting directory #{image_dir}")
  	end
    if image_dir.match(/[a-z]/)
    	FileUtils.rm_rf(image_dir)
    end
  end
  exists = "no"
  case options['vm']
  when /fusion/
    exists = check_packer_fusion_disk_exists(options)
  when /vbox/
    exists = check_packer_vbox_disk_exists(options)
  when /kvm/
    exists = check_packer_kvm_disk_exists(options)
  end
  if exists == "yes"
    case options['vm']
    when /fusion/
      delete_packer_fusion_disk(options)
    when /vbox/
      delete_packer_vbox_disk(options)
    when /kvm/
      delete_packer_kvm_disk(options)
    end
  end
	return
end

# Kill off any existing packer processes for a client
# some times dead packer processes are left running which stop the build process starting

def kill_packer_processes(options)
  handle_output(options,"Information:\tMaking sure no existing Packer processes are running for #{options['name']}")
  %x[ps -ef |grep packer |grep "#{options['name']}.json" |awk '{print $2}' |xargs kill]
  return
end

# Check if a packer VMware Fusion disk image exists

def check_packer_fusion_disk_exists(options)
  exists = "no"
  return exists
end

# Check if a packer KVM disk image exists

def check_packer_kvm_disk_exists(options)
  exists = "no"
  return exists
end

# Delete packer KVM disk image

def delete_packer_kvm_disk(options)
  return
end

# Delete packer VMware Fusion disk image

def delete_packer_fusion_disk(options)
  return
end

# Check if a packer VirtualBox disk image exists

def check_packer_vbox_disk_exists(options)
  exists   = "no"
  vdi_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/images/"+options['name']+".vdi"
  message  = "Information:\tChecking if VDI file exists for #{options['name']}"
  command  = "#{options['vboxmanage']} list hdds |grep ^Location"
  output   = execute_command(options,message,command)
  if output.match(/#{vdi_file}/)
    puts "got here"
  end
  return exists
end

# Delete packer VirtualBox disk image

def delete_packer_vbox_disk(options)
  vdi_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/images/"+options['name']+".vdi"
  message  = "Information:\tDetermining UUID for VDI file for #{options['name']}"
  command  = "#{options['vboxmanage']} list hdds |egrep '^Location|^UUID' |grep -2 '#{vdi_file}'"
  output   = execute_command(options,message,command)
  if output.match(/#{vdi_file}/)
    disk_uuid = output.split("\n")[0].split(":")[1].gsub(/\s+/,"")
    message   = "Information:\tDeleting VDI file for #{options['name']}"
    command   = "#{options['vboxmanage']} closemedium disk #{disk_uuid} --delete"
    execute_command(options,message,command)
  end
  return
end

# Create a packer config

def configure_packer_client(options)
  if not options['service'].to_s.match(/purity/)
    options['ip'] = single_install_ip(options)
  end
  if not options['hostip']
    options['hostip'] = get_default_host()
  end
  if not options['hostip'].to_s.match(/[0-9,a-z,A-Z]/)
  end
  if options['osname'].to_s.match(/Linux/) and not options['ip'] == options['empty']
    enable_linux_ufw_internal_network(options)
  end
  check_dir_exists(options,options['clientdir'])
  check_dir_owner(options,options['clientdir'],options['uid'])
  exists = check_vm_exists(options)
	if exists == "yes"
    if options['vm'].to_s.match(/vbox/)
  		handle_output(options,"Warning:\tVirtualBox VM #{options['name']} already exists")
    else
      handle_output(options,"Warning:\tVMware Fusion VM #{options['name']} already exists")
    end
		quit(options)
	end
	exists = check_packer_image_exists(options)
	if exists == "yes"
    if options['vm'].to_s.match(/vbox/)
  		handle_output(options,"Warning:\tPacker image for VirtualBox VM #{options['name']} already exists")
    else
      handle_output(options,"Warning:\tPacker image for VMware Fusion VM #{options['name']} already exists")
    end
		quit(options)
  end
  if options['vm'] == options['empty'] && options['service'] == options['empty'] && options['method'] == options['empty'] && options['type'] == options['empty'] && options['mode'] == options['empty']
    options = get_install_service_from_file(options)
  end
  options['guest'] = get_vm_guest_os(options)
  case options['method']
  when /aws/
    options = configure_packer_aws_client(options)
  when /pe/
    options = configure_packer_pe_client(options)
  when /vs/
    options = configure_packer_vs_client(options)
  when /ks/
    options = configure_packer_ks_client(options)
  when /ay/
    options = configure_packer_ay_client(options)
  when /ps/
    options = configure_packer_ps_client(options)
  when /ai/
    options = configure_packer_ai_client(options)
  when /js/
    options = configure_packer_js_client(options)
  end
  if options['vm'].to_s.match(/fusion/)
    options['share'] = ""
    options['mount'] = ""
    image_dir = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/images/"
    check_dir_exists(options,image_dir)
    check_dir_owner(options,image_dir,options['uid'])
    fusion_vmx_file = image_dir+"/"+options['name']+".vmx"
    create_fusion_vm_vmx_file(options,fusion_vmx_file)
  end
  if options['guest'].kind_of?(Array)
    options['guest'] = options['guest'].join("")
  end
  if options['label'] == nil
    options['label'] = "none"
  else
    if not options['label'].to_s.match(/[a-z]|[0-9]/)
      options['label'] = "none"
    end
  end
  create_packer_json(options)
	return
end

# Build a packer config

def build_packer_config(options)
  kill_packer_processes(options)
  exists = check_vm_exists(options)
  if exists.to_s.match(/yes/)
    if options['vm'].to_s.match(/vbox/)
      handle_output(options,"Warning:\tVirtualBox VM #{options['name']} already exists")
    else
      handle_output(options,"Warning:\tVMware Fusion VM #{options['name']} already exists")
    end
    quit(options)
  end
  exists = check_packer_image_exists(options)
  options['clientdir'] = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']
  json_file  = options['clientdir']+"/"+options['name']+".json"
  if not File.exist?(json_file)
    handle_output(options,"Warning:\tJSON configuration file \"#{json_file}\" for #{options['name']} does not exist")
    quit(options)
  end
	message = "Information:\tBuilding Packer Image "+json_file
  if options['verbose'] == true
    if options['osname'].to_s.match(/NT/)
      command = "cd "+options['clientdir']+" ; export PACKER_LOG=1 ; packer build "+options['name']+".json"
    else
      command = "export PACKER_LOG=1 ; packer build "+json_file
    end
  else
    if options['osname'].to_s.match(/NT/)
  	  command = "cd "+options['clientdir']+" ; packer build "+options['name']+".json"
    else
      command = "packer build "+json_file
    end
  end
  if options['verbose'] == true
    handle_output(options,message)
    handle_output(options,"Executing:\t"+command)
  end
  exec(command)
	return
end

# Create vSphere Packer client

def create_packer_vs_install_files(options)
  output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
  check_dir_exists(options,options['clientdir'])
  delete_file(options,output_file)
  options = populate_vs_questions(options)
  process_questions(options)
  output_vs_header(options,output_file)
  # Output firstboot list
  post_list = populate_vs_firstboot_list(options)
  output_vs_post_list(post_list,output_file)
  # Output post list
  post_list = populate_vs_post_list(options)
  output_vs_post_list(post_list,output_file)
  print_contents_of_file(options,"",output_file)
  return options
end

# Create Kickstart Packer client (RHEL, CentOS, SL, and OEL)

def create_packer_ks_install_files(options)
  output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
  check_dir_exists(options,options['clientdir'])
  delete_file(options,output_file) 
  options = populate_ks_questions(options)
  process_questions(options)
  output_ks_header(options,output_file)
  pkg_list = populate_ks_pkg_list(options)
  output_ks_pkg_list(options,pkg_list,output_file)
  post_list = populate_ks_post_list(options)
  output_ks_post_list(options,post_list,output_file)
  return options
end

# Create Windows client

def create_packer_pe_install_files(options)
  output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/"+"Autounattend.xml"
  output_dir  = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']
  check_dir_exists(options,options['clientdir'])
  check_dir_exists(options,output_dir)
  delete_file(options,output_file)
  populate_pe_questions(options)
  process_questions(options)
  output_pe_client_profile(options,output_file)
  output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/post_install.ps1"
  if File.exist?(output_file)
    %x[rm #{output_file}]
    %x[touch #{output_file}]
  end
  if options['shell'].to_s.match(/ssh/)
    download_pkg($openssh_win_url)
    openssh_pkg = File.basename($openssh_win_url)
    copy_pkg_to_packer_client(openssh_package,options)
    openssh_psh = populate_openssh_psh()
    output_psh(options['name'],openssh_psh,output_file)
  else
    winrm_psh = populate_winrm_psh()
    output_psh(options['name'],winrm_psh,output_file)
    vmtools_psh = populate_vmtools_psh(options)
    output_psh(options['name'],vmtools_psh,output_file)
  end
  return options
end

# Create AutoYast (SLES and OpenSUSE) client

def create_packer_ay_install_files(options)
  output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/"+options['name']+".xml"
  check_dir_exists(options,options['clientdir'])
  check_dir_owner(options,options['clientdir'],owner['uid'])
  delete_file(options,output_file)
  options = populate_ks_questions(options)
  process_questions(options)
  output_ay_client_profile(options,output_file)
  return options
end

# Create Preseed (Ubuntu and Debian) client

def create_packer_ps_install_files(options)
  output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
  check_dir_exists(options,options['clientdir'])
  delete_file(options,output_file)
  options = populate_ps_questions(options)
  process_questions(options)
  if !options['service'].to_s.match(/purity/)
    output_ps_header(options,output_file)
    output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/"+options['name']+"_post.sh"
    post_list   = populate_ps_post_list(options)
    output_ks_post_list(options,post_list,output_file)
    output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/"+options['name']+"_first_boot.sh"
    post_list   = populate_ps_first_boot_list(options)
    output_ks_post_list(options,post_list,output_file)
  end
  return options
end

# Create JS client

def create_packer_js_install_files(options)
  options['packerdir'] = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']
  check_dir_exists(options,options['packerdir'])
  check_dir_owner(options,options['packerdir'],options['uid'])
  output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
  delete_file(options,output_file)
  options['version'] = options['service'].split(/_/)[1]
  options['update']  = options['service'].split(/_/)[2]
  options['model']   = "vm"
  options = populate_js_sysid_questions(options)
  process_questions(options)
  options['sysid'] = options['packerdir']+"/sysidcfg"
#  options['sysid'] = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/sysidcfg"
  create_js_sysid_file(options)
  options['publisherhost'] = ""
  options['karch']  = "packer"
  options = populate_js_machine_questions(options)
  process_questions(options)
#  options['machine'] = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/profile"
  options['machine'] = options['packerdir']+"/profile"
  create_js_machine_file(options)
#  options['rules'] = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/rules"
  options['rules'] = options['packerdir']+"/rules"
  create_js_rules_file(options)
#  create_rules_ok_file(options)
#  output_file = options['clientdir']+"/begin"
#  options['finish'] = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/finish"
  options['finish'] = options['packerdir']+"/finish"
  create_js_finish_file(options)
  process_questions(options)
  return options
end

# Create AI client

def create_packer_ai_install_files(options)
  output_file = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
  check_dir_exists(options,options['clientdir'])
  delete_file(options,output_file)
  options['publisherhost'] = ""
  options['publisherport'] = ""
  populate_ai_manifest_questions(options)
  populate_ai_client_profile_questions(options)
  process_questions(options)
  return options
end

# Populate vagrant.sh array

def populate_packer_vagrant_sh(options)
  tmp_keyfile = "/tmp/"+options['name']+".key.pub"
  file_array  = []
  file_array.push("#!/usr/bin/env bash\n")
  file_array.push("\n")
  file_array.push("groupadd vagrant\n")
  file_array.push("useradd vagrant -g vagrant -G wheel\n")
  file_array.push("echo \"vagrant\" | passwd --stdin vagrant\n")
  file_array.push("echo \"vagrant        ALL=(ALL)       NOPASSWD: ALL\" >> /etc/sudoers.d/99-vagrant\n")
  file_array.push("\n")
  file_array.push("mkdir /home/vagrant/.ssh\n")
  file_array.push("\n")
  file_array.push("# Use my own private key\n")
  file_array.push("cat  #{tmp_keyfile} >> /home/vagrant/.ssh/authorized_key\n")
  file_array.push("chown -R vagrant /home/vagrant/.ssh\n")
  file_array.push("chmod -R go-rwsx /home/vagrant/.ssh\n")
  return file_array
end

# Create vagrant.sh array

def create_packer_vagrant_sh(options,file_name)
  file_array = populate_packer_vagrant_sh(options)
  write_array_to_file(options,file_array,file_name,"w")
  return
end

# Create AWS client

def create_packer_aws_install_files(options)
  if not options['number'].to_s.match(/[0,9]/)
    handle_output(options,"Warning:\tIncorrect number of instances specified: '#{options['number']}'")
    quit(options)
  end
  options['name'],options['key'],options['keyfile'],options['group'],options['ports'] = handle_aws_values(options)
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
  script_dir     = options['clientdir']+"/scripts"
  build_dir      = options['clientdir']+"/builds"
  user_data_file = "userdata.yml"
  check_dir_exists(options,options['clientdir'])
  check_dir_exists(options,script_dir)
  check_dir_exists(options,build_dir)
  populate_aws_questions(options['name'],options['ami'],options['region'],options['size'],options['access'],options['secret'],user_data_file,options['type'],options['number'],options['key'],options['keyfile'],options['group'],options['ports'])
  options['service'] = "aws"
  process_questions(options)
  user_data_file = options['clientdir']+"/userdata.yml"
  create_aws_user_data_file(user_data_file)
  create_packer_aws_json()
  file_name = script_dir+"/vagrant.sh"
  create_packer_vagrant_sh(options['name'],file_name)
  key_file = options['clientdir']+"/"+options['name']+".key.pub"
  if not File.exist?(key_file)
    message  = "Copying Key file '#{options['keyfile']}' to '#{key_file}' ; chmod 600 #{key_file}"
    command  = "cp #{options['keyfile']} #{key_file}"
    execute_command(options,message,command)
  end
  return options
end

# Copy package from package directory to packer client directory

def copy_pkg_to_packer_client(pkg_name,options)
  if not pkg_name.match(/$pkg_base_dir/)
    source_pkg = $pkg_base_dir+"/"+pkg_name
  else
    source_pkg = pkg_name
  end
  if not File.exist?(source_pkg)
    handle_output(options,"Warning:\tPackage #{source_pkg} does not exist")
    quit(options)
  end
  if not File.exist?(dest_pkg)
    dest_pkg = options['clientdir']+"/"+pkg_name
    message  = "Information:\tCopying '"+source_pkg+"' to '"+dest_pkg+"'"
    command  = "cp #{source_pkg} #{dest_pkg}"
    execute_command(options,message,command)
  end
  return
end

# Build AWS client

def build_packer_aws_config(options)
  exists = check_aws_image_exists(options)
  if exists == "yes"
    handle_output(options,"Warning:\tAWS image already exists for '#{options['name']}'")
    quit(options)
  end
  options['clientdir'] = options['clientdir']+"/packer/aws/"+options['name']
  json_file  = options['clientdir']+"/"+options['name']+".json"
  key_file   = options['clientdir']+"/"+options['name']+".key.pub"
  if not File.exist?(json_file)
    handle_output(options,"Warning:\tPacker AWS config file '#{json_file}' does not exist")
    quit(options)
  end
  if not File.exist?(key_file) and not File.symlink?(key_file)
    handle_output(options,"Warning:\tPacker AWS key file '#{key_file}' does not exist")
    quit(options)
  end
  message    = "Information:\tCodesigning /usr/local/bin/packer"
  command    = "/usr/bin/codesign --verify /usr/local/bin/packer"
  execute_command(options,message,command)
  message    = "Information:\tBuilding Packer AWS instance using AMI name '#{options['name']}' using '#{json_file}'"
  command    = "cd #{options['clientdir']} ; /usr/local/bin/packer build #{json_file}"
  execute_command(options,message,command)
  return
end

# Configure Packer AWS client

def configure_packer_aws_client(options)
  create_packer_aws_install_files(options)
  return options
end

# Configure Packer Windows client

def configure_packer_pe_client(options)
  create_packer_pe_install_files(options)
  return options
end

# Configure Packer vSphere client

def configure_packer_vs_client(options)
  create_packer_vs_install_files(options)
  return options
end

# Configure Packer Kickstart client

def configure_packer_ks_client(options)
  options = create_packer_ks_install_files(options)
  return options
end

# Configure Packer AutoYast client

def configure_packer_ay_client(options)
  options = create_packer_ay_install_files(options)
  return options
end

# Configure Packer Preseed client

def configure_packer_ps_client(options)
  options = create_packer_ps_install_files(options)
  return options
end

# Configure Packer AI client

def configure_packer_ai_client(options)
  options = create_packer_ai_install_files(options)
  return options
end

# Configure Packer JS client

def configure_packer_js_client(options)
  options = create_packer_js_install_files(options)
  return options
end
