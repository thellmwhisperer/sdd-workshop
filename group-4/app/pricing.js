// All pricing of the shop. Money is whole cents. A basket line is
// { name, category, price, quantity }; a promotion is { kind, category, ... }.
var Pricing = (function () {
  // saving(line, promotion): cents saved on the whole line by one promotion.
  function saving(line, promotion, date) {
    if (promotion.start && date < promotion.start) return 0;
    if (promotion.end && date > promotion.end) return 0;
    if (promotion.kind === "percent" && promotion.category === line.category) {
      return Math.round(line.price * line.quantity * promotion.percent / 100);
    }
    if (promotion.kind === "second half" && promotion.category === line.category) {
      return Math.floor(line.quantity / 2) * Math.round(line.price / 2);
    }
    if ((promotion.kind === "three for two" || promotion.kind === "three-for-two") &&
        promotion.category === line.category) {
      return Math.floor(line.quantity / 3) * line.price;
    }
    return 0;
  }

  // price(basket, promotions, date): the price of each line, the total and the saving.
  function price(basket, promotions, date) {
    var lines = basket.map(function (line) {
      var saved = 0;
      for (var i = 0; i < promotions.length; i++) {
        var candidate = saving(line, promotions[i], date);
        if (candidate > saved) saved = candidate;
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
