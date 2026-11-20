# Bug reports: Maison Lumen cart and promo-code API

Reference: SPEC.md v1. Server: `node server.js` on http://localhost:3002. Every bug was reproduced against the running server on 20/11/2026, starting from `POST /reset`. After a reset the first cart is `c1` and the first order is `o1`. The curl commands work in Git Bash, Linux and macOS (on Windows PowerShell, use Postman: quoting JSON for curl is unreliable there).

| ID     | Title                                                              | Severity | Priority      |
| ------ | ------------------------------------------------------------------ | -------- | ------------- |
| BUG-01 | Quantity 0, negative or decimal is accepted when adding a product  | Critical | 1 = fix first |
| BUG-02 | Two checkouts at the same time make the stock negative             | Critical | 2             |
| BUG-03 | FIVEOFF discount stays after the cart falls below the 3000 minimum | Critical | 3             |
| BUG-04 | Two discount codes can be applied to the same cart                 | Critical | 4             |
| BUG-05 | An unpaid order can be shipped                                     | Critical | 5             |
| BUG-06 | The 10-unit limit is checked per request, not on the line          | Major    | 6             |
| BUG-07 | Free shipping is decided before the discount instead of after      | Major    | 7             |
| BUG-08 | Adding exactly the available stock is refused                      | Major    | 8             |
| BUG-09 | Percentage discounts are rounded down instead of half up           | Minor    | 9             |
| BUG-10 | An expired promo code returns 404 instead of 422                   | Minor    | 10            |

**Severity** follows the template: Critical = money, stock or order data is wrong or can be abused; Major = a rule of the specification is broken but the damage is limited; Minor = small inconsistency, no direct damage. **Priority** is my fix order: first what any customer can do with one request (BUG-01), then what needs timing or a known trick (BUG-02, BUG-03), then the rest by the damage done. The reason is given on each bug.

Automated run: 104 tests, 84 passed, 16 red, 4 skipped. The 16 red tests give these 10 bugs. The red tests are left red on purpose.

---

## BUG-01: Quantity 0, negative or decimal is accepted when adding a product

- **Severity / Priority:** Critical / 1. Money and stock data are wrong and the flaw can be abused on purpose. Priority 1 because it needs one request and is the cheapest defect to exploit.
- **Specification reference:** SPEC 3, rule 1: "On POST …/items, quantity must be an integer of at least 1, otherwise 400."
- **Steps to reproduce:**
  - _Quantity -1_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": -1}'`
  - _Quantity 0_
  4. `curl -X POST http://localhost:3002/reset`
  5. `curl -X POST http://localhost:3002/carts`
  6. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": 0}'`
  - _Quantity 1.5_
  7. `curl -X POST http://localhost:3002/reset`
  8. `curl -X POST http://localhost:3002/carts`
  9. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": 1.5}'`
  - _Abuse: negative line used to lower the order total and raise the stock_
  10. `curl -X POST http://localhost:3002/reset`
  11. `curl -X POST http://localhost:3002/carts`
  12. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 2, "quantity": 1}'`
  13. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": -1}'`
  14. `curl -X GET http://localhost:3002/carts/c1`
  15. `curl -X POST http://localhost:3002/carts/c1/checkout`
  16. `curl -X GET http://localhost:3002/products/1`
- **Expected result:** 400 with {"error": "..."} for each of the three bodies. The cart is left unchanged.
- **Actual result:**
  - `POST /carts/c1/items` returned **201**: `{"id": "c1", "status": "open", "promoCodes": [], "items": [{"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": -1, "lineTotalCents": -1995}], "subtotalCents": -1995, "discountCents": 0, "shippingCents": 490, "totalCents": -1505}`
  - `POST /carts/c1/items` returned **201**: `{"id": "c1", "status": "open", "promoCodes": [], "items": [{"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": 0, "lineTotalCents": 0}], "subtotalCents": 0, "discountCents": 0, "shippingCents": 490, "totalCents": 490}`
  - `POST /carts/c1/items` returned **201**: `{"id": "c1", "status": "open", "promoCodes": [], "items": [{"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": 1.5, "lineTotalCents": 2992.5}], "subtotalCents": 2992.5, "discountCents": 0, "shippingCents": 490, "totalCents": 3482.5}`
  - `POST /carts/c1/checkout` returned **201**: `{"id": "o1", "cartId": "c1", "status": "pending_payment", "promoCodes": [], "items": [{"productId": 2, "name": "Ceramic Mug", "unitPriceCents": 1250, "quantity": 1, "lineTotalCents": 1250}, {"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": -1, "lineTotalCents": -1995}], "subtotalCents": -745, "discountCents": 0, "shippingCents": 490, "totalCents": -255}`
  - `GET /products/1` returned **200**: `{"id": 1, "name": "Amber Candle", "priceCents": 1995, "stock": 26}`
  - In short: 201 Created each time. Quantity -1: line quantity -1, lineTotalCents -1995, cart totalCents -1505. Quantity 0: a line with quantity 0 is created. Quantity 1.5: lineTotalCents 2992.5, which is not a whole number of cents. Abuse path: cart subtotalCents -745, checkout returns 201 with order o1 totalCents -255, and the stock of product 1 goes from 25 to 26.
