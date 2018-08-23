require 'docker_task'

module Devkit
  module Task
    module ClassMethods
      def set_config_name(name)
        @config_name = name
      end

      def set_namespace(ns)
        @namespace = ns
        set_config_name(ns)
      end

      def get_namespace
        @namespace
      end

      def set_default_options(opts = { })
        @default_options ||= { }
        @default_options.merge!(opts)
        @default_options
      end

      def default_options
        @default_options ||= { }
      end

      def config
        config = Devkit.config[@config_name]
      end

      def var_path
        var_path = Devkit.config.finalize_paths(docker_run_config[:var])
      end

      def docker_run_config
        Devkit::Helper.symbolize_keys(config[:docker_run])
      end

      def docker_config
        Devkit::Helper.symbolize_keys(config[:docker])
      end

      def create!(opts = { }, &block)
        new(opts, &block).define!
      end
    end

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def get_namespace; self.class.get_namespace; end

    attr_reader :docker_config
    attr_reader :docker_run_config

    def initialize(options = { })
      options = DockerTask::Helper.symbolize_keys(options)
      @options = self.class.default_options.merge(options)

      @docker_config = (@options[:docker] || { }).merge(self.class.docker_config)
      @docker_run_config = (@options[:docker_run] || { }).merge(self.class.docker_run_config)

      yield(self) if block_given?

      finalize_paths!

      @docker_exec = nil
      docker_exec

      @docker_run = nil
      docker_run
    end

    def finalize_paths!
      unless @docker_run_config[:var].nil?
        @docker_run_config[:var] = Devkit.config.finalize_paths(@docker_run_config[:var])
      end

      @docker_run_config
    end

    def var_path;
      @docker_run_config[:var]
    end

    def docker_exec
      if @docker_exec.nil?
        @docker_exec = DockerTask::DockerExec.new(@docker_config)
      else
        @docker_exec
      end
    end

    def docker_run
      if @docker_run.nil?
        @docker_run = DockerTask::Run.new(docker_exec, @docker_run_config)
        docker_exec.set_run(@docker_run)

        @docker_run.set_configure_run_opts(&method(:configure_run_opts))

        unless @options[:exposed_volume].nil?
          @docker_run.set_exposed_volume(@options[:exposed_volume])
        end

        unless @options[:exposed_port].nil?
          @docker_run.set_exposed_port(@options[:exposed_port])
        end

        unless @options[:envs].nil? || @options[:envs].empty?
          @docker_run.envs.update!(@options[:envs])
        end

        @docker_run
      else
        @docker_run
      end
    end

    def configure_run_opts(drun, run_opts)
      drun.configure_run_opts(run_opts)
    end

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
      task_opts = { }
      task_opts[:docker_exec] = docker_exec
      task_opts[:namespace] = '%s:docker' % get_namespace

      DockerTask.include_tasks(task_opts)
    end
  end
end
