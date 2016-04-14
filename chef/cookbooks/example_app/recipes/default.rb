# We'll run our app under a non-privileged user
user 'deploy' do
  comment 'Deploy user'
  home '/app'
  shell '/bin/bash'
  password ''
end

# Our app lives in /app
directory '/app' do
  owner 'deploy'
  group 'deploy'
  mode '0755'
  action :create
end

# Copy the pre-compiled application to the directory
cookbook_file '/app/app' do
  source 'app-linux-amd64'
  owner 'deploy'
  group 'deploy'
  mode '0755'
  action :create
end

# Copy the upstart job script
cookbook_file '/etc/init/app.conf' do
  source 'init-app.conf'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# Start the upstart job, ie. service
service 'app' do
  action :start
end