module GlobalSession::Session
  class Abstract
    attr_reader :id, :authority, :created_at, :expired_at, :directory
  end
end