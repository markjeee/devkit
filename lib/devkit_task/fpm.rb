#
# Source:
#  https://hub.docker.com/_/php/
#

require 'rake'
require 'rake/tasklib'

class DevkitTask::Fpm < Rake::TaskLib
  include Devkit::Task

  set_namespace :fpm
  set_exposed_port 9000
  set_exposed_volume '/fpm'

  EXPOSED_FPM_VHOSTS = '/vhosts'

  def self.docker_run(task, opts)
    vhosts_path = File.join(var_path, 'vhosts')

    foreach_vhost(vhosts_path) do |vhost_name, original_path, vhost_link|
      opts = configure_volume_opts(original_path, opts, File.join(EXPOSED_FPM_VHOSTS, vhost_name))
    end

    super(task, opts)
  end

  def perform_prepare
    super

    vhosts_path = File.join(var_path, 'vhosts')
    sh 'mkdir -p %s' % vhosts_path
  end
end
