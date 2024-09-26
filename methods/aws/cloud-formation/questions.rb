# AWS CloudFormation questions

# Populate AWS CF questions

def populate_aws_cf_questions(values)
  # values['answers'] = {}
  # values['order']  = []

  name   = "stack_name"
  config = Ks.new(
    type      = "",
    question  = "Stack Name",
    ask       = "yes",
    parameter = "",
    value     = values['name'],
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

  name   = "ssh_location"
  config = Ks.new(
    type      = "",
    question  = "SSH Location",
    ask       = "yes",
    parameter = "",
    value     = values['cidr'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "template_url"
  config = Ks.new(
    type      = "",
    question  = "Template Location",
    ask       = "yes",
    parameter = "",
    value     = values['file'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "security_groups"
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

  return
end