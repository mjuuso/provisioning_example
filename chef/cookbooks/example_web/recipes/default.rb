# First, we need to update our package list
execute 'apt-get-update' do
  command 'apt-get -y update'
end

# Install the latest nginx version
apt_package 'nginx'

# Build nginx configuration from a template, passing
# $APP_NODES to it
template '/etc/nginx/sites-available/default' do
  source 'nginx-site.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    :app_nodes => ENV['APP_NODES']
  })
end

# Finally, restart nginx
service 'nginx' do
  action :restart
end