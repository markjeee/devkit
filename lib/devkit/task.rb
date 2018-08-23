require 'docker_task'

module Devkit
  module Task
    module ClassMethods
      def foreach_vhost(vhosts_path)
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

      def configure_volume_opts(run_opts, opts, exp_vol = nil)
        unless run_opts.nil? || run_opts.empty? || exp_vol.nil?

          if run_opts.is_a?(Hash) && !run_opts['var'].nil? && !run_opts['var'].empty?
            var_path = Devkit.config.finalize_paths(run_opts['var'])
            opts << '-v %s:%s' % [ var_path, exp_vol ]
          elsif run_opts.is_a?(String) && !run_opts.empty?
            var_path = Devkit.config.finalize_paths(run_opts)
            opts << '-v %s:%s' % [ var_path, exp_vol ]
          end
        end

        opts
      end

      def configure_port_opts(run_opts, opts, exp_port = nil)
        unless run_opts.nil? || run_opts.empty? || exp_port.nil?
          opts.concat(DockerTask::Helper.format_port_maps(exp_port, run_opts))
        end

        opts
      end

      def configure_envs(run_opts, opts, envs = nil)
        unless run_opts.nil? || run_opts.empty? || envs.nil?
          opts.concat(DockerTask::Helper.format_env_params(envs))
        end

        opts
      end

      def configure_exec_opts(run_opts, opts)
        unless run_opts.nil? || run_opts.empty?
          unless run_opts['opts'].nil? || run_opts['opts'].empty?
            opts << nil
            opts << run_opts['opts']
          end
        end

        opts
      end

      def set_config_name(name)
        @config_name = name
      end

      def set_namespace(ns)
        @namespace = ns
        set_config_name(ns)
      end

      def set_exposed_volume(vol)
        @exposed_volume = vol
      end

      def set_exposed_port(port)
        @exposed_port = port
      end

      def envs
        if defined?(@envs)
          @envs
        else
          @envs = { }
        end
      end

      def set_default_options(opts = { })
        @default_options ||= { }
        @default_options.merge!(opts)
        @default_options
      end

      def get_namespace
        @namespace
      end

      def config
        config = Devkit.config[@config_name]
      end

      def default_options
        @default_options ||= { }
      end

      def var_path
        var_path = Devkit.config.finalize_paths(docker_run_config['var'])
      end

      def docker_run_config
        Devkit::Helper.symbolize_keys(config['docker_run'])
      end

      def docker_config
        Devkit::Helper.symbolize_keys(config['docker'])
      end

      def configure
        docker_opts = docker_config
        docker_opts[:run] = self.method(:docker_run)
        docker_opts
      end

      def docker_run(task, opts)
        run_opts = docker_run_config

        if defined?(@exposed_volume) && !@exposed_volume.nil?
          opts = configure_volume_opts(run_opts, opts, @exposed_volume)
        end

        if defined?(@exposed_port) && !@exposed_port.nil?
          opts = configure_port_opts(run_opts, opts, @exposed_port)
        end

        if defined?(@envs) && !@envs.nil? && !@envs.empty?
          opts = configure_envs(run_opts, opts, @envs)
        end

        opts = configure_exec_opts(run_opts, opts)

        opts
      end

      def create!(opts = { }, &block)
        new(opts, &block).define!
      end
    end

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def get_namespace; self.class.get_namespace; end
    def config; self.class.config; end
    def var_path; self.class.var_path; end
    def docker_config; self.docker_config; end

    def initialize(options = { })
      options = DockerTask::Helper.symbolize_keys(options)
      @options = self.class.default_options.merge(options)

      yield(self) if block_given?
    end

    def define!
      define_docker_task!

      namespace get_namespace do
        desc 'Perform initial preparation'
        task :prepare do
          perform_prepare
        end
      end
    end

    def perform_prepare
      unless var_path.nil?
        sh 'mkdir -p %s' % var_path
      end

      self
    end

    def define_docker_task!
      docker_opts = self.class.configure
      docker_opts[:namespace] = '%s:docker' % get_namespace

      Devkit.include_docker_tasks(docker_opts)
    end
  end
end
