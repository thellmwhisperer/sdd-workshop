// The rules of the shop checkout. A plain script: it defines one global, Checkout, and
// never touches the page. Every amount is a whole number of cents, VAT included.
var Checkout = (function () {
  // newBasket(): an empty basket.
  function newBasket() {
    return { lines: [] };
  }

  // add(basket, product): adds one product; a product already there raises its quantity.
  function add(basket, product) {
    for (var i = 0; i < basket.lines.length; i++) {
      var line = basket.lines[i];
      if (line.name === product.name) {
        line.quantity += 1;
        line.amount += product.price;
        return basket;
      }
    }
    basket.lines.push({ name: product.name, quantity: 1, amount: product.price });
    return basket;
  }

  // remove(basket, name): removes the line of that product.
  function remove(basket, name) {
    basket.lines = basket.lines.filter(function (line) {
      return line.name !== name;
    });
    return basket;
  }

  // total(basket): the sum of the lines, in cents.
  function total(basket) {
    var sum = 0;
    for (var i = 0; i < basket.lines.length; i++) {
      sum += basket.lines[i].amount;
    }
    return sum;
  }

  // money(cents): the amount with two decimals, for example "60.00" or "-2.83".
  function money(cents) {
    var sign = cents < 0 ? "-" : "";
    var abs = Math.abs(cents);
    var rest = abs % 100;
    return sign + Math.floor(abs / 100) + "." + (rest < 10 ? "0" : "") + rest;
  }

  return { newBasket: newBasket, add: add, remove: remove, total: total, money: money };
})();
