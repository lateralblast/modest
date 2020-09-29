# AWS CloudFormation questions

# Populate AWS CF questions

def populate_aws_cf_questions(options)
  # $q_struct = {}
  # $q_order  = []

  name   = "stack_name"
  config = Ks.new(
    type      = "",
    question  = "Stack Name",
    ask       = "yes",
    parameter = "",
    value     = options['name'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "instance_type"
  config = Ks.new(
    type      = "",
    question  = "Instance Type",
    ask       = "yes",
    parameter = "",
    value     = options['size'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "key_name"
  config = Ks.new(
    type      = "",
    question  = "Key Name",
    ask       = "yes",
    parameter = "",
    value     = options['key'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "ssh_location"
  config = Ks.new(
    type      = "",
    question  = "SSH Location",
    ask       = "yes",
    parameter = "",
    value     = options['cidr'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "template_url"
  config = Ks.new(
    type      = "",
    question  = "Template Location",
    ask       = "yes",
    parameter = "",
    value     = options['file'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "security_groups"
  config = Ks.new(
    type      = "",
    question  = "Security Groups",
    ask       = "yes",
    parameter = "",
    value     = options['group'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  return
end