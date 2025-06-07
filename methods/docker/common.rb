# frozen_string_literal: true

# Common Docker code

# Install docker

def install_docker(values)
  if values['host-os-uname'].to_s.match(/Darwin/) && !Dir.exist?('/Applications/Docker.app')
    information_message(values, 'Docker no installed')
    verbose_message(values, "Download:\thttps://docs.docker.com/docker-for-mac/")
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
  message   = "Information:\tListing docker images"
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
  command   = "docker image rm #{values['id']}"
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

# List docker instances

def list_docker_instances(values)
  instances = get_docker_instance_list(values)
  instances.each do |instance|
    verbose_message(instance) if (instance.match(/#{values['name']}/) || values['name'].to_s.match(/^#{values['empty']}$|^all$/)) && (instance.match(/#{values['id']}/) || values['id'].to_s.match(/^#{values['empty']}$|^all$/))
  end
  nil
end

# List docker images

def list_docker_images(values)
  images = get_docker_image_list(values)
  images.each do |image|
    verbose_message(image) if (image.match(/#{values['name']}/) || values['name'].to_s.match(/^#{values['empty']}$|^all$/)) && (image.match(/#{values['id']}/) || values['id'].to_s.match(/^#{values['empty']}$|^all$/))
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
  exists  = false
  message = "Information:\tChecking docker instances for #{values['name']}"
  command = 'docker-machine ls'
  output  = execute_command(values, message, command)
  output  = output.split(/\n/)
  output.each do |line|
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
