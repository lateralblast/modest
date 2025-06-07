# frozen_string_literal: true

# Common code to all Jumpstart functions

# Question/config structure

Js = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

def populate_js_fs_list(values)
  # UFS filesystems
  fs = Struct.new(:name, :mount, :slice, :mirror, :size)

  f_struct = {}
  f_order  = []
  config = fs.new(
    name   = 'root',
    '/',
    '0',
    'd10',
    values['slice']
  )
  f_struct[name] = config
  f_order.push(name)
  config = fs.new(
    name   = 'swap',
    '/',
    '1',
    'd20',
    values['slice']
  )
  f_struct[name] = config
  f_order.push(name)
  config = fs.new(
    name   = 'var',
    '/var',
    '3',
    'd30',
    values['slice']
  )
  f_struct[name] = config
  f_order.push(name)
  config = fs.new(
    name   = 'opt',
    '/opt',
    '4',
    'd40',
    '1024'
  )
  f_struct[name] = config
  f_order.push(name)
  config = fs.new(
    name   = 'export',
    '/home/home',
    '5',
    'd50',
    'free'
  )
  f_struct[name] = config
  f_order.push(name)

  [f_struct, f_order]
end

# Get ISO/repo version info

def get_js_iso_version(values)
  message = "Checking:\tSolaris Version"
  command = "ls #{values['repodir']} |grep Solaris"
  output  = execute_command(values, message, command)
  iso_version = output.chomp
  iso_version.split(/_/)[1]
end

# Get ISO/repo update info

def get_js_iso_update(values)
  update = ''
  release = if values['type'].to_s.match(/client/)
              "#{values['repodir']}/Solaris_#{values['version']}/Product/SUNWsolnm/reloc/etc/release"
            else
              "#{values['mountdir']}/Solaris_#{values['version']}/Product/SUNWsolnm/reloc/etc/release"
            end
  message = "Checking:\tSolaris release"
  command = "cat #{release} |head -1 |awk \"{print \\\$4}\""
  output  = execute_command(values, message, command)
  if output.match(/_/)
    update = output.split(/_/)[1].gsub(/[a-z]/, '')
  else
    case output
    when %r{1/06}
      update = '1'
    when %r{6/06}
      update = '2'
    when %r{11/06}
      update = '3'
    when %r{8/07}
      update = '4'
    when %r{5/08}
      update = '5'
    when %r{10/08}
      update = '6'
    when %r{5/09}
      update = '7'
    when %r{10/09}
      update = '8'
    when %r{9/10}
      update = '9'
    when %r{8/11}
      update = '10'
    when %r{1/13}
      update = '11'
    end
  end
  update
end

# List available ISOs

def list_js_isos(values)
  values['search'] = '\\-ga\\-|_ga_'
  iso_list = get_base_dir_list(values)
  if iso_list.length.positive?
    if values['output'].to_s.match(/html/)
      verbose_message(values, '<h1>Available Jumpstart ISOs:</h1>')
      verbose_message(values, '<table border="1">')
      verbose_message(values, '<tr>')
      verbose_message(values, '<th>ISO File</th>')
      verbose_message(values, '<th>Distribution</th>')
      verbose_message(values, '<th>Version</th>')
      verbose_message(values, '<th>Architecture</th>')
      verbose_message(values, '<th>Service Name</th>')
      verbose_message(values, '</tr>')
    else
      verbose_message(values, 'Available Jumpstart ISOs:')
      verbose_message(values, '')
    end
    iso_list.each do |file_name|
      file_name   = file_name.chomp
      iso_info    = File.basename(file_name)
      iso_info    = iso_info.split(/-/)
      iso_version = iso_info[1..2].join('_')
      iso_arch    = iso_info[4]
      if values['output'].to_s.match(/html/)
        verbose_message(values, '<tr>')
        verbose_message(values, "<td>#{file_name}</td>")
        verbose_message(values, '<td>Solaris</td>')
        verbose_message(values, "<td>#{iso_version}</td>")
        verbose_message(values, "<td>#{iso_arch}</td>")
      else
        verbose_message(values, "ISO file:\t#{file_name}")
        verbose_message(values, "Distribution:\tSolaris")
        verbose_message(values, "Version:\t#{iso_version}")
        verbose_message(values, "Architecture:\t#{iso_arch}")
      end
      values['service'] = "sol_#{iso_version}_#{iso_arch}"
      values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
      if File.directory?(values['repodir'])
        if values['output'].to_s.match(/html/)
          verbose_message(values, "<td>#{values['service']} (exists)</td>")
        else
          information_message(values, "Service Name #{values['service']} (exists)")
        end
      elsif values['output'].to_s.match(/html/)
        verbose_message(values, "<td>#{values['service']}</td>")
      else
        information_message(values, "Service Name #{values['service']}")
      end
      if values['output'].to_s.match(/html/)
        verbose_message(values, '</tr>')
      else
        verbose_message(values, '')
      end
    end
    verbose_message(values, '</table>') if values['output'].to_s.match(/html/)
  end
  nil
end
