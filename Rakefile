require File.expand_path('../config/boboot', __FILE__)
Boboot.require_boot!

require_relative 'mariadb/mariadb'
DevkitTask::MariaDB.new.define!

require_relative 'postgres/postgres'
DevkitTask::Postgres.new.define!
