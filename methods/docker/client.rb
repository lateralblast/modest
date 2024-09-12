# Docker client code

# Execute command on docker client

def execute_docker_command(values)
  command = values['command'].to_s 
	exists  = check_docker_vm_exists(values)
	if exists == true
		output = %x[docker-machine ssh #{values['name']} "#{command}']
		verbose_output(values,output)
	else
		verbose_output(values, "Information:\tDocker instance #{values['name']} does not exist")
	end
	return
end

# Connect to docker client

def connect_to_docker_client(values)
	exists = check_docker_vm_exists(values)
	if exists == true
		verbose_output(values, "Command:\tdocker ssh #{values['name']}")
	else
		verbose_output(values, "Information:\tDocker instance #{values['name']} does not exist")
	end
	return
end



# Add docker client

def configure_docker_client(values)
	install_docker()
	docker_dir = values['clientdir']+"/docker"
	if values['vm'].to_s.match(/box/)
		if values['vmnetwork'].to_s.match(/hostonly/)
			if values['ip'].empty?
				values['ip'] = values['ip']
			end
		end
		docker_vm = "virtualbox"
	else
		if values['vmnetwork'].to_s.match(/hostonly/)
			if values['ip'].empty?
				values['ip'] = values['ip']
			end
		end
		docker_vm = "vmwarefusion"
	end
	exists = check_docker_vm_exists(values)
	if exists == false
		message = "Information:\tCreating docker VM #{values['name']}"
		if values['vm'].to_s.match(/box/)
			if not values['ip'].empty?
				command = "docker-machine create --driver #{docker_vm} --#{docker_vm}-hostonly-cidr #{values['ip']}/#{values['cidr']} #{values['name']}"
			else
				command = "docker-machine create --driver #{docker_vm} #{values['name']}"
			end
		else
			command = "docker-machine create --driver #{docker_vm} #{values['name']}"
		end
		execute_command(values, message, command)
	else
		verbose_output(values, "Information:\tDocker instance '#{values['name']}' already exists")
	end
	return
end

def unconfigure_docker_client(values)
	exists = check_docker_vm_exists(values)
	if exists == true
		message = "Information:\tDeleting docker instance #{values['name']}"
		command = "docker-machine rm --force #{values['name']}"
		execute_command(values, message, command)
	else
		verbose_output(values, "Information:\tDocker instance #{values['name']} does not exist")
	end
	return
end
