# Password-protecting this site with a login page

This site now has a simple built-in login page — no special hosting
features needed. It works on literally any static host: Cloudflare Pages/
Workers, Netlify, GitHub Pages, anywhere.

## How it works
- `login.html` — the password screen.
- `auth-guard.js` — loaded first thing on every other page. If you haven't
  logged in yet, it immediately redirects you to `login.html`.
- Once you enter the correct password, it's remembered in your browser
  (`localStorage`) so you won't be asked again on that device/browser.

## Deploying
Just push/upload the whole folder to whatever host you're using — same as
before, nothing special to configure. No environment variables, no
Functions, no Workers config needed.

## The password
The current password is set to **Ian12345**. It isn't stored anywhere in
plain text in the code — only a SHA-256 hash of it, inside `login.html` and
`auth-guard.js` (`CORRECT_HASH`).

### To change the password later
1. Compute the new SHA-256 hash of your new password. Easiest way: ask me
   to update it, or run this in a terminal:
   ```
   echo -n "your-new-password" | shasum -a 256
   ```
   (On Windows: `certutil -hashfile file.txt SHA256`, or just ask me.)
2. Replace the `CORRECT_HASH` value in **both** `login.html` and
   `auth-guard.js` with the new hash.
3. Re-deploy.

## Important limits of this approach
This is a light deterrent, not real security:
- It keeps out casual visitors, search engines, and people just browsing
  around — good enough for "don't want this showing up publicly."
- It does **not** stop someone determined: the raw HTML/images are still
  technically downloadable by anyone who knows how to view page source or
  fetch the files directly by URL. There's no server checking the password
  before handing out files — the check happens in the visitor's browser.
- Don't use this to protect anything truly sensitive (financial info,
  private documents, etc.). For that, you'd want a real server-side gate
  (like the Cloudflare Worker version discussed earlier).

## Logging out / testing as a new visitor
Open your browser's dev tools → Application/Storage tab → clear
`localStorage` for the site, or just open the site in a private/incognito
window.
