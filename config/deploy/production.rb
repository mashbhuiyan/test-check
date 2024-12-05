set :nvm_node, 'v17.9.1'
set :deploy_user, 'ec2-user'
set :deploy_to, '/home/ec2-user/apps/client_api/'
# set :branch, 'IIA-334'
set :branch, 'main'

role :app, %w{ec2-user@54.243.152.229 ec2-user@23.23.240.130}

server '54.243.152.229', user: 'ec2-user', roles: %w{web app}, my_property: :my_value
server '23.23.240.130', user: 'ec2-user', roles: %w{web app}, my_property: :my_value

namespace :deploy do
  desc "Installing npm..."
  task :install_npm do
    on roles(:app) do
      execute "cd '#{release_path}' && source ~/.nvm/nvm.sh && rm -fr node_modules && npm install"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # execute "cd #{current_path} && source ~/.nvm/nvm.sh && pm2 start server.js --name production"
      execute "cd #{current_path} && source ~/.nvm/nvm.sh && pm2 stop production && pm2 delete production && pm2 start server.js --name production -i max"
      # execute "cd #{current_path} && source ~/.nvm/nvm.sh && pm2 startOrGracefulReload pm2_production.config.js -i max"
    end
  end

  before :publishing, 'deploy:install_npm'
  after :publishing, 'deploy:restart'
end
