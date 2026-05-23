/* ═══════════════════════════════════════════════
   NUSUK — Sacred Journey Platform
   Main JavaScript
   ═══════════════════════════════════════════════ */

'use strict';

// ─── Theme Manager ─────────────────────────────
const ThemeManager = {
  init() {
    const saved = localStorage.getItem('nusuk-theme') || 'light';
    document.documentElement.setAttribute('data-theme', saved);
    document.getElementById('themeToggle')?.addEventListener('click', () => this.toggle());
  },
  toggle() {
    const next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('nusuk-theme', next);
  }
};

// ─── Prayer Time Calculator ─────────────────────
// Pure JS implementation — no external library required
const PrayerCalc = {
  // Degrees-to-radians helpers
  DR: Math.PI / 180,
  RD: 180 / Math.PI,

  julianDate(y, m, d) {
    if (m <= 2) { y -= 1; m += 12; }
    const A = Math.floor(y / 100);
    const B = 2 - A + Math.floor(A / 4);
    return Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + d + B - 1524.5;
  },

  sunPosition(jd) {
    const D  = jd - 2451545.0;
    const g  = (357.529 + 0.98560028 * D) % 360;
    const q  = (280.459 + 0.98564736 * D) % 360;
    const L  = (q + 1.915 * Math.sin(g * this.DR) + 0.020 * Math.sin(2 * g * this.DR)) % 360;
    const e  = 23.439 - 0.00000036 * D;
    const RA = this.RD * Math.atan2(Math.cos(e * this.DR) * Math.sin(L * this.DR), Math.cos(L * this.DR)) / 15;
    const d  = this.RD * Math.asin(Math.sin(e * this.DR) * Math.sin(L * this.DR));
    const EqT = q / 15 - ((RA + 360) % 24);
    return { d, EqT };
  },

  // Time for a given angle below horizon
  timeForAngle(angle, lat, d, direction) {
    const val = (Math.cos(angle * this.DR) - Math.sin(lat * this.DR) * Math.sin(d * this.DR))
              / (Math.cos(lat * this.DR) * Math.cos(d * this.DR));
    if (Math.abs(val) > 1) return null; // never rises/sets
    const T = this.RD * Math.acos(val) / 15;
    return direction === 'rise' ? -T : T;
  },

  // Asr time (shadow factor = 1 for Shafi'i)
  asrTime(lat, d, shadowFactor) {
    const target = this.RD * Math.atan(1 / (shadowFactor + Math.tan(Math.abs(lat - d) * this.DR)));
    return this.timeForAngle(90 - target, lat, d, 'set');
  },

  compute(lat, lng, date) {
    const jd = this.julianDate(date.getFullYear(), date.getMonth() + 1, date.getDate());
    const { d, EqT } = this.sunPosition(jd);
    const tz = -date.getTimezoneOffset() / 60;
    const noon = 12 - lng / 15 - EqT + tz; // solar noon in local hours

    const toLocal = (offset) => offset !== null ? noon + offset : null;

    const fajrOff    = this.timeForAngle(107.5, lat, d, 'rise');   // MWL 18°
    const sunriseOff = this.timeForAngle(90.8333, lat, d, 'rise');
    const sunsetOff  = this.timeForAngle(90.8333, lat, d, 'set');
    const ishaOff    = this.timeForAngle(108.5, lat, d, 'set');    // MWL 17°
    const asrOff     = this.asrTime(lat, d, 1);

    return [
      { name: 'Fajr',    hour: toLocal(fajrOff) },
      { name: 'Sunrise', hour: toLocal(sunriseOff) },
      { name: 'Dhuhr',   hour: noon },
      { name: 'Asr',     hour: toLocal(asrOff) },
      { name: 'Maghrib', hour: toLocal(sunsetOff) },
      { name: 'Isha',    hour: toLocal(ishaOff) },
    ];
  }
};

