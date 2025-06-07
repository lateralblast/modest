# frozen_string_literal: true

# Packer client related commands

# Get packer vm type

def get_client_vm_type_from_packer(values)
  packer_dir = "#{values['clientdir']}/packer"
  values['vm'] = ''
  %w[vbox fusion].each do |test_vm|
    test_dir = "#{packer_dir}/#{test_vm}/#{values['name']}"
    return test_vm if File.directory?(test_dir)
  end
  values['vm']
end

# Get packer client directory

def get_packer_client_dir(values)
  values['vm'] = get_client_vm_type_from_packer(values) unless values['vm'].to_s.match(/[a-z]/)
  packer_dir = "#{values['clientdir']}/packer"
  values['clientdir'] = "#{packer_dir}/#{values['vm']}/#{values['name']}"
  values['clientdir']
end

# check if packer VM image exists

def check_packer_vm_image_exists(values)
  images_dir = "#{values['clientdir']}/images"
  exists = File.directory?(images_dir) || false
  [exists, images_dir]
end

# List packer clients

def list_packer_aws_clients(_values)
  list_packer_clients('aws')
  nil
end

def list_packer_clients(values)
  packer_dir = "#{values['clientdir']}/packer"
  if !values['vm'].to_s.match(/[a-z,A-Z]/) || (values['vm'] == values['empty'])
    vm_types = %w[fusion vbox aws parallels]
  else
    vm_types = []
    vm_types.push(values['vm'])
  end
  vm_types.each do |vm_type|
    vm_dir = "#{packer_dir}/#{vm_type}"
    next unless File.directory?(vm_dir)

    verbose_message(values, '')
    vm_title = case vm_type
               when /vbox/
                 'VirtualBox'
               when /aws/
                 'AWS'
               when /parallels/
                 'Parallels'
               else
                 if values['host-os-uname'].to_s.match(/Darwin/)
                   'VMware Fusion'
                 else
                   'VMware Workstation'
                 end
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
      verbose_message(values, "Packer #{vm_title} clients:")
      verbose_message(values, '')
    end
    vm_list.each do |vm_name|
      next unless vm_name.match(/[a-z,A-Z]/)

      json_file = "#{vm_dir}/#{vm_name}/#{vm_name}.json"
      next unless File.exist?(json_file)

      json = File.readlines(json_file)
      vm_os = if vm_type.match(/aws/)
                'AMI'
              else
                json.grep(/guest_os_type/)[0].split(/:/)[1].split(/"/)[1]
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

# Check if a packer image exists

def check_packer_image_exists(values)
  values['clientdir']
  values['vm']
  image_dir  = "#{values['clientdir']}/images"
  image_file = "#{image_dir}/#{values['name']}.ovf"
  File.exist?(image_file) || false
end

# Delete a packer image

def unconfigure_packer_client(values)
  information_message(values, "Deleting Packer Image for #{values['name']}") if values['verbose'] == true
  packer_dir = "#{values['clientdir']}/packer/#{values['vm']}"
  values['clientdir'] = "#{packer_dir}/#{values['name']}"
  image_dir  = "#{values['clientdir']}/images"
  ovf_file   = "#{image_dir}/#{values['name']}.ovf"
  cfg_file   = "#{values['clientdir']}/#{values['name']}.cfg"
  json_file  = "#{values['clientdir']}/#{values['name']}.json"
  disk_file  = "#{image_dir}/#{values['name']}-disk1.vmdk"
  [ovf_file, cfg_file, json_file, disk_file].each do |file_name|
    next unless File.exist?(file_name)

    information_message(values, "Deleting file #{file_name}") if values['verbose'] == true
    File.delete(file_name)
  end
  if Dir.exist?(image_dir)
    information_message(values, "Deleting directory #{image_dir}") if values['verbose'] == true
    FileUtils.rm_rf(image_dir) if image_dir.match(/[a-z]/)
  end
  exists = false
  case values['vm']
  when /fusion/
    exists = check_packer_fusion_disk_exists(values)
  when /vbox/
    exists = check_packer_vbox_disk_exists(values)
  when /kvm/
    exists = check_packer_kvm_disk_exists(values)
  end
  if exists == true
    case values['vm']
    when /fusion/
      delete_packer_fusion_disk(values)
    when /vbox/
      delete_packer_vbox_disk(values)
    when /kvm/
      delete_packer_kvm_disk(values)
    end
  end
  nil
end

# Kill off any existing packer processes for a client
# some times dead packer processes are left running which stop the build process starting

def kill_packer_processes(values)
  information_message(values, "Making sure no existing Packer processes are running for #{values['name']}")
  `ps -ef |grep packer |grep "#{values['name']}.json" |awk '{print $2}' |xargs kill`
  nil
end

# Check if a packer VMware Fusion disk image exists

def check_packer_fusion_disk_exists(_values)
  false
end

# Check if a packer KVM disk image exists

def check_packer_kvm_disk_exists(_values)
  false
end

# Delete packer KVM disk image

def delete_packer_kvm_disk(_values)
  nil
end

# Delete packer VMware Fusion disk image

def delete_packer_fusion_disk(_values)
  nil
end

# Check if a packer VirtualBox disk image exists

def check_packer_vbox_disk_exists(values)
  exists   = false
  vdi_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/images/#{values['name']}.vdi"
  message  = "Information:\tChecking if VDI file exists for #{values['name']}"
  command  = "#{values['vboxmanage']} list hdds |grep ^Location"
  output   = execute_command(values, message, command)
  puts 'got here' if output.match(/#{vdi_file}/)
  exists
end

# Delete packer VirtualBox disk image

def delete_packer_vbox_disk(values)
  vdi_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/images/#{values['name']}.vdi"
  message  = "Information:\tDetermining UUID for VDI file for #{values['name']}"
  command  = "#{values['vboxmanage']} list hdds |egrep '^Location|^UUID' |grep -2 '#{vdi_file}'"
  output   = execute_command(values, message, command)
  if output.match(/#{vdi_file}/)
    disk_uuid = output.split("\n")[0].split(':')[1].gsub(/\s+/, '')
    message   = "Information:\tDeleting VDI file for #{values['name']}"
    command   = "#{values['vboxmanage']} closemedium disk #{disk_uuid} --delete"
    execute_command(values, message, command)
  end
  nil
end

# Create a packer config

def configure_packer_client(values)
  values['ip'] = single_install_ip(values) unless values['service'].to_s.match(/purity/)
  values['hostip'] = get_default_host(values) unless values['hostip']
  unless values['hostip'].to_s.match(/[0-9,a-z,A-Z]/)
  end
  enable_linux_ufw_internal_network(values) if values['host-os-uname'].to_s.match(/Linux/) && (values['ip'] != values['empty'])
  information_message(values, 'Checking Packer client directory') if values['verbose'] == true
  information_message(values, 'Checking Packer client configuration directory') if values['verbose'] == true
  check_dir_exists(values, values['clientdir'])
  check_dir_owner(values, values['clientdir'], values['uid'])
  exists = check_vm_exists(values)
  if exists == true
    warning_message(values, "#{values['vmapp']} VM #{values['name']} already exists")
    quit(values)
  end
  exists = check_packer_image_exists(values)
  if exists == true
    warning_message(values, "Packer image for #{values['vmapp']} VM #{values['name']} already exists")
    quit(values)
  end
  values = get_install_service_from_file(values) if values['vm'] == values['empty'] && values['service'] == values['empty'] && values['method'] == values['empty'] && values['type'] == values['empty'] && values['mode'] == values['empty']
  values['guest'] = get_vm_guest_os(values)
  case values['method']
  when /aws/
    values = configure_packer_aws_client(values)
  when /pe/
    values = configure_packer_pe_client(values)
  when /vs/
    values = configure_packer_vs_client(values)
  when /ks/
    values = configure_packer_ks_client(values)
  when /ay/
    values = configure_packer_ay_client(values)
  when /ps/
    values = configure_packer_ps_client(values)
  when /ai/
    values = configure_packer_ai_client(values)
  when /js/
    values = configure_packer_js_client(values)
  when /ci/
    case values['service']
    when /ubuntu/
      values = configure_packer_ps_client(values)
    end
  end
  if values['vm'].to_s.match(/fusion/)
    values['share'] = ''
    values['mount'] = ''
    image_dir = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/images/"
    information_message(values, 'Checking Packer image directory') if values['verbose'] == true
    check_dir_exists(values, image_dir)
    check_dir_owner(values, image_dir, values['uid'])
    fusion_vmx_file = "#{image_dir}/#{values['name']}.vmx"
    values = create_fusion_vm_vmx_file(values, fusion_vmx_file)
  end
  values['guest'] = values['guest'].join('') if values['guest'].is_a?(Array)
  if values['label'].nil?
    values['label'] = 'none'
  else
    values['label'] = 'none' unless values['label'].to_s.match(/[a-z]|[0-9]/)
  end
  create_packer_json(values)
end

# Build a packer config

def build_packer_config(values)
  kill_packer_processes(values)
  exists = check_vm_exists(values)
  if exists == true
    if values['vm'].to_s.match(/vbox/)
      warning_message(values, "VirtualBox VM #{values['name']} already exists")
    else
      warning_message(values, "VMware Fusion VM #{values['name']} already exists")
    end
    quit(values)
  end
  check_packer_image_exists(values)
  values['clientdir'] = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}"
  json_file = "#{values['clientdir']}/#{values['name']}.json"
  unless File.exist?(json_file)
    warning_message(values, "JSON configuration file \"#{json_file}\" for #{values['name']} does not exist")
    quit(values)
  end
  if values['vm'].to_s.match(/fusion/) && values['vmnetwork'].to_s.match(/hostonly/)
    if_name = values['vmnet'].to_s
    gw_if_name = get_gw_if_name(values)
    check_nat(values, gw_if_name, if_name)
  end
  message = "Information:\tBuilding Packer Image #{json_file}"
  command = if values['verbose'] == true
              if values['host-os-uname'].to_s.match(/NT/)
                "cd #{values['clientdir']} ; export PACKER_LOG=1 ; packer build #{values['name']}.json"
              else
                "export PACKER_LOG=1 ; packer build --on-error=abort #{json_file}"
              end
            elsif values['host-os-uname'].to_s.match(/NT/)
              "cd #{values['clientdir']} ; packer build #{values['name']}.json"
            else
              "packer build #{json_file}"
            end
  if values['verbose'] == true
    verbose_message(values, message)
    execute_message(values, command)
  end
  exec(command)
  nil
end

# Create vSphere Packer client

def create_packer_vs_install_files(values)
  output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/#{values['name']}.cfg"
  check_dir_exists(values, values['clientdir'])
  delete_file(values, output_file)
  values = populate_vs_questions(values)
  process_questions(values)
  output_vs_header(values, output_file)
  # Output firstboot list
  post_list = populate_vs_firstboot_list(values)
  output_vs_post_list(post_list, output_file)
  # Output post list
  post_list = populate_vs_post_list(values)
  output_vs_post_list(post_list, output_file)
  print_contents_of_file(values, '', output_file)
  values
end

# Create Kickstart Packer client (RHEL, CentOS, SL, and OEL)

def create_packer_ks_install_files(values)
  output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/#{values['name']}.cfg"
  check_dir_exists(values, values['clientdir'])
  delete_file(values, output_file)
  values = populate_ks_questions(values)
  process_questions(values)
  output_ks_header(values, output_file)
  pkg_list = populate_ks_pkg_list(values)
  output_ks_pkg_list(values, pkg_list, output_file)
  print_contents_of_file(values, '', output_file)
  post_list = populate_ks_post_list(values)
  output_ks_post_list(values, post_list, output_file)
  print_contents_of_file(values, '', output_file)
  values
end

# Create Windows client

def create_packer_pe_install_files(values)
  output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/Autounattend.xml"
  output_dir  = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}"
  check_dir_exists(values, values['clientdir'])
  check_dir_exists(values, output_dir)
  delete_file(values, output_file)
  input_file = values['unattendedfile'].to_s
  populate_pe_questions(values)
  process_questions(values)
  if input_file.match(/[a-z]/) && File.exist?(info_file)
    "cp #{input_file} #{output_file}"
  else
    output_pe_client_profile(values, output_file)
  end
  print_contents_of_file(values, '', output_file)
  output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/post_install.ps1"
  if File.exist?(output_file)
    `rm #{output_file}`
    `touch #{output_file}`
  end
  if values['winshell'].to_s.match(/ssh/)
    download_pkg(values, values['opensshwinurl'])
    File.basename(values['opensshwinurl'])
    copy_pkg_to_packer_client(openssh_package, values)
    openssh_psh = populate_openssh_psh(values)
    output_psh(values['name'], openssh_psh, output_file)
  else
    winrm_psh = populate_winrm_psh(values)
    output_psh(values['name'], winrm_psh, output_file)
    vmtools_psh = populate_vmtools_psh(values)
    output_psh(values['name'], vmtools_psh, output_file)
  end
  print_contents_of_file(values, '', output_file)
  values
end

# Create AutoYast (SLES and OpenSUSE) client

def create_packer_ay_install_files(values)
  output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/#{values['name']}.xml"
  information_message(values, 'Checking Packer AutoYast configuration directory') if values['verbose'] == true
  check_dir_exists(values, values['clientdir'])
  check_dir_owner(values, values['clientdir'], owner['uid'])
  delete_file(values, output_file)
  values = populate_ks_questions(values)
  process_questions(values)
  output_ay_client_profile(values, output_file)
  print_contents_of_file(values, '', output_file)
  values
end

# Create Preseed (Ubuntu and Debian) client

def create_packer_ps_install_files(values)
  output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/#{values['name']}.cfg"
  check_dir_exists(values, values['clientdir'])
  delete_file(values, output_file)
  values = get_fusion_vm_rootdisk(values) if values['vm'].to_s.match(/fusion/)
  values = populate_ps_questions(values)
  process_questions(values)
  unless values['service'].to_s.match(/purity/)
    output_ps_header(values, output_file)
    output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/#{values['name']}_post.sh"
    post_list   = populate_ps_post_list(values)
    output_ks_post_list(values, post_list, output_file)
    output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/#{values['name']}_first_boot.sh"
    post_list   = populate_ps_first_boot_list(values)
    output_ks_post_list(values, post_list, output_file)
    print_contents_of_file(values, '', output_file)
    if values['livecd'] == true
      output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/subiquity/http/user-data"
      (user_data, early_exec_data, late_exec_data) = populate_packer_cc_user_data(values)
      delete_file(values, output_file)
      output_packer_cc_user_data(values, user_data, early_exec_data, late_exec_data, output_file)
      output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/subiquity/http/meta-data"
      FileUtils.touch(output_file)
    end
  end
  values
end

# Create JS client

def create_packer_js_install_files(values)
  values['packerdir'] = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}"
  information_message(values, 'Checking Packer Jumpstart configuration directory') if values['verbose'] == true
  check_dir_exists(values, values['packerdir'])
  check_dir_owner(values, values['packerdir'], values['uid'])
  output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/#{values['name']}.cfg"
  delete_file(values, output_file)
  values['version'] = values['service'].split(/_/)[1]
  values['update']  = values['service'].split(/_/)[2]
  values['model']   = 'vm'
  values = populate_js_sysid_questions(values)
  print_contents_of_file(values, '', output_file)
  process_questions(values)
  values['sysid'] = "#{values['packerdir']}/sysidcfg"
  #  values['sysid'] = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/sysidcfg"
  create_js_sysid_file(values)
  values['publisherhost'] = ''
  values['karch'] = 'packer'
  values = populate_js_machine_questions(values)
  process_questions(values)
  #  values['machine'] = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/profile"
  values['machine'] = "#{values['packerdir']}/profile"
  create_js_machine_file(values)
  #  values['rules'] = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/rules"
  values['rules'] = "#{values['packerdir']}/rules"
  create_js_rules_file(values)
  #  create_rules_ok_file(values)
  #  output_file = values['clientdir']+"/begin"
  #  values['finish'] = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/finish"
  values['finish'] = "#{values['packerdir']}/finish"
  create_js_finish_file(values)
  process_questions(values)
  values
