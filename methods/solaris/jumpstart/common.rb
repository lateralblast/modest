
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
      verbose_message(values, "<h1>Available Jumpstart ISOs:</h1>")
      verbose_message(values, "<table border=\"1\">")
      verbose_message(values, "<tr>")
      verbose_message(values, "<th>ISO File</th>")
      verbose_message(values, "<th>Distribution</th>")
      verbose_message(values, "<th>Version</th>")
      verbose_message(values, "<th>Architecture</th>")
      verbose_message(values, "<th>Service Name</th>")
      verbose_message(values, "</tr>")
    else
      verbose_message(values, "Available Jumpstart ISOs:")
      verbose_message(values, "") 
    end
    iso_list.each do |file_name|
      file_name   = file_name.chomp
      iso_info    = File.basename(file_name)
      iso_info    = iso_info.split(/-/)
      iso_version = iso_info[1..2].join("_")
      iso_arch    = iso_info[4]
      if values['output'].to_s.match(/html/)
        verbose_message(values, "<tr>")
        verbose_message(values, "<td>#{file_name}</td>")
        verbose_message(values, "<td>Solaris</td>")
        verbose_message(values, "<td>#{iso_version}</td>")
        verbose_message(values, "<td>#{iso_arch}</td>")
      else
        verbose_message(values, "ISO file:\t#{file_name}")
        verbose_message(values, "Distribution:\tSolaris")
        verbose_message(values, "Version:\t#{iso_version}")
        verbose_message(values, "Architecture:\t#{iso_arch}")
      end
      values['service'] = "sol_"+iso_version+"_"+iso_arch
      values['repodir'] = values['baserepodir']+"/"+values['service']
      if File.directory?(values['repodir'])
        if values['output'].to_s.match(/html/)
          verbose_message(values, "<td>#{values['service']} (exists)</td>")
        else
          information_message(values, "Service Name #{values['service']} (exists)")
        end
      else
        if values['output'].to_s.match(/html/)
          verbose_message(values, "<td>#{values['service']}</td>")
        else
          information_message(values, "Service Name #{values['service']}")
        end
      end
      if values['output'].to_s.match(/html/)
        verbose_message(values, "</tr>") 
      else
        verbose_message(values, "") 
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_message(values, "</table>")
    end
  end
  return
end
