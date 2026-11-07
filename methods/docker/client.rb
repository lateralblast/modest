# frozen_string_literal: true

# Docker client code

# Execute command on docker client

def execute_docker_command(values)
  command = values['command'].to_s
  exists = check_docker_vm_exists(values)
  if exists == true
    output = `docker exec #{shell_arg(values['name'])} sh -c #{shell_arg(command)}`
    handle_output(values, output.chomp)
  else
    information_message(values, "Docker instance #{values['name']} does not exist")
  end
  nil
end

# Connect to docker client

def connect_to_docker_client(values)
  exists = check_docker_vm_exists(values)
  if exists == true
    verbose_message(values, "Command:\tdocker exec -it #{values['name']} sh")
  else
    information_message(values, "Docker instance #{values['name']} does not exist")
  end
  nil
end

# Return the docker platform for the host architecture (for example linux/arm64)

def docker_platform(values)
  # An architecture given with --arch wins; otherwise the host architecture is used
  machine = values['requested-arch'].to_s.match?(/\S/) ? values['requested-arch'].to_s : host_uname(:machine)
  arch = case machine
         when /arm64|aarch64/ then 'arm64'
         when /x86_64|amd64/ then 'amd64'
         else machine
         end
  verbose_message(values, "Docker platform for host architecture #{machine} is linux/#{arch}")
  "linux/#{arch}"
end

# Return true if a docker image can be found in its registry (read-only)

def docker_image_available?(image)
  system("docker manifest inspect #{shell_arg(image)} >/dev/null 2>&1")
end

# Return the image for the requested Ubuntu release. If the exact tag is not published, the release
# line (for example 26.04 for 26.04.1) is used, with a warning.

def get_docker_image_name(values)
  return nil unless values['os-type'].to_s.match(/^ubuntu$/)

  release = values['release'].to_s
  release_line = release.split('.')[0..1].join('.')
  [release, release_line].uniq.each do |tag|
    image = "ubuntu:#{tag}"
    next unless docker_image_available?(image)

    warning_message(values, "Ubuntu #{release} is not published as a Docker image, using #{image}") unless tag == release
    return image
  end
  nil
end

# Add docker client: an Ubuntu container kept running, so it can be managed like a VM

def configure_docker_client(values)
  install_docker(values)
  if check_docker_vm_exists(values)
    information_message(values, "Docker instance '#{values['name']}' already exists")
    return nil
  end
  image = get_docker_image_name(values)
  if image.nil?
    warning_message(values, "Docker VMs are only created for Ubuntu releases (requested #{values['os-type']} #{values['release']})")
    return nil
  end
  platform = docker_platform(values)
  message = "Information:\tCreating docker VM #{values['name']} from #{image} (#{platform})"
  command = "docker run -d --name #{shell_arg(values['name'])} --platform #{shell_arg(platform)} #{shell_arg(image)} sleep infinity"
  if values['dryrun'] == true
    information_message(values, "Dry run: would run: #{command}")
    return nil
  end
  execute_command(values, message, command)
  nil
end

# Delete docker client

def unconfigure_docker_client(values)
  if check_docker_vm_exists(values)
    message = "Information:\tDeleting docker instance #{values['name']}"
    command = "docker rm -f #{shell_arg(values['name'])}"
    if values['dryrun'] == true
      information_message(values, "Dry run: would run: #{command}")
      return nil
    end
    execute_command(values, message, command)
  else
    information_message(values, "Docker instance #{values['name']} does not exist")
  end
  nil
end
