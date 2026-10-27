/* =====================================================================
   iOS Training — Slide Engine  (zero dependencies)
   Keys:  → / Space / PageDown   next step or slide
          ← / PageUp             back
          Home / End              first / last slide
          S   speaker notes       O  overview      F  fullscreen
          B   blank screen        ?  help
   Mark any element with class="step" to reveal incrementally.
   data-lit="N" on any element adds .lit while N steps are shown
   (also "N-M", "N+"); <i class="step cue"></i> = invisible step.
   Put speaker notes in <aside class="notes-src"> inside a slide.
   <pre class="cb"> inside a .cw gets Swift syntax colouring.
   ===================================================================== */
(function () {
  'use strict';

  var slides = Array.from(document.querySelectorAll('.slide'));
  var deckName = document.body.dataset.deck || document.title;
  var current = 0;

  /* ---------- build chrome ---------- */
  var progress = mk('div', 'progress');
  var notes    = mk('div', 'notes');
  var overview = mk('div', 'overview');
  var help     = mk('div', 'help');
  var chrome   = mk('div', 'chrome');

  chrome.innerHTML =
    '<button class="navbtn" data-act="prev" title="Back">&#8592;</button>' +
    '<button class="navbtn" data-act="next" title="Next">&#8594;</button>' +
    '<button class="navbtn" data-act="notes" title="Speaker notes (S)">Notes</button>' +
    '<button class="navbtn" data-act="overview" title="All slides (O)">Slides</button>' +
    '<button class="navbtn" data-act="full" title="Fullscreen (F)">&#x26F6;</button>';

  help.innerHTML =
    '<h3 style="margin:0 0 14px;font-size:18px">Keyboard shortcuts</h3><table>' +
    row('&#8594;  Space  PageDown', 'Next step / slide') +
    row('&#8592;  PageUp', 'Previous') +
    row('Home / End', 'First / last slide') +
    row('S', 'Speaker notes') +
    row('O', 'All slides') +
    row('F', 'Fullscreen') +
    row('B', 'Blank screen') +
    row('?', 'This help') +
    row('Esc', 'Close panel') +
    row('Ctrl/&#8984; + P', 'Print / save as PDF') +
    '</table>';

  document.body.append(progress, chrome, notes, overview, help);

  var blank = mk('div');
  blank.style.cssText = 'position:fixed;inset:0;background:#0f172a;z-index:60;display:none';
  document.body.append(blank);

  /* ---------- per-slide setup ---------- */
  slides.forEach(function (s, i) {
    // footer
    var foot = mk('div', 'foot');
    // footer: deck name · click counter (only on slides with steps) · slide number
    foot.innerHTML = '<span>' + esc(deckName) + '</span><span class="stepc"></span><span>' + (i + 1) + ' / ' + slides.length + '</span>';
    s.append(foot);

    // overview button
    var b = mk('button');
    // data-title overrides; <br> in a heading becomes a space
    var h = s.querySelector('h1,h2');
    var title = s.dataset.title || (h ? h.innerHTML.replace(/<br\s*\/?>/gi, ' ').replace(/<[^>]+>/g, '')
      .replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ') : '') || 'Slide ' + (i + 1);
    b.innerHTML = '<small>' + (i + 1) + '</small><span>' + esc(title.trim()) + '</span>';
    b.onclick = function () { go(i); toggle(overview, false); };
    overview.append(b);
  });

  // lesson map on every divider: all parts, the current one teal, earlier ones done
  var chapters = slides.filter(function (s) { return s.classList.contains('chapter'); });
  if (chapters.length > 2) {
    var parts = chapters.map(function (c) {
      var k = c.querySelector('.kicker'), h = c.querySelector('h2');
      return { k: k ? k.textContent.trim() : '', t: h ? h.textContent.replace(/\s+/g, ' ').trim() : '' };
    });
    chapters.forEach(function (c, ci) {
      var ol = mk('ol', 'partmap' + (parts.length > 9 ? ' dense' : ''));
      ol.setAttribute('aria-label', 'Lesson map');
      ol.innerHTML = parts.map(function (p, pi) {
        return '<li class="' + (pi < ci ? 'done' : pi === ci ? 'now' : '') + '"><small>' + esc(p.k) + '</small>' + esc(p.t) + '</li>';
      }).join('');
      c.classList.add('has-map');
      c.append(ol);
    });
  }

  // syntax-colour Swift code blocks
  document.querySelectorAll('.cb').forEach(function (pre) { colourSwift(pre); });

  /* ---------- navigation ---------- */
  function steps(s) { return Array.from(s.querySelectorAll('.step')); }

  function go(i, showAll) {
    i = Math.max(0, Math.min(slides.length - 1, i));
    slides[current].classList.remove('active');
    current = i;
    var s = slides[current];
    s.classList.add('active');

    var st = steps(s);
    st.forEach(function (x) { x.classList.toggle('shown', !!showAll); });
    // mark past steps
    st.forEach(function (x) { x.classList.remove('past'); });
    if (showAll) st.forEach(function (x) { x.classList.add('past'); });
    light(s);

    progress.style.width = ((current + 1) / slides.length * 100) + '%';

    // edge to edge: letterbox strips continue the slide's own background
    var cs = getComputedStyle(s);
    document.body.style.backgroundColor = /^rgba\(0, 0, 0, 0\)$|^transparent$/.test(cs.backgroundColor) ? '#0f172a' : cs.backgroundColor;
    document.body.style.backgroundImage = cs.backgroundImage;

    // speaker notes
    var src = s.querySelector('aside.notes-src');
    notes.innerHTML = '<h4>Speaker notes &middot; slide ' + (current + 1) + '</h4>' +
      (src ? src.innerHTML : '<p class="muted">No notes for this slide.</p>');

    // overview highlight
    overview.querySelectorAll('button').forEach(function (b, j) {
      b.classList.toggle('current', j === current);
    });

    history.replaceState(null, '', '#' + (current + 1));
  }

  function next() {
    var hidden = steps(slides[current]).filter(function (x) { return !x.classList.contains('shown'); });
    if (hidden.length) {
      hidden[0].classList.add('shown');
      // mark earlier steps as past (for dim-after)
      steps(slides[current]).forEach(function (x) {
        if (x.classList.contains('shown') && x !== hidden[0]) x.classList.add('past');
      });
      light(slides[current]);
      return;
    }
    if (current < slides.length - 1) go(current + 1);
  }

  function prev() {
    var shown = steps(slides[current]).filter(function (x) { return x.classList.contains('shown'); });
    if (shown.length) {
      var last = shown[shown.length - 1];
      last.classList.remove('shown');
      last.classList.remove('past');
      light(slides[current]);
      return;
    }
    if (current > 0) go(current - 1, true);
  }

  // data-lit="2" | "2-4" | "2+" (space-separated) → .lit while that many steps are shown
  function light(s) {
    var n = s.querySelectorAll('.step.shown').length, total = s.querySelectorAll('.step').length;
    var counter = s.querySelector('.foot .stepc');
    if (counter) counter.textContent = total ? 'click ' + n + ' / ' + total : '';
    s.querySelectorAll('[data-lit]').forEach(function (el) {
      var on = el.dataset.lit.split(/\s+/).some(function (r) {
        var m = r.match(/^(\d+)(\+|-(\d+))?$/);
        if (!m) return false;
        var a = +m[1];
        return m[2] === '+' ? n >= a : m[3] ? n >= a && n <= +m[3] : n === a;
      });
      el.classList.toggle('lit', on);
    });
  }

  function fit() {
    var s = Math.min(window.innerWidth / 1280, window.innerHeight / 720);
    document.documentElement.style.setProperty('--scale', 'scale(' + s.toFixed(4) + ')');
  }

  function fullscreen() {
    var d = document, el = d.documentElement;
    if (d.fullscreenElement || d.webkitFullscreenElement) {
      (d.exitFullscreen || d.webkitExitFullscreen).call(d);
    } else {
      (el.requestFullscreen || el.webkitRequestFullscreen || function(){}).call(el);
    }
  }

  function toggle(node, force) { node.classList.toggle('open', force); }

  /* ---------- keyboard ---------- */
  document.addEventListener('keydown', function (e) {
    if (e.target.closest('input, textarea, select')) return;
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    var k = e.key;
    if (['ArrowRight', 'ArrowDown', ' ', 'PageDown', 'Enter'].indexOf(k) !== -1) { e.preventDefault(); next(); }
    else if (['ArrowLeft', 'ArrowUp', 'PageUp', 'Backspace'].indexOf(k) !== -1) { e.preventDefault(); prev(); }
    else if (k === 'Home') go(0);
    else if (k === 'End') go(slides.length - 1, true);
    else if (k === 's' || k === 'S') toggle(notes);
    else if (k === 'o' || k === 'O') toggle(overview);
    else if (k === 'f' || k === 'F') fullscreen();
    else if (k === 'b' || k === 'B' || k === '.') blank.style.display = blank.style.display === 'none' ? 'block' : 'none';
    else if (k === '?') toggle(help);
    else if (k === 'Escape') { toggle(overview, false); toggle(help, false); toggle(notes, false); blank.style.display = 'none'; }
  });

  /* ---------- click chrome ---------- */
  chrome.addEventListener('click', function (e) {
    var btn = e.target.closest('button');
    if (!btn) return;
    var act = btn.dataset.act;
    if (act === 'next') next();
    if (act === 'prev') prev();
    if (act === 'notes') toggle(notes);
    if (act === 'overview') toggle(overview);
    if (act === 'full') fullscreen();
  });

  /* ---------- touch swipe ---------- */
  var touchX = null;
  document.addEventListener('touchstart', function (e) { touchX = e.touches[0].clientX; }, { passive: true });
  document.addEventListener('touchend', function (e) {
    if (touchX === null || !e.changedTouches[0]) return;
    var dx = e.changedTouches[0].clientX - touchX;
    if (Math.abs(dx) > 50) (dx < 0 ? next : prev)();
    touchX = null;
  });

  /* ---------- print: every slide in its final state ---------- */
  window.addEventListener('beforeprint', function () {
    slides.forEach(function (s) {
      steps(s).forEach(function (x) { x.classList.add('shown', 'past'); });
      light(s);
    });
  });
  window.addEventListener('afterprint', function () {
    slides.forEach(function (s) { steps(s).forEach(function (x) { x.classList.remove('shown', 'past'); }); });
    go(current);
  });

  // typing #12 in the address bar jumps to slide 12
  window.addEventListener('hashchange', function () {
    var i = (parseInt(location.hash.slice(1), 10) || 1) - 1;
    if (i !== current) go(i);
  });

  /* ---------- init ---------- */
  window.addEventListener('resize', fit);
  fit();
  go(Math.max(0, (parseInt(location.hash.slice(1), 10) || 1) - 1));

  /* ---------- Swift syntax colouring ---------- */
  function colourSwift(pre) {
    var walker = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
    var nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    nodes.forEach(function (n) {
      var html = swiftRules(n.nodeValue);
      if (html === esc(n.nodeValue)) return;
      var span = document.createElement('span');
      span.innerHTML = html;
      n.replaceWith.apply(n, Array.from(span.childNodes));
    });
  }

  function swiftRules(text) {
    // Order: comments, strings, attributes, numbers, keywords, types, functions
    var re = /(\/\/[^\n]*)|("(?:[^"\\]|\\.)*")|(@\w+)|\b(\d+(?:\.\d+)?)\b|\b(import|let|var|func|struct|class|enum|protocol|extension|typealias|init|deinit|self|Self|super|return|if|else|guard|switch|case|default|for|in|while|repeat|break|continue|do|try|catch|throw|throws|rethrows|async|await|actor|some|any|where|is|as|true|false|nil|private|public|internal|fileprivate|open|static|mutating|nonmutating|lazy|weak|unowned|override|final|required|convenience|inout|get|set|willSet|didSet|subscript|associatedtype|operator|precedencegroup|indirect|nonisolated|isolated|sending|consuming|borrowing|macro|MainActor|Sendable)\b|\b([A-Z][A-Za-z0-9]*(?:\.[A-Z][A-Za-z0-9]*)?)\b/g;
    return esc(text).replace(re, function (m, com, str, attr, num, kw, ty) {
      if (com)  return '<span class="com">' + com + '</span>';
      if (str)  return '<span class="str">' + str + '</span>';
      if (attr) return '<span class="at">'  + attr + '</span>';
      if (num)  return '<span class="num">' + num + '</span>';
      if (kw)   return '<span class="kw">'  + m + '</span>';
      if (ty)   return '<span class="ty">'  + m + '</span>';
      return m;
    });
  }

  /* ---------- helpers ---------- */
  function mk(tag, cls) { var n = document.createElement(tag); if (cls) n.className = cls; return n; }
  function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
  function row(k, v) { return '<tr><td><kbd>' + k + '</kbd></td><td style="padding-left:18px">' + v + '</td></tr>'; }

  // public API for extensions
  window.Deck = { go: go, next: next, prev: prev, current: function () { return current; }, total: slides.length };
})();
