module Stall
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def copy_migrations
      rake 'stall_engine:install:migrations'
    end

    def copy_initializer
      copy_file 'initializer.rb', 'config/initializers/stall.rb'
    end
  end
end