- **Notes:** Always (3 of 3 bodies, abuse path every time). Detected by `stc-item-04`, `stc-item-05`, `stc-item-06`. Impact: Any customer can trigger it with one request, no timing and no knowledge needed. Orders with a negative total are created, stock numbers become wrong (the shop appears to have more goods than it does), and decimal quantities break the whole-cent rule for money. Possible cause: The add handler only checks that quantity is a number (typeof) and the upper limit, not that it is an integer of at least 1. PATCH validates correctly and returns 400, so only POST …/items is affected. Related: BUG-06 (same handler).

---

## BUG-02: Two checkouts at the same time make the stock negative

- **Severity / Priority:** Critical / 2. Overselling cannot be undone after the order is confirmed. Priority 2: it needs simultaneous requests, so it is less trivial than BUG-01 but very likely on a launch day.
- **Specification reference:** SPEC 6: "The stock can never become negative, including when two customers check out at the same time."
- **Steps to reproduce:**
  - _Two simultaneous checkouts of the last 2 vases_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts`
  4. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 6, "quantity": 1}'`
  5. `curl -X PATCH http://localhost:3002/carts/c1/items/6 -H "Content-Type: application/json" -d '{"quantity": 2}'`
  6. `curl -X POST http://localhost:3002/carts/c2/items -H "Content-Type: application/json" -d '{"productId": 6, "quantity": 1}'`
  7. `curl -X PATCH http://localhost:3002/carts/c2/items/6 -H "Content-Type: application/json" -d '{"quantity": 2}'`
  8. Send these two at the same time (for example `cmd1 & cmd2 & wait`):
     `curl -X POST http://localhost:3002/carts/c1/checkout`
     `curl -X POST http://localhost:3002/carts/c2/checkout`
  9. `curl -X GET http://localhost:3002/products/6`
- **Expected result:** One checkout returns 201, the other 409. Stock of product 6 is 0.
- **Actual result:**
  - `POST /carts/c1/checkout` returned **201**: `{"id": "o2", "cartId": "c1", "status": "pending_payment", "promoCodes": [], "items": [{"productId": 6, "name": "Hand-blown Vase", "unitPriceCents": 5900, "quantity": 2, "lineTotalCents": 11800}], "subtotalCents": 11800, "discountCents": 0, "shippingCents": 0, "totalCents": 11800}`
  - `POST /carts/c2/checkout` returned **201**: `{"id": "o1", "cartId": "c2", "status": "pending_payment", "promoCodes": [], "items": [{"productId": 6, "name": "Hand-blown Vase", "unitPriceCents": 5900, "quantity": 2, "lineTotalCents": 11800}], "subtotalCents": 11800, "discountCents": 0, "shippingCents": 0, "totalCents": 11800}`
  - `GET /products/6` returned **200**: `{"id": 6, "name": "Hand-blown Vase", "priceCents": 5900, "stock": -2}`
  - In short: Both checkouts return 201. GET /products/6 returns "stock": -2.
- **Notes:** 10 runs out of 10. Detected by `stc-conc-01`, `stc-conc-02`. Impact: The shop sells goods it does not have. Both customers are told the order is confirmed, and one of them will have to be refused or refunded later. With 5 carts, 5 orders are accepted for a stock of 2 (stc-conc-02). Possible cause: Checkout checks the stock, then waits (await sleep(25) in server.js) before decreasing it. A second request passes the check during that wait. Related: BUG-08 (the setup needs the PATCH workaround).

---

## BUG-03: FIVEOFF discount stays after the cart falls below the 3000 minimum

