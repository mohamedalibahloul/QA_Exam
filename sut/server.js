// Mock "Maison Lumen" cart and promo-code API for the QA case study. Node.js 18+, no dependency.
//   node server.js            (listens on http://localhost:3002, or PORT=xxxx node server.js)
// The written specification is SPEC.md: it is the reference. This file is the system under test.
// Data lives in memory. POST /reset puts everything back to the initial state (handy between tests).
const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = Number(process.env.PORT || 3002);
const MAX_PER_LINE = 10;
const SHIPPING_CENTS = 490;
const FREE_SHIPPING_FROM_CENTS = 5000;
const PROMOS = {
  WELCOME10: { kind: "percent", value: 10, discount: true },
  FIVEOFF: { kind: "fixed", value: 500, minCents: 3000, discount: true },
  SUMMER25: { kind: "percent", value: 25, discount: true, expiresAt: Date.parse("2026-08-31T23:59:59Z") },
  FREESHIP: { kind: "shipping", discount: false },
};

let products, carts, orders, counters;
function reset() {
  products = JSON.parse(fs.readFileSync(path.join(__dirname, "products.json"), "utf8"));
  carts = new Map();
  orders = new Map();
  counters = { cart: 0, order: 0 };
}
reset();

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function percentOf(cents, pct) {
  return Math.floor((cents * pct) / 100);
}

function totals(cart) {
  const items = cart.items.map((l) => {
    const p = products.find((x) => x.id === l.productId);
    return { productId: l.productId, name: p.name, unitPriceCents: p.priceCents, quantity: l.quantity, lineTotalCents: p.priceCents * l.quantity };
  });
  const subtotalCents = items.reduce((s, l) => s + l.lineTotalCents, 0);
  let discountCents = 0;
  for (const code of cart.promoCodes) {
    const promo = PROMOS[code];
    if (promo.kind === "percent") discountCents += percentOf(subtotalCents, promo.value);
    if (promo.kind === "fixed") discountCents += promo.value;
  }
  discountCents = Math.min(discountCents, Math.max(subtotalCents, 0));
  const freeShipping = cart.promoCodes.includes("FREESHIP") || subtotalCents >= FREE_SHIPPING_FROM_CENTS || items.length === 0;
  const shippingCents = freeShipping ? 0 : SHIPPING_CENTS;
  return { items, subtotalCents, discountCents, shippingCents, totalCents: subtotalCents - discountCents + shippingCents };
}

function cartView(cart) {
  return { id: cart.id, status: cart.status, promoCodes: [...cart.promoCodes], ...totals(cart) };
}

function readBody(req) {
  return new Promise((resolve) => {
    let raw = "";
    req.on("data", (c) => (raw += c));
    req.on("end", () => {
      if (!raw) return resolve({});
      try { resolve(JSON.parse(raw)); } catch { resolve(null); }
    });
  });
}

function send(res, code, body) {
  res.writeHead(code, { "Content-Type": "application/json; charset=utf-8" });
  res.end(body === undefined ? "" : JSON.stringify(body));
}
const fail = (res, code, message) => send(res, code, { error: message });

