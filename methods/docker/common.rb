# frozen_string_literal: true

# Common Docker code

# Install docker

def install_docker(values)
  # The docker CLI and a running daemon are what is needed (Docker Desktop, Colima or Homebrew docker)
  unless system('docker info >/dev/null 2>&1')
    information_message(values, 'Docker is not installed or the Docker daemon is not running')
    verbose_message(values, "Download:\thttps://docs.docker.com/get-docker/")
    quit(values)
  end
  nil
end

# Get docker image list

def get_docker_image_list(values)
  message = "Information:\tListing docker images"
  command = 'docker image list'
  output  = execute_command(values, message, command)
  output.split(/\n/)
end

# Get docker instance list

def get_docker_instance_list(values)
  message   = "Information:\tListing docker instances"
  command   = 'docker ps'
  output    = execute_command(values, message, command)
  output.split(/\n/)
end

# Get docker image id from name

def get_docker_image_id_from_name(values)
  image_id = 'none'
  images   = get_docker_image_list(values)
  images.each do |image|
    docker_values = image.split(/\s+/)
    image_name    = docker_values[0]
    image_id      = docker_values[2]
    return image_id if image_name.match(/#{values['name']}/)
  end
  image_id
end

# Delete docker image

def delete_docker_image(values)
  values['id'] = get_docker_image_id_from_name(values) if (values['id'].length > 12) || values['id'].to_s.match(/[A-Z]|[g-z]/)
  if values['id'] == values['empty']
    information_message(values, 'No image found')
    quit(values)
  end
  message   = "Information:\tListing docker images"
  command   = "docker image rm #{shell_arg(values['id'])}"
  output    = execute_command(values, message, command)
  verbose_message(values, output)
  nil
end

# Check docker is installed

def check_docker_is_installed(values)
  installed   = 'yes'
  docker_file = ''
  if values['host-os-uname'].to_s.match(/Darwin/)
    %w[docker docker-compose docker-machine].each do |check_file|
      file_name = "/usr/local/bin/#{check_file}"
      if !File.exist?(file_name) && !File.symlink?(file_name)
        docker_file = check_file
        installed = 'no'
      end
    end
  end
  if installed == 'no'
    verbose_message(values, "Information:\tDocker #{docker_file} not installed")
    if values['host-os-uname'].to_s.match(/Darwin/)
      install_package(values, docker_file)
    else
      quit(values)
    end
  end
  nil
end

# Check docker, docker compose and the docker group (--action check --check docker).
# Missing tools are installed with --install. Group changes only apply at the next login.

def check_docker(values)
  information_message(values, 'Checking Docker is installed')
  docker_found = !which_program('docker').empty?
  if docker_found
    information_message(values, 'Docker CLI found')
  else
    warning_message(values, 'Docker is not installed (docker not found on PATH)')
  end
  compose_found = !which_program('docker-compose').empty? || system('docker compose version >/dev/null 2>&1')
  if compose_found
    information_message(values, 'Docker Compose found')
  else
    warning_message(values, 'Docker Compose is not installed (neither docker compose nor docker-compose found)')
  end
  install_docker_tools(values) if (!docker_found || !compose_found) && values['install-check'] == true
  daemon_ok = system('docker info >/dev/null 2>&1')
  if daemon_ok
    information_message(values, 'The Docker daemon is reachable')
  else
    warning_message(values, 'The Docker daemon is not reachable (docker info failed). Start Docker, or check the user can access the socket')
  end
  group_ok = values['host-os-uname'].to_s.match(/Darwin/) ? true : check_docker_group(values)
  if docker_found && compose_found && daemon_ok && group_ok
    information_message(values, "Docker packages are installed and user #{values['user']} is a member of the docker group")
  end
  nil
end

# Install docker and docker compose (--action check --check docker --install)

def install_docker_tools(values)
  if values['host-os-uname'].to_s.match(/Darwin/)
    install_osx_package(values, 'docker-compose')
    warning_message(values, 'Docker Desktop (or Colima) provides the docker CLI on macOS. Install it from https://docs.docker.com/desktop/setup/install/mac-install/ if docker is missing')
  elsif values['host-lsb-description'].to_s.match(/Endeavour|Arch/)
    %w[docker docker-compose].each { |pkg_name| install_linux_package(values, pkg_name) }
  elsif File.exist?('/etc/redhat-release') || File.exist?('/etc/SuSE-release')
    warning_message(values, 'Automatic install is not set up for this distribution. Install docker and docker-compose with the system package manager')
  else
    %w[docker.io docker-compose-v2].each { |pkg_name| install_linux_package(values, pkg_name) }
  end
  nil
end

# Check the user is in the docker group (Linux). Returns true only when the user was already a member

def check_docker_group(values)
  user_name = values['user'].to_s
  output    = `getent group docker`.chomp
  if output.empty?
    warning_message(values, 'Group docker does not exist (is the docker package installed?)')
    return false
  end
  # Membership is read from the group database, so it reflects the user's login state
  members = output.split(':')[3].to_s.split(',')
  if members.include?(user_name)
    information_message(values, "User #{user_name} is a member of the docker group")
    return true
  end
  message = "Information:\tAdding user #{user_name} to group docker"
  command = "usermod -a -G docker #{shell_arg(user_name)}"
  execute_command(values, message, command)
  warning_message(values, "User #{user_name} was added to the docker group")
  warning_message(values, 'Log out and log back in for the new group permissions to take effect')
  false
end

# List docker instances

def list_docker_instances(values)
  instances = get_docker_instance_list(values)
  instances.each do |instance|
    handle_output(values, instance) if (instance.match(/#{values['name']}/) || values['name'].to_s.match(/^#{values['empty']}$|^all$/)) && (instance.match(/#{values['id']}/) || values['id'].to_s.match(/^#{values['empty']}$|^all$/))
  end
  nil
end

# List docker images

def list_docker_images(values)
  images = get_docker_image_list(values)
  images.each do |image|
    handle_output(values, image) if (image.match(/#{values['name']}/) || values['name'].to_s.match(/^#{values['empty']}$|^all$/)) && (image.match(/#{values['id']}/) || values['id'].to_s.match(/^#{values['empty']}$|^all$/))
  end
  nil
end

# List docker VMs

def list_docker_vms(values)
  values['id'] = 'none'
  list_docker_images(values)
  nil
end

# Check docker instance exists

def check_docker_vm_exists(values)
  # Read-only, so it runs directly and also under --dryrun
  output = `docker inspect --format '{{.Name}}' #{shell_arg(values['name'])} 2>/dev/null`
  output.to_s.match?(/\S/)
end

# Check docker image exists

def check_docker_image_exists(values)
  exists = false
  images = get_docker_image_list(values)
  images.each do |line|
    line  = line.chomp
    items = line.split(/\s+/)
    host  = items[0]
    if host.match(/^#{values['name']}$/)
      exists = true
      return exists
    end
  end
  exists
end
