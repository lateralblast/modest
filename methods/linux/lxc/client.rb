# Code for LXC clients

# List availabel clients

def list_lxcs(values)
  dom_type = "LXC"
  dom_command = "lxc-ls"
  list_doms(values, dom_type, dom_command)
  return
end

# Start container

def boot_lxc(values)
  message = "Information:\tChecking status of "+values['name']
  command = "lxc-list |grep '^#{values['name']}'"
  output  = execute_command(values, message, command)
  if not output.match(/RUNNING/)
    message = "Information:\tStarting client "+values['name']
    command = "lxc-start -n #{values['name']} -d"
    execute_command(values, message, command)
    if values['serial'] == true
      system("lxc-console -n #{values['name']}")
    end
  end
  return
end

# Stop container

def stop_lxc(values)
  message = "Information:\tChecking status of "+values['name']
  command = "lxc-list |grep '^#{values['name']}'"
  output  = execute_command(values, message, command)
  if output.match(/RUNNING/)
    message = "Information:\tStopping client "+values['name']
    command = "lxc-stop -n #{values['name']}"
    execute_command(values, message, command)
  end
  return
end

# Create Centos container configuration

def create_centos_lxc_config(values)
  tmp_file = "/tmp/lxc_"+values['name']
  file = File.open(tmp_file, "w")
  file.write("\n")
  file.close
  return
end

# Create Ubuntu container config

