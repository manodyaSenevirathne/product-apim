Feature: API Key Invocation

  Background:
    Given The system is ready and I have valid access tokens for current user

  # Step 1: Create, deploy and publish a new API, create an application and subscribe it
  Scenario: Setup - Create new API and application
    # Create a new API
    When I put JSON payload from file "artifacts/payloads/create_apim_test_api.json" in context as "<createApiPayload>"
    And I create an "apis" resource with payload "<createApiPayload>"
    And I wait until the response status code is 201
    And I extract response field "id" and store it as "<apiKeyTestApiId>"

    # Enable API Key security by setting the apiKeyHeader and securityScheme
    And I retrieve the "apis" resource with id "<apiKeyTestApiId>"
    And I wait until the response status code is 200
    And I put the response payload in context as "<apiKeyTestApiPayload>"
    And I set field "apiKeyHeader" to "ApiKey" in payload "<apiKeyTestApiPayload>"
    And I get the value from json payload "<apiKeyTestApiPayload>" at path "securityScheme" and store it as "<securitySchemesArray>"
    # Append the API Key security scheme to the extracted security schemes array
    And I append the following value to the json array "<securitySchemesArray>":
      """
      api_key
      """
    When I update the "apis" resource "<apiKeyTestApiId>" and "<apiKeyTestApiPayload>" with configuration type "securityScheme" and value from context "<securitySchemesArray>"
    And I wait until the response status code is 200

    # Deploy the API so the updated configuration reaches the Gateway
    And I deploy the API with id "<apiKeyTestApiId>"
    And I wait until the response status code is 201
    And I retrieve the "apis" resource with id "<apiKeyTestApiId>"
    And I wait until the response status code is 200
    And I put the response payload in context as "<apiKeyTestDeployedPayload>"
    And I wait for deployment of the resource in "<apiKeyTestDeployedPayload>"

    # Publish the API
    And I publish the "apis" resource with id "<apiKeyTestApiId>"
    And I wait until the response status code is 200
    Then I get the lifecycle status of API "<apiKeyTestApiId>"
    Then I wait until the response status code is 200 and the value of response field "state" is "Published"

    # Create a new application
    When I put JSON payload from file "artifacts/payloads/create_apim_test_app.json" in context as "<createAppPayload>"
    And I create an application with payload "<createAppPayload>"
    And I wait until the response status code is 201
    And I extract response field "applicationId" and store it as "<apiKeyTestAppId>"

    # Subscribe the new application to the new API
    And I subscribe to resource "<apiKeyTestApiId>" using application "<apiKeyTestAppId>" and store subscription as "<apiKeyTestSubscriptionId>"

  # Step 2: Generate API key, invoke, list, regenerate, invoke, invoke with old key
  Scenario: Generate, regenerate API key and invoke API
    # Generate a PRODUCTION API key
    When I put the following JSON payload in context as "<apiKeyGenPayload>"
    """
    {
      "validityPeriod": 7200,
      "additionalProperties": {
        "permittedIP": "",
        "permittedReferer": ""
      }
    }
    """
    And I generate an api key for application "<apiKeyTestAppId>" with payload "<apiKeyGenPayload>"
    And I wait until the response status code is 200
    And I extract response field "apikey" and store it as "<apiKey1>"
    # Allow time for the Gateway cache to sync the new key
    And I wait for 3 seconds

    # Invoke the API with the generated key - should succeed
    When I invoke the API resource at path "/apiTestContext/1.0.0/customers/123/" with method "GET" using api key "apiKey1"
    Then The response status code should be 200

    # Regenerate a PRODUCTION API key
    When I put the following JSON payload in context as "<apiKeyGenPayload>"
    """
    {
      "validityPeriod": 7200,
      "additionalProperties": {
        "permittedIP": "",
        "permittedReferer": ""
      }
    }
    """
    And I generate an api key for application "<apiKeyTestAppId>" with payload "<apiKeyGenPayload>"
    And I wait until the response status code is 200
    And I extract response field "apikey" and store it as "apiKey1Regenerated"
    # Allow time for the Gateway cache to sync the new key
    And I wait for 2 seconds

    # Invoke API with regenerated key - should succeed
    When I invoke the API resource at path "/apiTestContext/1.0.0/customers/123/" with method "GET" using api key "apiKey1Regenerated"
    Then The response status code should be 200

    # Invoke API with old key after regeneration - should succeed as the old key should still be valid until expiry
    When I invoke the API resource at path "/apiTestContext/1.0.0/customers/123/" with method "GET" using api key "apiKey1"
    Then The response status code should be 200

  # Step 3: Clean up
  Scenario: Delete the subscription
    When I delete the subscription with id "apiKeyTestSubscriptionId"
    And I wait until the response status code is 200

  Scenario: Delete the created application
    When I delete the application with id "apiKeyTestAppId"
    And I wait until the response status code is 200

  Scenario: Delete the created API
    When I delete the "apis" resource with id "apiKeyTestApiId"
    And I wait until the response status code is 200
