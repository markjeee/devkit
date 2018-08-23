#
# Source:
#   https://hub.docker.com/_/postgres/
#

require 'rake'
require 'rake/task'
require 'rake/tasklib'
require 'docker_task'

class DevkitTask::Postgres < Rake::TaskLib
  include Devkit::Task

  set_namespace :postgres
  set_default_options :exposed_port => 5432,
                      :exposed_volume => '/var/lib/postgresql/data'

  def configure_run_opts(drun, run_opts)
    run_config = docker_run_config

    if run_config['root_password'].nil? || run_config['root_password'].empty?
      drun.envs['POSTGRES_PASSWORD'] = ''
    else
      drun.envs['POSTGRES_PASSWORD'] = run_config['root_password']
    end

    super(drun, run_opts)
  end
end
