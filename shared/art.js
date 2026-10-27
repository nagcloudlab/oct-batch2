/* =====================================================================
   iOS Training — Illustration library  (zero dependencies)
   Injects one hidden <svg> of <symbol>s so any slide can draw:
       <use href="#i-phone" x=".." y=".." width="28" height="28"/>
   Icons are 24x24 line art, stroke = currentColor, so they take the
   grey / teal state of the .nd group they sit in (see deck.css .art).
   Inlined via script (not an external .svg) so decks still work from file://.
   Load before deck.js:  <script src="../../shared/art.js"></script>
   ===================================================================== */
(function () {
  'use strict';

  var icons = {
    // devices & system
    'phone':      '<rect x="6" y="2" width="12" height="20" rx="2.5"/><path d="M10.5 18.5h3"/>',
    'tap':        '<circle cx="12" cy="12" r="2.5"/><path d="M6.5 8.5a6.5 6.5 0 0 1 11 0M4 6a9.5 9.5 0 0 1 16 0"/><path d="M12 14.5V21"/>',
    'grid':       '<rect x="4" y="4" width="6" height="6" rx="1.5"/><rect x="14" y="4" width="6" height="6" rx="1.5"/><rect x="4" y="14" width="6" height="6" rx="1.5"/><rect x="14" y="14" width="6" height="6" rx="1.5"/>',
    'gear':       '<circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="7"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12h2.5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8"/>',
    'decision':   '<path d="M12 3l9 9-9 9-9-9z"/><path d="M10 10a2 2 0 1 1 2.5 1.9c-.4.2-.5.5-.5.9v.4"/><path d="M12 15.8v.1"/>',
    'app':        '<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="3.5"/>',
    'frameworks': '<rect x="3" y="4" width="8" height="7" rx="1.5"/><rect x="13" y="4" width="8" height="7" rx="1.5"/><rect x="3" y="13" width="18" height="7" rx="1.5"/>',
    'services':   '<circle cx="6" cy="6" r="2.5"/><circle cx="18" cy="6" r="2.5"/><circle cx="12" cy="18" r="2.5"/><path d="M8.5 6h7M7.2 8.2l3.6 7.6M16.8 8.2l-3.6 7.6"/>',
    'kernel':     '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="4"/><path d="M12 3v5M12 16v5M3 12h5M16 12h5"/>',
    'chip':       '<rect x="6" y="6" width="12" height="12" rx="2"/><rect x="9.5" y="9.5" width="5" height="5" rx="1"/><path d="M9.5 3v3M14.5 3v3M9.5 18v3M14.5 18v3M3 9.5h3M3 14.5h3M18 9.5h3M18 14.5h3"/>',
    'process':    '<path d="M12 3l8 4.5v9L12 21l-8-4.5v-9z"/><path d="M4 7.5l8 4.5 8-4.5M12 12v9"/>',
    'memory':     '<rect x="3" y="6" width="18" height="12" rx="1.5"/><path d="M8 9v6M12 9v6M16 9v6"/>',
    'file':       '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/>',
    'link':       '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
    'lock':       '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
    'code':       '<path d="M9 8l-4 4 4 4M15 8l4 4-4 4"/>',
    'thread':     '<path d="M3 7h13M3 12h18M3 17h9"/><path d="M14 4l3 3-3 3"/>',
    'clock':      '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    'db':         '<ellipse cx="12" cy="5.5" rx="7.5" ry="2.5"/><path d="M4.5 5.5v13c0 1.4 3.4 2.5 7.5 2.5s7.5-1.1 7.5-2.5v-13M4.5 12c0 1.4 3.4 2.5 7.5 2.5s7.5-1.1 7.5-2.5"/>',
    'cloud':      '<path d="M7 19h10.5a4.5 4.5 0 0 0 .5-9 6 6 0 0 0-11.6-1.5A5 5 0 0 0 7 19z"/>',
    // app architecture (Lesson 0.2+)
    'user':       '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    'send':       '<path d="M21 3L10 14"/><path d="M21 3l-7 18-4-7-7-4z"/>',
    'bank':       '<path d="M3 10l9-6 9 6"/><path d="M5 10v8M9.5 10v8M14.5 10v8M19 10v8M3 21h18"/>',
    'shield':     '<path d="M12 3l8 3v6c0 4.5-3.4 8.2-8 9-4.6-.8-8-4.5-8-9V6z"/>',
    'key':        '<circle cx="7.5" cy="15.5" r="4.5"/><path d="M10.7 12.3L20 3M16 7l3 3M14 9l2 2"/>',
    'folder':     '<path d="M3 6.5A1.5 1.5 0 0 1 4.5 5H9l2 2.5h8.5A1.5 1.5 0 0 1 21 9v9.5a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 18.5z"/>',
    'check':      '<circle cx="12" cy="12" r="9"/><path d="M8 12.5l2.8 2.8L16 10"/>',
    'cross':      '<circle cx="12" cy="12" r="9"/><path d="M9 9l6 6M15 9l-6 6"/>',
    'globe':      '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.5 3.8 5.5 3.8 9s-1.3 6.5-3.8 9c-2.5-2.5-3.8-5.5-3.8-9S9.5 5.5 12 3z"/>',
    // analogies
    'book':       '<path d="M5 4.5A1.5 1.5 0 0 1 6.5 3H19v15H6.5A1.5 1.5 0 0 0 5 19.5z"/><path d="M5 19.5A1.5 1.5 0 0 0 6.5 21H19v-3M9 7h6"/>',
    'building':   '<rect x="5" y="3" width="14" height="18" rx="1.5"/><path d="M9 7h1M14 7h1M9 11h1M14 11h1M9 15h1M14 15h1M11 21v-3h2v3"/>',
    'stage':      '<path d="M3 4h18M3 20h18M4 4v16c2-1 3.5-4 4-9M20 4v16c-2-1-3.5-4-4-9"/>',
    // rendering pipeline
    'play':       '<circle cx="12" cy="12" r="9"/><path d="M10 8.5l5.5 3.5-5.5 3.5z"/>',
    'eye':        '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    'diff':       '<path d="M7 4v13M4 14l3 3 3-3M17 20V7M14 10l3-3 3 3"/>',
    'layout':     '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 3v18M9 10h12"/>',
    'layers':     '<path d="M12 3l9 5-9 5-9-5z"/><path d="M3 12.5l9 5 9-5M3 16.5l9 5 9-5"/>',
    'frame':      '<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="8.5" cy="10" r="1.5"/><path d="M21 16l-5-5-8 8"/>'
  };

  var out = '';
  for (var k in icons) {
    out += '<symbol id="i-' + k + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
           'stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">' + icons[k] + '</symbol>';
  }

  // iPhone outline, 120 x 240. Screen content is drawn by the slide on top.
  out += '<symbol id="d-iphone" viewBox="0 0 120 240">' +
         '<rect x="3" y="3" width="114" height="234" rx="22" fill="#0f172a"/>' +
         '<rect x="9" y="9" width="102" height="222" rx="17" fill="#f8fafc"/>' +
         '<rect x="44" y="15" width="32" height="10" rx="5" fill="#0f172a"/>' +
         '<rect x="44" y="222" width="32" height="3" rx="1.5" fill="#94a3b8"/>' +
         '</symbol>';

  document.body.insertAdjacentHTML('afterbegin',
    '<svg width="0" height="0" style="position:absolute" aria-hidden="true">' + out + '</svg>');
})();