end

# Create AI client

def create_packer_ai_install_files(values)
  output_file = "#{values['clientdir']}/packer/#{values['vm']}/#{values['name']}/#{values['name']}.cfg"
  check_dir_exists(values, values['clientdir'])
  delete_file(values, output_file)
  values['publisherhost'] = ''
  values['publisherport'] = ''
  populate_ai_manifest_questions(values)
  populate_ai_client_profile_questions(values)
  process_questions(values)
  values
end

# Populate vagrant.sh array

def populate_packer_vagrant_sh(values)
  tmp_keyfile = "/tmp/#{values['name']}.key.pub"
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
  file_array
end

# Create vagrant.sh array

def create_packer_vagrant_sh(values, file_name)
  file_array = populate_packer_vagrant_sh(values)
  write_array_to_file(values, file_array, file_name, 'w')
  print_contents_of_file(values, '', file_name)
  nil
end

# Create AWS client

def create_packer_aws_install_files(values)
  unless values['number'].to_s.match(/[0,9]/)
    warning_message(values, "Incorrect number of instances specified: '#{values['number']}'")
    quit(values)
  end
  values = handle_aws_values(values)
  exists = check_aws_image_exists(values)
  if exists == 'yes'
    warning_message(values, "AWS AMI already exists with name #{values['name']}")
    quit(values)
  end
  unless values['ami'].to_s.match(/^ami/)
    old_ami = values['ami']
    _, values['ami'] = get_aws_image(values)
    if values['ami'].to_s.match(/^none$/)
      warning_message(values, "No AWS AMI ID found for #{old_ami}")
      information_message(values, "Setting AWS AMI ID to #{values['ami']}")
    else
      information_message(values, "Found AWS AMI ID #{values['ami']} for #{old_ami}")
    end
  end
  script_dir     = "#{values['clientdir']}/scripts"
  build_dir      = "#{values['clientdir']}/builds"
  user_data_file = 'userdata.yml'
  check_dir_exists(values, values['clientdir'])
  check_dir_exists(values, script_dir)
  check_dir_exists(values, build_dir)
  values = set_aws_key_file(values)
  populate_aws_questions(values, user_data_file)
  values['service'] = 'aws'
  process_questions(values)
  user_data_file = "#{values['clientdir']}/userdata.yml"
  create_aws_user_data_file(values, user_data_file)
  values = create_packer_aws_json(values)
  file_name = "#{script_dir}/vagrant.sh"
  create_packer_vagrant_sh(values['name'], file_name)
  key_file = "#{values['clientdir']}/#{values['name']}.key.pub"
  unless File.exist?(key_file)
    message  = "Copying Key file '#{values['keyfile']}' to '#{key_file}' ; chmod 600 #{key_file}"
    command  = "cp #{values['keyfile']} #{key_file}"
    execute_command(values, message, command)
  end
  values
