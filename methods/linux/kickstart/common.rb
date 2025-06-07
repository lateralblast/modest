# frozen_string_literal: true

# Common routines for server and client configuration

# Client Linux distribution

def check_linux_distro(linux_distro)
  unless linux_distro.match(/redhat|centos/)
    warning_message(values, 'No Linux distribution given')
    verbose_message(values, 'Use redhat or centos')
    quit(values)
  end
  nil
end

# Get VSphere info from ISO file name

def get_vsphere_version_info(file_name)
  iso_info     = File.basename(file_name)
  iso_info     = iso_info.split(/-/)
  linux_distro = iso_info[0]
  iso_version  = iso_info[3]
  iso_arch     = iso_info[4].split(/\./)[1]
  [linux_distro, iso_version, iso_arch]
end

# List ISOs

def list_ks_isos(values)
  values['search'] = 'CentOS|rhel|SL|OracleLinux|Fedora' unless values['search'].to_s.match(/[a-z]|[A-Z]|all/)
  list_linux_isos(values)
  nil
end
