#
# Source:
#  https://hub.docker.com/_/nginx/
#

require 'rake'
require 'rake/task'
require 'rake/tasklib'
require 'docker_task'

class DevkitTask::Nginx < Rake::TaskLib
  include Devkit::Task

  set_config_name :nginx
  set_namespace :nginx

  EXPOSED_PORT = 80
  EXPOSED_VOLUME = '/nginx'

  EXPOSED_NGINX_CONF = '/etc/nginx/nginx.conf'
  EXPOSED_NGINX_VHOSTS = '/nginx/vhosts'

  TEMPLATE_NGINX_CONF = File.expand_path('../nginx.conf', __FILE__)
  TEMPLATE_SITE_NGINX_CONF = File.expand_path('../site.nginx.conf', __FILE__)

  def self.configure
    docker_opts = Devkit::Helper.symbolize_keys(config['docker'])

    docker_opts[:run] = lambda do |task, opts|
      run_opts = config['docker_run']
      envs = { }

      vpath = var_path
      vhosts_path = File.join(var_path, 'vhosts')

      foreach_vhost(vhosts_path) do |vhost_name, original_path, vhost_link|
        opts = configure_volume_opts(original_path, opts, File.join(EXPOSED_NGINX_VHOSTS, vhost_name))
      end

      opts = configure_volume_opts(TEMPLATE_NGINX_CONF, opts, EXPOSED_NGINX_CONF)
      opts = configure_volume_opts(run_opts, opts, EXPOSED_VOLUME)

      opts = configure_port_opts(run_opts, opts, EXPOSED_PORT)
      opts = configure_envs(run_opts, opts, envs)
      opts = configure_exec_opts(run_opts, opts)

      opts
    end

    docker_opts
  end

  def self.foreach_vhost(vhosts_path)
    Dir.glob('%s/*' % vhosts_path).each do |vhost_link|
      vhost_name = File.basename(vhost_link)

      if File.symlink?(vhost_link)
        original_path = File.readlink(vhost_link)
      else
        original_path = vhost_link
      end

      yield(vhost_name, original_path, vhost_link)
    end
  end

  def perform_prepare
    super

    vpath = var_path

    confd_path = File.join(var_path, 'conf.d')
    sh 'mkdir -p %s' % confd_path

    vhosts_path = File.join(var_path, 'vhosts')
    sh 'mkdir -p %s' % vhosts_path

    nginx_conf = File.join(vpath, File.basename(TEMPLATE_NGINX_CONF))
    sh 'cp %s %s' % [ TEMPLATE_NGINX_CONF, nginx_conf ]

    self.class.foreach_vhost(vhosts_path) do |vhost_name, original_path, vhost_link|
      conf_opts = {
        server_name: vhost_name,
        original_path: original_path
      }

      devkit_nginx_conf = File.join(original_path, '.devkit.nginx.yml')
      if File.exists?(devkit_nginx_conf)
        conf_opts.merge! Devkit::Helper.symbolize_keys(YAML.load(File.read(devkit_nginx_conf)))
      end

      conf_bind = SiteNginxConfBind.new(conf_opts)

      vhost_conf = File.join(confd_path, '%s.conf' % vhost_name)
      File.open(vhost_conf, 'w') { |f| f.write(conf_bind.parse) }
    end

    self
  end

  class SiteNginxConfBind
    attr_reader :opts

    DEFAULT_OPTS = {
      server_name: 'localhost',
      use_fpm: false,
      fpm_port: 9000,
      original_path: nil
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

    def fpm_remote_path
      'host.docker.internal:%s' % @opts[:fpm_port]
    end

    def original_document_root
      @opts[:original_path]
    end

    def parse
      ERB.new(File.read(TEMPLATE_SITE_NGINX_CONF), nil, '-').result(binding)
    end
  end
end
