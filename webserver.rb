#!/usr/bin/env ruby
# frozen_string_literal: true

# Name:         mode (Multi OS Deployment Engine) webserver
# Version:      0.0.5
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
  `gem install #{gem_name}`
  Gem.clear_paths
  nil
end

begin
  require 'sinatra'
rescue LoadError
  install_gem('sinatra')
end
begin
  require 'sinatra/formkeeper'
rescue LoadError
  install_gem('sinatra-formkeeper')
end
begin
  require 'fileutils'
rescue LoadError
  install_gem('fileutils')
end
begin
  require 'hex_string'
rescue LoadError
  install_gem('hex_string')
end
begin
  require 'unpack'
rescue LoadError
  install_gem('unpack')
end
begin
  require 'enumerate'
rescue LoadError
  install_gem('enumerate')
end
begin
  require 'iconv'
rescue LoadError
  install_gem('iconv')
end
begin
  require 'bcrypt'
rescue LoadError
  install_gem('bcrypt')
end
begin
  require 'fileutils'
rescue LoadError
  install_gem('fileutils')
end
begin
  require 'parseconfig'
rescue LoadError
  install_gem('parseconfig')
end

# Some webserver defaults

default_bind       = '127.0.0.1'
default_exceptions = false
default_port       = '9495'
default_sessions   = 'true'
default_errors     = 'false'
enable_ssl         = true
enable_auth        = false
ssl_dir            = "#{Dir.pwd}/ssl"
ssl_certificate    = "#{ssl_dir}/cert.crt"
ssl_key            = "#{ssl_dir}/pkey.pem"
Dir.pwd

# Only allow uploads if we has authentication

false unless enable_auth == true

set :port,            default_port
set :bind,            default_bind
set :sessions,        default_sessions
set :dump_errors,     default_errors
set :show_exceptions, default_exceptions

# Load methods

if Dir.exist?('./methods')
  file_list = Dir.entries('./methods')
  file_list.each do |file|
    require "./methods/#{file}" if file =~ /rb$/
  end
end

# SSL config

if enable_ssl == true
  require 'webrick/ssl'
  require 'webrick/https'
  unless File.directory?(ssl_dir)
    puts "Information: Creating #{ssl_dir}"
    Dir.mkdir(ssl_dir)
  end
  `openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout #{ssl_key} -out #{ssl_certificate}` if !File.exist?(ssl_certificate) || !File.exist?(ssl_key)
  set :ssl_certificate, ssl_certificate
  set :ssl_key, ssl_key
  module Sinatra
    class Application
      def self.run!
        certificate_content = File.open(ssl_certificate).read
        key_content = File.open(ssl_key).read

        server_values = {
          Host: bind,
          Port: port,
          SSLEnable: true,
          SSLCertificate: OpenSSL::X509::Certificate.new(certificate_content),
          SSLPrivateKey: OpenSSL::PKey::RSA.new(key_content, ssl_password)
        }

        Rack::Handler::WEBrick.run self, server_values do |server|
          %i[INT TERM].each { |sig| trap(sig) { server.stop } }
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
          return if authorized?

          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, 'Not authorized\n'])
        end

        def authorized?
          @auth ||= Rack::Auth::Basic::Request.new(request.env)
          passwd = File.open(htpasswd_file).read.split("\n").map { |credential| credential.split(':') }
          return unless @auth.provided? && @auth.basic? && @auth.credentials

          user, = @auth.credentials
          auth = passwd.assoc(user)
          crypt = BCrypt::Password.create(auth[1])
          return false unless auth

          auth == [user, crypt]
        end
      end
    end
  end
end

# Set global variables
# Set defaults
# Unlike the reporting script, these currently don't get auto detected

set_global_vars

before do
  set_global_vars
  check_local_config('client')
  values['verbose'] = 0
  values['output']  = 'html'
  values['stdout']  = []
end

# handle error - redirect to help

error do
  head  = File.readlines('./views/layout.html')
  body  = File.readlines('./views/help.html')
  array = head + body
  array = array.join("\n")
  array.to_s
end

# handle 404

not_found do
  head  = File.readlines('./views/layout.html')
  body  = File.readlines('./views/help.html')
  array = head + body
  array = array.join("\n")
  array.to_s
end

# handle help

get '/help' do
  head  = File.readlines('./views/layout.html')
  body  = File.readlines('./views/help.html')
  array = head + body
  array = array.join("\n")
  array.to_s
end

# handle version

