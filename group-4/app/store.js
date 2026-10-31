// The promotions of the shop, saved in localStorage under one key.
// A promotion is { name, kind, category, percent, start, end }; dates are YYYY-MM-DD.
var Store = (function () {
  var KEY = "brisa.promotions";

  // list(): every saved promotion, in the order they were saved.
  function list() {
    var text = localStorage.getItem(KEY);
    return text ? JSON.parse(text) : [];
  }

  // validate(promotion): the messages of what is wrong; none when it can be saved.
  function validate(p) {
    var errors = [];
    if (!p.name || String(p.name).trim() === "") errors.push("The name is empty");
    if (!p.category || String(p.category).trim() === "") errors.push("The category is empty");
    if (p.kind === "percent") {
      var n = Number(p.percent);
      if (p.percent === "" || p.percent === null || p.percent === undefined ||
          isNaN(n) || n < 1 || n > 100) {
        errors.push("The percent must be between 1 and 100");
      }
    }
    if (p.start && p.end && p.end < p.start) errors.push("The end date is before the start date");
    return errors;
  }

  // add(promotion): saves it when valid; returns { ok, errors }.
  function add(p) {
    var errors = validate(p);
    if (errors.length > 0) return { ok: false, errors: errors };
    var all = list();
    all.push(p);
    localStorage.setItem(KEY, JSON.stringify(all));
    return { ok: true, errors: [] };
  }

  return { list: list, validate: validate, add: add };
})();