def create_ubuntu_lxc_config(values)
  tmp_file = "/tmp/lxc_"+values['name']
  values['ip'] = single_install_ip(values)
  values['clientdir']  = values['lxcdir']+"/"+values['name']
  config_file = values['clientdir']+"/config"
  message = "Information:\tCreating configuration for "+values['name']
  command = "cp #{config_file} #{tmp_file}"
  execute_command(values, message, command)
  copy = []
  info = IO.readlines(config_file)
  info.each do |line|
    if line.match(/hwaddr/)
      if values['mac'].to_s.match(/[0-9]/)
        output = "lxc.network.hwaddr = "+values['mac']+"\n"
        copy.push(output)
        output = "lxc.network.ipv4 = "+values['ip']+"\n"
        copy.push(output)
      else
        copy.push(line)
        output = "lxc.network.ipv4 = "+values['ip']+"\n"
        copy.push(output)
      end
    else
      copy.push(line)
    end
  end
  copy = copy.join
  File.open(tmp_file, "w") { |file| file.write(copy) }
  message = "Information:\tCreating network configuration file "+config_file
  command = "cp #{tmp_file} #{config_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  print_contents_of_file(values, "", config_file)
  file = File.open(tmp_file, "w")
  gateway    = values['answers']['gateway'].value
  broadcast  = values['answers']['broadcast'].value
  netmask    = values['answers']['netmask'].value
  network    = values['answers']['network_address'].value
  nameserver = values['answers']['nameserver'].value
  file.write("# The loopback network interface\n")
  file.write("auto lo\n")
  file.write("iface lo inet loopback\n")
  file.write("\n")
  file.write("auto eth0\n")
  file.write("iface eth0 inet static\n")
  file.write("address #{values['ip']}\n")
  file.write("netmask #{netmask}\n")
  file.write("gateway #{gateway}\n")
  file.write("network #{network}\n")
  file.write("broadcast #{broadcast}\n")
  file.write("dns-nameservers #{nameserver}\n")
  file.write("post-up route add default gw 192.168.1.#{values['gatewaynode']}\n")
  file.write("\n")
  file.close
  values['clientdir'] = values['clientdir']+"/rootfs"
  net_file = values['clientdir']+"/etc/network/interfaces"
  message  = "Information:\tCreating network interface file "+net_file
  command  = "cp #{tmp_file} #{net_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  user_username = values['answers']['user_username'].value
  user_uid      = values['answers']['user_uid'].value
  user_gid      = values['answers']['user_gid'].value
  user_crypt    = values['answers']['user_crypt'].value
  root_crypt    = values['answers']['root_crypt'].value
  user_fullname = values['answers']['user_fullname'].value
  user_home     = values['answers']['user_home'].value
  user_shell    = values['answers']['user_shell'].value
  passwd_file   = values['clientdir']+"/etc/passwd"
  shadow_file   = values['clientdir']+"/etc/shadow"
  info          = IO.readlines(passwd_file)
  file          = File.open(tmp_file, "w")
  info.each do |line|
    field = line.split(":")
    if field[0] != "ubuntu" and field[0] != "#{user_username}"
      file.write(line)
    end
  end
  output = user_username+":x:"+user_uid+":"+user_gid+":"+user_fullname+":"+user_home+":"+user_shell+"\n"
  file.write(output)
  file.close
  message = "Information:\tCreating password file"
  command = "cat #{tmp_file} > #{passwd_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  print_contents_of_file(values, "", passwd_file)
  info = IO.readlines(shadow_file)
  file = File.open(tmp_file, "w")
  info.each do |line|
    field = line.split(":")
    if field[0] != "ubuntu" and field[0] != "root" and field[0] != "#{user_username}"
      file.write(line)
    end
    if field[0] == "root"
      field[1] = root_crypt
      copy = field.join(":")
      file.write(copy)
    end
  end
  output = user_username+":"+user_crypt+":::99999:7:::\n"
  file.write(output)
  file.close
  message = "Information:\tCreating shadow file"
  command = "cat #{tmp_file} > #{shadow_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  print_contents_of_file(values, "", shadow_file)
  client_home = values['clientdir']+user_home
  message = "Information:\tCreating SSH directory for "+user_username
  command = "mkdir -p #{client_home}/.ssh ; cd #{values['clientdir']}/home ; chown -R #{user_uid}:#{user_gid} #{user_username}"
  execute_command(values, message, command)
  # Copy admin user keys
  rsa_file = user_home+"/.ssh/id_rsa.pub"
  dsa_file = user_home+"/.ssh/id_dsa.pub"
  key_file = client_home+"/.ssh/authorized_keys"
  if File.exist?(key_file)
    system("rm #{key_file}")
  end
  [rsa_file, dsa_file].each do |pub_file|
    if File.exist?(pub_file)
      message = "Information:\tCopying SSH public key "+pub_file+" to "+key_file
      command = "cat #{pub_file} >> #{key_file}"
      execute_command(values, message, command)
    end
  end
  message = "Information:\tCreating SSH directory for root"
  command = "mkdir -p #{values['clientdir']}/root/.ssh ; cd #{values['clientdir']} ; chown -R 0:0 root"
  execute_command(values, message, command)
  # Copy root keys
  rsa_file = "/root/.ssh/id_rsa.pub"
  dsa_file = "/root/.ssh/id_dsa.pub"
  key_file = values['clientdir']+"/root/.ssh/authorized_keys"
  if File.exist?(key_file)
    system("rm #{key_file}")
  end
  [rsa_file, dsa_file].each do |pub_file|
    if File.exist?(pub_file)
      message = "Information:\tCopying SSH public key "+pub_file+" to "+key_file
      command = "cat #{pub_file} >> #{key_file}"
      execute_command(values, message, command)
    end
  end
  # Fix permissions
  message = "Information:\tFixing SSH permissions for "+user_username
  command = "cd #{values['clientdir']}/home ; chown -R #{user_uid}:#{user_gid} #{user_username}"
  execute_command(values, message, command)
  message = "Information:\tFixing SSH permissions for root "
  command = "cd #{values['clientdir']} ; chown -R 0:0 root"
  execute_command(values, message, command)
  # Add sudoers entry
  sudoers_file = values['clientdir']+"/etc/sudoers.d/"+user_username
  message = "Information:\tCreating sudoers file "+sudoers_file
  command = "echo 'administrator ALL=(ALL) NOPASSWD:ALL' > #{sudoers_file}"
  execute_command(values, message, command)
  # Add default route
  rc_file = values['clientdir']+"/etc/rc.local"
  info = IO.readlines(rc_file)
  file = File.open(tmp_file, "w")
  info.each do |line|
    if line.match(/exit 0/)
      output = "route add default gw #{gateway}\n"
      file.write(output)
      file.write(line)
    else
      file.write(line)
    end
  end
  file.close
  message = "Information:\tAdding default route to "+rc_file
  command = "cp #{tmp_file} #{rc_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  return
end

# Create standard LXC

def create_standard_lxc(values)
  message = "Information:\tCreating standard container "+values['name']
  if values['host-os-unamea'].match(/Ubuntu/)
    command = "lxc-create -t ubuntu -n #{values['name']}"
  end
  execute_command(values, message, command)
  return
end

# Unconfigure LXC client

def unconfigure_lxc(values)
  stop_lxc(values)
  message = "Information:\tDeleting client "+values['name']
  command = "lxc-destroy -n #{values['name']}"
  execute_command(values, message, command)
  values['ip'] = get_install_ip(values)
  remove_hosts_entry(values['name'], values['ip'])
  return
end

# Check LXC exists

