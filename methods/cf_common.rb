
# Cloud Formation common code

# Initiate Cloud Formation Stack

def initiate_aws_cf_client(options)
  cf = Aws::CloudFormation::Client.new(
    :region             =>  options['region'], 
    :access_key_id      =>  options['access'],
    :secret_access_key  =>  options['secret']
  )
  return cf
end 

# Get list of AWS CF stacks

def get_aws_cf_stacks(options)
  cf = initiate_aws_cf_client(options['access'],options['secret'],options['region'])
  begin
    stacks = cf.describe_stacks.stacks 
  rescue Aws::CloudFormation::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit(options)
  end
  return stacks
end

# Check if AWS CF Stack exists

def check_if_aws_cf_stack_exists(options)
  exists = "no"
  stacks = get_aws_cf_stacks(options)
  stacks.each do |stack|
    stack_name  = stack.stack_name
    if stack_name.match(/#{options['name']}/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

