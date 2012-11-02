Feature: GlobalSession
  In order to test default behavior for global_session
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
      | test/trust                  | ['authority1']      |
      | test/authority              | 'authority1'        |

  Scenario: everything is copacetic
    Given a valid global session cookie
    Then everything is ok

  Scenario: reusing the cryptographic signature
    Given a valid global session cookie
    And a trusted signature is passed in
    And I have a valid digest
    Then I should not recompute the signature

  Scenario: changing insecure attributes
    Given a valid global session cookie
    And an insecure attribute has changed
    Then everything is ok
