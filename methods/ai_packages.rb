
# AI Package routines

# Populate package information

def populate_ai_pkg_info()
  p_struct = {}

  #   name = "facter"
  #   config = Pkg.new(
  #     info      = "Facter is an independent, cross-platform Ruby library designed to gather information on all the nodes you will be managing with Puppet.",
  #     type      = "ruby",
  #     version   = "1.7.4",
  #     depend    = "",
  #     base_url  = "http://downloads.puppetlabs.com/#{name}"
  #     )
  #   p_struct[name]=config

  return p_struct
end

# Create mog file

def create_ai_mog_file(p_struct,pkg_name,spool_dir)
  pkg_info    = p_struct[pkg_name].info
  pkg_depend  = p_struct[pkg_name].depend
  pkg_version = p_struct[pkg_name].version
  pkg_arch    = %x[uname -p]
  pkg_arch    = pkg_arch.chomp
  mog_file    = spool_dir+"/"+pkg_name+".mog"
  depend_list = []
  output_text = []
  output_text.push("set name = pkg.fmri value=application/#{pkg_name}@#{pkg_version},1.0")
  output_text.push("set name = pkg.description value=\"#{pkg_info}\"")
  output_text.push("set name = pkg.summary value=\"#{pkg_name} #{pkg_version}\"")
  output_text.push("set name = variant.arch value=#{pkg_arch}")
  output_text.push("set name = info.classification value=\"org.opensolaris.category.2008:Applications/System Utilities\"")
  if pkg_depend.match(/[a-z,A-Z]/)
    if pkg_depend.match(/,/)
      depend_list = pkg_depend.split(/,/)
    else
      depend_list[0] = pkg_depend
    end
    depend_list.each do |temp_depend|
      output_text.push(temp_depend)
    end
  end
  File.open(mog_file,"w") {|file| file.puts output_text}
  return mog_file
end

# Create IPS package

def create_ai_ips_pkg(options,pkg_name,spool_dir,install_dir,mog_file)
  manifest_file = spool_dir+"/"+pkg_name+".p5m"
  temp_file_1   = spool_dir+"/"+pkg_name+".p5m.1"
  temp_file_2   = spool_dir+"/"+pkg_name+".p5m.2"
  commands      = []
  commands.push("cd #{install_dir} ; pkgsend generate . |pkgfmt > #{temp_file_1}")
  commands.push("cd #{install_dir} ; pkgmogrify -DARCH=#{pkg_arch} #{temp_file_1} #{mog_file} |pkgfmt > #{temp_file_2}")
  commands.push("cd #{install_dir} ; pkgdepend generate -md . #{temp_file_2} |pkgfmt |sed 's/path=usr owner=root group=bin/path=usr owner=root group=sys/g' |sed 's/path=etc owner=root group=bin/path=usr owner=root group=sys/g' > #{manifest_file}")
  commands.push("cd #{install_dir} ; pkgdepend resolve -m #{manifest_file}")
  commands.each do |command|
    message = ""
    execute_command(options,message,command)
  end
  return
end

# Publish IPS package

def publish_ai_ips_pkg(options,pkg_name,spool_dir,install_dir,pkg_repo_dir)
  message = "Information:\tPublishing package "+pkg_name+" to "+pkg_repo_dir
  command = "cd #{install_dir} ; pkgsend publish -s #{pkg_repo_dir} -d . #{spool_dir}/#{pkg_name}.p5m.res"
  execute_command(options,message,command)
  return
end

# Build package

def build_ai_pkg(options,p_struct,pkg_name,build_type,pkg_repo_dir)
  pkg_version      = p_struct[pkg_name].version
  repo_pkg_version = check_pkg_repo(p_struct,pkg_name,pkg_repo_dir)
  if not repo_pkg_version.match(/#{pkg_version}/)
    source_dir = options['baserepodir']+"/source"
    check_fs_exists(options,source_dir)
    pkg_version = p_struct[pkg_name].version
    source_name = pkg_name+"-"+pkg_version+".tar.gz"
    source_file = source_dir+"/"+source_name
    source_base_url = p_struct[pkg_name].base_url
    source_url = source_base_url+"/"+source_name
    if not File.exist?(source_file)
      get_pkg_source(source_url,source_file)
    end
    build_dir = options['workdir']+"/build"
    check_dir_exists(options,build_dir)
    install_dir = build_dir+"/install"
    extract_dir = build_dir+"/source"
    spool_dir   = build_dir+"/spool"
    dir_list    = [ install_dir, extract_dir, spool_dir ]
    dir_list.each do |dir_name|
      if File.directory?(dir_name)
        message = "Cleaning:\tDirectory "+dir_name
        command = "cd #{dir_name} ; rm -rf *"
        execute_command(options,message,command)
      end
      check_dir_exists(options,dir_name)
    end
    message = "Information:\tExtracting source "+source_file+" to "+extract_dir
    command = "cd #{extract_dir} ; gcat #{source_file} |tar -xpf -"
    execute_command(options,message,command)
    compile_dir = extract_dir+"/"+pkg_name+"-"+pkg_version
    if p_struct[pkg_name].type.match(/ruby/)
      message = "Compling:\t"+pkg_name
      command = "cd #{compile_dir} ; ./install.rb --destdir=#{install_dir} --full"
      execute_command(options,message,command)
    end
    if build_type.match(/ips/)
      mog_file = create_mog_file(p_struct,pkg_name,spool_dir)
      options['arch'] = %x[uname -p].chomp
      create_ai_ips_pkg(options,pkg_name,spool_dir,install_dir,mog_file)
      publish_ai_ips_pkg(options,pkg_name,spool_dir,install_dir,pkg_repo_dir)
    end
  end
  return
end

# Check a package is in the repository

def check_ai_pkg_repo(options,p_struct,pkg_name,pkg_repo_dir)
  pkg_version=p_struct[pkg_name].version
  message = "Information:\tChecking if repository contains "+pkg_name+" "+pkg_version
  command = "pkg info -g #{pkg_repo_dir} -r #{pkg_name} |grep Version |awk \"{print \\\$2}\""
  output  = execute_command(options,message,command)
  repo_pkg_version = output.chomp
  return repo_pkg_version
end
