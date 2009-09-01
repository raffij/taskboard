# Configuration

set :application, "taskboard2"
set :use_mysql, true

ssh_options[:keys] = File.expand_path('~/keys/mbm-keypair')
ssh_options[:forward_agent] = true

default_run_options[:pty] = true
set :deploy_via, :remote_cache
set :repository,  "git@github.com:madebymany/taskboard.git"
set :scm, "git"
set :branch, "master"

role :app, "taskboard.mxmdev.com"
role :web, "taskboard.mxmdev.com"
role :db,  "taskboard.mxmdev.com", :primary => true

load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'