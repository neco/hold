default_run_options[:pty] = true

set :application, 'hold'

set :scm, :git
set :repository, 'git@github.com:neco/hold.git'
set :branch, :master

set :deploy_to, lambda { "/var/www/#{application}" }
set :keep_releases, 5
set :user, 'deploy'

role :web, 'slice.neco.com'
role :app, 'slice.neco.com'
role :db, 'slice.neco.com', :primary => true

namespace :deploy do
  task :start do
  end

  task :stop do
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end

  task :after_update_code do
    %w{config/db.sqlite3}.each do |file|
      run "ln -nfs #{shared_path}/#{file} #{release_path}/#{file}"
    end

    gems.bundle
  end
end

namespace :gems do
  task :bundle, :roles => :app do
    run "cd #{release_path} ; gem bundle --only production"
  end
end
