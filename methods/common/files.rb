# frozen_string_literal: true

# File operations and simple reads done in Ruby rather than by running a shell command.
# Anything the router does not fully understand, including expansion, globbing, chown, cd,
# sudo-wrapped commands, and operations the current user cannot perform, still runs in the shell.

require 'fileutils'
require 'find'
require 'shellwords'

# Split a command into words, returning nil unless the command is exactly what
# Shellwords.join would produce for those words (so no shell syntax is present)

def simple_file_command(command)
  words = Shellwords.split(command)
  return nil if words.empty? || Shellwords.join(words) != command

  words
rescue ArgumentError
  nil
end

# Perform a single simple file command in Ruby. Returns the output (empty for writes), or nil
# when the command is not one of the handled shapes or needs privileges the shell path can provide.

def run_simple_file_command(words)
  verb, *args = words
  flag = %w[-f -p -s].include?(args.first) ? args.shift : nil

  case verb
  when 'cp'
    return nil unless args.size == 2 && flag.nil?

    FileUtils.cp(args[0], args[1])
  when 'rm'
    return nil unless args.size == 1 && (flag.nil? || flag == '-f')

    FileUtils.rm_f(args[0])
  when 'mkdir'
    return nil unless args.size == 1

    flag == '-p' ? FileUtils.mkdir_p(args[0]) : Dir.mkdir(args[0])
  when 'touch'
    return nil unless args.size == 1 && flag.nil?

    FileUtils.touch(args[0])
  when 'rmdir'
    return nil unless args.size == 1 && flag.nil?

    Dir.rmdir(args[0])
  when 'chmod'
    return nil unless args.size == 2 && flag.nil? && args[0].match?(/\A[0-7]{3,4}\z/)

    File.chmod(args[0].to_i(8), args[1])
  when 'ln'
    return nil unless args.size == 2 && flag == '-s'

    File.symlink(args[0], args[1])
  when 'cat'
    return nil unless args.size == 1 && flag.nil?

    return File.read(args[0])
  else
    return nil
  end
  ''
rescue Errno::EACCES, Errno::EPERM
  nil
rescue SystemCallError => e
  # Report the error as the shell command would, then return no output
  $stderr.puts "#{verb}: #{e.message}"
  ''
end

# Parse one segment without a pipe into a file operation, or nil if it is not supported

def parse_file_segment(words)
  redirect = nil
  target = nil
  if (index = words.index { |word| word == '>' || word == '>>' })
    return nil unless index == words.size - 2

    redirect = words[index]
    target = words[index + 1]
    words = words[0...index]
  end
  verb, *args = words
  append = redirect == '>>'

  if redirect
    case verb
    when 'cat'
      return nil unless args.size == 1

      { type: :copy_content, src: args[0], dst: target, append: append }
    when 'echo'
      return nil unless args.size == 1 && !args[0].start_with?('-') && !args[0].include?('\\')

      { type: :echo, text: args[0], dst: target, append: append }
    end
  else
    flag = %w[-f -p -s].include?(args.first) ? args.shift : nil
    case verb
    when 'cp'
      return nil unless args.size == 2 && flag.nil?

      { type: :copy, src: args[0], dst: args[1] }
    when 'rm'
      return nil unless args.size == 1 && (flag.nil? || flag == '-f')

      { type: :remove, path: args[0] }
    when 'mkdir'
      return nil unless args.size == 1 && (flag.nil? || flag == '-p')

      { type: :mkdir, path: args[0], parents: flag == '-p' }
    when 'touch'
      return nil unless args.size == 1 && flag.nil?

      { type: :touch, path: args[0] }
    when 'rmdir'
      return nil unless args.size == 1 && flag.nil?

      { type: :rmdir, path: args[0] }
    when 'chmod'
      return nil unless args.size == 2 && flag.nil?
      return { type: :chmod, path: args[1], mode: args[0].to_i(8) } if args[0].match?(/\A[0-7]{3,4}\z/)
      return { type: :chmod_execute, path: args[1] } if args[0] == '+x'

      nil
    when 'ln'
      return nil unless args.size == 2 && flag == '-s'

      { type: :symlink, target: args[0], link: args[1] }
    when 'cd'
      return nil unless args.size == 1 && flag.nil?

      { type: :cd, dir: args[0] }
    when 'chown', 'chgrp'
      recursive = args.first == '-R'
      args.shift if recursive
      return nil unless args.size == 2 && flag.nil?

      if verb == 'chgrp'
        return nil unless args[0].match?(/\A\d+\z/)

        { type: :chgrp, path: args[1], gid: args[0].to_i, recursive: recursive }
      else
        # Owner, owner:group or :group, all numeric; a trailing colon is not supported
        return nil unless args[0].match?(/\A\d+(:\d+)?\z|\A:\d+\z/)

        uid, gid = args[0].split(':', -1)
        { type: :chown, path: args[1], uid: uid.to_s.empty? ? nil : uid.to_i,
          gid: gid.to_s.empty? ? nil : gid.to_i, recursive: recursive }
      end
    end
  end
end

