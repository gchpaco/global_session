module GlobalSession
  module Session
  end
end

require 'global_session/session/abstract'
require 'global_session/session/v1'

module GlobalSession::Session
  def self.new(*args)
    V1.new(*args)
  end

  def self.decode_cookie(*args)
    V1.decode_cookie(*args)
  end
end
