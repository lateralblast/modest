# Code for LXC clients

# List availabel clients

def list_lxcs()
  dom_type = "LXC"
  dom_command = "lxc-ls"
  list_doms(dom_type,dom_command)
  return
end

# Start container

def boot_lxc(options)
  message = "Information:\tChecking status of "+options['name']
  command = "lxc-list |grep '^#{options['name']}'"
  output  = execute_command(options,message,command)
  if not output.match(/RUNNING/)
    message = "Information:\tStarting client "+options['name']
    command = "lxc-start -n #{options['name']} -d"
    execute_command(options,message,command)
    if options['serial'] == true
      system("lxc-console -n #{options['name']}")
    end
  end
  return
end

# Stop container

def stop_lxc(options)
  message = "Information:\tChecking status of "+options['name']
  command = "lxc-list |grep '^#{options['name']}'"
  output  = execute_command(options,message,command)
  if output.match(/RUNNING/)
    message = "Information:\tStopping client "+options['name']
    command = "lxc-stop -n #{options['name']}"
    execute_command(options,message,command)
  end
  return
end

# Create Centos container configuration

def create_centos_lxc_config(options)
  tmp_file = "/tmp/lxc_"+options['name']
  file = File.open(tmp_file,"w")
  file.write("\n")
  file.close
  return
end

# Create Ubuntu container config

