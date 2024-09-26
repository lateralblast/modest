# LDom related questions

# Control domain questions

def populate_cdom_questions(values)
  ld = Struct.new(:question, :ask, :value, :valid, :eval)

  if values['host-os-unamea'].match(/T5[0-9]|T3/)

    name   = "cdom_mau"
    config = ld.new(
      question  = "Control Domain Cryptographic Units",
      ask       = "yes",
      value     = values['mau'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "cdom_vcpu"
  config = ld.new(
    question  = "Control Domain Virtual CPUs",
    ask       = "yes",
    value     = values['vcpus'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "cdom_memory"
  config = ld.new(
    question  = "Control Domain Memory",
    ask       = "yes",
    value     = values['vcpus'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "cdom_name"
  config = ld.new(
    question  = "Control Domain Configuration Name",
    ask       = "yes",
    value     = values['name'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return values
end

# Guest domain questions

def populate_gdom_questions(values)
  gdom_dir    = $ldom_base_dir+"/"+values['name']
  client_disk = gdom_dir+"/vdisk0"

  if values['host-os-unamea'].match(/T5[0-9]|T3/)

    name   = "gdom_mau"
    config = ld.new(
      question  = "Domain Cryptographic Units",
      ask       = "yes",
      value     = values['mau'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "gdom_vcpu"
  config = ld.new(
    question  = "Guest Domain Virtual CPUs",
    ask       = "yes",
    value     = values['vcpus'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "gdom_memory"
  config = ld.new(
    question  = "Guest Domain Memory",
    ask       = "yes",
    value     = values['memory'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "gdom_disk"
  config = ld.new(
    question  = "Guest Domain Disk",
    ask       = "yes",
    value     = client_disk,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "gdom_size"
  config = ld.new(
    question  = "Guest Domain Disk Size",
    ask       = "yes",
    value     = values['size'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return values
end
