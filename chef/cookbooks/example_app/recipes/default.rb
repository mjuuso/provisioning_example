group 'deploy' do
  action :create
  gid 1101
end

user 'deploy' do
  comment 'Deploy user'
  uid 1101
  gid 1101
  home '/app'
  shell '/bin/bash'
  password ''
end

directory '/app' do
  owner 'deploy'
  group 'deploy'
  mode '0755'
  action :create
end

cookbook_file '/app/app' do
  source 'app-linux-amd64'
  owner 'deploy'
  group 'deploy'
  mode '0755'
  action :create
end

cookbook_file '/etc/init/app.conf' do
  source 'init-app.conf'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

service "app" do
  action :start
end