def create_ubuntu_lxc_config(options)
  options['ip']  = single_install_ip(options)
  tmp_file    = "/tmp/lxc_"+options['name']
  options['clientdir']  = options['lxcdir']+"/"+options['name']
  config_file = options['clientdir']+"/config"
  message = "Information:\tCreating configuration for "+options['name']
  command = "cp #{config_file} #{tmp_file}"
  execute_command(options,message,command)
  copy = []
  info = IO.readlines(config_file)
  info.each do |line|
    if line.match(/hwaddr/)
      if options['mac'].to_s.match(/[0-9]/)
        output = "lxc.network.hwaddr = "+options['mac']+"\n"
        copy.push(output)
        output = "lxc.network.ipv4 = "+options['ip']+"\n"
        copy.push(output)
      else
        copy.push(line)
        output = "lxc.network.ipv4 = "+options['ip']+"\n"
        copy.push(output)
      end
    else
      copy.push(line)
    end
  end
  copy = copy.join
  File.open(tmp_file,"w") { |file| file.write(copy) }
  message = "Information:\tCreating network configuration file "+config_file
  command = "cp #{tmp_file} #{config_file} ; rm #{tmp_file}"
  execute_command(options,message,command)
  print_contents_of_file(options,"",config_file)
  file = File.open(tmp_file,"w")
  gateway    = $q_struct['gateway'].value
  broadcast  = $q_struct['broadcast'].value
  netmask    = $q_struct['netmask'].value
  network    = $q_struct['network_address'].value
  nameserver = $q_struct['nameserver'].value
  file.write("# The loopback network interface\n")
  file.write("auto lo\n")
  file.write("iface lo inet loopback\n")
  file.write("\n")
  file.write("auto eth0\n")
  file.write("iface eth0 inet static\n")
  file.write("address #{options['ip']}\n")
  file.write("netmask #{netmask}\n")
  file.write("gateway #{gateway}\n")
  file.write("network #{network}\n")
  file.write("broadcast #{broadcast}\n")
  file.write("dns-nameservers #{nameserver}\n")
  file.write("post-up route add default gw 192.168.1.#{options['gatewaynode']}\n")
  file.write("\n")
  file.close
  options['clientdir'] = options['clientdir']+"/rootfs"
  net_file   = options['clientdir']+"/etc/network/interfaces"
  message    = "Information:\tCreating network interface file "+net_file
  command    = "cp #{tmp_file} #{net_file} ; rm #{tmp_file}"
  execute_command(options,message,command)
  user_username = $q_struct['user_username'].value
  user_uid      = $q_struct['user_uid'].value
  user_gid      = $q_struct['user_gid'].value
  user_crypt    = $q_struct['user_crypt'].value
  root_crypt    = $q_struct['root_crypt'].value
  user_fullname = $q_struct['user_fullname'].value
  user_home     = $q_struct['user_home'].value
  user_shell    = $q_struct['user_shell'].value
  passwd_file   = options['clientdir']+"/etc/passwd"
  shadow_file   = options['clientdir']+"/etc/shadow"
  info          = IO.readlines(passwd_file)
  file          = File.open(tmp_file,"w")
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
  execute_command(options,message,command)
  print_contents_of_file(options,"",passwd_file)
  info = IO.readlines(shadow_file)
  file = File.open(tmp_file,"w")
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
  execute_command(options,message,command)
  print_contents_of_file(options,"",shadow_file)
  client_home = options['clientdir']+user_home
  message = "Information:\tCreating SSH directory for "+user_username
  command = "mkdir -p #{client_home}/.ssh ; cd #{options['clientdir']}/home ; chown -R #{user_uid}:#{user_gid} #{user_username}"
  execute_command(options,message,command)
  # Copy admin user keys
  rsa_file = user_home+"/.ssh/id_rsa.pub"
  dsa_file = user_home+"/.ssh/id_dsa.pub"
  key_file = client_home+"/.ssh/authorized_keys"
  if File.exist?(key_file)
    system("rm #{key_file}")
  end
  [rsa_file,dsa_file].each do |pub_file|
    if File.exist?(pub_file)
      message = "Information:\tCopying SSH public key "+pub_file+" to "+key_file
      command = "cat #{pub_file} >> #{key_file}"
      execute_command(options,message,command)
    end
  end
  message = "Information:\tCreating SSH directory for root"
  command = "mkdir -p #{options['clientdir']}/root/.ssh ; cd #{options['clientdir']} ; chown -R 0:0 root"
  execute_command(options,message,command)
  # Copy root keys
  rsa_file = "/root/.ssh/id_rsa.pub"
  dsa_file = "/root/.ssh/id_dsa.pub"
  key_file = options['clientdir']+"/root/.ssh/authorized_keys"
  if File.exist?(key_file)
    system("rm #{key_file}")
  end
  [rsa_file,dsa_file].each do |pub_file|
    if File.exist?(pub_file)
      message = "Information:\tCopying SSH public key "+pub_file+" to "+key_file
      command = "cat #{pub_file} >> #{key_file}"
      execute_command(options,message,command)
    end
  end
  # Fix permissions
  message = "Information:\tFixing SSH permissions for "+user_username
  command = "cd #{options['clientdir']}/home ; chown -R #{user_uid}:#{user_gid} #{user_username}"
  execute_command(options,message,command)
  message = "Information:\tFixing SSH permissions for root "
  command = "cd #{options['clientdir']} ; chown -R 0:0 root"
  execute_command(options,message,command)
  # Add sudoers entry
  sudoers_file = options['clientdir']+"/etc/sudoers.d/"+user_username
  message = "Information:\tCreating sudoers file "+sudoers_file
  command = "echo 'administrator ALL=(ALL) NOPASSWD:ALL' > #{sudoers_file}"
  execute_command(options,message,command)
  # Add default route
  rc_file = options['clientdir']+"/etc/rc.local"
  info = IO.readlines(rc_file)
  file = File.open(tmp_file,"w")
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
  execute_command(options,message,command)
  return
end

# Create standard LXC

def create_standard_lxc(options)
  message = "Information:\tCreating standard container "+options['name']
  if options['host-os-uname'].match(/Ubuntu/)
    command = "lxc-create -t ubuntu -n #{options['name']}"
  end
  execute_command(options,message,command)
  return
end

# Unconfigure LXC client

