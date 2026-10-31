// All pricing of the shop. Money is whole cents. One global: Pricing.
var Pricing = (function () {
  // lineSaving(line, promotion): cents saved on a basket line by one promotion.
  function lineSaving(line, promotion) {
    if (promotion.kind === "percent" && promotion.category === line.category) {
      return Math.round(line.price * line.quantity * promotion.percent / 100);
    }
    return 0;
  }

  // price(basket, promotions, date): each line's price and saving, the total and the saving.
  // A basket line is { name, category, price, quantity }; price is cents per unit.
  function price(basket, promotions, date) {
    var lines = [];
    var total = 0;
    var saving = 0;
    basket.forEach(function (line) {
      var saved = 0;
      promotions.forEach(function (promotion) {
        if (saved === 0) {
          saved = lineSaving(line, promotion);
        }
      });
      var charged = line.price * line.quantity - saved;
      lines.push({ name: line.name, price: charged, saving: saved });
      total += charged;
      saving += saved;
    });
    return { lines: lines, total: total, saving: saving };
  }

  return { price: price };
})();