- **Severity / Priority:** Critical / 3. Money is wrong and the rule can be abused by a customer who knows the trick. Priority 3: it needs a specific sequence of actions.
- **Specification reference:** SPEC 5: "FIVEOFF needs a subtotal of 3000 or more. A code gives a discount only while its conditions are met: the totals always describe the cart as it is now."
- **Steps to reproduce:**
  - _Apply FIVEOFF, then drop below the minimum_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": 2}'`
  4. `curl -X POST http://localhost:3002/carts/c1/promo -H "Content-Type: application/json" -d '{"code": "FIVEOFF"}'`
  5. `curl -X PATCH http://localhost:3002/carts/c1/items/1 -H "Content-Type: application/json" -d '{"quantity": 0}'`
  6. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 7, "quantity": 1}'`
  7. `curl -X GET http://localhost:3002/carts/c1`
- **Expected result:** discountCents 0 (the condition is no longer met). shippingCents 490, totalCents 1289.
- **Actual result:**
  - `GET /carts/c1` returned **200**: `{"id": "c1", "status": "open", "promoCodes": ["FIVEOFF"], "items": [{"productId": 7, "name": "Tea Towel", "unitPriceCents": 799, "quantity": 1, "lineTotalCents": 799}], "subtotalCents": 799, "discountCents": 500, "shippingCents": 490, "totalCents": 789}`
  - In short: subtotalCents 799, discountCents 500, shippingCents 490, totalCents 789.
- **Notes:** Always. Detected by `stc-promo-05`, `stc-amb-12`. Impact: The minimum-spend rule can be bypassed on purpose: fill the cart, apply the code, then swap items. The shop gives 500 cents on any small cart. Possible cause: The 3000 minimum is checked only when the code is applied, not when the totals are calculated. Related: BUG-04 (same promo handler).

---

## BUG-04: Two discount codes can be applied to the same cart

- **Severity / Priority:** Critical / 4. Money is wrong and the shop loses revenue on purpose-built carts. Priority 4: it needs two valid codes.
- **Specification reference:** SPEC 5: "A cart holds at most one discount code; applying a second one is refused with 409 and the cart does not change."
- **Steps to reproduce:**
  - _WELCOME10 then FIVEOFF_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": 2}'`
  4. `curl -X POST http://localhost:3002/carts/c1/promo -H "Content-Type: application/json" -d '{"code": "WELCOME10"}'`
  5. `curl -X POST http://localhost:3002/carts/c1/promo -H "Content-Type: application/json" -d '{"code": "FIVEOFF"}'`
  6. `curl -X GET http://localhost:3002/carts/c1`
- **Expected result:** The second code returns 409. promoCodes is ["WELCOME10"], discountCents 399.
- **Actual result:**
  - `POST /carts/c1/promo` returned **200**: `{"id": "c1", "status": "open", "promoCodes": ["WELCOME10", "FIVEOFF"], "items": [{"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": 2, "lineTotalCents": 3990}], "subtotalCents": 3990, "discountCents": 899, "shippingCents": 490, "totalCents": 3581}`
  - `GET /carts/c1` returned **200**: `{"id": "c1", "status": "open", "promoCodes": ["WELCOME10", "FIVEOFF"], "items": [{"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": 2, "lineTotalCents": 3990}], "subtotalCents": 3990, "discountCents": 899, "shippingCents": 490, "totalCents": 3581}`
  - In short: The second code returns 200. promoCodes is ["WELCOME10","FIVEOFF"], discountCents 899, totalCents 3581.
- **Notes:** Always, in both orders. Detected by `stc-promo-09`, `stc-promo-10`. Impact: Discounts stack without limit between discount codes, so every customer who knows two codes pays less than the shop allows. Possible cause: There is no check for an existing discount code when a code is added. Related: BUG-03.

---

## BUG-05: An unpaid order can be shipped

- **Severity / Priority:** Critical / 5. Order data is wrong and goods are lost. Priority 5: it needs someone or a system to call the endpoint, so it ranks after the money bugs open to every customer.
- **Specification reference:** SPEC 6: "The only allowed change to shipped is paid --ship--> shipped; any other change gives 409."
- **Steps to reproduce:**
  - _Ship before payment_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": 2}'`
  4. `curl -X POST http://localhost:3002/carts/c1/checkout`
  5. `curl -X POST http://localhost:3002/orders/o1/ship`
  6. `curl -X GET http://localhost:3002/orders/o1`
