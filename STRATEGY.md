# Test strategy: Maison Lumen cart and promo-code API

## How I understood the need, and my assumptions

The team wants to know, before launch, what works, what does not, and what to fix first. I used SPEC.md as the reference and server.js as the system under test. I wrote more than 100 test cases from the spec (ID, steps, expected result) and automated them with pytest and pytest-bdd.

In three places the spec does not say what should happen. I had to choose what I expect, so I wrote my choice down:

1. **Two errors at once.** If a request goes over the limit of 10 units (error 422) and also over the stock (error 409), the spec does not say which error comes first. I assumed 422.
2. **Promo code spelling.** The spec writes codes in capitals. It does not say if "welcome10" or a code with spaces is accepted. I assumed it is.
3. **Changing a quantity.** The spec limits a cart to 10 units of one product. It does not say if this also applies when the quantity is changed with PATCH. I assumed it does.

The tests that use these guesses are tagged `@proposed`. If one of them fails, I check the answer of the author before calling it a bug: when the spec does not say who is right, it is a question, not a defect.

## Architecture, and one choice I hesitated over

Four layers, each talking only to the one below: Gherkin scenarios (what is tested, named with the test-case ID) > step definitions > one API class per resource > one HTTP client (the only file using `requests`). Expected values come from the spec, never from the server, and every scenario starts with `POST /reset`, so tests are independent. If an endpoint changes, I edit one method, not 100 tests.

- **Start the server from the tests, or by hand.** I built an auto-start, then removed it: it broke on Windows and made the project harder to explain. The cost is two terminals.

## What I tested first, and why (risks, most serious first)

1. **Stock and concurrency:** overselling costs money and cannot be undone. Real simultaneous checkouts.
2. **Money: totals, rounding, shipping:** every customer sees these.
3. **Promo codes:** many interacting rules (one discount code, minimum subtotal, conditions that must stop applying, expiry).
4. **Input validation:** quantity 0, negative, decimal, wrong types, broken JSON.
5. **Order status:** only the allowed transitions; stock returned on cancel.
6. **Catalogue and cart reading:** low risk, covered as a base.

Result: 104 automated tests, 84 passed, 16 red, 4 skipped. The 16 red tests show 10 confirmed defects (5 Critical, 3 Major, 2 Minor). They stay red on purpose.

## What I did not test

- Security (the API has no authentication) and performance.
- The reset helper itself, used only as a tool.
- SUMMER25 dates in a normal run: the API reads the machine clock, so the expired case is tested but the valid case cannot be, and 3 tests are skipped with a reason. The FIVEOFF boundary at exactly 3000 has no matching product: 1 test skipped.
- No CI and no Postman collection.

## Where I used AI, and how I checked its output

I used DeepSeek to create professional Quality report , Test case Report, and bug report templates, then provided the JSON output from pytest and asked DeepSeek to analyze the failures/bugs and populate those templates. This helped turn raw test results into structured QA documentation, capturing failing tests, error details, reproduction context, and severity.

I used Claude to help me read the specific requirements, understand the context, create test cases, write the pytest code, and suggest a better structure for the tests.

I checked Claude's work in three ways:

- I took expected values from the spec, not from the server.
- I reproduced every failing test as a direct request before calling it a bug.
- I made sure the tests could actually fail.

## With one more day

- **CI pipeline:** run the tests automatically in a Continuous Integration pipeline (for example GitHub Actions, GitLab CI or Jenkins), so they run on every change.
- **n8n workflow:** connect GitHub/CI with the QA tools. It is triggered when the CI run finishes, pulls the pytest and Postman test results, fills the QA report automatically, creates or closes Jira/ClickUp tickets based on failures and fixes, uses AI to analyze bugs and suggest fixes, and emails the final report to the team.
