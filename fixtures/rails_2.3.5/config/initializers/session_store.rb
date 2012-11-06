ActionController::Base.session = {
  :key         => '_local_session',
  :secret      => '1337cafe'
}
ActionController::Base.session_store = :active_record_store
