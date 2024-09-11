# Common Docker code

# Install docker

def install_docker(values)
	if values['host-os-uname'].to_s.match(/Darwin/)
		if not Dir.exist?("/Applications/Docker.app")
			handle_output(values, "Information:\tDocker no installed")
			handle_output(values, "Download:\thttps://docs.docker.com/docker-for-mac/")
			quit(values)
		end
	end
	return
end

# Get docker image list

def get_docker_image_list(values)
  message = "Information:\tListing docker images"
  command = "docker image list"
  output  = execute_command(values, message, command)
  images  = output.split(/\n/)
  return images
end

# Get docker instance list

def get_docker_instance_list(values)
  message   = "Information:\tListing docker images"
  command   = "docker ps"
  output    = execute_command(values, message, command)
  instances = output.split(/\n/)
  return instances
end

# Get docker image id from name

def get_docker_image_id_from_name(values)
  image_id = "none"
  images   = get_docker_image_list(values)
  images.each do |image|
    docker_values = image.split(/\s+/)
    image_name    = docker_values[0]
    image_id      = docker_values[2]
    if image_name.match(/#{values['name']}/)
      return image_id
    end
  end
  return image_id
end

# Delete docker image

def delete_docker_image(values)
  if values['id'].length > 12 or values['id'].to_s.match(/[A-Z]|[g-z]/)
    values['id'] = get_docker_image_id_from_name(values)
  end
  if values['id']== values['empty']
    handle_output(values, "Information:\tNo image found")
    quit(values)
  end
  message   = "Information:\tListing docker images"
  command   = "docker image rm #{values['id']}"
  output    = execute_command(values, message, command)
  handle_output(values, output)
  return
end

# Check docker is installed

def check_docker_is_installed(values)
  installed   = "yes"
  docker_file = ""
	if values['host-os-uname'].to_s.match(/Darwin/)
		[ "docker", "docker-compose", "docker-machine" ].each do |check_file|
			file_name = "/usr/local/bin/"+check_file
      if not File.exist?(file_name) and not File.symlink?(file_name)
        docker_file = check_file
				installed   = "no"
			end
		end
	end
	if installed == "no"
    handle_output(values,"Information:\tDocker #{docker_file} not installed")
    if values['host-os-uname'].to_s.match(/Darwin/)
      values = install_package(docker_file)
    else
      quit(values)
    end
	end
	return
end

# List docker instances

def list_docker_instances(values)
  instances = get_docker_instance_list()
	instances.each do |instance|
    if instance.match(/#{values['name']}/) or values['name'].to_s.match(/^#{values['empty']}$|^all$/)
      if instance.match(/#{values['id']}/) or values['id'].to_s.match(/^#{values['empty']}$|^all$/)
        handle_output(instance)
      end
    end
	end
	return
end

# List docker images 

def list_docker_images(values)
  images =get_docker_image_list(values)
  images.each do |image|
    if image.match(/#{values['name']}/) or values['name'].to_s.match(/^#{values['empty']}$|^all$/)
      if image.match(/#{values['id']}/) or values['id'].to_s.match(/^#{values['empty']}$|^all$/)
        handle_output(image)
      end
    end
  end
  return
end

# List docker VMs

def list_docker_vms(values)
  values['id'] = "none"
  list_docker_images(values)
  return
end

# Check docker instance exists

def check_docker_vm_exists(values)
  exists  = false
  message = "Information:\tChecking docker instances for #{values['name']}"
  command = "docker-machine ls"
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
  return exists
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
  return exists
end

