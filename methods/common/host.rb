# frozen_string_literal: true

# Host probes answered in Ruby rather than by running a shell command.
# Where Ruby cannot provide the answer on a platform, the matching command is run instead.

require 'etc'
require 'socket'

# uname flag for each field, used when Etc.uname is not available

UNAME_FLAGS = { sysname: '', nodename: '-n', release: '-r', version: '-v', machine: '-m' }.freeze

# Return one uname field, sysname by default

def host_uname(field = :sysname)
  Etc.uname.fetch(field).to_s
rescue NotImplementedError, NoMethodError
  `uname #{UNAME_FLAGS.fetch(field)}`.strip
end

# Return the same string as uname -a

def host_uname_all
  Etc.uname.values_at(:sysname, :nodename, :release, :version, :machine).join(' ')
rescue NotImplementedError, NoMethodError
  `uname -a`.strip
end

# Return the host name

def host_hostname
  Socket.gethostname
end

# Return the name of the effective user

def host_user
  Etc.getpwuid(Process.euid).name
rescue NotImplementedError, NoMethodError, ArgumentError
  `whoami`.strip
end

# Return the effective user id

def host_uid
  Process.euid.to_s
rescue NotImplementedError, NoMethodError
  `id -u`.strip
end

# Return the uid of a named user, or an empty string if there is no such user

def host_user_id(name)
  Etc.getpwnam(name).uid.to_s
rescue ArgumentError
  ''
end

# Return the gid of a named group, or an empty string if there is no such group

def host_group_id(name)
  Etc.getgrnam(name).gid.to_s
rescue ArgumentError
  ''
end

# Return a getent style line for a group (name:x:gid:members), or an empty string

def host_group_line(name)
  group = Etc.getgrnam(name)
  "#{group.name}:x:#{group.gid}:#{group.mem.join(',')}"
rescue ArgumentError
  ''
end

# Return the number of processors

def host_cpu_count
  Etc.nprocessors.to_s
end

# Return total memory in whole gigabytes, read from /proc/meminfo, or an empty string where that file is absent

def host_memory_gb
  kb = File.read('/proc/meminfo')[/^MemTotal:\s+(\d+)/, 1]
  kb ? (kb.to_i / 1024 / 1024).to_s : ''
rescue Errno::ENOENT, Errno::EACCES
  ''
end

# Return the current time formatted as the date command would by default

def host_date(format = '%a %b %e %H:%M:%S %Z %Y')
  Time.now.strftime(format)
end

# Return the full path of a program found on PATH, or an empty string if it is not installed

def which_program(name)
  ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).each do |dir|
    path = File.join(dir, name)
    return path if File.file?(path) && File.executable?(path)
  end
  ''
end
