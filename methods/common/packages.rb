
# Common routines for packages

# Create struct for package information

# Pkg=Struct.new(:info, :type, :version, :depend, :base_url)

# Code to fetch a source file

def get_pkg_source(source_url, source_file)
  if not File.exist?("/usr/bin/wget")
    message = "Information:\tInstalling package wget"
    command = "pkg install pkg:/web/wget"
    execute_command(values, message, command)
  end
  message = "Information:\tFetching source "+source_url+" to "+source_file
  command = "wget #{source_url} -O #{source_file}"
  execute_command(values, message, command)
  return
end

# Check installed packages

def check_installed_pkg(p_struct, pkg_name)
  message = "Information:\tChecking if package "+pkg_name+" is installed"
  command = "pkg info #{pkg_name} |grep Version |awk \"{print \\\$2}\""
  ins_ver = execute_command(values, message, command)
  ins_ver = ins_ver.chomp
  return ins_ver
end

# Install a package

def install_pkg(p_struct, pkg_name, pkg_repo_dir)
  pkg_ver = p_struct[pkg_name].version
  ins_ver = check_installed_pkg(p_struct, pkg_name)
  if not ins_ver.match(/#{pkg_ver}/)
    message = "Information:\tInstalling Package "+pkg_name
    command = "pkg install -g #{pkg_repo_dir} #{pkg_name}"
    execute_command(values, message, command)
  end
  return
end

# Install local package

def install_package(values, pkg_name)
  if !values['host-os-packages'].to_s.match(/\"#{pkg_name}\"/)
    if values['host-os-uname'].to_s.match(/Darwin/)
      install_osx_package(values, pkg_name)
    end
    if values['host-os-uname'].to_s.match(/Linux/)
      install_linux_package(values, pkg_name)
    end
    values = update_package_list(values)
  end
  return values
end

# Updage package list

def update_package_list(values)
  if values['host-os-uname'].match(/Darwin/)
    if File.exist?("/usr/local/bin/brew")
      values['host-os-packages'] = %x[/usr/local/bin/brew list].split(/\s+|\n/)
    end
  end
  return values
end

# Handle a package

def handle_pkg(p_struct, pkg_name, build_type, pkg_repo_dir)
  if values['verbose'] == true
    verbose_output(values, "Information:\tHandling Package #{pkg_name}")
  end
  depend_list   = []
  pkg_version   = p_struct[pkg_name].version
  temp_pkg_name = p_struct[pkg_name].depend
  if tempt_pkg_name.match(/[a-z,A-Z]/)
    if temp_pkg_name.match(/,/)
      depend_list = temp_pkg_name.split(/,/)
    else
      depend_list[0] = temp_pkg_name
    end
    depend_list.each do |depend_pkg_name|
      if depend_pkg_name.match(/\//)
          depend_pkg_name = depend_pkg_name.split(/\//)[-1]
        if depend_pkg_name.match(/\ = /)
          depend_pkg_name = depend_pkg_name.split(/ /)[0]
        end
      end
      if not depend_pkg_name.match(/#{pkg_name}/)
        if values['verbose'] == true
          verbose_output(values, "Information:\tHandling dependency #{depend_pkg_name}")
        end
        build_pkg(p_struct, depend_pkg_name, build_type, pkg_repo_dir)
        install_pkg(p_struct, depend_pkg_name, pkg_repo_dir)
      end
    end
    repo_pkg_version = check_pkg_repo(p_struct, pkg_name, pkg_repo_dir)
    if not repo_pkg_version.match(/#{pkg_version}/)
      build_pkg(p_struct, pkg_name, build_type, pkg_repo_dir)
      install_pkg(p_struct, pkg_name, pkg_repo_dir)
    end
  else
    repo_pkg_version = check_pkg_repo(p_struct, pkg_name, pkg_repo_dir)
    if not repo_pkg_version.match(/#{pkg_version}/)
      build_pkg(p_struct, pkg_name, build_type, pkg_repo_dir)
      install_pkg(p_struct, pkg_name, pkg_repo_dir)
    end
  end
  return
end

# Process package list

def process_pkgs(p_struct, pkg_repo_dir, build_type)
  p_struct.each do |pkg_name, value|
    handle_pkg(p_struct, pkg_name, build_type, pkg_repo_dir)
  end
  return
end

# Get the alternate repository name

def check_alt_install_service(values)
  if not values['service'].to_s.match(/[a-z,A-Z]/)
    values['arch'] = %x[uname -p]
    values['arch'] = values['arch'].chomp()
    values['service'] = get_install_service(values['arch'])
    service_base_name  = get_service_base_name(values['service'])
    alt_values['service'] = service_base_name+"_"+$alt_repo_name
  else
    alt_values['service'] = values['service']
  end
  return alt_values['service']
end

# Uninstall package

def uninstall_pkg(pkg_name)
  message = "Information:\tChecking if package "+pkg_name+" is installed"
  command = "pkg info #{pkg_name} |grep Version |awk \"{print \\\$2}\""
  output  = execute_command(values, message, command)
  if output.match(/[0-9]/)
    message = "Information:\tUninstalling Package "+pkg_name
    command = "pkg uninstall #{pkg_name}"
    output  = execute_command(values, message, command)
  end
  return
end

# Check RHEL package is installed

def check_rhel_package(values, package)
  message = "Information\tChecking "+package+" is installed"
  command = "rpm -q #{package}"
  output  = execute_command(values, message, command)
  if not output
    output = ""
  end
  if not output.match(/#{package}/)
    message = "installing:\t"+package
    command = "yum -y install #{package}"
    execute_command(values, message, command)
  end
  return
end

# Check Arch package is installed

def check_arch_package(values, package)
  message = "Information\tChecking "+package+" is installed"
  command = "pacman -Q #{package}"
  output  = execute_command(values, message, command)
  output  = output.chomp.split(" ")[0]
  if not output
    output = ""
  end
  if not output.match(/#{package}/)
    message = "installing:\t"+package
    command = "echo Y |pacman -Sy #{package}"
    execute_command(values, message, command)
  end
  return
end

# Check Ubuntu / Debian package is installed

def check_apt_package(values, package)
  message = "Information:\tChecking "+package+" is installed"
  command = "dpkg -l | grep '#{package}' |grep 'ii'"
  output  = execute_command(values, message, command)
  if not output
    output = ""
  end
  if not output.match(/#{package}/)
    message = "Information:\tInstalling "+package
    command = "apt-get -y -o Dpkg::values::=--force-confdef -o Dpkg::values::=--force-confnew install #{package}"
    execute_command(values, message, command)
  end
  return
end
