#
# Source:
#   https://hub.docker.com/_/nginx/
#

require 'rake'
require 'rake/task'
require 'rake/tasklib'
require 'docker_task'

class DevkitTask::Nginx < Rake::TaskLib
  include Devkit::Task

  set_namespace :nginx
  set_exposed_port 80
  set_exposed_volume '/nginx'

  EXPOSED_NGINX_CONF = '/etc/nginx/nginx.conf'
  EXPOSED_NGINX_VHOSTS = '/vhosts'

  TEMPLATE_NGINX_CONF = File.join(DEVKIT_ROOT_PATH, 'nginx/nginx.conf')
  TEMPLATE_SITE_NGINX_CONF = File.join(DEVKIT_ROOT_PATH, 'nginx/site.nginx.conf')

  def self.docker_run(task, opts)
    vhosts_path = File.join(var_path, 'vhosts')

    foreach_vhost(vhosts_path) do |vhost_name, original_path, vhost_link|
      opts = configure_volume_opts(original_path, opts, File.join(EXPOSED_NGINX_VHOSTS, vhost_name))
    end

    opts = configure_volume_opts(TEMPLATE_NGINX_CONF, opts, EXPOSED_NGINX_CONF)

    super(task, opts)
  end

  def perform_prepare
    super

    confd_path = File.join(var_path, 'conf.d')
    sh 'mkdir -p %s' % confd_path

    vhosts_path = File.join(var_path, 'vhosts')
    sh 'mkdir -p %s' % vhosts_path

    nginx_conf = File.join(var_path, File.basename(TEMPLATE_NGINX_CONF))
    sh 'cp %s %s' % [ TEMPLATE_NGINX_CONF, nginx_conf ]

    self.class.foreach_vhost(vhosts_path) do |vhost_name, original_path, vhost_link|
      conf_opts = {
        vhost_path: File.join(EXPOSED_NGINX_VHOSTS, vhost_name),
        server_name: vhost_name,
        original_path: original_path
      }

      devkit_nginx_conf = File.join(original_path, '.devkit.nginx.yml')
      if File.exists?(devkit_nginx_conf)
        conf_opts.merge! Devkit::Helper.symbolize_keys(YAML.load(File.read(devkit_nginx_conf)))
      end

      if conf_opts[:custom_nginx_conf_path].nil?
        custom_nginx_conf = File.join(original_path, '.nginx.conf')
        if File.exists?(custom_nginx_conf)
          conf_opts[:custom_nginx_conf_path] = '.nginx.conf'
        end
      end

      conf_bind = SiteNginxConfBind.new(conf_opts)

      vhost_conf = File.join(confd_path, '%s.conf' % vhost_name)
      File.open(vhost_conf, 'w') { |f| f.write(conf_bind.parse) }
      puts 'Written %s' % vhost_conf
    end

    self
  end

  class SiteNginxConfBind
    attr_reader :opts

    DEFAULT_OPTS = {
      server_name: 'localhost',
      use_fpm: false,
      use_fpm_devkit: false,
      fpm_port: 9000,
      fpm_host: 'host.docker.internal',
      original_path: nil,
      custom_nginx_conf_path: nil
    }

    def initialize(opts = { })
      @opts = DEFAULT_OPTS.merge(opts)
    end

    def server_name
      @opts[:server_name]
    end

    def use_fpm
      @opts[:use_fpm]
    end

    def use_fpm_devkit
      @opts[:use_fpm_devkit]
    end

    def fpm_remote_path
      '%s:%s' % [ @opts[:fpm_host], @opts[:fpm_port] ]
    end

    def vhost_path
      @opts[:vhost_path]
    end

    def original_document_root
      @opts[:original_path]
    end

    def has_custom_nginx_conf?
      !@opts[:custom_nginx_conf_path].nil? && !@opts[:custom_nginx_conf_path].empty?
    end

    def custom_nginx_conf_path
      File.join(vhost_path, @opts[:custom_nginx_conf_path])
    end

    def parse
      ERB.new(File.read(TEMPLATE_SITE_NGINX_CONF), nil, '-').result(binding)
    end
  end
end
