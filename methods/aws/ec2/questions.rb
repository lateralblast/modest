# Questions for AWS EC2 creation

# Populate AWS questions

def populate_aws_questions(values, user_data_file)
  # values['answers'] = {}
  # values['order']  = []

  if values['type'].to_s.match(/packer|ansible/)

    name   = "name"
    config = Ks.new(
      type      = "",
      question  = "AMI Name",
      ask       = "no",
      parameter = "",
      value     = "aws",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)
  
    name   = "access_key"
    config = Ks.new(
      type      = "",
      question  = "Access Key",
      ask       = "yes",
      parameter = "",
      value     = values['access'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    if values['unmasked'] == true

      name   = "secret_key"
      config = Ks.new(
        type      = "",
        question  = "Secret Key",
        ask       = "yes",
        parameter = "",
        value     = values['secret'],
        valid     = "",
        eval      = "no"
      )
      values['answers'][name] = config
      values['order'].push(name)

      name   = "keyfile"
      config = Ks.new(
        type      = "",
        question  = "AWS Key file",
        ask       = "yes",
        parameter = "",
        value     = values['keyfile'],
        valid     = "",
        eval      = "no"
      )
      values['answers'][name] = config
      values['order'].push(name)

    else

      name   = "secret_key"
      config = Ks.new(
        type      = "",
        question  = "Secret Key",
        ask       = "no",
        parameter = "",
        value     = values['secret'],
        valid     = "",
        eval      = "no"
      )
      values['answers'][name] = config
      values['order'].push(name)

      name   = "keyfile"
      config = Ks.new(
        type      = "",
        question  = "AWS Key file",
        ask       = "no",
        parameter = "",
        value     = values['keyfile'],
        valid     = "",
        eval      = "no"
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

    name   = "type"
    config = Ks.new(
      type      = "",
      question  = "AWS Type",
      ask       = "yes",
      parameter = "",
      value     = values['type'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "region"
    config = Ks.new(
      type      = "",
      question  = "Region",
      ask       = "yes",
      parameter = "",
      value     = values['region'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name) 

    name   = "ssh_username"
    config = Ks.new(
      type      = "",
      question  = "SSH Username",
      ask       = "yes",
      parameter = "",
      value     = values['adminuser'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "ami_name"
    config = Ks.new(
      type      = "",
      question  = "AMI Name",
      ask       = "yes",
      parameter = "",
      value     = values['name'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  if values['type'].to_s.match(/packer/)

    name   = "user_data_file"
    config = Ks.new(
      type      = "",
      question  = "User Data File",
      ask       = "yes",
      parameter = "",
      value     = user_data_file,
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)
    
  else

    name   = "min_count"
    config = Ks.new(
      type      = "",
      question  = "Minimum Instances",
      ask       = "yes",
      parameter = "",
      value     = values['number'].split(/,/)[0],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)  

    name   = "max_count"
    config = Ks.new(
      type      = "",
      question  = "Maximum Instances",
      ask       = "yes",
      parameter = "",
      value     = values['number'].split(/,/)[1],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)  

    name   = "key_name"
    config = Ks.new(
      type      = "",
      question  = "Key Name",
      ask       = "yes",
      parameter = "",
      value     = values['key'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)  

    name   = "security_group"
    config = Ks.new(
      type      = "",
      question  = "Security Groups",
      ask       = "yes",
      parameter = "",
      value     = values['group'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name) 

    name   = "dry_run"
    config = Ks.new(
      type      = "",
      question  = "Dry run",
      ask       = "yes",
      parameter = "",
      value     = values['dryrun'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)  

  end

  name   = "source_ami"
  config = Ks.new(
    type      = "",
    question  = "Source AMI",
    ask       = "yes",
    parameter = "",
    value     = values['ami'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "instance_type"
  config = Ks.new(
    type      = "",
    question  = "Instance Type",
    ask       = "yes",
    parameter = "",
    value     = values['size'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "open_ports"
  config = Ks.new(
    type      = "",
    question  = "Open ports",
    ask       = "yes",
    parameter = "",
    value     = values['ports'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "default_cidr"
  config = Ks.new(
    type      = "",
    question  = "Default CIDR",
    ask       = "yes",
    parameter = "",
    value     = values['cidr'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return
end

