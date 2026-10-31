// The receipt: lines of text. The savings come as one total line at the bottom, only when
// the customer saved something. Prices come from Pricing.
var Receipt = (function () {
  // euros(cents): "80.00 €".
  function euros(cents) {
    return (cents / 100).toFixed(2) + " €";
  }

  // make(items, promotions, date): items are { product, quantity }, product a key of Products.
  function make(items, promotions, date) {
    var basket = items.map(function (item) {
      var product = Products[item.product];
      return { name: product.name, category: product.category, price: product.price, quantity: item.quantity };
    });
    var priced = Pricing.price(basket, promotions, date);
    var out = priced.lines.map(function (line, i) {
      return basket[i].quantity + " x " + line.name + " " + euros(line.price);
    });
    out.push("Total " + euros(priced.total));
    if (priced.saving > 0) out.push("You saved " + euros(priced.saving));
    return out;
  }

  return { make: make };
})();
