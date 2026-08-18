# frozen_string_literal: true

module Dotfiles
  class Profiles
    NAMES = %w[core rails frontend docker ai extras].freeze
    DEPENDENCIES = {
      "core" => [],
      "rails" => %w[core frontend],
      "frontend" => %w[core],
      "docker" => %w[core],
      "ai" => %w[core frontend],
      "extras" => %w[core]
    }.freeze
    MISE_TOOLS = {
      "rails" => %w[ruby node],
      "frontend" => %w[node],
      "ai" => %w[node],
      "extras" => %w[python rust awscli aws-vault kubectl]
    }.freeze

    def initialize(names)
      requested = names.empty? ? ["rails"] : names
      unknown = requested - NAMES
      raise Error, "unknown profile: #{unknown.join(', ')} (choose #{NAMES.join(', ')})" unless unknown.empty?

      @names = requested.flat_map { |name| expand(name) }.uniq
    end

    attr_reader :names

    def include?(name)
      names.include?(name)
    end

    def mise_tools
      names.flat_map { |name| MISE_TOOLS.fetch(name, []) }.uniq
    end

    private

    def expand(name)
      DEPENDENCIES.fetch(name).flat_map { |dependency| expand(dependency) } + [name]
    end
  end

  class Brewfile
    PROFILE = /^# profile: ([a-z]+)$/

    def initialize(path)
      @path = path
    end

    def entries(profiles)
      active = nil
      File.readlines(@path).each_with_object([]) do |line, selected|
        match = PROFILE.match(line.chomp)
        if match
          active = match[1]
          raise Error, "unknown Brewfile profile: #{active}" unless Profiles::NAMES.include?(active)
          next
        end

        next if line.strip.empty? || line.start_with?("#")
        raise Error, "Brewfile entry is missing a profile: #{line.strip}" unless active

        selected << line if profiles.include?(active)
      end
    end

    def all_profiles
      File.readlines(@path).each_with_object([]) do |line, profiles|
        match = PROFILE.match(line.chomp)
        profiles << match[1] if match
      end.uniq
    end
  end
end
