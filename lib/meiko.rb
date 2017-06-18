module Meiko
  require 'meiko/event'
  require 'meiko/eventraw'
  require 'meiko/instance'

  def self.instance(opts = {})
    Meiko::Instance.new(opts)
  end
end
