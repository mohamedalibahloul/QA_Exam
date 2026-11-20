"""Steps reused by every feature (setup and generic response checks)."""
from pytest_bdd import given, parsers, then


@given("the shop API is running with its initial data")
def initial_data(admin_api):
    response = admin_api.reset()
    assert response.status_code == 200, f"POST /reset failed: {response.status_code} {response.body}"


@then(parsers.parse("the response status is {status:d}"))
def check_status(context, status):
    actual = context["response"].status_code
    assert actual == status, f"expected status {status}, got {actual}: {context['response'].body}"


@then("the response contains an error message")
def check_error_shape(context):
    body = context["response"].body
    assert isinstance(body, dict) and set(body) == {"error"}, f"expected {{'error': ...}}, got {body!r}"
    assert isinstance(body["error"], str) and body["error"].strip(), "error message must be a non-empty string"
