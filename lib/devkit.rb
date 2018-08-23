unless defined?(DEVKIT_ROOT_PATH)
  DEVKIT_ROOT_PATH = File.expand_path('../../', __FILE__)
end

unless defined?(DEVKIT_LIB_PATH)
  DEVKIT_LIB_PATH = File.join(DEVKIT_ROOT_PATH, 'lib')
  $: << DEVKIT_LIB_PATH
end

require 'docker_task'
require 'devkit_task'

module Devkit
  autoload :Config, 'devkit/config'
  autoload :Helper, 'devkit/helper'
  autoload :Task, 'devkit/task'

  def self.config
    if defined?(@config)
      @config
    else
      @config = Config.load_config
    end
  end

  def self.include_docker_tasks(options = { })
    DockerTask.include_tasks(options)
  end
end
