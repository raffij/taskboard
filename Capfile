# Configuration

set :application, "taskboard"
set :use_mysql, true

ssh_options[:keys] = File.expand_path('~/keys/mbm-keypair')

default_run_options[:pty] = true
set :deploy_via, :remote_cache
set :repository,  "git@github.com:maccman/taskboard.git"
set :scm, "git"
set :branch, "master"

role :app, "taskboard.mxmdev.com"
role :web, "taskboard.mxmdev.com"
role :db,  "taskboard.mxmdev.com", :primary => true

load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'