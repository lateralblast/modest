
# Common routines for packages

# Create struct for package information

Pkg=Struct.new(:info, :type, :version, :depend, :base_url)

# Code to fetch a source file

def get_pkg_source(source_url,source_file)
  if not File.exist?("/usr/bin/wget")
    message = "Information:\tInstalling package wget"
    command = "pkg install pkg:/web/wget"
    execute_command(options,message,command)
  end
  message = "Information:\tFetching source "+source_url+" to "+source_file
  command = "wget #{source_url} -O #{source_file}"
  execute_command(options,message,command)
  return
end

# Check installed packages

def check_installed_pkg(p_struct,pkg_name)
  message           = "Information:\tChecking if package "+pkg_name+" is installed"
  command           = "pkg info #{pkg_name} |grep Version |awk \"{print \\\$2}\""
  installed_version = execute_command(options,message,command)
  installed_version = installed_version.chomp
  return installed_version
end

# Install a package

def install_pkg(p_struct,pkg_name,pkg_repo_dir)
  pkg_version       = p_struct[pkg_name].version
  installed_version = check_installed_pkg(p_struct,pkg_name)
  if not installed_version.match(/#{pkg_version}/)
    message = "Information:\tInstalling Package "+pkg_name
    command = "pkg install -g #{pkg_repo_dir} #{pkg_name}"
    execute_command(options,message,command)
  end
  return
end

# Install local package

def install_package(options,pkg_name)
  if !options['host-os-packages'].to_s.match(/\"#{pkg_name}\"/)
    if options['host-os-name'].to_s.match(/Darwin/)
      install_osx_package(options,pkg_name)
    end
    if options['host-os-name'].to_s.match(/Linux/)
      install_linux_package(options,pkg_name)
    end
    options = update_package_list(options)
  end
  return options
end

# Updage package list

def update_package_list(options)
  if options['host-os-name'].match(/Darwin/)
    if File.exist?("/usr/local/bin/brew")
      options['host-os-packages'] = %x[/usr/local/bin/brew list].split(/\s+|\n/)
    end
  end
  return options
end

# Handle a package

def handle_pkg(p_struct,pkg_name,build_type,pkg_repo_dir)
  if options['verbose'] == true
    handle_output(options,"Information:\tHandling Package #{pkg_name}")
  end
  depend_list     = []
  pkg_version     = p_struct[pkg_name].version
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
        if options['verbose'] == true
          handle_output(options,"Information:\tHandling dependency #{depend_pkg_name}")
        end
        build_pkg(p_struct,depend_pkg_name,build_type,pkg_repo_dir)
        install_pkg(p_struct,depend_pkg_name,pkg_repo_dir)
      end
    end
    repo_pkg_version = check_pkg_repo(p_struct,pkg_name,pkg_repo_dir)
    if not repo_pkg_version.match(/#{pkg_version}/)
      build_pkg(p_struct,pkg_name,build_type,pkg_repo_dir)
      install_pkg(p_struct,pkg_name,pkg_repo_dir)
    end
  else
    repo_pkg_version = check_pkg_repo(p_struct,pkg_name,pkg_repo_dir)
    if not repo_pkg_version.match(/#{pkg_version}/)
      build_pkg(p_struct,pkg_name,build_type,pkg_repo_dir)
      install_pkg(p_struct,pkg_name,pkg_repo_dir)
    end
  end
  return
end

# Process package list

def process_pkgs(p_struct,pkg_repo_dir,build_type)
  p_struct.each do |pkg_name, value|
    handle_pkg(p_struct,pkg_name,build_type,pkg_repo_dir)
  end
  return
end

# Get the alternate repository name

def check_alt_install_service(options)
  if not options['service'].to_s.match(/[a-z,A-Z]/)
    options['arch']       = %x[uname -p]
    options['arch']       = options['arch'].chomp()
    options['service']      = get_install_service(options['arch'])
    service_base_name = get_service_base_name(options['service'])
    alt_options['service']  = service_base_name+"_"+$alt_repo_name
  else
    alt_options['service'] = options['service']
  end
  return alt_options['service']
end

# Uninstall package

def uninstall_pkg(pkg_name)
  message = "Information:\tChecking if package "+pkg_name+" is installed"
  command = "pkg info #{pkg_name} |grep Version |awk \"{print \\\$2}\""
  output  = execute_command(options,message,command)
  if output.match(/[0-9]/)
    message = "Information:\tUninstalling Package "+pkg_name
    command = "pkg uninstall #{pkg_name}"
    output  = execute_command(options,message,command)
  end
  return
end
