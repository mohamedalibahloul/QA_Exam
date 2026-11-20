# Maison Lumen cart and promo-code API: test automation

104 automated tests (pytest + pytest-bdd) written from `SPEC.md`, run against `server.js`.
Result of the last run: **84 passed, 16 red, 4 skipped.** The 16 red tests are 10 confirmed bugs (see `BUGS.md`). They are left red on purpose.

## Files

| File                                 | Content                                                         |
| ------------------------------------ | --------------------------------------------------------------- |
| `README.md`                          | this file: how to run, how to read the results                  |
| `STRATEGY.md`                        | test strategy: assumptions, architecture, risk order, AI use    |
| `BUGS.md`                            | the 10 bug reports, with a traceability table (red test to bug) |
| `bugs/BUG-01.html` ... `BUG-10.html` | the same bugs, one filled report each                           |
| `maison-lumen-test-cases.md`         | the written test cases (ID, steps, expected result)             |
| `report/quality-report.html`         | HTML quality report built from the JSON results                 |

## Requirements

- Python 3.10 or newer and Node.js 18 or newer.

## 1. Start the server (terminal 1)

```bash
cd sut
node server.js
```

The API listens on http://localhost:3002. Leave this terminal open.

## 2. Run the tests (terminal 2)

```bash # Windows: .venv\Scripts\activate
pip install -r requirements.txt
pytest -v
```

If the server is not running, the tests fail at once with a connection error: start it first. Every scenario begins with `POST /reset`, so the order of the tests does not matter and you can run the suite as many times as you want.

| Command                       | What it does                                                                 |
| ----------------------------- | ---------------------------------------------------------------------------- |
| `pytest -v`                   | all tests                                                                    |
| `pytest -m smoke`             | fast check that the API is alive and sane                                    |
| `pytest -m conc`              | one module (markers: `prod cart item stock tot promo chk ord conc amb`)      |
| `pytest -k stcitem14`         | one test (the ID without dashes)                                             |
| `pytest -m "not proposed"`    | only tests whose expected result comes from the spec, without my assumptions |
| `pytest --log-cli-level=INFO` | shows every request and response                                             |

Settings (environment variables): `BASE_URL` (default `http://localhost:3002`) and `API_TIMEOUT` (default `5` seconds).

## 3. Get a report

```bash
pytest --cucumberjson=report/results.json
```

Open `report/quality-report.html` in a browser.

## How to read the results

- **Passed:** the API behaves as the specification says.
- **Red (failed):** the API differs from the specification. Each red test is mapped to a bug in the table at the top of `BUGS.md`. Several red tests can share one cause, which is why 16 red tests give 10 bugs. Expected values always come from `SPEC.md`, never from the server.
- **Skipped:** the test could not run. It is neither a pass nor a bug, and the reason is printed by `-ra` at the end of the run.
- **`@proposed` tests:** the spec is silent, so the expected result is my decision, written in the test and in `STRATEGY.md`. The spec author has answered three of these points: the 10-unit limit wins over the stock (422 before 409), codes are not case-sensitive, and the clock cannot be simulated. Spaces around a code and the FIVEOFF case after the subtotal drops are my decisions.

## Architecture

```
features (Gherkin)  ->  step_defs  ->  api objects  ->  base_client  ->  HTTP
   what is tested        glue          one class per      requests
                                       resource
```

- `tests/features/*.feature`: scenarios in business language, named with the test-case ID (`stc-item-04-...`).
- `tests/step_defs/`: step definitions. `common_steps.py` is shared, one `<module>_steps.py` per feature.
- `api/`: one class per resource (products, carts, orders, admin). Only `base_client.py` uses `requests`.
- `support/schemas.py`: contract checks (fields and types of products and carts).
- `data/initial_catalogue.json`: expected catalogue, written from the spec.
- `sut/`: `server.js` and `products.json` (unchanged).
- `reports/`: results and the HTML quality report filled bug reports.

If an endpoint changes, one method in `api/` changes, not the tests.
