// netbrain/zwift: theme toggle, route profile, segments list and previous/next links.
// Everything here is progressive enhancement; without JavaScript the site is plain just-the-docs.
(function () {
  'use strict';

  var WORDS_PER_MINUTE = 220;

  function ready(fn) {
    if (document.readyState !== 'loading') fn();
    else document.addEventListener('DOMContentLoaded', fn);
  }

  // ---------- Theme toggle ----------
  // "system" leaves the media queries from head.html alone; "light" and "dark" pin one stylesheet.

  function setupThemeToggle() {
    var button = document.getElementById('zw-theme-toggle');
    var label = document.getElementById('zw-theme-label');
    var light = document.getElementById('zw-theme-light');
    var dark = document.getElementById('zw-theme-dark');
    if (!button || !light || !dark) return;

    var themes = ['system', 'light', 'dark'];
    var theme = 'system';
    try { theme = localStorage.getItem('zw-theme') || 'system'; } catch (e) {}
    if (themes.indexOf(theme) < 0) theme = 'system';

    function apply() {
      if (theme === 'system') {
        light.media = 'not all and (prefers-color-scheme: dark)';
        dark.media = '(prefers-color-scheme: dark)';
      } else {
        light.media = theme === 'light' ? 'all' : 'not all';
        dark.media = theme === 'dark' ? 'all' : 'not all';
      }
      var name = theme.charAt(0).toUpperCase() + theme.slice(1);
      label.textContent = name;
      button.setAttribute('aria-label', 'Theme: ' + name);
      button.title = 'Theme: ' + name;
    }

    button.addEventListener('click', function () {
      theme = themes[(themes.indexOf(theme) + 1) % themes.length];
      try {
        if (theme === 'system') localStorage.removeItem('zw-theme');
        else localStorage.setItem('zw-theme', theme);
      } catch (e) {}
      apply();
    });

    apply();
    button.hidden = false;
  }

  // ---------- Reading helpers ----------

  function countWords(text) {
    var m = text.trim().match(/\S+/g);
    return m ? m.length : 0;
  }

  function wordsBefore(container, node) {
    var range = document.createRange();
    range.setStart(container, 0);
    range.setEndBefore(node);
    return countWords(range.toString());
  }

  function formatMinutes(minutes) {
    var s = Math.round(minutes * 60);
    return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0');
  }

  function headingLabel(h) {
    // Strip the anchor link that just-the-docs injects and the spec card badges.
    var clone = h.cloneNode(true);
    clone.querySelectorAll('.anchor-heading, .zw-badge').forEach(function (a) { a.remove(); });
    return clone.textContent.trim();
  }

  // ---------- Route profile and segments ----------

  function setupRoute() {
    var main = document.querySelector('#main-content main');
    var wrap = document.querySelector('.main-content-wrap');
    if (!main || !wrap) return;

    var heads = Array.prototype.slice.call(main.querySelectorAll('h2[id], h3[id]'));
    // Climbs come from the h2 sections. Pages without them use their h3s, and a page with no headings
    // gets flat rolling terrain.
    var sections = heads.filter(function (h) { return h.tagName === 'H2'; });
    if (!sections.length) sections = heads;

    var totalMinutes = countWords(main.textContent) / WORDS_PER_MINUTE;

    var route = document.createElement('div');
    route.className = 'zw-route';
    route.setAttribute('aria-hidden', 'true');
    route.innerHTML =
      '<div class="zw-hud"><span class="zw-hud-label">Ridden</span><span class="zw-hud-value" data-zw="pct">0%</span></div>' +
      '<div class="zw-profile"><svg viewBox="0 0 1000 40" preserveAspectRatio="none">' +
      '<defs><clipPath id="zw-ridden-clip"><rect x="0" y="-10" width="0" height="60"/></clipPath></defs>' +
      '<g data-zw="markers"></g><path class="zw-ground"/><path class="zw-ridden" clip-path="url(#zw-ridden-clip)"/>' +
      '</svg><div class="zw-rider"></div></div>' +
      '<div class="zw-hud zw-hud-right"><span class="zw-hud-label">Time left</span><span class="zw-hud-value" data-zw="time">0:00</span></div>';
    wrap.parentNode.insertBefore(route, wrap);

    var ground = route.querySelector('.zw-ground');
    var ridden = route.querySelector('.zw-ridden');
    var clip = route.querySelector('#zw-ridden-clip rect');
    var markers = route.querySelector('[data-zw="markers"]');
    var rider = route.querySelector('.zw-rider');
    var pct = route.querySelector('[data-zw="pct"]');
    var time = route.querySelector('[data-zw="time"]');

    var segments = document.createElement('aside');
    segments.className = 'zw-segments';
    segments.setAttribute('aria-label', 'On this page');
    segments.innerHTML = '<p class="zw-segments-title">Segments</p><ol></ol>';
    var list = segments.querySelector('ol');
    var items = heads.map(function (h) {
      var li = document.createElement('li');
      if (h.tagName === 'H3') li.className = 'zw-sub';
      var a = document.createElement('a');
      a.href = '#' + h.id;
      var name = document.createElement('span');
      name.className = 'zw-name';
      name.textContent = headingLabel(h);
      a.title = name.textContent;
      var at = document.createElement('span');
      at.className = 'zw-time';
      at.textContent = formatMinutes(wordsBefore(main, h) / WORDS_PER_MINUTE);
      a.appendChild(name);
      a.appendChild(at);
      li.appendChild(a);
      list.appendChild(li);
      return { h: h, li: li };
    });
    if (items.length) document.body.appendChild(segments);

    var W = 1000, H = 40, N = 160;
    var elevation = [];

    // Each h2 section is a climb; longer sections are bigger climbs.
    function build() {
      var top = main.offsetTop, len = main.offsetHeight || 1;
      var spans = sections.map(function (h, i) {
        var start = (h.offsetTop - top) / len;
        var end = i + 1 < sections.length ? (sections[i + 1].offsetTop - top) / len : 1;
        return { start: start, end: end };
      });
      var maxSpan = Math.max.apply(null, spans.map(function (s) { return s.end - s.start; })) || 1;
      elevation = [];
      for (var i = 0; i <= N; i++) {
        var x = i / N;
        var e = 0.12 + 0.04 * Math.sin(x * 37) + 0.03 * Math.sin(x * 91 + 1);
        spans.forEach(function (s) {
          var mid = (s.start + s.end) / 2;
          var w = Math.max(0.04, (s.end - s.start) / 2.4);
          var amp = 0.25 + 0.55 * ((s.end - s.start) / maxSpan);
          e += amp * Math.exp(-((x - mid) * (x - mid)) / (2 * w * w));
        });
        elevation.push(Math.min(0.96, e));
      }
      var d = 'M0 ' + H;
      elevation.forEach(function (e, i) { d += ' L' + (i / N) * W + ' ' + (H - e * H); });
      d += ' L' + W + ' ' + H + ' Z';
      ground.setAttribute('d', d);
      ridden.setAttribute('d', d);
      markers.innerHTML = spans.map(function (s) {
        var x = s.start * W;
        return '<line class="zw-marker" x1="' + x + '" x2="' + x + '" y1="0" y2="' + H + '"/>';
      }).join('');
      update();
    }

    function update() {
      // A page that fits in the window is ridden as soon as it opens.
      var max = document.documentElement.scrollHeight - window.innerHeight;
      var p = max < 1 ? 1 : Math.min(1, Math.max(0, window.scrollY / max));
      clip.setAttribute('width', p * W);
      rider.style.left = p * 100 + '%';
      rider.style.top = (1 - (elevation[Math.round(p * N)] || 0)) * 100 + '%';
      pct.textContent = Math.round(p * 100) + '%';
      time.textContent = formatMinutes(totalMinutes * (1 - p));

      var line = parseFloat(getComputedStyle(document.documentElement).scrollPaddingTop) || 0;
      var active = 0;
      items.forEach(function (item, i) {
        if (item.h.getBoundingClientRect().top <= line + 4) active = i;
      });
      if (p > 0.995) active = items.length - 1;
      items.forEach(function (item, i) {
        item.li.classList.toggle('zw-active', i === active);
        item.li.classList.toggle('zw-done', i < active);
      });
    }

    window.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', build);
    window.addEventListener('load', build);
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(build);
    build();
  }

  // ---------- Previous / next segment ----------
  // Follows the sidebar order, so it stays in sync with nav_order.

  function normalize(path) {
    return path.replace(/(index)?\.html$/, '').replace(/\/?$/, '/');
  }

  function setupSegmentNav() {
    var nav = document.getElementById('zw-segment-nav');
    var siteNav = document.getElementById('site-nav');
    if (!nav || !siteNav) return;

    var links = Array.prototype.slice.call(siteNav.querySelectorAll('a.nav-list-link'));
    var here = normalize(window.location.pathname);
    var index = -1;
    links.forEach(function (a, i) {
      if (index < 0 && normalize(new URL(a.href, window.location.href).pathname) === here) index = i;
    });
    if (index < 0) return;

    function link(a, label, cls) {
      var el = document.createElement('a');
      el.href = a.href;
      el.className = cls;
      var l = document.createElement('span');
      l.className = 'zw-label';
      l.textContent = label;
      var t = document.createElement('span');
      t.className = 'zw-page';
      t.textContent = a.textContent.trim();
      el.appendChild(l);
      el.appendChild(t);
      nav.appendChild(el);
    }

    if (links[index - 1]) link(links[index - 1], 'Previous segment', 'zw-prev');
    if (links[index + 1]) link(links[index + 1], 'Next segment', 'zw-next');
    nav.hidden = !nav.children.length;
  }

  // ---------- Spec cards ----------
  // Tables with the "Item | Description" layout (see configuration/options.md) become spec cards, and the
  // heading above each one gets badges for where the option can be used.

  function cellText(td) {
    return td ? td.textContent.trim() : '';
  }

  function setupSpecCards() {
    var main = document.querySelector('#main-content main');
    if (!main) return;

    main.querySelectorAll('.table-wrapper > table').forEach(function (table) {
      var head = table.querySelectorAll('thead th');
      if (head.length !== 2 || cellText(head[0]) !== 'Item') return;
      table.parentNode.classList.add('zw-spec');

      var usage = {};
      table.querySelectorAll('tbody tr').forEach(function (tr) {
        var cells = tr.children;
        if (!cellText(cells[0])) tr.classList.add('zw-cont');
        var key = cellText(cells[0]);
        if (key === 'Commandline usage' || key === 'Config file usage') {
          usage[key] = !cells[1].querySelector('img.emoji[title=":x:"]');
        }
      });

      var h = table.parentNode.previousElementSibling;
      while (h && !/^H[1-6]$/.test(h.tagName)) h = h.previousElementSibling;
      if (!h || h.tagName !== 'H3' || !Object.keys(usage).length) return;

      [['Commandline usage', 'Command line'], ['Config file usage', 'Config file']].forEach(function (pair) {
        if (!(pair[0] in usage)) return;
        var badge = document.createElement('span');
        badge.className = 'zw-badge ' + (usage[pair[0]] ? 'zw-badge-yes' : 'zw-badge-no');
        badge.textContent = usage[pair[0]] ? pair[1] : 'Not in ' + pair[1].toLowerCase();
        h.appendChild(badge);
      });
    });
  }

  // ---------- Variable filter ----------
  // Adds a search field and group pills above a "Key | Default value | Description" overview table.
  // Groups come from _data/option_groups.yaml.

  var OPTION_GROUPS = {{ site.data.option_groups | jsonify }};

  function setupVariableFilter() {
    var main = document.querySelector('#main-content main');
    if (!main) return;

    main.querySelectorAll('.table-wrapper > table').forEach(function (table) {
      var head = table.querySelectorAll('thead th');
      if (!head.length || cellText(head[0]) !== 'Key') return;

      var rows = Array.prototype.slice.call(table.querySelectorAll('tbody tr'));
      var groupOf = {};
      Object.keys(OPTION_GROUPS || {}).forEach(function (group) {
        OPTION_GROUPS[group].forEach(function (name) { groupOf[name] = group; });
      });
      var present = {};
      rows.forEach(function (tr) {
        var g = groupOf[cellText(tr.children[0])];
        if (g) present[g] = true;
      });

      var bar = document.createElement('div');
      bar.className = 'zw-filter';
      var input = document.createElement('input');
      input.type = 'search';
      input.id = 'zw-filter-input';
      input.placeholder = 'Filter variables, e.g. DIR or pull';
      input.setAttribute('aria-label', 'Filter variables');
      bar.appendChild(input);

      var group = 'All';
      var pills = ['All'].concat(Object.keys(OPTION_GROUPS || {}).filter(function (g) { return present[g]; }))
        .map(function (name) {
          var b = document.createElement('button');
          b.type = 'button';
          b.className = 'zw-pill';
          b.textContent = name;
          b.setAttribute('aria-pressed', String(name === group));
          b.addEventListener('click', function () {
            group = name;
            pills.forEach(function (p) { p.setAttribute('aria-pressed', String(p === b)); });
            apply();
          });
          bar.appendChild(b);
          return b;
        });

      var empty = document.createElement('p');
      empty.className = 'zw-filter-empty';
      empty.textContent = 'No variables match the filter.';
      empty.hidden = true;

      function apply() {
        var q = input.value.trim().toLowerCase();
        var shown = 0;
        rows.forEach(function (tr) {
          var ok = (group === 'All' || groupOf[cellText(tr.children[0])] === group) &&
            (!q || tr.textContent.toLowerCase().indexOf(q) >= 0);
          tr.hidden = !ok;
          if (ok) shown++;
        });
        empty.hidden = shown > 0;
        window.dispatchEvent(new Event('resize'));
      }
      input.addEventListener('input', apply);

      var wrapper = table.parentNode;
      wrapper.parentNode.insertBefore(bar, wrapper);
      wrapper.parentNode.insertBefore(empty, wrapper.nextSibling);
    });
  }

  // ---------- Page stats ----------
  // Zone, reading time and variable count under the page title.

  var ZONE_NAMES = { Z1: 'Recovery', Z2: 'Endurance', Z3: 'Tempo', Z4: 'Threshold', Z5: 'VO2 Max' };

  function setupPageStats() {
    var main = document.querySelector('#main-content main');
    var h1 = main && main.querySelector('h1');
    if (!h1 || main.querySelectorAll('h2[id]').length < 2) return;

    var stats = [];
    var section = document.querySelector('#site-nav > .nav-list > .nav-list-item.active > .nav-list-link');
    if (section) {
      var zone = getComputedStyle(section, '::after').content.replace(/["']/g, '');
      if (ZONE_NAMES[zone]) stats.push({ label: 'Zone', zone: zone, value: ZONE_NAMES[zone] });
    }
    var minutes = Math.max(1, Math.round(countWords(main.textContent) / WORDS_PER_MINUTE));
    stats.push({ label: 'Est. read', value: minutes + ' min' });
    var overview = Array.prototype.filter.call(main.querySelectorAll('table'), function (t) {
      var th = t.querySelector('thead th');
      return th && cellText(th) === 'Key';
    })[0];
    if (overview) stats.push({ label: 'Variables', value: String(overview.querySelectorAll('tbody tr').length) });

    var box = document.createElement('div');
    box.className = 'zw-stats';
    stats.forEach(function (s) {
      var el = document.createElement('div');
      el.className = 'zw-stat';
      var l = document.createElement('span');
      l.className = 'zw-stat-label';
      l.textContent = s.label;
      el.appendChild(l);
      if (s.zone) {
        var z = document.createElement('span');
        z.className = 'zw-zone zw-zone-' + s.zone.toLowerCase();
        z.textContent = s.zone;
        el.appendChild(z);
      }
      var v = document.createElement('span');
      v.className = 'zw-stat-value';
      v.textContent = s.value;
      el.appendChild(v);
      box.appendChild(el);
    });
    h1.parentNode.insertBefore(box, h1.nextSibling);
  }

  ready(function () {
    setupThemeToggle();
    setupPageStats();
    setupSpecCards();
    setupVariableFilter();
    setupRoute();
    setupSegmentNav();
  });
})();
