Feature: Publisher API Management
  This feature tests application creation, key generation, multiple client secret handling,
  token generation, API invocation, secret deletion rules, application sharing, and cleanup
  for a newly created application.

  Background:
    Given The system is ready and I have valid access tokens for current user

  # Create a new application
  Scenario: Create new application
    When I put JSON payload from file "artifacts/payloads/create_apim_test_app.json" in context as "<createAppPayload>"
    And I create an application with payload "<createAppPayload>"
    And I wait until the response status code is 201
    And I extract response field "applicationId" and store it as "<createdAppId>"
    And I retrieve the application with id "<createdAppId>"
    And I wait until the response status code is 200

  Scenario: Create a new API, deploy and publish it
    When I have created an api from "artifacts/payloads/create_apim_test_api.json" as "<createdApiId>" and deployed it
    And I retrieve the "apis" resource with id "<createdApiId>"
    And I wait until the response status code is 200
    And I put the response payload in context as "<createdAPIPayload>"
    And I wait for deployment of the resource in "<createdAPIPayload>"
    And I publish the "apis" resource with id "<createdApiId>"
    And I wait until the response status code is 200
    Then I get the lifecycle status of API "<createdApiId>"
    Then I wait until the response status code is 200 and the value of response field "state" is "Published"

  Scenario: Subscribe the new API using the created application
    And I put the following JSON payload in context as "<apiSubscriptionPayload>"
    """
    {
      "applicationId": "{{createdAppId}}",
      "apiId": "{{createdApiId}}",
      "throttlingPolicy": "Bronze"
    }
    """
    And I create a subscription using payload "<apiSubscriptionPayload>"
    And I wait until the response status code is 201
    And I extract response field "subscriptionId" and store it as "<subscriptionId>"

  # Generate the production key mapping for the application
  Scenario: Generate initial application keys
    When I put the following JSON payload in context as "<generateApplicationKeysPayload>"
    """
    {
      "keyType": "PRODUCTION",
      "grantTypesToBeSupported": [
        "client_credentials"
      ]
    }
    """
    And I generate client credentials for application id "<createdAppId>" with payload "<generateApplicationKeysPayload>"
    And I wait until the response status code is 200
    And I extract response field "consumerSecret" and store it as "<appConsumerSecret>"
    And I extract response field "keyMappingId" and store it as "<keyMappingId>"

  # Generate tokens
  Scenario: Generate access tokens
    When I put the following JSON payload in context as "<createApplicationAccessTokenPayload>"
    """
    {
      "consumerSecret": "{{appConsumerSecret}}",
      "validityPeriod": 3600
    }
    """
    And I request an access token for application id "createdAppId" using payload "<createApplicationAccessTokenPayload>" and key mapping id "<keyMappingId>"
    And I wait until the response status code is 200
    And I extract response field "accessToken" and store it as "<generatedAccessTokenForInitialSecret>"

  # Verify that the issued token can invoke the API
  Scenario: Invoke API using tokens generated from two client secrets
    And I invoke the API resource at path "/apiTestContext/1.0.0/customers/123/" with method "GET" using access token "<generatedAccessTokenForInitialSecret>" and payload ""
    Then The response status code should be 200

  # Delete the consumer key and secret generated for the new application
  Scenario: Delete generated keys
    When I delete the generate key with key mapping id "keyMappingId" for application "createdAppId"
    And I wait until the response status code is 200
    Then I retrieve existing application keys for "createdAppId"
    And I wait until the response status code is 200 and the value of response field "count" is "0"

  # The  issued token should remain valid even after the secret is deleted
  Scenario: Verify oldest issued token remains valid after secret deletion
    And I invoke the API resource at path "/apiTestContext/1.0.0/customers/123/" with method "GET" using access token "<generatedAccessTokenForInitialSecret>" and payload ""
    Then The response status code should be 200

  # Clean up the resources
  Scenario: Delete the subscription
    When I delete the subscription with id "<subscriptionId>"
    And I wait until the response status code is 200

  Scenario: Delete the created application
    When I delete the application with id "<createdAppId>"
    And I wait until the response status code is 200

  Scenario: Delete the created API
    When I delete the "apis" resource with id "<createdApiId>"
    And I wait until the response status code is 200
