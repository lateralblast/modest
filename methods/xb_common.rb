# Common *BSD and other code (e.g. CoreOS)

# List ISOs

def list_other_isos(options,search_string)
  iso_list      = check_iso_base_dir(search_string)
  if iso_list.length > 0
    handle_output(options,"Other available ISOs:")
    handle_output(options,"")
  end
  iso_list.each do |file_name|
    file_name = file_name.chomp
    (iso_distro,iso_version,iso_arch) = get_other_version_info(file_name)
    handle_output(options,"ISO file:\t#{file_name}")
    handle_output(options,"Distribution:\t#{iso_distro}")
    handle_output(options,"Version:\t#{iso_version}")
    handle_output(options,"Architecture:\t#{iso_arch}")
    options['service']     = iso_distro.downcase+"_"+iso_version.gsub(/\./,"_")+"_"+iso_arch
    options['repodir'] = options['baserepodir']+"/"+options['service']
    if File.directory?(options['repodir'])
      handle_output(options,"Service Name:\t#{options['service']} (exists)")
    else
      handle_output(options,"Service Name:\t#{options['service']}")
    end
    handle_output(options,"")
  end
  return
end

# List available *BSD ISOs

def list_xb_isos()
  search_string = "install|FreeBSD|coreos"
  list_other_isos(search_string)
  return
end

# Get BSD version info from the ISO

def get_other_version_info(options)
  if options['file'].to_s.match(/install/)
    iso_distro  = "OpenBSD"
    if !options['file'].to_s.match(/i386|x86_64|amd64/)
      iso_arch    = %x[strings #{options['file']} |head -2 |tail -1 |awk '{print $2}'].split(/\//)[1].chomp
      iso_version = File.basename(options['file'],".iso").gsub(/install/,"").split(//).join(".")
    else
      iso_arch = File.basename(options['file'],".iso").split(/-/)[1]
      if iso_arch.match(/amd64/)
        iso_arch = "x86_64"
      end
      iso_version = File.basename(options['file'],".iso").split(/-/)[0].gsub(/install/,"").split(//).join(".")
    end
  else
    if options['file'].to_s.match(/FreeBSD/)
      iso_info    = File.basename(options['file']).split(/-/)
      iso_distro  = iso_info[0]
      iso_version = iso_info[1]
      if options['file'].to_s.match(/amd64/)
        iso_arch = "x86_64"
      else
        iso_arch = "i386"
      end
    else
      if options['file'].to_s.match(/coreos/)
        iso_info    = File.basename(options['file']).split(/_/)
        iso_distro  = "coreos"
        iso_version = iso_info[1]
        iso_arch    = "x86_64"
      end
    end
  end
  return iso_distro, iso_version, iso_arch
end

# Get BSD service name from ISO

def get_xb_install_service(options)
  return options['service']
end
