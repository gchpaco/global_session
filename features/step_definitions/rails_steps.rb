Given /^a Rails ([\d\.]+) application$/ do |rails_version|
  STDOUT.puts "====> Create rails #{rails_version} application in  #{app_path('')}"
  app_shell("rails _#{rails_version}_ . -q")
end

Given /^configuration fixtures are loaded$/ do
  load_fixtures(app_rails_version)
end

Given /^database created$/ do
  app_shell('rake db:drop', :ignore_errors=>true)
  app_shell('rake db:create')
  app_shell('rake db:sessions:create')
  app_shell('rake db:migrate')
end

Given /^global_session added as a gem$/ do
  add_global_session_gem
end

Given /^I use (.+) environment$/ do |env|
  @rails_env = env
end

When /^I run \'.\/script\/generate\' with \'global_session_authority\'$/ do
  app_shell_with_log("./script/generate global_session_authority #{@rails_env}")
end

Then /^I should receive message about about successful result$/ do
  File.read(log_file).match("Don't forget to delete config/authorities/development.key").should_not be_nil
end

Then /^I should have the following files generated:$/ do |table|
  table.raw.map do |file|
    file = app_path(file)
    File.exist?(file).should be_true
  end
end

Given /^I use (.+) as a domain$/ do |domain|
  @domain = domain
end

When /^I run '\.\/script\/generate' with 'global_session'$/ do
  app_shell_with_log("./script/generate global_session #{@domain}")
end

Then /^I should receive message about successful result$/ do
  File.read(log_file).match("create  config/global_session.yml").should_not be_nil
end

Given /^global_session added as a middleware$/ do
  add_global_session_middleware
end

When /^I lunch my application on (\d+) port$/ do |port|
  @port = port
  run_application_at(@port)
end

Then /^I should have my application up and running$/ do
  lambda {
    TCPSocket.new('localhost', @port).close
  }.should_not raise_error(Errno::ECONNREFUSED)
end

When /^I send (.+) request '(.+)'$/ do |method, path|
  @response = make_request(method.downcase.to_sym, path)
end

Then /^I should receive message "(.+)"$/ do |message|
  JSON::parse(@response.body)["message"].should match(message)
end

Then /^I have only (\d+) cookie variable called '(.+)'$/ do |cookie_num, cookie_name|
  @response.cookies.size.should be_equal(1)
  @response.cookies.map(&:name).include?(cookie_name).should be_true
end

When /^I send (.+) request '(.+)' with the following:$/ do |method, path, data|
  @response = make_request(method.downcase.to_sym, path, data.rows_hash)
end

Then /^I should be redirected to '(.+)'$/ do |redirect_path|
  @response.status.should be_equal(302)
  @response.headers["Location"].should match(redirect_path)
  @response = make_request(:get, redirect_path)
end

Then /^I should receive in session the following variables:$/ do |data|
  JSON::parse(@response.body)["session"].should == data.rows_hash
end
