# frozen_string_literal: true

require "open3"

module Dotfiles
  class Shell
    def command?(name)
      ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
        File.executable?(File.join(directory, name))
      end
    end

    def capture(*command, env: {})
      output, error, status = Open3.capture3(env, *command)
      raise Error, "#{command.join(' ')} failed: #{error.strip}" unless status.success?

      output
    end

    def run(*command, env: {})
      return if system(env, *command)

      raise Error, "command failed: #{command.join(' ')}"
    end
  end
end
