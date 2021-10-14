# Docker client code

# Execute command on docker client

def execute_docker_command(options)
  command = options['command'].to_s 
	exists  = check_docker_vm_exists(options)
	if exists == "yes"
		output = %x[docker-machine ssh #{options['name']} "#{command}']
		handle_output(options,output)
	else
		handle_output(options,"Information:\tDocker instance #{options['name']} does not exist")
	end
	return
end

# Connect to docker client

def connect_to_docker_client(options)
	exists = check_docker_vm_exists(options)
	if exists == "yes"
		handle_output(options,"Command:\tdocker ssh #{options['name']}")
	else
		handle_output(options,"Information:\tDocker instance #{options['name']} does not exist")
	end
	return
end



# Add docker client

def configure_docker_client(options)
	install_docker()
	docker_dir = options['clientdir']+"/docker"
	if options['vm'].to_s.match(/box/)
		if options['vmnetwork'].to_s.match(/hostonly/)
			if options['ip'].empty?
				options['ip'] = options['ip']
			end
		end
		docker_vm = "virtualbox"
	else
		if options['vmnetwork'].to_s.match(/hostonly/)
			if options['ip'].empty?
				options['ip'] = options['ip']
			end
		end
		docker_vm = "vmwarefusion"
	end
	exists = check_docker_vm_exists(options)
	if exists == "no"
		message = "Information:\tCreating docker VM #{options['name']}"
		if options['vm'].to_s.match(/box/)
			if not options['ip'].empty?
				command = "docker-machine create --driver #{docker_vm} --#{docker_vm}-hostonly-cidr #{options['ip']}/#{options['cidr']} #{options['name']}"
			else
				command = "docker-machine create --driver #{docker_vm} #{options['name']}"
			end
		else
			command = "docker-machine create --driver #{docker_vm} #{options['name']}"
		end
		execute_command(options,message,command)
	else
		handle_output(options,"Information:\tDocker instance '#{options['name']}' already exists")
	end
	return
end

def unconfigure_docker_client(options)
	exists = check_docker_vm_exists(options)
	if exists == "yes"
		message = "Information:\tDeleting docker instance #{options['name']}"
		command = "docker-machine rm --force #{options['name']}"
		execute_command(options,message,command)
	else
		handle_output(options,"Information:\tDocker instance #{options['name']} does not exist")
	end
	return
end