def unconfigure_lxc(options)
  stop_lxc(options)
  message = "Information:\tDeleting client "+options['name']
  command = "lxc-destroy -n #{options['name']}"
  execute_command(options,message,command)
  options['ip'] = get_install_ip(options)
  remove_hosts_entry(options['name'],options['ip'])
  return
end

# Check LXC exists

def check_lxc_exists(options)
  message = "Information:\tChecking LXC "+options['name']+" exists"
  command = "lxc-ls |grep '#{options['name']}'"
  output  = execute_command(options,message,command)
  if not output.match(/#{options['name']}/)
    handle_output(options,"Warning:\tClient #{options['name']} doesn't exist")
    quit(options)
  end
  return
end

# Check LXC doesn't exist

def check_lxc_doesnt_exist(options)
  message = "Information:\tChecking LXC "+options['name']+" doesn't exist"
  command = "lxc-ls |grep '#{options['name']}'"
  output  = execute_command(options,message,command)
  if output.match(/#{options['name']}/)
    handle_output(options,"Warning:\tClient #{options['name']} already exists")
    quit(options)
  end
  return
end

# Populate post install list

def populate_lxc_post()
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
  post_list.push("  sed -i 's,#{options['mirror']},#{$local_ubuntu_mirror},g' /etc/apt/sources.list.orig")
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

def create_lxc_post(options,post_list)
  tmp_file   = "/tmp/post"
  options['clientdir'] = options['lxcdir']+"/"+options['name']
  post_file  = options['clientdir']+"/rootfs/root/post_install.sh"
  file       = File.open(tmp_file,"w")
  post_list.each do |line|
    output = line+"\n"
    file.write(output)
  end
  file.close
  message = "Information:\tCreating post install script"
  command = "cp #{tmp_file} #{post_file} ; chmod +x #{post_file} ; rm #{tmp_file}"
  execute_command(options,message,command)
  return
end

# Execute post install script

def execute_lxc_post(options)
  options['clientdir'] = options['lxcdir']+"/"+options['name']
  post_file  = options['clientdir']+"/root/post_install.sh"
  if not File.exist?(post_file)
    post_list = populate_lxc_post()
    create_lxc_post(options['name'],post_list)
  end
  boot_lxc(options)
  post_file = "/root/post_install.sh"
  message   = "Information:\tExecuting post install script on "+options['name']
  command   = "ssh -o 'StrictHostKeyChecking no' #{options['name']} '#{post_file}'"
  execute_command(options,message,command)
  return
end

# Configure a container

def configure_lxc(options)
  check_lxc_doesnt_exist(options)
  if not options['service'].to_s.match(/[a-z,A-Z]/) and not options['image'].to_s.match(/[a-z,A-Z]/)
    handle_output(options,"Warning:\tImage file or Service name not specified")
    handle_output(options,"Warning:\tIf this is the first time you have run this command it may take a while")
    handle_output(options,"Information:\tCreating standard container")
    options['ip'] = single_install_ip(options)
    populate_lxc_client_questions(options)
    process_questions(options)
    create_standard_lxc(options)
    if options['host-os-uname'].match(/Ubuntu/)
      create_ubuntu_lxc_config(options)
    end
    if options['host-os-uname'].match(/RedHat|Centos/)
      create_centos_lxc_config(options)
    end
  else
    if options['service'].to_s.match(/[a-z,A-Z]/)
      options['image'] = $lxc_image_dir+"/"+options['service'].gsub(/([0-9])_([0-9])/,'\1.\2').gsub(/_/,"-").gsub(/x86.64/,"x86_64")+".tar.gz"
    end
    if options['image'].to_s.match(/[a-z,A-Z]/)
      if not File.exist?(options['image'])
        handle_output(options,"Warning:\tImage file #{options['image']} does not exist")
        quit(options)
      end
    end
  end
  add_hosts_entry(options)
  boot_lxc(options)
  post_list = populate_lxc_post()
  create_lxc_post(options,post_list)
  return
end
