# Docker server code

# Configure Docker server

def configure_docker_server(values)
  check_dir_exists(values, values)
  values['tftpdir'] = values['exportdir']+"/tftpboot"
  if values['verbose'] == true
    verbose_output(values, "Information:\tChecking TFTP directory")
  end
  check_dir_exists(values, values['tftpdir'])
  check_dir_owner(values, values['tftpdir'], values['uid'])
  service_dir = values['tftpdir']+"/"+values['service']
  check_dir_exists(values, service_dir)
  exists = check_docker_image_exists(values['scriptname'])
  if exists == false
    check_dir_exists(values, $docker_host_base_dir)
    check_dir_owner(values, $docker_host_base_dir, values['uid'])
    check_dir_exists(values, $docker_host_tftp_dir)
    check_dir_exists(values, $docker_host_apache_dir)
    check_dir_exists(values, $docker_host_file_dir)
    docker_file = $docker_host_file_dir+"/Dockerfile"
    create_docker_file(docker_file)
    build_docker_file(docker_file)
  else
    verbose_output(values, "Docker image #{values['scriptname']} already exists")
  end
  return
end

# Configure Dockerfile

def create_docker_file(docker_file)
  if File.exist?(docker_file)
    File.delete(docker_file)
  end
  file = File.open(docker_file, "w")
  file.write("FROM: centos:latest\n")
  file.write("VOLUME #{values['tftpdir']} #{values['apachedir']}")
  file.write("RUN yum install -y tftp-server syslinux wget apache")
  file.write("EXPOSE 69/udp")
  file.write("ENTRYPOINT in.tftpd -s /srv -4 -L -a 0.0.0.0:69")
  return
end

# Build Dockerfile

def build_docker_file(docker_file)
  message = "Building: #{docker_file}"
  command = "cd #{$docker_host_base_dir} ; docker build --tag #{values['scriptname']} #{values['scriptname']}"
  #execute_command(values, message, command)
  return
end