Given /^a KeyFactory is on$/ do
  @keystore = KeyFactory.new
end

Given /^I have the following keystores:$/ do |data|
  data.raw.each do |keystore|
    @keystore.create(keystore.first, eval(keystore.last))
  end
end

Given /^I have the following mock_configs:$/ do |data|
  data.raw.each do |mock|
    mock_config(mock.first, eval(mock.last))
  end
end

Given /^a valid global session cookie$/ do
  @directory        = GlobalSession::Directory.new(mock_config, @keystore.dir)
  @original_session = GlobalSession::Session.new(@directory)
  @cookie           = @original_session.to_s
end

Given /^a valid V([0-9]+) cookie$/ do |n|
  @directory        = GlobalSession::Directory.new(mock_config, @keystore.dir)
  klass = GlobalSession::Session.const_get("V#{Integer(n)}".to_sym)
  @original_session = klass.new(@directory)
  @cookie           = @original_session.to_s
end

When /^a trusted signature is passed in$/ do
  @directory.authorities['authority1'].should_receive(:public_decrypt).never
end

When /^I have a valid digest$/ do
  @valid_digest = @original_session.signature_digest
end

When /^an insecure attribute has changed$/ do
  zbin = GlobalSession::Encoding::Base64Cookie.load(@cookie)
  data = Zlib::Inflate.inflate(zbin)
  hash = nil
  format = nil
  begin
    hash = GlobalSession::Encoding::Msgpack.load(data)
    format = GlobalSession::Encoding::Msgpack
  rescue Exception => e
    hash = GlobalSession::Encoding::JSON.load(data)
    format = GlobalSession::Encoding::JSON
  end
  hash['dx'] = {'favorite_color' => 'blue'}
  data = format.dump(hash)
  zbin = Zlib::Deflate.deflate(data, Zlib::BEST_COMPRESSION)
  @cookie = GlobalSession::Encoding::Base64Cookie.dump(zbin)
end

Then /^everything is ok$/ do
  GlobalSession::Session.new(@directory, @cookie, @valid_digest).should be_a(GlobalSession::Session::Abstract)
end

Then /^I should not recompute the signature$/ do
  GlobalSession::Session.new(@directory, @cookie, @valid_digest).should be_a(GlobalSession::Session::Abstract)
end
