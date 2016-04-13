execute 'apt-get-update' do
  command 'apt-get -y update'
end

apt_package 'nginx'

template '/etc/nginx/sites-available/default' do
  source 'nginx-site.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    :app_nodes => ENV['APP_NODES']
  })
end

service 'nginx' do
  action :restart
end