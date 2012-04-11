Feature: global_session
  Background:
    Given a Rails app
    And global_session is configured correctly
    And I have my application running

  Scenario: retrieving global session
    When I send GET request "/"
    Then I should receive message "yabadabadoo!"