// ─── Adhan Widget ───────────────────────────────
const AdhanWidget = {
  locs: {
    current: { lat: null, lng: null },
    makkah:  { lat: 21.3891, lng: 39.8579 },
    madinah: { lat: 24.4672, lng: 39.6150 },
  },
  activeTab: 'makkah',

  init() {
    if (!document.getElementById('adhanTabs')) return;

    // Tab clicks
    document.querySelectorAll('.adhan-tab').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.adhan-tab').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.activeTab = btn.dataset.loc;
        this.render(this.activeTab);
      });
    });

    // Try geolocation for "current"
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        pos => {
          this.locs.current.lat = pos.coords.latitude;
          this.locs.current.lng = pos.coords.longitude;
          if (this.activeTab === 'current') this.render('current');
        },
        () => {} // silently fail
      );
    }

    this.render(this.activeTab);

    // Refresh every minute
    setInterval(() => this.render(this.activeTab), 60_000);
  },

  render(key) {
    const container = document.getElementById('prayerTimesContainer');
    if (!container) return;

    let lat, lng;
    if (key === 'current') {
      if (!this.locs.current.lat) {
        container.innerHTML = `<p class="text-muted" style="font-size:.82rem;padding:.4rem 0">
          Enable location to see local prayer times.</p>`;
        return;
      }
      ({ lat, lng } = this.locs.current);
    } else {
      ({ lat, lng } = this.locs[key]);
    }

    const now    = new Date();
    const times  = PrayerCalc.compute(lat, lng, now);
    const nowH   = now.getHours() + now.getMinutes() / 60;

    // Find next prayer
    let nextName = null;
    for (const t of times) {
      if (t.hour !== null && t.hour > nowH) { nextName = t.name; break; }
    }

    const fmt = (h) => {
      if (h === null || isNaN(h)) return '--:--';
      let hrs = Math.floor(((h % 24) + 24) % 24);
      const mins = Math.round((h - Math.floor(h)) * 60);
      const ampm = hrs >= 12 ? 'PM' : 'AM';
      hrs = hrs % 12 || 12;
      return `${hrs}:${String(mins).padStart(2,'0')} ${ampm}`;
    };

    container.innerHTML = `
      <div class="prayer-times-grid">
        ${times.map(t => `
          <div class="prayer-time-item ${t.name === nextName ? 'next-prayer' : ''}">
            <span class="prayer-name">${t.name}</span>
            <span class="prayer-time">${fmt(t.hour)}</span>
          </div>`).join('')}
      </div>`;
  }
};

// ─── Modal Manager ──────────────────────────────
const Modal = {
  open(id) {
    const el = document.getElementById(id);
    if (el) { el.classList.add('open'); document.body.style.overflow = 'hidden'; }
  },
  close(id) {
    const el = document.getElementById(id);
    if (el) { el.classList.remove('open'); document.body.style.overflow = ''; }
  },
  closeAll() {
    document.querySelectorAll('.modal-overlay.open').forEach(el => {
      el.classList.remove('open');
    });
    document.body.style.overflow = '';
  },
  init() {
    // Click outside to close
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
      overlay.addEventListener('click', e => {
        if (e.target === overlay) this.closeAll();
      });
    });
    // Close buttons
    document.querySelectorAll('.modal-close').forEach(btn => {
      btn.addEventListener('click', () => this.closeAll());
    });
    // ESC key
    document.addEventListener('keydown', e => {
      if (e.key === 'Escape') this.closeAll();
    });
  }
};

// ─── Animate Chart Bars ─────────────────────────
const Charts = {
  init() {
    // Use IntersectionObserver so bars animate when scrolled into view
    const bars = document.querySelectorAll('.chart-bar-fill[data-width]');
    if (!bars.length) return;

    if ('IntersectionObserver' in window) {
      const obs = new IntersectionObserver(entries => {
        entries.forEach(e => {
          if (e.isIntersecting) {
            e.target.style.width = e.target.dataset.width + '%';
            obs.unobserve(e.target);
          }
        });
      }, { threshold: 0.1 });
      bars.forEach(b => obs.observe(b));
    } else {
      // Fallback
      setTimeout(() => bars.forEach(b => { b.style.width = b.dataset.width + '%'; }), 300);
    }
  }
};

