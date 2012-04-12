Feature: Rails 2.3.14
  In order to ensure full compatibility with different Rails versions
  Developers should be able to use global_session for Rails 2.3.14

  Background:
    Given a Rails 2.3.14 application
    And configuration fixtures are loaded
    And global_session added as a gem

  Scenario: configuring global_session authority
    Given I use development environment
    When I run './script/generate' with 'global_session_authority'
    Then I should receive message about about successful result
    And I should have the following files generated:
      | config/authorities | development.key |
      | config/authorities | development.pub |

  Scenario: configuring global_session config
    Given I use localhost as a domain
    When I run './script/generate' with 'global_session'
    Then I should receive message about successful result
    And I should have the following file generated:
      | config | global_session.yml |

  Scenario: configuring global_session middleware
    Given global_session added as a middleware
    When I lunch my application at:
      | localhost | 11415 |
    Then I should have my application up and running

  Scenario: initializing global_session cookies
    When I send GET request 'happy/index'
    Then I should receive something interesting from application
    And I have only 1 cookie variable called 'global_session'

  Scenario: save data to the local session variable
    When I send POST request 'happy/update' with the following:
      | key   | my_data       |
      | value | hello cookies |
    Then I should be redirected to 'happy/index'
    And I should receive the following:
      | my_data | hello cookies |
