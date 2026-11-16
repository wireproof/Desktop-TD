'use strict';
// A separate, optional view of the real game canvas. The original canvas and
// HUD keep their dimensions; only the sampled region is enlarged.
function installMapMagnifier(player) {
  const panel=document.createElement('section');
  panel.id='map-magnifier'; panel.setAttribute('aria-label','Map magnifier');
  panel.innerHTML='<header><span>Map magnifier 2×</span><button type="button" data-action="out" aria-label="Zoom out">−</button><button type="button" data-action="in" aria-label="Zoom in">+</button><button type="button" data-action="close" aria-label="Close magnifier">×</button></header><canvas aria-label="Magnified map; drag to pan, tap to select or place"></canvas><div class="magnifier-hint">Drag map to pan · tap to select or place</div>';
  document.body.appendChild(panel);
  const canvas=panel.querySelector('canvas'), header=panel.querySelector('header'), title=header.querySelector('span'), ctx=canvas.getContext('2d');
  let visible=false, zoom=2, focus={x:230,y:225}, view=null, last=0, raf=0, pan=null, move=null;
  const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
  function notify(){window.webkit?.messageHandlers?.gameStatus?.postMessage({magnifier:visible?'shown':'hidden'});}
  function draw(now) {
    if(!visible) return;
    raf=requestAnimationFrame(draw);
    if(now-last<85) return; last=now;
    const source=player.shadowRoot?.querySelector('canvas'), r=player.getBoundingClientRect(), cr=canvas.getBoundingClientRect();
    if(!source || !source.width || !source.height || !r.width || !r.height || !cr.width || !cr.height) return;
    const pixelRatio=Math.min(window.devicePixelRatio||1,2), w=Math.max(1,Math.round(cr.width*pixelRatio)), h=Math.max(1,Math.round(cr.height*pixelRatio));
    if(canvas.width!==w || canvas.height!==h){canvas.width=w;canvas.height=h;}
    const vw=clamp((cr.width/r.width)*700/zoom,1,700), vh=clamp((cr.height/r.height)*500/zoom,1,500);
    const x=clamp(focus.x-vw/2,0,700-vw), y=clamp(focus.y-vh/2,0,500-vh);
    view={x,y,w:vw,h:vh};
    try {ctx.clearRect(0,0,w,h);ctx.drawImage(source,x/700*source.width,y/500*source.height,vw/700*source.width,vh/500*source.height,0,0,w,h);} catch (_) {ctx.clearRect(0,0,w,h);}
  }
  function show(on) {visible=!!on;panel.style.display=visible?'block':'none';if(raf)cancelAnimationFrame(raf);raf=0;last=0;if(visible)raf=requestAnimationFrame(draw);notify();return true;}
  panel.addEventListener('click',e=>{const a=e.target.closest('button')?.dataset.action;if(!a)return;e.preventDefault();e.stopPropagation();if(a==='close')show(false);else if(a==='in')zoom=clamp(zoom+.5,1.5,4);else if(a==='out')zoom=clamp(zoom-.5,1.5,4);title.textContent='Map magnifier '+zoom+'×';});
  header.addEventListener('pointerdown',e=>{if(e.target.closest('button'))return;e.preventDefault();const r=panel.getBoundingClientRect();move={id:e.pointerId,x:e.clientX,y:e.clientY,left:r.left,top:r.top};header.setPointerCapture(e.pointerId);});
  header.addEventListener('pointermove',e=>{if(!move||e.pointerId!==move.id)return;const r=panel.getBoundingClientRect();panel.style.left=clamp(move.left+e.clientX-move.x,0,Math.max(0,innerWidth-r.width))+'px';panel.style.top=clamp(move.top+e.clientY-move.y,0,Math.max(0,innerHeight-r.height))+'px';});
  header.addEventListener('pointerup',e=>{if(move?.id===e.pointerId)move=null;});
  header.addEventListener('pointercancel',()=>{move=null;});
  canvas.addEventListener('pointerdown',e=>{if(e.pointerType!=='touch'&&e.button===2){e.preventDefault();e.stopPropagation();if(typeof player.wireCancelTower==='function')player.wireCancelTower();return;}if(e.button!==0&&e.pointerType!=='touch')return;e.preventDefault();e.stopPropagation();pan={id:e.pointerId,x:e.clientX,y:e.clientY,fx:focus.x,fy:focus.y,moved:false};canvas.setPointerCapture(e.pointerId);});
  canvas.addEventListener('pointermove',e=>{if(!pan||e.pointerId!==pan.id||!view)return;e.preventDefault();const r=canvas.getBoundingClientRect(),dx=e.clientX-pan.x,dy=e.clientY-pan.y;if(Math.hypot(dx,dy)>5)pan.moved=true;if(pan.moved){focus.x=clamp(pan.fx-dx/r.width*view.w,0,700);focus.y=clamp(pan.fy-dy/r.height*view.h,0,500);}});
  canvas.addEventListener('pointerup',e=>{if(!pan||e.pointerId!==pan.id)return;e.preventDefault();e.stopPropagation();const pending=pan;pan=null;if(!pending.moved&&view){const r=canvas.getBoundingClientRect(),x=view.x+clamp((e.clientX-r.left)/r.width,0,1)*view.w,y=view.y+clamp((e.clientY-r.top)/r.height,0,1)*view.h;if(typeof player.wireMagnifierTap==='function')player.wireMagnifierTap(x,y);}});
  canvas.addEventListener('pointercancel',()=>{pan=null;});
  canvas.addEventListener('contextmenu',e=>{e.preventDefault();e.stopPropagation();});
  player.addEventListener('pointermove',e=>{if(!visible||!e.isTrusted||e.buttons)return;const r=player.getBoundingClientRect(),x=(e.clientX-r.left)/r.width*700,y=(e.clientY-r.top)/r.height*500;if(x>=50&&x<=450&&y>=68&&y<=410)focus={x,y};},true);
  window.addEventListener('resize',()=>{if(!visible)return;const r=panel.getBoundingClientRect();panel.style.left=clamp(r.left,0,Math.max(0,innerWidth-r.width))+'px';panel.style.top=clamp(r.top,0,Math.max(0,innerHeight-r.height))+'px';});
  window.wireMagnifierCommand=command=>{if(command==='show')return show(true);if(command==='hide')return show(false);return false;};
}