// ─── Flash Auto-dismiss ─────────────────────────
const Flash = {
  init() {
    document.querySelectorAll('.flash').forEach((msg, i) => {
      setTimeout(() => {
        msg.style.transition = 'opacity .4s ease, transform .4s ease';
        msg.style.opacity    = '0';
        msg.style.transform  = 'translateX(110%)';
        setTimeout(() => msg.remove(), 420);
      }, 5000 + i * 600);
    });
  }
};

// ─── Date Validation for Booking Form ──────────
const DateValidation = {
  init() {
    const start = document.getElementById('booking_start_date');
    const end   = document.getElementById('booking_end_date');
    if (!start || !end) return;

    const today = new Date().toISOString().split('T')[0];
    start.min = today;
    end.min   = today;

    start.addEventListener('change', () => {
      end.min = start.value;
      if (end.value && end.value < start.value) end.value = start.value;
    });
  }
};

// ─── Active Nav Highlight ───────────────────────
const ActiveNav = {
  init() {
    const path = window.location.pathname;
    document.querySelectorAll('.nav-link').forEach(link => {
      if (link.getAttribute('href') === path) link.classList.add('active');
    });
  }
};

// ─── Table Search / Filter ──────────────────────
const TableSearch = {
  init() {
    const input = document.getElementById('tableSearch');
    if (!input) return;
    const tbody = document.querySelector(input.dataset.target || 'tbody');
    if (!tbody) return;

    input.addEventListener('input', () => {
      const q = input.value.toLowerCase();
      tbody.querySelectorAll('tr').forEach(row => {
        row.style.display = row.textContent.toLowerCase().includes(q) ? '' : 'none';
      });
    });
  }
};

// ─── Star Rating Interactive ────────────────────
const Stars = {
  init() {
    document.querySelectorAll('.star-input').forEach(widget => {
      const labels = [...widget.querySelectorAll('label')];
      labels.forEach((lbl, i) => {
        lbl.addEventListener('mouseover', () => {
          // Labels are in reverse order (5,4,3,2,1) for CSS trick
          labels.forEach((l, j) => {
            l.style.color = j >= i ? 'var(--gold)' : 'var(--border)';
          });
        });
        lbl.addEventListener('mouseout', () => {
          labels.forEach(l => l.style.color = '');
        });
      });
    });
  }
};

// ─── Smooth Page Reveal ─────────────────────────
const PageReveal = {
  init() {
    document.body.style.opacity = '0';
    document.body.style.transition = 'opacity .35s ease';
    requestAnimationFrame(() => {
      document.body.style.opacity = '1';
    });
  }
};

// ─── Confirm Wrapper (used inline in templates) ─
window.confirmAction = (msg, formId) => {
  if (confirm(msg)) document.getElementById(formId)?.submit();
};

// ─── Verse Refresh ──────────────────────────────
window.refreshVerse = async () => {
  try {
    const res  = await fetch('/api/verse');
    const v    = await res.json();
    const ar   = document.querySelector('.verse-arabic, .hero-verse-arabic');
    const tr   = document.querySelector('.verse-trans, .hero-verse-trans');
    const ref  = document.querySelector('.verse-ref, .hero-verse-ref');
    if (ar) ar.textContent  = v.arabic;
    if (tr) tr.textContent  = v.translation;
    if (ref) ref.textContent = '— ' + v.reference;
  } catch (_) {}
};

// ─── Init ───────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  PageReveal.init();
  ThemeManager.init();
  Modal.init();
  Flash.init();
  Charts.init();
  ActiveNav.init();
  DateValidation.init();
  TableSearch.init();
  Stars.init();
  AdhanWidget.init();
});
