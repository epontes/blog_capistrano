require "bunlder/capistrano"

server "162.243.198.14",:web ,:app , :db, primary: true



set :application, "blog"
set :user, "deployer"
set :deploy_to , "/home/#{user}/apps/#{application}"
set :deploy_via , :remote_cache
set :use_sudo , false

# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :scm, "git"
set :repository,  "https://github.com/epontes/blog_capistrano.git"
set :branch, "master"

default_run_options[:pity]  = true
ssh_options[:forward_agent] = true

after "deploy" , "deploy:cleanup" #keep only the last  5 releases

namespace :deploy do
   %w[start stop restart].each do |command|
     desc "#{command} unicorn server"
     taks command , roles: :app , except: {no_release: true} do
       run "/etc/init.d/unicorn_#{application} #{command}"
     end
   end
   
   task :setup_config, roles: :app do
     sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
     sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
     run "mkdir -p #{shared_path}/confg"
     put File.read("config/database.example.yml"), "#{shared_path}/config/database.yml"
     puts "Now edit the config files in #{shared_path}." 
   end
   after "deploy:setup" ,"deploy:setup_config"
   
   task :symlink_config , roles: :app do
     run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yaml"
   end
   after "deploy:finalize_update", "deploy:symlink_config"
   
   desc "Make sure local git is in sync with remote."
   
   task :check_revision, roles: :app do
     unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
     end
   end
   before "deploy" , "deploy:check_revision"
end
  
   
# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end