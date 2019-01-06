module Wordmove
  class UndefinedEnvironment < StandardError; end
  class NoAdapterFound < StandardError; end
  class MovefileNotFound < StandardError; end
  class ShellCommandError < StandardError; end
  class ImplementInSubclassError < StandardError; end
  class UnmetPeerDependencyError < StandardError; end
  class RemoteHookException < StandardError; end
  class LocalHookException < StandardError; end
end
