/**
 * Lightbox Image Viewer System for Ian Ryu Portfolio
 * Enlarges photos and figures with navigation, keyboard controls, and captions.
 */
(function() {
  'use strict';

  function initLightbox() {
    // Find all eligible images on the page
    var candidateImages = Array.from(document.querySelectorAll('img'));
    var images = candidateImages.filter(function(img) {
      // Exclude small tech icons and tiny graphics
      if (img.closest('.stack-icon') || img.closest('.social-links')) return false;
      if (img.classList.contains('lightbox-image')) return false;
      return true;
    });

    if (images.length === 0) return;

    var currentIndex = 0;
    var previouslyFocusedElement = null;

    // Create Modal Elements
    var overlay = document.createElement('div');
    overlay.className = 'lightbox-overlay';
    overlay.id = 'lightboxOverlay';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');
    overlay.setAttribute('aria-label', 'Image preview');
    overlay.setAttribute('aria-hidden', 'true');

    overlay.innerHTML = [
      '<div class="lightbox-header">',
      '  <div class="lightbox-counter mono" id="lightboxCounter"></div>',
      '  <div class="lightbox-actions">',
      '    <button class="lightbox-btn" id="lightboxClose" aria-label="Close preview" title="Close (Esc)">',
      '      <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>',
      '    </button>',
      '  </div>',
      '</div>',
      '<button class="lightbox-nav-btn lightbox-prev" id="lightboxPrev" aria-label="Previous image" title="Previous (Left Arrow)">',
      '  <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 18 9 12 15 6"></polyline></svg>',
      '</button>',
      '<button class="lightbox-nav-btn lightbox-next" id="lightboxNext" aria-label="Next image" title="Next (Right Arrow)">',
      '  <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"></polyline></svg>',
      '</button>',
      '<div class="lightbox-stage" id="lightboxStage">',
      '  <div class="lightbox-image-container" id="lightboxImgContainer">',
      '    <img class="lightbox-image" id="lightboxImage" src="" alt="">',
      '  </div>',
      '</div>',
      '<div class="lightbox-footer">',
      '  <div class="lightbox-caption mono" id="lightboxCaption"></div>',
      '  <div class="lightbox-hints mono">',
      '    <span><kbd>ESC</kbd> Close</span>',
      '    <span class="lightbox-nav-hint"><kbd>←</kbd> <kbd>→</kbd> Navigate</span>',
      '  </div>',
      '</div>'
    ].join('');

    document.body.appendChild(overlay);

    var imgEl = document.getElementById('lightboxImage');
    var captionEl = document.getElementById('lightboxCaption');
    var counterEl = document.getElementById('lightboxCounter');
    var closeBtn = document.getElementById('lightboxClose');
    var prevBtn = document.getElementById('lightboxPrev');
    var nextBtn = document.getElementById('lightboxNext');
    var navHint = overlay.querySelector('.lightbox-nav-hint');

    function getCaption(img) {
      if (img.getAttribute('data-caption')) {
        return img.getAttribute('data-caption').trim();
      }
      var figure = img.closest('figure');
      if (figure) {
        var figcap = figure.querySelector('figcaption');
        if (figcap && figcap.textContent.trim()) {
          return figcap.textContent.trim();
        }
      }
      return '';
    }

    function showImage(index) {
      if (index < 0) index = images.length - 1;
      if (index >= images.length) index = 0;
      currentIndex = index;

      var targetImg = images[currentIndex];

      imgEl.style.opacity = '0';
      imgEl.src = targetImg.currentSrc || targetImg.src;
      imgEl.alt = targetImg.alt || 'Enlarged photo';

      imgEl.onload = function() {
        imgEl.style.opacity = '1';
      };

      var caption = getCaption(targetImg);
      captionEl.textContent = caption;
      captionEl.style.display = caption ? 'block' : 'none';

      if (images.length > 1) {
        counterEl.textContent = (currentIndex + 1) + ' / ' + images.length;
        prevBtn.style.display = 'flex';
        nextBtn.style.display = 'flex';
        if (navHint) navHint.style.display = 'inline-block';
      } else {
        counterEl.textContent = '';
        prevBtn.style.display = 'none';
        nextBtn.style.display = 'none';
        if (navHint) navHint.style.display = 'none';
      }
    }

    function openLightbox(index) {
      previouslyFocusedElement = document.activeElement;
      showImage(index);
      overlay.classList.add('active');
      overlay.setAttribute('aria-hidden', 'false');
      document.body.classList.add('lightbox-open');
      closeBtn.focus();
    }

    function closeLightbox() {
      overlay.classList.remove('active');
      overlay.setAttribute('aria-hidden', 'true');
      document.body.classList.remove('lightbox-open');
      imgEl.src = '';
      if (previouslyFocusedElement && typeof previouslyFocusedElement.focus === 'function') {
        previouslyFocusedElement.focus();
      }
    }

    // Bind click and accessibility attributes to each image
    images.forEach(function(img, idx) {
      img.classList.add('lightbox-trigger');
      img.setAttribute('tabindex', '0');
      img.setAttribute('role', 'button');
      var cap = getCaption(img);
      img.setAttribute('aria-label', cap ? 'View photo: ' + cap : 'Click to view larger image');
      img.setAttribute('title', 'Click to view larger');

      function handleTrigger(e) {
        e.preventDefault();
        e.stopPropagation();
        openLightbox(idx);
      }

      img.addEventListener('click', handleTrigger);
      img.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' || e.key === ' ') {
          handleTrigger(e);
        }
      });
    });

    // Control event listeners
    closeBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      closeLightbox();
    });

    prevBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      showImage(currentIndex - 1);
    });

    nextBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      showImage(currentIndex + 1);
    });

    // Close when clicking stage background (outside image)
    overlay.addEventListener('click', function(e) {
      if (e.target === overlay || e.target === document.getElementById('lightboxStage')) {
        closeLightbox();
      }
    });

    // Keyboard Shortcuts
    document.addEventListener('keydown', function(e) {
      if (!overlay.classList.contains('active')) return;

      if (e.key === 'Escape') {
        e.preventDefault();
        closeLightbox();
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        showImage(currentIndex - 1);
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        showImage(currentIndex + 1);
      }
    });

    // Mobile touch gestures (Swipe support)
    var touchStartX = 0;
    var touchStartY = 0;
    overlay.addEventListener('touchstart', function(e) {
      if (e.touches.length === 1) {
        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
      }
    }, { passive: true });

    overlay.addEventListener('touchend', function(e) {
      if (e.changedTouches.length !== 1) return;
      var touchEndX = e.changedTouches[0].clientX;
      var touchEndY = e.changedTouches[0].clientY;
      var diffX = touchEndX - touchStartX;
      var diffY = touchEndY - touchStartY;

      if (Math.abs(diffX) > 45 && Math.abs(diffX) > Math.abs(diffY)) {
        if (diffX > 0) {
          showImage(currentIndex - 1);
        } else {
          showImage(currentIndex + 1);
        }
      } else if (diffY > 80 && Math.abs(diffY) > Math.abs(diffX)) {
        closeLightbox();
      }
    }, { passive: true });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLightbox);
  } else {
    initLightbox();
  }
})();