get '/version' do
  foot  = []
  head  = File.readlines('./views/layout.html')
  head  = html_header(head, 'Mode')
  body  = print_version
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  array.to_s
end

# handle /list

get '/list/*/*' do
  foot = []
  (values['type'], values['search']) = params[:splat]
  head = File.readlines('./views/layout.html')
  head = html_header(head, 'Mode')
  case values['type']
  when /packer/
    list_packer_clients(values['search'])
  when /service/
    eval "[list_#{values['search']}_services()]"
  when /iso/
    if values['search'].to_s.match(/[a-z]/)
      eval "[list_#{values['search']}_isos()]"
    else
      list_os_isos(values['search'])
    end
  else
    list_vms(values)
  end
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  array.to_s
end

get '/list/*' do
  foot = []
  values['type']   = params[:splat][0]
  values['search'] = ''
  head = File.readlines('./views/layout.html')
  head = html_header(head, 'Mode')
  case values['type']
  when /packer/
    list_packer_clients(values)
  when /service/
    list_all_services(values)
  else
    list_vms(values)
  end
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  array.to_s
end

get '/show/*/*' do
  foot = []
  head = File.readlines('./views/layout.html')
  head = html_header(head, 'Mode')
  (values['vm'], values['name']) = params[:splat]
  values['method']  = ''
  values['type']    = ''
  values['service'] = ''
  get_client_config(values)
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  array.to_s
end

get '/add/client' do
  foot = []
  head = File.readlines('./views/layout.html')
  head = html_header(head, 'Mode')
  # values['order']  = []
  # values['answers'] = {}
  values['name'] = (params['client'] || '')
  values['ip'] = (params['ip'] || '')
  if params['method']
    values['method'] = params['method']
  else
    redirect '/help'
  end
  if params['service']
    values['service'] = params['service']
  else
    redirect '/list/services'
  end
  eval "[populate_#{values['method']}_questions(values['service'],values['name'],values['ip'])]"
  values['stdout'].push('<form action="/add/client" method="post">')
  values['order'].each do |key|
    values['stdout'].push(values['answers'][key].question)
    values['stdout'].push("<input type=\"text\" name = \"#{key}\">")
  end
  values['stdout'].push('<input type="submit" value="Submit">')
  values['stdout'].push('</form>')
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  array.to_s
end

get '/add/fusion' do
  foot = []
  head = File.readlines('./views/layout.html')
  head = html_header(head, 'Mode')
  # values['order']  = []
  # values['answers'] = {}
  values['name'] = (params['client'] || '')
  values['ip'] = (params['ip'] || '')
  values['stdout'] = []
  values['stdout'].push('<form action="/add/client" method="post">')
  values['stdout'].push('Client Name:')
  values['stdout'].push("<input type=\"text\" name = \"values['name']\" value=\"#{values['name']}\">")
  values['stdout'].push('<input type="submit" value="Submit">')
  values['stdout'].push('</form>')
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  array.to_s
end

post '/add/fusion' do
  create_vm(values)
end

# handle /

get '/' do
  foot = []
  head = File.readlines('./views/layout.html')
  head = html_header(head, 'Mode')
  redirect '/help' if params['help']
  redirect '/version' if params['version']
  values['name'] = (params['client'] || '')
  if params['action']
    values['action'] = params['action']
  else
    redirect '/help'
  end
  values['vm'] = (params['vm'] || '')
  values['method'] = (params['method'] || '')
  values['os-type'] = (params['os'] || '')
  values['type'] = (params['type'] || '')
  case values['action']
  when /help/
    redirect '/help'
  when /display|view|show|prop/
    if values['name'].to_s.match(/[a-z,A-Z]/)
      if values['vm'].to_s.match(/[a-z]/) && (values['vm'] != values['empty'])
        eval "[show_#{values['vm']}_vm_config(values)]"
      else
        get_client_config(values)
      end
    else
      verbose_message(values, "Warning:\tClient name not specified")
    end
  when /list/
    if values['type'].to_s.match(/[a-z]/)
      if values['type'].to_s.match(/iso/)
        if values['method'].to_s.match(/[a-z]/)
          eval "[list_#{values['method']}_isos]"
        else
          list_os_isos(values)
        end
      end
      list_packer_clients(values) if values['type'].to_s.match(/packer/)
    elsif values['vm'].to_s.match(/[a-z]/)
      list_vms(values)
    end
  end
  body  = values['stdout']
  foot  = html_footer(foot)
  array = head + body + foot
  array = array.join("\n")
  array.to_s
end
