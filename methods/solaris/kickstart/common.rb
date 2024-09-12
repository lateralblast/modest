
# Common routines for server and client configuration

# Client Linux distribution

def check_linux_distro(linux_distro)
  if not linux_distro.match(/redhat|centos/)
    verbose_output(values, "Warning:\tNo Linux distribution given")
    verbose_output(values, "Use redhat or centos")
    quit(values)
  end
  return
end

# Get VSphere info from ISO file name

def get_vsphere_version_info(file_name)
  iso_info     = File.basename(file_name)
  iso_info     = iso_info.split(/-/)
  linux_distro = iso_info[0]
  iso_version  = iso_info[3]
  iso_arch     = iso_info[4].split(/\./)[1]
  return linux_distro, iso_version, iso_arch
end

# List ISOs

def list_ks_isos()
  if not values['search'].to_s.match(/[a-z]|[A-Z]|all/)
    values['search'] = "CentOS|rhel|SL|OracleLinux|Fedora"
  end
  list_linux_isos(values)
  return
end
