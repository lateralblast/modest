# S3 related code

# Create AWS S3 bucket

def create_aws_s3_bucket(values)
  s3 = initiate_aws_s3_resource(values)
  if s3.bucket(values['bucket']).exists?
    verbose_output(values, "Information:\tBucket: #{values['bucket']} already exists")
    s3 = initiate_aws_s3_client(values['access'], values['secret'], values['region'])
    begin
      s3.head_bucket({ bucket: values['bucket'], })
    rescue
      verbose_output(values, "Warning:\tDo not have permissions to access bucket: #{values['bucket']}")
      quit(values)
    end
  else
    verbose_output(values, "Information:\tCreating S3 bucket: #{values['bucket']}")
    s3.create_bucket({ acl: values['acl'], bucket: values['bucket'], create_bucket_configuration: { location_constraint: values['region'], }, })
  end
  return s3
end

# Get AWS S3 bucket ACL

def get_aws_s3_bucket_acl(values)
  s3  = initiate_aws_s3_client(values)
  begin
    acl = s3.get_bucket_acl(bucket: values['bucket'])
  rescue Aws::S3::Errors::AccessDenied
    verbose_output(values, "Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit(values)
  end
  return acl
end

# Show AWS S3 bucket ACL

def show_aws_s3_bucket_acl(values)
  acl    = get_aws_s3_bucket_acl(values)
  owner  = acl.owner.display_name
  verbose_output(values, "#{values['bucket']}\towner=#{owner}")
  acl.grants.each_with_index do |grantee, counter|
    owner = grantee[0].display_name
    email = grantee[0].email_address
    id    = grantee[0].id
    type  = grantee[0].type
    uri   = grantee[0].uri
    perms = grantee.permission
    verbose_output(values, "grants[#{counter}]\towner=#{owner}\temail=#{email}\ttype=#{type}\turi=#{uri}\tid=#{id}\tperms=#{perms}")
  end
  return
end

# Set AWS S3 bucket ACL

def set_aws_s3_bucket_acl(values)
  s3 = initiate_aws_s3_resource(values)
  return
end

# Upload file to S3 bucker

def upload_file_to_aws_bucket(values)
  if values['file'].to_s.match(/^http/)
    download_file = "/tmp/"+File.basename(values['file'])
    download_http = open(values['file'])
    IO.copy_stream(download_http, download_file)
    values['file'] = download_file
  end
  if not File.exist?(values['file'])
    verbose_output(values, "Warning:\tFile '#{values['file']}' does not exist")
    quit(values)
  end
  if not values['bucket'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    verbose_output(values, "Warning:\tNo Bucket name given")
    values['bucket'] =  values['bucket']
    verbose_output(values, "Information:\tSetting Bucket to default bucket '#{values['bucket']}'")
  end
  exists = check_if_aws_bucket_exists(values['access'], values['secret'], values['region'], values['bucket'])
  if exists == false
     s3 = create_aws_s3_bucket(values['access'], values['secret'], values['region'], values['bucket'])
  end
  if not values['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    values['key'] = values['object']+"/"+File.basename(values['file'])
  end
  s3 = initiate_aws_s3_resource(values['access'], values['secret'], values['region'])
  verbose_output(values, "Information:\tUploading: File '#{values['file']}' with key: '#{values['key']}' to bucket: '#{values['bucket']}'")
  s3.bucket(values['bucket']).object(values['key']).upload_file(values['file'])
  return
end

# Download file from S3 bucket

def download_file_from_aws_bucket(values)
  if not values['bucket'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    verbose_output(values, "Warning:\tNo Bucket name given")
    values['bucket'] =  values['bucket']
    verbose_output(values, "Information:\tSetting Bucket to default bucket '#{values['bucket']}'")
  end
  if not values['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    values['key'] = values['object']+"/"+File.basename(values['file'])
  end
  if values['file'].to_s.match(/\//)
    dir_name = Pathname.new(values['file'])
    dir_name = dir_name.dirname
    if not File.directory?(dir_name) and not File.symlink?(dir_name)
      FileUtils.mkdir_p(dir_name)
    end
  end
  s3 = initiate_aws_s3_client(values)
  verbose_output(values, "Information:\tDownloading: Key '#{values['key']}' from bucket: '#{values['bucket']}' to file: '#{values['file']}'")
  s3.get_object({ bucket: values['bucket'], key: values['key'], }, target: values['file'] )
  return
end

# Get buckets

def get_aws_buckets(values)
  s3 = initiate_aws_s3_client(values)
  begin
    buckets = s3.list_buckets.buckets
  rescue Aws::S3::Errors::AccessDenied
    verbose_output(values, "Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit(values)
  end
  return buckets
end

# Check if AWS bucket exists

def check_if_aws_bucket_exists(values)
  exists  = false
  buckets = get_aws_buckets(values)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if bucket_name.match(/#{values['bucket']}/)
      exists = true
      return exists
    end
  end
  return exists
end
