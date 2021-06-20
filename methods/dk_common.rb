# Common Docker code

# Install docker

def install_docker(options)
	if options['host-os-name'].to_s.match(/Darwin/)
		if not Dir.exist?("/Applications/Docker.app")
			handle_output(options,"Information:\tDocker no installed")
			handle_output(options,"Download:\thttps://docs.docker.com/docker-for-mac/")
			quit(options)
		end
	end
	return
end

# Get docker image list

def get_docker_image_list(options)
  message = "Information:\tListing docker images"
  command = "docker image list"
  output  = execute_command(options,message,command)
  images  = output.split(/\n/)
  return images
end

# Get docker instance list

def get_docker_instance_list(options)
  message   = "Information:\tListing docker images"
  command   = "docker ps"
  output    = execute_command(options,message,command)
  instances = output.split(/\n/)
  return instances
end

# Get docker image id from name

def get_docker_image_id_from_name(options)
  image_id = "none"
  images   = get_docker_image_list(options)
  images.each do |image|
    values     = image.split(/\s+/)
    image_name = values[0]
    image_id   = values[2]
    if image_name.match(/#{options['name']}/)
      return image_id
    end
  end
  return image_id
end

# Delete docker image

def delete_docker_image(options)
  if options['id'].length > 12 or options['id'].to_s.match(/[A-Z]|[g-z]/)
    options['id'] = get_docker_image_id_from_name(options)
  end
  if options['id']== options['empty']
    handle_output(options,"Information:\tNo image found")
    quit(options)
  end
  message   = "Information:\tListing docker images"
  command   = "docker image rm #{options['id']}"
  output    = execute_command(options,message,command)
  handle_output(options,output)
  return
end

# Check docker is installed

def check_docker_is_installed(options)
  installed   = "yes"
  docker_file = ""
	if options['host-os-name'].to_s.match(/Darwin/)
		[ "docker", "docker-compose", "docker-machine" ].each do |check_file|
			file_name = "/usr/local/bin/"+check_file
      if not File.exist?(file_name) and not File.symlink?(file_name)
        docker_file = check_file
				installed   = "no"
			end
		end
	end
	if installed == "no"
    handle_output(options,"Information:\tDocker #{docker_file} not installed")
    if options['host-os-name'].to_s.match(/Darwin/)
      options = install_package(docker_file)
    else
      quit(options)
    end
	end
	return
end

# List docker instances

def list_docker_instances(options)
  instances = get_docker_instance_list()
	instances.each do |instance|
    if instance.match(/#{options['name']}/) or options['name'].to_s.match(/^#{options['empty']}$|^all$/)
      if instance.match(/#{options['id']}/) or options['id'].to_s.match(/^#{options['empty']}$|^all$/)
        handle_output(instance)
      end
    end
	end
	return
end

# List docker images 

def list_docker_images(options)
  images =get_docker_image_list(options)
  images.each do |image|
    if image.match(/#{options['name']}/) or options['name'].to_s.match(/^#{options['empty']}$|^all$/)
      if image.match(/#{options['id']}/) or options['id'].to_s.match(/^#{options['empty']}$|^all$/)
        handle_output(image)
      end
    end
  end
  return
end

# List docker VMs

def list_docker_vms(options)
  options['id'] = "none"
  list_docker_images(options)
  return
end

# Check docker instance exists

def check_docker_vm_exists(options)
  exists  = "no"
  message = "Information:\tChecking docker instances for #{options['name']}"
  command = "docker-machine ls"
  output  = execute_command(options,message,command)
  output  = output.split(/\n/)
  output.each do |line|
    line  = line.chomp
    items = line.split(/\s+/)
    host  = items[0]
    if host.match(/^#{options['name']}$/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

# Check docker image exists

def check_docker_image_exists(options)
  exists = "no"
  images = get_docker_image_list(options)
  images.each do |line|
    line  = line.chomp
    items = line.split(/\s+/)
    host  = items[0]
    if host.match(/^#{options['name']}$/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

