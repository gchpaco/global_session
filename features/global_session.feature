Feature: GlobalSession
  In order to test default behaviour for global_session
  I want to duplicate some rspec scenarios here

  Background:
    Given a KeyFactory is on
    And I have the following keystores:
      | authority1 | true   |
      | authority2 | false  |
    And I have the following mock_configs:
      | common/attributes/signed    | ['user']            |
      | common/attributes/insecure  | ['favorite_color']  |
      | test/timeout                | '60'                |

      # @load_from_cookie
  Scenario: everything is copascetic
    When I load it from cookie successful
    Then everything is ok

  #@load_from_cookie
  Scenario: a trusted signature
    When a trusted signature is passed in
    And I have a valid digest
    Then I should not recompute the signature

  #@load_from_cookie
  Scenario: an insecure attribute
    Given an insecure attribute has changed
    When I load it from cookie
    Then everything is ok