def check_lxc_exists(values)
  message = "Information:\tChecking LXC "+values['name']+" exists"
  command = "lxc-ls |grep '#{values['name']}'"
  output  = execute_command(values, message, command)
  if not output.match(/#{values['name']}/)
    warning_message(values, "Client #{values['name']} doesn't exist")
    quit(values)
  end
  return
end

# Check LXC doesn't exist

def check_lxc_doesnt_exist(values)
  message = "Information:\tChecking LXC "+values['name']+" doesn't exist"
  command = "lxc-ls |grep '#{values['name']}'"
  output  = execute_command(values, message, command)
  if output.match(/#{values['name']}/)
    warning_message(values, "Client #{values['name']} already exists")
    quit(values)
  end
  return
end

# Populate post install list

def populate_lxc_post(values)
  post_list = []
  post_list.push("#!/bin/sh")
  post_list.push("# Install additional pacakges")
  post_list.push("")
  post_list.push("export TERM=vt100")
  post_list.push("export LANGUAGE=en_US.UTF-8")
  post_list.push("export LANG=en_US.UTF-8")
  post_list.push("export LC_ALL=en_US.UTF-8")
  post_list.push("locale-gen en_US.UTF-8")
  post_list.push("")
  post_list.push("if [ \"`lsb_release -i |awk '{print $3}'`\" = \"Ubuntu\" ] ; then")
  post_list.push("  dpkg-reconfigure locales")
  post_list.push("  cp /etc/apt/sources.list /etc/apt/sources.list.orig")
  post_list.push("  sed -i 's,#{values['mirror']},#{$local_ubuntu_mirror},g' /etc/apt/sources.list.orig")
  post_list.push("  apt-get install -y libterm-readkey-perl 2> /dev/null")
  post_list.push("  apt-get install -y nfs-common 2> /dev/null")
  post_list.push("  apt-get install -y openssh-server 2> /dev/null")
  post_list.push("  apt-get install -y python-software-properties 2> /dev/null")
  post_list.push("  apt-get install -y software-properties-common 2> /dev/null")
  post_list.push("fi")
  post_list.push("")
  repo_file = "/etc/yum.repos.d/CentOS-Base.repo"
  post_list.push("if [ \"`lsb_release -i |awk '{print $3}'`\" = \"Centos\" ] ; then")
  post_list.push("  sed -i 's/^mirror./#&/g' #{repo_file}")
  post_list.push("  sed -i 's/^#\\(baseurl\\)/\\1/g' #{repo_file}")
  post_list.push("  sed -i 's,#{$default_centos_mirror},#{$local_centos_mirror}' #{repo_file}")
  post_list.push("fi")
  post_list.push("")
  return post_list
end

# Create post install package on container

def create_lxc_post(values, post_list)
  tmp_file = "/tmp/post"
  values['clientdir'] = values['lxcdir']+"/"+values['name']
  post_file = values['clientdir']+"/rootfs/root/post_install.sh"
  file      = File.open(tmp_file, "w")
  post_list.each do |line|
    output = line+"\n"
    file.write(output)
  end
  file.close
  message = "Information:\tCreating post install script"
  command = "cp #{tmp_file} #{post_file} ; chmod +x #{post_file} ; rm #{tmp_file}"
  execute_command(values, message, command)
  return
end

# Execute post install script

def execute_lxc_post(values)
  values['clientdir'] = values['lxcdir']+"/"+values['name']
  post_file = values['clientdir']+"/root/post_install.sh"
  if not File.exist?(post_file)
    post_list = populate_lxc_post(values)
    create_lxc_post(values['name'], post_list)
  end
  boot_lxc(values)
  post_file = "/root/post_install.sh"
  message   = "Information:\tExecuting post install script on "+values['name']
  command   = "ssh -o 'StrictHostKeyChecking no' #{values['name']} '#{post_file}'"
  execute_command(values, message, command)
  return
end

# Configure a container

def configure_lxc(values)
  check_lxc_doesnt_exist(values)
  if not values['service'].to_s.match(/[a-z,A-Z]/) and not values['image'].to_s.match(/[a-z,A-Z]/)
    warning_message(values, "Image file or Service name not specified")
    warning_message(values, "If this is the first time you have run this command it may take a while")
    information_message(values, "Creating standard container")
    values['ip'] = single_install_ip(values)
    values = populate_lxc_client_questions(values)
    process_questions(values)
    create_standard_lxc(values)
    if values['host-os-unamea'].match(/Ubuntu/)
      create_ubuntu_lxc_config(values)
    end
    if values['host-os-unamea'].match(/RedHat|Centos/)
      create_centos_lxc_config(values)
    end
  else
    if values['service'].to_s.match(/[a-z,A-Z]/)
      values['image'] = $lxc_image_dir+"/"+values['service'].gsub(/([0-9])_([0-9])/,'\1.\2').gsub(/_/,"-").gsub(/x86.64/,"x86_64")+".tar.gz"
    end
    if values['image'].to_s.match(/[a-z,A-Z]/)
      if not File.exist?(values['image'])
        warning_message(values, "Image file #{values['image']} does not exist")
        quit(values)
      end
    end
  end
  add_hosts_entry(values)
  boot_lxc(values)
  post_list = populate_lxc_post(values)
  create_lxc_post(values, post_list)
  return
end
