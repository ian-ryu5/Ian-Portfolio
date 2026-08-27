/* ---------------------------------------------------------------------------
   Simple session gate for the portfolio.

   IMPORTANT — what this is and is not:
   This is a soft gate. It keeps casual visitors and search engines out of the
   site, but it is NOT real security. Everything needed to open the site is
   delivered to the browser, so anyone determined enough can bypass it by
   reading the page source or disabling JavaScript. Do not put anything
   genuinely confidential behind it.

   The password is stored as a SHA-256 hash rather than plain text, so it is
   not simply readable in the source, but a short password can still be
   brute-forced offline. For real protection use a host with server-side auth
   (e.g. Cloudflare Access).
--------------------------------------------------------------------------- */
(function () {
  var SESSION_KEY = 'ianryu_portfolio_unlocked';

  // Root-relative prefix, so this works from / and from /projects/
  function prefix() {
    return window.location.pathname.indexOf('/projects/') !== -1 ? '../' : '';
  }

  // Already unlocked for this browser session -> let the page render.
  try {
    if (window.sessionStorage.getItem(SESSION_KEY) === '1') {
      document.documentElement.classList.remove('gated');
      return;
    }
  } catch (e) {
    // sessionStorage blocked (private mode / cookies disabled). Fail open
    // rather than locking the visitor out of a site with nothing secret in it.
    document.documentElement.classList.remove('gated');
    return;
  }

  // Not unlocked -> send to the login page, remembering where they were headed
  // so they land back on the right page afterwards.
  var here = window.location.pathname.split('/').pop() || 'index.html';
  var dest = window.location.pathname.indexOf('/projects/') !== -1
    ? 'projects/' + here
    : here;

  try {
    window.sessionStorage.setItem('ianryu_portfolio_redirect', dest + window.location.hash);
  } catch (e) { /* non-fatal */ }

  window.location.replace(prefix() + 'login.html');
})();
