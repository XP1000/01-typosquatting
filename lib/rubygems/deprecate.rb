# frozen_string_literal: true
##
# Provides a single method +deprecate+ to be used to declare when
# something is going away.
#
#     class Legacy
#       def self.klass_method
#         # ...
#       end
#
#       def instance_method
#         # ...
#       end
#
#       extend Gem::Deprecate
#       deprecate :instance_method, "X.z", 2011, 4
#
#       class << self
#         extend Gem::Deprecate
#         deprecate :klass_method, :none, 2011, 4
#       end
#     end

module Gem::Deprecate

  def self.skip # :nodoc:
    @skip ||= false
  end

  def self.skip=(v) # :nodoc:
    @skip = v
  end

  ##
  # Temporarily turn off warnings. Intended for tests only.

  def skip_during
    Gem::Deprecate.skip, original = true, Gem::Deprecate.skip
    yield
  ensure
    Gem::Deprecate.skip = original
  end

  ##
  # Simple deprecation method that deprecates +name+ by wrapping it up
  # in a dummy method. It warns on each call to the dummy method
  # telling the user of +repl+ (unless +repl+ is :none) and the
  # year/month that it is planned to go away.

  def deprecate(name, repl, year, month)
    class_eval do
      old = "_deprecated_#{name}"
      alias_method old, name
      define_method name do |*args, &block|
        klass = self.kind_of? Module
        target = klass ? "#{self}." : "#{self.class}#"
        msg = [ "NOTE: #{target}#{name} is deprecated",
                repl == :none ? " with no replacement" : "; use #{repl} instead",
                ". It will be removed on or after %4d-%02d-01." % [year, month],
                "\n#{target}#{name} called from #{Gem.location_of_caller.join(":")}",
        ]
        warn "#{msg.join}." unless Gem::Deprecate.skip
        send old, *args, &block
      end
    end
  end

  # Deprecation method to deprecate Rubygems commands
  def deprecate_command(year, month)
    class_eval do
      define_method "deprecated?" do
        true
      end

      define_method "deprecation_warning" do
        msg = [ "\nNOTE: #{self.command} command is deprecated",
                ". It will be removed on or after %4d-%02d-01.\n" % [year, month],
        ]

        warn "#{msg.join}" unless Gem::Deprecate.skip
      end
    end
  end
  module_function :deprecate, :deprecate_command, :skip_during

end
