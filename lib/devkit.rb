require 'docker_task'

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

module DevkitTask
end
