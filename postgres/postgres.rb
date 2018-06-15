require 'rake'
require 'rake/task'
require 'rake/tasklib'
require 'docker_task'

class DevkitTask::Postgres < Rake::TaskLib
  POSTGRES_EXPOSED_PORT = 5432
  POSTGRES_EXPOSED_VOLUME = '/var/lib/postgresql/data'

  DEFAULT_OPTIONS = {
    :namespace => :postgres
  }

  def self.config
    config = Devkit.config['postgres']
  end

  def config; self.class.config; end

  def self.configure
    docker_opts = Devkit::Helper.symbolize_keys(config['docker'])

    docker_opts[:run] = lambda do |task, opts|
      run_opts = config['docker_run']

      envs = { }
      root_password = nil

      unless run_opts.nil? || run_opts.empty?
        var_path = Devkit.config.finalize_paths(run_opts['var'])
        opts << '-v %s:%s' % [ var_path, POSTGRES_EXPOSED_VOLUME ]

        opts.concat(DockerTask::Helper.format_port_maps(POSTGRES_EXPOSED_PORT, run_opts))

        root_password = run_opts['root_password']
      end

      if root_password.nil? || root_password.empty?
        envs['POSTGRES_PASSWORD'] = ''
      else
        envs['POSTGRES_PASSWORD'] = root_password
      end

      opts.concat(DockerTask::Helper.format_env_params(envs))

      unless run_opts['opts'].nil? || run_opts['opts'].empty?
        opts << nil
        opts << run_opts['opts']
      end

      opts
    end

    docker_opts
  end

  def initialize(options = { })
    options = DockerTask::Helper.symbolize_keys(options)
    @options = DEFAULT_OPTIONS.merge(options)

    yield(self) if block_given?
  end

  def define!
    define_docker_task!

    namespace @options[:namespace] do
      desc 'Perform initial preparation'
      task :prepare do
        run_opts = config['docker_run']
        var_path = Devkit.config.finalize_paths(run_opts['var'])

        sh 'mkdir -p %s' % var_path
      end
    end
  end

  def define_docker_task!
    docker_opts = self.class.configure
    docker_opts[:namespace] = '%s:docker' % @options[:namespace]

    Devkit.include_docker_tasks(docker_opts)
  end
end
