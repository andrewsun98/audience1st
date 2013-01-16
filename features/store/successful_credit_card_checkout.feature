@stubs_successful_credit_card_payment
Feature: Successful checkout with credit card

  As a patron
  So that I can purchase my tickets 
  I want to checkout with a credit card

  Background:
    Given today is May 9, 2011
    And I am logged in as customer "Tom Foolery"

  Scenario: successful credit card payment without donation

    Given my cart contains the following tickets:
      | show    | qty | type    | price | showdate             |
      | Chicago |   3 | General |  7.00 | May 15, 2011, 8:00pm |
    Then I should be on the checkout page
    And the billing customer should be "Tom Foolery"
    When I place my order with a valid credit card
    Then I should be on the order confirmation page
    And I should see "You have paid a total of $21.00 by Credit card"
    And customer Tom Foolery should have 3 "General" tickets for "Chicago" on May 15, 2011, 8:00pm

  Scenario: successful gift order without donation

    Given my gift order contains the following tickets:
      | show    | qty | type    | price | showdate             |
      | Chicago |   2 | General |  7.00 | May 15, 2011, 8:00pm |
    Then I should be on the shipping info page
    When I fill in the "billing_info" fields with "Al Smith, 123 Fake St., Alameda, CA 94501, 510-999-9999, alsmith@mail.com"
    And I press "CONTINUE >>"
    Then I should be on the checkout page
    And the gift recipient customer should be "Al Smith"
    And the billing customer should be "Tom Foolery"
    When  I place my order with a valid credit card
    Then I should be on the order confirmation page
    And customer Tom Foolery should have 0 "General" tickets for "Chicago" on May 15, 2011, 8:00pm
    And customer Al Smith should have 2 "General" tickets for "Chicago" on May 15, 2011, 8:00pm

