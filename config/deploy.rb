require 'capistrano/nvm'

lock '3.16.0'

set :application, 'client_api'
set :scm, :git
set :repo_url, 'git@github.com:nazrulcse/client_api.git'
set :nvm_type, :user
set :nvm_map_bins, %w{node npm yarn}

set :node_env, (fetch(:node_env) || fetch(:stage))

# Default value for default_env is {}
set :default_env, { node_env: fetch(:node_env) }
set :rvm_ruby, '3.1.0'

set :linked_files, %w{.env app/config/db_brands.json}
# set :linked_dirs, %w{public}

set :keep_releases, 4
