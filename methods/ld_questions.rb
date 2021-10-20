# LDom related questions

# Control domain questions

def populate_cdom_questions(options)
  ld = Struct.new(:question, :ask, :value, :valid, :eval)

  if options['host-os-uname'].match(/T5[0-9]|T3/)

    name = "cdom_mau"
    config = ld.new(
      question  = "Control Domain Cryptographic Units",
      ask       = "yes",
      value     = options['mau'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end

  name = "cdom_vcpu"
  config = ld.new(
    question  = "Control Domain Virtual CPUs",
    ask       = "yes",
    value     = options['vcpus'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "cdom_memory"
  config = ld.new(
    question  = "Control Domain Memory",
    ask       = "yes",
    value     = options['vcpus'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "cdom_name"
  config = ld.new(
    question  = "Control Domain Configuration Name",
    ask       = "yes",
    value     = options['name'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  return options
end

# Guest domain questions

def populate_gdom_questions(options)
  gdom_dir    = $ldom_base_dir+"/"+options['name']
  client_disk = gdom_dir+"/vdisk0"

  if options['host-os-uname'].match(/T5[0-9]|T3/)

    name = "gdom_mau"
    config = ld.new(
      question  = "Domain Cryptographic Units",
      ask       = "yes",
      value     = options['mau'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end

  name = "gdom_vcpu"
  config = ld.new(
    question  = "Guest Domain Virtual CPUs",
    ask       = "yes",
    value     = options['vcpus'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "gdom_memory"
  config = ld.new(
    question  = "Guest Domain Memory",
    ask       = "yes",
    value     = options['memory'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "gdom_disk"
  config = ld.new(
    question  = "Guest Domain Disk",
    ask       = "yes",
    value     = client_disk,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "gdom_size"
  config = ld.new(
    question  = "Guest Domain Disk Size",
    ask       = "yes",
    value     = options['size'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  return options
end