end

# Copy package from package directory to packer client directory

def copy_pkg_to_packer_client(pkg_name, values)
  source_pkg = if !pkg_name.match(/$pkg_base_dir/)
                 "#{$pkg_base_dir}/#{pkg_name}"
               else
                 pkg_name
               end
  unless File.exist?(source_pkg)
    warning_message(values, "Package #{source_pkg} does not exist")
    quit(values)
  end
  unless File.exist?(dest_pkg)
    dest_pkg = "#{values['clientdir']}/#{pkg_name}"
    message  = "Information:\tCopying '#{source_pkg}' to '#{dest_pkg}'"
    command  = "cp #{source_pkg} #{dest_pkg}"
    execute_command(values, message, command)
  end
  nil
end

# Populate Cloud Config/Init user_data

def populate_packer_cc_user_data(values)
  (user_data, early_exec_data, late_exec_data) = populate_cc_user_data(values)
  [user_data, early_exec_data, late_exec_data]
end

# Output Cloud Config/Init user data

def output_packer_cc_user_data(values, user_data, early_exec_data, later_exec_data, output_file)
  output_cc_user_data(values, user_data, early_exec_data, later_exec_data, output_file)
  nil
end

# Build AWS client

def build_packer_aws_config(values)
  exists = check_aws_image_exists(values)
  if exists == 'yes'
    warning_message(values, "AWS image already exists for '#{values['name']}'")
    quit(values)
  end
  values['clientdir'] = "#{values['clientdir']}/packer/aws/#{values['name']}"
  json_file  = "#{values['clientdir']}/#{values['name']}.json"
  key_file   = "#{values['clientdir']}/#{values['name']}.key.pub"
  unless File.exist?(json_file)
    warning_message(values, "Packer AWS config file '#{json_file}' does not exist")
    quit(values)
  end
  if !File.exist?(key_file) && !File.symlink?(key_file)
    warning_message(values, "Packer AWS key file '#{key_file}' does not exist")
    quit(values)
  end
  message = "Information:\tCodesigning /usr/local/bin/packer"
  command = '/usr/bin/codesign --verify /usr/local/bin/packer'
  execute_command(values, message, command)
  message = "Information:\tBuilding Packer AWS instance using AMI name '#{values['name']}' using '#{json_file}'"
  command = "cd #{values['clientdir']} ; /usr/local/bin/packer build #{json_file}"
  execute_command(values, message, command)
  nil
end

# Configure Packer AWS client

def configure_packer_aws_client(values)
  create_packer_aws_install_files(values)
  values
end

# Configure Packer Windows client

def configure_packer_pe_client(values)
  create_packer_pe_install_files(values)
  values
end

# Configure Packer vSphere client

def configure_packer_vs_client(values)
  create_packer_vs_install_files(values)
  values
end

# Configure Packer Kickstart client

def configure_packer_ks_client(values)
  create_packer_ks_install_files(values)
end

# Configure Packer AutoYast client

def configure_packer_ay_client(values)
  create_packer_ay_install_files(values)
end

# Configure Packer Preseed client

def configure_packer_ps_client(values)
  create_packer_ps_install_files(values)
end

# Configure Packer AI client

def configure_packer_ai_client(values)
  create_packer_ai_install_files(values)
end

# Configure Packer JS client

def configure_packer_js_client(values)
  create_packer_js_install_files(values)
end
