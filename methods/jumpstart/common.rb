
# Common code to all Jumpstart functions

# Question/config structure

Js = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)


def populate_js_fs_list(values)
  # UFS filesystems
  fs = Struct.new(:name, :mount, :slice, :mirror, :size)

  f_struct = {}
  f_order  = []

  name = "root"
  config = fs.new(
    name   = "root",
    mount  = "/",
    slice  = "0",
    mirror = "d10",
    size   = values['slice']
    )
  f_struct[name] = config
  f_order.push(name)

  name = "swap"
  config = fs.new(
    name   = "swap",
    mount  = "/",
    slice  = "1",
    mirror = "d20",
    size   = values['slice']
    )
  f_struct[name] = config
  f_order.push(name)

  name = "var"
  config = fs.new(
    name   = "var",
    mount  = "/var",
    slice  = "3",
    mirror = "d30",
    size   = values['slice']
    )
  f_struct[name] = config
  f_order.push(name)

  name = "opt"
  config = fs.new(
    name   = "opt",
    mount  = "/opt",
    slice  = "4",
    mirror = "d40",
    size   = "1024"
    )
  f_struct[name] = config
  f_order.push(name)

  name = "export"
  config = fs.new(
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

def get_js_iso_version(values)
  message = "Checking:\tSolaris Version"
  command = "ls #{values['repodir']} |grep Solaris"
  output  = execute_command(values,message,command)
  iso_version = output.chomp
  iso_version = iso_version.split(/_/)[1]
  return iso_version
end

# Get ISO/repo update info

def get_js_iso_update(values)
  update  = ""
  if values['type'].to_s.match(/client/)
    release = values['repodir'].to_s+"/Solaris_"+values['version']+"/Product/SUNWsolnm/reloc/etc/release"
  else
    release = values['mountdir'].to_s+"/Solaris_"+values['version']+"/Product/SUNWsolnm/reloc/etc/release"
  end
  message = "Checking:\tSolaris release"
  command = "cat #{release} |head -1 |awk \"{print \\\$4}\""
  output  = execute_command(values, message, command)
  if output.match(/_/)
    update = output.split(/_/)[1].gsub(/[a-z]/, "")
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

def list_js_isos(values)
  values['search'] = "\\-ga\\-|_ga_"
  iso_list = get_base_dir_list(values)
  if iso_list.length > 0
    if values['output'].to_s.match(/html/)
      handle_output(values, "<h1>Available Jumpstart ISOs:</h1>")
      handle_output(values, "<table border=\"1\">")
      handle_output(values, "<tr>")
      handle_output(values, "<th>ISO File</th>")
      handle_output(values, "<th>Distribution</th>")
      handle_output(values, "<th>Version</th>")
      handle_output(values, "<th>Architecture</th>")
      handle_output(values, "<th>Service Name</th>")
      handle_output(values, "</tr>")
    else
      handle_output(values, "Available Jumpstart ISOs:")
      handle_output(values, "") 
    end
    iso_list.each do |file_name|
      file_name   = file_name.chomp
      iso_info    = File.basename(file_name)
      iso_info    = iso_info.split(/-/)
      iso_version = iso_info[1..2].join("_")
      iso_arch    = iso_info[4]
      if values['output'].to_s.match(/html/)
        handle_output(values, "<tr>")
        handle_output(values, "<td>#{file_name}</td>")
        handle_output(values, "<td>Solaris</td>")
        handle_output(values, "<td>#{iso_version}</td>")
        handle_output(values, "<td>#{iso_arch}</td>")
      else
        handle_output(values, "ISO file:\t#{file_name}")
        handle_output(values, "Distribution:\tSolaris")
        handle_output(values, "Version:\t#{iso_version}")
        handle_output(values, "Architecture:\t#{iso_arch}")
      end
      values['service'] = "sol_"+iso_version+"_"+iso_arch
      values['repodir'] = values['baserepodir']+"/"+values['service']
      if File.directory?(values['repodir'])
        if values['output'].to_s.match(/html/)
          handle_output(values, "<td>#{values['service']} (exists)</td>")
        else
          handle_output(values, "Information:\tService Name #{values['service']} (exists)")
        end
      else
        if values['output'].to_s.match(/html/)
          handle_output(values, "<td>#{values['service']}</td>")
        else
          handle_output(values, "Information:\tService Name #{values['service']}")
        end
      end
      if values['output'].to_s.match(/html/)
        handle_output(values, "</tr>") 
      else
        handle_output(values, "") 
      end
    end
    if values['output'].to_s.match(/html/)
      handle_output(values, "</table>")
    end
  end
  return
end
