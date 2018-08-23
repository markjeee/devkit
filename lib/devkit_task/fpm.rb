#
# Source:
#  https://hub.docker.com/_/php/
#

require 'rake'
require 'rake/tasklib'

class DevkitTask::Fpm < Rake::TaskLib
  include Devkit::Task

  set_namespace :fpm
  set_default_options :exposed_port => 9000,
                      :exposed_volume => '/fpm'

  EXPOSED_FPM_VHOSTS = '/vhosts'

  def configure_run_opts(drun, run_opts)
    vhosts_path = File.join(var_path, 'vhosts')

    foreach_vhost(vhosts_path) do |vhost_name, original_path, vhost_link|
      run_opts = drun.configure_volume_opts(original_path, run_opts, File.join(EXPOSED_FPM_VHOSTS, vhost_name))
    end

    super(drun, run_opts)
  end

  def perform_prepare
    super

    vhosts_path = File.join(var_path, 'vhosts')
    sh 'mkdir -p %s' % vhosts_path
  end
end