async function handle(req, res) {
  const url = new URL(req.url, "http://localhost");
  const p = url.pathname.replace(/\/+$/, "") || "/";
  const method = req.method;
  let m;

  if (p === "/reset" && method === "POST") { reset(); return send(res, 200, { ok: true }); }

  // ---- products
  if (p === "/products" && method === "GET") return send(res, 200, products);
  if ((m = p.match(/^\/products\/(\d+)$/)) && method === "GET") {
    const prod = products.find((x) => x.id === Number(m[1]));
    return prod ? send(res, 200, prod) : fail(res, 404, "Product not found");
  }

  // ---- carts
  if (p === "/carts" && method === "POST") {
    const cart = { id: "c" + ++counters.cart, status: "open", items: [], promoCodes: [] };
    carts.set(cart.id, cart);
    return send(res, 201, cartView(cart));
  }
  if ((m = p.match(/^\/carts\/([^/]+)(?:\/(items|promo|checkout))?(?:\/(\d+))?$/))) {
    const cart = carts.get(m[1]);
    if (!cart) return fail(res, 404, "Cart not found");
    const sub = m[2];
    const lineId = m[3] === undefined ? null : Number(m[3]);

    if (!sub && method === "GET") return send(res, 200, cartView(cart));

    if (sub === "items" && lineId === null && method === "POST") {
      const body = await readBody(req);
      if (body === null) return fail(res, 400, "Invalid JSON");
      if (cart.status !== "open") return fail(res, 409, "Cart is already checked out");
      if (!Number.isInteger(body.productId)) return fail(res, 400, "productId must be an integer");
      const product = products.find((x) => x.id === body.productId);
      if (!product) return fail(res, 404, "Product not found");
      const q = body.quantity;
      if (typeof q !== "number") return fail(res, 400, "quantity must be a number");
      if (q > MAX_PER_LINE) return fail(res, 422, "At most " + MAX_PER_LINE + " units of a product per cart");
      const line = cart.items.find((l) => l.productId === product.id);
      const newQty = (line ? line.quantity : 0) + q;
      if (newQty >= product.stock) return fail(res, 409, "Not enough stock");
      if (line) line.quantity = newQty;
      else cart.items.push({ productId: product.id, quantity: q });
      return send(res, line ? 200 : 201, cartView(cart));
    }

    if (sub === "items" && lineId !== null && method === "PATCH") {
      const body = await readBody(req);
      if (body === null) return fail(res, 400, "Invalid JSON");
      if (cart.status !== "open") return fail(res, 409, "Cart is already checked out");
      const line = cart.items.find((l) => l.productId === lineId);
      if (!line) return fail(res, 404, "Product not in cart");
      const q = body.quantity;
      if (!Number.isInteger(q) || q < 0) return fail(res, 400, "quantity must be an integer >= 0");
      if (q === 0) {
        cart.items = cart.items.filter((l) => l !== line);
        return send(res, 200, cartView(cart));
      }
      if (q > MAX_PER_LINE) return fail(res, 422, "At most " + MAX_PER_LINE + " units of a product per cart");
      const product = products.find((x) => x.id === lineId);
      if (q > product.stock) return fail(res, 409, "Not enough stock");
      line.quantity = q;
      return send(res, 200, cartView(cart));
    }

    if (sub === "items" && lineId !== null && method === "DELETE") {
      if (cart.status !== "open") return fail(res, 409, "Cart is already checked out");
      const line = cart.items.find((l) => l.productId === lineId);
      if (!line) return fail(res, 404, "Product not in cart");
      cart.items = cart.items.filter((l) => l !== line);
      return send(res, 200, cartView(cart));
    }

    if (sub === "promo" && lineId === null && method === "POST") {
      const body = await readBody(req);
      if (body === null) return fail(res, 400, "Invalid JSON");
      if (cart.status !== "open") return fail(res, 409, "Cart is already checked out");
      if (typeof body.code !== "string" || body.code.trim() === "") return fail(res, 400, "code must be a non-empty string");
      const code = body.code.trim().toUpperCase();
      const promo = PROMOS[code];
      if (!promo) return fail(res, 404, "Unknown promo code");
      if (promo.expiresAt && Date.now() > promo.expiresAt) return fail(res, 404, "Unknown promo code");
      if (cart.promoCodes.includes(code)) return send(res, 200, cartView(cart));
      if (promo.minCents && totals(cart).subtotalCents < promo.minCents) {
        return fail(res, 422, "Minimum subtotal not reached for " + code);
      }
      cart.promoCodes.push(code);
      return send(res, 200, cartView(cart));
    }

    if (sub === "checkout" && lineId === null && method === "POST") {
      if (cart.status !== "open") return fail(res, 409, "Cart is already checked out");
      if (cart.items.length === 0) return fail(res, 422, "Cart is empty");
      for (const l of cart.items) {
        const product = products.find((x) => x.id === l.productId);
        if (l.quantity > product.stock) return fail(res, 409, "Not enough stock for product " + product.id);
      }
      await sleep(25); // payment pre-authorisation
      for (const l of cart.items) {
        const product = products.find((x) => x.id === l.productId);
        product.stock -= l.quantity;
      }
      const order = { id: "o" + ++counters.order, cartId: cart.id, status: "pending_payment", promoCodes: [...cart.promoCodes], ...totals(cart) };
      orders.set(order.id, order);
      cart.status = "checked_out";
      return send(res, 201, order);
    }

    return fail(res, 405, "Method not allowed");
  }

  // ---- orders
  if ((m = p.match(/^\/orders\/([^/]+)(?:\/(pay|ship|cancel))?$/))) {
    const order = orders.get(m[1]);
    if (!order) return fail(res, 404, "Order not found");
    const action = m[2];
    if (!action && method === "GET") return send(res, 200, order);
    if (!action || method !== "POST") return fail(res, 405, "Method not allowed");

    if (action === "pay") {
      if (order.status !== "pending_payment") return fail(res, 409, "Order cannot be paid from status " + order.status);
      order.status = "paid";
      return send(res, 200, order);
    }
    if (action === "ship") {
      if (order.status !== "paid" && order.status !== "pending_payment") return fail(res, 409, "Order cannot be shipped from status " + order.status);
      order.status = "shipped";
      return send(res, 200, order);
    }
    if (action === "cancel") {
      if (order.status !== "pending_payment" && order.status !== "paid") return fail(res, 409, "Order cannot be cancelled from status " + order.status);
      for (const l of order.items) {
        const product = products.find((x) => x.id === l.productId);
        product.stock += l.quantity;
      }
      order.status = "cancelled";
      return send(res, 200, order);
    }
  }

  return fail(res, 404, "Not found");
}

const server = http.createServer((req, res) => {
  handle(req, res).catch(() => fail(res, 500, "Internal error"));
});
server.listen(PORT, () => console.log("Maison Lumen API on http://localhost:" + PORT));
