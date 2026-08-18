# frozen_string_literal: true

module Dotfiles
  class Error < StandardError; end
end

require_relative "dotfiles/shell"
require_relative "dotfiles/profiles"
require_relative "dotfiles/link_plan"
require_relative "dotfiles/installer"
require_relative "dotfiles/doctor"
require_relative "dotfiles/verifier"
require_relative "dotfiles/cli"
