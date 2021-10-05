
# Common code to all Jumpstart functions

# Question/config structure

Js = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

# UFS filesystems

Fs = Struct.new(:name, :mount, :slice, :mirror, :size)

def populate_js_fs_list(options)

  f_struct = {}
  f_order  = []

  name = "root"
  config = Fs.new(
    name   = "root",
    mount  = "/",
    slice  = "0",
    mirror = "d10",
    size   = options['slice']
    )
  f_struct[name] = config
  f_order.push(name)

  name = "swap"
  config = Fs.new(
    name   = "swap",
    mount  = "/",
    slice  = "1",
    mirror = "d20",
    size   = options['slice']
    )
  f_struct[name] = config
  f_order.push(name)

  name = "var"
  config = Fs.new(
    name   = "var",
    mount  = "/var",
    slice  = "3",
    mirror = "d30",
    size   = options['slice']
    )
  f_struct[name] = config
  f_order.push(name)

  name = "opt"
  config = Fs.new(
    name   = "opt",
    mount  = "/opt",
    slice  = "4",
    mirror = "d40",
    size   = "1024"
    )
  f_struct[name] = config
  f_order.push(name)

  name = "export"
  config = Fs.new(
    name   = "export",
    mount  = "/home/home",
    slice  = "5",
    mirror = "d50",
    size   = "free"
    )
  f_struct[name] = config
  f_order.push(name)

  return f_struct,f_order
end

# Get ISO/repo version info

def get_js_iso_version(options)
  message = "Checking:\tSolaris Version"
  command = "ls #{options['repodir']} |grep Solaris"
  output  = execute_command(options,message,command)
  iso_version = output.chomp
  iso_version = iso_version.split(/_/)[1]
  return iso_version
end

# Get ISO/repo update info

def get_js_iso_update(options)
  update  = ""
  if options['type'].to_s.match(/client/)
    release = options['repodir'].to_s+"/Solaris_"+options['version']+"/Product/SUNWsolnm/reloc/etc/release"
  else
    release = options['mountdir'].to_s+"/Solaris_"+options['version']+"/Product/SUNWsolnm/reloc/etc/release"
  end
  message = "Checking:\tSolaris release"
  command = "cat #{release} |head -1 |awk \"{print \\\$4}\""
  output  = execute_command(options,message,command)
  if output.match(/_/)
    update = output.split(/_/)[1].gsub(/[a-z]/,"")
  else
    case output
    when /1\/06/
      update = "1"
    when /6\/06/
      update = "2"
    when /11\/06/
      update = "3"
    when /8\/07/
      update = "4"
    when /5\/08/
      update = "5"
    when /10\/08/
      update = "6"
    when /5\/09/
      update = "7"
    when /10\/09/
      update = "8"
    when /9\/10/
      update = "9"
    when /8\/11/
      update = "10"
    when /1\/13/
      update = "11"
    end
  end
  return update
end

# List available ISOs

def list_js_isos(options)
  options['search'] = "\\-ga\\-|_ga_"
  iso_list = get_base_dir_list(options)
  if iso_list.length > 0
    if options['output'].to_s.match(/html/)
      handle_output(options,"<h1>Available Jumpstart ISOs:</h1>")
      handle_output(options,"<table border=\"1\">")
      handle_output(options,"<tr>")
      handle_output(options,"<th>ISO File</th>")
      handle_output(options,"<th>Distribution</th>")
      handle_output(options,"<th>Version</th>")
      handle_output(options,"<th>Architecture</th>")
      handle_output(options,"<th>Service Name</th>")
      handle_output(options,"</tr>")
    else
      handle_output(options,"Available Jumpstart ISOs:")
      handle_output(options,"") 
    end
    iso_list.each do |file_name|
      file_name   = file_name.chomp
      iso_info    = File.basename(file_name)
      iso_info    = iso_info.split(/-/)
      iso_version = iso_info[1..2].join("_")
      iso_arch    = iso_info[4]
      if options['output'].to_s.match(/html/)
        handle_output(options,"<tr>")
        handle_output(options,"<td>#{file_name}</td>")
        handle_output(options,"<td>Solaris</td>")
        handle_output(options,"<td>#{iso_version}</td>")
        handle_output(options,"<td>#{iso_arch}</td>")
      else
        handle_output(options,"ISO file:\t#{file_name}")
        handle_output(options,"Distribution:\tSolaris")
        handle_output(options,"Version:\t#{iso_version}")
        handle_output(options,"Architecture:\t#{iso_arch}")
      end
      options['service'] = "sol_"+iso_version+"_"+iso_arch
      options['repodir'] = options['baserepodir']+"/"+options['service']
      if File.directory?(options['repodir'])
        if options['output'].to_s.match(/html/)
          handle_output(options,"<td>#{options['service']} (exists)</td>")
        else
          handle_output(options,"Information:\tService Name #{options['service']} (exists)")
        end
      else
        if options['output'].to_s.match(/html/)
          handle_output(options,"<td>#{options['service']}</td>")
        else
          handle_output(options,"Information:\tService Name #{options['service']}")
        end
      end
      if options['output'].to_s.match(/html/)
        handle_output(options,"</tr>") 
      else
        handle_output(options,"") 
      end
    end
    if options['output'].to_s.match(/html/)
      handle_output(options,"</table>")
    end
  end
  return
end
