// Full screen button for phones and tablets. The Web export's head include
// (export_presets.cfg) loads this into the game page at build/play/.
(function () {
  if (!window.matchMedia('(pointer: coarse)').matches) return;  // touch screens only
  if (window.navigator.standalone || window.matchMedia('(display-mode: standalone)').matches) return;

  const root = document.documentElement;
  const request = root.requestFullscreen || root.webkitRequestFullscreen;
  const isFull = () => document.fullscreenElement || document.webkitFullscreenElement;

  const style = document.createElement('style');
  style.textContent = `
    #fullscreen-btn {
      position: fixed; right: 14px; bottom: 14px; z-index: 10;
      width: 48px; height: 48px; padding: 10px; border-radius: 12px;
      border: 2px solid rgba(236, 228, 208, 0.35); background: rgba(11, 10, 16, 0.6);
      color: #ece4d0; touch-action: manipulation; -webkit-tap-highlight-color: transparent;
    }
    #fullscreen-btn:active { background: rgba(230, 57, 70, 0.6); }
    #fullscreen-btn svg { display: block; width: 100%; height: 100%; }
    #fullscreen-tip {
      position: fixed; left: 50%; bottom: 76px; z-index: 10; transform: translateX(-50%);
      max-width: calc(100% - 32px); padding: 10px 16px; border-radius: 10px;
      background: rgba(11, 10, 16, 0.9); color: #ece4d0; font: 15px/1.4 sans-serif; text-align: center;
    }
    .fullscreen-hidden { display: none; }
  `;
  document.head.appendChild(style);

  const btn = document.createElement('button');
  btn.id = 'fullscreen-btn';
  btn.setAttribute('aria-label', 'Play full screen');
  btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">'
    + '<path d="M3 9V3h6M15 3h6v6M21 15v6h-6M9 21H3v-6"/></svg>';
  document.body.appendChild(btn);

  const tip = document.createElement('div');
  tip.id = 'fullscreen-tip';
  tip.className = 'fullscreen-hidden';
  tip.textContent = 'To play full screen, tap Share, then "Add to Home Screen", and open SKULLRUN from there.';
  document.body.appendChild(tip);
  let tipTimer = 0;

  btn.addEventListener('click', async () => {
    if (!request) {
      // iPhone Safari can't go full screen, but a home screen web app opens without the browser bars.
      tip.classList.remove('fullscreen-hidden');
      clearTimeout(tipTimer);
      tipTimer = setTimeout(() => tip.classList.add('fullscreen-hidden'), 6000);
      return;
    }
    try {
      await request.call(root, { navigationUI: 'hide' });
    } catch (e) {
      return;
    }
    try {
      await screen.orientation.lock('landscape');
    } catch (e) {
      // Not every browser can lock the orientation; the game still fits the screen.
    }
    const canvas = document.getElementById('canvas');
    if (canvas) canvas.focus();
  });

  function update() {
    btn.classList.toggle('fullscreen-hidden', !!isFull());
  }
  document.addEventListener('fullscreenchange', update);
  document.addEventListener('webkitfullscreenchange', update);
})();
