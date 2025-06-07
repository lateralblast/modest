# frozen_string_literal: true

# LDom related questions

# Control domain questions

def populate_cdom_questions(values)
  ld = Struct.new(:question, :ask, :value, :valid, :eval)

  if values['host-os-unamea'].match(/T5[0-9]|T3/)

    name   = 'cdom_mau'
    config = ld.new(
      'Control Domain Cryptographic Units',
      'yes',
      values['mau'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'cdom_vcpu'
  config = ld.new(
    'Control Domain Virtual CPUs',
    'yes',
    values['vcpus'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'cdom_memory'
  config = ld.new(
    'Control Domain Memory',
    'yes',
    values['vcpus'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'cdom_name'
  config = ld.new(
    'Control Domain Configuration Name',
    'yes',
    values['name'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values
end

# Guest domain questions

def populate_gdom_questions(values)
  gdom_dir    = "#{$ldom_base_dir}/#{values['name']}"
  client_disk = "#{gdom_dir}/vdisk0"

  if values['host-os-unamea'].match(/T5[0-9]|T3/)

    name   = 'gdom_mau'
    config = ld.new(
      'Domain Cryptographic Units',
      'yes',
      values['mau'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'gdom_vcpu'
  config = ld.new(
    'Guest Domain Virtual CPUs',
    'yes',
    values['vcpus'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'gdom_memory'
  config = ld.new(
    'Guest Domain Memory',
    'yes',
    values['memory'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'gdom_disk'
  config = ld.new(
    'Guest Domain Disk',
    'yes',
    client_disk,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'gdom_size'
  config = ld.new(
    'Guest Domain Disk Size',
    'yes',
    values['size'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values
end
