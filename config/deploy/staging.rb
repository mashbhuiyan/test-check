set :nvm_node, 'v17.9.1'
# set :deploy_user, 'ec2-user'
# set :deploy_to, '/home/ec2-user/apps/client_api_staging/'
set :deploy_user, 'ubuntu'
# set :deploy_to, '/home/mannan/apps/client_api_staging/'
set :deploy_to, '/home/ubuntu/apps/client_api/'
set :branch, 'staging'

# role :app, %w{ec2-user@54.243.152.229 ec2-user@34.224.81.91}
role :app, %w{ubuntu@3.139.94.143}

# server '54.243.152.229', user: 'ec2-user', roles: %w{web app}, my_property: :my_value
# server '34.224.81.91', user: 'ec2-user', roles: %w{web app}, my_property: :my_value
server '3.139.94.143', user: 'ubuntu', roles: %w{web app}, my_property: :my_value


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
      # execute "cd #{current_path} && source ~/.nvm/nvm.sh && pm2 start server.js --name staging"
      execute "cd #{current_path} && source ~/.nvm/nvm.sh && pm2 stop staging && pm2 delete staging && pm2 start server.js --name staging"
    end
  end

  before :publishing, 'deploy:install_npm'
  after :publishing, 'deploy:restart'
end