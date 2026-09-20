(function () {
  "use strict";

  /* ---------- contact modal ---------- */

  var dialog = document.getElementById("contact-modal");

  if (dialog) {
    var useNative = typeof dialog.showModal === "function";
    var openers = document.querySelectorAll("[data-open-contact]");
    var lastFocused = null;

    function openModal() {
      lastFocused = document.activeElement;
      if (useNative) {
        dialog.showModal();
      } else {
        // Fallback for browsers without native <dialog> support.
        dialog.setAttribute("open", "");
        dialog.classList.add("contact-modal--fallback");
        var first = dialog.querySelector("a[href], button");
        if (first) first.focus();
      }
    }

    function closeModal() {
      if (useNative) {
        dialog.close();
      } else {
        dialog.removeAttribute("open");
        dialog.classList.remove("contact-modal--fallback");
        if (lastFocused && typeof lastFocused.focus === "function") {
          lastFocused.focus();
        }
        lastFocused = null;
      }
    }

    openers.forEach(function (el) {
      el.addEventListener("click", openModal);
    });

    dialog.querySelectorAll("[data-close-contact]").forEach(function (el) {
      el.addEventListener("click", closeModal);
    });

    // Clicking the backdrop (outside the dialog box) closes it.
    dialog.addEventListener("click", function (event) {
      if (event.target !== dialog) return;
      var box = dialog.getBoundingClientRect();
      var outside =
        event.clientX < box.left ||
        event.clientX > box.right ||
        event.clientY < box.top ||
        event.clientY > box.bottom;
      if (outside) closeModal();
    });

    if (!useNative) {
      document.addEventListener("keydown", function (event) {
        if (event.key === "Escape" && dialog.hasAttribute("open")) {
          closeModal();
        }
      });
    }

    dialog.addEventListener("close", function () {
      if (lastFocused && typeof lastFocused.focus === "function") {
        lastFocused.focus();
      }
      lastFocused = null;
    });

    // Let the anchor inside the modal navigate, then close the dialog.
    dialog.querySelectorAll("a[href]").forEach(function (link) {
      link.addEventListener("click", function () {
        window.setTimeout(closeModal, 0);
      });
    });
  }

  /* ---------- reveal on scroll ---------- */

  var reduceMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)"
  ).matches;
  var revealables = document.querySelectorAll(".reveal");

  if (reduceMotion || !("IntersectionObserver" in window)) {
    revealables.forEach(function (el) {
      el.classList.add("is-visible");
    });
    return;
  }

  var observer = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { rootMargin: "0px 0px -8% 0px", threshold: 0.08 }
  );

  revealables.forEach(function (el) {
    observer.observe(el);
  });
})();
