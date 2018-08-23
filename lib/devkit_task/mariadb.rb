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
  set_default_options :exposed_port => 3306,
                      :exposed_volume => '/var/lib/mysql'

  def configure_run_opts(drun, run_opts)
    run_config = docker_run_config

    root_password = nil
    unless run_config.nil? || run_config.empty?
      root_password = run_config['root_password']
    end

    if root_password.nil? || root_password.empty?
      drun.envs['MYSQL_ROOT_PASSWORD'] = ''
      drun.envs['MYSQL_ALLOW_EMPTY_PASSWORD'] = '1'
    else
      drun.envs['MYSQL_ROOT_PASSWORD'] = root_password
    end

    super(drun, run_opts)
  end
end
