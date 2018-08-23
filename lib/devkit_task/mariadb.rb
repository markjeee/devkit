#
# Source:
#   https://hub.docker.com/_/mariadb/
#

require 'rake'
require 'rake/task'
require 'rake/tasklib'
require 'docker_task'

class DevkitTask::MariaDB < Rake::TaskLib
  include Devkit::Task

  set_namespace :mariadb
  set_exposed_port 3306
  set_exposed_volume '/var/lib/mysql'

  def self.docker_run(task, opts)
    run_opts = docker_run_config

    root_password = nil
    unless run_opts.nil? || run_opts.empty?
      root_password = run_opts['root_password']
    end

    if root_password.nil? || root_password.empty?
      envs['MYSQL_ROOT_PASSWORD'] = ''
      envs['MYSQL_ALLOW_EMPTY_PASSWORD'] = '1'
    else
      envs['MYSQL_ROOT_PASSWORD'] = root_password
    end

    super(task, opts)
  end
end
