# frozen_string_literal: true

# Docker client code

# Execute command on docker client

def execute_docker_command(values)
  command = values['command'].to_s
  exists = check_docker_vm_exists(values)
  if exists == true
    output = `docker-machine ssh #{values['name']} "#{command}'`
    verbose_message(values, output)
  else
    information_message(values, "Docker instance #{values['name']} does not exist")
  end
  nil
end

# Connect to docker client

def connect_to_docker_client(values)
  exists = check_docker_vm_exists(values)
  if exists == true
    verbose_message(values, "Command:\tdocker ssh #{values['name']}")
  else
    information_message(values, "Docker instance #{values['name']} does not exist")
  end
  nil
end

# Add docker client

def configure_docker_client(values)
  install_docker(values)
  values['clientdir']
  values['ip'] = values['ip'] if values['vmnetwork'].to_s.match(/hostonly/) && values['ip'].empty?
  docker_vm = if values['vm'].to_s.match(/box/)
                'virtualbox'
              else
                'vmwarefusion'
              end
  exists = check_docker_vm_exists(values)
  if exists == false
    message = "Information:\tCreating docker VM #{values['name']}"
    command = if values['vm'].to_s.match(/box/)
                if !values['ip'].empty?
                  "docker-machine create --driver #{docker_vm} --#{docker_vm}-hostonly-cidr #{values['ip']}/#{values['cidr']} #{values['name']}"
                else
                  "docker-machine create --driver #{docker_vm} #{values['name']}"
                end
              else
                "docker-machine create --driver #{docker_vm} #{values['name']}"
              end
    execute_command(values, message, command)
  else
    information_message(values, "Docker instance '#{values['name']}' already exists")
  end
  nil
end

def unconfigure_docker_client(values)
  exists = check_docker_vm_exists(values)
  if exists == true
    message = "Information:\tDeleting docker instance #{values['name']}"
    command = "docker-machine rm --force #{values['name']}"
    execute_command(values, message, command)
  else
    information_message(values, "Docker instance #{values['name']} does not exist")
  end
  nil
end
