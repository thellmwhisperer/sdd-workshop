// All pricing of the shop. Money is whole cents. A basket line is
// { name, category, price, quantity }; a promotion is { kind, category, ... }.
var Pricing = (function () {
  // saving(line, promotion): cents saved on the whole line by one promotion.
  function saving(line, promotion) {
    if (promotion.kind === "percent" && promotion.category === line.category) {
      return Math.round(line.price * line.quantity * promotion.percent / 100);
    }
    if (promotion.kind === "second half" && promotion.category === line.category) {
      return Math.floor(line.quantity / 2) * Math.round(line.price / 2);
    }
    return 0;
  }

  // price(basket, promotions, date): the price of each line, the total and the saving.
  function price(basket, promotions, date) {
    var lines = basket.map(function (line) {
      var saved = 0;
      for (var i = 0; i < promotions.length && saved === 0; i++) {
        saved = saving(line, promotions[i]);
      }
      return { name: line.name, price: line.price * line.quantity - saved, saving: saved };
    });
    var total = 0;
    var savedTotal = 0;
    lines.forEach(function (line) {
      total += line.price;
      savedTotal += line.saving;
    });
    return { lines: lines, total: total, saving: savedTotal };
  }

  return { price: price };
})();