- **Expected result:** 409, and the order stays pending_payment.
- **Actual result:**
  - `POST /orders/o1/ship` returned **200**: `{"id": "o1", "cartId": "c1", "status": "shipped", "promoCodes": [], "items": [{"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": 2, "lineTotalCents": 3990}], "subtotalCents": 3990, "discountCents": 0, "shippingCents": 490, "totalCents": 4480}`
  - `GET /orders/o1` returned **200**: `{"id": "o1", "cartId": "c1", "status": "shipped", "promoCodes": [], "items": [{"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": 2, "lineTotalCents": 3990}], "subtotalCents": 3990, "discountCents": 0, "shippingCents": 490, "totalCents": 4480}`
  - In short: 200, the order status becomes shipped.
- **Notes:** Always. Detected by `stc-ord-05`. Impact: Goods can leave the warehouse without payment. A shipped order can no longer be cancelled, so the unpaid goods cannot be recovered through the API. Possible cause: The ship action accepts pending_payment as well as paid. Related: none.

---

## BUG-06: The 10-unit limit is checked per request, not on the line

- **Severity / Priority:** Major / 6. A rule is broken but damage is limited. Priority 6.
- **Specification reference:** SPEC 3, rule 2: "At most 10 units of the same product (the quantity of the line, not of one request). Above that: 422."
- **Steps to reproduce:**
  - _6 units, then 5 units on the same line_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 7, "quantity": 6}'`
  4. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 7, "quantity": 5}'`
  - _Second case: limit and stock both broken_
  5. `curl -X POST http://localhost:3002/reset`
  6. `curl -X POST http://localhost:3002/carts`
  7. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 4, "quantity": 2}'`
  8. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 4, "quantity": 9}'`
- **Expected result:** The second request returns 422. The line stays at 6 units.
- **Actual result:**
  - `POST /carts/c1/items` returned **200**: `{"id": "c1", "status": "open", "promoCodes": [], "items": [{"productId": 7, "name": "Tea Towel", "unitPriceCents": 799, "quantity": 11, "lineTotalCents": 8789}], "subtotalCents": 8789, "discountCents": 0, "shippingCents": 0, "totalCents": 8789}`
  - `POST /carts/c1/items` returned **409**: `{"error": "Not enough stock"}`
  - In short: The second request returns 200. The line holds 11 units (lineTotalCents 8789).
- **Notes:** Always. Detected by `stc-item-14`, `stc-amb-02`. Impact: The business limit can be bypassed by adding in several steps. Nothing breaks and the effect is bounded by the stock. Possible cause: The limit is compared with the quantity of the request, not with the sum of the line. PATCH applies the limit correctly (422 at 11 units). Related: BUG-01 (same handler).

---

## BUG-07: Free shipping is decided before the discount instead of after

- **Severity / Priority:** Major / 7. A pricing rule is broken with limited damage per order. Priority 7.
- **Specification reference:** SPEC 4, rule 3: "Shipping is 490 unless the subtotal after discount is 5000 or more."
- **Steps to reproduce:**
  - _WELCOME10 on a 5240 cart_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": 2}'`
  4. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 2, "quantity": 1}'`
  5. `curl -X POST http://localhost:3002/carts/c1/promo -H "Content-Type: application/json" -d '{"code": "WELCOME10"}'`
- **Expected result:** discountCents 524, so 4716 after discount. shippingCents 490, totalCents 5206.
- **Actual result:**
  - `POST /carts/c1/promo` returned **200**: `{"id": "c1", "status": "open", "promoCodes": ["WELCOME10"], "items": [{"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": 2, "lineTotalCents": 3990}, {"productId": 2, "name": "Ceramic Mug", "unitPriceCents": 1250, "quantity": 1, "lineTotalCents": 1250}], "subtotalCents": 5240, "discountCents": 524, "shippingCents": 0, "totalCents": 4716}`
  - In short: discountCents 524, shippingCents 0, totalCents 4716.
- **Notes:** Always. Detected by `stc-tot-05`. Impact: The shop loses 490 cents on carts close to the threshold and the customer is shown a wrong total. It applies to any discount that takes a cart from 5000 or more to under 5000. Possible cause: The shipping threshold is tested on the subtotal before the discount. Related: BUG-09 (rounding of the same discount).

---

## BUG-08: Adding exactly the available stock is refused

