#!/usr/bin/env ruby

# Name:         mode (Multi OS Deployment Engine) webserver
# Version:      0.0.4
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: UNIX
# Vendor:       Lateral Blast
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Ruby script for processing mode

# Load required gems

require 'rubygems'
require 'pathname'
require 'etc'
require 'date'

def install_gem(gem_name)
  puts "Information:\tInstalling #{gem_name}"
  %x[gem install #{gem_name}]
  Gem.clear_paths
  return
end

begin
  require 'sinatra'
rescue LoadError
  install_gem("sinatra")
end
begin
  require 'sinatra/formkeeper'
rescue LoadError
  install_gem("sinatra-formkeeper")
end
begin
  require 'fileutils'
rescue LoadError
  install_gem("fileutils")
end
begin
  require 'hex_string'
rescue LoadError
  install_gem("hex_string")
end
begin
  require 'unpack'
rescue LoadError
  install_gem("unpack")
end
begin
  require 'enumerate'
rescue LoadError
  install_gem("enumerate")
end
begin
  require 'iconv'
rescue LoadError
  install_gem("iconv")
end
begin
  require 'bcrypt'
rescue LoadError
  install_gem("bcrypt")
end
begin
  require 'fileutils'
rescue LoadError
  install_gem("fileutils")
end
begin
  require 'parseconfig'
rescue LoadError
  install_gem("parseconfig")
end

# Some webserver defaults

default_bind       = "127.0.0.1"
default_exceptions = false
default_port       = "9495"
default_sessions   = "true"
default_errors     = "false"
enable_ssl         = true
enable_auth        = false
enable_upload      = false
$ssl_dir           = Dir.pwd+"/ssl"
ssl_certificate    = $ssl_dir+"/cert.crt"
ssl_key            = $ssl_dir+"/pkey.pem"
$ssl_password      = "123456"
$htpasswd_file     = Dir.pwd+"/views/.htpasswd"

# Only allow uploads if we has authentication

if not enable_auth == true
  enable_upload = false
end

set :port,            default_port
set :bind,            default_bind
set :sessions,        default_sessions
set :dump_errors,     default_errors
set :show_exceptions, default_exceptions

# Load methods

if Dir.exist?("./methods")
  file_list = Dir.entries("./methods")
  for file in file_list
    if file =~ /rb$/
      require "./methods/#{file}"
    end
  end
end

# SSL config

if enable_ssl == true
  require 'webrick/ssl'
  require 'webrick/https'
  if not File.directory?($ssl_dir)
    puts "Information: Creating "+$ssl_dir
    Dir.mkdir($ssl_dir)
  end
  if not File.exist?(ssl_certificate) or not File.exist?(ssl_key)
    %x[openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout #{ssl_key} -out #{ssl_certificate}]
  end
  set :ssl_certificate, ssl_certificate
  set :ssl_key, ssl_key
  module Sinatra
    class Application
      def self.run!
        certificate_content = File.open(ssl_certificate).read
        key_content = File.open(ssl_key).read
  
        server_values = {
          :Host => bind,
          :Port => port,
          :SSLEnable => true,
          :SSLCertificate => OpenSSL::X509::Certificate.new(certificate_content),
          :SSLPrivateKey => OpenSSL::PKey::RSA.new(key_content,$ssl_password)
        }
  
        Rack::Handler::WEBrick.run self, server_values do |server|
          [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
          server.threaded = settings.threaded if server.respond_to? :threaded=
          set :running, true
        end
      end
    end
  end
end

# htpasswd authentication

if enable_auth == true
  module Sinatra
    class Application
    
      helpers do
        def protect!
          unless authorized?
            response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
            throw(:halt, [401, "Not authorized\n'])
          end
        end
  
        def authorized?
          @auth ||=  Rack::Auth::Basic::Request.new(request.env)
          passwd = File.open($htpasswd_file).read.split("\n").map {|credential| credential.split(':')}
          if @auth.provided? && @auth.basic? && @auth.credentials
            user, pass = @auth.credentials
            auth = passwd.assoc(user)
            crypt = BCrypt::Password.create(auth[1])
            return false unless auth
            [user, crypt] == auth
          end
        end
      end
    end
  end
end

# Set global variables
# Set defaults
# Unlike the reporting script, these currently don't get auto detected

set_global_vars()

before do
  set_global_vars()
  check_local_config("client")
  values['verbose']  = 0
  values['output'] = "html"
  values['stdout']   = []
end

# handle error - redirect to help

error do
  head  = []
  body  = []
  head  = File.readlines("./views/layout.html")
  body  = File.readlines("./views/help.html")
  array = head + body
  array = array.join("\n")
  "#{array}"
end

# handle 404

not_found do
  head  = []
  body  = []
  head  = File.readlines("./views/layout.html")
  body  = File.readlines("./views/help.html")
  array = head + body
  array = array.join("\n")
  "#{array}"
end

# handle help

get '/help' do
  head  = []
  body  = []
  head  = File.readlines("./views/layout.html")
  body  = File.readlines("./views/help.html")
  array = head + body
  array = array.join("\n")
  "#{array}"
end

# handle version

get '/version' do
  head  = []
  body  = []
  foot  = []
  head  = File.readlines("./views/layout.html")
  head  = html_header(head,"Mode")
  body  = print_version()
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  "#{array}"
end 

# handle /list

get '/list/*/*' do 
  head = []
  body = []
  foot = []
  ( values['type'], values['search'] ) = params[:splat]
  head = File.readlines("./views/layout.html")
  head = html_header(head,"Mode")
  case values['type']
  when /packer/
    list_packer_clients(values['search'])
  when /service/
    eval"[list_#{values['search']}_services()]"
  when /iso/
    if values['search'].to_s.match(/[a-z]/)
      eval"[list_#{values['search']}_isos()]"
    else
      list_os_isos(values['search'])
    end
  else
    list_vms(values['type'],values['search'])
  end
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  "#{array}"
end

get '/list/*' do
  head = []
  body = []
  foot = []
  values['type']   = params[:splat][0]
  values['search'] = ""
  head = File.readlines("./views/layout.html")
  head = html_header(head,"Mode")
  case values['type']
  when /packer/
    list_packer_clients(values['search']) 
  when /service/
    list_all_services()
  else
    list_vms(values['type'],values['search'])
  end
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  "#{array}"
end

get '/show/*/*' do
  head = []
  body = []
  foot = []
  head = File.readlines("./views/layout.html")
  head = html_header(head,"Mode")
  ( values['vm'], values['name'] ) = params[:splat]
  values['method']  = ""
  values['type']    = ""
  values['service'] = ""
  get_client_config(values['name'],values['service'],values['method'],values['type'],values['vm'])
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  "#{array}"
end

get '/add/client' do
  head = []
  body = []
  foot = []
  head = File.readlines("./views/layout.html")
  head = html_header(head,"Mode")
  # values['order']  = []
  # values['answers'] = {}
  if params['client']
    values['name'] = params['client'] 
  else
    values['name'] = ""
  end
  if params['ip']
    values['ip'] = params['ip']
  else
    values['ip'] = ""
  end
  if params['method']
    values['method'] = params['method']
  else
    redirect "/help"
  end
  if params['service']
    values['service'] = params['service']
  else
    redirect "/list/services"
  end
  eval"[populate_#{values['method']}_questions(values['service'],values['name'],values['ip'])]"
  values['stdout'].push("<form action=\"/add/client\" method=\"post\">")
  values['order'].each do |key|
    values['stdout'].push(values['answers'][key].question)
    values['stdout'].push("<input type=\"text\" name = \"#{key}\">")
  end
  values['stdout'].push("<input type=\"submit\" value=\"Submit\">")
  values['stdout'].push("</form>")
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  "#{array}"
end

get '/add/fusion' do
  head = []
  body = []
  foot = []
  head = File.readlines("./views/layout.html")
  head = html_header(head,"Mode")
  # values['order']  = []
  # values['answers'] = {}
  if params['client']
    values['name'] = params['client'] 
  else
    values['name'] = ""
  end
  if params['ip']
    values['ip'] = params['ip']
  else
    values['ip'] = ""
  end
  values['stdout'] = []
  values['stdout'].push("<form action=\"/add/client\" method=\"post\">")
  values['stdout'].push("Client Name:")
  values['stdout'].push("<input type=\"text\" name = \"values['name']\" value=\"#{values['name']}\">")
  values['stdout'].push("<input type=\"submit\" value=\"Submit\">")
  values['stdout'].push("</form>")
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  "#{array}"
end

post '/add/fusion' do
  create_vm(values['method'],values['vm'],values['name'],values['mac'],values['os-type'],values['arch'],values['release'],values['size'],values['file'],values['memory'],values['vcpus'],values['vmnetwork'],values['share'],values['mount'],values['ip'])
end  

# handle /

get '/' do
  head = []
  body = []
  foot = []
  head = File.readlines("./views/layout.html")
  head = html_header(head,"Mode")
  if params['help']
    redirect "/help"
  end
  if params['version']
    redirect "/version"
  end
  if params['client']
    values['name'] = params['client']
  else
    values['name'] = ""
  end
  if params['action']
    values['action'] = params['action']
  else
    redirect "/help"
  end
  if params['vm']
    values['vm'] = params['vm']
  else
    values['vm'] = ""
  end
  if params['method']
    values['method'] = params['method']
  else
    values['method'] = ""
  end
  if params['os']
    values['os-type'] = params['os']
  else
    values['os-type'] = ""
  end
  if params['type']
    values['type'] = params['type']
  else
    values['type'] = ""
  end
  case values['action']
  when /help/
    redirect "/help"
  when /display|view|show|prop/
    if values['name'].to_s.match(/[a-z,A-Z]/)
      if values['vm'].to_s.match(/[a-z]/) and not values['vm'] == values['empty']
        eval"[show_#{values['vm']}_vm_config(values)]"
      else
        get_client_config(values['name'],values['service'],values['method'],values['type'])
      end
    else
      verbose_message(values,"Warning:\tClient name not specified")
    end
  when /list/
    if values['type'].to_s.match(/[a-z]/)
      if values['type'].to_s.match(/iso/)
        if values['method'].to_s.match(/[a-z]/)
          eval"[list_#{values['method']}_isos]"
        else
          list_os_isos(values['os-type'])
        end
      end
      if values['type'].to_s.match(/packer/)
        list_packer_clients(values['vm'])
      end
    else
      if values['vm'].to_s.match(/[a-z]/)
        list_vms(values['vm'],values['os-type'])
      end
    end
  end
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  "#{array}"
end