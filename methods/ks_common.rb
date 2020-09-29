
# Common routines for server and client configuration

# Question/config structure

Ks = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

# Client Linux distribution

def check_linux_distro(linux_distro)
  if not linux_distro.match(/redhat|centos/)
    handle_output(options,"Warning:\tNo Linux distribution given")
    handle_output(options,"Use redhat or centos")
    quit(options)
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
  return linux_distro,iso_version,iso_arch
end

# List ISOs

def list_ks_isos()
  search_string = "CentOS|rhel|SL|OracleLinux|Fedora"
  linux_type    = "CentOS, Red Hat Enterprise, Oracle Linux, Scientific or Fedora"
  list_linux_isos(search_string,linux_type)
  return
end
