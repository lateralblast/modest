# Docker server code

# Configure Docker server

def configure_docker_server(options)
  check_dir_exists(options,options)
  options['tftpdir'] = options['exportdir']+"/tftpboot"
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking TFTP directory")
  end
  check_dir_exists(options,options['tftpdir'])
  check_dir_owner(options,options['tftpdir'],options['uid'])
  service_dir = options['tftpdir']+"/"+options['service']
  check_dir_exists(options,service_dir)
  exists = check_docker_image_exists(options['scriptname'])
  if exists == false
    check_dir_exists(options,$docker_host_base_dir)
    check_dir_owner(options,$docker_host_base_dir,options['uid'])
    check_dir_exists(options,$docker_host_tftp_dir)
    check_dir_exists(options,$docker_host_apache_dir)
    check_dir_exists(options,$docker_host_file_dir)
    docker_file = $docker_host_file_dir+"/Dockerfile"
    create_docker_file(docker_file)
    build_docker_file(docker_file)
  else
    handle_output(options,"Docker image #{options['scriptname']} already exists")
  end
  return
end

# Configure Dockerfile

def create_docker_file(docker_file)
  if File.exist?(docker_file)
    File.delete(docker_file)
  end
  file = File.open(docker_file,"w")
  file.write("FROM: centos:latest\n")
  file.write("VOLUME #{options['tftpdir']} #{options['apachedir']}")
  file.write("RUN yum install -y tftp-server syslinux wget apache")
  file.write("EXPOSE 69/udp")
  file.write("ENTRYPOINT in.tftpd -s /srv -4 -L -a 0.0.0.0:69")
  return
end

# Build Dockerfile

def build_docker_file(docker_file)
  message = "Building: #{docker_file}"
  command = "cd #{$docker_host_base_dir} ; docker build --tag #{options['scriptname']} #{options['scriptname']}"
  #execute_command(options,message,command)
  return
end