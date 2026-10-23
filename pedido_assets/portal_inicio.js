'use strict';
(()=>{
 const $=id=>document.getElementById(id);
 const source=Array.isArray(window.TOYO_CLIENTS)?window.TOYO_CLIENTS:[];
 const norm=s=>String(s||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLocaleLowerCase('es');
 const clients=source.map(c=>({...c,search:norm(c.client_code+' '+c.client_name),allVendors:c.vendors?.length?c.vendors:[c.vendor_label]}));
 const vendorList=[...new Set(clients.flatMap(c=>c.allVendors))].filter(Boolean).sort((a,b)=>a.localeCompare(b,'es'));
 const vendor=$('vendorFilter');
 vendorList.forEach(s=>{let o=document.createElement('option');o.value=s;o.textContent=s;vendor.append(o)});
 const byCode=new Map(clients.map(c=>[c.client_code,c]));
 const LS='toyo_inicio_recientes_20261022';
 let recent=[];try{recent=JSON.parse(localStorage.getItem(LS)||'[]')}catch(e){}
 const remember=c=>{recent=[c.client_code,...recent.filter(x=>x!==c.client_code)].slice(0,20);try{localStorage.setItem(LS,JSON.stringify(recent))}catch(e){}};
 let rows=[],limit=18;
 const COPYICON='<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/></svg>';
 const urlFor=c=>new URL(c.path,window.location.href).href;
 function initials(name){return String(name||'?').trim().split(/\s+/).slice(0,2).map(w=>w[0]).join('').toUpperCase().slice(0,2);}
 let toastTimer;
 function toast(msg){const el=$('toast');el.textContent=msg;el.hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>el.hidden=true,3500)}
 async function copyText(text){let ok=false;
  try{if(navigator.clipboard&&window.isSecureContext){await navigator.clipboard.writeText(text);ok=true}}catch(e){}
  if(!ok){const ta=document.createElement('textarea');ta.value=text;ta.style.cssText='position:fixed;left:-9999px;top:0';ta.setAttribute('readonly','');document.body.append(ta);ta.focus();ta.select();try{ok=!!document.execCommand('copy')}catch(e){}ta.remove()}
  if(!ok){window.prompt('Copia el enlace del cliente:',text)}return ok;
 }
 function makeRow(c){const root=document.createElement('div');root.className='row';root.setAttribute('role','listitem');
  const ava=document.createElement('div');ava.className='avatar';ava.textContent=initials(c.client_name);
  const main=document.createElement('div'),a=document.createElement('a');a.className='client-name';a.href=c.path;a.textContent=c.client_name;a.title='Ver catálogo de '+c.client_name;a.addEventListener('click',()=>remember(c));
  const code=document.createElement('span');code.className='client-code';code.textContent=c.client_code;main.append(a,code);
  const seller=document.createElement('div');seller.className='seller';seller.textContent=c.vendor_label||c.allVendors.join(', ');
  const btn=document.createElement('button');btn.type='button';btn.className='copy-btn';btn.innerHTML=COPYICON+'<span>Copiar link</span>';btn.setAttribute('aria-label','Copiar link de '+c.client_name);
  btn.addEventListener('click',async()=>{const url=urlFor(c);const copied=await copyText(url);if(copied){remember(c);btn.classList.add('copied');btn.querySelector('span').textContent='Copiado';setTimeout(()=>{btn.classList.remove('copied');btn.querySelector('span').textContent='Copiar link'},1800);toast('Enlace copiado: '+c.client_name);if(location.protocol==='file:')toast('Versión local: los links públicos funcionarán al subir la app a GitHub Pages.')}});
  root.append(ava,main,seller,btn);return root;
 }
 function render(){const q=norm($('searchInput').value.trim()),v=vendor.value,normalMode=!q&&!v;
  if(normalMode){const pinned=recent.map(code=>byCode.get(code)).filter(Boolean);const seen=new Set(pinned.map(c=>c.client_code));rows=[...pinned,...clients.filter(c=>!seen.has(c.client_code))];}
  else rows=clients.filter(c=>(!q||c.search.includes(q))&&(!v||c.allVendors.includes(v)));
  $('viewTitle').textContent=normalMode?(recent.length?'Clientes recientes y cartera':'Directorio de clientes'):'Resultados de búsqueda';
  $('resultsSummary').textContent=normalMode?'Selecciona un cliente o copia su enlace para compartirlo.':'Comparte el enlace personalizado con el cliente.';
  $('count').textContent=(normalMode?clients.length:rows.length).toLocaleString('es-MX')+' clientes';
  $('total').textContent=clients.length.toLocaleString('es-MX')+' clientes disponibles';
  const list=$('clientList');list.replaceChildren();
  if(!rows.length){const empty=document.createElement('div');empty.className='empty';empty.innerHTML='<strong>No encontramos clientes</strong>Intenta otro nombre, código o vendedor.';list.append(empty)}
  else{const frag=document.createDocumentFragment();for(const c of rows.slice(0,limit))frag.append(makeRow(c));list.append(frag)}
  $('more').hidden=rows.length<=limit;$('more').textContent='Mostrar más clientes ('+Math.min(18,rows.length-limit)+')';
 }
 let pending;
 $('searchInput').addEventListener('input',()=>{clearTimeout(pending);limit=18;$('clear').hidden=!$('searchInput').value;pending=setTimeout(render,80)});
 $('clear').addEventListener('click',()=>{$('searchInput').value='';$('clear').hidden=true;limit=18;render();$('searchInput').focus()});
 vendor.addEventListener('change',()=>{limit=18;render()});
 $('more').addEventListener('click',()=>{limit+=18;render()});
 $('searchInput').addEventListener('keydown',e=>{if(e.key==='Enter'&&rows.length===1){remember(rows[0]);location.href=rows[0].path;}});
 document.addEventListener('keydown',e=>{if(e.key==='/'&&document.activeElement!==$('searchInput')){e.preventDefault();$('searchInput').focus()}});
 render();
})();
