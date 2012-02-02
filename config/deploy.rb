def prompt_with_default(var, default)
  set(var, Proc.new {
      trx = Capistrano::CLI.ui.ask "#{var} [#{default}] : "
      trx.empty? ? default : trx
  })
end

set :use_sudo, false
set :stage, "production"
set :rails_env, stage

set :deploy_to, "/mnt/apps/#{application}"
set :user, "deploy"

namespace :deploy do
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
  
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

namespace :passenger do
  task :config do
    run "rm -f /etc/apache2/sites-available/#{application} /etc/apache2/sites-enabled/#{application}"
    put %{
      <VirtualHost *>
          ServerName #{find_servers(:roles => :app)}
          
          DocumentRoot #{current_path}/public
          <Directory #{current_path}/public>
            Options FollowSymLinks
            AllowOverride All
            Order allow,deny
            Allow from all
          </Directory>

          RewriteEngine on

          # Prevent access to .svn directories
          RewriteRule ^(.*/)?\.svn/ - [F,L]
          ErrorDocument 403 "Access Forbidden"

          # Check for maintenance file and redirect all requests
          RewriteCond %{DOCUMENT_ROOT}/system/maintenance.html -f
          RewriteCond %{SCRIPT_FILENAME} !maintenance.html
          RewriteRule ^.*$ /system/maintenance.html [L]

          # Deflate
          AddOutputFilterByType DEFLATE text/html text/plain text/xml
          BrowserMatch ^Mozilla/4 gzip-only-text/html
          BrowserMatch ^Mozilla/4\.0[678] no-gzip
          BrowserMatch \bMSIE !no-gzip !gzip-only-text/html

          ErrorLog  #{current_path}/log/apache_error.log
          CustomLog #{current_path}/log/apache_access.log common
      </VirtualHost>
    }, "/etc/apache2/sites-available/#{application}"
    run "ln -s /etc/apache2/sites-available/#{application} /etc/apache2/sites-enabled/#{application}"
    puts "/etc/init.d/apache2 restart"
  end
end

set :db_host, 'localhost'
prompt_with_default :db_name, "#{application}_#{stage}"
prompt_with_default :db_user, "#{application}_user"
set :db_pass, Proc.new { 
  pass1 = Capistrano::CLI.password_prompt('DB password?') 
  pass2 = Capistrano::CLI.password_prompt('Confirm password (leave blank to not confirm)?') 
  if pass2 && pass2 != ''
    raise 'Wrong password' unless pass1 == pass2
  end
  pass1
}
set :db_root_pass, Proc.new { Capistrano::CLI.password_prompt('Enter the mysql root password') }

desc "Executes a rake task on app"
task :rake, :roles => :app do 
  run("cd #{current_path} && RAILS_ENV=#{stage} rake #{Capistrano::CLI.ui.ask('Enter the rake task')}")
end

desc "Show current rev"
task :rev, :roles => :app do
  puts current_revision
end

task(:env) { run "env" }

after 'deploy:update_code', 'db:symlink'
namespace :db do
  task :default, :roles => :app do
    db.generate_config
    db.symlink
  end
  
  desc 'Generate the initial database.yml file'
  task :generate_config, :roles => :app do
    config = {}
    if use_mysql
      config['password']  = db_pass
      config['host']      = db_host
      config['adapter']   = 'mysql'
      config['username']  = db_user
      config['database']  = db_name
    else
      config['adapter']   = 'sqlite3'
      config['dbfile']    = "#{shared_path}/#{stage}.db"
      config['timeout']   = 5000
    end
    run "rm -f #{shared_path}/database.yml"
    put ({stage.to_s => config}.to_yaml), "#{shared_path}/database.yml"
  end 
  
  desc "Load db"
  task :schema_load, :roles => :app do
    run("cd #{latest_release} && RAILS_ENV=#{stage} rake db:schema:load")
  end
  
  desc 'Symlink database.yml'
  task :symlink, :roles => :app do
    run("rm -f #{latest_release}/config/database.yml")
    run("ln -s #{shared_path}/database.yml #{latest_release}/config/database.yml")
  end
end

set :log_name, Proc.new {
  default = 'production.log'
  trx = Capistrano::CLI.ui.ask "Log name [#{default}] : "
  res = trx.empty? ? default : trx
  res += '.log' if File.extname(res).empty?
  res
}

namespace :log do
  task :tail, :roles => :app do
    stream "tail -f -n 100 #{shared_path}/log/#{log_name}"
  end
  
  namespace :truncate do
    task :default, :roles => :app do
      run "echo > #{shared_path}/log/#{log_name}"
    end
    
    task :all, :roles => :app do
      capture("ls -x #{shared_path}/log/*.log").split.sort.each do |path|
        run "echo > #{path}" rescue nil
      end
    end
  end
end

desc "Run console remotely" 
task :console, :roles => :app do
  input = ''
  run "cd #{current_path} && ./script/console #{stage}" do |channel, stream, data|
    next if data.chomp == input.chomp || data.chomp == ''
    print data
    channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
  end
end

namespace :web do
  task :disable, :roles => :web, :except => { :no_release => true } do
    require 'erb'
    on_rollback { run "rm #{current_path}/public/system/maintenance.html" }

    name = application
    notice = Capistrano::CLI.ui.ask('Notice:')
    sub_notice = Capistrano::CLI.ui.ask('Sub notice:')

    template = File.read(File.join(File.dirname(__FILE__), 'maintenance.html.erb'))
    result = ERB.new(template).result(binding)

    put result, "#{current_path}/public/system/maintenance.html", :mode => 0644
  end
  
  task :enable, :roles => :web, :except => { :no_release => true } do
    run "rm #{current_path}/public/system/maintenance.html"
  end
end