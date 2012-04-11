Given /^a Rails app$/ do
  if File.directory?(app_path('.git'))
    #stage all changes so we can wipe them out
    app_shell('git add .')
    app_shell('git reset --hard initial')
  else
    STDOUT.puts "====> installing rails there #{app_path('')}"
    app_shell("rails . -q")

    apply_template

    app_shell('git init')
    app_shell('git add .')
    app_shell('git commit -q -m "Initial commit"')
    app_shell('git tag initial')
  end

  app_shell('rake db:drop', :ignore_errors=>true)
  app_shell('rake db:create')
end

Given /^global_session is configured correctly$/ do
  app_shell('./script/generate global_session_authority development')
  app_shell('./script/generate global_session localhost')

  apply_global_session_config

  app_shell('rake db:sessions:create')
  app_shell('rake db:migrate')
end

Given /^I have my application running$/ do
  run_app
end

When /^I send ([^"]*) request "([^"]*)"$/ do |method, command|
  @response = make_request(method.downcase.to_sym, command)
end

Then /^I should receive message (?:"([^"]*)")?$/ do |message|
  @response.body.should_not be_nil
end

def make_request(method, command, parameters = nil)
  http = Net::HTTP.new("localhost", 11415)

  #command = "/#{command}"

  request = case method
            when :get
              Net::HTTP::Get.new(command)
            when :post
              Net::HTTP::Post.new(command)
            when :delete
              Net::HTTP::Delete.new(command)
            end

  response = http.start do |http|
    http.request(request)
  end

  response
end

