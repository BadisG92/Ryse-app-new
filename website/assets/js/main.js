// =====================================================
// RYSE - Main JavaScript
// =====================================================

document.addEventListener('DOMContentLoaded', () => {
  // ===== MOBILE NAVIGATION TOGGLE =====
  const navToggle = document.getElementById('navToggle');
  const navMenu = document.getElementById('navMenu');

  if (navToggle && navMenu) {
    navToggle.addEventListener('click', () => {
      navMenu.classList.toggle('active');
      navToggle.textContent = navMenu.classList.contains('active') ? '✕' : '☰';
    });

    // Close menu when clicking on a link
    navMenu.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navMenu.classList.remove('active');
        navToggle.textContent = '☰';
      });
    });

    // Close menu when clicking outside
    document.addEventListener('click', (e) => {
      if (!navToggle.contains(e.target) && !navMenu.contains(e.target)) {
        navMenu.classList.remove('active');
        navToggle.textContent = '☰';
      }
    });
  }

  // ===== SMOOTH SCROLLING FOR ANCHOR LINKS =====
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      const href = this.getAttribute('href');

      // Skip empty anchors or just "#"
      if (href === '#' || href === '') return;

      const target = document.querySelector(href);
      if (target) {
        e.preventDefault();
        const navbarHeight = document.querySelector('.navbar').offsetHeight;
        const targetPosition = target.offsetTop - navbarHeight - 20;

        window.scrollTo({
          top: targetPosition,
          behavior: 'smooth'
        });
      }
    });
  });

  // ===== NAVBAR BACKGROUND ON SCROLL =====
  let lastScroll = 0;
  const navbar = document.querySelector('.navbar');

  window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset;

    // Add shadow when scrolled
    if (currentScroll > 50) {
      navbar.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.2)';
    } else {
      navbar.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
    }

    lastScroll = currentScroll;
  });

  // ===== INTERSECTION OBSERVER FOR FADE-IN ANIMATIONS =====
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = '1';
        entry.target.style.transform = 'translateY(0)';
      }
    });
  }, observerOptions);

  // Observe all fade-in elements
  document.querySelectorAll('.fade-in-up').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
    observer.observe(el);
  });

  // Observe feature cards
  document.querySelectorAll('.feature-card').forEach((card, index) => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(30px)';
    card.style.transition = `opacity 0.6s ease-out ${index * 0.1}s, transform 0.6s ease-out ${index * 0.1}s`;
    observer.observe(card);
  });

  // ===== COPY EMAIL ON CLICK =====
  document.querySelectorAll('a[href^="mailto:"]').forEach(link => {
    link.addEventListener('click', (e) => {
      const email = link.href.replace('mailto:', '').split('?')[0];

      // Copy to clipboard
      if (navigator.clipboard) {
        navigator.clipboard.writeText(email).then(() => {
          // Show temporary tooltip
          const tooltip = document.createElement('span');
          tooltip.textContent = 'Email copié !';
          tooltip.style.cssText = `
            position: absolute;
            background: #10B981;
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 0.5rem;
            font-size: 0.875rem;
            font-weight: 600;
            z-index: 9999;
            pointer-events: none;
            animation: fadeOut 2s ease-out forwards;
          `;

          // Position tooltip near the link
          const rect = link.getBoundingClientRect();
          tooltip.style.top = (rect.top + window.scrollY - 40) + 'px';
          tooltip.style.left = (rect.left + window.scrollX) + 'px';

          document.body.appendChild(tooltip);

          setTimeout(() => tooltip.remove(), 2000);
        }).catch(err => {
          console.error('Failed to copy email:', err);
        });
      }
    });
  });

  // ===== APP STORE BADGE TRACKING (Analytics placeholder) =====
  document.querySelectorAll('.app-badge, .navbar-cta, .btn-primary').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const action = e.target.textContent.trim();
      console.log('CTA clicked:', action);

      // TODO: Add analytics tracking here
      // Example: gtag('event', 'cta_click', { action: action });
    });
  });

  // ===== PERFORMANCE OPTIMIZATION: LAZY LOAD IMAGES =====
  if ('loading' in HTMLImageElement.prototype) {
    const images = document.querySelectorAll('img[loading="lazy"]');
    images.forEach(img => {
      img.src = img.dataset.src;
    });
  } else {
    // Fallback for browsers that don't support lazy loading
    const script = document.createElement('script');
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/lazysizes/5.3.2/lazysizes.min.js';
    document.body.appendChild(script);
  }

  // ===== EASTER EGG: Konami Code =====
  let konamiCode = [];
  const konamiSequence = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a'];

  document.addEventListener('keydown', (e) => {
    konamiCode.push(e.key);
    konamiCode = konamiCode.slice(-10);

    if (konamiCode.join('') === konamiSequence.join('')) {
      document.body.style.animation = 'rainbow 2s linear infinite';

      const style = document.createElement('style');
      style.textContent = `
        @keyframes rainbow {
          0% { filter: hue-rotate(0deg); }
          100% { filter: hue-rotate(360deg); }
        }
      `;
      document.head.appendChild(style);

      setTimeout(() => {
        document.body.style.animation = '';
        style.remove();
      }, 5000);

      console.log('🎉 Konami Code activated! You found the easter egg!');
    }
  });

  // ===== DETECT DARK MODE PREFERENCE =====
  if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
    console.log('User prefers dark mode - consider adding dark theme toggle in future');
    // TODO: Implement dark mode if needed
  }

  // ===== PERFORMANCE LOGGING =====
  if (window.performance) {
    window.addEventListener('load', () => {
      const perfData = window.performance.timing;
      const pageLoadTime = perfData.loadEventEnd - perfData.navigationStart;
      console.log(`Page fully loaded in ${pageLoadTime}ms`);

      // TODO: Send to analytics
    });
  }
});

// ===== UTILITY FUNCTIONS =====

/**
 * Debounce function to limit rapid function calls
 */
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

/**
 * Throttle function to limit function execution rate
 */
function throttle(func, limit) {
  let inThrottle;
  return function(...args) {
    if (!inThrottle) {
      func.apply(this, args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
}

// ===== EXPORT FOR USE IN OTHER SCRIPTS =====
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { debounce, throttle };
}
