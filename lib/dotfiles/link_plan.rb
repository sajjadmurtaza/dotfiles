# frozen_string_literal: true

require "pathname"

module Dotfiles
  Mapping = Struct.new(:destination, :source)

  class LinkPlan
    def initialize(root:, home:, shell: Shell.new)
      @root = root
      @home = home
      @shell = shell
    end

    def mappings
      @mappings ||= begin
        output = @shell.capture("lsrc", "-d", @root, env: { "HOME" => @home, "RCRC" => File.join(@root, "rcrc") })
        output.lines.each_with_object([]) do |line, result|
          destination, source = line.chomp.split(":", 2)
          next unless destination && source

          validate_destination!(destination)
          result << Mapping.new(destination, source)
        end
      end
    end

    def conflicts
      mappings.reject { |mapping| absent?(mapping.destination) || correct_link?(mapping) }
    end

    private

    def validate_destination!(path)
      home = File.expand_path(@home)
      destination = File.expand_path(path)
      relative = Pathname.new(destination).relative_path_from(Pathname.new(home))
      if relative.absolute? || relative.each_filename.first == ".."
        raise Error, "refusing rcm destination outside HOME: #{path}"
      end

      ancestor = File.dirname(destination)
      loop do
        raise Error, "refusing rcm destination beneath symlinked directory: #{path}" if File.symlink?(ancestor)
        break if ancestor == home
        raise Error, "refusing rcm destination outside HOME: #{path}" if ancestor == File.dirname(ancestor)

        ancestor = File.dirname(ancestor)
      end
    end

    def absent?(path)
      !File.exist?(path) && !File.symlink?(path)
    end

    def correct_link?(mapping)
      return false unless File.symlink?(mapping.destination)

      link_target = File.expand_path(File.readlink(mapping.destination), File.dirname(mapping.destination))
      normalized(link_target) == normalized(mapping.source)
    end

    def normalized(path)
      File.exist?(path) ? File.realpath(path) : File.expand_path(path)
    end
  end
end
