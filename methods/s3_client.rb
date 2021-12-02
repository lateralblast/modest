# S3 related code

# Create AWS S3 bucket

def create_aws_s3_bucket(options)
  s3 = initiate_aws_s3_resource(options)
  if s3.bucket(options['bucket']).exists?
    handle_output(options,"Information:\tBucket: #{options['bucket']} already exists")
    s3 = initiate_aws_s3_client(options['access'],options['secret'],options['region'])
    begin
      s3.head_bucket({ bucket: options['bucket'], })
    rescue
      handle_output(options,"Warning:\tDo not have permissions to access bucket: #{options['bucket']}")
      quit(options)
    end
  else
    handle_output(options,"Information:\tCreating S3 bucket: #{options['bucket']}")
    s3.create_bucket({ acl: options['acl'], bucket: options['bucket'], create_bucket_configuration: { location_constraint: options['region'], }, })
  end
  return s3
end

# Get AWS S3 bucket ACL

def get_aws_s3_bucket_acl(options)
  s3  = initiate_aws_s3_client(options)
  begin
    acl = s3.get_bucket_acl(bucket: options['bucket'])
  rescue Aws::S3::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit(options)
  end
  return acl
end

# Show AWS S3 bucket ACL

def show_aws_s3_bucket_acl(options)
  acl    = get_aws_s3_bucket_acl(options)
  owner  = acl.owner.display_name
  handle_output(options,"#{options['bucket']}\towner=#{owner}")
  acl.grants.each_with_index do |grantee,counter|
    owner = grantee[0].display_name
    email = grantee[0].email_address
    id    = grantee[0].id
    type  = grantee[0].type
    uri   = grantee[0].uri
    perms = grantee.permission
    handle_output(options,"grants[#{counter}]\towner=#{owner}\temail=#{email}\ttype=#{type}\turi=#{uri}\tid=#{id}\tperms=#{perms}")
  end
  return
end

# Set AWS S3 bucket ACL

def set_aws_s3_bucket_acl(options)
  s3 = initiate_aws_s3_resource(options)
  return
end

# Upload file to S3 bucker

def upload_file_to_aws_bucket(options)
  if options['file'].to_s.match(/^http/)
    download_file = "/tmp/"+File.basename(options['file'])
    download_http = open(options['file'])
    IO.copy_stream(download_http,download_file)
    options['file'] = download_file
  end
  if not File.exist?(options['file'])
    handle_output(options,"Warning:\tFile '#{options['file']}' does not exist")
    quit(options)
  end
  if not options['bucket'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output(options,"Warning:\tNo Bucket name given")
    options['bucket'] =  options['bucket']
    handle_output(options,"Information:\tSetting Bucket to default bucket '#{options['bucket']}'")
  end
  exists = check_if_aws_bucket_exists(options['access'],options['secret'],options['region'],options['bucket'])
  if exists == false
     s3 = create_aws_s3_bucket(options['access'],options['secret'],options['region'],options['bucket'])
  end
  if not options['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    options['key'] = options['object']+"/"+File.basename(options['file'])
  end
  s3 = initiate_aws_s3_resource(options['access'],options['secret'],options['region'])
  handle_output(options,"Information:\tUploading: File '#{options['file']}' with key: '#{options['key']}' to bucket: '#{options['bucket']}'")
  s3.bucket(options['bucket']).object(options['key']).upload_file(options['file'])
  return
end

# Download file from S3 bucket

def download_file_from_aws_bucket(options)
  if not options['bucket'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output(options,"Warning:\tNo Bucket name given")
    options['bucket'] =  options['bucket']
    handle_output(options,"Information:\tSetting Bucket to default bucket '#{options['bucket']}'")
  end
  if not options['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    options['key'] = options['object']+"/"+File.basename(options['file'])
  end
  if options['file'].to_s.match(/\//)
    dir_name = Pathname.new(options['file'])
    dir_name = dir_name.dirname
    if not File.directory?(dir_name) and not File.symlink?(dir_name)
      FileUtils.mkdir_p(dir_name)
    end
  end
  s3 = initiate_aws_s3_client(options)
  handle_output(options,"Information:\tDownloading: Key '#{options['key']}' from bucket: '#{options['bucket']}' to file: '#{options['file']}'")
  s3.get_object({ bucket: options['bucket'], key: options['key'], }, target: options['file'] )
  return
end

# Get buckets

def get_aws_buckets(options)
  s3 = initiate_aws_s3_client(options)
  begin
    buckets = s3.list_buckets.buckets
  rescue Aws::S3::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit(options)
  end
  return buckets
end

# Check if AWS bucket exists

def check_if_aws_bucket_exists(options)
  exists  = false
  buckets = get_aws_buckets(options)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if bucket_name.match(/#{options['bucket']}/)
      exists = true
      return exists
    end
  end
  return exists
end