- **Severity / Priority:** Major / 8. A rule is broken but a workaround exists. Priority 8.
- **Specification reference:** SPEC 3, rule 3: "Exactly the stock is allowed. Above: 409."
- **Steps to reproduce:**
  - _Add exactly the stock_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 4, "quantity": 3}'`
  - _Workaround: add 1 then change to 3_
  4. `curl -X POST http://localhost:3002/reset`
  5. `curl -X POST http://localhost:3002/carts`
  6. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 4, "quantity": 1}'`
  7. `curl -X PATCH http://localhost:3002/carts/c1/items/4 -H "Content-Type: application/json" -d '{"quantity": 3}'`
- **Expected result:** 201, and the line holds 3 units.
- **Actual result:**
  - `POST /carts/c1/items` returned **409**: `{"error": "Not enough stock"}`
  - In short: 409 {"error":"Not enough stock"}.
- **Notes:** Always. Detected by `stc-stock-01`. Impact: Customers cannot buy the last units in one step. The rule is inconsistent between POST and PATCH. No wrong data is stored. Possible cause: The add handler compares with >= instead of >. Related: BUG-02 (setup).

---

## BUG-09: Percentage discounts are rounded down instead of half up

- **Severity / Priority:** Minor / 9. A small inconsistency in money. Priority 9.
- **Specification reference:** SPEC 4, rule 2: "A percentage is rounded half up to the nearest cent."
- **Steps to reproduce:**
  - _WELCOME10 on 1995_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": 1}'`
  4. `curl -X POST http://localhost:3002/carts/c1/promo -H "Content-Type: application/json" -d '{"code": "WELCOME10"}'`
- **Expected result:** discountCents 200, totalCents 2285.
- **Actual result:**
  - `POST /carts/c1/promo` returned **200**: `{"id": "c1", "status": "open", "promoCodes": ["WELCOME10"], "items": [{"productId": 1, "name": "Amber Candle", "unitPriceCents": 1995, "quantity": 1, "lineTotalCents": 1995}], "subtotalCents": 1995, "discountCents": 199, "shippingCents": 490, "totalCents": 2286}`
  - In short: discountCents 199, totalCents 2286.
- **Notes:** Always when the discount ends in .5. Detected by `stc-promo-02`, `stc-promo-18 (skipped, needs frozen clock)`. Impact: The error is at most 1 cent per order, always against the customer. With a frozen clock on 1 August 2026, SUMMER25 on 3990 gives 997 instead of 998 for the same reason. Possible cause: Math.floor is used instead of rounding half up. Related: BUG-07.

---

## BUG-10: An expired promo code returns 404 instead of 422

- **Severity / Priority:** Minor / 10. A small inconsistency, the discount is correctly refused. Priority 10.
- **Specification reference:** SPEC 5: "An expired code is refused (422). An unknown code gives 404."
- **Steps to reproduce:**
  - _SUMMER25 after its end date_
  1. `curl -X POST http://localhost:3002/reset`
  2. `curl -X POST http://localhost:3002/carts`
  3. `curl -X POST http://localhost:3002/carts/c1/items -H "Content-Type: application/json" -d '{"productId": 1, "quantity": 2}'`
  4. `curl -X POST http://localhost:3002/carts/c1/promo -H "Content-Type: application/json" -d '{"code": "SUMMER25"}'`
- **Expected result:** 422 with a message saying the code is expired.
- **Actual result:**
  - `POST /carts/c1/promo` returned **404**: `{"error": "Unknown promo code"}`
  - In short: 404 {"error":"Unknown promo code"}.
- **Notes:** Always. Detected by `stc-promo-17`, `stc-promo-20 (skipped, needs frozen clock)`. Impact: The code is refused as it should be, only the status and the message are wrong. The client cannot tell the customer that the code expired. Also observed with a frozen clock at 2026-08-31T23:59:59.500Z: the code is refused (404) although the spec says 31 August is included; the server limit is 23:59:59.000Z, so the last second of the day is lost (not covered by an automated test). Possible cause: The expiry check returns the same not-found response as an unknown code, and its end-of-day limit is 23:59:59.000Z. Related: none.

---

## Questions answered by the spec author

- Limit and stock both broken: the limit (422) wins. `stc-amb-02` is therefore part of BUG-06.
- Promo codes are not case-sensitive. Spaces around a code are not specified: I expect them to be ignored.
- FIVEOFF below 3000 after it was applied: not specified. I expect the code to stay with a discount of 0, because SPEC section 5 says the totals always describe the cart as it is now (BUG-03).
- SUMMER25 cannot be tested as valid on this server (real clock): only the expired case is tested.
