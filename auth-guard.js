// Auth guard: include this as the FIRST thing in <head>, before any other
// content, on every page you want password-protected.
//
// It runs synchronously (this file is loaded without `defer`/`async`) so it
// checks login status before the rest of the page renders. If the visitor
// hasn't logged in, it immediately redirects to login.html.
//
// This is a client-side check: fine for keeping casual visitors and search
// engines out of a personal portfolio, but someone who really wants to
// could still find the page source. Don't use this to gate anything
// sensitive.
(function () {
  const CORRECT_HASH = "761d1f27b1b2df5b4d99409107b191b1e6d79a7e9c7bcc4330e1bb8722404e8d";
  const SESSION_KEY = "site_auth";

  const stored = localStorage.getItem(SESSION_KEY);
  if (stored !== CORRECT_HASH) {
    const segments = window.location.pathname.split("/").filter(Boolean);
    const here = segments.length ? segments.join("/") : "index.html";
    const depth = segments.length;
    // Figure out the relative path back to login.html depending on how
    // deep this page is nested (e.g. /projects/ev.html needs "../login.html").
    const prefix = depth > 1 ? "../".repeat(depth - 1) : "";
    window.location.replace(prefix + "login.html?redirect=" + encodeURIComponent(here));
  }
})();
