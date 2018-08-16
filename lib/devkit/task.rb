module Devkit
  module Task
    module ClassMethods
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
        run_opts = config['docker_run']
        var_path = Devkit.config.finalize_paths(run_opts['var'])
      end
    end

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def get_namespace; self.class.get_namespace; end
    def config; self.class.config; end
    def var_path; self.class.var_path; end

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
      sh 'mkdir -p %s' % var_path
    end

    def define_docker_task!
      docker_opts = self.class.configure
      docker_opts[:namespace] = '%s:docker' % get_namespace

      Devkit.include_docker_tasks(docker_opts)
    end
  end
end
