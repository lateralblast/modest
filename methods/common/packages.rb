# frozen_string_literal: true

# Common routines for packages

# Create struct for package information

# Pkg=Struct.new(:info, :type, :version, :depend, :base_url)

# Code to fetch a source file

def get_pkg_source(values, source_url, source_file)
  unless File.exist?('/usr/bin/wget')
    message = "Information:\tInstalling package wget"
    command = 'pkg install pkg:/web/wget'
    execute_command(values, message, command)
  end
  message = "Information:\tFetching source #{source_url} to #{source_file}"
  command = "wget #{source_url} -O #{source_file}"
  execute_command(values, message, command)
  nil
end

# Check installed packages

def check_installed_pkg(values, pkg_name)
  message = "Information:\tChecking if package #{pkg_name} is installed"
  command = "pkg info #{pkg_name} |grep Version |awk \"{print \\\$2}\""
  ins_ver = execute_command(values, message, command)
  ins_ver.chomp
end

# Install a package

def install_pkg(values, pkg_name, pkg_repo_dir)
  pkg_ver = values['pkgs'][pkg_name].version
  ins_ver = check_installed_pkg(values, pkg_name)
  unless ins_ver.match(/#{pkg_ver}/)
    message = "Information:\tInstalling Package #{pkg_name}"
    command = "pkg install -g #{pkg_repo_dir} #{pkg_name}"
    execute_command(values, message, command)
  end
  nil
end

# Install local package

def install_package(values, pkg_name)
  unless values['host-os-packages'].to_s.match(/"#{pkg_name}"/)
    install_osx_package(values, pkg_name) if values['host-os-uname'].to_s.match(/Darwin/)
    install_linux_package(values, pkg_name) if values['host-os-uname'].to_s.match(/Linux/)
    values = update_package_list(values)
  end
  values
end

# Updage package list

def update_package_list(values)
  values['host-os-packages'] = `/usr/local/bin/brew list`.split(/\s+|\n/) if values['host-os-uname'].match(/Darwin/) && File.exist?('/usr/local/bin/brew')
  values
end

# Handle a package

def handle_pkg(values, pkg_name, build_type, pkg_repo_dir)
  information_message(values, "Handling Package #{pkg_name}")
  depend_list   = []
  pkg_version   = values['pkgs'][pkg_name].version
  temp_pkg_name = values['pkgs'][pkg_name].depend
  if tempt_pkg_name.match(/[a-z,A-Z]/)
    if temp_pkg_name.match(/,/)
      depend_list = temp_pkg_name.split(/,/)
    else
      depend_list[0] = temp_pkg_name
    end
    depend_list.each do |depend_pkg_name|
      if depend_pkg_name.match(%r{/})
        depend_pkg_name = depend_pkg_name.split(%r{/})[-1]
        depend_pkg_name = depend_pkg_name.split(/ /)[0] if depend_pkg_name.match(/\ = /)
      end
      next if depend_pkg_name.match(/#{pkg_name}/)

      information_message(values, "Handling dependency #{depend_pkg_name}")
      build_pkg(values, depend_pkg_name, build_type, pkg_repo_dir)
      install_pkg(values, depend_pkg_name, pkg_repo_dir)
    end
  end
  repo_pkg_version = check_pkg_repo(values, pkg_name, pkg_repo_dir)
  unless repo_pkg_version.match(/#{pkg_version}/)
    build_pkg(values, pkg_name, build_type, pkg_repo_dir)
    install_pkg(values, pkg_name, pkg_repo_dir)
  end
  nil
end

# Process package list

def process_pkgs(values, pkg_repo_dir, build_type)
  values['pkgs'].each_key do |pkg_name|
    handle_pkg(values, pkg_name, build_type, pkg_repo_dir)
  end
  nil
end

# Get the alternate repository name

def check_alt_install_service(values)
  if !values['service'].to_s.match(/[a-z,A-Z]/)
    values['arch'] = `uname -p`
    values['arch'] = values['arch'].chomp
    values['service'] = get_install_service(values['arch'])
    service_base_name = get_service_base_name(values['service'])
    alt_values['service'] = "#{service_base_name}_#{$alt_repo_name}"
  else
    alt_values['service'] = values['service']
  end
  alt_values['service']
end

# Uninstall package

def uninstall_pkg(pkg_name)
  message = "Information:\tChecking if package #{pkg_name} is installed"
  command = "pkg info #{pkg_name} |grep Version |awk \"{print \\\$2}\""
  output  = execute_command(values, message, command)
  if output.match(/[0-9]/)
    message = "Information:\tUninstalling Package #{pkg_name}"
    command = "pkg uninstall #{pkg_name}"
    execute_command(values, message, command)
  end
  nil
end

# Check RHEL package is installed

def check_rhel_package(values, package)
  message = "Information\tChecking #{package} is installed"
  command = "rpm -q #{package}"
  output  = execute_command(values, message, command)
  output ||= ''
  unless output.match(/#{package}/)
    message = "installing:\t#{package}"
    command = "yum -y install #{package}"
    execute_command(values, message, command)
  end
  nil
end

# Check Arch package is installed

def check_arch_package(values, package)
  message = "Information\tChecking #{package} is installed"
  command = "pacman -Q #{package}"
  output  = execute_command(values, message, command)
  output  = output.chomp.split(' ')[0]
  output ||= ''
  unless output.match(/#{package}/)
    message = "installing:\t#{package}"
    command = "echo Y |pacman -Sy #{package}"
    execute_command(values, message, command)
  end
  nil
end

# Check Ubuntu / Debian package is installed

def check_apt_package(values, package)
  message = "Information:\tChecking #{package} is installed"
  command = "dpkg -l | grep '#{package}' |grep 'ii'"
  output  = execute_command(values, message, command)
  output ||= ''
  unless output.match(/#{package}/)
    message = "Information:\tInstalling #{package}"
    command = "apt-get -y -o Dpkg::values::=--force-confdef -o Dpkg::values::=--force-confnew install #{package}"
    execute_command(values, message, command)
  end
  nil
end