# Parse one stage of a read pipeline into an operation, or nil if it is not supported.
# Stages: grep [-v] [-i] PATTERN, head -N, tail -N, awk '{print $N}', cut -fN -dX

def parse_read_stage(words)
  verb, *args = words
  case verb
  when 'grep'
    invert = false
    ignore_case = false
    while args.first&.match?(/\A-[vi]+\z/)
      flags = args.shift
      invert ||= flags.include?('v')
      ignore_case ||= flags.include?('i')
    end
    return nil unless args.size == 1

    pattern = args.first
    anchored_start = pattern.start_with?('^')
    anchored_end = pattern.end_with?('$')
    body = pattern[(anchored_start ? 1 : 0)...(anchored_end ? -1 : pattern.length)].to_s
    return nil unless body.match?(/\A[A-Za-z0-9 _\/:=,#.-]*\z/)

    source = "#{'^' if anchored_start}#{body}#{'$' if anchored_end}"
    { type: :grep, regexp: Regexp.new(source, ignore_case ? Regexp::IGNORECASE : nil), invert: invert }
  when 'head', 'tail'
    return nil unless args.size == 1 && args.first.match?(/\A-\d+\z/)

    { type: verb.to_sym, count: args.first[1..].to_i }
  when 'awk'
    return nil unless args.size == 1 && args.first.match?(/\A\{print \$([1-9]\d*)\}\z/)

    { type: :field, index: args.first[/\d+/].to_i }
  when 'cut'
    field = args.find { |arg| arg.match?(/\A-f[1-9]\d*\z/) }
    delimiter = args.find { |arg| arg.match?(/\A-d.\z/) }
    return nil unless field && delimiter && args.size == 2

    { type: :cut, index: field[2..].to_i, delimiter: delimiter[2] }
  end
end

# Parse a read pipeline segment (cat FILE | stage | ...), optionally ending in > FILE or >> FILE

def parse_read_segment(text)
  return nil unless text.count('|') == text.scan(/\|/).size
  return nil if text.match?(/[\n]/)

  normalised = text.gsub(/\s*\|\s*/) { ' | ' }
  words = Shellwords.split(normalised)
  return nil unless words.count('|') == text.count('|')
  return nil if words.any? { |word| word != '|' && word.include?('|') }
  return nil if words.any? { |word| word.start_with?('#') }
  return nil unless words.all? { |word| word == '|' || word.match?(/\A\{print \$\d+\}\z/) || !word.delete_suffix('$').match?(/[$`*?\[\]{}~]/) }

  output = nil
  if words.size >= 2 && (words[-2] == '>' || words[-2] == '>>')
    output = { dst: words[-1], append: words[-2] == '>>' }
    words = words[0...-2]
  end

  segments = [[]]
  words.each { |word| word == '|' ? segments << [] : segments.last << word }
  return nil if segments.any?(&:empty?)
  return nil unless segments.first.size == 2 && segments.first.first == 'cat' && !segments.first.last.start_with?('-')

  stages = segments.drop(1).map { |segment| parse_read_stage(segment) }
  return nil if stages.any?(&:nil?)

  { type: :read, file: segments.first.last, stages: stages, output: output }
rescue ArgumentError
  nil
end

# Parse a whole command made of segments joined by ' ; ' into operations, or nil if any part is unsupported.
# Each segment is a read pipeline or a single file operation.

def parse_file_pipeline(command)
  return nil if command.match?(/[`()<&\n]/)
  # An unescaped $ is expanded by the shell unless it closes a single-quoted word
  return nil if command.match?(/(?<!\\)\$(?!')/)
  return nil unless command.scan(';').size == command.scan(' ; ').size
  return nil unless command.scan(/>+/).size == command.scan(/ >>? /).size
  return nil if command.match?(/['"][;>]|[;>]['"]/)

  segments = command.split(' ; ', -1)
  return nil if segments.any? { |segment| segment.strip.empty? }

  operations = segments.map do |segment|
    if segment.include?('|')
      parse_read_segment(segment)
    else
      words = Shellwords.split(segment)
      # Globs, brace and tilde expansion are left to the shell
      next nil if words.empty? || words.any? { |word| word.match?(/[*?\[\]{}~]/) }

      parse_file_segment(words)
    end
  end
  operations.any?(nil) ? nil : operations
rescue ArgumentError
  nil
end

# Return true if a path can be written: the file itself if it exists, otherwise its directory

def writable_target?(path)
  File.exist?(path) ? File.writable?(path) : File.writable?(File.dirname(path))
end

# Return true if the current user can perform an operation without privilege escalation

def file_operation_permitted?(operation)
  case operation[:type]
  when :read
    readable = !File.exist?(operation[:file]) || File.readable?(operation[:file])
    readable && (operation[:output].nil? || writable_target?(operation[:output][:dst]))
  when :copy then writable_target?(operation[:dst])
  when :copy_content, :echo then writable_target?(operation[:dst])
  when :remove then !File.exist?(operation[:path]) || writable_target?(File.dirname(operation[:path]))
  when :rmdir, :mkdir then writable_target?(File.dirname(operation[:path]))
  when :touch then writable_target?(operation[:path])
  when :symlink then writable_target?(operation[:link])
  when :chmod, :chmod_execute
    File.exist?(operation[:path]) && (File.owned?(operation[:path]) || Process.euid.zero?)
  when :chown, :chgrp
    # Ownership changes are left to the shell path (and its sudo wrapper) unless running as root
    Process.euid.zero? && File.exist?(operation[:path]) && !(operation[:recursive] && File.symlink?(operation[:path]))
  when :cd then true
  else
    false
  end
end

# Apply the stages to the lines of the file

def run_read_stages(lines, stages)
  stages.reduce(lines) do |current, stage|
    case stage[:type]
    when :grep
      current.select { |line| stage[:regexp].match?(line) != stage[:invert] }
    when :head then current.first(stage[:count])
    when :tail then current.last(stage[:count])
    when :field then current.map { |line| line.split[stage[:index] - 1].to_s }
    when :cut
      current.map do |line|
        line.include?(stage[:delimiter]) ? line.split(stage[:delimiter], -1)[stage[:index] - 1].to_s : line
      end
    end
  end
end

# Return the text a read operation produces, one line per output line

def read_operation_text(operation)
  lines = File.readlines(operation[:file], chomp: true)
  run_read_stages(lines, operation[:stages]).map { |line| "#{line}\n" }.join
end

# Carry out one read operation, either returning its text or writing it to the redirect target.
# The redirect target is opened before the file is read, as the shell does.

def run_read_operation(operation)
  output = operation[:output]
  if output
    File.open(output[:dst], output[:append] ? 'a' : 'w') { |out| out.write(read_operation_text(operation)) }
    ''
  else
    read_operation_text(operation)
  end
rescue SystemCallError => e
  $stderr.puts "cat: #{e.message}"
  ''
end

# Carry out one file operation. Errors are reported as the shell would report them, and processing continues

def run_file_operation(operation)
  case operation[:type]
  when :copy then FileUtils.cp(operation[:src], operation[:dst])
  when :copy_content
    File.open(operation[:dst], operation[:append] ? 'a' : 'w') { |out| out.write(File.read(operation[:src])) }
  when :echo then File.write(operation[:dst], "#{operation[:text]}\n", mode: operation[:append] ? 'a' : 'w')
  when :remove then FileUtils.rm_f(operation[:path])
  when :rmdir then Dir.rmdir(operation[:path])
  when :mkdir then operation[:parents] ? FileUtils.mkdir_p(operation[:path]) : Dir.mkdir(operation[:path])
  when :touch then FileUtils.touch(operation[:path])
  when :chmod then File.chmod(operation[:mode], operation[:path])
  when :chmod_execute
    File.chmod((File.stat(operation[:path]).mode | 0o111) & 0o7777, operation[:path])
  when :symlink then File.symlink(operation[:target], operation[:link])
  when :chown, :chgrp then change_ownership(operation)
  end
  ''
rescue SystemCallError => e
  $stderr.puts "#{operation[:type]}: #{e.message}"
  ''
end

# Change owner and/or group of a path, recursively without following symbolic links when asked

def change_ownership(operation)
  uid = operation[:type] == :chown ? operation[:uid] : nil
  gid = operation[:gid]
  if operation[:recursive]
    Find.find(operation[:path]) { |entry| File.lchown(uid, gid, entry) }
  else
    File.chown(uid, gid, operation[:path])
  end
end

# Resolve relative paths against the directory of the most recent cd, as the shell does for its own directory.
# Returns the planned operations, or nil if a cd cannot be planned (the shell then runs the whole command).

PATH_FIELDS = {
  read: %i[file], copy: %i[src dst], copy_content: %i[src dst], echo: %i[dst],
  remove: %i[path], rmdir: %i[path], mkdir: %i[path], touch: %i[path], chmod: %i[path],
  chmod_execute: %i[path], chown: %i[path], chgrp: %i[path], symlink: %i[link]
}.freeze

def plan_file_operations(operations)
  base = nil
  operations.map do |operation|
    if operation[:type] == :cd
      dir = base ? File.expand_path(operation[:dir], base) : operation[:dir]
      return nil unless File.directory?(dir) && File.readable?(dir)

      base = dir
      next operation.merge(dir: dir)
    end

    planned = operation.dup
    (PATH_FIELDS[operation[:type]] || []).each do |field|
      planned[field] = File.expand_path(operation[field], base) if base
    end
    planned[:output] = planned[:output].merge(dst: File.expand_path(planned[:output][:dst], base)) if base && planned[:output]
    planned
  end
end

# Return the output of a command, doing file operations and simple reads in Ruby where possible.
# Anything the router does not fully handle is run by the shell unchanged.

def file_command_output(command)
  words = simple_file_command(command)
  result = run_simple_file_command(words) if words
  return result unless result.nil?

  operations = parse_file_pipeline(command)
  planned = plan_file_operations(operations) if operations
  if planned && planned.all? { |operation| file_operation_permitted?(operation) }
    return planned.map { |operation| operation[:type] == :read ? run_read_operation(operation) : run_file_operation(operation) }.join
  end

  `#{command}`
end
