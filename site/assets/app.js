// Chuyển mục trong cửa sổ minh hoạ.
(function () {
  "use strict";

  var items = document.querySelectorAll(".nav-item[data-pane]");
  var panes = document.querySelectorAll(".pane");

  function show(name) {
    items.forEach(function (item) {
      var active = item.dataset.pane === name;
      item.classList.toggle("is-active", active);
      item.setAttribute("aria-pressed", active ? "true" : "false");
    });
    panes.forEach(function (pane) {
      pane.classList.toggle("is-shown", pane.id === "pane-" + name);
    });
  }

  items.forEach(function (item) {
    item.setAttribute("aria-pressed", item.classList.contains("is-active") ? "true" : "false");
    item.addEventListener("click", function () {
      show(item.dataset.pane);
    });
  });
})();
