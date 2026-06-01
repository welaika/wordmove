# Shim for the deprecated/removed 'mutex_m' stdlib which ActiveSupport 6.1 still requires.
# Provides a minimal implementation compatible with ActiveSupport's expectations.
# This can be removed once ActiveSupport dependency is upgraded to a version
# not relying on 'mutex_m' (>= 7.1) and Ruby version supplies needed features.

# rubocop:disable all
module Mutex_m
  def self.included(base)
    base.class_eval do
      if instance_methods(false).include?(:initialize)
        alias_method :__mutex_m_original_initialize,
                     :initialize
      end

      def initialize(*, &)
        @__mutex_m_mutex = ::Mutex.new
        if defined?(:__mutex_m_original_initialize)
          __mutex_m_original_initialize(*, &)
        elsif defined?(super)
          super
        end
      end
    end
  end

  def mu_synchronize(&)
    (@__mutex_m_mutex ||= ::Mutex.new).synchronize(&)
  end

  def mu_try_lock
    (@__mutex_m_mutex ||= ::Mutex.new).try_lock
  end

  def mu_unlock
    (@__mutex_m_mutex ||= ::Mutex.new).unlock
  end

  def mu_locked?
    (@__mutex_m_mutex ||= ::Mutex.new).locked?
  end
end
# rubocop:enable all
