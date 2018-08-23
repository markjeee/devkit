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
  set_exposed_port 5432
  set_exposed_volume '/var/lib/postgresql/data'

  def self.docker_run(task, opts)
    run_opts = docker_run_config

    if run_opts['root_password'].nil? || run_opts['root_password'].empty?
      envs['POSTGRES_PASSWORD'] = ''
    else
      envs['POSTGRES_PASSWORD'] = run_opts['root_password']
    end

    super(task, opts)
  end
end
