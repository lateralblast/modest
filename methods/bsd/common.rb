# frozen_string_literal: true

# Common *BSD and other code (e.g. CoreOS)

# List ISOs

def list_other_isos(values, _search_string)
  iso_list = get_base_dir_list(values)
  if iso_list.length.positive?
    handle_output(values, 'Other available ISOs:')
    handle_output(values, '')
  end
  iso_list.each do |file_name|
    file_name = file_name.chomp
    (iso_distro, iso_version, iso_arch) = get_other_version_info(file_name)
    handle_output(values, "ISO file:\t#{file_name}")
    handle_output(values, "Distribution:\t#{iso_distro}")
    handle_output(values, "Version:\t#{iso_version}")
    handle_output(values, "Architecture:\t#{iso_arch}")
    values['service'] = "#{iso_distro.downcase}_#{iso_version.gsub(/\./, '_')}_#{iso_arch}"
    values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
    if File.directory?(values['repodir'])
      handle_output(values, "Service Name:\t#{values['service']} (exists)")
    else
      handle_output(values, "Service Name:\t#{values['service']}")
    end
    handle_output(values, '')
  end
  nil
end

# List available *BSD ISOs

def list_xb_isos(values)
  search_string = 'install|FreeBSD|coreos'
  list_other_isos(values, search_string)
  nil
end

# Get BSD version info from the ISO

def get_other_version_info(values)
  case values['file'].to_s
  when /install/
    iso_distro = 'OpenBSD'
    if !values['file'].to_s.match(/i386|x86_64|amd64/)
      iso_arch    = `strings #{shell_arg(values['file'])} |head -2 |tail -1 |awk '{print $2}'`.split(%r{/})[1].chomp
      iso_version = File.basename(values['file'], '.iso').gsub(/install/, '').split(//).join('.')
    else
      iso_arch = File.basename(values['file'], '.iso').split(/-/)[1]
      iso_arch = 'x86_64' if iso_arch.match(/amd64/)
      iso_version = File.basename(values['file'], '.iso').split(/-/)[0].gsub(/install/, '').split(//).join('.')
    end
  when /FreeBSD/
    iso_info = File.basename(values['file']).split(/-/)
    iso_distro  = iso_info[0]
    iso_version = iso_info[1]
    iso_arch = if values['file'].to_s.match(/amd64/)
                 'x86_64'
               else
                 'i386'
               end
  when /coreos/
    iso_info = File.basename(values['file']).split(/_/)
    iso_distro  = 'coreos'
    iso_version = iso_info[1]
    iso_arch    = 'x86_64'
  end
  [iso_distro, iso_version, iso_arch]
end

# Get BSD service name from ISO

def get_xb_install_service(values)
  values['service']
end
