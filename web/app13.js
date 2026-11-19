(function(){if(window.__lumo)return;window.__lumo=1;var m=document.querySelector('meta[name=viewport]');if(!m){m=document.createElement('meta');m.name='viewport';document.head.appendChild(m);}m.content='width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover';var st=document.createElement('style');st.textContent="\n:root{\n--a1:#7c5cff; --a2:#22c1ff; --accent:linear-gradient(135deg,var(--a1),var(--a2));\n--bg:#0c0d1a; --panel:#13142a; --panel2:#1a1c36; --line:rgba(255,255,255,.07);\n--text:#eef0ff; --muted:#8d90b8; --hover:rgba(255,255,255,.05); --active:rgba(124,92,255,.18);\n--in:#1d1f3d; --out:linear-gradient(135deg,#6a4cf5,#3a7bff); --out-text:#fff; --out-muted:rgba(255,255,255,.72);\n--chatbg:#0e0f22; --danger:#ff5b7a; --ok:#3ee0a0; --shadow:0 18px 50px rgba(0,0,0,.45);\n--r:18px;\n}\n:root[data-theme=\"light\"]{\n--bg:#eef0fb; --panel:#ffffff; --panel2:#f4f5fd; --line:rgba(20,22,60,.08);\n--text:#14163a; --muted:#7276a0; --hover:rgba(20,22,60,.045); --active:rgba(124,92,255,.12);\n--in:#ffffff; --chatbg:#e7e9fb; --shadow:0 18px 50px rgba(40,40,110,.18);\n}\n*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}\nhtml,body{margin:0;height:100%;background:var(--bg);color:var(--text);font-family:Manrope,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;font-size:15px;overflow:hidden}\nbutton{font:inherit;color:inherit;border:0;background:none;cursor:pointer;padding:0}\ninput,textarea{font:inherit;color:inherit}\nsvg.i{width:22px;height:22px;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;flex:none}\nsvg.i.f{fill:currentColor;stroke:none}\n.hidden{display:none!important}\n.qrbox{display:flex;justify-content:center;margin:4px 0 16px}\n#qrImg{width:224px;height:224px;background:#fff;border-radius:22px;padding:14px;display:grid;place-items:center;box-shadow:0 12px 34px rgba(0,0,0,.2);position:relative}\n#qrImg svg{width:100%;height:100%;display:block}\n#qrImg .qrmark{position:absolute;left:50%;top:50%;width:46px;height:46px;margin:-23px 0 0 -23px;border-radius:14px;background:linear-gradient(135deg,var(--accent),var(--a2));display:grid;place-items:center;border:4px solid #fff}\n#qrImg .qrmark svg{width:22px;height:22px;color:#fff}\n.qrspin{width:34px;height:34px;border:3px solid #e3e3ea;border-top-color:#7c5cff;border-radius:50%;animation:lmspin 1s linear infinite}\n@keyframes lmspin{to{transform:rotate(360deg)}}\n.qrh{text-align:center;margin:0 0 12px;font-size:19px}\n.qrsteps{margin:0 0 14px;padding-left:22px;color:var(--muted);line-height:1.75;font-size:14.5px}\n.qrsteps b{color:var(--text)}\n.qrst{text-align:center;min-height:20px;font-weight:700;color:var(--accent);margin-bottom:10px;font-size:14px}\n.lnk{display:block;margin:16px auto 0;color:var(--accent);font-weight:700;font-size:14px;background:none;padding:6px}\n#qrScan{position:fixed;inset:0;z-index:99950;background:#000;display:flex;align-items:center;justify-content:center;animation:fade .2s}\n#qrScan video{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}\n#qrScan .frame{position:relative;width:min(70vw,280px);aspect-ratio:1;border-radius:30px;box-shadow:0 0 0 9999px rgba(0,0,0,.55);border:3px solid rgba(255,255,255,.92)}\n#qrScan .tt{position:absolute;top:calc(26px + env(safe-area-inset-top));left:0;right:0;text-align:center;color:#fff;font-weight:800;font-size:19px;z-index:2}\n#qrScan .hint{position:absolute;bottom:calc(112px + env(safe-area-inset-bottom));left:24px;right:24px;text-align:center;color:#fff;opacity:.88;z-index:2;font-size:14.5px;line-height:1.45}\n#qrScan .close{position:absolute;bottom:calc(32px + env(safe-area-inset-bottom));left:50%;margin-left:-30px;width:60px;height:60px;border-radius:50%;background:rgba(255,255,255,.2);color:#fff;display:grid;place-items:center;z-index:2}\n#qrScan .close svg{width:26px;height:26px}\n.grad{background:var(--accent)}\n.gtext{background:var(--accent);-webkit-background-clip:text;background-clip:text;color:transparent}\n::-webkit-scrollbar{width:6px;height:6px}::-webkit-scrollbar-thumb{background:rgba(140,140,200,.25);border-radius:6px}\n#auth{position:fixed;inset:0;z-index:99000;display:grid;place-items:center;padding:20px;overflow:auto;\nbackground:radial-gradient(900px 600px at 15% 10%,rgba(124,92,255,.35),transparent 60%),radial-gradient(800px 600px at 90% 90%,rgba(34,193,255,.25),transparent 60%),var(--bg)}\n.authcard{width:100%;max-width:400px;background:color-mix(in srgb,var(--panel) 85%,transparent);backdrop-filter:blur(20px);border:1px solid var(--line);border-radius:28px;padding:34px 28px;box-shadow:var(--shadow)}\n.logo{display:flex;align-items:center;gap:12px;justify-content:center;margin-bottom:6px}\n.logo .mark{width:52px;height:52px;border-radius:16px;display:grid;place-items:center;background:var(--accent);box-shadow:0 10px 30px rgba(124,92,255,.5)}\n.logo h1{font-size:34px;margin:0;font-weight:800;letter-spacing:-1px}\n.sub{color:var(--muted);text-align:center;margin:0 0 24px}\n.tabs{display:flex;background:var(--panel2);border-radius:14px;padding:4px;margin-bottom:18px}\n.tabs button{flex:1;padding:10px;border-radius:11px;font-weight:700;color:var(--muted)}\n.tabs button.on{background:var(--panel);color:var(--text);box-shadow:0 2px 10px rgba(0,0,0,.15)}\n.field{margin-bottom:12px}\n.field label{display:block;font-size:12px;color:var(--muted);margin:0 0 6px 4px;font-weight:600}\n.inp{width:100%;background:var(--panel2);border:1.5px solid transparent;border-radius:14px;padding:13px 14px;outline:none;transition:.15s}\n.inp:focus{border-color:var(--a1);background:var(--panel)}\n.btn{display:inline-flex;align-items:center;justify-content:center;gap:8px;padding:13px 18px;border-radius:14px;font-weight:700;transition:.15s}\n.btn.primary{background:var(--accent);color:#fff;box-shadow:0 8px 24px rgba(124,92,255,.35)}\n.btn.primary:hover{filter:brightness(1.08)}\n.btn.ghost{background:var(--panel2)}\n.btn.danger{background:rgba(255,91,122,.12);color:var(--danger)}\n.btn.w{width:100%}\n.err{color:var(--danger);font-size:13px;min-height:18px;margin:6px 4px}\n#app{position:fixed;inset:0;display:flex;z-index:99000;background:var(--bg)}\n#lumo-root input,#lumo-root textarea,#lumo-root button{font-family:inherit;letter-spacing:normal;text-transform:none;box-shadow:none}\n#side{width:380px;min-width:300px;background:var(--panel);border-right:1px solid var(--line);display:flex;flex-direction:column;position:relative;z-index:2}\n#main{flex:1;display:flex;flex-direction:column;min-width:0;position:relative;background:var(--chatbg)}\n#info{width:360px;background:var(--panel);border-left:1px solid var(--line);display:flex;flex-direction:column;overflow:auto}\n.top{display:flex;align-items:center;gap:10px;padding:12px 14px;min-height:62px}\n.tophead{display:flex;align-items:center;gap:10px;padding:calc(10px + env(safe-area-inset-top)) 12px 6px;min-height:58px}\n.tophead b{flex:1;text-align:center;font-size:18px;font-weight:800;letter-spacing:-.2px}\n.hbtn{width:44px;height:44px;border-radius:22px;display:grid;place-items:center;color:var(--text);background:var(--panel2);border:1px solid var(--line);flex:none;transition:.15s}\n.hbtn:hover{background:var(--active)}\n.hbtn.hide{visibility:hidden}\n.sbar{padding:2px 14px 10px}\n.sbar .search{height:40px;border-radius:14px}\n#tabs{position:absolute;left:12px;right:12px;bottom:calc(10px + env(safe-area-inset-bottom));display:flex;gap:2px;padding:6px;border-radius:34px;\nbackground:color-mix(in srgb,var(--panel) 72%,transparent);-webkit-backdrop-filter:blur(22px) saturate(1.7);backdrop-filter:blur(22px) saturate(1.7);\nborder:1px solid var(--line);box-shadow:0 12px 34px rgba(0,0,0,.28);z-index:12}\n#tabs button{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;padding:7px 0 6px;border-radius:28px;color:var(--text);position:relative;transition:background .2s,color .2s;min-width:0}\n#tabs button:hover{background:var(--hover)}\n#tabs button.on{background:var(--active);color:var(--a1)}\n#tabs .ti{display:grid;place-items:center;height:30px}\n#tabs .ti svg{width:28px;height:28px}\n#tabs .tl{font-size:11.5px;font-weight:700;white-space:nowrap}\n#tabs .badge{position:absolute;top:1px;left:calc(50% + 2px);min-width:20px;height:20px;font-size:11.5px;padding:0 6px;border-radius:10px;border:2px solid var(--panel)}\n#tabs .badge.red{background:#ff3b30}\n#tabs .av.tabav{width:28px;height:28px;font-size:11px}\n#tabs button.on .av.tabav{box-shadow:0 0 0 2px var(--a1)}\n.folders{background:var(--panel2);border-radius:22px;margin:0 14px 8px;padding:4px!important;gap:2px!important;scrollbar-width:none}\n.folders::-webkit-scrollbar{display:none}\n.folders button{background:none!important;color:var(--text)!important;display:inline-flex;align-items:center;gap:6px;padding:8px 14px!important;font-size:14px!important}\n.folders button.on{background:var(--panel)!important;color:var(--text)!important;box-shadow:0 1px 6px rgba(0,0,0,.12)}\n.folders .fc{min-width:20px;height:20px;padding:0 6px;border-radius:10px;background:var(--a1);color:#fff;font-size:11.5px;font-weight:800;display:inline-grid;place-items:center}\n#list,#pane{padding-bottom:calc(110px + env(safe-area-inset-bottom))!important}\n.row .t2 .pv{white-space:normal;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.3}\n.row{padding:8px 10px;transition:background .15s ease,opacity .15s ease,transform .1s ease}.row:active{transform:scale(.985)}\n.row .badge{background:var(--a1)}\n.row .badge.mute{background:#a3a6c2}\n.row .urh{display:inline-flex;color:#f0384f;margin:1px 4px 0;flex:none;animation:urpop .35s cubic-bezier(.34,1.56,.64,1)}.row .urh.mute{color:#a3a6c2}@keyframes urpop{from{transform:scale(.3);opacity:0}}\n.row .urv svg{width:14px;height:14px;vertical-align:-2px;margin-right:4px}\n.ib{width:40px;height:40px;border-radius:50%;display:grid;place-items:center;color:var(--muted);transition:.15s;flex:none}\n.ib:hover{background:var(--hover);color:var(--text)}\n.search{flex:1;display:flex;align-items:center;gap:8px;background:var(--panel2);border-radius:22px;padding:0 14px;height:42px;border:1.5px solid transparent}\n.search:focus-within{border-color:var(--a1)}\n.search input{flex:1;background:none;border:0;outline:none;min-width:0}\n.search svg{width:18px;height:18px;color:var(--muted)}\n.folders{display:flex;overflow-x:auto}\n.folders button{padding:7px 14px;border-radius:20px;color:var(--muted);font-weight:700;font-size:13px;white-space:nowrap;background:var(--panel2)}\n.folders button.on{background:var(--accent);color:#fff}\n#list,#pane{flex:1;overflow-y:auto;padding:0 8px 90px}\n.rbtn{width:40px;height:40px;border-radius:50%;display:grid;place-items:center;color:var(--a1);flex:none}\n.rbtn:hover{background:var(--active)}\n.miss{color:var(--danger)!important}\n.cdir{width:15px;height:15px}\n.pcard{display:flex;flex-direction:column;align-items:center;padding:8px 10px 18px;text-align:center}\n.pcard h2{margin:12px 0 2px;font-size:22px;font-weight:800}\n.pcard .st{color:var(--muted);font-weight:600}\n.setgrp{background:var(--panel2);border-radius:18px;padding:6px 10px;margin:0 4px 12px}\n.setgrp .set{padding:11px 4px}\n.sethdr{font-size:12px;color:var(--muted);font-weight:700;text-transform:uppercase;letter-spacing:.06em;padding:8px 14px 6px}\n#lumo-root,#lumo-root *,.ov,.ov *,#cmenu,#cmenu *,#call,#call *{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}\n#lumo-root input,#lumo-root textarea,.ov input,.ov textarea{-webkit-user-select:text;user-select:text;-webkit-touch-callout:default}\n#lumo-root img,#lumo-root video,#lumo-root a{-webkit-user-drag:none}\n.sec{font-size:12px;color:var(--muted);font-weight:700;padding:12px 10px 6px;text-transform:uppercase;letter-spacing:.06em}\n.row{display:flex;align-items:center;gap:12px;padding:9px 10px;border-radius:16px;cursor:pointer;transition:background .12s;position:relative}\n.row:hover{background:var(--hover)}\n.row.on{background:var(--active)}\n.row .mid{flex:1;min-width:0}\n.row .t1{display:flex;align-items:center;gap:6px;font-weight:700}\n.row .t1 .nm{overflow:hidden;text-overflow:ellipsis;white-space:nowrap;flex:1;display:flex;align-items:center;gap:5px}\n.row .t1 time{font-size:12px;color:var(--muted);font-weight:600;display:flex;align-items:center;gap:3px}\n.row .t2{display:flex;align-items:center;gap:6px;color:var(--muted);margin-top:3px;font-size:14px}\n.row .t2 .pv{flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;display:flex;align-items:center;gap:4px}\n.row .t2 .pv b{color:var(--text);font-weight:600}\n.row .t2 .pv svg{width:15px;height:15px}\n.typing{color:var(--a2)!important;font-weight:600}\n.badge{min-width:22px;height:22px;padding:0 7px;border-radius:11px;background:var(--accent);color:#fff;font-size:12px;font-weight:800;display:grid;place-items:center}\n.badge.mute{background:var(--muted)}\n.mini{width:15px;height:15px;color:var(--muted)}\n.chk{color:var(--a2)}\n.fab{position:absolute;right:20px;bottom:calc(84px + env(safe-area-inset-bottom));width:56px;height:56px;border-radius:50%;background:var(--accent);color:#fff;display:grid;place-items:center;box-shadow:0 10px 30px rgba(124,92,255,.5);transition:transform .2s}\n.fab:hover{transform:scale(1.06) rotate(90deg)}\n.drop{position:absolute;background:var(--panel);border:1px solid var(--line);border-radius:16px;box-shadow:var(--shadow);padding:6px;min-width:220px;z-index:99600;animation:pop .14s ease-out}\n.drop button{display:flex;align-items:center;gap:12px;width:100%;padding:10px 12px;border-radius:11px;font-weight:600;text-align:left}\n.drop button:hover{background:var(--hover)}\n.drop button svg{width:20px;height:20px;color:var(--muted)}\n.drop button.red,.drop button.red svg{color:var(--danger)}\n@keyframes pop{from{opacity:0;transform:scale(.96)}to{opacity:1;transform:none}}\n.av{width:54px;height:54px;border-radius:50%;flex:none;display:grid;place-items:center;color:#fff;font-weight:800;font-size:19px;position:relative;background-size:cover;background-position:center;user-select:none}\n.av.s{width:40px;height:40px;font-size:15px}.av.xs{width:32px;height:32px;font-size:13px}.av.l{width:110px;height:110px;font-size:40px}\n.av .on{position:absolute;right:1px;bottom:1px;width:14px;height:14px;border-radius:50%;background:var(--ok);border:3px solid var(--panel)}\n.av.s .on{width:12px;height:12px;border-width:2px}\n.c0{background:linear-gradient(135deg,#ff8a5b,#ff5b8a)}.c1{background:linear-gradient(135deg,#7c5cff,#b05cff)}.c2{background:linear-gradient(135deg,#22c1ff,#3a7bff)}\n.c3{background:linear-gradient(135deg,#2ee6a6,#13b0a5)}.c4{background:linear-gradient(135deg,#ffc94a,#ff8a3d)}.c5{background:linear-gradient(135deg,#ff5b7a,#c44dff)}\n.c6{background:linear-gradient(135deg,#5bd0ff,#7c5cff)}.c7{background:linear-gradient(135deg,#9be15d,#00c6a7)}\n.nc0{color:#ff7a6b}.nc1{color:#a48bff}.nc2{color:#36b8ff}.nc3{color:#25c99a}.nc4{color:#f0a23a}.nc5{color:#ff5b9a}.nc6{color:#6aa8ff}.nc7{color:#52c46e}\n#empty{flex:1;display:grid;place-items:center;text-align:center;color:var(--muted)}\n#empty .pill{background:color-mix(in srgb,var(--panel) 70%,transparent);padding:10px 18px;border-radius:20px;font-weight:600;backdrop-filter:blur(10px)}\n.pattern{position:absolute;inset:0;pointer-events:none;opacity:.5;\nbackground-image:radial-gradient(circle at 20% 20%,rgba(124,92,255,.22),transparent 40%),radial-gradient(circle at 80% 70%,rgba(34,193,255,.16),transparent 45%),\nurl(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120' viewBox='0 0 120 120'%3E%3Cg fill='none' stroke='%238080c0' stroke-opacity='.13' stroke-width='1.5'%3E%3Ccircle cx='20' cy='20' r='6'/%3E%3Cpath d='M70 15l8 8M78 15l-8 8'/%3E%3Cpath d='M95 60a8 8 0 1 0 0 .1'/%3E%3Cpath d='M20 80q10-12 20 0t20 0'/%3E%3Cpath d='M60 100l6-10 6 10z'/%3E%3C/g%3E%3C/svg%3E\")}\n#chat{flex:1;display:flex;flex-direction:column;min-height:0;position:relative}\n#chathead{display:flex;align-items:center;gap:10px;padding:8px 10px;min-height:62px;background:color-mix(in srgb,var(--panel) 88%,transparent);backdrop-filter:blur(18px);border-bottom:1px solid var(--line);z-index:3}\n#chathead .who{flex:1;min-width:0;cursor:pointer;display:flex;align-items:center;gap:12px}\n#chathead .nm{font-weight:800;font-size:16px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;display:flex;align-items:center;gap:6px}\n#chathead .st{font-size:13px;color:var(--muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n#chathead .st.live{color:var(--a2)}\n#back{display:none}\n#pinbar{display:flex;align-items:center;gap:10px;padding:8px 16px;background:color-mix(in srgb,var(--panel) 88%,transparent);backdrop-filter:blur(18px);border-bottom:1px solid var(--line);cursor:pointer;z-index:3}\n#pinbar .bar{width:3px;align-self:stretch;border-radius:2px;background:var(--accent)}\n#pinbar .tx{flex:1;min-width:0;font-size:13px}\n#pinbar .tx b{color:var(--a1);display:block}\n#pinbar .tx span{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--muted)}\n#insearch{display:flex;gap:8px;padding:8px 12px;background:var(--panel);border-bottom:1px solid var(--line);align-items:center;z-index:3}\n#msgs{flex:1;overflow-y:auto;overflow-x:hidden;padding:12px 0 8px;position:relative;z-index:1;overscroll-behavior:contain;display:flex;flex-direction:column}\n#mw{margin-top:auto;width:100%}\n.wrap{max-width:760px;margin:0 auto;padding:0 14px}\n.day{text-align:center;margin:14px 0 8px;position:sticky;top:4px;z-index:2} #hMore{display:none!important} .lxrow{display:flex;align-items:center;gap:8px;margin-top:5px;clear:both} .lxreact{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:14px;background:rgba(245,176,74,.22);border:1px solid rgba(245,176,74,.5);font-weight:700;font-size:12.5px} .lxviews{margin-left:auto;font-size:11.5px;opacity:.7}\n.day span{background:rgba(0,0,0,.38);padding:5px 12px;border-radius:14px;font-size:13px;font-weight:700;color:#fff}\n.sys{text-align:center;margin:8px 0}\n.sys span{background:rgba(0,0,0,.38);padding:5px 12px;border-radius:14px;font-size:13px;font-weight:600;color:#fff;display:inline-block;backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px)}\n.lxempty{display:flex;flex-direction:column;align-items:center;gap:14px;text-align:center;padding:24px;max-width:260px}\n.lxempty svg{filter:drop-shadow(0 10px 24px rgba(124,92,255,.25))}\n.lxempty-t{font-weight:800;font-size:17px;color:var(--text)}\n.lxempty-s{font-size:13.5px;color:var(--muted)}\n.m{display:flex;gap:8px;align-items:flex-end;margin:2px 0;position:relative}\n.m.me{flex-direction:row-reverse}\n.m .avs{width:34px;flex:none}\n.b{max-width:min(78%,520px);background:var(--in);border-radius:var(--r);padding:7px 11px 7px;position:relative;box-shadow:0 1px 2px rgba(0,0,0,.12);word-wrap:break-word;overflow-wrap:anywhere;animation:in .18s ease-out}\n@keyframes in{from{opacity:0;transform:translateY(6px) scale(.98)}to{opacity:1;transform:none}}\n.m.me .b{background:var(--out);color:var(--out-text)}\n.m.tail .b{border-bottom-left-radius:6px}\n.m.me.tail .b{border-bottom-left-radius:var(--r);border-bottom-right-radius:6px}\n.m.grp:not(.first) .b{border-top-left-radius:8px}\n.m.me.grp:not(.first) .b{border-top-left-radius:var(--r);border-top-right-radius:8px}\n.b .sn{font-weight:800;font-size:13.5px;margin-bottom:2px;display:block;cursor:pointer}\n.b .fw{font-size:13px;margin-bottom:3px;opacity:.85;display:flex;gap:5px;align-items:center}\n.b .fw svg{width:14px;height:14px}\n.b .txt{white-space:pre-wrap;line-height:1.42;font-size:var(--msgfs,15px)}\n.b .txt a{color:inherit;text-decoration:underline}\n.m:not(.me) .b .txt a{color:var(--a2)}\n.b code{background:rgba(0,0,0,.2);padding:1px 5px;border-radius:6px;font-family:ui-monospace,Menlo,monospace;font-size:13px}\n.meta{float:right;display:inline-flex;align-items:center;gap:3px;font-size:11.5px;margin:6px -2px -3px 10px;color:var(--muted);font-weight:600;position:relative;top:2px}\n.m.me .meta{color:var(--out-muted)}\n.meta svg{width:16px;height:16px}\n.meta .rd{color:#9ef0ff}\n.rep{display:flex;gap:8px;border-radius:10px;padding:5px 8px;margin:2px 0 5px;background:rgba(124,92,255,.12);cursor:pointer;font-size:13.5px}\n.m.me .rep{background:rgba(255,255,255,.16)}\n.rep .bar{width:3px;border-radius:2px;background:var(--a1);flex:none}\n.m.me .rep .bar{background:#fff}\n.rep .rt{min-width:0}.rep .rt b{display:block;font-size:13px}.rep .rt span{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;opacity:.8;max-width:300px}\n.reacts{display:flex;flex-wrap:wrap;gap:4px;margin-top:6px;clear:both}\n.rc{display:inline-flex;align-items:center;gap:4px;padding:3px 8px 3px 6px;border-radius:14px;background:rgba(124,92,255,.15);font-size:13px;font-weight:700;cursor:pointer;transition:.12s}\n.m.me .rc{background:rgba(255,255,255,.18)}\n.rc.mine{background:var(--a1);color:#fff}\n.m.me .rc.mine{background:#fff;color:#4b3bd6}\n.rc .e{font-size:15px}\n.b.media{padding:4px}\n.b.media .cap{padding:4px 7px 2px}\n.b img.ph,.b video.ph{display:block;max-width:100%;max-height:420px;border-radius:14px;cursor:pointer;min-width:160px;object-fit:cover;background:rgba(0,0,0,.2)}\n.b.media .meta.ov{position:absolute;right:10px;bottom:10px;background:rgba(0,0,0,.45);color:#fff;padding:2px 7px;border-radius:10px;margin:0;float:none;top:auto}\n.b.media .meta.ov .rd{color:#9ef0ff}\n.b.stk{background:none!important;box-shadow:none;padding:0}\n.b.stk .big{font-size:96px;line-height:1.1}.b.stk .big svg{width:116px;height:116px;display:block}\n.b.stk .meta{background:rgba(0,0,0,.35);color:#fff;padding:2px 7px;border-radius:10px;float:none}\n.file{display:flex;align-items:center;gap:10px;min-width:220px;text-decoration:none;color:inherit;padding:2px 0}\n.file .fi{width:46px;height:46px;border-radius:50%;background:var(--accent);display:grid;place-items:center;color:#fff;flex:none}\n.m.me .file .fi{background:rgba(255,255,255,.25)}\n.file .fn{font-weight:700;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;max-width:230px}\n.file .fs{font-size:12.5px;opacity:.7}\n.voice{display:flex;align-items:center;gap:10px;min-width:230px;padding:2px 0}\n.voice .pp{width:44px;height:44px;border-radius:50%;background:var(--accent);color:#fff;display:grid;place-items:center;flex:none}\n.m.me .voice .pp{background:#fff;color:#5b44ee}\n.voice .pp svg{width:20px;height:20px}\n.wave{display:flex;align-items:center;gap:2px;height:30px;cursor:pointer;flex:1}\n.wave i{display:block;width:3px;border-radius:2px;background:currentColor;opacity:.35;min-height:3px}\n.wave i.p{opacity:1}\n.m:not(.me) .wave i.p{color:var(--a1)}\n.voice .vd{font-size:12px;opacity:.75;font-weight:600;margin-top:2px}\n.vn{position:relative;width:240px;height:240px;cursor:pointer}\n.vn video{width:240px;height:240px;border-radius:50%;object-fit:cover;display:block;background:#000}\n.vn svg.ring{position:absolute;inset:-6px;width:252px;height:252px;transform:rotate(-90deg);pointer-events:none}\n.vn .vnd{position:absolute;left:10px;bottom:12px;background:rgba(0,0,0,.45);color:#fff;border-radius:10px;padding:2px 8px;font-size:12px;font-weight:700;display:flex;align-items:center;gap:4px}\n.vn .vnd svg{width:14px;height:14px}\n.vn .muteic{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:52px;height:52px;border-radius:50%;background:rgba(0,0,0,.4);display:grid;place-items:center;color:#fff;transition:.2s}\n.b.vnb{background:none!important;box-shadow:none;padding:0}\n.b.vnb .meta{position:absolute;right:6px;bottom:8px;background:rgba(0,0,0,.45);color:#fff;padding:2px 7px;border-radius:10px;margin:0;float:none;top:auto}\n.callm{display:flex;align-items:center;gap:10px;min-width:180px}\n.callm .ci{width:40px;height:40px;border-radius:50%;display:grid;place-items:center;background:rgba(124,92,255,.15)}\n.m.me .callm .ci{background:rgba(255,255,255,.2)}\n.callm .ci.miss{color:var(--danger)}\n.del{font-style:italic;opacity:.6;display:flex;align-items:center;gap:6px}\n.hl .b{animation:hl 1.6s}\n@keyframes hl{0%,40%{box-shadow:0 0 0 3px var(--a2)}}\n#down{position:absolute;right:20px;bottom:90px;width:48px;height:48px;border-radius:50%;background:var(--panel);box-shadow:var(--shadow);display:grid;place-items:center;z-index:4;color:var(--muted)}\n#down .badge{position:absolute;top:-6px;right:-4px}\n.typingdots{display:inline-flex;gap:3px;margin-left:4px;vertical-align:middle}\n.typingdots i{width:5px;height:5px;border-radius:50%;background:currentColor;animation:td 1.2s infinite}\n.typingdots i:nth-child(2){animation-delay:.2s}.typingdots i:nth-child(3){animation-delay:.4s}\n@keyframes td{0%,60%,100%{opacity:.3;transform:none}30%{opacity:1;transform:translateY(-3px)}}\n#composer{padding:8px 12px calc(10px + env(safe-area-inset-bottom));z-index:3}\n#composer .wrap{display:flex;align-items:flex-end;gap:8px;padding:0}\n.cbox{flex:1;background:var(--panel);border-radius:24px;box-shadow:0 2px 10px rgba(0,0,0,.12);display:flex;flex-direction:column;min-width:0}\n.cline{display:flex;align-items:flex-end;padding:4px 4px}\n#txt{flex:1;resize:none;background:none;border:0;outline:none;padding:11px 6px;max-height:180px;line-height:1.4;min-height:44px}\n.ctx{display:flex;align-items:center;gap:10px;padding:8px 12px 2px;border-bottom:1px solid var(--line);margin:0 6px}\n.ctx svg{color:var(--a1)}\n.ctx .tx{flex:1;min-width:0;font-size:13px}.ctx .tx b{color:var(--a1);display:block}.ctx .tx span{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--muted)}\n#sendbtn *{pointer-events:none}\n#sendbtn,#recbar,#vnrec{-webkit-touch-callout:none;-webkit-user-select:none;user-select:none}\n#sendbtn{width:52px;height:52px;border-radius:50%;background:var(--accent);color:#fff;display:grid;place-items:center;flex:none;box-shadow:0 6px 20px rgba(124,92,255,.4);touch-action:none;user-select:none;-webkit-user-select:none;transition:transform .15s}\n#sendbtn.rec{transform:scale(1.35);background:var(--danger)}\n#recbar{flex:1;display:flex;align-items:center;gap:12px;background:var(--panel);border-radius:24px;padding:0 16px;height:52px;box-shadow:0 2px 10px rgba(0,0,0,.12)}\n#recbar .dot{width:10px;height:10px;border-radius:50%;background:var(--danger);animation:blink 1s infinite}\n@keyframes blink{50%{opacity:.2}}\n#recbar .hint{flex:1;text-align:center;color:var(--muted);font-weight:600;font-size:14px;white-space:nowrap;overflow:hidden}\n#recbar .tm{font-weight:700;font-variant-numeric:tabular-nums}\n#lockic{position:absolute;right:16px;bottom:84px;width:44px;height:84px;border-radius:22px;background:var(--panel);box-shadow:var(--shadow);display:flex;flex-direction:column;align-items:center;justify-content:space-around;padding:8px 0;color:var(--muted);z-index:5;animation:pop .15s}\n#readonly{padding:14px;text-align:center;z-index:3}\n#readonly button{background:var(--panel);padding:12px 26px;border-radius:20px;font-weight:700;color:var(--a1);box-shadow:0 2px 10px rgba(0,0,0,.12)}\n#emoji{position:absolute;bottom:76px;left:12px;width:340px;max-width:calc(100% - 24px);height:340px;background:var(--panel);border-radius:20px;box-shadow:var(--shadow);z-index:6;display:flex;flex-direction:column;animation:pop .15s;border:1px solid var(--line)}\n#emoji .et{display:flex;gap:4px;padding:8px;border-bottom:1px solid var(--line)}\n#emoji .et button{padding:6px 12px;border-radius:12px;font-weight:700;font-size:13px;color:var(--muted)}\n#emoji .et button.on{background:var(--active);color:var(--text)}\n#emoji .eg{flex:1;overflow:auto;display:grid;grid-template-columns:repeat(8,1fr);padding:8px;gap:2px;align-content:start}\n#emoji .eg.stk{grid-template-columns:repeat(4,1fr)}\n#emoji .eg button{font-size:24px;height:40px;border-radius:10px}\n#emoji .eg.stk button{font-size:52px;height:76px}#emoji .eg.stk button svg{width:40px;height:40px;display:block}\n#emoji .eg button:hover{background:var(--hover)}\n#cmenu{position:fixed;z-index:99600}\n#cmenu .rx{display:flex;gap:2px;background:var(--panel);border-radius:26px;padding:5px;box-shadow:var(--shadow);margin-bottom:8px;border:1px solid var(--line);width:max-content}\n#cmenu .rx button{font-size:24px;width:40px;height:40px;border-radius:50%;transition:transform .12s}\n#cmenu .rx button:hover{transform:scale(1.25);background:var(--hover)}\n#cmenu .drop{position:static}\n.ov{position:fixed;inset:0;background:rgba(5,6,20,.55);backdrop-filter:blur(6px);z-index:99500;display:grid;place-items:center;padding:16px;animation:fade .15s}\n@keyframes fade{from{opacity:0}}\n.modal{background:var(--panel);border-radius:26px;width:100%;max-width:440px;max-height:min(720px,92vh);display:flex;flex-direction:column;box-shadow:var(--shadow);animation:pop .16s;overflow:hidden}\n.modal .mh{display:flex;align-items:center;gap:8px;padding:14px 14px 8px 20px}\n.modal .mh h3{flex:1;margin:0;font-size:19px;font-weight:800}\n.modal .mb{padding:6px 20px 18px;overflow:auto;flex:1}\n.modal .mf{padding:12px 20px 18px;display:flex;gap:10px;justify-content:flex-end}\n.chips{display:flex;flex-wrap:wrap;gap:6px;margin-bottom:10px}\n.chip{display:inline-flex;align-items:center;gap:6px;background:var(--active);padding:4px 10px 4px 4px;border-radius:20px;font-weight:600;font-size:13px;cursor:pointer;transition:transform .15s ease,opacity .15s ease}.chip:active{transform:scale(.95)}\n.sel{width:22px;height:22px;border-radius:50%;border:2px solid var(--muted);display:grid;place-items:center;flex:none}\n.sel.on{background:var(--accent);border-color:transparent;color:#fff}\n.sel svg{width:14px;height:14px;stroke-width:3}\n.avedit{display:flex;flex-direction:column;align-items:center;gap:10px;margin:6px 0 16px}\n.avedit .av{cursor:pointer}\n.avedit .av::after{content:\"\";position:absolute;inset:0;border-radius:50%;background:rgba(0,0,0,.35) url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z'/%3E%3Ccircle cx='12' cy='13' r='3'/%3E%3C/svg%3E\") center/34px no-repeat;opacity:0;transition:.15s}\n.avedit .av:hover::after{opacity:1}\n.swatches{display:flex;gap:10px;flex-wrap:wrap}\n.sw{width:36px;height:36px;border-radius:50%;cursor:pointer;border:3px solid transparent}\n.sw.on{border-color:var(--text)}\n.set{display:flex;align-items:center;gap:14px;padding:12px 4px;border-radius:12px;cursor:pointer}\n.set:hover{background:var(--hover)}\n.set .sl{flex:1;font-weight:600}\n.tog{width:44px;height:26px;border-radius:13px;background:var(--panel2);position:relative;transition:.2s;flex:none;border:1px solid var(--line)}\n.tog::after{content:\"\";position:absolute;width:20px;height:20px;border-radius:50%;background:#fff;top:2px;left:2px;transition:.2s;box-shadow:0 1px 4px rgba(0,0,0,.3)}\n.tog.on{background:var(--a1)}.tog.on::after{left:20px}\n.ihead{display:flex;flex-direction:column;align-items:center;padding:10px 20px 18px;text-align:center}\n.ihead h2{margin:14px 0 2px;font-size:22px;font-weight:800}\n.ihead .st{color:var(--muted)}\n.iact{display:flex;gap:10px;justify-content:center;margin-top:16px}\n.iact button{display:flex;flex-direction:column;align-items:center;gap:6px;font-size:12px;font-weight:700;color:var(--muted);width:76px;padding:10px 0;border-radius:16px;background:var(--panel2)}\n.iact button svg{color:var(--a1)}\n.iblock{padding:6px 12px;border-top:1px solid var(--line)}\n.ikv{padding:10px 8px;transition:background .15s ease,opacity .15s ease}\n.ikv .k{font-size:12px;color:var(--muted);font-weight:600}\n.ikv .v{white-space:pre-wrap}\n.mgrid{display:grid;grid-template-columns:repeat(3,1fr);gap:3px;padding:6px 8px}\n.mgrid div{aspect-ratio:1;background-size:cover;background-position:center;border-radius:8px;cursor:pointer;background-color:var(--panel2);position:relative}\n.mgrid div svg{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);color:#fff}\n.role{font-size:12px;color:var(--a1);font-weight:700}\n#vnrec{position:fixed;inset:0;z-index:99700;background:rgba(5,6,20,.72);backdrop-filter:blur(12px);display:grid;place-items:center;animation:fade .15s}\n#vnrec .circ{position:relative;width:min(78vw,320px);height:min(78vw,320px)}\n#nbanner{position:fixed;left:50%;top:calc(10px + env(safe-area-inset-top));transform:translateX(-50%);z-index:99960;width:min(440px,calc(100vw - 20px));background:color-mix(in srgb,var(--panel) 92%,transparent);backdrop-filter:blur(18px);-webkit-backdrop-filter:blur(18px);border:1px solid var(--line);border-radius:20px;box-shadow:var(--shadow);display:flex;gap:12px;align-items:center;padding:10px 12px;cursor:pointer;animation:nb .28s cubic-bezier(.2,.9,.3,1.2)}\n@keyframes nb{from{opacity:0;transform:translate(-50%,-30px)}to{opacity:1;transform:translate(-50%,0)}}\n#nbanner .tx{flex:1;min-width:0}#nbanner b{display:block;font-size:14.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n#nbanner span{display:block;color:var(--muted);font-size:13.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n#vnrec canvas{width:100%;height:100%;border-radius:50%;display:block;background:#000}\n.tgcard{display:flex;align-items:center;gap:12px;padding:12px 4px}\n.tgcard .tgi{width:40px;height:40px;border-radius:12px;background:linear-gradient(135deg,#2aabee,#229ed9);display:grid;place-items:center;color:#fff;flex:none}\n.tgcard .tx{flex:1;min-width:0}.tgcard .tx b{display:block}.tgcard .tx span{display:block;color:var(--muted);font-size:13px}\n.tgbtn{padding:9px 14px;border-radius:12px;background:linear-gradient(135deg,#2aabee,#229ed9);color:#fff;font-weight:700;font-size:13.5px;text-decoration:none;white-space:nowrap}\n#vnrec video{width:100%;height:100%;border-radius:50%;object-fit:cover;transform:scaleX(-1);background:#000}\n#vnrec svg.ring{position:absolute;inset:-10px;width:calc(100% + 20px);height:calc(100% + 20px);transform:rotate(-90deg)}\n#vnrec .vtm{position:absolute;top:-48px;left:50%;transform:translateX(-50%);color:#fff;font-weight:800;display:flex;align-items:center;gap:8px;font-size:18px}\n#vnrec .vbtns{position:absolute;bottom:-84px;left:50%;transform:translateX(-50%);display:flex;gap:18px}\n#vnrec .vbtns button{width:56px;height:56px;border-radius:50%;background:rgba(255,255,255,.15);color:#fff;display:grid;place-items:center}\n#vnrec .vbtns button.go{background:var(--accent)}\n#lightbox{position:fixed;inset:0;z-index:99800;background:rgba(0,0,0,.92);display:grid;place-items:center;animation:fade .15s}\n#lightbox img,#lightbox video{max-width:96vw;max-height:88vh;border-radius:10px}\n#lightbox .ib{position:absolute;top:14px;right:14px;color:#fff;background:rgba(255,255,255,.1)}\n#lightbox .dl{right:64px}\n#call{position:fixed;inset:0;z-index:99900;background:radial-gradient(800px 500px at 50% 0%,rgba(124,92,255,.45),transparent 70%),#07081a;color:#fff;display:flex;flex-direction:column;align-items:center;animation:fade .2s}\n#call #rv{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;background:#000}\n#call #rimg,#call #rcv{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;background:#000}\n.qrnote{text-align:center;color:var(--muted);font-size:13.5px;margin:2px 0 0;line-height:1.45}\n.setsub{display:block;font-size:12.5px;color:var(--muted);font-weight:500;margin-top:2px}\n#call #lv{position:absolute;right:16px;top:calc(16px + env(safe-area-inset-top));width:120px;height:170px;border-radius:16px;object-fit:cover;transform:scaleX(-1);box-shadow:0 10px 30px rgba(0,0,0,.5);z-index:2;background:#111}\n#call .cinfo{position:relative;z-index:2;margin-top:14vh;text-align:center;text-shadow:0 2px 12px rgba(0,0,0,.6)}\n#call .cinfo h2{margin:18px 0 6px;font-size:28px;font-weight:800}\n#call .cinfo p{margin:0;opacity:.8;font-weight:600}\n#call .pulse{animation:pulse 1.6s infinite;border-radius:50%}\n@keyframes pulse{0%{box-shadow:0 0 0 0 rgba(124,92,255,.6)}100%{box-shadow:0 0 0 30px rgba(124,92,255,0)}}\n#call .cbtns{position:absolute;bottom:calc(46px + env(safe-area-inset-bottom));display:flex;gap:22px;z-index:2}\n#call .cbtns button{width:64px;height:64px;border-radius:50%;background:rgba(255,255,255,.16);backdrop-filter:blur(10px);display:grid;place-items:center;color:#fff}\n#call .cbtns button.off{background:#fff;color:#111}\n#call .cbtns button.end{background:#ff3b5c}\n#call .cbtns button.acc{background:#2bd67b}\n#call .cbtns svg{width:28px;height:28px}#cui{position:relative;z-index:2;width:100%;height:100%;display:flex;flex-direction:column;align-items:center}@media (max-width:800px){#txt,.inp,.search input{font-size:16px}}\n#toast{position:fixed;left:50%;top:18px;transform:translateX(-50%);background:var(--panel);color:var(--text);padding:12px 18px;border-radius:16px;box-shadow:var(--shadow);z-index:99950;font-weight:600;animation:pop .15s;max-width:90vw;border:1px solid var(--line)}\n.dropzone{position:absolute;inset:10px;border:3px dashed var(--a1);border-radius:24px;background:rgba(124,92,255,.12);display:grid;place-items:center;font-size:20px;font-weight:800;color:var(--a1);z-index:20;pointer-events:none}\n.prog{height:4px;border-radius:2px;background:rgba(255,255,255,.2);overflow:hidden;margin-top:6px}\n.prog i{display:block;height:100%;background:#fff;width:30%;animation:prog 1.2s infinite ease-in-out}\n@keyframes prog{0%{margin-left:-30%}100%{margin-left:100%}}\n\n/* ===== СТАРТОВАЯ ЗАСТАВКА ===== */\n#splash{position:fixed;inset:0;z-index:99990;background:var(--bg);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;transition:opacity .55s cubic-bezier(.4,0,.2,1),transform .55s cubic-bezier(.4,0,.2,1)}\n#splash.out{opacity:0;transform:scale(1.12);pointer-events:none}\n#splash .mark{width:92px;height:92px;border-radius:28px;background:var(--accent);display:grid;place-items:center;box-shadow:0 20px 60px rgba(124,92,255,.5);animation:markIn .9s cubic-bezier(.34,1.56,.64,1) both,breathe 1.8s ease-in-out .9s infinite;position:relative;overflow:hidden}\n#splash .mark::after,.logo .mark::after{content:\"\";position:absolute;inset:-40%;background:linear-gradient(115deg,transparent 40%,rgba(255,255,255,.55) 50%,transparent 60%);transform:translateX(-100%);animation:shine 2.8s ease-in-out 1s infinite}\n#splash .sname{font-size:30px;font-weight:800;letter-spacing:-1px;animation:rise .8s cubic-bezier(.16,1,.3,1) .35s both}\n@keyframes markIn{from{opacity:0;transform:scale(.2) rotate(-35deg)}to{opacity:1;transform:none}}\n@keyframes breathe{50%{transform:scale(1.07);box-shadow:0 26px 70px rgba(124,92,255,.65)}}\n@keyframes shine{0%{transform:translateX(-100%)}45%,100%{transform:translateX(100%)}}\n@keyframes rise{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:none}}\n@keyframes fadeIn{from{opacity:0}to{opacity:1}}\n\n/* ===== ВХОД / РЕГИСТРАЦИЯ ===== */\n#auth{overflow:hidden auto}\n#auth .blobs{position:fixed;inset:0;overflow:hidden;pointer-events:none;z-index:0}\n#auth .blobs i{position:absolute;width:560px;height:560px;border-radius:50%;filter:blur(80px);opacity:.5;animation:blob 18s ease-in-out infinite alternate}\n#auth .blobs i:nth-child(1){background:#7c5cff;top:-180px;left:-160px}\n#auth .blobs i:nth-child(2){background:#22c1ff;bottom:-200px;right:-160px;animation-duration:23s;animation-delay:-7s}\n#auth .blobs i:nth-child(3){background:#ff5b8a;top:38%;left:52%;width:380px;height:380px;opacity:.3;animation-duration:27s;animation-delay:-13s}\n@keyframes blob{0%{transform:translate(0,0) scale(1)}33%{transform:translate(90px,70px) scale(1.15)}66%{transform:translate(-70px,50px) scale(.9)}100%{transform:translate(50px,-80px) scale(1.08)}}\n.authcard{position:relative;z-index:1;animation:cardIn .9s cubic-bezier(.16,1,.3,1) both}\n@keyframes cardIn{from{opacity:0;transform:translateY(46px) scale(.93);filter:blur(8px)}to{opacity:1;transform:none;filter:none}}\n.authcard>*,#passView>*,#qrView>*,#authForm>*{animation:rise .75s cubic-bezier(.16,1,.3,1) both}\n.authcard>*:nth-child(1){animation-delay:.15s}.authcard>*:nth-child(2){animation-delay:.24s}.authcard>*:nth-child(3),.authcard>*:nth-child(4){animation-delay:.3s}\n#passView>*:nth-child(1),#qrView>*:nth-child(1){animation-delay:.34s}#passView>*:nth-child(2),#qrView>*:nth-child(2){animation-delay:.42s}#passView>*:nth-child(3),#qrView>*:nth-child(3){animation-delay:.5s}#qrView>*:nth-child(4){animation-delay:.56s}#qrView>*:nth-child(5),#qrView>*:nth-child(6){animation-delay:.62s}\n#authForm>*:nth-child(2){animation-delay:.46s}#authForm>*:nth-child(3){animation-delay:.52s}#authForm>*:nth-child(5){animation-delay:.6s}\n.logo .mark{position:relative;overflow:hidden;animation:markIn .9s cubic-bezier(.34,1.56,.64,1) .1s both,float 4.5s ease-in-out 1.1s infinite}\n@keyframes float{50%{transform:translateY(-5px) rotate(-4deg)}}\n.authcard .tabs{position:relative}\n.authcard .tabs::before{content:\"\";position:absolute;top:4px;bottom:4px;left:4px;width:calc(50% - 4px);border-radius:11px;background:var(--panel);box-shadow:0 3px 12px rgba(0,0,0,.14);transition:transform .5s cubic-bezier(.34,1.35,.64,1)}\n.authcard .tabs.reg::before{transform:translateX(100%)}\n.authcard .tabs button{position:relative;z-index:1;transition:color .35s}\n.authcard .tabs button.on{background:none!important;box-shadow:none!important}\n.field{transition:max-height .5s cubic-bezier(.16,1,.3,1),opacity .4s,transform .5s cubic-bezier(.16,1,.3,1),margin .5s;max-height:110px}\n.field.collapse{max-height:0;opacity:0;transform:translateY(-10px) scale(.97);margin-bottom:0;overflow:hidden;pointer-events:none}\n.inp{transition:border-color .25s,background .25s,box-shadow .3s,transform .3s}\n.inp:focus{box-shadow:0 0 0 4px rgba(124,92,255,.18);transform:translateY(-1px)}\n.field label{transition:color .25s}.field:focus-within label{color:var(--a1)}\n.btn{transition:transform .2s cubic-bezier(.34,1.56,.64,1),filter .2s,box-shadow .25s,background .25s}\n.btn:active{transform:scale(.95)}\n.btn.primary{background-size:200% 200%;animation:gradmove 6s ease infinite}\n.btn.primary:hover{box-shadow:0 12px 32px rgba(124,92,255,.5)}\n@keyframes gradmove{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}\n.btn.loading{color:transparent!important;pointer-events:none;position:relative}\n.btn.loading::after{content:\"\";position:absolute;left:50%;top:50%;width:20px;height:20px;margin:-10px 0 0 -10px;border:2.5px solid rgba(255,255,255,.4);border-top-color:#fff;border-radius:50%;animation:lmspin .7s linear infinite}\n.shake{animation:shake .5s cubic-bezier(.36,.07,.19,.97) both!important}\n@keyframes shake{10%,90%{transform:translateX(-2px)}20%,80%{transform:translateX(4px)}30%,50%,70%{transform:translateX(-8px)}40%,60%{transform:translateX(8px)}}\n.err:not(:empty){animation:rise .35s cubic-bezier(.16,1,.3,1)}\n#auth.leaving{z-index:99001;animation:authOut .55s cubic-bezier(.4,0,.2,1) forwards;pointer-events:none}\n@keyframes authOut{to{opacity:0;transform:scale(1.08);filter:blur(10px)}}\n/* QR */\n#qrImg{overflow:hidden;transition:box-shadow .4s}\n#qrImg .qrmark{background:var(--accent)!important}\n#qrImg svg{animation:qrIn .6s cubic-bezier(.34,1.45,.64,1) both;transition:filter .4s,opacity .4s}\n@keyframes qrIn{from{opacity:0;transform:scale(.8) rotate(-4deg)}to{opacity:1;transform:none}}\n#qrImg.ready::after{content:\"\";position:absolute;left:12px;right:12px;top:12px;height:3px;border-radius:3px;background:linear-gradient(90deg,transparent,#7c5cff,#22c1ff,transparent);box-shadow:0 0 14px 2px rgba(124,92,255,.55);animation:scanline 2.6s ease-in-out infinite}\n@keyframes scanline{0%,100%{transform:translateY(0);opacity:.2}50%{transform:translateY(196px);opacity:1}}\n#qrImg.scanned svg,#qrImg.scanned .qrmark{filter:blur(5px);opacity:.3}\n#qrImg.scanned::after{display:none}\n#qrImg.scanned::before{content:\"\u2713\";position:absolute;left:50%;top:50%;width:76px;height:76px;margin:-38px 0 0 -38px;border-radius:50%;background:#2bd67b;color:#fff;font-size:42px;font-weight:800;display:grid;place-items:center;z-index:3;box-shadow:0 10px 30px rgba(43,214,123,.5);animation:markIn .6s cubic-bezier(.34,1.56,.64,1) both}\n.qrst:not(:empty){animation:pulseText 1.6s ease-in-out infinite}\n@keyframes pulseText{50%{opacity:.55}}\n\n/* ===== ГЛАВНЫЙ ЭКРАН (как на фото) ===== */\n#app.appin #side{animation:sideIn .8s cubic-bezier(.16,1,.3,1) both}\n#app.appin #main{animation:fadeIn .9s .15s both}\n#app.appin #tabs{animation:tabsUp .8s cubic-bezier(.34,1.35,.64,1) .3s both}\n@keyframes sideIn{from{opacity:0;transform:translateY(24px) scale(.98)}to{opacity:1;transform:none}}\n@keyframes tabsUp{from{opacity:0;transform:translate(-50%,60px) scale(.9)}to{opacity:1;transform:translate(-50%,0)}}\n.sbar{display:flex;gap:12px;align-items:center;padding:calc(12px + env(safe-area-inset-top)) 16px 4px!important}\n.sbar .search{flex:1 1 auto;min-width:0;width:auto;height:52px!important;border-radius:22px!important;background:var(--panel2);padding:0 18px;gap:12px;border:0!important;transition:box-shadow .3s,background .3s}\n.sbar .search svg{width:24px;height:24px}\n.sbar .search input{font-size:18px}\n.sbar .search:focus-within{box-shadow:0 0 0 3px rgba(124,92,255,.2);background:var(--panel)}\n.hbtn.sq{flex:none;width:52px;height:52px;border-radius:20px;background:var(--panel2);border:0;transition:transform .25s cubic-bezier(.34,1.56,.64,1),background .2s}\n.hbtn.sq svg{width:25px;height:25px}\n.hbtn:active,.ib:active,.rbtn:active{transform:scale(.88)}\n.hbtn,.ib,.rbtn{transition:transform .25s cubic-bezier(.34,1.56,.64,1),background .2s,color .2s}\n.tophead{padding:calc(12px + env(safe-area-inset-top)) 14px 6px!important}\n.folders{background:none!important;margin:2px 4px 2px!important;padding:0 0 2px!important;gap:0!important;position:relative;border-radius:0!important;scroll-behavior:smooth}\n.folders button{background:none!important;color:var(--muted)!important;font-size:18px!important;font-weight:600!important;padding:12px 16px 15px!important;border-radius:0!important;box-shadow:none!important;transition:color .35s}\n.folders button.on{color:var(--text)!important}\n.folders .fc{font-size:11px;min-width:18px;height:18px}\n.folders .find{position:absolute;bottom:0;left:0;width:0;height:3px;border-radius:3px;background:var(--text);transition:transform .5s cubic-bezier(.34,1.3,.64,1),width .5s cubic-bezier(.34,1.3,.64,1);pointer-events:none}\n#list{padding-left:0!important;padding-right:0!important;padding-top:2px!important}\n#list .row{border-radius:0;padding:0 0 0 16px;gap:14px;align-items:center}\n#list .row .av{width:66px;height:66px;font-size:25px;margin:9px 0;font-weight:700}\n#list .row .av .on{width:16px;height:16px}\n#list .row .mid{align-self:stretch;display:flex;flex-direction:column;justify-content:center;padding:10px 16px 10px 0;border-bottom:1px solid var(--line)}\n#list .row:last-child .mid{border-bottom-color:transparent}\n#list .row .t1 .nm{font-size:17.5px}\n#list .row .t1 time{font-size:14.5px;font-weight:500;gap:4px}\n#list .row .t1 time svg{width:19px;height:19px}\n#list .chk{color:var(--text);opacity:.8}\n#list .row .t2{font-size:16px;margin-top:4px;align-items:flex-start}\n#list .row .t2 .pv{line-height:1.35}\n#list .row .t2 .pv b{font-weight:500;color:var(--muted)}\n#list .row:hover{background:var(--hover)}\n#list .row.on{background:var(--active)}\n#list .row .badge{margin-top:2px}\n.row{transition:background .25s,transform .25s cubic-bezier(.34,1.56,.64,1)}\n.row:active{transform:scale(.985)}\n.stg{animation:stg .6s cubic-bezier(.16,1,.3,1) both}\n@keyframes stg{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:none}}\n/* нижняя панель: три иконки в \u00abтаблетке\u00bb со скользящей подсветкой */\n#tabs{left:50%!important;right:auto!important;width:min(320px,calc(100% - 70px));transform:translateX(-50%);padding:6px!important;gap:0!important;border-radius:40px!important;background:color-mix(in srgb,var(--panel) 80%,transparent)!important;box-shadow:0 12px 40px rgba(20,20,60,.16),0 1px 0 var(--line) inset!important}\n#tabs .tl{display:none}\n#tabs button{padding:12px 0!important;background:none!important;color:var(--text)!important;z-index:1;transition:transform .3s cubic-bezier(.34,1.56,.64,1)}\n#tabs button:hover{background:none!important}\n#tabs button:active{transform:scale(.85)}\n#tabs button.on .ti{animation:tabPop .55s cubic-bezier(.34,1.56,.64,1)}\n#tabs .ti{height:32px}\n#tabs .ti svg{width:31px;height:31px}\n#tabs .tind{position:absolute;top:6px;bottom:6px;left:0;width:0;border-radius:32px;background:rgba(128,128,150,.16);transition:transform .55s cubic-bezier(.34,1.25,.64,1),width .55s cubic-bezier(.34,1.25,.64,1);z-index:0}\n#tabs .badge{top:4px!important;left:calc(50% + 6px)!important;animation:bpop .45s cubic-bezier(.34,1.56,.64,1)}\n@keyframes tabPop{0%{transform:scale(1)}35%{transform:scale(.78)}70%{transform:scale(1.12)}100%{transform:scale(1)}}\n@keyframes bpop{from{transform:scale(0)}to{transform:scale(1)}}\n.mini.rot{transform:rotate(-90deg)}\n/* смена вкладок и экранов */\n#pane>*{animation:stg .55s cubic-bezier(.16,1,.3,1) both}\n@media (min-width:801px){#chat.cin{animation:chatIn .45s cubic-bezier(.16,1,.3,1)}}\n@keyframes chatIn{from{opacity:0;transform:translateX(18px)}to{opacity:1;transform:none}}\n@media (max-width:800px){\n#side,#main{transition:transform .46s cubic-bezier(.32,.72,0,1),filter .46s!important}\n#app.inchat #side{filter:brightness(.9)}\n}\n/* сообщения */\n.b{animation:msgIn .32s cubic-bezier(.34,1.3,.64,1) both;transform-origin:bottom left}\n.m.me .b{transform-origin:bottom right}\n@keyframes msgIn{from{opacity:0;transform:translateY(8px) scale(.94)}to{opacity:1;transform:none}}\n#sendbtn{transition:transform .3s cubic-bezier(.34,1.56,.64,1),background .3s}\n#sendbtn:active{transform:scale(.88)}\n.rc{transition:transform .25s cubic-bezier(.34,1.56,.64,1),background .2s}\n.rc:active{transform:scale(.85)}\n/* меню, окна, уведомления */\n.ov{animation:fadeIn .3s ease both}\n.modal{animation:sheet .5s cubic-bezier(.16,1,.3,1) both}\n@keyframes sheet{from{opacity:0;transform:translateY(40px) scale(.94)}to{opacity:1;transform:none}}\n.drop{animation:dropIn .3s cubic-bezier(.34,1.3,.64,1) both;transform-origin:top right}\n@keyframes dropIn{from{opacity:0;transform:scale(.82) translateY(-8px)}to{opacity:1;transform:none}}\n.drop button{animation:stg .4s cubic-bezier(.16,1,.3,1) both}\n.drop button:nth-child(2){animation-delay:.03s}.drop button:nth-child(3){animation-delay:.06s}.drop button:nth-child(4){animation-delay:.09s}.drop button:nth-child(5){animation-delay:.12s}.drop button:nth-child(6){animation-delay:.15s}.drop button:nth-child(7){animation-delay:.18s}.drop button:nth-child(8){animation-delay:.21s}\n#toast{animation:toastIn .5s cubic-bezier(.34,1.4,.64,1) both}\n@keyframes toastIn{from{opacity:0;transform:translate(-50%,-34px) scale(.9)}to{opacity:1;transform:translate(-50%,0)}}\n.set{transition:background .2s,transform .25s cubic-bezier(.34,1.56,.64,1)}\n.set:active{transform:scale(.98)}\n.tog::after{transition:left .4s cubic-bezier(.34,1.56,.64,1)!important}\n.tog{transition:background .3s!important}\n.sw{transition:transform .3s cubic-bezier(.34,1.56,.64,1),border-color .2s}.sw:hover{transform:scale(1.12)}\n#emoji{animation:sheet .4s cubic-bezier(.16,1,.3,1) both}\n#lightbox img,#lightbox video{animation:sheet .45s cubic-bezier(.16,1,.3,1) both}\n#call{animation:fadeIn .4s ease both}\n#call .cbtns button{transition:transform .25s cubic-bezier(.34,1.56,.64,1),background .2s}#call .cbtns button:active{transform:scale(.88)}\n#call .cbtns{animation:rise .6s cubic-bezier(.16,1,.3,1) .1s both}\n#call .cinfo{animation:rise .7s cubic-bezier(.16,1,.3,1) both}\n.ncard{display:flex;align-items:center;gap:12px;margin:6px 14px 8px;padding:12px 10px 12px 14px;border-radius:20px;background:linear-gradient(135deg,rgba(124,92,255,.14),rgba(34,193,255,.12));border:1px solid var(--line);animation:stg .6s cubic-bezier(.16,1,.3,1) both;transition:opacity .35s,transform .35s,max-height .35s}\n.ncard.bye{opacity:0;transform:translateX(30px) scale(.95)}\n.ncard .nci{width:42px;height:42px;border-radius:14px;background:var(--accent);color:#fff;display:grid;place-items:center;flex:none;animation:ring 2.4s ease-in-out 1s infinite}\n@keyframes ring{0%,40%,100%{transform:rotate(0)}5%,15%,25%{transform:rotate(-14deg)}10%,20%,30%{transform:rotate(14deg)}}\n.ncard .tx{flex:1;min-width:0}.ncard .tx b{display:block;font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.ncard .tx span{display:block;color:var(--muted);font-size:12.5px;line-height:1.3}\n.ncard .ncon{padding:9px 14px;border-radius:14px;background:var(--accent);color:#fff;font-weight:700;font-size:13.5px;white-space:nowrap;transition:transform .25s cubic-bezier(.34,1.56,.64,1)}\n.ncard .ncon:active{transform:scale(.92)}\n.ncard .ncx{width:30px;height:30px;border-radius:50%;display:grid;place-items:center;color:var(--muted)}\n.ncard .ncx svg{width:18px;height:18px}\n#earBlack{position:fixed;inset:0;z-index:2147483646;background:#000;opacity:0;transition:opacity .22s;touch-action:none;display:flex;align-items:flex-end;justify-content:center;padding-bottom:calc(30px + env(safe-area-inset-bottom))}\n#earBlack.on{opacity:1}#earBlack span{color:#2a2a2a;font-size:12px}\n#call .spkl{position:absolute;bottom:calc(20px + env(safe-area-inset-bottom));z-index:2;color:rgba(255,255,255,.6);font-size:12.5px;font-weight:600;animation:fadeIn .3s both}\n.tgor{display:flex;align-items:center;gap:12px;color:var(--muted);font-size:13px;margin:16px 0 12px}.tgor i{flex:1;height:1px;background:var(--line)}\n.btn.tgw{display:flex;align-items:center;justify-content:center;gap:10px;background:linear-gradient(135deg,#2aabee,#1d93d2);color:#fff;text-decoration:none;box-shadow:0 8px 24px rgba(34,158,217,.35)}\n.btn.tgw svg{width:22px;height:22px;flex:none}\n.btn.tgw.dis{opacity:.55;pointer-events:none}\n.tgwait{display:flex;gap:10px;align-items:center;justify-content:center;color:var(--muted);font-size:13px;line-height:1.35;margin-top:12px;text-align:left;animation:rise .4s cubic-bezier(.16,1,.3,1) both}\n.tgwait .tgsp{width:16px;height:16px;border:2px solid var(--line);border-top-color:#2aabee;border-radius:50%;animation:lmspin .8s linear infinite;flex:none}\n.ncard.tgl{background:linear-gradient(135deg,rgba(42,171,238,.16),rgba(124,92,255,.10))}\n#adm{position:fixed;inset:0;z-index:99400;background:var(--bg);color:var(--text);display:flex;flex-direction:column;transform:translateX(100%);transition:transform .34s cubic-bezier(.16,1,.3,1)}\n#adm.on{transform:none}#adm.out{transform:translateX(100%)}\n#adm .adh{display:flex;align-items:center;gap:10px;padding:calc(10px + env(safe-area-inset-top)) 12px 8px;flex:none}\n#adm .adt{flex:1;min-width:0}#adm .adt b{display:block;font-size:19px;font-weight:800}#adm .adt span{color:var(--muted);font-size:12.5px}\n#adm .adtabs{display:flex;gap:6px;overflow-x:auto;padding:4px 12px 10px;scrollbar-width:none;flex:none}#adm .adtabs::-webkit-scrollbar{display:none}\n#adm .adtabs button{display:inline-flex;align-items:center;gap:6px;padding:8px 13px;border-radius:20px;background:var(--panel2);color:var(--muted);font-weight:700;font-size:13.5px;white-space:nowrap;flex:none;transition:.2s}\n#adm .adtabs button svg{width:17px;height:17px}#adm .adtabs button.on{background:var(--accent);color:#fff}\n#adm .adb{flex:1;overflow-y:auto;padding:2px 12px calc(30px + env(safe-area-inset-bottom));-webkit-overflow-scrolling:touch;overscroll-behavior:contain}\n#adm .adview{max-width:920px;margin:0 auto;animation:fadeIn .25s ease both}\n#adm .adload{display:grid;place-items:center;padding:50px}\n#adm .adload .tgsp{width:26px;height:26px;border:3px solid var(--line);border-top-color:var(--a1);border-radius:50%;animation:lmspin .8s linear infinite;display:block}\n#adm .adempty{display:flex;flex-direction:column;align-items:center;gap:8px;padding:50px 20px;text-align:center;color:var(--muted)}#adm .adempty b{color:var(--text)}\n#adm .admuted{color:var(--muted);text-align:center;padding:22px 12px;font-size:14px}\n#adm .adcards{display:grid;grid-template-columns:repeat(auto-fill,minmax(158px,1fr));gap:10px;margin-bottom:12px}\n#adm .adcard{background:var(--panel2);border-radius:18px;padding:14px;display:flex;flex-direction:column;gap:3px;min-width:0}\n#adm .adcard .sic{width:34px;height:34px;border-radius:11px;display:grid;place-items:center;color:#fff;margin-bottom:6px}#adm .adcard .sic svg{width:19px;height:19px}\n#adm .adcard .t{color:var(--muted);font-size:13px;font-weight:600}#adm .adcard b{font-size:24px;font-weight:800;letter-spacing:-.3px}#adm .adcard .s{color:var(--muted);font-size:12px;line-height:1.3}\n#adm .adsec{background:var(--panel2);border-radius:18px;padding:14px;margin-bottom:12px}\n#adm .adsec h4{margin:0 0 10px;font-size:15px;font-weight:800}\n#adm .adbars{display:flex;align-items:flex-end;gap:4px;height:130px}\n#adm .adbar{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:flex-end;height:100%;gap:3px;min-width:0}\n#adm .adbar i{display:block;width:100%;max-width:26px;background:var(--accent);border-radius:6px 6px 3px 3px;min-height:3px;transition:height .4s}\n#adm .adbar em{font-style:normal;font-size:10px;color:var(--muted);min-height:12px}#adm .adbar span{font-size:10px;color:var(--muted)}\n#adm .adcount{color:var(--muted);font-size:12.5px;margin:8px 2px}\n#adm .adrow{display:flex;align-items:center;gap:12px;padding:9px 6px;border-radius:14px;cursor:pointer;transition:background .15s}\n#adm .adrow:hover{background:rgba(127,127,160,.1)}#adm .adrow:active{background:rgba(127,127,160,.16)}\n#adm .adrow .mid{flex:1;min-width:0}#adm .adrow .mid b{display:block;font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n#adm .adrow .mid span{display:block;color:var(--muted);font-size:12.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n#adm .tags{display:flex;gap:4px;flex-wrap:wrap;justify-content:center}#adm .tags em{font-style:normal;font-size:11px;font-weight:700;padding:3px 8px;border-radius:10px;background:var(--panel);color:var(--muted);white-space:nowrap}\n#adm .tags .tg-owner{background:linear-gradient(135deg,#ffb020,#ff7a00);color:#fff}#adm .tags .tg-admin{background:rgba(124,92,255,.18);color:var(--a1)}\n#adm .tags .tg-ban{background:rgba(255,91,122,.15);color:var(--danger);white-space:normal}#adm .tags .tg-tg{background:rgba(42,171,238,.15);color:#2aabee}\n#adm .adnum{width:24px;text-align:center;font-weight:800;color:var(--muted);flex:none}#adm .adval{font-weight:800;white-space:nowrap}\n#adm .adti{width:40px;height:40px;border-radius:50%;background:var(--panel);display:grid;place-items:center;color:var(--a1);flex:none}#adm .adti svg{width:20px;height:20px}\n#adm .adkinds{display:flex;flex-wrap:wrap;gap:8px}#adm .adkinds span{background:var(--panel);border-radius:12px;padding:8px 12px;font-size:12.5px;color:var(--muted)}#adm .adkinds b{display:block;color:var(--text);font-size:17px}\n#adm .adsearch{margin:0 0 10px;flex:none}\n#adm .adchips{display:flex;gap:6px;overflow-x:auto;margin-bottom:6px;scrollbar-width:none}#adm .adchips::-webkit-scrollbar{display:none}\n#adm .adchips button{padding:7px 13px;border-radius:16px;background:var(--panel2);color:var(--muted);font-weight:700;font-size:13px;white-space:nowrap;flex:none}#adm .adchips button.on{background:var(--text);color:var(--bg)}\n#adm .aduser{display:flex;flex-direction:column;align-items:center;text-align:center;padding:8px 0 14px;gap:5px}\n#adm .aduser h2{margin:8px 0 0;font-size:22px}#adm .aduser .st{color:var(--muted);font-size:13.5px}#adm .aduser .bio{margin:4px 0 0;max-width:460px;font-size:14px;white-space:pre-wrap}\n#adm .adacts{display:flex;flex-wrap:wrap;gap:8px;justify-content:center;margin-bottom:14px}\n#adm .adacts button{display:inline-flex;align-items:center;gap:7px;padding:10px 14px;border-radius:14px;background:var(--panel2);font-weight:700;font-size:13.5px;transition:transform .2s}\n#adm .adacts button:active{transform:scale(.95)}#adm .adacts button svg{width:18px;height:18px}\n#adm .adacts .warn{color:#ff9f1a}#adm .adacts .danger{color:var(--danger);background:rgba(255,91,122,.12)}\n#adm .adgrid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:8px;margin-bottom:12px}\n#adm .adkv{background:var(--panel2);border-radius:14px;padding:10px 12px;min-width:0}#adm .adkv span{display:block;color:var(--muted);font-size:12px}#adm .adkv b{font-size:14px;font-weight:700;word-break:break-word}\n#adm .admsg{padding:9px 10px;border-radius:14px;background:var(--panel);margin-bottom:6px}#adm .admsg[data-c]{cursor:pointer}\n#adm .admsg .h{display:flex;align-items:center;gap:8px;font-size:13px}#adm .admsg .h b{white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:45%}\n#adm .admsg .h span{flex:1;color:var(--muted);font-size:12px;min-width:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n#adm .admsg .abx{font-size:14.5px;margin-top:2px;word-break:break-word;white-space:pre-wrap}#adm .admsg .abx a{color:var(--a2)}#adm .admsg .abx i{color:var(--muted)}\n#adm .admsg .abx mark{background:rgba(255,200,0,.38);color:inherit;border-radius:3px;padding:0 1px}#adm .admsg.del{opacity:.55}\n#adm .adx{width:34px;height:34px;border-radius:50%;display:grid;place-items:center;color:var(--muted);flex:none;transition:.15s}#adm .adx svg{width:18px;height:18px}\n#adm .adx:hover{color:var(--danger);background:rgba(255,91,122,.1)}#adm a.adx:hover{color:var(--a2);background:rgba(34,193,255,.1)}\n#adm .adradio{display:flex;flex-direction:column;gap:8px;margin:12px 0}\n#adm .adradio label{display:flex;gap:10px;padding:12px;border-radius:14px;background:var(--panel);cursor:pointer;align-items:flex-start}\n#adm .adradio input{margin-top:3px;accent-color:var(--a1);flex:none;width:18px;height:18px}#adm .adradio span{font-size:13px;color:var(--muted);line-height:1.4}#adm .adradio span b{display:block;color:var(--text);font-size:14.5px;margin-bottom:2px}\n#adm .adhb{display:flex;align-items:center;gap:10px;margin:8px 0;font-size:13.5px}#adm .adhb>span{width:84px;flex:none}\n#adm .adhb i{flex:1;height:10px;border-radius:5px;background:var(--panel);overflow:hidden}#adm .adhb i b{display:block;height:100%;background:var(--accent);border-radius:5px}\n#adm .adhb em{font-style:normal;color:var(--muted);font-size:12px;width:118px;text-align:right;flex:none}\n#adm .adbtns{display:flex;gap:8px;margin:10px 0 6px}\n#adm .setgrp{margin:0}\n#adm .adlog{padding:10px;border-radius:14px;background:var(--panel);margin-bottom:6px}#adm .adlog .h{display:flex;gap:8px;font-size:14px}#adm .adlog .h span{margin-left:auto;color:var(--muted);font-size:12px;white-space:nowrap}\n#adm .adlog .abx{font-size:13px;color:var(--muted);margin-top:3px;word-break:break-word}#adm .adlog code{font-size:11.5px;opacity:.8}\n#adm .adlog pre{font-size:11px;white-space:pre-wrap;word-break:break-all;margin:6px 0 0;max-height:260px;overflow:auto;color:var(--muted)}\n#adm textarea.inp{font-family:inherit}\n@media (min-width:900px){ #adm .adb{padding:4px 24px 30px} #adm .adtabs{justify-content:center} }\n.adchk{display:flex;align-items:center;gap:10px;margin:8px 0;cursor:pointer;font-size:14.5px}.adchk input{width:20px;height:20px;accent-color:var(--a1);flex:none}.adchk svg{width:16px;height:16px;vertical-align:-3px;color:var(--a2)}\n.vbadge{display:inline-grid;place-items:center;width:18px;height:18px;border-radius:50%;background:var(--accent);color:#fff;vertical-align:1px;margin-left:5px}.vbadge svg{width:12px;height:12px;stroke-width:3}\nh2 .vbadge{width:22px;height:22px;vertical-align:2px}h2 .vbadge svg{width:14px;height:14px}\n.botbadge{display:inline-block;font-size:10px;font-weight:800;letter-spacing:.4px;padding:2px 6px;border-radius:6px;background:var(--panel2,rgba(127,127,127,.2));color:var(--muted);vertical-align:2px;margin-left:6px}\n.prembadge{display:inline-block;color:#ffb020;font-size:.9em;margin-left:4px;vertical-align:1px}\n.kb{display:flex;flex-direction:column;gap:5px;margin:8px -4px -2px}\n.kb .kr{display:flex;gap:5px}\n.aemo{display:inline-block;width:1.15em;height:1.15em;vertical-align:-.2em}.aemo.flick{animation:aeFlick 1s ease-in-out infinite;transform-origin:center}.aemo.beat{animation:aeBeat 1.2s ease-in-out infinite;transform-origin:center}.aemo.float{animation:aeFloatS 2.2s ease-in-out infinite}.aemo.bounce{animation:aeBounce 1.5s ease-in-out infinite}.aemo.shine{animation:aeShine 1.6s ease-in-out infinite}@keyframes aeFlick{0%,100%{transform:scale(1) rotate(0deg)}25%{transform:scale(1.08) rotate(-4deg)}50%{transform:scale(.94) rotate(3deg)}75%{transform:scale(1.04) rotate(-2deg)}}@keyframes aeBeat{0%,100%{transform:scale(1)}15%{transform:scale(1.22)}30%{transform:scale(1)}45%{transform:scale(1.15)}60%{transform:scale(1)}}@keyframes aeFloatS{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}@keyframes aeBounce{0%,100%{transform:translateY(0)}30%{transform:translateY(-5px)}50%{transform:translateY(0)}70%{transform:translateY(-2px)}}@keyframes aeShine{0%,100%{filter:brightness(1) saturate(1)}50%{filter:brightness(1.6) saturate(1.4)}}.aemo svg{width:100%;height:100%;display:block;overflow:visible}\n.aemo.flick svg{animation:aeF 1.1s ease-in-out infinite;transform-origin:50% 90%}@keyframes aeF{0%,100%{transform:scale(1,1) rotate(0)}30%{transform:scale(.94,1.08) rotate(-3deg)}60%{transform:scale(1.04,.96) rotate(3deg)}}\n.aemo.beat svg{animation:aeB 1.2s ease-in-out infinite}@keyframes aeB{0%,100%{transform:scale(1)}15%{transform:scale(1.2)}30%{transform:scale(1)}45%{transform:scale(1.15)}}\n.aemo.spin svg{animation:aeS 4s linear infinite}@keyframes aeS{to{transform:rotate(360deg)}}\n.aemo.float svg{animation:aeFl 2s ease-in-out infinite}@keyframes aeFl{0%,100%{transform:translateY(0)}50%{transform:translateY(-12%)}}\n.aemo.bounce svg{animation:aeBo 1.3s ease-in-out infinite}@keyframes aeBo{0%,100%{transform:translateY(0)}40%{transform:translateY(-15%) rotate(-5deg)}60%{transform:translateY(-15%) rotate(5deg)}}\n.aemo.sway svg{animation:aeSw 2.4s ease-in-out infinite;transform-origin:50% 100%}@keyframes aeSw{0%,100%{transform:rotate(-8deg)}50%{transform:rotate(8deg)}}\n.aemo.shine svg{animation:aeSh 2s ease-in-out infinite}@keyframes aeSh{0%,100%{filter:brightness(1);transform:scale(1)}50%{filter:brightness(1.3);transform:scale(1.1)}}\n@media (prefers-reduced-motion:reduce){.aemo svg{animation:none!important}}\n.aegrid{display:grid;grid-template-columns:repeat(6,1fr);gap:8px;margin-bottom:12px}.aeb{height:50px;border-radius:14px;background:var(--panel);font-size:28px;display:flex;align-items:center;justify-content:center}.aeb.on{outline:2px solid var(--a1)}\n.shero .prembadge{cursor:pointer}\na[data-cmd]{color:#4aa3ff;text-decoration:none;cursor:pointer}.m.me a[data-cmd]{color:#fff;text-decoration:underline}\n.pmpage{padding-bottom:90px}\n.pmtop{display:flex;align-items:center;padding:2px 0}\n.pmhero{position:relative;text-align:center;padding:10px 16px 6px;overflow:hidden}\n.pmhero .pmsp{position:absolute;inset:0;pointer-events:none}.pmsp i{position:absolute;background:#b79bff;clip-path:polygon(50% 0,60% 40%,100% 50%,60% 60%,50% 100%,40% 60%,0 50%,40% 40%);opacity:0;animation:pmT 2.8s ease-in-out infinite}@keyframes pmT{0%,100%{opacity:0;transform:scale(.4)}50%{opacity:.9;transform:scale(1)}}\n.pmhero svg.pmstar{width:112px;height:112px;position:relative;filter:drop-shadow(0 10px 24px rgba(140,100,255,.5));animation:aeFl 3.4s ease-in-out infinite}\n.pmhero h1{margin:6px 0 6px;font-size:30px;font-weight:800;letter-spacing:-.5px;position:relative}.pmhero p{margin:0 auto;max-width:300px;color:var(--muted);font-size:15px;line-height:1.4;position:relative}\n.pmplans{background:var(--panel2);border-radius:22px;margin:16px 16px 0;overflow:hidden}\n.pmplan{display:flex;align-items:center;gap:14px;padding:14px 16px;cursor:pointer;position:relative}.pmplan+.pmplan::before{content:'';position:absolute;left:62px;right:0;top:0;height:1px;background:var(--line,rgba(127,127,127,.18))}\n.pmrad{width:26px;height:26px;border-radius:50%;border:2px solid var(--muted);flex:none;display:flex;align-items:center;justify-content:center}.pmplan.on .pmrad{background:var(--a1);border-color:var(--a1)}.pmplan.on .pmrad::after{content:'';width:10px;height:10px;border-radius:50%;background:#fff}\n.pmplan .pt{flex:1;min-width:0}.pmplan .pt b{font-size:17px;font-weight:600}.pmplan .pt small{display:block;color:var(--muted);font-size:13px;margin-top:2px}.pmplan .pp{color:var(--muted);font-size:15px;white-space:nowrap}\n.pmbadge{display:inline-block;background:#2f8bff;color:#fff;font-size:12px;font-weight:700;border-radius:7px;padding:1px 6px;margin-left:6px;vertical-align:2px}\n.pmsec{margin:22px 30px 8px;color:var(--muted);font-size:13px;letter-spacing:.4px;text-transform:uppercase}\n.pmfeats{background:var(--panel2);border-radius:22px;margin:0 16px;overflow:hidden}\n.pmf{display:flex;gap:14px;padding:14px 16px;align-items:flex-start;position:relative}.pmf+.pmf::before{content:'';position:absolute;left:68px;right:0;top:0;height:1px;background:var(--line,rgba(127,127,127,.18))}\n.pmf .pi{width:38px;height:38px;border-radius:10px;flex:none;display:flex;align-items:center;justify-content:center;color:#fff}.pmf .pi svg{width:22px;height:22px}\n.pmf b{display:block;font-size:17px;font-weight:600}.pmf span.d{display:block;color:var(--muted);font-size:14px;line-height:1.35;margin-top:2px}\n.pmabout{background:var(--panel2);border-radius:22px;margin:0 16px;padding:16px;font-size:15px;line-height:1.45}\n.pmbtn{position:sticky;bottom:14px;margin:18px 16px 0;z-index:5}.pmbtn button{width:100%;height:54px;border-radius:27px;font-size:18px;font-weight:700;color:#fff;background:linear-gradient(90deg,#6a8bff,#b36bff 60%,#e06bd0);box-shadow:0 8px 22px rgba(140,100,255,.4)}\n.pmok{margin:16px 16px 0;padding:14px 16px;border-radius:18px;background:color-mix(in srgb,#8a6bff 16%,transparent);text-align:center;font-weight:600}\n#fxl{position:fixed;inset:0;pointer-events:none;z-index:99998;overflow:hidden}\n.fxp{position:absolute;left:var(--x);top:var(--y);font-size:var(--s);opacity:0;animation:fxA var(--d) ease-out forwards}\n@keyframes fxA{0%{opacity:0;transform:translate(0,0) scale(.3) rotate(0)}15%{opacity:1}100%{opacity:0;transform:translate(var(--dx),var(--dy)) scale(1.2) rotate(var(--r))}}\n.sov{position:fixed;inset:0;z-index:9998;background:rgba(10,12,20,.28);-webkit-backdrop-filter:blur(26px) saturate(1.4);backdrop-filter:blur(26px) saturate(1.4);animation:sovIn .18s ease-out}\n@keyframes sovIn{from{opacity:0}to{opacity:1}}\n.sstack{position:absolute;display:flex;flex-direction:column;align-items:flex-end;gap:10px;animation:sstIn .22s cubic-bezier(.2,.9,.3,1.2);transform-origin:100% 50%}\n@keyframes sstIn{from{opacity:0;transform:scale(.86)}to{opacity:1;transform:scale(1)}}\n.glass{background:color-mix(in srgb,var(--panel2) 72%,transparent);-webkit-backdrop-filter:blur(30px) saturate(1.6);backdrop-filter:blur(30px) saturate(1.6);border:1px solid rgba(255,255,255,.12);box-shadow:0 10px 40px rgba(0,0,0,.28)}\n.fxbar{border-radius:30px;padding:10px 12px 12px;position:relative;align-self:stretch}\n.fxbar::after{content:'';position:absolute;right:52px;bottom:-9px;width:22px;height:22px;border-radius:50%;background:inherit;-webkit-backdrop-filter:inherit;backdrop-filter:inherit}\n.fxbar::before{content:'';position:absolute;right:34px;bottom:-22px;width:11px;height:11px;border-radius:50%;background:color-mix(in srgb,var(--panel2) 72%,transparent)}\n.fxt{font-size:14px;color:var(--muted);text-align:center;margin-bottom:6px}.fxr{display:flex;gap:2px;justify-content:space-between;align-items:center}.fxr button{font-size:30px;width:44px;height:44px;position:relative;border-radius:50%;line-height:1}.fxr button:active{background:rgba(127,127,127,.25)}.fxr .fxmore{font-size:0;width:38px;height:38px;background:color-mix(in srgb,var(--a1) 35%,transparent);display:flex;align-items:center;justify-content:center;color:#fff}.fxr .fxmore svg{width:20px;height:20px}\n.fxr2{display:none;gap:2px;justify-content:space-between;margin-top:4px}.fxbar.open .fxr2{display:flex}.fxr2 button{font-size:30px;width:44px;height:44px;position:relative;border-radius:50%;line-height:1}\n.fxlk{position:absolute;right:0;bottom:0;background:#9aa0ad;color:#fff;border-radius:50%;width:17px;height:17px;display:flex;align-items:center;justify-content:center;border:2px solid rgba(255,255,255,.5)}.fxlk svg{width:9px;height:9px;stroke:#fff;fill:none;stroke-width:3.2}\n.srow{display:flex;align-items:flex-end;gap:10px;margin-top:14px;max-width:calc(100vw - 24px)}\n.sbub{background:var(--out);color:var(--out-text);border-radius:20px 20px 6px 20px;padding:9px 14px;max-width:calc(100vw - 100px);font-size:17px;line-height:1.35;word-break:break-word;white-space:pre-wrap;box-shadow:0 4px 16px rgba(0,0,0,.2)}\n.sbtn{width:48px;height:48px;border-radius:50%;background:var(--accent,#3a7bff);color:#fff;flex:none;display:flex;align-items:center;justify-content:center}.sbtn svg{width:24px;height:24px}\n.smenu{border-radius:28px;padding:6px;min-width:250px}\n.smenu button{display:flex;align-items:center;gap:14px;width:100%;padding:13px 16px;font-size:17px;border-radius:20px;text-align:left}.smenu button:active{background:rgba(127,127,127,.22)}.smenu button svg{width:22px;height:22px;flex:none}\n#lock{position:fixed;inset:0;z-index:99999;background:var(--bg);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;padding:24px}\n#lock h3{margin:0;font-size:20px}#lock .dots{display:flex;gap:14px;height:16px}#lock .dots i{width:14px;height:14px;border-radius:50%;border:2px solid var(--muted)}#lock .dots i.on{background:var(--a1);border-color:var(--a1)}\n#lock .pad{display:grid;grid-template-columns:repeat(3,72px);gap:14px}#lock .pad button{height:72px;border-radius:50%;background:var(--panel);font-size:26px;font-weight:600;color:var(--text)}#lock .pad button:active{background:var(--panel2)}\n#lock .err{color:var(--danger);min-height:18px;font-size:14px}\n.sw.pr::after{content:'\u2605';position:absolute;right:-2px;top:-4px;font-size:12px;color:#ffb020}.sw{position:relative}\n.kb button{flex:1;min-width:0;border:0;border-radius:10px;padding:9px 10px;font:inherit;font-size:14px;font-weight:600;cursor:pointer;background:rgba(127,127,127,.18);color:var(--accent);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n.kb button:active{opacity:.6}\n.ncard.ann{background:linear-gradient(135deg,rgba(255,159,26,.16),rgba(255,91,91,.10))}.ncard.ann .nci.an{background:linear-gradient(135deg,#ff9f1a,#ff5b5b);animation:none}\n.ncard.ann .tx span{white-space:pre-wrap;color:var(--text);opacity:.85}\n#bannedScr{position:fixed;inset:0;z-index:99990;background:var(--bg);color:var(--text);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;padding:30px;text-align:center}\n#bannedScr .bi{width:88px;height:88px;border-radius:50%;background:rgba(255,91,122,.14);color:var(--danger);display:grid;place-items:center;margin-bottom:6px}#bannedScr .bi svg{width:44px;height:44px}\n#bannedScr h2{margin:0;font-size:23px}#bannedScr p{margin:0;color:var(--muted);max-width:360px;line-height:1.45}#bannedScr .btn{margin-top:10px;min-width:180px}\n.pcard .lnk.del{color:var(--danger);margin-top:4px}\nhtml{-webkit-text-size-adjust:100%;text-size-adjust:100%}\n#adm .adrep{padding:12px;border-radius:14px;background:var(--panel);margin-bottom:8px;border-left:3px solid #ff9f1a}\n#adm .adrep.done{border-left-color:#2bd67b;opacity:.85}#adm .adrep.rejected{border-left-color:var(--muted);opacity:.7}\n#adm .adrep .h{display:flex;gap:8px;font-size:14.5px}#adm .adrep .h span{margin-left:auto;color:var(--muted);font-size:12px;white-space:nowrap}\n#adm .adrep .abx{font-size:13px;color:var(--muted);margin-top:4px;word-break:break-word}#adm .adrep a{color:var(--a2);cursor:pointer}\n#adm .adrep .rq{margin-top:6px;padding:8px 10px;border-radius:10px;background:var(--panel2);font-size:14px;white-space:pre-wrap;word-break:break-word}\n#adm .adrep .rb{display:flex;flex-wrap:wrap;gap:6px;margin-top:8px;align-items:center}\n#adm .adrep .rb button{display:inline-flex;align-items:center;gap:5px;padding:7px 11px;border-radius:12px;background:var(--panel2);font-weight:700;font-size:13px}#adm .adrep .rb svg{width:16px;height:16px}\n#adm .adrep .rb .st{color:var(--muted);font-size:12.5px}\n#adm .adrep .tg-ban{font-style:normal;font-size:11px;font-weight:700;padding:2px 7px;border-radius:9px;background:rgba(255,91,122,.15);color:var(--danger)}\n.banbox{display:flex;gap:10px;align-items:flex-start;margin:10px 0 6px;padding:12px;border-radius:14px;background:rgba(255,91,122,.12);color:var(--danger);text-align:left}\n.banbox svg{flex:none;width:22px;height:22px}.banbox b{display:block}.banbox span{display:block;font-size:13px;color:var(--text);opacity:.85;margin-top:2px;word-break:break-word}\n#info .banbox{margin:0 12px 10px}\n#readonly .rotx{display:flex;align-items:center;justify-content:center;gap:8px;color:var(--muted);font-size:14px;margin:0 0 8px;padding:0 10px;text-align:center}\n#readonly .rotx:last-child{margin:4px 0}#readonly .rotx svg{width:18px;height:18px;flex:none}#readonly .rotx.ban{color:var(--danger)}\n.iacts2{padding:6px!important}.iacts2 .iab{display:flex;align-items:center;gap:12px;width:100%;padding:11px 10px;border-radius:12px;font-weight:600;text-align:left}\n.iacts2 .iab:hover{background:var(--hover)}.iacts2 .iab svg{width:20px;height:20px;color:var(--muted)}.iacts2 .iab.red,.iacts2 .iab.red svg{color:var(--danger)}\n.rpl label{display:flex;gap:10px;align-items:center;padding:10px 12px;border-radius:12px;background:var(--panel2);margin-bottom:6px;cursor:pointer;font-weight:600}\n.rpl input{accent-color:var(--a1);width:18px;height:18px;flex:none}\n.uacts{display:flex;flex-wrap:wrap;gap:6px;justify-content:center;margin:4px 0 12px}\n.uacts button{display:inline-flex;align-items:center;gap:6px;padding:8px 12px;border-radius:12px;background:var(--panel2);font-weight:700;font-size:13px}.uacts button svg{width:16px;height:16px}.uacts .red{color:var(--danger)}\n#vplayer{position:fixed;inset:0;z-index:99850;background:#000;display:flex;align-items:center;justify-content:center;animation:fade .18s;touch-action:none;transition:opacity .2s}\n#vplayer video{width:100%;height:100%;object-fit:contain;background:#000}\n#vplayer .vptop,#vplayer .vpbot{position:absolute;left:0;right:0;display:flex;align-items:center;gap:8px;padding:12px 14px;color:#fff;transition:opacity .25s,transform .25s;z-index:2}\n#vplayer .vptop{top:0;padding-top:calc(12px + env(safe-area-inset-top));background:linear-gradient(rgba(0,0,0,.55),transparent)}\n#vplayer .vpbot{bottom:0;flex-direction:column;align-items:stretch;gap:4px;padding-bottom:calc(14px + env(safe-area-inset-bottom));background:linear-gradient(transparent,rgba(0,0,0,.7))}\n#vplayer:not(.ui) .vptop{opacity:0;transform:translateY(-10px);pointer-events:none}#vplayer:not(.ui) .vpbot{opacity:0;transform:translateY(10px);pointer-events:none}\n#vplayer:not(.ui){cursor:none}\n#vplayer .ib{color:#fff;background:rgba(255,255,255,.12);width:42px;height:42px}#vplayer .ib svg{width:22px;height:22px}\n#vplayer .sp{flex:1}\n#vplayer .vpchip{color:#fff;font-weight:800;font-size:14px;padding:9px 13px;border-radius:20px;background:rgba(255,255,255,.12)}\n#vplayer .vprow{display:flex;align-items:center;gap:8px}#vplayer .vt{font-size:13.5px;font-weight:700;font-variant-numeric:tabular-nums;opacity:.95}\n#vplayer .vpseek{position:relative;height:26px;display:flex;align-items:center;cursor:pointer;touch-action:none}\n#vplayer .vpseek .tr{position:relative;height:4px;flex:1;border-radius:4px;background:rgba(255,255,255,.25);overflow:hidden;transition:height .15s}\n#vplayer .vpseek:active .tr{height:6px}\n#vplayer .vpseek .buf{position:absolute;left:0;top:0;bottom:0;background:rgba(255,255,255,.35)}\n#vplayer .vpseek .fill{position:absolute;left:0;top:0;bottom:0;background:linear-gradient(90deg,var(--a1),var(--a2))}\n#vplayer .vpseek .knob{position:absolute;top:50%;width:14px;height:14px;margin:-7px 0 0 -7px;border-radius:50%;background:#fff;box-shadow:0 2px 8px rgba(0,0,0,.4)}\n#vplayer .vpbig{position:absolute;left:50%;top:50%;width:76px;height:76px;margin:-38px 0 0 -38px;border-radius:50%;background:rgba(0,0,0,.45);backdrop-filter:blur(6px);color:#fff;display:grid;place-items:center;z-index:2;transition:opacity .2s,transform .2s;opacity:0;pointer-events:none;transform:scale(.85)}\n#vplayer .vpbig svg{width:34px;height:34px}#vplayer.paused .vpbig{opacity:1;pointer-events:auto;transform:none}\n#vplayer .vpspin{position:absolute;left:50%;top:50%;width:44px;height:44px;margin:-22px 0 0 -22px;border:3px solid rgba(255,255,255,.25);border-top-color:#fff;border-radius:50%;animation:lmspin .8s linear infinite;display:none;z-index:1}\n#vplayer.wait .vpspin{display:block}\n#vplayer .vpskip{position:absolute;top:50%;margin-top:-40px;width:80px;height:80px;border-radius:50%;background:rgba(255,255,255,.14);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;opacity:0;pointer-events:none;font-size:12px;font-weight:700}\n#vplayer .vpskip.l{left:12%}#vplayer .vpskip.r{right:12%}#vplayer .vpskip.r b{transform:scaleX(-1)}#vplayer .vpskip svg{width:24px;height:24px}\n#vplayer .vpskip.on{animation:vpskip .6s ease}\n@keyframes vpskip{0%{opacity:0;transform:scale(.8)}25%{opacity:1;transform:none}100%{opacity:0}}\n.shbtns{display:flex;gap:8px;justify-content:center;flex-wrap:wrap}\n.myqr{text-align:center}.mqcard{display:flex;flex-direction:column;align-items:center;gap:2px;padding:18px 14px 20px;border-radius:24px;background:linear-gradient(160deg,rgba(124,92,255,.18),rgba(34,193,255,.12))}\n.mqcard b{font-size:19px;margin-top:8px}.mqcard>span{color:var(--muted);font-size:14px;margin-bottom:14px}\n.mqcard .qrbox{width:220px;height:220px;background:#fff;border-radius:22px;padding:14px;position:relative;box-shadow:0 12px 34px rgba(0,0,0,.2)}\n.mqcard .qrbox>svg{width:100%;height:100%;display:block}.mqcard .qrbox .qrmark{position:absolute;left:50%;top:50%;width:46px;height:46px;margin:-23px 0 0 -23px;border-radius:14px;background:var(--accent);display:grid;place-items:center;border:4px solid #fff;filter:none;opacity:1}.qrbox .qrmark svg{width:22px;height:22px;color:#fff}\n.qrhint{color:var(--muted);font-size:13.5px;line-height:1.45;margin:14px 4px 4px}\n.stbar{display:flex;gap:12px;overflow-x:auto;padding:6px 14px 10px;scrollbar-width:none}.stbar::-webkit-scrollbar{display:none}\n.stit{display:flex;flex-direction:column;align-items:center;gap:5px;width:66px;flex:none}\n.stav{position:relative;padding:3px;border-radius:50%;background:conic-gradient(from 200deg,#ff9f1a,#ff3b8a,#7c5cff,#22c1ff,#ff9f1a)}\n.stav.seen{background:var(--line)}.stav.none{background:none}.stav.mine{background:conic-gradient(from 200deg,#7c5cff,#22c1ff,#7c5cff)}\n.stav .av{width:56px;height:56px;border:3px solid var(--panel);font-size:20px;margin:0}\n.stav .stplus{position:absolute;right:-1px;bottom:-1px;width:22px;height:22px;border-radius:50%;background:var(--accent);color:#fff;display:grid;place-items:center;border:2.5px solid var(--panel)}.stav .stplus svg{width:13px;height:13px;stroke-width:3}\n.stnm{font-size:12px;font-weight:600;max-width:66px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--text)}\n.stnew{display:flex;justify-content:center;background:#000;border-radius:16px;overflow:hidden;max-height:52vh}.stnew img,.stnew video{max-width:100%;max-height:52vh;object-fit:contain;display:block}\n#stv{position:fixed;inset:0;z-index:100001;background:#000;display:flex;justify-content:center;animation:fade .2s;touch-action:none;user-select:none;-webkit-user-select:none}\n#stv.out{opacity:0;transition:opacity .2s}\n#stv .stin{position:relative;width:100%;max-width:480px;height:100%;display:flex;flex-direction:column;transition:transform .2s}\n#stv .stp{position:absolute;top:calc(8px + env(safe-area-inset-top));left:10px;right:10px;display:flex;gap:4px;z-index:3}\n#stv .stp i{flex:1;height:3px;border-radius:3px;background:rgba(255,255,255,.3);overflow:hidden}#stv .stp i b{display:block;height:100%;width:0;background:#fff}#stv .stp i.done b{width:100%}\n#stv .sthead{position:absolute;top:calc(18px + env(safe-area-inset-top));left:10px;right:6px;display:flex;align-items:center;gap:10px;z-index:3;color:#fff}\n#stv .sthead .av{width:38px;height:38px;font-size:14px;margin:0}#stv .sthn b{display:block;font-size:15px;text-shadow:0 1px 4px rgba(0,0,0,.5)}#stv .sthn span{font-size:12.5px;opacity:.85}\n#stv .sp{flex:1}#stv .ib{color:#fff;background:rgba(0,0,0,.25)}\n#stv .stmedia{flex:1;display:flex;align-items:center;justify-content:center;overflow:hidden;position:relative}\n#stv .stmedia img,#stv .stmedia video{width:100%;height:100%;object-fit:contain;pointer-events:none}\n#stv .stspin{position:absolute;left:50%;top:50%;width:40px;height:40px;margin:-20px 0 0 -20px;border:3px solid rgba(255,255,255,.25);border-top-color:#fff;border-radius:50%;animation:lmspin .8s linear infinite;display:none}\n#stv.wait .stspin{display:block}\n#stv .stcap{position:absolute;left:0;right:0;bottom:calc(76px + env(safe-area-inset-bottom));padding:10px 18px;color:#fff;text-align:center;font-size:15.5px;line-height:1.4;background:linear-gradient(transparent,rgba(0,0,0,.55));z-index:2;white-space:pre-wrap}\n#stv .stfoot{display:flex;align-items:center;gap:8px;padding:10px 12px calc(12px + env(safe-area-inset-bottom));z-index:3;background:#000}\n#stv .streply{flex:1;min-width:0;background:transparent;border:1.5px solid rgba(255,255,255,.35);border-radius:22px;color:#fff;padding:11px 16px;font:inherit;outline:none}\n#stv .streply::placeholder{color:rgba(255,255,255,.6)}\n#stv .sthrt.on{color:#ff3b5c}#stv .sthrt.on svg{fill:#ff3b5c}\n#stv .stviews,#stv .stadd{display:inline-flex;align-items:center;gap:7px;color:#fff;font-weight:700;padding:10px 14px;border-radius:20px;background:rgba(255,255,255,.12)}#stv .stviews svg,#stv .stadd svg{width:19px;height:19px}\n#stv .stnav{position:absolute;top:90px;bottom:80px;width:33%;z-index:1}#stv .stnav.l{left:0}#stv .stnav.r{right:0}\n#stv.hold .stp,#stv.hold .sthead,#stv.hold .stcap{opacity:0;transition:opacity .2s}\n#toast{z-index:100005!important}\n/* --- бета 3.3: профиль как в Telegram --- */\n#info .tgtop{display:flex;align-items:center;padding:10px 10px 0;border:0}\n.lnk2{font-weight:700;font-size:16px;color:var(--a1);padding:8px 12px;border-radius:12px}.lnk2:hover{background:var(--hover)}\n.ihead.tgh{padding:4px 16px 16px}\n.ibig .av{width:112px!important;height:112px!important;font-size:40px!important}\n.ibig.zoom{cursor:zoom-in;transition:transform .25s cubic-bezier(.34,1.56,.64,1)}.ibig.zoom:active{transform:scale(.94)}\n.ihead.tgh h2{font-size:26px;margin-top:14px}\n.ihead.tgh .st{font-size:15px}.ihead.tgh .st.live{color:var(--a2)}\n.iact.tga{width:100%;gap:8px}\n.iact.tga button{flex:1;width:auto;min-width:0;background:var(--panel2);color:var(--a1);font-weight:600;font-size:12.5px;padding:12px 0 10px;transition:transform .25s cubic-bezier(.34,1.56,.64,1)}\n.iact.tga button:active{transform:scale(.9)}.iact.tga button svg{width:22px;height:22px}\n.ikv.tgkv{display:flex;align-items:center;gap:8px}.ikv.tgkv>div{flex:1;min-width:0}\n.ikv .k{text-transform:none}\n.qrb svg{width:26px;height:26px;color:var(--a1)}\n.uqr .qrbox{animation:qrIn .5s cubic-bezier(.34,1.56,.64,1)}\n@keyframes qrIn{from{transform:scale(.8);opacity:0}to{transform:none;opacity:1}}\n.uqnick{display:inline-flex;align-items:center;gap:8px;margin-top:16px;padding:10px 18px;border-radius:22px;font-size:20px;font-weight:800;color:var(--a1);background:rgba(124,92,255,.14);box-shadow:0 0 18px rgba(124,92,255,.35);transition:transform .2s}\n.uqnick svg{width:18px;height:18px}.uqnick:active{transform:scale(.92)}.uqnick.ok{animation:nickOk .5s}\n@keyframes nickOk{30%{transform:scale(1.12)}100%{transform:none}}\n.uqh{font-size:12.5px;color:var(--muted);margin-top:6px}\n/* --- выбор нескольких сообщений --- */\n#mw.selmode .m{position:relative;padding-left:40px;cursor:pointer}\n#mw.selmode .m::before{content:'';position:absolute;left:6px;bottom:8px;width:22px;height:22px;border-radius:50%;border:2px solid var(--muted);box-sizing:border-box;transition:all .15s}\n#mw.selmode .m.sel::before{border:none;background:var(--accent) center/14px no-repeat url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='3.2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M5 12.5l4.5 4.5L19 7.5'/%3E%3C/svg%3E\")}\n#mw.selmode .m.sel{background:rgba(124,92,255,.12);border-radius:12px}\n#mw.selmode .m *{pointer-events:none}\n#selhead{position:absolute;inset:0;display:flex;align-items:center;gap:8px;padding:0 10px;background:var(--panel);z-index:5}\n#selhead b{flex:1;text-align:center;font-size:17px}#selhead span{width:70px}\n#passView:not(.pwok),#qrToPass,#toQr{display:none!important}\n#chathead{position:relative;padding-top:calc(8px + env(safe-area-inset-top));min-height:calc(62px + env(safe-area-inset-top))}\n#selbar{display:flex;padding:6px 8px calc(6px + env(safe-area-inset-bottom));background:var(--panel);border-top:1px solid var(--line)}\n#selbar button{flex:1;display:flex;flex-direction:column;align-items:center;gap:3px;font-size:11.5px;font-weight:700;color:var(--a1);padding:6px 0;border-radius:12px;transition:transform .2s}\n#selbar button:active{transform:scale(.88)}#selbar button.red{color:var(--danger)}#selbar button[disabled]{opacity:.35}\n#selbar svg{width:22px;height:22px}\n/* --- статус соединения --- */\n#netst{display:flex;align-items:center;justify-content:center;gap:8px;font-weight:800;font-size:15px;height:0;overflow:hidden;opacity:0;transition:height .25s,opacity .25s}\n#netst.on{height:34px;opacity:1}\n#netst .nsp{width:14px;height:14px;border:2px solid var(--muted);border-top-color:transparent;border-radius:50%;animation:lmspin .8s linear infinite}\n/* --- бета --- */\n.betab{display:inline-block;padding:2px 9px;border-radius:12px;background:var(--accent);color:#fff;font-weight:900;font-size:10.5px;letter-spacing:1px;margin-bottom:6px}\n.betat{display:inline-block;margin-top:6px;font-size:12px;font-weight:700;color:var(--muted)}\n/* --- значки нижней панели оживают --- */\n#tabs button[data-tab=\"contacts\"] .ti.tbump{animation:tbJump .55s cubic-bezier(.34,1.56,.64,1)}\n#tabs button[data-tab=\"chats\"] .ti.tbump{animation:tbWiggle .6s ease}\n#tabs button[data-tab=\"settings\"] .ti.tbump{animation:tbSpin .7s cubic-bezier(.34,1.56,.64,1)}\n@keyframes tbJump{0%{transform:none}35%{transform:translateY(-7px) scale(1.25)}100%{transform:none}}\n@keyframes tbWiggle{0%{transform:none}20%{transform:rotate(-14deg) scale(1.2)}40%{transform:rotate(12deg) scale(1.2)}60%{transform:rotate(-8deg) scale(1.1)}100%{transform:none}}\n@keyframes tbSpin{0%{transform:none}60%{transform:rotate(200deg) scale(1.25)}100%{transform:rotate(180deg)}}\n/* --- входящий звонок: \u00abОтветить\u00bb подпрыгивает, трубка дрожит, волны --- */\n.cbtns button.ringa{position:relative;overflow:visible;animation:accJump 1.2s ease-in-out infinite}\n.cbtns button.ringa svg{animation:accShake 1.4s ease-in-out infinite}\n.cbtns button.ringa i{position:absolute;inset:0;border-radius:50%;border:3px solid #2bd67b;animation:accWave 1.6s ease-out infinite;pointer-events:none}\n.cbtns button.ringa i+i{animation-delay:.8s}\n.cbtns button.ringb{animation:rejBreath 1.8s ease-in-out infinite}\n@keyframes accJump{0%,100%{transform:translateY(0)}30%{transform:translateY(-8px)}50%{transform:translateY(0)}}\n@keyframes accShake{0%,45%,100%{transform:none}5%{transform:rotate(-16deg)}10%{transform:rotate(14deg)}15%{transform:rotate(-12deg)}20%{transform:rotate(10deg)}25%{transform:rotate(-6deg)}30%{transform:none}}\n@keyframes accWave{from{transform:scale(1);opacity:.75}to{transform:scale(1.8);opacity:0}}\n@keyframes rejBreath{0%,100%{transform:scale(1)}50%{transform:scale(1.05)}}\n\n.bllist .row{display:flex;align-items:center;gap:10px;padding:8px 0}.bllist .mid{flex:1;min-width:0}.bllist .btn{padding:8px 12px;font-size:13px}\n.ncard .nci.tg{background:linear-gradient(135deg,#2aabee,#1d93d2)}.ncard .ncon.tg{background:linear-gradient(135deg,#2aabee,#1d93d2);text-decoration:none}\n/* ===== НАСТРОЙКИ ===== */\n#chat{background:var(--wall,none)}\n.spage.sinner{animation:spIn .42s cubic-bezier(.16,1,.3,1) both}.spage.smain{animation:fadeIn .35s both}\n@keyframes spIn{from{opacity:0;transform:translateX(28px)}to{opacity:1;transform:none}}\n.spage>*{animation:stg .5s cubic-bezier(.16,1,.3,1) both}.spage>*:nth-child(2){animation-delay:.03s}.spage>*:nth-child(3){animation-delay:.06s}.spage>*:nth-child(4){animation-delay:.09s}.spage>*:nth-child(5){animation-delay:.12s}.spage>*:nth-child(6){animation-delay:.15s}.spage>*:nth-child(n+7){animation-delay:.18s}\n.sphead{display:flex;align-items:center;gap:6px;padding:2px 0 10px}.sphead b{font-size:21px;font-weight:800;letter-spacing:-.3px}\n.shero{display:flex;flex-direction:column;align-items:center;text-align:center;padding:14px 10px 18px;margin:0 4px 14px;border-radius:26px;background:linear-gradient(160deg,color-mix(in srgb,var(--a1) 16%,transparent),color-mix(in srgb,var(--a2) 10%,transparent));border:1px solid var(--line)}\n.shero h2{margin:12px 0 2px;font-size:24px;letter-spacing:-.4px}.shero .st{color:var(--muted);font-weight:600}\n.shbio{margin-top:8px;font-size:14px;max-width:320px;line-height:1.4}\n.shedit{margin-top:14px;padding:9px 16px!important;border-radius:14px!important;gap:6px;background:var(--panel)!important}.shedit svg{width:17px;height:17px}\n.shav{position:relative;cursor:pointer;border-radius:50%;transition:transform .3s cubic-bezier(.34,1.56,.64,1)}.shav:active{transform:scale(.94)}\n.shav .av{box-shadow:0 10px 30px rgba(0,0,0,.18)}\n.shcam{position:absolute;right:2px;bottom:2px;width:34px;height:34px;border-radius:50%;background:var(--accent);color:#fff;display:grid;place-items:center;border:3px solid var(--bg)}.shcam svg{width:17px;height:17px}\n.sic{width:32px;height:32px;border-radius:10px;display:grid;place-items:center;color:#fff;flex:none;box-shadow:0 3px 8px rgba(0,0,0,.12)}.sic svg{width:18px;height:18px}\n.srow .chev{color:var(--muted);display:grid;place-items:center}.srow .chev svg{width:18px;height:18px}\n.setgrp .srow+.srow,.setgrp .sradio+.sradio{border-top:1px solid var(--line);border-radius:0}\n.setgrp{overflow:hidden}\n.slink{color:var(--a1);font-weight:700;font-size:13px}\n.sfoot{text-align:center;color:var(--muted);font-size:12px;padding:6px 0 18px}\n.sradio{padding:13px 8px!important}.sradio .rchk{width:24px;height:24px;border-radius:50%;display:grid;place-items:center;color:#fff;background:transparent;border:2px solid var(--line);transition:.25s}\n.sradio .rchk svg{width:14px;height:14px;opacity:0;transform:scale(.4);transition:.3s cubic-bezier(.34,1.56,.64,1)}\n.sradio.on .rchk{background:var(--accent);border-color:transparent}.sradio.on .rchk svg{opacity:1;transform:none}\n.sform{padding:12px!important}.sform .inp{background:var(--panel)}\n.atinp{display:flex;align-items:center;background:var(--panel);border-radius:14px;border:1px solid var(--line)}.atinp span{padding-left:14px;color:var(--muted);font-weight:700}.atinp .inp{border:0!important;background:none!important;padding-left:4px}\n.fhint{font-size:12px;color:var(--muted);margin-top:6px;line-height:1.35}.fhint.pad{padding:0 14px 14px}\n.cnt{float:right;color:var(--muted);font-weight:600;text-transform:none;letter-spacing:0}\n.sethdr .cnt{float:none;margin-left:6px;color:var(--a1)}\n.seg{display:flex;gap:6px;margin:0 4px 12px;padding:5px;background:var(--panel2);border-radius:18px}\n.seg button{flex:1;display:flex;flex-direction:column;align-items:center;gap:5px;padding:11px 4px;border-radius:14px;font-weight:700;font-size:12.5px;color:var(--muted);transition:background .3s,color .3s,transform .25s cubic-bezier(.34,1.56,.64,1)}\n.seg button svg{width:20px;height:20px}.seg button.on{background:var(--panel);color:var(--text);box-shadow:0 3px 12px rgba(0,0,0,.1)}.seg button:active{transform:scale(.94)}\n.lkprev{margin:0 4px 14px;border-radius:22px;padding:18px 14px;display:flex;flex-direction:column;gap:8px;border:1px solid var(--line);transition:background .4s}\n.lkm{max-width:78%;padding:8px 12px;border-radius:18px;line-height:1.4;transition:font-size .2s}.lkm.in{background:var(--in);align-self:flex-start;border-bottom-left-radius:6px}.lkm.out{background:var(--out);color:var(--out-text,#fff);align-self:flex-end;border-bottom-right-radius:6px}\n.fsrow{display:flex;align-items:center;gap:12px;padding:12px 8px;color:var(--muted);font-weight:700}\n.fsrow input{flex:1;accent-color:var(--a1);height:28px}\n.walls{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin:0 4px 16px}\n.wl{aspect-ratio:3/4;border-radius:16px;border:2px solid var(--line);display:grid;place-items:center;color:var(--muted);font-size:12px;font-weight:700;transition:transform .25s cubic-bezier(.34,1.56,.64,1),border-color .25s}\n.wl.on{border-color:var(--a1);box-shadow:0 0 0 3px color-mix(in srgb,var(--a1) 25%,transparent)}.wl:active{transform:scale(.94)}\n.about{display:flex;flex-direction:column;align-items:center;text-align:center;padding:10px 0 18px}.about h2{margin:12px 0 2px;font-size:26px}.about .st{color:var(--muted)}\n.mark.big{width:84px;height:84px;border-radius:26px;background:var(--accent);display:grid;place-items:center;color:#fff;box-shadow:0 16px 40px rgba(124,92,255,.4);animation:markIn .8s cubic-bezier(.34,1.56,.64,1) both}.mark.big svg{width:42px;height:42px}\n/* выбор области фото */\n.crop{position:fixed;inset:0;z-index:100000;touch-action:none;overscroll-behavior:contain;background:rgba(6,6,16,.78);backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);display:grid;place-items:center;padding:16px;animation:fadeIn .25s both}\n.crop.out{opacity:0;transition:opacity .25s}\n.crbox{width:min(420px,100%);background:var(--panel);color:var(--text);border-radius:28px;padding:18px;box-shadow:0 30px 80px rgba(0,0,0,.45);animation:crIn .45s cubic-bezier(.16,1,.3,1) both}\n@keyframes crIn{from{opacity:0;transform:translateY(24px) scale(.96)}to{opacity:1;transform:none}}\n.crhd{display:flex;flex-direction:column;gap:2px;margin:0 4px 14px}.crhd b{font-size:19px;font-weight:800}.crhd span{color:var(--muted);font-size:13px}\n.crst{position:relative;width:100%;aspect-ratio:1;border-radius:20px;overflow:hidden;background:#111;touch-action:none;cursor:grab;user-select:none;-webkit-user-select:none}\n.crst.drag{cursor:grabbing}.crst canvas{position:absolute;inset:0;width:100%;height:100%;display:block}\n.crring{position:absolute;inset:0;border-radius:50%;box-shadow:0 0 0 999px rgba(0,0,0,.55);border:2px solid rgba(255,255,255,.9);pointer-events:none}\n.crst.drag .crring{background:linear-gradient(rgba(255,255,255,.25),rgba(255,255,255,.25)) 33.3% 0/1px 100% no-repeat,linear-gradient(rgba(255,255,255,.25),rgba(255,255,255,.25)) 66.6% 0/1px 100% no-repeat,linear-gradient(rgba(255,255,255,.25),rgba(255,255,255,.25)) 0 33.3%/100% 1px no-repeat,linear-gradient(rgba(255,255,255,.25),rgba(255,255,255,.25)) 0 66.6%/100% 1px no-repeat}\n.crz{display:flex;align-items:center;gap:10px;margin:14px 4px 4px;color:var(--muted)}.crz svg{width:20px;height:20px;cursor:pointer;flex:none}.crz input{flex:1;accent-color:var(--a1);height:28px}\n.crbt{display:flex;align-items:center;gap:10px;margin-top:12px}.crbt .btn{flex:1}.crbt .crrot{flex:none;width:46px;height:46px;border-radius:14px;background:var(--panel2)}\n.intg #toQr,.intg .qrfoot{display:none!important}\n@media (prefers-reduced-motion:reduce){*,*::before,*::after{animation-duration:.01ms!important;animation-iteration-count:1!important;transition-duration:.01ms!important}}\n@media (max-width:1100px){#info{position:absolute;right:0;top:0;bottom:0;z-index:30;box-shadow:var(--shadow)}}\n@media (max-width:800px){\n#side{width:100%;min-width:0;border:0;position:absolute;inset:0;transition:transform .25s}\n#main{position:absolute;inset:0;transform:translateX(100%);transition:transform .25s;z-index:5}\n#app.inchat #main{transform:none}\n#app.inchat #side{transform:translateX(-25%)}\n#back{display:grid}\n#hSearch{display:none}\n#info{width:100%}\n.b{max-width:86%}\n#down{bottom:84px}\n}\n\n/* изменение профиля и конфиденциальность \u2014 как в Telegram */\n.pex{padding:4px 0 40px}\n.petop2{display:flex;align-items:flex-start;justify-content:space-between;padding:6px 16px 22px}\n.pebtn{width:52px;height:52px;border-radius:50%;border:0;background:var(--panel2);color:var(--text);display:grid;place-items:center;cursor:pointer;transition:transform .15s;flex:none;box-shadow:0 2px 10px rgba(0,0,0,.08)}\n.pebtn:active{transform:scale(.88)}.pebtn svg{width:24px;height:24px}\n.pebtn.ok{background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff}\n.peav{display:flex;flex-direction:column;align-items:center;gap:12px;padding-top:4px;min-width:0}\n.peavi{cursor:pointer;transition:transform .2s}.peavi:active{transform:scale(.95)}\n.pelnk{font-size:18px;color:var(--a1);background:none;border:0;cursor:pointer;padding:0}\n.pecard{background:var(--panel2);border-radius:26px;margin:0 16px;overflow:hidden}\n.pein{display:block;width:100%;box-sizing:border-box;border:0;background:transparent;color:var(--text);font:inherit;font-size:17px;padding:17px 20px;outline:none;resize:none}\n.pein::placeholder{color:var(--muted);opacity:.75}\n.pesep{height:1px;background:var(--line);margin-left:20px}.pesep.i{margin-left:68px}\n.e2elk{display:inline-flex;vertical-align:-2px;margin-left:5px;color:var(--a2)}.e2elk svg{width:14px;height:14px}\n.pehint{color:var(--muted);font-size:14px;padding:7px 32px 18px;line-height:1.4}.pehint a{color:var(--a1);font-weight:600;cursor:pointer}\n.perow{display:flex;align-items:center;gap:16px;padding:0 18px;min-height:56px;cursor:pointer;position:relative;font-size:17px;transition:background .15s}\n.perow:active{background:var(--line)}\n.perow .sl{flex:none;white-space:nowrap}.perow .peval{color:var(--muted);flex:1;min-width:0;text-align:right;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.perow>.sl:last-child,.perow>.sl:nth-last-child(2):not(:has(+.peval)){flex:1}\n.perow .chev{opacity:.5}.perow.red{color:var(--danger);justify-content:center}\n.perow input[type=date]{position:absolute;inset:0;opacity:0;cursor:pointer;width:100%}\n.pesec{color:var(--muted);font-size:13px;padding:22px 32px 8px;text-transform:uppercase}\n.pechk{color:var(--a1);display:grid}.pechk svg{width:20px;height:20px}\n.pecolors{display:flex;justify-content:space-between;padding:18px}\n.pecolors b{width:36px;height:36px;border-radius:50%;cursor:pointer;display:grid;place-items:center;color:#fff;outline:3px solid transparent;outline-offset:3px;transition:transform .15s}\n.pecolors b.on{outline-color:var(--text)}.pecolors b:active{transform:scale(.85)}.pecolors b svg{width:18px;height:18px}\n.peprev{display:flex;align-items:center;gap:14px;padding:18px}.peprev .bub{background:var(--panel);border-radius:16px;padding:8px 12px}\n.peprev .bub b{display:block;font-size:14px}\n";document.head.appendChild(st);var f=document.createElement('link');f.rel='stylesheet';f.href='https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&display=swap';document.head.appendChild(f);document.title='Lumo';var h=document.getElementById('lumo-mount')||document.body;h.insertAdjacentHTML('beforeend',"<div id=\"lumo-root\">\n<div id=\"splash\"><div class=\"mark\"><svg class=\"i\" style=\"width:44px;height:44px;color:#fff\" viewBox=\"0 0 24 24\"><path d=\"M21 11.5a8.4 8.4 0 0 1-9 8.4 9 9 0 0 1-4-1L3 20l1.3-4A8.4 8.4 0 0 1 12 3a8.5 8.5 0 0 1 9 8.5z\"/><path d=\"M8.5 12h.01M12 12h.01M15.5 12h.01\" stroke-width=\"3\"/></svg></div><div class=\"sname\">Lumo</div></div>\n<div id=\"auth\" class=\"hidden\">\n<div class=\"blobs\"><i></i><i></i><i></i></div>\n<div class=\"authcard\">\n<div class=\"logo\"><div class=\"mark\"><svg class=\"i\" style=\"width:30px;height:30px;color:#fff\" viewBox=\"0 0 24 24\"><path d=\"M21 11.5a8.4 8.4 0 0 1-9 8.4 9 9 0 0 1-4-1L3 20l1.3-4A8.4 8.4 0 0 1 12 3a8.5 8.5 0 0 1 9 8.5z\"/><path d=\"M8.5 12h.01M12 12h.01M15.5 12h.01\" stroke-width=\"3\"/></svg></div><h1>Lumo</h1></div>\n<p class=\"sub\">Быстрый и красивый мессенджер<br><span class=\"betat\">Бета-версия 3.3</span></p>\n<div id=\"qrView\" class=\"hidden\">\n<div class=\"qrbox\"><div id=\"qrImg\"><div class=\"qrspin\"></div></div></div>\n<h3 class=\"qrh\">Вход по QR-коду</h3>\n<ol class=\"qrsteps\"><li>Откройте Lumo на телефоне</li><li>Зайдите в <b>Настройки \u2192 Подключить компьютер</b></li><li>Наведите камеру телефона на этот код</li></ol>\n<div class=\"qrst\" id=\"qrSt\"></div>\n<p class=\"qrnote hidden\" id=\"qrNote\">Нет аккаунта? Зарегистрируйтесь в Lumo на телефоне, а потом отсканируйте этот код.</p>\n<button class=\"btn ghost w\" id=\"qrToPass\" type=\"button\">Войти по юзернейму и паролю</button>\n</div>\n<div id=\"passView\">\n<div class=\"tabs\"><button id=\"tLogin\" class=\"on\">Вход</button><button id=\"tReg\">Регистрация</button></div>\n<div id=\"authForm\" role=\"form\">\n<div class=\"field collapse\" id=\"fName\"><label>Имя</label><input class=\"inp\" id=\"aName\" placeholder=\"Как вас зовут\" maxlength=\"64\"></div>\n<div class=\"field\"><label>Юзернейм</label><input class=\"inp\" id=\"aUser\" placeholder=\"например, ivan_99\" autocomplete=\"username\" autocapitalize=\"off\" spellcheck=\"false\"></div>\n<div class=\"field\"><label>Пароль</label><input class=\"inp\" id=\"aPass\" type=\"password\" placeholder=\"Минимум 6 символов\" autocomplete=\"current-password\"></div>\n<div class=\"err\" id=\"aErr\"></div>\n<button class=\"btn primary w\" id=\"aBtn\" type=\"button\">Войти</button>\n</div>\n<button class=\"lnk\" id=\"toQr\" type=\"button\">Войти по QR-коду</button>\n<div class=\"tgor\"><i></i><span>или</span><i></i></div>\n<a class=\"btn tgw w dis\" id=\"tgLogin\" href=\"#\" target=\"_blank\" rel=\"noopener\"><svg viewBox=\"0 0 24 24\"><path fill=\"currentColor\" stroke=\"none\" d=\"M21.9 4.3 18.7 19.4c-.2 1-.9 1.3-1.8.8l-4.9-3.6-2.4 2.3c-.3.3-.5.5-1 .5l.4-5 9-8.2c.4-.3-.1-.5-.6-.2L6.3 13 1.5 11.5c-1-.3-1-1 .2-1.5l18.8-7.2c.9-.3 1.6.2 1.4 1.5z\"/></svg><span id=\"tgLoginTx\">Войти через Telegram</span></a>\n<div class=\"tgwait hidden\" id=\"tgWait\"><span class=\"tgsp\"></span><span>Нажмите \u00abЗапустить\u00bb в боте и вернитесь сюда \u2014 вход выполнится сам</span></div>\n</div>\n</div>\n</div>\n<div id=\"app\" class=\"hidden\">\n<aside id=\"side\">\n<div class=\"tophead hidden\" id=\"tophead\">\n<button class=\"hbtn hide\" id=\"topBack\" title=\"Назад\"></button>\n<b id=\"tabTitle\">Чаты</b>\n<button class=\"hbtn hidden\" id=\"menuBtn\" title=\"Меню\"></button><span class=\"hbtn hide\"></span>\n</div>\n<div class=\"sbar\" id=\"qbox\"><label class=\"search\"><span data-i=\"search\"></span><input id=\"q\" placeholder=\"Поиск\" autocomplete=\"off\"></label><button class=\"hbtn sq\" id=\"newBtn\" title=\"Новый чат\"></button></div>\n<div class=\"folders\" id=\"folders\">\n<button data-f=\"all\" class=\"on\">Все</button><button data-f=\"private\">Чаты</button><button data-f=\"group\">Группы</button><button data-f=\"channel\">Каналы</button><i class=\"find\"></i>\n</div>\n<div id=\"list\"></div>\n<div id=\"pane\" class=\"hidden\"></div>\n<nav id=\"tabs\"><i class=\"tind\"></i>\n<button data-tab=\"calls\" title=\"Звонки\"><span class=\"ti\" data-ti=\"phone\"></span><span class=\"tl\">Звонки</span><span class=\"badge red hidden\" id=\"bCalls\"></span></button>\n<button data-tab=\"chats\" class=\"on\" title=\"Чаты\"><span class=\"ti\" data-ti=\"chatF\"></span><span class=\"tl\">Чаты</span><span class=\"badge red hidden\" id=\"bChats\"></span></button>\n<button data-tab=\"settings\" title=\"Настройки\"><span class=\"ti\" id=\"tabMe\" data-ti=\"gear\"></span><span class=\"tl\">Настройки</span></button>\n</nav>\n</aside>\n<section id=\"main\">\n<div class=\"pattern\"></div>\n<div id=\"empty\"><div class=\"pill\">Выберите чат, чтобы начать общение</div></div>\n<div id=\"chat\" class=\"hidden\">\n<header id=\"chathead\">\n<button class=\"ib\" id=\"back\"></button>\n<div class=\"who\" id=\"who\"></div>\n<button class=\"ib\" id=\"hSearch\" title=\"Поиск\"></button>\n<button class=\"ib\" id=\"hCall\" title=\"Звонок\"></button>\n<button class=\"ib\" id=\"hVideo\" title=\"Видеозвонок\"></button>\n<button class=\"ib\" id=\"hMore\" title=\"Ещё\"></button>\n</header>\n<div id=\"insearch\" class=\"hidden\"><label class=\"search\"><span data-i=\"search\"></span><input id=\"iq\" placeholder=\"Поиск в чате\"></label><span id=\"iqn\" style=\"color:var(--muted);font-size:13px;font-weight:600\"></span><button class=\"ib\" id=\"iqUp\"></button><button class=\"ib\" id=\"iqDown\"></button><button class=\"ib\" id=\"iqX\"></button></div>\n<div id=\"pinbar\" class=\"hidden\"></div>\n<div id=\"msgs\"><div class=\"wrap\" id=\"mw\"></div></div>\n<button id=\"down\" class=\"hidden\"></button>\n<div id=\"composer\">\n<div class=\"wrap\">\n<div class=\"cbox\" id=\"cbox\">\n<div id=\"ctx\" class=\"ctx hidden\"></div>\n<div class=\"cline\">\n<button class=\"ib\" id=\"atBtn\" title=\"Прикрепить\"></button>\n<textarea id=\"txt\" rows=\"1\" placeholder=\"Сообщение\"></textarea>\n<button class=\"ib\" id=\"emBtn\" title=\"Эмодзи и стикеры\"></button>\n</div>\n</div>\n<div id=\"recbar\" class=\"hidden\"><span class=\"dot\"></span><span class=\"tm\" id=\"recTm\">0:00</span><span class=\"hint\" id=\"recHint\">\u2039 Влево \u2014 отмена</span><button class=\"ib hidden\" id=\"recDel\" title=\"Удалить\"></button></div>\n<button id=\"sendbtn\"></button>\n</div>\n</div>\n<div id=\"readonly\" class=\"hidden\"><button id=\"roBtn\">Без звука</button></div>\n<div id=\"emoji\" class=\"hidden\"></div>\n</div>\n</section>\n<aside id=\"info\" class=\"hidden\"></aside>\n</div>\n<input type=\"file\" id=\"fileIn\" multiple class=\"hidden\">\n<input type=\"file\" id=\"mediaIn\" accept=\"image/*,video/*\" multiple class=\"hidden\">\n<input type=\"file\" id=\"avIn\" accept=\"image/*\" class=\"hidden\">\n</div>");var own=h.lastElementChild;st.setAttribute('data-lumo-own','1');try{if(own){own.setAttribute('data-lumo-own','1');var ids={};[].forEach.call(own.querySelectorAll('[id]'),function(e){ids[e.id]=1;});if(own.id)ids[own.id]=1;var kill=function(n){if(!n||n.nodeType!==1||n===own||own.contains(n)||n.contains(own))return;if(n.tagName==='STYLE'){if(!n.hasAttribute('data-lumo-own')&&n.textContent.indexOf('#sendbtn')>=0)n.remove();return;}if(n.tagName==='SCRIPT'){if(!n.src&&n.textContent.indexOf('SUPABASE_URL')>=0&&/lm_messages|lumo-root|sendbtn/.test(n.textContent))n.remove();return;}if(n.id&&ids[n.id]){n.remove();}};[].forEach.call(document.querySelectorAll('[id],style,script'),kill);new MutationObserver(function(ms){ms.forEach(function(m){[].forEach.call(m.addedNodes,function(n){kill(n);if(n.querySelectorAll)[].forEach.call(n.querySelectorAll('[id],style,script'),kill);});});}).observe(document.documentElement,{childList:true,subtree:true});}}catch(e){}})();
if(!window.__lumoRun){window.__lumoRun=1;
(function(){
"use strict";
// На странице может оказаться ещё одна (старая) копия Lumo (например, в соседнем HTML-блоке Тильды).
// Обе копии реагировали бы на одни и те же кнопки: двойные голосовые, двойной звук. Поэтому:
// 1) разметка, стили и скрипт чужой копии удаляются вместе с её обработчиками;
// 2) старая копия, вставленная обычным скриптом, объявляет свои функции глобально \u2014 они заменяются пустышками.
(function lumoOne(){ try{
  if(window.__lumoOne) return; window.__lumoOne=1;
  const me=document.currentScript;
  const before=n=>!me||!!(n.compareDocumentPosition(me)&Node.DOCUMENT_POSITION_FOLLOWING);
  let own=null; document.querySelectorAll('#lumo-root').forEach(r=>{ if(r.hasAttribute('data-lumo-own')||before(r)) own=r; });
  if(!own) return;
  own.setAttribute('data-lumo-own','1');
  let myStyle=null; document.querySelectorAll('style').forEach(st=>{ if(st.hasAttribute('data-lumo-own')||(before(st)&&st.textContent.indexOf('#sendbtn')>=0)) myStyle=st; });
  if(myStyle) myStyle.setAttribute('data-lumo-own','1');
  const ids=new Set(); own.querySelectorAll('[id]').forEach(e=>ids.add(e.id)); ids.add('lumo-root');
  const kill=n=>{ if(!n||n.nodeType!==1||n===own||own.contains(n)||n.contains(own)||n===me) return;
    if(n.tagName==='STYLE'){ if(!n.hasAttribute('data-lumo-own')&&n.textContent.indexOf('#sendbtn')>=0) n.remove(); return; }
    if(n.tagName==='SCRIPT'){ if(!n.src&&n.textContent.indexOf('SUPABASE_URL')>=0&&/sendbtn|lm_messages/.test(n.textContent)) n.remove(); return; }
    if(n.id&&ids.has(n.id)) n.remove(); };
  document.querySelectorAll('[id],style,script').forEach(kill);
  new MutationObserver(ms=>ms.forEach(m=>m.addedNodes.forEach(n=>{ kill(n); if(n.querySelectorAll) n.querySelectorAll('[id],style,script').forEach(kill); }))).observe(document.documentElement,{childList:true,subtree:true});
  const MARKS=['#sendbtn','lm_messages','lm_profiles','lm_members','S.cur','SUPABASE_KEY',"'#avIn'",'storage.from(','lm-call-','callUI(','C.st=','ringtone(','onSig('];
  // старая копия держит своё подключение к серверу: слушает звонки, отвечает на них и обновляет вход \u2014 отключаем его полностью
  const killSb=()=>{ try{ const o=(0,eval)("typeof sb!=='undefined'?sb:null"); if(!o||o.__lumoDead) return; o.__lumoDead=1;
      try{ o.auth&&o.auth.stopAutoRefresh&&o.auth.stopAutoRefresh(); }catch(e){}
      try{ o.removeAllChannels&&o.removeAllChannels(); }catch(e){}
      try{ o.realtime&&o.realtime.disconnect&&o.realtime.disconnect(); }catch(e){}
      try{ o.channel=function(){ const c={on(){return c},subscribe(){return c},send(){return Promise.resolve('ok')},track(){return Promise.resolve()},untrack(){return Promise.resolve()},unsubscribe(){return Promise.resolve()},presenceState(){return {}}}; return c; }; }catch(e){}
      console.warn('Lumo: отключено соединение старой копии приложения'); }catch(e){} };
  const neuter=()=>{ let n=0; for(const k of Object.getOwnPropertyNames(window)){ let d; try{ d=Object.getOwnPropertyDescriptor(window,k); }catch(e){ continue; }
      if(!d||typeof d.value!=='function'||!d.writable) continue; let src=''; try{ src=Function.prototype.toString.call(d.value); }catch(e){ continue; }
      if(src.indexOf('[native code]')>=0||src.length<20) continue;
      if(MARKS.some(m=>src.indexOf(m)>=0)){ try{ window[k]=function(){}; n++; }catch(e){} } }
    killSb(); if(n) console.warn('Lumo: отключена старая копия приложения на странице ('+n+' функций)'); };
  neuter(); setTimeout(neuter,0); setTimeout(neuter,1000); setTimeout(neuter,4000); document.addEventListener('DOMContentLoaded',neuter);
}catch(e){ console.warn('lumoOne',e); } })();
/* ================= CONFIG ================= */
// Основной сервер (за рубежом). В России он бывает недоступен без VPN \u2014 тогда Lumo сам переключается
// на сервер-посредник в России (PROXY_URLS), который пересылает всё на основной сервер.
const SUPABASE_ORIGIN = 'https://foniukmpiukuwpcdvdhp.supabase.co';
const PROXY_URLS = ['https://api.lumomess.ru'];
let SUPABASE_URL = SUPABASE_ORIGIN;
const SUPABASE_KEY = 'sb_publishable_cE72E1dUPnfaVn8mPnc9sA_U2HO-mxN';
const EMAIL_DOMAIN = '@lumo.app';
const BUCKET = 'lm-media';
let FN = SUPABASE_URL + '/functions/v1/lumo';
/* ---- выбор пути до сервера: напрямую или через посредника в России ---- */
const ROUTE={via:'direct'};
// адреса файлов в базе хранятся \u00abкак есть\u00bb (основной сервер); при работе через посредника подменяем их на лету
const pxu=u=>(typeof u==='string'&&SUPABASE_URL!==SUPABASE_ORIGIN&&u.startsWith(SUPABASE_ORIGIN))?SUPABASE_URL+u.slice(SUPABASE_ORIGIN.length):u;
const unpx=u=>(typeof u==='string'&&SUPABASE_URL!==SUPABASE_ORIGIN&&u.startsWith(SUPABASE_URL))?SUPABASE_ORIGIN+u.slice(SUPABASE_URL.length):u;
// проверка: сервер не просто отвечает, а отдаёт заметный объём данных (у некоторых провайдеров соединение \u00abдушат\u00bb после первых килобайт)
async function probeRoute(base,ms){ const c=new AbortController(); const t=setTimeout(()=>c.abort(),ms);
  try{ const r=await fetch(base+'/functions/v1/lumo/ping?kb=48&t='+Date.now(),{signal:c.signal,cache:'no-store'}); if(!r.ok) return false; const b=await r.text(); return b.length>40000; }
  catch{ return false; } finally{ clearTimeout(t); } }
function useRoute(base){ SUPABASE_URL=base; FN=base+'/functions/v1/lumo'; ROUTE.via=base===SUPABASE_ORIGIN?'direct':'proxy'; if(ROUTE.via==='proxy') proxyRewriteOn(); }
async function pickRoute(){
  const proxies=PROXY_URLS.filter(Boolean); if(!proxies.length) return;
  let saved=null; try{ saved=JSON.parse(localStorage.getItem('lm_route')||'null'); }catch{}
  const remember=v=>{ try{ localStorage.setItem('lm_route',JSON.stringify({v,t:Date.now()})); }catch{} };
  // недавно уже выяснили, что нужен посредник \u2014 сразу через него, а напрямую перепроверим в фоне
  if(saved&&saved.v!=='direct'&&proxies.includes(saved.v)&&Date.now()-saved.t<12*3600e3){ useRoute(saved.v);
    probeRoute(SUPABASE_ORIGIN,6000).then(ok=>{ if(ok) remember('direct'); }); return; }
  const direct=probeRoute(SUPABASE_ORIGIN,saved&&saved.v==='direct'?6000:4000);
  const viaP=proxies.map(u=>probeRoute(u,8000).then(ok=>ok?u:Promise.reject()));
  if(await direct){ remember('direct'); return; }
  try{ const u=await Promise.any(viaP); useRoute(u); remember(u); }
  catch{ /* посредник тоже недоступен \u2014 остаёмся на прямом пути */ }
}
function proxyRewriteOn(){ if(ROUTE.rw) return; ROUTE.rw=1;
  const fix=el=>{ if(!el||el.nodeType!==1) return;
    for(const a of ['src','href','poster','data-view']){ const v=el.getAttribute&&el.getAttribute(a); if(v&&v.indexOf(SUPABASE_ORIGIN)>=0) el.setAttribute(a,v.split(SUPABASE_ORIGIN).join(SUPABASE_URL)); }
    const st=el.getAttribute&&el.getAttribute('style'); if(st&&st.indexOf(SUPABASE_ORIGIN)>=0) el.setAttribute('style',st.split(SUPABASE_ORIGIN).join(SUPABASE_URL)); };
  const scan=n=>{ if(!n||n.nodeType!==1) return; fix(n); n.querySelectorAll&&n.querySelectorAll('[src],[href],[poster],[style],[data-view]').forEach(fix); };
  new MutationObserver(ms=>ms.forEach(m=>{ if(m.type==='attributes') fix(m.target); else m.addedNodes.forEach(scan); }))
    .observe(document.documentElement,{subtree:true,childList:true,attributes:true,attributeFilter:['src','href','poster','style','data-view']});
  scan(document.body);
  for(const P of [HTMLMediaElement.prototype,HTMLImageElement.prototype,HTMLSourceElement.prototype]){ const d=Object.getOwnPropertyDescriptor(P,'src'); if(d&&d.set) Object.defineProperty(P,'src',{...d,set(v){ d.set.call(this,pxu(v)); }}); }
  const of=window.fetch.bind(window); window.fetch=(u,o)=>of(typeof u==='string'?pxu(u):u,o);
  const oo=window.open; window.open=function(u,...r){ return oo.call(window,pxu(u),...r); };
}
// Lumo открыт как мини-приложение внутри Telegram: Telegram передаёт подписанные данные пользователя в адресе (#tgWebAppData=...)
const TGA=(()=>{ let init=''; try{ const m=location.hash.match(/tgWebAppData=([^&]+)/); if(m) init=decodeURIComponent(m[1]); }catch{}
  try{ if(init) sessionStorage.setItem('lm_tga',init); else init=sessionStorage.getItem('lm_tga')||''; }catch{}
  let chat=''; try{ chat=new URLSearchParams(location.search).get('c')||''; }catch{}
  return {init, chat:/^[\w-]{1,64}$/.test(chat)?chat:'', on:!!init, nolink:false}; })();
let WA=null;
function tgAppSetup(){ if(!TGA.on) return; document.documentElement.classList.add('intg');
  loadScript('https://telegram.org/js/telegram-web-app.js',8000).then(()=>{ WA=window.Telegram&&window.Telegram.WebApp; if(!WA) return;
    try{ WA.ready(); WA.expand(); WA.disableVerticalSwipes?.(); }catch{}
    const paint=()=>{ try{ const bg=getComputedStyle(document.body).backgroundColor; WA.setHeaderColor?.(bg); WA.setBackgroundColor?.(bg); WA.setBottomBarColor?.(bg); }catch{} };
    paint(); setInterval(paint,3000);
    try{ WA.BackButton.onClick(()=>{ const c=document.querySelector('body>.crop'); if(c){ c.querySelector('[data-a="x"]')?.click(); return; } const o=document.querySelector('body>.ov'); if(o){ o.remove(); return; } if(S.cur) closeChat(); }); }catch{}
    setInterval(()=>{ try{ const need=!!(S.cur&&innerWidth<=800)||!!document.querySelector('body>.ov,body>.crop'); if(need!==WA.BackButton.isVisible) WA.BackButton[need?'show':'hide'](); }catch{} },250);
  }).catch(()=>{}); }
async function tgApp(body,auth){ const h={'Content-Type':'text/plain'}; if(auth){ const {data:{session}}=await sb.auth.getSession(); if(session) h.Authorization='Bearer '+session.access_token; }
  const r=await fetch(FN+'/tgapp',{method:'POST',headers:h,body:JSON.stringify({init:TGA.init,...body})}); return r.json(); }
// вход: Telegram-аккаунт уже привязан к Lumo \u2014 входим без пароля
async function tgAppLogin(session){
  const j=await tgApp({uid:session?.user?.id||''});
  if(j.same){ await start(); return true; }
  if(j.th){ if(session){ try{ await sb.auth.signOut({scope:'local'}); }catch{} }
    const {error}=await sb.auth.verifyOtp({token_hash:j.th,type:'magiclink'}); if(error) throw error; await start(); return true; }
  TGA.nolink=!!j.nolink; return false; }
async function tgAppCreate(){ const a=$('#tgLogin'); a.classList.add('loading'); $('#aErr').textContent='';
  try{ const j=await tgApp({create:true}); if(!j.th) throw new Error(j.error||'не получилось');
    const {error}=await sb.auth.verifyOtp({token_hash:j.th,type:'magiclink'}); if(error) throw error;
    TGA.nolink=false; if(j.new) setTimeout(()=>toast('Аккаунт создан: @'+(j.username||'')+' \u2014 имя и юзернейм можно поменять в настройках'),1600);
    await start(); }
  catch(e){ $('#aErr').textContent='Не удалось войти через Telegram: '+(e.message||e); }
  a.classList.remove('loading'); }
// компьютер (не телефон и не планшет): вход только по QR-коду
const IS_DESKTOP=(()=>{ try{ const ua=navigator.userAgent; if(/Android|iPhone|iPad|iPod|Mobile|Opera Mini|IEMobile|webOS|BlackBerry/i.test(ua)) return false; if(/Macintosh/.test(ua)&&navigator.maxTouchPoints>1) return false; return true; }catch{ return true; } })();
const ICE = [{urls:['stun:stun.l.google.com:19302','stun:stun1.l.google.com:19302']},{urls:'stun:stun.cloudflare.com:3478'}];
let sb = null;
// Библиотека Supabase грузится с нескольких зеркал по очереди \u2014 если одно недоступно (бывает у российских провайдеров), берётся следующее
const SB_SOURCES = [
'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js',
'https://fastly.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js',
'https://gcore.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js',
'https://unpkg.com/@supabase/supabase-js@2/dist/umd/supabase.js',
'esm:https://esm.sh/@supabase/supabase-js@2',
'esm:https://cdn.skypack.dev/@supabase/supabase-js@2'
];
function loadScript(url, ms=9000){ return new Promise((res,rej)=>{ const s=document.createElement('script'); const t=setTimeout(()=>{ s.remove(); rej(new Error('timeout')); },ms);
s.src=url; s.onload=()=>{ clearTimeout(t); res(); }; s.onerror=()=>{ clearTimeout(t); s.remove(); rej(new Error('error')); }; document.head.appendChild(s); }); }
// если на странице оказалась ещё одна (старая) копия Lumo, она получает \u00abпустое\u00bb подключение и ничего не делает:
// иначе обе копии реагируют на одни и те же кнопки (двойные голосовые и т.п.)
const LUMO_OWN={};
function lumoWrapLib(L){ try{ if(!L||!L.createClient||L.__lumoWrapped) return L; const orig=L.createClient;
  const never=new Promise(()=>{}); const dead=new Proxy(function(){},{ get:(t,k)=>k==='then'?never.then.bind(never):(k===Symbol.toPrimitive?()=>'':dead), apply:()=>dead });
  L.createClient=function(url,key,opt){ if(opt&&opt.__own===LUMO_OWN){ const o={...opt}; delete o.__own; return orig.call(this,url,key,o); } console.warn('Lumo: на странице найдена вторая копия приложения \u2014 она отключена'); return dead; };
  L.__lumoWrapped=true; }catch(e){} return L; }
lumoWrapLib(window.supabase);
async function loadSupabase(){
if(window.supabase?.createClient) return lumoWrapLib(window.supabase);
for(const src of SB_SOURCES){
try{
if(src.startsWith('esm:')){ const mod=await Promise.race([import(src.slice(4)), new Promise((_,r)=>setTimeout(()=>r(new Error('timeout')),12000))]); if(mod?.createClient){ const m={...mod}; window.supabase=m; return lumoWrapLib(m); } }
else { await loadScript(src); if(window.supabase?.createClient) return lumoWrapLib(window.supabase); }
}catch(e){ console.warn('Supabase source failed:', src, e.message); }
}
throw new Error('no-lib');
}
const $ = s => document.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
/* ================= ICONS ================= */
const P = {
menu:'<path d="M4 6h16M4 12h16M4 18h16"/>', search:'<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
send:'<path d="M3.7 3.05a.5.5 0 0 0-.68.63l2.84 7.62a2 2 0 0 1 0 1.4l-2.84 7.62a.5.5 0 0 0 .68.63l18-8.5a.5.5 0 0 0 0-.9z"/><path d="M6 12h16"/>',
mic:'<path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v3"/>',
vcirc:'<circle cx="12" cy="12" r="9.5"/><rect x="7" y="9.2" width="6.5" height="5.6" rx="1.2"/><path d="m13.5 12 3.3-2v4z"/>',
clip:'<path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48"/>',
smile:'<circle cx="12" cy="12" r="10"/><path d="M8 14s1.5 2 4 2 4-2 4-2M9 9h.01M15 9h.01"/>',
phone:'<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.8 19.8 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.8 19.8 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"/>',
video:'<path d="m22 8-6 4 6 4V8Z"/><rect x="2" y="6" width="14" height="12" rx="2"/>',
more:'<circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/>',
x:'<path d="M18 6 6 18M6 6l12 12"/>', check:'<path d="M20 6 9 17l-5-5"/>', checks:'<path d="M17 6.5 6.5 17 2 12.5"/><path d="M22 8.5 12.5 18l-1.2-1.2"/>',
reply:'<path d="M9 17l-5-5 5-5"/><path d="M20 18v-2a4 4 0 0 0-4-4H4"/>',
copy:'<rect x="8" y="8" width="14" height="14" rx="2"/><path d="M4 16a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2"/>',
edit:'<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
trash:'<path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>',
pin:'<path d="M12 17v5"/><path d="M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V17h14v-1.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 0-4H8a2 2 0 0 0 0 4 1 1 0 0 1 1 1z"/>',
fwd:'<path d="M15 17l5-5-5-5"/><path d="M4 18v-2a4 4 0 0 1 4-4h12"/>', back:'<path d="M19 12H5M12 19l-7-7 7-7"/>',
users:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
mega:'<path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/>',
bookmark:'<path d="m19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z"/>',
bar:'<path d="M5 21V11M12 21V4M19 21v-7"/>',
list:'<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>',
star:'<path d="m12 2 3.1 6.3 6.9 1-5 4.9 1.2 6.8-6.2-3.3-6.2 3.3L8 14.2 3 9.3l6.9-1z"/>',
moon:'<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>', sun:'<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>',
logout:'<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>', plus:'<path d="M12 5v14M5 12h14"/>',
minus:'<path d="M5 12h14"/>', volx:'<path d="M11 5 6 9H2v6h4l5 4V5z"/><path d="m22 9-6 6"/><path d="m16 9 6 6"/>', expand:'<path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/><path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/>', heart:'<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1.1L12 21l7.8-7.5 1-1.1a5.5 5.5 0 0 0 0-7.8z"/>', flag:'<path d="M5 22V4"/><path d="M5 4h12l-2.5 4.5L17 13H5"/>', chart:'<path d="M4 20V10"/><path d="M10 20V4"/><path d="M16 20v-7"/><path d="M22 20H2"/>', rotate:'<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/>',
play:'<path d="M8 5.14v13.72a1 1 0 0 0 1.5.86l11-6.86a1 1 0 0 0 0-1.72l-11-6.86A1 1 0 0 0 8 5.14z" fill="currentColor"/>',
pause:'<rect x="6" y="4" width="4" height="16" rx="1" fill="currentColor"/><rect x="14" y="4" width="4" height="16" rx="1" fill="currentColor"/>',
image:'<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.09-3.09a2 2 0 0 0-2.82 0L6 21"/>',
file:'<path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><path d="M14 2v6h6"/>',
lock:'<rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
micoff:'<path d="m2 2 20 20M18.89 13.23A7 7 0 0 0 19 12v-2M5 10v2a7 7 0 0 0 12 5M15 9.34V5a3 3 0 0 0-5.68-1.33M9 9v3a3 3 0 0 0 5.12 2.12M12 19v3"/>',
videooff:'<path d="m2 2 20 20"/><path d="M16 16v1a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h2m5.66 0H14a2 2 0 0 1 2 2v3.34l1 1L22 8v8"/>',
flip:'<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/>',
belloff:'<path d="M8.7 3A6 6 0 0 1 18 8a21.3 21.3 0 0 0 .6 5M17 17H3s3-2 3-9a4.67 4.67 0 0 1 .3-1.7M10.3 21a1.94 1.94 0 0 0 3.4 0M2 2l20 20"/>',
bell:'<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
down:'<path d="m6 9 6 6 6-6"/>', up:'<path d="m18 15-6-6-6 6"/>',
userplus:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6M22 11h-6"/>',
info:'<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>',
dl:'<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/>',
user:'<circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 0 0-16 0"/>',
link:'<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
hangup:'<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.8 19.8 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.8 19.8 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z" transform="rotate(135 12 12)"/>',
callin:'<path d="M16 2v6h6M22 2l-6 6"/>'+'<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.8 19.8 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.8 19.8 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"/>',
ban:'<circle cx="12" cy="12" r="10"/><path d="m4.9 4.9 14.2 14.2"/>', shield:'<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
volume:'<path d="M11 5 6 9H2v6h4l5 4V5z"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/>', muteV:'<path d="M11 5 6 9H2v6h4l5 4V5z"/><path d="m22 9-6 6M16 9l6 6"/>',
clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
chat:'<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>',
contact:'<circle cx="12" cy="12" r="10"/><circle cx="12" cy="10" r="3"/><path d="M7 20.66V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.66"/>',
gear:'<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
arrin:'<path d="M17 7 7 17M17 17H7V7"/>', arrout:'<path d="M7 17 17 7M7 7h10v10"/>',
userx:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="m17 8 5 5M22 8l-5 5"/>',
contactF:'<circle cx="12" cy="12" r="10.5" fill="currentColor" stroke="none"/><circle cx="12" cy="9.6" r="3.6" fill="var(--panel)" stroke="none"/><path d="M5.6 18.6c1.3-2.5 3.6-3.7 6.4-3.7s5.1 1.2 6.4 3.7" stroke="var(--panel)" stroke-width="2.2" fill="none"/>',
phoneF:'<path fill="currentColor" stroke="none" d="M6.6 2.5c.7-.2 1.4.1 1.8.7l2 3.2c.4.6.3 1.4-.2 1.9l-1.4 1.4c1.1 2.3 2.9 4.1 5.2 5.2l1.4-1.4c.5-.5 1.3-.6 1.9-.2l3.2 2c.6.4.9 1.1.7 1.8l-.6 2.3c-.3 1-1.2 1.7-2.3 1.6C10.2 20.4 3.6 13.8 3 5.7c-.1-1.1.6-2 1.6-2.3z"/>',
chatsF:'<path fill="currentColor" stroke="none" d="M10 3.5c-4.7 0-8.5 3.1-8.5 7 0 2 1 3.8 2.6 5.1-.2 1.2-.8 2.3-1.7 3.1 1.9.1 3.7-.5 5.1-1.5.8.2 1.6.3 2.5.3 4.7 0 8.5-3.1 8.5-7s-3.8-7-8.5-7z"/><path fill="currentColor" stroke="none" opacity=".55" d="M20.2 9.3c.2.6.3 1.3.3 2 0 4.6-4.3 8.3-9.7 8.5 1.3 1.1 3.1 1.7 5.2 1.7.7 0 1.4-.1 2-.2 1.1.8 2.5 1.2 4 1.2-.7-.6-1.1-1.5-1.3-2.4 1.3-1 2.1-2.4 2.1-4 0-2.6-1.1-5-2.6-6.8z"/>',
chatF:'<path fill="currentColor" stroke="none" d="M5.5 3.5h13a3 3 0 0 1 3 3v8a3 3 0 0 1-3 3h-7.6l-4.3 3.5c-.65.53-1.6.07-1.6-.77V17.5a3 3 0 0 1-2.5-3v-8a3 3 0 0 1 3-3z"/><path d="M7.8 9h8.4M7.8 12.6h5.4" stroke="var(--panel)" stroke-width="2.1"/>',
palette:'<circle cx="13.5" cy="6.5" r="1.2"/><circle cx="17.5" cy="10.5" r="1.2"/><circle cx="8.5" cy="7.5" r="1.2"/><circle cx="6.5" cy="12.5" r="1.2"/><path d="M12 2a10 10 0 0 0 0 20c1.1 0 2-.9 2-2 0-.5-.2-1-.5-1.3-.3-.4-.5-.8-.5-1.3 0-1.1.9-2 2-2h2.4A5.6 5.6 0 0 0 22 9.8C22 5.5 17.5 2 12 2z"/>',
laptop:'<rect x="4" y="5" width="16" height="11" rx="2"/><path d="M2 19h20"/>',
db:'<ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v6c0 1.7 3.6 3 8 3s8-1.3 8-3V5M4 11v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6"/>',
camera:'<path d="M4 8h3l2-3h6l2 3h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13" r="3.5"/>',
key:'<circle cx="8" cy="15" r="4"/><path d="m10.8 12.2 8.7-8.7M16 7l3 3M14 9l2 2"/>',
eye:'<path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
textA:'<path d="M3 19 8.5 5h1L15 19M5.2 14h7.6M15.5 19l3-7.5 3 7.5M16.6 16.5h3.8"/>',
phoneX:'<path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 1.9.7 2.8a2 2 0 0 1-.5 2.1L8 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2zM16 3l5 5M21 3l-5 5"/>',
speaker:'<path d="M11 5 6 9H2v6h4l5 4V5z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.6 5.4a9.4 9.4 0 0 1 0 13.2"/>',
qr:'<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><path d="M14 14h3v3h-3zM20.5 14v.01M14 20.5h.01M17.5 20.5H21v-3.5"/>',
laptop:'<rect x="4" y="4" width="16" height="11" rx="2"/><path d="M2 19h20"/>',
cake:'<path d="M20 21v-8a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8"/><path d="M4 16s.5-1 2-1 2.5 2 4 2 2.5-2 4-2 2.5 2 4 2 2-1 2-1"/><path d="M2 21h20M7 8v3M12 8v3M17 8v3M7 4h.01M12 4h.01M17 4h.01"/>',
at:'<circle cx="12" cy="12" r="4"/><path d="M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-4 8"/>',
megaphone:'<path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/>',
brush:'<path d="m9.06 11.9 8.07-8.06a2.85 2.85 0 1 1 4.03 4.03l-8.06 8.08"/><path d="M7.07 14.94c-1.66 0-3 1.35-3 3.02 0 1.33-2.5 1.52-2 2.02 1.08 1.1 2.49 2.02 4 2.02 2.2 0 4-1.8 4-4.04a3.01 3.01 0 0 0-3-3.02z"/>',
palette:'<circle cx="13.5" cy="6.5" r="1"/><circle cx="17.5" cy="10.5" r="1"/><circle cx="8.5" cy="7.5" r="1"/><circle cx="6.5" cy="12.5" r="1"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.93 0 1.65-.75 1.65-1.69 0-.44-.18-.84-.44-1.13-.29-.29-.44-.65-.44-1.13a1.64 1.64 0 0 1 1.67-1.67h2c3.05 0 5.55-2.5 5.55-5.55C21.97 6.01 17.46 2 12 2z"/>'
};
const ic = (n, cls='') => `<svg class="i ${cls}" viewBox="0 0 24 24">${P[n]||''}</svg>`;
function paintIcons(root=document){ root.querySelectorAll('[data-i]').forEach(e=>{e.innerHTML=ic(e.dataset.i);}); }
/* ================= STATE ================= */
// профили: если вы дали человеку своё имя \u2014 показываем его (видите только вы)
class PMap extends Map{ set(k,v){ if(v&&typeof S!=='undefined'&&S.alias&&k!==S.me?.id){ const real=(v.__al!==undefined&&v.name===v.__al&&v.__real!=null)?v.__real:v.name; const a=S.alias.get(k)||null; v={...v,__real:real,__al:a||undefined,name:a||real}; } return super.set(k,v); } }
const S = {
alias:new Map(), blocks:{mine:new Set(),me:new Set()}, cleared:new Map(),
tab:'chats', contacts:[], calls:[], callsLoaded:false,
me:null, chats:[], chatMap:new Map(), cur:null, msgs:new Map(), more:new Map(), members:new Map(), profiles:new PMap(),
reacts:new Map(), hidden:new Set(), online:new Set(), typing:new Map(), reply:null, edit:null, folder:'all', q:'', mode:'mic',
unreadBelow:0, inSearch:{res:[],i:0}
};
const cur = () => S.chatMap.get(S.cur);
const COLORS = 8;
/* ================= HELPERS ================= */
function toast(t, ms=2600){ $('#toast')?.remove(); const d=document.createElement('div'); d.id='toast'; d.textContent=t; document.body.appendChild(d); setTimeout(()=>d.remove(), ms); }
function initials(n){ const p=String(n||'?').trim().split(/\s+/).filter(Boolean); if(!p.length) return '?'; const a=[...p[0]]; return ((p[1]?a[0]+[...p[1]][0]:a.slice(0,2).join(''))||'?').toUpperCase(); }
function avatar(o, size='', online=false){
const st = o.avatar ? ` style="background-image:url('${esc(o.avatar)}');background-size:cover;background-position:center;background-repeat:no-repeat"` : '';
const inner = o.icon ? ic(o.icon) : (o.avatar ? '' : esc(initials(o.name)));
return `<div class="av ${size} c${(o.color??0)%COLORS}"${st}>${inner}${online?'<span class="on"></span>':''}</div>`;
}
const pad = n => String(n).padStart(2,'0');
const fmtT = d => { d=new Date(d); return pad(d.getHours())+':'+pad(d.getMinutes()); };
const fmtDur = s => { s=Math.max(0,Math.round(s||0)); return Math.floor(s/60)+':'+pad(s%60); };
function sameDay(a,b){ a=new Date(a); b=new Date(b); return a.toDateString()===b.toDateString(); }
function fmtDay(d){ d=new Date(d); const n=new Date(); if(sameDay(d,n)) return 'Сегодня'; const y=new Date(); y.setDate(n.getDate()-1); if(sameDay(d,y)) return 'Вчера';
return d.toLocaleDateString('ru-RU',{day:'numeric',month:'long',...(d.getFullYear()!==n.getFullYear()?{year:'numeric'}:{})}); }
function fmtListTime(d){ d=new Date(d); const n=new Date(); if(sameDay(d,n)) return fmtT(d); const diff=(n-d)/864e5;
if(diff<6) return d.toLocaleDateString('ru-RU',{weekday:'short'}); return d.toLocaleDateString('ru-RU',{day:'2-digit',month:'2-digit',...(d.getFullYear()!==n.getFullYear()?{year:'2-digit'}:{})}); }
function lastSeen(p){
if(!p) return '';
if(p.show_seen===false&&p.id!==S.me?.id) return 'был(а) недавно';
if(S.online.has(p.id)) return 'в сети';
if(!p.last_seen) return 'был(а) недавно';
const d=new Date(p.last_seen), m=(Date.now()-d)/6e4;
if(m<1.5) return 'был(а) только что';
if(m<60) return `был(а) ${Math.round(m)} мин. назад`;
if(sameDay(d,new Date())) return 'был(а) сегодня в '+fmtT(d);
return 'был(а) '+fmtDay(d).toLowerCase()+' в '+fmtT(d);
}
function fmtSize(b){ if(!b) return ''; const u=['Б','КБ','МБ','ГБ']; let i=0; while(b>=1024&&i<3){b/=1024;i++;} return b.toFixed(i?1:0)+' '+u[i]; }
function plural(n,a,b,c){ n=Math.abs(n)%100; const n1=n%10; if(n>10&&n<20) return c; if(n1>1&&n1<5) return b; if(n1===1) return a; return c; }
function richText(t,cmd){
let s = esc(t);
const L=[]; s=s.replace(/\[([^\]\n]+)\]\(((?:https?:\/\/|date:|mailto:|tel:)[^)\s]+)\)/g,(m,a,u)=>{ let h; if(u.startsWith('date:')){ const d=new Date(+u.slice(5)*1000); const f=isNaN(d)?'':d.toLocaleString('ru-RU',{dateStyle:'full',timeStyle:'short'}); h=`<span class="mdate" data-date="${f}" title="${f}">${a}</span>`; } else h=`<a href="${u}" target="_blank" rel="noopener">${a}</a>`; L.push(h); return '\u0001'+(L.length-1)+'\u0002'; });
s=s.replace(/\|\|([^|\n]+)\|\|/g,'<span class="spl">$1</span>');
s=s.replace(/(^|\n)((?:&gt; [^\n]*(?:\n|$))+)/g,(m,p,b)=>p+'<span class="mq">'+b.replace(/\n$/,'').replace(/(^|\n)&gt; /g,'$1')+'</span>');
s = s.replace(/```([\s\S]+?)```/g,'<code>$1</code>').replace(/`([^`\n]+)`/g,'<code>$1</code>')
.replace(/\*\*([^*\n]+)\*\*/g,'<b>$1</b>').replace(/__([^_\n]+)__/g,'<i>$1</i>').replace(/~~([^~\n]+)~~/g,'<s>$1</s>')
.replace(/(https?:\/\/[^\s<]+[^\s<.,:;"')\]])/g,'<a href="$1" target="_blank" rel="noopener">$1</a>')
.replace(/(^|\s)@([a-z0-9_]{3,32})/gi,'$1<a href="#" data-mention="$2">@$2</a>');
if(cmd) s=s.replace(/(^|\s)(\/[a-zA-Z_][a-zA-Z0-9_]{0,31})(@[a-z0-9_]+)?(?=\s|$|[.,!?])/g,'$1<a href="#" data-cmd="$2">$2$3</a>');
s=s.replace(/\u0001(\d+)\u0002/g,(m,i)=>L[+i]||'');
return s;
}
if(!window.__lmFmt){ window.__lmFmt=1; const st=document.createElement('style'); st.textContent='.spl{background:currentColor;border-radius:4px;cursor:pointer;transition:background .2s}.spl.on{background:rgba(127,127,127,.22)}.mdate{text-decoration:underline dotted;cursor:pointer}.mq{display:block;border-left:3px solid var(--a1,#7c5cff);background:rgba(124,92,255,.12);border-radius:6px;padding:4px 8px;margin:2px 0}'; document.head.appendChild(st); document.addEventListener('click',e=>{ const x=e.target.closest&&e.target.closest('.spl,.mdate'); if(!x) return; if(x.classList.contains('spl')){ if(!x.classList.contains('on')){ x.classList.add('on'); e.preventDefault(); e.stopPropagation(); } } else if(x.dataset.date){ toast(x.dataset.date); e.stopPropagation(); } },true); }
function isOnlyEmoji(t){ if(!t) return false; const s=t.trim(); if([...s].length>6) return false; return /^(\p{Extended_Pictographic}|\p{Emoji_Component}|\u200d|\ufe0f|\s)+$/u.test(s) && /\p{Extended_Pictographic}/u.test(s); }
function chatName(c){ if(!c) return ''; if(c.type==='private') return c.peer_id===S.me.id ? 'Избранное' : (S.alias.get(c.peer_id)||c.peer_name||'Пользователь'); return c.title||'Чат'; }
function chatAv(c,size){ if(c.type==='private'){ if(c.peer_id===S.me.id) return avatar({icon:'bookmark',color:2},size);
return avatar({name:c.peer_name,avatar:c.peer_avatar,color:c.peer_color},size,S.online.has(c.peer_id)); }
return avatar({name:c.title,avatar:c.avatar_url,color:c.color},size); }
function kindLabel(k,body){ return ({voice:[ 'mic','Голосовое сообщение'],video_note:['vcirc','Видеосообщение'],image:['image','Фото'],video:['video','Видео'],file:['file','Файл'],sticker:['smile',(body&&!/^(art|img):/.test(body)?body+' ':'')+'Стикер'],call:['phone','Звонок']})[k]; }
function previewOf(m){ if(!m) return ''; if(m.deleted) return 'Сообщение удалено'; const kl=kindLabel(m.kind,m.body);
if(kl) return ic(kl[0])+esc(m.kind!=='sticker'&&m.body&&m.kind!=='call'?plain(m.body):kl[1]); return esc(plain(m.body)); }
function plain(t){ return String(t||'').replace(/\|\|[^|\n]+\|\|/g,'▒▒▒▒').replace(/\[([^\]\n]+)\]\([^)\s]+\)/g,'$1').replace(/(^|\n)> /g,'$1').replace(/```|`|\*\*|__|~~/g,''); }
function profName(id){ return S.profiles.get(id)?.name || 'Пользователь'; }
function uid8(){ return (crypto.randomUUID?crypto.randomUUID():Math.random().toString(36).slice(2)+Date.now()); }
/* ================= AUTH ================= */
let regMode=false;
$('#tLogin').onclick=()=>setMode(false); $('#tReg').onclick=()=>setMode(true);
function setMode(r){ regMode=r; $('#tLogin').classList.toggle('on',!r); $('#tReg').classList.toggle('on',r); $('#fName').classList.toggle('collapse',!r); document.querySelector('.authcard .tabs')?.classList.toggle('reg',r); $('#aBtn').textContent=r?'Создать аккаунт':'Войти'; if($('#tgLoginTx')) $('#tgLoginTx').textContent=r?'Регистрация через Telegram':'Войти через Telegram'; $('#aErr').textContent=''; $('#aPass').autocomplete=r?'new-password':'current-password'; }
async function doAuth(e){
e&&e.preventDefault&&e.preventDefault(); if(!sb){ $('#aErr').textContent='Подождите, приложение ещё загружается\u2026'; return; } const u=$('#aUser').value.trim().toLowerCase().replace(/^@/,''), p=$('#aPass').value, n=$('#aName').value.trim();
$('#aErr').textContent=''; $('#aBtn').disabled=true; $('#aBtn').classList.add('loading');
try{
if(!/^[a-z0-9_]{3,32}$/.test(u)) throw new Error('Юзернейм: 3\u201332 символа, латиница, цифры и _');
if(regMode){ const {error}=await sb.rpc('lm_register',{p_username:u,p_password:p,p_name:n}); if(error) throw new Error(error.message); }
const {error}=await sb.auth.signInWithPassword({email:u+EMAIL_DOMAIN,password:p});
if(error) throw new Error(error.message.includes('Invalid')?'Неверный юзернейм или пароль':error.message);
await start();
}catch(err){ $('#aErr').textContent=err.message; const c=document.querySelector('.authcard'); c.classList.remove('shake'); void c.offsetWidth; c.classList.add('shake'); try{ navigator.vibrate?.([30,40,30]); }catch{} }
$('#aBtn').disabled=false; $('#aBtn').classList.remove('loading');
}
$('#aBtn').addEventListener('click',e=>{ if(!$('#aBtn').dataset.reload) doAuth(e); });
/* вход и регистрация через Telegram-бота: бот создаёт аккаунт (или находит ваш) и пускает в Lumo */
const TGL={k:null,poll:null,bot:null,n:0,busy:false};
async function tgPrep(){ const a=$('#tgLogin'); if(!a) return;
  if(TGA.on){ a.href='#'; a.removeAttribute('target'); a.classList.remove('dis','hidden'); document.querySelector('.tgor')?.classList.remove('hidden'); $('#tgLoginTx').textContent='Создать аккаунт через Telegram'; return; }
  if(IS_DESKTOP){ a.classList.add('hidden'); document.querySelector('.tgor')?.classList.add('hidden'); return; }
  try{ if(!TGL.bot){ const j=await (await fetch(FN+'/config')).json(); TGL.bot=j.bot||null; } }catch{}
  if(!TGL.bot){ a.classList.add('dis'); return; }
  let saved=null; try{ saved=JSON.parse(localStorage.getItem('lm_tgk')||'null'); }catch{}
  if(saved&&saved.k&&Date.now()-saved.t<10*60e3){ TGL.k=saved.k; tgPollStart(); } else if(!TGL.k) TGL.k=rndKey();
  a.href=`https://t.me/${TGL.bot}?start=l_${TGL.k}`; a.classList.remove('dis'); }
$('#tgLogin').addEventListener('click',e=>{ if(TGA.on){ e.preventDefault(); tgAppCreate(); return; } if(!TGL.bot||!TGL.k){ e.preventDefault(); return; } try{ localStorage.setItem('lm_tgk',JSON.stringify({k:TGL.k,t:Date.now()})); }catch{} tgPollStart(); });
function tgPollStart(){ $('#tgWait').classList.remove('hidden'); clearInterval(TGL.poll); TGL.n=0; TGL.poll=setInterval(tgCheck,2000); setTimeout(tgCheck,800); }
function tgPollStop(){ clearInterval(TGL.poll); TGL.poll=null; $('#tgWait').classList.add('hidden'); }
async function tgCheck(){ if(!TGL.k||TGL.busy||!sb) return; if(++TGL.n>300){ tgPollStop(); return; } TGL.busy=true;
  try{ const r=await fetch(FN+'/tglogin',{method:'POST',headers:{'Content-Type':'text/plain'},body:JSON.stringify({key:TGL.k})}); const j=await r.json();
    if(j.th){ tgPollStop(); try{ localStorage.removeItem('lm_tgk'); }catch{} TGL.k=null;
      const {error}=await sb.auth.verifyOtp({token_hash:j.th,type:'magiclink'}); if(error) throw error;
      if(j.new) setTimeout(()=>toast('Аккаунт создан: @'+(j.username||'')+' \u2014 имя и юзернейм можно поменять в настройках'),1600);
      await start(); }
    else if(j.error==='expired'){ tgPollStop(); try{ localStorage.removeItem('lm_tgk'); }catch{} TGL.k=rndKey(); tgPrep(); }
  }catch(e){ console.warn(e); if(!TGL.poll){ $('#aErr').textContent='Не удалось войти через Telegram: '+(e.message||e); TGL.k=rndKey(); tgPrep(); } }
  TGL.busy=false; }
document.addEventListener('visibilitychange',()=>{ if(!document.hidden&&TGL.poll) tgCheck(); });
$('#authForm').addEventListener('keydown',e=>{ if(e.key==='Enter'){ e.preventDefault(); e.stopPropagation(); doAuth(e); } });
async function boot(){
applyTheme(); paintIcons(); tgAppSetup();
$('#toQr').classList.add('hidden');
// на компьютере вход только по QR-коду: форму пароля не показываем вообще
if(IS_DESKTOP){ $('#passView').classList.add('hidden'); $('#qrView').classList.remove('hidden'); $('#qrToPass').classList.add('hidden'); $('#qrNote').classList.remove('hidden'); }
try{ const lib=await loadSupabase(); await pickRoute(); sb=lib.createClient(SUPABASE_URL, SUPABASE_KEY, {auth:{persistSession:true,autoRefreshToken:true,storageKey:'sb-foniukmpiukuwpcdvdhp-auth-token'},__own:LUMO_OWN}); }
catch(e){ const msg='Не удалось загрузить приложение: интернет-провайдер блокирует нужные серверы. Попробуйте другую сеть (мобильный интернет / Wi-Fi) или VPN и обновите страницу.';
  $('#aErr').innerHTML=msg; $('#qrSt').textContent=msg; $('#qrImg').innerHTML='<div style="color:#555;font-size:13px;text-align:center">Нет связи</div>';
  $('#aBtn').textContent='Обновить'; $('#aBtn').dataset.reload='1'; $('#aBtn').onclick=()=>location.reload(); showAuth(); return; }
setMode(regMode);
const {data:{session}} = await sb.auth.getSession();
if(TGA.on){ try{ if(await tgAppLogin(session)) return; }catch(e){ console.warn('tgapp',e); } }
if(session) { try{ await start(); return; }catch(e){ console.error(e); } }
if(IS_DESKTOP) showQrLogin();
showAuth(); tgPrep();
}
function hideSplash(){ const s=$('#splash'); if(!s||s.classList.contains('out')) return; s.classList.add('out'); setTimeout(()=>s.remove(),700); }
function showAuth(){ hideSplash(); const a=$('#auth'); a.classList.remove('hidden','leaving'); }
function leaveAuth(){ const a=$('#auth'); if(a.classList.contains('hidden')) return; a.classList.add('leaving'); setTimeout(()=>{ a.classList.add('hidden'); a.classList.remove('leaving'); },560); }
function showApp(){ hideSplash(); const ap=$('#app'); const was=ap.classList.contains('hidden'); ap.classList.remove('hidden'); if(was){ ap.classList.add('appin'); setTimeout(()=>ap.classList.remove('appin'),1400); } requestAnimationFrame(()=>{ moveTabInd(); moveFolderInd(); }); }
// плавные индикаторы и появление элементов
function moveTabInd(){ const b=document.querySelector('#tabs button.on'), i=document.querySelector('#tabs .tind'); if(!b||!i||!b.offsetWidth) return; i.style.width=b.offsetWidth+'px'; i.style.transform=`translateX(${b.offsetLeft}px)`; }
function moveFolderInd(){ const b=document.querySelector('#folders button.on'), i=document.querySelector('#folders .find'); if(!b||!i||!b.offsetWidth) return; i.style.width=Math.max(18,b.offsetWidth-28)+'px'; i.style.transform=`translateX(${b.offsetLeft+14}px)`; }
function stagger(el,max=14){ if(!el) return; [...el.children].slice(0,max).forEach((c,i)=>{ if(c.classList.contains('find')) return; c.classList.remove('stg'); void c.offsetWidth; c.style.animationDelay=(i*38)+'ms'; c.classList.add('stg'); }); }
window.addEventListener('resize',()=>{ moveTabInd(); moveFolderInd(); });
async function start(){
const {data:{user}} = await sb.auth.getUser();
const {data:me,error} = await sb.from('lm_profiles').select('*').eq('id',user.id).maybeSingle();
if(error||!me){ await sb.auth.signOut({scope:'local'}); throw new Error('Профиль не найден'); }
S.me=me; S.profiles.set(me.id,me);
try{ const [mp]=await profGet([me.id]); if(mp) S.me=mp; }catch{}
try{ webSession(); setTimeout(webPhoneGate,1500); }catch{}
if(me.banned){ leaveAuth(); hideSplash(); return showBanned(me); }
sb.rpc('lm_staff_role').then(({data})=>{ S.staff=data||null; if(S.staff&&$('#sAbout')) renderSettings(); },()=>{});
leaveAuth(); showApp(); banWatch(); lockShow();
setupStatic(); if(!S.chats||!S.chats.length) $('#list').innerHTML=skelHtml(); await loadChats(); stagger($('#list')); requestAnimationFrame(()=>{ moveFolderInd(); moveTabInd(); }); setupRealtime(); setupCallChannel(); loadCalls(); loadContacts(); loadTg(); loadCfg(); loadBlocks(); loadStories(); setInterval(()=>{ if(!document.hidden) loadStories(); },60000); getIce();
touchNow(); setInterval(()=>{ if(!document.hidden) touchNow(); },45000);
const h=location.hash.match(/^#@([a-z0-9_]+)/i); if(h) openByUsername(h[1]);
const hc=location.hash.match(/^#c=([\w-]+)/); if(hc){ try{ history.replaceState(null,'',location.href.split('#')[0]); }catch{} openChat(hc[1]); }
try{ navigator.serviceWorker?.addEventListener('message',e=>{ const c=e.data&&e.data.lumoOpen; if(c&&S.me){ setTab?.('chats'); openChat(c); } }); }catch{}
if(TGA.on&&TGA.nolink){ TGA.nolink=false; tgApp({link:true},true).then(j=>{ if(j&&j.ok){ toast('Telegram привязан \u2014 дальше вход будет автоматическим'); loadTg(); } }).catch(()=>{}); }
if(TGA.chat){ const c=TGA.chat; TGA.chat=''; setTab?.('chats'); openChat(c); }
qrStop(); const qk=qrFromText(location.hash); if(qk){ try{ history.replaceState(null,'',location.href.split('#')[0]); }catch{} setTimeout(()=>qrApprove(qk),400); }
}
/* ================= СКВОЗНОЕ ШИФРОВАНИЕ ЛИЧНЫХ ЧАТОВ ================= */
// Ключевая пара P-256 создаётся в браузере; открытая часть лежит на сервере (lm_keys), закрытая \u2014 здесь и в резервной копии под паролем (lm_key_backup).
// Ключ чата = HKDF-SHA256(ECDH, соль = id чата, info = "lumo-e2e-v1"); сообщение = "e2e1:" + base64(iv12 \u2016 шифртекст+тег), AES-256-GCM.
const E2E=(()=>{
const PFX='e2e1:', LOCK='\u{1f512} Не удалось расшифровать', te=new TextEncoder(), td=new TextDecoder();
const b64=u=>{ u=new Uint8Array(u); let s=''; for(let i=0;i<u.length;i+=8192) s+=String.fromCharCode.apply(null,u.subarray(i,i+8192)); return btoa(s); };
const ub64=s=>{ const b=atob(s), u=new Uint8Array(b.length); for(let i=0;i<b.length;i++) u[i]=b.charCodeAt(i); return u; };
const b64u=u=>b64(u).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
const ub64u=s=>{ s=s.replace(/-/g,'+').replace(/_/g,'/'); while(s.length%4) s+='='; return ub64(s); };
const st={status:'loading',backedUp:true,busy:false};
let me=null, mine=null, priv=null, setupP=null, setupFor=null;
const peers=new Map(), noKey=new Map(), keys=new Map(), changed=new Set();
const is=b=>typeof b==='string'&&b.startsWith(PFX);
const ECP={name:'ECDH',namedCurve:'P-256'};
// хранилище ключа на этом устройстве
function idb(){ return new Promise((res,rej)=>{ const r=indexedDB.open('lumo-e2e',1); r.onupgradeneeded=()=>r.result.createObjectStore('k'); r.onsuccess=()=>res(r.result); r.onerror=()=>rej(r.error); }); }
async function kvGet(k){ try{ const db=await idb(); return await new Promise((res,rej)=>{ const q=db.transaction('k').objectStore('k').get(k); q.onsuccess=()=>res(q.result||null); q.onerror=()=>rej(q.error); }); }catch{ try{ return JSON.parse(localStorage.getItem('lm_e2e_'+k)||'null'); }catch{ return null; } } }
async function kvSet(k,v){ try{ const db=await idb(); await new Promise((res,rej)=>{ const t=db.transaction('k','readwrite'); t.objectStore('k').put(v,k); t.oncomplete=res; t.onerror=()=>rej(t.error); }); }catch{ try{ localStorage.setItem('lm_e2e_'+k,JSON.stringify(v)); }catch{} } }
async function kvDel(k){ try{ const db=await idb(); await new Promise((res,rej)=>{ const t=db.transaction('k','readwrite'); t.objectStore('k').delete(k); t.oncomplete=res; t.onerror=()=>rej(t.error); }); }catch{} try{ localStorage.removeItem('lm_e2e_'+k); }catch{} }
async function gen(){ const kp=await crypto.subtle.generateKey(ECP,true,['deriveBits']); const jwk=await crypto.subtle.exportKey('jwk',kp.privateKey); return {d:ub64u(jwk.d),pub:new Uint8Array(await crypto.subtle.exportKey('raw',kp.publicKey))}; }
async function install(uid,d,pub){ const jwk={kty:'EC',crv:'P-256',x:b64u(pub.slice(1,33)),y:b64u(pub.slice(33,65)),d:b64u(d)};
  priv=await crypto.subtle.importKey('jwk',jwk,ECP,false,['deriveBits']); me=uid; mine={d,pub}; keys.clear(); peers.clear(); noKey.clear(); st.status='ready'; }
const publish=async(uid,pubB64)=>{ const {error}=await sb.from('lm_keys').upsert({user_id:uid,pub:pubB64},{onConflict:'user_id'}); if(error) throw error; };
async function setup(uid){
  const {data:sr,error}=await sb.from('lm_keys').select('pub').eq('user_id',uid).maybeSingle(); if(error) throw error;
  const srv=sr?.pub||null, loc=await kvGet('key_'+uid);
  if(loc&&(!srv||srv===loc.pub)){ await install(uid,ub64(loc.d),ub64(loc.pub)); if(!srv) await publish(uid,loc.pub);
    const {data:b}=await sb.from('lm_key_backup').select('iters').eq('user_id',uid).maybeSingle(); st.backedUp=!!b;
    if(!b||b.iters!==0) autoBackup(); return; }
  if(loc) await kvDel('key_'+uid);
  if(srv){ if(await autoRestore(uid,srv)) return; me=uid; priv=null; mine=null; st.status='restore'; setTimeout(restoreDlg,500); return; }
  const g=await gen(); await publish(uid,b64(g.pub)); await kvSet('key_'+uid,{d:b64(g.d),pub:b64(g.pub)}); await install(uid,g.d,g.pub); st.backedUp=false; autoBackup();
}
function ready(){ if(!S.me) return Promise.resolve(); if(setupFor!==S.me.id){ setupFor=S.me.id; setupP=setup(S.me.id).catch(e=>{ console.error('e2e',e); setupFor=null; }); } return setupP; }
// пароль резервной копии
async function pbk(pw,salt,iters){ const base=await crypto.subtle.importKey('raw',te.encode(pw),'PBKDF2',false,['deriveKey']);
  return crypto.subtle.deriveKey({name:'PBKDF2',salt,iterations:iters,hash:'SHA-256'},base,{name:'AES-GCM',length:256},false,['encrypt','decrypt']); }
/* копия ключа без пароля: шифруется ключом обёртки владельца (lm_wrap_key), формат как на iOS/Android: iters=0, blob=iv12‖шифртекст‖тег */
async function wrapK(){ const {data,error}=await sb.rpc('lm_wrap_key'); if(error||!data) return null; const raw=ub64(String(data)); if(raw.length!==32) return null; return crypto.subtle.importKey('raw',raw,'AES-GCM',false,['encrypt','decrypt']); }
async function autoBackup(){ try{ if(!mine||!me) return false; const k=await wrapK(); if(!k) return false; const iv=crypto.getRandomValues(new Uint8Array(12)); const plain=new Uint8Array(97); plain.set(mine.d,0); plain.set(mine.pub,32);
  const ct=new Uint8Array(await crypto.subtle.encrypt({name:'AES-GCM',iv},k,plain)); const blob=new Uint8Array(12+ct.length); blob.set(iv); blob.set(ct,12);
  const {error}=await sb.from('lm_key_backup').upsert({user_id:me,salt:'',iters:0,blob:b64(blob),updated_at:new Date().toISOString()},{onConflict:'user_id'}); if(error) throw error; st.backedUp=true; return true; }catch(e){ console.warn('e2e autobackup',e); return false; } }
async function autoRestore(uid,srv){ try{ const {data:row}=await sb.from('lm_key_backup').select('iters,blob').eq('user_id',uid).maybeSingle(); if(!row||row.iters!==0) return false; const k=await wrapK(); if(!k) return false;
  const blob=ub64(row.blob); const plain=new Uint8Array(await crypto.subtle.decrypt({name:'AES-GCM',iv:blob.slice(0,12)},k,blob.slice(12))); if(plain.length!==97) return false;
  const d=plain.slice(0,32), pub=plain.slice(32); if(b64(pub)!==srv) return false; await kvSet('key_'+uid,{d:b64(d),pub:b64(pub)}); await install(uid,d,pub); st.backedUp=true; return true; }catch(e){ console.warn('e2e autorestore',e); return false; } }
async function createBackup(pw){ if(!mine) return false; st.busy=true; try{ const salt=crypto.getRandomValues(new Uint8Array(16)), iv=crypto.getRandomValues(new Uint8Array(12)), iters=310000;
  const plain=new Uint8Array(97); plain.set(mine.d,0); plain.set(mine.pub,32);
  const ct=new Uint8Array(await crypto.subtle.encrypt({name:'AES-GCM',iv},await pbk(pw,salt,iters),plain)); const blob=new Uint8Array(12+ct.length); blob.set(iv); blob.set(ct,12);
  const {error}=await sb.from('lm_key_backup').upsert({user_id:me,salt:b64(salt),iters,blob:b64(blob),updated_at:new Date().toISOString()},{onConflict:'user_id'}); if(error) throw error;
  st.backedUp=true; return true; }catch(e){ console.error(e); return false; }finally{ st.busy=false; } }
async function restore(pw){ st.busy=true; try{ const uid=S.me.id; const {data:row}=await sb.from('lm_key_backup').select('salt,iters,blob').eq('user_id',uid).maybeSingle(); if(!row) return false;
  const blob=ub64(row.blob); let plain; try{ plain=new Uint8Array(await crypto.subtle.decrypt({name:'AES-GCM',iv:blob.slice(0,12)},await pbk(pw,ub64(row.salt),row.iters||310000),blob.slice(12))); }catch{ return false; }
  if(plain.length!==97) return false; const d=plain.slice(0,32), pub=plain.slice(32);
  const {data:sr}=await sb.from('lm_keys').select('pub').eq('user_id',uid).maybeSingle(); if(sr&&sr.pub!==b64(pub)) return false;
  await kvSet('key_'+uid,{d:b64(d),pub:b64(pub)}); await install(uid,d,pub); st.backedUp=true; autoBackup(); return true; }catch(e){ console.error(e); return false; }finally{ st.busy=false; } }
async function reset(){ st.busy=true; try{ const uid=S.me.id; await sb.from('lm_key_backup').delete().eq('user_id',uid); const g=await gen(); await publish(uid,b64(g.pub)); await kvSet('key_'+uid,{d:b64(g.d),pub:b64(g.pub)}); await install(uid,g.d,g.pub); st.backedUp=false; await autoBackup(); return true; }catch(e){ console.error(e); return false; }finally{ st.busy=false; } }
// ключи собеседников и чатов
function accept(uid,s){ let raw; try{ raw=ub64(s); }catch{ return null; } if(raw.length!==65) return null; noKey.delete(uid);
  try{ const k='lm_e2e_pin_'+uid, pin=localStorage.getItem(k); if(pin==null) localStorage.setItem(k,s); else if(pin!==s) changed.add(uid); }catch{}
  peers.set(uid,raw); return raw; }
async function peerPub(uid){ if(uid===me) return mine?.pub; if(peers.has(uid)) return peers.get(uid); const t=noKey.get(uid); if(t&&Date.now()-t<60000) return null;
  const {data}=await sb.from('lm_keys').select('pub').eq('user_id',uid).maybeSingle(); if(!data?.pub){ noKey.set(uid,Date.now()); return null; } return accept(uid,data.pub); }
async function prefetch(ids){ const now=Date.now(); const need=[...new Set(ids)].filter(u=>u&&u!==me&&!peers.has(u)&&!(noKey.get(u)&&now-noKey.get(u)<60000)); if(!need.length) return;
  const {data}=await sb.from('lm_keys').select('user_id,pub').in('user_id',need); const got=new Set(); (data||[]).forEach(r=>{ if(accept(r.user_id,r.pub)) got.add(r.user_id); }); need.forEach(u=>{ if(!got.has(u)) noKey.set(u,now); }); }
async function prepFor(cid,peer){ if(st.status!=='ready'||!priv||keys.has(cid)) return; const pk=await peerPub(peer||me); if(!pk) return;
  const pubKey=await crypto.subtle.importKey('raw',pk,ECP,false,[]); const bits=await crypto.subtle.deriveBits({name:'ECDH',public:pubKey},priv,256);
  const hk=await crypto.subtle.importKey('raw',bits,'HKDF',false,['deriveKey']);
  keys.set(cid,await crypto.subtle.deriveKey({name:'HKDF',hash:'SHA-256',salt:te.encode(String(cid).toLowerCase()),info:te.encode('lumo-e2e-v1')},hk,{name:'AES-GCM',length:256},false,['encrypt','decrypt']));
  try{ if(S.cur===cid) renderHead(); }catch{} }
async function prepChat(cid){ if(keys.has(cid)) return; const c=S.chatMap&&S.chatMap.get(cid); if(!c||c.type!=='private') return; await prepFor(cid,c.peer_id); }
async function enc(cid,text){ const k=keys.get(cid); if(!k) return null; const iv=crypto.getRandomValues(new Uint8Array(12));
  const ct=new Uint8Array(await crypto.subtle.encrypt({name:'AES-GCM',iv},k,te.encode(text))); const o=new Uint8Array(12+ct.length); o.set(iv); o.set(ct,12); return PFX+b64(o); }
async function decOnce(cid,body){ const k=keys.get(cid); if(!k) throw 0; const raw=ub64(body.slice(PFX.length)); return td.decode(await crypto.subtle.decrypt({name:'AES-GCM',iv:raw.slice(0,12)},k,raw.slice(12))); }
// собеседник мог сменить ключ (новое устройство, сброс), пока страница открыта: сверяем с сервером и пересчитываем ключ чата
const chkAt=new Map();
async function refreshPeer(cid){ const c=S.chatMap&&S.chatMap.get(cid); if(!c||c.type!=='private'||!c.peer_id||c.peer_id===me) return false; const t=chkAt.get(c.peer_id)||0; if(Date.now()-t<20000) return false; chkAt.set(c.peer_id,Date.now());
  const {data}=await sb.from('lm_keys').select('pub').eq('user_id',c.peer_id).maybeSingle(); if(!data?.pub) return false; const cur=peers.get(c.peer_id); if(cur&&b64(cur)===data.pub) return false;
  if(!accept(c.peer_id,data.pub)) return false; keys.delete(cid); await prepFor(cid,c.peer_id); return keys.has(cid); }
async function decStr(cid,body){ try{ return await decOnce(cid,body); }catch{} try{ if(await refreshPeer(cid)) return await decOnce(cid,body); }catch{} return LOCK; }
async function dec(m){ if(m&&!m._enc&&is(m.body)){ await prepChat(m.chat_id); m._enc=1; m.body=await decStr(m.chat_id,m.body); } return m; }
async function decAll(arr){ for(const m of (arr||[])) await dec(m); return arr; }
async function decChats(list){ if(!list||st.status!=='ready') return; await prefetch(list.filter(c=>c.type==='private').map(c=>c.peer_id));
  for(const c of list){ if(c.type==='private'&&is(c.last_body)){ await prepFor(c.chat_id,c.peer_id); c.last_body=await decStr(c.chat_id,c.last_body); } } }
const active=cid=>keys.has(cid);
function drop(){ noKey.clear(); for(const k of [...peers.keys()]) if(k!==me) peers.delete(k); keys.clear(); }
async function safety(peer){ const a=mine?.pub, b=peer===me?mine?.pub:peers.get(peer); if(!a||!b) return null; const sa=b64(a), sb2=b64(b), [x,y]=sa<=sb2?[sa,sb2]:[sb2,sa];
  const h=new Uint8Array(await crypto.subtle.digest('SHA-256',te.encode(x+'|'+y))); const g=[];
  for(let i=0;i<8;i++){ const v=((h[i*4]<<24)>>>0)+(h[i*4+1]<<16)+(h[i*4+2]<<8)+h[i*4+3]; g.push(String(v%100000).padStart(5,'0')); } return g.join(' '); }
// окна
function backupDlg(){ if(st.status!=='ready'||document.getElementById('e2p1')) return;
  modal(st.backedUp?'Новый пароль копии':'Сохраните ключи шифрования',`<p style="margin:0 0 12px;color:var(--muted);font-size:14px">Личные чаты защищены сквозным шифрованием. Ключи хранятся только в этом браузере. Придумайте пароль резервной копии \u2014 с ним переписки можно будет прочитать на другом устройстве. Если пароль забыть, старые сообщения восстановить будет нельзя: мы их прочитать не можем.</p><div class="field"><input class="inp" id="e2p1" type="password" autocomplete="new-password" placeholder="Пароль (не меньше 8 символов)"></div><div class="field"><input class="inp" id="e2p2" type="password" autocomplete="new-password" placeholder="Повторите пароль"></div>`,
  [...(st.backedUp?[['Отмена','ghost']]:[]),['Сохранить','primary',async c=>{ const a=$('#e2p1').value, b=$('#e2p2').value;
    if(a.length<8) return toast('Пароль слишком короткий'); if(a!==b) return toast('Пароли не совпадают');
    if(await createBackup(a)){ c(); toast('Резервная копия сохранена'); try{ if($('#sE2E')) renderSettings(); }catch{} } else toast('Не удалось сохранить, попробуйте ещё раз'); }]],!st.backedUp); }
function restoreDlg(){ if(st.status!=='restore'||document.getElementById('e2pr')) return;
  modal('Расшифровка переписок',`<p style="margin:0 0 12px;color:var(--muted);font-size:14px">Личные чаты защищены сквозным шифрованием. Введите пароль резервной копии, который вы задали на другом устройстве.</p><div class="field"><input class="inp" id="e2pr" type="password" autocomplete="current-password" placeholder="Пароль резервной копии"></div>`,
  [['Забыл пароль','ghost',c=>{ confirmBox('Будут созданы новые ключи. Старые личные переписки останутся зашифрованными и прочитать их будет нельзя. Новые сообщения будут работать как обычно.','Сбросить',async()=>{ if(await reset()){ c(); toast('Ключи созданы заново'); loadChats(); if(S.cur) openChat(S.cur); } else toast('Не удалось, попробуйте ещё раз'); }); }],
   ['Расшифровать','primary',async c=>{ const pw=$('#e2pr').value; if(!pw) return; if(await restore(pw)){ c(); toast('Переписки расшифрованы'); loadChats(); if(S.cur) openChat(S.cur); } else toast('Неверный пароль'); }]]); }
async function safetyDlg(peer){ await prefetch([peer]); const code=await safety(peer);
  modal('Код безопасности',code?`<div style="font-size:20px;font-weight:700;letter-spacing:.5px;text-align:center;margin:6px 0 12px;word-spacing:6px">${code}</div><p style="margin:0;color:var(--muted);font-size:14px">Сравните этот код с кодом у собеседника при встрече или по звонку. Если коды совпадают \u2014 переписка защищена от подмены.${changed.has(peer)?'<br><br>\u26a0\ufe0f Ключ собеседника изменился с прошлого раза (например, он сменил устройство или сбросил ключи).':''}</p>`:`<p style="margin:0;color:var(--muted)">У собеседника пока нет ключа шифрования \u2014 сообщения ему идут без сквозного шифрования.</p>`,[['Закрыть','ghost']]); }
function open(){ if(st.status==='restore') restoreDlg(); else if(st.status==='ready'){ try{ localStorage.removeItem('lm_e2e_skip_'+me); }catch{} backupDlg(); } else toast('Шифрование ещё запускается\u2026'); }
const label=()=>st.status==='ready'?(st.backedUp?'Копия ключей сохранена':'Задайте пароль копии'):st.status==='restore'?'Нужен пароль копии':'Личные чаты';
async function callKey(peer){ try{ await ready(); const c=(S.chats||[]).find(x=>x.type==='private'&&x.peer_id===peer); if(!c) return null; await prepChat(c.chat_id); return keys.has(c.chat_id)?c.chat_id:null; }catch{ return null; } }
return {is,ready,decChats,dec,decAll,prepChat,enc,active,drop,safetyDlg,safety,createBackup,restore,reset,open,label,st,callKey,encStr:enc,decStr};
})();
async function sendRow(cid,row){
const go=async()=>{ let wire=row; if(row.kind==='text'&&row.body){ await E2E.prepChat(cid); const e=await E2E.enc(cid,row.body); if(e) wire={...row,body:e}; }
  const r=await sb.from('lm_messages').insert({chat_id:cid,sender_id:S.me.id,...wire}).select().single(); if(r.data) await E2E.dec(r.data); return r; };
let r=await go();
if(r.error&&/зашифровано/.test(r.error.message||'')){ E2E.drop(); r=await go(); }
return r;
}
const admB=b=>(b&&String(b).startsWith('e2e1:'))?'\u{1f512} зашифровано (сквозное шифрование)':b;
/* ================= CHAT LIST ================= */
function cdb(){ return new Promise((res,rej)=>{ const r=indexedDB.open('lumo-cache',1); r.onupgradeneeded=()=>{ const db=r.result; if(!db.objectStoreNames.contains('chats')) db.createObjectStore('chats'); if(!db.objectStoreNames.contains('msgs')) db.createObjectStore('msgs'); }; r.onsuccess=()=>res(r.result); r.onerror=()=>rej(r.error); }); }
async function ccSet(store,key,val){ try{ const db=await cdb(); return await new Promise(res=>{ const tx=db.transaction(store,'readwrite'); tx.objectStore(store).put(val,key); tx.oncomplete=()=>res(true); tx.onerror=()=>res(false); }); }catch{ return false; } }
async function ccGet(store,key){ try{ const db=await cdb(); return await new Promise(res=>{ const q=db.transaction(store).objectStore(store).get(key); q.onsuccess=()=>res(q.result||null); q.onerror=()=>res(null); }); }catch{ return null; } }
async function loadChats(){
const {data,error}=await sb.rpc('lm_chats_v2');
if(error){
console.error(error);
if(!S.chats.length){ const cached=await ccGet('chats','list'); if(cached&&cached.length){ S.chats=cached; S.chatMap=new Map(cached.map(c=>[c.chat_id,c])); cached.forEach(c=>{ if(c.peer_id){ const o=S.profiles.get(c.peer_id)||{}; S.profiles.set(c.peer_id,{...o,id:c.peer_id,name:c.peer_name,username:c.peer_username,avatar_url:c.peer_avatar,color:c.peer_color,last_seen:c.peer_last_seen,bio:c.peer_bio}); } }); renderList(); updateTitle(); toast('Нет сети \\u2014 показаны последние сохранённые чаты'); } }
return;
}
try{ await E2E.ready(); await E2E.decChats(data); }catch(e){ console.error(e); }
S.chats=data; S.chatMap=new Map(data.map(c=>[c.chat_id,c])); setTimeout(syncTyping,0); setTimeout(loadUR,0);
data.forEach(c=>{ if(c.peer_id){ const o=S.profiles.get(c.peer_id)||{}; S.profiles.set(c.peer_id,{...o,id:c.peer_id,name:c.peer_name,username:c.peer_username,avatar_url:c.peer_avatar,color:c.peer_color,last_seen:c.peer_last_seen,bio:c.peer_bio}); } });
renderList(); updateTitle();
ccSet('chats','list',data);
}
let reloadT; function scheduleReload(){ clearTimeout(reloadT); reloadT=setTimeout(loadChats,400); }
function updateTitle(){ const n=S.chats.filter(c=>!c.muted).reduce((a,c)=>a+c.unread,0); document.title=n?`(${n}) Lumo`:'Lumo'; }
function renderList(){
updateTabBadges();
if(S.tab!=='chats'){ if(S.tab==='contacts') renderContacts(); return; }
if(S.q) return renderSearch();
let L=S.chats; const f=S.folder;
if(f==='unread') L=L.filter(c=>c.unread>0); else if(f!=='all') L=L.filter(c=>c.type===f);
const PN=f==='all'?S.chats.filter(c=>c.pinned):[]; if(PN.length) L=L.filter(c=>!c.pinned);
$('#list').innerHTML = storiesBar() + (window.lfRemBar?window.lfRemBar():'') + announceCard() + tgListCard() + notifCard() + pinRowHtml(PN) + (L.length ? L.map(rowHtml).join('') : '') + ((L.length||PN.length)?'': `<div style="text-align:center;color:var(--muted);padding:40px 20px">${f==='all'?'Пока нет чатов.<br>Найдите людей через поиск или нажмите \u00ab+\u00bb':'Здесь пусто'}</div>`);
}
function tgListCard(){ if(S.q||!/iPhone|iPad|iPod/.test(navigator.userAgent)||navigator.standalone||matchMedia('(display-mode: standalone)').matches||localStorage.getItem('lm_tgc_hide')) return '';
const href=S.tgCode?`https://t.me/${S.bot}?start=${S.tgCode}`:`https://t.me/${S.bot}`;
return `<div class="ncard tgl"><span class="nci tg">${ic('bell')}</span><div class="tx"><b>Уведомления на iPhone</b><span>Нажмите «Поделиться» → «На экран Домой» и открывайте Lumo с иконки <span style="display:none">\u2014 сообщения и звонки придут, когда Lumo закрыт</span></div><a class="ncon tg" id="tgListOn" href="${href}" target="_blank" rel="noopener">Понятно</a><button class="ncx tgx" type="button">${ic('x')}</button></div>`; }
document.addEventListener('click',e=>{ const on=e.target.closest('#tgListOn'), x=e.target.closest('.ncard .tgx'); if(!on&&!x) return; e.stopPropagation();
  if(x){ localStorage.setItem('lm_tgc_hide','1'); x.closest('.ncard').classList.add('bye'); setTimeout(renderList,350); return; }
  e.preventDefault(); localStorage.setItem('lm_tgc_hide','1'); on.closest('.ncard').classList.add('bye'); setTimeout(renderList,350); },true);
// ждём, пока пользователь нажмёт \u00abЗапустить\u00bb в боте
function tgWaitLink(){ clearInterval(tgPoll); let n=0; toast('Нажмите \u00abЗапустить\u00bb в боте \u2014 и всё');
  tgPoll=setInterval(async()=>{ if(++n>60){ clearInterval(tgPoll); return; } const {data}=await sb.from('lm_tg_links').select('*').eq('user_id',S.me.id).maybeSingle();
    if(data&&data.enabled){ clearInterval(tgPoll); S.tg=data; toast('Telegram привязан \u2014 уведомления включены'); renderList(); renderSettings(); } },3000); }
function notifCard(){ if(S.q||!notifSupported()||Notification.permission!=='default'||localStorage.getItem('lm_nc_hide')) return '';
return `<div class="ncard"><span class="nci">${ic('bell')}</span><div class="tx"><b>Уведомления</b><span>Не пропускайте сообщения и звонки</span></div><button class="ncon" type="button">Включить</button><button class="ncx" type="button">${ic('x')}</button></div>`; }
document.addEventListener('click',async e=>{ const on=e.target.closest('.ncard .ncon'), x=e.target.closest('.ncard .ncx'); if(!on&&!x) return; e.stopPropagation();
  const card=e.target.closest('.ncard'); if(x){ localStorage.setItem('lm_nc_hide','1'); card.classList.add('bye'); setTimeout(renderList,350); return; }
  await askNotif(); card.classList.add('bye'); setTimeout(renderList,350); if(canNotify()) showNote('Lumo',{body:'Уведомления включены \u{1f389}',icon:NOTE_ICON,tag:'lumo-test'}); },true);
/* непросмотренные реакции на мои сообщения: «Реакция … на Ваше сообщение» и сердечко в списке чатов */
S.ur=new Map(); let urT=null;
async function loadUR(){ const {data,error}=await sb.rpc('lm_unseen_reactions'); if(error||!data) return; const m=new Map();
  data.forEach(r=>{ if(r.chat_id===S.cur&&!document.hidden){ seenUR(r.chat_id); return; } m.set(r.chat_id,r); }); S.ur=m; renderList(); }
function seenUR(id){ if(!S.ur.has(id)&&id!==S.cur) return; const had=S.ur.delete(id); if(had) renderList(); sb.rpc('lm_seen_reactions',{p_chat:id}).then(()=>{},()=>{}); }
function urArrived(id){ if(!id) return; if(id===S.cur&&!document.hidden){ seenUR(id); return; } clearTimeout(urT); urT=setTimeout(loadUR,600); }
function rowHtml(c){
const typ=S.typing.get(c.chat_id); const tnames=typ?[...typ.values()].map(v=>v.name):[];
let pv;
if(tnames.length){ const tv=[...typ.values()][0]; pv=`<span class="typing">${c.type==='private'?typVerb(tv):esc(tnames[0])+' '+typVerb(tv)}<span class="typingdots"><i></i><i></i><i></i></span></span>`; }
else if(false) pv=`<span><span class="typingdots"><i></i><i></i><i></i></span></span>`;
else if(c.chat_id!==S.cur&&drafts.get(c.chat_id)) pv=`<span class="drf">Черновик: </span>${esc(drafts.get(c.chat_id).replace(/\s+/g,' ').slice(0,120))}`;
else if(S.ur&&S.ur.get(c.chat_id)&&(!c.last_at||new Date(S.ur.get(c.chat_id).at)>=new Date(c.last_at))){ const e=S.ur.get(c.chat_id).emoji||''; pv=`<span class="urv">${ic('fwd','mini')}Реакция ${e.length<=8&&!e.includes(':')?esc(e)+' ':''}на Ваше сообщение</span>`; }
else if(c.last_id){ let pre=''; if(c.last_kind!=='system'){ if(c.last_sender===S.me.id && c.peer_id!==S.me.id) pre='<b>Вы: </b>'; else if(c.type==='group' && c.last_sender_name) pre=`<b>${esc(c.last_sender_name)}: </b>`; }
pv=pre+previewOf({kind:c.last_kind,body:c.last_body,deleted:c.last_deleted}); }
else pv='Нет сообщений';
const mine=c.last_sender===S.me.id && c.last_kind!=='system' && c.peer_id!==S.me.id && c.type!=='channel';
const read=mine && c.others_read_at && new Date(c.others_read_at)>=new Date(c.last_at);
const tIcon = c.type==='group'?ic('users','mini'):c.type==='channel'?ic('mega','mini'):'';
return `<div class="row ${c.chat_id===S.cur?'on':''}" data-chat="${c.chat_id}">${chatAv(c)}
<div class="mid"><div class="t1"><span class="nm">${tIcon}${esc(chatName(c))}${c.type==='private'&&c.peer_id!==S.me.id?pMark({verified:c.peer_verified,is_bot:c.peer_bot,premium:c.peer_premium,emoji_status:c.peer_emoji||(S.profiles.get(c.peer_id)||{}).emoji_status}):(c.peer_verified?vMark(true):'')}${c.type==='private'&&window.lfBadge?window.lfBadge(c.chat_id):''}${c.muted?ic('belloff','mini'):''}</span>
<time>${mine?ic(read?'checks':'check','mini chk'):''}${c.last_at?fmtListTime(c.last_at):''}</time></div>
<div class="t2"><span class="pv">${pv}</span>${S.ur&&S.ur.has(c.chat_id)?`<span class="urh ${c.muted?'mute':''}"><svg viewBox="0 0 24 24" width="21" height="21"><path d="M12 21C5 15 2 11.5 2 8a5 5 0 0 1 10-1 5 5 0 0 1 10 1c0 3.5-3 7-10 13z" fill="currentColor"/></svg></span>`:''}${c.unread?`<span class="badge ${c.muted?'mute':''}">${c.unread>99?'99+':c.unread}</span>`:(c.pinned?ic('pin','mini'):'')}</div></div></div>`;
}
let searchT;
$('#q').addEventListener('input',e=>{ S.q=e.target.value.trim(); clearTimeout(searchT);
if(S.tab==='contacts'){ renderContacts(); searchT=setTimeout(contactSearch,250); return; } if(!S.q) return renderList(); renderSearch(); searchT=setTimeout(globalSearch,250); });
let globalRes=[];
async function globalSearch(){ const q=S.q.replace(/^@/,''); if(!q||S.tab!=='chats') return; const {data}=await sb.rpc('lm_search',{q}); globalRes=data||[]; renderSearch(); }
function renderSearch(){
if(S.tab!=='chats') return;
const q=S.q.toLowerCase().replace(/^@/,'');
const local=S.chats.filter(c=>chatName(c).toLowerCase().includes(q)||(c.peer_username||c.username||'').includes(q));
const ids=new Set(local.map(c=>c.peer_id||c.chat_id));
const glob=globalRes.filter(r=>!ids.has(r.id));
let h=''; if(local.length) h+='<div class="sec">Чаты</div>'+local.map(rowHtml).join('');
if(glob.length) h+='<div class="sec">Глобальный поиск</div>'+glob.map(r=>`<div class="row" data-g="${r.kind}" data-id="${r.id}">${avatar({name:r.name,avatar:r.avatar_url,color:r.color},'',r.kind==='user'&&S.online.has(r.id))}
<div class="mid"><div class="t1"><span class="nm">${r.kind==='group'?ic('users','mini'):r.kind==='channel'?ic('mega','mini'):''}${esc(r.name)}</span></div>
<div class="t2"><span class="pv">@${esc(r.username||'')}${r.kind!=='user'?' \u00b7 '+r.extra+' '+(r.kind==='channel'?plural(+r.extra,'подписчик','подписчика','подписчиков'):plural(+r.extra,'участник','участника','участников')):''}</span></div></div></div>`).join('');
if(!h) h='<div style="text-align:center;color:var(--muted);padding:40px">Ничего не найдено</div>';
$('#list').innerHTML=h;
}
$('#list').addEventListener('click',async e=>{
const r=e.target.closest('.row'); if(!r) return;
if(r.dataset.chat){ openChat(r.dataset.chat); }
else if(r.dataset.g==='user'){ await openDM(r.dataset.id); }
else if(r.dataset.g){ joinPrompt(r.dataset.id, r.dataset.g, r.querySelector('.nm').textContent); }
if(S.q){ $('#q').value=''; S.q=''; renderList(); }
});
$('#folders').onclick=e=>{ const b=e.target.closest('button'); if(!b||b.classList.contains('on')) return; S.folder=b.dataset.f; $('#folders').querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b)); renderList(); moveFolderInd(); stagger($('#list')); try{ b.scrollIntoView({inline:'center',block:'nearest',behavior:'smooth'}); }catch{} };
async function openDM(uid){ const {data,error}=await sb.rpc('lm_open_dm',{p_other:uid}); if(error) return toast(error.message); await loadChats(); openChat(data); }
async function openByUsername(u){ u=u.toLowerCase(); const {data}=await sb.rpc('lm_search',{q:u}); const r=(data||[]).find(x=>(x.username||'').toLowerCase()===u); if(!r) return toast('Не найдено: @'+u);
if(r.kind==='user') return openDM(r.id); const c=S.chatMap.get(r.id); if(c) return openChat(r.id); joinPrompt(r.id,r.kind,r.name); }
function joinPrompt(id,kind,name){
modal(`${kind==='channel'?'Канал':'Группа'}`, `<div style="text-align:center;padding:10px 0"><div style="display:flex;justify-content:center">${avatar({name},'l')}</div><h2 style="margin:14px 0 4px">${esc(name)}</h2><p style="color:var(--muted)">Вступите, чтобы читать и писать сообщения</p></div>`,
[['Отмена','ghost'],[kind==='channel'?'Подписаться':'Вступить','primary',async close=>{ const {error}=await sb.rpc('lm_join',{p_chat:id}); if(error) return toast(error.message); close(); await loadChats(); openChat(id); }]]);
}
/* ================= TABS: контакты / звонки / чаты / настройки ================= */
function setTab(t){ { const b=document.querySelector(`#tabs button[data-tab="${t==='contacts'?'settings':t}"] .ti`); if(b){ b.classList.remove('tbump'); void b.offsetWidth; b.classList.add('tbump'); } }
if(t==='settings'&&S.tab!=='settings') SP.page='main';
S.tab=t; const tb=t==='contacts'?'settings':t; document.querySelectorAll('#tabs button').forEach(b=>b.classList.toggle('on',b.dataset.tab===tb));
const titles={contacts:'Контакты',calls:'Звонки',chats:'Чаты',settings:'Настройки'};
const searchable = t==='chats'||t==='contacts';
$('#qbox').classList.toggle('hidden',!searchable); $('#tabTitle').textContent=titles[t]; $('#tophead').classList.toggle('hidden',searchable); $('#topBack').classList.toggle('hide',t!=='contacts');
$('#q').placeholder = t==='contacts' ? 'Поиск контактов и людей' : 'Поиск';
$('#q').value=''; S.q=''; globalRes=[]; contactRes=[];
$('#folders').classList.toggle('hidden',t!=='chats');
$('#list').classList.toggle('hidden',t!=='chats'); $('#pane').classList.toggle('hidden',t==='chats');
$('#newBtn').classList.toggle('hide',!(t==='chats'||t==='contacts'));
$('#newBtn').innerHTML=ic(t==='contacts'?'userplus':'edit');
$('#pane').scrollTop=0;
if(t==='chats') renderList();
if(t==='contacts'){ renderContacts(); loadContacts(); }
if(t==='calls'){ localStorage.setItem('lm_calls_seen',new Date().toISOString()); renderCalls(); loadCalls(); }
if(t==='settings') renderSettings();
updateTabBadges();
requestAnimationFrame(()=>{ moveTabInd(); if(t==='chats') moveFolderInd(); stagger(t==='chats'?$('#list'):$('#pane')); });
}
function missedCount(){ const seen=localStorage.getItem('lm_calls_seen')||'1970'; return (S.calls||[]).filter(m=>m.sender_id!==S.me?.id && m.meta?.status==='missed' && m.created_at>seen).length; }
function updateTabBadges(){
const n=S.chats.filter(c=>!c.muted).reduce((a,c)=>a+(c.unread||0),0);
const fmtN=x=>x>999?(Math.floor(x/100)/10)+'K':String(x);
const bc=$('#bChats'); if(bc){ bc.textContent=fmtN(n); bc.classList.toggle('hidden',!n); }

const cnt={private:0,group:0,channel:0,unread:0};
S.chats.forEach(c=>{ if(c.unread&&!c.muted){ cnt[c.type]=(cnt[c.type]||0)+1; cnt.unread++; } });
const FL={all:'Все',private:'Чаты',group:'Группы',channel:'Каналы',unread:'Непрочитанные'};
document.querySelectorAll('#folders button').forEach(b=>{ const k=b.dataset.f; const v=k==='all'?0:cnt[k]; b.innerHTML=esc(FL[k])+(v?`<span class="fc">${v}</span>`:''); });
const seen=localStorage.getItem('lm_calls_seen')||'1970';
const miss=S.tab==='calls'?0:S.calls.filter(m=>m.sender_id!==S.me?.id && m.meta?.status==='missed' && m.created_at>seen).length;
const bm=$('#bCalls'); if(bm){ bm.textContent=miss; bm.classList.toggle('hidden',!miss); }
moveFolderInd();
}
$('#tabs').addEventListener('click',e=>{ const b=e.target.closest('[data-tab]'); if(b) setTab(b.dataset.tab); });
/* contacts */
let contactRes=[];
async function ensureProfiles(ids){ const need=[...new Set(ids)].filter(u=>u&&!S.profiles.has(u)); if(!need.length) return;
await profGet(need); }
async function loadContacts(){
const {data,error}=await sb.from('lm_contacts').select('contact_id,created_at,alias').order('created_at',{ascending:false});
if(error) return; S.contacts=data.map(r=>r.contact_id); S.alias=new Map(data.filter(r=>r.alias).map(r=>[r.contact_id,r.alias])); reapplyAlias();
// обновляем \u00abбыл в сети\u00bb у контактов
if(S.contacts.length){ await profGet(S.contacts); }
renderContacts();
}
const isContact=id=>S.contacts.includes(id);
async function addContact(id){ if(isContact(id)||id===S.me.id) return; if(isBotUser(id)) return toast('Ботов нельзя добавить в контакты'); const {error}=await sb.from('lm_contacts').insert({contact_id:id}); if(error) return toast(error.message);
S.contacts.unshift(id); await ensureProfiles([id]); toast('Добавлено в контакты'); renderContacts(); if(!$('#info').classList.contains('hidden')) renderInfo(); }
async function removeContact(id){ const {error}=await sb.from('lm_contacts').delete().eq('contact_id',id); if(error) return toast(error.message);
S.contacts=S.contacts.filter(x=>x!==id); toast('Удалено из контактов'); renderContacts(); if(!$('#info').classList.contains('hidden')) renderInfo(); }
async function contactSearch(){ const q=S.q.replace(/^@/,''); if(!q||S.tab!=='contacts') return; const {data}=await sb.rpc('lm_search',{q});
contactRes=(data||[]).filter(r=>r.kind==='user'&&r.id!==S.me.id); renderContacts(); }
let syncRes=null;
const normPh=t=>{let d=String(t).replace(/\D/g,'');if(d.length==11&&d[0]=='8')d='7'+d.slice(1);if(d.length==10&&d[0]=='9')d='7'+d;return d.length==11&&d[0]=='7'?d:null;};
async function syncContacts(){
if(!(navigator.contacts&&navigator.contacts.select)) return toast('Этот браузер не открывает контакты. Работает в Chrome на Android, а в приложениях Lumo для iPhone и Android — всегда');
let c; try{ c=await navigator.contacts.select(['name','tel'],{multiple:true}); }catch(e){ return; }
const m=new Map(); (c||[]).forEach(x=>(x.tel||[]).forEach(t=>{ const p=normPh(t); if(p&&!m.has(p)) m.set(p,(x.name&&x.name[0])||('+'+p)); }));
if(!m.size) return toast('Номера не выбраны');
const {data,error}=await sb.rpc('lm_match_contacts',{p_phones:[...m.keys()]}); if(error) return toast(error.message);
const f=data||[], got=new Set(f.map(r=>r.phone));
syncRes={found:f,rest:[...m].filter(([p])=>!got.has(p)).map(([p,n])=>({p,n}))};
renderContacts();
}
function invite(p){ location.href='sms:+'+p+'?body='+encodeURIComponent('Я в Lumo, заходи: '+location.origin+location.pathname+'#@'+S.me.username); }
/* видео в чате подгружаются по одному и только когда доходят до экрана — иначе канал с десятками видео забивает соединение */
(function(){ const q=[]; let busy=false;
{ const st=document.createElement('style'); st.textContent='.b.media .meta.ov{width:auto!important;left:auto!important;right:10px!important;bottom:10px!important;max-width:max-content!important;display:inline-flex!important;justify-content:flex-end!important}.albgrid{min-height:60px}button,.ib,.rbtn,[data-view],#who{touch-action:manipulation}.albgrid .vc{position:relative!important}.albgrid .vc video.ph{position:absolute!important;left:0!important;top:0!important;right:0!important;bottom:0!important;width:100%!important;height:100%!important;min-width:0!important;transform:none!important;margin:0!important}.albgrid video.ph{object-fit:contain!important;object-position:center!important;background:#0c0d1a}'; document.head.appendChild(st); }
const next=()=>{ if(busy) return; const v=q.shift(); if(!v) return; if(!v.isConnected||v.getAttribute('src')) return next(); busy=true;
 const done=()=>{ clearTimeout(t); v.removeEventListener('loadeddata',done); v.removeEventListener('error',done); busy=false; next(); };
 const t=setTimeout(done,5000); v.addEventListener('loadeddata',done); v.addEventListener('error',done); v.preload='metadata'; v.src=v.dataset.lsrc; };
const io='IntersectionObserver' in window?new IntersectionObserver(es=>{ es.forEach(e=>{ if(e.isIntersecting){ io.unobserve(e.target); q.push(e.target); } }); next(); },{rootMargin:'120px'}):null;
const scan=n=>{ if(n.nodeType!==1) return; (n.matches&&n.matches('video[data-lsrc]')?[n]:[...n.querySelectorAll('video[data-lsrc]')]).forEach(v=>{ if(v.__lz) return; v.__lz=1; if(io) io.observe(v); else { q.push(v); next(); } }); };
new MutationObserver(ms=>ms.forEach(m=>m.addedNodes.forEach(scan))).observe(document.documentElement,{childList:true,subtree:true});
/* нажатие на видео открывается сразу по касанию, без второго тапа */
let tp=null;
document.addEventListener('touchstart',e=>{ const v=e.target.closest&&e.target.closest('video[data-view]'); tp=v&&e.touches.length===1?{v,x:e.touches[0].clientX,y:e.touches[0].clientY,t:Date.now()}:null; },{passive:true,capture:true});
document.addEventListener('touchend',e=>{ if(!tp) return; const d=tp; tp=null; const t=e.changedTouches[0]; if(S.sel||Math.abs(t.clientX-d.x)>10||Math.abs(t.clientY-d.y)>10||Date.now()-d.t>600) return; e.preventDefault(); e.stopPropagation(); lightbox(d.v.dataset.view,true); },{passive:false,capture:true});
})();
function personRow(p,extra){ return `<div class="row" data-person="${p.id}">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'',S.online.has(p.id))}
<div class="mid"><div class="t1"><span class="nm">${esc(p.name||'')}</span></div><div class="t2"><span class="pv ${S.online.has(p.id)?'typing':''}">${esc(lastSeen(p))}</span></div></div>${extra||''}</div>`; }
function renderContacts(){
if(S.tab!=='contacts') return; const q=S.q.toLowerCase().replace(/^@/,'');
let list=S.contacts.map(id=>S.profiles.get(id)).filter(Boolean);
if(q) list=list.filter(p=>(p.name||'').toLowerCase().includes(q)||(p.username||'').includes(q));
list.sort((a,b)=>(S.online.has(b.id)-S.online.has(a.id))||(new Date(b.last_seen)-new Date(a.last_seen)));
let h='';
if(!q) h+=`<div class="row" id="cInvite"><div class="av c2">${ic('link')}</div><div class="mid"><div class="t1"><span class="nm">Пригласить друзей</span></div><div class="t2"><span class="pv">Скопировать ссылку на мой профиль</span></div></div></div>`;
if(!q) h+=`<div class="row" id="cSync"><div class="av c1">${ic('userplus')}</div><div class="mid"><div class="t1"><span class="nm">Найти друзей в Lumo</span></div><div class="t2"><span class="pv">Выбрать людей из телефонной книги</span></div></div></div>`;
if(list.length) h+=`<div class="sec">${q?'Мои контакты':'Контакты \u00b7 '+list.length}</div>`+list.map(p=>personRow(p,`<button class="rbtn" data-cdm="${p.id}" title="Написать">${ic('chat')}</button>`)).join('');
const glob=contactRes.filter(r=>!isContact(r.id));
if(q&&glob.length) h+='<div class="sec">Глобальный поиск</div>'+glob.map(r=>personRow({id:r.id,name:r.name,avatar_url:r.avatar_url,color:r.color,last_seen:S.profiles.get(r.id)?.last_seen,username:r.username},`<button class="rbtn" data-cadd="${r.id}" title="Добавить в контакты">${ic('userplus')}</button>`)).join('');
if(!list.length && !(q&&glob.length)) h+=`<div style="text-align:center;color:var(--muted);padding:34px 20px">${q?'Никого не найдено':'Контактов пока нет.<br>Найдите человека по имени или @юзернейму и нажмите \u00ab+\u00bb'}</div>`;
if(!q&&syncRes){
 if(syncRes.found.length) h+=`<div class="sec">Уже в Lumo · ${syncRes.found.length}</div>`+syncRes.found.map(r=>personRow({id:r.user_id,name:r.name,avatar_url:r.avatar_url,color:r.color,last_seen:S.profiles.get(r.user_id)?.last_seen,username:r.username},isContact(r.user_id)?`<button class="rbtn" data-cdm="${r.user_id}" title="Написать">${ic('chat')}</button>`:`<button class="rbtn" data-cadd="${r.user_id}" title="Добавить в контакты">${ic('userplus')}</button>`)).join('');
 if(syncRes.rest.length) h+=`<div class="sec">Пригласить · ${syncRes.rest.length}</div>`+syncRes.rest.slice(0,150).map(x=>`<div class="row"><div class="av c2">${ic('link')}</div><div class="mid"><div class="t1"><span class="nm">${esc(x.n)}</span></div><div class="t2"><span class="pv">Ещё нет в Lumo</span></div></div><button class="rbtn" data-inv="${x.p}" title="Пригласить">${ic('chat')}</button></div>`).join('');
 if(!syncRes.found.length&&!syncRes.rest.length) h+='';
}
$('#pane').innerHTML=h;
}
/* calls */
async function loadCalls(){
const {data,error}=await sb.from('lm_messages').select('id,chat_id,sender_id,meta,created_at').eq('kind','call').order('id',{ascending:false}).limit(100);
if(error) return; S.calls=data; S.callsLoaded=true; renderCalls(); updateTabBadges();
}
function callPeer(m){ const c=S.chatMap.get(m.chat_id); if(!c||c.type!=='private') return null; return {chat:c,p:S.profiles.get(c.peer_id)||{id:c.peer_id,name:c.peer_name,avatar_url:c.peer_avatar,color:c.peer_color}}; }
function renderCalls(){
if(S.tab!=='calls') return;
if(!S.callsLoaded){ $('#pane').innerHTML='<div style="text-align:center;color:var(--muted);padding:40px">Загрузка\u2026</div>'; return; }
const rows=S.calls.map(m=>{ const x=callPeer(m); if(!x) return '';
const out=m.sender_id===S.me.id, ok=m.meta?.status==='ended', rej=m.meta?.status==='rejected', miss=!ok&&!out&&!rej, v=!!m.meta?.video;
const label=(out?(ok?'Исходящий':'Отменённый'):ok?'Входящий':rej?'Отклонённый':'Пропущенный')+(v?' видеозвонок':' звонок');
const d=new Date(m.created_at); const when=sameDay(d,new Date())?fmtT(d):fmtDay(d).toLowerCase()+' в '+fmtT(d);
return `<div class="row" data-callchat="${m.chat_id}">${avatar({name:x.p.name,avatar:x.p.avatar_url,color:x.p.color},'',S.online.has(x.p.id))}
<div class="mid"><div class="t1"><span class="nm ${miss?'miss':''}">${esc(x.p.name||'')}</span></div>
<div class="t2"><span class="pv">${ic(out?'arrout':'arrin','cdir '+(ok?'':'miss'))}${label} \u00b7 ${when}${ok&&m.meta.duration?' \u00b7 '+fmtDur(m.meta.duration):''}</span></div></div>
<button class="rbtn" data-recall="${m.chat_id}" data-v="${v?1:''}" title="Позвонить">${ic(v?'video':'phone')}</button></div>`; }).join('');
$('#pane').innerHTML = rows || `<div style="text-align:center;color:var(--muted);padding:40px 20px">Звонков пока нет.<br>Позвонить можно из чата или из контактов</div>`;
}
async function callChat(chatId,video){ await openChat(chatId); startCall(video); }
/* settings (вкладка) */
// ---------- Настройки: главный экран и разделы ----------
const WALLS=['none',
 'linear-gradient(160deg,rgba(124,92,255,.13),rgba(34,193,255,.10))',
 'radial-gradient(circle at 18% 22%,rgba(255,91,138,.16),transparent 45%),radial-gradient(circle at 82% 72%,rgba(124,92,255,.16),transparent 45%)',
 'radial-gradient(rgba(128,128,170,.22) 1px,transparent 1.6px) 0 0/18px 18px',
 'linear-gradient(160deg,rgba(19,176,165,.16),rgba(46,230,166,.06))',
 'repeating-linear-gradient(45deg,rgba(128,128,170,.07) 0 2px,transparent 2px 14px)'];
function applyLook(){ const r=document.documentElement.style;
  const fs=+(localStorage.getItem('lm_fs')||15); r.setProperty('--msgfs',fs+'px');
  const wv=String(localStorage.getItem('lm_wall')||'0'); r.setProperty('--wall',(wv[0]==='p'?PREM_WALLS[+wv.slice(1)]:WALLS[+wv])||'none'); }
applyLook();
const SP={page:'main'};
const SPAGES={premium:'Lumo Premium',uname:'Имя пользователя',colors:'Персональные цвета',pk:'Конфиденциальность',msgp:'Сообщения',phone:'Смена номера',profile:'Мой профиль',notif:'Уведомления и звуки',privacy:'Конфиденциальность',look:'Оформление',chats:'Чаты и данные',devices:'Устройства',about:'О Lumo'};
function setSPage(pg){ SP.page=pg; renderSettings(); try{ $('#pane').scrollTop=0; }catch{} }
function sic(icon,color){ return `<span class="sic" style="background:${color}">${ic(icon)}</span>`; }
function srow(id,icon,color,label,sub,right){ return `<div class="set srow" ${id?`id="${id}"`:''}>${sic(icon,color)}<span class="sl">${label}${sub?`<span class="setsub">${sub}</span>`:''}</span>${right===undefined?`<span class="chev">${ic('down','mini rot')}</span>`:right}</div>`; }
function stog(id,icon,color,label,sub,on){ return srow(id,icon,color,label,sub,`<span class="tog ${on?'on':''}"></span>`); }
function sradio(name,val,label,sub,cur){ return `<div class="set sradio ${cur===val?'on':''}" data-r="${name}" data-v="${val}"><span class="sl">${label}${sub?`<span class="setsub">${sub}</span>`:''}</span><span class="rchk">${ic('check')}</span></div>`; }
/* ---- профиль: имя/фамилия, день рождения, конфиденциальность ---- */
const PRIV_ITEMS=[
 ['seen','Время захода','Кто видит время моего последнего входа?','Если вы скрываете время захода, вы тоже не увидите его у других. Вместо времени будет \u00abбыл(а) недавно\u00bb.',1],
 ['photo','Фотографии профиля','Кто видит фотографию моего профиля?','Те, кому фото недоступно, увидят цветной кружок с инициалами.',1],
 ['bio','Раздел \u00abО себе\u00bb','Кто видит раздел \u00abО себе\u00bb?','Текст из раздела \u00abО себе\u00bb в вашем профиле.',1],
 ['birthday','День рождения','Кто видит мой день рождения?','Дата рождения в вашем профиле.',1],
 ['calls','Звонки','Кто может мне звонить?','Остальные не смогут вам позвонить.',1],
 ['voice','Голосовые сообщения','Кто может присылать мне голосовые и видеосообщения?','Остальные смогут писать только текстом.',1],
 ['messages','Сообщения','Кто может писать мне первым?','Тем, с кем вы уже переписываетесь, ограничение не помешает ответить.',0],
 ['invites','Приглашения','Кто может приглашать меня в группы и каналы?','Вы можете выбрать, кому разрешаете приглашать Вас в группы и каналы.',1]];
function privLabel(v){ return v==='contacts'?'Контакты':v==='none'?'Никто':'Все'; }
function myPriv(k){ const me=S.me||{}, p=me.privacy||{}; if(p[k]) return p[k];
  return k==='seen'?(me.show_seen===false?'none':'all'):k==='calls'?(me.calls_from||'all'):k==='birthday'?'contacts':'all'; }
function firstName(p){ const n=p?.name||'', l=p?.last_name||''; return l&&n.endsWith(' '+l)?n.slice(0,-(l.length+1)):n; }
const BD_M=['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];
function bdText(b,age){ if(!b) return ''; const [y,m,d]=String(b).slice(0,10).split('-').map(Number); if(!y||!m||!d) return '';
  let t=d+' '+BD_M[m-1]+' '+y; if(age){ const n=new Date(); let a=n.getFullYear()-y; if(n.getMonth()+1<m||(n.getMonth()+1===m&&n.getDate()<d)) a--; if(a>0&&a<121) t+=' ('+a+' '+plural(a,'год','года','лет')+')'; } return t; }
// профили \u2014 через сервер, который скрывает то, что мне видеть нельзя (фото, \u00abо себе\u00bb, время захода, день рождения)
async function profGet(ids){ ids=[...new Set((ids||[]).filter(Boolean))]; if(!ids.length) return []; const {data}=await sb.rpc('lm_profiles_get',{p_ids:ids}); (data||[]).forEach(p=>S.profiles.set(p.id,p)); return data||[]; }
async function refreshMe(){ const [p]=await profGet([S.me.id]); if(p){ S.me=p; } return S.me; }
function perow(id,icon,color,label,val,chev=true){ return `<div class="perow" id="${id}">${sic(icon,color)}<span class="sl">${label}</span>${val!==undefined&&val!==''?`<span class="peval">${val}</span>`:''}${chev?`<span class="chev">${ic('down','mini rot')}</span>`:''}</div>`; }
function themeMode(){ return localStorage.getItem('lm_theme')||'auto'; }
function devName(){ const ua=navigator.userAgent; const os=/iPhone|iPad|iPod/.test(ua)?'iPhone / iPad':/Android/.test(ua)?'Android':/Windows/.test(ua)?'Windows':/Mac/.test(ua)?'Mac':/Linux/.test(ua)?'Linux':'Устройство';
  const br=/YaBrowser/.test(ua)?'Яндекс Браузер':/Edg\//.test(ua)?'Edge':/OPR\//.test(ua)?'Opera':/Firefox/.test(ua)?'Firefox':/Chrome|CriOS/.test(ua)?'Chrome':/Safari/.test(ua)?'Safari':'браузер';
  return os+' \u00b7 '+br; }
function renderSettings(){
if(S.tab!=='settings') return;
const me=S.me; if(!me) return;
const pg=SP.page||'main';
const head=(pg==='main'||pg==='profile'||pg==='premium')?'':`<div class="sphead"><button class="hbtn" id="spBack">${ic('back')}</button><b>${SPAGES[pg]||''}</b></div>`;
let h='';
if(pg==='main'){
  const tgOn=!!(S.tg&&S.tg.enabled);
  h=`<div class="shero"><div class="shav" id="meAv">${avatar({name:me.name,avatar:me.avatar_url,color:me.color},'l')}<span class="shcam">${ic('camera')}</span></div>
<h2>${esc(me.name)}${pMark(me)}</h2><div class="st">@${esc(me.username)}</div>${me.bio?`<div class="shbio">${esc(me.bio)}</div>`:''}
<div class="shbtns"><button class="btn ghost shedit" id="sEdit">${ic('edit')} Изменить профиль</button><button class="btn ghost shedit" id="sMyQr" title="Мой QR-код">${ic('qr')} QR-код</button></div></div>
<div class="setgrp">${accList().filter(a=>a.id!==me.id).map(a=>`<div class="set srow" data-accsw="${a.id}">${avatar({name:a.name,avatar:a.avatar,color:0},'')}<span class="sl">${esc(a.name||'Аккаунт')}</span></div>`).join('')}${srow('mAddAcc','userplus','#7c5cff','Добавить аккаунт','')}</div>
<div class="setgrp">${srow('sPrem','star','linear-gradient(135deg,#6a8bff,#c06bff)','Lumo Premium','')}</div>
${window.lxRows?`<div class="setgrp">${window.lxRows()}</div>`:''}${window.lfRows?`<div class="setgrp">${window.lfRows()}</div>`:''}${S.staff?`<div class="setgrp">${srow('sAdmin','shield','#ff8a3d','Админ-панель',S.staff==='owner'?'Вы владелец Lumo \u00b7 люди, чаты, рассылки, статистика':'Вы администратор Lumo')}</div>`:''}
<div class="setgrp">
${srow('sProf','user','#7c5cff','Мой профиль','Имя, юзернейм, о себе, номер телефона')}
${srow('sSaved','bookmark','#3a7bff','Избранное','Заметки и сохранённые сообщения')}
${srow('sCalls','contact','#2bd67b','Контакты','Ваши контакты и поиск людей')}
${srow('sDev','laptop','#ff8a3d','Устройства',IS_DESKTOP?'Подключить телефон или другое устройство':'Подключить компьютер по QR-коду')}
</div>
<div class="setgrp">
${srow('sNotifP','bell','#ff5b5b','Уведомления и звуки',(window.Notification&&Notification.permission==='granted')?'Включены':'Выключены')}
${srow('sPriv','lock','#5b6cff','Конфиденциальность','Время захода, звонки, сеансы')}
${srow('sLook','palette','#22a6ff','Оформление',{light:'Светлая тема',dark:'Тёмная тема',auto:'Как в системе'}[themeMode()]+' \u00b7 цвет, фон, текст')}
${srow('sChats','db','#13b0a5','Чаты и данные','Отправка, черновики, память')}
</div>
<div class="setgrp">
${srow('sInvite','userplus','#ff5b8a','Пригласить друзей','Поделиться ссылкой на ваш профиль')}
${srow('sScanQr','qr','#7c5cff','Сканировать QR-код','Открыть профиль человека или войти на компьютере')}
${srow('sAbout','info','#8e8ea8','О Lumo')}
</div>
<div class="setgrp"><div class="set srow" id="sOut" style="color:var(--danger)">${sic('logout','#ff3b5c')}<span class="sl">Выйти из аккаунта</span></div></div>
<div class="sfoot"><span class="betab">БЕТА</span><br>Lumo \u00b7 бета-версия 3.3 \u00b7 сборка 23${ROUTE.via==='proxy'?'<br>Подключение через сервер в России':''}</div>`;
}
else if(pg==='profile'){ loadMyPhone();
  const bd=me.birthday?String(me.birthday).slice(0,10):''; const today=new Date().toISOString().slice(0,10);
  h=`<div class="pex">
<div class="petop2"><button class="pebtn" id="peX" title="Закрыть">${ic('x')}</button>
<div class="peav"><div class="peavi" id="meAv">${avatar({name:me.name,avatar:me.avatar_url,color:me.color},'l')}</div><button class="pelnk" id="sAvBtn">Изменить фотографию</button></div>
<button class="pebtn ok" id="peOk" title="Сохранить">${ic('check')}</button></div>
<div class="pecard"><input class="pein" id="peFirst" placeholder="Имя" maxlength="64" value="${esc(firstName(me))}"><div class="pesep"></div><input class="pein" id="peLast" placeholder="Фамилия" maxlength="64" value="${esc(me.last_name||'')}"></div>
<div class="pehint">Укажите имя и, если хотите, добавьте фотографию для Вашего профиля.</div>
<div class="pecard"><textarea class="pein" id="peBio" rows="2" maxlength="70" placeholder="О себе">${esc(me.bio||'')}</textarea></div>
<div class="pehint">Раздел \u00abО себе\u00bb видят: ${privLabel(myPriv('bio')).toLowerCase()}.<br><a data-pk="bio">Изменить \u203a</a></div>
${(()=>{ const t=document.createElement('template'); t.innerHTML=window.lfRows?window.lfRows():''; const g=id=>{ const e=t.content.getElementById(id); return e?e.outerHTML:''; }; const r=g('tgSStyle')+g('tgSMus'); return r?`<div class="setgrp pesg">${r}</div>`:''; })()}<div class="pecard"><label class="perow">${sic('cake','#3a8dff')}<span class="sl">День рождения</span><span class="peval" id="peBdV">${bd?bdText(bd):'<span style="color:var(--a1)">Указать</span>'}</span><input type="date" id="peBd" value="${bd}" min="1920-01-01" max="${today}"></label></div>
<div class="pehint">Ваш день рождения видят: ${privLabel(myPriv('birthday')).toLowerCase()}.<br><a data-pk="birthday">Изменить \u203a</a><span id="peBdDelW">${bd?' &nbsp;\u00b7&nbsp; <a id="peBdDel">Удалить дату</a>':''}</span></div>
<div class="pecard">${perow('peUser','at','#7c5cff','Имя пользователя','@'+esc(me.username))}<div class="pesep i"></div>${perow('peCol','brush','#3ab8ff','Персональные цвета','')}<div class="pesep i"></div>${perow('peCh','megaphone','#ffa33a','Канал',me.channel_title?esc(me.channel_title):'Добавить')}</div>
<div class="pecard" style="margin-top:22px"><div class="perow" id="pePh">${sic('phone','#2bd67b')}<span class="sl">Номер телефона</span><span class="peval" id="pePhV">${S.myPhone?fmtPh(S.myPhone):'Привязать'}</span><span class="chev">${ic('down','mini rot')}</span></div></div>
<div class="pecard" style="margin-top:22px">${perow('pePw','key','#2bd67b','Пароль','Изменить')}<div class="pesep i"></div>${perow('sLink','link','#3a7bff','Ссылка на профиль','Скопировать')}</div>
<div class="pecard" style="margin-top:22px">${accList().filter(a=>a.id!==me.id).map(a=>`<div class="perow" data-accsw="${a.id}">${avatar({name:a.name,avatar:a.avatar,color:0},'')}<span class="sl">${esc(a.name||'Аккаунт')}<span class="setsub">@${esc(a.username||'')}</span></span><span class="chev">${ic('down','mini rot')}</span></div><div class="pesep"></div>`).join('')}${perow('peAddAcc','userplus','#7c5cff','Добавить аккаунт','')}</div>
<div class="pehint">Без Premium доступен один аккаунт, с Premium — до 3. Переключаться между ними можно здесь.</div>
<div class="pecard" style="margin-top:22px"><div class="perow red" id="sDelAcc">Удалить аккаунт</div></div>
</div>`;
}
else if(pg==='notif'){
  h=`<div class="sethdr">В приложении</div>
<div class="setgrp">
${stog('sSound','volume','#ff8a3d','Звук сообщений','Короткий сигнал о новом сообщении',localStorage.getItem('lm_sound')!=='0')}
${IS_DESKTOP?'':stog('sVibe','phone','#a05bff','Вибрация','При новых сообщениях',localStorage.getItem('lm_vibe')!=='0')}
${IS_DESKTOP?stog('sNotif','bell','#ff5b5b','Уведомления браузера','Когда вкладка Lumo в фоне',window.Notification?.permission==='granted'):''}
</div>
<div class="fhint pad">На iPhone уведомления работают, только если добавить Lumo на главный экран: в Safari нажмите «Поделиться» → «На экран Домой» и открывайте Lumo с иконки. Отключённые чаты (без звука) не присылают уведомлений.</div>`;
}
else if(pg==='premium'){ h=premiumPage(); }
else if(pg==='privacy'){
  h=`<div class="pecard" style="margin-top:8px">${perow('sE2E','lock','#5b6cff','Сквозное шифрование',E2E.label())}</div>
<div class="pecard" style="margin-top:8px">${perow('sLock','lock','#ff8a3d','Блокировка приложения',lockHas()?'Включена':'Выкл.')}</div>
<div class="pecard" style="margin-top:8px">${perow('sBlocked','ban','#ff5b7a','Заблокированные',S.blocks.mine.size?String(S.blocks.mine.size):'Никого')}</div>
<div class="pesec">Конфиденциальность</div>
<div class="pecard">${PRIV_ITEMS.map((it,i)=>`<div class="perow" data-pk="${it[0]}"><span class="sl">${it[1]}</span><span class="peval">${it[0]==='messages'?(myPriv('msg_prem')==='premium'?'Контакты и Premium':'Все'):privLabel(myPriv(it[0]))}</span><span class="chev">${ic('down','mini rot')}</span></div>${i<PRIV_ITEMS.length-1?'<div class="pesep"></div>':''}`).join('')}</div>
<div class="pehint">Вы можете выбрать, кому разрешаете приглашать Вас в группы и каналы.</div>
<div class="pecard">${perow('sOutAll','laptop','#ff3b5c','Выйти на всех устройствах','',false)}</div>
<div class="pehint">Завершит вход везде, включая это устройство.</div>`;
}
else if(pg==='look'){
  const tm=themeMode(), accCur=JSON.parse(localStorage.getItem('lm_accent')||'null')||ACCENTS[0], fs=+(localStorage.getItem('lm_fs')||15), wl0=String(localStorage.getItem('lm_wall')||'0'), wl=wl0[0]==='p'?wl0:+wl0;
  h=`<div class="lkprev" style="background:${wl0[0]==='p'?PREM_WALLS[+wl0.slice(1)]+',var(--panel2)':WALLS[wl]==='none'?'var(--panel2)':WALLS[wl]+',var(--panel2)'}"><div class="lkm in" style="font-size:${fs}px">Привет! Как тебе новый Lumo? \u{1f44b}</div><div class="lkm out" style="font-size:${fs}px">Очень красиво \u{1f60d}</div></div>
<div class="sethdr">Тема</div>
<div class="seg" id="sThemeSeg">${[['light','Светлая','sun'],['dark','Тёмная','moon'],['auto','Как в системе','gear']].map(x=>`<button data-th="${x[0]}" class="${tm===x[0]?'on':''}">${ic(x[2])}<span>${x[1]}</span></button>`).join('')}</div>
<div class="sethdr">Цвет</div>
<div class="setgrp"><div style="padding:10px 4px"><div class="swatches">${ACCENTS.map((a,i)=>`<div class="sw ${a[0]===accCur[0]?'on':''}" data-acc="${i}" style="background:linear-gradient(135deg,${a[0]},${a[1]})"></div>`).join('')}</div></div></div>
<div class="sethdr">Эксклюзивные цвета (Premium)</div>
<div class="setgrp"><div style="padding:10px 4px"><div class="swatches">${PREM_ACCENTS.map((a,i)=>`<div class="sw pr ${a[0]===accCur[0]?'on':''}" data-pacc="${i}" style="background:linear-gradient(135deg,${a[0]},${a[1]})"></div>`).join('')}</div></div></div>
<div class="sethdr">Размер текста <span class="cnt" id="sFsN">${fs}</span></div>
<div class="setgrp"><div class="fsrow"><span style="font-size:13px">A</span><input type="range" id="sFs" min="13" max="20" step="1" value="${fs}"><span style="font-size:20px">A</span></div></div>
<div class="sethdr">Фон чата</div>
<div class="walls">${WALLS.map((w,i)=>`<button class="wl ${i===wl?'on':''}" data-wall="${i}" style="background:${w==='none'?'var(--panel2)':w+',var(--panel2)'}">${i===0?'<span>Без фона</span>':''}</button>`).join('')}</div>
<div class="sethdr">Эксклюзивные фоны (Premium)</div>
<div class="walls">${PREM_WALLS.map((w,i)=>`<button class="wl ${wl===('p'+i)?'on':''}" data-pwall="${i}" style="background:${w},var(--panel2)"></button>`).join('')}</div>`;
}
else if(pg==='chats'){
  h=`<div class="sethdr">Отправка</div>
<div class="setgrp">${IS_DESKTOP?stog('sEnter','send','#3a7bff','Отправка по Enter','Shift+Enter \u2014 новая строка',localStorage.getItem('lm_enter')!=='0'):srow('','send','#3a7bff','Голосовые и кружки','Удерживайте кнопку \u2014 запись, вверх \u2014 закрепить, влево \u2014 отмена','')}</div>
<div class="sethdr">Данные</div>
<div class="setgrp">
${srow('sDrafts','edit','#ff8a3d','Очистить черновики','Удалить несохранённые тексты во всех чатах','')}
${srow('sCache','db','#13b0a5','Очистить кэш','Недавние эмодзи и временные данные <span id="sMem"></span>','')}
</div>`;
}
else if(pg==='devices'){
  h=`<div id="devList"></div><div class="sethdr">Это устройство</div>
<div class="setgrp"><div class="set srow">${sic(IS_DESKTOP?'laptop':'phone','#2bd67b')}<span class="sl">${esc(devName())}<span class="setsub" style="color:var(--ok)">в сети</span></span></div></div>
<div class="setgrp">${srow('sQr','qr','#7c5cff',IS_DESKTOP?'Подключить устройство':'Подключить компьютер',IS_DESKTOP?'Отсканируйте QR-код на другом устройстве':'Откройте Lumo на компьютере и наведите камеру на QR-код',`<span class="slink">Сканировать</span>`)}</div>
<div class="setgrp">${srow('sOutAll','logout','#ff3b5c','Выйти на всех устройствах','Потребуется войти заново','')}</div>`;
}
else if(pg==='about'){
  h=`<div class="about"><div class="mark big">${ic('chat')}</div><h2>Lumo</h2><div class="st">Быстрый и красивый мессенджер</div></div>
<div class="setgrp">
${srow('','chat','#7c5cff','Чаты, группы и каналы','Реакции, ответы, пересылка, закрепление','')}
${srow('','mic','#ff5b8a','Голосовые и видеосообщения','Удерживайте кнопку справа от поля ввода','')}
${srow('','phone','#2bd67b','Звонки и видеозвонки','Обычная и громкая связь','')}
${srow('','qr','#ff8a3d','Вход на компьютере','По QR-коду из \u00abУстройств\u00bb','')}
${S.bot?srow('sBotLink','send','#2aabee','Бот уведомлений','@'+esc(S.bot),`<span class="chev">${ic('down','mini rot')}</span>`):''}
</div>`;
}
if(pg==='pk'){ const it=PRIV_ITEMS.find(x=>x[0]===SP.key)||PRIV_ITEMS[0]; const curv=myPriv(it[0]); const opts=['all','contacts'].concat(it[4]?['none']:[]);
  h=`<div class="pesec">${it[2]}</div><div class="pecard">${opts.map((v,i)=>`<div class="perow" data-pkv="${v}"><span class="sl">${v==='contacts'?'Мои контакты':privLabel(v)}</span>${curv===v?`<span class="pechk">${ic('check')}</span>`:''}</div>${i<opts.length-1?'<div class="pesep"></div>':''}`).join('')}</div><div class="pehint">${esc(it[3])}</div>`; }
if(pg==='msgp'){ const pr=myPriv('msg_prem')==='premium'?'premium':'all'; if(S.paidPrice===undefined){ S.paidPrice=0; sb.rpc('lm_paid_get').then(({data})=>{ S.paidPrice=+data||0; if(SP.page==='msgp') renderSettings(); }); } const chk=`<span class="pechk">${ic('check')}</span>`;
  h=`<div class="pesec">Кто может отправлять мне сообщения</div><div class="pecard"><div class="perow" data-mp="all"><span class="sl">Все</span>${pr==='all'?chk:''}</div><div class="pesep"></div><div class="perow" data-mp="premium"><span class="sl">Контакты и Premium-подписчики</span>${pr==='premium'?chk:''}</div></div>
<div class="pehint">Вы можете запретить входящие сообщения от пользователей, которых нет в Вашем списке контактов и которым Вы не писали сами.</div>
<div class="pesec">Платные сообщения</div><div class="pecard"><div style="display:flex;flex-wrap:wrap;gap:8px;padding:12px 14px">${[[0,'Бесплатно'],[5,'5'],[10,'10'],[25,'25'],[50,'50'],[100,'100']].map(x=>`<button class="btn ${S.paidPrice===x[0]?'primary':'ghost'}" data-pp="${x[0]}">${x[1]}</button>`).join('')}</div></div>
<div class="pehint">Незнакомые люди смогут написать вам только за люмены, а вы получите оплату. Контакты и те, с кем вы уже переписываетесь, пишут бесплатно.</div>`; }
if(pg==='phone'){ loadMyPhone(); const pp=S.myPhone;
  h=`<div style="text-align:center;padding:26px 28px 6px"><svg width="150" height="150" viewBox="0 0 150 150"><circle cx="75" cy="75" r="72" fill="var(--a1)" opacity=".14"/><rect x="38" y="22" width="64" height="104" rx="16" transform="rotate(-8 70 74)" fill="#5b7bff"/><rect x="46" y="32" width="48" height="80" rx="8" transform="rotate(-8 70 74)" fill="#fff" opacity=".22"/><rect x="86" y="70" width="40" height="52" rx="7" transform="rotate(10 106 96)" fill="#fff"/><rect x="97" y="86" width="20" height="16" rx="3" transform="rotate(10 106 96)" fill="#f5c542"/></svg>
<div style="font-size:26px;font-weight:800;margin-top:12px">${pp?fmtPh(pp):'Номер не привязан'}</div>
<div style="color:var(--muted);font-size:14.5px;margin-top:8px;line-height:1.4">${pp?'Здесь Вы можете сменить номер телефона. Ваш аккаунт и все данные (сообщения, медиа, контакты и т. д.) будут перенесены на новый номер.':'Привяжите номер для входа и защиты аккаунта. Ваши данные останутся на месте.'}</div></div>
<div class="pecard" style="margin-top:22px"><div class="perow" id="phChange" style="justify-content:center;color:var(--a1);font-weight:600"><span>${pp?'Изменить номер':'Привязать номер'}</span></div></div>`; }
if(pg==='uname'){ h=`<div class="pecard" style="margin-top:12px"><div class="perow" style="cursor:text"><span style="color:var(--muted)">@</span><input class="pein" id="unIn" style="padding-left:0" value="${esc(me.username)}" maxlength="32" autocapitalize="off" spellcheck="false"></div></div>
<div class="pehint">Латинские буквы, цифры и _, от 3 до 32 символов. По этому имени вас смогут найти в Lumo.<br>Ссылка: <span id="unLink">${esc(location.origin+location.pathname+'#@'+me.username)}</span></div>
<div style="padding:0 16px"><button class="btn primary w" id="unSave">Сохранить</button></div>`; }
if(pg==='colors'){ const cc=SP.color??me.color;
  h=`<div class="pecard" style="margin-top:12px"><div class="peprev">${avatar({name:me.name,color:cc},'')}<div class="bub"><b style="color:${['#ff7a6b','#a48bff','#36b8ff','#25c99a','#f0a23a','#ff5b9a','#6aa8ff','#52c46e'][(cc%8+8)%8]}">${esc(me.name)}</b>Так ваше имя выглядит в группах</div></div></div>
<div class="pehint">Цвет используется для кружка с инициалами и вашего имени в группах.</div>
<div class="pecard"><div class="pecolors">${[0,1,2,3,4,5,6,7].map(i=>`<b data-col="${i}" class="c${i} ${i===cc?'on':''}">${i===cc?ic('check'):''}</b>`).join('')}</div></div>
<div style="padding:18px 16px 0"><button class="btn primary w" id="colSave">Сохранить</button></div>`; }
$('#pane').innerHTML=`<div class="spage ${pg==='main'?'smain':'sinner'}">${head}${h}</div>`;
bindSettings(pg);
}
const ACC_KEY='lm_accounts', SB_KEY='sb-foniukmpiukuwpcdvdhp-auth-token';
function accList(){ try{ return JSON.parse(localStorage.getItem(ACC_KEY)||'[]'); }catch{ return []; } }
function accSave(l){ try{ localStorage.setItem(ACC_KEY,JSON.stringify(l)); }catch{} }
function accLimit(){ return S.me&&S.me.premium?3:1; }
function accStoreCurrent(){ try{ const raw=localStorage.getItem(SB_KEY); if(!raw||!S.me) return; const s=JSON.parse(raw); if(!s.access_token||!s.refresh_token) return;
  const l=accList(); const i=l.findIndex(a=>a.id===S.me.id); const e={id:S.me.id,name:S.me.name,username:S.me.username,avatar:S.me.avatar_url||null,access:s.access_token,refresh:s.refresh_token}; if(i>=0) l[i]=e; else l.push(e); accSave(l); }catch{} }
async function accSwitch(id){ accStoreCurrent(); const a=accList().find(x=>x.id===id); if(!a) return;
  const {error}=await sb.auth.setSession({access_token:a.access,refresh_token:a.refresh});
  if(error){ accSave(accList().filter(x=>x.id!==id)); toast('Сеанс этого аккаунта истёк — войдите в него заново'); if(S.me) renderSettings(); return; }
  try{ localStorage.setItem('lm_sess_active','0'); }catch{} location.reload(); }
function accAdd(){ if(accList().length>=accLimit()){ const pr=!!(S.me&&S.me.premium); modal('Достигнут лимит',`<p style="margin:4px 0 8px;line-height:1.45">${pr?'Можно подключить не больше 3 аккаунтов.':'Без Premium можно подключить 1 аккаунт, с Premium — до 3. Чтобы увеличить лимит, оформите Lumo Premium.'}</p>`,pr?[['Ок','primary',c=>c()]]:[['Закрыть','ghost'],['Увеличить лимит','primary',c=>{ c(); try{ openPremium(); }catch{} }]]); return; }
  accStoreCurrent(); try{ localStorage.removeItem(SB_KEY); localStorage.setItem('lm_sess_active','0'); }catch{} location.reload(); }
function accBackLink(){ try{ const au=document.getElementById('auth'); const need=!S.me&&accList().length>0&&au&&!au.classList.contains('hidden'); let b=document.getElementById('accBack');
  if(need&&!b){ b=document.createElement('button'); b.id='accBack'; b.className='btn ghost'; b.style.cssText='position:fixed;top:12px;left:12px;z-index:99999'; b.textContent='‹ Вернуться в аккаунт'; b.onclick=()=>accSwitch(accList()[0].id); document.body.appendChild(b); }
  else if(!need&&b) b.remove(); }catch{} }
setInterval(accBackLink,1500);
function webDevId(){ try{ let d=localStorage.getItem('lm_device_id'); if(!d){ d=(window.crypto&&crypto.randomUUID)?crypto.randomUUID():('w'+Date.now()+Math.random().toString(36).slice(2)); localStorage.setItem('lm_device_id',d); } return d; }catch{ return 'web-anon'; } }
let _webSessT=null;
async function webSession(){ try{
  let fresh=true; try{ fresh=localStorage.getItem('lm_sess_active')!=='1'; }catch{}
  const {data,error}=await sb.rpc('lm_session_touch',{p_device:webDevId(),p_name:devName(),p_platform:'web',p_version:'3.3',p_fresh:fresh});
  if(error) return;
  if(data&&data.revoked){ try{ localStorage.setItem('lm_sess_active','0'); }catch{} await sb.auth.signOut({scope:'local'}); location.reload(); return; }
  try{ localStorage.setItem('lm_sess_active','1'); }catch{}
  accStoreCurrent();
  if(!_webSessT) _webSessT=setInterval(webSession,120000);
 }catch{} }
async function webPhoneGate(){ try{ const {data}=await sb.rpc('lm_my_phone'); const o=Array.isArray(data)?data[0]:data; if(!o) return; S.myPhone=o.phone||null;
  if(o.status==='required'){ phoneFlow(true); return; }
  if((o.status==='remind'||o.status==='skipped')&&!sessionStorage.getItem('lm_ph_rem')){ sessionStorage.setItem('lm_ph_rem','1');
   modal('Привяжите номер телефона',`<p style="margin:4px 0 8px;line-height:1.45">${o.status==='remind'?'Теперь в Lumo можно входить по номеру и защитить аккаунт кодом. Привязать номер нужно в течение 7 дней.':'Привяжите номер, иначе пользоваться Lumo скоро будет нельзя.'}</p>`,[[o.status==='remind'?'Напомнить через 7 дней':'Позже','ghost',async c=>{ if(o.status==='remind'){ try{ await sb.rpc('lm_phone_skip'); }catch{} } c(); }],['Привязать номер','primary',c=>{ c(); phoneFlow(); }]]); }
 }catch{} }
async function loadDevList(){ const box=document.getElementById('devList'); if(!box) return; try{
  const {data,error}=await sb.from('lm_sessions').select('id,device_id,name,platform,last_active,revoked').order('last_active',{ascending:false}); if(error||!data) return;
  const me=webDevId(); const rows=data.filter(r=>!r.revoked&&r.device_id!==me);
  if(!rows.length){ box.innerHTML=''; return; }
  const fmt=d=>{ const t=new Date(d); return isNaN(t)?'':t.toLocaleString('ru-RU',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'}); };
  box.innerHTML=`<div class="sethdr">Активные сеансы</div><div class="setgrp">${rows.map(r=>`<div class="set srow">${sic(r.platform==='web'?'laptop':'phone','#3a7bff')}<span class="sl">${esc(r.name||'Устройство')}<span class="setsub">${r.platform==='web'?'Сайт':r.platform==='ios'?'iPhone':'Android'} · ${fmt(r.last_active)}</span></span><span class="slink" data-kill="${r.id}" style="color:var(--danger);cursor:pointer">Завершить</span></div>`).join('')}</div>`;
  box.querySelectorAll('[data-kill]').forEach(el=>el.onclick=async()=>{ const {error:e2}=await sb.rpc('lm_session_kill',{p_id:el.dataset.kill}); if(e2) return toast(e2.message); toast('Сеанс завершён'); loadDevList(); });
 }catch{} }
function fmtPh(p){ return p&&p.length===11?`+7 ${p.slice(1,4)} ${p.slice(4,7)} ${p.slice(7,9)} ${p.slice(9)}`:''; }
function loadMyPhone(){ if(S.myPhone!==undefined) return; S.myPhone=null; sb.rpc('lm_my_phone').then(({data})=>{ const o=Array.isArray(data)?data[0]:data; S.myPhone=(o&&o.phone)||null; const v=document.getElementById('pePhV'); if(v) v.textContent=S.myPhone?fmtPh(S.myPhone):'Привязать'; if(S.tab==='settings'&&SP.page==='phone') renderSettings(); }); }
function phoneFlow(req){ const E={bad_phone:'Введите российский номер мобильного телефона',bad_code:'Неверный код',expired:'Код устарел — запросите новый',locked:'Слишком много попыток — запросите новый код',too_many:'Слишком много кодов. Попробуйте через час',wait:'Новый код можно запросить через минуту',busy:'Сервис занят, попробуйте позже',sms_off:'Отправка кодов пока недоступна',sms_fail:'Отправка кодов пока недоступна',phone_taken:'Этот номер уже привязан к другому аккаунту',banned:'Аккаунт заблокирован'};
 const call=async(path,body)=>{ const {data:{session}}=await sb.auth.getSession(); const r=await fetch(SUPABASE_URL+'/functions/v1/lumo-phone/'+path,{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+(session?.access_token||''),apikey:SUPABASE_KEY},body:JSON.stringify(body)}); return r.json().catch(()=>({})); };
 let close=modal(req?'Привяжите номер телефона':S.myPhone?'Новый номер':'Привязать номер',`<div class="field"><input class="inp" id="phIn" inputmode="numeric" maxlength="18" placeholder="+7 900 000 00 00" autocomplete="tel"></div><div id="phMsg" class="pehint" style="padding:0 2px 10px"></div><button class="btn primary w" id="phGo">Получить код</button>`);
 if(req){ const ov=[...document.querySelectorAll('.ov')].pop(); const nb=ov.cloneNode(true); const x=nb.querySelector('[data-x]'); if(x) x.remove(); ov.replaceWith(nb); close=()=>nb.remove(); }
 const g=id=>document.getElementById(id); let full='',stage=0;
 g('phGo').onclick=async()=>{ const b=g('phGo'), msg=g('phMsg'); b.disabled=true; msg.textContent='';
  try{
   if(stage===0){ let d=g('phIn').value.replace(/\D/g,''); if(d.length===11&&(d[0]==='7'||d[0]==='8')) d=d.slice(1); if(d.length!==10){ msg.textContent=E.bad_phone; return; } full='7'+d;
    const j=await call('send',{phone:full,purpose:'bind'}); if(j.error){ msg.textContent=E[j.error]||'Не удалось выполнить действие'; return; }
    stage=1; g('phIn').value=''; g('phIn').placeholder='Код подтверждения'; g('phIn').maxLength=8; g('phIn').focus(); b.textContent='Подтвердить';
    msg.innerHTML=j.channel==='telegram'?(j.link&&!j.direct?`Код придёт в Telegram: <a href="${esc(j.link)}" target="_blank" rel="noopener">открыть бота</a>`:'Код отправлен вам в Telegram'):'Код отправлен в SMS на '+fmtPh(full);
   } else { const j=await call('verify',{phone:full,code:g('phIn').value.trim(),purpose:'bind'}); if(j.error){ msg.textContent=E[j.error]||'Не удалось выполнить действие'; return; }
    if(j.need_tfa){ msg.textContent='На этом номере включена двухэтапная защита. Привяжите его в приложении Lumo'; return; }
    S.myPhone=full; close(); if(SP.page==='phone') renderSettings(); toast('Номер сохранён'); }
  }catch(e){ msg.textContent='Нет соединения. Попробуйте ещё раз'; } finally{ b.disabled=false; } };
}
function bindSettings(pg){
const me=S.me, on=(id,f)=>{ const e=$('#'+id); if(e) e.onclick=f; }; if(pg==='devices') loadDevList(); document.querySelectorAll('[data-accsw]').forEach(el=>el.onclick=()=>accSwitch(el.dataset.accsw)); on('peAddAcc',accAdd); on('mAddAcc',accAdd);
on('spBack',()=>setSPage(pg==='pk'?SP.back||'privacy':pg==='msgp'?'privacy':(pg==='uname'||pg==='colors'||pg==='phone')?'profile':'main'));
// изменение профиля
on('peX',()=>setSPage('main')); on('pePh',()=>setSPage('phone')); on('phChange',phoneFlow);
document.querySelectorAll('[data-mp]').forEach(el=>el.onclick=async()=>{ const v=el.dataset.mp; if(v==='premium'&&!premOk()) return; const {error}=await sb.rpc('lm_set_privacy',{p_key:'msg_prem',p_value:v}); if(error) return toast(error.message); await refreshMe(); renderSettings(); });
document.querySelectorAll('[data-pp]').forEach(el=>el.onclick=async()=>{ const v=+el.dataset.pp; if(v>0&&!premOk()) return; const {error}=await sb.rpc('lm_paid_set',{p_price:v}); if(error) return toast(error.message); S.paidPrice=v; renderSettings(); toast(v?('Цена сообщения: '+v):'Платные сообщения выключены'); });
document.querySelectorAll('[data-pk]').forEach(el=>el.onclick=()=>{ SP.key=el.dataset.pk; SP.back=pg; setSPage(SP.key==='messages'?'msgp':'pk'); });
document.querySelectorAll('[data-pkv]').forEach(el=>el.onclick=async()=>{ const v=el.dataset.pkv; try{ navigator.vibrate?.(8); }catch{}
  document.querySelectorAll('[data-pkv]').forEach(x=>{ const c=x.querySelector('.pechk'); if(c) c.remove(); }); el.insertAdjacentHTML('beforeend',`<span class="pechk">${ic('check')}</span>`);
  const {error}=await sb.rpc('lm_set_privacy',{p_key:SP.key,p_value:v}); if(error) return toast(error.message); await refreshMe(); toast('Сохранено'); });
const bdIn=$('#peBd'); if(bdIn){ bdIn.onchange=()=>{ $('#peBdV').innerHTML=bdIn.value?esc(bdText(bdIn.value)):'<span style="color:var(--a1)">Указать</span>'; $('#peBdDelW').innerHTML=bdIn.value?' &nbsp;\u00b7&nbsp; <a id="peBdDel">Удалить дату</a>':''; on('peBdDel',bdDel); }; }
const bdDel=()=>{ if(bdIn){ bdIn.value=''; bdIn.onchange(); } }; on('peBdDel',bdDel);
on('peOk',async()=>{ const f=$('#peFirst').value.trim(), l=$('#peLast').value.trim(); if(!f) return toast('Укажите имя');
  const b=$('#peOk'); b.style.opacity=.6;
  const {error}=await sb.from('lm_profiles').update({name:[f,l].filter(Boolean).join(' '),last_name:l,bio:$('#peBio').value.trim().slice(0,70),birthday:bdIn&&bdIn.value?bdIn.value:null}).eq('id',me.id);
  b.style.opacity=''; if(error) return toast(error.message); await refreshMe(); toast('Сохранено'); setSPage('main'); });
on('peUser',()=>setSPage('uname')); on('peCol',()=>{ SP.color=undefined; setSPage('colors'); });
on('peCh',()=>{ const mine=S.chats.filter(c=>c.type==='channel'&&c.role==='owner');
  const body=mine.length?mine.map(c=>`<div class="row" data-chp="${c.chat_id}">${chatAv(c,'s')}<div class="mid"><div class="t1"><span class="nm">${esc(chatName(c))}</span>${S.me.channel_id===c.chat_id?`<span class="pechk">${ic('check')}</span>`:''}</div></div></div>`).join(''):'<p style="color:var(--muted)">У вас пока нет своих каналов. Создайте канал \u2014 и его можно будет показать в профиле.</p>';
  const close=modal('Канал в профиле',`<div id="chpl">${body}</div>`,S.me.channel_id?[['Убрать из профиля','danger',async c=>{ c(); await sb.from('lm_profiles').update({channel_id:null}).eq('id',me.id); await refreshMe(); renderSettings(); }]]:[]);
  $('#chpl').onclick=async e=>{ const r=e.target.closest('[data-chp]'); if(!r) return; close(); const {error}=await sb.from('lm_profiles').update({channel_id:r.dataset.chp}).eq('id',me.id); if(error) return toast(error.message); await refreshMe(); renderSettings(); toast('Канал добавлен в профиль'); }; });
on('pePw',()=>{ const close=modal('Новый пароль',`<div class="field"><input class="inp" id="pw1" type="password" autocomplete="new-password" placeholder="Минимум 6 символов"></div><div class="field"><input class="inp" id="pw2" type="password" autocomplete="new-password" placeholder="Ещё раз"></div>`,
  [['Отмена','ghost'],['Сохранить','primary',async c=>{ const a=$('#pw1').value, b2=$('#pw2').value; if(a.length<6) return toast('Пароль \u2014 минимум 6 символов'); if(a!==b2) return toast('Пароли не совпадают');
    const {error}=await sb.auth.updateUser({password:a}); if(error) return toast(error.message); c(); toast('Пароль изменён'); }]]); });
const unIn=$('#unIn'); if(unIn) unIn.oninput=()=>{ $('#unLink').textContent=location.origin+location.pathname+'#@'+unIn.value.trim().toLowerCase(); };
on('unSave',async()=>{ const un=unIn.value.trim().toLowerCase().replace(/^@/,''); if(un===me.username) return setSPage('profile');
  if(!/^[a-z0-9_]{3,32}$/.test(un)) return toast('Юзернейм: 3\u201332 символа, латиница, цифры и _');
  const {error}=await sb.rpc('lm_set_username',{p_username:un}); if(error) return toast(error.message); await refreshMe(); toast('Сохранено'); setSPage('profile'); });
document.querySelectorAll('[data-col]').forEach(el=>el.onclick=()=>{ SP.color=+el.dataset.col; renderSettings(); });
on('colSave',async()=>{ const c=SP.color??me.color; const {error}=await sb.from('lm_profiles').update({color:c}).eq('id',me.id); if(error) return toast(error.message); await refreshMe(); toast('Цвет сохранён'); setSPage('profile'); });
const av=()=>pickAvatar(async url=>{ const {error}=await sb.from('lm_profiles').update({avatar_url:url}).eq('id',me.id); if(!error){ await refreshMe(); renderSettings(); toast('Фото обновлено'); } });
const avMenu=e=>{ if(pg!=='profile'||!me.avatar_url) return av(); e?.stopPropagation?.(); dropMenu(e.currentTarget,[['image','Выбрать фото',av],['trash','Удалить фото',async()=>{ const {error}=await sb.from('lm_profiles').update({avatar_url:null}).eq('id',me.id); if(error) return toast(error.message); await refreshMe(); renderSettings(); toast('Фото удалено'); },'red']]); };
on('meAv',avMenu); on('sAvBtn',avMenu);
on('sAvDel',()=>confirmBox('Удалить фото профиля?','Удалить',async()=>{ const {data,error}=await sb.from('lm_profiles').update({avatar_url:null}).eq('id',me.id).select().single(); if(error) return toast(error.message); S.me=data; S.profiles.set(data.id,data); renderSettings(); toast('Фото удалено'); }));
on('sAdmin',()=>openAdmin()); on('sPrem',openPremium); on('sLock',lockDlg); on('sMsgP',async()=>{ if(!premOk()) return; const on1=myPriv('msg_prem')==='premium'; const {error}=await sb.rpc('lm_set_privacy',{p_key:'msg_prem',p_value:on1?'all':'premium'}); if(error) return toast(error.message); await refreshMe(); renderSettings(); toast(on1?'Ограничение выключено':'Теперь вам могут писать только пользователи Premium'); }); { const pb=document.querySelector('.shero .prembadge'); if(pb) pb.onclick=emojiStatusDlg; } if(pg==='premium') bindPremium(); on('sMyQr',showMyQr); on('sScanQr',qrScan); on('sBlocked',blockedDlg); on('sE2E',()=>E2E.open()); on('sDelAcc',deleteAccountDlg);
on('sEdit',()=>setSPage('profile')); on('sProf',()=>setSPage('profile')); on('sNotifP',()=>setSPage('notif')); on('sPriv',()=>setSPage('privacy'));
on('sLook',()=>setSPage('look')); on('sChats',()=>setSPage('chats')); on('sDev',()=>setSPage('devices')); on('sAbout',()=>setSPage('about'));
on('sSaved',()=>{ setTab('chats'); openDM(S.me.id); }); on('sCalls',()=>setTab('contacts')); on('sQr',qrScan);
on('sOut',()=>confirmBox('Выйти из аккаунта?','Выйти',()=>{ try{ accSave(accList().filter(a=>a.id!==S.me.id)); }catch{} logout(); }));
on('sOutAll',()=>confirmBox('Завершить сеансы Lumo на всех устройствах, включая это?','Выйти везде',async()=>{ try{ await sb.auth.signOut({scope:'global'}); }catch{} location.reload(); }));
const link=location.origin+location.pathname+'#@'+me.username;
on('sInvite',async()=>{ try{ if(navigator.share){ await navigator.share({title:'Lumo',text:'Пиши мне в Lumo',url:link}); return; } }catch{} navigator.clipboard?.writeText(link); toast('Ссылка скопирована \u2014 отправьте её другу'); });
on('sLink',()=>{ navigator.clipboard?.writeText(link); toast('Ссылка скопирована'); });
on('sBotLink',()=>window.open('https://t.me/'+S.bot,'_blank'));
// профиль
const bio=$('#sBio'); if(bio) bio.oninput=()=>{ $('#sBioN').textContent=bio.value.length+'/200'; };
on('sSave',async()=>{ const name=$('#sName').value.trim(), un=$('#sUser').value.trim().toLowerCase().replace(/^@/,''); if(!name) return toast('Укажите имя');
  const b=$('#sSave'); b.classList.add('loading');
  try{ if(un!==me.username){ if(!/^[a-z0-9_]{3,32}$/.test(un)) throw new Error('Юзернейм: 3\u201332 символа, латиница, цифры и _'); const {error}=await sb.rpc('lm_set_username',{p_username:un}); if(error) throw new Error(error.message); }
    const {data,error}=await sb.from('lm_profiles').update({name,bio:$('#sBio').value.trim()}).eq('id',me.id).select().single(); if(error) throw new Error(error.message);
    S.me=data; S.profiles.set(data.id,data); toast('Профиль сохранён'); setSPage('main'); }
  catch(e){ b.classList.remove('loading'); toast(e.message); } });
on('sPwBtn',async()=>{ const a=$('#sPw1').value, c=$('#sPw2').value; if(a.length<6) return toast('Пароль \u2014 минимум 6 символов'); if(a!==c) return toast('Пароли не совпадают');
  const {error}=await sb.auth.updateUser({password:a}); if(error) return toast(error.message); $('#sPw1').value=$('#sPw2').value=''; toast('Пароль установлен'); });
// уведомления
const tgl=(id,key)=>on(id,()=>{ const v=localStorage.getItem(key)==='0'; localStorage.setItem(key,v?'1':'0'); $('#'+id+' .tog').classList.toggle('on',v); });
tgl('sSound','lm_sound'); tgl('sVibe','lm_vibe'); tgl('sEnter','lm_enter');
on('sNotif',async()=>{ await askNotif(); $('#sNotif .tog')?.classList.toggle('on',window.Notification?.permission==='granted'); });
if(pg==='notif') bindTg();
// конфиденциальность
document.querySelectorAll('.sradio').forEach(el=>el.onclick=async()=>{ const n=el.dataset.r, v=el.dataset.v; const upd=n==='seen'?{show_seen:v==='1'}:{calls_from:v};
  document.querySelectorAll(`.sradio[data-r="${n}"]`).forEach(x=>x.classList.toggle('on',x===el)); try{ navigator.vibrate?.(8); }catch{}
  const {data,error}=await sb.from('lm_profiles').update(upd).eq('id',me.id).select().single(); if(error) return toast(error.message); S.me=data; S.profiles.set(data.id,data); toast('Сохранено'); });
// оформление
document.querySelectorAll('#sThemeSeg button').forEach(b=>b.onclick=()=>{ const t=b.dataset.th; if(t==='auto') localStorage.removeItem('lm_theme'); else localStorage.setItem('lm_theme',t); applyTheme(); updateTabBadges(); renderSettings(); });
document.querySelectorAll('[data-acc]').forEach(el=>el.onclick=()=>{ setAccent(ACCENTS[+el.dataset.acc]); document.querySelectorAll('[data-acc]').forEach(x=>x.classList.toggle('on',x===el)); });
const fs=$('#sFs'); if(fs) fs.oninput=()=>{ localStorage.setItem('lm_fs',fs.value); $('#sFsN').textContent=fs.value; document.querySelectorAll('.lkm').forEach(m=>m.style.fontSize=fs.value+'px'); applyLook(); };
document.querySelectorAll('[data-wall]').forEach(el=>el.onclick=()=>{ localStorage.setItem('lm_wall',el.dataset.wall); applyLook(); renderSettings(); });
document.querySelectorAll('[data-pwall]').forEach(el=>el.onclick=()=>{ if(!premOk()) return; localStorage.setItem('lm_wall','p'+el.dataset.pwall); applyLook(); renderSettings(); });
document.querySelectorAll('[data-pacc]').forEach(el=>el.onclick=()=>{ if(!premOk()) return; setAccent(PREM_ACCENTS[+el.dataset.pacc]); renderSettings(); });
// чаты и данные
on('sDrafts',()=>confirmBox('Удалить черновики во всех чатах?','Удалить',()=>{ Object.keys(localStorage).filter(k=>/draft/i.test(k)).forEach(k=>localStorage.removeItem(k)); toast('Черновики удалены'); }));
on('sCache',()=>{ ['lm_recent','lm_nc_hide','lm_tgc_hide','lm_calls_seen'].forEach(k=>localStorage.removeItem(k)); try{ caches?.keys().then(ks=>ks.forEach(k=>caches.delete(k))); }catch{} toast('Кэш очищен'); renderSettings(); });
if(pg==='chats'&&navigator.storage?.estimate) navigator.storage.estimate().then(e=>{ const el=$('#sMem'); if(el&&e.usage) el.textContent='\u00b7 '+(e.usage/1048576).toFixed(1)+' МБ'; }).catch(()=>{});
}
$('#pane').addEventListener('click',async e=>{
const t=e.target;
const add=t.closest('[data-cadd]'); if(add){ e.stopPropagation(); return addContact(add.dataset.cadd); }
const rc=t.closest('[data-recall]'); if(rc){ e.stopPropagation(); return callChat(rc.dataset.recall,!!rc.dataset.v); }
const dm=t.closest('[data-cdm]'); if(dm){ e.stopPropagation(); return openDM(dm.dataset.cdm); }
if(t.closest('#cSync')) return syncContacts();
const iv=t.closest('[data-inv]'); if(iv){ e.stopPropagation(); return invite(iv.dataset.inv); }
if(t.closest('#cInvite')){ navigator.clipboard?.writeText(location.origin+location.pathname+'#@'+S.me.username); return toast('Ссылка на ваш профиль скопирована \u2014 отправьте её другу'); }
const pr=t.closest('[data-person]'); if(pr) return openUser(pr.dataset.person);
const cc=t.closest('[data-callchat]'); if(cc) return openChat(cc.dataset.callchat);
});
$('#pane').addEventListener('contextmenu',e=>{ const pr=e.target.closest('[data-person]'); if(!pr||!isContact(pr.dataset.person)) return; e.preventDefault(); personMenu(pr); });
let pLp; $('#pane').addEventListener('touchstart',e=>{ const pr=e.target.closest('[data-person]'); if(!pr||!isContact(pr.dataset.person)) return; pLp=setTimeout(()=>{ navigator.vibrate?.(15); personMenu(pr); },450); },{passive:true});
['touchend','touchmove'].forEach(ev=>$('#pane').addEventListener(ev,()=>clearTimeout(pLp),{passive:true}));
async function personMenu(row){ const id=row.dataset.person;
const dmId=async()=>{ const {data}=await sb.rpc('lm_open_dm',{p_other:id}); await loadChats(); return data; };
dropMenu(row,[['chat','Написать',()=>openDM(id)],['phone','Позвонить',async()=>callChat(await dmId(),false)],['video','Видеозвонок',async()=>callChat(await dmId(),true)],['userx','Удалить из контактов',()=>removeContact(id),'red']]); }
/* ================= OPEN CHAT ================= */
async function openChat(id){
if(!S.chatMap.has(id)) await loadChats();
const c=S.chatMap.get(id); if(!c) return;
if(S.cur && S.cur!==id) saveDraft();
if(S.sel) selEnd(); S.cur=id; S.reply=null; S.edit=null; S.unreadBelow=0; closeEmoji(); closeInSearch();
if(innerWidth<=800&&!(history.state&&history.state.lumoChat)){ try{ history.pushState({lumoChat:1},''); }catch{} }
$('#app').classList.add('inchat'); $('#empty').classList.add('hidden'); $('#chat').classList.remove('hidden'); { const ch=$('#chat'); ch.classList.remove('cin'); void ch.offsetWidth; ch.classList.add('cin'); }
applyBub(id); renderList(); renderHead(); renderCtx(); loadDraft(); updateComposer(); subscribeTyping(id); if(S.chatMap.get(id)?.type==='private') loadBlocks();
if(!$('#info').classList.contains('hidden')) renderInfo();
$('#mw').innerHTML='';
await loadMembers(id);
if(!S.msgs.has(id)) await loadMessages(id);
if(S.cur!==id) return;
renderPin(); renderMsgs(true); markRead();
if(innerWidth>800) $('#txt').focus({preventScroll:true});
}
async function loadMembers(id){
const {data}=await sb.from('lm_members').select('user_id,role,last_read_at,muted,cleared_at').eq('chat_id',id);
{ const mine=(data||[]).find(m=>m.user_id===S.me.id); if(mine&&mine.cleared_at) S.cleared.set(id,mine.cleared_at); else S.cleared.delete(id); }
const need=(data||[]).map(m=>m.user_id).filter(u=>u!==S.me.id);
if(need.length){ await profGet(need); }
S.members.set(id,data||[]);
}
const PAGE=50;
async function loadMessages(id, beforeId){
let q=sb.from('lm_messages').select('*').eq('chat_id',id).eq('deleted',false).order('id',{ascending:false}).limit(PAGE);
if(S.cleared.get(id)) q=q.gt('created_at',S.cleared.get(id));
if(beforeId) q=q.lt('id',beforeId);
const {data,error}=await q;
if(error){
if(!beforeId&&!S.msgs.has(id)){ const cached=await ccGet('msgs',id); if(cached&&cached.length){ S.msgs.set(id,cached); S.more.set(id,false); if(id===S.cur) renderMsgs(true); } }
toast(error.message); return [];
}
await E2E.ready(); await E2E.prepChat(id); await E2E.decAll(data);
// удалённые только у меня
try{ const {data:hd}=await sb.from('lm_hidden').select('message_id').eq('chat_id',id); (hd||[]).forEach(r=>S.hidden.add(r.message_id)); }catch{}
const arr=(data||[]).reverse().filter(m=>!S.hidden.has(m.id));
const old=S.msgs.get(id)||[]; S.msgs.set(id, beforeId?[...arr,...old]:arr); S.more.set(id, data.length===PAGE);
// senders & reply targets
const need=[...new Set(arr.map(m=>m.sender_id).filter(u=>u&&!S.profiles.has(u)))];
if(need.length){ await profGet(need); }
const ids=arr.map(m=>m.id); if(ids.length){ const {data:rs}=await sb.from('lm_reactions').select('message_id,user_id,emoji').in('message_id',ids); (rs||[]).forEach(addReact); }
const have=new Set(S.msgs.get(id).map(m=>m.id)); const missing=[...new Set(arr.map(m=>m.reply_to).filter(r=>r&&!have.has(r)))];
if(missing.length){ const {data:rm}=await sb.from('lm_messages').select('*').in('id',missing); await E2E.decAll(rm); (rm||[]).forEach(m=>replyCache.set(m.id,m)); }
if(!beforeId) ccSet('msgs',id,S.msgs.get(id).slice(-80));
if(!beforeId&&id===S.cur) updateComposer();
return arr;
}
const replyCache=new Map();
function findMsg(id){ return (S.msgs.get(S.cur)||[]).find(m=>m.id===id) || replyCache.get(id); }
function addReact(r){ let a=S.reacts.get(r.message_id); if(!a){a=[];S.reacts.set(r.message_id,a);} const i=a.findIndex(x=>x.user_id===r.user_id); if(i>=0) a[i]=r; else a.push(r); }
function delReact(mid,uid){ const a=S.reacts.get(mid); if(!a) return; const i=a.findIndex(x=>x.user_id===uid); if(i>=0) a.splice(i,1); }
function headStatus(c){
const typ=S.typing.get(c.chat_id); if(typ&&typ.size){ const vs=[...typ.values()], n=vs.map(v=>v.name); return {t:(c.type==='private'?typVerb(vs[0]):n.length>1?n.slice(0,2).join(', ')+' печатают':n[0]+' '+typVerb(vs[0])),live:true,dots:true}; }
if(c.type==='private'){ if(c.peer_id===S.me.id) return {t:'заметки для себя'}; if(window.lfDnd){ const dd=window.lfDnd(c.peer_id); if(dd) return {t:dd}; } const p=S.profiles.get(c.peer_id); if(c.peer_bot||(p&&p.is_bot)) return {t:'бот'}; if(p&&p.banned) return {t:'аккаунт заблокирован'}; return {t:lastSeen(p),live:S.online.has(c.peer_id)}; }
const mem=S.members.get(c.chat_id)||[]; const n=mem.length||c.members_count; const on=mem.filter(m=>S.online.has(m.user_id)).length;
return {t:c.type==='channel'?`${n} ${plural(n,'подписчик','подписчика','подписчиков')}`:`${n} ${plural(n,'участник','участника','участников')}${on>1?`, ${on} в сети`:''}`};
}
function renderHead(){
const c=cur(); if(!c) return; const st=headStatus(c);
$('#who').innerHTML=`${chatAv(c,'s')}<div style="min-width:0"><div class="nm">${esc(chatName(c))}${c.type==='private'?pMark(S.profiles.get(c.peer_id)):vMark(c.peer_verified)}${c.type==='private'&&window.lfBadge?window.lfBadge(c.chat_id,true):''}${c.muted?ic('belloff','mini'):''}${c.type==='private'&&E2E.active(c.chat_id)?`<span class="e2elk" title="Сквозное шифрование">${ic('lock','mini')}</span>`:''}</div><div class="st ${st.live?'live':''}">${esc(st.t)}${st.dots?'<span class="typingdots"><i></i><i></i><i></i></span>':''}</div></div>`;
const dm=c.type==='private'&&c.peer_id!==S.me.id;
const bt=!!(c.peer_bot||S.profiles.get(c.peer_id)?.is_bot); $('#hCall').classList.toggle('hidden',!((dm&&!bt)||c.type==='group')); $('#hVideo').classList.toggle('hidden',!((dm&&!bt)||c.type==='group'));
if(window.lfHead) window.lfHead();
}
function renderPin(){
const c=cur(); const pb=$('#pinbar');
if(!c||!c.pinned_message_id){ pb.classList.add('hidden'); return; }
const m=findMsg(c.pinned_message_id);
if(!m){ sb.from('lm_messages').select('*').eq('id',c.pinned_message_id).maybeSingle().then(async({data})=>{ if(data&&!data.deleted){ await E2E.dec(data); replyCache.set(data.id,data); renderPin(); } }); pb.classList.add('hidden'); return; }
if(m.deleted){ pb.classList.add('hidden'); return; }
pb.innerHTML=`<span class="bar"></span><div class="tx"><b>Закреплённое сообщение</b><span>${previewOf(m).replace(/<svg[\s\S]*?<\/svg>/,'')}</span></div>${canPin()?`<button class="ib" id="unpin">${ic('x')}</button>`:''}`;
pb.classList.remove('hidden');
pb.onclick=e=>{ if(e.target.closest('#unpin')){ e.stopPropagation(); return pinMsg(null); } jumpTo(m.id); };
}
/* ================= RENDER MESSAGES ================= */
function readBy(m){ const mem=S.members.get(S.cur)||[]; return mem.some(x=>x.user_id!==S.me.id && new Date(x.last_read_at)>=new Date(m.created_at)); }
function metaHtml(m,ov=''){
const me=m.sender_id===S.me.id, c=cur();
const st = me && c.type!=='channel' && c.peer_id!==S.me.id ? ic(readBy(m)?'checks':'check', readBy(m)?'rd':'') : (me && m._pending ? '' : '');
return `<span class="meta ${ov}">${m.edited_at?'изм. ':''}${fmtT(m.created_at)}${m._pending?ic('clock'):''}${st}</span>`;
}
function reactsHtml(m){
const a=S.reacts.get(m.id); if(!a||!a.length) return '';
const g=new Map(); a.forEach(r=>{ const x=g.get(r.emoji)||{n:0,mine:false}; x.n++; if(r.user_id===S.me.id) x.mine=true; g.set(r.emoji,x); });
return `<div class="reacts">${[...g].map(([e,x])=>`<span class="rc ${x.mine?'mine':''}" data-react="${esc(e)}"><span class="e">${esc(e)}</span>${x.n}</span>`).join('')}</div>`;
}
function replyHtml(m){
if(!m.reply_to) return ''; const r=findMsg(m.reply_to);
const nm=r? (r.sender_id?profName(r.sender_id):'') : ''; const tx=r? previewOf(r).replace(/<svg[\s\S]*?<\/svg>/,'') : 'Сообщение';
return `<div class="rep" data-jump="${m.reply_to}"><span class="bar"></span><div class="rt"><b>${esc(nm||'Ответ')}</b><span>${tx}</span></div></div>`;
}
function waveHtml(w,n=40){ w=(w&&w.length?w:Array.from({length:n},(_,i)=>8+((i*37)%17))); return w.map(v=>`<i style="height:${Math.max(3,Math.round(v/31*28))}px"></i>`).join(''); }
function msgHtml(m,prev,next){
if(m.kind==='gift'&&!m.deleted&&window.lxGiftMsg) return window.lxGiftMsg(m);
if(window.lfMsg){ const lfh=window.lfMsg(m); if(lfh) return lfh; }
if(m.kind==='system') return `<div class="sys" data-id="${m.id}"><span>${esc(m.body)}</span></div>`;
const c=cur(); const me=m.sender_id===S.me.id; const grp=c.type==='group';
const p=S.profiles.get(m.sender_id);
const samePrev=prev&&prev.kind!=='system'&&prev.sender_id===m.sender_id&&sameDay(prev.created_at,m.created_at)&&(new Date(m.created_at)-new Date(prev.created_at)<5*6e4);
const sameNext=next&&next.kind!=='system'&&next.sender_id===m.sender_id&&sameDay(next.created_at,m.created_at)&&(new Date(next.created_at)-new Date(m.created_at)<5*6e4);
const showAv=grp&&!me; const cls=`m ${me?'me':''} ${!sameNext?'tail':''} ${samePrev?'grp':'grp first'}`;
const nameHtml = grp&&!me&&!samePrev ? `<span class="sn nc${(p?.color??0)%COLORS}" data-user="${m.sender_id}">${esc(p?.name||'...')}</span>` : (c.type==='channel'&&!samePrev?`<span class="sn nc${c.color%COLORS}">${esc(c.title)}</span>`:'');
const fw = m.forwarded_from?`<div class="fw">${ic('fwd')}Переслано от ${esc(m.forwarded_from)}</div>`:'';
let inner, bcls='b';
const meta=m.meta||{};
if(m.deleted){ inner=`<div class="del">${ic('ban')}Сообщение удалено</div>${metaHtml(m)}`; }
else if(meta.parts&&meta.parts.length&&(m.kind==='file'||m.kind==='video')){ inner=`${nameHtml}${fw}${replyHtml(m)}<a class="file" href="#" data-big="${m.id}"><span class="fi">${ic(m.kind==='video'?'play':'dl')}</span><span style="min-width:0"><div class="fn">${esc(meta.name||'Файл')}</div><div class="fs">${m.kind==='video'?'Видео · ':''}${fmtSize(meta.size)}</div></span></a>${m.body?`<div class="txt">${richText(m.body)}</div>`:''}${metaHtml(m)}`; }
else switch(m.kind){
case 'sticker': bcls+=' stk'; inner=`<div class="big">${m.body&&m.body.startsWith('art:')?stkArt(m.body.slice(4)):m.body&&/^img:https:\/\//.test(m.body)?`<img class="rstk" src="${esc(m.body.slice(4))}" loading="lazy" alt="">`:esc(m.body)}</div>${metaHtml(m)}`; break;
case 'image': bcls+=' media'; inner=`${nameHtml?`<div class="cap">${nameHtml}${fw}</div>`:fw?`<div class="cap">${fw}</div>`:''}${replyHtml(m)}<img class="ph" src="${esc(m.media_url)}" data-view="${esc(m.media_url)}" loading="lazy" ${meta.w?`width="${meta.w}" height="${meta.h}"`:''}>${m.body?`<div class="cap"><div class="txt">${richText(m.body)}</div>${metaHtml(m)}</div>`:metaHtml(m,'ov')}`; break;
case 'video': bcls+=' media'; inner=`${nameHtml||fw?`<div class="cap">${nameHtml}${fw}</div>`:''}${replyHtml(m)}<video class="ph" data-lsrc="${esc(m.media_url)}#t=0.1" preload="none" playsinline data-view="${esc(m.media_url)}" data-vid="1"></video>${m.body?`<div class="cap"><div class="txt">${richText(m.body)}</div>${metaHtml(m)}</div>`:metaHtml(m,'ov')}`; break;
case 'file': inner=`${nameHtml}${fw}${replyHtml(m)}<a class="file" href="${esc(m.media_url)}" target="_blank" download="${esc(meta.name||'file')}"><span class="fi">${ic('dl')}</span><span style="min-width:0"><div class="fn">${esc(meta.name||'Файл')}</div><div class="fs">${fmtSize(meta.size)}</div></span></a>${m.body?`<div class="txt">${richText(m.body)}</div>`:''}${metaHtml(m)}`; break;
case 'voice': inner=`${nameHtml}${fw}${replyHtml(m)}<div class="voice" data-voice="${m.id}"><button class="pp">${ic('play')}</button><div style="flex:1;min-width:0"><div class="wave">${waveHtml(meta.wave)}</div><div class="vdw"><div class="vd">${fmtDur(meta.dur)}</div>${lsDot(m)}</div></div></div>${metaHtml(m)}`; break;
case 'video_note': bcls+=' vnb'; inner=`${fw}<div class="vn" data-vn="${m.id}"><video src="${esc(m.media_url)}#t=0.1" preload="metadata" playsinline loop muted></video><svg class="ring" viewBox="0 0 252 252"><circle cx="126" cy="126" r="123" fill="none" stroke="#fff" stroke-width="3" stroke-dasharray="773" stroke-dashoffset="773" stroke-linecap="round"/></svg><span class="muteic">${ic('play')}</span><span class="vnd">${fmtDur(meta.dur)}</span>${lsDot(m)}</div>${metaHtml(m)}`; break;
case 'call': { const miss=meta.status!=='ended'; const out=me;
inner=`<div class="callm"><span class="ci ${miss?'miss':''}">${ic(meta.video?'video':'phone')}</span><div><div style="font-weight:700">${miss?(out?'Отменённый':(meta.status==='rejected'?'Отклонённый':'Пропущенный')):(out?'Исходящий':'Входящий')} ${meta.video?'видеозвонок':'звонок'}</div><div style="font-size:13px;opacity:.75">${meta.status==='ended'?fmtDur(meta.duration):(meta.status==='rejected'?'отклонён':'без ответа')}</div></div></div>${metaHtml(m)}`; break; }
default:{ const big=isOnlyEmoji(m.body)&&!m.reply_to; if(big){ bcls+=' stk'; inner=`<div class="big">${bemoHtml(m.body)}</div>${metaHtml(m)}`; }
else inner=`${meta.urgent===true?'<div class="lftag">'+ic('bolt')+'СРОЧНО</div>':''}${nameHtml}${fw}${replyHtml(m)}<span class="txt">${richText(m.body,!!(cur()&&cur().peer_bot))}</span>${metaHtml(m)}`; }
}
const avh = showAv ? `<div class="avs">${!sameNext?`<div data-user="${m.sender_id}" style="cursor:pointer">${avatar({name:p?.name,avatar:p?.avatar_url,color:p?.color},'xs')}</div>`:''}</div>` : '';
return `<div class="${cls}" data-id="${m.id}">${avh}<div class="${bcls}">${inner}${kbHtml(m)}${reactsHtml(m)}</div></div>`;
}
function renderMsgs(toBottom=false, keepOffset=null){
const el=$('#msgs'); const list=S.msgs.get(S.cur)||[];
const atBottom = el.scrollHeight-el.scrollTop-el.clientHeight < 120;
const firstUnread = toBottom ? list.find(m=>m.sender_id!==S.me.id && m.kind!=='system' && new Date(m.created_at)>new Date(cur()?.last_read_at||0)) : null;
let h=''; let last=null;
if(S.more.get(S.cur)) h+=`<div class="sys"><span>Загрузка\u2026</span></div>`;
list.forEach((m,i)=>{
if(!last||!sameDay(last.created_at,m.created_at)) h+=`<div class="day"><span>${fmtDay(m.created_at)}</span></div>`;
if(firstUnread && m===firstUnread && i>0) h+=`<div class="sys" id="unreadMark"><span>Непрочитанные сообщения</span></div>`;
h+=msgHtml(m,list[i-1],list[i+1]); last=m;
});
if(!list.length){
if(cur()?.type==='private') h=`<div style="display:grid;place-items:center;height:60vh"><div class="lxempty"><svg viewBox="0 0 100 100" width="104" height="104"><defs><linearGradient id="egb" x1="0" y1="0" x2="100" y2="100"><stop offset="0" stop-color="#9b7bff"/><stop offset="1" stop-color="#4fc3f7"/></linearGradient></defs><ellipse cx="50" cy="60" rx="33" ry="30" fill="url(#egb)"/><circle cx="28" cy="60" r="7" fill="#ffb3c6" opacity=".55"/><circle cx="72" cy="60" r="7" fill="#ffb3c6" opacity=".55"/><circle cx="40" cy="54" r="4.2" fill="#2a2240"/><circle cx="60" cy="54" r="4.2" fill="#2a2240"/><circle cx="41.4" cy="52.6" r="1.3" fill="#fff"/><circle cx="61.4" cy="52.6" r="1.3" fill="#fff"/><path d="M39 66q11 9 22 0" stroke="#2a2240" stroke-width="2.6" fill="none" stroke-linecap="round"/><path d="M78 42c8-10 20-8 18 2-1 6-9 9-14 6" fill="url(#egb)"/><circle cx="90" cy="34" r="7" fill="url(#egb)"/><path d="M85 28l-3-5M90 26l-1-6M95 28l3-5" stroke="#2a2240" stroke-width="2" stroke-linecap="round"/></svg><div class="lxempty-t">Сообщений пока нет</div><div class="lxempty-s">Отправьте сообщение или напишите первым</div></div></div>`;
else h=`<div style="display:grid;place-items:center;height:60vh"><div class="sys"><span style="padding:16px 22px;border-radius:20px">Сообщений пока нет.<br>Напишите первым!</span></div></div>`;
}
$('#mw').innerHTML=h;
if(keepOffset!=null) el.scrollTop=el.scrollHeight-keepOffset;
else if(toBottom){ const um=$('#unreadMark'); if(um) um.scrollIntoView({block:'center'}); else el.scrollTop=el.scrollHeight; }
else if(atBottom) el.scrollTop=el.scrollHeight;
S.pinBottom = el.scrollHeight-el.scrollTop-el.clientHeight < 120;
stickInit();
restoreMedia();
}
// видео и фото догружаются уже после открытия чата и становятся выше \u2014 если вы были внизу, остаёмся внизу
function stickInit(){ if(S.stickOn) return; const el=$('#msgs'), mw=$('#mw'); if(!el||!mw||!window.ResizeObserver) return; S.stickOn=1;
  let last=el.scrollHeight;
  el.addEventListener('scroll',()=>{ S.pinBottom = el.scrollHeight-el.scrollTop-el.clientHeight < 120; },{passive:true});
  const stick=()=>{ const h=el.scrollHeight; if(h!==last){ if(S.pinBottom) el.scrollTop=h; last=h; } };
  new ResizeObserver(stick).observe(mw); new ResizeObserver(stick).observe(el);
  mw.addEventListener('load',stick,true); mw.addEventListener('loadedmetadata',stick,true); }
function rerenderOne(id){
const list=S.msgs.get(S.cur)||[]; const i=list.findIndex(m=>m.id===id); if(i<0) return;
const old=$(`#mw [data-id="${id}"]`); if(!old) return renderMsgs();
const t=document.createElement('div'); t.innerHTML=msgHtml(list[i],list[i-1],list[i+1]); old.replaceWith(t.firstElementChild); restoreMedia();
}
$('#msgs').addEventListener('scroll',async()=>{
const el=$('#msgs'); const fromBottom=el.scrollHeight-el.scrollTop-el.clientHeight;
$('#down').classList.toggle('hidden',fromBottom<300);
if(fromBottom<60 && S.unreadBelow){ S.unreadBelow=0; updDown(); }
if(el.scrollTop<150 && S.more.get(S.cur) && !S.loadingMore){
S.loadingMore=true; const id=S.cur; const first=(S.msgs.get(id)||[])[0];
if(first){ const off=el.scrollHeight-el.scrollTop; await loadMessages(id,first.id); if(S.cur===id) renderMsgs(false,off); }
S.loadingMore=false;
}
});
function selKeep(){ if(S.sel) $('#mw').querySelectorAll('.m[data-id]').forEach(el=>el.classList.toggle('sel',S.sel.has(+el.dataset.id))); }
function updDown(){ selKeep(); $('#down').innerHTML=ic('down')+(S.unreadBelow?`<span class="badge">${S.unreadBelow}</span>`:''); }
$('#down').onclick=()=>{ const el=$('#msgs'); el.scrollTo({top:el.scrollHeight,behavior:'smooth'}); S.unreadBelow=0; updDown(); };
async function jumpTo(id){
let el=$(`#mw [data-id="${id}"]`);
if(!el){ // load until found (max 10 pages)
for(let k=0;k<10&&!el&&S.more.get(S.cur);k++){ const first=S.msgs.get(S.cur)[0]; await loadMessages(S.cur,first.id); renderMsgs(); el=$(`#mw [data-id="${id}"]`); }
}
if(!el) return toast('Сообщение не найдено');
el.scrollIntoView({block:'center',behavior:'smooth'}); el.classList.remove('hl'); void el.offsetWidth; el.classList.add('hl');
}
/* read receipts */
let readT;
function markRead(){
if(S.cur&&S.ur&&S.ur.has(S.cur)) seenUR(S.cur);
clearTimeout(readT); readT=setTimeout(async()=>{
const c=cur(); if(!c||document.hidden) return; const list=S.msgs.get(c.chat_id)||[]; const last=list[list.length-1];
if(!last) return; if(c.unread===0 && new Date(c.last_read_at)>=new Date(last.created_at)) return;
const real=[...list].reverse().find(m=>m.id>0)||last; const ts=new Date(new Date(real.created_at).getTime()+1).toISOString();
c.unread=0; c.last_read_at=ts; renderList(); updateTitle();
await sb.from('lm_members').update({last_read_at:ts}).eq('chat_id',c.chat_id).eq('user_id',S.me.id);
},300);
}
document.addEventListener('visibilitychange',()=>{ if(!sb||!S.me) return;
if(document.hidden){ touchNow(true); try{ presChan?.untrack(); }catch{} }
else { markRead(); touchNow(); try{ presChan?.track({at:Date.now()}); }catch{} catchUp(); } });
async function catchUp(){ try{ await loadChats();
for(const [cid,list] of [...S.msgs]){ if(cid!==S.cur){ S.msgs.delete(cid); continue; }
  const last=[...list].reverse().find(m=>m.id>0); if(!last) continue;
  const {data}=await sb.from('lm_messages').select('*').eq('chat_id',cid).gt('id',last.id).order('id',{ascending:true}).limit(100);
  for(const m of (data||[])) await onNewMsg(m); }
}catch{} }
window.addEventListener('pagehide',()=>{ if(sb&&S.me) touchNow(true); });
let lastTok=null;
function touchNow(beacon){ try{
if(!beacon){ sb.rpc('lm_presence',{p_active:true}).then(r=>{ if(r&&r.error) sb.rpc('lm_touch'); }); sb.auth.getSession().then(({data})=>{ lastTok=data?.session?.access_token||lastTok; }); return; }
if(!lastTok) return;
fetch(SUPABASE_URL+'/rest/v1/rpc/lm_presence',{method:'POST',keepalive:true,headers:{'Content-Type':'application/json',apikey:SUPABASE_KEY,Authorization:'Bearer '+lastTok},body:'{"p_active":false}'});
}catch{} }
/* ================= COMPOSER ================= */
const drafts=new Map();
function saveDraft(){ if(!S.cur) return; const v=$('#txt').value; if(v.trim()) drafts.set(S.cur,v); else drafts.delete(S.cur); lmDraftsSave(); }
function loadDraft(){ $('#txt').value=drafts.get(S.cur)||''; autoGrow(); }
function autoGrow(){ const t=$('#txt'); t.style.height='auto'; t.style.height=Math.min(t.scrollHeight,180)+'px'; }
function canPost(){ const c=cur(); return c && (c.type!=='channel' || ['owner','admin'].includes(c.role)); }
function canPin(){ const c=cur(); return c && (c.type==='private' || ['owner','admin'].includes(c.role)); }
const startedBots=new Set();
function botNeedStart(c){ return !!(c&&c.peer_bot&&S.msgs.has(c.chat_id)&&!startedBots.has(c.chat_id)&&!(S.msgs.get(c.chat_id)||[]).some(m=>m.sender_id===S.me.id)); }
function startBot(){ const c=cur(); if(!c) return; startedBots.add(c.chat_id); updateComposer(); $('#txt').value='/start'; sendText(); }
function sendCmd(cmd){ const c=cur(); if(!c) return; startedBots.add(c.chat_id); updateComposer(); $('#txt').value=cmd; sendText(); }
function updateComposer(){
const c=cur(); if(!c) return; const bs=peerState(c); const ns=botNeedStart(c); const ok=canPost()&&!bs&&!ns;
$('#composer').classList.toggle('hidden',!ok); $('#readonly').classList.toggle('hidden',ok);
if(!ok){ const ro=$('#readonly');
  ro.innerHTML=ns?`<button id="roBtn">Начать</button>`:bs?`<div class="rotx ${bs.ban?'ban':''}">${ic(bs.ban?'ban':'lock')}<span>${esc(bs.t)}</span></div>${bs.btn?`<button id="roBtn">${bs.btn}</button>`:''}`:`<button id="roBtn">${c.muted?'Включить звук':'Убрать звук'}</button>`;
  const b=$('#roBtn'); if(b) b.onclick=ns?startBot:bs?bs.fn:()=>toggleMute(); }
const has=$('#txt').value.trim().length>0 || S.edit;
$('#sendbtn').innerHTML = has ? ic(S.edit?'check':'send') : ic(S.mode==='mic'?'mic':'vcirc');
$('#sendbtn').title = has ? 'Отправить' : (S.mode==='mic'?'Удерживайте для записи голосового. Нажмите \u2014 сменить на видео':'Удерживайте для записи кружка. Нажмите \u2014 сменить на голос');
}
let typingSent=0;
$('#txt').addEventListener('input',()=>{ autoGrow(); updateComposer(); if(Date.now()-typingSent>2500){ typingSent=Date.now(); sendTyping(); } });
$('#txt').addEventListener('keydown',e=>{
if(e.key==='Enter'&&!e.shiftKey&&innerWidth>800&&localStorage.getItem('lm_enter')!=='0'){ e.preventDefault(); sendText(); }
if(e.key==='Escape'){ S.reply=null; S.edit=null; renderCtx(); }
if(e.key==='ArrowUp'&&!$('#txt').value){ const mine=[...(S.msgs.get(S.cur)||[])].reverse().find(m=>m.sender_id===S.me.id&&m.kind==='text'&&!m.deleted); if(mine){ e.preventDefault(); startEdit(mine); } }
});
$('#txt').addEventListener('paste',e=>{ const files=[...(e.clipboardData?.files||[])]; if(files.length){ e.preventDefault(); sendFiles(files); } });
function renderCtx(){
const el=$('#ctx'); const m=S.reply||S.edit;
if(!m){ el.classList.add('hidden'); updateComposer(); return; }
el.innerHTML=`${ic(S.edit?'edit':'reply')}<div class="tx"><b>${S.edit?'Редактирование':'Ответ '+esc(profName(m.sender_id))}</b><span>${previewOf(m).replace(/<svg[\s\S]*?<\/svg>/,'')}</span></div><button class="ib" id="ctxX">${ic('x')}</button>`;
el.classList.remove('hidden'); $('#ctxX').onclick=()=>{ if(S.edit) $('#txt').value=''; S.reply=null; S.edit=null; renderCtx(); autoGrow(); };
updateComposer();
}
function startEdit(m){ S.edit=m; S.reply=null; $('#txt').value=m.body||''; renderCtx(); autoGrow(); $('#txt').focus(); }
async function sendText(meta){
if(meta&&meta.preventDefault) meta=null;
const t=$('#txt').value.trim(); if(!t) return;
const c=cur();
if(S.edit){ const m=S.edit; S.edit=null; $('#txt').value=''; renderCtx(); autoGrow();
if(t!==m.body){ let wire=t; if(m.kind==='text'){ await E2E.prepChat(m.chat_id); wire=(await E2E.enc(m.chat_id,t))||t; } const {error}=await sb.from('lm_messages').update({body:wire,edited_at:new Date().toISOString()}).eq('id',m.id); if(error) toast(error.message); }
return; }
$('#txt').value=''; autoGrow(); drafts.delete(S.cur); lmDraftsSave(); if(innerWidth<=800) $('#txt').focus();
const reply=S.reply; S.reply=null; renderCtx();
if(!meta&&window.lfUrgent) meta=window.lfUrgent();
await insertMsg({kind:'text',body:t,reply_to:reply?.id||null,...(meta?{meta}:{})});
}
async function insertMsg(row, chatId=S.cur){
const temp={id:-Date.now(),chat_id:chatId,sender_id:S.me.id,created_at:new Date().toISOString(),meta:{},_pending:true,...row};
if(chatId===S.cur){ pushMsg(temp); }
const {data,error}=await sendRow(chatId,row);
const list=S.msgs.get(chatId)||[]; const i=list.findIndex(m=>m.id===temp.id);
if(error){ if(i>=0) list.splice(i,1); if(chatId===S.cur) renderMsgs(); toast('Не отправлено: '+error.message); return null; }
if(i>=0){ if(list.some(m=>m.id===data.id)) list.splice(i,1); else list[i]=data; }
if(chatId===S.cur) renderMsgs(); bumpChat(data); if(window.lfSent) window.lfSent(data); return data;
}
function pushMsg(m){ const list=S.msgs.get(m.chat_id); if(!list) return; if(list.some(x=>x.id===m.id)) return; list.push(m); const el=$('#msgs');
const atBottom=el.scrollHeight-el.scrollTop-el.clientHeight<150 || m.sender_id===S.me.id; renderMsgs();
if(atBottom) el.scrollTo({top:el.scrollHeight,behavior:'smooth'}); else { S.unreadBelow++; updDown(); } }
function bumpChat(m){ const c=S.chatMap.get(m.chat_id); if(!c) return scheduleReload();
Object.assign(c,{last_id:m.id,last_kind:m.kind,last_body:m.body,last_sender:m.sender_id,last_sender_name:profName(m.sender_id),last_at:m.created_at,last_deleted:m.deleted});
S.chats.sort((a,b)=>(b.pinned-a.pinned)||(new Date(b.last_at)-new Date(a.last_at))); renderList(); }
/* uploads */
async function upload(blob, ext){
const path=`${S.me.id}/${uid8()}.${ext}`;
const {error}=await sb.storage.from(BUCKET).upload(path, blob, {contentType:blob.type||undefined, upsert:false, cacheControl:'31536000'});
if(error) throw error; return unpx(sb.storage.from(BUCKET).getPublicUrl(path).data.publicUrl);
}
function extOf(f,def='bin'){ const m=(f.name||'').match(/\.([a-z0-9]{1,8})$/i); if(m) return m[1].toLowerCase(); const t=(f.type||'').split('/')[1]; return (t||def).split(';')[0].replace('x-matroska','mkv').replace('quicktime','mov').replace('jpeg','jpg'); }
function imgSize(f){ return new Promise(r=>{ const i=new Image(); i.onload=()=>{ r({w:i.naturalWidth,h:i.naturalHeight}); URL.revokeObjectURL(i.src); }; i.onerror=()=>r({}); i.src=URL.createObjectURL(f); }); }
async function compressImage(f){
if(!/^image\/(jpeg|png|webp)$/.test(f.type) || f.size<400000) return f;
const cv=await loadPhoto(f).catch(()=>null); if(!cv) return f;
return await new Promise(r=>cv.toBlob(b=>r(b?new File([b],'photo.jpg',{type:'image/jpeg'}):f),'image/jpeg',.86));
}
async function sendFiles(files, asFile=false){
if(!canPost()) return;
const caption=$('#txt').value.trim(); let capUsed=false;
for(const f0 of files){
if(f0.size>window.tgLim()){ toast(`«${f0.name}» больше ${window.tgLimTxt()}`); continue; }
const kind = asFile ? 'file' : f0.type.startsWith('image/') && !/svg|gif/.test(f0.type) ? 'image' : f0.type.startsWith('video/') ? 'video' : f0.type==='image/gif' ? 'image' : 'file';
const chatId=S.cur; const temp=pendingUpload(f0.name, chatId);
try{
const f = kind==='image' ? await compressImage(f0) : f0;
const meta = kind==='image' ? await imgSize(f) : {name:f0.name,size:f0.size};
const parts=kind!=='image'?await window.tgBigUp(f0,extOf(f0)):null; if(parts){ meta.parts=parts; meta.name=meta.name||f0.name; meta.size=f0.size; }
const url=parts?parts[0]:await upload(f, kind==='image'&&f!==f0?'jpg':extOf(f0));
temp.remove();
const body = (!capUsed && caption) ? caption : null; if(body){ capUsed=true; $('#txt').value=''; autoGrow(); updateComposer(); }
await insertMsg({kind,media_url:url,meta,body,reply_to:S.reply?.id||null}, chatId); S.reply=null; renderCtx();
}catch(e){ temp.remove(); toast('Ошибка загрузки: '+e.message); }
}
}
function pendingUpload(name, chatId){
const d=document.createElement('div'); d.className='m me tail grp first'; d.innerHTML=`<div class="b"><div style="display:flex;gap:10px;align-items:center">${ic('file')}<span style="max-width:220px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(name)}</span></div><div class="prog"><i></i></div></div>`;
if(chatId===S.cur){ $('#mw').appendChild(d); $('#msgs').scrollTop=$('#msgs').scrollHeight; }
return d;
}
$('#atBtn').onclick=e=>{ e.stopPropagation(); dropMenu(e.currentTarget,[['image','Фото или видео',()=>$('#mediaIn').click()],['file','Файл',()=>$('#fileIn').click()]],'up'); };
$('#mediaIn').onchange=e=>{ sendFiles([...e.target.files]); e.target.value=''; };
$('#fileIn').onchange=e=>{ sendFiles([...e.target.files],true); e.target.value=''; };
// drag & drop
let dragN=0;
$('#main').addEventListener('dragenter',e=>{ if(!S.cur||!e.dataTransfer.types.includes('Files')) return; dragN++; if(!$('.dropzone')){ const d=document.createElement('div'); d.className='dropzone'; d.textContent='Отпустите, чтобы отправить'; $('#main').appendChild(d);} });
$('#main').addEventListener('dragleave',()=>{ if(--dragN<=0){ dragN=0; $('.dropzone')?.remove(); } });
$('#main').addEventListener('dragover',e=>e.preventDefault());
$('#main').addEventListener('drop',e=>{ e.preventDefault(); dragN=0; $('.dropzone')?.remove(); if(S.cur) sendFiles([...e.dataTransfer.files]); });
/* ================= EMOJI & STICKERS ================= */
const EMO='\u{1f600} \u{1f603} \u{1f604} \u{1f601} \u{1f606} \u{1f605} \u{1f923} \u{1f602} \u{1f642} \u{1f609} \u{1f60a} \u{1f607} \u{1f970} \u{1f60d} \u{1f929} \u{1f618} \u{1f617} \u{1f61a} \u{1f60b} \u{1f61b} \u{1f61c} \u{1f92a} \u{1f61d} \u{1f911} \u{1f917} \u{1f92d} \u{1f92b} \u{1f914} \u{1f910} \u{1f928} \u{1f610} \u{1f611} \u{1f636} \u{1f60f} \u{1f612} \u{1f644} \u{1f62c} \u{1f60c} \u{1f614} \u{1f62a} \u{1f634} \u{1f637} \u{1f912} \u{1f915} \u{1f922} \u{1f975} \u{1f976} \u{1f974} \u{1f635} \u{1f92f} \u{1f920} \u{1f973} \u{1f60e} \u{1f913} \u{1f9d0} \u{1f615} \u{1f61f} \u{1f641} \u{1f62e} \u{1f62f} \u{1f632} \u{1f633} \u{1f97a} \u{1f626} \u{1f627} \u{1f628} \u{1f630} \u{1f625} \u{1f622} \u{1f62d} \u{1f631} \u{1f616} \u{1f623} \u{1f61e} \u{1f613} \u{1f629} \u{1f62b} \u{1f971} \u{1f624} \u{1f621} \u{1f620} \u{1f92c} \u{1f608} \u{1f47f} \u{1f480} \u{1f4a9} \u{1f921} \u{1f47b} \u{1f47d} \u{1f916} \u{1f63a} \u{1f638} \u{1f639} \u{1f63b} \u{1f63c} \u{1f640} \u{1f63f} \u{1f63e} \u{1f648} \u{1f649} \u{1f64a} \u2764\ufe0f \u{1f9e1} \u{1f49b} \u{1f49a} \u{1f499} \u{1f49c} \u{1f5a4} \u{1f90d} \u{1f494} \u2763\ufe0f \u{1f495} \u{1f49e} \u{1f493} \u{1f497} \u{1f496} \u{1f498} \u{1f49d} \u{1f4af} \u{1f4a2} \u{1f4a5} \u{1f4ab} \u{1f4a6} \u{1f4a8} \u{1f4ac} \u{1f44b} \u{1f91a} \u270b \u{1f596} \u{1f44c} \u{1f90c} \u270c\ufe0f \u{1f91e} \u{1f91f} \u{1f918} \u{1f919} \u{1f448} \u{1f449} \u{1f446} \u{1f447} \u261d\ufe0f \u{1f44d} \u{1f44e} \u270a \u{1f44a} \u{1f91b} \u{1f91c} \u{1f44f} \u{1f64c} \u{1f450} \u{1f932} \u{1f91d} \u{1f64f} \u{1f4aa} \u{1f9e0} \u{1f440} \u{1f441}\ufe0f \u{1f445} \u{1f444} \u{1f525} \u2728 \u2b50 \u{1f31f} \u26a1 \u{1f308} \u2600\ufe0f \u{1f319} \u2744\ufe0f \u{1f30a} \u{1f340} \u{1f339} \u{1f338} \u{1f33b} \u{1f34e} \u{1f355} \u{1f354} \u{1f35f} \u{1f32e} \u{1f363} \u{1f369} \u{1f36a} \u{1f382} \u{1f370} \u{1f36b} \u{1f37f} \u2615 \u{1f375} \u{1f37a} \u{1f377} \u{1f942} \u{1f389} \u{1f38a} \u{1f381} \u{1f388} \u{1f3c6} \u26bd \u{1f3c0} \u{1f3ae} \u{1f3a7} \u{1f3b5} \u{1f3b6} \u{1f4f1} \u{1f4bb} \u{1f4f7} \u{1f3ac} \u{1f4da} \u270f\ufe0f \u{1f4a1} \u{1f4b0} \u{1f680} \u2708\ufe0f \u{1f697} \u{1f3e0} \u{1f30d} \u23f0 \u2705 \u274c \u2753 \u2757 \u26a0\ufe0f \u{1f514} \u{1f4a4}'.split(' ');
const STK=['pumpkin','ghost','cat','candy','spider','skull','bat','potion'];
const STK_ART={
pumpkin:'<ellipse cx="50" cy="58" rx="38" ry="32" fill="#ff8a1e"/><path d="M30 30 Q26 58 30 86" stroke="#e8690a" stroke-width="2.5" fill="none" opacity=".55"/><path d="M50 28 Q46 58 50 88" stroke="#e8690a" stroke-width="2.5" fill="none" opacity=".55"/><path d="M70 30 Q74 58 70 86" stroke="#e8690a" stroke-width="2.5" fill="none" opacity=".55"/><path d="M50 20c6-4 11 0 9 6-2 4-7 5-9 2-1 3-6 2-6-2 0-4 3-7 6-6z" fill="#3a7a3a"/><path d="M34 50 l10 10 l-10 10 z" fill="#2a1a08"/><path d="M66 50 l-10 10 l10 10 z" fill="#2a1a08"/><path d="M46 62 l4 6 l4-6 z" fill="#2a1a08"/><path d="M28 76 q22 16 44 0 l-5-7 q-17 11-34 0 z" fill="#2a1a08"/>',
ghost:'<path d="M50 14a26 26 0 0 0-26 26v42l8-6 8 6 8-6 8 6 8-6 8 6V40A26 26 0 0 0 50 14z" fill="#f4f2ff"/><circle cx="40" cy="46" r="4.5" fill="#2a2240"/><circle cx="60" cy="46" r="4.5" fill="#2a2240"/><ellipse cx="40" cy="58" rx="4" ry="5" fill="#ffb3c6" opacity=".6"/><ellipse cx="60" cy="58" rx="4" ry="5" fill="#ffb3c6" opacity=".6"/><path d="M44 58q6 6 12 0" stroke="#2a2240" stroke-width="2.4" fill="none" stroke-linecap="round"/>',
cat:'<path d="M20 86c0-20 6-30 10-36l-6-18 14 10c4-2 8-3 12-3s8 1 12 3l14-10-6 18c4 6 10 16 10 36z" fill="#1a1a2e"/><path d="M30 32l-8-16 14 10z" fill="#1a1a2e"/><path d="M70 32l8-16-14 10z" fill="#1a1a2e"/><circle cx="40" cy="52" r="3.4" fill="#ffd97a"/><circle cx="60" cy="52" r="3.4" fill="#ffd97a"/><path d="M50 58l-3 4h6z" fill="#ff8fab"/><path d="M18 50q-10-2-14 2M18 58q-10 2-14 4M82 50q10-2 14 2M82 58q10 2 14 4" stroke="#1a1a2e" stroke-width="2" stroke-linecap="round" fill="none"/>',
candy:'<path d="M50 16c10 14 16 24 16 34H34c0-10 6-20 16-34z" fill="#fff"/><path d="M34 50h32c0 10-4 16-4 16H38s-4-6-4-16z" fill="#ffc83d"/><path d="M38 66h24c0 8-6 14-12 14s-12-6-12-14z" fill="#ff8a1e"/>',
spider:'<circle cx="50" cy="55" r="16" fill="#1a1a2e"/><circle cx="50" cy="38" r="10" fill="#1a1a2e"/><circle cx="45" cy="36" r="2.4" fill="#fff"/><circle cx="55" cy="36" r="2.4" fill="#fff"/><g stroke="#1a1a2e" stroke-width="2.4" stroke-linecap="round"><path d="M36 48 L18 40M36 54 L16 54M36 60 L18 68M64 48 L82 40M64 54 L84 54M64 60 L82 68"/></g><path d="M42 28l-6-6 8 2zM58 28l6-6-8 2z" fill="#ff5b7a"/>',
skull:'<path d="M50 18a24 24 0 0 0-24 24c0 9 4 14 8 18 1 1 2 2 2 4v6a2 2 0 0 0 2 2h24a2 2 0 0 0 2-2v-6c0-2 1-3 2-4 4-4 8-9 8-18a24 24 0 0 0-24-24z" fill="#f4f2ff"/><circle cx="38" cy="46" r="7" fill="#2a2240"/><circle cx="62" cy="46" r="7" fill="#2a2240"/><path d="M50 50l-4 8h8z" fill="#2a2240"/><path d="M38 70h24" stroke="#2a2240" stroke-width="2.4" stroke-linecap="round"/><path d="M30 42l8 4M70 42l-8 4" stroke="#ff5b7a" stroke-width="2" opacity=".7" stroke-linecap="round"/>',
bat:'<path d="M42 50 L20 44 L26 54 L16 58 L26 62 L18 70 L30 68 L30 76 L40 64 Z" fill="#2a2240"/><path d="M58 50 L80 44 L74 54 L84 58 L74 62 L82 70 L70 68 L70 76 L60 64 Z" fill="#2a2240"/><ellipse cx="50" cy="58" rx="9" ry="11" fill="#2a2240"/><path d="M44 46l4 7 2-8z" fill="#2a2240"/><path d="M56 46l-4 7-2-8z" fill="#2a2240"/><circle cx="46.5" cy="57" r="1.8" fill="#ffd97a"/><circle cx="53.5" cy="57" r="1.8" fill="#ffd97a"/><path d="M48 62q2 2 4 0" stroke="#ffd97a" stroke-width="1.4" fill="none" stroke-linecap="round"/>',
potion:'<path d="M44 20h12v14l10 20a18 18 0 0 1-32 0l10-20z" fill="#7c5cff"/><rect x="42" y="16" width="16" height="6" rx="2" fill="#5a3fd6"/><path d="M30 66a18 18 0 0 0 40 0z" fill="#9b7bff"/><circle cx="50" cy="58" r="3" fill="#2bd67b"/><circle cx="42" cy="50" r="2" fill="#2bd67b"/><circle cx="58" cy="52" r="2.4" fill="#2bd67b"/><path d="M36 30q-4-4-2-10M64 30q4-4 2-10" stroke="#2a2240" stroke-width="2" fill="none" stroke-linecap="round" opacity=".5"/>'
};
const STK_NAME={pumpkin:'Тыква',ghost:'Привидение',cat:'Чёрный кот',candy:'Конфета',spider:'Паук',skull:'Череп',bat:'Летучая мышь',potion:'Зелье'};
function stkArt(id){ const p=STK_ART[id]; return p?`<svg viewBox="0 0 100 100">${p}</svg>`:''; }
let recentEmo=JSON.parse(localStorage.getItem('lm_recent')||'[]');
function openEmoji(tab='emoji'){
const el=$('#emoji'); el.classList.remove('hidden');
const list = tab==='emoji' ? [...new Set([...recentEmo,...EMO])] : STK;
el.innerHTML=`<div class="et"><button data-t="emoji" class="${tab==='emoji'?'on':''}">Эмодзи</button><button data-t="stk" class="${tab==='stk'?'on':''}">Стикеры</button></div><div class="eg ${tab==='stk'?'stk':''}">${tab==='stk'?list.map(e=>`<button data-e="${e}" title="${STK_NAME[e]||''}">${stkArt(e)}</button>`).join('')+((S.cfg&&S.cfg.look&&S.cfg.look.stickers)||[]).map(pk=>`<div class="rspk">${esc(pk.name||'')}</div>`+(pk.items||[]).filter(it=>/^https:\/\//.test(it.url||'')).map(it=>`<button data-u="${esc(it.url)}"><img class="rstk" src="${esc(it.url)}" loading="lazy" alt=""></button>`).join('')).join(''):list.map(e=>`<button data-e="${e}">${e}</button>`).join('')}</div>`;
el.querySelector('.et').onclick=ev=>{ const b=ev.target.closest('button'); if(b) openEmoji(b.dataset.t); };
el.querySelector('.eg').onclick=ev=>{ const b=ev.target.closest('button'); if(!b) return; const e=b.dataset.e;
if(tab==='stk'){ insertMsg({kind:'sticker',body:b.dataset.u?'img:'+b.dataset.u:'art:'+e,reply_to:S.reply?.id||null}); S.reply=null; renderCtx(); closeEmoji(); return; }
const t=$('#txt'); const s=t.selectionStart??t.value.length; t.value=t.value.slice(0,s)+e+t.value.slice(t.selectionEnd??s); t.selectionStart=t.selectionEnd=s+e.length; autoGrow(); updateComposer();
recentEmo=[e,...recentEmo.filter(x=>x!==e)].slice(0,16); localStorage.setItem('lm_recent',JSON.stringify(recentEmo)); };
}
function closeEmoji(){ $('#emoji').classList.add('hidden'); }
$('#emBtn').onclick=e=>{ e.stopPropagation(); $('#emoji').classList.contains('hidden')?openEmoji():closeEmoji(); };
document.addEventListener('click',e=>{ if(!e.target.closest('#emoji,#emBtn')) closeEmoji(); if(!e.target.closest('.drop,#cmenu')) closeDrops(); });
/* ================= RECORDING (voice / video notes) ================= */
const R={on:false,locked:false,stream:null,rec:null,t0:0,timer:null,kind:null,peaks:[],ctx:null,an:null,facing:'user',sess:null,starting:false};
const btn=$('#sendbtn');
let holdT=null, downXY=null, pressed=false, noClickUntil=0, touchId=null;
// нажатие кнопки записи \u2014 одинаково для пальца и мыши
function recDown(x,y){
if($('#txt').value.trim()||S.edit||R.on||R.starting) return false;
pressed=true; downXY=[x,y];
try{ if(!R.ctx||R.ctx.state==='closed') R.ctx=new (window.AudioContext||window.webkitAudioContext)(); R.ctx.resume?.(); }catch{}
clearTimeout(holdT); holdT=setTimeout(()=>{ holdT=null; if(pressed) startRec(S.mode==='mic'?'voice':'video_note'); },230);
return true;
}
function recMove(x,y){
if(!R.on||R.locked||!downXY||!pressed) return; const dx=x-downXY[0], dy=y-downXY[1];
$('#recHint').style.transform=`translateX(${Math.min(0,dx/2)}px)`; $('#recHint').style.opacity=1+Math.min(0,dx)/160;
if(dx<-110){ pressed=false; stopRec(false); }
else if(dy<-80) lockRec();
}
function recUp(){
if(!pressed) return; pressed=false; downXY=null; noClickUntil=Date.now()+450;
if(holdT){ clearTimeout(holdT); holdT=null; if(!R.on&&!R.starting) recRelease(); S.mode=S.mode==='mic'?'video':'mic'; updateComposer(); btn.animate([{transform:'scale(.85)'},{transform:'scale(1)'}],{duration:180}); return; }
if(R.on&&!R.locked) stopRec(true);
}
// палец: сенсорные события не \u00abтеряются\u00bb, даже если браузер решит, что это прокрутка
btn.addEventListener('touchstart',e=>{ if(touchId!==null||e.touches.length>1) return; const t=e.changedTouches[0]; if(recDown(t.clientX,t.clientY)){ touchId=t.identifier; if(e.cancelable) e.preventDefault(); } },{passive:false});
btn.addEventListener('touchmove',e=>{ const t=[...e.changedTouches].find(x=>x.identifier===touchId); if(!t) return; if(e.cancelable) e.preventDefault(); recMove(t.clientX,t.clientY); },{passive:false});
const recTouchEnd=e=>{ const t=[...e.changedTouches].find(x=>x.identifier===touchId); if(!t) return; touchId=null; if(e.cancelable) e.preventDefault();
  if(e.type==='touchcancel'&&pressed&&R.on&&!R.locked){ pressed=false; downXY=null; noClickUntil=Date.now()+450; lockRec(); return; } recUp(); };
btn.addEventListener('touchend',recTouchEnd,{passive:false}); btn.addEventListener('touchcancel',recTouchEnd,{passive:false});
// мышь и стилус
btn.addEventListener('pointerdown',e=>{ if(e.pointerType==='touch'||e.button) return; if(recDown(e.clientX,e.clientY)){ e.preventDefault(); try{btn.setPointerCapture(e.pointerId);}catch{} } });
btn.addEventListener('pointermove',e=>{ if(e.pointerType!=='touch') recMove(e.clientX,e.clientY); });
btn.addEventListener('pointerup',e=>{ if(e.pointerType!=='touch') recUp(); });
btn.addEventListener('pointercancel',e=>{ if(e.pointerType==='touch') return; if(pressed&&R.on&&!R.locked){ pressed=false; downXY=null; lockRec(); } else recUp(); });
btn.addEventListener('contextmenu',e=>{ e.preventDefault(); if(sendMenuOk()) openSendMenu(); });
let sendXY=null;
btn.addEventListener('touchstart',e=>{ if(!sendMenuOk()) return; const t=e.touches[0]; sendXY=t?[t.clientX,t.clientY]:null; clearTimeout(sendHold); sendHold=setTimeout(()=>{ try{ navigator.vibrate?.(12); }catch{} openSendMenu(); },300); },{passive:true});
btn.addEventListener('touchmove',e=>{ const t=e.touches[0]; if(sendXY&&t&&sendHold&&sendXY[1]-t.clientY>26&&sendMenuOk()){ clearTimeout(sendHold); sendHold=null; try{ navigator.vibrate?.(12); }catch{} openSendMenu(); return; } if(sendXY&&t&&Math.hypot(t.clientX-sendXY[0],t.clientY-sendXY[1])<18) return; clearTimeout(sendHold); },{passive:true});
['touchend','touchcancel'].forEach(ev=>btn.addEventListener(ev,()=>clearTimeout(sendHold),{passive:true}));
btn.style.webkitTouchCallout='none'; btn.style.userSelect='none'; btn.style.webkitUserSelect='none';
btn.addEventListener('click',()=>{ if(sendHeld) return; if($('#txt').value.trim()||S.edit){ sendText(); return; } if(Date.now()<noClickUntil) return; if(R.on&&R.locked) stopRec(true); });
$('#recDel').onclick=()=>stopRec(false);
// после наших обработчиков \u2014 ничьи больше: если на странице есть чужая копия приложения, до неё нажатие не дойдёт
['touchstart','touchmove','touchend','touchcancel','pointerdown','pointermove','pointerup','pointercancel','click','contextmenu','mousedown','mouseup'].forEach(t=>btn.addEventListener(t,e=>e.stopImmediatePropagation()));
function pickMime(list){ for(const m of list){ if(window.MediaRecorder&&MediaRecorder.isTypeSupported(m)) return m; } return ''; }
async function startRec(kind){
if(R.on||R.starting||!canPost()) return; R.starting=true; try{ await startRec2(kind); }catch(e){ console.warn(e); recRelease(); }finally{ R.starting=false; } }
async function startRec2(kind){
if(!navigator.mediaDevices?.getUserMedia){ toast('Браузер не поддерживает запись. Откройте сайт по https'); return; }
R.kind=kind; R.locked=false; R.peaks=[];
const tAsk=Date.now();
try{
if(kind==='voice'){ R.stream=await navigator.mediaDevices.getUserMedia({audio:{echoCancellation:true,noiseSuppression:true}}); R.all=R.stream.getTracks(); }
else {
  R.cam=await navigator.mediaDevices.getUserMedia({audio:{echoCancellation:true,noiseSuppression:true},video:{facingMode:R.facing,width:{ideal:720},height:{ideal:720}}});
  R.all=R.cam.getTracks();
  R.vid=document.createElement('video'); R.vid.muted=true; R.vid.playsInline=true; R.vid.setAttribute('playsinline',''); R.vid.style.cssText='position:fixed;left:0;top:0;width:2px;height:2px;opacity:0;pointer-events:none'; document.body.appendChild(R.vid); R.vid.srcObject=R.cam; await R.vid.play().catch(()=>{});
  R.cv=document.createElement('canvas'); R.cv.width=R.cv.height=480; const cx=R.cv.getContext('2d');
  const draw=()=>{ const v=R.vid; if(v&&v.videoWidth){ const w=v.videoWidth,h=v.videoHeight,q=Math.min(w,h); cx.save(); if(R.facing==='user'){ cx.translate(480,0); cx.scale(-1,1); } cx.drawImage(v,(w-q)/2,(h-q)/2,q,q,0,0,480,480); cx.restore(); } if(R.cv) R.raf=requestAnimationFrame(draw); };
  draw();
  if(R.cv.captureStream){ R.stream=new MediaStream([...R.cv.captureStream(30).getVideoTracks(), ...R.cam.getAudioTracks()]); R.all.push(...R.stream.getVideoTracks()); }
  else R.stream=R.cam;
}
}catch(e){ (R.all||[]).forEach(t=>t.stop()); R.vid?.remove(); R.vid=null; R.cv=null; recRelease(); toast(kind==='voice'?'Нет доступа к микрофону':'Нет доступа к камере'); return; }
if(!pressed && !R.locked){ R.all.forEach(t=>t.stop()); cancelAnimationFrame(R.raf); R.cv=null; R.vid?.remove(); R.vid=null; recRelease(); if(Date.now()-tAsk>700) toast('Доступ разрешён. Теперь удерживайте кнопку, чтобы записать'); return; }
const mime = kind==='voice' ? pickMime(['audio/mp4;codecs=mp4a.40.2','audio/mp4;codecs=mp4a','audio/webm;codecs=opus','audio/mp4','audio/ogg;codecs=opus','audio/webm']) : pickMime(['video/mp4;codecs=avc1.42E01E,mp4a.40.2','video/mp4;codecs=avc1,mp4a.40.2','video/mp4;codecs=avc1,mp4a','video/mp4;codecs=avc1,opus','video/mp4;codecs=avc1','video/webm;codecs=vp8,opus','video/webm;codecs=vp9,opus','video/webm','video/mp4']);
let rec; try{ rec=new MediaRecorder(R.stream, mime?{mimeType:mime, audioBitsPerSecond:64000, videoBitsPerSecond:1000000}:undefined); }catch(e){ try{ rec=new MediaRecorder(R.stream); }catch{ toast('Запись не поддерживается этим браузером'); cancelAnimationFrame(R.raf); R.cv=null; R.vid?.remove(); R.vid=null; recRelease(); return; } }
// у каждой записи своя \u00abсессия\u00bb: данные, отмена и отправка не перепутаются с другой записью
const ss={kind,chunks:[],peaks:R.peaks,cancel:false,done:false,mime:'',dur:0,chatId:S.cur};
rec.ondataavailable=e=>{ if(e.data&&e.data.size&&!ss.cancel) ss.chunks.push(e.data); };
rec.onstop=()=>{ if(R.sess===ss) stopRec(true); else finishRec(ss); };
try{ rec.start(1000); }catch{ toast('Не удалось начать запись'); cancelAnimationFrame(R.raf); R.cv=null; R.vid?.remove(); R.vid=null; recRelease(); return; }
R.rec=rec; R.sess=ss; R.on=true; R.t0=Date.now(); { const a=R.kind==='voice'?'voice':'video'; sendAct(a); clearInterval(R.actT); R.actT=setInterval(()=>{ if(R.on) sendAct(a); },1500); }
// analyser for waveform
R.an=null; try{ if(!R.ctx||R.ctx.state==='closed') R.ctx=new (window.AudioContext||window.webkitAudioContext)(); R.ctx.resume?.(); R.asrc=R.ctx.createMediaStreamSource(R.stream); R.an=R.ctx.createAnalyser(); R.an.fftSize=512; R.asrc.connect(R.an); }catch{}
const buf=new Uint8Array(512);
$('#cbox').classList.add('hidden'); $('#recbar').classList.remove('hidden'); btn.classList.add('rec'); $('#recHint').textContent='\u2039 Влево \u2014 отмена'; $('#recHint').style.transform=''; $('#recHint').style.opacity=1; $('#recDel').classList.add('hidden');
if(!R.locked){ const l=document.createElement('div'); l.id='lockic'; l.innerHTML=ic('lock')+ic('up'); $('#chat').appendChild(l); }
if(kind==='video_note') showVnOverlay();
R.timer=setInterval(()=>{
if(!R.on) return; const s=(Date.now()-R.t0)/1000; $('#recTm').textContent=fmtDur(s);
if(R.an){ R.an.getByteTimeDomainData(buf); let pk=0; for(let i=0;i<buf.length;i++) pk=Math.max(pk,Math.abs(buf[i]-128)); R.peaks.push(pk); }
if(kind==='video_note'){ const ring=$('#vnrec .ring circle'); if(ring) ring.style.strokeDashoffset=String(1005*(1-Math.min(1,s/60))); const t=$('#vnrec .vtm span'); if(t) t.textContent=fmtDur(s); }
if(s>=(kind==='voice'?600:60)) stopRec(true);
},100);
navigator.vibrate?.(30);
}
// свернули приложение во время записи \u2014 запись удаляется (ничего не отправится само)
document.addEventListener('visibilitychange',()=>{ if(document.hidden){ pressed=false; clearTimeout(holdT); holdT=null; if(R.on){ stopRec(false); R.hidCancel=true; } } else if(R.hidCancel){ R.hidCancel=false; toast('Запись отменена: приложение было свёрнуто'); } });
window.addEventListener('pagehide',()=>{ if(R.on) stopRec(false); });
// всё, что держит микрофон и камеру, \u2014 выключить: дорожки, анализатор, аудиоконтекст
function recRelease(){ try{ R.asrc?.disconnect(); }catch{} R.asrc=null; R.an=null;
  [...(R.all||[]),...(R.stream?.getTracks?.()||[]),...(R.cam?.getTracks?.()||[])].forEach(t=>{ try{ t.stop(); }catch{} });
  R.all=[]; R.stream=null; R.cam=null;
  try{ if(R.ctx&&R.ctx.state!=='closed') R.ctx.close(); }catch{} R.ctx=null; }
function lockRec(){ if(R.locked||!R.on) return; R.locked=true; $('#lockic')?.remove(); $('#recHint').textContent=R.kind==='voice'?'Запись\u2026':'Запись кружка\u2026'; $('#recHint').style.transform=''; $('#recHint').style.opacity=1; $('#recDel').classList.remove('hidden'); $('#recDel').innerHTML=ic('trash'); btn.classList.remove('rec'); btn.innerHTML=ic('send'); navigator.vibrate?.(20); if(R.kind==='video_note') showVnOverlay(); }
function stopRec(send){
const ss=R.sess;
if(!R.on||!ss){ R.on=false; recRelease(); return; }
R.on=false; R.sess=null; R.locked=false; clearInterval(R.timer); clearInterval(R.actT); sendAct('stop');
ss.dur=(Date.now()-R.t0)/1000; ss.cancel=!send||ss.dur<0.7;
const rec=R.rec; R.rec=null; ss.mime=(rec&&rec.mimeType)||'';
if(ss.cancel){ ss.chunks.length=0; if(rec){ rec.ondataavailable=null; rec.onstop=null; } }
try{ if(rec&&rec.state!=='inactive') rec.stop(); else finishRec(ss); }catch{ finishRec(ss); }
cancelAnimationFrame(R.raf); R.cv=null; R.vid?.remove(); R.vid=null; recRelease();
$('#lockic')?.remove(); $('#vnrec')?.remove(); $('#recbar').classList.add('hidden'); $('#cbox').classList.remove('hidden'); btn.classList.remove('rec'); updateComposer();
if(ss.cancel&&send===false) try{ navigator.vibrate?.(15); }catch{}
}
async function finishRec(ss){
if(!ss||ss.done||ss.cancel) return; ss.done=true;
const chunks=ss.chunks.splice(0); if(!chunks.length) return;
const kind=ss.kind, recDur=ss.dur;
const type=ss.mime || chunks[0].type || (kind==='voice'?'audio/webm':'video/webm');
const blob=new Blob(chunks,{type}); const ext=type.includes('mp4')?(kind==='voice'?'m4a':'mp4'):type.includes('ogg')?'ogg':'webm';
const n=40, pk=ss.peaks||[]; const wave=[]; for(let i=0;i<n;i++){ const a=pk.slice(Math.floor(i*pk.length/n),Math.floor((i+1)*pk.length/n)); wave.push(a.length?Math.max(...a):0); }
const mx=Math.max(1,...wave); const w=wave.map(v=>Math.round(v/mx*31));
const chatId=ss.chatId||S.cur, reply=chatId===S.cur?S.reply:null; if(reply){ S.reply=null; renderCtx(); }
const temp=pendingUpload(kind==='voice'?'Голосовое сообщение':'Видеосообщение', chatId);
try{ const url=await upload(blob,ext); temp.remove();
await insertMsg({kind,media_url:url,meta:{dur:Math.max(1,Math.round(recDur)),wave:kind==='voice'?w:undefined},reply_to:reply?.id||null},chatId);
}catch(e){ temp.remove(); toast('Ошибка отправки: '+e.message); }
}
function showVnOverlay(){
let o=$('#vnrec'); if(!o){ o=document.createElement('div'); o.id='vnrec'; document.body.appendChild(o); }
o.innerHTML=`<div class="circ"><div class="vtm"><span class="dot" style="width:10px;height:10px;border-radius:50%;background:var(--danger);animation:blink 1s infinite"></span><span>${fmtDur((Date.now()-R.t0)/1000)}</span></div><div class="cvhost" style="width:100%;height:100%"></div>
<svg class="ring" viewBox="0 0 340 340"><circle cx="170" cy="170" r="160" fill="none" stroke="rgba(255,255,255,.15)" stroke-width="6"/><circle cx="170" cy="170" r="160" fill="none" stroke="url(#gr)" stroke-width="6" stroke-dasharray="1005" stroke-dashoffset="1005" stroke-linecap="round"/><defs><linearGradient id="gr"><stop offset="0" stop-color="#7c5cff"/><stop offset="1" stop-color="#22c1ff"/></linearGradient></defs></svg>
<div class="vbtns">${R.locked?`<button id="vnX">${ic('trash')}</button>`:''}<button id="vnFlip">${ic('flip')}</button>${R.locked?`<button class="go" id="vnGo">${ic('send')}</button>`:''}</div></div>`;
if(R.cv) o.querySelector('.cvhost').appendChild(R.cv);
o.querySelector('.ring circle:nth-child(2)').style.strokeDashoffset=String(1005*(1-Math.min(1,(Date.now()-R.t0)/60000)));
$('#vnFlip').onclick=flipVnCam;
if(R.locked){ $('#vnX').onclick=()=>stopRec(false); $('#vnGo').onclick=()=>stopRec(true); }
}
async function flipVnCam(){
  if(!R.on||!R.cam||R.flipping) return; R.flipping=true; const old=R.facing, nf=old==='user'?'environment':'user';
  const cur=(R.vid?.srcObject?.getVideoTracks?.()||[]); cur.forEach(t=>t.stop()); R.cam.getVideoTracks().forEach(t=>t.stop());
  let ns=null; try{ ns=await navigator.mediaDevices.getUserMedia({video:{facingMode:nf,width:{ideal:720},height:{ideal:720}}}); R.facing=nf; }
  catch{ try{ ns=await navigator.mediaDevices.getUserMedia({video:{facingMode:old,width:{ideal:720},height:{ideal:720}}}); }catch{} toast('Не удалось переключить камеру'); }
  if(ns&&R.on&&R.vid){ R.all.push(...ns.getVideoTracks()); R.vid.srcObject=new MediaStream([...ns.getVideoTracks()]); await R.vid.play().catch(()=>{}); try{navigator.vibrate?.(10);}catch{} }
  else ns?.getTracks().forEach(t=>t.stop());
  R.flipping=false;
}
/* ================= MEDIA PLAYBACK ================= */
let playing=null; // {id, el(audio/video), type}
function durOf(el,id){ const d=el&&el.duration; if(d&&isFinite(d)) return d; return findMsg(+id)?.meta?.dur||0; }
function restoreMedia(){ if(!playing) return; if(playing.type==='voice') updVoiceUI(); }
function stopPlaying(){ if(!playing) return; try{ playing.el.pause(); }catch{} if(playing.type==='vn'){ const v=$(`[data-vn="${playing.id}"] video`); if(v){ v.muted=true; v.currentTime=0; } } const p=playing; playing=null; if(p.type==='voice') updVoiceUI(p.id); else updVnUI(p.id); }
function updVoiceUI(id=playing?.id){
const box=$(`[data-voice="${id}"]`); if(!box) return; const isP=playing&&playing.id==id&&!playing.el.paused;
box.querySelector('.pp').innerHTML=ic(isP?'pause':'play');
const bars=box.querySelectorAll('.wave i'); const dd=playing&&playing.id==id?durOf(playing.el,id):0; const pr=dd?Math.min(1,playing.el.currentTime/dd):0;
bars.forEach((b,i)=>b.classList.toggle('p',i/bars.length<pr));
const m=findMsg(+id); box.querySelector('.vd').textContent = playing&&playing.id==id ? fmtDur(playing.el.currentTime)+' / '+fmtDur(m?.meta?.dur) : fmtDur(m?.meta?.dur);
}
function updVnUI(id){ const box=$(`[data-vn="${id}"]`); if(!box) return; const v=box.querySelector('video'); const isP=playing&&playing.id==id;
box.querySelector('.muteic').style.opacity=isP?0:1; const c=box.querySelector('.ring circle'); const dd=durOf(v,id); c.style.strokeDashoffset=isP&&dd?String(773*(1-Math.min(1,v.currentTime/dd))):'773'; }
function playVoice(id, seek){
const m=findMsg(+id); if(!m) return; lsMark(m);
if(playing&&playing.id==id&&playing.type==='voice'){ if(seek!=null){ const dd=durOf(playing.el,id); if(dd) try{ playing.el.currentTime=Math.max(0,Math.min(dd-0.05,seek*dd)); }catch{} playing.el.play().catch(()=>{}); } else if(playing.el.paused) playing.el.play(); else playing.el.pause(); updVoiceUI(); return; }
stopPlaying(); const a=new Audio(pxu(m.media_url)); playing={id:+id,el:a,type:'voice'};
a.ontimeupdate=()=>updVoiceUI(+id); a.onpause=()=>updVoiceUI(+id); a.onplay=()=>updVoiceUI(+id);
a.preload='auto'; a.onloadedmetadata=()=>{ const dd=durOf(a,id); if(seek!=null&&dd) try{ a.currentTime=seek*dd; }catch{} };
a.onerror=()=>{ if(playing&&playing.el===a){ playing=null; updVoiceUI(+id); } toast('Этот браузер не может воспроизвести запись'); };
a.onended=()=>{ const cid=+id; playing=null; updVoiceUI(cid); playNextVoice(cid); };
a.play().catch(e=>{ if(e&&e.name==='NotAllowedError') toast('Нажмите ещё раз, чтобы воспроизвести'); }); markRead();
}
function playNextVoice(id){ const list=S.msgs.get(S.cur)||[]; const i=list.findIndex(m=>m.id===id); const n=list.slice(i+1).find(m=>!m.deleted&&(m.kind==='voice'||m.kind==='video_note'));
if(n&&n.sender_id!==S.me.id){ n.kind==='voice'?playVoice(n.id):playVn(n.id); } }
function playVn(id){
const box=$(`[data-vn="${id}"]`); if(!box) return; const v=box.querySelector('video');
if(playing&&playing.id==id){ if(v.paused){v.play();} else { v.pause(); } return; }
stopPlaying(); lsMark(findMsg(+id)); v.muted=false; v.loop=false; v.currentTime=0; playing={id:+id,el:v,type:'vn'};
v.ontimeupdate=()=>updVnUI(id); v.onended=()=>{ playing=null; v.muted=true; v.currentTime=0; updVnUI(id); playNextVoice(+id); };
v.onerror=()=>{ toast('Этот браузер не может воспроизвести кружок'); };
v.play().catch(()=>{ v.muted=true; v.play().catch(()=>{}); }); updVnUI(id);
box.scrollIntoView({block:'nearest',behavior:'smooth'});
}
/* ================= MESSAGE INTERACTIONS ================= */
$('#mw').addEventListener('click',e=>{ if(!S.sel) return; const m=e.target.closest('.m[data-id]'); e.preventDefault(); e.stopPropagation(); if(m) selToggle(+m.dataset.id); },true);
$('#mw').addEventListener('click',e=>{
const t=e.target;
const pp=t.closest('.voice .pp'); if(pp){ playVoice(pp.closest('[data-voice]').dataset.voice); return; }
const wv=t.closest('.wave'); if(wv){ const r=wv.getBoundingClientRect(); playVoice(wv.closest('[data-voice]').dataset.voice,(e.clientX-r.left)/r.width); return; }
const vn=t.closest('[data-vn]'); if(vn){ playVn(vn.dataset.vn); return; }
const v=t.closest('[data-view]'); if(v){ lightbox(v.dataset.view, !!v.dataset.vid); return; }
const kbu=t.closest('[data-kburl]'); if(kbu){ const u=kbu.dataset.kburl; if(/^https:\/\/([a-z0-9-]+\.)*yoomoney\.ru\//i.test(u)){ payOpen(u,(/[?&]label=([^&]+)/.exec(u)||[])[1]||null,null); return; } if(/^https?:\/\//i.test(u)) window.open(u,'_blank','noopener'); return; }
const kbb=t.closest('[data-kb]'); if(kbb){ botCb(+kbb.closest('[data-id]').dataset.id,kbb.dataset.kb,kbb); return; }
const j=t.closest('[data-jump]'); if(j){ jumpTo(+j.dataset.jump); return; }
const rc=t.closest('[data-react]'); if(rc){ react(+rc.closest('[data-id]').dataset.id, rc.dataset.react); return; }
const u=t.closest('[data-user]'); if(u){ openUser(u.dataset.user); return; }
const cm=t.closest('[data-cmd]'); if(cm){ e.preventDefault(); sendCmd(cm.dataset.cmd); return; }
const mn=t.closest('[data-mention]'); if(mn){ e.preventDefault(); openByUsername(mn.dataset.mention); return; }
});
$('#mw').addEventListener('dblclick',e=>{ const m=e.target.closest('.m'); if(!m||e.target.closest('.voice,.vn,a')) return; window.getSelection()?.removeAllRanges(); react(+m.dataset.id,'\u2764\ufe0f'); });
$('#mw').addEventListener('contextmenu',e=>{ const m=e.target.closest('.m'); if(!m||S.sel) return; if(e.target.closest('a')&&!e.shiftKey) return; e.preventDefault(); msgMenu(+m.dataset.id,e.clientX,e.clientY); });
let lpT=null, lpXY=null;
$('#mw').addEventListener('touchstart',e=>{ const m=e.target.closest('.m'); if(!m) return; const t=e.touches[0]; lpXY=[t.clientX,t.clientY]; lpT=setTimeout(()=>{ lpT=null; if(S.sel) return; navigator.vibrate?.(15); msgMenu(+m.dataset.id,lpXY[0],lpXY[1]); },450); },{passive:true});
$('#mw').addEventListener('touchmove',e=>{ if(!lpT) return; const t=e.touches[0]; if(Math.hypot(t.clientX-lpXY[0],t.clientY-lpXY[1])>10){ clearTimeout(lpT); lpT=null; } },{passive:true});
$('#mw').addEventListener('touchend',()=>{ if(lpT){ clearTimeout(lpT); lpT=null; } });
// swipe-to-reply on touch
let sw=null;
$('#msgs').addEventListener('touchstart',e=>{ const m=e.target.closest('.m'); if(!m||!canPost()) return; const t=e.touches[0]; sw={el:m,x:t.clientX,y:t.clientY,dx:0,on:false}; },{passive:true});
$('#msgs').addEventListener('touchmove',e=>{ if(!sw) return; const t=e.touches[0]; const dx=t.clientX-sw.x, dy=t.clientY-sw.y;
if(!sw.on){ if(Math.abs(dy)>12){ sw=null; return; } if(dx<-12) sw.on=true; else return; }
sw.dx=Math.max(-80,Math.min(0,dx)); sw.el.style.transform=`translateX(${sw.dx}px)`; },{passive:true});
$('#msgs').addEventListener('touchend',()=>{ if(!sw) return; const s=sw; sw=null; s.el.style.transition='transform .2s'; s.el.style.transform=''; setTimeout(()=>s.el.style.transition='',220);
if(s.dx<=-60){ const m=findMsg(+s.el.dataset.id); if(m&&m.id>0&&!m.deleted){ S.reply=m; S.edit=null; renderCtx(); navigator.vibrate?.(10); } } });
const QUICK=['\u2764\ufe0f','\u{1f44d}','\u{1f602}','\u{1f525}','\u{1f62e}','\u{1f622}','\u{1f389}','\u{1f44f}'];
async function readersDlg(m){ const {data}=await sb.rpc('lm_msg_readers',{p_msg:m.id}); const seen=new Set(); const rows=(data||[]).filter(r=>!seen.has(r.user_id)&&seen.add(r.user_id)); try{ await profGet(rows.map(r=>r.user_id)); }catch{}
  const fmt=d=>{ const t=new Date(d); return isNaN(t)?'':t.toLocaleString('ru-RU',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'}); };
  modal('Просмотры',rows.length?rows.map(r=>{ const p=S.profiles.get(r.user_id)||{}; return `<div style="display:flex;align-items:center;gap:12px;padding:7px 0">${avatar({name:p.name||'?',avatar:p.avatar_url,color:p.color||0},'')}<div style="flex:1;min-width:0"><div style="font-weight:700">${esc(p.name||'Пользователь')}</div><div style="color:var(--muted);font-size:13px">${fmt(r.read_at)}</div></div><div style="font-size:24px">${r.emoji?esc(r.emoji):''}</div></div>`; }).join(''):'<p style="color:var(--muted)">Пока никто не прочитал</p>'); }
function msgMenu(id,x,y){
const m=findMsg(id); if(!m||m.id<0||m.kind==='system') return; closeDrops();
const c=cur(); const mine=m.sender_id===S.me.id; const admin=['owner','admin'].includes(c.role);
const acts=[];
if(!m.deleted && canPost()) acts.push(['reply','Ответить',()=>{ S.reply=m; S.edit=null; renderCtx(); $('#txt').focus(); }]);
if(!m.deleted && m.body && (m.kind==='text'||m.body)) acts.push(['copy','Копировать текст',()=>{ navigator.clipboard?.writeText(m.body); toast('Скопировано'); }]);
if(mine && !m.deleted && ['text','image','video','file'].includes(m.kind)) acts.push(['edit','Изменить',()=>startEdit(m)]);
if(!m.deleted && canPin()) acts.push(['pin',c.pinned_message_id===m.id?'Открепить':'Закрепить',()=>pinMsg(c.pinned_message_id===m.id?null:m.id)]);
if(!m.deleted && m.kind!=='call') acts.push(['fwd','Переслать',()=>forwardMsg(m)]);
if(m.id>0) acts.push(['check','Выбрать',()=>selStart(m.id)]);
if(m.media_url && !m.deleted) acts.push(['dl','Скачать',()=>{ const a=document.createElement('a'); a.href=m.media_url; a.download=m.meta?.name||''; a.target='_blank'; a.click(); }]);
if(!mine&&!m.deleted&&m.sender_id&&m.kind!=='gift'&&window.lxTip) acts.push(['heart','Отправить люмены',()=>window.lxTip(m.sender_id,m.id)]);
if(!mine && !m.deleted && m.sender_id) acts.push(['flag','Пожаловаться',()=>reportDlg({user:m.sender_id,chat:c.chat_id,message:m.id}),'red']);
if(mine&&!m.deleted&&c.type==='group') acts.push(['check','Кто прочитал и отреагировал',()=>readersDlg(m)]);
if(window.lfMenu) window.lfMenu(m,acts);
if(!m.deleted && m.id>0) acts.push(['trash','Удалить',()=>delDlg([m]),'red']);
const d=document.createElement('div'); d.id='cmenu';
d.innerHTML=`${!m.deleted?`<div class="rx">${(window.lxQuick?window.lxQuick():QUICK).map(e=>`<button data-e="${e}">${e}</button>`).join('')}</div>`:''}<div class="drop">${acts.map((a,i)=>`<button data-a="${i}" class="${a[3]||''}">${ic(a[0])}${a[1]}</button>`).join('')}</div>`;
document.body.appendChild(d);
const r=d.getBoundingClientRect(); d.style.left=Math.max(8,Math.min(x,innerWidth-r.width-8))+'px'; d.style.top=Math.max(8,Math.min(y,innerHeight-r.height-8))+'px';
d.onclick=e=>{ const b=e.target.closest('button'); if(!b) return; closeDrops(); if(b.dataset.e) react(id,b.dataset.e); else acts[+b.dataset.a][2](); };
}
function closeDrops(){ document.querySelectorAll('.drop:not(#cmenu .drop),#cmenu,.fxbar,.sov').forEach(x=>x.remove()); }
async function react(id,emoji){
const m=findMsg(id); if(!m||m.deleted||id<0) return; const a=S.reacts.get(id)||[]; const mine=a.find(r=>r.user_id===S.me.id);
if(mine&&mine.emoji===emoji){ delReact(id,S.me.id); rerenderOne(id); await sb.from('lm_reactions').delete().eq('message_id',id).eq('user_id',S.me.id); }
else { addReact({message_id:id,user_id:S.me.id,emoji}); rerenderOne(id);
const {error}=await sb.from('lm_reactions').upsert({message_id:id,user_id:S.me.id,chat_id:m.chat_id,emoji},{onConflict:'message_id,user_id'}); if(error) toast(error.message); }
}
async function pinMsg(id){ const c=cur(); const {error}=await sb.from('lm_chats').update({pinned_message_id:id}).eq('id',c.chat_id); if(error) return toast(error.message); c.pinned_message_id=id; renderPin(); toast(id?'Сообщение закреплено':'Сообщение откреплено'); }
function selStart(id){ S.sel=new Set([id]); $('#mw').classList.add('selmode'); selUI(); }
function selEnd(){ S.sel=null; $('#mw').classList.remove('selmode'); $('#mw').querySelectorAll('.m.sel').forEach(x=>x.classList.remove('sel')); $('#selhead')?.remove(); $('#selbar')?.remove(); $('#composer').classList.remove('hidden'); }
function selToggle(id){ if(!S.sel) return; const m=findMsg(id); if(!m||m.id<0||m.deleted||m.kind==='system') return; S.sel.has(id)?S.sel.delete(id):S.sel.add(id); navigator.vibrate?.(8); selUI(); }
function selList(){ return (S.msgs.get(S.cur)||[]).filter(m=>S.sel&&S.sel.has(m.id)).sort((a,b)=>a.id-b.id); }
function selUI(){ if(!S.sel) return; const L=selList(), c=cur(); const admin=['owner','admin'].includes(c?.role);
  $('#mw').querySelectorAll('.m[data-id]').forEach(el=>el.classList.toggle('sel',S.sel.has(+el.dataset.id)));
  let h=$('#selhead'); if(!h){ h=document.createElement('div'); h.id='selhead'; $('#chathead').appendChild(h); }
  h.innerHTML=`<button class="lnk2" id="selX">Отмена</button><b>${L.length?'Выбрано: '+L.length:'Выберите сообщения'}</b><span></span>`;
  $('#selX').onclick=selEnd;
  let b=$('#selbar'); if(!b){ b=document.createElement('div'); b.id='selbar'; $('#composer').after(b); } $('#composer').classList.add('hidden');
  const texts=L.map(m=>m.body).filter(Boolean), canDel=L.length>0;
  b.innerHTML=`<button data-s="del" ${canDel?'':'disabled'} class="red">${ic('trash')}<span>Удалить</span></button><button data-s="copy" ${texts.length?'':'disabled'}>${ic('copy')}<span>Копировать</span></button>${L.length===1&&canPost()?`<button data-s="reply">${ic('reply')}<span>Ответить</span></button>`:''}<button data-s="fwd" ${L.length?'':'disabled'}>${ic('fwd')}<span>Переслать</span></button>`;
  b.onclick=e=>{ const x=e.target.closest('[data-s]'); if(!x||x.disabled) return; const a=x.dataset.s, list=selList();
    if(a==='del'){ selEnd(); delDlg(list); }
    else if(a==='copy'){ navigator.clipboard?.writeText(list.map(m=>m.body).filter(Boolean).join('\n\n')); toast(list.length>1?'Сообщения скопированы':'Скопировано'); selEnd(); }
    else if(a==='reply'){ S.reply=list[0]; S.edit=null; selEnd(); renderCtx(); $('#txt').focus(); }
    else if(a==='fwd'){ selEnd(); forwardMsg(list); } }; }
function forwardMsg(m){ if(Array.isArray(m)) return forwardMany(m);
const from = m.forwarded_from || (cur().type==='channel'? cur().title : profName(m.sender_id));
const html=S.chats.filter(c=>c.type!=='channel'||['owner','admin'].includes(c.role)).map(c=>`<div class="row" data-fc="${c.chat_id}">${chatAv(c,'s')}<div class="mid"><div class="t1"><span class="nm">${esc(chatName(c))}</span></div></div></div>`).join('');
const close=modal('Переслать в\u2026',`<div id="fwl">${html}</div>`,[]);
$('#fwl').onclick=async e=>{ const r=e.target.closest('[data-fc]'); if(!r) return; close();
const row={kind:m.kind,body:m.body,media_url:m.media_url,meta:m.meta,forwarded_from:from};
const cid=r.dataset.fc; if(cid===S.cur) await insertMsg(row,cid); else { await sendRow(cid,row); }
toast('Сообщение переслано'); if(cid!==S.cur) openChat(cid); };
}
function forwardMany(list){ const src=cur();
const html=S.chats.filter(c=>c.type!=='channel'||['owner','admin'].includes(c.role)).map(c=>`<div class="row" data-fc="${c.chat_id}">${chatAv(c,'s')}<div class="mid"><div class="t1"><span class="nm">${esc(chatName(c))}</span></div></div></div>`).join('');
const close=modal('Переслать в\u2026',`<div id="fwl">${html}</div>`,[]);
$('#fwl').onclick=async e=>{ const r=e.target.closest('[data-fc]'); if(!r) return; close(); const cid=r.dataset.fc;
  for(const m of list){ const from=m.forwarded_from||(src?.type==='channel'?src.title:profName(m.sender_id)); const row={kind:m.kind,body:m.body,media_url:m.media_url,meta:m.meta,forwarded_from:from};
    if(cid===S.cur) await insertMsg(row,cid); else await sendRow(cid,row); }
  toast(list.length>1?'Сообщения пересланы':'Сообщение переслано'); if(cid!==S.cur) openChat(cid); }; }
/* lightbox */
function lightbox(url,isVid){ if(isVid) return videoPlayer(url); const d=document.createElement('div'); d.id='lightbox';
d.innerHTML=`${isVid?`<video src="${esc(url)}" controls autoplay playsinline></video>`:`<img src="${esc(url)}">`}<a class="ib dl" href="${esc(url)}" download target="_blank">${ic('dl')}</a><button class="ib">${ic('x')}</button>`;
d.onclick=e=>{ if(e.target===d||e.target.closest('button')) d.remove(); }; document.body.appendChild(d); stopPlaying(); }
document.addEventListener('keydown',e=>{ if(e.key==='Escape'){ $('#lightbox')?.remove(); closeDrops(); document.querySelector('.ov')?.remove(); } });
/* ---- собственный видеоплеер (без системного) ---- */
function vfmt(t){ t=Math.max(0,Math.floor(t||0)); const m=Math.floor(t/60), s=t%60; return m+':'+String(s).padStart(2,'0'); }
function videoPlayer(url){ stopPlaying(); $('#vplayer')?.remove();
  const d=document.createElement('div'); d.id='vplayer'; d.className='ui';
  d.innerHTML=`<video playsinline webkit-playsinline preload="auto" src="${esc(url)}"></video>
<div class="vpspin"></div><div class="vpskip l"><b>${ic('back')}</b><span>10 сек</span></div><div class="vpskip r"><b>${ic('back')}</b><span>10 сек</span></div>
<button class="vpbig" data-v="pp">${ic('play')}</button>
<div class="vptop"><button class="ib" data-v="x" title="Закрыть">${ic('x')}</button><span class="sp"></span><button class="vpchip" data-v="spd">1\u00d7</button><a class="ib" href="${esc(url)}" download target="_blank" title="Скачать">${ic('dl')}</a></div>
<div class="vpbot"><div class="vpseek"><div class="tr"><i class="buf"></i><i class="fill"></i></div><i class="knob"></i></div>
<div class="vprow"><button class="ib" data-v="pp">${ic('pause')}</button><span class="vt">0:00 / 0:00</span><span class="sp"></span><button class="ib" data-v="mute">${ic('volume')}</button><button class="ib vpfs" data-v="fs" title="На весь экран">${ic('expand')}</button></div></div>`;
  document.body.appendChild(d);
  const v=d.querySelector('video'), seek=d.querySelector('.vpseek'), fill=d.querySelector('.fill'), buf=d.querySelector('.buf'), knob=d.querySelector('.knob'), vt=d.querySelector('.vt');
  let hideT=0, drag=false; const SPD=[1,1.5,2,0.5];
  const show=()=>{ d.classList.add('ui'); clearTimeout(hideT); if(!v.paused&&!drag) hideT=setTimeout(()=>d.classList.remove('ui'),2600); };
  const upd=()=>{ const du=v.duration||0, p=du?v.currentTime/du:0; fill.style.width=(p*100)+'%'; knob.style.left=(p*100)+'%'; vt.textContent=vfmt(v.currentTime)+' / '+vfmt(du);
    try{ if(v.buffered.length&&du) buf.style.width=(v.buffered.end(v.buffered.length-1)/du*100)+'%'; }catch{} };
  const ppIcons=()=>{ const pl=v.paused; d.querySelectorAll('[data-v="pp"]').forEach(b=>b.innerHTML=ic(pl?'play':'pause')); d.classList.toggle('paused',pl); };
  const toggle=()=>{ if(v.paused){ if(v.ended) v.currentTime=0; v.play().catch(()=>{}); } else v.pause(); };
  v.addEventListener('timeupdate',upd); v.addEventListener('progress',upd); v.addEventListener('loadedmetadata',upd);
  v.addEventListener('play',()=>{ ppIcons(); show(); }); v.addEventListener('pause',()=>{ ppIcons(); show(); }); v.addEventListener('ended',()=>{ ppIcons(); d.classList.add('ui'); });
  v.addEventListener('waiting',()=>d.classList.add('wait')); v.addEventListener('playing',()=>d.classList.remove('wait')); v.addEventListener('canplay',()=>d.classList.remove('wait'));
  const close=()=>{ try{ v.pause(); v.removeAttribute('src'); v.load(); }catch{} if(document.fullscreenElement) document.exitFullscreen?.().catch(()=>{}); d.remove(); removeEventListener('keydown',key,true); };
  const seekTo=x=>{ const r=seek.getBoundingClientRect(), p=Math.min(1,Math.max(0,(x-r.left)/r.width)); if(v.duration) v.currentTime=p*v.duration; upd(); };
  seek.addEventListener('pointerdown',e=>{ e.stopPropagation(); drag=true; seek.setPointerCapture(e.pointerId); seekTo(e.clientX); show(); });
  seek.addEventListener('pointermove',e=>{ if(drag) seekTo(e.clientX); });
  seek.addEventListener('pointerup',()=>{ drag=false; show(); }); seek.addEventListener('pointercancel',()=>{ drag=false; });
  // одно касание по видео \u2014 показать/скрыть кнопки; двойное слева/справа \u2014 назад/вперёд на 10 секунд
  let lastTap=0, tapT=0;
  v.addEventListener('click',e=>{ const now=Date.now(), r=v.getBoundingClientRect(), side=e.clientX<r.left+r.width/3?'l':e.clientX>r.right-r.width/3?'r':'c';
    if(now-lastTap<300&&side!=='c'){ clearTimeout(tapT); lastTap=0; v.currentTime=Math.max(0,Math.min(v.duration||0,v.currentTime+(side==='l'?-10:10))); const k=d.querySelector('.vpskip.'+side); k.classList.remove('on'); void k.offsetWidth; k.classList.add('on'); upd(); return; }
    lastTap=now; clearTimeout(tapT); tapT=setTimeout(()=>{ if(d.classList.contains('ui')&&!v.paused){ d.classList.remove('ui'); clearTimeout(hideT); } else show(); },side==='c'?0:260); });
  d.addEventListener('click',e=>{ const b=e.target.closest('[data-v]'); if(!b) return; e.stopPropagation(); const a=b.dataset.v; show();
    if(a==='x') close(); else if(a==='pp') toggle();
    else if(a==='mute'){ v.muted=!v.muted; b.innerHTML=ic(v.muted?'volx':'volume'); }
    else if(a==='spd'){ const i=(SPD.indexOf(v.playbackRate)+1)%SPD.length; v.playbackRate=SPD[i]; b.textContent=String(SPD[i]).replace('.',',')+'\u00d7'; }
    else if(a==='fs'){ try{ if(document.fullscreenElement) document.exitFullscreen(); else if(d.requestFullscreen) d.requestFullscreen().catch(()=>{}); else if(v.webkitEnterFullscreen) v.webkitEnterFullscreen(); }catch{} } });
  // смахнуть вниз \u2014 закрыть
  let sy=null; d.addEventListener('touchstart',e=>{ if(e.target.closest('.vpseek')) return; sy=e.touches[0].clientY; },{passive:true});
  d.addEventListener('touchmove',e=>{ if(sy==null) return; const dy=e.touches[0].clientY-sy; if(dy>0){ d.style.transform=`translateY(${dy}px)`; d.style.opacity=String(Math.max(.3,1-dy/500)); } },{passive:true});
  d.addEventListener('touchend',e=>{ if(sy==null) return; const dy=(e.changedTouches[0]?.clientY||sy)-sy; sy=null; if(dy>110) close(); else { d.style.transform=''; d.style.opacity=''; } });
  const key=e=>{ if(!document.body.contains(d)) return; if(e.key==='Escape'){ e.stopPropagation(); close(); } else if(e.key===' '){ e.preventDefault(); toggle(); } else if(e.key==='ArrowRight'){ v.currentTime+=5; show(); } else if(e.key==='ArrowLeft'){ v.currentTime-=5; show(); } };
  addEventListener('keydown',key,true);
  if(!document.fullscreenEnabled&&!v.webkitEnterFullscreen) d.querySelector('.vpfs').remove();
  ppIcons(); v.play().then(()=>show()).catch(()=>{ ppIcons(); d.classList.add('ui'); });
  return d; }
/* in-chat search */
$('#hSearch').onclick=()=>{ $('#insearch').classList.remove('hidden'); $('#iq').focus(); };
function closeInSearch(){ $('#insearch').classList.add('hidden'); $('#iq').value=''; $('#iqn').textContent=''; S.inSearch={res:[],i:0}; }
$('#iqX').onclick=closeInSearch;
let iqT; $('#iq').addEventListener('input',()=>{ clearTimeout(iqT); iqT=setTimeout(async()=>{ const q=$('#iq').value.trim(); if(!q){ $('#iqn').textContent=''; return; }
let data; const pc=cur();
if(pc&&pc.type==='private'){ await E2E.ready(); await E2E.prepChat(S.cur); const rr=await sb.from('lm_messages').select('id,chat_id,kind,body').eq('chat_id',S.cur).eq('deleted',false).gt('created_at',S.cleared.get(S.cur)||'1970-01-01').order('id',{ascending:false}).limit(600);
  await E2E.decAll(rr.data); const nq=q.toLowerCase(); data=(rr.data||[]).filter(m=>m.kind!=='system'&&m.kind!=='call'&&m.body&&m.body.toLowerCase().includes(nq)).slice(0,100); }
else data=(await sb.from('lm_messages').select('id').eq('chat_id',S.cur).eq('deleted',false).gt('created_at',S.cleared.get(S.cur)||'1970-01-01').ilike('body',`%${q.replace(/[%_]/g,'\\$&')}%`).order('id',{ascending:false}).limit(100)).data;
S.inSearch={res:(data||[]).map(r=>r.id),i:0}; $('#iqn').textContent=data?.length?`1 из ${data.length}`:'Нет совпадений'; if(data?.length) jumpTo(data[0].id); },300); });
function iqStep(d){ const s=S.inSearch; if(!s.res.length) return; s.i=Math.max(0,Math.min(s.res.length-1,s.i+d)); $('#iqn').textContent=`${s.i+1} из ${s.res.length}`; jumpTo(s.res[s.i]); }
$('#iqUp').onclick=()=>iqStep(1); $('#iqDown').onclick=()=>iqStep(-1);
$('#iq').addEventListener('keydown',e=>{ if(e.key==='Enter') iqStep(e.shiftKey?-1:1); if(e.key==='Escape') closeInSearch(); });
/* ================= REALTIME ================= */
let dbChan, presChan, typChan;
function setupRealtime(){
dbChan=sb.channel('lm-db')
.on('postgres_changes',{event:'INSERT',schema:'public',table:'lm_messages'},({new:m})=>onNewMsg(m))
.on('postgres_changes',{event:'UPDATE',schema:'public',table:'lm_messages'},({new:m})=>onUpdMsg(m))
.on('postgres_changes',{event:'*',schema:'public',table:'lm_reactions'},p=>{
if(p.eventType==='DELETE'){ delReact(p.old.message_id,p.old.user_id); if(p.old.message_id) rerenderOne(p.old.message_id); }
else { addReact(p.new); if(p.new.chat_id===S.cur) rerenderOne(p.new.message_id); }
if(p.new&&p.new.user_id&&p.new.user_id!==S.me.id) urArrived(p.new.chat_id); else if(p.eventType==='DELETE'&&S.ur&&S.ur.size) urArrived(p.old&&p.old.chat_id||'x'); })
.on('postgres_changes',{event:'*',schema:'public',table:'lm_members'},p=>{
const r=p.new&&p.new.chat_id?p.new:p.old;
if(p.eventType==='UPDATE'){ const mem=S.members.get(r.chat_id); if(mem){ const x=mem.find(m=>m.user_id===r.user_id); if(x) Object.assign(x,r); }
const c=S.chatMap.get(r.chat_id); if(c&&r.user_id!==S.me.id){ if(!c.others_read_at||new Date(r.last_read_at)>new Date(c.others_read_at)){ c.others_read_at=r.last_read_at; renderList(); } }
if(r.chat_id===S.cur && r.user_id!==S.me.id) document.querySelectorAll('#mw .m.me').forEach(el=>{ const m=findMsg(+el.dataset.id); if(m&&readBy(m)){ const ms=el.querySelector('.meta svg:last-child'); if(ms&&!ms.classList.contains('rd')) rerenderOne(m.id); } });
if(r.user_id===S.me.id && c){ c.muted=r.muted; c.pinned=r.pinned; } }
else { scheduleReload(); if(r.chat_id===S.cur) loadMembers(S.cur).then(renderHead); if(p.eventType==='DELETE'&&r.user_id===S.me.id&&r.chat_id===S.cur) closeChat(); } })
.on('postgres_changes',{event:'UPDATE',schema:'public',table:'lm_chats'},({new:c})=>{ const x=S.chatMap.get(c.id); if(!x) return;
Object.assign(x,{title:c.title,description:c.description,avatar_url:c.avatar_url,pinned_message_id:c.pinned_message_id,is_public:c.is_public,username:c.username});
renderList(); if(c.id===S.cur){ renderHead(); renderPin(); if(!$('#info').classList.contains('hidden')) renderInfo(); } })
.on('postgres_changes',{event:'UPDATE',schema:'public',table:'lm_profiles'},async({new:raw})=>{ const [p]=await profGet([raw.id]); if(!p) return; if(cur()?.peer_id===p.id){ updateComposer(); renderHead(); } let ch=false;
S.chats.forEach(c=>{ if(c.peer_id===p.id){ Object.assign(c,{peer_name:p.name,peer_avatar:p.avatar_url,peer_last_seen:p.last_seen,peer_bio:p.bio}); ch=true; } });
if(p.id===S.me.id) S.me=p; if(ch) renderList(); if(cur()) renderHead(); })
.subscribe(st=>{ if(st==='SUBSCRIBED'){ netSt(null); if(S.wasDown){ S.wasDown=false; refreshAfterReconnect(); } } if(st==='CHANNEL_ERROR'||st==='TIMED_OUT'||st==='CLOSED'){ S.wasDown=true; netSt('conn'); } });
presChan=sb.channel('lm-online',{config:{presence:{key:S.me.id}}});
presChan.on('presence',{event:'sync'},()=>{ const now=new Set(Object.keys(presChan.presenceState())); const ts=new Date().toISOString();
S.online.forEach(id=>{ if(!now.has(id)&&id!==S.me.id){ const p=S.profiles.get(id); if(p) p.last_seen=ts; S.chats.forEach(c=>{ if(c.peer_id===id) c.peer_last_seen=ts; }); } });
S.online=now; renderList(); if(cur()) renderHead(); if(S.tab==='contacts') renderContacts(); })
.subscribe(async st=>{ if(st==='SUBSCRIBED') await presChan.track({at:Date.now()}); });
}
async function refreshAfterReconnect(){ netSt('upd'); try{ await loadChats(); if(S.cur){ S.msgs.delete(S.cur); await loadMessages(S.cur); renderMsgs(); } }finally{ netSt(null); } }
// как в Telegram: сверху \u00abСоединение\u2026\u00bb, потом \u00abОбновление\u2026\u00bb, потом исчезает
let netT=0; function netSt(k){ clearTimeout(netT); const show=()=>{ let e=$('#netst'); if(!k){ e&&e.classList.remove('on'); return; } if(!e){ e=document.createElement('div'); e.id='netst'; $('#side').insertBefore(e,$('#side').firstChild); }
  e.innerHTML=`<span class="nsp"></span>${k==='conn'?'Соединение\u2026':'Обновление\u2026'}`; e.classList.add('on'); };
  if(k==='conn') netT=setTimeout(show,900); else show(); }
addEventListener('offline',()=>netSt('conn')); addEventListener('online',()=>{ netSt('upd'); setTimeout(()=>{ if(!S.wasDown) netSt(null); },1500); });
const seenMsg=new Set();
async function onNewMsg(m){
if(seenMsg.has(m.id)) return; seenMsg.add(m.id);
if(E2E.is(m.body)){ if(!S.chatMap.get(m.chat_id)) await loadChats(); await E2E.dec(m); }
if(m.sender_id && !S.profiles.has(m.sender_id)){ await profGet([m.sender_id]); }
if(window.lfOnMsg) try{ window.lfOnMsg(m); }catch{}
const typ=S.typing.get(m.chat_id); if(typ&&typ.delete(m.sender_id)){ if(m.chat_id===S.cur) renderHead(); }
const c=S.chatMap.get(m.chat_id);
if(!c){ await loadChats(); notify(m); return; }
const list=S.msgs.get(m.chat_id);
if(list && !list.some(x=>x.id===m.id)){
if(m.sender_id===S.me.id){ const tmp=list.find(x=>x._pending&&x.kind===m.kind&&x.body===m.body); if(tmp){ Object.assign(tmp,m); tmp._pending=false; } else list.push(m); if(m.chat_id===S.cur) renderMsgs(); }
else if(m.chat_id===S.cur) pushMsg(m); else list.push(m);
}
if(m.meta&&m.meta.fx&&FX_LIST.includes(m.meta.fx)&&m.chat_id===S.cur&&Date.now()-new Date(m.created_at)<15000) playFx(m.meta.fx);
if(m.kind==='call' && !S.calls.some(x=>x.id===m.id)){ S.calls.unshift(m); renderCalls(); updateTabBadges(); }
if(m.sender_id!==S.me.id && m.kind!=='system'){ if(m.chat_id===S.cur && !document.hidden){ markRead(); if(!c.muted&&localStorage.getItem('lm_sound')!=='0'&&m.kind!=='call'&&!C.st) beep(1046,.08,.04); } else { c.unread=(c.unread||0)+1; notify(m); } }
bumpChat(m); updateTitle();
}
async function onUpdMsg(m){
if(E2E.is(m.body)) await E2E.dec(m);
if(m.deleted){ dropMsgs(m.chat_id,[m.id]); }
const list=S.msgs.get(m.chat_id); if(list&&!m.deleted){ const i=list.findIndex(x=>x.id===m.id); if(i>=0){ const lbo=lsOnlyLb(list[i],m); list[i]=m; if(m.chat_id===S.cur){ if(lbo) lsRefresh(m); else rerenderOne(m.id); } } }
if(replyCache.has(m.id)) replyCache.set(m.id,m);
const c=S.chatMap.get(m.chat_id); if(c&&c.last_id===m.id){ c.last_body=m.body; c.last_deleted=m.deleted; renderList(); }
if(c&&c.pinned_message_id===m.id&&m.chat_id===S.cur) renderPin();
}
// сообщение исчезает полностью (без \u00abСообщение удалено\u00bb)
function dropMsgs(cid,ids){ const set=new Set(ids); const list=S.msgs.get(cid); if(list) S.msgs.set(cid,list.filter(x=>!set.has(x.id)));
  if(cid===S.cur){ ids.forEach(id=>{ const el=$('#mw')?.querySelector(`.m[data-id="${id}"]`); if(el){ el.style.transition='opacity .2s, transform .2s'; el.style.opacity='0'; el.style.transform='scale(.9)'; setTimeout(()=>{ el.remove(); },200); } }); setTimeout(()=>{ try{ renderMsgs(); }catch{} },230); }
  const c=S.chatMap.get(cid); if(c&&set.has(c.last_id)) loadChats(); }
// удалить: у всех (исчезает у всех) или только у себя
function delDlg(list){ list=list.filter(m=>m&&m.id>0); if(!list.length) return; const c=cur(); const saved=c?.type==='private'&&c.peer_id===S.me.id;
  const forAll=!saved&&(list.every(m=>m.sender_id===S.me.id)||(['owner','admin'].includes(c?.role)&&c?.type!=='private'));
  const n=list.length; const ttl=n>1?`Удалить ${n} ${plural(n,'сообщение','сообщения','сообщений')}?`:'Удалить сообщение?';
  const go=async everyone=>{ const ids=list.map(m=>m.id), cid=list[0].chat_id; dropMsgs(cid,ids);
    for(const id of ids){ const {error}=everyone?await sb.from('lm_messages').update({deleted:true}).eq('id',id):await sb.from('lm_hidden').upsert({message_id:id,chat_id:cid},{onConflict:'user_id,message_id',ignoreDuplicates:true}); if(error){ toast(error.message); break; } if(!everyone) S.hidden.add(id); }
    if(everyone&&c&&ids.includes(c.pinned_message_id)){ await sb.from('lm_chats').update({pinned_message_id:null}).eq('id',cid); c.pinned_message_id=null; renderPin(); } };
  const btns=[['Отмена','ghost']];
  if(forAll) btns.push([c?.type==='private'?'Удалить у меня и у '+esc(chatName(c)):'Удалить у всех','danger',x=>{ x(); go(true); }]);
  btns.push([saved?'Удалить':'Удалить только у меня',forAll?'ghost':'danger',x=>{ x(); go(saved); }]);
  modal(ttl,'<p style="margin:4px 0 8px;color:var(--muted)">'+(forAll?'Выберите, у кого удалить.':'Сообщение исчезнет только у вас.')+'</p>',btns); }
const typChans=new Map();
function typingChan(id){ let ch=typChans.get(id); if(ch) return ch;
ch=sb.channel('lm-typing-'+id,{config:{broadcast:{self:false}}})
.on('broadcast',{event:'typing'},({payload:p})=>{
if(p.uid===S.me.id) return; let m=S.typing.get(id); if(!m){ m=new Map(); S.typing.set(id,m); }
const old=m.get(p.uid); if(old) clearTimeout(old.t);
if(p.act==='stop'){ m.delete(p.uid); if(S.cur===id) renderHead(); renderList(); return; }
m.set(p.uid,{name:p.name,act:p.act||'typing',t:setTimeout(()=>{ m.delete(p.uid); if(S.cur===id) renderHead(); renderList(); },4000)});
if(S.cur===id) renderHead(); renderList(); })
.subscribe(); typChans.set(id,ch); return ch; }
// \u00abпечатает\u2026\u00bb слушаем во всех недавних чатах \u2014 чтобы видеть его прямо в списке
function syncTyping(){ if(!sb||!S.me) return; const want=new Set(S.chats.slice(0,40).map(c=>c.chat_id)); if(S.cur) want.add(S.cur);
  for(const [id,ch] of typChans) if(!want.has(id)){ try{ sb.removeChannel(ch); }catch{} typChans.delete(id); }
  want.forEach(id=>typingChan(id)); }
function subscribeTyping(id){ typChan=typingChan(id); }
function sendTyping(){ (S.cur?typingChan(S.cur):typChan)?.send({type:'broadcast',event:'typing',payload:{uid:S.me.id,name:S.me.name}}); }
/* «записывает голосовое / видеосообщение…» — как в приложениях */
function sendAct(act){ (S.cur?typingChan(S.cur):typChan)?.send({type:'broadcast',event:'typing',payload:{uid:S.me.id,name:S.me.name,act}}); }
window.typVerb=v=>v&&v.act==='voice'?'записывает голосовое':v&&v.act==='video'?'записывает видеосообщение':'печатает';
/* notifications */
let actx;
function beep(f=880,d=.12,v=.06){ try{ actx=actx||new (window.AudioContext||window.webkitAudioContext)(); const o=actx.createOscillator(), g=actx.createGain(); o.frequency.value=f; o.type='sine'; g.gain.setValueAtTime(v,actx.currentTime); g.gain.exponentialRampToValueAtTime(.0001,actx.currentTime+d); o.connect(g).connect(actx.destination); o.start(); o.stop(actx.currentTime+d); }catch{} }
function notify(m){
const c=S.chatMap.get(m.chat_id); if(!c||c.muted||m.sender_id===S.me.id||m.kind==='system') return;
const lfU=!!(m.meta&&m.meta.urgent===true); if(!lfU&&window.lfQuiet&&window.lfQuiet()) return;
const p=S.profiles.get(m.sender_id);
const title=(lfU?'Срочно · ':'')+(c.type==='private'?(p?.name||'Lumo'):chatName(c));
const text=(c.type==='group'&&p?p.name+': ':'')+(m.kind==='text'?plain(m.body):(kindLabel(m.kind,m.body)?.[1]||'Новое сообщение'));
if(localStorage.getItem('lm_sound')!=='0'){ beep(880,.09); setTimeout(()=>beep(1320,.12),90); }
try{ if(localStorage.getItem('lm_vibe')!=='0') navigator.vibrate?.([60,40,60]); }catch{}
if(document.hidden||!document.hasFocus()){
  flashTitle(title);
  if(canNotify()){
    showNote(title,{body:text,icon:p?.avatar_url||NOTE_ICON,tag:m.chat_id,renotify:true},()=>{ setTab('chats'); openChat(m.chat_id); });
  }
} else if(m.chat_id!==S.cur || (innerWidth<=800&&!$('#app').classList.contains('inchat'))){
  banner(c.type==='private'?{name:p?.name,avatar:p?.avatar_url,color:p?.color}:{name:c.title,avatar:c.avatar_url,color:c.color}, title, text, ()=>{ setTab('chats'); openChat(m.chat_id); });
}
}
let bannerT;
function banner(av,title,text,onclick){
  $('#nbanner')?.remove(); clearTimeout(bannerT);
  const d=document.createElement('div'); d.id='nbanner';
  d.innerHTML=`${avatar(av,'s')}<div class="tx"><b>${esc(title)}</b><span>${esc(text)}</span></div>`;
  d.onclick=()=>{ d.remove(); onclick&&onclick(); };
  let y0=null; d.addEventListener('touchstart',e=>{ y0=e.touches[0].clientY; },{passive:true});
  d.addEventListener('touchmove',e=>{ if(y0!=null&&e.touches[0].clientY-y0<-25) d.remove(); },{passive:true});
  document.body.appendChild(d); bannerT=setTimeout(()=>d.remove(),4500);
}
let flashI=null; const baseTitle=()=>{ const n=S.chats.filter(c=>!c.muted).reduce((a,c)=>a+c.unread,0); return n?`(${n}) Lumo`:'Lumo'; };
function flashTitle(t){ clearInterval(flashI); let k=0; flashI=setInterval(()=>{ document.title=(k++%2)?baseTitle():'\u{1f4ac} '+t; if(!document.hidden){ clearInterval(flashI); flashI=null; document.title=baseTitle(); } },1100); }

/* уведомления в Telegram */
async function loadTg(){
  try{ const r=await fetch(FN+'/config'); const j=await r.json(); S.bot=j.bot; S.vapid=j.vapid||null; S.pwaUrl=j.pwa||null; }catch{ S.bot=null; }
if(window.LUMO_PWA&&window.Notification&&Notification.permission==='granted') pushSetup(false);
  const {data}=await sb.from('lm_tg_links').select('*').maybeSingle(); S.tg=data||null;
  if(S.bot&&!(S.tg&&S.tg.enabled)){ const {data:code}=await sb.rpc('lm_tg_code'); S.tgCode=code||null; }
  renderSettings(); renderList();
}
function tgCardHtml(){
  if(!S.bot) return `<div class="tgcard"><span class="tgi">${ic('send')}</span><div class="tx"><b>Уведомления в Telegram</b><span>Бот уведомлений ещё не подключён</span></div></div>`;
  if(S.tg&&S.tg.enabled) return `<div class="tgcard"><span class="tgi">${ic('send')}</span><div class="tx"><b>Уведомления в Telegram</b><span>Подключено${S.tg.tg_name?': '+esc(S.tg.tg_name):''} \u00b7 @${esc(S.bot)}</span></div><span class="tog on" id="tgOff" style="cursor:pointer"></span></div>`;
  const href=S.tgCode?`https://t.me/${S.bot}?start=${S.tgCode}`:`https://t.me/${S.bot}`;
  return `<div class="tgcard"><span class="tgi">${ic('send')}</span><div class="tx"><b>Уведомления в Telegram</b><span>Привяжите бота к этому аккаунту \u2014 сообщения и звонки придут в Telegram, когда Lumo закрыт</span></div><a class="tgbtn" id="tgOn" href="${href}" target="_blank" rel="noopener">Привязать</a></div>`;
}
let tgPoll=null;
function bindTg(){
  const off=$('#tgOff'); if(off) off.onclick=async()=>{ await sb.from('lm_tg_links').update({enabled:false}).eq('user_id',S.me.id); toast('Уведомления в Telegram отключены'); loadTg(); };
  const on=$('#tgOn'); if(on) on.addEventListener('click',()=>{ tgWaitLink(); return; clearInterval(tgPoll); let n=0;
    tgPoll=setInterval(async()=>{ if(++n>40){ clearInterval(tgPoll); return; } const {data}=await sb.from('lm_tg_links').select('*').maybeSingle();
      if(data&&data.enabled){ clearInterval(tgPoll); S.tg=data; toast('Telegram подключён \u2014 уведомления включены'); renderSettings(); } },3000); });
}
/* ================= CALLS (WebRTC) ================= */
const doneCalls=new Set();
const IS_IOS=/iPhone|iPad|iPod/i.test(navigator.userAgent)||(/Macintosh/.test(navigator.userAgent)&&navigator.maxTouchPoints>1);
const C={st:null,peer:null,video:false,speaker:false,pc:null,local:null,remote:null,callId:null,role:null,iceQ:[],t0:0,timer:null,ring:null,chatId:null,outCh:null,muted:false,camOff:false};
let myCallCh;
function setupCallChannel(){
myCallCh=sb.channel('lm-call-'+S.me.id,{config:{broadcast:{self:false}}}).on('broadcast',{event:'sig'},({payload})=>onSig(payload)).subscribe();
}
const outChans=new Map();
function outChan(to){ let ch=outChans.get(to);
if(!ch){ ch=sb.channel('lm-call-'+to,{config:{broadcast:{self:false}}}); ch._ready=new Promise(r=>ch.subscribe(s=>{ if(s==='SUBSCRIBED'){ ch._ok=1; r(); } })); outChans.set(to,ch); }
return ch; }
async function sig(to,data){
const payload={...data,from:S.me.id,callId:data.callId||C.callId}; if((data.t==='offer'||data.t==='answer')&&!data.auth) payload.nokey=1;
if(to===S.me.id){ try{ await myCallCh.send({type:'broadcast',event:'sig',payload}); }catch{} return; }
const ch=outChan(to);
await Promise.race([ch._ready,new Promise(r=>setTimeout(r,6000))]);
for(let i=0;i<3;i++){ try{ const r=await ch.send({type:'broadcast',event:'sig',payload}); if(r==='ok') return; }catch{} await new Promise(r=>setTimeout(r,400)); }
}
const sdpFp=s=>[...new Set([...String(s||'').matchAll(/a=fingerprint:(\S+) (\S+)/gi)].map(m=>m[1].toLowerCase()+' '+m[2].toUpperCase()))].sort().join(',');
async function sdpAuth(typ,sdp){ await C.secP; if(!C.secCid) return undefined; return E2E.encStr(C.secCid,`lumo-call1|${C.callId}|${typ}|${sdpFp(sdp)}`); }
async function sdpOk(p,typ){ await C.secP; if(!C.secCid) return true; if(!p.auth){ if(p.nokey){ callUnverified(); return true; } return false; } const x=await E2E.decStr(C.secCid,p.auth); return x===`lumo-call1|${C.callId}|${typ}|${sdpFp(p.sdp&&p.sdp.sdp)}`; }
function callUnverified(){ if(C._unv===C.callId) return; C._unv=C.callId; toast('У собеседника нет ключа шифрования на этом устройстве — подлинность звонка не проверена'); }
function callTampered(){ toast('Звонок остановлен: данные соединения подменены'); try{ hangup(); }catch{} }
/* ---- резервный канал звонка: звук и видео идут через сервер, если прямое соединение (P2P) заблокировано ---- */
const RL={on:false};
const MUD=(()=>{ const t=new Float32Array(256); for(let i=0;i<256;i++){ const u=~i&0xFF, sg=u&0x80, ex=(u>>4)&7, mn=u&0x0F; let x=((mn<<3)+0x84)<<ex; x-=0x84; t[i]=(sg?-x:x)/32768; } return t; })();
function muEnc(f){ let x=Math.round(Math.max(-1,Math.min(1,f))*32767); const sg=x<0?0x80:0; if(sg) x=-x; if(x>32635) x=32635; x+=0x84; let ex=7; for(let m=0x4000;(x&m)===0&&ex>0;ex--,m>>=1); const mn=(x>>(ex+3))&0x0F; return (~(sg|(ex<<4)|mn))&0xFF; }
let RCAPS=null;
async function relayCaps(){ if(RCAPS) return RCAPS; const c={a:0,v:[]};
try{ if(window.AudioEncoder&&window.AudioDecoder&&window.AudioData){ const e=await AudioEncoder.isConfigSupported({codec:'opus',sampleRate:48000,numberOfChannels:1,bitrate:32000}); const d=await AudioDecoder.isConfigSupported({codec:'opus',sampleRate:48000,numberOfChannels:1}); if(e.supported&&d.supported) c.a=1; } }catch{}
try{ if(window.VideoEncoder&&window.VideoDecoder&&window.VideoFrame){ for(const cd of ['vp8','avc1.42E01F']){ try{ const e=await VideoEncoder.isConfigSupported({codec:cd,width:360,height:480,bitrate:500000,framerate:15,...(cd.startsWith('avc')?{avc:{format:'annexb'}}:{})}); const d=await VideoDecoder.isConfigSupported({codec:cd}); if(e.supported&&d.supported) c.v.push(cd); }catch{} } } }catch{}
return RCAPS=c; }
relayCaps();
function p2pOn(){ return !!(C.pc&&C.pc.connectionState==='connected'); }
/* код проверки звонка (как в Telegram): 4 значка из ключей шифрования обоих устройств; тот же алгоритм на iOS и Android */
window.CC_ICONS=[['Звезда','star','#FFC93C','#FF8A00'],['Сердце','favorite','#FF5A7A','#E0245E'],['Луна','bedtime','#8E8CFF','#5B4BDB'],['Солнце','wb_sunny','#FFB703','#FB8500'],['Молния','bolt','#FFE066','#F4A100'],['Лист','eco','#7BD88F','#2E9E5B'],['Огонь','local_fire_department','#FF8A3D','#E63946'],['Капля','water_drop','#5AC8FA','#1A73E8'],['Снежинка','ac_unit','#A0E9FF','#4CA9E0'],['Облако','cloud','#B8C6FF','#6C7FD8'],['Самолёт','flight','#74C0FC','#3B82F6'],['Ключ','key','#FFD166','#D4A017'],['Колокол','notifications','#FFB4A2','#E5737F'],['Нота','music_note','#C77DFF','#7B2CBF'],['Камера','photo_camera','#9AA5B1','#52606D'],['Подарок','card_giftcard','#FF8FAB','#C9184A'],['Флаг','flag','#FF6B6B','#C92A2A'],['Планета','public','#63E6BE','#0CA678'],['Лапа','pets','#E6A57E','#A0522D'],['Машина','directions_car','#FF922B','#D9480F'],['Велосипед','pedal_bike','#94D82D','#5C940D'],['Дом','home','#F9A8D4','#DB2777'],['Парусник','sailing','#66D9E8','#1098AD'],['Мяч','sports_soccer','#CED4DA','#495057'],['Кубок','emoji_events','#FCC419','#E67700'],['Палитра','palette','#DA77F2','#9C36B5'],['Лампочка','lightbulb','#FFF3BF','#FAB005'],['Зонт','umbrella','#91A7FF','#4263EB'],['Компас','explore','#38D9A9','#087F5B'],['Гора','landscape','#A9E34B','#2B8A3E'],['Пазл','extension','#FFA94D','#E8590C'],['Дерево','park','#8CE99A','#2F9E44']];
window.ccFont=()=>{ if(document.getElementById('ccfont')) return; const l=document.createElement('link'); l.id='ccfont'; l.rel='stylesheet'; l.href='https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,600,1,0&display=block'; document.head.appendChild(l);
  const st=document.createElement('style'); st.textContent="#ccode{position:absolute;top:calc(14px + env(safe-area-inset-top));left:50%;transform:translateX(-50%);z-index:6;display:flex;gap:5px;padding:5px 8px;border-radius:99px;background:rgba(0,0,0,.35);-webkit-backdrop-filter:blur(14px);backdrop-filter:blur(14px);border:0;cursor:pointer}.cci{width:24px;height:24px;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;color:#fff;border:1px solid rgba(255,255,255,.35);animation:ccpop .5s cubic-bezier(.34,1.56,.64,1) both}.cci i{font-family:'Material Symbols Rounded';font-style:normal;font-size:15px;line-height:1;font-variation-settings:'FILL' 1,'wght' 600;text-shadow:0 1px 2px rgba(0,0,0,.2)}@keyframes ccpop{from{transform:scale(.2) rotate(-25deg);opacity:0}}#cccard{position:fixed;inset:0;z-index:99990;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,.55);animation:ccfade .2s both}#cccard .cb{margin:0 22px;max-width:420px;padding:22px;border-radius:28px;background:rgba(28,28,40,.92);-webkit-backdrop-filter:blur(20px);backdrop-filter:blur(20px);color:#fff;text-align:center;animation:ccin .42s cubic-bezier(.34,1.4,.64,1) both}#cccard .ic{display:flex;justify-content:center;gap:14px;margin-bottom:16px}#cccard .ic div{width:66px;display:flex;flex-direction:column;align-items:center;gap:7px;font-size:12px;font-weight:600;opacity:.9}#cccard .cci{width:58px;height:58px}#cccard .cci i{font-size:32px}#cccard h3{margin:0 0 8px;font-size:20px}#cccard p{margin:0 0 16px;font-size:15px;opacity:.8;line-height:1.35}#cccard button{width:100%;height:48px;border:0;border-radius:99px;background:rgba(255,255,255,.18);color:#fff;font-size:17px;font-weight:600;cursor:pointer}@keyframes ccfade{from{opacity:0}}@keyframes ccin{from{transform:scale(.85);opacity:0}}";
  document.head.appendChild(st); };
window.ccIcon=(i,k)=>{ const c=CC_ICONS[i%CC_ICONS.length]; return `<span class="cci" style="background:linear-gradient(135deg,${c[2]},${c[3]});box-shadow:0 2px 6px ${c[3]}73;animation-delay:${(k||0)*70}ms"><i>${c[1]}</i></span>`; };
window.ccMake=async()=>{ try{ if(!C.pc||!C.pc.localDescription||!C.pc.remoteDescription) return; const s=C.pc.localDescription.sdp+'\n'+C.pc.remoteDescription.sdp;
  const set=new Set(); for(const m of s.matchAll(/a=fingerprint:(\S+) (\S+)/gi)) set.add(m[1].toLowerCase()+' '+m[2].toUpperCase()); const fp=[...set].sort().join(','); if(set.size<2) return;
  const h=new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode('lumo-callcode1|'+fp))); const code=[0,1,2,3].map(i=>h[i]%CC_ICONS.length);
  if(C.code&&C.code.join()===code.join()) return; C.code=code; ccShow(); }catch(e){ console.warn('callcode',e); } };
window.ccShow=()=>{ let el=document.getElementById('ccode'); if(!C.code||!C.st){ if(el) el.remove(); return; } const host=document.getElementById('call'); if(!host) return; ccFont();
  if(!el){ el=document.createElement('button'); el.id='ccode'; el.title='Код проверки звонка'; el.onclick=ccCard; host.appendChild(el); } el.innerHTML=C.code.map((i,k)=>ccIcon(i,k)).join(''); };
window.ccCard=()=>{ if(!C.code) return; const d=document.createElement('div'); d.id='cccard';
  d.innerHTML=`<div class="cb"><div class="ic">${C.code.map((i,k)=>`<div>${ccIcon(i,k+1)}${esc(CC_ICONS[i][0])}</div>`).join('')}</div><h3>Звонок зашифрован</h3><p>Если у собеседника на экране те же четыре значка, разговор защищён сквозным шифрованием и никто посередине его не слышит.</p><button>Понятно</button></div>`;
  d.onclick=e=>{ if(e.target===d||e.target.tagName==='BUTTON') d.remove(); }; document.body.appendChild(d); };
function relaySending(){ return false; }
function relayStart(){
if(RL.on||!C.local) return;
let ctx; try{ ctx=C.ctx&&C.ctx.state!=='closed'?C.ctx:(C.ctx=new (window.AudioContext||window.webkitAudioContext)()); ctx.resume?.(); }catch{ return; }
const mc=RCAPS||{a:0,v:[]}, pc=C.peerCaps||{a:0,v:[]};
const aMode=(mc.a&&pc.a)?'opus':'mu', vCodec=(mc.v||[]).find(x=>(pc.v||[]).includes(x))||null;
Object.assign(RL,{on:true,ctx,buf:[],pos:0,seq:0,rseq:-1,next:0,gotV:0,lastV:0,vmode:null,aMode,vCodec,aq:[],vq:[],ats:0,vts:0,dts:0,vdts:0,fi:0,needKey:true,vwait:true,jt:0.14,lastUnder:0,jpg:null,vcfg:null});
try{
  RL.out=ctx.createGain();
  if(ctx.createMediaStreamDestination){ RL.dest=ctx.createMediaStreamDestination(); RL.out.connect(RL.dest); const a=$('#rra'); if(a){ a.srcObject=RL.dest.stream; a.play().catch(()=>{}); } }
  else RL.out.connect(ctx.destination);
  if(aMode==='opus'){ try{ RL.aenc=new AudioEncoder({output:ch=>{ const b=new Uint8Array(ch.byteLength); ch.copyTo(b); RL.aq.push(b); },error:e=>{ console.warn('aenc',e); RL.aMode='mu'; }}); RL.aenc.configure({codec:'opus',sampleRate:48000,numberOfChannels:1,bitrate:32000}); }catch(e){ RL.aMode='mu'; } }
  if(C.local.getAudioTracks().length){
    RL.src=ctx.createMediaStreamSource(C.local); RL.proc=ctx.createScriptProcessor(2048,1,1); const ratio=ctx.sampleRate/16000;
    RL.proc.onaudioprocess=e=>{ e.outputBuffer.getChannelData(0).fill(0); if(!relaySending()||C.muted){ RL.pos=0; return; }
      const d=e.inputBuffer.getChannelData(0);
      if(RL.aMode==='opus'&&RL.aenc&&RL.aenc.state==='configured'){ try{ const f=resampleTo(d,ctx.sampleRate,48000); const ad=new AudioData({format:'f32-planar',sampleRate:48000,numberOfFrames:f.length,numberOfChannels:1,timestamp:RL.ats,data:f}); RL.ats+=Math.round(f.length/0.048); RL.aenc.encode(ad); ad.close(); }catch(err){ console.warn(err); RL.aMode='mu'; } return; }
      let p=RL.pos;
      while(p<d.length){ const a=p|0, b=Math.min(d.length,(p+ratio)|0); let sum=0,n=0; for(let i=a;i<b;i++){ sum+=d[i]; n++; } RL.buf.push(n?sum/n:d[a]); p+=ratio; }
      RL.pos=p-d.length; if(RL.buf.length>16000) RL.buf.splice(0,RL.buf.length-8000); };
    RL.src.connect(RL.proc); RL.proc.connect(ctx.destination);
  }
}catch(e){ console.warn('relay audio',e); }
RL.vid=document.createElement('video'); RL.vid.muted=true; RL.vid.playsInline=true; RL.vid.setAttribute('playsinline',''); RL.vid.style.cssText='position:absolute;width:2px;height:2px;opacity:0;pointer-events:none';
RL.vid.srcObject=C.local; ($('#call')||document.body).appendChild(RL.vid); RL.vid.play().catch(()=>{});
RL.cv=document.createElement('canvas'); RL.cx=RL.cv.getContext('2d');
if(vCodec){ try{ RL.venc=new VideoEncoder({output:ch=>{ const b=new Uint8Array(ch.byteLength); ch.copyTo(b); RL.vq.push([ch.type==='key'?1:0,b]); },error:e=>{ console.warn('venc',e); RL.vCodec=null; }}); }catch{ RL.vCodec=null; } }
RL.tick=setInterval(relayFlush,200);
RL.vt=setInterval(relayVideoTick,66);
RL.hb=setInterval(()=>{ if(C.st==='active') sig(C.peer,{t:'hb'}); },4000);
RL.watch=setInterval(()=>{ if(C.st==='active'&&!C.everUp&&C.t0&&Date.now()-C.t0>30000){ toast('Не удалось соединиться'); hangup(); return; } if(C.st==='active'&&!p2pOn()&&(Date.now()-(C.lastPeer||0)>45000||(C.downT&&Date.now()-C.downT>45000))){ toast('Связь с собеседником потеряна'); hangup(); } },3000);
}
function resampleTo(d,from,to){ if(from===to) return new Float32Array(d); const n=Math.floor(d.length*to/from), o=new Float32Array(n), r=from/to; for(let i=0;i<n;i++){ const x=i*r, j=x|0, f=x-j, a=d[j], b=j+1<d.length?d[j+1]:a; o[i]=a+(b-a)*f; } return o; }
function b64(u){ let s=''; for(let i=0;i<u.length;i+=8192) s+=String.fromCharCode.apply(null,u.subarray(i,i+8192)); return btoa(s); }
function ub64(s){ const bin=atob(s), u=new Uint8Array(bin.length); for(let i=0;i<bin.length;i++) u[i]=bin.charCodeAt(i); return u; }
function packFrames(arr){ let n=0; for(const b of arr) n+=4+b.length; const o=new Uint8Array(n); let p=0; for(const b of arr){ const l=b.length; o[p]=(l>>>24)&255; o[p+1]=(l>>>16)&255; o[p+2]=(l>>>8)&255; o[p+3]=l&255; o.set(b,p+4); p+=4+l; } return o; }
function unpackFrames(u){ const r=[]; let p=0; while(p+4<=u.length){ const n=((u[p]<<24)|(u[p+1]<<16)|(u[p+2]<<8)|u[p+3])>>>0; r.push(u.subarray(p+4,p+4+n)); p+=4+n; } return r; }
function relayVideoTick(){
if(!RL.on||!relaySending()||!C.video||C.camOff) return; const v=RL.vid; if(!v||!v.videoWidth) return;
if(RL.vCodec&&RL.venc&&RL.venc.state!=='closed'){
  if(RL.venc.encodeQueueSize>2) return;
  let h=480, w=Math.round(h*v.videoWidth/v.videoHeight/2)*2; if(w>640){ w=640; h=Math.round(w*v.videoHeight/v.videoWidth/2)*2; }
  if(!RL.vcfg||RL.vcfg.w!==w||RL.vcfg.h!==h){ try{ RL.venc.configure({codec:RL.vCodec,width:w,height:h,bitrate:500000,framerate:15,latencyMode:'realtime',...(RL.vCodec.startsWith('avc')?{avc:{format:'annexb'}}:{})}); RL.vcfg={w,h}; RL.needKey=true; }catch(e){ console.warn(e); RL.vCodec=null; return; } }
  if(RL.cv.width!==w||RL.cv.height!==h){ RL.cv.width=w; RL.cv.height=h; }
  try{ RL.cx.drawImage(v,0,0,w,h); const fr=new VideoFrame(RL.cv,{timestamp:RL.vts}); RL.vts+=66666; const key=RL.needKey||(RL.fi++%45===0); RL.needKey=false; RL.venc.encode(fr,{keyFrame:key}); fr.close(); }catch(e){ console.warn(e); RL.vCodec=null; }
  return; }
if((RL.fi++%3)!==0) return;
const w=320, h=Math.min(480,Math.round(w*v.videoHeight/v.videoWidth)); if(RL.cv.width!==w||RL.cv.height!==h){ RL.cv.width=w; RL.cv.height=h; }
try{ RL.cx.drawImage(v,0,0,w,h); RL.jpg=RL.cv.toDataURL('image/jpeg',0.6).split(',')[1]; }catch{}
}
async function relayFlush(){
if(!RL.on||!C.st) return;
if(!relaySending()){ RL.buf=[]; RL.aq=[]; RL.vq=[]; RL.jpg=null; return; }
const pl={t:'rm',s:RL.seq++};
if(RL.aq.length){ pl.o=b64(packFrames(RL.aq)); RL.aq=[]; }
else if(RL.buf.length){ const b=RL.buf; RL.buf=[]; const u=new Uint8Array(b.length); for(let i=0;i<b.length;i++) u[i]=muEnc(b[i]); pl.a=b64(u); }
if(RL.vq.length){ pl.vc=RL.vCodec; pl.vk=RL.vq.map(x=>x[0]).join(''); pl.vf=b64(packFrames(RL.vq.map(x=>x[1]))); RL.vq=[]; }
else if(RL.jpg){ pl.v=RL.jpg; RL.jpg=null; }
if(!pl.a&&!pl.o&&!pl.vf&&!pl.v) return;
if(!C.secCid) return;
const {t:_t,s:_s,...med}=pl; const e=await E2E.encStr(C.secCid,JSON.stringify(med)); if(!e) return;
const ch=outChan(C.peer); ch.send({type:'broadcast',event:'sig',payload:{t:'rm',s:pl.s,e,from:S.me.id,callId:C.callId}}).catch(()=>{});
}
function relaySchedule(f32,sr){
const ctx=RL.ctx; if(!ctx||!RL.out) return; const buf=ctx.createBuffer(1,f32.length,sr); buf.getChannelData(0).set(f32); const now=ctx.currentTime;
if(RL.next<now+0.02){ if(RL.next>0){ RL.jt=Math.min(0.5,RL.jt+0.04); RL.lastUnder=now; } RL.next=now+RL.jt; }
else if(now-RL.lastUnder>6&&RL.jt>0.1){ RL.jt=Math.max(0.1,RL.jt-0.01); RL.lastUnder=now; }
if(RL.next>now+RL.jt+0.6) return;
const sn=ctx.createBufferSource(); sn.buffer=buf; sn.connect(RL.out); sn.start(RL.next); RL.next+=buf.duration;
const a=$('#rra'); if(a&&a.paused) a.play().catch(()=>{});
}
function askKey(){ if(Date.now()-(RL.lastAsk||0)<1000) return; RL.lastAsk=Date.now(); sig(C.peer,{t:'kf'}); }
function relayRecv(p){
if(!RL.on) return;
if(p.s<=RL.rseq) return; const gap=RL.rseq>=0&&p.s!==RL.rseq+1; RL.rseq=p.s;
if(p.o&&window.AudioDecoder){ try{
  if(!RL.adec||RL.adec.state==='closed'){ RL.adec=new AudioDecoder({output:ad=>{ const n=ad.numberOfFrames, f=new Float32Array(n); try{ ad.copyTo(f,{planeIndex:0,format:'f32-planar'}); }catch{ try{ ad.copyTo(f,{planeIndex:0}); }catch{} } const sr=ad.sampleRate; ad.close(); relaySchedule(f,sr); },error:e=>{ console.warn('adec',e); RL.adec=null; }}); RL.adec.configure({codec:'opus',sampleRate:48000,numberOfChannels:1}); }
  for(const fr of unpackFrames(ub64(p.o))){ RL.adec.decode(new EncodedAudioChunk({type:'key',timestamp:RL.dts,data:fr})); RL.dts+=20000; }
}catch(e){ console.warn(e); } }
else if(p.a){ try{ const ctx=RL.ctx, bin=atob(p.a), n=bin.length, sr=ctx.sampleRate, ratio=sr/16000, m=Math.floor(n*ratio), f=new Float32Array(m);
  for(let i=0;i<m;i++){ const x=i/ratio, j=x|0, fr=x-j, a=MUD[bin.charCodeAt(j)], c=j+1<n?MUD[bin.charCodeAt(j+1)]:a; f[i]=a+(c-a)*fr; }
  relaySchedule(f,sr); }catch{} }
if(p.vf&&p.vc&&window.VideoDecoder){ try{
  if(!RL.vdec||RL.vdecCodec!==p.vc||RL.vdec.state==='closed'){ try{ RL.vdec?.close(); }catch{}
    RL.vdec=new VideoDecoder({output:f=>{ const c=$('#rcv'); if(c){ if(c.width!==f.displayWidth||c.height!==f.displayHeight){ c.width=f.displayWidth; c.height=f.displayHeight; } c.getContext('2d').drawImage(f,0,0); } f.close(); RL.lastV=Date.now(); if(RL.vmode!=='codec'||!RL.gotV){ RL.vmode='codec'; RL.gotV=1; callUI(); } },
      error:e=>{ console.warn('vdec',e); RL.vwait=true; RL.vdec=null; askKey(); }});
    RL.vdec.configure({codec:p.vc,optimizeForLatency:true}); RL.vdecCodec=p.vc; RL.vwait=true; }
  if(gap){ RL.vwait=true; }
  const fs=unpackFrames(ub64(p.vf)), ks=String(p.vk||'');
  fs.forEach((fr,i)=>{ const k=ks[i]==='1'; if(RL.vwait&&!k) return; if(k) RL.vwait=false; RL.vdts+=66666; RL.vdec.decode(new EncodedVideoChunk({type:k?'key':'delta',timestamp:RL.vdts,data:fr})); });
  if(RL.vwait) askKey();
}catch(e){ console.warn(e); RL.vwait=true; askKey(); } }
else if(p.v){ const im=$('#rimg'); if(im) im.src='data:image/jpeg;base64,'+p.v; RL.lastV=Date.now(); if(RL.vmode!=='jpg'||!RL.gotV){ RL.vmode='jpg'; RL.gotV=1; callUI(); } }
}
function relayStop(){
if(!RL.on) return; RL.on=false; clearInterval(RL.tick); clearInterval(RL.vt); clearInterval(RL.hb); clearInterval(RL.watch);
try{ RL.proc&&(RL.proc.onaudioprocess=null); RL.src?.disconnect(); RL.proc?.disconnect(); RL.out?.disconnect(); }catch{}
for(const k of ['aenc','adec','venc','vdec']){ try{ if(RL[k]&&RL[k].state!=='closed') RL[k].close(); }catch{} RL[k]=null; }
try{ RL.vid.srcObject=null; RL.vid.remove(); }catch{}
Object.assign(RL,{src:null,proc:null,out:null,dest:null,vid:null,cv:null,cx:null,buf:[],aq:[],vq:[],jpg:null});
}
function startActive(){
if(!C.st||C.t0) return; C.t0=Date.now(); C.st='active'; C.lastPeer=Date.now(); relayStart(); callUI();
clearInterval(C.timer); C.timer=setInterval(()=>{ document.querySelectorAll('#ctime').forEach(t=>t.textContent=fmtDur((Date.now()-C.t0)/1000)); },1000);
}
let iceCache=null;
async function getIce(){
  if(iceCache&&Date.now()-iceCache.t<6*3600e3) return iceCache.v;
  try{ const ctl=new AbortController(); setTimeout(()=>ctl.abort(),5000);
    const r=await fetch(FN+'/ice',{signal:ctl.signal}); const j=await r.json(); if(j.iceServers?.length){ iceCache={t:Date.now(),v:j.iceServers}; return j.iceServers; } }catch{}
  return ICE;
}
async function pingCallTg(peer,video){ try{ const {data:{session}}=await sb.auth.getSession(); await fetch(FN+'/call',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+session.access_token},body:JSON.stringify({peer_id:peer,video})}); }catch{} }
async function startCall(video){
const c=cur(); if(!c||c.type!=='private'||c.peer_id===S.me.id) return; if(C.st) return toast('Вы уже в звонке');
{ const bs=peerState(c); if(bs) return toast(bs.t); }
try{ C.ctx=new (window.AudioContext||window.webkitAudioContext)(); C.ctx.resume?.(); }catch{}
callAudioInit(); C.speaker=!!video;
const rc=await relayCaps();
try{ C.local=await navigator.mediaDevices.getUserMedia({audio:AUD_C,video:video?VID_C('user'):false}); }catch{ try{ C.local=await navigator.mediaDevices.getUserMedia({audio:true,video:video?{facingMode:'user'}:false}); }catch{ try{ C.ctx?.close(); }catch{} C.ctx=null; return toast('Нет доступа к '+(video?'камере/микрофону':'микрофону')); } }
hintTracks(C.local);
Object.assign(C,{ringing:false,st:'calling',peer:c.peer_id,video,speaker:!!video,callId:uid8(),role:'caller',iceQ:[],chatId:c.chat_id,muted:false,camOff:false,pendingOffer:null,facing:'user',secCid:null});
C.secP=E2E.callKey(c.peer_id).then(v=>{ C.secCid=v; });
callUI(); callLog('start',{to:c.peer_id,video}); setTimeout(()=>{ if(C.st==='calling'&&!C.ringing&&S.online.has(C.peer)){ C.ringing=true; callUI(); } },800);
getIce(); outChan(C.peer); pingCallTg(C.peer,video);
const ringPl={t:'ring',video,name:S.me.name,avatar:S.me.avatar_url,color:S.me.color,chatId:c.chat_id,rc};
await sig(C.peer,ringPl);
clearInterval(C.reRing); C.reRing=setInterval(()=>{ if(C.st==='calling'&&C.callId===ringPl.callId) sig(C.peer,ringPl); else clearInterval(C.reRing); },3000); ringPl.callId=C.callId;
C.timeoutT=setTimeout(()=>{ if(C.st==='calling'){ sig(C.peer,{t:'cancel'}); endCall('missed'); } },45000);
}
async function onSig(p){
if(p.t==='rm'){ if(false&&C.st==='active'&&p.callId===C.callId&&p.from===C.peer){ C.lastPeer=Date.now(); if(!C.secCid||!p.e) return; C.rmQ=(C.rmQ||Promise.resolve()).then(async()=>{ const x=await E2E.decStr(C.secCid,p.e); let m; try{ m=JSON.parse(x); }catch{ return; } if(m&&typeof m==='object') relayRecv({...m,s:p.s}); }).catch(()=>{}); } return; }
if(p.t==='ring'){
if(doneCalls.has(p.callId)) return;
if(S.blocks.mine.has(p.from)||S.profiles.get(p.from)?.banned){ doneCalls.add(p.callId); sig(p.from,{t:'nocall',callId:p.callId}); return; }
if(C.st){ if(p.callId!==C.callId) sig(p.from,{t:'busy',callId:p.callId}); else if(C.st==='incoming') sig(p.from,{t:'ringing',callId:p.callId}); return; }
{ const cf=S.me?.calls_from||'all'; if(cf==='none'||(cf==='contacts'&&!isContact(p.from))){ doneCalls.add(p.callId); sig(p.from,{t:'nocall',callId:p.callId}); return; } }
Object.assign(C,{st:'incoming',peer:p.from,video:p.video,speaker:!!p.video,callId:p.callId,role:'callee',iceQ:[],chatId:p.chatId,peerCaps:p.rc||null,peerName:p.name,peerAvatar:p.avatar,peerColor:p.color,muted:false,camOff:false,pendingOffer:null,facing:'user',secCid:null});
C.secP=E2E.callKey(p.from).then(v=>{ C.secCid=v; });
callUI(); ringtone('in'); notifyCall(p); sig(p.from,{t:'ringing',callId:p.callId}); callLog('ring_in',{from:p.from}); C.inT=setTimeout(()=>{ if(C.st==='incoming') endCall('missed',true); },50000); return;
}
if(p.t==='taken'){ if(C.st==='incoming'&&p.callId===C.callId) endCall('elsewhere',true); return; }
if(!C.st || p.callId!==C.callId || p.from!==C.peer) return;
if(C.st==='incoming'&&(p.t==='offer'||p.t==='ice'||p.t==='hb')){ endCall('elsewhere',true); return; }
C.lastPeer=Date.now();
switch(p.t){
case 'accept': if(C.st!=='calling') return; clearTimeout(C.timeoutT); clearInterval(C.reRing); stopRing(); C.peerCaps=p.rc||null; startActive(); await makePC(); if(!C.pc) return;
  try{ const o=await C.pc.createOffer(); const od={type:o.type,sdp:opusTune(o.sdp)}; await C.pc.setLocalDescription(od); sig(C.peer,{t:'offer',sdp:od,auth:await sdpAuth('offer',od.sdp)}); }catch(e){ console.warn(e); } break;
case 'offer': if(!C.pc){ C.pendingOffer=p; return; }
  if(!(await sdpOk(p,'offer'))) return callTampered();
  try{ await C.pc.setRemoteDescription(p.sdp); const a=await C.pc.createAnswer(); const ad={type:a.type,sdp:opusTune(a.sdp)}; await C.pc.setLocalDescription(ad); sig(C.peer,{t:'answer',sdp:ad,auth:await sdpAuth('answer',ad.sdp)}); flushIce(); }catch(e){ console.warn(e); } break;
case 'answer': if(!C.pc) return; if(!(await sdpOk(p,'answer'))) return callTampered(); try{ await C.pc.setRemoteDescription(p.sdp); flushIce(); }catch(e){ console.warn(e); } break;
case 'ice': if(C.pc&&C.pc.remoteDescription) C.pc.addIceCandidate(p.c).catch(()=>{}); else C.iceQ.push(p.c); break;
case 'reject': endCall('rejected'); toast('Звонок отклонён'); break;
case 'busy': endCall('missed'); toast('Абонент занят'); break;
case 'nocall': endCall('missed'); toast('Пользователь ограничил входящие звонки'); break;
case 'cancel': endCall('missed',true); break;
case 'hangup': endCall(C.t0?'ended':'missed',true); break;
case 'media': C.peerCamOff=p.camOff; if(p.video&&!C.video){ C.video=true; C.speaker=true; C.outKey=null; applyOut(); } callUI(); break;
case 'restart': if(C.role==='caller') restartIce(); break;
case 'ringing': if(C.st==='calling'&&!C.ringing){ C.ringing=true; callUI(); } break;
case 'hb': break;
case 'kf': RL.needKey=true; break;
}
}
async function restartIce(){ if(!C.pc) return; try{ const o=await C.pc.createOffer({iceRestart:true}); const od={type:o.type,sdp:opusTune(o.sdp)}; await C.pc.setLocalDescription(od); sig(C.peer,{t:'offer',sdp:od,auth:await sdpAuth('offer',od.sdp)}); }catch{} }
// качество P2P: чистый звук (шумодав, эхо, автоуровень), HD-видео, устойчивый Opus с коррекцией потерь
const AUD_C={echoCancellation:true,noiseSuppression:true,autoGainControl:true,channelCount:1};
const VID_C=f=>({facingMode:f,width:{ideal:1280},height:{ideal:720},frameRate:{ideal:30,max:30}});
function hintTracks(st){ try{ st.getAudioTracks().forEach(t=>t.contentHint='speech'); st.getVideoTracks().forEach(t=>t.contentHint='motion'); }catch{} }
function opusTune(sdp){ try{ const m=sdp.match(/a=rtpmap:(\d+) opus\/48000/i); if(!m) return sdp; const pt=m[1]; const re=new RegExp('a=fmtp:'+pt+' ([^\\r\\n]*)');
  return sdp.replace(re,(all,par)=>{ let q=par; if(!/useinbandfec/.test(q)) q+=';useinbandfec=1'; if(!/maxaveragebitrate/.test(q)) q+=';maxaveragebitrate=64000'; if(!/maxplaybackrate/.test(q)) q+=';maxplaybackrate=48000'; return 'a=fmtp:'+pt+' '+q; }); }catch{ return sdp; } }
async function tuneSenders(pc){ for(const s of pc.getSenders()){ if(!s.track) continue; try{ const p=s.getParameters(); if(!p.encodings||!p.encodings.length) continue;
  if(s.track.kind==='video'){ p.encodings[0].maxBitrate=2500000; p.encodings[0].maxFramerate=30; p.encodings[0].priority='high'; p.encodings[0].networkPriority='high'; p.degradationPreference='balanced'; } else { p.encodings[0].maxBitrate=96000; p.encodings[0].priority='high'; p.encodings[0].networkPriority='high'; }
  await s.setParameters(p); }catch{} } }
async function flipCallCam(){
  if(!C.local) return; const old=C.facing||'user', nf=old==='environment'?'user':'environment';
  const prev=C.local.getVideoTracks(); prev.forEach(t=>t.stop());
  let nt=null; try{ nt=(await navigator.mediaDevices.getUserMedia({video:VID_C(nf)})).getVideoTracks()[0]; C.facing=nf; try{ nt.contentHint='motion'; }catch{} }
  catch{ try{ nt=(await navigator.mediaDevices.getUserMedia({video:{facingMode:old}})).getVideoTracks()[0]; }catch{} toast('Не удалось переключить камеру'); }
  prev.forEach(t=>C.local.removeTrack(t)); if(!nt){ callUI(); return; }
  C.local.addTrack(nt); nt.enabled=!C.camOff;
  const snd=C.pc?.getSenders().find(x=>x.track===null||x.track?.kind==='video'); if(snd) try{ await snd.replaceTrack(nt); }catch{}
  if(RL.vid){ RL.vid.srcObject=C.local; RL.vid.play().catch(()=>{}); }
  const lv=$('#lv'); if(lv){ lv.srcObject=null; }
  callUI();
}
function flushIce(){ C.iceQ.forEach(c=>C.pc.addIceCandidate(c).catch(()=>{})); C.iceQ=[]; }
async function makePC(){
const ice=await getIce(); if(!C.st||!C.local||C.pc) return; const pc=new RTCPeerConnection({iceServers:ice,iceCandidatePoolSize:4}); C.pc=pc; C.restarts=0;
C.local.getTracks().forEach(t=>pc.addTrack(t,C.local));
pc.onicecandidate=e=>{ if(e.candidate&&C.pc===pc) sig(C.peer,{t:'ice',c:e.candidate.toJSON()}); };
pc.ontrack=e=>{ C.remote=e.streams[0]||new MediaStream([e.track]); if(e.track.kind==='video'&&!C.video&&C.st==='active'){ C.video=true; C.speaker=true; C.outKey=null; applyOut(); } if(C.remote&&e.track&&!C.remote.getTracks().includes(e.track)){ try{ C.remote.addTrack(e.track); }catch{} } if(C.st) callUI(); };
pc.onconnectionstatechange=()=>{ if(C.pc!==pc) return; const s=pc.connectionState;
if(s==='connected'){ C.restarts=0; C.everUp=true; C.reconn=false; C.downT=0; clearTimeout(C.rT); if(!C.t0) startActive(); callUI(); tuneSenders(pc); window.ccMake&&ccMake(); }
if(s==='failed'||s==='disconnected'){ if(C.everUp){ C.reconn=true; if(!C.downT) C.downT=Date.now(); } if(C.st) callUI(); clearTimeout(C.rT);
  const tryR=()=>{ if(C.pc!==pc||!C.st) return; const st=pc.connectionState; if(st==='connected'||st==='closed') return;
    C.restarts++; if(C.role==='caller') restartIce(); else sig(C.peer,{t:'restart'}); C.rT=setTimeout(tryR,3000); };
  C.rT=setTimeout(tryR, s==='failed'?300:1000); }
};
}
async function acceptCall(){
if(C.st!=='incoming') return; stopRing(); clearTimeout(C.inT); const id=C.callId; C.st='answering'; callUI();
try{ C.ctx=new (window.AudioContext||window.webkitAudioContext)(); C.ctx.resume?.(); }catch{}
callAudioInit();
let st=null;
try{ st=await navigator.mediaDevices.getUserMedia({audio:AUD_C,video:C.video?VID_C('user'):false}); }
catch{ try{ st=await navigator.mediaDevices.getUserMedia({audio:true}); C.video=false; }catch{ toast('Нет доступа к микрофону'); C.st='incoming'; return rejectCall(); } }
if(C.callId!==id||!C.st){ st.getTracks().forEach(t=>t.stop()); return; }
C.speaker=!!C.video; C.local=st; hintTracks(st); sig(C.peer,{t:'accept',rc:await relayCaps()}); sig(S.me.id,{t:'taken'}); startActive();
await makePC(); if(C.callId!==id||!C.st||!C.pc) return;
if(C.pendingOffer){ const po=C.pendingOffer; C.pendingOffer=null; await onSig(po); }
}
function rejectCall(){ if(!C.st) return; sig(C.peer,{t:'reject'}); sig(S.me.id,{t:'taken'}); endCall('rejected',true); }
function hangup(){ if(!C.st) return; sig(C.peer,{t:C.st==='calling'?'cancel':'hangup'}); endCall(C.t0?'ended':'missed'); }
async function endCall(status,remote=false){
if(!C.st) return; callLog('end',{status,remote}); const wasCaller=C.role==='caller', dur=C.t0?Math.round((Date.now()-C.t0)/1000):0, chatId=C.chatId, video=C.video;
stopRing(); relayStop(); try{ if(C.ctx&&C.ctx.state!=='closed') C.ctx.close(); }catch{} C.ctx=null; clearInterval(C.reRing); if(C.callId) doneCalls.add(C.callId); clearTimeout(C.timeoutT); clearTimeout(C.inT); clearTimeout(C.dogT); clearTimeout(C.connT); clearInterval(C.timer); try{ C.notif?.close(); }catch{} C.notif=null; C.reconn=false; C.everUp=false; C.code=null; setTimeout(()=>window.ctUpdate&&ctUpdate(),0); clearInterval(CT.t); CT.t=null; CT.kind=''; { const cc=document.getElementById('ccode'); if(cc) cc.remove(); const cd=document.getElementById('cccard'); if(cd) cd.remove(); } C.downT=0; clearTimeout(C.rT); C.peerCamOff=false;
try{ C.pc?.close(); }catch{} C.local?.getTracks().forEach(t=>t.stop());
earShow(false); Object.assign(C,{rsrc:null,rgain:null,rStream:null,outKey:null,speaker:false,st:null,pc:null,local:null,remote:null,t0:0,peer:null,callId:null,pendingOffer:null,iceQ:[],lastPeer:0,secCid:null,secP:null});
const box=$('#call'); if(box){ box.querySelectorAll('video,audio').forEach(v=>{ try{ v.pause(); v.srcObject=null; }catch{} }); box.remove(); }
if(remote&&status==='ended') toast('Звонок завершён');
if(wasCaller && chatId){ const row={kind:'call',meta:{status:dur?'ended':status,duration:dur,video}}; if(chatId===S.cur) insertMsg(row,chatId); else sb.from('lm_messages').insert({chat_id:chatId,sender_id:S.me.id,...row}); }
}
/* звук исходящего звонка: «Звонок…» — двойной «пип» каждые 1,6 с; «Вызов…» — гудки 425 Гц (1 с звука, 4 с тишины), как в приложениях */
window.CT={kind:'',ac:null,t:null};
window.ctBeep=(f,at,dur,amp)=>{ const ac=CT.ac, t0=ac.currentTime+at; const o=ac.createOscillator(), o2=ac.createOscillator(), g=ac.createGain(), g2=ac.createGain();
  o.frequency.value=f; o2.frequency.value=f*2; g2.gain.value=0.12; o.connect(g); o2.connect(g2); g2.connect(g); g.connect(ac.destination);
  g.gain.setValueAtTime(0,t0); g.gain.linearRampToValueAtTime(amp,t0+0.018); g.gain.setValueAtTime(amp,t0+dur-0.018); g.gain.linearRampToValueAtTime(0,t0+dur);
  o.start(t0); o2.start(t0); o.stop(t0+dur+0.02); o2.stop(t0+dur+0.02); };
window.ctUpdate=()=>{ const k=(typeof C!=='undefined'&&C.st==='calling')?(C.ringing?'ring':'conn'):''; if(k===CT.kind) return; CT.kind=k; clearInterval(CT.t); CT.t=null; if(!k) return;
  try{ CT.ac=CT.ac||new (window.AudioContext||window.webkitAudioContext)(); CT.ac.resume&&CT.ac.resume(); }catch{ return; }
  const once=()=>{ if(CT.kind!==k) return; if(k==='ring') ctBeep(425,0,1.0,0.16); else { ctBeep(880,0,0.09,0.13); ctBeep(1175,0.17,0.11,0.13); } };
  once(); CT.t=setInterval(once,k==='ring'?5000:1600); };
function callUI(){
ctUpdate();
let o=$('#call');
if(!o){ o=document.createElement('div'); o.id='call'; o.innerHTML='<video id="rv" autoplay playsinline muted class="hidden"></video><img id="rimg" class="hidden" alt=""><canvas id="rcv" class="hidden"></canvas><audio id="ra" autoplay playsinline></audio><audio id="rra" autoplay playsinline></audio><video id="lv" autoplay muted playsinline class="hidden"></video><div id="cui"></div>'; document.body.appendChild(o); }
const p=S.profiles.get(C.peer)||{name:C.peerName,avatar_url:C.peerAvatar,color:C.peerColor};
const stTxt={reconn:'Повторное подключение\u2026',calling:C.ringing?'Вызов\u2026':'Звонок\u2026',incoming:C.video?'Входящий видеозвонок':'Входящий звонок',connecting:'Соединение\u2026',active:''}[C.st==='answering'?'connecting':C.st];
const p2p=p2pOn();
const showRelayVid=C.video&&C.st==='active'&&!C.peerCamOff&&!p2p&&!!RL.gotV;
const showRemoteVid=(C.video&&C.st==='active'&&!C.peerCamOff&&p2p)||showRelayVid;
const rv=$('#rv'), ra=$('#ra'), lv=$('#lv');
$('#rimg').classList.toggle('hidden',!(showRelayVid&&RL.vmode!=='codec')); $('#rcv').classList.toggle('hidden',!(showRelayVid&&RL.vmode==='codec'));
if(C.remote){ if(ra.srcObject!==C.remote){ ra.srcObject=C.remote; rv.srcObject=C.remote; } ra.play().catch(()=>{}); if(showRemoteVid) rv.play().catch(()=>{}); }
rv.classList.toggle('hidden',!showRemoteVid||showRelayVid);
const showLocal=!!(C.video&&C.local&&!C.camOff);
lv.classList.toggle('hidden',!showLocal);
if(showLocal){ if(lv.srcObject!==C.local) lv.srcObject=C.local; lv.play().catch(()=>{}); lv.style.transform=C.facing==='environment'?'none':''; }
$('#cui').innerHTML=`<div class="cinfo ${showRemoteVid?'hidden':''}"><div style="display:flex;justify-content:center"><div class="${C.st!=='active'?'pulse':''}" style="border-radius:50%">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'l')}</div></div><h2>${esc(p.name||'')}</h2><p>${C.reconn?stTxt.reconn:(C.st==='active'&&!C.everUp)?'Соединение\u2026':C.st==='active'?'<span id="ctime">'+fmtDur((Date.now()-C.t0)/1000)+'</span>':stTxt}</p></div>
${showRemoteVid?`<div style="position:absolute;top:calc(20px + env(safe-area-inset-top));left:20px;z-index:2;font-weight:800;text-shadow:0 2px 8px #000">${esc(p.name||'')} \u00b7 <span id="ctime">${fmtDur((Date.now()-C.t0)/1000)}</span></div>`:''}
<div class="cbtns">${C.st==='incoming'
?`<button class="end ringb" id="cRej">${ic('hangup')}</button><button class="acc ringa" id="cAcc">${ic(C.video?'video':'phone')}<i></i><i></i></button>`
:`<button id="cMic" class="${C.muted?'off':''}">${ic(C.muted?'micoff':'mic')}</button>${C.st==='active'||C.st==='connecting'||C.st==='answering'||C.video?`<button id="cCam" class="${(!C.video||C.camOff)?'off':''}" title="Камера">${ic((!C.video||C.camOff)?'videooff':'video')}</button>`:''}${C.video&&C.st==='active'?`<button id="cFlip">${ic('flip')}</button>`:''}<button id="cSpk" class="${C.speaker?'off':''}" title="Громкая связь">${ic('speaker')}</button><button class="end" id="cEnd">${ic('hangup')}</button>`}</div>
${C.st!=='incoming'?`<div class="spkl">${C.speaker?'Громкая связь':'Обычная связь'}</div>`:''}`;
$('#cAcc')&&($('#cAcc').onclick=acceptCall); $('#cFlip')&&($('#cFlip').onclick=flipCallCam); $('#cRej')&&($('#cRej').onclick=rejectCall); $('#cEnd')&&($('#cEnd').onclick=hangup);
$('#cSpk')&&($('#cSpk').onclick=()=>{ C.speaker=!C.speaker; try{ navigator.vibrate?.(10); }catch{} applyOut(); callUI(); });
applyOut(); earEval();
$('#cMic')&&($('#cMic').onclick=()=>{ if(!C.local) return; C.muted=!C.muted; C.local.getAudioTracks().forEach(t=>t.enabled=!C.muted); callUI(); });
$('#cCam')&&($('#cCam').onclick=()=>{ if(!C.local) return; if(!C.local.getVideoTracks().length) return enableCallVideo(); C.camOff=!C.camOff; if(!C.camOff&&!C.speaker){ C.speaker=true; applyOut(); } C.local.getVideoTracks().forEach(t=>t.enabled=!C.camOff); sig(C.peer,{t:'media',camOff:C.camOff}); callUI(); });
}
// включить камеру во время аудиозвонка: добавляем видео в соединение и договариваемся заново, звук \u2014 на громкую связь
async function enableCallVideo(){
  if(!C.st||!C.local) return; let nt=null;
  try{ nt=(await navigator.mediaDevices.getUserMedia({video:VID_C('user')})).getVideoTracks()[0]; }
  catch{ try{ nt=(await navigator.mediaDevices.getUserMedia({video:true})).getVideoTracks()[0]; }catch{ return toast('Нет доступа к камере'); } }
  if(!C.st){ nt.stop(); return; } try{ nt.contentHint='motion'; }catch{}
  C.local.addTrack(nt); C.video=true; C.camOff=false; C.facing='user'; C.speaker=true; C.outKey=null;
  if(C.pc){ try{ C.pc.addTrack(nt,C.local); const o=await C.pc.createOffer(); const od={type:o.type,sdp:opusTune(o.sdp)}; await C.pc.setLocalDescription(od); sig(C.peer,{t:'offer',sdp:od,auth:await sdpAuth('offer',od.sdp)}); }catch(e){ console.warn(e); } }
  try{ if(RL.vid){ RL.vid.srcObject=C.local; RL.vid.play().catch(()=>{}); } }catch{}
  sig(C.peer,{t:'media',camOff:false,video:true}); applyOut(); callUI(); callLog('video_on'); }
// журнал звонка (для поиска ошибок в бета-версии)
function callLog(ev,info){ try{ sb.from('lm_call_log').insert({call_id:C.callId||'',ev,info:{...(info||{}),state:C.st,role:C.role,app:document.hidden?'bg':'fg',v:'web'}}).then(()=>{},()=>{}); }catch{} }
// --- куда идёт звук собеседника ---
// по умолчанию в аудиозвонке \u2014 \u00abобычная связь\u00bb (тише, как у уха), в видеозвонке \u2014 громкая.
// Где браузер умеет выбирать динамик (часть Android), переключается настоящий разговорный динамик.
function callAudioInit(){ try{ if(navigator.audioSession) navigator.audioSession.type='play-and-record'; }catch{} earInit(); }
async function applyOut(){
  if(!C.st) return;
  const key=C.speaker+'|'+(C.remote?C.remote.id:'')+'|'+(RL.on?1:0); if(C.outKey===key) return; C.outKey=key;
  let real=false;
  try{ if(navigator.mediaDevices?.enumerateDevices&&'setSinkId' in HTMLMediaElement.prototype){
    const ds=(await navigator.mediaDevices.enumerateDevices()).filter(d=>d.kind==='audiooutput'&&d.label);
    const want=C.speaker?/speaker|громк|loud/i:/earpiece|receiver|handset|разговор|телефон/i;
    const d=ds.find(x=>want.test(x.label)) || (C.speaker?ds.find(x=>x.deviceId==='default'):null);
    if(d&&ds.some(x=>/earpiece|receiver|handset|разговор/i.test(x.label))){ for(const sel of ['#ra','#rra']){ const a=$(sel); if(a&&a.sinkId!==d.deviceId) await a.setSinkId(d.deviceId).catch(()=>{}); } real=true; } } }catch{}
  const vol=(C.speaker||real)?1:0.5;
  // на iPhone громкость плеера менять нельзя \u2014 звук собеседника идёт через свой регулятор
  if(IS_IOS&&C.remote&&C.ctx&&C.ctx.state==='running'&&C.rStream!==C.remote&&C.remote.getAudioTracks().length){
    try{ try{ C.rsrc?.disconnect(); }catch{} C.rsrc=C.ctx.createMediaStreamSource(C.remote); if(!C.rgain){ C.rgain=C.ctx.createGain(); C.rgain.connect(C.ctx.destination); } C.rsrc.connect(C.rgain); C.rStream=C.remote; const ra=$('#ra'); if(ra) ra.muted=true; }
    catch(e){ C.rsrc=null; const ra=$('#ra'); if(ra) ra.muted=false; }
  }
  try{ if(C.rgain) C.rgain.gain.value=vol; }catch{}
  try{ if(RL.out) RL.out.gain.value=vol; }catch{}
  ['#ra','#rra'].forEach(sel=>{ const a=$(sel); if(a) try{ a.volume=vol; }catch{} });
}
// --- экран гаснет у уха ---
// датчика приближения у браузера нет, поэтому определяем по положению телефона (вертикально и повёрнут к уху)
// и по касанию щекой (большое или несколько касаний сразу). Пока экран чёрный, нажатия не проходят.
const EAR={on:false,init:false,b:null,g:null,cheek:false,t:null,tv:null};
function earWanted(){ return !!(C.st&&C.st!=='incoming'&&!C.video&&!C.speaker&&!IS_DESKTOP); }
function earInit(){ if(IS_DESKTOP||EAR.init) return; EAR.init=true;
  try{ const D=window.DeviceOrientationEvent; if(D&&typeof D.requestPermission==='function') D.requestPermission().catch(()=>{}); }catch{}
  window.addEventListener('deviceorientation',e=>{ if(e.beta==null) return; EAR.b=e.beta; EAR.g=e.gamma; if(C.st) earEval(); });
  const tt=e=>{ if(!earWanted()){ EAR.cheek=false; return; } const ts=[...e.touches];
    if(e.type==='touchstart'&&(ts.length>=2||ts.some(t=>(t.radiusX||0)>=22||(t.radiusY||0)>=22))) EAR.cheek=true;
    if(!ts.length) EAR.cheek=false;
    if(EAR.on&&e.cancelable){ e.preventDefault(); e.stopPropagation(); } earEval(); };
  ['touchstart','touchmove','touchend','touchcancel'].forEach(t=>document.addEventListener(t,tt,{capture:true,passive:false}));
}
function earPose(){ if(EAR.b==null) return null; const b=EAR.b, g=Math.abs(EAR.g||0); if(b<35||b>160) return false; return (b>55&&g>22)||b>100; }
function earEval(){ const pose=earPose(); const c=earWanted()&&(pose===true||(EAR.cheek&&pose!==false));
  if(c===EAR.on){ clearTimeout(EAR.t); EAR.t=null; EAR.tv=null; return; }
  if(EAR.t&&EAR.tv===c) return; clearTimeout(EAR.t); EAR.tv=c; EAR.t=setTimeout(()=>{ EAR.t=null; EAR.tv=null; earShow(c); }, c?600:250); }
function earShow(on){ on=!!on; if(EAR.on===on) return; EAR.on=on; let el=$('#earBlack');
  if(on){ if(!el){ el=document.createElement('div'); el.id='earBlack'; el.innerHTML='<span>Отведите телефон от уха, чтобы включить экран</span>'; document.body.appendChild(el); } requestAnimationFrame(()=>el.classList.add('on')); }
  else { clearTimeout(EAR.t); EAR.t=null; EAR.tv=null; if(el){ el.classList.remove('on'); setTimeout(()=>{ if(!EAR.on) el.remove(); },260); } } }
function ringtone(kind){ stopRing(); const play=()=>{ if(!C.ring) return; if(kind==='in'){ beep(660,.25,.08); setTimeout(()=>{ if(C.ring) beep(880,.3,.08); },300); try{ navigator.vibrate?.([400,200,400]); }catch{} } else beep(440,.6,.05); }; C.ring=setInterval(play,kind==='in'?1800:3000); play(); }
function stopRing(){ clearInterval(C.ring); C.ring=null; try{ navigator.vibrate?.(0); }catch{} }
function notifyCall(p){ if(!(document.hidden||!document.hasFocus())) return; flashTitle('\u{1f4de} '+(p.name||'Звонок')); C.notif=showNote((p.name||'Lumo'),{body:p.video?'\u{1f4f9} Входящий видеозвонок':'\u{1f4de} Входящий звонок',requireInteraction:true,tag:'call',icon:p.avatar||NOTE_ICON,vibrate:[400,200,400]},()=>{}); }
// уведомление: обычное браузерное, а если браузер требует service worker (Android) \u2014 через него, когда он есть
const NOTE_ICON='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEgAAABICAIAAADajyQQAAAKsUlEQVR42t2bW2wc1RmAv3PmshffkmDiJIYkxDERBoogpAmUSymtSG8UVSqkFe0DrVCpVKAvFRJqn1pVqvpSqZWqPiDBS+EFIRqVWwGFS0iq3ERKEuIaDG5wgmMnsZ1d7+7MOX2Y2d257e7Y3qTgkb2anT1z5vznfOc///+ff8Tj92stQKAheiIAdODEu6iJlvevB8s3LRB5Sq3ChHqaNCBwEn+c6d8D1Gqpnvt1BZ9K4ETWC+jAYwhWGHx2oMJQJ8akqtcjYvVQb09dWmJfBWa8q4i1NT5EkVrqNzbo0UZdmzikRGROrDCpATowNma8q+JEzRfUVAQ2ryfegBRIB+sxdQMCG46VDBcI05IgFS2kSqgn3juEW0Id+PhY+XOMhRJIAwKZF4HxemhWT0sCazeaQZQ/3wQGOrGK4tIgUIQUu7mUCAx+NZcOgbXh8VBcOgTKUAEzwbb4PBNY61ZziRFYK2/CBSMw9niSbNn2Ehg2gi8AgQiERAo0KFCBbhISBEJUr7eVwFoDzPYSiEAaaHAUpRKOCxLDwLSQEiFwFJUyFYUGw8SyMM3qWNEGAmvlzZB/tWACQYM0cDXni2jo6Wbjetb3038py3tY3oltA5QqnJ1lcpoTpxkZZ3SCqVmkJJtBSlwWRWBwAExNGwgUEq2ZLpDNsvlqtn6BoQF6l9HymDjH4VHePsqhD5mdI59FSJReOIF14B99SC+SQCk5P4dpc+tm7ryJK/qrBppGa793REAY7f8jBKL6w8hJXjjAPw9TdunI4upkgloSWCspHnlItyCwsUb2FMD5Oa7dxL1fZ3BdXZ5go5sckcLHTvDkLvZ/SEcu8PSUBAb0lgbx8M8084ku1E6kpOLiar57F/fcCaBUWnnih9KgkRINz+zmqbcxJYaJq5M9j5ZLi7kwAqWk5GDbPPwDrh9CazRIyYIPKUCgNAJ23Mz6lfz+H8w52KavUVISWCspg3o2EmNppAOlpOyQz/PYg1w/hKsQAilY/CEFQuAqtm3kd/fSkaXkIkVTqYjpFQEgE6IoIgRrfF45CmHw6I8YWIurMCTtPQyJq9i0il9/B2ngaJCNdWCYr9pX2YjAqClQE15SLPPj77FpA67bfqmCsl3bzy++RqGCSDevggVkegIBaTJT4Cs3ccsNuArD4MIdnmxfvYpvXce5EtJIRWBtfZMpCUSApOSw8hJ2fAOt2zOpWk45rfnJl1jVQ8lBiGhTQwSG+ZSpCPRWBkmxzDe/TFeHv/hc6MMjsCfHfZspOCCbxj/DMsuUnog3XGtWctsWtEZILs4hQGu2X8XaFZScUNA7TmBw7ZYtCfRKC8lcmW3XkcugNYKLJZhAQ4fNHYMUHN/lSSYwbFjKZHcotsYrTSbDjdf4D2tkPSiFrn6GflK+9aRU1KSq3aJ0Mwlv3UDWRunwWAUJlGEUddxiSrK+yg59vaxb3VAwT514Tpf3GZTNu+L9FLxFBG6RItoddaMEBnq5bBklN2wDkTBWSbstDaIxUlJ2WbcGy0Ql6UOviUeG2b2f2QL9fdxxM73L/euu4o29vHcc4OoruW0rhvR/On2G13dz4hSdeW7ezNBgslpSGttgoJfhKTKJvR9zAsyU0Ril6buk6nWIBKle3MUzf/f7/uB77N7PIw+wrp9Khb/+jT0HfUdz7yGODPPg9zFNRv/LH59g6hyWiVK8vY/7vs322xNk8yTp78H1ViidtEsYviJTxQMByfKeZAKF4JNTPPcS+RydeXIZlndzboann0cI3trHngOsWEY+Sz7LimXsOcBb+xCCp5/n3AzLu8ll6MyTz/HcS3xyKopx7bi0w3eUkgmMOB8hl7mBVN5JRy5ZMODIMKWybysoTcUhl2VsnOkZ3h/BslGq/mfZvD/C9Axj4+SyVByU9m3OUpkjw/Vqg0of6Mz4BkUTAomHuJtHdS6egm/ilRIOftBss1O2jEj7cwzOzyWvM8DQIBnb73UpsEyKc1y+mu4uNg1QKSNl/a9SZtMA3V1cvpriHJaJFP5oZ2yGBhMUryfSbBlFctDKmyxBN0Um7HbHItJebHBypsECqlnTxz13USgyW6BY4sw0PV3suButueVGtt3A1FkKcxTmmDrLthu45Ua0Zsfd9HRxZppiidkChSL33MWavob22kQBJVoQWGtz2riikIxPBniPybb9dtauSVD3lsVP72doMEHdr7+Mx3+eSt17F8am/diBThESFw88plvuiQhJyWF1L394CMtsGJYRosWVxdxScfnhc3w0jW3WgfQJDEcN6/5Yyz0RBZbJ+BSjJ6uBlyQmIyZVsImJJpU31EGTKlEqpdFwfIqPZ7DNsNcbI7AmiIwSmLhYgzAoVth7LDCXk2yfoEkV+inJpPJkC5pUjZShgF0fUXBCKGoRCtXosCAy0WmLBxWUJmPz1hGKZd/ivkgqXiPhfIVXRslZuCTrwIhlS926b7orpwUKMjZjp3n1EEKg1UUSTIEQ7Bzmw3NkLBQtCKzPseabd0Hb39VkMzz7DtOFhlZP21dkKThb4ql/k7NwdSjAmMhXOK4okgmMbHYqsC1OnuXJ1y4SjUoh4E/7ODHrK0PdhEBaxhUT94UFCBxNZ54XD/HKu0gR9Rrbe7gaQ/LCCM8epzuL25LASKy6JYFx51pIdu5HXcjIh6MwBAdP8Zvd5Kx6VKYlgSEUmxMY3xeuKLZsRF4wFeIqTMl7E/zyNVyQRnWnNwWB9ZSjYMpjy8wET4VkbLYOJptXi51U2g+VvjnGr96k6JAxcXVAhlZjFdjRnE9mgpDMVRhYxYaVvspqo0gaDIGGJ97lLwcxpL/VkjJBMWIPmslSNchMEIKyy5YB38uIBO69/hZVWyHtxp8XZRYAhz/lzwfY8wldGd+UmxeBwYXXjGwENjeZXU3WZuvGkMukNUqHbCJRXYVqogYv1j69TSPv+rFJnj3GzhFKip4sLmEZ0hCYjGIaR0Ay5zCwioG+utXrtc8QAEdP8vJRPp3l9kGu66evy78ed0Bqx8lZ9o/z6ij/Gud8hc4MnSaOnkeKbKP2mymzs2rOy5YNSEHFxTL8QZuc5c0RXn+fo6eYcxCSNz5gRQdX9HLlStYuo7eTS/JkLAQUHSYLTBT46CzHJvnPGU4XEZKcTU8OV/u7YaEGzIfAOoqkzI0RuBrb4osDCIFl4CoOjvHaMfaOMjGLaZK16bZQAgQFhwMn2DOGEBgGlokh0QJHU1ZUFFpgGGRMurNoURWp1SrckkBCyc4psrOEpFDmmsvZtJqxKd44zq5hPpjA0WQz9OT9/CFHV+ePJGeQl/WUI1WNvebNUMTB0cmBwYURGMhXTJ2dhcS2+O1O3hlhtoxtkcuAwKU6KyJs4Ec2tQipAX9d0rFwZzsIrIe4Q0514+wsBRmLgx9TVuTs+hBpnW4HtWmcvY0Epg5xhxthWdjVIUqfmZD83sqCXhNIk4ASRjFlfqD2pwrzyUxoEZFuF4Hh3jEXlh+Ydg+/1Z5I2wms9Y7ZKDl0wdlZ/18CA6mzYtH5gZ8ZAoP1mIvMUP1MEagbps5+/gnUwZd2WEIEhq37JURgLUBqLjECa7+akXzFaMZsSgKT3h5NTgtNSWDLt3aTCAy9yhi0HQnvskcS6pvbgfUJFqmHUFIaKSJnLV/KpcE2ZbCe/wEAe/6iQtw/swAAAABJRU5ErkJggg==';
function canNotify(){ return IS_DESKTOP && 'Notification' in window && Notification.permission==='granted'; }
function showNote(title,opt,onclick){ if(!canNotify()) return null;
  try{ const n=new Notification(title,opt); n.onclick=()=>{ try{ window.focus(); }catch{} onclick&&onclick(); n.close(); }; return n; }
  catch(e){ try{ navigator.serviceWorker?.getRegistration().then(r=>r&&r.showNotification(title,{...opt,data:{chat:opt.tag&&opt.tag!=='call'?opt.tag:null}})); }catch{} return null; } }
function notifSupported(){ try{ if(window.LUMO_PWA&&('Notification' in window)) return true; if(!IS_DESKTOP||!('Notification' in window)) return false; if(window.LUMO_PWA) return true; if(/Android/i.test(navigator.userAgent)) return false; return true; }catch{ return false; } }
$('#hCall').onclick=()=>{ const c=cur(); if(c&&c.type==='group'&&window.tgGcall) return window.tgGcall(c,false); startCall(false); }; $('#hVideo').onclick=()=>{ const c=cur(); if(c&&c.type==='group'&&window.tgGcall) return window.tgGcall(c,true); startCall(true); };
/* ================= ВХОД ПО QR-КОДУ ================= */
const LIBS={qr:['/lib/qr.js','https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.min.js','https://unpkg.com/qrcode-generator@1.4.4/qrcode.js'],
jsqr:['/lib/jsqr.js','https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js','https://unpkg.com/jsqr@1.4.0/dist/jsQR.js']};
const libP={};
function needLib(name,test){ if(test()) return Promise.resolve(); return libP[name]||(libP[name]=(async()=>{ for(const u of LIBS[name]){ try{ await loadScript(u.startsWith('/')?FN+u:u,12000); if(test()) return; }catch{} } libP[name]=null; throw new Error('lib'); })()); }
const QR={ch:null,k:null,rot:null,busyT:null,busy:false};
function rndKey(){ const a=new Uint8Array(18); crypto.getRandomValues(a); return btoa(String.fromCharCode(...a)).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,''); }
function qrFromText(t){ const m=String(t||'').match(/lmqr=([A-Za-z0-9_-]{16,64})/); return m?m[1]:null; }
function qrSvg(text){ const q=window.qrcode(0,'M'); q.addData(text); q.make(); const n=q.getModuleCount(); let d=''; for(let r=0;r<n;r++) for(let c=0;c<n;c++) if(q.isDark(r,c)) d+='M'+c+' '+r+'h1v1h-1z';
return `<svg viewBox="-1 -1 ${n+2} ${n+2}" shape-rendering="crispEdges"><path d="${d}" fill="#14142b"/></svg><div class="qrmark">${ic('chat')}</div>`; }
function qrStatus(t){ const e=$('#qrSt'); if(e) e.textContent=t; }
async function showQrLogin(){
if(!sb) return; $('#passView').classList.add('hidden'); $('#qrView').classList.remove('hidden'); qrStatus('');
$('#qrToPass').classList.toggle('hidden',IS_DESKTOP); $('#qrNote').classList.toggle('hidden',!IS_DESKTOP);
try{ await needLib('qr',()=>typeof window.qrcode==='function'); }catch{ $('#qrImg').innerHTML='<div style="color:#555;font-size:13px;text-align:center;line-height:1.5">Не удалось загрузить QR-код<br><button class="btn ghost" style="margin-top:8px;padding:8px 14px" onclick="this.closest(\'#qrImg\').innerHTML=\'<div class=qrspin></div>\'">Повторить</button></div>'; $('#qrImg').querySelector('button').addEventListener('click',()=>showQrLogin()); if(!IS_DESKTOP) $('#qrToPass').classList.remove('hidden'); return; }
qrRotate();
}
function qrStop(){ clearTimeout(QR.rot); clearTimeout(QR.busyT); QR.busy=false; if(QR.ch){ try{ sb.removeChannel(QR.ch); }catch{} } QR.ch=null; QR.k=null; }
function qrRotate(){
qrStop(); if(S.me||$('#qrView').classList.contains('hidden')) return;
const k=rndKey(); QR.k=k;
try{ const qi=$('#qrImg'); qi.classList.remove('scanned'); qi.innerHTML=qrSvg(location.href.split('#')[0]+'#lmqr='+k); qi.classList.add('ready'); }catch(e){ console.error(e); }
QR.ch=sb.channel('lm-qr-'+k,{config:{broadcast:{self:false}}}).on('broadcast',{event:'qr'},({payload})=>onQrMsg(payload||{},k)).subscribe();
QR.rot=setTimeout(qrRotate,60000);
}
async function onQrMsg(p,k){
if(k!==QR.k) return;
if(p.t==='scan'){ $('#qrImg').classList.add('scanned'); clearTimeout(QR.rot); clearTimeout(QR.busyT); QR.busy=true; qrStatus('Подтвердите вход на телефоне\u2026'); QR.busyT=setTimeout(()=>{ qrStatus(''); qrRotate(); },120000); return; }
if(p.t==='cancel'){ qrStatus('Вход отменён на телефоне'); setTimeout(()=>{ if(QR.k===k) qrRotate(); },1500); return; }
if(p.t==='login'&&p.th){
  qrStatus('Входим\u2026'); const ch=QR.ch;
  let r=await sb.auth.verifyOtp({token_hash:p.th,type:'magiclink'});
  if(r.error) r=await sb.auth.verifyOtp({token_hash:p.th,type:'email'});
  try{ await ch.send({type:'broadcast',event:'qr',payload:{t:r.error?'fail':'ok'}}); }catch{}
  if(r.error){ qrStatus('Не удалось войти \u2014 попробуйте ещё раз'); setTimeout(qrRotate,1500); return; }
  qrStop(); try{ await start(); }catch(e){ qrStatus(e.message); }
}
}
$('#toQr').onclick=()=>showQrLogin();
$('#qrToPass').onclick=()=>{ qrStop(); $('#qrView').classList.add('hidden'); $('#passView').classList.remove('hidden'); };
async function qrApprove(k){
if(!k||!S.me) return;
const ch=sb.channel('lm-qr-'+k,{config:{broadcast:{self:false}}}); let res=null; const resP=new Promise(r=>res=r);
ch.on('broadcast',{event:'qr'},({payload})=>{ if(payload&&(payload.t==='ok'||payload.t==='fail')) res(payload.t); });
await new Promise(r=>{ ch.subscribe(s=>{ if(s==='SUBSCRIBED') r(); }); setTimeout(r,6000); });
const send=pl=>ch.send({type:'broadcast',event:'qr',payload:pl}).catch(()=>{});
const drop=()=>setTimeout(()=>{ try{ sb.removeChannel(ch); }catch{} },1500);
send({t:'scan'}); let done=false;
modal('Вход на другом устройстве',`<div style="text-align:center;padding:4px 0 2px"><div style="width:64px;height:64px;margin:0 auto 12px;border-radius:20px;background:linear-gradient(135deg,var(--accent),var(--a2));display:grid;place-items:center;color:#fff">${ic('laptop')}</div>
<p style="margin:0 0 8px;font-weight:700">Войти в ваш аккаунт Lumo на компьютере?</p><p style="margin:0;color:var(--muted);font-size:13.5px;line-height:1.45">Подтверждайте, только если вы сами отсканировали QR-код на своём экране. Если код прислал кто-то другой \u2014 нажмите \u00abОтмена\u00bb.</p></div>`,
[['Отмена','ghost',c=>{ done=true; c(); send({t:'cancel'}); drop(); }],['Войти','primary',async c=>{ done=true; c(); toast('Подтверждаем вход\u2026',15000);
  try{ const {data:{session}}=await sb.auth.getSession();
    const r=await fetch(FN+'/qr',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+session.access_token},body:'{}'});
    const j=await r.json(); if(!j.th) throw new Error(j.error||'error');
    await send({t:'login',th:j.th});
    const out=await Promise.race([resP,new Promise(r=>setTimeout(()=>r('timeout'),15000))]);
    toast(out==='ok'?'Готово! Вы вошли на компьютере':out==='fail'?'Не получилось \u2014 обновите QR-код на компьютере':'Компьютер не ответил. Обновите страницу на компьютере и отсканируйте код заново',4000);
  }catch(e){ toast('Не удалось подтвердить вход'); }
  drop(); }]]);
setTimeout(()=>{ if(!done){ document.querySelector('.ov')?.remove(); drop(); } },110000);
}
async function qrScan(){
if(!navigator.mediaDevices?.getUserMedia) return toast('Камера недоступна в этом браузере');
const o=document.createElement('div'); o.id='qrScan';
o.innerHTML=`<video playsinline muted autoplay></video><div class="tt">Сканирование QR-кода</div><div class="frame"></div><div class="hint">Наведите камеру на QR-код профиля Lumo \u2014 или на QR-код входа на экране компьютера</div><button class="close" type="button">${ic('x')}</button>`;
document.body.appendChild(o);
let st=null, stop=false, tm=null;
const close=()=>{ stop=true; clearTimeout(tm); st?.getTracks().forEach(t=>t.stop()); o.remove(); };
o.querySelector('.close').onclick=close;
try{ st=await navigator.mediaDevices.getUserMedia({video:{facingMode:{ideal:'environment'}},audio:false}); }catch{ close(); return toast('Нет доступа к камере'); }
if(stop){ st.getTracks().forEach(t=>t.stop()); return; }
const v=o.querySelector('video'); v.srcObject=st; await v.play().catch(()=>{});
let det=null; try{ if('BarcodeDetector' in window){ const f=await BarcodeDetector.getSupportedFormats(); if(f.includes('qr_code')) det=new BarcodeDetector({formats:['qr_code']}); } }catch{}
if(!det){ try{ await needLib('jsqr',()=>typeof window.jsQR==='function'); }catch{ close(); return toast('Не удалось загрузить сканер. Отсканируйте код обычной камерой телефона'); } }
const cv=document.createElement('canvas'), cx=cv.getContext('2d',{willReadFrequently:true});
const tick=async()=>{ if(stop) return; let txt=null;
  try{ if(v.videoWidth){ if(det){ const r=await det.detect(v); txt=r[0]?.rawValue; }
    else { const sc=Math.min(1,640/Math.max(v.videoWidth,v.videoHeight)); cv.width=v.videoWidth*sc|0; cv.height=v.videoHeight*sc|0; cx.drawImage(v,0,0,cv.width,cv.height); const r=window.jsQR(cx.getImageData(0,0,cv.width,cv.height).data,cv.width,cv.height,{inversionAttempts:'dontInvert'}); txt=r?.data; } } }catch{}
  if(stop) return;
  const k=qrFromText(txt); if(k){ try{ navigator.vibrate?.(30); }catch{} close(); qrApprove(k); return; }
  { const pu=String(txt||'').match(/#@([a-z0-9_]{3,32})\b/i); if(pu&&S.me){ try{ navigator.vibrate?.(30); }catch{} close(); if(pu[1].toLowerCase()===S.me.username.toLowerCase()) return toast('Это ваш собственный QR-код'); openByUsername(pu[1]); return; } }
  if(txt) o.querySelector('.hint').textContent='Это не QR-код Lumo';
  tm=setTimeout(tick,200); };
tick();
}
function myProfileLink(){ return location.href.split('#')[0].split('?')[0]+'#@'+S.me.username; }
async function showUserQr(p){ if(!p) return; try{ await needLib('qr',()=>typeof window.qrcode==='function'); }catch{ return toast('Не удалось загрузить QR-код, попробуйте ещё раз'); }
  const link=location.origin+location.pathname+'#@'+p.username;
  modal('QR-код',`<div class="myqr"><div class="mqcard uqr">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'l')}<b>${esc(p.name||'')}</b><div class="qrbox">${qrSvg(link)}</div><button class="uqnick" id="uqNick">@${esc(p.username||'')}${ic('copy')}</button><span class="uqh" id="uqH">Нажмите, чтобы скопировать</span></div></div>`,
  [['Поделиться','primary',async c=>{ try{ if(navigator.share){ await navigator.share({title:'Lumo',text:p.name+' в Lumo',url:link}); return; } }catch{ return; } navigator.clipboard?.writeText(link); toast('Ссылка на профиль скопирована'); }]]);
  $('#uqNick').onclick=()=>{ navigator.clipboard?.writeText('@'+p.username); const n=$('#uqNick'); n.classList.remove('ok'); void n.offsetWidth; n.classList.add('ok'); $('#uqH').textContent='Скопировано'; navigator.vibrate?.(10); }; }
async function showMyQr(){ try{ await needLib('qr',()=>typeof window.qrcode==='function'); }catch{ return toast('Не удалось загрузить QR-код, попробуйте ещё раз'); }
  const me=S.me, link=myProfileLink();
  modal('Мой QR-код',`<div class="myqr"><div class="mqcard">${avatar({name:me.name,avatar:me.avatar_url,color:me.color},'l')}<b>${esc(me.name)}</b><span>@${esc(me.username)}</span><div class="qrbox">${qrSvg(link)}</div></div>
<p class="qrhint">Покажите код другу: он отсканирует его в Lumo (Настройки \u2192 \u00abСканировать QR-код\u00bb) или обычной камерой телефона и сразу попадёт в ваш профиль.</p></div>`,
  [['Сканировать','ghost',c=>{ c(); qrScan(); }],['Поделиться','primary',async c=>{ try{ if(navigator.share){ await navigator.share({title:'Lumo',text:'Мой профиль в Lumo',url:link}); return; } }catch{ return; } navigator.clipboard?.writeText(link); toast('Ссылка на профиль скопирована'); }]]); }
/* ================= MENUS, MODALS ================= */
function dropMenu(anchor, items, dir='down'){
closeDrops(); const d=document.createElement('div'); d.className='drop';
d.innerHTML=items.map((a,i)=>a?`<button data-a="${i}" class="${a[3]||''}">${ic(a[0])}${a[1]}</button>`:'<div style="height:1px;background:var(--line);margin:4px 8px"></div>').join('');
document.body.appendChild(d); const r=anchor.getBoundingClientRect(), dr=d.getBoundingClientRect(); d.style.position='fixed';
d.style.left=Math.max(8,Math.min(r.left,innerWidth-dr.width-8))+'px';
d.style.top=(dir==='up'?Math.max(8,r.top-dr.height-6):Math.min(r.bottom+6,innerHeight-dr.height-8))+'px';
d.onclick=e=>{ const b=e.target.closest('button'); if(!b) return; closeDrops(); items[+b.dataset.a][2](); };
}
function modal(title, body, buttons=[], lock=false){
const o=document.createElement('div'); o.className='ov';
o.innerHTML=`<div class="modal"><div class="mh"><h3>${title}</h3>${lock?'':`<button class="ib" data-x>${ic('x')}</button>`}</div><div class="mb">${body}</div>${buttons.length?`<div class="mf">${buttons.map((b,i)=>`<button class="btn ${b[1]}" data-b="${i}">${b[0]}</button>`).join('')}</div>`:''}</div>`;
document.body.appendChild(o); const close=()=>o.remove();
o.addEventListener('click',e=>{ if(e.target===o||e.target.closest('[data-x]')){ if(!lock) close(); return; } const b=e.target.closest('[data-b]'); if(b){ const f=buttons[+b.dataset.b][2]; f?f(close):close(); } });
return close;
}
function confirmBox(text, ok, fn){ modal('Подтверждение',`<p style="margin:4px 0 8px">${esc(text)}</p>`,[['Отмена','ghost'],[ok,'danger',c=>{ c(); fn(); }]]); }
function setupStatic(){
paintIcons();
$('#menuBtn').innerHTML=ic('menu'); $('#newBtn').innerHTML=ic('edit'); $('#back').innerHTML=ic('back'); $('#topBack').innerHTML=ic('back'); $('#topBack').onclick=()=>setTab('settings');
$('#hSearch').innerHTML=ic('search'); $('#hCall').innerHTML=ic('phone'); $('#hVideo').innerHTML=ic('video'); $('#hMore').innerHTML=ic('more');
$('#emBtn').innerHTML=ic('smile'); $('#atBtn').innerHTML=ic('clip'); $('#iqUp').innerHTML=ic('up'); $('#iqDown').innerHTML=ic('down'); $('#iqX').innerHTML=ic('x');
updDown(); updateComposer();
document.querySelectorAll('[data-ti]').forEach(e=>e.innerHTML=ic(e.dataset.ti));
const unlockAudio=()=>{ try{ actx=actx||new (window.AudioContext||window.webkitAudioContext)(); if(actx.state==='suspended') actx.resume(); }catch{} };
document.addEventListener('pointerdown',unlockAudio,{passive:true}); document.addEventListener('keydown',unlockAudio);
// клавиатура на телефоне не перекрывает поле ввода
// после поворота телефона браузер оставляет страницу сдвинутой/увеличенной \u2014 возвращаем всё на место
(function vpFix(){ try{ let m=document.querySelector('head meta[name=viewport]'); if(!m){ m=document.createElement('meta'); m.name='viewport'; document.head.appendChild(m); }
  m.setAttribute('content','width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover'); }catch{} })();
if(window.visualViewport){ const vv=window.visualViewport; const fit=()=>{ const a=$('#app'); if(!a) return; const el=$('#msgs'); const atB=el&&el.scrollHeight-el.scrollTop-el.clientHeight<200;
  const ae=document.activeElement, typing=!!ae&&/^(INPUT|TEXTAREA)$/.test(ae.tagName)&&ae.type!=='range'&&ae.type!=='checkbox'&&ae.type!=='radio';
  // клавиатура открыта \u2014 подгоняем под видимую часть; иначе приложение просто на весь экран (без запомненных размеров)
  if(innerWidth<=800&&typing&&vv.height<innerHeight-60){ a.style.height=vv.height+'px'; a.style.top=vv.offsetTop+'px'; a.style.bottom='auto'; }
  else { a.style.height=''; a.style.top=''; a.style.bottom=''; if(!typing&&(window.scrollX||window.scrollY)) window.scrollTo(0,0); }
  if(atB&&el) el.scrollTop=el.scrollHeight; };
  const refit=()=>{ fit(); [60,250,600,1200].forEach(t=>setTimeout(()=>{ fit(); try{ moveTabInd(); moveFolderInd(); }catch{} },t)); };
  vv.addEventListener('resize',fit); vv.addEventListener('scroll',fit); addEventListener('orientationchange',refit); addEventListener('resize',refit);
  document.addEventListener('focusout',()=>setTimeout(fit,80)); document.addEventListener('focusin',()=>setTimeout(fit,80)); fit(); }
// кнопка \u00abназад\u00bb на телефоне закрывает чат, а не уходит с сайта
window.addEventListener('popstate',()=>{ $('#lightbox')?.remove(); document.querySelector('.ov')?.remove(); if(S.cur) closeChat(true); });
// запрет системного меню/выделения (кроме полей ввода)
const allowSys=t=>t.closest&&t.closest('input,textarea,[contenteditable]');
document.addEventListener('contextmenu',e=>{ if(!allowSys(e.target)) e.preventDefault(); });
document.addEventListener('selectstart',e=>{ if(!allowSys(e.target)) e.preventDefault(); });
document.addEventListener('dragstart',e=>{ if(e.target.closest&&e.target.closest('img,video,a')) e.preventDefault(); });
document.addEventListener('copy',e=>{ if(!allowSys(document.activeElement||e.target)) e.preventDefault(); });
$('#menuBtn').onclick=e=>{ e.stopPropagation(); dropMenu(e.currentTarget,[
['user','Мой профиль',openSettings],['bookmark','Избранное',()=>openDM(S.me.id)],['qr',IS_DESKTOP?'Подключить устройство':'Войти на компьютере',qrScan],null,
['users','Создать группу',()=>newChatFlow('group')],['mega','Создать канал',()=>newChatFlow('channel')],null,
[document.documentElement.dataset.theme==='light'?'moon':'sun',document.documentElement.dataset.theme==='light'?'Тёмная тема':'Светлая тема',toggleTheme],
['bell','Уведомления',askNotif],['logout','Выйти',logout,'red']]); };
$('#newBtn').onclick=e=>{ e.stopPropagation(); if(S.tab==='contacts'){ $('#q').focus(); return toast('Введите имя или @юзернейм и нажмите \u00ab+\u00bb'); } dropMenu(e.currentTarget,[['user','Новый личный чат',()=>{ $('#q').focus(); toast('Введите имя или @юзернейм в поиске'); }],['users','Новая группа',()=>newChatFlow('group')],['mega','Новый канал',()=>newChatFlow('channel')]],'down'); };
$('#back').onclick=closeChat;
$('#who').onclick=()=>toggleInfo();
$('#hMore').onclick=e=>{ e.stopPropagation(); const c=cur(); const items=[['info','Информация',()=>toggleInfo(true)],[c.muted?'bell':'belloff',c.muted?'Включить уведомления':'Без звука',toggleMute],[c.pinned?'pin':'pin',c.pinned?'Открепить чат':'Закрепить чат',togglePinChat],['search','Поиск сообщений',()=>$('#hSearch').click()]];
items.push(...chatActs(c));
if(c.type!=='private') items.push(['logout',c.type==='channel'?'Покинуть канал':'Покинуть группу',leaveChat,'red']);
dropMenu(e.currentTarget,items); };
}
function closeChat(fromPop){ if(fromPop!==true&&history.state&&history.state.lumoChat){ history.back(); return; } if(S.cur) saveDraft(); S.cur=null; stopPlaying(); $('#app').classList.remove('inchat'); setTimeout(()=>{ if(!S.cur){ $('#chat').classList.add('hidden'); $('#empty').classList.remove('hidden'); } },innerWidth<=800?260:0); $('#info').classList.add('hidden'); typChan=null; renderList(); }
let muteBusy=false;
async function toggleMute(){ const c=cur(); if(!c||muteBusy) return; muteBusy=true; c.muted=!c.muted;
 renderHead(); renderList(); updateComposer(); if(!$('#info').classList.contains('hidden')) renderInfo(); toast(c.muted?'Уведомления выключены':'Уведомления включены');
 try{ const {error}=await sb.from('lm_members').update({muted:c.muted}).eq('chat_id',c.chat_id).eq('user_id',S.me.id); if(error) throw error; }
 catch(e){ c.muted=!c.muted; renderHead(); renderList(); updateComposer(); if(!$('#info').classList.contains('hidden')) renderInfo(); toast('Не удалось изменить, проверьте соединение'); }
 muteBusy=false; }
async function togglePinChat(){ const c=cur(); c.pinned=!c.pinned; await sb.from('lm_members').update({pinned:c.pinned}).eq('chat_id',c.chat_id).eq('user_id',S.me.id); loadChats(); }
function leaveChat(){ const c=cur(); confirmBox(`Покинуть \u00ab${chatName(c)}\u00bb?`,'Покинуть',async()=>{ const {error}=await sb.from('lm_members').delete().eq('chat_id',c.chat_id).eq('user_id',S.me.id); if(error) return toast(error.message); closeChat(); loadChats(); }); }
async function logout(){ try{ await sb.auth.signOut({scope:'local'}); }catch{} location.reload(); }
async function askNotif(){ if(!IS_DESKTOP&&!window.LUMO_PWA) return toast('Чтобы получать уведомления на телефоне, откройте lumomess.ru в Safari или Chrome, добавьте Lumo на главный экран и включите их там'); void(' \u2014 подключите бота в Настройках'); if(!('Notification' in window)) return toast(window.LUMO_PWA?'Уведомления работают из иконки на главном экране: нажмите «Поделиться» → «На экран Домой», затем откройте Lumo с иконки и включите их':'Браузер не поддерживает уведомления'); const p=await Notification.requestPermission();
if(p==='granted'&&window.LUMO_PWA){ const ok=await pushSetup(true); if(ok) toast('Уведомления включены'); return; }
toast(p==='granted'?'Уведомления включены':'Уведомления запрещены в браузере'); }
function b64uToU8(s){ s=String(s).replace(/-/g,'+').replace(/_/g,'/'); while(s.length%4) s+='='; return ub64(s); }
async function pushSetup(ask){
const P=window.LUMO_PWA; if(!P||!S.me||!('serviceWorker' in navigator)||!('PushManager' in window)) return false;
if(!S.vapid){ try{ const j=await (await fetch(FN+'/config')).json(); S.vapid=j.vapid||null; }catch{} if(!S.vapid) return false; }
try{ const reg=await navigator.serviceWorker.register(P.sw||'lumo-sw.js'); await navigator.serviceWorker.ready;
  let perm=Notification.permission; if(perm==='default'&&ask) perm=await Notification.requestPermission(); if(perm!=='granted') return false;
  const key=b64uToU8(S.vapid); let sub=await reg.pushManager.getSubscription();
  if(sub){ const k=sub.options&&sub.options.applicationServerKey; if(k&&b64(new Uint8Array(k))!==b64(key)){ try{ await sub.unsubscribe(); }catch{} sub=null; } }
  if(!sub) sub=await reg.pushManager.subscribe({userVisibleOnly:true,applicationServerKey:key});
  const j=sub.toJSON(); const {error}=await sb.from('lm_push').upsert({endpoint:j.endpoint,user_id:S.me.id,p256dh:j.keys.p256dh,auth:j.keys.auth,ua:navigator.userAgent.slice(0,180)});
  if(error) throw error; return true;
}catch(e){ console.warn('push',e); if(ask) toast('Не удалось включить уведомления: '+(e.message||e)); return false; } }
/* theme */
function applyTheme(){ const t=localStorage.getItem('lm_theme')||(window.matchMedia&&matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light'); document.documentElement.dataset.theme=t; const a=JSON.parse(localStorage.getItem('lm_accent')||'null'); if(a) setAccent(a,false);
const tc=document.querySelector('meta[name=theme-color]'); if(tc) tc.content=t==='light'?'#ffffff':'#0f1020'; }
function toggleTheme(){ localStorage.setItem('lm_theme',document.documentElement.dataset.theme==='light'?'dark':'light'); applyTheme(); updateTabBadges(); }
try{ matchMedia('(prefers-color-scheme: dark)').addEventListener('change',()=>{ if(!localStorage.getItem('lm_theme')) applyTheme(); }); }catch{}
const PREM_ACCENTS=[['#ff3d6e','#7c5cff'],['#00c6ff','#0072ff'],['#f7971e','#ffd200'],['#43e97b','#38f9d7'],['#fa709a','#fee140'],['#667eea','#764ba2']];
const PREM_WALLS=['radial-gradient(120% 90% at 10% 0%,rgba(255,61,110,.28),transparent 60%),radial-gradient(100% 80% at 100% 100%,rgba(124,92,255,.30),transparent 60%)',
'radial-gradient(120% 90% at 0% 100%,rgba(0,198,255,.28),transparent 60%),radial-gradient(100% 80% at 100% 0%,rgba(0,114,255,.30),transparent 60%)',
'radial-gradient(120% 90% at 100% 0%,rgba(255,210,0,.26),transparent 60%),radial-gradient(100% 80% at 0% 100%,rgba(247,151,30,.28),transparent 60%)',
'radial-gradient(120% 90% at 0% 0%,rgba(67,233,123,.26),transparent 60%),radial-gradient(100% 80% at 100% 100%,rgba(56,249,215,.28),transparent 60%)'];
/* блокировка приложения (ПИН-код хранится на устройстве в виде хеша) */
const lockHas=()=>{ try{ return !!localStorage.getItem('lm_lock'); }catch{ return false; } };
async function lockHash(pin,salt){ const b=await crypto.subtle.digest('SHA-256',new TextEncoder().encode('lumo-lock|'+salt+'|'+pin)); return [...new Uint8Array(b)].map(x=>x.toString(16).padStart(2,'0')).join(''); }
function pinPad(title,onDone,cancel){
  let v=''; let el=document.getElementById('lock'); const own=!el; if(own){ el=document.createElement('div'); el.id='lock'; document.body.appendChild(el); }
  const draw=(err='')=>{ el.innerHTML=`<h3>${esc(title)}</h3><div class="dots">${[0,1,2,3].map(i=>`<i class="${i<v.length?'on':''}"></i>`).join('')}</div><div class="err">${esc(err)}</div><div class="pad">${[1,2,3,4,5,6,7,8,9].map(n=>`<button data-k="${n}">${n}</button>`).join('')}${cancel?'<button data-k="x" style="font-size:15px">Отмена</button>':'<span></span>'}<button data-k="0">0</button><button data-k="d">\u232b</button></div>`;
    el.querySelectorAll('[data-k]').forEach(b=>b.onclick=async()=>{ const k=b.dataset.k; if(k==='x'){ el.remove(); return; } if(k==='d') v=v.slice(0,-1); else if(v.length<4) v+=k; draw(); if(v.length===4){ const r=await onDone(v); if(r===true){ el.remove(); } else { v=''; draw(r||'Неверный код'); } } }); };
  draw(); }
async function lockShow(){ if(!lockHas()||document.getElementById('lock')) return; let o; try{ o=JSON.parse(localStorage.getItem('lm_lock')); }catch{ return; }
  pinPad('Введите код',async pin=>(await lockHash(pin,o.s))===o.h?true:'Неверный код',false); }
function lockDlg(){
  if(!premOk()&&!lockHas()) return;
  const has=lockHas(); const items=has?[['Изменить код','chg'],['Выключить блокировку','off']]:[['Включить блокировку','on']];
  const cl=modal('Блокировка приложения',`<p style="margin:4px 0 10px;color:var(--muted);font-size:14px">Lumo будет просить 4-значный код при открытии и после минуты в фоне. Код хранится только на этом устройстве \u2014 если забудете, выйдите из аккаунта и войдите снова.</p>${items.map(x=>`<button class="btn ghost" style="width:100%;margin:3px 0" data-lk="${x[1]}">${x[0]}</button>`).join('')}`,[['Закрыть','ghost']]);
  document.querySelectorAll('[data-lk]').forEach(b=>b.onclick=()=>{ cl(); const k=b.dataset.lk;
    if(k==='off'){ let o; try{ o=JSON.parse(localStorage.getItem('lm_lock')); }catch{ o=null; } pinPad('Введите текущий код',async pin=>{ if(o&&(await lockHash(pin,o.s))!==o.h) return 'Неверный код'; localStorage.removeItem('lm_lock'); toast('Блокировка выключена'); renderSettings(); return true; },true); return; }
    const setNew=()=>{ let first=null; pinPad('Придумайте код',async pin=>{ if(!first){ first=pin; setTimeout(()=>{ document.getElementById('lock')?.remove(); pinPad('Повторите код',async p2=>{ if(p2!==first) return 'Коды не совпадают'; const salt=uid8()+uid8(); localStorage.setItem('lm_lock',JSON.stringify({s:salt,h:await lockHash(p2,salt)})); toast('Блокировка включена'); renderSettings(); return true; },true); },0); return true; } return true; },true); };
    if(k==='chg'){ let o; try{ o=JSON.parse(localStorage.getItem('lm_lock')); }catch{ o=null; } pinPad('Введите текущий код',async pin=>{ if(o&&(await lockHash(pin,o.s))!==o.h) return 'Неверный код'; setTimeout(setNew,0); return true; },true); } else setNew(); }); }
let hiddenAt=0; document.addEventListener('visibilitychange',()=>{ if(document.hidden) hiddenAt=Date.now(); else if(hiddenAt&&Date.now()-hiddenAt>60000&&lockHas()) lockShow(); });
const ACCENTS=[['#7c5cff','#22c1ff'],['#ff5b8a','#ff9a5b'],['#13b0a5','#2ee6a6'],['#3a7bff','#22c1ff'],['#c44dff','#ff5b7a'],['#ff8a3d','#ffc94a']];
function setAccent(a,save=true){ const r=document.documentElement.style; r.setProperty('--a1',a[0]); r.setProperty('--a2',a[1]); r.setProperty('--out',`linear-gradient(135deg,${a[0]},${a[1]})`); if(save) localStorage.setItem('lm_accent',JSON.stringify(a)); }
/* settings / profile */
function openSettings(){ if(S.cur&&innerWidth<=800) closeChat(); setTab('settings'); }
// фото -> обычный холст с уже применённым поворотом из EXIF (до 2048px по большей стороне).
// createImageBitmap не используем: на iPhone (Safari и Telegram) он отдаёт размеры без учёта поворота снимка,
// из-за чего сохранялась не та область, что выбрана.
function loadPhoto(f){ return new Promise((res,rej)=>{ const u=URL.createObjectURL(f); const im=new Image();
  im.onload=()=>{ try{ const w=im.naturalWidth||im.width, h=im.naturalHeight||im.height; if(!w||!h) throw new Error('не удалось открыть фото');
      const k=Math.min(1,2048/Math.max(w,h)); const c=document.createElement('canvas'); c.width=Math.max(1,Math.round(w*k)); c.height=Math.max(1,Math.round(h*k));
      const x=c.getContext('2d'); x.imageSmoothingQuality='high'; x.drawImage(im,0,0,c.width,c.height); URL.revokeObjectURL(u); res(c); }
    catch(e){ URL.revokeObjectURL(u); rej(e); } };
  im.onerror=()=>{ URL.revokeObjectURL(u); createImageBitmap(f).then(bm=>{ const c=document.createElement('canvas'); const k=Math.min(1,2048/Math.max(bm.width,bm.height)); c.width=Math.round(bm.width*k); c.height=Math.round(bm.height*k); c.getContext('2d').drawImage(bm,0,0,c.width,c.height); res(c); }).catch(()=>rej(new Error('формат фото не поддерживается'))); };
  im.src=u; }); }
// окно выбора области фото: перетаскивание, масштаб пальцами / колесом / ползунком, поворот
function cropImage(bmp,D){ D=D||{}; const cnt=k=>{ D[k]=(D[k]||0)+1; }; return new Promise(done=>{
  let src=bmp, W=src.width, H=src.height;
  const ov=document.createElement('div'); ov.className='crop';
  ov.innerHTML=`<div class="crbox"><div class="crhd"><b>Выберите область</b><span>Перетащите фото и измените масштаб</span></div>
<div class="crst"><canvas></canvas><div class="crring"></div></div>
<div class="crz">${ic('minus')}<input type="range" min="0" max="1000" value="0" class="crr">${ic('plus')}</div>
<div class="crbt"><button class="btn ghost" data-a="x">Отмена</button><button class="hbtn crrot" data-a="r" title="Повернуть">${ic('rotate')}</button><button class="btn primary" data-a="ok">Готово</button></div></div>`;
  document.body.appendChild(ov);
  const st=ov.querySelector('.crst'), cv=ov.querySelector('canvas'), ctx=cv.getContext('2d'), rng=ov.querySelector('.crr');
  let Z=0, s=1, x=0, y=0, minS=1, maxS=4, dpr=Math.min(3,devicePixelRatio||1);
  const fit=()=>{ Z=st.clientWidth||300; dpr=Math.max(Math.min(3,devicePixelRatio||1),640/Z); cv.width=cv.height=Math.round(Z*dpr); minS=Math.max(Z/W,Z/H); maxS=minS*5; };
  const clamp=()=>{ s=Math.min(maxS,Math.max(minS,s)); x=Math.min(0,Math.max(Z-W*s,x)); y=Math.min(0,Math.max(Z-H*s,y)); };
  const draw=()=>{ clamp(); ctx.setTransform(1,0,0,1,0,0); ctx.clearRect(0,0,cv.width,cv.height); ctx.imageSmoothingQuality='high';
    // берём из фото только видимый квадрат и рисуем его на весь холст (без координат за краем \u2014 так надёжно и в Safari)
    const sw=Math.min(W,Z/s), sh=Math.min(H,Z/s), sx=Math.max(0,Math.min(W-sw,-x/s)), sy=Math.max(0,Math.min(H-sh,-y/s));
    ctx.drawImage(src,sx,sy,sw,sh,0,0,cv.width,cv.height); rng.value=Math.round(Math.log(s/minS)/Math.log(maxS/minS)*1000)||0; };
  const reset=()=>{ fit(); s=minS; x=(Z-W*s)/2; y=(Z-H*s)/2; draw(); D.r0={Z,s:+s.toFixed(4),x:Math.round(x),y:Math.round(y),W,H,cw:cv.width}; };
  const zoomAt=(ns,cx,cy)=>{ ns=Math.min(maxS,Math.max(minS,ns)); const ix=(cx-x)/s, iy=(cy-y)/s; s=ns; x=cx-ix*s; y=cy-iy*s; draw(); };
  requestAnimationFrame(reset);
  const onRs=()=>{ const ox=(Z/2-x)/s, oy=(Z/2-y)/s, k=s/minS; fit(); s=minS*k; x=Z/2-ox*s; y=Z/2-oy*s; draw(); }; addEventListener('resize',onRs);
  rng.oninput=()=>{ cnt('slider'); zoomAt(minS*Math.pow(maxS/minS,rng.value/1000),Z/2,Z/2); };
  ov.querySelector('.crz svg:first-child').onclick=()=>zoomAt(s/1.25,Z/2,Z/2); ov.querySelector('.crz svg:last-child').onclick=()=>zoomAt(s*1.25,Z/2,Z/2);
  // координаты пальца/мыши -> координаты расчёта (учитываем реальный размер окошка на экране)
  const P=(cx,cy)=>{ const r=st.getBoundingClientRect(), f=Z/(r.width||Z); return [(cx-r.left)*f,(cy-r.top)*f]; };
  const rel=e=>P(e.clientX,e.clientY);
  let last=null;
  const gestOf=list=>{ const a=[...list]; if(a.length>=2){ const p=P(a[0].clientX,a[0].clientY), q=P(a[1].clientX,a[1].clientY); return {cx:(p[0]+q[0])/2,cy:(p[1]+q[1])/2,d:Math.hypot(p[0]-q[0],p[1]-q[1])}; }
    if(a.length===1){ const p=P(a[0].clientX,a[0].clientY); return {cx:p[0],cy:p[1],d:0}; } return null; };
  const step=g=>{ if(g&&last&&!!g.d===!!last.d){
      if(g.d){ const ix=(last.cx-x)/s, iy=(last.cy-y)/s; s=Math.min(maxS,Math.max(minS,s*g.d/last.d)); x=g.cx-ix*s; y=g.cy-iy*s; }
      else { x+=g.cx-last.cx; y+=g.cy-last.cy; }
      draw(); }
    last=g; };
  // пальцы: события касания (на iPhone надёжнее), страницу при этом не масштабируем
  let tap0=0, tapT=0, moved=false;
  st.addEventListener('touchstart',e=>{ e.preventDefault(); cnt('tstart'); moved=false; last=gestOf(e.touches); st.classList.add('drag'); },{passive:false});
  st.addEventListener('touchmove',e=>{ e.preventDefault(); cnt(e.touches.length>1?'pinch':'tmove'); moved=true; step(gestOf(e.touches)); },{passive:false});
  const tend=e=>{ e.preventDefault(); last=gestOf(e.touches); if(!e.touches.length){ st.classList.remove('drag');
      if(!moved&&e.changedTouches.length===1){ const now=Date.now(), t=e.changedTouches[0]; if(now-tapT<320){ const [cx,cy]=P(t.clientX,t.clientY); zoomAt(s<minS*1.6?s*2:minS,cx,cy); tapT=0; } else tapT=now; } } };
  st.addEventListener('touchend',tend,{passive:false}); st.addEventListener('touchcancel',tend,{passive:false});
  // мышь
  let mdown=false;
  st.addEventListener('mousedown',e=>{ e.preventDefault(); mdown=true; last=gestOf([e]); st.classList.add('drag'); });
  const mm=e=>{ if(mdown){ cnt('mmove'); step(gestOf([e])); } }, mu=()=>{ if(mdown){ mdown=false; last=null; st.classList.remove('drag'); } };
  addEventListener('mousemove',mm); addEventListener('mouseup',mu);
  st.addEventListener('wheel',e=>{ e.preventDefault(); cnt('wheel'); const [cx,cy]=rel(e); zoomAt(s*Math.exp(-e.deltaY*0.0015),cx,cy); },{passive:false});
  st.addEventListener('dblclick',e=>{ const [cx,cy]=rel(e); zoomAt(s<minS*1.6?s*2:minS,cx,cy); });
  // Safari на iPhone масштабирует страницу щипком \u2014 пока открыто окно, запрещаем
  const noZoom=e=>{ e.preventDefault(); };
  ['gesturestart','gesturechange','gestureend'].forEach(t=>document.addEventListener(t,noZoom,{passive:false}));
  ov.addEventListener('touchmove',e=>{ if(e.touches.length>1||!e.target.closest('input')) e.preventDefault(); },{passive:false});
  const close=v=>{ removeEventListener('resize',onRs); removeEventListener('keydown',key,true); removeEventListener('mousemove',mm); removeEventListener('mouseup',mu);
    ['gesturestart','gesturechange','gestureend'].forEach(t=>document.removeEventListener(t,noZoom)); ov.classList.add('out'); setTimeout(()=>ov.remove(),260); done(v); };
  const key=e=>{ if(e.key==='Escape'){ e.stopPropagation(); close(null); } if(e.key==='Enter'){ e.preventDefault(); e.stopPropagation(); ok(); } };
  addEventListener('keydown',key,true);
  // аватарка = ровно то, что видно в окошке: копируем готовый холст предпросмотра целиком.
  // (Safari на iPhone неверно рисует фото со смещением за край холста, поэтому отдельный пересчёт давал другую область.)
  const ok=()=>{ draw(); { const r=st.getBoundingClientRect(), sw=Math.min(W,Z/s); D.fin={Z,s:+s.toFixed(4),x:Math.round(x),y:Math.round(y),W,H,minS:+minS.toFixed(4),cw:cv.width,ch:cv.height,rw:Math.round(r.width),rh:Math.round(r.height),sx:Math.round(Math.max(0,Math.min(W-sw,-x/s))),sy:Math.round(Math.max(0,Math.min(H-Math.min(H,Z/s),-y/s))),sw:Math.round(sw)}; } const o=document.createElement('canvas'); o.width=o.height=512; const c=o.getContext('2d'); c.imageSmoothingQuality='high'; c.fillStyle='#fff'; c.fillRect(0,0,512,512);
    c.drawImage(cv,0,0,cv.width,cv.height,0,0,512,512); o.toBlob(b=>close(b),'image/jpeg',.9); };
  ov.querySelector('.crbt').onclick=e=>{ const a=e.target.closest('[data-a]')?.dataset.a; if(a==='x') close(null); else if(a==='ok') ok();
    else if(a==='r'){ cnt('rotate'); const r=document.createElement('canvas'); r.width=H; r.height=W; const c=r.getContext('2d'); c.translate(H,0); c.rotate(Math.PI/2); c.drawImage(src,0,0); src=r; W=r.width; H=r.height; reset(); } };
  ov.addEventListener('click',e=>{ if(e.target===ov) close(null); });
}); }
function dbg(kind,data){ try{ sb.rpc('lm_debug_log',{p_kind:kind,p_data:data}).then(()=>{},()=>{}); }catch{} }
function pickAvatar(cb){
document.querySelectorAll('input.lmfile').forEach(x=>x.remove());
const D={v:'c8',href:location.href.split('#')[0].slice(0,140),ua:navigator.userAgent,iw:innerWidth,ih:innerHeight,dpr:devicePixelRatio,vv:window.visualViewport?Math.round(visualViewport.scale*100)/100:null,tg:TGA.on};
const inp=document.createElement('input'); inp.type='file'; inp.accept='image/*'; inp.className='lmfile';
inp.style.cssText='position:fixed;left:-9999px;top:0;width:1px;height:1px;opacity:0';
document.body.appendChild(inp);
inp.onchange=async()=>{ const f=inp.files&&inp.files[0]; setTimeout(()=>inp.remove(),0); if(!f) return; D.file={type:f.type,size:f.size};
try{ const bmp=await loadPhoto(f); D.img=[bmp.width,bmp.height];
const blob=await cropImage(bmp,D); if(!blob){ D.cancel=1; return dbg('avatar',D); } D.out=blob.size; toast('Загрузка\u2026'); const url=await upload(blob,'jpg'); D.url=String(url).split('/').pop(); dbg('avatar',D); await cb(url); toast('Фото обновлено');
}catch(err){ D.err=String(err&&err.message||err); dbg('avatar',D); toast('Ошибка: '+err.message); } };
inp.click();
}
function showBannedOld(me){ const r=me.ban_reason;
  const d=document.createElement('div'); d.id='bannedScr';
  d.innerHTML=`<div class="bi">${ic('ban')}</div><h2>Аккаунт заблокирован</h2><p>Администратор Lumo заблокировал аккаунт @${esc(me.username)}.${r?`<br><br>Причина: ${esc(r)}`:''}</p><button class="btn primary" id="banOut">Выйти</button>`;
  ($('#lumo-root')||document.body).appendChild(d); d.querySelector('#banOut').onclick=logout; }
/* ================= АДМИН-ПАНЕЛЬ (владелец и администраторы) ================= */
const AD={tab:'home', stack:[], q:{}, f:{users:'all',chats:'all',reps:'new'}};
async function adminApi(body){ const {data:{session}}=await sb.auth.getSession();
  const r=await fetch(FN+'/admin',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+(session?.access_token||'')},body:JSON.stringify(body)});
  const j=await r.json().catch(()=>({error:'Сервер не ответил'})); if(!r.ok||j.error) throw new Error(j.error||('Ошибка '+r.status)); return j; }
async function rpc(n,a){ const {data,error}=await sb.rpc(n,a||{}); if(error) throw new Error(error.message); return data; }
const ADT=[['home','Обзор','chart'],['users','Люди','users'],['chats','Чаты','chat'],['msgs','Сообщения','search'],['reps','Жалобы','flag'],['apl','Апелляции','ban'],['cast','Рассылка','mega'],['files','Файлы','db'],['conf','Настройки','gear'],['log','Журнал','clock'],['dbg','Диагностика','info']];
const KIND_RU={text:'текст',image:'фото',video:'видео',voice:'голосовые',video_note:'кружки',file:'файлы',sticker:'стикеры',call:'звонки',system:'системные'};
const ACT_RU={ban:'Блокировка',unban:'Разблокировка',signout:'Завершение сеансов',avatar_remove:'Удаление фото',staff:'Права администратора',user_delete:'Удаление аккаунта',user_edit:'Изменение профиля',message_delete:'Удаление сообщения',chat_delete:'Удаление чата',chat_edit:'Изменение чата',member_remove:'Исключение из чата',broadcast:'Рассылка в приложение',tg_broadcast:'Рассылка в Telegram',config:'Настройки',file_delete:'Удаление файла',report:'Жалоба рассмотрена',self_delete:'Пользователь удалил аккаунт'};
const TYPE_RU={private:'личный',group:'группа',channel:'канал'};
const nf=n=>Number(n||0).toLocaleString('ru-RU');
const admAgo=d=>d?fmtDay(d)+', '+fmtT(d):'\u2014';
const admOnline=d=>!!d&&Date.now()-new Date(d).getTime()<120000;
const adCard=(i,t,v,sub,c)=>`<div class="adcard"><span class="sic" style="background:${c}">${ic(i)}</span><span class="t">${t}</span><b>${v}</b><span class="s">${sub}</span></div>`;
const adKv=(k,v)=>`<div class="adkv"><span>${k}</span><b>${v}</b></div>`;
const adEmpty=t=>`<div class="admuted">${t}</div>`;
const adSearch=(ph,v)=>`<label class="search adsearch"><span>${ic('search')}</span><input id="admQ" placeholder="${ph}" value="${esc(v||'')}" autocomplete="off"></label>`;
const adChips=(list,cur)=>`<div class="adchips">${list.map(x=>`<button data-f="${x[0]}" class="${cur===x[0]?'on':''}">${x[1]}</button>`).join('')}</div>`;
const roleTag=r=>r?`<em class="tg-${r}">${r==='owner'?'владелец':'админ'}</em>`:'';
const vMark=v=>v?` <span class="vbadge" title="Подтверждено администрацией Lumo">${ic('check')}</span>`:'';
/* нажатие на галочку — плашка «подтверждено администрацией Lumo» */
document.addEventListener('click',e=>{ const v=e.target.closest('.vbadge'); if(!v) return; e.stopPropagation(); e.preventDefault();
  const c=typeof cur==='function'?cur():null, inHead=!!v.closest('#who'), kind=inHead&&c&&c.type!=='private'?(c.type==='channel'?'Этот канал':'Эта группа'):'Этот профиль';
  let el=document.getElementById('vplq'); if(!el){ el=document.createElement('div'); el.id='vplq'; document.body.appendChild(el);
    const st=document.createElement('style'); st.textContent='#vplq{position:fixed;left:50%;top:calc(12px + env(safe-area-inset-top));transform:translate(-50%,-140%);z-index:99995;width:min(420px,calc(100vw - 24px));display:flex;gap:12px;align-items:center;padding:12px 16px;border-radius:22px;background:color-mix(in srgb,var(--panel) 82%,transparent);-webkit-backdrop-filter:blur(20px) saturate(1.6);backdrop-filter:blur(20px) saturate(1.6);box-shadow:0 10px 30px rgba(0,0,0,.18);border:1px solid color-mix(in srgb,var(--line) 60%,transparent);transition:transform .45s cubic-bezier(.34,1.4,.64,1),opacity .3s;opacity:0;cursor:pointer}#vplq.on{transform:translate(-50%,0);opacity:1}#vplq .vi{color:var(--a2);flex:none;width:28px;height:28px}#vplq .vi svg{width:28px;height:28px}#vplq b{display:block;font-size:15px}#vplq span{font-size:13.5px;color:var(--muted)}'; document.head.appendChild(st);
    el.onclick=()=>el.classList.remove('on'); }
  el.innerHTML=`<div class="vi">${ic('check')}</div><div><b>Подтверждено</b><span>${kind} подтверждён администрацией Lumo.</span></div>`;
  requestAnimationFrame(()=>el.classList.add('on')); clearTimeout(el._t); el._t=setTimeout(()=>el.classList.remove('on'),3200); },true);
const pMark=p=>p?vMark(p.verified)+(p.is_bot?'<span class="botbadge">БОТ</span>':'')+((p.premium&&!p.is_bot)?`<span class="prembadge" title="Premium">${p.emoji_status?emoHtml(p.emoji_status):'\u2605'}</span>`:''):'';
function kbHtml(m){ const b=m.meta&&m.meta.buttons; if(!Array.isArray(b)||!b.length||m.deleted) return ''; return `<div class="kb">${b.map(r=>`<div class="kr">${r.map(x=>x.url?`<button data-kburl="${esc(x.url)}">${esc(x.text)}</button>`:`<button data-kb="${esc(x.data||'')}">${esc(x.text)}</button>`).join('')}</div>`).join('')}</div>`; }
async function botCb(mid,data,btn){ if(btn) btn.disabled=true; try{ const {data:{session}}=await sb.auth.getSession(); const r=await fetch(SUPABASE_URL+'/functions/v1/lumo-bots/cb',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+(session?.access_token||''),apikey:SUPABASE_KEY},body:JSON.stringify({message_id:mid,data})}); const j=await r.json().catch(()=>({})); if(j&&j.toast) toast(j.toast); else if(!r.ok) toast('Не удалось выполнить действие'); }catch{ toast('Нет соединения'); } if(btn) btn.disabled=false; }
/* ===== Оплата картой (ЮMoney) прямо из Lumo ===== */
const PAY_RET='https://lumomess.ru/?lumo_paid=1', PAY_RATE=1.7;
const rubF=v=>(Math.abs(v-Math.round(v))<.001?Math.round(v).toLocaleString('ru-RU'):Number(v).toLocaleString('ru-RU',{minimumFractionDigits:2,maximumFractionDigits:2}))+' ₽';
const lpWord=n=>plural(Number(n)||0,'люмен','люмена','люменов');
const PAY_WATCH=new Set();
(function(){ if(document.getElementById('lpcss')) return; const st=document.createElement('style'); st.id='lpcss'; st.textContent=`
.lpov{position:fixed;inset:0;z-index:9000;background:rgba(5,6,18,.55);backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px);display:flex;align-items:center;justify-content:center;opacity:0;transition:opacity .2s}
.lpov.on{opacity:1}
.lpsh{width:420px;max-width:calc(100% - 24px);background:var(--bg);color:var(--text);border:1px solid var(--line);border-radius:26px;padding:14px 18px 20px;box-shadow:0 30px 90px rgba(0,0,0,.45);transform:translateY(14px) scale(.97);transition:transform .28s cubic-bezier(.2,.9,.3,1.2)}
.lpov.on .lpsh{transform:none}
.lph{display:flex;align-items:center;gap:10px;position:relative;min-height:38px}
.lpx{width:36px;height:36px;border-radius:50%;background:var(--panel2);display:flex;align-items:center;justify-content:center;flex:none;cursor:pointer;border:0;color:var(--text)}
.lpx svg{width:16px;height:16px;stroke:currentColor;stroke-width:2.4;stroke-linecap:round;fill:none}
.lpt{position:absolute;left:0;right:0;text-align:center;pointer-events:none}.lpt b{display:block;font-size:17px}.lpt span{font-size:12px;color:var(--muted)}
.lpart{height:130px;display:flex;align-items:center;justify-content:center;position:relative}
.lpglow{position:absolute;width:170px;height:170px;border-radius:50%;background:radial-gradient(circle,rgba(255,179,71,.4),transparent 62%);animation:lpgl 3s ease-in-out infinite}
@keyframes lpgl{0%,100%{transform:scale(.92)}50%{transform:scale(1.06)}}
.lpart .g{width:76px;height:76px;filter:drop-shadow(0 6px 20px rgba(255,140,60,.5));animation:lpsw 2.6s ease-in-out infinite}
@keyframes lpsw{0%,100%{transform:rotate(-7deg)}50%{transform:rotate(7deg) scale(1.05)}}
.lpsh h2{margin:4px 0 2px;text-align:center;font-size:23px;font-weight:800}
.lpsum{text-align:center;color:var(--muted);font-size:15px;margin-bottom:16px}
.lpbtn{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;height:52px;border:0;border-radius:16px;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;font-weight:800;font-size:16.5px;cursor:pointer;transition:transform .12s,filter .15s}
.lpbtn:hover{filter:brightness(1.08)}.lpbtn:active{transform:scale(.97)}.lpbtn.alt{background:var(--panel2);color:var(--text);font-weight:600;height:46px;margin-top:8px}
.lpnote{display:flex;gap:8px;color:var(--muted);font-size:12.5px;line-height:1.45;margin-top:14px}.lpnote svg{width:17px;height:17px;flex:none;fill:#2bd67b}
.lpspin{width:46px;height:46px;border-radius:50%;border:4px solid var(--panel2);border-top-color:var(--a1);animation:lpsp 1s linear infinite;margin:30px auto 18px}
@keyframes lpsp{to{transform:rotate(360deg)}}
.lpok{width:84px;height:84px;border-radius:50%;margin:24px auto 12px;background:linear-gradient(135deg,#2bd67b,#18a957);display:flex;align-items:center;justify-content:center;animation:lppop .5s cubic-bezier(.2,.9,.3,1.4)}
.lpok svg{width:44px;height:44px;stroke:#fff;stroke-width:3;fill:none;stroke-linecap:round;stroke-linejoin:round}
@keyframes lppop{from{transform:scale(.3);opacity:0}to{transform:none;opacity:1}}
`; document.head.appendChild(st); })();
const lpGem=(c='g')=>`<svg class="${c}" viewBox="0 0 24 24"><defs><linearGradient id="lpgg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffe08a"/><stop offset=".5" stop-color="#ff9a3d"/><stop offset="1" stop-color="#ff5e8a"/></linearGradient></defs><polygon points="12,0.48 21.98,6.24 21.98,17.76 12,23.52 2.02,17.76 2.02,6.24" fill="url(#lpgg)" stroke="rgba(255,255,255,.45)" stroke-width="1.08" stroke-linejoin="round"/><polygon points="12,5.04 13.27,10.73 18.96,12 13.27,13.27 12,18.96 10.73,13.27 5.04,12 10.73,10.73" fill="#fff"/></svg>`;
const lpStar=()=>`<svg class="g" viewBox="0 0 24 24"><defs><linearGradient id="lpsg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#c59bff"/><stop offset="1" stop-color="#6a7bff"/></linearGradient></defs><path fill="url(#lpsg)" d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z"/></svg>`;
const lpShield='<svg viewBox="0 0 24 24"><path d="M12 2l8 3v6c0 5-3.4 9.4-8 11-4.6-1.6-8-6-8-11V5zm-1.2 13.2l5.7-5.7-1.4-1.4-4.3 4.3-2-2-1.4 1.4z"/></svg>';
async function payFn(body){
  const {data:{session}}=await sb.auth.getSession();
  const r=await fetch(SUPABASE_URL+'/functions/v1/lumo-yoomoney',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+(session?.access_token||''),apikey:SUPABASE_KEY},body:JSON.stringify(body)});
  const j=await r.json().catch(()=>({})); if(!r.ok||!j.url) throw new Error(j.error||'Не удалось создать платёж'); return j;
}
async function payCreate(kind,qty,to){
  try{ const b={action:'create',kind,qty,return_url:PAY_RET}; if(to) b.to=to; const j=await payFn(b); payOpen(j.url,j.order_id,{kind,qty,amount:j.amount,to}); }
  catch(e){ toast(e.message||'Не удалось создать платёж'); }
}
function payWhat(i){ if(!i) return 'Оплата в Lumo'; return i.kind==='prem'?('Lumo Premium на '+i.qty+' мес.'+(i.to?' в подарок':'')):(i.qty+' '+lpWord(i.qty)); }
/** Окно оплаты: в браузере ЮMoney нельзя встроить в страницу, поэтому платёжная форма открывается отдельным окошком поверх Lumo и закрывается сама после оплаты */
function payOpen(url,order,info){
  document.querySelectorAll('.lpov').forEach(x=>x.remove());
  const o=document.createElement('div'); o.className='lpov';
  o.innerHTML=`<div class="lpsh"><div class="lph"><button class="lpx" data-lpx title="Закрыть"><svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg></button><div class="lpt"><b>Оплата</b><span>Банковская карта · ЮMoney</span></div></div><div class="lpb"></div></div>`;
  document.body.appendChild(o); requestAnimationFrame(()=>o.classList.add('on'));
  const body=o.querySelector('.lpb'); let win=null, timer=null, closed=false;
  const close=()=>{ if(closed) return; closed=true; clearInterval(timer); window.removeEventListener('message',onMsg); try{ win&&!win.closed&&win.close(); }catch{} o.classList.remove('on'); setTimeout(()=>o.remove(),220); };
  const art=()=>`<div class="lpart"><div class="lpglow" ${info&&info.kind==='prem'?'style="background:radial-gradient(circle,rgba(164,139,255,.45),transparent 62%)"':''}></div>${info&&info.kind==='prem'?lpStar():lpGem()}</div>`;
  const ready=()=>{ body.innerHTML=`${art()}<h2>${esc(payWhat(info))}</h2><div class="lpsum">${info&&info.amount?'К оплате: '+rubF(info.amount):'Оплата банковской картой'}</div>
    <button class="lpbtn" data-go>Оплатить картой</button>
    <div class="lpnote">${lpShield}<div>Оплата работает: откроется защищённая форма ЮMoney. После оплаты она закроется сама, а ${info&&info.kind==='prem'?'Premium включится':'люмены зачислятся'} автоматически, обычно за минуту.</div></div>`; };
  const waiting=()=>{ body.innerHTML=`<div class="lpspin"></div><h2>Ожидаем оплату</h2><div class="lpsum">Завершите оплату в окне ЮMoney.<br>Как только деньги поступят, здесь появится подтверждение.</div>
    <button class="lpbtn alt" data-go>Открыть форму оплаты снова</button>`; };
  const done=()=>{ body.innerHTML=`<div class="lpok"><svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg></div><h2>Оплата прошла</h2><div class="lpsum">${info&&info.kind==='prem'?(info.to?'Premium подарен':'Lumo Premium активирован'):'Начислено '+(info?info.qty:'')+' '+lpWord(info?info.qty:0)}</div><button class="lpbtn" data-lpx>Готово</button>`; };
  const go=()=>{ const w=480,h=760; const l=Math.max(0,(screen.width-w)/2), t=Math.max(0,(screen.height-h)/2);
    win=window.open(url,'lumopay',`popup=yes,width=${w},height=${h},left=${l},top=${t}`);
    if(!win){ try{ localStorage.setItem('lm_pay_pending',JSON.stringify({order,info,t:Date.now()})); }catch{} location.href=url; return; }
    waiting(); };
  const onMsg=e=>{ if(e&&e.data&&e.data.lumo_paid){ try{ win&&win.close(); }catch{} if(!closed) waiting(); } };
  window.addEventListener('message',onMsg);
  o.addEventListener('click',e=>{ if(e.target===o||e.target.closest('[data-lpx]')) return close(); if(e.target.closest('[data-go]')) go(); });
  ready();
  if(order) timer=setInterval(async()=>{ const st=await payStatus(order); if(st==='paid'){ clearInterval(timer); try{ win&&win.close(); }catch{} if(!closed){ done(); setTimeout(close,3500); } payAfter(info); } else if(st==='unknown') clearInterval(timer); },3000);
}
async function payStatus(order){ try{ const {data}=await sb.rpc('lm_pay_status',{p_order:order}); return data&&data.status; }catch{ return null; } }
async function payAfter(info){
  if(info&&info.kind==='prem'&&!info.to){ try{ await refreshMe(); }catch{} toast('Оплата прошла. Lumo Premium активирован'); try{ renderSettings(); }catch{} }
  else toast(info&&info.kind==='prem'?'Оплата прошла. Premium подарен':'Оплата прошла. Начислено '+(info?info.qty:'')+' '+lpWord(info?info.qty:0));
  try{ window.dispatchEvent(new Event('lumo-paid')); }catch{}
}
/** вернулись в Lumo после оплаты в этой же вкладке */
(function(){ if(!/[?&]lumo_paid\b/.test(location.search)) return;
  try{ if(window.opener&&window.opener!==window){ window.opener.postMessage({lumo_paid:1},'*'); window.close(); } }catch{}
  try{ history.replaceState(null,'',location.pathname); }catch{}
  let p=null; try{ p=JSON.parse(localStorage.getItem('lm_pay_pending')||'null'); localStorage.removeItem('lm_pay_pending'); }catch{}
  setTimeout(()=>toast('Платёж принят. Зачисляем…'),1500);
  if(p&&p.order){ let n=0; const t=setInterval(async()=>{ if(++n>200) return clearInterval(t); const st=await payStatus(p.order); if(st==='paid'||st==='unknown'){ clearInterval(t); if(st==='paid') payAfter(p.info); } },3000); }
})();
window.lumoPay={create:payCreate,open:payOpen,rub:rubF};
async function botCb(mid,data,btn){ if(btn) btn.disabled=true; try{ const {data:{session}}=await sb.auth.getSession(); const r=await fetch(SUPABASE_URL+'/functions/v1/lumo-bots/cb',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+(session?.access_token||''),apikey:SUPABASE_KEY},body:JSON.stringify(/^pay_/.test(data)?{message_id:mid,data,inline:true}:{message_id:mid,data})}); const j=await r.json().catch(()=>({}));
  if(j&&j.pay_url){ const q=/^pay_p(\d+)/.exec(data), l=/^pay_l(\d+)/.exec(data); payOpen(j.pay_url,j.order_id||null,q?{kind:'prem',qty:+q[1],amount:j.amount}:l?{kind:'lum',qty:+l[1],amount:j.amount}:null); }
  else if(j&&j.toast) toast(j.toast); else if(!r.ok) toast('Не удалось выполнить действие'); }catch{ toast('Нет соединения'); } if(btn) btn.disabled=false; }
function bindPremium(){ const me=S.me;
  document.querySelectorAll('[data-pp]').forEach(el=>el.onclick=()=>{ pmPlan=+el.dataset.pp; renderSettings(); });
  const buy=$('#pmBuy'); if(buy) buy.onclick=()=>{ const pl=PM_PLANS[pmPlan]||PM_PLANS[0]; buy.disabled=true; payCreate('prem',pl.m).finally(()=>{ buy.disabled=false; }); };
  const pb=$('#pmBot'); if(pb) pb.onclick=e=>{ e.preventDefault(); openByUsername('lumo_premium'); };
  document.querySelectorAll('[data-pf]').forEach(el=>el.onclick=()=>{ if(!me.premium) return; const k=el.dataset.pf; if(k==='emo') emojiStatusDlg(); else if(k==='px') profExtraDlg(); else if(k==='lock') setSPage('privacy'); else if(k==='look') setSPage('look'); else if(k==='bot') openByUsername('botfather'); });
  if(me.premium) sb.rpc('lm_my_premium').then(({data})=>{ const el=$('#pmSt'); if(!el||!data) return; el.textContent=data.owner?'Вы владелец Lumo — Premium включён навсегда':(data.until?('Premium активен до '+new Date(data.until).toLocaleDateString('ru-RU')):'Premium активен'); }); }

/* ===== точка «не прослушано» у голосовых и кружков (meta.lb — кто прослушал) ===== */
(function(){ if(document.getElementById('lscss')) return; const st=document.createElement('style'); st.id='lscss'; st.textContent=`
.vdw{display:flex;align-items:center;gap:6px}.lsd{width:7px;height:7px;border-radius:50%;background:var(--a1);flex:none;transition:transform .25s,opacity .25s}
.m.me .voice .lsd{background:#fff}.lsd.gone{transform:scale(0);opacity:0}
.vn .lsd{position:absolute;right:20px;bottom:20px;width:13px;height:13px;border:2.5px solid var(--bg);box-sizing:content-box;background:var(--a1)}`; document.head.appendChild(st); })();
const LS_LOCAL=new Set(), LS_SENT=new Set();
function lsUnheard(m){ if(!m||(m.kind!=='voice'&&m.kind!=='video_note')||!(m.id>0)||!S.me) return false;
  const lb=Array.isArray(m.meta&&m.meta.lb)?m.meta.lb:[];
  if(m.sender_id===S.me.id){ const c=S.chatMap.get(m.chat_id); if(c&&c.type==='private'&&c.peer_id===S.me.id) return false; return lb.length===0; }
  return !LS_LOCAL.has(m.id)&&!lb.includes(S.me.id); }
function lsDot(m){ return lsUnheard(m)?`<span class="lsd" data-lsd="${m.id}"></span>`:''; }
function lsMark(m){ if(!m||!S.me||m.sender_id===S.me.id||!lsUnheard(m)) return; LS_LOCAL.add(m.id);
  document.querySelectorAll(`[data-lsd="${m.id}"]`).forEach(d=>{ d.classList.add('gone'); setTimeout(()=>d.remove(),300); });
  if(LS_SENT.has(m.id)) return; LS_SENT.add(m.id); try{ sb.rpc('lm_voice_listen',{p_msg:m.id}).then(()=>{},()=>{}); }catch{} }
function lsOnlyLb(a,b){ try{ if(!a||!b||a.body!==b.body||a.media_url!==b.media_url||a.deleted!==b.deleted||a.edited_at!==b.edited_at) return false;
  const x=Object.assign({},a.meta||{}), y=Object.assign({},b.meta||{}); delete x.lb; delete y.lb; return JSON.stringify(x)===JSON.stringify(y); }catch{ return false; } }
function lsRefresh(m){ if(!lsUnheard(m)) document.querySelectorAll(`[data-lsd="${m.id}"]`).forEach(d=>{ d.classList.add('gone'); setTimeout(()=>d.remove(),300); }); }

/* ===== временная тема Vice Nights (до 1 декабря): закат, неон, пальмы — поверх обычного оформления (стекло и формы остаются) ===== */
(function(){
  const svgUrl=s=>"url(\"data:image/svg+xml;utf8,"+encodeURIComponent(s)+"\")";
  const SKY_SVG=`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 260' preserveAspectRatio='xMidYMax slice'><defs><linearGradient id='s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#2a0f52'/><stop offset='.35' stop-color='#6d2483'/><stop offset='.62' stop-color='#ff4f8b'/><stop offset='.84' stop-color='#ff9a3d'/><stop offset='1' stop-color='#ffd36b'/></linearGradient><linearGradient id='u' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffe58a'/><stop offset='1' stop-color='#ff8a3d'/></linearGradient><clipPath id='c'><circle cx='195' cy='238' r='62'/></clipPath></defs><rect width='390' height='260' fill='url(#s)'/><g fill='#fff'><circle cx='40' cy='30' r='1.2'/><circle cx='120' cy='18' r='1'/><circle cx='260' cy='26' r='1.3'/><circle cx='340' cy='44' r='1'/><circle cx='300' cy='12' r='.9'/><circle cx='70' cy='60' r='.9'/></g><g clip-path='url(#c)'><rect x='130' y='176' width='130' height='90' fill='url(#u)'/><g fill='#ff4f8b' opacity='.9'><rect x='130' y='222' width='130' height='3'/><rect x='130' y='232' width='130' height='4'/><rect x='130' y='243' width='130' height='5'/><rect x='130' y='254' width='130' height='6'/></g></g><path fill='#1a0b33' d='M0 260 L0 236 L26 236 L26 222 L44 222 L44 232 L62 232 L62 204 L78 204 L78 232 L110 232 L110 226 L128 226 L128 244 L262 244 L262 212 L274 212 L274 194 L284 194 L284 212 L298 212 L298 230 L330 230 L330 218 L350 218 L350 234 L390 234 L390 260 Z'/><g stroke='#120826' fill='none' stroke-linecap='round'><path stroke-width='5' d='M34 260 C36 230 40 190 48 156'/><path stroke-width='4.5' d='M48 156 C34 148 18 152 6 162 M48 156 C60 144 80 144 92 152 M48 156 C42 140 30 132 18 132 M48 156 C62 156 76 166 82 178 M48 156 C36 162 26 174 24 188'/><path stroke-width='5' d='M352 260 C350 234 346 206 338 176'/><path stroke-width='4.5' d='M338 176 C326 166 310 168 300 178 M338 176 C350 162 368 162 380 170 M338 176 C332 160 320 152 308 152 M338 176 C352 178 362 188 368 200'/></g></svg>`;
  const NIGHT_SVG=`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 800 800' preserveAspectRatio='xMidYMid slice'><g stroke='#2fd6d0' stroke-opacity='.18'><path d='M0 500H800M0 520H800M0 550H800M0 590H800M0 640H800M0 700H800M0 770H800'/></g><g stroke='#ff4f8b' stroke-opacity='.16'><path d='M400 500V800M370 500L190 800M340 500L-20 800M430 500L610 800M460 500L820 800M310 500L-230 800M490 500L1030 800'/></g><g stroke='#ff9a3d' stroke-opacity='.18' fill='none' stroke-linecap='round'><path stroke-width='7' d='M640 500C640 420 634 340 620 250'/><path stroke-width='6' d='M620 250C600 236 572 240 556 258M620 250C640 228 672 228 692 242M620 250C610 222 590 210 570 212M620 250C646 254 662 274 668 296M620 250C602 262 588 284 586 306'/></g></svg>`;
  const PALM_SVG=`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 300 300' preserveAspectRatio='xMidYMid slice'><rect width='300' height='300' fill='#0f0828'/><circle cx='210' cy='90' r='54' fill='#ff4f8b' opacity='.18'/><g stroke='#ff4f8b' fill='none' stroke-linecap='round' stroke-width='6'><path d='M150 300 C152 240 160 170 176 110'/><path d='M176 110 C150 92 120 98 98 116 M176 110 C198 86 236 86 262 102 M176 110 C166 80 142 66 120 68 M176 110 C204 112 228 132 238 156 M176 110 C152 122 136 146 132 172'/></g><g stroke='#2fd6d0' fill='none' stroke-linecap='round' stroke-width='5' opacity='.85'><path d='M70 300 C70 262 74 226 82 196'/><path d='M82 196 C66 186 46 190 32 202 M82 196 C96 182 118 182 134 192 M82 196 C88 212 92 228 90 246'/></g></svg>`;
  const SKY=svgUrl(SKY_SVG), NIGHT=svgUrl(NIGHT_SVG), PALM=svgUrl(PALM_SVG);
  const STAR='<svg viewBox="0 0 24 24"><path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z"/></svg>';
  const st=document.createElement('style'); st.id='vicecss'; st.setAttribute('data-lumo-own','1'); st.textContent=`
@import url('https://fonts.googleapis.com/css2?family=Anton&display=swap');
body.vice{--out:linear-gradient(135deg,#ff4f8b,#ff8a3d);--vglass:rgba(22,10,48,.34);--vline:rgba(255,255,255,.28)}
/* небо за шапкой */
body.vice #side::before{content:'';position:absolute;left:0;right:0;top:0;height:calc(272px + env(safe-area-inset-top));background:${SKY} center bottom/cover no-repeat;pointer-events:none;z-index:-1;
  -webkit-mask-image:linear-gradient(#000 66%,transparent);mask-image:linear-gradient(#000 66%,transparent);animation:viceSky 1s ease both}
@keyframes viceSky{from{opacity:0;transform:translateY(-14px)}to{opacity:1;transform:none}}
/* шапка: то же стекло, только тёмное поверх заката */
body.vice #tghead .mid b{font-family:Anton,Impact,sans-serif;font-weight:400;font-size:27px;letter-spacing:.6px;text-transform:uppercase;color:#fff;text-shadow:0 2px 0 #2a0f52,0 0 18px rgba(255,79,139,.8)}
body.vice #tghead .gb{background:var(--vglass);border-color:var(--vline);color:#fff;-webkit-backdrop-filter:blur(18px) saturate(1.6);backdrop-filter:blur(18px) saturate(1.6)}
body.vice #tghead .pair button{color:#fff}
body.vice #tghead .cmp{background:linear-gradient(135deg,#ff4f8b,#ff8a3d);box-shadow:0 0 0 2px #140a2e,3px 3px 0 2px #140a2e;transition:transform .15s}
body.vice #tghead .cmp:active{transform:translate(2px,2px);box-shadow:0 0 0 2px #140a2e,1px 1px 0 2px #140a2e}
body.vice #tghead .stk>*{background:transparent}
.vstars{display:none;gap:1px;margin-left:2px}
body.vice .vstars{display:inline-flex}
.vstars svg{width:13px;height:13px;fill:rgba(255,255,255,.28);stroke:#140a2e;stroke-width:1.5}
.vstars svg.on{fill:#ffd36b;filter:drop-shadow(0 0 4px rgba(255,211,107,.9));animation:vstar 1.4s ease-in-out infinite}
.vstars svg.on:nth-child(2){animation-delay:.12s}.vstars svg.on:nth-child(3){animation-delay:.24s}.vstars svg.on:nth-child(4){animation-delay:.36s}.vstars svg.on:nth-child(5){animation-delay:.48s}
@keyframes vstar{50%{transform:scale(1.18)}}
/* поиск */
body.vice #qbox .search{background:var(--vglass)!important;border:1px solid var(--vline)!important;box-shadow:none!important;-webkit-backdrop-filter:blur(18px) saturate(1.6);backdrop-filter:blur(18px) saturate(1.6)}
body.vice #q{background:transparent!important;color:#fff!important;border:0!important;box-shadow:none!important;outline:0}
body.vice #qbox .search svg,body.vice #qbox [data-i] svg{color:rgba(255,255,255,.85)}
body.vice #q::placeholder{color:rgba(255,255,255,.75)}
body.vice #qbox svg{color:#fff}
/* папки: стеклянная полоса, активная — жёлтая плашка */
body.vice #folders{background:var(--vglass);border:1px solid var(--vline);border-radius:20px;margin-left:10px;margin-right:10px;-webkit-backdrop-filter:blur(18px) saturate(1.6);backdrop-filter:blur(18px) saturate(1.6)}
body.vice #folders button{color:#fff!important;background:transparent!important;text-shadow:0 1px 2px rgba(0,0,0,.35);border-radius:10px;transition:transform .2s}
body.vice #folders button.on{background:#ffd36b!important;color:#140a2e!important;text-shadow:none;font-family:Anton,Impact,sans-serif;font-weight:400;letter-spacing:.6px;text-transform:uppercase;box-shadow:2px 2px 0 #140a2e;transform:rotate(-2deg)}
body.vice #folders .fc{background:#ff4f8b;color:#fff}
body.vice #folders .find{opacity:0}
/* список чатов */
body.vice .row .badge:not(.mute){background:linear-gradient(135deg,#ff4f8b,#ff8a3d);color:#fff;box-shadow:0 0 10px rgba(255,79,139,.55)}
body.vice .row.on{background:linear-gradient(90deg,rgba(255,79,139,.2),rgba(47,214,208,.08))}
/* нижняя панель */
body.vice #tabs{border-color:rgba(255,79,139,.45);box-shadow:0 8px 30px rgba(0,0,0,.25),0 0 22px rgba(255,79,139,.25)}
body.vice #tabs button.on{color:#ff4f8b;background:rgba(255,79,139,.14)}
body.vice #tabs button.on .ti svg{filter:drop-shadow(0 0 6px rgba(255,79,139,.75))}
/* переписка */
body.vice #chat{background:var(--wall, ${NIGHT} center/cover no-repeat, linear-gradient(180deg,#1a0b3a,#2b0f4f 45%,#4a1559 72%,#6b1d55))}
body.vice .day span{background:#ffd36b!important;color:#140a2e!important;font-family:Anton,Impact,sans-serif;font-weight:400;letter-spacing:.8px;text-transform:uppercase;border:0!important;
  border-radius:7px;box-shadow:3px 3px 0 #0c0620;display:inline-block;transform:rotate(-2deg);-webkit-backdrop-filter:none;backdrop-filter:none}
body.vice .m.me .b{box-shadow:0 2px 12px rgba(255,79,139,.28)}
body.vice #composer .cbox{box-shadow:0 0 0 1px rgba(47,214,208,.45),0 0 18px rgba(47,214,208,.22)}
body.vice #toast{border:2px solid #140a2e;box-shadow:4px 4px 0 #140a2e;background:#ffd36b;color:#140a2e}
/* заставка при запуске */
body.vice #splash{visibility:hidden!important}
/* звонки */
body.vice #call{background:${NIGHT} center/cover no-repeat,linear-gradient(180deg,#1a0b3a,#2b0f4f 45%,#4a1559 72%,#6b1d55)}
body.vice #call:has(#cAcc){background:${SKY} center bottom/cover no-repeat,${NIGHT} center/cover no-repeat,#140a2e}
body.vice #call .cinfo h2{font-family:Anton,Impact,sans-serif;font-weight:400;font-size:42px;letter-spacing:1px;text-transform:uppercase;text-shadow:0 3px 0 #2a0f52,0 0 18px rgba(255,79,139,.8)}
body.vice #call .cinfo .av{box-shadow:0 0 0 4px #ffd36b,0 0 0 7px #0c0620,0 0 40px rgba(255,79,139,.7)}
body.vice #call:has(#cAcc) .cinfo::before{content:'ВХОДЯЩИЙ ЗВОНОК';display:inline-block;margin-bottom:18px;padding:5px 14px;background:#ffd36b;color:#140a2e;font-family:Anton,Impact,sans-serif;font-size:17px;letter-spacing:1.2px;border-radius:6px;box-shadow:4px 4px 0 #0c0620;transform:rotate(-3deg);text-shadow:none}
body.vice #call .cinfo p:has(#ctime)::after{content:'ОТЛИЧНАЯ СВЯЗЬ';display:block;width:max-content;margin:12px auto 0;padding:4px 12px;background:#ffd36b;color:#140a2e;font-family:Anton,Impact,sans-serif;font-size:14px;letter-spacing:1px;border-radius:6px;box-shadow:3px 3px 0 #0c0620;transform:rotate(-2deg);text-shadow:none;opacity:1}
body.vice #call .cbtns button{background:rgba(22,10,48,.45);border:1px solid rgba(255,255,255,.22)}
body.vice #call .cbtns button.off{background:#ffd36b;color:#140a2e;border:0;box-shadow:3px 3px 0 #0c0620}
body.vice #call .cbtns button.end{background:linear-gradient(135deg,#ff3b5c,#ff8a3d);border:0;box-shadow:0 0 0 2px #0c0620,4px 4px 0 2px #0c0620}
body.vice #call .cbtns button.acc{background:#2bd67b;border:0;box-shadow:0 0 0 2px #0c0620,4px 4px 0 2px #0c0620}
/* переключатель в «Оформлении» */
.vicesw{display:flex;align-items:center;gap:12px;padding:12px 14px;border-radius:16px;background:var(--panel2);margin:10px 14px;cursor:pointer}
.vicesw .ic{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,#ff4f8b,#ff8a3d);display:flex;align-items:center;justify-content:center;flex:none}
.vicesw b{display:block;font-size:15px}.vicesw .t span{display:block;font-size:12.5px;color:var(--muted)}.vicesw .t{flex:1}
.vicesw input{width:22px;height:22px;accent-color:#ff4f8b}
/* вступление: комикс-панели, логотип и плашка */
#vintro{position:fixed;inset:0;z-index:99996;background:#140a2e;overflow:hidden;cursor:pointer;animation:viOut .55s cubic-bezier(.7,0,.3,1) 2.15s forwards}
@keyframes viOut{to{clip-path:polygon(100% 0,100% 0,100% 100%,100% 100%);visibility:hidden}}
#vintro .pn{position:absolute;border:4px solid #0c0620;box-shadow:0 0 0 5px #fff,10px 10px 0 5px rgba(0,0,0,.35);background-size:cover;background-position:center;opacity:0}
#vintro .p1{left:-4%;top:-3%;width:66%;height:46%;background-image:${SKY};transform:rotate(-4deg);animation:viP1 .5s cubic-bezier(.2,.9,.3,1.2) .05s forwards}
#vintro .p2{right:-6%;top:22%;width:52%;height:44%;background-image:${PALM};transform:rotate(5deg);animation:viP2 .5s cubic-bezier(.2,.9,.3,1.2) .2s forwards}
#vintro .p3{left:-6%;bottom:-4%;width:72%;height:40%;background:${NIGHT} center/cover,linear-gradient(180deg,#2b0f4f,#6b1d55);transform:rotate(3deg);animation:viP3 .5s cubic-bezier(.2,.9,.3,1.2) .35s forwards}
@keyframes viP1{from{opacity:0;transform:translate(-60px,-40px) rotate(-12deg)}to{opacity:1;transform:rotate(-4deg)}}
@keyframes viP2{from{opacity:0;transform:translate(80px,0) rotate(14deg)}to{opacity:1;transform:rotate(5deg)}}
@keyframes viP3{from{opacity:0;transform:translate(-40px,70px) rotate(-6deg)}to{opacity:1;transform:rotate(3deg)}}
#vintro .lg{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);text-align:center;z-index:2}
#vintro .lg b{display:block;font-family:Anton,Impact,sans-serif;font-weight:400;font-size:min(30vw,150px);line-height:.9;letter-spacing:2px;
  background:linear-gradient(180deg,#ffe58a 0%,#ffb347 40%,#ff4f8b 100%);-webkit-background-clip:text;background-clip:text;color:transparent;
  -webkit-text-stroke:4px #140a2e;paint-order:stroke fill;filter:drop-shadow(7px 7px 0 #140a2e) drop-shadow(0 0 30px rgba(255,79,139,.6));
  opacity:0;animation:viLogo .5s cubic-bezier(.2,1.4,.4,1) .6s forwards}
@keyframes viLogo{from{opacity:0;transform:scale(2.6) rotate(-10deg)}to{opacity:1;transform:rotate(-4deg)}}
#vintro .lg i{display:inline-block;margin-top:14px;font-style:normal;font-family:Anton,Impact,sans-serif;font-size:min(6vw,26px);letter-spacing:2px;color:#140a2e;background:#ffd36b;
  padding:4px 14px;border-radius:6px;box-shadow:4px 4px 0 #0c0620;opacity:0;animation:viStamp .35s cubic-bezier(.2,1.6,.4,1) 1s forwards}
@keyframes viStamp{from{opacity:0;transform:scale(1.8) rotate(8deg)}to{opacity:1;transform:rotate(3deg)}}
#vintro .fl{position:absolute;inset:0;background:#fff;opacity:0;animation:viFlash .35s ease .6s;pointer-events:none;z-index:3}
@keyframes viFlash{0%{opacity:.85}100%{opacity:0}}
`;
  document.head.appendChild(st);

  let avail=false; try{ const c=JSON.parse(localStorage.getItem('vice_av')||'null'); avail=!!(c&&c.on&&(!c.until||new Date(c.until)>new Date())); }catch{}
  const offNow=()=>{ try{ return localStorage.getItem('vice_off')==='1'; }catch{ return false; } };
  const meta=document.querySelector('meta[name="theme-color"]'); const meta0=meta&&meta.getAttribute('content');
  function intro(){
    // вступление показывает сама страница при запуске; здесь — только если она его не показала, а Lumo ещё грузится
    if(document.getElementById('vintro')||document.documentElement.classList.contains('vice')) return;
    const sp=document.getElementById('splash'); if(!sp||sp.classList.contains('out')) return;
    const o=document.createElement('div'); o.id='vintro'; o.setAttribute('aria-hidden','true');
    o.innerHTML='<div class="pn p1"></div><div class="pn p2"></div><div class="pn p3"></div><div class="fl"></div><div class="lg"><b>LUMO</b><i>VICE NIGHTS</i></div>';
    const done=()=>o.remove(); o.addEventListener('animationend',e=>{ if(e.animationName==='viOut') done(); }); o.onclick=done; setTimeout(done,3200);
    document.body.appendChild(o);
  }
  function apply(){ const on=avail&&!offNow(); const was=document.body.classList.contains('vice'); document.body.classList.toggle('vice',on);
    if(meta) meta.setAttribute('content',on?'#2a0f52':(meta0||''));
    if(on&&!was) intro(); }
  // уровень «розыска»: сколько чатов с непрочитанными (до пяти звёзд)
  function stars(){ const mid=document.querySelector('#tghead .mid'); if(!mid) return; let s=mid.querySelector('.vstars');
    if(!s){ s=document.createElement('span'); s.className='vstars'; s.title='Уровень розыска: чаты с непрочитанными'; s.innerHTML=STAR.repeat(5); const b=mid.querySelector('b'); b?b.after(s):mid.appendChild(s); }
    const n=Math.min(5,(window.S&&S.chats?S.chats:(typeof S!=='undefined'&&S.chats?S.chats:[])).filter(c=>c.unread&&!c.muted).length);
    s.querySelectorAll('svg').forEach((e,i)=>e.classList.toggle('on',i<n)); }
  const check=async()=>{ try{ const {data}=await sb.rpc('lm_get_config'); const e=data&&data.look&&data.look.event;
      avail=!!(e&&e.id==='vice'&&(!e.until||new Date(e.until)>new Date()));
      try{ localStorage.setItem('vice_av',JSON.stringify({on:avail,until:e&&e.until||null})); }catch{} }catch{} apply(); };
  window.viceToggle=on=>{ try{ localStorage.setItem('vice_off',on?'0':'1'); }catch{} apply(); };
  window.viceAvail=()=>avail;
  apply(); setTimeout(check,800); setInterval(check,30*60*1000); setInterval(()=>{ if(document.body.classList.contains('vice')) stars(); },1500);
  // переключатель в «Оформлении»
  new MutationObserver(()=>{ if(!avail||typeof SP==='undefined'||SP.page!=='look') return; const hd=document.querySelector('.sphead'); if(!hd||!hd.parentNode||hd.parentNode.querySelector('.vicesw')) return;
    const d=document.createElement('label'); d.className='vicesw';
    d.innerHTML=`<span class="ic"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round"><path d="M3 18h18M6 18a6 6 0 0 1 12 0M12 6V3M5 9 3.5 7.5M19 9l1.5-1.5"/></svg></span><span class="t"><b>Vice Nights</b><span>Закат, неон и пальмы — до 1 декабря</span></span><input type="checkbox" ${offNow()?'':'checked'}>`;
    d.querySelector('input').onchange=e=>viceToggle(e.target.checked);
    hd.after(d); }).observe(document.body,{childList:true,subtree:true});
})();

let pmPlan=0;
const PM_PLANS=[{t:'На 2 года',sub:'24 месяца \u00b7 2\u00a0490\u00a0\u20bd',per:'104\u00a0\u20bd/месяц',price:'2\u00a0490\u00a0\u20bd',tail:'на 2 года'},{t:'Ежегодно',badge:'\u221238%',sub:'12 месяцев \u00b7 1\u00a0490\u00a0\u20bd',per:'124\u00a0\u20bd/месяц',price:'1\u00a0490\u00a0\u20bd',tail:'на год'},{t:'Ежемесячно',sub:'',per:'199\u00a0\u20bd/месяц',price:'199\u00a0\u20bd',tail:'в месяц'}];
const PM_FEAT=[['smile','#ff9f0a','Анимированный эмодзи-статус','Живой значок рядом с именем \u2014 виден всем в чатах и профиле.','emo'],['palette','#a35bff','Эксклюзивное оформление','Особые цвета, фоны чатов и свой цвет ваших сообщений в каждом чате.','look'],['clock','#2bd67b','Умная отправка','Отложенные и тихие сообщения, исчезающие сообщения по таймеру.',''],['camera','#ff5b7a','Истории до 7 дней','Публикуйте истории на 48 часов, 3 дня или неделю.',''],['lock','#5b6cff','Блокировка приложения','Код при входе в Lumo \u2014 в разделе \u00abКонфиденциальность\u00bb.','lock'],['link','#22a6ff','Расширенный профиль','До 3 ссылок в вашем профиле.','px'],['at','#ff8a3d','Свои боты','Создавайте ботов через BotFather и подключайте их по API.','bot'],['file','#2b8cff','Файлы до 200 МБ','Отправляйте файлы и видео до 200 МБ. Без Premium — до 100 МБ.',''],['bar','#1fb6a6','Статистика каналов','Рост подписчиков и активность ваших каналов.',''],['star','#ffb020','Писать только Premium','Ограничьте входящие сообщения от людей без подписки \u2014 в \u00abКонфиденциальности\u00bb.','']];
function pmSparks(){ let s='',r=7; const rnd=()=>{ r=(r*9301+49297)%233280; return r/233280; }; for(let i=0;i<36;i++){ const x=rnd()*100,y=rnd()*100,z=6+rnd()*11,d=rnd()*3; s+=`<i style="left:${x}%;top:${y}%;width:${z}px;height:${z}px;animation-delay:${d.toFixed(2)}s"></i>`; } return s; }
function premiumPage(){
  const me=S.me, pl=PM_PLANS[pmPlan];
  return `<div class="pmpage"><div class="pmtop"><button class="hbtn" id="spBack">${ic('back')}</button></div>
<div class="pmhero"><div class="pmsp">${pmSparks()}</div><svg class="pmstar" viewBox="0 0 100 100"><defs><linearGradient id="pmg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7f8bff"/><stop offset=".55" stop-color="#b878ff"/><stop offset="1" stop-color="#e58bf0"/></linearGradient></defs><path d="m50 12 11 25 27 3-20 18 6 27-24-14-24 14 6-27L12 40l27-3z" fill="url(#pmg)" stroke="url(#pmg)" stroke-width="9" stroke-linejoin="round"/></svg>
<h1>Lumo Premium</h1><p>Больше свободы и десятки эксклюзивных возможностей с подпиской Lumo Premium.</p></div>
${me.premium?`<div class="pmok" id="pmSt">Premium активен</div>`:''}${`<div class="pmplans">${PM_PLANS.map((x,i)=>`<div class="pmplan ${i===pmPlan?'on':''}" data-pp="${i}"><span class="pmrad"></span><span class="pt"><b>${x.t}</b>${x.badge?`<span class="pmbadge">${x.badge}</span>`:''}${x.sub?`<small>${x.sub}</small>`:''}</span><span class="pp">${x.per}</span></div>`).join('')}</div>`}
<div class="pmsec">Преимущества подписки</div>
<div class="pmfeats">${PM_FEAT.map(f=>`<div class="pmf" data-pf="${f[4]}" ${f[4]&&me.premium?'style="cursor:pointer"':''}><span class="pi" style="background:${f[1]}">${ic(f[0])}</span><span><b>${f[2]}</b><span class="d">${f[3]}</span></span></div>`).join('')}</div>
<div class="pmsec">Скоро</div>
<div class="pmabout" style="color:var(--muted)">Секретные чаты \u00b7 перевод и расшифровка голосовых \u00b7 запись звонков \u00b7 размытие фона \u00b7 файлы до 4 ГБ \u00b7 посты в каналах по расписанию \u00b7 красивые ссылки \u00b7 видео-аватар. Всё это появится в обновлениях \u2014 функции включатся автоматически.</div>
<div class="pmsec">О Lumo Premium</div>
<div class="pmabout">Lumo бесплатен для всех. Подписка помогает оплачивать серверы и развивать мессенджер, а вам даёт дополнительные возможности. Оплата банковской картой через ЮMoney работает прямо в Lumo: Premium включается автоматически сразу после оплаты. Также подписку можно оформить в боте <a href="#" id="pmBot" style="color:var(--a1)">@lumo_premium</a>.</div>
<div class="pmbtn"><button id="pmBuy">${me.premium?`Продлить за ${pl.price}`:`Подключить за ${pl.price} ${pl.tail}`}</button></div></div>`; }
function bindPremium(){ const me=S.me;
  document.querySelectorAll('[data-pp]').forEach(el=>el.onclick=()=>{ pmPlan=+el.dataset.pp; renderSettings(); });
  const buy=$('#pmBuy'); if(buy) buy.onclick=()=>{ if(me.premium) openByUsername('lumo_premium'); else toast('Оплата Premium временно недоступна. Мы сообщим, когда она заработает.'); };
  const pb=$('#pmBot'); if(pb) pb.onclick=e=>{ e.preventDefault(); openByUsername('lumo_premium'); };
  document.querySelectorAll('[data-pf]').forEach(el=>el.onclick=()=>{ if(!me.premium) return; const k=el.dataset.pf; if(k==='emo') emojiStatusDlg(); else if(k==='px') profExtraDlg(); else if(k==='lock') setSPage('privacy'); else if(k==='look') setSPage('look'); else if(k==='bot') openByUsername('botfather'); });
  if(me.premium) sb.rpc('lm_my_premium').then(({data})=>{ const el=$('#pmSt'); if(!el||!data) return; el.textContent=data.owner?'Вы владелец Lumo \u2014 Premium включён навсегда':(data.until?('Premium активен до '+new Date(data.until).toLocaleDateString('ru-RU')):'Premium активен'); }); }
function openPremium(){ if(S.tab!=='settings') setTab('settings'); setSPage('premium'); }
const PREM_SOON='Это функция Lumo Premium. Оформить: Настройки \u2192 Lumo Premium';
const premOk=()=>{ if(S.me&&S.me.premium) return true; toast(PREM_SOON); return false; };
const fmtAt=d=>d.toLocaleString('ru-RU',{day:'numeric',month:'long',hour:'2-digit',minute:'2-digit'});
function scheduleDlg(){
  const t=$('#txt').value.trim(), c=cur(); if(!t||!c) return; const reply=S.reply;
  const d=new Date(Date.now()+3600e3), pd=n=>String(n).padStart(2,'0'); const v=`${d.getFullYear()}-${pd(d.getMonth()+1)}-${pd(d.getDate())}T${pd(d.getHours())}:${pd(d.getMinutes())}`;
  modal('Отложить отправку',`<p style="margin:4px 0 10px;color:var(--muted);font-size:14px">Сообщение уйдёт само в выбранное время, даже если Lumo закрыт.</p><input type="datetime-local" id="schAt" value="${v}" style="width:100%;box-sizing:border-box;font:inherit;padding:12px;border-radius:12px;border:1px solid rgba(127,127,127,.3);background:var(--panel);color:var(--text)">`,
  [['Отмена','ghost'],['Запланировать','primary',async cl=>{ const at=new Date($('#schAt').value); if(isNaN(at)||at<Date.now()+10000) return toast('Выберите время в будущем');
    let wire=t; await E2E.prepChat(c.chat_id); const e=await E2E.enc(c.chat_id,t); if(e) wire=e;
    const {error}=await sb.rpc('lm_schedule',{p_chat:c.chat_id,p_kind:'text',p_body:wire,p_media:null,p_meta:{},p_at:at.toISOString(),p_reply:reply?.id||null}); if(error) return toast(error.message);
    cl(); $('#txt').value=''; autoGrow(); S.reply=null; renderCtx(); toast('Запланировано на '+fmtAt(at)); }]]); }
async function schedList(){
  const c=cur(); if(!c) return; const {data,error}=await sb.rpc('lm_scheduled_list',{p_chat:c.chat_id}); if(error) return toast(error.message);
  const rows=data||[]; if(!rows.length) return toast('Запланированных сообщений нет'); await E2E.prepChat(c.chat_id);
  const items=await Promise.all(rows.map(async r=>{ let b=r.body||''; if(E2E.is(b)){ try{ b=await E2E.decStr(c.chat_id,b); }catch{ b='\u{1f512}'; } }
    return `<div style="display:flex;gap:8px;align-items:center;padding:8px 0"><div style="flex:1;min-width:0"><div style="font-weight:600">${esc(fmtAt(new Date(r.send_at)))}</div><div style="color:var(--muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(b)}</div></div><button class="btn ghost" data-sc="${r.id}">Отменить</button></div>`; }));
  modal('Запланированные',items.join(''),[['Закрыть','ghost']]);
  document.querySelectorAll('[data-sc]').forEach(b=>b.onclick=async()=>{ await sb.rpc('lm_scheduled_cancel',{p_id:+b.dataset.sc}); b.parentElement.remove(); toast('Отменено'); }); }
async function ttlDlg(c){
  const {data}=await sb.from('lm_chats').select('ttl_seconds').eq('id',c.chat_id).maybeSingle(); const now0=data?.ttl_seconds||0;
  const opts=[[0,'Выключено'],[3600,'1 час'],[86400,'1 день'],[604800,'1 неделя'],[2592000,'1 месяц']];
  const cl=modal('Исчезающие сообщения',`<p style="margin:4px 0 10px;color:var(--muted);font-size:14px">Сообщения в этом чате будут удаляться у всех через выбранное время после отправки.</p>${opts.map(o=>`<button class="btn ${o[0]===now0?'primary':'ghost'}" style="width:100%;margin:3px 0" data-ttl="${o[0]}">${o[1]}</button>`).join('')}`,[['Закрыть','ghost']]);
  document.querySelectorAll('[data-ttl]').forEach(b=>b.onclick=async()=>{ const v=+b.dataset.ttl; if(v>0&&!premOk()) return;
    const {error}=await sb.rpc('lm_set_chat_ttl',{p_chat:c.chat_id,p_seconds:v}); if(error) return toast(error.message); cl(); toast(v?'Исчезающие сообщения включены':'Исчезающие сообщения выключены'); }); }
async function statsDlg(c){
  if(!premOk()) return; const {data,error}=await sb.rpc('lm_channel_stats',{p_chat:c.chat_id}); if(error) return toast(error.message); const d=data||{};
  const mx=Math.max(1,...(d.days||[]).map(x=>Math.max(x.joined,x.posts)));
  const bars=(d.days||[]).map(x=>`<div title="${x.d}: +${x.joined} подписчиков, ${x.posts} постов" style="flex:1;display:flex;gap:1px;align-items:flex-end;height:70px"><div style="flex:1;background:var(--accent);height:${Math.max(2,Math.round(x.joined/mx*70))}px;border-radius:3px 3px 0 0"></div><div style="flex:1;background:#2bd67b;height:${Math.max(2,Math.round(x.posts/mx*70))}px;border-radius:3px 3px 0 0"></div></div>`).join('');
  modal('Статистика канала',`<div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">${[['Подписчиков',d.subscribers],['Новых за 7 дней',d.joined_7d],['Новых за 30 дней',d.joined_30d],['Постов всего',d.posts],['Постов за 7 дней',d.posts_7d]].map(a=>`<div style="background:var(--panel);border-radius:14px;padding:12px"><div style="font-size:22px;font-weight:800">${a[1]||0}</div><div style="color:var(--muted);font-size:13px">${a[0]}</div></div>`).join('')}</div><div style="margin:14px 0 6px;color:var(--muted);font-size:13px">Последние 14 дней: новые подписчики (синий) и посты (зелёный)</div><div style="display:flex;gap:3px;align-items:flex-end">${bars}</div>`,[['Закрыть','ghost']]); }
const AEMO={
 fire:['flick','<path d="M12 2c1 4 5 6 5 11a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-4-1-6 1-10z" fill="#ff7a1a"/><path d="M12 12c1 2 3 3 3 5a3 3 0 0 1-6 0c0-2 2-3 3-5z" fill="#ffd54a"/>'],
 heart:['beat','<path d="M12 21C5 15 2 11.5 2 8a5 5 0 0 1 10-1 5 5 0 0 1 10 1c0 3.5-3 7-10 13z" fill="#ff3d6e"/>'],
 star:['spin','<path d="m12 2 3 6.5 7 .9-5.2 4.8 1.4 7-6.2-3.4-6.2 3.4 1.4-7L2 9.4l7-.9z" fill="#ffc83d"/>'],
 rocket:['float','<path d="M12 2c3 2 5 6 5 10l-2 3H9l-2-3c0-4 2-8 5-10z" fill="#e8eefc"/><circle cx="12" cy="9" r="2" fill="#3a7bff"/><path d="M7 13l-3 4 4-1zM17 13l3 4-4-1z" fill="#ff5b7a"/><path d="M10 17h4l-2 5z" fill="#ffb020"/>'],
 crown:['bounce','<path d="M3 8l4 4 5-7 5 7 4-4-2 11H5z" fill="#ffc83d"/><circle cx="3" cy="8" r="1.6" fill="#ff9d00"/><circle cx="12" cy="5" r="1.6" fill="#ff9d00"/><circle cx="21" cy="8" r="1.6" fill="#ff9d00"/>'],
 gem:['shine','<path d="M6 3h12l4 6-10 12L2 9z" fill="#3ac8ff"/><path d="M2 9h20M9 3l-3 6 6 12 6-12-3-6" stroke="#fff" stroke-opacity=".6" fill="none" stroke-width="1"/>'],
 bolt:['flick','<path d="M13 2 4 14h6l-1 8 9-12h-6z" fill="#ffd21f"/>'],
 ghost:['float','<path d="M12 2a7 7 0 0 0-7 7v12l3-2 2 2 2-2 2 2 2-2 3 2V9a7 7 0 0 0-7-7z" fill="#f3f4ff"/><circle cx="9.5" cy="10" r="1.3" fill="#2a2d52"/><circle cx="14.5" cy="10" r="1.3" fill="#2a2d52"/>'],
 sun:['spin','<circle cx="12" cy="12" r="5" fill="#ffc83d"/><g stroke="#ffb020" stroke-width="2" stroke-linecap="round"><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2"/></g>'],
 moon:['sway','<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4 7 7 0 0 0 20 14.5z" fill="#ffd97a"/>'],
 clover:['sway','<g fill="#2bd67b"><circle cx="8.5" cy="8.5" r="4"/><circle cx="15.5" cy="8.5" r="4"/><circle cx="8.5" cy="15" r="4"/><circle cx="15.5" cy="15" r="4"/></g><path d="M12 14l-1 8" stroke="#1a9e5a" stroke-width="2" stroke-linecap="round"/>'],
 note:['bounce','<path d="M9 18V5l11-2v13" fill="none" stroke="#8a6bff" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/><circle cx="6.5" cy="18" r="3" fill="#8a6bff"/><circle cx="17.5" cy="16" r="3" fill="#8a6bff"/>'],
 snow:['spin','<g stroke="#8fd8ff" stroke-width="2" stroke-linecap="round"><path d="M12 2v20M3.5 7l17 10M3.5 17l17-10"/></g><circle cx="12" cy="12" r="1.6" fill="#fff"/>'],
 trophy:['bounce','<path d="M7 3h10v3a5 5 0 0 1-10 0V3z" fill="#ffc83d"/><path d="M7 4H4a3 3 0 0 0 3 4M17 4h3a3 3 0 0 1-3 4" fill="none" stroke="#ffb020" stroke-width="1.6" stroke-linecap="round"/><rect x="10" y="12" width="4" height="4" fill="#ffb020"/><rect x="7" y="18" width="10" height="2" rx="1" fill="#ffb020"/>'],
 skull:['sway','<path d="M12 3a7 7 0 0 0-7 7c0 2.6 1.3 4.1 2.3 5.3.4.5.7 1 .7 1.7v1h8v-1c0-.7.3-1.2.7-1.7C17.7 14.1 19 12.6 19 10a7 7 0 0 0-7-7z" fill="#eef0ff"/><circle cx="9" cy="11" r="1.6" fill="#2a2d52"/><circle cx="15" cy="11" r="1.6" fill="#2a2d52"/><path d="M11 14h2l-1 2z" fill="#2a2d52"/>'],
 pumpkin:['bounce','<ellipse cx="12" cy="13" rx="8" ry="7" fill="#ff8a1e"/><path d="M9 13a3 7 0 0 1 3-7 3 7 0 0 1 3 7" fill="none" stroke="#e8690a" stroke-width="1.2" opacity=".6"/><path d="M12 2c1.5 0 2 1.5 1 3-1 .5-2 .5-2.5 0-.5-1 0-3 1.5-3z" fill="#3a7a3a"/>'],
 confetti:['shine','<path d="M4 20l6-14 10 4z" fill="#8a6bff"/><circle cx="18" cy="5" r="1.4" fill="#ff5b7a"/><circle cx="21" cy="9" r="1.1" fill="#ffc83d"/><circle cx="14" cy="4" r="1" fill="#2bd67b"/><circle cx="19" cy="14" r="1" fill="#3ac8ff"/>'],
 witch:['sway','<path d="M12 2 7 15h10L12 2z" fill="#2a2240"/><ellipse cx="12" cy="15" rx="9" ry="2" fill="#2a2240"/><circle cx="10.5" cy="9" r="1" fill="#8a6bff"/>']};
const emoHtml=v=>{ v=String(v||''); if(v.startsWith('a:')){ const L=window.LSTAT&&window.LSTAT[v.slice(2)]; if(L) return '<span class="aemo lst">'+L+'</span>'; const a=AEMO[v.slice(2)]; return a?`<span class="aemo ${a[0]}"><svg viewBox="0 0 24 24">${a[1]}</svg></span>`:'\u2605'; } return esc(v); };

async function setEmo(e){ const {error}=await sb.rpc('lm_set_emoji_status',{p_emoji:e}); if(error) return toast(error.message); await refreshMe(); renderSettings(); toast(e?'Статус установлен':'Статус убран'); }
function emojiStatusDlg(){
  if(!premOk()) return;
  const cur0=S.me.emoji_status||'';
  const cl=modal('Эмодзи-статус',`<p style="margin:4px 0 10px;color:var(--muted);font-size:14px">Значок показывается рядом с вашим именем в чатах и профиле. Анимированные \u2014 только для Premium.</p><div class="aegrid">${Object.keys(AEMO).map(k=>`<button class="aeb ${cur0==='a:'+k?'on':''}" data-es="a:${k}">${emoHtml('a:'+k)}</button>`).join('')}</div>`,[['Убрать статус','ghost',async c=>{ c(); await setEmo(''); }],['Закрыть','ghost']]);
  document.querySelectorAll('[data-es]').forEach(b=>b.onclick=async()=>{ cl(); await setEmo(b.dataset.es); }); }
let sendHold=null, sendHeld=false;
const sendMenuOk=()=>!!($('#txt').value.trim()&&!S.edit&&!R.on&&!R.starting&&cur());
function openSendMenu(){ sendHeld=true; setTimeout(()=>{ sendHeld=false; },700);
  closeDrops(); const txt=($('#txt').value||'').trim().slice(0,400); const prem=!!(S.me&&S.me.premium);
  const fxb=e=>`<button data-fx="${e}">${e}${prem?'':`<i class="fxlk">${ic('lock','mini')}</i>`}</button>`;
  const o=document.createElement('div'); o.className='sov';
  o.innerHTML=`<div class="sstack"><div class="fxbar glass"><div class="fxt">Добавить анимированный эффект</div><div class="fxr">${FX_LIST.slice(0,7).map(fxb).join('')}<button class="fxmore" id="fxMore">${ic('down')}</button></div><div class="fxr2">${FX_LIST.slice(7).map(fxb).join('')}</div></div>
<div class="srow"><div class="sbub">${esc(txt)}</div><button class="sbtn" id="sovSend">${ic('send')}</button></div>
<div class="smenu glass"><button data-sm="0">${ic('belloff')}<span>Отправить без звука</span></button><button data-sm="1">${ic('clock')}<span>Отложить отправку\u2026</span></button><button data-sm="2">${ic('list')}<span>Запланированные</span></button></div></div>`;
  document.body.appendChild(o);
  const st=o.querySelector('.sstack'), br=$('#sendbtn').getBoundingClientRect(), sh=st.getBoundingClientRect();
  const rw=o.querySelector('.srow').getBoundingClientRect(); st.style.right=Math.max(12,innerWidth-br.right)+'px';
  st.style.top=Math.max(10,Math.min(br.top+br.height/2-(rw.top-sh.top)-rw.height/2, innerHeight-sh.height-10))+'px';
  o.addEventListener('click',ev=>{ const t=ev.target;
    const fx=t.closest('[data-fx]'); if(fx){ ev.stopPropagation(); closeDrops(); if(premOk()) sendText({fx:fx.dataset.fx}); return; }
    if(t.closest('#fxMore')){ ev.stopPropagation(); o.querySelector('.fxbar').classList.toggle('open'); return; }
    const sm=t.closest('[data-sm]'); if(sm){ ev.stopPropagation(); closeDrops(); const k=+sm.dataset.sm; if(k===0){ if(premOk()) sendText({silent:true}); } else if(k===1){ if(premOk()) scheduleDlg(); } else schedList(); return; }
    if(t.closest('#sovSend')){ ev.stopPropagation(); closeDrops(); sendText(); return; }
    if(t===o){ ev.stopPropagation(); closeDrops(); } }); }
const FX_LIST=['\u{1f44d}','\u{1f44e}','\u2764\ufe0f','\u{1f525}','\u{1f389}','\u{1f4a9}','\u{1f60d}','\u{1f929}','\u{1f973}','\u{1f4af}','\u{1f44f}','\u{1f602}','\u{1f622}','\u{1f621}'];
function playFx(e){ try{ if(matchMedia('(prefers-reduced-motion:reduce)').matches) return; let l=document.getElementById('fxl'); if(!l){ l=document.createElement('div'); l.id='fxl'; document.body.appendChild(l); }
  const W=innerWidth,H=innerHeight, up=(e==='\u{1f525}'||e==='\u2764\ufe0f'||e==='\u{1f60d}'), down=(e==='\u{1f4a9}');
  for(let i=0;i<28;i++){ const q=document.createElement('span'); q.className='fxp'; q.textContent=e; const x=W*(.08+Math.random()*.84), y=up?H*(.7+Math.random()*.25):down?H*(.05+Math.random()*.2):H*(.45+Math.random()*.2), sz=22+Math.random()*32, dx=(Math.random()-.5)*(up||down?120:W*.7), dy=up?-(H*.4+Math.random()*H*.35):down?(H*.5+Math.random()*H*.3):(Math.random()-.5)*H*.6;
    q.style.cssText=`--x:${x}px;--y:${y}px;--s:${sz}px;--dx:${dx}px;--dy:${dy}px;--r:${(Math.random()-.5)*120}deg;--d:${1.6+Math.random()*1.2}s;animation-delay:${(Math.random()*.35).toFixed(2)}s`; l.appendChild(q); }
  setTimeout(()=>{ if(l) l.innerHTML=''; },3600); }catch{} }
function admHl(t,q){ const s=esc(t||''); if(!q) return s; const e=esc(q).replace(/[.*+?^${}()|[\]\\]/g,'\\$&'); return s.replace(new RegExp(e,'gi'),m=>`<mark>${m}</mark>`); }

function openAdmin(push){ if(!S.staff) return; let el=$('#adm');
  if(!el){ el=document.createElement('div'); el.id='adm'; ($('#lumo-root')||document.body).appendChild(el); }
  el.innerHTML=`<div class="adh"><button class="hbtn" id="admX" title="Назад">${ic('back')}</button><div class="adt"><b>Админ-панель</b><span>${S.staff==='owner'?'Владелец':'Администратор'} \u00b7 Lumo</span></div><button class="hbtn" id="admR" title="Обновить">${ic('rotate')}</button></div>
<div class="adtabs" id="admTabs">${ADT.map(t=>`<button data-at="${t[0]}">${ic(t[2])}<span>${t[1]}</span></button>`).join('')}</div><div class="adb" id="admB"></div>`;
  el.classList.remove('out'); requestAnimationFrame(()=>el.classList.add('on'));
  $('#admX').onclick=()=>{ if(AD.stack.length){ AD.stack.pop(); admRender(); } else closeAdmin(); };
  $('#admR').onclick=()=>admRender();
  el.querySelectorAll('[data-at]').forEach(b=>b.onclick=()=>{ AD.tab=b.dataset.at; AD.stack=[]; admRender(); });
  AD.stack=push?[push]:[]; admRender(); }
function closeAdmin(){ const el=$('#adm'); if(!el) return; el.classList.remove('on'); el.classList.add('out'); setTimeout(()=>el.remove(),320); AD.stack=[]; }
function admPush(v){ AD.stack.push(v); admRender(); }
let admSeq=0;
async function admRender(){ const B=$('#admB'); if(!B) return; const my=++admSeq;
  document.querySelectorAll('#adm [data-at]').forEach(b=>b.classList.toggle('on',b.dataset.at===AD.tab&&!AD.stack.length));
  const on=document.querySelector('#adm [data-at].on'); if(on) on.scrollIntoView({block:'nearest',inline:'center',behavior:'smooth'});
  const top=AD.stack[AD.stack.length-1];
  B.innerHTML='<div class="adload"><span class="tgsp"></span></div>';
  try{ const V=document.createElement('div'); V.className='adview';
    if(top){ if(top.t==='user') await admUser(V,top.id); else if(top.t==='chat') await admChat(V,top.id); }
    else await ({home:admHome,users:admUsers,chats:admChats,msgs:admMsgs,reps:admReps,apl:admApl,cast:admCast,files:admFiles,conf:admConf,log:admLog,dbg:admDbg}[AD.tab])(V);
    if(my!==admSeq) return; B.innerHTML=''; B.appendChild(V); B.scrollTop=0; V.__after&&V.__after(); }
  catch(e){ if(my!==admSeq) return; B.innerHTML=`<div class="adempty">${ic('info')}<b>Не получилось загрузить</b><span>${esc(e.message)}</span></div>`; } }
function admBind(R){ R.querySelectorAll('[data-u]').forEach(r=>r.onclick=e=>{ if(e.target.closest('button,a')) return; admPush({t:'user',id:r.dataset.u}); });
  R.querySelectorAll('[data-c]').forEach(r=>r.onclick=e=>{ if(e.target.closest('button,a')) return; admPush({t:'chat',id:r.dataset.c}); });
  R.querySelectorAll('[data-dm]').forEach(b=>b.onclick=e=>{ e.stopPropagation(); confirmBox('Удалить это сообщение у всех?','Удалить',async()=>{ try{ await rpc('lm_admin_message_delete',{mid:+b.dataset.dm}); toast('Сообщение удалено'); const m=b.closest('.admsg'); if(m){ m.classList.add('del'); m.querySelector('.abx').innerHTML='<i>удалено</i>'; b.remove(); } }catch(er){ toast(er.message); } }); }); }
function admBars(arr){ const mx=Math.max(1,...arr.map(x=>x.n)); const sum=arr.reduce((a,x)=>a+x.n,0);
  return `<div class="adbars">${arr.map(x=>`<div class="adbar" title="${x.d}: ${x.n}"><em>${x.n||''}</em><i style="height:${Math.max(3,x.n/mx*100)}%"></i><span>${x.d.slice(0,2)}</span></div>`).join('')}</div><div class="adcount">Всего за 14 дней: ${nf(sum)}</div>`; }
function admUserRow(u){ return `<div class="adrow" data-u="${u.id}">${avatar({name:u.name,avatar:u.avatar_url,color:u.color},'s',admOnline(u.last_seen))}<div class="mid"><b>${esc(u.name)}${vMark(u.verified)}</b><span>@${esc(u.username)} \u00b7 ${admOnline(u.last_seen)?'в сети':u.last_seen?'был(а) '+admAgo(u.last_seen):'не заходил(а)'}${u.msgs!=null?' \u00b7 '+nf(u.msgs)+' сообщ.':''}</span></div><div class="tags">${roleTag(u.staff)}${u.banned?'<em class="tg-ban">бан</em>':''}${u.tg?'<em class="tg-tg">TG</em>':''}</div></div>`; }
function admMsgRow(m){ const t=m.deleted?'<i>удалено</i>':(m.kind==='text'?esc(admB(m.body)||''):`<i>${KIND_RU[m.kind]||esc(m.kind)}</i>${m.body?' '+esc(m.body):''}`)+(!m.deleted&&m.media_url?` <a href="${esc(m.media_url)}" target="_blank" rel="noopener">открыть</a>`:'');
  return `<div class="admsg ${m.deleted?'del':''}"><div class="h"><b>${esc(m.sender_name||'Система')}</b><span>${admAgo(m.created_at)}</span>${m.deleted?'':`<button class="adx" data-dm="${m.id}" title="Удалить">${ic('trash')}</button>`}</div><div class="abx">${t}</div></div>`; }

/* --- обзор --- */
async function admHome(V){ const [s,nrep]=await Promise.all([rpc('lm_admin_stats'),rpc('lm_admin_reports',{p_status:'new',lim:200}).then(r=>r.length).catch(()=>0)]); const ch=s.chats||{}, k=s.kinds||{};
  V.innerHTML=`<div class="adcards">
${adCard('users','Пользователи',nf(s.users),`+${nf(s.users_24h)} за сутки \u00b7 +${nf(s.users_7d)} за неделю`,'#7c5cff')}
${adCard('eye','Сейчас в сети',nf(s.online),`${nf(s.active_24h)} заходили за сутки`,'#2bd67b')}
${adCard('chat','Сообщения',nf(s.messages),`+${nf(s.messages_24h)} за сутки`,'#22a6ff')}
${adCard('users','Чаты',nf((ch.group||0)+(ch.channel||0)+(ch.private||0)),`${ch.group||0} групп \u00b7 ${ch.channel||0} каналов \u00b7 ${ch.private||0} личных`,'#ff8a3d')}
${adCard('db','Файлы',fmtSize(s.storage_bytes)||'0 Б',`${nf(s.files)} файлов`,'#13b0a5')}
${adCard('send','Telegram-бот',nf(s.tg_linked),'подключили уведомления','#2aabee')}
${adCard('ban','Заблокированы',nf(s.banned),'пользователей','#ff3b5c')}
${adCard('flag','Жалобы',nf(nrep),nrep?'новых \u2014 откройте вкладку \u00abЖалобы\u00bb':'новых нет','#ff9f1a')}
</div>
<div class="adsec"><h4>Сообщения за 14 дней</h4>${admBars(s.msg_days||[])}</div>
<div class="adsec"><h4>Новые пользователи за 14 дней</h4>${admBars(s.user_days||[])}</div>
<div class="adsec"><h4>Самые активные за неделю</h4>${(s.top||[]).map((u,i)=>`<div class="adrow" data-u="${u.id}"><span class="adnum">${i+1}</span><div class="mid"><b>${esc(u.name)}</b><span>@${esc(u.username)}</span></div><span class="adval">${nf(u.n)}</span></div>`).join('')||adEmpty('Пока пусто')}</div>
<div class="adsec"><h4>Типы сообщений</h4><div class="adkinds">${Object.entries(k).sort((a,b)=>b[1]-a[1]).map(([t,n])=>`<span><b>${nf(n)}</b>${KIND_RU[t]||esc(t)}</span>`).join('')||adEmpty('Нет сообщений')}</div></div>`;
  admBind(V); }

/* --- люди --- */
async function admUsers(V){
  V.innerHTML=adSearch('Имя или @юзернейм',AD.q.users)+adChips([['all','Все'],['online','В сети'],['new','Новые'],['staff','Админы'],['banned','Заблокированные']],AD.f.users)+'<div id="admL"></div>';
  const L=V.querySelector('#admL');
  const load=async()=>{ L.innerHTML='<div class="adload"><span class="tgsp"></span></div>';
    try{ const R=await rpc('lm_admin_users',{q:AD.q.users||'',p_filter:AD.f.users,lim:300,off:0});
      L.innerHTML=R.length?`<div class="adcount">Найдено: ${R.length}</div>`+R.map(admUserRow).join(''):adEmpty('Никого не найдено'); admBind(L); }
    catch(e){ L.innerHTML=adEmpty(esc(e.message)); } };
  let t; V.querySelector('#admQ').oninput=e=>{ AD.q.users=e.target.value; clearTimeout(t); t=setTimeout(load,300); };
  V.querySelectorAll('.adchips [data-f]').forEach(b=>b.onclick=()=>{ AD.f.users=b.dataset.f; V.querySelectorAll('.adchips button').forEach(x=>x.classList.toggle('on',x===b)); load(); });
  await load(); }

async function admUser(V,id){ const d=await rpc('lm_admin_user',{uid:id}); if(!d) throw new Error('Пользователь не найден');
  const p=d.profile, a=d.auth||{}, me=id===S.me.id, owner=S.staff==='owner', tOwner=p.staff==='owner', canMod=!me&&!tOwner&&(owner||!p.staff);
  V.innerHTML=`<div class="aduser">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'l',admOnline(p.last_seen))}<h2>${esc(p.name)}${vMark(p.verified)}</h2><div class="st">@${esc(p.username)} \u00b7 ${admOnline(p.last_seen)?'в сети':'был(а) '+admAgo(p.last_seen)}</div>
<div class="tags">${roleTag(p.staff)}${p.banned?`<em class="tg-ban">заблокирован${p.ban_reason?': '+esc(p.ban_reason):''}</em>`:''}${d.tg&&d.tg.enabled?'<em class="tg-tg">Telegram</em>':''}</div>${p.bio?`<p class="bio">${esc(p.bio)}</p>`:''}</div>
<div class="adacts">
${me?'':`<button data-a="dm">${ic('chat')}Написать</button>`}
<button data-a="edit">${ic('edit')}Изменить</button>
${p.avatar_url?`<button data-a="av">${ic('camera')}Удалить фото</button>`:''}
${canMod?`<button data-a="ban" class="${p.banned?'':'warn'}">${ic('ban')}${p.banned?'Разблокировать':'Заблокировать'}</button>`:''}
${canMod?`<button data-a="out">${ic('logout')}Завершить сеансы</button>`:''}
${owner&&!me?`<button data-a="staff">${ic('shield')}${p.staff?'Снять админа':'Сделать админом'}</button>`:''}
${canMod?`<button data-a="del" class="danger">${ic('trash')}Удалить аккаунт</button>`:''}
</div>
<div class="adgrid">
${adKv('Регистрация',admAgo(p.created_at))}${adKv('Последний вход',admAgo(a.last_sign_in_at))}${adKv('Активных сеансов',nf(a.sessions))}${adKv('Сообщений',nf(d.msgs)+' \u00b7 '+nf(d.msgs_7d)+' за неделю')}
${adKv('Файлы',nf(d.files)+' \u00b7 '+(fmtSize(d.bytes)||'0 Б'))}${adKv('Контакты',nf(d.contacts))}${adKv('Telegram',d.tg?esc(d.tg.tg_name||'подключён')+(d.tg.enabled?'':' (выключен)'):'не подключён')}${adKv('Кто звонит',{all:'все',contacts:'контакты',none:'никто'}[p.calls_from]||'все')}
</div>
<div class="adsec"><h4>Чаты \u00b7 ${d.chats.length}</h4>${d.chats.map(c=>`<div class="adrow" data-c="${c.id}"><span class="adti">${ic(c.type==='channel'?'mega':c.type==='group'?'users':'chat')}</span><div class="mid"><b>${esc(c.title||'Без названия')}</b><span>${TYPE_RU[c.type]||c.type}${c.role&&c.role!=='member'?' \u00b7 '+({owner:'создатель',admin:'админ'}[c.role]||c.role):''}${c.last?' \u00b7 '+admAgo(c.last):''}</span></div></div>`).join('')||adEmpty('Нет чатов')}</div>`;
  admBind(V);
  const act=async(fn,ok,pop)=>{ try{ await fn(); if(ok) toast(ok); if(pop) AD.stack.pop(); admRender(); }catch(e){ toast(e.message); } };
  V.querySelectorAll('[data-a]').forEach(b=>b.onclick=()=>{ const x=b.dataset.a;
    if(x==='dm'){ closeAdmin(); setTab('chats'); openDM(id); }
    else if(x==='edit') admEditUser(p);
    else if(x==='av') confirmBox(`Удалить фото профиля @${p.username}?`,'Удалить',()=>act(()=>rpc('lm_admin_remove_avatar',{uid:id}),'Фото удалено'));
    else if(x==='ban'){ if(p.banned) confirmBox(`Разблокировать @${p.username}?`,'Разблокировать',()=>act(()=>rpc('lm_admin_ban',{p_uid:id,p_ban:false}),'Пользователь разблокирован'));
      else modal('Блокировка',`<p style="margin:0 0 12px">@${esc(p.username)} не сможет писать и пользоваться Lumo: вместо приложения он увидит окно блокировки с причиной и сможет подать апелляцию.</p><div class="field"><label>Причина (её увидит пользователь)</label><input class="inp" id="banR" maxlength="200" placeholder="Например: спам"></div>`,
        [['Отмена','ghost'],['Заблокировать','danger',c=>{ const r=$('#banR').value.trim(); c(); act(()=>rpc('lm_admin_ban',{p_uid:id,p_ban:true,p_reason:r}),'Пользователь заблокирован'); }]]); }
    else if(x==='out') confirmBox(`Завершить все сеансы @${p.username}? Ему придётся войти заново.`,'Завершить',()=>act(()=>adminApi({action:'signout',uid:id}),'Сеансы завершены'));
    else if(x==='staff') confirmBox(p.staff?`Снять права администратора с @${p.username}?`:`Сделать @${p.username} администратором? Он получит доступ к этой панели (но не сможет управлять владельцем).`,p.staff?'Снять':'Назначить',()=>act(()=>rpc('lm_admin_set_staff',{uid:id,p_role:p.staff?null:'admin'}),'Готово'));
    else if(x==='del') confirmBox(`Удалить аккаунт @${p.username} навсегда? Удалятся профиль, его личные чаты и файлы. Отменить будет нельзя.`,'Удалить навсегда',()=>act(()=>adminApi({action:'delete_user',uid:id}),'Аккаунт удалён',true));
  }); }
function admEditUser(p){ modal('Изменить пользователя',`<div class="field"><label>Имя</label><input class="inp" id="aeN" maxlength="64" value="${esc(p.name)}"></div>
<div class="field"><label>Юзернейм</label><div class="atinp"><span>@</span><input class="inp" id="aeU" maxlength="32" value="${esc(p.username)}" autocapitalize="off" spellcheck="false"></div></div>
<div class="field"><label>О себе</label><textarea class="inp" id="aeB" rows="3" maxlength="200" style="resize:none">${esc(p.bio||'')}</textarea></div>
<label class="adchk"><input type="checkbox" id="aeV" ${p.verified?'checked':''}><span>Отметка \u00abпроверенный\u00bb ${ic('check')}</span></label>`,
  [['Отмена','ghost'],['Сохранить','primary',async c=>{ try{ await rpc('lm_admin_user_save',{uid:p.id,p_name:$('#aeN').value,p_username:$('#aeU').value,p_bio:$('#aeB').value,p_verified:$('#aeV').checked}); c(); toast('Сохранено'); admRender(); }catch(e){ toast(e.message); } }]]); }

/* --- чаты --- */
async function admChats(V){
  V.innerHTML=adSearch('Название, @ссылка или участник',AD.q.chats)+adChips([['all','Все'],['group','Группы'],['channel','Каналы'],['private','Личные']],AD.f.chats)+'<div id="admL"></div>';
  const L=V.querySelector('#admL');
  const load=async()=>{ L.innerHTML='<div class="adload"><span class="tgsp"></span></div>';
    try{ const R=await rpc('lm_admin_chats',{q:AD.q.chats||'',p_type:AD.f.chats,lim:300,off:0});
      L.innerHTML=R.length?`<div class="adcount">Найдено: ${R.length}</div>`+R.map(c=>`<div class="adrow" data-c="${c.id}">${avatar({name:c.title,avatar:c.avatar_url,color:c.color,icon:c.type==='channel'?'mega':c.type==='group'?'users':null},'s')}<div class="mid"><b>${esc(c.title||'Без названия')}</b><span>${TYPE_RU[c.type]||c.type} \u00b7 ${nf(c.members)} уч. \u00b7 ${nf(c.msgs)} сообщ.${c.last_message_at?' \u00b7 '+admAgo(c.last_message_at):''}</span></div><div class="tags">${c.is_public?'<em class="tg-tg">публичный</em>':''}</div></div>`).join(''):adEmpty('Ничего не найдено'); admBind(L); }
    catch(e){ L.innerHTML=adEmpty(esc(e.message)); } };
  let t; V.querySelector('#admQ').oninput=e=>{ AD.q.chats=e.target.value; clearTimeout(t); t=setTimeout(load,300); };
  V.querySelectorAll('.adchips [data-f]').forEach(b=>b.onclick=()=>{ AD.f.chats=b.dataset.f; V.querySelectorAll('.adchips button').forEach(x=>x.classList.toggle('on',x===b)); load(); });
  await load(); }

async function admChat(V,id){ const [c,M]=await Promise.all([rpc('lm_admin_chat',{cid:id}),rpc('lm_admin_chat_messages',{cid:id,before_id:null,lim:50})]); if(!c) throw new Error('Чат не найден');
  const title=c.type==='private'?(c.members.map(m=>m.name).join(' \u2194 ')||'Личный чат'):(c.title||'Без названия');
  V.innerHTML=`<div class="aduser">${avatar({name:title,avatar:c.avatar_url,color:c.color,icon:c.type==='channel'?'mega':c.type==='group'?'users':null},'l')}<h2>${esc(title)}</h2><div class="st">${{private:'Личный чат',group:'Группа',channel:'Канал'}[c.type]||c.type}${c.username?' \u00b7 @'+esc(c.username):''} \u00b7 ${nf(c.msgs)} сообщений</div>${c.description?`<p class="bio">${esc(c.description)}</p>`:''}<div class="tags">${c.is_public?'<em class="tg-tg">публичный</em>':''}</div></div>
<div class="adacts">${c.type!=='private'?`<button data-a="edit">${ic('edit')}Изменить</button>`:''}<button data-a="del" class="danger">${ic('trash')}Удалить чат</button></div>
<div class="adgrid">${adKv('Создан',admAgo(c.created_at))}${adKv('Последнее сообщение',admAgo(c.last_message_at))}</div>
<div class="adsec"><h4>Участники \u00b7 ${c.members.length}</h4>${c.members.map(m=>`<div class="adrow" data-u="${m.id}">${avatar({name:m.name,avatar:m.avatar_url,color:m.color},'s')}<div class="mid"><b>${esc(m.name)}</b><span>@${esc(m.username)}${m.role!=='member'?' \u00b7 '+({owner:'создатель',admin:'админ'}[m.role]||m.role):''}</span></div>${c.type!=='private'&&m.id!==S.me.id?`<button class="adx" data-rm="${m.id}" title="Исключить">${ic('userx')}</button>`:''}</div>`).join('')||adEmpty('Нет участников')}</div>
<div class="adsec"><h4>Сообщения</h4><div id="admMs">${M.map(admMsgRow).join('')||adEmpty('Сообщений нет')}</div>${M.length===50?'<button class="btn ghost w" id="admMore">Показать ещё</button>':''}</div>`;
  admBind(V);
  V.querySelectorAll('[data-rm]').forEach(b=>b.onclick=e=>{ e.stopPropagation(); const m=c.members.find(x=>x.id===b.dataset.rm);
    confirmBox(`Исключить ${m?m.name:'участника'} из \u00ab${title}\u00bb?`,'Исключить',async()=>{ try{ await adminApi({action:'remove_member',cid:id,uid:b.dataset.rm}); toast('Исключён'); admRender(); }catch(er){ toast(er.message); } }); });
  const more=V.querySelector('#admMore'); if(more){ let last=M[M.length-1].id; more.onclick=async()=>{ more.classList.add('loading');
    try{ const R=await rpc('lm_admin_chat_messages',{cid:id,before_id:last,lim:50}); const box=V.querySelector('#admMs'); const tmp=document.createElement('div'); tmp.innerHTML=R.map(admMsgRow).join(''); admBind(tmp); [...tmp.children].forEach(x=>box.appendChild(x)); if(R.length) last=R[R.length-1].id; if(R.length<50) more.remove(); }
    catch(e){ toast(e.message); } more.classList.remove('loading'); }; }
  V.querySelectorAll('[data-a]').forEach(b=>b.onclick=()=>{ const x=b.dataset.a;
    if(x==='del') confirmBox(`Удалить \u00ab${title}\u00bb со всеми сообщениями у всех участников? Отменить будет нельзя.`,'Удалить',async()=>{ try{ await adminApi({action:'delete_chat',cid:id}); toast('Чат удалён'); AD.stack.pop(); admRender(); loadChats(); }catch(e){ toast(e.message); } });
    if(x==='edit') modal('Изменить',`<div class="field"><label>Название</label><input class="inp" id="acT" maxlength="64" value="${esc(c.title||'')}"></div><div class="field"><label>Описание</label><textarea class="inp" id="acD" rows="3" maxlength="255" style="resize:none">${esc(c.description||'')}</textarea></div><label class="adchk"><input type="checkbox" id="acP" ${c.is_public?'checked':''}><span>Публичный (можно найти в поиске)</span></label>`,
      [['Отмена','ghost'],['Сохранить','primary',async cl=>{ try{ await rpc('lm_admin_chat_save',{cid:id,p_title:$('#acT').value.trim(),p_description:$('#acD').value.trim(),p_public:$('#acP').checked}); cl(); toast('Сохранено'); admRender(); }catch(e){ toast(e.message); } }]]);
  }); }

/* --- поиск по сообщениям --- */
async function admMsgs(V){
  V.innerHTML=adSearch('Текст сообщения',AD.q.msgs)+'<div id="admL"></div>';
  const L=V.querySelector('#admL');
  const load=async()=>{ const q=(AD.q.msgs||'').trim(); if(q.length<2){ L.innerHTML=adEmpty('Введите хотя бы 2 символа \u2014 поиск идёт по всем чатам'); return; }
    L.innerHTML='<div class="adload"><span class="tgsp"></span></div>';
    try{ const R=await rpc('lm_admin_messages',{q,lim:150});
      L.innerHTML=R.length?`<div class="adcount">Найдено: ${R.length}</div>`+R.map(m=>`<div class="admsg" data-c="${m.chat_id}"><div class="h"><b>${esc(m.sender_name||'')}</b><span>${esc(m.chat_type==='private'?'личный чат':m.chat_title)} \u00b7 ${admAgo(m.created_at)}</span><button class="adx" data-dm="${m.id}" title="Удалить">${ic('trash')}</button></div><div class="abx">${admHl(admB(m.body),q)}</div></div>`).join(''):adEmpty('Ничего не найдено'); admBind(L); }
    catch(e){ L.innerHTML=adEmpty(esc(e.message)); } };
  let t; V.querySelector('#admQ').oninput=e=>{ AD.q.msgs=e.target.value; clearTimeout(t); t=setTimeout(load,350); };
  await load(); }

/* --- жалобы --- */
async function admReps(V){
  const RR=Object.fromEntries(REASONS);
  V.innerHTML=adChips([['new','Новые'],['done','Решённые'],['rejected','Отклонённые'],['all','Все']],AD.f.reps)+'<div id="admL"></div>';
  const L=V.querySelector('#admL');
  const load=async()=>{ L.innerHTML='<div class="adload"><span class="tgsp"></span></div>';
    try{ const R=await rpc('lm_admin_reports',{p_status:AD.f.reps,lim:200});
      L.innerHTML=R.length?`<div class="adcount">Жалоб: ${R.length}</div>`+R.map(r=>`<div class="adrep ${r.status}"><div class="h"><b>${esc(RR[r.reason]||r.reason)}</b><span>${admAgo(r.created_at)}</span></div>
<div class="abx">От <a data-u2="${r.reporter_id||''}">@${esc(r.reporter_username||'?')}</a>${r.target_user?` на <a data-u2="${r.target_user}">@${esc(r.target_username||'?')}</a>${r.target_banned?' <em class="tg-ban">бан</em>':''}`:''}${r.chat_type?` \u00b7 ${esc(r.chat_type==='private'?'личный чат':(r.chat_title||'чат'))}`:''}</div>
${r.message_text?`<div class="rq">${esc(r.message_text)}</div>`:''}${r.comment?`<div class="abx">\u00ab${esc(r.comment)}\u00bb</div>`:''}
<div class="rb">${r.target_user?`<button data-u2="${r.target_user}">${ic('user')}Профиль</button>`:''}${r.chat_id?`<button data-c2="${r.chat_id}">${ic('chat')}Чат</button>`:''}${r.status==='new'?`<button data-rs="done" data-id="${r.id}">${ic('check')}Решено</button><button data-rs="rejected" data-id="${r.id}">${ic('x')}Отклонить</button>`:`<span class="st">${r.status==='done'?'решено':'отклонено'}${r.handled_name?' \u00b7 '+esc(r.handled_name):''}</span>`}</div></div>`).join(''):adEmpty(AD.f.reps==='new'?'Новых жалоб нет':'Пусто');
      L.querySelectorAll('[data-u2]').forEach(b=>b.onclick=()=>b.dataset.u2&&admPush({t:'user',id:b.dataset.u2}));
      L.querySelectorAll('[data-c2]').forEach(b=>b.onclick=()=>admPush({t:'chat',id:b.dataset.c2}));
      L.querySelectorAll('[data-rs]').forEach(b=>b.onclick=async()=>{ try{ await rpc('lm_admin_report_set',{rid:+b.dataset.id,p_status:b.dataset.rs}); toast(b.dataset.rs==='done'?'Отмечено как решённое':'Жалоба отклонена'); load(); }catch(e){ toast(e.message); } }); }
    catch(e){ L.innerHTML=adEmpty(esc(e.message)); } };
  V.querySelectorAll('.adchips [data-f]').forEach(b=>b.onclick=()=>{ AD.f.reps=b.dataset.f; V.querySelectorAll('.adchips button').forEach(x=>x.classList.toggle('on',x===b)); load(); });
  await load(); }

/* --- рассылка --- */
async function admCast(V){
  V.innerHTML=`<div class="adsec"><h4>Сообщение всем пользователям</h4>
<textarea class="inp" id="caT" rows="6" maxlength="3000" placeholder="Текст рассылки\u2026" style="resize:vertical;width:100%"></textarea>
<div class="adradio"><label><input type="radio" name="caM" value="app" checked><span><b>В приложение</b>Сообщение в официальном канале \u00abLumo\u00bb \u2014 канал появится у всех пользователей. Кто сейчас не в Lumo, получит уведомление в Telegram.</span></label>
<label><input type="radio" name="caM" value="tg"><span><b>Только в Telegram</b>Сообщение от бота всем, кто подключил уведомления (<span id="caN">\u2026</span>).</span></label></div>
<button class="btn primary w" id="caGo">${ic('send')} Отправить</button></div>`;
  V.__after=()=>{ rpc('lm_admin_stats').then(s=>{ const e=$('#caN'); if(e) e.textContent=nf(s.tg_linked)+' чел.'; }).catch(()=>{});
    $('#caGo').onclick=()=>{ const t=$('#caT').value.trim(); if(!t) return toast('Введите текст'); const m=document.querySelector('[name=caM]:checked').value;
      confirmBox(m==='app'?'Отправить сообщение всем пользователям в канал \u00abLumo\u00bb?':'Отправить сообщение всем в Telegram?','Отправить',async()=>{ const b=$('#caGo'); b.classList.add('loading');
        try{ if(m==='app'){ await rpc('lm_admin_broadcast',{p_text:t}); toast('Отправлено в канал \u00abLumo\u00bb'); loadChats(); }
             else { const r=await adminApi({action:'tg_broadcast',text:t}); toast(`Отправлено в Telegram: ${r.sent} из ${r.total}`); }
             $('#caT').value=''; }
        catch(e){ toast(e.message); } b.classList.remove('loading'); }); }; }; }

/* --- файлы --- */
async function admFiles(V){ const s=await rpc('lm_admin_storage'); const T=s.types||[]; const mx=Math.max(1,...T.map(t=>t.b));
  const url=n=>`${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${n}`;
  V.innerHTML=`<div class="adcards">${adCard('db','Хранилище',fmtSize(s.total)||'0 Б',nf(s.count)+' файлов','#13b0a5')}</div>
<div class="adsec"><h4>По типам</h4>${T.map(t=>`<div class="adhb"><span>${{image:'Фото',video:'Видео',audio:'Аудио',application:'Документы'}[t.k]||esc(t.k)}</span><i><b style="width:${Math.max(2,t.b/mx*100)}%"></b></i><em>${fmtSize(t.b)} \u00b7 ${nf(t.n)}</em></div>`).join('')||adEmpty('Файлов нет')}</div>
<div class="adsec"><h4>Кто занимает больше всего</h4>${(s.users||[]).map(u=>`<div class="adrow" data-u="${u.id}"><div class="mid"><b>${esc(u.name)}</b><span>@${esc(u.username)} \u00b7 ${nf(u.n)} файлов</span></div><span class="adval">${fmtSize(u.b)}</span></div>`).join('')||adEmpty('Пусто')}</div>
<div class="adsec"><h4>Самые большие файлы</h4>${(s.big||[]).map(f=>`<div class="adrow"><span class="adti">${ic(/^image/.test(f.mt)?'image':/^video/.test(f.mt)?'video':/^audio/.test(f.mt)?'mic':'file')}</span><div class="mid"><b>${fmtSize(f.b)} \u00b7 ${esc(f.mt||'')}</b><span>@${esc(f.username||'?')} \u00b7 ${admAgo(f.created_at)}</span></div><a class="adx" href="${esc(url(f.name))}" target="_blank" rel="noopener" title="Открыть">${ic('eye')}</a><button class="adx" data-rf="${esc(f.name)}" title="Удалить">${ic('trash')}</button></div>`).join('')||adEmpty('Пусто')}</div>`;
  admBind(V);
  V.querySelectorAll('[data-rf]').forEach(b=>b.onclick=()=>confirmBox('Удалить файл? В сообщениях он перестанет открываться.','Удалить',async()=>{ try{ await adminApi({action:'delete_file',path:b.dataset.rf}); toast('Файл удалён'); admRender(); }catch(e){ toast(e.message); } })); }

/* --- настройки --- */
async function admConf(V){ const c=await rpc('lm_get_config'); const reg=c.registration_open!==false; const an=c.announce&&c.announce.text?c.announce:null;
  V.innerHTML=`<div class="adsec"><h4>Доступ</h4><div class="setgrp">${stog('cfReg','userplus','#2bd67b','Регистрация открыта','Новые пользователи могут создавать аккаунты \u2014 по паролю и через Telegram',reg)}</div></div>
<div class="adsec"><h4>Объявление вверху списка чатов</h4><textarea class="inp" id="cfA" rows="3" maxlength="500" placeholder="Например: сегодня в 23:00 технические работы" style="resize:vertical;width:100%">${esc(an?an.text:'')}</textarea>
<div class="adbtns"><button class="btn primary" id="cfAS">${an?'Обновить':'Показать всем'}</button>${an?'<button class="btn ghost" id="cfAD">Убрать</button>':''}</div><div class="fhint">Пользователь может скрыть объявление крестиком. Новое объявление покажется снова.</div></div>
<div class="adsec"><h4>Telegram</h4><div class="setgrp">${srow('cfBot','send','#2aabee','@'+esc(S.bot||'бот'),'Открыть бота уведомлений','')}</div></div>`;
  V.__after=()=>{
    $('#cfReg').onclick=async()=>{ const v=!$('#cfReg .tog').classList.contains('on'); try{ await rpc('lm_admin_config_set',{p_key:'registration_open',p_value:v}); $('#cfReg .tog').classList.toggle('on',v); toast(v?'Регистрация открыта':'Регистрация закрыта'); }catch(e){ toast(e.message); } };
    $('#cfAS').onclick=async()=>{ const t=$('#cfA').value.trim(); if(!t) return toast('Введите текст'); try{ await rpc('lm_admin_config_set',{p_key:'announce',p_value:{text:t,id:Date.now()}}); toast('Объявление показано всем'); loadCfg(); admRender(); }catch(e){ toast(e.message); } };
    const d=$('#cfAD'); if(d) d.onclick=async()=>{ try{ await rpc('lm_admin_config_set',{p_key:'announce',p_value:{}}); toast('Объявление убрано'); loadCfg(); admRender(); }catch(e){ toast(e.message); } };
    $('#cfBot').onclick=()=>S.bot&&window.open('https://t.me/'+S.bot,'_blank'); }; }

/* --- журнал и диагностика --- */
async function admLog(V){ const L=await rpc('lm_admin_log_list',{lim:200});
  V.innerHTML=`<div class="adsec"><h4>Действия администраторов</h4>${L.map(l=>`<div class="adlog"><div class="h"><b>${ACT_RU[l.action]||esc(l.action)}</b><span>${admAgo(l.created_at)}</span></div><div class="abx">${esc(l.admin_name||'')} \u2192 ${esc(l.target||'')}${l.details&&Object.keys(l.details).length?` <code>${esc(JSON.stringify(l.details).slice(0,300))}</code>`:''}</div></div>`).join('')||adEmpty('Журнал пока пуст')}</div>`; }
async function admDbg(V){ const L=await rpc('lm_admin_debug_list',{lim:40});
  V.innerHTML=`<div class="adsec"><h4>Технический журнал</h4><div class="fhint" style="margin:-4px 0 10px">Записи о выборе фото профиля \u2014 помогают найти ошибки на конкретных телефонах.</div>${L.map(d=>`<div class="adlog"><div class="h"><b>${esc(d.kind)} \u00b7 @${esc(d.username||'')}</b><span>${admAgo(d.created_at)}</span></div><pre>${esc(JSON.stringify(d.data,null,1))}</pre></div>`).join('')||adEmpty('Пусто')}</div>`; }

/* --- объявление в списке чатов и настройки приложения --- */
async function loadCfg(){ try{ const {data}=await sb.rpc('lm_get_config'); S.cfg=data||{}; }catch{ S.cfg={}; } if(S.tab==='chats') renderList(); }
function announceCard(){ const a=S.cfg&&S.cfg.announce; if(S.q||!a||!a.text) return ''; try{ if(localStorage.getItem('lm_ann_hide')===String(a.id)) return ''; }catch{}
  return `<div class="ncard ann"><span class="nci an">${ic('mega')}</span><div class="tx"><b>Объявление</b><span>${esc(a.text)}</span></div><button class="ncx annx" type="button">${ic('x')}</button></div>`; }
document.addEventListener('click',e=>{ const x=e.target.closest('.annx'); if(!x) return; e.stopPropagation(); try{ localStorage.setItem('lm_ann_hide',String(S.cfg?.announce?.id)); }catch{} x.closest('.ncard').classList.add('bye'); setTimeout(renderList,350); },true);
/* ---- блокировки, жалобы, свои имена, очистка истории, удаление аккаунта ---- */
function reapplyAlias(){ for(const [k,v] of [...S.profiles]) S.profiles.set(k,v); }
async function loadBlocks(){ try{ const {data}=await sb.rpc('lm_my_blocks'); if(data) S.blocks={mine:new Set(data.mine||[]),me:new Set(data.me||[])}; }catch{} if(S.cur){ updateComposer(); } }
function banBox(p){ return `<div class="banbox">${ic('ban')}<div><b>Аккаунт заблокирован</b><span>${p.ban_reason?'Причина: '+esc(p.ban_reason):'Аккаунт заблокирован администрацией Lumo'}</span></div></div>`; }
function peerState(c){ if(!c||c.type!=='private'||c.peer_id===S.me.id) return null; const p=S.profiles.get(c.peer_id)||{};
  if(p.banned) return {ban:1,t:'Аккаунт заблокирован администрацией Lumo'+(p.ban_reason?'. Причина: '+p.ban_reason:'')};
  if(S.blocks.mine.has(c.peer_id)&&isBotUser(c.peer_id)) return {t:'Бот остановлен',btn:'Перезапустить бота',fn:()=>botStop(c.peer_id,false,c.chat_id)};
  if(S.blocks.mine.has(c.peer_id)) return {t:'Вы заблокировали этого пользователя',btn:'Разблокировать',fn:()=>setBlock(c.peer_id,false)};
  if(S.blocks.me.has(c.peer_id)) return {t:'Пользователь ограничил отправку ему сообщений'};
  return null; }
const BUBS=[null,['#ff3d6e','#ff8a5b'],['#00c6ff','#0072ff'],['#43e97b','#12b886'],['#f7971e','#ffb020'],['#fa709a','#b66cff'],['#667eea','#764ba2'],['#475569','#1e293b']];
const bubMap=()=>{ try{ return JSON.parse(localStorage.getItem('lm_bub')||'{}'); }catch{ return {}; } };
function applyBub(cid){ const el=document.getElementById('chat'); if(!el) return; const i=bubMap()[cid]; const b=(S.me&&S.me.premium&&i)?BUBS[i]:null; if(b) el.style.setProperty('--out',`linear-gradient(135deg,${b[0]},${b[1]})`); else el.style.removeProperty('--out'); }
function bubDlg(c){ if(!premOk()) return; const cur0=bubMap()[c.chat_id]||0;
  const cl=modal('Цвет ваших сообщений',`<p style="margin:4px 0 10px;color:var(--muted);font-size:14px">Только для этого чата, на этом устройстве.</p><div class="swatches">${BUBS.map((b,i)=>`<div class="sw ${i===cur0?'on':''}" data-bub="${i}" style="background:${b?`linear-gradient(135deg,${b[0]},${b[1]})`:'var(--panel2)'}"></div>`).join('')}</div>`,[['Закрыть','ghost']]);
  document.querySelectorAll('[data-bub]').forEach(el=>el.onclick=()=>{ const m=bubMap(); if(+el.dataset.bub) m[c.chat_id]=+el.dataset.bub; else delete m[c.chat_id]; try{ localStorage.setItem('lm_bub',JSON.stringify(m)); }catch{} applyBub(c.chat_id); cl(); }); }
function chatActs(c){ const dm=c.type==='private'&&c.peer_id!==S.me.id, a=[];
  a.push(['palette','Цвет сообщений \u2605',()=>bubDlg(c)]);
  if(dm&&!c.peer_bot) a.push(['lock','Код безопасности',()=>E2E.safetyDlg(c.peer_id)]);
  if(dm) a.push(['edit','Переименовать у себя',()=>renameDlg(c.peer_id)]);
  if(c.type!=='channel'&&!(c.type==='private'&&(c.peer_id===S.me.id||c.peer_bot))) a.push(['clock','Исчезающие сообщения',()=>ttlDlg(c)]);
  if(c.type==='channel'&&(c.role==='owner'||c.role==='admin')) a.push(['bar','Статистика канала',()=>statsDlg(c)]);
  a.push(['trash','Очистить историю',()=>clearChat(c)]);
  if(dm&&isBotUser(c.peer_id)) a.push([S.blocks.mine.has(c.peer_id)?'play':'stopsq',S.blocks.mine.has(c.peer_id)?'Перезапустить бота':'Остановить бота',()=>botStop(c.peer_id,!S.blocks.mine.has(c.peer_id),c.chat_id),'red']);
  else if(dm) a.push(['ban',S.blocks.mine.has(c.peer_id)?'Разблокировать':'Заблокировать',()=>setBlock(c.peer_id,!S.blocks.mine.has(c.peer_id)),'red']);
  if(!(c.type==='private'&&c.peer_id===S.me.id)) a.push(['flag','Пожаловаться',()=>reportDlg({user:dm?c.peer_id:null,chat:c.chat_id}),'red']);
  return a; }
function afterPeerChange(){ updateComposer(); renderHead(); renderList(); if(!$('#info').classList.contains('hidden')) renderInfo(); if($('#sBlocked')) renderSettings(); }
async function doBlock(uid,on){ const {error}=await sb.rpc('lm_block',{p_user:uid,p_on:on}); if(error){ toast(error.message); return false; }
  if(on) S.blocks.mine.add(uid); else S.blocks.mine.delete(uid); return true; }
function setBlock(uid,on){ const n=S.profiles.get(uid)?.name||'пользователя';
  const go=async()=>{ if(await doBlock(uid,on)){ toast(on?'Пользователь заблокирован':'Пользователь разблокирован'); afterPeerChange(); } };
  if(on) confirmBox(`Заблокировать ${n}? Он не сможет писать и звонить вам, пока вы его не разблокируете.`,'Заблокировать',go); else go(); }
function clearChat(c){ confirmBox(`Очистить историю \u00ab${chatName(c)}\u00bb? Сообщения исчезнут только у вас, у остальных участников они останутся.`,'Очистить',async()=>{
  const {data,error}=await sb.rpc('lm_clear_chat',{p_chat:c.chat_id}); if(error) return toast(error.message);
  S.cleared.set(c.chat_id,data); S.msgs.set(c.chat_id,[]); S.more.set(c.chat_id,false); c.unread=0;
  if(S.cur===c.chat_id){ renderMsgs(true); } await loadChats(); toast('История очищена'); }); }
const REASONS=[['spam','Спам'],['abuse','Оскорбления или травля'],['fraud','Мошенничество'],['violence','Угрозы или насилие'],['adult','Неприемлемый контент'],['other','Другое']];
function reportDlg(o){ const nm=o.user?(S.profiles.get(o.user)?.name||'пользователя'):'';
  modal(o.message?'Пожаловаться на сообщение':o.user?'Пожаловаться на '+esc(nm):'Пожаловаться на чат',`<p style="margin:0 0 10px;color:var(--muted);font-size:14px">Жалобу увидит только администрация Lumo. Укажите причину:</p>
<div class="rpl">${REASONS.map((r,i)=>`<label><input type="radio" name="rpR" value="${r[0]}" ${i?'':'checked'}><span>${r[1]}</span></label>`).join('')}</div>
<div class="field" style="margin-top:8px"><label>Комментарий (необязательно)</label><textarea class="inp" id="rpC" rows="3" maxlength="500" style="resize:none"></textarea></div>
${o.user&&!S.blocks.mine.has(o.user)?'<label class="adchk"><input type="checkbox" id="rpB"><span>Также заблокировать пользователя</span></label>':''}`,
  [['Отмена','ghost'],['Отправить','danger',async cl=>{ const reason=document.querySelector('[name=rpR]:checked')?.value||'other', comment=$('#rpC').value, blk=$('#rpB')?.checked;
    const rcid=o.chat||S.cur; const em=o.message?((S.msgs.get(rcid)||[]).find(x=>x.id===o.message)||replyCache.get(o.message)):null;
    const {error}=(em&&em._enc)?await sb.rpc('lm_report_e2e',{p_user:o.user||null,p_chat:rcid,p_message:o.message,p_reason:reason,p_comment:comment,p_plain:em.body||''}):await sb.rpc('lm_report',{p_user:o.user||null,p_chat:o.chat||null,p_message:o.message||null,p_reason:reason,p_comment:comment}); if(error) return toast(error.message);
    cl(); if(blk&&await doBlock(o.user,true)) afterPeerChange(); toast('Жалоба отправлена. Спасибо!'); }]]); }
function renameDlg(uid){ if(window.tgContactEdit) return window.tgContactEdit(uid); const p=S.profiles.get(uid)||{}; if(p.is_bot){ toast('Имя бота изменить нельзя'); return; } const real=p.__real||p.name||''; const curA=S.alias.get(uid)||'';
  modal('Имя у вас',`<p style="margin:0 0 10px;color:var(--muted);font-size:14px">Это имя будете видеть только вы \u2014 в списке чатов, контактах и сообщениях. Настоящее имя: <b style="color:var(--text)">${esc(real)}</b></p>
<div class="field"><input class="inp" id="alN" maxlength="64" value="${esc(curA)}" placeholder="${esc(real)}"></div>`,
  [...(curA?[['Вернуть настоящее','ghost',async cl=>{ if(await saveAlias(uid,'')) cl(); }]]:[]),['Отмена','ghost'],['Сохранить','primary',async cl=>{ if(await saveAlias(uid,$('#alN').value)) cl(); }]]);
  setTimeout(()=>$('#alN')?.focus(),50); }
async function saveAlias(uid,v){ const a=String(v||'').trim().slice(0,64); const {error}=await sb.rpc('lm_set_alias',{p_user:uid,p_alias:a}); if(error){ toast(error.message); return false; }
  if(a) S.alias.set(uid,a); else S.alias.delete(uid); if(!isContact(uid)) S.contacts.unshift(uid);
  reapplyAlias(); renderContacts(); afterPeerChange(); toast(a?'Имя изменено \u2014 его видите только вы':'Показывается настоящее имя'); return true; }
async function blockedDlg(){ const ids=[...S.blocks.mine]; await ensureProfiles(ids);
  const close=modal('Заблокированные',ids.length?`<div class="bllist">${ids.map(id=>{ const p=S.profiles.get(id)||{}; return `<div class="row">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'s')}<div class="mid"><b>${esc(p.name||'')}</b><div style="color:var(--muted);font-size:13px">@${esc(p.username||'')}</div></div><button class="btn ghost" data-ub="${id}">Разблокировать</button></div>`; }).join('')}</div>`:'<p style="color:var(--muted);text-align:center;margin:10px 0 16px">Вы никого не блокировали</p>');
  const ov=[...document.querySelectorAll('.ov')].pop(); ov&&ov.querySelectorAll('[data-ub]').forEach(b=>b.onclick=async()=>{ if(await doBlock(b.dataset.ub,false)){ b.closest('.row').remove(); toast('Пользователь разблокирован'); afterPeerChange(); } }); }
function deleteAccountDlg(){ const u=S.me.username;
  modal('Удаление аккаунта',`<p style="margin:0 0 10px">Будут удалены навсегда: ваш профиль, личные переписки, загруженные фото, видео и голосовые. Сообщения в группах останутся без автора. <b>Восстановить аккаунт будет нельзя.</b></p>
<div class="field"><label>Чтобы подтвердить, введите свой юзернейм: <b>${esc(u)}</b></label><input class="inp" id="daU" autocapitalize="off" spellcheck="false" autocomplete="off" placeholder="${esc(u)}"></div>`,
  [['Отмена','ghost'],['Удалить навсегда','danger',async cl=>{ const v=$('#daU').value.trim().replace(/^@/,'').toLowerCase(); if(v!==u.toLowerCase()) return toast('Юзернейм введён неверно');
    const b=[...document.querySelectorAll('.ov .mf .btn')].pop(); b&&b.classList.add('loading');
    try{ const {data:{session}}=await sb.auth.getSession();
      const r=await fetch(FN+'/account',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+(session?.access_token||'')},body:JSON.stringify({action:'delete'})});
      const j=await r.json().catch(()=>({error:'Сервер не ответил'})); if(!r.ok||j.error) throw new Error(j.error||('Ошибка '+r.status));
      cl(); toast('Аккаунт удалён'); try{ await sb.auth.signOut({scope:'local'}); }catch{} setTimeout(()=>location.reload(),900); }
    catch(e){ b&&b.classList.remove('loading'); toast(e.message); } }]]); }
/* ================= ИСТОРИИ ================= */
const ST={list:[],by:new Map(),loaded:false};
async function loadStories(){ try{ const {data,error}=await sb.rpc('lm_stories_feed'); if(error) return; ST.list=data||[]; ST.loaded=true;
  const by=new Map(); for(const s of ST.list){ let g=by.get(s.user_id); if(!g){ g={uid:s.user_id,name:s.name,username:s.username,avatar_url:s.avatar_url,color:s.color,items:[]}; by.set(s.user_id,g); } g.items.push(s); }
  by.forEach(g=>{ g.items.sort((a,b)=>new Date(a.created_at)-new Date(b.created_at)); g.unseen=g.uid!==S.me.id&&g.items.some(x=>!x.seen); g.last=g.items[g.items.length-1].created_at; });
  ST.by=by; }catch{} if(S.tab==='chats'&&!document.querySelector('#stv')) renderList(); }
function storyOrder(){ const a=[...ST.by.values()].filter(g=>g.uid!==S.me.id); a.sort((x,y)=>(y.unseen-x.unseen)||(new Date(y.last)-new Date(x.last))); const mine=ST.by.get(S.me.id); return mine?[mine,...a]:a; }
function storiesBar(){ if(S.q||S.folder!=='all'||!S.me) return ''; const mine=ST.by.get(S.me.id), others=storyOrder().filter(g=>g.uid!==S.me.id);
  const nm=g=>esc(((S.alias&&S.alias.get(g.uid))||g.name||'').split(' ')[0]);
  return `<div class="stbar"><button class="stit" data-st="${mine?S.me.id:'add'}"><span class="stav ${mine?'mine':'none'}">${avatar({name:S.me.name,avatar:S.me.avatar_url,color:S.me.color},'s')}<i class="stplus" data-st-add="1">${ic('plus')}</i></span><span class="stnm">Моя история</span></button>${others.map(g=>`<button class="stit" data-st="${g.uid}"><span class="stav ${g.unseen?'':'seen'}">${avatar({name:g.name,avatar:g.avatar_url,color:g.color},'s')}</span><span class="stnm">${nm(g)}</span></button>`).join('')}</div>`; }
document.addEventListener('click',e=>{ const b=e.target.closest('.stbar .stit'); if(!b) return; e.stopPropagation();
  if(e.target.closest('[data-st-add]')||b.dataset.st==='add') return addStory(); openStories(b.dataset.st); },true);
function addStory(){ const inp=document.createElement('input'); inp.type='file'; inp.accept='image/*,video/*'; inp.style.cssText='position:fixed;left:-9999px;opacity:0';
  document.body.appendChild(inp); inp.onchange=async()=>{ const f=inp.files&&inp.files[0]; inp.remove(); if(!f) return;
    const isV=/^video\//.test(f.type); if(!isV&&!/^image\//.test(f.type)) return toast('Можно выбрать фото или видео');
    if(isV&&f.size>25*1024*1024) return toast('Видео для истории — до 25 МБ. Загрузите его с телефона: приложение сожмёт видео само');
    let meta={}; if(isV){ meta=await new Promise(r=>{ const v=document.createElement('video'); v.preload='metadata'; v.onloadedmetadata=()=>{ r({dur:v.duration,w:v.videoWidth,h:v.videoHeight}); URL.revokeObjectURL(v.src); }; v.onerror=()=>r({}); v.src=URL.createObjectURL(f); });
      if(meta.dur>61) return toast('Видео для истории \u2014 не длиннее 60 секунд'); }
    const blob=isV?f:await compressImage(f); const prev=URL.createObjectURL(blob);
    const close=modal('Новая история',`<div class="stnew">${isV?`<video src="${prev}" playsinline muted autoplay loop></video>`:`<img src="${prev}">`}</div><div class="field" style="margin-top:10px"><input class="inp" id="stCap" maxlength="300" placeholder="Подпись (необязательно)"></div><div class="field" style="margin-top:8px"><select class="inp" id="stHrs"><option value="24">Живёт 24 часа</option><option value="48">Живёт 48 часов \u2605</option><option value="72">Живёт 3 дня \u2605</option><option value="168">Живёт 7 дней \u2605</option></select></div><div class="fhint">История видна вашим контактам и тем, с кем у вас есть переписка, 24 часа.</div>`,
      [['Отмена','ghost',c=>{ URL.revokeObjectURL(prev); c(); }],['Опубликовать','primary',async c=>{ const b=[...document.querySelectorAll('.ov .mf .btn')].pop(); b&&b.classList.add('loading');
        try{ const hrs=+($('#stHrs')?.value||24); if(hrs>24&&!premOk()){ b&&b.classList.remove('loading'); return; } const url=await upload(blob,isV?(extOf(f,'mp4')):'jpg'); const {error}=await sb.rpc('lm_story_add',{p_kind:isV?'video':'image',p_url:url,p_caption:$('#stCap').value,p_meta:meta,p_hours:hrs}); if(error) throw error;
          c(); URL.revokeObjectURL(prev); toast('История опубликована'); loadStories(); }
        catch(err){ b&&b.classList.remove('loading'); toast('Ошибка: '+(err.message||err)); } }]]); };
  inp.click(); }
function openStories(uid){ const order=storyOrder(); let gi=order.findIndex(g=>g.uid===uid); if(gi<0) return;
  $('#stv')?.remove(); stopPlaying();
  const d=document.createElement('div'); d.id='stv'; document.body.appendChild(d);
  let ii=0, t0=0, dur=5000, paused=false, raf=0, pausedAt=0, vid=null, closed=false;
  const G=()=>order[gi], I=()=>G().items[ii];
  const startIdx=g=>{ const k=g.items.findIndex(x=>!x.seen); return g.uid===S.me.id||k<0?0:k; };
  ii=startIdx(G());
  const close=()=>{ if(closed) return; closed=true; cancelAnimationFrame(raf); try{ vid&&vid.pause(); }catch{} d.classList.add('out'); setTimeout(()=>d.remove(),220); removeEventListener('keydown',key,true); renderList(); };
  const next=()=>{ if(ii<G().items.length-1){ ii++; show(); } else if(gi<order.length-1){ gi++; ii=startIdx(G()); show(); } else close(); };
  const prev=()=>{ if(ii>0){ ii--; show(); } else if(gi>0){ gi--; ii=0; show(); } else { t0=performance.now(); if(vid){ vid.currentTime=0; } } };
  const tick=()=>{ if(closed) return; const bar=d.querySelector('.stp i.cur b'); let p;
    if(vid&&vid.duration){ p=vid.currentTime/vid.duration; } else { p=paused?(pausedAt-t0)/dur:(performance.now()-t0)/dur; }
    if(bar) bar.style.width=Math.min(100,p*100)+'%';
    if(!paused&&p>=1) return next(); raf=requestAnimationFrame(tick); };
  const setPause=v=>{ if(v===paused) return; paused=v; if(v){ pausedAt=performance.now(); vid&&vid.pause(); } else { t0+=performance.now()-pausedAt; vid&&vid.play().catch(()=>{}); } d.classList.toggle('hold',v); };
  function show(){ cancelAnimationFrame(raf); paused=false; d.classList.remove('hold'); const g=G(), s=I(), mine=g.uid===S.me.id;
    const nm=(S.alias&&S.alias.get(g.uid))||g.name;
    d.innerHTML=`<div class="stin"><div class="stp">${g.items.map((x,k)=>`<i class="${k<ii?'done':k===ii?'cur':''}"><b></b></i>`).join('')}</div>
<div class="sthead">${avatar({name:g.name,avatar:g.avatar_url,color:g.color},'s')}<div class="sthn"><b>${esc(mine?'Моя история':nm)}</b><span>${storyAgo(s.created_at)}</span></div><span class="sp"></span>${mine?`<button class="ib" data-sa="del" title="Удалить">${ic('trash')}</button>`:''}<button class="ib" data-sa="x">${ic('x')}</button></div>
<div class="stmedia">${s.kind==='video'?`<video src="${esc(s.media_url)}" playsinline webkit-playsinline autoplay preload="auto"></video>`:`<img src="${esc(s.media_url)}" alt="">`}<div class="stspin"></div></div>
${s.caption?`<div class="stcap">${esc(s.caption)}</div>`:''}
<div class="stfoot">${mine?`<button class="stviews" data-sa="views">${ic('eye')}<span>${s.views||0} ${plural(s.views||0,'просмотр','просмотра','просмотров')}</span></button><span class="sp"></span><button class="stadd" data-sa="add">${ic('plus')}Ещё история</button>`
  :`<input class="streply" id="stRe" placeholder="Ответить ${esc(nm.split(' ')[0])}\u2026" maxlength="1000" enterkeyhint="send"><button class="ib sthrt${s.liked?' on':''}" data-sa="like">${ic('heart')}</button><button class="ib" data-sa="send">${ic('send')}</button>`}</div>
<div class="stnav l"></div><div class="stnav r"></div></div>`;
    vid=d.querySelector('.stmedia video'); const img=d.querySelector('.stmedia img');
    dur=5000; t0=performance.now();
    if(vid){ d.classList.add('wait'); vid.addEventListener('playing',()=>d.classList.remove('wait')); vid.addEventListener('waiting',()=>d.classList.add('wait'));
      vid.addEventListener('ended',()=>{ if(!paused) next(); }); vid.play().catch(()=>{ vid.muted=true; vid.play().catch(()=>{}); }); }
    else { d.classList.add('wait'); paused=true; pausedAt=t0; const go=()=>{ d.classList.remove('wait'); if(paused){ paused=false; t0=performance.now(); } }; if(img.complete&&img.naturalWidth) go(); else { img.onload=go; img.onerror=go; } }
    if(!mine&&!s.seen){ s.seen=true; sb.rpc('lm_story_view',{p_id:s.id}).then(()=>{},()=>{}); g.unseen=g.items.some(x=>!x.seen); }
    const re=d.querySelector('#stRe'); if(re){ re.onfocus=()=>setPause(true); re.onblur=()=>setPause(false); re.onkeydown=e=>{ if(e.key==='Enter'){ e.preventDefault(); sendReply(); } }; }
    raf=requestAnimationFrame(tick); }
  async function sendReply(){ const re=d.querySelector('#stRe'); const t=(re?.value||'').trim(); if(!t) return; const g=G(), s=I(); re.value=''; re.blur();
    try{ const {data:cid,error}=await sb.rpc('lm_open_dm',{p_other:g.uid}); if(error) throw error;
      const {error:e2}=await sendRow(cid,{kind:'text',body:'\u21a9\ufe0f Ответ на историю'+(s.caption?' \u00ab'+s.caption.slice(0,60)+'\u00bb':'')+':\n'+t,meta:{story:{id:s.id,kind:s.kind,url:s.media_url}}}); if(e2) throw e2;
      toast('Ответ отправлен'); }catch(err){ toast(err.message||'Не удалось отправить'); } }
  async function viewers(){ setPause(true); const {data,error}=await sb.rpc('lm_story_viewers',{p_id:I().id}); if(error){ setPause(false); return toast(error.message); }
    const L=data||[]; const cl=modal('Просмотры',L.length?`<div class="bllist">${L.map(v=>`<div class="row">${avatar({name:v.name,avatar:v.avatar_url,color:v.color},'s')}<div class="mid"><b>${esc(v.name)}</b><div style="color:var(--muted);font-size:13px">${storyAgo(v.viewed_at)}</div></div>${v.reaction?`<span style="font-size:20px">${esc(v.reaction)}</span>`:''}</div>`).join('')}</div>`:'<p style="color:var(--muted);text-align:center;margin:10px 0 16px">Пока никто не посмотрел</p>');
    const ov=[...document.querySelectorAll('.ov')].pop(); ov&&ov.style.setProperty('z-index','100002'); const mo=new MutationObserver(()=>{ if(!document.body.contains(ov)){ mo.disconnect(); setPause(false); } }); mo.observe(document.body,{childList:true}); }
  d.addEventListener('click',e=>{ const a=e.target.closest('[data-sa]')?.dataset.sa; if(!a) return; e.stopPropagation();
    if(a==='x') close(); else if(a==='send') sendReply(); else if(a==='views') viewers(); else if(a==='add'){ close(); addStory(); }
    else if(a==='like'){ const s=I(); const bt=e.target.closest('button'); s.liked=!s.liked; bt.classList.toggle('on',s.liked); sb.rpc('lm_story_react',{p_id:s.id,p_emoji:'\u2764\ufe0f'}).then(({data,error})=>{ if(error){ s.liked=!s.liked; bt.classList.toggle('on',s.liked); return; } if(typeof data==='boolean'){ s.liked=data; bt.classList.toggle('on',data); } },()=>{}); }
    else if(a==='del'){ setPause(true); const s=I(); confirmBox('Удалить эту историю?','Удалить',async()=>{ const {error}=await sb.rpc('lm_story_delete',{p_id:s.id}); if(error) return toast(error.message);
      G().items.splice(ii,1); toast('История удалена'); if(!G().items.length){ order.splice(gi,1); if(!order.length) { close(); loadStories(); return; } if(gi>=order.length) gi=order.length-1; ii=0; } else if(ii>=G().items.length) ii=G().items.length-1; show(); loadStories(); });
      setTimeout(()=>{ const ov=[...document.querySelectorAll('.ov')].pop(); ov&&ov.style.setProperty('z-index','100002'); },0); } });
  // касание слева/справа \u2014 назад/вперёд, удержание \u2014 пауза, смахивание вниз \u2014 закрыть, вбок \u2014 к другому человеку
  let px=0, py=0, pt=0, holdT=0, moved=false;
  d.addEventListener('pointerdown',e=>{ if(e.target.closest('.stfoot,.sthead,[data-sa]')) return; px=e.clientX; py=e.clientY; pt=Date.now(); moved=false; holdT=setTimeout(()=>setPause(true),180); });
  d.addEventListener('pointermove',e=>{ if(!pt) return; const dy=e.clientY-py; if(Math.abs(dy)>12||Math.abs(e.clientX-px)>12) moved=true; if(dy>0){ const i=d.querySelector('.stin'); if(i){ i.style.transform=`translateY(${dy}px) scale(${Math.max(.85,1-dy/1500)})`; } } });
  d.addEventListener('pointerup',e=>{ if(!pt) return; clearTimeout(holdT); const dx=e.clientX-px, dy=e.clientY-py, dt=Date.now()-pt; pt=0; const i=d.querySelector('.stin'); if(i) i.style.transform='';
    if(dy>120) return close();
    if(Math.abs(dx)>70&&Math.abs(dx)>Math.abs(dy)){ setPause(false); if(dx<0){ if(gi<order.length-1){ gi++; ii=startIdx(G()); show(); } else close(); } else if(gi>0){ gi--; ii=0; show(); } return; }
    if(paused&&dt>180){ setPause(false); return; }
    if(!moved){ setPause(false); if(e.clientX<innerWidth/3) prev(); else next(); } });
  const key=e=>{ if(closed) return; if(document.activeElement?.id==='stRe') return; if(e.key==='Escape'){ e.stopPropagation(); close(); } else if(e.key==='ArrowRight') next(); else if(e.key==='ArrowLeft') prev(); };
  addEventListener('keydown',key,true);
  show(); }
function storyAgo(t){ const m=Math.round((Date.now()-new Date(t))/6e4); if(m<1) return 'только что'; if(m<60) return m+' мин назад'; const h=Math.round(m/60); return h+' ч назад'; }
/* new group / channel */
function newChatFlow(type,onCreated){
const sel=new Map();
const close=modal(type==='channel'?'Новый канал':'Новая группа',`
<div class="avedit" style="flex-direction:row;justify-content:flex-start;gap:14px;margin:0 0 12px"><div class="av c1" style="width:64px;height:64px">${ic(type==='channel'?'mega':'users')}</div>
<div style="flex:1"><input class="inp" id="ncTitle" placeholder="${type==='channel'?'Название канала':'Название группы'}" maxlength="64"></div></div>
<div class="field"><input class="inp" id="ncDesc" placeholder="Описание (необязательно)" maxlength="200"></div>
<div class="field"><label>Публичная ссылка (необязательно) \u2014 тогда ${type==='channel'?'канал':'группу'} можно найти в поиске</label><input class="inp" id="ncUser" placeholder="юзернейм, например my_${type==='channel'?'channel':'group'}" autocapitalize="off"></div>
<div class="field"><label>${type==='channel'?'Добавить подписчиков':'Участники'}</label><div class="chips" id="ncChips"></div><label class="search"><span>${ic('search')}</span><input id="ncQ" placeholder="Найти людей"></label></div>
<div id="ncList"></div>`,
[['Отмена','ghost'],['Создать','primary',async c=>{ const t=$('#ncTitle').value.trim(); if(!t) return toast('Укажите название');
const u=$('#ncUser').value.trim().toLowerCase().replace(/^@/,'')||null; if(u&&!/^[a-z0-9_]{3,32}$/.test(u)) return toast('Ссылка: 3\u201332 символа, латиница, цифры и _');
const {data,error}=await sb.rpc('lm_create_chat',{p_type:type,p_title:t,p_members:[...sel.keys()],p_description:$('#ncDesc').value.trim(),p_username:u});
if(error) return toast(error.message); c(); await loadChats(); if(onCreated) onCreated(data); else openChat(data); }]]);
const people=()=>{ const ids=new Set(); return S.chats.filter(c=>c.type==='private'&&c.peer_id&&c.peer_id!==S.me.id&&!ids.has(c.peer_id)&&ids.add(c.peer_id)).map(c=>({id:c.peer_id,name:c.peer_name,username:c.peer_username,avatar_url:c.peer_avatar,color:c.peer_color})); };
let shown=people();
const draw=()=>{ $('#ncChips').innerHTML=[...sel.values()].map(p=>`<span class="chip" data-rm="${p.id}">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'xs')}${esc(p.name)}</span>`).join('');
$('#ncList').innerHTML=shown.length?shown.map(p=>`<div class="row" data-pick="${p.id}">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'s',S.online.has(p.id))}<div class="mid"><div class="t1"><span class="nm">${esc(p.name)}</span></div><div class="t2"><span class="pv">@${esc(p.username||'')}</span></div></div><span class="sel ${sel.has(p.id)?'on':''}">${sel.has(p.id)?ic('check'):''}</span></div>`).join(''):'<div style="color:var(--muted);text-align:center;padding:14px">Найдите людей по имени или @юзернейму</div>'; };
draw();
$('#ncList').onclick=e=>{ const r=e.target.closest('[data-pick]'); if(!r) return; const p=shown.find(x=>x.id===r.dataset.pick); sel.has(p.id)?sel.delete(p.id):sel.set(p.id,p); draw(); };
$('#ncChips').onclick=e=>{ const r=e.target.closest('[data-rm]'); if(r){ sel.delete(r.dataset.rm); draw(); } };
let t; $('#ncQ').oninput=e=>{ clearTimeout(t); const q=e.target.value.trim().replace(/^@/,''); t=setTimeout(async()=>{ if(!q){ shown=people(); return draw(); } const {data}=await sb.rpc('lm_search',{q}); shown=(data||[]).filter(r=>r.kind==='user'&&r.id!==S.me.id); draw(); },250); };
}
/* ================= INFO PANEL ================= */
function toggleInfo(force){ const el=$('#info'); const show=force??el.classList.contains('hidden'); el.classList.toggle('hidden',!show); if(show) renderInfo(); }
function chanCard(p){ if(!p?.channel_id) return ''; return `<div class="ikv" style="cursor:pointer" data-chan="${p.channel_id}"><div class="row" style="padding:0">${avatar({name:p.channel_title,avatar:p.channel_avatar,color:p.channel_color},'s')}<div class="mid"><div class="t1"><span class="nm">${esc(p.channel_title||'Канал')}</span></div><div class="t2"><span class="pv">${p.channel_members||0} ${plural(p.channel_members||0,'подписчик','подписчика','подписчиков')}${p.channel_username?' \u00b7 @'+esc(p.channel_username):''}</span></div></div></div><div class="k">канал</div></div>`; }
document.addEventListener('click',async e=>{ const ch=e.target.closest('[data-chan]'); if(!ch) return; e.stopPropagation(); const id=ch.dataset.chan; document.querySelectorAll('.ov').forEach(o=>o.remove());
  if(!S.chatMap.has(id)){ const {error}=await sb.rpc('lm_join',{p_chat:id}); if(error) return toast(error.message); await loadChats(); } setTab('chats'); openChat(id); },true);
async function profExtraDlg(){ if(!premOk()) return;
  const {data:ex}=await sb.rpc('lm_profile_extra',{p_id:S.me.id}); const L=(ex&&ex.links)||[];
  const row=i=>`<div style="display:flex;gap:6px;margin:6px 0"><input class="inp" id="pxt${i}" maxlength="30" placeholder="Название" value="${esc(L[i]?.title||'')}" style="flex:1"><input class="inp" id="pxu${i}" maxlength="200" placeholder="https://\u2026" value="${esc(L[i]?.url||'')}" style="flex:2"></div>`;
  const cl=modal('Расширенный профиль',`<p style="margin:4px 0 10px;color:var(--muted);font-size:14px">До 3 ссылок в вашем профиле.</p>${row(0)}${row(1)}${row(2)}`,[['Отмена','ghost'],['Сохранить','primary',async c=>{
    const links=[0,1,2].map(i=>({title:$('#pxt'+i).value.trim(),url:$('#pxu'+i).value.trim()})).filter(x=>x.title&&/^https?:\/\//i.test(x.url));
    const {error}=await sb.rpc('lm_set_profile_extra',{p_cover:ex?.cover||null,p_links:links}); if(error) return toast(error.message); c(); toast('Профиль обновлён'); }]]); }
async function openUser(uid){ if(uid===S.me.id) return openSettings(); const p=S.profiles.get(uid);
if(p&&p.premium&&!p.is_bot) sb.rpc('lm_profile_extra',{p_id:uid}).then(({data})=>{ const L=data&&data.links; if(!Array.isArray(L)||!L.length) return; const ov=[...document.querySelectorAll('.ov')].pop(); const ref=ov&&ov.querySelector('.tgkv'); if(!ref) return; const d=document.createElement('div'); d.className='ikv'; d.innerHTML=`<div class="v">${L.map(x=>`<a href="${esc(x.url)}" target="_blank" rel="noopener" style="color:var(--a1);display:block">${esc(x.title)}</a>`).join('')}</div><div class="k">Ссылки</div>`; ref.after(d); });
const close=modal('Профиль',`<div class="ihead">${avatar({name:p?.name,avatar:p?.avatar_url,color:p?.color},'l',S.online.has(uid))}<h2>${esc(p?.name||'')}${pMark(p)}</h2><div class="st">${esc(p?.banned?'аккаунт заблокирован':lastSeen(p))}</div></div>
${p?.banned?banBox(p):''}${S.alias.get(uid)?`<div class="ikv"><div class="v">${esc(p?.__real||'')}</div><div class="k">Настоящее имя</div></div>`:''}
<div class="uacts" data-lxu="${uid}"><button data-ua="rn">${ic('edit')}Переименовать</button><button data-ua="bl" class="red">${isBotUser(uid)?ic(S.blocks.mine.has(uid)?'play':'stopsq')+(S.blocks.mine.has(uid)?'Перезапустить бота':'Остановить бота'):ic('ban')+(S.blocks.mine.has(uid)?'Разблокировать':'Заблокировать')}</button><button data-ua="rp" class="red">${ic('flag')}Пожаловаться</button></div>
${p?.bio?`<div class="ikv"><div class="v">${esc(p.bio)}</div><div class="k">О себе</div></div>`:''}${p?.birthday?`<div class="ikv"><div class="v">${esc(bdText(p.birthday,1))}</div><div class="k">День рождения</div></div>`:''}${chanCard(p)}<div class="ikv tgkv"><div><div class="k">имя пользователя</div><div class="v" style="color:var(--a1)">@${esc(p?.username||'')}</div></div><button class="ib qrb" data-ua="qr" title="QR-код">${ic('qr')}</button></div>`,
[...(S.staff?[['Админка','ghost',c=>{ c(); openAdmin({t:'user',id:uid}); }]]:[]),[isContact(uid)?'Удалить из контактов':'В контакты','ghost',c=>{ c(); isContact(uid)?removeContact(uid):addContact(uid); }],['Написать','primary',async c=>{ c(); openDM(uid); }]]);
const ov=[...document.querySelectorAll('.ov')].pop(); ov&&ov.querySelectorAll('[data-ua]').forEach(b=>b.onclick=()=>{ const a=b.dataset.ua; if(a==='qr') return showUserQr(p); close();
  if(a==='rn') renameDlg(uid); else if(a==='bl'){ if(isBotUser(uid)) botStop(uid,!S.blocks.mine.has(uid),S.chats.find(x=>x.type==='private'&&x.peer_id===uid)?.chat_id); else setBlock(uid,!S.blocks.mine.has(uid)); } else reportDlg({user:uid}); }); }
async function renderInfo(){
const c=cur(); if(!c) return; const el=$('#info');
const isDM=c.type==='private'; const p=isDM?S.profiles.get(c.peer_id):null; const saved=isDM&&c.peer_id===S.me.id; const admin=['owner','admin'].includes(c.role);
const st=headStatus(c);
const canEd=isDM?!saved:admin; const avUrl=isDM?(p?.avatar_url||c.peer_avatar):c.avatar_url;
let h=`<div class="top tgtop"><button class="ib" id="infX">${ic('back')}</button><span style="flex:1"></span>${canEd?`<button class="lnk2" id="infEd2">Изм.</button>`:''}</div>
<div class="ihead tgh"><div class="ibig ${avUrl?'zoom':''}" id="infAv">${chatAv(c,'l')}</div><h2>${esc(chatName(c))}${isDM&&p?pMark(p):''}</h2><div class="st ${st.live?'live':''}">${esc(st.t)}</div>
<div class="iact tga" ${isDM&&!saved&&!(p&&p.is_bot)?`data-lxu="${c.peer_id}"`:''}>${isDM&&!saved&&!(p&&p.is_bot)?`<button id="iaC">${ic('phone')}<span>звонок</span></button><button id="iaV">${ic('video')}<span>видео</span></button>`:''}${!saved?`<button id="iaM">${ic(c.muted?'belloff':'bell')}<span>${c.muted?'без звука':'звук'}</span></button>`:''}<button id="iaS">${ic('search')}<span>поиск</span></button><button id="iaMore">${ic('more')}<span>ещё</span></button></div></div>`;
h+=(isDM&&!saved&&p&&p.banned?banBox(p):'')+(isDM&&!saved&&S.alias.get(c.peer_id)?`<div class="iblock"><div class="ikv"><div class="v">${esc(p?.__real||'')}</div><div class="k">Настоящее имя (вы переименовали у себя)</div></div></div>`:'');
h+='<div class="iblock">';
if(isDM&&!saved){ h+=`<div class="ikv tgkv"><div><div class="k">имя пользователя</div><div class="v" id="infUser" style="color:var(--a1);cursor:pointer">@${esc(p?.username||'')}</div></div><button class="ib qrb" id="infQr" title="QR-код">${ic('qr')}</button></div>`; if(p?.bio) h+=`<div class="ikv"><div class="k">о себе</div><div class="v">${esc(p.bio)}</div></div>`; if(p?.birthday) h+=`<div class="ikv"><div class="k">день рождения</div><div class="v">${esc(bdText(p.birthday,1))}</div></div>`; h+=chanCard(p); }
if(!isDM){ if(c.description) h+=`<div class="ikv"><div class="v">${esc(c.description)}</div><div class="k">Описание</div></div>`;
if(c.username) h+=`<div class="ikv" style="cursor:pointer" id="infLink"><div class="v" style="color:var(--a2)">@${esc(c.username)}</div><div class="k">Ссылка \u2014 нажмите, чтобы скопировать</div></div>`; }
if(admin) h+=`<div class="ikv" style="cursor:pointer" id="infType"><div class="v">${c.is_public?'Публичный':'Приватный'}${c.username?' · @'+esc(c.username):''}</div><div class="k">Тип ${c.type==='channel'?'канала':'группы'} и ссылка ›</div></div>`;
h+='</div>';
if(!isDM){
const mem=(S.members.get(c.chat_id)||[]).slice().sort((a,b)=>({owner:0,admin:1,member:2}[a.role]-{owner:0,admin:1,member:2}[b.role]));
h+=`<div class="iblock"><div class="sec" style="display:flex;align-items:center">${mem.length} ${c.type==='channel'?plural(mem.length,'подписчик','подписчика','подписчиков'):plural(mem.length,'участник','участника','участников')}<span style="flex:1"></span>${admin?`<button class="ib" id="infAdmins" title="Администраторы">${ic('shield')}</button><button class="ib" id="infAdd" title="Добавить">${ic('userplus')}</button>`:''}</div>`;
h+=mem.map(m=>{ const pp=S.profiles.get(m.user_id)||{}; return `<div class="row" data-mem="${m.user_id}">${avatar({name:pp.name,avatar:pp.avatar_url,color:pp.color},'s',S.online.has(m.user_id))}<div class="mid"><div class="t1"><span class="nm">${esc(pp.name||'')}${m.user_id===S.me.id?' (вы)':''}</span>${m.role!=='member'?`<span class="role">${m.role==='owner'?'владелец':'админ'}</span>`:''}</div><div class="t2"><span class="pv">${esc(lastSeen(pp))}</span></div></div></div>`; }).join('')+'</div>';
}
h+=`<div class="iblock"><div class="sec">Медиа</div><div class="mgrid" id="infMedia"><div style="grid-column:1/-1;aspect-ratio:auto;background:none;color:var(--muted);text-align:center;padding:10px;cursor:default">Загрузка\u2026</div></div></div>`;
{ const A=chatActs(c); if(A.length) h+=`<div class="iblock iacts2">${A.map((a,i)=>`<button class="iab ${a[3]||''}" data-ia="${i}">${ic(a[0])}<span>${a[1]}</span></button>`).join('')}</div>`; el.__acts=A; }
el.innerHTML=h;
if(window.tgDecor&&isDM&&!saved&&p){ window.tgDecor(el.querySelector('.ihead'),p,false); const mbx=el.querySelector('#infMedia'); if(mbx&&window.tgPosts){ const pd=document.createElement('div'); pd.className='iblock'; pd.innerHTML='<div class="sec">Публикации</div><div class="tgpb"></div>'; mbx.closest('.iblock').before(pd); window.tgPosts(pd.querySelector('.tgpb'),c.peer_id); } }
$('#infX').onclick=()=>toggleInfo(false);
el.querySelectorAll('[data-ia]').forEach(b=>b.onclick=()=>el.__acts[+b.dataset.ia][2]());
$('#iaC')&&($('#iaC').onclick=()=>startCall(false)); $('#iaV')&&($('#iaV').onclick=()=>startCall(true)); $('#iaM')&&($('#iaM').onclick=async()=>{ await toggleMute(); renderInfo(); });
$('#iaS').onclick=()=>{ toggleInfo(false); $('#hSearch').click(); };
$('#iaMore').onclick=e=>{ const items=[]; if(isDM&&!saved&&!isBotUser(c.peer_id)) items.push([isContact(c.peer_id)?'userx':'userplus',isContact(c.peer_id)?'Удалить из контактов':'Добавить в контакты',()=>isContact(c.peer_id)?removeContact(c.peer_id):addContact(c.peer_id)]);
  const un=isDM?p?.username:c.username; if(un) items.push(['copy','Скопировать @'+un,()=>{ navigator.clipboard?.writeText('@'+un); toast('Юзернейм скопирован'); }]);
  items.push(['pin',c.pinned?'Открепить чат':'Закрепить чат',togglePinChat]);
  chatActs(c).forEach(a=>items.push(a)); if(!isDM) items.push(['logout',c.type==='channel'?'Отписаться':'Покинуть группу',leaveChat,'red']);
  e.stopPropagation(); dropMenu(e.currentTarget,items); };
$('#infEd2')&&($('#infEd2').onclick=()=>isDM?renameDlg(c.peer_id):editChat());
$('#infAv').onclick=()=>{ if(avUrl) lightbox(avUrl); };
$('#infQr')&&($('#infQr').onclick=()=>showUserQr(p));
$('#infUser')&&($('#infUser').onclick=()=>{ navigator.clipboard?.writeText('@'+(p?.username||'')); toast('Юзернейм скопирован'); }); $('#iaK')&&($('#iaK').onclick=()=>isContact(c.peer_id)?removeContact(c.peer_id):addContact(c.peer_id)); $('#iaL')&&($('#iaL').onclick=leaveChat);
$('#infLink')&&($('#infLink').onclick=()=>{ navigator.clipboard?.writeText(location.origin+location.pathname+'#@'+c.username); toast('Ссылка скопирована'); });
$('#infType')&&($('#infType').onclick=()=>chatTypeDialog(c));
$('#infAdmins')&&($('#infAdmins').onclick=()=>showAdmins(c));
$('#infEd')&&($('#infEd').onclick=editChat); $('#infAdd')&&($('#infAdd').onclick=addMembers);
el.querySelectorAll('[data-mem]').forEach(r=>bindMemberRow(c,admin,r));
const {data}=await sb.from('lm_messages').select('id,kind,media_url').eq('chat_id',c.chat_id).in('kind',['image','video']).eq('deleted',false).order('id',{ascending:false}).limit(60);
const g=$('#infMedia'); if(!g) return;
g.innerHTML=(data||[]).length?data.map(m=>m.kind==='image'?`<div style="background-image:url('${esc(m.media_url)}')" data-v="${esc(m.media_url)}"></div>`:`<div data-v="${esc(m.media_url)}" data-vid="1" style="background:#000">${ic('play')}</div>`).join(''):'<div style="grid-column:1/-1;aspect-ratio:auto;background:none;color:var(--muted);text-align:center;padding:10px;cursor:default">Пока нет фото и видео</div>';
g.onclick=e=>{ const d=e.target.closest('[data-v]'); if(d) lightbox(d.dataset.v,!!d.dataset.vid); };
}
function bindMemberRow(c,admin,r){
r.onclick=e=>{ const uid=r.dataset.mem; if(uid===S.me.id) return openSettings(); const m=(S.members.get(c.chat_id)||[]).find(x=>x.user_id===uid);
const items=[['user','Профиль',()=>openUser(uid)],['send','Написать',()=>openDM(uid)]];
if(c.role==='owner'&&m.role!=='owner') items.push(['shield',m.role==='admin'?'Снять админа':'Сделать админом',async()=>{ const {error}=await sb.rpc('lm_set_role',{p_chat:c.chat_id,p_user:uid,p_role:m.role==='admin'?'member':'admin'}); if(error) return toast(error.message); await loadMembers(c.chat_id); renderInfo(); const al=document.getElementById('admList'); if(al) renderAdminsList(c,al); }]);
if(admin&&m.role==='member') items.push(['ban','Удалить из чата',async()=>{ const {error}=await sb.from('lm_members').delete().eq('chat_id',c.chat_id).eq('user_id',uid); if(error) return toast(error.message); await loadMembers(c.chat_id); renderInfo(); renderHead(); },'red']);
e.stopPropagation(); dropMenu(r,items); };
}
function renderAdminsList(c,box){
const mem=(S.members.get(c.chat_id)||[]).filter(m=>m.role!=='member').slice().sort((a,b)=>({owner:0,admin:1}[a.role]-{owner:0,admin:1}[b.role]));
const admin=['owner','admin'].includes(c.role);
box.innerHTML=mem.length?mem.map(m=>{ const pp=S.profiles.get(m.user_id)||{}; return `<div class="row" data-mem="${m.user_id}">${avatar({name:pp.name,avatar:pp.avatar_url,color:pp.color},'s',S.online.has(m.user_id))}<div class="mid"><div class="t1"><span class="nm">${esc(pp.name||'')}${m.user_id===S.me.id?' (вы)':''}</span><span class="role">${m.role==='owner'?'владелец':'админ'}</span></div></div></div>`; }).join(''):'<div style="color:var(--muted);padding:16px;text-align:center">Нет администраторов</div>';
box.querySelectorAll('[data-mem]').forEach(r=>bindMemberRow(c,admin,r));
}
function showAdmins(c){
modal('Администраторы','<div id="admList"></div>',[]);
renderAdminsList(c,$('#admList'));
}
function chatTypeDialog(c){
let pub=!!c.is_public;
const kind=c.type==='channel'?'канала':'группы';
const body=`<div class="field"><label class="adchk" style="display:flex;align-items:center;gap:8px"><input type="checkbox" id="ctPub" ${pub?'checked':''}><span>Публичный ${kind} (виден в поиске)</span></label></div>
<div class="field" id="ctUwrap" style="${pub?'':'display:none'}"><label>Ссылка</label><div style="display:flex;align-items:center;gap:4px"><span style="color:var(--muted)">lumomess.ru/#@</span><input class="inp" id="ctU" value="${esc(c.username||'')}" maxlength="32" placeholder="username"></div></div>
<div class="field"><label>Ссылка-приглашение</label><div style="display:flex;gap:8px"><input class="inp" id="ctInv" readonly value="${c.invite_code?location.origin+location.pathname+'#+'+c.invite_code:'Нажмите «Создать»'}"><button class="btn ghost" id="ctInvBtn">${c.invite_code?'Обновить':'Создать'}</button></div></div>`;
const close=modal('Тип '+kind, body,
[['Отмена','ghost'],['Сохранить','primary',async cl=>{
const u=$('#ctU')?$('#ctU').value.trim().toLowerCase():'';
try{ await rp('lm_chat_edit',{p_chat:c.chat_id,p_public:pub,p_username:pub?(u||null):null}); Object.assign(c,{is_public:pub,username:pub?(u||null):null}); cl(); toast('Сохранено'); renderInfo(); }catch(e){ toast(e.message); }
}]]);
$('#ctPub').onchange=e=>{ pub=e.target.checked; $('#ctUwrap').style.display=pub?'':'none'; };
$('#ctInvBtn').onclick=async()=>{ try{ const code=await rp('lm_chat_invite',{p_chat:c.chat_id,p_reset:!!c.invite_code}); c.invite_code=code; $('#ctInv').value=location.origin+location.pathname+'#+'+code; $('#ctInvBtn').textContent='Обновить'; toast('Ссылка создана'); }catch(e){ toast(e.message); } };
}
function editChat(){
const c=cur(); let newAv=null;
const close=modal('Редактировать',`<div class="avedit"><div id="ecAv">${chatAv(c,'l')}</div></div><div style="text-align:center;margin:-2px 0 12px"><button type="button" class="pelnk" id="ecAvB" style="background:none;border:0;color:var(--a1);font:inherit;font-size:15px;cursor:pointer;padding:6px 10px">${c.avatar_url?'Изменить фото':'Выбрать фото'}</button></div>
<div class="field"><label>Название</label><input class="inp" id="ecT" value="${esc(c.title)}" maxlength="64"></div>
<div class="field"><label>Описание</label><textarea class="inp" id="ecD" rows="3" maxlength="200" style="resize:none">${esc(c.description||'')}</textarea></div>${c.type==='group'?'<div id="ecGc"></div>':''}`,
[['Отмена','ghost'],['Сохранить','primary',async cl=>{ const upd={title:$('#ecT').value.trim()||c.title,description:$('#ecD').value.trim()}; if(newAv!==null) upd.avatar_url=newAv||null;
const {error}=await sb.from('lm_chats').update(upd).eq('id',c.chat_id); if(error) return toast(error.message); Object.assign(c,upd); cl(); renderHead(); renderList(); renderInfo(); }]]);
if(c.type==='group'&&window.tgGcSet) window.tgGcSet(document.getElementById('ecGc'),c);
const ecPick=()=>pickAvatar(async url=>{ newAv=url; $('#ecAv').innerHTML=avatar({name:c.title,avatar:url,color:c.color},'l'); $('#ecAvB').textContent='Изменить фото'; });
const ecMenu=e=>{ const has=newAv!==null?!!newAv:!!c.avatar_url; if(!has) return ecPick(); e.stopPropagation(); dropMenu(e.currentTarget,[['image','Выбрать новое фото',ecPick],['trash','Удалить фото',()=>{ newAv=''; $('#ecAv').innerHTML=avatar({name:c.title,avatar:null,color:c.color},'l'); $('#ecAvB').textContent='Выбрать фото'; },'red']]); };
$('#ecAv').onclick=ecMenu; $('#ecAvB').onclick=ecMenu;
}
function addMembers(){
const c=cur(); const have=new Set((S.members.get(c.chat_id)||[]).map(m=>m.user_id)); const sel=new Map(); let shown=[];
const base=()=>{ const ids=new Set(); return S.chats.filter(x=>x.type==='private'&&x.peer_id&&!have.has(x.peer_id)&&!ids.has(x.peer_id)&&ids.add(x.peer_id)).map(x=>({id:x.peer_id,name:x.peer_name,username:x.peer_username,avatar_url:x.peer_avatar,color:x.peer_color})); };
shown=base();
modal('Добавить участников',`<label class="search" style="margin-bottom:10px"><span>${ic('search')}</span><input id="amQ" placeholder="Имя или @юзернейм"></label><div id="amL"></div>`,
[['Отмена','ghost'],['Добавить','primary',async cl=>{ if(!sel.size) return cl(); const {error}=await sb.rpc('lm_add_members',{p_chat:c.chat_id,p_members:[...sel.keys()]}); if(error) return toast(error.message); cl(); await loadMembers(c.chat_id); renderInfo(); renderHead(); }]]);
const draw=()=>{ $('#amL').innerHTML=shown.map(p=>`<div class="row" data-pick="${p.id}">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'s')}<div class="mid"><div class="t1"><span class="nm">${esc(p.name)}</span></div><div class="t2"><span class="pv">@${esc(p.username||'')}</span></div></div><span class="sel ${sel.has(p.id)?'on':''}">${sel.has(p.id)?ic('check'):''}</span></div>`).join('')||'<div style="color:var(--muted);text-align:center;padding:14px">Никого не найдено</div>'; };
draw();
$('#amL').onclick=e=>{ const r=e.target.closest('[data-pick]'); if(!r) return; const p=shown.find(x=>x.id===r.dataset.pick); sel.has(p.id)?sel.delete(p.id):sel.set(p.id,p); draw(); };
let t; $('#amQ').oninput=e=>{ clearTimeout(t); const q=e.target.value.trim().replace(/^@/,''); t=setTimeout(async()=>{ if(!q){ shown=base(); return draw(); } const {data}=await sb.rpc('lm_search',{q}); shown=(data||[]).filter(r=>r.kind==='user'&&!have.has(r.id)); draw(); },250); };
}
/* periodic refresh of "last seen" labels */
setInterval(()=>{ if(S.me){ if(cur()) renderHead(); if(S.tab==='contacts') renderContacts(); } },30000);
window.addEventListener('hashchange',()=>{ const h=location.hash.match(/^#@([a-z0-9_]+)/i); if(h&&S.me) openByUsername(h[1]); });
window.addEventListener('beforeunload',()=>{ if(C.st) hangup(); });
window.addEventListener('pagehide',()=>{ if(C.st) hangup(); });
/* Рисованные подарки Lumo: SVG с анимацией, собираются в браузере */
const LXA=(function(){
const CSS=`<style>:root{--e:cubic-bezier(.45,0,.55,1)}[class]{transform-box:fill-box}.tw{animation:tw 4s var(--e) infinite;transform-origin:center}@keyframes tw{0%,100%{opacity:.1;transform:scale(.5)}50%{opacity:1;transform:scale(1.3)}}.tw2{animation:tw 2s var(--e) infinite;transform-origin:center}.bob{animation:bob 4s var(--e) infinite}@keyframes bob{0%,100%{transform:translateY(10px)}50%{transform:translateY(-14px)}}.rays{animation:rays 4s linear infinite;transform-origin:400px 360px;transform-box:view-box}@keyframes rays{to{transform:rotate(45deg)}}.halo{animation:halo 4s var(--e) infinite;transform-origin:center}@keyframes halo{0%,100%{opacity:.55;transform:scale(.92)}50%{opacity:1;transform:scale(1.1)}}.rise{animation:rise 4s linear infinite;opacity:0}@keyframes rise{0%{opacity:0;transform:translate(0,0) scale(.4)}12%{opacity:1}100%{opacity:0;transform:translate(var(--dx),var(--dy)) scale(1)}}.sweep{animation:sweep 4s var(--e) infinite}@keyframes sweep{0%,35%{transform:translateX(-420px)}75%,100%{transform:translateX(420px)}}.spin{animation:spin 8s linear infinite;transform-origin:center}@keyframes spin{to{transform:rotate(360deg)}}.spinr{animation:spin 4s linear infinite reverse;transform-origin:center}.breathe{animation:br 4s var(--e) infinite;transform-origin:center}@keyframes br{0%,100%{transform:scale(.94)}50%{transform:scale(1.06)}}.sway{animation:sway 4s var(--e) infinite;transform-origin:center}@keyframes sway{0%,100%{transform:rotate(-6deg)}50%{transform:rotate(6deg)}}.flash{animation:flash 4s var(--e) infinite}@keyframes flash{0%,100%{opacity:0}50%{opacity:.8}}.flash2{animation:flash 4s var(--e) infinite;animation-delay:-1s}.flash3{animation:flash 4s var(--e) infinite;animation-delay:-2s}.flash4{animation:flash 4s var(--e) infinite;animation-delay:-3s}.ring{animation:ring 4s ease-out infinite;transform-origin:center}@keyframes ring{0%{opacity:.7;transform:scale(.3)}100%{opacity:0;transform:scale(1.6)}}.lid{animation:lid 4s var(--e) infinite;transform-origin:0% 100%}@keyframes lid{0%,100%{transform:rotate(0)}20%,80%{transform:rotate(-42deg)}}.pearl{animation:pearl 4s var(--e) infinite}@keyframes pearl{0%,100%{transform:translateY(40px) scale(.9)}25%,75%{transform:translateY(-34px) scale(1.05)}}.pglow{animation:pg 4s var(--e) infinite}@keyframes pg{0%,100%{opacity:0}30%,70%{opacity:1}}.trail{animation:trail 1s ease-in-out infinite;transform-origin:right center}@keyframes trail{0%,100%{transform:scaleX(1)}50%{transform:scaleX(1.12)}}.ember{animation:ember 2s linear infinite;opacity:0}@keyframes ember{0%{opacity:0;transform:translate(0,0) scale(.5)}15%{opacity:1}100%{opacity:0;transform:translate(var(--dx),var(--dy)) scale(.1)}}.petal{animation:petal 4s var(--e) infinite;transform-origin:50% 100%}@keyframes petal{0%,100%{transform:rotate(var(--a)) scale(.82)}50%{transform:rotate(var(--a)) scale(1.06)}}</style>`;
const f1=x=>x.toFixed(1), f0=x=>x.toFixed(0);
const star=(cx,cy,R,r,n,rot=0)=>{let o=[];for(let i=0;i<n*2;i++){const a=rot+Math.PI*i/n-Math.PI/2,rr=i%2?r:R;o.push(f1(cx+rr*Math.cos(a))+','+f1(cy+rr*Math.sin(a)));}return o.join(' ');};
const rng=s=>()=>{s=(s*9301+49297)%233280;return s/233280;};
const sparkles=(seed,cols,n=16)=>{const r=rng(seed*7+3);let o='';for(let i=0;i<n;i++){const x=40+r()*720,y=40+r()*600,s=4+r()*11,c=cols[Math.floor(r()*cols.length)],cl=r()<.5?'tw':'tw2';o+=`<polygon class="${cl}" style="animation-delay:-${(r()*4).toFixed(2)}s" points="${star(x,y,s,s*.3,4)}" fill="${c}"/>`;}return o;};
const particles=(seed,cols,n=7,cx=400,cy=380,spread=260)=>{const r=rng(seed*13+5);let o='';for(let i=0;i<n;i++){const a=r()*6.283,d=(.5+r()*.5)*spread,dx=Math.cos(a)*d,dy=-Math.abs(Math.sin(a))*d-80,x=cx+(r()-.5)*180,y=cy+(r()-.3)*140,s=4+r()*6;o+=`<circle class="rise" style="--dx:${f0(dx)}px;--dy:${f0(dy)}px;animation-delay:-${(r()*4).toFixed(2)}s" cx="${f0(x)}" cy="${f0(y)}" r="${s.toFixed(1)}" fill="${cols[Math.floor(r()*cols.length)]}"/>`;}return o;};
const rays=()=>{let o='';for(let i=0;i<8;i++){const a=Math.PI*2*i/8,L=520;o+=`<polygon points="400,360 ${f0(400+L*Math.cos(a-.08))},${f0(360+L*Math.sin(a-.08))} ${f0(400+L*Math.cos(a+.08))},${f0(360+L*Math.sin(a+.08))}" fill="url(#ray)"/>`;}return `<g class="rays" opacity=".35">${o}</g>`;};
const frame=(name,tag,id,bg1,bg2,glow,body,cols,extra='')=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800" width="800" height="800">${CSS}<defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${bg1}"/><stop offset="1" stop-color="${bg2}"/></linearGradient><radialGradient id="gl" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="${glow}" stop-opacity=".8"/><stop offset="1" stop-color="${glow}" stop-opacity="0"/></radialGradient><radialGradient id="ray" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(400 360) scale(520)"><stop offset="0" stop-color="${glow}" stop-opacity=".9"/><stop offset="1" stop-color="${glow}" stop-opacity="0"/></radialGradient><radialGradient id="vig" cx=".5" cy=".45" r=".75"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".55"/></radialGradient><filter id="blur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="16"/></filter><linearGradient id="rim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".9"/><stop offset=".5" stop-color="#fff" stop-opacity=".06"/><stop offset="1" stop-color="#fff" stop-opacity=".5"/></linearGradient><linearGradient id="shine" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".5" stop-color="#fff" stop-opacity=".85"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>${extra}</defs><rect width="800" height="800" rx="64" fill="url(#bg)"/>${rays()}<circle class="halo" cx="400" cy="360" r="330" fill="url(#gl)"/>${sparkles(id,cols)}${body}<rect width="800" height="800" rx="64" fill="url(#vig)"/><rect x="14" y="14" width="772" height="772" rx="56" fill="none" stroke="url(#rim)" stroke-width="3"/><text x="400" y="708" text-anchor="middle" font-family="sans-serif" font-weight="800" font-size="46" fill="#fff">${name}</text><text x="400" y="750" text-anchor="middle" font-family="sans-serif" font-size="24" fill="#fff" opacity=".7" letter-spacing="4">${tag}</text></svg>`;
const G={};
G.crystal=()=>{const shape='0,-200 110,-55 75,140 -75,140 -110,-55';
return frame('Лунный кристалл','ЛЕГЕНДАРНЫЙ',1,'#1b1f5e','#0a0c2a','#6f7dff',`<g class="bob"><g transform="translate(400 360)"><polygon points="${shape}" fill="#6f7dff" opacity=".5" filter="url(#blur)" class="halo"/><polygon points="0,-200 110,-55 0,40" fill="#cfe0ff"/><polygon points="0,-200 -110,-55 0,40" fill="#9db8ff"/><polygon points="110,-55 75,140 0,40" fill="#5f72f0"/><polygon points="-110,-55 -75,140 0,40" fill="#7d8dff"/><polygon points="-75,140 75,140 0,40" fill="#3f4fd0"/><polygon class="flash" points="0,-200 110,-55 0,40" fill="#fff"/><polygon class="flash2" points="110,-55 75,140 0,40" fill="#fff"/><polygon class="flash3" points="-75,140 75,140 0,40" fill="#fff"/><polygon class="flash4" points="-110,-55 -75,140 0,40" fill="#fff"/><polygon points="0,-200 30,-70 0,40 -30,-70" fill="#fff" opacity=".4"/><clipPath id="cc"><polygon points="${shape}"/></clipPath><g clip-path="url(#cc)"><g class="sweep"><polygon points="-60,-220 -10,-220 70,170 20,170" fill="url(#shine)"/></g></g><polyline points="${shape} 0,-200" fill="none" stroke="#fff" stroke-opacity=".75" stroke-width="3"/></g><g transform="translate(400 360)"><g class="spin" style="transform-origin:0 0;transform-box:view-box"><g transform="translate(190 0)"><polygon class="spinr" points="0,-16 10,0 0,16 -10,0" fill="#cfe0ff"/></g></g><g class="spinr" style="transform-origin:0 0;transform-box:view-box"><g transform="translate(-230 20)"><polygon points="0,-12 8,0 0,12 -8,0" fill="#fff6c9"/></g></g></g></g><g class="bob" style="animation-delay:-.6s"><path d="M600 130a70 70 0 1 0 60 100a56 56 0 1 1 -60 -100z" fill="#fff6c9"/></g>${particles(3,['#cfe0ff','#fff6c9'],6)}`,['#cfe0ff','#fff6c9']);};
G.comet=()=>{let em='';for(let i=0;i<6;i++){const sg=i%2?-1:1;em+=`<circle class="ember" style="--dx:${-170-i*20}px;--dy:${sg*(30+i*14)}px;animation-delay:-${(i*.3).toFixed(2)}s" cx="${480-i*6}" cy="${352+sg*6}" r="${4+i%3*2}" fill="${i%2?'#ffd36b':'#ff8a3d'}"/>`;}
return frame('Огненная комета','ЭПИЧЕСКИЙ',2,'#4a0f2a','#1a0618','#ff7a2b',`<g class="bob"><g transform="translate(-45 35) rotate(-30 400 360)"><g class="trail"><path d="M60 360 Q 280 280 480 335 Q 280 440 60 360z" fill="#ff5a1f" opacity=".5" filter="url(#blur)"/><path d="M40 360 Q 280 295 480 338 Q 280 425 40 360z" fill="#ff9a3d"/><path d="M150 360 Q 300 322 480 342 Q 300 398 150 360z" fill="#ffd36b"/><path d="M260 360 Q 360 338 480 346 Q 360 380 260 360z" fill="#fff3c0"/></g>${em}<circle class="ring" cx="505" cy="352" r="110" fill="none" stroke="#ffd36b" stroke-width="5"/><circle class="ring" style="animation-delay:-2s" cx="505" cy="352" r="110" fill="none" stroke="#ff8a3d" stroke-width="4"/><circle cx="505" cy="352" r="105" fill="#ff9a3d" opacity=".5" filter="url(#blur)" class="halo"/><circle class="breathe" cx="505" cy="352" r="80" fill="#ffecb0"/><circle cx="505" cy="352" r="80" fill="none" stroke="#fff" stroke-width="4" opacity=".85"/><circle cx="485" cy="332" r="30" fill="#fff" opacity=".75"/><circle cx="520" cy="372" r="46" fill="#ffd36b" opacity=".55"/></g></g>`,['#ffd36b','#ff8fb5']);};
G.pearl=()=>frame('Морская жемчужина','РЕДКИЙ',3,'#0a4a63','#06182e','#35d6e8',`<g class="bob" style="animation-duration:6s"><g transform="translate(400 400)"><path d="M-200 60 Q-200 190 0 200 Q200 190 200 60z" fill="#127f95"/><path d="M0 200 L-90 60 M0 200 L90 60 M0 200 L-170 60 M0 200 L170 60 M0 200 L0 60" stroke="#0b5f76" stroke-width="5" fill="none" opacity=".7"/><circle class="pglow" cx="0" cy="0" r="170" fill="#8ff3ff" opacity=".6" filter="url(#blur)"/><g class="pearl"><circle cx="0" cy="20" r="78" fill="#f4fbff"/><ellipse cx="-24" cy="-4" rx="24" ry="14" fill="#fff" transform="rotate(-30 -24 -4)"/><circle cx="0" cy="20" r="78" fill="none" stroke="#bfefff" stroke-width="4"/><clipPath id="pc"><circle cx="0" cy="20" r="78"/></clipPath><g clip-path="url(#pc)"><g class="sweep"><polygon points="-30,-80 10,-80 50,120 10,120" fill="url(#shine)"/></g></g></g><path d="M-200 60 Q-200 190 0 200 Q200 190 200 60 Q0 100 -200 60z" fill="#19a3b8"/><path d="M-200 60 Q0 100 200 60" fill="none" stroke="#9cf3ff" stroke-width="5"/><g class="lid"><path d="M-200 60 Q-200 -90 0 -120 Q200 -90 200 60 Q0 100 -200 60z" fill="#22b9cf"/><path d="M0 -120 L-110 80 M0 -120 L110 80 M0 -120 L-190 60 M0 -120 L190 60 M0 -120 L0 90" stroke="#0b6f86" stroke-width="5" fill="none" opacity=".5"/><path d="M-200 60 Q-200 -90 0 -120 Q200 -90 200 60" fill="none" stroke="#bff6ff" stroke-width="6"/></g></g></g>${particles(5,['#bff6ff','#fff'],7,400,420,240)}`,['#bff6ff','#fff']);
G.key=()=>{let d='';for(let i=0;i<6;i++){const sg=i%2?-1:1;d+=`<circle class="ember" style="--dx:${sg*(40+i*12)}px;--dy:${90+i*10}px;animation-delay:-${(i*.5).toFixed(2)}s;animation-duration:3s" cx="${300+i*20}" cy="${290+(i%3)*20}" r="${3+i%3*2}" fill="#fff3c0"/>`;}
return frame('Золотой ключ','МИФИЧЕСКИЙ',4,'#4d3410','#1c1204','#ffc247',`<g class="bob"><g transform="translate(400 370) rotate(-35)"><g class="sway"><rect x="-450" y="-300" width="900" height="600" fill="none"/><circle cx="-120" cy="0" r="110" fill="#ffc247" opacity=".5" filter="url(#blur)" class="halo"/><circle cx="-120" cy="0" r="86" fill="none" stroke="#ffd36b" stroke-width="34"/><circle cx="-120" cy="0" r="86" fill="none" stroke="#fff3c0" stroke-width="6" opacity=".7"/><rect x="-40" y="-17" width="290" height="34" rx="14" fill="#ffc247"/><rect x="-40" y="-17" width="290" height="12" rx="6" fill="#fff3c0" opacity=".65"/><rect x="160" y="10" width="30" height="62" rx="8" fill="#ffb02e"/><rect x="215" y="10" width="30" height="44" rx="8" fill="#ffb02e"/><polygon class="breathe" points="-120,-24 -96,0 -120,24 -144,0" fill="#ff5e8a"/><clipPath id="kc"><path clip-rule="evenodd" d="M-120 -103 A103 103 0 1 1 -120 103 A103 103 0 1 1 -120 -103 Z M-120 -69 A69 69 0 1 0 -120 69 A69 69 0 1 0 -120 -69 Z"/><rect x="-40" y="-17" width="290" height="34" rx="14"/><rect x="160" y="10" width="30" height="62" rx="8"/><rect x="215" y="10" width="30" height="44" rx="8"/></clipPath><g clip-path="url(#kc)"><g class="sweep"><polygon points="-60,-120 -10,-120 30,120 -20,120" fill="url(#shine)" opacity=".8"/></g></g></g></g></g><g transform="translate(400 370)"><g class="tw" style="animation-delay:-.5s"><polygon points="${star(210,-150,30,8,4)}" fill="#fff"/></g></g>${d}`,['#fff3c0','#ffd36b']);};
G.flower=()=>{const pet=(n,rx,ry,g,off,dl)=>{let o='';for(let i=0;i<n;i++)o+=`<ellipse class="petal" style="--a:${off+i*360/n}deg;animation-delay:-${dl+(i%2)*.5}s" cx="0" cy="-${ry}" rx="${rx}" ry="${ry}" fill="url(#${g})" opacity=".92"/>`;return o;};
let pol='';for(let i=0;i<7;i++)pol+=`<circle class="rise" style="--dx:${f0(Math.cos(i*1.8)*230)}px;--dy:${f0(Math.sin(i*1.8)*230)}px;animation-delay:-${(i*.55).toFixed(2)}s" cx="400" cy="360" r="${4+i%3*2}" fill="${i%2?'#ffe08a':'#ffd0f5'}"/>`;
const extra='<linearGradient id="pt" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff8fe0"/><stop offset="1" stop-color="#7c5cff"/></linearGradient><linearGradient id="pt2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffd0f5"/><stop offset="1" stop-color="#b069ff"/></linearGradient>';
return frame('Звёздный цветок','ЛЕГЕНДАРНЫЙ',5,'#3a1166','#12062a','#c066ff',`<g class="bob"><g transform="translate(400 360)"><circle r="200" fill="#c066ff" opacity=".4" filter="url(#blur)" class="halo"/><g class="spin" style="animation-duration:16s">${pet(8,46,105,'pt',0,0)}</g><g class="spinr" style="animation-duration:12s;transform:scale(.62)">${pet(8,46,105,'pt2',22.5,1)}</g><circle r="52" fill="#ffe08a" class="breathe"/><g class="spin" style="animation-duration:8s"><polygon points="${star(0,0,44,18,5)}" fill="#fff"/></g></g></g>${pol}`,['#ffd0f5','#b69cff'],extra);};
const gart=()=>window.__gart||{};
const loadArt=()=>{ if(window.__gartT&&Date.now()-window.__gartT<60000) return; window.__gartT=Date.now(); try{ sb.rpc('lm_gift_art').then(r=>{ if(r&&r.data&&typeof r.data==='object') window.__gart=r.data; }).catch(()=>{}); }catch(e){} };
return {svg:id=>{ loadArt(); const a=gart()[id]; return (typeof a==='string'&&a.indexOf('<svg')>=0)?a:(G[id]?G[id]():''); },ids:Object.keys(G),reload:()=>{ window.__gartT=0; loadArt(); }};
})();


/* ===== Lumo ext: люмены, подарки, комментарии, реакции каналов, звёзды Premium ===== */
(function(){
if(window.__lx||localStorage.getItem('lx_off')) return; window.__lx=1;
const LX={cfg:{},cfgT:0,tips:new Map(),tipAsk:new Set(),cmn:new Map(),cmnAsk:new Set(),art:{}};
const rp=async(n,a)=>{ const {data,error}=await sb.rpc(n,a||{}); if(error) throw new Error(error.message); return data; };
const owner=()=>S.staff==='owner';
const lw=n=>plural(Number(n)||0,'люмен','люмена','люменов');
const RAR={rare:['Редкий','#22c7e0'],epic:['Эпический','#ff8a3d'],legendary:['Легендарный','#b069ff'],mythic:['Мифический','#ffc247'],ultra:['Божественный','#ff2ec4']};
const gem=(s=22)=>`<svg class="lxgem" width="${s}" height="${s}" viewBox="0 0 64 64"><defs><linearGradient id="lxg1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffe08a"/><stop offset=".5" stop-color="#ff9a3d"/><stop offset="1" stop-color="#ff5e8a"/></linearGradient></defs><polygon points="32,1.3 58.6,16.6 58.6,47.3 32,62.7 5.4,47.4 5.4,16.6" fill="url(#lxg1)" stroke="#fff" stroke-opacity=".4" stroke-width="2.9" stroke-linejoin="round"/><polygon points="32,13.4 35.4,28.6 50.6,32 35.4,35.4 32,50.6 28.6,35.4 13.4,32 28.6,28.6" fill="#fff"/></svg>`;
const live=(s=84)=>{ let sp=''; for(let i=0;i<10;i++){ const a=i*36; sp+=`<i style="--a:${a}deg;animation-delay:-${(i*.3).toFixed(1)}s"></i>`; } return `<div class="lxlive" style="width:${s*2}px;height:${s*1.6}px"><div class="lxhalo"></div>${sp}<div class="lxgw">${gem(s)}</div></div>`; };
const artUrl=id=>{ if(!LX.art[id]) LX.art[id]='data:image/svg+xml;charset=utf-8,'+encodeURIComponent(LXA.svg(id)); return LX.art[id]; };
const nm=id=>profName(id);

/* ---------- стили ---------- */
const st=document.createElement('style'); st.textContent=`
.lxgem{display:block}.lxlive{position:relative;margin:0 auto 10px;display:flex;align-items:center;justify-content:center}
.lxhalo{position:absolute;inset:8%;border-radius:50%;background:radial-gradient(circle,rgba(255,179,71,.55),transparent 68%);animation:lxp 3s ease-in-out infinite}
.lxgw{animation:lxsw 2.6s ease-in-out infinite;position:relative}
.lxlive i{position:absolute;left:50%;top:50%;width:8px;height:8px;margin:-4px;background:#ffe08a;transform:rotate(45deg);border-radius:2px;opacity:0;animation:lxsp 3s linear infinite}
@keyframes lxp{0%,100%{transform:scale(.92);opacity:.7}50%{transform:scale(1.1);opacity:1}}
@keyframes lxsw{0%,100%{transform:rotate(-8deg) scale(.97)}50%{transform:rotate(8deg) scale(1.05)}}
@keyframes lxsp{0%{opacity:0;transform:rotate(var(--a)) translateX(30px) rotate(45deg) scale(.4)}15%{opacity:1}100%{opacity:0;transform:rotate(var(--a)) translateX(92px) rotate(45deg) scale(1)}}
.ov .modal.lxglass{background:linear-gradient(135deg,rgba(255,255,255,.2),rgba(255,255,255,.06) 55%,rgba(176,156,255,.16));backdrop-filter:blur(26px) saturate(1.4);-webkit-backdrop-filter:blur(26px) saturate(1.4);border:1px solid rgba(255,255,255,.35);box-shadow:0 30px 80px rgba(60,20,160,.45);color:#fff;max-width:400px}
.ov:has(.modal.lxglass){background:radial-gradient(circle at 15% 15%,rgba(255,154,61,.35),transparent 55%),radial-gradient(circle at 85% 85%,rgba(124,92,255,.45),transparent 55%),rgba(8,6,24,.7)}
.lxglass .mh{display:none}.lxglass .mb{padding:18px 20px 20px;text-align:center}
.lxrc{display:flex;gap:10px;align-items:center;justify-content:center;margin:2px 0 10px}
.lxrc .t{text-align:left;font-size:12px;opacity:.75}.lxrc b{display:block;font-size:17px;opacity:1}
.lxamt{display:flex;align-items:center;justify-content:center;gap:10px;background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.3);border-radius:22px;padding:8px 14px}
.lxamt input{width:140px;background:none;border:0;outline:0;color:#fff;font-size:44px;font-weight:800;text-align:center;font-family:inherit}
.lxchips{display:flex;gap:8px;justify-content:center;flex-wrap:wrap;margin:12px 0}
.lxchips button{padding:7px 12px;border-radius:14px;background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.25);color:#fff;font-weight:700}
.lxchips button.on{background:rgba(255,255,255,.32);border-color:rgba(255,255,255,.7)}
.lxnote{font-size:13px;opacity:.78;margin:4px 0 12px}
.lxbtn{display:block;width:100%;height:52px;border-radius:20px;background:var(--accent);color:#fff;font-weight:800;font-size:17px;border:1px solid rgba(255,255,255,.5)}
.lxbtn[disabled]{opacity:.5}.lxbtn.alt{background:rgba(255,255,255,.1);margin-top:8px;font-weight:600;font-size:15px;height:44px}
.lxdone h2{margin:6px 0 2px;font-size:26px}.lxdone p{opacity:.85;margin:0 0 14px}
.lxw{text-align:center}.lxw .bal{font-size:44px;font-weight:800;line-height:1.1}.lxw .sub{color:var(--muted);margin-bottom:12px}
.lxhist{margin-top:12px;text-align:left;max-height:240px;overflow:auto}.lxhist div{display:flex;justify-content:space-between;gap:10px;padding:8px 2px;border-top:1px solid var(--line);font-size:14px}
.lxhist .p{color:var(--ok);font-weight:700}.lxhist .m{color:var(--danger);font-weight:700}
.lxgrid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.lxg{background:var(--panel2);border-radius:20px;padding:8px;text-align:center;cursor:pointer}
.lxg img{width:100%;aspect-ratio:1;border-radius:16px;display:block}.lxg b{display:block;margin-top:6px;font-size:14px}
.lxg .pr{display:flex;gap:4px;align-items:center;justify-content:center;font-weight:800;margin-top:3px}.lxg small{color:var(--muted)}
.lxbd{display:inline-block;font-size:10px;font-weight:700;letter-spacing:.04em;padding:2px 8px;border-radius:9px;border:1px solid;margin-top:4px}
.lxsec{margin:14px 2px 6px;font-size:12px;font-weight:700;color:var(--muted);letter-spacing:.05em}
.lxmine{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}.lxmine .lxg b{font-size:12px;margin-top:4px}
.lxgm{display:flex;flex-direction:column;align-items:center;margin:10px 0}
.lx-giftwrap{display:inline-block}
.lx-giftwrap.lxgift-launch{animation:lxlaunch 1.05s cubic-bezier(.22,.9,.32,1.1) both}
@keyframes lxlaunch{0%{transform:translateY(160px) scale(.3) rotate(-8deg);opacity:0;filter:blur(3px)}55%{transform:translateY(-18px) scale(1.12) rotate(3deg);opacity:1;filter:blur(0)}75%{transform:translateY(6px) scale(.96) rotate(-1deg)}100%{transform:translateY(0) scale(1) rotate(0);opacity:1}}
.lxpill{background:var(--panel);color:var(--text);padding:6px 14px;border-radius:16px;font-size:13px;font-weight:600;text-align:center;max-width:88%}
.lxcard{margin-top:8px;width:250px;max-width:86%;border-radius:26px;padding:14px;text-align:center;background:linear-gradient(180deg,var(--lxc),var(--panel));border:1px solid var(--lxb);color:var(--text)}
.lxcard img{width:150px;height:150px;border-radius:20px}.lxcard b{display:block;font-size:18px;margin-top:6px}.lxcard .n{font-weight:700;font-size:14px}.lxcard .d{color:var(--muted);font-size:13px;margin:4px 0 10px}
.lxcard button{padding:9px 26px;border-radius:18px;background:var(--lxb);font-weight:700;color:var(--text)}
.lxtip{display:flex;width:fit-content;align-items:center;gap:4px;margin-top:4px;padding:2px 8px;border-radius:12px;background:rgba(255,180,70,.18);font-size:12px;font-weight:700;clear:both}
.lxcm{display:flex;align-items:center;gap:10px;margin-top:8px;padding:9px 0 2px;border-top:1px solid var(--line);color:var(--a2);font-weight:400;font-size:16px;cursor:pointer;clear:both;min-width:220px}.lxcm .hs{display:flex;align-items:center}.lxcm .hs>span{display:inline-flex;margin-left:-9px}.lxcm .hs>span:first-child{margin-left:0}.lxcm .hs .av{width:30px;height:30px;min-width:30px;font-size:12px;border:2px solid var(--panel);box-sizing:border-box}.lxcm .t{flex:1}.lxcm .ci,.lxcm .ar{display:inline-flex;align-items:center}.lxcm .ci svg{width:20px;height:20px}.lxcm .ar svg{width:18px;height:18px}
.lxcl{max-height:46vh;overflow:auto;text-align:left}.lxcl .c{padding:8px 0;border-bottom:1px solid var(--line)}.lxcl .c b{font-size:13px;color:var(--a1)}.lxcl .c div{white-space:pre-wrap;word-break:break-word}
.lxcin{display:flex;gap:8px;margin-top:10px}.lxcin input{flex:1}
.lxset{display:flex;justify-content:space-between;padding:12px 4px;border-top:1px solid var(--line);cursor:pointer;transition:background .15s ease,opacity .15s ease,transform .1s ease}.lxset:active{transform:scale(.985)}.lxset span{color:var(--muted)}
.lxrx{display:flex;flex-wrap:wrap;gap:8px}.lxrx button{font-size:24px;padding:6px 8px;border-radius:12px;background:var(--panel2);opacity:.45}.lxrx button.on{opacity:1;outline:2px solid var(--a1)}
.pmhero{position:relative}.lxem{position:absolute;pointer-events:none;width:0;height:0}
.lxem i{position:absolute;left:0;top:0;width:var(--s);height:var(--s);margin:calc(var(--s)/-2);background:var(--c);clip-path:polygon(50% 0,61% 35%,98% 35%,68% 57%,79% 91%,50% 70%,21% 91%,32% 57%,2% 35%,39% 35%);opacity:0;animation:lxst 3.6s linear infinite}
@keyframes lxst{0%{opacity:0;transform:translate(0,0) rotate(0) scale(.4)}10%{opacity:1}100%{opacity:0;transform:translate(var(--x),var(--y)) rotate(220deg) scale(1)}}
.lxgrow{margin:8px 0}.lxgrow .lxsec{margin-top:4px}
`;
document.head.appendChild(st);

/* ---------- кошелёк ---------- */
async function lxWallet(){
  const close=modal('Люмены','<div class="lxw" id="lxw"><div class="sub">Загрузка…</div></div>',[]);
  const el=document.getElementById('lxw');
  try{
    const w=await rp('lm_wallet_me'); const hist=await rp('lm_wallet_history',{p_limit:60}).catch(()=>[]);
    const ids=[...new Set(hist.map(h=>h.ref_user).filter(Boolean))].filter(i=>!S.profiles.has(i)); if(ids.length) await profGet(ids).catch(()=>{});
    const K={daily:['Ежедневный бонус',1],tip_in:['Получено от ',1],tip_out:['Отправлено для ',0],grant:['Начислено владельцем',1],gift_buy:['Подарок',0],gift_sell:['Обмен подарка на люмены',1],game_stake:['Ставка в игре',0],game_win:['Выигрыш в игре',1],game_refund:['Возврат ставки',1]};
    const render=w=>{
      el.innerHTML=`${live(72)}<div class="bal">${w.balance}</div><div class="sub">${lw(w.balance)}</div>
      <button class="lxbtn" id="lxClaim" ${w.can_claim?'':'disabled'}>${w.can_claim?'Забрать ежедневный бонус':'Бонус получен — загляните позже'}</button>
      ${w.streak>0?`<div class="lxnote" style="color:var(--muted)">Серия: ${w.streak} дн. подряд. Чем длиннее серия, тем больше бонус — до 10 в день.</div>`:''}
      <button class="lxbtn alt" id="lxToG" style="background:var(--panel2);color:var(--text)">Подарки за люмены</button>
      <div class="lxsec" style="text-align:left">ИСТОРИЯ</div><div class="lxhist">${hist.length?hist.map(h=>{ const k=K[h.kind]||[h.kind,h.delta>0]; const who=h.ref_user&&(h.kind==='tip_in'||h.kind==='tip_out'||h.kind==='gift_buy')?esc(nm(h.ref_user)):''; return `<div><span>${esc(k[0])}${who}</span><span class="${h.delta>0?'p':'m'}">${h.delta>0?'+':''}${h.delta}</span></div>`; }).join(''):'<div style="color:var(--muted)">Пока пусто</div>'}</div>`;
      document.getElementById('lxClaim').onclick=async()=>{ try{ const r=await rp('lm_wallet_daily'); toast('Получено: '+(r&&r.amount||0)+' '+lw(r&&r.amount)); render(await rp('lm_wallet_me')); }catch(e){ toast(e.message); } };
      document.getElementById('lxToG').onclick=()=>{ close(); lxGifts(); };
    };
    render(w);
  }catch(e){ el.innerHTML='<div class="sub">'+esc(e.message)+'</div>'; }
}

/* ---------- отправка люменов ---------- */
function lxSend(uid,msgId){
  let amt=5, busy=false; const own=owner();
  const close=modal('',`<div id="lxs">${live(70)}
  <div class="lxrc"><div class="t">Получатель<b>${esc(nm(uid))}</b></div></div>
  <div class="lxamt"><input id="lxA" inputmode="numeric" value="5" maxlength="${own?7:4}">${gem(30)}</div>
  <div class="lxchips">${[1,5,10,50,100,500].map(v=>`<button data-v="${v}">${v}</button>`).join('')}</div>
  <div class="lxnote" id="lxN">${own?'Вы владелец: люмены начисляются без списания с вашего счёта':'Загрузка баланса…'}</div>
  <button class="lxbtn" id="lxGo">Отправить</button><button class="lxbtn alt" id="lxNo">Закрыть</button></div>`,[]);
  const ov=[...document.querySelectorAll('.ov')].pop(); ov&&ov.querySelector('.modal').classList.add('lxglass');
  const inp=document.getElementById('lxA'); const sync=()=>{ ov.querySelectorAll('.lxchips button').forEach(b=>b.classList.toggle('on',+b.dataset.v===(+inp.value||0))); };
  inp.oninput=()=>{ inp.value=inp.value.replace(/\D/g,''); sync(); }; sync();
  ov.querySelectorAll('.lxchips button').forEach(b=>b.onclick=()=>{ inp.value=b.dataset.v; sync(); });
  document.getElementById('lxNo').onclick=close;
  if(!own) rp('lm_wallet_me').then(w=>{ const n=document.getElementById('lxN'); if(n) n.textContent='На вашем счёте: '+w.balance+' '+lw(w.balance); }).catch(()=>{});
  document.getElementById('lxGo').onclick=async()=>{
    const n=+inp.value||0; if(n<1||busy) return; busy=true; document.getElementById('lxGo').disabled=true;
    try{
      if(msgId){ await rp('lm_wallet_tip',{p_message:msgId,p_amount:n}); LX.tips.set(msgId,(LX.tips.get(msgId)||0)+n); decorate(); }
      else await rp('lm_wallet_send',{p_user:uid,p_amount:n});
      document.getElementById('lxs').innerHTML=`<div class="lxdone">${live(86)}<h2>Отправлено</h2><p>${n} ${lw(n)} для ${esc(nm(uid))}</p></div>`;
      setTimeout(close,1800);
    }catch(e){ toast(e.message); busy=false; document.getElementById('lxGo').disabled=false; }
  };
}

/* ---------- подарки ---------- */
const badge=r=>{ const x=RAR[r]||[r,'#888']; return `<span class="lxbd" style="color:${x[1]};border-color:${x[1]}88;background:${x[1]}22">${x[0].toUpperCase()}</span>`; };
async function lxGifts(toUid){
  const close=modal(toUid?'Подарок для '+esc(nm(toUid)):'Подарки','<div id="lxg"><div class="lxnote">Загрузка…</div></div>',[]);
  const draw=async()=>{
    const el=document.getElementById('lxg'); if(!el) return;
    try{
      try{ const ga=await rp('lm_gift_art'); if(ga&&typeof ga==='object') window.__gart=ga; }catch(e){}
      const [cat,mine,w]=await Promise.all([rp('lm_gift_list'),rp('lm_gift_mine'),rp('lm_wallet_me').catch(()=>null)]);
      el.innerHTML=`${w?`<div style="display:flex;gap:8px;align-items:center;margin-bottom:6px">${gem(22)}<b>${w.balance} ${lw(w.balance)}</b></div>`:''}
      <div class="lxnote" style="text-align:left;color:var(--muted)">Редкие подарки с ограниченным тиражом.${toUid?'':' Купите себе или подарите другу из его профиля.'}</div>
      <div class="lxgrid">${cat.map(g=>`<div class="lxg" data-g="${g.id}">${art(g.id,'')}<b>${esc(g.name)}</b>${badge(g.rarity)}<div class="pr">${gem(15)}${g.supply-g.sold>0?g.price:'Раскуплено'}</div><small>${Math.max(0,g.supply-g.sold)} из ${g.supply}</small></div>`).join('')}</div>
      ${!toUid&&mine.length?`<div class="lxsec">МОИ ПОДАРКИ</div><div class="lxmine">${mine.map(o=>`<div class="lxg" data-o="${o.id}" style="${o.hidden?'opacity:.5':''}">${art(o.gift_id,'')}<b style="color:${(RAR[o.rarity]||[0,'#888'])[1]}">№${o.serial}</b>${o.hidden?'<small>Скрыт</small>':''}</div>`).join('')}</div>`:''}`;
      el.querySelectorAll('[data-g]').forEach(c=>c.onclick=()=>detail(cat.find(g=>g.id===c.dataset.g)));
      el.querySelectorAll('[data-o]').forEach(c=>c.onclick=()=>owned(mine.find(o=>String(o.id)===c.dataset.o)));
    }catch(e){ el.innerHTML='<div class="lxnote">'+esc(e.message)+'</div>'; }
  };
  const detail=g=>{
    const left=Math.max(0,g.supply-g.sold);
    const c2=modal(esc(g.name),`<div style="text-align:center"><img src="${artUrl(g.id)}" style="width:100%;max-width:320px;border-radius:24px"><div>${badge(g.rarity)}</div><div class="lxnote" style="color:var(--muted)">Осталось ${left} из ${g.supply}${toUid?'<br>Получатель: '+esc(nm(toUid)):''}</div></div>`,
      [['Отмена','ghost'],[left?`${toUid?'Подарить':'Купить'} за ${owner()?0:g.price}`:'Раскуплено','primary',async cl=>{ if(!left) return; try{ const r=await rp('lm_gift_buy',toUid?{p_gift:g.id,p_to:toUid}:{p_gift:g.id}); cl(); toast((toUid?'Подарено: ':'Куплено: ')+g.name+' №'+r.serial); if(toUid) close(); else draw(); }catch(e){ toast(e.message); } }]]);
  };
  const owned=o=>{ if(!o) return; const refund=Math.max(1,Math.floor((o.price||0)*0.5));
  modal(esc(o.name),`<div style="text-align:center"><img src="${artUrl(o.gift_id)}" style="width:100%;max-width:320px;border-radius:24px"><div>${badge(o.rarity)}</div><div style="font-weight:800;font-size:20px;margin-top:6px">№${o.serial} из ${o.supply}</div>${o.from_user?`<div class="lxnote" style="color:var(--muted)">От: ${esc(nm(o.from_user))}</div>`:''}<div class="lxnote" style="color:var(--muted)">Получен: ${fmtDay(o.at)}</div>${o.hidden?'<div class="lxnote" style="color:var(--muted)">Скрыт из профиля</div>':''}</div>`,
    [['Закрыть','ghost'],[o.hidden?'Показать в профиле':'Скрыть из профиля','ghost',async cl=>{ try{ await rp('lm_gift_hide',{p_owned_id:o.id,p_hidden:!o.hidden}); o.hidden=!o.hidden; cl(); toast(o.hidden?'Подарок скрыт из профиля':'Подарок снова виден в профиле'); draw(); }catch(e){ toast(e.message); } }],[`Обменять на ${refund} ${lw(refund)}`,'primary',cl=>{ cl(); confirmBox('Обменять «'+o.name+'» на '+refund+' '+lw(refund)+'? Подарок пропадёт из профиля.','Обменять',async()=>{ try{ const r=await rp('lm_gift_sell',{p_owned_id:o.id}); toast('Получено: '+r.refund+' '+lw(r.refund)); draw(); }catch(e){ toast(e.message); } }); }]]); };
  draw();
}
function lxGiftMsg(m){
  const me=m.sender_id===S.me.id, mt=m.meta||{}, c=cur(), col=(RAR[mt.rarity]||[0,'#888'])[1];
  const who=me?'Вы отправили подарок: '+esc(nm(c&&c.peer_id)):esc(nm(m.sender_id))+' отправил(а) Вам подарок';
  const launch=me&&m._pending?' lxgift-launch':'';
  return `<div class="lxgm" data-id="${m.id}"><div class="lxpill">${who} стоимостью ${mt.price||0} ${lw(mt.price)}</div><div class="lxcard" style="--lxc:${col}59;--lxb:${col}73"><span class="lx-giftwrap${launch}">${art(mt.gift_id,'')}</span><b>Подарок</b><div class="n" style="color:${col}">${esc(mt.name||'')} №${mt.serial} из ${mt.supply}</div><div class="d">${me?'Подарок появится в профиле получателя.':'Подарок добавлен в ваш профиль.'}</div><button data-lxg="${m.id}">Посмотреть</button></div></div>`;
}

/* ---------- комментарии и реакции каналов ---------- */
async function lxCfg(){ LX.cfgT=Date.now(); try{ const {data}=await sb.from('lm_chats').select('id,reactions,linked_chat_id').eq('type','channel'); (data||[]).forEach(r=>{ LX.cfg[r.id]={rx:r.reactions,linked:r.linked_chat_id}; }); }catch(e){} }
const nz=e=>String(e).replace(/️/g,'');
function lxQuick(){ try{ const c=cur(); const f=c&&c.type==='channel'&&LX.cfg[c.chat_id]; if(f&&Array.isArray(f.rx)){ const a=f.rx.map(nz); return QUICK.filter(e=>a.includes(nz(e))); } }catch(e){} return QUICK; }
async function lxComments(post){
  const close=modal('Комментарии','<div class="lxcl" id="lxcl"></div><div class="lxcin"><input class="inp" id="lxci" maxlength="1000" placeholder="Написать комментарий…"><button class="btn primary" id="lxcb">Отправить</button></div>',[]);
  const load=async()=>{ const el=document.getElementById('lxcl'); if(!el) return clearInterval(t); try{ const L=await rp('lm_comments',{p_post:post}); const ids=[...new Set(L.map(x=>x.sender_id))].filter(i=>i&&!S.profiles.has(i)); if(ids.length) await profGet(ids).catch(()=>{});
    el.innerHTML=L.length?L.map(x=>`<div class="c"><b>${esc(nm(x.sender_id))}</b><div>${esc(x.body||'')}</div></div>`).join(''):'<div style="color:var(--muted);text-align:center;padding:20px">Комментариев пока нет. Напишите первый.</div>'; LX.cmn.set(post,L.length); }catch(e){ el.innerHTML=esc(e.message); } };
  const t=setInterval(load,5000); await load();
  const send=async()=>{ const i=document.getElementById('lxci'); const v=i.value.trim(); if(!v) return; i.value=''; try{ await rp('lm_comment_add',{p_post:post,p_body:v}); await load(); decorate(); }catch(e){ toast(e.message); i.value=v; } };
  document.getElementById('lxcb').onclick=send; document.getElementById('lxci').onkeydown=e=>{ if(e.key==='Enter'){ e.preventDefault(); send(); } };
}
const ALLRX=['👍','❤️','😂','😮','😢','🔥','🙏','👏','🎉','🤔','😍','👎','💯','🤝','😡','🥰'];
function lxChanSettings(mb){
  const c=cur(); if(!c||c.type!=='channel'||mb.querySelector('.lxset')) return;
  const f=LX.cfg[c.chat_id]||{}; const rxT=f.rx==null?'Все':(f.rx.length?f.rx.length+' из '+ALLRX.length:'Выключены');
  const lk=f.linked&&S.chatMap.get(f.linked); const d=document.createElement('div');
  d.innerHTML=`<div class="lxset" data-s="rx">Реакции<span>${rxT} ›</span></div><div class="lxset" data-s="dc">Обсуждение<span>${lk?esc(lk.title):'Нет'} ›</span></div>`;
  mb.appendChild(d);
  d.querySelector('[data-s=rx]').onclick=()=>{ let sel=new Set((f.rx==null?ALLRX:f.rx).map(nz));
    const cl=modal('Реакции в канале','<div class="lxnote" style="color:var(--muted)">Выберите, какие реакции можно ставить на посты.</div><div class="lxrx" id="lxrx"></div>',
      [['Выключить все','ghost',async x=>{ try{ await rp('lm_set_reactions',{p_chat:c.chat_id,p_list:[]}); await lxCfg(); x(); toast('Реакции выключены'); }catch(e){ toast(e.message); } }],['Сохранить','primary',async x=>{ try{ const all=ALLRX.every(e=>sel.has(nz(e))); await rp('lm_set_reactions',{p_chat:c.chat_id,p_list:all?null:ALLRX.filter(e=>sel.has(nz(e)))}); await lxCfg(); x(); toast('Сохранено'); }catch(e){ toast(e.message); } }]]);
    const draw=()=>{ document.getElementById('lxrx').innerHTML=ALLRX.map(e=>`<button data-e="${e}" class="${sel.has(nz(e))?'on':''}">${e}</button>`).join(''); document.querySelectorAll('#lxrx button').forEach(b=>b.onclick=()=>{ const k=nz(b.dataset.e); sel.has(k)?sel.delete(k):sel.add(k); draw(); }); }; draw(); };
  d.querySelector('[data-s=dc]').onclick=()=>{ const gs=S.chats.filter(x=>x.type==='group'&&['owner','admin'].includes(x.role));
    const btns=[['Создать группу','primary',x=>{ x(); newChatFlow('group',async gid=>{ try{ await rp('lm_link_discussion',{p_channel:c.chat_id,p_group:gid}); await lxCfg(); toast('Группа создана и подключена'); }catch(e){ toast(e.message); } }); }]];
    if(f.linked) btns.push(['Отвязать группу','ghost',async x=>{ try{ await rp('lm_link_discussion',{p_channel:c.chat_id,p_group:null}); await lxCfg(); x(); toast('Группа отвязана'); }catch(e){ toast(e.message); } }]);
    const cl=modal('Обсуждение',`<div class="lxnote" style="color:var(--muted)">Выберите группу: комментарии к постам будут храниться в ней.</div>${gs.length?gs.map(g=>`<div class="lxset" data-gid="${g.chat_id}">${esc(g.title)}<span>${f.linked===g.chat_id?'подключена':'выбрать'}</span></div>`).join(''):'<div style="color:var(--muted)">Нет своих групп — создайте новую кнопкой ниже.</div>'}`,btns);
    document.querySelectorAll('[data-gid]').forEach(r=>r.onclick=async()=>{ try{ await rp('lm_link_discussion',{p_channel:c.chat_id,p_group:r.dataset.gid}); await lxCfg(); document.querySelectorAll('.ov').forEach(o=>o.remove()); toast('Обсуждение подключено'); }catch(e){ toast(e.message); } }); };
}

/* ---------- оформление интерфейса ---------- */
window.lxRows=function(){ const row=(id,svg,col,l,s)=>`<div class="set srow" id="${id}"><span class="sic" style="background:${col}">${svg}</span><span class="sl">${l}<span class="setsub">${s}</span></span><span class="chev">${ic('down','mini rot')}</span></div>`;
  return row('lxWal',gem(22),'linear-gradient(135deg,#ff9a3d,#ff5e8a)','Люмены','Баланс, бонус, история')+row('lxGif','<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13M5 12v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-8M8 8a2.5 2.5 0 1 1 4-2M16 8a2.5 2.5 0 1 0-4-2"/></svg>','#ff5e8a','Подарки','Редкие подарки за люмены'); };
window.lxGiftMsg=lxGiftMsg; window.lxQuick=lxQuick; window.lxTip=(u,id)=>lxSend(u,id);
const btnIc={send:gem(22),gift:'<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13M5 12v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-8M8 8a2.5 2.5 0 1 1 4-2M16 8a2.5 2.5 0 1 0-4-2"/></svg>'};
document.addEventListener('click',e=>{
  const t=e.target; let x;
  if((x=t.closest('#lxWal'))) return lxWallet();
  if((x=t.closest('#lxGif'))) return lxGifts();
  if((x=t.closest('[data-lx]'))){ e.stopPropagation(); const u=x.dataset.u; const k=x.dataset.lx; document.querySelectorAll('.ov').forEach(o=>{ if(o.querySelector('.uacts')) o.remove(); }); return k==='send'?lxSend(u):lxGifts(u); }
  if((x=t.closest('[data-lxg]'))){ const m=findMsg(+x.dataset.lxg); if(m){ const mt=m.meta||{}; modal(esc(mt.name||'Подарок'),`<div style="text-align:center"><img src="${artUrl(mt.gift_id)}" style="width:100%;max-width:320px;border-radius:24px"><div>${badge(mt.rarity)}</div><div style="font-weight:800;font-size:20px;margin-top:6px">№${mt.serial} из ${mt.supply}</div><div class="lxnote" style="color:var(--muted)">Получен: ${fmtDay(m.created_at)}</div></div>`,[['Закрыть','ghost']]); } return; }
  if((x=t.closest('[data-lxc]'))){ e.stopPropagation(); return lxComments(+x.dataset.lxc); }
},true);

let dT=0; function vShort(n){ return n>=1000?(n/1000).toFixed(1).replace('.0','')+'K':String(n); }
function lxViewsLoad(c){ if(!c||c.type!=='channel') return; LX.views=LX.views||new Map(); LX.vreq=LX.vreq||new Set();
  const ids=[...document.querySelectorAll('#msgs .m[data-id]')].map(e=>+e.dataset.id).filter(i=>i>0&&!LX.vreq.has(i)).slice(-80); if(!ids.length) return;
  ids.forEach(i=>LX.vreq.add(i)); rp('lm_msg_views',{p_chat:c.chat_id,p_ids:ids}).then(rows=>{ (rows||[]).forEach(r=>LX.views.set(+r.id,+r.n)); decorate(); }).catch(()=>{ ids.forEach(i=>LX.vreq.delete(i)); }); }
async function lxChanTip(id){ const c=cur(); const owner=S.staff==='owner'; let bal=0; if(!owner){ try{ const w=await rp('lm_wallet_me'); bal=+w.balance||0; }catch{} }
  const mx=owner?1000:Math.min(1000,bal); if(mx<1){ toast('У вас пока нет люменов'); return; }
  let v=Math.min(10,mx); let busy=false;
  const close=modal('Реакция люменами',`<div style="text-align:center"><div style="display:inline-flex;align-items:center;gap:6px;padding:7px 16px;border-radius:20px;background:linear-gradient(#ffb347,#f2994a);color:#fff;font-size:26px;font-weight:800">${gem(22)}<span id="lxcV">${v}</span></div>${mx>1?`<input type="range" id="lxcR" min="1" max="${mx}" value="${v}" style="width:100%;margin:16px 0">`:'<div style="height:14px"></div>'}<p style="color:var(--muted);line-height:1.45;margin:0 0 14px">Выберите количество люменов для отправки ${esc(chatName(c))} в поддержку этой публикации.</p><button class="btn primary w" id="lxcGo">Отправить ${v}</button></div>`);
  const r=document.getElementById('lxcR'), go=document.getElementById('lxcGo');
  if(r) r.oninput=()=>{ v=+r.value; document.getElementById('lxcV').textContent=v; go.textContent='Отправить '+v; };
  go.onclick=async()=>{ if(busy) return; busy=true; go.disabled=true; try{ await rp('lm_wallet_tip',{p_message:id,p_amount:v}); LX.tips.set(id,(LX.tips.get(id)||0)+v); decorate(); toast('Отправлено'); close(); }catch(e){ toast(e.message); busy=false; go.disabled=false; } };
}
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('[data-lxr]'); if(t){ e.stopPropagation(); lxChanTip(+t.dataset.lxr); } },true);
function decorate(){ clearTimeout(dT); dT=setTimeout(run,80); }
function run(){ try{ if(!S||!S.me) return;
  if(!LX.cfgT||Date.now()-LX.cfgT>120000) lxCfg().then(decorate);
  document.querySelectorAll('.uacts[data-lxu]:not([data-lxd])').forEach(a=>{ a.dataset.lxd=1; const u=a.dataset.lxu; if(!u||u===S.me.id) return; const p=S.profiles.get(u); if(p&&p.is_bot) return;
    a.insertAdjacentHTML('beforeend',`<button data-lx="send" data-u="${u}">${btnIc.send}Люмены</button><button data-lx="gift" data-u="${u}">${btnIc.gift}Подарок</button>`);
    const g=document.createElement('div'); g.className='lxgrow'; a.after(g);
    rp('lm_gift_mine',{p_user:u}).then(L=>{ if(!L.length) return; g.innerHTML=`<div class="lxsec">ПОДАРКИ · ${L.length}</div><div class="lxmine">${L.slice(0,6).map(o=>`<div class="lxg" data-og="1"><img src="${artUrl(o.gift_id)}" alt=""><b style="color:${(RAR[o.rarity]||[0,'#888'])[1]}">№${o.serial}</b></div>`).join('')}</div>`; }).catch(()=>{}); });
  document.querySelectorAll('.iact[data-lxu]:not([data-lxd])').forEach(a=>{ a.dataset.lxd=1; const u=a.dataset.lxu; if(!u) return;
    a.insertAdjacentHTML('beforeend',`<button data-lx="send" data-u="${u}">${btnIc.send}<span>люмены</span></button><button data-lx="gift" data-u="${u}">${btnIc.gift}<span>подарок</span></button>`); });
  document.querySelectorAll('.modal .mh h3').forEach(h=>{ if(h.textContent==='Редактировать'){ const mb=h.closest('.modal').querySelector('.mb'); if(mb) lxChanSettings(mb); } });
  const c=cur(); lxViewsLoad(c);
  document.querySelectorAll('#msgs .m[data-id]').forEach(el=>{ const id=+el.dataset.id; if(!(id>0)) return; const b=el.querySelector('.b'); if(!b) return;
    const n=LX.tips.get(id); if(c&&c.type==='channel'){ const old=b.querySelector('.lxrow'); if(old) old.remove(); const vv=LX.views&&LX.views.get(id); b.insertAdjacentHTML('beforeend',`<div class="lxrow"><button class="lxreact" data-lxr="${id}">${gem(15)}${n?`<b>${n}</b>`:''}</button>${vv?`<span class="lxviews" style="display:inline-flex;align-items:center;gap:3px">${ic('eye','mini')}${vShort(vv)}</span>`:''}</div>`); }
    else if(n&&!b.querySelector('.lxtip')) b.insertAdjacentHTML('beforeend',`<div class="lxtip">${gem(14)}${n}</div>`);
    if(!LX.tipAsk.has(id)){ LX.tipAsk.add(id); (LX.tq=LX.tq||[]).push(id); }
    const f=c&&c.type==='channel'&&LX.cfg[c.chat_id]; if(f&&f.linked&&!b.querySelector('.lxcm')){ const k=LX.cmn.get(id)||0; LX.cmIn=LX.cmIn||function(pid){ const n=LX.cmn.get(pid)||0, hs=((LX.hd&&LX.hd.get(pid))||[]).slice(0,3); const a=n%10,b2=n%100, w=a===1&&b2!==11?'комментарий':(a>=2&&a<=4&&(b2<10||b2>=20)?'комментария':'комментариев'); const av=n&&hs.length?`<span class="hs">${hs.map((u,i)=>{ const p=S.profiles.get(u)||{}; return `<span style="position:relative;z-index:${3-i}">${avatar({name:p.name||'?',avatar:p.avatar_url,color:p.color})}</span>`; }).join('')}</span>`:`<span class="ci">${ic('chat')}</span>`; return av+`<span class="t">${n?n+' '+w:'Оставить комментарий'}</span><span class="ar"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m9 6 6 6-6 6"/></svg></span>`; }; b.insertAdjacentHTML('beforeend',`<div class="lxcm" data-lxc="${id}">${LX.cmIn(id)}</div>`); if(!LX.cmnAsk.has(id)){ LX.cmnAsk.add(id); (LX.cq=LX.cq||[]).push(id); } } });
  if(LX.tq&&LX.tq.length){ const ids=LX.tq.splice(0,200); rp('lm_tip_totals',{p_ids:ids}).then(r=>{ let ch=0; (r||[]).forEach(x=>{ if(x.total>0){ LX.tips.set(Number(x.message_id),Number(x.total)); ch=1; } }); if(ch) decorate(); }).catch(()=>{}); }
  if(LX.cq&&LX.cq.length){ const ids=LX.cq.splice(0,200); rp('lm_comment_heads',{p_posts:ids}).catch(()=>rp('lm_comment_counts',{p_posts:ids})).then(async r=>{ LX.hd=LX.hd||new Map(); (r||[]).forEach(x=>{ LX.cmn.set(Number(x.post),Number(x.n)); LX.hd.set(Number(x.post),x.heads||[]); }); try{ await ensureProfiles([].concat(...[...LX.hd.values()])); }catch{} document.querySelectorAll('.lxcm[data-lxc]').forEach(e=>{ if(LX.cmIn) e.innerHTML=LX.cmIn(+e.dataset.lxc); }); }).catch(()=>{}); }
}catch(e){ console.warn('lx',e); } }
/* тарифы Premium совпадают с сервером оплаты */
try{ PM_PLANS.splice(0,PM_PLANS.length,...[{t:'Ежегодно',badge:'\u221258%',sub:'12 месяцев \u00b7 2\u00a0490\u00a0\u20bd',per:'208\u00a0\u20bd/месяц',price:'2\u00a0490\u00a0\u20bd',tail:'на год',m:12},{t:'Полгода',badge:'\u221238%',sub:'6 месяцев \u00b7 1\u00a0490\u00a0\u20bd',per:'249\u00a0\u20bd/месяц',price:'1\u00a0490\u00a0\u20bd',tail:'на полгода',m:6},{t:'Ежемесячно',sub:'',per:'199\u00a0\u20bd/месяц',price:'199\u00a0\u20bd',tail:'в месяц',m:1}]); }catch(e){}
/* ---------- кошелёк v2: как «Звёзды» в Telegram ---------- */
(function(){ const st=document.createElement('style'); st.textContent=`
.ov .modal.lxw2m{width:520px;max-width:calc(100vw - 20px)}
.lxw2{text-align:center;padding-bottom:6px}
.lxw2 h2{margin:0;font-size:26px;font-weight:800}.lxw2 .ds{color:var(--muted);font-size:14.5px;line-height:1.45;margin:6px auto 0;max-width:400px}
.lxw2 .bc{background:var(--panel2);border-radius:22px;padding:16px;margin-top:16px}
.lxw2 .bn{display:flex;align-items:center;justify-content:center;gap:8px;font-size:40px;font-weight:800;line-height:1.1}.lxw2 .bl{color:var(--muted);font-size:14.5px}
.lxw2 .bb{display:flex;gap:10px;margin-top:14px}.lxw2 .bb button{flex:1;height:48px;border-radius:14px;font-weight:800;font-size:15.5px;display:flex;align-items:center;justify-content:center;gap:7px;border:0;cursor:pointer;transition:transform .12s,filter .15s}
.lxw2 .bb button:active{transform:scale(.96)}.lxw2 .bb .p{background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff}.lxw2 .bb .s{background:rgba(124,92,255,.16);color:var(--a1)}.lxw2 .bb .s[disabled]{opacity:.55;cursor:default}
.lxw2 .bb svg{width:18px;height:18px}
.lxw2 .lk{display:inline-flex;align-items:center;gap:6px;margin-top:12px;color:var(--a1);font-weight:700;font-size:15px;cursor:pointer;padding:6px 10px;border-radius:10px}.lxw2 .lk:hover{background:rgba(124,92,255,.1)}.lxw2 .lk svg{width:16px;height:16px}
.lxw2 .pr{display:flex;align-items:center;gap:12px;text-align:left;padding:14px;border-radius:20px;margin-top:12px;background:linear-gradient(135deg,rgba(124,92,255,.28),rgba(255,91,138,.18));border:1px solid rgba(164,139,255,.35)}
.lxw2 .pr .t{flex:1}.lxw2 .pr b{font-size:15.5px}.lxw2 .pr span{display:block;font-size:13px;color:var(--muted)}
.lxw2 .pr button{height:38px;padding:0 14px;border-radius:12px;border:0;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;font-weight:800;cursor:pointer}
.lxw2 .cp{text-align:left;margin:18px 6px 6px;font-size:12px;font-weight:700;color:var(--muted);letter-spacing:.3px}
.lxw2 .cd{background:var(--panel2);border-radius:20px;text-align:left}
.lxw2 .it{display:flex;align-items:center;gap:12px;padding:11px 14px}.lxw2 .it+.it{border-top:1px solid var(--line)}
.lxw2 .ic{width:34px;height:34px;border-radius:10px;display:flex;align-items:center;justify-content:center;flex:none}.lxw2 .ic svg{width:18px;height:18px;fill:#fff}
.lxw2 .it b{display:block;font-size:15px}.lxw2 .it span{display:block;font-size:13px;color:var(--muted)}.lxw2 .it.c{cursor:pointer}
.lxw2 .sg{display:flex;background:var(--panel2);border-radius:999px;padding:3px;margin:18px 0 10px}
.lxw2 .sg button{flex:1;height:34px;border-radius:999px;border:0;background:none;color:var(--muted);font-weight:700;font-size:14px;cursor:pointer;transition:all .2s}.lxw2 .sg button.on{background:var(--panel);color:var(--text);box-shadow:0 1px 4px rgba(0,0,0,.2)}
.lxw2 .op{display:flex;align-items:center;gap:12px;padding:10px 14px;text-align:left}.lxw2 .op+.op{border-top:1px solid var(--line)}
.lxw2 .op .av{width:44px;height:44px;min-width:44px}.lxw2 .op .ki{width:44px;height:44px;border-radius:50%;display:flex;align-items:center;justify-content:center;flex:none}.lxw2 .op .ki svg{width:21px;height:21px;fill:#fff}
.lxw2 .op .t{flex:1;min-width:0}.lxw2 .op b{display:block;font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.lxw2 .op span{display:block;font-size:12.5px;color:var(--muted)}
.lxw2 .am{display:flex;align-items:center;gap:4px;font-weight:800;font-size:16px}.lxw2 .am.p{color:#2bc46f}.lxw2 .am.m{color:#ff4d6a}
.lxw2 .em{color:var(--muted);padding:24px 0}
.lxbuy{text-align:center}.lxbuy .hd{display:flex;justify-content:flex-end}.lxbuy .hd div{text-align:right}.lxbuy .hd span{display:block;font-size:12px;color:var(--muted)}.lxbuy .hd b{display:flex;align-items:center;gap:4px}
.lxbuy h2{margin:0;font-size:23px;font-weight:800}.lxbuy .sb{color:var(--muted);margin:4px 0 14px}
.lxbuy .ls{background:var(--panel2);border-radius:20px;text-align:left;overflow:hidden}
.lxbuy .pk{display:flex;align-items:center;gap:12px;padding:13px 16px;cursor:pointer;transition:background .15s}.lxbuy .pk+.pk{border-top:1px solid var(--line)}.lxbuy .pk:hover{background:rgba(124,92,255,.07)}
.lxbuy .stk{position:relative;width:70px;height:24px;flex:none}.lxbuy .stk span{position:absolute;top:0}
.lxbuy .pk b{flex:1;font-size:16px}.lxbuy .pk i{font-style:normal;color:var(--muted)}
.lxbuy .mr{display:inline-flex;align-items:center;gap:4px;margin-top:12px;color:var(--a1);font-weight:700;cursor:pointer;padding:6px 10px;border-radius:10px}
.lxbuy .cu{display:flex;align-items:center;gap:10px;height:52px;padding:0 16px;border-radius:16px;background:var(--panel2);margin-top:12px}.lxbuy .cu input{flex:1;border:0;outline:0;background:none;color:var(--text);font-weight:700;font-size:16px;min-width:0}.lxbuy .cu i{font-style:normal;color:var(--muted)}
.lxbuy .go{margin-top:10px;width:100%;height:50px;border-radius:16px;border:0;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;font-weight:800;font-size:16px;cursor:pointer}.lxbuy .go[disabled]{opacity:.5}
.lxbuy .nt{display:flex;gap:8px;text-align:left;color:var(--muted);font-size:12.5px;margin-top:14px;line-height:1.45}.lxbuy .nt svg{width:17px;height:17px;flex:none;fill:#2bd67b}
`; document.head.appendChild(st); })();
const W2I={
 plus:'<svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" fill="none"/></svg>',
 spark:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2l1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8z"/></svg>',
 check:'<svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>',
 gift:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M20 7h-2.2A3 3 0 0012 3.8 3 3 0 006.2 7H4a1 1 0 00-1 1v3a1 1 0 001 1h1v8a1 1 0 001 1h12a1 1 0 001-1v-8h1a1 1 0 001-1V8a1 1 0 00-1-1z"/></svg>',
 cal:'<svg viewBox="0 0 24 24"><path d="M7 2v3M17 2v3M3 9h18M5 5h14a2 2 0 012 2v12a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2z" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/></svg>',
 heart:'<svg viewBox="0 0 24 24"><path d="M12 21s-7.5-4.6-9.5-9.3C1.1 8.3 3.3 5 6.6 5c2 0 3.4 1.1 4.4 2.5C12 6.1 13.4 5 15.4 5c3.3 0 5.5 3.3 4.1 6.7C19.5 16.4 12 21 12 21z"/></svg>',
 game:'<svg viewBox="0 0 24 24"><path d="M7 7h10a5 5 0 015 5v1a4 4 0 01-7 2.6l-.6-.6H9.6l-.6.6A4 4 0 012 13v-1a5 5 0 015-5zm0 3v1.5H5.5v1.5H7v1.5h1.5V13H10v-1.5H8.5V10z"/></svg>',
 shield:'<svg viewBox="0 0 24 24"><path d="M12 2l8 3v6c0 5-3.4 9.4-8 11-4.6-1.6-8-6-8-11V5zm-1.2 13.2l5.7-5.7-1.4-1.4-4.3 4.3-2-2-1.4 1.4z"/></svg>',
 card:'<svg viewBox="0 0 24 24"><path d="M3 6a2 2 0 012-2h14a2 2 0 012 2v2H3zm0 4h18v8a2 2 0 01-2 2H5a2 2 0 01-2-2zm3 5v2h5v-2z"/></svg>',
 star:'<svg viewBox="0 0 24 24"><path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z"/></svg>',
 chev:'<svg viewBox="0 0 24 24"><path d="M9 6l6 6-6 6" stroke="currentColor" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>',
};
const W2K={buy:[W2I.card,'#2bd67b','#18a957'],daily:[W2I.cal,'#ffb347','#ff7a3d'],gift_buy:[W2I.gift,'#ff7ab8','#c65cff'],gift_sell:[W2I.gift,'#ff7ab8','#c65cff'],game_win:[W2I.game,'#8a7bff','#5b5cff'],game_stake:[W2I.game,'#8a7bff','#5b5cff'],game_refund:[W2I.game,'#8a7bff','#5b5cff']};
const W2T={buy:'Покупка люменов',daily:'Ежедневный бонус',grant:'Начисление от Lumo',gift_buy:'Покупка подарка',gift_sell:'Продажа подарка',game_win:'Выигрыш в игре',game_stake:'Ставка в игре',game_refund:'Возврат ставки'};
const W2S={tip_in:'Отправил(а) вам люмены',tip_out:'Вы отправили люмены',buy:'Оплата картой'};
async function lxWallet(){
  const close=modal('','<div class="lxw2" id="lxw2"><div class="sub" style="padding:40px 0;color:var(--muted)">Загрузка…</div></div>',[]);
  const ov=[...document.querySelectorAll('.ov')].pop(); ov&&ov.querySelector('.modal').classList.add('lxw2m');
  const el=document.getElementById('lxw2'); let tab=0, W=null, H=[];
  const load=async()=>{ W=await rp('lm_wallet_me'); H=await rp('lm_wallet_history',{p_limit:100}).catch(()=>[]);
    const ids=[...new Set(H.map(h=>h.ref_user).filter(Boolean))].filter(i=>!S.profiles.has(i)); if(ids.length) await profGet(ids).catch(()=>{}); };
  const ops=()=>{ const a=H.filter(h=>tab===1?h.delta>0:tab===2?h.delta<0:true); if(!a.length) return '<div class="em">Операций пока нет</div>';
    return '<div class="cd">'+a.map(h=>{ const u=h.ref_user, p=u&&S.profiles.get(u); let av;
      if(u) av=avatar({name:nm(u),avatar:p&&p.avatar_url,color:p&&p.color});
      else { const k=W2K[h.kind]||[W2I.spark,'#36b8ff','#3a7bff']; av=`<div class="ki" style="background:linear-gradient(135deg,${k[1]},${k[2]})">${k[0]}</div>`; }
      const t=(h.kind==='tip_in'||h.kind==='tip_out')&&u?nm(u):(W2T[h.kind]||'Операция'); const d=new Date(h.created_at);
      return `<div class="op">${av}<div class="t"><b>${esc(t)}</b>${W2S[h.kind]?`<span>${W2S[h.kind]}</span>`:''}<span>${d.toLocaleDateString('ru-RU',{day:'numeric',month:'short',year:'numeric'})}, ${d.toLocaleTimeString('ru-RU',{hour:'2-digit',minute:'2-digit'})}</span></div><div class="am ${h.delta>0?'p':'m'}">${h.delta>0?'+':'−'}${Math.abs(h.delta)}${gem(17)}</div></div>`; }).join('')+'</div>'; };
  const draw=()=>{ const me=S.me||{}; const st=W.streak>0?`Серия ${W.streak} дн. подряд — завтра +${Math.min(3+W.streak,10)}`:'Заходите каждый день — до 10 люменов в день';
    el.innerHTML=`${live(64)}<h2>Люмены Lumo</h2><div class="ds">Покупайте люмены, чтобы дарить подарки, поддерживать авторов и каналы и отправлять их друзьям.</div>
    <div class="bc"><div class="bn">${gem(34)}<span>${Number(W.balance).toLocaleString('ru-RU')}</span></div><div class="bl">Ваш баланс</div>
    <div class="bb"><button class="p" id="w2Buy">${W2I.plus}Пополнить</button><button class="s" id="w2Cl" ${W.can_claim?'':'disabled'}>${W.can_claim?W2I.spark+'Бонус дня':W2I.check+'Бонус получен'}</button></div></div>
    <div class="lk" id="w2Fr">${W2I.gift}Подарить люмены друзьям${W2I.chev}</div>
    <div class="pr"><div class="ic" style="background:linear-gradient(135deg,#a48bff,#6a7bff)">${W2I.star}</div><div class="t"><b>Lumo Premium</b><span>${me.premium?'Подписка активна':'Дополнительные функции на всех устройствах'}</span></div><button id="w2Pr">${me.premium?'Продлить':'Оформить'}</button></div>
    <div class="cp">ЗАРАБОТАТЬ ЛЮМЕНЫ</div><div class="cd">
    <div class="it"><div class="ic" style="background:#ff9a3d">${W2I.cal}</div><div><b>Ежедневный бонус</b><span>${st}</span></div></div>
    <div class="it"><div class="ic" style="background:#ff5e8a">${W2I.heart}</div><div><b>Поддержка от читателей</b><span>Люмены за ваши сообщения и посты в каналах</span></div></div>
    <div class="it"><div class="ic" style="background:#7c5cff">${W2I.game}</div><div><b>Игры с друзьями</b><span>Ставки и выигрыши в играх Lumo</span></div></div>
    <div class="it c" id="w2G"><div class="ic" style="background:#c65cff">${W2I.gift}</div><div><b>Подарки</b><span>Подарки за люмены — дарите и храните в профиле</span></div></div></div>
    <div class="cd" style="margin-top:12px"><div class="it"><div class="ic" style="background:#2bd67b">${W2I.shield}</div><div><b>Оплата работает</b><span>Банковской картой через ЮMoney. Люмены и Premium зачисляются автоматически, обычно за минуту.</span></div></div></div>
    <div class="sg">${['Все операции','Зачисления','Списания'].map((t,i)=>`<button data-tb="${i}" class="${i===tab?'on':''}">${t}</button>`).join('')}</div><div id="w2Ops">${ops()}</div>`;
    el.querySelector('#w2Buy').onclick=()=>lxBuy(W.balance);
    el.querySelector('#w2Cl').onclick=async()=>{ if(!W.can_claim) return; try{ const r=await rp('lm_wallet_daily'); toast('Получено: '+(r&&r.amount||0)+' '+lw(r&&r.amount)); await load(); draw(); }catch(e){ toast(e.message); } };
    el.querySelector('#w2Fr').onclick=()=>lxFriend();
    el.querySelector('#w2Pr').onclick=()=>{ close(); openPremium(); };
    el.querySelector('#w2G').onclick=()=>{ close(); lxGifts(); };
    el.querySelectorAll('[data-tb]').forEach(b=>b.onclick=()=>{ tab=+b.dataset.tb; el.querySelectorAll('[data-tb]').forEach(x=>x.classList.toggle('on',x===b)); el.querySelector('#w2Ops').innerHTML=ops(); });
  };
  const onPaid=async()=>{ if(!document.body.contains(el)) return window.removeEventListener('lumo-paid',onPaid); try{ await load(); draw(); }catch{} };
  window.addEventListener('lumo-paid',onPaid);
  try{ await load(); draw(); }catch(e){ el.innerHTML='<div class="sub">'+esc(e.message)+'</div>'; }
}
function lxBuy(bal){
  const P=[[50,1],[100,2],[250,3],[500,4],[1000,5],[2500,6]], X=[[1500,5],[5000,7]];
  const stk=n=>{ let s=''; for(let i=n-1;i>=0;i--) s+=`<span style="left:${i*7}px">${gem(24)}</span>`; return `<div class="stk">${s}</div>`; };
  const close=modal('','<div class="lxbuy" id="lxbuy"></div>',[]);
  const el=document.getElementById('lxbuy'); let busy=false;
  const pay=n=>{ if(busy) return; busy=true; close(); window.lumoPay.create('lum',n).finally(()=>{ busy=false; }); };
  const draw=more=>{ const L=more?[...P,...X].sort((a,b)=>a[0]-b[0]):P;
    el.innerHTML=`<div class="hd"><div><span>Баланс</span><b>${gem(15)}${Number(bal||0).toLocaleString('ru-RU')}</b></div></div>${live(52)}<h2>Купить люмены</h2><div class="sb">Выберите нужное количество</div>
    <div class="ls">${L.map(([n,g])=>`<div class="pk" data-n="${n}">${stk(g)}<b>${n.toLocaleString('ru-RU')} ${lw(n)}</b><i>${window.lumoPay.rub(n*1.7)}</i></div>`).join('')}</div>
    ${more?`<div class="cu">${gem(24)}<input id="lbC" inputmode="numeric" maxlength="4" placeholder="Своё количество (от 50)"><i id="lbP"></i></div><button class="go" id="lbG" style="display:none"></button>`:'<div class="mr" id="lbM">Показать другие варианты</div>'}
    <div class="nt">${W2I.shield}<div>Оплата банковской картой через ЮMoney. Люмены зачисляются автоматически, обычно за минуту. 1 люмен = 1,7 ₽.</div></div>`;
    el.querySelectorAll('.pk').forEach(p=>p.onclick=()=>pay(+p.dataset.n));
    const m=el.querySelector('#lbM'); if(m) m.onclick=()=>draw(true);
    const c=el.querySelector('#lbC'); if(c){ const g=el.querySelector('#lbG'), pp=el.querySelector('#lbP'); c.focus();
      c.oninput=()=>{ c.value=c.value.replace(/\D/g,'').slice(0,4); const n=+c.value||0, ok=n>=50&&n*1.7<=10000; pp.textContent=n?window.lumoPay.rub(n*1.7):''; g.style.display=n?'block':'none'; g.disabled=!ok; g.textContent=ok?`Купить ${n} ${lw(n)} за ${window.lumoPay.rub(n*1.7)}`:(n<50?'Минимум 50 люменов':'Не больше 10 000 ₽ за раз'); };
      g.onclick=()=>{ const n=+c.value||0; if(n>=50&&n*1.7<=10000) pay(n); }; c.onkeydown=e=>{ if(e.key==='Enter') g.click(); }; } };
  draw(false);
}
function lxFriend(){
  const L=(S.chats||[]).filter(c=>c.type==='private'&&c.peer_id&&c.peer_id!==S.me.id&&!c.peer_bot);
  const close=modal('Кому отправить люмены',`<input id="lfQ" placeholder="Поиск" style="width:100%;margin-bottom:8px"><div id="lfL" style="max-height:55vh;overflow:auto;text-align:left"></div>`,[]);
  const q=document.getElementById('lfQ'), l=document.getElementById('lfL');
  const draw=()=>{ const s=q.value.trim().toLowerCase(); const a=L.filter(c=>!s||chatName(c).toLowerCase().includes(s));
    l.innerHTML=a.length?a.map(c=>`<div data-fu="${esc(c.peer_id)}" style="display:flex;align-items:center;gap:12px;padding:8px 4px;cursor:pointer;border-radius:12px">${avatar({name:chatName(c),avatar:c.peer_avatar,color:c.peer_color})}<b>${esc(chatName(c))}</b></div>`).join(''):'<div style="color:var(--muted);padding:20px;text-align:center">Никого не найдено</div>'; };
  q.oninput=draw; draw(); q.focus();
  l.onclick=e=>{ const r=e.target.closest('[data-fu]'); if(!r) return; close(); lxSend(r.dataset.fu); };
}

new MutationObserver(decorate).observe(document.body,{childList:true,subtree:true});
decorate();
})();
;(function(){
const H='<!doctype html><meta charset=utf-8><style>html,body{margin:0;background:transparent;overflow:hidden}svg{display:block;width:100%;height:100%}</style>';
window.art=(id,st)=>`<iframe class="lxif" scrolling="no" tabindex="-1" style="${st||''}" srcdoc="${esc(H+LXA.svg(id))}"></iframe>`;
const s=document.createElement('style'); s.textContent='.lxif{border:0;pointer-events:none;display:block;background:transparent}.lxg .lxif{width:100%;aspect-ratio:1;border-radius:16px}.lxcard .lxif{width:150px;height:150px;border-radius:20px;margin:0 auto}'; document.head.appendChild(s);
const conv=()=>{ document.querySelectorAll('img[src^="data:image/svg+xml"]').forEach(im=>{ try{ const f=document.createElement('iframe'); f.className='lxif'; f.setAttribute('scrolling','no'); f.tabIndex=-1; f.setAttribute('style',im.getAttribute('style')||''); f.srcdoc=H+decodeURIComponent(im.src.slice(im.src.indexOf(',')+1)); if(im.style.width) f.style.aspectRatio='1'; im.replaceWith(f); }catch(e){} }); };
new MutationObserver(conv).observe(document.body,{childList:true,subtree:true}); conv();
})();

;(function(){ const s=document.createElement('style'); s.textContent='.modal .lxif{margin-left:auto;margin-right:auto}'; document.head.appendChild(s); })();

;(function(){
let box=null; const close=()=>{ if(box){ box.remove(); box=null; } };
const st=document.createElement('style'); st.textContent=`#lxprof{position:fixed;inset:0;z-index:99000;background:var(--bg);color:var(--text);overflow:auto;-webkit-overflow-scrolling:touch}
#lxprof .pw{max-width:560px;margin:0 auto;padding:max(12px,env(safe-area-inset-top)) 14px 40px}
#lxprof .bar{display:flex;justify-content:space-between;align-items:center;height:56px}
#lxprof .rb{min-width:44px;height:44px;border-radius:22px;background:var(--panel2);border:1px solid var(--line);color:var(--text);display:grid;place-items:center;font-weight:700;padding:0 16px;font-size:16px}
#lxprof .rb.sq{padding:0;width:44px}#lxprof .rb svg{width:22px;height:22px}
#lxprof .hero{text-align:center;margin:-4px 0 18px}#lxprof .hero .av{margin:0 auto;width:112px;height:112px;font-size:40px}
#lxprof h1{font-size:28px;margin:12px 0 2px;font-weight:800}#lxprof .stt{color:var(--muted)}
#lxprof .card{background:var(--panel);border-radius:22px;padding:4px 18px}
#lxprof .row{padding:12px 0;border-top:1px solid var(--line);display:flex;justify-content:space-between;align-items:center;gap:10px}#lxprof .row:first-child{border-top:0}
#lxprof .k{font-size:13px;color:var(--muted)}#lxprof .v{font-size:17px;word-break:break-word}#lxprof .v.a{color:var(--a1)}
#lxprof .tabs{display:flex;gap:4px;background:var(--panel);border-radius:22px;padding:4px;margin:18px 0 12px}
#lxprof .tabs button{flex:1;padding:10px 6px;border-radius:18px;font-weight:700;color:var(--muted)}#lxprof .tabs button.on{background:var(--panel2);color:var(--text)}
#lxprof .gr{display:grid;grid-template-columns:repeat(3,1fr);gap:3px;border-radius:14px;overflow:hidden}
#lxprof .gr .t{position:relative;aspect-ratio:3/4;background:var(--panel2);overflow:hidden;cursor:pointer}#lxprof .gr .t img,#lxprof .gr .t video{width:100%;height:100%;object-fit:cover;display:block}
#lxprof .gr .t span{position:absolute;left:6px;bottom:5px;font-size:11px;font-weight:700;color:#fff;text-shadow:0 1px 3px #000}
#lxprof .gg{display:grid;grid-template-columns:repeat(2,1fr);gap:10px}#lxprof .gg .g{background:var(--panel);border-radius:18px;padding:8px;text-align:center;cursor:pointer}#lxprof .gg .g .lxif{width:100%;aspect-ratio:1;border-radius:14px}#lxprof .gg b{display:block;margin-top:6px;font-size:13px}
#lxprof .em{color:var(--muted);text-align:center;padding:34px 10px}`;
document.head.appendChild(st);
const fmtPh=p=>{ const d=String(p||'').replace(/\D/g,''); return d.length===11?`+${d[0]} ${d.slice(1,4)} ${d.slice(4,7)} ${d.slice(7)}`:(d?'+'+d:''); };
async function open(){
  close(); const me=S.me; if(!me) return;
  box=document.createElement('div'); box.id='lxprof';
  const bd=me.birthday?String(me.birthday).slice(0,10):'';
  box.innerHTML=`<div class="pw"><div class="bar"><button class="rb sq" id="lpB">${ic('back')}</button><button class="rb" id="lpE">Изм.</button></div>
  <div class="hero">${avatar({name:me.name,avatar:me.avatar_url,color:me.color},'l')}<h1>${esc(me.name)}${pMark(me)}</h1><div class="stt">в сети</div></div>
  <div class="card"><div class="row" id="lpPhR" style="display:none"><div><div class="k">мобильный</div><div class="v a" id="lpPh"></div></div></div>
  <div class="row"><div><div class="k">имя пользователя</div><div class="v a">@${esc(me.username)}</div></div><button class="rb sq" id="lpQ" style="background:none;border:0;color:var(--a1)">${ic('qr')}</button></div>
  ${bd?`<div class="row"><div><div class="k">день рождения</div><div class="v">${esc(bdText(bd,1))}</div></div></div>`:''}
  ${me.bio?`<div class="row"><div><div class="k">о себе</div><div class="v">${esc(me.bio)}</div></div></div>`:''}</div>
  <div class="tabs"><button class="on" data-t="p">Публикации</button><button data-t="g">Подарки</button></div><div id="lpC"><div class="em">Загрузка…</div></div></div>`;
  document.body.appendChild(box); if(window.tgDecor) window.tgDecor(box.querySelector('.hero'),S.me,true);
  document.getElementById('lpB').onclick=close;
  document.getElementById('lpE').onclick=()=>{ close(); setSPage('profile'); };
  document.getElementById('lpQ').onclick=()=>showMyQr();
  sb.rpc('lm_my_phone').then(({data})=>{ const p=data&&data.phone; if(p&&box){ document.getElementById('lpPh').textContent=fmtPh(p); document.getElementById('lpPhR').style.display=''; } },()=>{});
  const C=document.getElementById('lpC'); let pubs=null,gifts=null;
  const show=async t=>{ box.querySelectorAll('.tabs button').forEach(b=>b.classList.toggle('on',b.dataset.t===t));
    if(t==='p'&&window.tgPosts){ window.tgPosts(C,S.me.id); return; }
    if(t==='p'){ if(!pubs){ const {data}=await sb.rpc('lm_my_stories'); pubs=data||[]; }
      C.innerHTML=pubs.length?`<div class="gr">${pubs.map((s,i)=>`<div class="t" data-i="${i}">${s.kind==='video'?`<video src="${esc(pxu(s.media_url))}#t=0.1" preload="metadata" playsinline muted></video>`:`<img src="${esc(pxu(s.media_url))}" loading="lazy" alt="">`}<span>${new Date(s.created_at).toLocaleDateString('ru-RU',{day:'numeric',month:'short'})}</span></div>`).join('')}</div>`:'<div class="em">Опубликованных историй пока нет</div>';
      C.querySelectorAll('[data-i]').forEach(el=>el.onclick=()=>{ const s=pubs[+el.dataset.i]; modal(s.caption?esc(s.caption):'История',`<div style="text-align:center">${s.kind==='video'?`<video src="${esc(pxu(s.media_url))}" controls playsinline autoplay style="max-width:100%;max-height:70vh;border-radius:16px"></video>`:`<img src="${esc(pxu(s.media_url))}" style="max-width:100%;max-height:70vh;border-radius:16px">`}</div>`,[['Закрыть','ghost']]); }); }
    else { if(!gifts){ const {data}=await sb.rpc('lm_gift_mine',{}); gifts=data||[]; }
      C.innerHTML=gifts.length?`<div class="gg">${gifts.map((o,i)=>`<div class="g" data-i="${i}">${window.art(o.gift_id,'')}<b>${esc(o.name)} №${o.serial}</b></div>`).join('')}</div>`:'<div class="em">Подарков пока нет. Их можно купить за люмены в разделе «Подарки».</div>';
      C.querySelectorAll('[data-i]').forEach(el=>el.onclick=()=>{ const o=gifts[+el.dataset.i]; modal(esc(o.name),`<div style="text-align:center">${window.art(o.gift_id,'width:100%;max-width:320px;aspect-ratio:1;border-radius:24px;margin:0 auto')}<div style="font-weight:800;font-size:20px;margin-top:8px">№${o.serial} из ${o.supply}</div></div>`,[['Закрыть','ghost']]); }); } };
  box.querySelectorAll('.tabs button').forEach(b=>b.onclick=()=>show(b.dataset.t)); show('p');
}
window.lxMyProfile=open;
document.addEventListener('click',e=>{ const r=e.target.closest&&e.target.closest('#sProf'); if(r){ e.stopImmediatePropagation(); e.preventDefault(); open(); } },true);
})();

;(function(){
const st=document.createElement('style'); st.textContent=`.lxsh{position:fixed;inset:0;z-index:99600;background:rgba(5,6,20,.55);backdrop-filter:blur(6px);display:flex;align-items:flex-end;justify-content:center;animation:fade .15s}
.lxsh .sh{width:100%;max-width:520px;background:var(--panel);color:var(--text);border-radius:30px 30px 0 0;padding:16px 18px max(18px,env(safe-area-inset-bottom));text-align:center;position:relative;max-height:92vh;overflow:auto}
.lxsh .x{position:absolute;left:14px;top:14px;width:42px;height:42px;border-radius:50%;background:var(--panel2);border:1px solid var(--line);color:var(--text);display:grid;place-items:center}.lxsh .x svg{width:20px;height:20px}
.lxsh .lxif{width:230px;height:230px;border-radius:26px;margin:18px auto 6px}.lxsh h2{margin:8px 0 6px;font-size:24px}.lxsh .d{color:var(--muted);font-size:15px;margin:0 8px 14px}
.lxsh .tb{border:1px solid var(--line);border-radius:18px;overflow:hidden;text-align:left;margin:0 0 14px}.lxsh .tr{display:flex;border-top:1px solid var(--line)}.lxsh .tr:first-child{border-top:0}
.lxsh .tr .l{width:34%;background:var(--panel2);padding:13px 14px;font-weight:600}.lxsh .tr .r{flex:1;padding:13px 14px;display:flex;align-items:center;gap:8px;min-width:0}.lxsh .tr .r .av{width:30px;height:30px;font-size:12px;flex:none}.lxsh .tr .r a{color:var(--a1);font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.lxsh .ok{display:block;width:100%;height:54px;border-radius:20px;background:var(--accent);color:#fff;font-weight:800;font-size:17px}`;
document.head.appendChild(st);
const RR={rare:['Редкий','#22c7e0'],epic:['Эпический','#ff8a3d'],legendary:['Легендарный','#b069ff'],mythic:['Мифический','#ffc247'],ultra:['Божественный','#ff2ec4']};
async function sheet(o){
  let price=null; try{ const {data}=await sb.rpc('lm_gift_list'); const g=(data||[]).find(x=>x.id===o.gift_id); if(g) price=g.price; }catch(e){}
  let from=null; if(o.from_user){ if(!S.profiles.get(o.from_user)) await profGet([o.from_user]).catch(()=>{}); from=S.profiles.get(o.from_user); }
  const r=RR[o.rarity]||['','#888']; const d=o.at?new Date(o.at):null;
  const w=document.createElement('div'); w.className='lxsh';
  w.innerHTML=`<div class="sh"><button class="x">${ic('x')}</button>${window.art(o.gift_id,'')}<h2>${from?'Подарок Вам':'Ваш подарок'}</h2>
  <div class="d">${esc(o.name)} №${o.serial} из ${o.supply} · <b style="color:${r[1]}">${r[0]}</b><br>Подарок хранится в вашем профиле.</div>
  <div class="tb"><div class="tr"><div class="l">От</div><div class="r">${from?`${avatar({name:from.name,avatar:from.avatar_url,color:from.color},'xs')}<a>${esc(from.name)}</a>`:'Вы'}</div></div>
  <div class="tr"><div class="l">Дата</div><div class="r">${d?esc(d.toLocaleDateString('ru-RU')+' в '+d.toLocaleTimeString('ru-RU',{hour:'2-digit',minute:'2-digit'})):'—'}</div></div>
  <div class="tr"><div class="l">Стоимость</div><div class="r">${price!=null?price+' <svg width="18" height="18" viewBox="0 0 64 64"><polygon points="32,3 57,17 57,47 32,61 7,47 7,17" fill="#ff9a3d"/><polygon points="32,3 57,17 32,32 7,17" fill="#fff" opacity=".4"/></svg> '+esc(plural(price,'люмен','люмена','люменов')):'—'}</div></div></div>
  <button class="ok">OK</button></div>`;
  const cl=()=>w.remove(); w.onclick=e=>{ if(e.target===w) cl(); };
  w.querySelector('.x').onclick=cl; w.querySelector('.ok').onclick=cl; document.body.appendChild(w);
}
document.addEventListener('click',async e=>{
  const g=e.target.closest&&e.target.closest('#lxprof .gg .g'); const s=e.target.closest&&e.target.closest('#lxg [data-o]');
  if(!g&&!s) return; e.stopImmediatePropagation(); e.preventDefault();
  try{ const {data}=await sb.rpc('lm_gift_mine',{}); const L=data||[]; const o=g?L[+g.dataset.i]:L.find(x=>String(x.id)===s.dataset.o); if(o) sheet(o); }catch(er){}
},true);
})();



;(function(){
const COL={pearl:'#35d6e8',comet:'#ff8a3d',crystal:'#7d8dff',key:'#ffc247',flower:'#c066ff'};
const st=document.createElement('style'); st.textContent=`.lxcel{display:none!important}.lxmg{position:fixed;inset:0;z-index:99800;overflow:hidden;background:radial-gradient(circle at 50% 40%,color-mix(in srgb,var(--c) 22%,#070816),#03040b 75%);animation:lxmgi .4s ease-out both;touch-action:none;user-select:none;-webkit-user-select:none}
.lxmg.out{animation:lxmgo .5s ease-in forwards}@keyframes lxmgi{from{opacity:0}to{opacity:1}}@keyframes lxmgo{to{opacity:0;transform:scale(1.04)}}
.lxmg canvas{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}
.lxmg .ry{position:absolute;left:50%;top:var(--cy);width:170vmax;height:170vmax;margin:-85vmax;opacity:0;background:repeating-conic-gradient(from 0deg,color-mix(in srgb,var(--c) 45%,transparent) 0 5deg,transparent 5deg 15deg);-webkit-mask-image:radial-gradient(circle,#000 0,transparent 52%);mask-image:radial-gradient(circle,#000 0,transparent 52%);animation:lxspin 26s linear infinite}
.lxmg.b .ry{opacity:.85;transition:opacity 1.4s ease-out}@keyframes lxspin{to{transform:rotate(360deg)}}
.lxmg .fl{position:absolute;inset:0;background:#fff;opacity:0;pointer-events:none}.lxmg.b .fl{animation:lxflash .9s ease-out both}@keyframes lxflash{0%{opacity:.95}100%{opacity:0}}
.lxmg .gf{position:absolute;left:50%;top:var(--cy);width:var(--sz);height:var(--sz);margin:calc(var(--sz)/-2) 0 0 calc(var(--sz)/-2);perspective:900px;opacity:0;transform:scale(.2)}
.lxmg.b .gf{animation:lxflip 1.15s cubic-bezier(.2,1.25,.35,1) both}
@keyframes lxflip{0%{opacity:0;transform:scale(.15) rotateY(-200deg)}35%{opacity:1}100%{opacity:1;transform:scale(1) rotateY(0)}}
.lxmg .fy{position:relative;width:100%;height:100%;border-radius:32px;overflow:hidden;transform-style:preserve-3d;transition:transform .25s ease-out;box-shadow:0 0 90px color-mix(in srgb,var(--c) 75%,transparent),0 30px 80px rgba(0,0,0,.6);animation:lxfloat 4.2s ease-in-out infinite 1.3s}
@keyframes lxfloat{0%,100%{translate:0 6px}50%{translate:0 -10px}}
.lxmg .fy .lxif{width:100%;height:100%;display:block;border-radius:0}
.lxmg .fy::after{content:"";position:absolute;inset:-20%;background:linear-gradient(105deg,transparent 40%,rgba(255,255,255,.55) 50%,transparent 60%);transform:translateX(-120%);animation:lxsh 3.8s ease-in-out infinite 1.8s;pointer-events:none}
@keyframes lxsh{0%{transform:translateX(-120%)}35%,100%{transform:translateX(120%)}}
.lxmg .gf.fly{transition:transform 1.05s cubic-bezier(.55,0,.85,.4),opacity .25s ease-in .85s;transform:translateY(calc(var(--cy) * -1 + 40px)) scale(.1) rotate(18deg)!important;opacity:0!important;animation:none!important}
.lxmg .tx{position:absolute;left:0;right:0;top:calc(var(--cy) + var(--sz)/2 + 30px);text-align:center;color:#fff;padding:0 22px}
.lxmg h2{margin:0 0 8px;font-size:30px;font-weight:800;letter-spacing:.01em;text-shadow:0 0 24px color-mix(in srgb,var(--c) 80%,transparent)}
.lxmg h2 span{display:inline-block;opacity:0;filter:blur(12px);transform:translateY(14px) scale(1.3);animation:lxlt .7s ease-out forwards}
@keyframes lxlt{to{opacity:1;filter:none;transform:none}}
.lxmg p{margin:0;font-size:16px;opacity:0;animation:lxfd .8s ease-out forwards 1.9s}.lxmg .sr{display:inline-block;margin-top:14px;padding:7px 18px;border-radius:18px;background:rgba(255,255,255,.12);border:1px solid color-mix(in srgb,var(--c) 70%,#fff);font-weight:700;opacity:0;animation:lxfd .8s ease-out forwards 2.2s}
@keyframes lxfd{to{opacity:.92}}.lxmg .sr{--o:1}
.lxmg .tp{position:absolute;bottom:max(24px,env(safe-area-inset-bottom));left:0;right:0;text-align:center;font-size:13px;color:rgba(255,255,255,.5);opacity:0;animation:lxfd .8s ease-out forwards 2.8s}`;
document.head.appendChild(st);
const rgb=h=>{ const n=parseInt(h.slice(1),16); return (n>>16&255)+','+(n>>8&255)+','+(n&255); };
const glow=col=>{ const c=document.createElement('canvas'); c.width=c.height=64; const g=c.getContext('2d'),r=g.createRadialGradient(32,32,0,32,32,32); r.addColorStop(0,'rgba(255,255,255,1)'); r.addColorStop(.22,`rgba(${col},.9)`); r.addColorStop(1,`rgba(${col},0)`); g.fillStyle=r; g.fillRect(0,0,64,64); return c; };
const starS=col=>{ const c=document.createElement('canvas'); c.width=c.height=64; const g=c.getContext('2d'); const r=g.createRadialGradient(32,32,0,32,32,30); r.addColorStop(0,'rgba(255,255,255,.95)'); r.addColorStop(.3,`rgba(${col},.5)`); r.addColorStop(1,`rgba(${col},0)`); g.fillStyle=r; g.beginPath(); for(let i=0;i<8;i++){ const a=i*Math.PI/4-Math.PI/2, d=i%2?4:30; g.lineTo(32+Math.cos(a)*d,32+Math.sin(a)*d); } g.closePath(); g.fill(); return c; };

function celebrate(a,res){
  const id=a&&a.p_gift; if(!id) return; const to=a.p_to; const hex=COL[id]||'#ffc247', col=rgb(hex);
  const W=innerWidth,H=innerHeight, sz=Math.round(Math.min(W*.58,250)), cx=W/2, cy=Math.round(H*.37);
  const w=document.createElement('div'); w.className='lxmg'; w.style.setProperty('--c',hex); w.style.setProperty('--cy',cy+'px'); w.style.setProperty('--sz',sz+'px');
  const name=res&&res.name||'Подарок'; const title=to?'Подарок отправлен!':'Подарок ваш!';
  w.innerHTML=`<div class="ry"></div><canvas></canvas><div class="gf"><div class="fy">${window.art(id,'')}</div></div><div class="fl"></div>
  <div class="tx"><h2>${[...title].map((ch,i)=>`<span style="animation-delay:${1.25+i*.045}s">${ch===' '?'&nbsp;':ch}</span>`).join('')}</h2><p>${to?esc(profName(to))+' получит «'+esc(name)+'»':'«'+esc(name)+'» теперь в вашем профиле'}</p>${res&&res.serial?`<div class="sr">№${res.serial} из ${res.supply}</div>`:''}</div><div class="tp">нажмите, чтобы закрыть</div>`;
  document.body.appendChild(w);
  const cv=w.querySelector('canvas'), dpr=Math.min(2,devicePixelRatio||1); cv.width=W*dpr; cv.height=H*dpr; const g=cv.getContext('2d'); g.scale(dpr,dpr);
  const SG=glow(col), SS=starS(col), SW=glow('255,255,255'), SW2=starS('255,255,255'), SY=glow('255,224,138');
  const ps=[], rings=[]; let t0=performance.now(), last=t0, alive=true, burst=false, flown=false, fin=false;
  const gf=w.querySelector('.gf'), fy=w.querySelector('.fy');
  const R=(a,b)=>a+Math.random()*(b-a);
  const free=(x,y,sp,ang,life,sz,spr,o)=>ps.push(Object.assign({k:'f',x,y,vx:Math.cos(ang)*sp,vy:Math.sin(ang)*sp,life,max:life,sz,spr,ay:0,drag:1.2,rot:R(0,6),vr:R(-3,3)},o||{}));
  const shock=(x,y,maxR,lw)=>rings.push({x,y,r:6,maxR,t:0,lw});
  const doBurst=(x,y,n)=>{ for(let i=0;i<n;i++){ const sp=R(120,900); free(x,y,sp,R(0,6.283),R(.8,2.2),R(10,26),[SG,SW,SY][i%3],{drag:2}); }
    for(let i=0;i<Math.round(n*.3);i++) free(x,y,R(60,420),R(0,6.283),R(1.4,3),R(14,30),i%2?SS:SW2,{drag:1.1,ay:-20}); };
  function frame(now){ if(!alive) return; const dt=Math.min(.05,(now-last)/1000); last=now; const t=(now-t0)/1000;
    g.clearRect(0,0,W,H); g.globalCompositeOperation='lighter';
    if(t<1){ const k=t; for(let i=0;i<7;i++){ const r=R(260,Math.max(W,H)*.7); ps.push({k:'i',r,th:R(0,6.283),sp:R(380,620),w:R(1.2,2.4),sz:R(8,20),spr:[SG,SW,SS][i%3],life:9,max:9}); }
      const orb=24+k*k*110; g.globalAlpha=.35+.65*k; g.drawImage(SW,cx-orb,cy-orb,orb*2,orb*2); g.globalAlpha=.8*k; g.drawImage(SG,cx-orb*2,cy-orb*2,orb*4,orb*4); }
    if(t>=1&&!burst){ burst=true; w.classList.add('b'); doBurst(cx,cy,170); shock(cx,cy,Math.max(W,H)*.9,10); setTimeout(()=>shock(cx,cy,Math.max(W,H)*.6,5),160);
      for(let i=0;i<34;i++){ const an=R(0,6.283), sp=R(200,700); ps.push({k:'c',x:cx,y:cy,vx:Math.cos(an)*sp,vy:Math.sin(an)*sp-250,life:R(2.4,3.8),max:3.8,w:R(6,11),h:R(10,17),rot:R(0,6),vr:R(-9,9),c:['#ffe08a','#ff5e8a','#7c5cff','#22c1ff','#ffffff',hex][i%6]}); }
      for(let i=0;i<16;i++) ps.push({k:'o',a:R(0,6.283),rx:sz*R(.62,.85),ry:sz*R(.5,.9),wv:R(.7,1.6)*(i%2?1:-1),sz:R(10,22),spr:i%3?SW2:SG,life:99,max:99,ph:R(0,6)});
      try{ w.animate([{transform:'translate(0,0)'},{transform:'translate(-7px,5px)'},{transform:'translate(6px,-6px)'},{transform:'translate(-4px,-3px)'},{transform:'translate(0,0)'}],{duration:420}); }catch(e){} }
    if(burst){ if(Math.random()<dt*28) free(R(0,W),H+10,R(40,120),-Math.PI/2+R(-.4,.4),R(3,5),R(8,18),Math.random()<.5?SG:SY,{drag:0,ay:-8}); }
    if(to&&t>3.3&&!flown){ flown=true; gf.classList.add('fly'); }
    if(flown&&!fin){ const r=gf.getBoundingClientRect(), px=r.left+r.width/2, py=r.top+r.height/2; for(let i=0;i<5;i++) free(px+R(-12,12),py+R(-12,12),R(20,90),R(0,6.283),R(.5,1.1),R(10,26),[SG,SW,SY][i%3],{drag:2});
      if(t>4.3){ fin=true; doBurst(cx,50,110); shock(cx,50,Math.max(W,H)*.7,6); } }
    for(let i=ps.length-1;i>=0;i--){ const p=ps[i];
      if(p.k==='i'){ p.r-=p.sp*dt*(1+ (1-p.r/900)); p.th+=p.w*dt; if(p.r<14||t>1.02){ ps.splice(i,1); continue; } const x=cx+Math.cos(p.th)*p.r, y=cy+Math.sin(p.th)*p.r; const f=1-p.r/700; g.globalAlpha=Math.max(0,Math.min(1,f+.2)); const s=p.sz*(.5+f*.6); g.drawImage(p.spr,x-s/2,y-s/2,s,s); }
      else if(p.k==='o'){ p.a+=p.wv*dt; const x=cx+Math.cos(p.a)*p.rx, y=cy+Math.sin(p.a)*p.ry*.55; const tw=.55+.45*Math.sin(t*5+p.ph); g.globalAlpha=tw; g.drawImage(p.spr,x-p.sz/2,y-p.sz/2,p.sz,p.sz); if(Math.random()<dt*10) free(x,y,R(5,25),R(0,6.283),R(.6,1.1),p.sz*.5,SG,{drag:2}); if(flown){ p.rx*=1-dt*1.5; p.ry*=1-dt*1.5; } }
      else if(p.k==='c'){ p.life-=dt; if(p.life<=0){ ps.splice(i,1); continue; } p.vy+=900*dt; p.vx*=1-.8*dt; p.x+=p.vx*dt; p.y+=p.vy*dt; p.rot+=p.vr*dt; g.globalCompositeOperation='source-over'; g.globalAlpha=Math.min(1,p.life/1.2); g.save(); g.translate(p.x,p.y); g.rotate(p.rot); g.scale(1,Math.abs(Math.cos(p.rot*1.7))+.15); g.fillStyle=p.c; g.fillRect(-p.w/2,-p.h/2,p.w,p.h); g.restore(); g.globalCompositeOperation='lighter'; }
      else { p.life-=dt; if(p.life<=0){ ps.splice(i,1); continue; } p.vx*=1-p.drag*dt; p.vy=p.vy*(1-p.drag*dt)+p.ay*dt; p.x+=p.vx*dt; p.y+=p.vy*dt; const f=p.life/p.max; g.globalAlpha=Math.min(1,f*1.6); const s=p.sz*(.4+.6*f); g.drawImage(p.spr,p.x-s/2,p.y-s/2,s,s); } }
    g.globalAlpha=1; for(let i=rings.length-1;i>=0;i--){ const q=rings[i]; q.t+=dt; const k=Math.min(1,q.t/1.1); q.r=q.maxR*(1-Math.pow(1-k,3)); if(k>=1){ rings.splice(i,1); continue; } g.globalAlpha=(1-k)*.85; g.lineWidth=q.lw*(1-k)+1; g.strokeStyle=`rgba(${col},1)`; g.beginPath(); g.arc(q.x,q.y,q.r,0,6.283); g.stroke(); g.globalAlpha=(1-k)*.4; g.lineWidth=q.lw*2.4*(1-k); g.strokeStyle='rgba(255,255,255,1)'; g.stroke(); }
    if(ps.length>900) ps.splice(0,ps.length-900);
    requestAnimationFrame(frame); }
  requestAnimationFrame(frame);
  w.addEventListener('pointermove',e=>{ const dx=(e.clientX/W-.5), dy=(e.clientY/H-.5); fy.style.transform=`rotateY(${dx*14}deg) rotateX(${-dy*14}deg)`; });
  let done=false; const end=()=>{ if(done) return; done=true; w.classList.add('out'); setTimeout(()=>{ alive=false; w.remove(); },520); };
  w.onclick=end; setTimeout(end,to?6200:6000);
}
const hook=()=>{ try{ if(!sb||sb.__lxmg) return; const orig=sb.rpc.bind(sb); sb.rpc=function(n,a){ if(n!=='lm_gift_buy') return orig(n,a); const p=Promise.resolve(orig(n,a)); p.then(r=>{ if(r&&!r.error&&r.data) celebrate(a,r.data); },()=>{}); return p; }; sb.__lxmg=1; }catch(e){} };
setInterval(hook,1000); hook();
window.lxCelebrate=celebrate;
})();

;(function(){
const s=document.createElement('style'); s.textContent='.lxmg{contain:paint;max-width:none!important}'; document.head.appendChild(s);
const fit=w=>{ try{ const vv=window.visualViewport; const W=Math.max(innerWidth,document.documentElement.clientWidth||0,vv?Math.round(vv.width):0), H=Math.max(innerHeight,vv?Math.round(vv.height):0); w.style.left='0'; w.style.top='0'; w.style.right='auto'; w.style.bottom='auto'; w.style.width=W+'px'; w.style.height=H+'px'; }catch(e){} };
new MutationObserver(ms=>{ ms.forEach(m=>m.addedNodes.forEach(n=>{ if(n.nodeType===1&&n.classList&&n.classList.contains('lxmg')) fit(n); })); }).observe(document.body,{childList:true});
})();


;(function(){
const st0=document.createElement('style'); st0.textContent=`.wzw,.wza{position:fixed;inset:0;z-index:99450;background:var(--bg);display:flex;flex-direction:column;overflow:auto}
.wza{background:rgba(0,0,0,.45);align-items:center;justify-content:flex-end;overflow:hidden}
.wza .sh{background:var(--bg);width:min(560px,100%);height:min(86vh,720px);border-radius:26px 26px 0 0;display:flex;flex-direction:column;position:relative;overflow:hidden}
.wzwh{display:flex;align-items:center;justify-content:space-between;padding:12px 14px;position:relative}
.wzwh b{position:absolute;left:0;right:0;text-align:center;font-size:17px;pointer-events:none}
.wzwh .ib,.wzwh .wznx{background:var(--panel);border:0;color:var(--text);border-radius:23px;min-width:44px;height:44px;cursor:pointer;display:grid;place-items:center;position:relative;z-index:1;font:inherit}
.wzwh .wznx{padding:0 18px;color:var(--a1);font-weight:600;font-size:16px}.wzwh .wznx[disabled]{color:var(--muted);cursor:default}
.wzc{background:var(--panel);border-radius:26px;margin:0 14px}.wzc.p{padding:16px 18px}
.wzh{color:var(--muted);font-size:14px;padding:6px 28px}.wzt{color:var(--muted);font-size:12px;font-weight:700;letter-spacing:.04em;padding:14px 28px 4px;text-transform:uppercase}
.wzin{width:100%;background:transparent;border:0;outline:0;color:var(--text);font:inherit;font-size:19px;resize:none}
.wzrow{display:flex;align-items:center;gap:12px;padding:16px 18px;cursor:pointer;font-size:19px}.wzrow+.wzrow{border-top:1px solid var(--line)}
.wzrow i{width:26px;color:var(--a1);font-style:normal;font-weight:700}
.wzbtn{display:flex;align-items:center;justify-content:center;height:54px;border-radius:27px;background:var(--accent);color:#fff;font-weight:700;font-size:17px;border:0;cursor:pointer;margin:12px 14px;width:calc(100% - 28px)}
.wzbtn[disabled]{opacity:.6}.wzbtn.sm{margin:10px 0 0;width:100%;height:48px}
.wzlink{display:flex;align-items:center;gap:8px;background:var(--bg);border-radius:26px;padding:10px 12px 10px 18px;font-size:17px}.wzlink span{flex:1;text-align:center;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.wzlink button{background:var(--panel2);border:0;color:var(--text);border-radius:16px;padding:6px 10px;cursor:pointer;font-size:13px}
.wzsw{display:flex;align-items:center;justify-content:space-between;padding:14px 18px;font-size:18px}.wzsw input{width:22px;height:22px;accent-color:var(--a1)}
.wzav{width:76px;height:76px;border-radius:50%;background:rgba(124,92,255,.14);display:grid;place-items:center;cursor:pointer;overflow:hidden;flex:none;color:var(--a1);font-size:28px}.wzav img{width:100%;height:100%;object-fit:cover}
.wzart{position:relative;width:260px;height:250px;margin:0 auto}.wzart .ph1{position:absolute;left:55px;top:10px;width:150px;height:230px;border-radius:30px;background:#b9d8f6;border:5px solid #3b4a5c}
.wzart .dk{position:absolute;left:88px;top:120px;color:#3b4a5c}.wzart .dk svg{width:84px;height:84px;stroke-width:1.6}.wzart .c1,.wzart .c2{position:absolute;border-radius:50%;background:#cfe4f8;border:3px solid #fff;display:flex;flex-direction:column;align-items:center;justify-content:center;color:#5b6b7d;font-size:12px}
.wzart .c1{left:-10px;top:20px;width:98px;height:98px}.wzart .c1 b{font-size:18px;color:#1d2733}.wzart .c2{right:-6px;top:112px;width:96px;height:96px}
.wzpick{display:flex;align-items:center;gap:12px;padding:8px 16px;cursor:pointer}.wzpick .sel{margin-left:auto}
.wzg{display:grid;grid-template-columns:repeat(3,1fr);gap:2px;padding:0 0 130px;overflow:auto;flex:1}.wzg .it{position:relative;aspect-ratio:1;background:var(--panel2);overflow:hidden}.wzg .it img,.wzg .it video{width:100%;height:100%;object-fit:cover}
.wzg .it u{position:absolute;top:7px;right:7px;width:26px;height:26px;border-radius:50%;border:2px solid #fff;background:var(--a1);color:#fff;font:700 13px/22px system-ui;text-align:center;text-decoration:none}
.wzg .add{display:grid;place-items:center;color:var(--a1);font-size:30px;cursor:pointer}
.wzbar{position:absolute;left:10px;right:10px;bottom:10px;display:flex;gap:8px;align-items:flex-end}
.wztabs{display:flex;overflow:auto;background:var(--panel);border-radius:36px;padding:6px;width:100%;scrollbar-width:none}.wztabs button{flex:none;width:84px;background:transparent;border:0;color:var(--text);border-radius:30px;padding:8px 0;cursor:pointer;font:inherit;font-size:12.5px;display:flex;flex-direction:column;align-items:center;gap:4px}.wztabs button.on{background:rgba(124,92,255,.14);color:var(--a1)}.wztabs b{font-size:22px;font-weight:400}
.wzcap{flex:1;background:var(--panel);border-radius:26px;padding:14px 16px;border:0;outline:0;color:var(--text);font:inherit;font-size:16px;resize:none;max-height:110px}
.wzsend{width:52px;height:52px;border-radius:50%;border:0;background:var(--accent);color:#fff;font-size:22px;cursor:pointer;position:relative;flex:none}.wzsend s{position:absolute;top:-4px;right:-4px;background:var(--a1);border-radius:10px;font:700 11px/18px system-ui;min-width:18px;text-decoration:none;border:2px solid var(--bg)}
.wzopt{display:block;width:100%;text-align:left;background:none;border:0;color:var(--danger);font:inherit;font-weight:600;font-size:16px;padding:13px 4px;cursor:pointer}
.albgrid{display:flex;flex-direction:column;gap:2px;width:260px;max-width:100%;border-radius:14px;overflow:hidden}.albgrid .r{display:flex;gap:2px}.albgrid .r>*{flex:1 1 0;min-width:0;height:100%;position:relative;overflow:hidden}
.albgrid .ph{width:100%!important;height:100%!important;max-width:none!important;max-height:none!important;border-radius:0!important;object-fit:cover;display:block}.albgrid .vc i{position:absolute;inset:0;display:grid;place-items:center;font-style:normal;color:#fff;font-size:22px;pointer-events:none;text-shadow:0 1px 6px #0008}`;
st0.textContent+=`.spc{display:flex;align-items:center;gap:10px;min-width:210px;padding:4px 2px;cursor:pointer}.spc i{width:46px;height:46px;border-radius:50%;background:#e5484d;color:#fff;display:grid;place-items:center;font-style:normal;font-size:22px;flex:none;overflow:hidden;background-size:cover}.spc.ct i{background:var(--a1);font-weight:700}.spc small{display:block;opacity:.7;font-size:13px}`;
st0.textContent+='.set.srow{align-items:center!important;margin-top:0!important;max-width:none!important}';
document.head.appendChild(st0);
const E=s=>esc(s==null?'':String(s));
const rnd=()=>Array.from(crypto.getRandomValues(new Uint8Array(8)),b=>b.toString(16).padStart(2,'0')).join('');
const SITE=location.origin+location.pathname;
const copyTxt=t=>{ try{ navigator.clipboard.writeText(t); toast('Ссылка скопирована'); }catch(e){ toast(t); } };

function wizard(type){
const ch=type==='channel', noun=ch?'канал':'группу', nounOf=ch?'канала':'группы', many=ch?'каналы':'группы';
const s={step:ch?0:1,title:'',about:'',pub:false,user:'',inv:rnd(),req:false,nocopy:false,sel:new Map(),av:null,avUrl:'',busy:false};
const o=document.createElement('div'); o.className='wzw'; document.body.appendChild(o);
const close=()=>{ if(s.avUrl) URL.revokeObjectURL(s.avUrl); if(o.classList.contains('out')) return; o.classList.add('out'); setTimeout(()=>o.remove(),260); };
const clean=()=>s.user.replace(/^@/,'').trim();
const people=()=>{ const ids=new Set(); return S.chats.filter(c=>c.type==='private'&&c.peer_id&&c.peer_id!==S.me.id&&!ids.has(c.peer_id)&&ids.add(c.peer_id)).map(c=>({id:c.peer_id,name:c.peer_name,username:c.peer_username,avatar_url:c.peer_avatar,color:c.peer_color})); };
const link=()=>SITE+'#+'+s.inv;
const nextOk=()=>s.step===1?!!s.title.trim():s.step===2?(!s.pub||clean().length>=5):true;
const head=(t,next)=>`<div class="wzwh"><button class="ib" data-bk>${ic('back')}</button><b>${t}</b>${next?`<button class="wznx" data-nx ${nextOk()?'':'disabled'}>${next}</button>`:'<span></span>'}</div>`;
const draw=()=>{
let h='';
if(s.step===0) h=`<div class="wzwh"><button class="ib" data-bk>${ic('back')}</button><span></span></div><div style="flex:1;display:flex;flex-direction:column;justify-content:center;align-items:center;text-align:center;padding:0 30px"><div class="wzart"><div class="ph1"></div><div class="dk">${ic('megaphone')}</div><div class="c1"><b>Канал</b>57k подписчиков</div><div class="c2">просмотры<span style="display:inline-flex;align-items:center;gap:3px">${ic('eye','mini')}1K</span></div></div><h2 style="font-size:28px;margin:34px 0 12px">Что такое канал?</h2><div style="font-size:19px;max-width:420px">Каналы — инструмент, который позволяет транслировать сообщения на большую аудиторию.</div></div><button class="wzbtn" data-go>Создать канал</button>`;
else if(s.step===1) h=head('Создать '+noun,'Далее')+`<div class="wzc p" style="display:flex;align-items:center;gap:16px"><label class="wzav">${s.avUrl?`<img src="${s.avUrl}">`:ic('camera')||'\u{1F4F7}'}<input type="file" accept="image/*" hidden data-av></label><input class="wzin" data-t placeholder="${ch?'Название канала':'Название группы'}" maxlength="64" value="${E(s.title)}"></div><div class="wzc p" style="margin-top:18px"><textarea class="wzin" data-a rows="2" placeholder="Описание">${E(s.about)}</textarea></div><div class="wzh">Можете указать дополнительное описание ${nounOf}.</div>`;
else if(s.step===2) h=head('Тип '+nounOf,'Далее')+`<div class="wzt">Ссылка</div><div class="wzc"><div class="wzrow" data-ty="1"><i>${s.pub?ic('check'):''}</i>Публичная</div><div class="wzrow" data-ty="0"><i>${s.pub?'':ic('check')}</i>Частная</div></div><div class="wzh">${s.pub?`Публичные ${many} можно найти через поиск, вступить в них может любой пользователь.`:`На частные ${many} можно вступить только по ссылке-приглашению.`}</div>`
+(s.pub?`<div class="wzc p" style="display:flex;align-items:center;margin-top:12px"><span style="font-size:19px">@</span><input class="wzin" data-u placeholder="ссылка" autocapitalize="off" spellcheck="false" value="${E(s.user)}"></div><div class="wzh">Если у ${nounOf} будет постоянная публичная ссылка, другие пользователи смогут найти ${ch?'его':'её'} и вступить.</div><div class="wzh">Можно использовать латиницу (a-z), цифры (0-9) и подчёркивание. Минимальная длина — 5 символов.</div>`
:`<div class="wzt">Ссылка-приглашение</div><div class="wzc p"><div class="wzlink"><span>${E(link().replace(/^https?:\/\//,''))}</span><button data-cp>Копировать</button><button data-nw>Новая</button></div><button class="wzbtn sm" data-sh>Поделиться</button></div><div class="wzh">По этой ссылке можно вступить в ${ch?'канал':'группу'}. Вы можете сбросить её в любой момент.</div><div class="wzc" style="margin-top:10px"><label class="wzsw">Заявки на вступление<input type="checkbox" data-rq ${s.req?'checked':''}></label></div><div class="wzh">Новые участники смогут вступить в ${ch?'канал':'группу'} только после одобрения заявки администратором.</div>`)
+`<div class="wzt">Сохранение и копирование материалов</div><div class="wzc"><label class="wzsw">Запретить копирование<input type="checkbox" data-nc ${s.nocopy?'checked':''}></label></div><div class="wzh">${ch?'Подписчики':'Участники'} смогут копировать, сохранять или пересылать материалы из ${nounOf}.</div><div style="height:30px"></div>`;
else { const ps=people(); h=head(ch?'Подписчики':'Участники')+`<div class="wzh">Это необязательно — людей можно позвать позже по ссылке или из списка контактов.</div><div style="flex:1;overflow:auto">${ps.length?ps.map(p=>`<div class="wzpick" data-pk="${p.id}">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'s')}<b>${E(p.name)}</b><span class="sel ${s.sel.has(p.id)?'on':''}">${s.sel.has(p.id)?ic('check'):''}</span></div>`).join(''):'<div class="wzh">Контактов пока нет</div>'}</div><button class="wzbtn" data-mk ${s.busy?'disabled':''}>${s.busy?'Создаём…':'Создать '+noun}</button>`; }
o.innerHTML=h;
const q=x=>o.querySelector(x);
q('[data-bk]').onclick=()=>{ if(s.step===0||(s.step===1&&!ch)) close(); else { s.step--; draw(); } };
const nx=q('[data-nx]'); if(nx) nx.onclick=()=>{ if(nextOk()){ s.step++; draw(); } };
const go=q('[data-go]'); if(go) go.onclick=()=>{ s.step=1; draw(); };
const upd=()=>{ if(nx){ if(nextOk()) nx.removeAttribute('disabled'); else nx.setAttribute('disabled',''); } };
const t=q('[data-t]'); if(t){ t.oninput=()=>{ s.title=t.value; upd(); }; setTimeout(()=>t.focus(),50); }
const a=q('[data-a]'); if(a) a.oninput=()=>{ s.about=a.value; };
const av=q('[data-av]'); if(av) av.onchange=()=>{ const f=av.files[0]; if(!f) return; s.av=f; if(s.avUrl) URL.revokeObjectURL(s.avUrl); s.avUrl=URL.createObjectURL(f); draw(); };
o.querySelectorAll('[data-ty]').forEach(e=>e.onclick=()=>{ s.pub=e.dataset.ty==='1'; draw(); });
const u=q('[data-u]'); if(u) u.oninput=()=>{ u.value=u.value.replace(/[^A-Za-z0-9_]/g,''); s.user=u.value; upd(); };
const cp=q('[data-cp]'); if(cp) cp.onclick=()=>copyTxt(link());
const nw=q('[data-nw]'); if(nw) nw.onclick=()=>{ s.inv=rnd(); draw(); };
const sh=q('[data-sh]'); if(sh) sh.onclick=()=>{ if(navigator.share) navigator.share({url:link()}).catch(()=>{}); else copyTxt(link()); };
const rq=q('[data-rq]'); if(rq) rq.onchange=()=>{ s.req=rq.checked; };
const nc=q('[data-nc]'); if(nc) nc.onchange=()=>{ s.nocopy=nc.checked; };
o.querySelectorAll('[data-pk]').forEach(e=>e.onclick=()=>{ const id=e.dataset.pk; if(s.sel.has(id)) s.sel.delete(id); else s.sel.set(id,people().find(p=>p.id===id)); draw(); });
const mk=q('[data-mk]'); if(mk) mk.onclick=async()=>{ if(s.busy) return; s.busy=true; draw();
 const {data,error}=await sb.rpc('lm_create_chat_v3',{p_type:type,p_title:s.title.trim(),p_members:[...s.sel.keys()],p_description:s.about.trim(),p_username:s.pub?clean().toLowerCase():null,p_protected:s.nocopy,p_requests:s.pub?false:s.req,p_invite:s.inv});
 if(error){ s.busy=false; draw(); return toast(error.message); }
 if(s.av){ try{ const f=await compressImage(s.av); const url=await upload(f,f!==s.av?'jpg':extOf(s.av)); await sb.from('lm_chats').update({avatar_url:url}).eq('id',data); }catch(e){} }
 close(); await loadChats(); openChat(data); };
};
draw();
}
newChatFlow=wizard;

async function sendAlbumWeb(files,cap){
if(!canPost()||!files.length) return;
const chatId=S.cur, album=files.length>1?(crypto.randomUUID?crypto.randomUUID():rnd()+rnd()):null;
const temps=files.map(f=>pendingUpload(f.name,chatId));
const prep=await Promise.all(files.map(async f0=>{ try{
 if(f0.size>window.tgLim()){ toast(`«${f0.name}» больше ${window.tgLimTxt()}`); return null; }
 const kind=f0.type.startsWith('image/')?'image':f0.type.startsWith('video/')?'video':'file';
 const f=kind==='image'?await compressImage(f0):f0;
 const meta=kind==='image'?await imgSize(f):{name:f0.name,size:f0.size};
 const parts=kind!=='image'?await window.tgBigUp(f0,extOf(f0)):null; if(parts){ meta.parts=parts; meta.name=meta.name||f0.name; meta.size=f0.size; }
 const url=parts?parts[0]:await upload(f,kind==='image'&&f!==f0?'jpg':extOf(f0));
 return {kind,url,meta};
}catch(e){ toast('Ошибка загрузки: '+e.message); return null; } }));
temps.forEach(t=>t.remove());
const ok=prep.filter(Boolean);
for(let i=0;i<ok.length;i++){ const p=ok[i]; if(album&&ok.length>1&&!p.meta.parts) p.meta={...p.meta,album};
 await insertMsg({kind:p.kind,media_url:p.url,meta:p.meta,body:i===ok.length-1?(cap||null):null,reply_to:i===0?(S.reply?.id||null):null},chatId);
 if(i===0){ S.reply=null; renderCtx(); } }
}

function attachSheet(){
if(!S.cur||!canPost()) return;
const o=document.createElement('div'); o.className='wza'; document.body.appendChild(o);
let files=[]; const urls=[]; let tabSel='Галерея';
const close=()=>{ urls.forEach(u=>URL.revokeObjectURL(u)); if(o.dataset.bye) return; o.dataset.bye=1; o.classList.add('bye'); setTimeout(()=>o.remove(),250); };
const post=(kind,body,media,meta)=>{ close(); insertMsg({kind,body,media_url:media||null,meta:meta||{},reply_to:S.reply?.id||null},S.cur); if(S.reply){ S.reply=null; renderCtx(); } };
const pickIn=document.createElement('input'); pickIn.type='file'; pickIn.multiple=true; pickIn.accept='image/*,video/*';
pickIn.onchange=()=>{ [...pickIn.files].forEach(f=>{ if(files.length<10&&!files.includes(f)){ files.push(f); urls[files.length-1]=URL.createObjectURL(f); } }); pickIn.value=''; draw(); };
const AUD=/\.(mp3|m4a|wav|flac|ogg|aac|opus)$/i;
const recent=audio=>{ const out=[]; for(const l of S.msgs.values()) for(const m of l) if(m.kind==='file'&&!m.deleted&&m.media_url&&m.id>0&&AUD.test((m.meta&&m.meta.name)||'')===audio) out.push(m);
 const seen=new Set(); return out.sort((a,b)=>new Date(b.created_at)-new Date(a.created_at)).filter(m=>!seen.has(m.media_url)&&seen.add(m.media_url)).slice(0,30); };
const fsz=b=>b>1048576?(b/1048576).toFixed(1)+' МБ':Math.max(1,Math.round(b/1024))+' КБ';
const filesPanel=audio=>{ const r=recent(audio);
 return `<div style="flex:1;overflow:auto;padding-bottom:110px"><div class="wzc">${audio?'':'<div class="wzrow" data-gal><i>'+ic('image')+'</i>Выбрать из Галереи</div>'}<div class="wzrow" data-pf="${audio?'a':'f'}"><i>${ic('cloud')}</i>Выбрать из файлов</div></div>`
 +`<div class="wzt">${r.length?(audio?'Ваши чаты':'Недавно отправленные'):''}</div>`+(r.length?`<div class="wzc">${r.map((m,i)=>`<div class="wzrow" data-rs="${i}"><i style="width:44px;height:44px;border-radius:50%;background:var(--a1);color:#fff;display:grid;place-items:center">${audio?ic('music'):ic('file')}</i><div style="min-width:0"><b style="display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${E((m.meta&&m.meta.name)||'Файл')}</b><span style="font-size:14px;color:var(--muted)">${m.meta&&m.meta.size?fsz(m.meta.size):''}</span></div></div>`).join('')}</div>`:`<div class="wzh">${audio?'Здесь появятся аудиофайлы из ваших чатов':'Здесь появятся файлы, которые вы отправляли'}</div>`)+'</div>'; };
const people=()=>{ const ids=new Set(); return S.chats.filter(c=>c.type==='private'&&c.peer_id&&c.peer_id!==S.me.id&&!ids.has(c.peer_id)&&ids.add(c.peer_id)).map(c=>({id:c.peer_id,name:chatName(c),username:c.peer_username,avatar_url:c.peer_avatar,color:c.peer_color})).sort((a,b)=>String(a.name).localeCompare(String(b.name))); };
const tab=(i,t)=>`<button class="${t===tabSel?'on':''}" data-tb="${t}"><b>${i}</b>${t}</button>`;
const draw=()=>{
 let mid;
 if(tabSel==='Файл') mid=filesPanel(false);
 else if(tabSel==='Звук') mid=filesPanel(true);
 else if(tabSel==='Геопозиция') mid=`<div style="flex:1;overflow:auto;padding-bottom:110px;padding-top:10px"><div class="wzc"><div class="wzrow" data-geo><i>${ic('geo')}</i><div><b>Отправить геопозицию</b><div style="font-size:14px;color:var(--muted)">Ваше текущее местоположение</div></div></div><div class="wzrow" data-soon="Трансляция геопозиции"><i>${ic('radar')}</i><div><b>Транслировать геопозицию</b><div style="font-size:14px;color:var(--muted)">Обновляется в реальном времени · в разработке</div></div></div></div><div class="wzh" style="margin-top:10px">Места рядом: в разработке</div></div>`;
 else if(tabSel==='Контакт'){ const ps=people(); mid=`<div style="flex:1;overflow:auto;padding-bottom:110px"><div class="wzc">${ps.length?ps.map(p=>`<div class="wzpick" data-ct="${p.id}">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'s')}<div><b>${E(p.name)}</b>${p.username?`<div style="font-size:13px;color:var(--muted)">@${E(p.username)}</div>`:''}</div></div>`).join(''):'<div class="wzh">Контактов пока нет</div>'}</div></div>`; }
 else mid=files.length?`<div class="wzg">${files.map((f,i)=>`<div class="it" data-rm="${i}">${f.type.startsWith('video/')?`<video src="${urls[i]}#t=0.1" muted playsinline></video>`:`<img src="${urls[i]}">`}<u>${i+1}</u></div>`).join('')}${files.length<10?'<div class="it add" data-add>+</div>':''}</div>`
 :`<div style="flex:1;display:grid;place-items:center;text-align:center;padding:20px"><div><div>${ic('image','big46')}</div><div style="margin:8px 0 14px;color:var(--muted)">Выберите до 10 фото и видео</div><button class="wzbtn sm" data-add style="width:260px">Выбрать фото и видео</button></div></div>`;
 const showCap=tabSel==='Галерея'&&files.length;
 const _sl=(o.querySelector('.wztabs')||{}).scrollLeft||0;
 o.innerHTML=`<div class="sh${o.dataset.d?'':' up'}"><div class="wzwh"><button class="ib" data-x>${ic('x')}</button><b>${showCap?'Выбрано: '+files.length:tabSel==='Галерея'?'Недавние':tabSel==='Контакт'?'Контакты':tabSel}</b><span></span></div>${mid}<div class="wzbar">`
 +(showCap?`<textarea class="wzcap" rows="1" placeholder="Добавьте подпись…" data-cap></textarea><button class="wzsend" data-send>${ic('send')}<s>${files.length}</s></button>`
 :`<div class="wztabs">${tab(ic('image'),'Галерея')}${tab(ic('file'),'Файл')}${tab(ic('geo'),'Геопозиция')}${tab(ic('poll'),'Опрос')}${tab(ic('music'),'Звук')}${tab(ic('user'),'Контакт')}${window.lfCapsule?tab(ic('hourglass'),'Капсула'):''}${window.lmGames?tab(ic('gamepad'),'Игры'):''}</div>`)+`</div></div>`;
 o.dataset.d=1; { const _tb=o.querySelector('.wztabs'); if(_tb) _tb.scrollLeft=_sl; } o.querySelector('[data-x]').onclick=close; o.onclick=e=>{ if(e.target===o) close(); };
 o.querySelectorAll('[data-add]').forEach(b=>b.onclick=()=>pickIn.click());
 o.querySelectorAll('[data-rm]').forEach(b=>b.onclick=e=>{ if(e.target.closest('[data-add]')) return; const i=+b.dataset.rm; URL.revokeObjectURL(urls[i]); urls.splice(i,1); files.splice(i,1); draw(); });
 o.querySelectorAll('[data-tb]').forEach(b=>b.onclick=()=>{ const t=b.dataset.tb; if(t==='Опрос') return toast('Опрос: в разработке'); if(t==='Капсула'){ close(); return window.lfCapsule(); } if(t==='Игры'){ close(); return window.lmGames(); } tabSel=t; draw(); });
 const g=o.querySelector('[data-gal]'); if(g) g.onclick=()=>{ tabSel='Галерея'; draw(); };
 o.querySelectorAll('[data-pf]').forEach(b=>b.onclick=()=>{ if(b.dataset.pf==='f'){ close(); $('#fileIn').click(); } else { const a=document.createElement('input'); a.type='file'; a.accept='audio/*'; a.onchange=()=>{ close(); sendFiles([...a.files],true); }; a.click(); } });
 o.querySelectorAll('[data-rs]').forEach(b=>b.onclick=()=>{ const m=recent(tabSel==='Звук')[+b.dataset.rs]; if(m) post('file',null,m.media_url,m.meta); });
 o.querySelectorAll('[data-soon]').forEach(b=>b.onclick=()=>toast(b.dataset.soon+': в разработке'));
 const ge=o.querySelector('[data-geo]'); if(ge) ge.onclick=()=>{ if(!navigator.geolocation) return toast('Геолокация недоступна'); toast('Определяем…');
  navigator.geolocation.getCurrentPosition(p=>post('text',spcLoc(null,p.coords.latitude,p.coords.longitude)),()=>toast('Нет доступа к геопозиции'),{enableHighAccuracy:true,timeout:15000}); };
 o.querySelectorAll('[data-ct]').forEach(b=>b.onclick=()=>{ const p=people().find(x=>x.id===b.dataset.ct); if(p) post('text',spcContact(p.name,p.id)); });
 const sd=o.querySelector('[data-send]'); if(sd) sd.onclick=()=>{ const cap=(o.querySelector('[data-cap]').value||'').trim(); const fl=files.slice(); close(); sendAlbumWeb(fl,cap); };
};
draw();
}
$('#atBtn').onclick=e=>{ e.stopPropagation(); attachSheet(); };

const ROWS={2:[2],3:[1,2],4:[2,2],5:[2,3],6:[3,3],7:[1,3,3],8:[2,3,3],9:[3,3,3],10:[2,2,3,3]};
let albBusy=false;
function albRun(){
if(albBusy) return; const mw=$('#mw'); if(!mw||!S.cur) return; const list=S.msgs.get(S.cur)||[]; albBusy=true;
try{ let i=0; while(i<list.length){ const m=list[i], a=m.meta&&m.meta.album;
 if(a&&(m.kind==='image'||m.kind==='video')&&!m.deleted){ let j=i+1; while(j<list.length&&list[j].meta&&list[j].meta.album===a&&list[j].sender_id===m.sender_id&&!list[j].deleted&&(list[j].kind==='image'||list[j].kind==='video')) j++;
  if(j-i>1) albDeco(mw,list.slice(i,j)); i=j; } else i++; }
}catch(e){} albBusy=false;
}
function albDeco(mw,g){
const last=g[g.length-1]; const el=mw.querySelector(`.m[data-id="${last.id}"]`); if(!el||el.dataset.alb) return;
const ph=el.querySelector('.b .ph'); if(!ph) return;
const shown=g.slice(0,10), rows=ROWS[shown.length]||ROWS[10]; let k=0, h='<div class="albgrid">';
rows.forEach(n=>{ h+=`<div class="r" style="height:${n===1?190:n===2?128:86}px">`; for(let c=0;c<n;c++){ const m=shown[k++]; if(!m) break;
 h+=m.kind==='video'?`<div class="vc"><video class="ph" src="${E(m.media_url)}#t=0.1" preload="metadata" playsinline data-view="${E(m.media_url)}" data-vid="1"></video><i>▶</i></div>`:`<img class="ph" src="${E(m.media_url)}" data-view="${E(m.media_url)}" loading="lazy">`; }
 h+='</div>'; });
h+='</div>'; ph.outerHTML=h; el.dataset.alb=1;
g.slice(0,-1).forEach(m=>{ const e2=mw.querySelector(`.m[data-id="${m.id}"]`); if(e2){ e2.style.display='none'; e2.dataset.alb=1; } });
}
const spcLoc=(t,la,lo)=>'\u{1F4CD} '+(t||'Геопозиция')+'\nhttps://maps.apple.com/?ll='+la.toFixed(6)+','+lo.toFixed(6);
const spcContact=(n,id)=>'\u{1F464} '+n+'\nlumo://user/'+id;
const spcParse=b=>{ if(!b) return null; const l=String(b).split('\n'); if(l.length<2) return null; const last=l[l.length-1], head=l.slice(0,-1).join('\n'); const pre='https://maps.apple.com/?ll=';
 if(head.startsWith('\u{1F4CD} ')&&last.startsWith(pre)){ const c=last.slice(pre.length).split(','); const la=parseFloat(c[0]), lo=parseFloat(c[1]); if(c.length===2&&isFinite(la)&&isFinite(lo)) return {t:'loc',title:head.slice(3),la,lo}; }
 if(head.startsWith('\u{1F464} ')&&last.startsWith('lumo://user/')) return {t:'ct',name:head.slice(3),id:last.slice(12)};
 return null; };
function spcRun(){
const mw=$('#mw'); if(!mw||!S.cur) return; const list=S.msgs.get(S.cur)||[];
for(const m of list){ if(m.kind!=='text'||m.deleted) continue; const sp=spcParse(m.body); if(!sp) continue;
 const el=mw.querySelector(`.m[data-id="${m.id}"]`); if(!el||el.dataset.spc) continue; const tx=el.querySelector('.b .txt'); if(!tx) continue;
 const u=sp.t==='ct'?(S.profiles&&S.profiles.get&&S.profiles.get(sp.id)):null;
 tx.outerHTML=sp.t==='loc'?`<div class="spc" data-geo="${sp.la},${sp.lo}"><i>${ic('geo')}</i><div><b>${E(sp.title)}</b><small>Открыть на карте</small></div></div>`
  :`<div class="spc ct" data-cuid="${E(sp.id)}"><i${u&&u.avatar_url?` style="background-image:url('${E(u.avatar_url)}')"`:''}>${u&&u.avatar_url?'':E(sp.name.slice(0,1).toUpperCase())}</i><div><b>${E(sp.name)}</b><small>Контакт</small></div></div>`;
 el.dataset.spc=1; } }
document.addEventListener('click',e=>{ const g=e.target.closest('.spc[data-geo]'); if(g){ const [la,lo]=g.dataset.geo.split(','); window.open(`https://www.openstreetmap.org/?mlat=${la}&mlon=${lo}#map=16/${la}/${lo}`,'_blank','noopener'); return; }
 const c=e.target.closest('.spc[data-cuid]'); if(c) openDM(c.dataset.cuid); });
const albWatch=()=>{ const mw=$('#mw'); if(!mw) return setTimeout(albWatch,500); new MutationObserver(()=>{ albRun(); spcRun(); }).observe(mw,{childList:true}); albRun(); };
albWatch();

const delLabel=c=>c.type==='private'?'Удалить чат':c.role==='owner'?(c.type==='channel'?'Удалить канал':'Удалить группу'):(c.type==='channel'?'Отписаться':'Покинуть группу');
async function delChat(c,all){
try{
 if(all){ const {error}=await sb.rpc('lm_delete_chat',{p_chat:c.chat_id,p_all:true}); if(error) throw error; }
 else { if(c.type==='private') await sb.rpc('lm_clear_chat',{p_chat:c.chat_id}); const {error}=await sb.from('lm_members').delete().eq('chat_id',c.chat_id).eq('user_id',S.me.id); if(error) throw error; }
 closeChat(); loadChats();
}catch(e){ toast(e.message||'Ошибка'); }
}
function warnDel(c){
const t=c.type==='private'?'Если удалить этот чат у обоих, вся переписка будет потеряна у вас и у собеседника. Вы точно хотите его удалить?':c.type==='channel'?'Если удалить этот канал, все подписчики и сообщения будут потеряны. Вы точно хотите его удалить?':'Если удалить эту группу, все участники и сообщения будут потеряны. Вы точно хотите её удалить?';
modal('Внимание!',`<p style="margin:4px 0 8px">${E(t)}</p>`,[['Отмена','ghost'],['Удалить всё','danger',cl=>{ cl(); delChat(c,true); }]]);
}
leaveChat=function(){
const c=cur(); if(!c) return; const name=chatName(c), priv=c.type==='private', ch=c.type==='channel', opts=[];
if(priv){ opts.push(['Удалить у меня',()=>delChat(c,false)]); opts.push(['Удалить у меня и у '+name,()=>warnDel(c)]); }
else { if(c.role==='owner') opts.push([ch?'Удалить канал у всех':'Удалить группу у всех',()=>warnDel(c)]); opts.push([ch?'Отписаться':'Покинуть группу',()=>delChat(c,false)]); }
const close=modal(priv?E('Удалить чат с «'+name+'»?'):E(name),opts.map((x,i)=>`<button class="wzopt" data-o="${i}">${E(x[0])}</button>`).join(''),[['Отмена','ghost']]);
const ov=[...document.querySelectorAll('.ov')].pop(); if(ov) ov.addEventListener('click',e=>{ const b=e.target.closest('[data-o]'); if(b){ close(); opts[+b.dataset.o][1](); } });
};
const dm0=dropMenu;
dropMenu=function(btn,items,dir){ try{ const c=cur(); if(c&&Array.isArray(items)){
 items=items.map(x=>x&&x[2]===leaveChat?[x[0],delLabel(c),x[2],x[3]]:x);
 if(c.type==='private'&&items.some(x=>x&&/Очистить историю/.test(x[1]))&&!items.some(x=>x&&x[2]===leaveChat)) items=[...items,['trash','Удалить чат',()=>leaveChat(),'red']]; } }catch(e){}
 return dm0(btn,items,dir); };

const ih=location.hash.match(/^#\+([A-Za-z0-9]{12,24})$/);
if(ih){ const tm=setInterval(async()=>{ if(typeof S==='undefined'||!S.me) return; clearInterval(tm);
 const {data,error}=await sb.rpc('lm_join_code',{p_code:ih[1]}); history.replaceState(null,'',location.pathname+location.search);
 if(error) return toast(error.message); if(data&&data.status==='requested') return toast('Заявка отправлена — дождитесь одобрения администратора');
 await loadChats(); if(data&&data.chat) openChat(data.chat); },800); }
})();

;(function(){
const css=document.createElement('style'); css.textContent=`.phl{position:fixed;inset:0;z-index:100000;background:var(--bg);display:flex;align-items:center;justify-content:center;padding:16px;overflow:auto}.phl .cd{width:min(400px,100%);background:var(--panel);border-radius:26px;padding:26px 22px;text-align:center;box-shadow:0 10px 40px rgba(0,0,0,.12)}.phl h2{margin:0 0 8px;font-size:24px}.phl p{margin:0 0 16px;color:var(--muted);font-size:15px}.phl .pr{display:flex;align-items:center;gap:8px;background:var(--panel2);border-radius:16px;padding:0 14px;height:54px;margin-bottom:12px}.phl .pr b{font-size:19px}.phl .pr input,.phl .cin{flex:1;border:0;outline:0;background:transparent;color:var(--text);font:inherit;font-size:19px;font-weight:600;min-width:0}.phl .cin{background:var(--panel2);border-radius:16px;height:54px;padding:0 14px;width:100%;box-sizing:border-box;margin-bottom:12px;text-align:center;letter-spacing:.3em}.phl .cin.tx{letter-spacing:normal;text-align:left;font-size:17px}.phl .go{display:flex;align-items:center;justify-content:center;width:100%;height:52px;border:0;border-radius:26px;background:var(--accent);color:#fff;font-weight:700;font-size:17px;cursor:pointer}.phl .go[disabled]{opacity:.55;cursor:default}.phl .lk{display:block;margin:14px auto 0;background:none;border:0;color:var(--a1);font:inherit;font-size:14px;font-weight:600;cursor:pointer}.phl .er{color:var(--danger);font-size:14px;min-height:18px;margin-bottom:8px}.phl .nt{color:var(--muted);font-size:13px;margin-top:10px}`;
document.head.appendChild(css);
const E=s=>esc(s==null?'':String(s));
const PH=()=>FN.replace(/\/lumo$/,'/lumo-phone');
const call=async(path,body)=>{ try{ const r=await fetch(PH()+'/'+path,{method:'POST',headers:{'Content-Type':'text/plain'},body:JSON.stringify(body)}); return await r.json(); }catch(e){ return {error:'net'}; } };
const MSG={bad_phone:'Введите российский номер мобильного телефона',bad_code:'Неверный код',expired:'Код устарел — запросите новый',locked:'Слишком много попыток — запросите новый код',too_many:'Слишком много кодов. Попробуйте через час',wait:'Новый код можно запросить через минуту',busy:'Сервис занят, попробуйте позже',sms_off:'Отправка кодов пока недоступна',sms_fail:'Отправка кодов пока недоступна',banned:'Аккаунт заблокирован',bad_tfa:'Неверный пароль',username_taken:'Этот юзернейм уже занят',bad_username:'Юзернейм: 3–32 символа, латиница, цифры и _',net:'Нет соединения. Попробуйте ещё раз'};
const fmtD=d=>d.replace(/^(\d{0,3})(\d{0,3})(\d{0,2})(\d{0,2}).*$/,(m,a,b,c,e)=>[a,b,c,e].filter(Boolean).join(' ').replace(/^(\d{3}) (\d{3}) (\d{2})/,'$1 $2-$3').replace(/-(\d{2}) (\d{2})/,'-$1-$2'));
function phoneLogin(){
const s={fb:false,step:'welcome',d:'',code:'',name:'',last:'',un:'',tfa:'',hint:'',err:'',note:'',busy:false,link:null,direct:false,chan:'sms',wait:0};
if(!document.getElementById('wlcss')){ const w=document.createElement('style'); w.id='wlcss'; w.textContent='@keyframes wlUp{from{opacity:0;transform:translateY(20px) scale(.98)}to{opacity:1;transform:none}}@keyframes wlFloat{0%,100%{transform:translateY(0)}50%{transform:translateY(-7px)}}@keyframes wlPulse{0%{box-shadow:0 0 0 0 rgba(108,92,231,.5)}100%{box-shadow:0 0 0 30px rgba(108,92,231,0)}}@keyframes wlIn{from{opacity:0}to{opacity:1}}.phl{animation:wlIn .4s ease both}.phl .stepin>*{animation:wlUp .5s cubic-bezier(.2,.8,.2,1) both}.phl .stepin>*:nth-child(2){animation-delay:.06s}.phl .stepin>*:nth-child(3){animation-delay:.12s}.phl .stepin>*:nth-child(4){animation-delay:.18s}.phl .stepin>*:nth-child(5){animation-delay:.24s}.phl .stepin>*:nth-child(6){animation-delay:.3s}.phl .cd.wel{display:flex;flex-direction:column}.phl .wel .wlg{order:-1;width:88px;height:88px;margin:0 auto 20px;border-radius:28px;background:linear-gradient(135deg,#6c5ce7,#4da3ff);display:grid;place-items:center;animation:wlUp .6s cubic-bezier(.2,.8,.2,1) both,wlFloat 3.2s ease-in-out .6s infinite,wlPulse 2.4s ease-out .6s infinite}.phl .wel .wf{display:grid;gap:12px;margin:18px 0 22px;text-align:left}.phl .wel .wf>div{display:flex;gap:12px;align-items:center;animation:wlUp .55s cubic-bezier(.2,.8,.2,1) both}.phl .wel .wf>div:nth-child(1){animation-delay:.45s}.phl .wel .wf>div:nth-child(2){animation-delay:.6s}.phl .wel .wf>div:nth-child(3){animation-delay:.75s}.phl .wel .wf i{flex:none;width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,#6c5ce7,#4da3ff);display:grid;place-items:center;color:#fff;font-style:normal;font-weight:800}.phl .wel .wf b{display:block;font-size:15px}.phl .wel .wf span{display:block;font-size:13px;color:var(--muted)}.phl .wel>.go{animation:wlUp .55s cubic-bezier(.2,.8,.2,1) .95s both}'; document.head.appendChild(w); }
const o=document.createElement('div'); o.className='phl'; (document.getElementById('auth')||document.body).appendChild(o);
let tm=null; const close=()=>{ clearInterval(tm); o.remove(); };
const full=()=>'7'+s.d;
const fail=j=>{ s.err=MSG[j.error]||'Не удалось выполнить действие'; if(['sms_off','sms_fail','busy','too_many','net','server','link'].includes(j.error)) s.fb=true; if(j.error==='username_taken'||j.error==='bad_username') return; if(['bad_code','expired','locked'].includes(j.error)){ s.code=''; if(j.error!=='bad_code') s.step='code'; } if(j.error==='bad_tfa') s.tfa=''; };
const draw=()=>{
 const t={welcome:['Добро пожаловать в Lumo','Быстрый и красивый мессенджер, в котором приятно общаться'],phone:['Ваш номер телефона','Мы отправим код в SMS или в Telegram. Если аккаунта с этим номером нет, он будет создан.'],code:['Введите код',s.chan==='telegram'?(s.direct?'Код отправлен вам в Telegram (бот Lumo)':'Откройте бота Lumo в Telegram, нажмите «Старт» и поделитесь номером — код придёт в чат'):'Код отправлен на +7 '+fmtD(s.d)],name:['Как вас зовут?','Имя и фамилия по желанию — их увидят ваши контакты. Можно пропустить.'],un:['Придумайте юзернейм','По юзернейму вас смогут найти. Латиница, цифры и _, от 3 символов.'],tfa:['Пароль защиты','Для аккаунта включена двухэтапная аутентификация. Введите пароль.'+(s.hint?' Подсказка: '+s.hint:'')]}[s.step];
 let b='';
 if(s.step==='welcome') b=`<div class="wlg"><svg viewBox="0 0 24 24" width="44" height="44" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 11.5a8.4 8.4 0 0 1-9 8.4 9 9 0 0 1-4-1L3 20l1.3-4A8.4 8.4 0 0 1 12 3a8.5 8.5 0 0 1 9 8.5z"/><path d="M8.5 12h.01M12 12h.01M15.5 12h.01" stroke-width="3"/></svg></div><div class="wf"><div><i>1</i><p><b>Быстрые сообщения</b><span>Доставляются мгновенно и без лишних шагов</span></p></div><div><i>2</i><p><b>Звонки и видеосообщения</b><span>Голос, видео и кружки — всё в одном месте</span></p></div><div><i>3</i><p><b>Вход без паролей</b><span>Только номер телефона и код</span></p></div></div><button class="go" data-go>Продолжить</button>`;
 else if(s.step==='phone') b=`<div class="pr"><b>+7</b><input id="phI" inputmode="tel" placeholder="900 123-45-67" value="${fmtD(s.d)}" autocomplete="tel-national"></div><div class="er">${E(s.err)}</div><button class="go" data-go ${s.d.length===10&&!s.busy?'':'disabled'}>${s.busy?'Отправляем…':'Получить код'}</button>`;
 else if(s.step==='code') b=`<input class="cin" id="cdI" inputmode="numeric" maxlength="5" placeholder="•••••" value="${E(s.code)}" autocomplete="one-time-code"><div class="er">${E(s.err)}</div><button class="go" data-go ${s.code.length===5&&!s.busy?'':'disabled'}>${s.busy?'Проверяем…':'Войти'}</button>`
  +(s.chan==='telegram'&&!s.direct&&s.link?`<a class="lk" href="${E(s.link)}" target="_blank" rel="noopener">Открыть Telegram</a>`:'')
  +(s.chan==='sms'?'<button class="lk" data-tg>Получить код в Telegram</button>':'')
  +`<button class="lk" data-re ${s.wait>0?'disabled style="color:var(--muted)"':''}>${s.wait>0?'Отправить ещё раз через '+s.wait+' с':'Отправить код ещё раз'}</button><button class="lk" data-ch>Изменить номер</button>`;
 else if(s.step==='name') b=`<input class="cin tx" id="nmI" placeholder="Имя" maxlength="64" value="${E(s.name)}"><input class="cin tx" id="lnI" placeholder="Фамилия" maxlength="64" value="${E(s.last)}" style="margin-top:10px"><div class="er">${E(s.err)}</div><button class="go" data-go>Продолжить</button><button class="lk" data-sk>Пропустить</button>`;
 else if(s.step==='un') b=`<input class="cin tx" id="unI" placeholder="Юзернейм" maxlength="32" autocapitalize="off" autocomplete="username" value="${E(s.un)}"><div class="er">${E(s.err)}</div><button class="go" data-go ${s.un.length>=3&&!s.busy?'':'disabled'}>${s.busy?'Создаём…':'Готово'}</button>`;
 else b=`<input class="cin tx" id="tfI" type="password" placeholder="Пароль" value="${E(s.tfa)}"><div class="er">${E(s.err)}</div><button class="go" data-go ${s.tfa&&!s.busy?'':'disabled'}>Войти</button><button class="lk" data-rs>Забыли пароль?</button>`;
 o.innerHTML=`<div class="cd${s.step==='welcome'?' wel':''}"><h2>${E(t[0])}</h2><p>${E(t[1])}</p>${b}${s.note?`<div class="nt">${E(s.note)}</div>`:''}${(s.fb||Date.now()<1793912400000)?'<button class="lk" data-x style="margin-top:18px;color:var(--muted)">Войти по логину и паролю</button>':''}</div>`;
 if(s._st!==s.step){ s._st=s.step; o.firstElementChild.classList.add('stepin'); }
 const q=x=>o.querySelector(x);
 const xx=q('[data-x]'); if(xx) xx.onclick=close;
 const ph=q('#phI'); if(ph){ ph.oninput=()=>{ let d=ph.value.replace(/\D/g,''); if(d.length>10&&/^[78]/.test(d)) d=d.slice(1); s.d=d.slice(0,10); s.err=''; const pos=ph.value; ph.value=fmtD(s.d); const g=q('[data-go]'); if(g) g.disabled=s.d.length!==10; }; ph.onkeydown=e=>{ if(e.key==='Enter') q('[data-go]').click(); }; ph.focus(); }
 const cd=q('#cdI'); if(cd){ cd.oninput=()=>{ s.code=cd.value.replace(/\D/g,'').slice(0,5); cd.value=s.code; s.err=''; const g=q('[data-go]'); if(g) g.disabled=s.code.length!==5; if(s.code.length===5) verify(); }; cd.focus(); }
 const nm=q('#nmI'); if(nm){ nm.oninput=()=>{ s.name=nm.value; }; nm.onkeydown=e=>{ if(e.key==='Enter') q('[data-go]').click(); }; nm.focus(); }
 const ln=q('#lnI'); if(ln){ ln.oninput=()=>{ s.last=ln.value; }; ln.onkeydown=e=>{ if(e.key==='Enter') q('[data-go]').click(); }; } const un=q('#unI'); if(un){ un.oninput=()=>{ s.un=un.value.toLowerCase().replace(/[^a-z0-9_]/g,'').slice(0,32); un.value=s.un; s.err=''; const g=q('[data-go]'); if(g) g.disabled=s.un.length<3; }; un.onkeydown=e=>{ if(e.key==='Enter') q('[data-go]').click(); }; un.focus(); } const sk=q('[data-sk]'); if(sk) sk.onclick=()=>{ s.name=''; s.last=''; s.step='un'; s.err=''; draw(); }; const tf=q('#tfI'); if(tf){ tf.oninput=()=>{ s.tfa=tf.value; const g=q('[data-go]'); if(g) g.disabled=!s.tfa; }; tf.onkeydown=e=>{ if(e.key==='Enter') q('[data-go]').click(); }; tf.focus(); }
 const go=q('[data-go]'); if(go) go.onclick=()=>{ if(s.step==='welcome'){ s.step='phone'; draw(); } else if(s.step==='phone') send(false); else if(s.step==='name'){ s.step='un'; s.err=''; draw(); } else verify(); };
 const tg=q('[data-tg]'); if(tg) tg.onclick=()=>send(true);
 const re=q('[data-re]'); if(re) re.onclick=()=>{ if(s.wait<=0) send(false); };
 const ch=q('[data-ch]'); if(ch) ch.onclick=()=>{ s.step='phone'; s.code=''; s.err=''; draw(); };
 const rs=q('[data-rs]'); if(rs) rs.onclick=()=>verify(true);
};
async function send(viaTg){ if(s.busy||s.d.length!==10) return; if(s.d==='9999999999'){ close(); try{ qrStop(); $('#qrView').classList.add('hidden'); $('#passView').classList.remove('hidden'); $('#passView').classList.add('pwok'); }catch(e){} return; } s.busy=true; s.err=''; draw();
 const body={phone:full(),purpose:'auth'}; if(viaTg) body.channel='telegram';
 const j=await call('send',body); s.busy=false;
 if(j.error) fail(j); else { s.code=''; s.step='code'; s.chan=j.channel||'sms'; s.link=j.link||null; s.direct=!!j.direct; s.wait=45; clearInterval(tm); tm=setInterval(()=>{ if(s.wait>0){ s.wait--; const r=o.querySelector('[data-re]'); if(r&&s.step==='code'){ r.textContent=s.wait>0?'Отправить ещё раз через '+s.wait+' с':'Отправить код ещё раз'; if(s.wait<=0){ r.removeAttribute('disabled'); r.style.color=''; } } } },1000); if(s.chan==='telegram'&&!s.direct&&s.link) window.open(s.link,'_blank','noopener'); }
 draw(); }
async function verify(reset){ if(s.busy) return; s.busy=true; s.err=''; draw();
 const body={phone:full(),code:s.code,purpose:'auth'}; if(s.name.trim()) body.name=s.name.trim(); if(s.last.trim()) body.last_name=s.last.trim(); if(s.un) body.username=s.un; if(s.tfa) body.tfa=s.tfa; if(reset) body.reset_tfa=true;
 const j=await call('verify',body); s.busy=false;
 if(j.error){ fail(j); draw(); }
 else if(j.need_name){ if(!s.un) s.step='name'; draw(); }
 else if(j.need_tfa){ s.hint=j.hint||''; s.step='tfa'; draw(); }
 else if(j.reset_pending){ s.note='Запрос на сброс пароля принят. Сбросить его можно через 7 дней: повторите вход и нажмите «Забыли пароль» ещё раз.'; draw(); }
 else if(j.token_hash){ const {error}=await sb.auth.verifyOtp({token_hash:j.token_hash,type:'magiclink'}); if(error){ s.err=error.message; draw(); } else { close(); try{ await start(); }catch(e){ toast(e.message||'Ошибка входа'); } if(j.created) toast('Аккаунт создан — имя и юзернейм можно поменять в настройках'); } }
 else draw(); }
draw();
}
const autoOpen=()=>{ if(IS_DESKTOP) return; let k=0; if(!document.getElementById('noReg')){ const st=document.createElement('style'); st.id='noReg'; st.textContent='#tReg{display:none!important}'; document.head.appendChild(st); } const iv2=setInterval(()=>{ const a=document.getElementById('auth'); if(a&&!a.classList.contains('hidden')&&!document.querySelector('.phl')&&!document.querySelector('#passView.pwok')){ phoneLogin(); } },500); };
const mount=()=>{ if(IS_DESKTOP) return true; const tq=document.getElementById('toQr'); if(!tq||document.getElementById('phBtn')) return !!document.getElementById('phBtn');
 const b=document.createElement('button'); b.id='phBtn'; b.type='button'; b.className='btn ghost w'; b.style.marginTop='10px'; b.textContent='Войти по номеру телефона'; b.onclick=phoneLogin; tq.insertAdjacentElement('afterend',b); autoOpen(); return true; };
if(!mount()){ let n=0; const iv=setInterval(()=>{ if(mount()||++n>40) clearInterval(iv); },500); }
})();

;(function(){
const st=document.createElement('style'); st.textContent='.shero~.setgrp .setsub{display:none}.shero~.setgrp .set{padding:9px 4px}.shero~.setgrp .sic{margin-bottom:0}.sval{color:var(--muted);font-size:15px;margin-right:2px;white-space:nowrap}';
document.head.appendChild(st);
function tgOrder(){
 const g=id=>document.getElementById(id);
 const out=g('sOut'); if(!out||!g('sProf')) return;
 const old=out.closest('.setgrp'); const box=old&&old.parentElement; if(!box||old.dataset.tgo) return;
 const lx=g('lxWal')?g('lxWal').parentElement:null; const lxRows=lx?[...lx.children]:[];
 const mk=rows=>{ rows=rows.filter(Boolean); if(!rows.length) return null; const d=document.createElement('div'); d.className='setgrp'; rows.forEach(r=>d.appendChild(r)); return d; };
 const acc=[...box.querySelectorAll('[data-accsw]')];
 const lk=g('sLook'); if(lk){ try{ const v={light:'Светлая',dark:'Тёмная',auto:'Авто'}[themeMode()]; const ch=lk.querySelector('.chev'); if(v&&ch&&!lk.querySelector('.sval')){ const s=document.createElement('span'); s.className='sval'; s.textContent=v; lk.insertBefore(s,ch); } }catch(e){} }
 ['lfSRem','tgSStyle','tgSMus','tgSPosts','tgSArc'].forEach(id=>{ const e=g(id); if(e) e.remove(); });
 const groups=[mk([...acc,g('sProf'),g('mAddAcc')]),mk([g('sSaved'),g('sCalls'),g('sDev')]),mk([g('lfSDnd'),g('sNotifP'),g('sPriv'),g('sLook'),g('sChats')]),mk([g('sPrem'),...lxRows,g('lfSCap'),g('lfSSt'),g('sAdmin')]),mk([g('sInvite'),g('sScanQr'),g('sAbout')]),mk([out])].filter(Boolean);
 groups[groups.length-1].dataset.tgo='1';
 const foot=box.querySelector('.sfoot');
 groups.forEach(x=>box.insertBefore(x,foot||null));
 [...box.children].forEach(x=>{ if(x.classList&&x.classList.contains('setgrp')&&!x.children.length) x.remove(); });
}
const rs0=renderSettings;
renderSettings=function(){ const r=rs0.apply(this,arguments); try{ tgOrder(); }catch(e){} return r; };
})();

;(function(){
const hard=()=>{ try{ location.replace(location.href.split('#')[0]); }catch(e){ try{ location.reload(); }catch(e2){} } };
const aa=accAdd;
accAdd=function(){ const r=aa.apply(this,arguments); setTimeout(()=>{ if(!document.querySelector('.ov')) hard(); },400); return r; };
const as0=accSwitch;
accSwitch=async function(id){ const r=await as0.apply(this,arguments); setTimeout(()=>{ try{ if(accList().some(x=>x.id===id)) hard(); }catch(e){} },500); return r; };
})();
;(function(){
try{
P.lxsend='<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9 10h4.5a1.5 1.5 0 0 1 0 3H9"/>';
P.lxgift='<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13M5 12v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-8M8 8a2.5 2.5 0 1 1 4-2M16 8a2.5 2.5 0 1 0-4-2"/>';
const st=document.createElement('style');
st.textContent='.iact[data-lxu]>[data-lx="send"],.iact[data-lxu]>[data-lx="gift"]{display:none!important}';
document.head.appendChild(st);
const _dm=dropMenu;
dropMenu=function(anchor,items,dir){
  try{
    if(anchor&&anchor.id==='iaMore'){
      const box=anchor.closest('.iact');
      const s=box&&box.querySelector('[data-lx="send"]'), g=box&&box.querySelector('[data-lx="gift"]');
      const add=[];
      if(s) add.push(['lxsend','Отправить люмены',()=>s.click()]);
      if(g) add.push(['lxgift','Подарить подарок',()=>g.click()]);
      if(add.length) items=add.concat([null],items);
    }
  }catch(e){}
  return _dm(anchor,items,dir);
};
}catch(e){ console.warn('lx more',e); }
})();

;(function(){
try{
const st=document.createElement('style');
st.textContent='.lxgrid{grid-template-columns:repeat(2,minmax(0,1fr))!important;align-items:stretch}.lxmine{grid-template-columns:repeat(3,minmax(0,1fr))!important}.lxg{min-width:0;overflow:hidden;display:flex;flex-direction:column;align-items:center;justify-content:flex-start}.lxg img{width:100%;height:auto;aspect-ratio:1;object-fit:cover}.lxg b,.lxg small{max-width:100%;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.lxg .pr{white-space:nowrap}.lxgm{width:100%;align-items:center}.lxgm>.lxpill{width:auto;max-width:88%;align-self:center;display:inline-block;line-height:1.35}.lxgm>.lxcard{align-self:center}.lxgm .lxcard img{object-fit:cover}';
document.head.appendChild(st);
}catch(e){ console.warn('lx grid',e); }
})();

;(function(){
try{
const E=s=>String(s==null?'':s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const API='https://foniukmpiukuwpcdvdhp.supabase.co/functions/v1/lumo-pay';
const isOwner=()=>{ try{ return S.staff==='owner'&&S.me&&S.me.username==='emelka_karamelka2'; }catch(e){ return false; } };
const PRICES={1:199,6:1490,12:2490};
function payTest(){
  const close=modal('Тест оплаты (владелец)',`<div id="ptW">
<p style="margin:0 0 10px;color:var(--muted);font-size:14px">Проверка покупки без денег: найдёт аккаунт по юзернейму и зачислит покупку. Видно только вам.</p>
<label style="font-weight:700;font-size:14px">Юзернейм</label>
<input class="inp" id="ptU" placeholder="@username" autocomplete="off" autocapitalize="none" style="margin:6px 0 8px">
<div id="ptA" style="min-height:48px;margin-bottom:10px"></div>
<label style="font-weight:700;font-size:14px">Что покупаем</label>
<select class="inp" id="ptK" style="margin:6px 0 8px"><option value="lum">Люмены</option><option value="p1">Premium, 1 месяц (199 ₽)</option><option value="p6">Premium, 6 месяцев (1 490 ₽)</option><option value="p12">Premium, 12 месяцев (2 490 ₽)</option></select>
<input class="inp" id="ptN" type="number" min="50" step="1" value="50" placeholder="Количество люменов, от 50" style="margin-bottom:6px">
<div id="ptP" style="font-weight:800;font-size:18px;margin:8px 0 12px"></div>
<button class="btn primary" id="ptGo" disabled style="width:100%">Выполнить тестовую покупку</button>
<div id="ptR" style="margin-top:12px;font-size:14px"></div></div>`,[]);
  const g=id=>document.getElementById(id);
  let found=null,seq=0,tm=0;
  const sum=()=>{ const k=g('ptK').value; g('ptN').style.display=k==='lum'?'':'none';
    if(k==='lum'){ const n=Math.floor(Number(g('ptN').value)||0); g('ptP').textContent=n>=50?'К оплате: '+(Math.round(n*170)/100).toLocaleString('ru-RU')+' ₽':'Минимум 50 люменов'; }
    else g('ptP').textContent='К оплате: '+PRICES[k.slice(1)].toLocaleString('ru-RU')+' ₽';
    g('ptGo').disabled=!found||(k==='lum'&&Math.floor(Number(g('ptN').value)||0)<50); };
  const look=()=>{ clearTimeout(tm); found=null; sum(); const u=g('ptU').value.trim().replace(/^@/,'').toLowerCase();
    if(!u){ g('ptA').innerHTML=''; return; }
    if(!/^[a-z0-9_]{3,32}$/.test(u)){ g('ptA').innerHTML='<span style="color:var(--danger)">Юзернейм: 3–32 символа, латиница, цифры, _</span>'; return; }
    g('ptA').innerHTML='<span style="color:var(--muted)">Проверяем…</span>'; const my=++seq;
    tm=setTimeout(async()=>{ try{ const r=await fetch(API,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:u})}); const d=await r.json(); if(my!==seq) return;
      if(d.found){ found=d; g('ptA').innerHTML=`<div style="display:flex;align-items:center;gap:10px;padding:8px 10px;border:1px solid var(--line);border-radius:14px"><div style="width:40px;height:40px;border-radius:50%;background:${d.avatar_url?`url('${E(d.avatar_url)}') center/cover`:'var(--accent)'};color:#fff;display:grid;place-items:center;font-weight:800">${d.avatar_url?'':E((d.name||d.username).charAt(0).toUpperCase())}</div><div><b>${E(d.name||d.username)}</b><div style="color:var(--muted);font-size:13px">@${E(d.username)} · проверьте, что это нужный аккаунт</div></div></div>`; }
      else g('ptA').innerHTML='<span style="color:var(--danger)">Аккаунт не найден</span>';
      sum(); }catch(e){ if(my===seq) g('ptA').innerHTML='<span style="color:var(--danger)">Не удалось проверить аккаунт</span>'; } },350); };
  g('ptU').oninput=look; g('ptK').onchange=sum; g('ptN').oninput=sum; sum();
  g('ptGo').onclick=async()=>{ if(!found) return; const k=g('ptK').value; const btn=g('ptGo'); btn.disabled=true; g('ptR').textContent='Выполняем…';
    try{ const {data:{session}}=await sb.auth.getSession();
      const body={action:'test_buy',username:found.username,kind:k==='lum'?'lum':'prem'}; if(k==='lum') body.amount=Math.floor(Number(g('ptN').value)); else body.months=Number(k.slice(1));
      const r=await fetch(API,{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+session.access_token},body:JSON.stringify(body)}); const d=await r.json();
      if(!r.ok||!d.ok) throw new Error(d.error||'Ошибка');
      g('ptR').innerHTML=d.until?`<span style="color:var(--ok)">Готово: Premium у ${E(d.name||d.username)} до ${new Date(d.until).toLocaleString('ru-RU')}. Сообщение в бот отправлено, если у пользователя включены уведомления Telegram.</span>`
        :`<span style="color:var(--ok)">Готово: ${E(d.name||d.username)} получил(а) ${d.added} люменов. Баланс: ${d.balance}.</span>`;
      toast('Тестовая покупка выполнена');
    }catch(e){ g('ptR').innerHTML='<span style="color:var(--danger)">'+E(e.message||e)+'</span>'; }
    btn.disabled=false; };
}
function addRow(){
  if(!isOwner()) return; const a=document.getElementById('sAdmin'); if(!a||document.getElementById('sPayTest')) return;
  a.insertAdjacentHTML('afterend',srow('sPayTest','lxsend','#2bd67b','Тест оплаты','Проверка покупки Premium и люменов по юзернейму'));
  const r=document.getElementById('sPayTest'); if(r) r.onclick=payTest; }
const rs1=renderSettings;
renderSettings=function(){ const r=rs1.apply(this,arguments); return r; };
}catch(e){ console.warn('pay test',e); }
})();

/* Открыть в приложении: только при запуске с иконки (PWA) и только если у аккаунта есть живой сеанс приложения на этой платформе */
(function(){ const sa=()=>{ try{ return matchMedia('(display-mode: standalone)').matches||navigator.standalone===true; }catch{ return false; } };
 if(!sa()) return; const plat=/iPhone|iPad|iPod/i.test(navigator.userAgent)?'ios':(/Android/i.test(navigator.userAgent)?'android':null); if(!plat) return;
 let tries=0; const t=setInterval(async()=>{ if(++tries>90) return clearInterval(t); if(!sb||!S.me||!S.me.id) return; clearInterval(t);
  try{ if(sessionStorage.getItem('lx_openapp')) return; }catch{}
  try{ const since=new Date(Date.now()-30*864e5).toISOString(); const {data}=await sb.from('lm_sessions').select('id').eq('user_id',S.me.id).eq('platform',plat).eq('revoked',false).gt('last_active',since).limit(1); if(!data||!data.length) return; }catch{ return; }
  try{ sessionStorage.setItem('lx_openapp','1'); }catch{}
  modal('Открыть в приложении?','<p style="margin:0;color:var(--muted)">У вас установлено приложение Lumo — в нём быстрее работают звонки, уведомления и шифрование.</p>',[['Остаться','ghost'],['Открыть','primary',c=>{ c(); location.href='lumo://open'; }]]);
 },1000); })();
/* ===== LF: «Ответить позже», «Не беспокоить» + «Срочно», «Капсула времени», серии-огоньки ===== */
(function(){
const LF={rem:[],remPrev:new Map(),dnd:null,peers:new Map(),streaks:new Map(),caps:new Map(),capViews:new Map(),urgent:false,timers:[]};
const R=async(n,a)=>{ const {data,error}=await sb.rpc(n,a||{}); if(error) throw new Error(error.message); return data; };
const RU_M=['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];
const hm=d=>String(d.getHours()).padStart(2,'0')+':'+String(d.getMinutes()).padStart(2,'0');
const sameD=(a,b)=>a.getFullYear()===b.getFullYear()&&a.getMonth()===b.getMonth()&&a.getDate()===b.getDate();
function future(d){ d=new Date(d); const n=new Date(); if(sameD(d,n)) return 'сегодня в '+hm(d); const t=new Date(); t.setDate(t.getDate()+1); if(sameD(d,t)) return 'завтра в '+hm(d); return d.getDate()+' '+RU_M[d.getMonth()]+' в '+hm(d); }
function fullD(d){ d=new Date(d); return d.getDate()+' '+RU_M[d.getMonth()]+' '+d.getFullYear()+', '+hm(d); }
function untilT(d){ const f=future(d); d=new Date(d); return f.startsWith('сегодня')?'до '+hm(d):f.startsWith('завтра')?'до завтра '+hm(d):'до '+d.getDate()+' '+RU_M[d.getMonth()]+' '+hm(d); }
function days(n){ const a=n%10,b=n%100; return a===1&&b!==11?'день':(a>=2&&a<=4&&(b<10||b>=20))?'дня':'дней'; }
function plur(n,a,b,c){ const x=n%10,y=n%100; return x===1&&y!==11?a:(x>=2&&x<=4&&(y<10||y>=20))?b:c; }
const localDT=d=>{ d=new Date(d); const z=new Date(d.getTime()-d.getTimezoneOffset()*6e4); return z.toISOString().slice(0,16); };
const inp='style="width:100%;box-sizing:border-box;font:inherit;padding:12px;border-radius:12px;border:1px solid rgba(127,127,127,.3);background:var(--panel);color:var(--text)"';

/* ---------- стили ---------- */
const css=document.createElement('style'); css.textContent=`
.lfchips{display:flex;flex-wrap:wrap;gap:8px;margin:8px 0}.lfchip{border:0;border-radius:12px;padding:10px 12px;background:var(--panel2,rgba(127,127,127,.12));color:var(--text);font:inherit;font-weight:600;cursor:pointer}
.lfchip.on{background:linear-gradient(135deg,#7c5cff,#4f7cff);color:#fff}.lfchip.or.on{background:linear-gradient(135deg,#ffb347,#ff6a3d)}
.lfsec{font-size:12px;font-weight:800;color:var(--muted);margin:14px 2px 4px;letter-spacing:.3px}
.lflist{display:flex;flex-direction:column;border-radius:16px;overflow:hidden;background:var(--panel2,rgba(127,127,127,.08))}
.lfli{display:flex;align-items:center;gap:12px;padding:13px 14px;cursor:pointer;border-bottom:1px solid rgba(127,127,127,.12)}.lfli:last-child{border-bottom:0}.lfli:hover{background:rgba(127,127,127,.08)}
.lfli .r{margin-left:auto;color:var(--muted);font-size:13px;white-space:nowrap}
.lfbar{display:flex;align-items:center;gap:12px;margin:6px 10px;padding:10px 12px;border-radius:16px;background:var(--panel2,rgba(127,127,127,.1));cursor:pointer}
.lfbar .bi{width:34px;height:34px;border-radius:50%;display:grid;place-items:center;background:linear-gradient(135deg,#ffb347,#ff6a3d);color:#fff;font-size:17px;flex:none}
.lfbar b{display:block;font-size:15px}.lfbar span{font-size:13px;color:var(--muted)}
.lfbtn{width:100%;border:0;border-radius:16px;height:50px;font:inherit;font-weight:800;font-size:16px;color:#fff;cursor:pointer;background:linear-gradient(135deg,#7c5cff,#4f7cff)}
.lfbtn.or{background:linear-gradient(135deg,#ff8a3d,#e8336a)}.lfbtn.red{background:rgba(255,91,122,.14);color:#ff5b7a}.lfbtn:disabled{opacity:.6}
.lfurg{display:flex;align-items:center;gap:10px;padding:8px 14px 2px;font-size:13px}.lfurg .tx{flex:1;min-width:0}.lfurg .tx b{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.lfurg .tx span{color:var(--muted);font-size:12px}.lfurg .tx span.on{color:#ff7a1a}
.lfurgb{border:0;border-radius:20px;padding:7px 12px;font:inherit;font-weight:800;font-size:13px;cursor:pointer;background:rgba(127,127,127,.14);color:var(--text)}.lfurgb.on{background:linear-gradient(135deg,#ffb020,#ff4d3d);color:#fff}
.lftag{display:inline-flex;align-items:center;gap:3px;padding:2px 8px;border-radius:10px;background:linear-gradient(135deg,#ffb020,#ff4d3d);color:#fff;font-size:10.5px;font-weight:900;margin-bottom:3px}
.lfcapb{width:250px;max-width:78vw;border-radius:20px!important;background:linear-gradient(#fff6e6,#ffe9c7)!important;border:1px solid #e8c48c;color:#3b2a14!important;padding:12px!important;box-sizing:border-box}
.lfcapb .hd{font-size:11.5px;font-weight:900;color:#b07a2a;letter-spacing:.6px;margin-bottom:8px}.lfcapb .env{display:grid;place-items:center;cursor:pointer;padding:4px 0 12px}.lfcapb .env svg{width:168px!important;height:auto!important;max-width:100%}
.lfcapb .env.shake{animation:lfsh .4s}.lfcapb .env.crack svg .ck{opacity:1}.lfcapb .env.pop{animation:lfpop .6s}
@keyframes lfsh{0%,100%{transform:none}20%{transform:translateX(-10px)}40%{transform:translateX(9px)}60%{transform:translateX(-6px)}80%{transform:translateX(3px)}}
@keyframes lfpop{0%{transform:scale(1)}50%{transform:scale(1.12) rotate(-3deg)}100%{transform:scale(.2);opacity:0}}
.lfcapb .cd{text-align:center}.lfcapb .cd small{display:block;color:#8a6a3e;font-size:12.5px}.lfcapb .cd b{display:block;font-size:20px;font-weight:900}
.lfcapb .ct{white-space:pre-wrap;word-break:break-word;font-size:15.5px}.lfcapb img{width:100%;border-radius:14px;display:block;margin-bottom:8px;cursor:pointer}
.lfcapb .ft{color:#8a6a3e;font-size:12px;margin-top:6px}.lfcapb .tm{text-align:right;color:#8a6a3e;font-size:11.5px}
.lfpill{display:inline-flex;align-items:center;gap:6px;padding:7px 14px;border-radius:20px;font-size:13px;font-weight:600;cursor:pointer;border:0;font-family:inherit}
.lfpill.gift{background:linear-gradient(90deg,#fff1d6,#ffe0b0);color:#8a5a1a}.lfpill.fire{background:linear-gradient(90deg,#ffe3b8,#ffc2a0);color:#8a3a0a}.lfpill.ash{background:linear-gradient(90deg,#dadce2,#c4c7cf);color:#55585f}
.lfst{display:inline-flex;align-items:center;gap:1px;margin-left:4px;font-weight:900;font-size:14px;vertical-align:middle;cursor:pointer}.lfst.on{color:#ff7a1a}.lfst.off{color:var(--muted)}
.lfsheet{text-align:center}.lfsheet .avs{display:flex;justify-content:center;margin:6px 0 14px}.lfsheet .avs>div{border:3px solid var(--bg,#fff);border-radius:50%;margin:0 -14px}
.lfsheet h2{font-size:22px;font-weight:900;margin:6px 0 10px;display:flex;align-items:center;justify-content:center;gap:4px;flex-wrap:wrap}
.lfsheet ul{text-align:left;color:var(--muted);font-size:15px;padding-left:20px;margin:0 0 16px}.lfsheet li{margin:6px 0}
.lflv{display:flex;align-items:center;margin:8px 0 6px}.lflv i{flex:1;height:3px;border-radius:2px;background:rgba(127,127,127,.25)}.lflv i.on{background:#ff9a3d}
.lflv div{display:flex;flex-direction:column;align-items:center;gap:3px;font-size:12.5px;color:var(--muted)}.lflv div.on{color:var(--text);font-weight:700}
.lfok{width:100%;border:0;border-radius:30px;height:52px;background:#e8455a;color:#fff;font:inherit;font-weight:800;font-size:17px;cursor:pointer;margin-top:12px}
.lfflame{animation:lfbob 1.8s ease-in-out infinite}@keyframes lfbob{0%,100%{transform:rotate(-8deg)}50%{transform:translateY(-6px) rotate(8deg)}}
.ov .mb:has(.lfwrap){overflow-x:hidden;overscroll-behavior:contain;text-align:left}
.lfwrap{max-width:100%;min-width:0;overflow:hidden}
.lfwrap input,.lfwrap textarea{display:block;max-width:100%;min-width:0;-webkit-appearance:none;appearance:none}
.lfwrap input[type=datetime-local]{text-align:left;min-height:46px}
.lfadd{width:100%;display:flex;align-items:center;justify-content:center;gap:8px}.lfadd svg.i{width:20px;height:20px}
.lfbtn{display:flex;align-items:center;justify-content:center;gap:8px}.lfbtn svg.i{width:20px;height:20px}
.lfli .lic{width:26px;display:grid;place-items:center;color:var(--a1)}.lfbar .bi svg.i{width:18px;height:18px}
.lfwrap .lfchips{gap:6px;margin:6px 0}.lfwrap .lfchip{padding:8px 11px;font-size:14px;border-radius:11px}.lfwrap textarea{min-height:72px}.lfwrap .lfadd{padding:9px}.lfwrap .lfbtn{height:48px}.lfwrap .lfsec{margin:10px 2px 2px}
.lfbig svg.i{width:46px;height:46px;stroke-width:1.6;color:#7c5cff}
#mw>.day{transition:opacity .18s}#mw>.day.lfdh{opacity:0;pointer-events:none}
.lfsheet ul.lful{padding:0}.lful{list-style:none;padding:0;margin:6px 0 14px;text-align:left}.lful li{display:flex;gap:10px;align-items:flex-start;color:var(--muted);font-size:15px;margin:8px 0}
.lfli2{flex:none;width:24px;height:24px;display:grid;place-items:center;color:#ff7a1a}.lfli2 svg.i{width:19px;height:19px}.lfli2.n{border-radius:50%;background:#ff7a1a;color:#fff;font-weight:800;font-size:13px;width:22px;height:22px}
.lfmw{display:flex;justify-content:center;margin:-34px 0 2px;position:relative;z-index:1}.lfmw.big{margin:0 0 4px}
.lfmascot{animation:lfsq 1.6s ease-in-out infinite;transform-origin:50% 100%}@keyframes lfsq{0%,100%{transform:scale(.97,1.03)}50%{transform:scale(1.03,.97)}}
.lfmascot .lfeye{animation:lfblink 3.4s infinite;transform-origin:center;transform-box:fill-box}@keyframes lfblink{0%,94%,100%{transform:scaleY(1)}96%{transform:scaleY(.1)}}
.lfgo{display:flex;align-items:center;justify-content:center;gap:8px;background:linear-gradient(90deg,#ffa318,#ff5a2a)!important}
.lfcel{position:fixed;inset:0;z-index:100100;display:grid;place-items:center;background:rgba(0,0,0,0);transition:background .3s;cursor:pointer}
.lfcel.on{background:rgba(0,0,0,.62)}.lfcel.off{background:rgba(0,0,0,0)}
.lfcb{position:relative;text-align:center;color:#fff;padding:20px;max-width:360px}.lfcb h2{font-size:26px;font-weight:900;margin:8px 0 6px}.lfcb p{opacity:.85;margin:0 0 16px}
.lfcb>*{opacity:0;transform:scale(.4);transition:opacity .35s,transform .6s cubic-bezier(.2,1.6,.4,1)}.lfcel.on .lfcb>*{opacity:1;transform:none}.lfcel.off .lfcb>*{opacity:0;transform:scale(.8);transition:.22s}
.lfglow{position:absolute;left:50%;top:120px;width:300px;height:300px;margin:-150px 0 0 -150px;border-radius:50%;background:radial-gradient(circle,rgba(255,179,71,.75),transparent 70%);animation:lfglow 2.2s ease-in-out infinite}
@keyframes lfglow{0%,100%{transform:scale(.88)}50%{transform:scale(1.12)}}
.lfbigf{position:relative;height:200px;display:flex;align-items:flex-end;justify-content:center}.lfbigf svg{animation:lfsway 2.2s ease-in-out infinite;transform-origin:50% 100%}@keyframes lfsway{0%,100%{transform:rotate(-3deg)}50%{transform:rotate(3deg)}}
.lfnum{font-size:64px;font-weight:900;text-shadow:0 0 18px rgba(255,106,0,.85);position:relative}
.lfsp{position:absolute;left:50%;top:120px;width:0;height:0}.lfsp i{position:absolute;width:7px;height:7px;border-radius:50%;opacity:0;animation:lfspark 1.8s ease-out infinite;animation-delay:var(--d)}
@keyframes lfspark{0%{transform:translate(0,0) scale(1);opacity:1}100%{transform:translate(var(--x),var(--y)) scale(.3);opacity:0}}
.lfchip.lfic{display:inline-flex;align-items:center;gap:6px}.lfchip svg.i{width:17px;height:17px}.lfurgb{display:inline-flex;align-items:center;gap:4px}.lfurgb svg.i{width:15px;height:15px}.lfcapb .hd{display:flex;align-items:center;gap:5px}.lfcapb .hd svg.i{width:14px;height:14px}.lfpill svg.i{width:15px;height:15px}.lftag svg.i{width:11px;height:11px;stroke-width:2.6}
.wza{animation:wzFade .25s ease both}.wza.bye{animation:wzFadeOut .25s ease both}
.wza .sh.up{animation:wzUp .34s cubic-bezier(.2,.9,.3,1) both}.wza.bye .sh{animation:wzDown .25s ease-in both}
.wza .sh>.wzwh+*{animation:wzIn .26s ease both}
.wzw{animation:tgWzIn .34s cubic-bezier(.2,.9,.3,1) both}.wzw.out{animation:tgWzOut .26s ease both;pointer-events:none}
@keyframes tgWzIn{from{opacity:0;transform:translateY(24px) scale(.985)}to{opacity:1;transform:none}}
@keyframes tgWzOut{from{opacity:1;transform:none}to{opacity:0;transform:translateY(24px) scale(.985)}}
.wztabs button{transition:background .2s,color .2s}.wztabs button.on{animation:wzOn .25s ease}
.wztabs b{display:grid;place-items:center;height:26px}.wztabs b svg.i{width:24px;height:24px}
.wzrow i{display:grid;place-items:center}.wzrow i svg.i{width:22px;height:22px}
.wza svg.i.big46{width:54px;height:54px;stroke-width:1.6;color:var(--a1)}
#emoji:not(.hidden){animation:wzIn .22s ease both}
@keyframes wzFade{from{opacity:0}to{opacity:1}}@keyframes wzFadeOut{from{opacity:1}to{opacity:0}}
@keyframes wzUp{from{transform:translateY(100%)}to{transform:none}}@keyframes wzDown{from{transform:none}to{transform:translateY(100%)}}
@keyframes wzIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}@keyframes wzOn{from{background:transparent}}
`; document.head.appendChild(css);
Object.assign(P,{geo:'<path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>',
 poll:'<path d="M5 20V10M12 20V4M19 20v-7"/>',music:'<path d="M9 18V5l11-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>',
 cloud:'<path d="M7 18a5 5 0 0 1-.6-9.96A6 6 0 0 1 18 9a4.5 4.5 0 0 1-.5 9z"/>',
 radar:'<circle cx="12" cy="12" r="2"/><path d="M16.2 7.8a6 6 0 0 1 0 8.4M7.8 16.2a6 6 0 0 1 0-8.4M19 5a10 10 0 0 1 0 14M5 19A10 10 0 0 1 5 5"/>',
 hourglass:'<path d="M6 2h12M6 22h12M7 2c0 5 5 6 5 10s-5 5-5 10M17 2c0 5-5 6-5 10s5 5 5 10"/>',
 sun:'<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
 cup:'<path d="M4 8h13v5a6 6 0 0 1-6 6h-1a6 6 0 0 1-6-6z"/><path d="M17 10h1.5a2.5 2.5 0 0 1 0 5H17M8 2v3M12 2v3"/>',
 bolt:'<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>',gift:'<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13M5 12v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-8M8 8a2.5 2.5 0 1 1 4-2M16 8a2.5 2.5 0 1 0-4-2"/>',
 flame:'<path d="M12 22c-4 0-7-2.8-7-6.6 0-3 1.9-5 3.6-6.8.2 1.6 1 2.6 2 3-0.4-3.6 1.4-6.6 4.4-8.6-.2 2.6 1 4.2 2.5 5.8 1.3 1.4 2.5 3.2 2.5 5.9C20 19 16.5 22 12 22z"/>'});

/* ---------- рисунки ---------- */
function flameColors(lv,lit){ if(!lit) return ['#d9d9de','#9ea0a8','#9ea0a8'];
  return lv>=200?['#ffe27a','#b45cff','#5b2bff']:lv>=100?['#b6f0ff','#3fa9ff','#2155ff']:lv>=30?['#ffd1f0','#ff4fa3','#e0145a']:lv>=10?['#ffe07a','#ff5a2a','#d9141e']:['#ffe680','#ffa318','#ff6a00']; }
let fid=0;
function flame(lv,lit,w=14,h=17,cls=''){ const c=flameColors(lv,lit); const id='lff'+(++fid);
  const extra=lv>=30&&lit?' C80 32 84 26 88 20 C96 40 98 55 96 65':'';
  return `<svg class="${cls}" width="${w}" height="${h}" viewBox="0 0 100 100" preserveAspectRatio="none" style="flex:none"><defs><linearGradient id="${id}a" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c[1]}"/><stop offset="1" stop-color="${c[2]}"/></linearGradient><linearGradient id="${id}b" x1="0" y1=".44" x2="0" y2="1"><stop offset="0" stop-color="${c[0]}"/><stop offset="1" stop-color="#fff" stop-opacity="${lit?.9:.6}"/></linearGradient></defs>`
   +`<path fill="url(#${id}a)" d="M50 98 C12 98 2 62 20 38 C24 52 32 56 36 55 C30 30 44 10 60 2 C58 22 70 30 78 40${extra} C100 84 82 98 50 98Z"/>`
   +`<path fill="url(#${id}b)" d="M50 96 C30 96 26 76 36 64 C42 70 46 70 48 68 C46 56 52 48 60 44 C62 56 74 66 72 80 C70 92 62 96 50 96Z"/></svg>`; }
function envelope(w=210,h=140,opened=false){
  // пропорции конверта не искажаются: рисунок 150×100, флап и печать — внутри скруглённого корпуса
  const cx=75, cy=56;
  const seal=[]; for(let i=0;i<16;i++){ const a=i/16*Math.PI*2, r=(i%2?0.88:1)*14; seal.push((cx+Math.cos(a)*r).toFixed(1)+','+(cy+Math.sin(a)*r).toFixed(1)); }
  const star=[]; for(let i=0;i<10;i++){ const a=i/10*Math.PI*2-Math.PI/2, r=i%2?2.8:6.6; star.push((cx+Math.cos(a)*r).toFixed(1)+','+(cy+Math.sin(a)*r).toFixed(1)); }
  const hh=Math.round(w*(opened?0.81:0.667));
  return `<svg width="${w}" height="${hh}" viewBox="${opened?'0 -22 150 122':'0 0 150 100'}" preserveAspectRatio="xMidYMid meet" style="display:block;overflow:visible"><defs><linearGradient id="lfe1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f8e6c6"/><stop offset="1" stop-color="#e6c08a"/></linearGradient><linearGradient id="lfe2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f2d7a9"/><stop offset="1" stop-color="#dcb173"/></linearGradient><radialGradient id="lfe3" cx=".4" cy=".38" r=".75"><stop offset="0" stop-color="#ff6074"/><stop offset="1" stop-color="#b3122e"/></radialGradient><clipPath id="lfe4"><rect x="3" y="6" width="144" height="92" rx="11"/></clipPath><filter id="lfe5" x="-20%" y="-20%" width="140%" height="160%"><feDropShadow dx="0" dy="3" stdDeviation="3" flood-color="#8a5a1e" flood-opacity=".22"/></filter></defs>`
   +`<g filter="url(#lfe5)"><rect x="3" y="6" width="144" height="92" rx="11" fill="url(#lfe1)"/></g><g clip-path="url(#lfe4)"><path d="M3 98 L75 52 L147 98" fill="none" stroke="#c9a36a" stroke-width="1.2" stroke-linejoin="round"/>`
   +(opened?`</g><path d="M6 8 L75 -18 L144 8 Z" fill="url(#lfe2)" stroke="#b8894a" stroke-width="1" stroke-linejoin="round"/>`:`<path d="M3 6 L75 ${cy+4} L147 6 Z" fill="url(#lfe2)" stroke="#b8894a" stroke-width="1" stroke-linejoin="round"/></g><polygon points="${seal.join(' ')}" fill="url(#lfe3)"/><circle cx="${cx}" cy="${cy}" r="9" fill="none" stroke="#fff" stroke-opacity=".38" stroke-width="1"/><polygon points="${star.join(' ')}" fill="#ffd2d8" fill-opacity=".92"/><path class="ck" d="M63 53 L73 58 L78 51 L88 57" fill="none" stroke="#fff" stroke-width="1.6" opacity="0"/>`)
   +`</svg>`; }

/* ---------- Ответить позже ---------- */
async function remLoad(){ try{ LF.rem=await R('lm_remind_list')||[]; }catch{ return; }
  const need=LF.rem.map(r=>r.message_id).filter(id=>!LF.remPrev.has(id));
  if(need.length){ const {data}=await sb.from('lm_messages').select('*').in('id',need); for(const m of (data||[])){ await E2E.dec(m); LF.remPrev.set(m.id,m); } await ensureProfiles((data||[]).map(m=>m.sender_id)); }
  remSchedule(); if(S.tab==='chats'&&!S.q) renderList(); }
function remSchedule(){ LF.timers.forEach(clearTimeout); LF.timers=[];
  for(const r of LF.rem){ const ms=new Date(r.remind_at)-Date.now(); if(ms<0||ms>2147483000) continue;
    LF.timers.push(setTimeout(()=>remFire(r),ms)); } }
function remText(r){ const m=LF.remPrev.get(r.message_id); return m?(profName(m.sender_id)+' — «'+plain(m.kind==='text'?m.body:(kindLabel(m.kind,m.body)?.[1]||'сообщение')).slice(0,90)+'»'):'Сообщение'; }
function remFire(r){ const body='Вы хотели ответить: '+remText(r);
  try{ beep(880,.09); setTimeout(()=>beep(1320,.12),90); }catch{}
  showNote('Ответить позже',{body,icon:NOTE_ICON,tag:'remind-'+r.message_id},()=>remOpen(r));
  const close=modal('Ответить позже',`<p style="margin:0 0 6px;color:var(--muted)">${esc(body)}</p>`,[['Позже','ghost'],['Ответить','primary',c=>{ c(); remOpen(r); }]]); }
async function remOpen(r){ S.tab='chats'; try{ await openChat(r.chat_id); }catch{}
  let m=findMsg(r.message_id)||LF.remPrev.get(r.message_id);
  if(!m){ const {data}=await sb.from('lm_messages').select('*').eq('id',r.message_id).maybeSingle(); if(data){ await E2E.dec(data); m=data; } }
  if(!m) return; S.reply=m; S.edit=null; renderCtx(); try{ jumpTo(m.id); }catch{} setTimeout(()=>$('#txt')?.focus(),300);
  remDel(m.id); }
async function remDel(id){ try{ await R('lm_remind_del',{p_msg:id}); }catch{} LF.rem=LF.rem.filter(r=>r.message_id!==id); remSchedule(); renderList(); }
function remPick(m){
  const now=Date.now(); const opts=[['clock','Через час',new Date(now+36e5)]];
  const ev=new Date(); ev.setHours(20,0,0,0); if(ev-now>18e5) opts.push(['moon','Сегодня вечером',ev]);
  const mo=new Date(); mo.setDate(mo.getDate()+1); mo.setHours(9,0,0,0); opts.push(['sun','Завтра утром',mo]);
  const we=new Date(); we.setHours(10,0,0,0); while(we.getDay()!==6||we-now<36e5) we.setDate(we.getDate()+1); opts.push(['cup','В выходные',we]);
  const pv=plain(m.kind==='text'?m.body:(kindLabel(m.kind,m.body)?.[1]||'')).slice(0,120);
  const close=modal('Ответить позже',`<p style="margin:0 0 10px;color:var(--muted)">Напомню и открою это сообщение</p><div style="padding:10px 12px;border-radius:12px;background:rgba(127,127,127,.1);color:var(--muted);margin-bottom:10px">«${esc(pv)}»</div>
   <div class="lflist">${opts.map((o,i)=>`<div class="lfli" data-ri="${i}"><span class="lic">${ic(o[0])}</span><b>${o[1]}</b><span class="r">${future(o[2])}</span></div>`).join('')}</div>
   <div class="lfsec">СВОЁ ВРЕМЯ</div><div style="display:flex;gap:8px"><input type="datetime-local" id="lfRAt" value="${localDT(now+36e5*3)}" ${inp}><button class="btn primary" id="lfRGo">ОК</button></div>`);
  const go=async d=>{ close(); try{ await R('lm_remind_set',{p_msg:m.id,p_at:d.toISOString()}); LF.remPrev.set(m.id,m); toast('Напомню '+future(d)); remLoad(); }catch(e){ toast(e.message); } };
  document.querySelectorAll('[data-ri]').forEach(el=>el.onclick=()=>go(opts[+el.dataset.ri][2]));
  document.getElementById('lfRGo').onclick=()=>{ const v=document.getElementById('lfRAt').value; if(!v) return; const d=new Date(v); if(d-Date.now()<6e4) return toast('Выберите время в будущем'); go(d); };
}
function remList(){
  const items=[...LF.rem].sort((a,b)=>new Date(a.remind_at)-new Date(b.remind_at));
  const close=modal('Ждут ответа',items.length?`<div class="lflist">${items.map(r=>{ const c=S.chatMap.get(r.chat_id);
     return `<div class="lfli" data-ro="${r.message_id}">${c?chatAv(c,'s'):''}<div style="min-width:0;flex:1"><b style="display:block">${esc(c?chatName(c):'Чат')}</b><span style="color:var(--muted);font-size:14px;display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(remText(r))}</span></div><span class="r" style="${new Date(r.remind_at)<new Date()?'color:#ff6a3d':''}">${future(r.remind_at)}</span><button class="ib" data-rx="${r.message_id}">${ic('x')}</button></div>`; }).join('')}</div>`
    :'<div style="text-align:center;padding:30px;color:var(--muted)">Вы на всё ответили</div>');
  document.querySelectorAll('[data-rx]').forEach(b=>b.onclick=e=>{ e.stopPropagation(); remDel(+b.dataset.rx); b.closest('.lfli').remove(); });
  document.querySelectorAll('[data-ro]').forEach(b=>b.onclick=()=>{ const r=LF.rem.find(x=>x.message_id===+b.dataset.ro); close(); if(r) remOpen(r); });
}
window.lfRemBar=()=>{ if(!LF.rem.length||S.folder!=='all') return ''; const f=[...LF.rem].sort((a,b)=>new Date(a.remind_at)-new Date(b.remind_at))[0];
  return `<div class="lfbar" id="lfRemBar"><span class="bi">${ic('bell')}</span><div style="flex:1"><b>Ждут ответа · ${LF.rem.length}</b><span>Ближайшее — ${future(f.remind_at)}</span></div>${ic('down','mini rot')}</div>`; };

/* ---------- Не беспокоить ---------- */
const dndActive=()=>!!(LF.dnd&&LF.dnd.until&&new Date(LF.dnd.until)>new Date());
async function dndLoad(){ try{ LF.dnd=await R('lm_my_dnd'); }catch{ return; } dndRemember(); dndCheckEnded(); }
function dndRemember(){ if(!dndActive()) return; localStorage.setItem('lf_dnd_until',new Date(LF.dnd.until).getTime()); if(!localStorage.getItem('lf_dnd_from')) localStorage.setItem('lf_dnd_from',Date.now());
  setTimeout(dndCheckEnded,Math.min(2147483000,Math.max(1000,new Date(LF.dnd.until)-Date.now()+500))); }
async function dndCheckEnded(){ const u=+localStorage.getItem('lf_dnd_until')||0; if(!u||Date.now()<u||dndActive()) return; dndSummary(); }
async function dndSummary(){ const from=+localStorage.getItem('lf_dnd_from')||0; localStorage.removeItem('lf_dnd_until'); localStorage.removeItem('lf_dnd_from'); if(!from) return;
  try{ const j=await R('lm_dnd_summary',{p_from:new Date(from).toISOString(),p_to:new Date().toISOString()});
    const n=j.msgs||0,c=j.chats||0,u=j.urgent||0;
    modal('Пока вас не было',`<p style="margin:0">${n?`${n} ${plur(n,'сообщение','сообщения','сообщений')} в ${c} ${plur(c,'чате','чатах','чатах')}. ${u?'Срочных: '+u+'.':'Срочных не было.'}`:'Пока вы были в режиме «Не беспокоить», новых сообщений не было.'}</p>`,[['Хорошо','primary']]); }catch{} }
async function dndSet(until,text,urgent){ const was=dndActive();
  await R('lm_set_dnd',{p_until:until?until.toISOString():null,p_text:text||'',p_urgent:urgent});
  LF.dnd={until:until?until.toISOString():null,text,urgent};
  if(until&&!was) localStorage.setItem('lf_dnd_from',Date.now());
  if(!until&&was) dndSummary(); dndRemember(); renderSettings(); }
function dndDlg(){
  const st=['Сплю','На встрече','За рулём','Занят','В дороге','Свой'], du=[['1 час',1],['2 часа',2],['4 часа',4],['До утра',-1],['До завтра',24]];
  let s=st[0], d=-1, urg=(LF.dnd&&LF.dnd.urgent)||'contacts', custom='';
  const untilOf=()=>{ if(d===-1){ const c=new Date(); c.setHours(8,0,0,0); if(c<=new Date()) c.setDate(c.getDate()+1); return c; } return new Date(Date.now()+d*36e5); };
  const o=document.createElement('div'); let close;
  const draw=()=>{ const on=dndActive();
    const urgH=`<div class="lfsec">КТО МОЖЕТ НАПИСАТЬ СРОЧНО</div><div class="lflist">${[['all','Все'],['contacts','Только контакты'],['none','Никто']].map(([k,t])=>`<div class="lfli" data-ug="${k}"><b style="font-weight:500">${t}</b><span class="r">${urg===k?ic('check'):''}</span></div>`).join('')}</div>
      <p style="font-size:12.5px;color:var(--muted);margin:8px 2px 0">Срочное сообщение приходит со звуком даже в этом режиме. Каждый может отправить вам не больше одного срочного в сутки. Если сообщение было не срочным — откройте его меню и выберите «Это было не срочно»: человек на неделю потеряет эту возможность.</p>`;
    o.innerHTML=on?`<div style="text-align:center"><div class="lfbig">${ic('moon')}</div><h3 style="margin:6px 0">${esc(LF.dnd.text||'Не беспокоить')} ${untilT(LF.dnd.until)}</h3><p style="color:var(--muted);margin:0 0 12px">Сообщения приходят без звука. Срочные — со звуком.</p><button class="lfbtn red" id="lfDOff">Выключить</button></div>${urgH}`
     :`<p style="color:var(--muted);margin:0 0 6px">Собеседники увидят ваш статус, а сообщения придут без звука. Если что-то правда важное — вам смогут написать срочно.</p>
      <div class="lfsec">СТАТУС</div><div class="lfchips">${st.map(x=>`<button class="lfchip lfic ${x===s?'on':''}" data-st="${x}">${ic(dndIc(x))}${x}</button>`).join('')}</div>
      ${s==='Свой'?`<input id="lfDTx" maxlength="40" placeholder="Например: На тренировке" value="${esc(custom)}" ${inp}>`:''}
      <div class="lfsec">НА СКОЛЬКО</div><div class="lfchips">${du.map(([t,v])=>`<button class="lfchip ${v===d?'on':''}" data-du="${v}">${t}</button>`).join('')}</div>
      <div style="font-size:13px;color:var(--muted);margin:2px 2px 12px">Выключится ${untilT(untilOf()).replace('до ','в ')}</div>
      <button class="lfbtn" id="lfDOn">${ic('moon')}Включить</button>${urgH}`;
    o.querySelectorAll('[data-st]').forEach(b=>b.onclick=()=>{ s=b.dataset.st; draw(); });
    o.querySelectorAll('[data-du]').forEach(b=>b.onclick=()=>{ d=+b.dataset.du; draw(); });
    const tx=o.querySelector('#lfDTx'); if(tx) tx.oninput=()=>custom=tx.value;
    o.querySelectorAll('[data-ug]').forEach(b=>b.onclick=async()=>{ urg=b.dataset.ug; draw(); if(dndActive()) try{ await dndSet(new Date(LF.dnd.until),LF.dnd.text,urg); }catch(e){ toast(e.message); } });
    const off=o.querySelector('#lfDOff'); if(off) off.onclick=async()=>{ off.disabled=true; try{ await dndSet(null,LF.dnd.text,urg); draw(); }catch(e){ toast(e.message); off.disabled=false; } };
    const go=o.querySelector('#lfDOn'); if(go) go.onclick=async()=>{ go.disabled=true; const t=s==='Свой'?(custom.trim()||'Не беспокоить'):s;
      try{ await dndSet(untilOf(),t,urg); toast('«Не беспокоить» '+untilT(untilOf())); draw(); }catch(e){ toast(e.message); go.disabled=false; } };
  };
  close=modal('Не беспокоить','<div id="lfDnd"></div>'); document.getElementById('lfDnd').appendChild(o); draw();
}
async function peersLoad(ids){ ids=[...new Set(ids)].filter(u=>u&&u!==S.me.id); if(!ids.length) return;
  try{ const a=await R('lm_dnd_get',{p_ids:ids}); for(const u of ids) LF.peers.delete(u); for(const j of (a||[])) if(new Date(j.dnd_until)>new Date()) LF.peers.set(j.id,j); }catch{} }
const dndIc=t=>{ t=String(t||'').toLowerCase(); return /сплю|сон/.test(t)?'moon':/встреч/.test(t)?'clock':/рул/.test(t)?'phone':/занят/.test(t)?'volume':/дорог|самол/.test(t)?'arrin':t==='свой'?'edit':'moon'; };
const peerDnd=u=>{ const j=u&&LF.peers.get(u); return j&&new Date(j.dnd_until)>new Date()?j:null; };
window.lfDnd=u=>{ const j=peerDnd(u); return j?(j.dnd_text||'Не беспокоить')+' '+untilT(j.dnd_until)+' · без звука':null; };
window.lfQuiet=()=>dndActive();
function urgStrip(){ let el=document.getElementById('lfurg'); const c=cur(); const j=c&&c.type==='private'?peerDnd(c.peer_id):null;
  if(!j){ el&&el.remove(); LF.urgent=false; return; }
  if(!el){ el=document.createElement('div'); el.id='lfurg'; el.className='lfurg'; const comp=document.getElementById('composer'); if(!comp) return; comp.insertBefore(el,comp.firstChild); }
  el.innerHTML=`<span style="display:grid;color:#7c5cff">${ic('moon')}</span><div class="tx"><b>${esc(chatName(c))}: ${esc(j.dnd_text||'Не беспокоить')} ${untilT(j.dnd_until)}</b><span class="${LF.urgent?'on':''}">${LF.urgent?'Сообщение придёт со звуком — только если правда важно':'Сообщения придут без звука'}</span></div>${j.urgent_ok?`<button class="lfurgb ${LF.urgent?'on':''}" id="lfUrgB">${ic('bolt')}Срочно</button>`:''}`;
  const b=el.querySelector('#lfUrgB'); if(b) b.onclick=()=>{ LF.urgent=!LF.urgent; urgStrip(); $('#txt')?.focus(); }; }
window.lfUrgent=()=>{ if(!LF.urgent) return null; LF.urgent=false; setTimeout(()=>{ const c=cur(); if(c) peersLoad([c.peer_id]).then(urgStrip); },800); return {urgent:true}; };

/* ---------- Капсула времени ---------- */
function capCountdown(at){ let s=Math.max(0,Math.floor((new Date(at)-Date.now())/1000)); const d=Math.floor(s/86400),h=Math.floor(s%86400/3600),m=Math.floor(s%3600/60),x=s%60;
  return d>0?`${d} д ${h} ч ${m} мин`:h>0?`${h} ч ${m} мин ${x} с`:`${m}:${String(x).padStart(2,'0')}`; }
async function capOpen(m){ const j=await R('lm_capsule_open',{p_msg:m.id}); const pl=j.payload||{};
  const dec=async v=>v&&E2E.is(v)?await E2E.decStr(m.chat_id,v):v;
  await E2E.prepChat(m.chat_id);
  LF.caps.set(m.id,{kind:pl.kind||'text',text:await dec(pl.text),image:await dec(pl.image)}); LF.capViews.set(m.id,j.views||0); }
function capInner(m){ const meta=m.meta||{}; const at=meta.open_at||m.created_at; const mine=m.sender_id===S.me.id; const ready=new Date(at)<=new Date(); const c=LF.caps.get(m.id);
  const grp=(cur()||{}).type==='group'; const v=LF.capViews.get(m.id)||0;
  if(c&&(ready||mine)) return `${c.image?`<img src="${esc(c.image)}" data-view="${esc(c.image)}">`:''}${c.text?`<div class="ct">${esc(c.text)}</div>`:''}<div class="ft">${ready?'Открыта '+fullD(at)+(grp&&v?' · открыли: '+v:''):'Откроется '+fullD(at)+' · видно только вам'}</div>`;
  if(mine&&!c){ capOpen(m).then(()=>rerenderOne(m.id)).catch(()=>{}); }
  return `<div class="env" data-capenv="${m.id}">${envelope()}</div><div class="cd">${ready?'<b style="font-size:15px">Нажмите, чтобы открыть</b>':`<small>Откроется через</small><b data-capcd="${esc(at)}">${capCountdown(at)}</b><small>${fullD(at)}</small>`}</div>`; }
function capHtml(m){ const me=m.sender_id===S.me.id; const c=cur()||{}; const p=S.profiles.get(m.sender_id);
  const nm=c.type==='group'&&!me?`<div style="font-weight:700;font-size:13px;color:var(--a2);margin-bottom:4px">${esc(p?.name||'')}</div>`:'';
  return `<div class="m ${me?'me':''} tail grp first" data-id="${m.id}"><div class="b lfcapb">${nm}<div class="hd">${ic('hourglass')}КАПСУЛА ВРЕМЕНИ</div><div data-capin="${m.id}">${capInner(m)}</div><div class="tm">${hm(new Date(m.created_at))}</div>${reactsHtml(m)}</div></div>`; }
setInterval(()=>{ document.querySelectorAll('[data-capcd]').forEach(el=>{ const at=el.dataset.capcd; if(new Date(at)<=new Date()){ const box=el.closest('[data-capin]'); const m=box&&findMsg(+box.dataset.capin); if(m) box.innerHTML=capInner(m); } else el.textContent=capCountdown(at); }); },1000);
document.addEventListener('click',async e=>{ const env=e.target.closest&&e.target.closest('[data-capenv]'); if(!env) return; e.stopPropagation();
  const m=findMsg(+env.dataset.capenv); if(!m) return; const at=(m.meta||{}).open_at;
  if(at&&new Date(at)>new Date()){ env.classList.remove('shake'); void env.offsetWidth; env.classList.add('shake'); navigator.vibrate?.(30); toast('Ещё рано. Откроется '+fullD(at)); return; }
  if(env.dataset.busy) return; env.dataset.busy=1; env.classList.add('crack');
  try{ await capOpen(m); env.classList.add('pop'); setTimeout(()=>rerenderOne(m.id),550); }catch(err){ toast(err.message); env.classList.remove('crack'); delete env.dataset.busy; } },true);
window.lfCapsule=()=>{ const chatId=(cur()||{}).chat_id; if(!chatId) return; const replyTo=S.reply?.id||null;
  const P_=[['Завтра',()=>{ const d=new Date(); d.setDate(d.getDate()+1); d.setHours(9,0,0,0); return d; }],['Через неделю',()=>new Date(Date.now()+7*864e5)],
   ['Через месяц',()=>{ const d=new Date(); d.setMonth(d.getMonth()+1); return d; }],['Новый год',()=>new Date(new Date().getFullYear()+1,0,1,0,0,0)],['Через год',()=>{ const d=new Date(); d.setFullYear(d.getFullYear()+1); return d; }]];
  let at=P_[1][1](), sel=1, file=null, url=null;
  const close=modal('Капсула времени',`<div class="lfwrap"><div style="text-align:center;margin-bottom:4px">${envelope(96,64)}</div><p style="text-align:center;color:var(--muted);margin:0 0 8px;font-size:13px;line-height:1.35">Сообщение откроется только в выбранный момент. До этого собеседник увидит запечатанный конверт с обратным отсчётом.</p>
   <textarea id="lfCT" rows="3" maxlength="4000" placeholder="Что вы хотите сказать в будущем?" ${inp}></textarea>
   <div id="lfCPh" style="margin:8px 0"></div>
   <div class="lfsec">КОГДА ОТКРЫТЬ</div><div class="lfchips" id="lfCCh"></div>
   <input type="datetime-local" id="lfCAt" ${inp}>
   <div style="margin-top:14px"><button class="lfbtn or" id="lfCGo"></button></div></div>`);
  const fi=document.createElement('input'); fi.type='file'; fi.accept='image/*';
  const draw=()=>{ document.getElementById('lfCCh').innerHTML=P_.map((p,i)=>`<button class="lfchip or ${i===sel?'on':''}" data-cp="${i}">${p[0]}</button>`).join('');
    document.getElementById('lfCAt').value=localDT(at);
    document.getElementById('lfCGo').innerHTML=ic('lock')+'Запечатать до '+fullD(at);
    document.getElementById('lfCPh').innerHTML=url?`<div style="position:relative"><img src="${url}" style="width:100%;max-height:200px;object-fit:cover;border-radius:14px"><button class="ib" id="lfCRm" style="position:absolute;top:6px;right:6px;background:rgba(0,0,0,.55);color:#fff">${ic('x')}</button></div>`:`<button class="lfchip lfadd" id="lfCAdd">${ic('image')}Добавить фото</button>`;
    document.querySelectorAll('[data-cp]').forEach(b=>b.onclick=()=>{ sel=+b.dataset.cp; at=P_[sel][1](); draw(); });
    const a=document.getElementById('lfCAdd'); if(a) a.onclick=()=>fi.click();
    const r=document.getElementById('lfCRm'); if(r) r.onclick=()=>{ URL.revokeObjectURL(url); file=null; url=null; draw(); }; };
  fi.onchange=()=>{ const f=fi.files[0]; if(!f) return; file=f; if(url) URL.revokeObjectURL(url); url=URL.createObjectURL(f); draw(); };
  draw();
  document.getElementById('lfCAt').onchange=e=>{ const d=new Date(e.target.value); if(!isNaN(d)){ at=d; sel=-1; draw(); } };
  const go=document.getElementById('lfCGo');
  go.onclick=async()=>{ const text=document.getElementById('lfCT').value.trim(); if(!text&&!file) return toast('Напишите что-нибудь или добавьте фото');
    if(at-Date.now()<9e4) return toast('Выберите время хотя бы через пару минут');
    go.disabled=true; go.textContent='Запечатываем…';
    try{ await E2E.prepChat(chatId); const pl={kind:file?'image':'text'};
      if(text) pl.text=(await E2E.enc(chatId,text))||text;
      if(file){ const u=await upload(file,(file.name.split('.').pop()||'jpg').toLowerCase()); pl.image=(await E2E.enc(chatId,u))||u; }
      await R('lm_capsule_send',{p_chat:chatId,p_open_at:at.toISOString(),p_payload:pl,p_reply:replyTo});
      if(S.reply){ S.reply=null; renderCtx(); } if(url) URL.revokeObjectURL(url); close(); toast('Капсула запечатана до '+fullD(at));
    }catch(err){ toast(err.message); go.disabled=false; draw(); } };
};
async function capBox(){ let L=[]; try{ L=await R('lm_capsule_list')||[]; }catch(e){ return toast(e.message); }
  await ensureProfiles(L.map(x=>x.sender_id));
  const row=x=>{ const c=S.chatMap.get(x.chat_id); return `<div class="lfli" data-cj="${x.message_id}" data-cc="${x.chat_id}">${envelope(48,34,x.opened)}<div style="flex:1;min-width:0"><b style="display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${x.mine?'Вы → '+esc(c?chatName(c):'чат'):'От '+esc(profName(x.sender_id))+(c&&c.type!=='private'?' · '+esc(chatName(c)):'')}</b><span style="font-size:13px;color:${x.opened?'var(--muted)':'#d08a2a'}">${x.opened?'Открыта ':'Откроется '}${fullD(x.open_at)}</span></div></div>`; };
  const sealed=L.filter(x=>!x.opened), opened=L.filter(x=>x.opened).reverse();
  const close=modal('Капсулы времени',L.length?`${sealed.length?`<div class="lfsec">ЗАПЕЧАТАНЫ · ${sealed.length}</div><div class="lflist">${sealed.map(row).join('')}</div>`:''}${opened.length?`<div class="lfsec">ОТКРЫТЫ · ${opened.length}</div><div class="lflist">${opened.map(row).join('')}</div>`:''}`
    :`<div style="text-align:center;padding:16px 6px">${envelope(140,94)}<h3>Капсул пока нет</h3><p style="color:var(--muted)">Отправьте капсулу через скрепку в любом чате — она откроется в выбранный день.</p></div>`);
  document.querySelectorAll('[data-cj]').forEach(b=>b.onclick=async()=>{ close(); S.tab='chats'; await openChat(b.dataset.cc); setTimeout(()=>jumpTo(+b.dataset.cj),300); }); }

/* ---------- Серии ---------- */
let stT=0;
async function stLoad(force=true){ if(!force&&Date.now()-stT<2e4) return; stT=Date.now();
  try{ const a=await R('lm_streaks')||[]; LF.streaks=new Map(a.map(x=>[x.chat_id,x])); }catch{ return; }
  if(S.tab==='chats'&&!S.q) renderList(); if(S.cur) renderHead(); stCelebrateCheck(); }
const stOf=id=>{ const s=LF.streaks.get(id); return s&&s.enabled&&s.count>=3?s:null; };
window.lfBadge=(id,big)=>{ const ch=S.chatMap.get(id); if(!ch||ch.peer_id===S.me.id||ch.peer_bot) return ''; const s=stOf(id);
  if(!s) return big?`<span class="lfst off" data-streak="${id}" title="Огонёк" style="opacity:.75">${flame(3,false,12,14)}</span>`:'';
  return `<span class="lfst ${s.done?'on':'off'}" data-streak="${id}" title="Серия ${s.count} ${days(s.count)}">${flame(s.level,s.done,big?14:12,big?17:15)}${s.count}</span>`; };
/* серийчик — огонёк с глазками */
function mascot(size=120,level=3,sleeping=false){ const c=flameColors(level,!sleeping); const id='lfm'+(++fid);
  const eye=x=>sleeping?`<path d="M${x-6} 66 Q${x} 72 ${x+6} 66" fill="none" stroke="#5a2600" stroke-width="2.6" stroke-linecap="round"/>`
    :`<ellipse class="lfeye" cx="${x}" cy="66" rx="6" ry="7.5" fill="#4a1d00"/><circle cx="${x+1.5}" cy="63" r="2.2" fill="#fff"/>`;
  return `<svg class="lfmascot" width="${size*0.86}" height="${size}" viewBox="0 0 100 100" preserveAspectRatio="none"><defs><linearGradient id="${id}a" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c[1]}"/><stop offset="1" stop-color="${c[2]}"/></linearGradient><linearGradient id="${id}b" x1="0" y1=".44" x2="0" y2="1"><stop offset="0" stop-color="${c[0]}"/><stop offset="1" stop-color="#fff" stop-opacity=".85"/></linearGradient></defs>`
   +`<path fill="url(#${id}a)" d="M50 98 C12 98 2 62 20 38 C24 52 32 56 36 55 C30 30 44 10 60 2 C58 22 70 30 78 40 C100 84 82 98 50 98Z"/><path fill="url(#${id}b)" d="M50 96 C30 96 26 76 36 64 C42 70 46 70 48 68 C46 56 52 48 60 44 C62 56 74 66 72 80 C70 92 62 96 50 96Z"/>`
   +eye(40)+eye(66)+`<path d="M45 80 Q53 87 61 80" fill="none" stroke="#5a2600" stroke-width="2.6" stroke-linecap="round"/><ellipse cx="29" cy="77" rx="5" ry="3" fill="#ff5a7a" opacity=".55"/><ellipse cx="77" cy="77" rx="5" ry="3" fill="#ff5a7a" opacity=".55"/></svg>`; }
function stSheet(id){ const s=LF.streaks.get(id); const on=!!(s&&s.enabled); const c=S.chatMap.get(id); const n=on?s.count:0, lit=!!(s&&s.done); const name=c?chatName(c):'собеседник';
  const todo=!s||!s.count?'Напишите друг другу сегодня — серия начнётся.':s.done?'Сегодня вы оба уже написали — огонёк горит. Возвращайтесь завтра!':s.mine?`Вы сегодня уже написали. Ждём ответа от ${esc(name)} — иначе серия погаснет в полночь.`:s.peer?`${esc(name)} уже написал(а) сегодня. Ответьте до полуночи, чтобы серия продолжилась!`:'Напишите друг другу сегодня до полуночи, чтобы серия не погасла.';
  const lv=[3,10,30,100,200]; const li=(i,t)=>`<li><span class="lfli2">${ic(i)}</span>${t}</li>`;
  const head=on&&n>=3?`<div class="avs"><div>${avatar({name:S.me.name,avatar:S.me.avatar_url,color:S.me.color},'l')}</div><div>${c?chatAv(c,'l'):''}</div></div><div class="lfmw">${mascot(54,s.level||3)}</div>
    <h2>Ваша серия длится ${flame(s.level||3,lit,20,24)}<span style="color:${lit?'#ff7a1a':'var(--muted)'}">${n} ${days(n)}</span></h2>`
   :`<div class="lfmw big">${mascot(120,3,!on)}</div><h2>${on?'Серийчик выведен':'Серийчик ещё спит'}</h2><p style="color:var(--muted);margin:0 0 8px">${on?`Пишите друг другу каждый день — на третий день загорится огонёк. Сейчас: ${n} ${days(n)} подряд.`:'Выведите серийчика, и в этом чате начнётся серия: общайтесь каждый день, и через 3 дня рядом с именем загорится огонёк.'}</p>`;
  const close=modal('',`<div class="lfsheet">${head}
    <ul class="lful">${li('clock','День засчитывается, когда вы оба написали друг другу хотя бы по сообщению (по московскому времени).')}${on?li('bell',todo):''}${li('moon','Не пропускайте дни: если день пропущен, серия погаснет в полночь.')}${li('star','Чем дольше серия, тем ярче огонёк: 3, 10, 30, 100 и 200 дней.')}</ul>
    <div class="lflv">${lv.map((x,i)=>`${i?`<i class="${n>=x?'on':''}"></i>`:''}<div class="${n>=x?'on':''}">${flame(x,n>=x,26,32)}${x} д</div>`).join('')}</div>
    ${on&&s.best>n?`<div style="color:var(--muted);font-size:13px;margin-top:8px">Рекорд: ${s.best} ${days(s.best)}</div>`:''}
    ${on?'<button class="lfok" data-x>Понятно</button>':`<button class="lfok lfgo" id="lfStGo">${flame(3,true,16,19)}Вывести серийчика</button>`}</div>`);
  const go=document.getElementById('lfStGo'); if(go) go.onclick=async()=>{ go.disabled=true; try{ await R('lm_streak_enable',{p_chat:id}); close(); await stLoad(); const x=LF.streaks.get(id); if(x&&x.count<3) stCelebrate(x); }catch(e){ toast(e.message); go.disabled=false; } }; }
/* красивое появление огонька */
function stCelebrate(s){ const lit=s.count>=3; const c=S.chatMap.get(s.chat_id);
  const o=document.createElement('div'); o.className='lfcel';
  let sp=''; for(let i=0;i<30;i++){ const a=i/30*Math.PI*2, r=110+(i%5)*24; sp+=`<i style="--x:${Math.cos(a)*r}px;--y:${Math.sin(a)*r-40}px;--d:${(i%7)*0.12}s;background:${['#ffd24c','#ff8a3d','#fff'][i%3]}"></i>`; }
  o.innerHTML=`<div class="lfcb"><div class="lfglow"></div><div class="lfsp">${sp}</div><div class="lfbigf">${lit?flame(s.level,true,130,155):mascot(150)}</div>
    ${lit?`<div class="lfnum">${s.count}</div>`:''}<h2>${lit?(s.level<=3?'Огонёк загорелся!':'Огонёк стал ярче!'):'Серийчик выведен!'}</h2>
    <p>${lit?`${s.count} ${days(s.count)} подряд с ${esc(c?chatName(c):'собеседником')}. Не прерывайте серию!`:'Пишите друг другу каждый день — через 3 дня загорится огонёк.'}</p><button class="lfok" style="max-width:220px">Ура!</button></div>`;
  document.body.appendChild(o); requestAnimationFrame(()=>o.classList.add('on'));
  const close=()=>{ o.classList.remove('on'); o.classList.add('off'); setTimeout(()=>o.remove(),300); };
  o.onclick=close; }
function stCelebrateCheck(){ if(document.querySelector('.lfcel')) return; let seen={}; try{ seen=JSON.parse(localStorage.getItem('lf_st_seen')||'{}'); }catch{}
  for(const s of LF.streaks.values()){ if(!s.enabled||(s.level||0)<3) continue; if((seen[s.chat_id]||0)<s.level){ seen[s.chat_id]=s.level; try{ localStorage.setItem('lf_st_seen',JSON.stringify(seen)); }catch{} stCelebrate(s); return; } } }
function stInfo(){ const lv=[3,10,30,100,200], nm=['Огонёк загорелся','Огонёк ярче','Розовое пламя','Синее пламя','Легендарное пламя'];
  modal('Огоньки',`<div class="lfsheet"><div class="lfmw big">${mascot(120)}</div><h2>Огоньки и серийчик</h2><p style="color:var(--muted);margin:0 0 10px">Огонёк показывает, сколько дней подряд вы общаетесь с человеком.</p>
   <ul class="lful"><li><span class="lfli2 n">1</span>Откройте личный чат и нажмите на серый огонёк рядом с именем, затем — «Вывести серийчика».</li><li><span class="lfli2 n">2</span>Пишите друг другу каждый день. День засчитывается, когда написали вы оба (по московскому времени).</li><li><span class="lfli2 n">3</span>На третий день загорится огонёк с числом — его видно в списке чатов и в шапке чата.</li><li><span class="lfli2">${ic('moon')}</span>Если день пропущен, серия гаснет в полночь, и в чате появится сообщение об этом.</li></ul>
   <div class="lfsec" style="text-align:left">УРОВНИ</div><div class="lflist">${lv.map((x,i)=>`<div class="lfli">${flame(x,true,24,29)}<b>${x} ${days(x)} подряд</b><span class="r">${nm[i]}</span></div>`).join('')}</div></div>`); }
function stPill(m){ const lost=m.meta&&m.meta.streak_lost!=null; const n=Math.max(3,(m.meta&&m.meta.streak)||3);
  return `<div class="sys" data-id="${m.id}"><button class="lfpill ${lost?'ash':'fire'}" data-streak="${m.chat_id}">${flame([200,100,30,10,3].find(x=>x<=n)||3,!lost,14,17)}${esc(String(m.body||'').replace(/^(🔥|💨) /,''))}</button></div>`; }
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('[data-streak]'); if(!t) return; e.stopPropagation(); e.preventDefault(); stLoad().then(()=>stSheet(t.dataset.streak)); },true);
/* ---------- хуки ---------- */
window.lfMsg=m=>{ if(m.deleted) return null;
  if(m.kind==='system'&&m.meta&&(m.meta.streak!=null||m.meta.streak_lost!=null)) return stPill(m);
  if(m.kind==='capsule_open'){ const mine=m.sender_id===S.me.id; return `<div class="sys" data-id="${m.id}"><button class="lfpill gift" data-capjump="${(m.meta||{}).capsule}">${ic('gift')}${mine?'Ваша капсула открылась':esc(profName(m.sender_id))+': капсула открылась'} · посмотреть</button></div>`; }
  if(m.kind==='capsule') return capHtml(m);
  if(m.meta&&m.meta.urgent===true&&m.kind==='text'){ return null; }
  return null; };
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('[data-capjump]'); if(!t) return; e.stopPropagation(); jumpTo(+t.dataset.capjump); },true);
window.lfMenu=(m,acts)=>{ const mine=m.sender_id===S.me.id; if(m.deleted||m.id<0) return;
  if(!mine&&m.sender_id) acts.push(['bell','Ответить позже',()=>remPick(m)]);
  if(!mine&&m.meta&&m.meta.urgent===true) acts.push(['ban','Это было не срочно',async()=>{ try{ await R('lm_urgent_report',{p_msg:m.id}); toast('Понятно. Неделю этот человек не сможет отправлять вам срочные'); }catch(e){ toast(e.message); } }]); };
window.lfSent=m=>{ if(LF.rem.some(r=>r.chat_id===m.chat_id)){ LF.rem=LF.rem.filter(r=>r.chat_id!==m.chat_id); remSchedule(); }
  const c=S.chatMap.get(m.chat_id); if(c&&c.type==='private') setTimeout(()=>stLoad(),700); };
window.lfOnMsg=m=>{ if(m.kind==='system'&&m.meta&&(m.meta.streak!=null||m.meta.streak_lost!=null)) stLoad();
  else if(m.sender_id===S.me.id&&m.kind!=='system') window.lfSent(m);
  else { const c=S.chatMap.get(m.chat_id); if(c&&c.type==='private') setTimeout(()=>stLoad(),700); } };
window.lfHead=()=>{ const c=cur(); if(c&&c.type==='private'&&c.peer_id!==S.me.id){ if(!LF.peers.has('_t'+c.peer_id)){ LF.peers.set('_t'+c.peer_id,1); peersLoad([c.peer_id]).then(()=>{ renderHead(); }); setTimeout(()=>LF.peers.delete('_t'+c.peer_id),6e4); } stLoad(false); }
  urgStrip(); };
window.lfRows=()=>srow('lfSDnd','moon','#7c5cff','Не беспокоить',dndActive()?esc((LF.dnd.text||'Включено')+' '+untilT(LF.dnd.until)):'Выключено')
  +srow('lfSRem','bell','#ffa318','Ждут ответа',LF.rem.length?LF.rem.length+' — «Ответить позже»':'Нет напоминаний')
  +srow('lfSCap','clock','#ff8a3d','Капсулы времени','Сообщения, которые откроются в будущем')
  +srow('lfSSt','flame','#ff6a00','Огоньки','Серии общения и серийчик');
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('#lfSDnd,#lfSRem,#lfSCap,#lfSSt,#lfRemBar'); if(!t) return; e.stopPropagation();
  if(t.id==='lfSDnd') dndDlg(); else if(t.id==='lfSCap') capBox(); else if(t.id==='lfSSt') stInfo(); else remList(); },true);
/* ---------- даты в чате: видна только одна закреплённая плашка ---------- */
let dayRaf=0;
function dayFix(){ dayRaf=0; const box=document.getElementById('msgs'), mw=document.getElementById('mw'); if(!box||!mw) return; const ds=mw.querySelectorAll(':scope>.day'); if(!ds.length) return;
  const top=box.getBoundingClientRect().top; let cur=-1;
  ds.forEach((d,i)=>{ const n=d.nextElementSibling; const y=n?n.getBoundingClientRect().top-top:1e9; if(y<=d.offsetHeight+10) cur=i; });
  ds.forEach((d,i)=>d.classList.toggle('lfdh',i<cur)); }
const dayQ=()=>{ if(!dayRaf) dayRaf=requestAnimationFrame(dayFix); };
document.addEventListener('scroll',e=>{ if(e.target&&e.target.id==='msgs') dayQ(); },true);
(function dayObs(){ const mw=document.getElementById('mw'); if(!mw) return setTimeout(dayObs,800); new MutationObserver(dayQ).observe(mw,{childList:true}); dayQ(); })();
let lfBooted=false;
function lfBoot(){ if(lfBooted||!S||!S.me) return; lfBooted=true; remLoad(); dndLoad(); stLoad(); }
setInterval(()=>{ if(!lfBooted) lfBoot(); },1500);
document.addEventListener('visibilitychange',()=>{ if(!document.hidden&&lfBooted){ remLoad(); dndCheckEnded(); stLoad(); } });
})();
/* ===== TG: истории как в Telegram, публикации, оформление и музыка профиля ===== */
(function(){
Object.assign(P,{
  tgrid:'<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
  tarch:'<rect x="3" y="4" width="18" height="5" rx="1.5"/><path d="M5 9v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9M10 13h4"/>',
  tnote:'<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
  tok:'<circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>',
  tcirc:'<circle cx="12" cy="12" r="9"/>',
  tchev:'<path d="M9 6l6 6-6 6"/>'
});
const TGC=[['#6f8cff','#3d4fd8'],['#b06bff','#6a2fd8'],['#ff6fae','#d8336f'],['#ff8a4c','#e0442a'],['#ffc24c','#e08a12'],['#4cd98a','#1f9e5c'],['#3cc6e0','#1a7fa8'],['#7a8296','#434a5e'],['#ff5f6d','#c0263a'],['#9be15d','#4caf2e'],['#5ee7df','#2a9d8f'],['#2b2d42','#101120']];
const PSVG={
  'star.fill':'<path d="M12 2l3 6.5 7 .8-5.2 4.8 1.5 7L12 17.6 5.7 21.1l1.5-7L2 9.3l7-.8z"/>',
  'heart.fill':'<path d="M12 21s-8-5.2-8-11a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 10c0 5.8-8 11-8 11z"/>',
  'sparkles':'<path d="M12 2l2 6 6 2-6 2-2 6-2-6-6-2 6-2z"/>',
  'moon.stars.fill':'<path d="M20 15A8 8 0 1 1 9 4a7 7 0 0 0 11 11z"/>',
  'leaf.fill':'<path d="M4 20C4 9 11 4 21 3c-1 10-6 17-17 17z"/>',
  'bolt.fill':'<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>',
  'music.note':'<path d="M9 17V5l11-2v12"/><circle cx="6" cy="17" r="3"/><circle cx="17" cy="15" r="3"/>',
  'pawprint.fill':'<circle cx="6" cy="10" r="2"/><circle cx="10" cy="6" r="2"/><circle cx="14" cy="6" r="2"/><circle cx="18" cy="10" r="2"/><path d="M12 11c-3 0-6 4-6 6.5S8 20 12 20s6-.5 6-2.5S15 11 12 11z"/>',
  'snowflake':'<path d="M11 2h2v20h-2zM2 11h20v2H2zM4.9 6.3l1.4-1.4 12.8 12.8-1.4 1.4zM17.7 4.9l1.4 1.4L6.3 19.1l-1.4-1.4z"/>',
  'flame.fill':'<path d="M12 2c1 4 6 6 6 12a6 6 0 0 1-12 0c0-3 2-5 3-6 0 2 1 3 2 3 0-4-1-6 1-9z"/>',
  'gamecontroller.fill':'<path d="M7 7h10a5 5 0 0 1 4.8 6.4l-1 3.4A2.5 2.5 0 0 1 16.5 18L14 15h-4l-2.5 3a2.5 2.5 0 0 1-4.3-1.2l-1-3.4A5 5 0 0 1 7 7z"/>',
  'crown.fill':'<path d="M3 7l4.5 4L12 4l4.5 7L21 7l-2 12H5z"/>',
  'cloud.fill':'<path d="M7 19a5 5 0 0 1-.6-10A7 7 0 0 1 20 10.5 4.3 4.3 0 0 1 18 19z"/>',
  'camera.fill':'<path d="M4 7h3l2-3h6l2 3h3a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1z"/>',
  'airplane':'<path d="M21 16v-2l-8-5V3.5a1.5 1.5 0 0 0-3 0V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5z"/>',
  'sun.max.fill':'<circle cx="12" cy="12" r="5"/><path d="M11 1h2v4h-2zM11 19h2v4h-2zM1 11h4v2H1zM19 11h4v2h-4z"/>'
};
const tst=document.createElement('style'); tst.setAttribute('data-lumo-own','1'); tst.textContent=`
.tgsty{position:relative;isolation:isolate;color:#fff}
.tgsty>.tgbg{position:absolute;left:-40px;right:-40px;top:-220px;bottom:0;z-index:-1;overflow:hidden;border-radius:0 0 26px 26px}
.tgsty h1,.tgsty h2,.tgsty .st,.tgsty .stt,.tgsty .st.live{color:#fff!important}
.tgsty .st,.tgsty .stt{opacity:.86}
.tgsty .iact button,.tgsty .tga button{background:rgba(255,255,255,.18)!important;color:#fff!important;border:.7px solid rgba(255,255,255,.22)}
.tgglow{position:absolute;width:420px;height:420px;transform:translate(-50%,-50%);background:radial-gradient(circle,rgba(255,255,255,.32),rgba(255,255,255,0) 62%);pointer-events:none}
.tgpat{position:absolute;width:0;height:0;animation:tgdrift 7s ease-in-out infinite alternate;pointer-events:none}
.tgpat i{position:absolute;display:grid;place-items:center}
.tgpat i svg{width:100%;height:100%;fill:currentColor}
@keyframes tgdrift{from{transform:rotate(-7deg) scale(.97)}to{transform:rotate(7deg) scale(1.05)}}
.tgmus{display:flex;align-items:center;gap:10px;margin:12px auto 0;max-width:420px;padding:8px 10px;border-radius:16px;background:var(--panel);cursor:pointer;text-align:left}
.tgsty .tgmus{background:rgba(255,255,255,.18);color:#fff}
.tgmus .pb{width:32px;height:32px;border-radius:50%;display:grid;place-items:center;background:var(--a1);color:#fff;flex:none}
.tgsty .tgmus .pb{background:#fff;color:#000}
.tgmus .pb svg{width:16px;height:16px}
.tgmus .tx{flex:1;min-width:0}.tgmus .tx b{display:block;font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.tgmus .tx span{font-size:13px;opacity:.75}
.tgmus .wv{display:flex;gap:2px;align-items:center;height:18px}.tgmus .wv i{width:3px;height:5px;border-radius:2px;background:currentColor;opacity:.8}
.tgmus.on .wv i{animation:tgwv .45s ease-in-out infinite alternate}.tgmus.on .wv i:nth-child(2){animation-delay:.1s}.tgmus.on .wv i:nth-child(3){animation-delay:.2s}.tgmus.on .wv i:nth-child(4){animation-delay:.3s}
@keyframes tgwv{to{height:16px}}
.tgposts{display:grid;grid-template-columns:repeat(3,1fr);gap:2px;border-radius:14px;overflow:hidden}
.tgposts .t{position:relative;aspect-ratio:9/16;background:#000;cursor:pointer;overflow:hidden}
.tgposts .t img,.tgposts .t video{width:100%;height:100%;object-fit:cover;display:block}
.tgposts .t span{position:absolute;left:6px;bottom:5px;font-size:11px;font-weight:800;color:#fff;text-shadow:0 1px 3px rgba(0,0,0,.6);display:flex;gap:3px;align-items:center}
.tgposts .t span svg{width:12px;height:12px}
.tgposts .t .pn{position:absolute;right:5px;top:5px;width:20px;height:20px;border-radius:50%;background:rgba(0,0,0,.45);display:grid;place-items:center;color:#fff}
.tgposts .t .pn svg{width:11px;height:11px}
.tgempty{color:var(--muted);text-align:center;padding:22px 10px}
#tgst{position:fixed;inset:0;z-index:99500;background:#000;color:#fff;display:flex;flex-direction:column;padding:max(8px,env(safe-area-inset-top)) 10px max(8px,env(safe-area-inset-bottom));animation:tgin .22s ease}
@keyframes tgin{from{opacity:0;transform:translateY(16px)}}
#tgst .pv{flex:1;min-height:0;border-radius:22px;overflow:hidden;background:#141414;position:relative;display:grid;place-items:center}
#tgst .pv img,#tgst .pv video{max-width:100%;max-height:100%;object-fit:contain}
#tgst .rb{width:42px;height:42px;border-radius:50%;display:grid;place-items:center;background:rgba(255,255,255,.12);color:#fff}
#tgst .pv .rb{position:absolute;top:10px;background:rgba(0,0,0,.4)}
#tgst .cap{margin-top:10px;border-radius:24px;background:rgba(255,255,255,.12);padding:12px 16px}
#tgst .cap textarea{width:100%;background:none;border:0;outline:0;color:#fff;font-size:16px;resize:none;max-height:96px}
#tgst .bt{display:flex;align-items:center;margin-top:10px}
#tgst .nx{margin-left:auto;display:flex;align-items:center;gap:4px;background:#2f8cff;color:#fff;font-weight:800;border-radius:22px;padding:12px 20px}
#tgst .nx svg{width:18px;height:18px}
#tgsh{position:fixed;inset:0;z-index:99600;background:#121217;color:#fff;overflow:auto;animation:tgup .28s cubic-bezier(.2,.9,.3,1)}
@keyframes tgup{from{transform:translateY(100%)}}
#tgsh .w{max-width:560px;margin:0 auto;padding:max(10px,env(safe-area-inset-top)) 16px 120px}
#tgsh .hd{position:relative;height:50px;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:17px}
#tgsh .hd button{position:absolute;left:0;width:34px;height:34px;border-radius:50%;background:rgba(255,255,255,.12);display:grid;place-items:center;color:#fff}
#tgsh .hd button svg{width:18px;height:18px}
#tgsh .cd{background:#212128;border-radius:14px;overflow:hidden}
#tgsh .me{display:flex;align-items:center;gap:12px;padding:12px}
#tgsh .me small{display:block;color:rgba(255,255,255,.55);font-size:13px}
#tgsh .lb{color:rgba(255,255,255,.55);font-size:12.5px;margin:18px 14px 6px}
#tgsh .hn{color:rgba(255,255,255,.55);font-size:12.5px;margin:6px 14px 0}
#tgsh .ar{display:flex;align-items:center;gap:12px;padding:9px 12px;cursor:pointer;border-bottom:1px solid rgba(255,255,255,.08)}
#tgsh .ar:last-child{border-bottom:0}
#tgsh .ar .rd svg{width:24px;height:24px;color:rgba(255,255,255,.3)}
#tgsh .ar.on .rd svg{color:#2f8cff}
#tgsh .ar .ico{width:38px;height:38px;border-radius:50%;display:grid;place-items:center;color:#fff;flex:none}
#tgsh .ar .ico svg{width:20px;height:20px}
#tgsh .ar b{display:block;font-weight:600;font-size:16px}
#tgsh .ar a{color:#2f8cff;font-size:13px;cursor:pointer}
#tgsh .tr{display:flex;align-items:center;justify-content:space-between;padding:0 14px;height:50px;border-bottom:1px solid rgba(255,255,255,.08);cursor:pointer}
#tgsh .tr:last-child{border-bottom:0}
#tgsh .sw{width:50px;height:30px;border-radius:15px;background:rgba(255,255,255,.2);position:relative;transition:background .2s}
#tgsh .sw:after{content:'';position:absolute;left:2px;top:2px;width:26px;height:26px;border-radius:50%;background:#fff;transition:transform .2s}
#tgsh .sw.on{background:#34c759}#tgsh .sw.on:after{transform:translateX(20px)}
#tgsh .hr{display:flex;gap:4px}#tgsh .hr button{padding:5px 9px;border-radius:10px;color:#2f8cff;font-weight:700;font-size:13.5px}#tgsh .hr button.on{background:#2f8cff;color:#fff}
#tgsh .ft{position:fixed;left:0;right:0;bottom:0;padding:12px 16px max(12px,env(safe-area-inset-bottom));background:rgba(18,18,23,.96)}
#tgsh .ft button{display:block;width:100%;max-width:528px;margin:0 auto;height:52px;border-radius:26px;background:#2f8cff;color:#fff;font-weight:700;font-size:17px}
#tgsh .ft button.dis{opacity:.5}
#tgsh .ft button.loading{pointer-events:none;position:relative;overflow:hidden;background:rgba(47,140,255,.35)}#tgsh .ft button .pf{position:absolute;left:0;top:0;bottom:0;width:10%;background:#2f8cff;border-radius:26px;transition:width .25s ease;overflow:hidden}#tgsh .ft button .pf:after{content:'';position:absolute;top:0;bottom:0;width:80px;background:linear-gradient(90deg,transparent,rgba(255,255,255,.35),transparent);animation:tgshm 1.3s linear infinite}@keyframes tgshm{from{left:-80px}to{left:100%}}#tgsh .ft button span{position:relative}
.tgpick .row{cursor:pointer}.tgpick .row .ck{margin-left:auto;width:22px;height:22px;border-radius:50%;border:2px solid var(--muted)}.tgpick .row.on .ck{background:var(--a1);border-color:var(--a1)}
.tgemo{display:inline-flex;vertical-align:middle;margin-left:6px;cursor:pointer}
#stv .stmedia{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}
.tgsw{display:flex;flex-wrap:wrap;gap:10px;margin:6px 0 12px}.tgsw b{width:40px;height:40px;border-radius:50%;cursor:pointer;display:grid;place-items:center;border:3px solid transparent}.tgsw b.on{border-color:var(--text)}
.tgpg{display:grid;grid-template-columns:repeat(6,1fr);gap:8px}.tgpg b{aspect-ratio:1;border-radius:12px;background:var(--panel2);display:grid;place-items:center;cursor:pointer;border:2px solid transparent}.tgpg b.on{border-color:var(--a1)}.tgpg b svg{width:22px;height:22px;fill:currentColor}
.tgprev{height:200px;border-radius:20px;position:relative;overflow:hidden;display:flex;flex-direction:column;align-items:center;justify-content:center;background:var(--panel2);margin-bottom:12px}
`; document.head.appendChild(tst);

/* ---------- узор и цвет шапки ---------- */
const DOTS=(()=>{ const o=[]; const cn=[7,11,15], rr=[92,140,190], sz=[22,19,16]; for(let r=0;r<3;r++) for(let k=0;k<cn[r];k++){ const a=k/cn[r]*Math.PI*2+r*.35; o.push([Math.cos(a)*rr[r],Math.sin(a)*rr[r]*.82,sz[r],.42-r*.1]); } return o; })();
function bgHtml(bg,pat,status){
  const c=TGC[bg]; let h='';
  if(c) h+=`<div style="position:absolute;inset:0;background:linear-gradient(180deg,${c[0]},${c[1]})"></div><div class="tgglow" data-c></div>`;
  if(pat){ const useS=pat==='@status'&&status; const svg=PSVG[pat==='@status'?'star.fill':pat]||PSVG['star.fill'];
    h+=`<div class="tgpat" data-c>${DOTS.map(d=>`<i style="left:${d[0]-d[2]/2}px;top:${d[1]-d[2]/2}px;width:${d[2]}px;height:${d[2]}px;opacity:${(useS?.9:(c?.8:.6))*d[3]};color:${c?'#fff':'var(--a1)'}">${useS?emoHtml(status):`<svg viewBox="0 0 24 24">${svg}</svg>`}</i>`).join('')}</div>`; }
  return h; }
function place(host,av){ requestAnimationFrame(()=>{ const hb=host.getBoundingClientRect(), ab=(av||host).getBoundingClientRect(); const x=ab.left-hb.left+ab.width/2+40, y=ab.top-hb.top+ab.height/2+220;
  host.querySelectorAll('[data-c]').forEach(e=>{ e.style.left=x+'px'; e.style.top=y+'px'; if(e.classList.contains('tgpat')) e.style.transformOrigin='0 0'; }); }); }
const AU={a:null,u:null};
function musHtml(p){ if(!p||!p.profile_music||!p.profile_music.url) return ''; const m=p.profile_music;
  return `<div class="tgmus ${AU.u===m.url?'on':''}" data-mu="${esc(m.url)}"><span class="pb">${ic(AU.u===m.url?'pause':'play','f')}</span><span class="tx"><b>${esc(m.title||'Без названия')}</b>${m.artist?`<span>${esc(m.artist)}</span>`:''}</span><span class="wv"><i></i><i></i><i></i><i></i></span>${ic('tnote')}</div>`; }
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('[data-mu]'); if(!t) return; e.stopPropagation(); const u=t.dataset.mu;
  const sync=()=>document.querySelectorAll('[data-mu]').forEach(x=>{ const on=AU.u===x.dataset.mu; x.classList.toggle('on',on); x.querySelector('.pb').innerHTML=ic(on?'pause':'play','f'); });
  if(AU.u===u){ AU.a&&auFade(AU.a,0,400,x=>x.pause()); AU.u=null; sync(); return; }
  if(AU.a) auFade(AU.a,0,350,x=>x.pause()); const na=new Audio(pxu(u)); na.volume=0; AU.a=na; AU.u=u; na.onended=()=>{ AU.u=null; sync(); }; na.play().then(()=>auFade(na,1,600)).catch(()=>{ AU.u=null; sync(); }); sync(); },true);
/* музыка включается и выключается плавно */
function auFade(a,to,ms,done){ if(!a) return; clearInterval(a._fd); const from=a.volume, n=Math.max(1,Math.round(ms/20)); let i=0;
  a._fd=setInterval(()=>{ i++; const k=i/n, e=k*k*(3-2*k); try{ a.volume=Math.max(0,Math.min(1,from+(to-from)*e)); }catch{} if(i>=n){ clearInterval(a._fd); a._fd=null; done&&done(a); } },20); }
window.tgDecor=(host,p,mine)=>{ if(!host||!p) return; host.querySelector(':scope>.tgbg')?.remove(); host.querySelector(':scope>.tgmus')?.remove();
  const bg=(p.profile_bg===null||p.profile_bg===undefined)?null:+p.profile_bg; const pat=p.profile_pattern||null;
  host.classList.toggle('tgsty',bg!==null);
  if(bg!==null||pat){ const d=document.createElement('div'); d.className='tgbg'; if(bg===null){ d.style.cssText='position:absolute;left:-40px;right:-40px;top:-220px;bottom:0;z-index:-1;overflow:hidden'; host.style.position='relative'; host.style.isolation='isolate'; }
    d.innerHTML=bgHtml(bg,pat,p.premium?p.emoji_status:null); host.prepend(d); place(host,host.querySelector('.av,.ibig,.avatar,img')); }
  const mh=musHtml(p); if(mh) host.insertAdjacentHTML('beforeend',mh); };

/* ---------- публикации в профиле ---------- */
function postView(s,mine,onCh){ const u=pxu(s.media_url); let pinned=s.pinned!==false;
  const close=modal(s.caption?esc(s.caption):'Публикация',`<div style="text-align:center">${s.kind==='video'?`<video src="${esc(u)}" controls playsinline autoplay style="max-width:100%;max-height:68vh;border-radius:16px"></video>`:`<img src="${esc(u)}" style="max-width:100%;max-height:68vh;border-radius:16px">`}</div>`,
    mine?[['Удалить','danger',c=>confirmBox('Удалить эту историю навсегда?','Удалить',async()=>{ c(); await sb.rpc('lm_story_delete',{p_id:s.id}); loadStories(); onCh&&onCh(); })],[pinned?'Убрать из профиля':'В профиль','ghost',async c=>{ c(); await sb.rpc('lm_story_set_pinned',{p_id:s.id,p_on:!pinned}); toast(pinned?'Убрано из профиля':'Опубликовано в профиле'); onCh&&onCh(); }],['Закрыть','primary']]:[['Закрыть','primary']]); }
function gridHtml(L,showPin){ return `<div class="tgposts">${L.map((s,i)=>{ const th=s.kind==='video'?(s.meta&&s.meta.thumb):s.media_url;
  return `<div class="t" data-pi="${i}">${th?`<img src="${esc(pxu(th))}" loading="lazy" alt="">`:`<video src="${esc(pxu(s.media_url))}#t=0.1" preload="metadata" playsinline muted></video>`}<span>${s.kind==='video'?ic('play','f'):''}${s.views?ic('eye')+s.views:''}</span>${showPin&&s.pinned?`<b class="pn">${ic('pin')}</b>`:''}</div>`; }).join('')}</div>`; }
window.tgPosts=async(box,uid)=>{ if(!box) return; box.innerHTML='<div class="tgempty">Загрузка…</div>';
  const {data}=await sb.rpc('lm_profile_posts',{p_user:uid}); const L=data||[]; const mine=uid===S.me.id;
  box.innerHTML=L.length?gridHtml(L,false):`<div class="tgempty">${mine?'Опубликуйте историю в профиле — она останется здесь':'Пока нет публикаций'}</div>`;
  box.querySelectorAll('[data-pi]').forEach(el=>el.onclick=()=>postView(L[+el.dataset.pi],mine,()=>window.tgPosts(box,uid))); };
async function archiveBox(postsOnly){ const close=modal(postsOnly?'Опубликованные истории':'Архив историй','<div id="tgArc"><div class="tgempty">Загрузка…</div></div>',[['Закрыть','ghost']]);
  const load=async()=>{ const box=document.getElementById('tgArc'); if(!box) return; const {data}=postsOnly?await sb.rpc('lm_profile_posts',{p_user:S.me.id}):await sb.rpc('lm_story_archive'); const L=data||[];
    box.innerHTML=L.length?gridHtml(L,!postsOnly):`<div class="tgempty">${postsOnly?'Нет опубликованных историй':'Архив пуст. Здесь хранятся все ваши истории, их видите только вы.'}</div>`;
    box.querySelectorAll('[data-pi]').forEach(el=>el.onclick=()=>postView(L[+el.dataset.pi],true,load)); }; load(); }

/* ---------- выбор людей ---------- */
async function pickPeople(title,initial,done){ const sel=new Set(initial||[]); const ids=(S.contacts||[]).slice(); if(ids.length) await profGet(ids).catch(()=>{});
  const row=id=>{ const p=S.profiles.get(id)||{}; return `<div class="row ${sel.has(id)?'on':''}" data-pp="${id}">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'s')}<div class="mid"><div class="t1"><span class="nm">${esc(p.name||'')}</span></div></div><span class="ck"></span></div>`; };
  modal(esc(title),`<div class="tgpick" style="max-height:56vh;overflow:auto">${ids.length?ids.map(row).join(''):'<div class="tgempty">В контактах пока никого</div>'}</div>`,[['Отмена','ghost'],['Готово','primary',c=>{ c(); done(sel); }]]);
  const ov=[...document.querySelectorAll('.ov')].pop(); ov&&ov.querySelectorAll('[data-pp]').forEach(r=>r.onclick=()=>{ const id=r.dataset.pp; sel.has(id)?sel.delete(id):sel.add(id); r.classList.toggle('on',sel.has(id)); }); }

/* ---------- новая история: предпросмотр → «Поделиться историей» ---------- */
function videoThumb(blob){ return new Promise(r=>{ const v=document.createElement('video'); v.muted=true; v.playsInline=true; v.preload='auto'; v.src=URL.createObjectURL(blob);
  v.onloadeddata=()=>{ v.currentTime=Math.min(.1,v.duration||0); }; v.onseeked=()=>{ try{ const k=540/Math.max(v.videoWidth,1); const cv=document.createElement('canvas'); cv.width=Math.round(v.videoWidth*Math.min(1,k)); cv.height=Math.round(v.videoHeight*Math.min(1,k)); cv.getContext('2d').drawImage(v,0,0,cv.width,cv.height); cv.toBlob(b=>{ URL.revokeObjectURL(v.src); r(b); },'image/jpeg',.72); }catch(e){ r(null); } }; v.onerror=()=>r(null); setTimeout(()=>r(null),6000); }); }
function tgAddStory(){ const inp=document.createElement('input'); inp.type='file'; inp.accept='image/*,video/*'; inp.style.cssText='position:fixed;left:-9999px;opacity:0';
  document.body.appendChild(inp); inp.onchange=async()=>{ const f=inp.files&&inp.files[0]; inp.remove(); if(!f) return;
    const isV=/^video\//.test(f.type); if(!isV&&!/^image\//.test(f.type)) return toast('Можно выбрать фото или видео');
    if(isV&&f.size>25*1024*1024) return toast('Видео для истории — до 25 МБ. Загрузите его с телефона: приложение сожмёт видео само');
    let meta={}; if(isV){ meta=await new Promise(r=>{ const v=document.createElement('video'); v.preload='metadata'; v.onloadedmetadata=()=>{ r({dur:v.duration,w:v.videoWidth,h:v.videoHeight}); URL.revokeObjectURL(v.src); }; v.onerror=()=>r({}); v.src=URL.createObjectURL(f); });
      if(meta.dur>61) return toast('Видео для истории — не длиннее 60 секунд'); }
    const blob=isV?f:await compressImage(f); const prev=URL.createObjectURL(blob);
    const st={choice:'all',excl:new Set(),sel:new Set(),pinned:true,shots:true,hours:24,cap:''};
    const ed=document.createElement('div'); ed.id='tgst';
    ed.innerHTML=`<div class="pv">${isV?`<video src="${prev}" playsinline autoplay loop></video>`:`<img src="${prev}" alt="">`}<button class="rb" data-k="x" style="right:10px">${ic('x')}</button></div>
<div class="cap"><textarea rows="1" maxlength="300" placeholder="Добавить подпись…"></textarea></div><div class="bt"><button class="rb" data-k="x">${ic('back')}</button><button class="nx" data-k="n">ДАЛЕЕ${ic('tchev')}</button></div>`;
    document.body.appendChild(ed); const ta=ed.querySelector('textarea'); ta.oninput=()=>{ ta.style.height='auto'; ta.style.height=Math.min(96,ta.scrollHeight)+'px'; };
    const shut=()=>{ const s2=document.getElementById('tgsh'); s2&&s2.classList.add('out'); ed.classList.add('out'); setTimeout(()=>{ ed.remove(); URL.revokeObjectURL(prev); s2&&s2.remove(); },320); };
    ed.querySelectorAll('[data-k=x]').forEach(b=>b.onclick=shut);
    ed.querySelector('[data-k=n]').onclick=()=>{ st.cap=ta.value; ed.querySelector('video')?.pause(); share(); };
    const share=async()=>{ let close=new Set(); sb.rpc('lm_close_friends_get').then(({data})=>{ close=new Set((data||[]).map(x=>typeof x==='string'?x:x.lm_close_friends_get)); draw(); });
      const sh=document.createElement('div'); sh.id='tgsh'; document.body.appendChild(sh);
      const ar=(k,icon,col,t,sub,act)=>`<div class="ar ${st.choice===k?'on':''}" data-a="${k}"><span class="rd">${ic(st.choice===k?'tok':'tcirc')}</span><span class="ico" style="background:${col}">${ic(icon)}</span><span><b>${t}</b><a data-s="${act}">${sub} ›</a></span></div>`;
      const draw=()=>{ const me=S.me; const ok=!(st.choice==='only'&&!st.sel.size);
        sh.innerHTML=`<div class="w"><div class="hd"><button data-k="b">${ic('x')}</button>Поделиться историей</div>
<div class="cd me">${avatar({name:me.name,avatar:me.avatar_url,color:me.color},'s')}<div><b>${esc(me.name)}</b>${pMark(me)}<small>личный аккаунт</small></div></div>
<div class="lb">КТО ВИДИТ ЭТУ ИСТОРИЮ</div><div class="cd">
${ar('all','megaphone','#2f8cff','Все',st.choice==='all'&&st.excl.size?'кроме '+st.excl.size+' чел.':'добавить исключения','excl')}
${ar('contacts','user','#9b5cff','Мои контакты',st.choice==='contacts'&&st.excl.size?'кроме '+st.excl.size+' чел.':'добавить исключения','excl')}
${ar('close','star','#34c759','Близкие друзья',close.size?close.size+' чел. · изменить':'выбрать','close')}
${ar('only','users','#ff9500','Выбранные пользователи',st.sel.size?st.sel.size+' чел. · изменить':'выбрать','only')}</div>
<div class="hn">Выберите пользователей, которые не будут видеть Вашу историю.</div>
<div class="cd" style="margin-top:14px"><div class="tr" data-t="shots">Разрешить снимки экрана<span class="sw ${st.shots?'on':''}"></span></div><div class="tr" data-t="pinned">Опубликовать в моём профиле<span class="sw ${st.pinned?'on':''}"></span></div></div>
<div class="hn">История в профиле останется после 24 часов. Её смогут увидеть только те, кого Вы выбрали выше.</div>
<div class="cd" style="margin-top:14px"><div class="tr" style="cursor:default">Срок<span class="hr">${[[24,'24 ч'],[48,'48 ч'],[72,'3 дня'],[168,'7 дней']].map(h=>`<button data-h="${h[0]}" class="${st.hours===h[0]?'on':''}">${h[1]}</button>`).join('')}</span></div></div></div>
<div class="ft"><button data-k="p" class="${ok?'':'dis'}">Опубликовать историю</button></div>`;
        sh.querySelector('[data-k=b]').onclick=()=>{ sh.classList.add('out'); setTimeout(()=>sh.remove(),300); ed.querySelector('video')?.play().catch(()=>{}); };
        sh.querySelectorAll('[data-a]').forEach(r=>r.onclick=e=>{ if(e.target.closest('[data-s]')) return; st.choice=r.dataset.a; if(st.choice==='only'&&!st.sel.size) return pick('only'); if(st.choice==='close'&&!close.size) return pick('close'); draw(); });
        sh.querySelectorAll('[data-s]').forEach(a=>a.onclick=e=>{ e.stopPropagation(); pick(a.dataset.s); });
        sh.querySelectorAll('[data-t]').forEach(r=>r.onclick=()=>{ st[r.dataset.t]=!st[r.dataset.t]; draw(); });
        sh.querySelectorAll('[data-h]').forEach(b=>b.onclick=()=>{ const h=+b.dataset.h; if(h>24&&!premOk()) return; st.hours=h; draw(); });
        sh.querySelector('[data-k=p]').onclick=publish; };
      const pick=k=>{ if(k==='excl') pickPeople('Скрыть от',st.excl,s=>{ st.excl=s; draw(); });
        else if(k==='only') pickPeople('Кто увидит',st.sel,s=>{ st.sel=s; st.choice='only'; draw(); });
        else pickPeople('Близкие друзья',close,async s=>{ close=s; await sb.rpc('lm_close_friends_set',{p_ids:[...s]}); draw(); }); };
      const publish=async()=>{ if(st.choice==='only'&&!st.sel.size) return; const b=sh.querySelector('[data-k=p]'); b.classList.add('loading'); b.innerHTML='<i class="pf"></i><span>Загрузка 0%</span>'; const setP=k=>{ const pf=b.querySelector('.pf'), sp=b.querySelector('span'); if(pf) pf.style.width=Math.max(10,k*100)+'%'; if(sp) sp.textContent=k>=1?'Публикуем…':'Загрузка '+Math.round(k*100)+'%'; };
        try{ let url=await window.tgUpP(blob,isV?extOf(f,'mp4'):'jpg',setP); if(!url) url=await upload(blob,isV?extOf(f,'mp4'):'jpg'); setP(1); const m=Object.assign({},meta); if(!st.shots) m.noshot=true;
          if(isV){ const tb=await videoThumb(blob); if(tb){ try{ m.thumb=await upload(tb,'jpg'); }catch(e){} } }
          let aud='all', allow=[]; if(st.choice==='contacts'){ aud='contacts'; allow=[...st.excl]; } else if(st.choice==='close') aud='close'; else if(st.choice==='only'){ aud='only'; allow=[...st.sel]; } else if(st.excl.size){ aud='except'; allow=[...st.excl]; }
          const {error}=await sb.rpc('lm_story_add3',{p_kind:isV?'video':'image',p_url:url,p_caption:st.cap,p_meta:m,p_hours:st.hours,p_aud:aud,p_allow:allow,p_pinned:st.pinned}); if(error) throw error;
          shut(); toast('История опубликована'); loadStories(); refreshMe(); }
        catch(err){ b.classList.remove('loading'); b.textContent='Опубликовать историю'; toast('Ошибка: '+(err.message||err)); } };
      draw(); };
  }; inp.click(); }
addStory=tgAddStory;

/* ---------- оформление и музыка профиля (настройки) ---------- */
function styleBox(){ const me=S.me; let bg=me.profile_bg??null, pat=me.profile_pattern||null;
  const opts=[null,...(me.emoji_status?['@status']:[]),...Object.keys(PSVG)];
  const close=modal('Оформление профиля',`<div class="tgprev" id="tgPv"></div><div class="k" style="color:var(--muted);font-size:12.5px">ЦВЕТ</div><div class="tgsw" id="tgSw"></div><div class="k" style="color:var(--muted);font-size:12.5px;margin-bottom:6px">УЗОР · PREMIUM</div><div class="tgpg" id="tgPg"></div>`,
    [['Отмена','ghost'],['Сохранить','primary',async c=>{ const {error}=await sb.rpc('lm_set_profile_style',{p_bg:bg,p_pattern:pat}); if(error) return toast(error.message); c(); await refreshMe(); renderSettings(); toast('Оформление сохранено'); }]]);
  const draw=()=>{ const pv=document.getElementById('tgPv'); if(!pv) return;
    pv.innerHTML=`${avatar({name:me.name,avatar:me.avatar_url,color:me.color},'l')}<b style="margin-top:8px;font-size:19px">${esc(me.name)}</b>`; window.tgDecor(pv,Object.assign({},me,{profile_bg:bg,profile_pattern:pat,profile_music:null}),true);
    pv.querySelector('.tgbg')&&(pv.querySelector('.tgbg').style.cssText='position:absolute;inset:0;z-index:-1;overflow:hidden');
    place(pv,pv.querySelector('.av,.avatar,img')); pv.querySelectorAll('[data-c]').forEach(e=>{ requestAnimationFrame(()=>{ const a=pv.querySelector('.av,.avatar,img'); if(!a) return; const hb=pv.getBoundingClientRect(), ab=a.getBoundingClientRect(); e.style.left=(ab.left-hb.left+ab.width/2)+'px'; e.style.top=(ab.top-hb.top+ab.height/2)+'px'; }); });
    document.getElementById('tgSw').innerHTML=`<b data-bg="" class="${bg===null?'on':''}" style="background:var(--panel2)">${ic('x')}</b>`+TGC.map((c,i)=>`<b data-bg="${i}" class="${bg===i?'on':''}" style="background:linear-gradient(180deg,${c[0]},${c[1]})"></b>`).join('');
    document.getElementById('tgPg').innerHTML=opts.map(o=>`<b data-pt="${o||''}" class="${pat===o?'on':''}">${o===null?ic('x'):o==='@status'?emoHtml(me.emoji_status):`<svg viewBox="0 0 24 24">${PSVG[o]}</svg>`}</b>`).join('');
    document.querySelectorAll('#tgSw [data-bg]').forEach(b=>b.onclick=()=>{ bg=b.dataset.bg===''?null:+b.dataset.bg; draw(); });
    document.querySelectorAll('#tgPg [data-pt]').forEach(b=>b.onclick=()=>{ const v=b.dataset.pt||null; if(v&&!premOk()) return; pat=v; draw(); }); };
  draw(); }
function musicBox(){ const me=S.me; const m=me.profile_music;
  const close=modal('Музыка профиля',`<p style="margin:0 0 10px;color:var(--muted)">Трек будет играть у тех, кто откроет ваш профиль, по нажатию.</p>${m&&m.url?musHtml(me):'<div class="tgempty">Трек не выбран</div>'}`,
    [...(m&&m.url?[['Убрать','danger',async c=>{ await sb.rpc('lm_set_profile_music',{p:null}); c(); await refreshMe(); renderSettings(); }]]:[]),['Выбрать файл','primary',c=>{
      const inp=document.createElement('input'); inp.type='file'; inp.accept='audio/*'; inp.style.cssText='position:fixed;left:-9999px;opacity:0'; document.body.appendChild(inp);
      inp.onchange=async()=>{ const f=inp.files&&inp.files[0]; inp.remove(); if(!f) return; if(f.size>15*1024*1024) return toast('Файл больше 15 МБ'); c(); toast('Загружаем трек…');
        try{ const ext=(extOf(f,'mp3')||'mp3').replace(/[^a-z0-9]/g,''); const url=await upload(f,['mp3','m4a','wav','ogg'].includes(ext)?ext:'mp3');
          const title=(f.name||'').replace(/\.[^.]+$/,''); const {error}=await sb.rpc('lm_set_profile_music',{p:{url,title,artist:''}}); if(error) throw error; await refreshMe(); renderSettings(); toast('Музыка профиля установлена'); }
        catch(err){ toast('Ошибка: '+(err.message||err)); } }; inp.click(); }]]); }
const prevRows=window.lfRows;
window.lfRows=()=>(prevRows?prevRows():'')+srow('tgSStyle','palette','#ff6fae','Оформление профиля',S.me&&(S.me.profile_bg!=null||S.me.profile_pattern)?'Своё':'Стандартное')
  +srow('tgSMus','music','#ff2d55','Музыка профиля',S.me&&S.me.profile_music&&S.me.profile_music.url?esc(S.me.profile_music.title||'Выбрана'):'Не выбрана')
  +srow('tgSPosts','tgrid','#2f8cff','Опубликованные истории','Истории, закреплённые в профиле')
  +srow('tgSArc','tarch','#8e8e93','Архив историй','Все ваши истории, видите только вы');
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('#tgSStyle,#tgSMus,#tgSPosts,#tgSArc'); if(!t) return; e.stopPropagation();
  if(t.id==='tgSStyle') styleBox(); else if(t.id==='tgSMus') musicBox(); else archiveBox(t.id==='tgSPosts'); },true);

/* ---------- эмодзи-статус рядом с «Чаты» ---------- */
setInterval(()=>{ const t=document.getElementById('tabTitle'); if(!t||!S||!S.me) return; let sp=t.querySelector('.tgemo');
  const want=t.firstChild&&String(t.firstChild.textContent||'').trim()==='Чаты'&&S.me.premium;
  if(!want){ sp&&sp.remove(); return; }
  const h=S.me.emoji_status?emoHtml(S.me.emoji_status):ic('star','f');
  if(!sp){ sp=document.createElement('span'); sp.className='tgemo'; sp.onclick=e=>{ e.stopPropagation(); emojiStatusDlg(); }; t.appendChild(sp); }
  if(sp.__h!==h){ sp.__h=h; sp.innerHTML=h; } },1200);
document.addEventListener('contextmenu',e=>{ if(e.target.closest&&e.target.closest('#stv .stmedia')) e.preventDefault(); },true);
})();

/* ===== TG2: шапка списка чатов как в приложении — «Изм.», стопка историй + «Чаты» + эмодзи-статус, кнопки справа; лента историй раскрывается, если потянуть список вниз ===== */
(function(){
const st2=document.createElement('style'); st2.setAttribute('data-lumo-own','1'); st2.textContent=`
#tghead{display:none;align-items:center;gap:8px;padding:calc(10px + env(safe-area-inset-top)) 14px 4px}
body.tgchats #tghead{display:flex}
body.tgchats #qbox{padding-top:6px!important}
body.tgchats #newBtn{display:none!important}
#tghead .gb{height:42px;border-radius:21px;background:var(--panel2);border:1px solid var(--line);display:flex;align-items:center;justify-content:center;color:var(--text);flex:none}
#tghead .ed{padding:0 16px;font-weight:700;font-size:16px}
#tghead .mid{flex:1;min-width:0;display:flex;align-items:center;justify-content:center;gap:6px}
#tghead .mid b{font-size:19px;font-weight:800;white-space:nowrap}
#tghead .pair{padding:0 4px}#tghead .pair button{width:40px;height:42px;display:grid;place-items:center;color:var(--text)}
#tghead .pair svg,#tghead .cmp svg{width:21px;height:21px}
#tghead .cmp{width:44px;height:44px;border-radius:50%;background:var(--a1);color:#fff;display:grid;place-items:center;flex:none;border:0}
#tghead .stk{display:flex;align-items:center;cursor:pointer;transition:transform .3s cubic-bezier(.2,.9,.3,1.2),opacity .25s}
#tghead .stk>*{margin-left:-12px;border-radius:50%;padding:2px;background:var(--bg)}
#tghead .stk>*:first-child{margin-left:0}
#tghead .stk .av{width:30px!important;height:30px!important;min-width:30px;font-size:12px}
#tghead .stk .cnt{width:30px;height:30px;border-radius:50%;display:grid;place-items:center;color:#fff;font-weight:800;font-size:13px;background:linear-gradient(180deg,#6fb8ff,var(--a1));box-sizing:content-box}
body.tgstopen #tghead .stk{transform:scale(.4);opacity:0;pointer-events:none;width:0;margin:0}
#list>.stbar{max-height:0;opacity:0;overflow:hidden;padding-top:0;padding-bottom:0;transform:translateY(-12px);transition:max-height .38s cubic-bezier(.2,.9,.3,1),opacity .28s,transform .38s cubic-bezier(.2,.9,.3,1),padding .38s}
body.tgstopen #list>.stbar{max-height:120px;opacity:1;transform:none;padding-top:6px;padding-bottom:10px;overflow-x:auto}
#tghead .tgemo{margin-left:0}
`; document.head.appendChild(st2);

const qb=document.getElementById('qbox'); if(!qb) return;
const hd=document.createElement('div'); hd.id='tghead';
hd.innerHTML=`<button class="gb ed" data-h="ed">Изм.</button><div class="mid"><span class="stk" data-h="stk"></span><b>Чаты</b><span class="emo" data-h="emo"></span></div><div class="gb pair"><button data-h="add" title="Новая история">${ic('plus')}</button></div><button class="cmp" data-h="new" title="Новый чат">${ic('edit')}</button>`;
qb.parentNode.insertBefore(hd,qb);
hd.addEventListener('click',e=>{ const b=e.target.closest('[data-h]'); if(!b) return; e.stopPropagation(); const k=b.dataset.h;
  if(k==='new'||k==='ed'){ dropMenu(b,[['user','Новый личный чат',()=>{ $('#q').focus(); toast('Введите имя или @юзернейм в поиске'); }],['users','Новая группа',()=>newChatFlow('group')],['mega','Новый канал',()=>newChatFlow('channel')],['clock','Архив историй',()=>{ const r=document.createElement('div'); r.id='tgSArc'; r.style.display='none'; document.body.appendChild(r); r.click(); r.remove(); }]],'down'); }
  else if(k==='add') addStory();
  else if(k==='emo'){ if(S.me&&S.me.premium) emojiStatusDlg(); }
  else if(k==='stk'){ const o=storyOrder(); const g=o.find(x=>x.uid!==S.me.id&&x.unseen)||o[0]; if(g) openStories(g.uid); } });

const setOpen=v=>{ if(document.body.classList.contains('tgstopen')===v) return; document.body.classList.toggle('tgstopen',v); if(v&&navigator.vibrate) try{ navigator.vibrate(8); }catch(e){} };
let lastStk='', lastEmo='';
function sync(){ if(!S||!S.me) return; const on=S.tab==='chats'&&!S.q; document.body.classList.toggle('tgchats',S.tab==='chats');
  if(!on) setOpen(false);
  const o=storyOrder().slice().sort((a,b)=>(a.uid===S.me.id?-1:b.uid===S.me.id?1:0)||((b.unseen?1:0)-(a.unseen?1:0)));
  const sh=o.length?(o.length>2?`<span class="cnt">${o.length}</span>`:'')+o.slice(0,2).map(g=>avatar({name:g.name,avatar:g.avatar_url,color:g.color},'xs')).join(''):'';
  if(sh!==lastStk){ lastStk=sh; hd.querySelector('[data-h=stk]').innerHTML=sh; }
  const eh=S.me.premium?(S.me.emoji_status?emoHtml(S.me.emoji_status):`<span style="color:var(--a1);display:grid">${ic('star','f')}</span>`):'';
  if(eh!==lastEmo){ lastEmo=eh; hd.querySelector('[data-h=emo]').innerHTML=eh; } }
setInterval(sync,700);

// потянуть вниз у верхнего края — раскрыть ленту; прокрутить вниз — свернуть
let ty=null, acc=0;
const L=()=>document.getElementById('list');
document.addEventListener('wheel',e=>{ const l=L(); if(!l||!l.contains(e.target)||S.tab!=='chats') return;
  if(e.deltaY<0&&l.scrollTop<=0){ acc+=-e.deltaY; if(acc>60){ acc=0; setOpen(true); } }
  else if(e.deltaY>0){ acc=0; if(document.body.classList.contains('tgstopen')&&l.scrollTop<=4) setOpen(false); } },{passive:true});
document.addEventListener('touchstart',e=>{ const l=L(); ty=(l&&l.contains(e.target)&&l.scrollTop<=0)?e.touches[0].clientY:null; },{passive:true});
document.addEventListener('touchmove',e=>{ if(ty===null) return; const dy=e.touches[0].clientY-ty; if(dy>70){ ty=null; setOpen(true); } else if(dy<-24){ ty=null; setOpen(false); } },{passive:true});
document.addEventListener('scroll',e=>{ if(e.target&&e.target.id==='list'&&e.target.scrollTop>40) setOpen(false); },true);
})();

/* ===== TG3: большие файлы — до 100 МБ, с Premium до 200 МБ. Хранилище берёт до 50 МБ за раз, поэтому режем на части по 45 МБ и склеиваем у получателя ===== */
(function(){
const CH=45*1024*1024;
window.tgLim=()=>((S.me&&S.me.premium)?200:100)*1024*1024;
window.tgLimTxt=()=>(S.me&&S.me.premium)?'200 МБ':'100 МБ (с Premium — 200 МБ)';
window.tgBigUp=async(f,ext)=>{ if(f.size<=CH) return null; const parts=[];
  for(let off=0,i=0;off<f.size;off+=CH,i++){ const b=f.slice(off,Math.min(f.size,off+CH),'application/octet-stream'); parts.push(await upload(b,ext+'.p'+i)); }
  return parts; };
const st=document.createElement('style'); st.setAttribute('data-lumo-own','1');
st.textContent='.file[data-big] .fi{position:relative}.file[data-big] .fi b{position:absolute;inset:0;display:grid;place-items:center;font-size:11px;font-weight:800;color:#fff;border-radius:50%}';
document.head.appendChild(st);
const busy=new Set(), done=new Map();
function findMsg(id){ for(const l of S.msgs.values()) for(const m of l) if(m.id===id) return m; return null; }
async function fetchBig(m,el){ if(done.has(m.id)) return done.get(m.id); if(busy.has(m.id)) return null; busy.add(m.id);
  const parts=m.meta.parts, out=[]; const fi=el&&el.querySelector('.fi'); const fs=el&&el.querySelector('.fs'); const total=m.meta.size||0;
  try{ for(let i=0;i<parts.length;i++){ const r=await fetch(pxu(parts[i])); if(!r.ok) throw new Error('HTTP '+r.status); out.push(await r.blob());
      const k=(i+1)/parts.length; if(fi) fi.innerHTML=`${ic('dl')}<b>${Math.round(k*100)}</b>`; if(fs&&total) fs.textContent=fmtSize(Math.round(total*k))+' из '+fmtSize(total); }
    const name=m.meta.name||'file'; const ext=(name.match(/\.([a-z0-9]{1,8})$/i)||[])[1]||'';
    const type=m.kind==='video'?('video/'+(ext==='mov'?'quicktime':(ext||'mp4'))):'';
    const blob=new Blob(out,type?{type}:{}); const url=URL.createObjectURL(blob); done.set(m.id,url); return url; }
  catch(e){ toast('Не удалось скачать файл'); return null; }
  finally{ busy.delete(m.id); if(fi) fi.innerHTML=ic(m.kind==='video'?'play':'dl'); if(fs&&total) fs.textContent=(m.kind==='video'?'Видео · ':'')+fmtSize(total); } }
document.addEventListener('click',async e=>{ const a=e.target.closest&&e.target.closest('[data-big]'); if(!a) return; e.preventDefault(); e.stopPropagation();
  const m=findMsg(+a.dataset.big); if(!m||!m.meta||!m.meta.parts) return; const url=await fetchBig(m,a); if(!url) return;
  if(m.kind==='video'){ modal(esc(m.meta.name||'Видео'),`<video src="${url}" controls autoplay playsinline style="width:100%;max-height:70vh;border-radius:14px;background:#000"></video>`,[['Сохранить','ghost',()=>{ const d=document.createElement('a'); d.href=url; d.download=m.meta.name||'video.mp4'; d.click(); }],['Закрыть','primary']]); }
  else { const d=document.createElement('a'); d.href=url; d.download=m.meta.name||'file'; document.body.appendChild(d); d.click(); d.remove(); } },true);
})();

/* ===== TG4: загрузка с прогрессом (для публикации истории) ===== */
(function(){
const KEY4=SUPABASE_KEY;
window.tgUpP=async(blob,ext,cb)=>{
  const ses=await sb.auth.getSession(); const tk=ses&&ses.data&&ses.data.session&&ses.data.session.access_token;
  const path=`${S.me.id}/${uid8()}.${ext}`;
  try{
    await new Promise((res,rej)=>{ const x=new XMLHttpRequest(); x.open('POST',`${SUPABASE_URL}/storage/v1/object/${BUCKET}/${path}`);
      x.setRequestHeader('apikey',KEY4); if(tk) x.setRequestHeader('Authorization','Bearer '+tk); x.setRequestHeader('x-upsert','false'); x.setRequestHeader('cache-control','3600');
      if(blob.type) x.setRequestHeader('Content-Type',blob.type);
      x.upload.onprogress=e=>{ if(e.lengthComputable&&cb) cb(Math.min(.99,e.loaded/e.total)); };
      x.onload=()=>x.status>=200&&x.status<300?res():rej(new Error('Ошибка загрузки ('+x.status+')'));
      x.onerror=()=>rej(new Error('Нет связи')); x.send(blob); });
    return `${SUPABASE_ORIGIN}/storage/v1/object/public/${BUCKET}/${path}`;
  }catch(e){ return await upload(blob,ext); } };
})();

/* ===== TG5: кнопки поверх цветной шапки профиля, без горизонтальной прокрутки; плавное закрытие окон истории ===== */
(function(){
const st=document.createElement('style'); st.setAttribute('data-lumo-own','1'); st.textContent=`
#lxprof,#info{overflow-x:hidden}
#lxprof .bar,#info .tgtop{position:relative;z-index:3}
#lxprof:has(.hero.tgsty) .bar .rb{background:rgba(255,255,255,.22);border-color:rgba(255,255,255,.32);color:#fff;-webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px)}
#info:has(.ihead.tgsty) .tgtop .ib,#info:has(.ihead.tgsty) .tgtop .lnk2{color:#fff}
#info:has(.ihead.tgsty) .tgtop .ib{background:rgba(255,255,255,.22);border-radius:50%}
#tgst.out{animation:tgfadeout .28s ease forwards;pointer-events:none}
#tgsh.out{animation:tgdown .3s cubic-bezier(.4,0,.6,1) forwards;pointer-events:none}
@keyframes tgfadeout{to{opacity:0;transform:scale(.97)}}
@keyframes tgdown{to{transform:translateY(100%)}}
`; document.head.appendChild(st);
})();

/* Lumo: групповой звонок (LiveKit). Общий код для сайта и приложений.
   GCall.open({url, token, title, video, onLeave}) — рисует полноэкранное окно звонка. */
(function(){
if (window.GCall) return;
const IC = {
  mic: '<path d="M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3z"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
  micOff: '<path d="M3 3l18 18"/><path d="M9 9v3a3 3 0 0 0 5.1 2.1M15 9.3V6a3 3 0 0 0-5.8-1.1"/><path d="M5 11a7 7 0 0 0 11.6 5.3M19 11a7 7 0 0 1-.4 2.3M12 18v3"/>',
  cam: '<rect x="2.5" y="6" width="13" height="12" rx="3"/><path d="M15.5 10.5l6-3.5v10l-6-3.5z"/>',
  camOff: '<path d="M3 3l18 18"/><path d="M15.5 10.5l6-3.5v10l-3.2-1.9M13 18H5.5a3 3 0 0 1-3-3V9a3 3 0 0 1 2-2.8M9 6h3.5a3 3 0 0 1 3 3v3"/>',
  flip: '<path d="M4 7h11a4 4 0 0 1 4 4v1"/><path d="M7 4L4 7l3 3"/><path d="M20 17H9a4 4 0 0 1-4-4v-1"/><path d="M17 20l3-3-3-3"/>',
  end: '<path d="M3.5 14.5c4.7-4 12.3-4 17 0l-2 2.6-3.6-1.4v-2.3a10 10 0 0 0-5.8 0v2.3l-3.6 1.4z" fill="currentColor"/>',
  spk: '<path d="M4 9h4l5-4v14l-5-4H4z"/><path d="M17 8.5a5 5 0 0 1 0 7M19.5 6a8.5 8.5 0 0 1 0 12"/>',
  min: '<path d="M6 15l6-6 6 6"/>',
  add: '<circle cx="9" cy="8" r="4"/><path d="M2 21a7 7 0 0 1 14 0M19 8v6M16 11h6"/>',
  ok: '<path d="M5 12.5l4.5 4.5L19 7.5"/>'
};
const svg = (n, s = 24) => `<svg viewBox="0 0 24 24" width="${s}" height="${s}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${IC[n]}</svg>`;
const COLORS = [['#ff8a65','#f4511e'],['#9575cd','#5e35b1'],['#4fc3f7','#0288d1'],['#81c784','#388e3c'],['#f06292','#c2185b'],['#ffb74d','#f57c00'],['#4db6ac','#00796b'],['#7986cb','#3949ab']];
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const css = `
#gcw{position:fixed;inset:0;z-index:2147483000;background:#0b0b10;color:#fff;display:flex;flex-direction:column;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;animation:gcin .32s cubic-bezier(.2,.9,.3,1)}
@keyframes gcin{from{opacity:0;transform:scale(.97)}}
#gcw.out{animation:gcout .26s ease forwards}@keyframes gcout{to{opacity:0;transform:scale(.97)}}
#gcw .hd{display:flex;align-items:center;gap:10px;padding:calc(10px + env(safe-area-inset-top)) 130px 8px 16px}
#gcw .hd b{font-size:17px;display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#gcw .hd small{font-size:13px;opacity:.65}
#gcw .grid{flex:1;min-height:0;display:grid;gap:8px;padding:8px 10px;grid-auto-rows:1fr}
#gcw .t{position:relative;border-radius:22px;overflow:hidden;background:#1c1c24;display:grid;place-items:center;transition:box-shadow .2s;animation:gcin .3s ease}
#gcw .t::after{content:'';position:absolute;inset:0;border-radius:22px;box-shadow:inset 0 0 0 3px #34c759;opacity:0;transition:opacity .2s;pointer-events:none;z-index:2}#gcw .t.sp::after{opacity:1}#gcw .t .nm{z-index:3}
#gcw .t video{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
#gcw .t.me video{transform:scaleX(-1)}
#gcw .t.me.back video{transform:none}
#gcw .t .av{width:92px;height:92px;border-radius:50%;display:grid;place-items:center;font-size:34px;font-weight:800;background-size:cover;background-position:center;box-shadow:0 6px 24px rgba(0,0,0,.35)}
#gcw .t .nm{position:absolute;left:10px;bottom:10px;display:flex;align-items:center;gap:6px;font-size:13.5px;font-weight:600;padding:5px 10px;border-radius:12px;background:rgba(0,0,0,.42);-webkit-backdrop-filter:blur(8px);backdrop-filter:blur(8px);max-width:calc(100% - 20px)}
#gcw .t .nm span{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#gcw .t .nm i{display:grid;color:#ff5a5a}
#gcw .t .nm i svg{width:15px;height:15px}
#gcw .bar{display:flex;justify-content:center;gap:14px;padding:12px 16px calc(18px + env(safe-area-inset-bottom))}
#gcw .bar button{width:60px;height:60px;border-radius:50%;border:0;display:grid;place-items:center;color:#fff;background:rgba(255,255,255,.14);cursor:pointer;transition:transform .15s,background .2s}
#gcw .bar button:active{transform:scale(.92)}
#gcw .bar button.off{background:#fff;color:#111}
#gcw .bar button.end{background:#ff3b30}
#gcw .bar label{display:flex;flex-direction:column;align-items:center;gap:6px;font-size:12px;opacity:.85}
#gcw .st{position:absolute;left:0;right:0;top:45%;text-align:center;font-size:15px;opacity:.8}
#gcw .addb{position:absolute;right:14px;top:calc(8px + env(safe-area-inset-top));height:38px;border-radius:19px;border:0;padding:0 14px 0 10px;display:flex;align-items:center;gap:6px;background:rgba(255,255,255,.14);color:#fff;font-weight:700;font-size:14px;cursor:pointer}
#gcw .addb svg{width:20px;height:20px}
#gcw .sheet{position:absolute;inset:0;background:rgba(0,0,0,.45);display:flex;align-items:flex-end;animation:gcfade .2s ease;z-index:5}
@keyframes gcfade{from{opacity:0}}
#gcw .sheet .pn{width:100%;max-height:75%;background:#1a1a22;border-radius:22px 22px 0 0;display:flex;flex-direction:column;animation:gcup .32s cubic-bezier(.2,.9,.3,1);padding-bottom:env(safe-area-inset-bottom)}
@keyframes gcup{from{transform:translateY(100%)}}
#gcw .sheet .ph{display:flex;align-items:center;justify-content:space-between;padding:14px 16px;font-weight:800;font-size:17px}
#gcw .sheet .ph button{border:0;background:none;color:#7fb2ff;font-size:16px;font-weight:700;cursor:pointer}
#gcw .sheet .ls{overflow:auto;padding:0 8px 8px}
#gcw .sheet .r{display:flex;align-items:center;gap:12px;padding:8px 10px;border-radius:14px;cursor:pointer}
#gcw .sheet .r:active{background:rgba(255,255,255,.06)}
#gcw .sheet .r .av{width:42px;height:42px;font-size:16px;box-shadow:none;border-radius:50%;display:grid;place-items:center;font-weight:800;background-size:cover;background-position:center;flex:none}
#gcw .sheet .r b{flex:1;font-weight:600;font-size:15.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#gcw .sheet .r small{color:#34c759;font-size:12.5px;font-weight:700}
#gcw .sheet .r .ck{width:24px;height:24px;border-radius:50%;border:2px solid rgba(255,255,255,.35);display:grid;place-items:center;flex:none}
#gcw .sheet .r.on .ck{background:#2f8cff;border-color:#2f8cff}
#gcw .sheet .r .ck svg{width:15px;height:15px;opacity:0}#gcw .sheet .r.on .ck svg{opacity:1}
#gcw .sheet .go{margin:8px 16px 12px;height:50px;border-radius:25px;border:0;background:#2f8cff;color:#fff;font-weight:700;font-size:16px;cursor:pointer}
#gcw .sheet .go:disabled{opacity:.45}
#gcw .toast{position:absolute;left:50%;top:calc(60px + env(safe-area-inset-top));transform:translateX(-50%);background:rgba(255,255,255,.95);color:#111;padding:9px 16px;border-radius:16px;font-weight:600;font-size:14px;z-index:6;animation:gcfade .2s ease}
`;
function avatarHtml(name, meta) {
  let m = {}; try { m = JSON.parse(meta || '{}') || {}; } catch (e) {}
  const c = COLORS[Math.abs(m.color || 0) % COLORS.length];
  const ini = String(name || '?').trim().split(/\s+/).slice(0, 2).map(w => w[0] || '').join('').toUpperCase();
  return m.avatar ? `<div class="av" style="background-image:url('${esc(m.avatar)}')"></div>` : `<div class="av" style="background:linear-gradient(160deg,${c[0]},${c[1]})">${esc(ini)}</div>`;
}
window.GCall = {
  active: false,
  async open(o) {
    if (this.active) return;
    const LK = window.LivekitClient;
    if (!LK) { alert('Не удалось загрузить звонок. Проверьте интернет.'); o.onLeave && o.onLeave(); return; }
    this.active = true;
    const { Room, RoomEvent, Track, VideoPresets } = LK;
    if (!document.getElementById('gcss')) { const s = document.createElement('style'); s.id = 'gcss'; s.textContent = css; document.head.appendChild(s); }
    const w = document.createElement('div'); w.id = 'gcw';
    w.innerHTML = `<div class="hd"><div style="flex:1;min-width:0"><b>${esc(o.title || 'Групповой звонок')}</b><small id="gcs">Подключение…</small></div></div>
<button class="addb" id="gcadd">${svg('add')}Добавить</button>
<div class="grid" id="gcg"></div><div id="gca" style="display:none"></div>
<div class="bar">
<label><button id="gcm">${svg('mic')}</button>Микрофон</label>
<label><button id="gcv">${svg('cam')}</button>Камера</label>
<label><button id="gcf">${svg('flip')}</button>Повернуть</label>
<label><button id="gce" class="end">${svg('end', 28)}</button>Выйти</label></div>`;
    document.body.appendChild(w);
    const $ = id => w.querySelector('#' + id);
    const room = new Room({ adaptiveStream: true, dynacast: true, videoCaptureDefaults: { resolution: VideoPresets.h540.resolution, facingMode: 'user' }, audioCaptureDefaults: { echoCancellation: true, noiseSuppression: true, autoGainControl: true } });
    let t0 = 0, timer = 0, front = true, closed = false;
    const fmt = s => (s >= 3600 ? Math.floor(s / 3600) + ':' : '') + String(Math.floor(s / 60) % 60).padStart(2, '0') + ':' + String(s % 60).padStart(2, '0');
    const status = () => {
      const n = 1 + room.remoteParticipants.size;
      $('gcs').textContent = (t0 ? fmt(Math.floor((Date.now() - t0) / 1000)) + ' · ' : '') + n + ' ' + (n % 10 === 1 && n % 100 !== 11 ? 'участник' : (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) ? 'участника' : 'участников');
    };
    const tiles = new Map();
    function tileFor(p, me) {
      let t = tiles.get(p.identity);
      if (!t) { t = document.createElement('div'); t.className = 't' + (me ? ' me' : ''); tiles.set(p.identity, t); $('gcg').appendChild(t); }
      const camPub = p.getTrackPublication(Track.Source.Camera);
      const micPub = p.getTrackPublication(Track.Source.Microphone);
      const vt = camPub && !camPub.isMuted && camPub.track ? camPub.track : null;
      const muted = !micPub || micPub.isMuted;
      const key = (vt ? vt.sid || 'v' : 'a') + (muted ? 'm' : '') + (p.name || '');
      if (t.__k !== key) {
        t.__k = key;
        t.innerHTML = '';
        if (vt) { const v = vt.attach(); v.muted = true; v.playsInline = true; t.appendChild(v); }
        else t.insertAdjacentHTML('beforeend', avatarHtml(p.name || p.identity, p.metadata));
        t.insertAdjacentHTML('beforeend', `<div class="nm">${muted ? `<i>${svg('micOff')}</i>` : ''}<span>${esc(me ? 'Вы' : (p.name || 'Участник'))}</span></div>`);
      }
      return t;
    }
    function layout() {
      const all = [room.localParticipant, ...room.remoteParticipants.values()];
      const ids = new Set(all.map(p => p.identity));
      for (const [id, t] of tiles) if (!ids.has(id)) { t.remove(); tiles.delete(id); }
      all.forEach((p, i) => tileFor(p, i === 0));
      const n = all.length, wide = w.clientWidth > w.clientHeight;
      const cols = n <= 1 ? 1 : n === 2 ? (wide ? 2 : 1) : n <= 4 ? 2 : n <= 9 ? 3 : 4;
      all.forEach((p, i) => { const t = tiles.get(p.identity); if (t) t.style.gridColumn = (cols === 2 && n % 2 === 1 && i === n - 1) ? 'span 2' : ''; });
      $('gcg').style.gridTemplateColumns = `repeat(${cols},1fr)`;
      status();
    }
    const syncBtns = () => {
      const lp = room.localParticipant;
      $('gcm').classList.toggle('off', !lp.isMicrophoneEnabled); $('gcm').innerHTML = svg(lp.isMicrophoneEnabled ? 'mic' : 'micOff');
      $('gcv').classList.toggle('off', !lp.isCameraEnabled); $('gcv').innerHTML = svg(lp.isCameraEnabled ? 'cam' : 'camOff');
      $('gcf').parentElement.style.display = lp.isCameraEnabled ? '' : 'none';
    };
    const leave = async () => {
      if (closed) return; closed = true; clearInterval(timer);
      try { await room.disconnect(); } catch (e) {}
      w.classList.add('out'); setTimeout(() => { w.remove(); }, 260);
      GCall.active = false; o.onLeave && o.onLeave();
    };
    room
      .on(RoomEvent.ParticipantConnected, layout)
      .on(RoomEvent.ParticipantDisconnected, layout)
      .on(RoomEvent.TrackSubscribed, (track) => { if (track.kind === 'audio') { const a = track.attach(); $('gca').appendChild(a); } layout(); })
      .on(RoomEvent.TrackUnsubscribed, (track) => { track.detach().forEach(el => el.remove()); layout(); })
      .on(RoomEvent.TrackMuted, layout).on(RoomEvent.TrackUnmuted, layout)
      .on(RoomEvent.LocalTrackPublished, () => { layout(); syncBtns(); })
      .on(RoomEvent.LocalTrackUnpublished, () => { layout(); syncBtns(); })
      .on(RoomEvent.ParticipantMetadataChanged, layout).on(RoomEvent.ParticipantNameChanged, layout)
      .on(RoomEvent.ActiveSpeakersChanged, (sp) => { const s = new Set(sp.map(p => p.identity)); for (const [id, t] of tiles) t.classList.toggle('sp', s.has(id)); })
      .on(RoomEvent.Reconnecting, () => { $('gcs').textContent = 'Переподключение…'; })
      .on(RoomEvent.Reconnected, status)
      .on(RoomEvent.Disconnected, () => { if (!closed) leave(); });
    $('gce').onclick = leave;
    const api = o.api || (async (action, extra) => {
      const r = await fetch(o.fn, { method: 'POST', headers: { 'Content-Type': 'application/json', apikey: o.apikey || '', Authorization: 'Bearer ' + (o.auth || '') },
        body: JSON.stringify(Object.assign({ chat_id: o.chat_id, action }, extra || {})) });
      return await r.json().catch(() => ({}));
    });
    const toast = t => { const d = document.createElement('div'); d.className = 'toast'; d.textContent = t; w.appendChild(d); setTimeout(() => d.remove(), 2200); };
    $('gcadd').onclick = async () => {
      const sh = document.createElement('div'); sh.className = 'sheet';
      sh.innerHTML = `<div class="pn"><div class="ph"><span>Добавить в звонок</span><button data-x>Закрыть</button></div><div class="ls"><div style="padding:20px;text-align:center;opacity:.6">Загрузка…</div></div><button class="go" disabled>Пригласить</button></div>`;
      w.appendChild(sh);
      const close = () => sh.remove();
      sh.onclick = e => { if (e.target === sh) close(); };
      sh.querySelector('[data-x]').onclick = close;
      const r = await api('members').catch(() => ({}));
      const inRoom = new Set([room.localParticipant.identity, ...room.remoteParticipants.keys()]);
      const L = (r.members || []).filter(m => !inRoom.has(m.id));
      const sel = new Set();
      const ls = sh.querySelector('.ls'), go = sh.querySelector('.go');
      ls.innerHTML = L.length ? L.map(m => `<div class="r" data-u="${esc(m.id)}">${avatarHtml(m.name, JSON.stringify({ avatar: m.avatar, color: m.color }))}<b>${esc(m.name || 'Участник')}</b>${m.in_call ? '<small>в звонке</small>' : ''}<span class="ck">${svg('ok')}</span></div>`).join('')
        : '<div style="padding:20px;text-align:center;opacity:.6">Все участники группы уже в звонке</div>';
      ls.querySelectorAll('[data-u]').forEach(el => el.onclick = () => { const u = el.dataset.u; sel.has(u) ? sel.delete(u) : sel.add(u); el.classList.toggle('on', sel.has(u)); go.disabled = !sel.size; go.textContent = sel.size ? 'Пригласить (' + sel.size + ')' : 'Пригласить'; });
      go.onclick = async () => { go.disabled = true; const res = await api('invite', { user_ids: [...sel] }).catch(() => ({})); close(); toast(res && res.sent ? 'Приглашение отправлено' : (res.error || 'Не удалось пригласить')); };
    };
    $('gcm').onclick = async () => { await room.localParticipant.setMicrophoneEnabled(!room.localParticipant.isMicrophoneEnabled).catch(() => {}); syncBtns(); layout(); };
    $('gcv').onclick = async () => { await room.localParticipant.setCameraEnabled(!room.localParticipant.isCameraEnabled, { facingMode: front ? 'user' : 'environment' }).catch(() => {}); syncBtns(); layout(); };
    $('gcf').onclick = async () => {
      const pub = room.localParticipant.getTrackPublication(Track.Source.Camera);
      if (!pub || !pub.videoTrack) return;
      front = !front;
      try { await pub.videoTrack.restartTrack({ facingMode: front ? 'user' : 'environment' }); } catch (e) { front = !front; }
      const t = tiles.get(room.localParticipant.identity); if (t) t.classList.toggle('back', !front);
    };
    window.addEventListener('resize', layout);
    this.leave = leave;
    try {
      await room.connect(o.url, o.token);
      t0 = Date.now(); timer = setInterval(status, 1000);
      await room.localParticipant.setMicrophoneEnabled(true).catch(() => {});
      if (o.video) await room.localParticipant.setCameraEnabled(true).catch(() => {});
      try { await room.startAudio(); } catch (e) {}
      layout(); syncBtns();
    } catch (e) {
      $('gcs').textContent = 'Не удалось подключиться';
      setTimeout(leave, 1800);
    }
  }
};
})();
/* ===== TG6: групповые звонки на сайте ===== */
(function(){
const KEY6=SUPABASE_KEY;
const LKV='2.18.10';
const st=document.createElement('style'); st.setAttribute('data-lumo-own','1'); st.textContent=`
#gcban{display:flex;align-items:center;gap:10px;padding:8px 14px;background:var(--panel);border-bottom:1px solid var(--line);cursor:pointer;animation:gcbin .3s ease}
@keyframes gcbin{from{opacity:0;transform:translateY(-8px)}}
#gcban .ci{width:30px;height:30px;border-radius:50%;background:#34c759;color:#fff;display:grid;place-items:center;flex:none}
#gcban .ci svg{width:16px;height:16px}
#gcban b{display:block;font-size:15px}#gcban small{color:var(--muted);font-size:13px}
#gcban .go{margin-left:auto;background:#34c759;color:#fff;font-weight:800;border-radius:16px;padding:7px 16px}`;
document.head.appendChild(st);
const loadLK=()=>new Promise(res=>{ if(window.LivekitClient) return res(true);
  const add=(u,next)=>{ const s=document.createElement('script'); s.src=u; s.onload=()=>res(true); s.onerror=next; document.head.appendChild(s); };
  add(`https://cdn.jsdelivr.net/npm/livekit-client@${LKV}/dist/livekit-client.umd.js`,()=>add(`https://unpkg.com/livekit-client@${LKV}/dist/livekit-client.umd.js`,()=>res(false))); });
async function lkApi(chat,action){ const ses=await sb.auth.getSession(); const tk=ses&&ses.data&&ses.data.session&&ses.data.session.access_token;
  const r=await fetch(`${SUPABASE_URL}/functions/v1/lumo-lk`,{method:'POST',headers:{'Content-Type':'application/json',apikey:KEY6,Authorization:'Bearer '+tk},body:JSON.stringify({chat_id:chat,action})});
  return await r.json().catch(()=>({})); }
const plur=n=>n+' '+(n%10===1&&n%100!==11?'участник':(n%10>=2&&n%10<=4&&(n%100<10||n%100>=20))?'участника':'участников');
let gcBusy=false;
window.tgGcall=async(c,video,join)=>{ if(!c||gcBusy||(window.GCall&&GCall.active)) return; gcBusy=true;
  try{ const ok=await loadLK(); if(!ok){ toast('Не удалось загрузить звонок'); return; }
    const r=await lkApi(c.chat_id||c.id,join?'join':'start'); if(r.error){ toast(r.error); return; } if(!r.token){ toast('Не удалось начать звонок'); return; }
    GCall.open({url:r.url,token:r.token,title:c.title||'Групповой звонок',video,api:(a,e)=>window.tgLkApi(c.chat_id||c.id,a,e),onLeave:()=>setTimeout(poll,1500)}); }
  finally{ gcBusy=false; } };
async function poll(){ let c=null; try{ c=cur(); }catch(e){}
  const ban=document.getElementById('gcban');
  if(!c||c.type!=='group'){ ban&&ban.remove(); return; }
  const r=await lkApi(c.chat_id||c.id,'status').catch(()=>({})); const n=(r&&r.count)||0;
  let b=document.getElementById('gcban');
  if(!n){ b&&b.remove(); return; }
  if(!b||b.dataset.c!==String(c.chat_id||c.id)){ b&&b.remove(); b=document.createElement('div'); b.id='gcban'; b.dataset.c=String(c.chat_id||c.id); const pin=document.getElementById('pinbar'); if(!pin) return; pin.parentNode.insertBefore(b,pin);
    b.onclick=()=>window.tgGcall(c,false); }
  b.innerHTML=`<span class="ci">${ic('phone')}</span><span><b>Групповой звонок</b><small>${plur(n)}</small></span><span class="go">Войти</span>`; }
let lastChat=null;
setInterval(()=>{ let c=null; try{ c=cur(); }catch(e){} const id=c&&(c.chat_id||c.id); if(id!==lastChat){ lastChat=id; poll(); } },800);
setInterval(poll,15000);
})();

/* ===== TG7: приглашения в групповой звонок, настройка звонков группы, «Изменить контакт» как в приложении ===== */
(function(){
const KEY7=SUPABASE_KEY;
const st=document.createElement('style'); st.setAttribute('data-lumo-own','1'); st.textContent=`
#gcinv{position:fixed;inset:0;z-index:2147482000;background:linear-gradient(#1b2a4a,#0b0b10);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:24px;text-align:center;animation:tgup .38s cubic-bezier(.2,.9,.3,1)}
#gcinv.out{animation:tgdown .3s ease forwards}
#gcinv .ring{position:relative;width:150px;height:150px;display:grid;place-items:center}
#gcinv .ring:before{content:'';position:absolute;inset:0;border-radius:50%;background:rgba(255,255,255,.12);animation:gcpulse 1.6s ease-out infinite}
@keyframes gcpulse{from{transform:scale(.95);opacity:1}to{transform:scale(1.3);opacity:0}}
#gcinv .ring .av{width:120px!important;height:120px!important;font-size:44px}
#gcinv h2{font-size:28px;margin:16px 0 4px}
#gcinv .s1{opacity:.7;font-size:16px}#gcinv .s2{font-size:15px;font-weight:600;margin-top:4px;opacity:.9}
#gcinv .who{margin-top:18px;background:rgba(255,255,255,.08);border-radius:18px;padding:14px 18px;max-width:420px;width:100%}
#gcinv .who small{display:block;font-size:12px;font-weight:800;opacity:.55;margin-bottom:6px}
#gcinv .bt{display:flex;gap:70px;margin-top:46px}
#gcinv .bt div{display:flex;flex-direction:column;align-items:center;gap:8px;font-size:14px;opacity:.9}
#gcinv .bt button{width:74px;height:74px;border-radius:50%;border:0;color:#fff;display:grid;place-items:center;cursor:pointer;transition:transform .15s}
#gcinv .bt button:active{transform:scale(.92)}
#gcinv .bt button svg{width:32px;height:32px}
#gcinv .no{background:#ff3b30}#gcinv .yes{background:#34c759}
.tggcm .r{display:flex;align-items:center;justify-content:space-between;padding:13px 16px;cursor:pointer;border-top:1px solid var(--line)}
.tggcm .r:first-child{border-top:0}.tggcm .r svg{width:20px;height:20px;color:var(--a1);opacity:0;transition:opacity .15s}.tggcm .r.on svg{opacity:1}
.tggcm{background:var(--panel2);border-radius:16px;overflow:hidden;margin-top:6px}
#tgce{position:fixed;inset:0;z-index:99700;background:var(--bg);color:var(--text);overflow:auto;animation:tgup .36s cubic-bezier(.2,.9,.3,1)}
#tgce.out{animation:tgdown .3s ease forwards}
#tgce .w{max-width:560px;margin:0 auto;padding:max(12px,env(safe-area-inset-top)) 16px 40px}
#tgce .tb{display:flex;justify-content:space-between;align-items:center;height:56px}
#tgce .tb button{width:48px;height:48px;border-radius:50%;border:1px solid var(--line);background:var(--panel2);display:grid;place-items:center;color:var(--text);cursor:pointer}
#tgce .tb button.ok{background:var(--a1);border-color:var(--a1);color:#fff}
#tgce .tb button svg{width:22px;height:22px}
#tgce .ava{display:grid;place-items:center;margin:4px 0 22px}
#tgce .ava .av,#tgce .ava img{width:116px!important;height:116px!important;border-radius:50%;object-fit:cover;font-size:42px}
#tgce .cd{background:var(--panel);border-radius:26px;overflow:hidden;margin-bottom:8px}
#tgce .cd input,#tgce .cd textarea{display:block;width:100%;box-sizing:border-box;border:0;outline:0;background:none;color:var(--text);font-size:17px;padding:16px 18px;font-family:inherit;resize:none}
#tgce .cd input+input{border-top:1px solid var(--line)}
#tgce .hint{color:var(--muted);font-size:13px;margin:0 20px 22px}
#tgce .act{display:flex;align-items:center;gap:14px;padding:16px 18px;color:var(--a1);cursor:pointer;font-size:16px}
#tgce .act+.act{border-top:1px solid var(--line)}
#tgce .act svg{width:22px;height:22px}
#tgce .del{color:var(--danger,#ff3b30)}`;
document.head.appendChild(st);

async function lk(chat,action,extra){ const ses=await sb.auth.getSession(); const tk=ses&&ses.data&&ses.data.session&&ses.data.session.access_token;
  const r=await fetch(`${SUPABASE_URL}/functions/v1/lumo-lk`,{method:'POST',headers:{'Content-Type':'application/json',apikey:KEY7,Authorization:'Bearer '+tk},body:JSON.stringify(Object.assign({chat_id:chat,action},extra||{}))});
  return await r.json().catch(()=>({})); }
window.tgLkApi=lk;

/* --- входящее приглашение --- */
window.tgShowInvite=p=>showInvite(p);
function showInvite(p){ if(!p||!p.chat_id||(window.GCall&&GCall.active)||document.getElementById('gcinv')) return;
  const d=document.createElement('div'); d.id='gcinv';
  const names=(p.names||[]).filter(Boolean);
  d.innerHTML=`<div class="ring">${avatar({name:p.title,avatar:p.avatar,color:p.color||0},'l')}</div><h2>${esc(p.title||'Группа')}</h2><div class="s1">Входящий групповой звонок</div><div class="s2">${p.from?esc(p.from)+' приглашает вас':'Звонок уже идёт'}</div>
${names.length?`<div class="who"><small>УЖЕ В ЗВОНКЕ</small>${esc(names.slice(0,6).join(', '))}${names.length>6?' и ещё '+(names.length-6):''}</div>`:''}
<div class="bt"><div><button class="no">${ic('phone')}</button>Отклонить</div><div><button class="yes">${ic('phone')}</button>Присоединиться</div></div>`;
  d.querySelector('.no svg').style.transform='rotate(135deg)';
  document.body.appendChild(d);
  try{ navigator.vibrate&&navigator.vibrate([300,200,300]); }catch(e){}
  const close=()=>{ if(!d.isConnected) return; d.classList.add('out'); setTimeout(()=>d.remove(),300); };
  d.querySelector('.no').onclick=close;
  d.querySelector('.yes').onclick=async()=>{ close(); const c=S.chatMap.get(p.chat_id)||{chat_id:p.chat_id,type:'group',title:p.title}; window.tgGcall&&window.tgGcall(c,false,true); };
  setTimeout(close,45000); }
let gcCh=null;
setInterval(()=>{ if(gcCh||!S||!S.me||!S.me.id) return;
  gcCh=sb.channel('lm-gc-'+S.me.id).on('broadcast',{event:'invite'},m=>showInvite(m&&m.payload)).on('broadcast',{event:'premium'},()=>{ const was=!!(S.me&&S.me.premium); refreshMe().then(()=>{ try{ renderSettings(); }catch(e){} if(!was&&S.me&&S.me.premium) toast('Lumo Premium активирован'); }); }).subscribe(); },1500);

/* --- настройка «кто может звонить» в редактировании группы --- */
window.tgGcSet=async(box,c)=>{ if(!box||!c) return; const id=c.chat_id||c.id; const r=await lk(id,'status'); if(!r||!r.admin) return;
  let mode=r.mode||'all';
  const draw=()=>{ box.innerHTML=`<div class="field"><label>Групповые звонки</label><div class="tggcm">${[['all','Все могут начать звонок'],['admins','Только администраторы начинают'],['off','Звонки отключены']].map(([k,t])=>`<div class="r ${mode===k?'on':''}" data-m="${k}">${t}${ic('check')}</div>`).join('')}</div></div>`;
    box.querySelectorAll('[data-m]').forEach(el=>el.onclick=async()=>{ const old=mode; mode=el.dataset.m; draw(); const {error}=await sb.rpc('lm_set_group_calls',{p_chat:id,p_mode:mode}); if(error){ mode=old; draw(); toast(error.message); } }); };
  draw(); };

/* --- «Изменить контакт» (плавное окно, как в приложении) --- */
window.tgContactEdit=async(uid)=>{ const p=S.profiles.get(uid)||{}; if(p.is_bot){ toast('Имя бота изменить нельзя'); return; }
  const real=p.__real||p.name||''; const al=S.alias.get(uid)||'';
  const {data:row}=await sb.from('lm_contacts').select('note,photo').eq('contact_id',uid).maybeSingle();
  const full=al||real; const sp=full.indexOf(' ');
  let first=sp>0?full.slice(0,sp):full, last=sp>0?full.slice(sp+1):'', note=(row&&row.note)||'', photo=(row&&row.photo)||null, newFile=null, newUrl=null;
  const d=document.createElement('div'); d.id='tgce';
  const avHtml=()=>newUrl?`<img src="${newUrl}">`:avatar({name:first||real,avatar:photo||p.avatar_url,color:p.color||0},'l');
  const draw=()=>{ d.innerHTML=`<div class="w"><div class="tb"><button data-k="x">${ic('x')}</button><button class="ok" data-k="s">${ic('check')}</button></div>
<div class="ava">${avHtml()}</div>
<div class="cd"><input id="ceF" placeholder="Имя" maxlength="64" value="${esc(first)}"><input id="ceL" placeholder="Фамилия" maxlength="64" value="${esc(last)}"></div><div style="height:14px"></div>
<div class="cd"><textarea id="ceN" rows="2" maxlength="300" placeholder="Заметка">${esc(note)}</textarea></div><div class="hint">Заметку видите только Вы.</div>
<div class="cd"><div class="act" data-k="ph">${ic('image')}Установить фото для ${esc(first||real)}</div>${(photo||newUrl)?`<div class="act" data-k="rp">${ic('back')}Вернуть настоящее фото</div>`:''}</div>
<div class="hint">Вы можете заменить фотографию ${esc(real)} другой по своему выбору. Она будет видна только Вам.</div>
${isContact(uid)?`<div class="cd"><div class="act del" data-k="dl">Удалить контакт</div></div>`:''}</div>`;
    const keep=()=>{ first=d.querySelector('#ceF').value; last=d.querySelector('#ceL').value; note=d.querySelector('#ceN').value; };
    d.querySelector('[data-k=x]').onclick=close;
    d.querySelector('[data-k=s]').onclick=async()=>{ keep(); const b=d.querySelector('[data-k=s]'); b.style.opacity=.6; b.style.pointerEvents='none';
      try{ let url=photo; if(newFile) url=await upload(newFile,'jpg');
        const {error}=await sb.rpc('lm_set_contact_extra',{p_user:uid,p_note:note.trim(),p_photo:url||''}); if(error) throw error;
        const name=[first,last].map(x=>x.trim()).filter(Boolean).join(' '); await saveAlias(uid,name===real?'':name); close(); }
      catch(e){ toast(e.message||'Ошибка'); b.style.opacity=1; b.style.pointerEvents=''; } };
    d.querySelector('[data-k=ph]').onclick=()=>{ keep(); const i=document.createElement('input'); i.type='file'; i.accept='image/*'; i.style.cssText='position:fixed;left:-9999px';
      document.body.appendChild(i); i.onchange=async()=>{ const f=i.files&&i.files[0]; i.remove(); if(!f) return; newFile=await compressImage(f); newUrl=URL.createObjectURL(newFile); draw(); }; i.click(); };
    const rp=d.querySelector('[data-k=rp]'); rp&&(rp.onclick=()=>{ keep(); photo=null; newFile=null; newUrl=null; draw(); });
    const dl=d.querySelector('[data-k=dl]'); dl&&(dl.onclick=()=>confirmBox('Удалить контакт?','Удалить',async()=>{ await removeContact(uid); close(); })); };
  const close=()=>{ d.classList.add('out'); setTimeout(()=>d.remove(),300); };
  draw(); document.body.appendChild(d); };
})();

/* ===== TG8: открыли Lumo из уведомления о групповом звонке — сразу показываем «Входящий групповой звонок» ===== */
(function(){
try{ navigator.serviceWorker&&navigator.serviceWorker.addEventListener('message',e=>{ const id=e.data&&e.data.lumoOpen; if(!id) return;
  setTimeout(async()=>{ const c=S.chatMap&&S.chatMap.get(id); if(!c||c.type!=='group'||(window.GCall&&GCall.active)||!window.tgLkApi) return;
    const r=await window.tgLkApi(id,'status'); if(!r||!r.count) return;
    const inv=document.getElementById('gcinv'); if(inv) return;
    window.tgShowInvite&&window.tgShowInvite({chat_id:id,title:c.title,avatar:c.avatar_url,color:c.color,from:'',names:r.names||[]}); },1200); }); }catch(e){}
})();

/* ===== Блокировка аккаунта: окно с кирпичной стеной и апелляция; боты: остановить/перезапустить ===== */
P.stopsq='<rect x="6" y="6" width="12" height="12" rx="2.5" fill="currentColor"/>';
(function(){ const st=document.createElement('style'); st.textContent=`
#bannedScr{position:fixed;inset:0;z-index:99990;background:var(--bg);color:var(--text);overflow-y:auto;overflow-x:hidden;display:block;padding:0;text-align:center;animation:bnIn .45s ease both}
#bannedScr::before{content:"";position:absolute;left:0;right:0;top:0;height:420px;background:radial-gradient(ellipse at 50% 0,rgba(255,91,91,.26),transparent 70%);pointer-events:none}
@keyframes bnIn{from{opacity:0;transform:scale(1.03)}to{opacity:1;transform:none}}
#bannedScr .bnw{position:relative;max-width:440px;margin:0 auto;padding:56px 20px 30px}
#bannedScr .wall{position:relative;width:250px;height:190px;margin:0 auto}
#bannedScr .bricks{position:absolute;left:0;top:0;width:250px;height:150px;overflow:hidden;-webkit-mask:linear-gradient(transparent,#000 38%);mask:linear-gradient(transparent,#000 38%)}
#bannedScr .bk{position:absolute;height:21px;border-radius:4px;box-shadow:0 1.5px 2px rgba(0,0,0,.28),inset 0 2px 0 rgba(255,255,255,.18);opacity:0;animation:bkDrop .55s cubic-bezier(.3,1.5,.6,1) both}
@keyframes bkDrop{from{opacity:0;transform:translateY(-110px)}to{opacity:1;transform:none}}
#bannedScr .lk{position:absolute;left:50%;bottom:0;width:84px;height:84px;margin-left:-42px;border-radius:50%;background:var(--bg);padding:4px;opacity:0;animation:lkPop .6s cubic-bezier(.3,1.6,.5,1) .85s both}
#bannedScr .lk i{display:grid;place-items:center;width:100%;height:100%;border-radius:50%;background:linear-gradient(135deg,#ff6a5b,#e0284f);color:#fff;box-shadow:0 10px 26px rgba(224,40,79,.5)}
#bannedScr .lk svg{width:34px;height:34px}
@keyframes lkPop{from{opacity:0;transform:scale(.2)}to{opacity:1;transform:none}}
#bannedScr h2{margin:20px 0 0;font-size:26px;font-weight:800;letter-spacing:-.2px}
#bannedScr .sub{margin:10px 8px 0;color:var(--muted);font-size:15px;line-height:1.45}
#bannedScr .why{margin-top:22px;text-align:left;background:var(--panel);border:1px solid rgba(255,106,91,.35);border-radius:18px;padding:16px}
#bannedScr .why small{display:flex;align-items:center;gap:6px;color:#ff6a5b;font-size:12px;font-weight:700;letter-spacing:.3px}
#bannedScr .why small svg{width:15px;height:15px}
#bannedScr .why b{display:block;margin-top:6px;font-size:16px;font-weight:600;white-space:pre-wrap;word-break:break-word}
#bannedScr .apst{margin-top:12px;display:flex;gap:12px;text-align:left;background:var(--panel);border-radius:18px;padding:14px}
#bannedScr .apst svg{width:24px;height:24px;flex:none;color:#f0a23a}
#bannedScr .apst.rej svg{color:var(--danger)}
#bannedScr .apst b{display:block;font-size:15px}#bannedScr .apst span{display:block;margin-top:3px;color:var(--muted);font-size:13.5px;line-height:1.4;white-space:pre-wrap}
#bannedScr .bnbtn,#apSheet .bnbtn{margin-top:22px;width:100%;height:54px;border:0;border-radius:16px;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;font-weight:700;font-size:17px;font-family:inherit;display:flex;align-items:center;justify-content:center;gap:8px;cursor:pointer;transition:transform .15s,opacity .2s}
#bannedScr .bnbtn:active,#apSheet .bnbtn:active{transform:scale(.97)}#bannedScr .bnbtn[disabled],#apSheet .bnbtn[disabled]{opacity:.5;cursor:default}
#bannedScr .bnbtn svg,#apSheet .bnbtn svg{width:20px;height:20px}
#bannedScr .bnout{margin-top:8px;background:none;border:0;color:var(--muted);font-weight:600;font-size:15px;font-family:inherit;padding:12px 16px;cursor:pointer;border-radius:10px}
#bannedScr .bnout:hover{background:var(--hover)}
#apSheet{position:fixed;inset:0;z-index:99991;background:var(--bg);display:flex;flex-direction:column;transform:translateY(100%);transition:transform .38s cubic-bezier(.2,.9,.3,1)}
#apSheet.on{transform:none}
#apSheet .aph{display:flex;align-items:center;padding:12px 14px}
#apSheet .aph button{width:40px;height:40px;border-radius:50%;border:0;background:var(--panel);color:var(--text);display:grid;place-items:center;cursor:pointer}
#apSheet .aph button svg{width:20px;height:20px}
#apSheet .aph b{flex:1;text-align:center;font-size:17px}
#apSheet .apb{flex:1;overflow:auto;padding:8px 20px 20px;max-width:560px;width:100%;margin:0 auto;box-sizing:border-box}
#apSheet .aphd{display:flex;gap:12px;align-items:center}
#apSheet .aphd i{width:48px;height:48px;flex:none;border-radius:14px;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;display:grid;place-items:center}
#apSheet .aphd i svg{width:24px;height:24px}
#apSheet .aphd b{display:block;font-size:18px}#apSheet .aphd span{color:var(--muted);font-size:13.5px}
#apSheet textarea{margin-top:14px;width:100%;min-height:220px;box-sizing:border-box;border:0;outline:0;resize:vertical;background:var(--panel);color:var(--text);border-radius:18px;padding:16px;font-size:16px;line-height:1.45;font-family:inherit}
#apSheet .apm{display:flex;gap:10px;margin-top:8px;color:var(--muted);font-size:12.5px}#apSheet .apm span:first-child{flex:1}
#apSheet .aperr{color:var(--danger);font-size:14px;margin-top:8px}
#apSheet .apf{padding:12px 20px 18px;max-width:560px;width:100%;margin:0 auto;box-sizing:border-box}
#apSheet .apf .bnbtn{margin:0}
#apSheet .apok{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:30px;animation:bnIn .4s ease both}
#apSheet .apok i{width:88px;height:88px;border-radius:50%;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;display:grid;place-items:center}
#apSheet .apok i svg{width:46px;height:46px}
#apSheet .apok b{margin-top:18px;font-size:22px}#apSheet .apok span{margin-top:8px;color:var(--muted);font-size:15px;max-width:360px}
#apSheet .bnbtn,#bannedScr .bnbtn{font-family:inherit}
.adapl{background:var(--panel);border-radius:16px;padding:14px;margin-bottom:10px}
.adapl .h{display:flex;align-items:center;gap:10px}.adapl .h .mid{flex:1;min-width:0}.adapl .h b{display:block}.adapl .h span{color:var(--muted);font-size:13px}
.adapl .rs{margin-top:10px;font-size:13px;color:var(--muted)}.adapl .rs em{font-style:normal;color:#ff6a5b}
.adapl .tx{margin-top:8px;white-space:pre-wrap;word-break:break-word;line-height:1.45}
.adapl .rb{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}
.adapl .rb button{display:flex;align-items:center;gap:6px;border:0;border-radius:10px;padding:8px 12px;background:var(--panel2,var(--hover));color:var(--text);font-weight:600;font-size:13.5px;font-family:inherit;cursor:pointer}
.adapl .rb button svg{width:16px;height:16px}.adapl .rb .ok{background:rgba(62,224,160,.16);color:#22b07d}.adapl .rb .no{background:rgba(255,91,122,.14);color:var(--danger)}
.adapl .st{font-size:13px;color:var(--muted)}
`; document.head.appendChild(st); })();

let BAN=null, banTimer=null;
function banState(j){ if(!j||!j.banned) return null; const a=j.appeal||{}; return {reason:j.reason||'',st:a.status||null,reply:a.reply||'',at:a.created_at||null}; }
async function banCheck(){ try{ const {data,error}=await sb.rpc('lm_my_ban'); if(error||!data) return;
  const b=banState(data);
  if(!b){ if(BAN){ BAN=null; location.reload(); } return; }
  const changed=JSON.stringify(b)!==JSON.stringify(BAN); BAN=b; if(changed||!document.getElementById('bannedScr')) drawBanned(); }catch(e){} }
function banWatch(){ clearInterval(banTimer); banCheck(); banTimer=setInterval(banCheck,30000); }
function brickWall(){ let h=''; const tones=['#c8553d','#b4472f','#d76a4c','#a63f2b','#bf5a3f']; const rows=6, per=5, gap=4, bw=(250-gap*(per-1))/per, bh=21;
  for(let r=0;r<rows;r++){ const odd=r%2===1, n=odd?per+1:per, sh=odd?-bw/2:0;
    for(let i=0;i<n;i++){ const ord=(rows-1-r)*(per+1)+i, c=tones[(r*3+i*7)%tones.length];
      h+=`<span class="bk" style="left:${(sh+i*(bw+gap)).toFixed(1)}px;top:${r*(bh+gap)}px;width:${bw.toFixed(1)}px;background:linear-gradient(${c},${c}cc);animation-delay:${(ord*0.028).toFixed(3)}s"></span>`; } }
  return h; }
function drawBanned(){ const b=BAN; if(!b) return; let d=document.getElementById('bannedScr'); const fresh=!d;
  if(fresh){ d=document.createElement('div'); d.id='bannedScr'; ($('#lumo-root')||document.body).appendChild(d); }
  const pend=b.st==='pending', rej=b.st==='rejected', un=S.me&&S.me.username;
  const apst=b.st&&b.st!=='accepted'?`<div class="apst ${rej?'rej':''}">${ic(rej?'x':'hourglass')}<div><b>${rej?'Апелляция отклонена':'Апелляция отправлена'}</b><span>${rej?(b.reply?'Ответ модератора: '+esc(b.reply):'Модераторы оставили блокировку в силе.'):'Модераторы рассмотрят её и снимут блокировку, если согласятся. Это окно обновится само.'}</span></div></div>`:'';
  const body=`<div class="bnw">${fresh?`<div class="wall"><div class="bricks">${brickWall()}</div><div class="lk"><i>${ic('lock')}</i></div></div>`:d.querySelector('.wall').outerHTML}
<h2>Ваш аккаунт заблокирован</h2>
<p class="sub">Администрация Lumo ограничила доступ к аккаунту${un?' @'+esc(un):''}. Пока блокировка действует, нельзя писать сообщения и пользоваться Lumo.</p>
<div class="why"><small>${ic('info')}ПРИЧИНА</small><b>${b.reason?esc(b.reason):'Причина не указана'}</b></div>${apst}
<button class="bnbtn" id="bnAp" ${pend?'disabled':''}>${ic(pend?'clock':'send')}${pend?'Апелляция на рассмотрении':rej?'Подать апелляцию ещё раз':'Подать апелляцию'}</button>
<button class="bnout" id="bnOut">Выйти из аккаунта</button></div>`;
  d.innerHTML=body;
  d.querySelector('#bnAp').onclick=()=>{ if(!pend) openAppeal(); };
  d.querySelector('#bnOut').onclick=()=>confirmBox('Выйти из аккаунта?','Выйти',()=>{ clearInterval(banTimer); logout(); }); }
function showBanned(me){ S.me=S.me||me; BAN=BAN||{reason:me.ban_reason||'',st:null,reply:'',at:null}; drawBanned(); banWatch(); }
function openAppeal(){ document.getElementById('apSheet')?.remove();
  const s=document.createElement('div'); s.id='apSheet';
  s.innerHTML=`<div class="aph"><button id="apX" title="Закрыть">${ic('x')}</button><b>Апелляция</b><span style="width:40px"></span></div>
<div class="apb"><div class="aphd"><i>${ic('chat')}</i><div><b>Расскажите, что случилось</b><span>За что вас могли заблокировать и почему блокировку стоит снять</span></div></div>
<textarea id="apT" maxlength="2000" placeholder="Например: я отправил много одинаковых сообщений, потому что…"></textarea>
<div class="apm"><span>Пишите честно и спокойно — так апелляцию рассмотрят быстрее.</span><span id="apN">0/2000</span></div><div class="aperr" id="apE"></div></div>
<div class="apf"><button class="bnbtn" id="apS" disabled>${ic('send')}Отправить апелляцию</button></div>`;
  document.body.appendChild(s); requestAnimationFrame(()=>requestAnimationFrame(()=>s.classList.add('on')));
  const close=()=>{ s.classList.remove('on'); setTimeout(()=>s.remove(),400); };
  const T=s.querySelector('#apT'), B=s.querySelector('#apS');
  setTimeout(()=>T.focus(),380);
  s.querySelector('#apX').onclick=close;
  T.oninput=()=>{ s.querySelector('#apN').textContent=T.value.length+'/2000'; B.disabled=T.value.trim().length<10; };
  B.onclick=async()=>{ if(B.disabled) return; B.disabled=true; B.innerHTML='<span class="tgsp"></span>'; s.querySelector('#apE').textContent='';
    const {data,error}=await sb.rpc('lm_appeal_submit',{p_text:T.value.trim()});
    if(error){ s.querySelector('#apE').textContent=error.message; B.disabled=false; B.innerHTML=ic('send')+'Отправить апелляцию'; return; }
    BAN=banState(data)||BAN; drawBanned();
    s.querySelector('.apb').outerHTML=`<div class="apok"><i>${ic('check')}</i><b>Апелляция отправлена</b><span>Модераторы прочитают ваше обращение. Если блокировку снимут, Lumo откроется сам.</span></div>`;
    B.disabled=false; B.innerHTML='Готово'; B.onclick=close; }; }

/* --- боты --- */
function isBotUser(uid){ if(!uid) return false; if(S.profiles.get(uid)?.is_bot) return true; return S.chats.some(c=>c.type==='private'&&c.peer_id===uid&&c.peer_bot); }
async function botStop(uid,stop,chatId){ if(!(await doBlock(uid,stop))) return; toast(stop?'Бот остановлен':'Бот перезапущен'); afterPeerChange();
  if(!stop&&chatId&&cur()&&cur().chat_id===chatId){ startBot(); } }

/* --- админка: апелляции --- */
async function admApl(V){
  AD.f.apl=AD.f.apl||'pending';
  V.innerHTML=adChips([['pending','Новые'],['rejected','Отклонённые'],['accepted','Принятые'],['all','Все']],AD.f.apl)+'<div id="admL"></div>';
  const L=V.querySelector('#admL');
  const load=async()=>{ L.innerHTML='<div class="adload"><span class="tgsp"></span></div>';
    try{ const R=await rpc('lm_admin_appeals',{p_status:AD.f.apl});
      L.innerHTML=R.length?`<div class="adcount">Апелляций: ${R.length}</div>`+R.map(a=>`<div class="adapl"><div class="h">${avatar({name:a.name,avatar:a.avatar_url,color:a.color},'s')}<div class="mid"><b>${esc(a.name||'')}</b><span>@${esc(a.username||'?')} · ${admAgo(a.created_at)}</span></div></div>
<div class="rs">Причина блокировки: <em>${esc(a.ban_reason||'не указана')}</em></div><div class="tx">${esc(a.text)}</div>
<div class="rb"><button data-u2="${a.user_id}">${ic('user')}Профиль</button>${a.status==='pending'?`<button class="ok" data-ok="${a.id}">${ic('check')}Разблокировать</button><button class="no" data-no="${a.id}">${ic('x')}Отклонить</button>`:`<span class="st">${a.status==='accepted'?'принята — разблокирован':'отклонена'}${a.reply?' · «'+esc(a.reply)+'»':''}</span>`}</div></div>`).join(''):adEmpty(AD.f.apl==='pending'?'Новых апелляций нет':'Пусто');
      L.querySelectorAll('[data-u2]').forEach(b=>b.onclick=()=>admPush({t:'user',id:b.dataset.u2}));
      L.querySelectorAll('[data-ok]').forEach(b=>b.onclick=()=>confirmBox('Принять апелляцию и разблокировать пользователя?','Разблокировать',async()=>{ try{ await rpc('lm_admin_appeal_resolve',{p_id:+b.dataset.ok,p_accept:true}); toast('Пользователь разблокирован'); load(); }catch(e){ toast(e.message); } }));
      L.querySelectorAll('[data-no]').forEach(b=>b.onclick=()=>modal('Отклонить апелляцию',`<div class="field"><label>Ответ пользователю (необязательно)</label><textarea class="inp" id="aplR" rows="3" maxlength="500" style="resize:none" placeholder="Например: нарушение подтвердилось"></textarea></div>`,
        [['Отмена','ghost'],['Отклонить','danger',async c=>{ const r=$('#aplR').value.trim(); c(); try{ await rpc('lm_admin_appeal_resolve',{p_id:+b.dataset.no,p_accept:false,p_reply:r}); toast('Апелляция отклонена'); load(); }catch(e){ toast(e.message); } }]])); }
    catch(e){ L.innerHTML=adEmpty(esc(e.message)); } };
  V.querySelectorAll('.adchips [data-f]').forEach(b=>b.onclick=()=>{ AD.f.apl=b.dataset.f; V.querySelectorAll('.adchips button').forEach(x=>x.classList.toggle('on',x===b)); load(); });
  await load(); }

/* ===== Мини-игры: броски в чате и игры вдвоём (крестики-нолики, шашки, морской бой) ===== */
P.gem='<path d="M6.5 3h11l4 6-9.5 12L2.5 9z" fill="currentColor" stroke="none"/>';
P.gamepad='<path d="M7 8h10a5 5 0 0 1 4.6 7l-.9 2.1a2.6 2.6 0 0 1-4.3.7L14.6 16H9.4l-1.8 1.8a2.6 2.6 0 0 1-4.3-.7L2.4 15A5 5 0 0 1 7 8z"/><path d="M7.5 10.5v3M6 12h3"/><circle cx="16" cy="11" r=".6" fill="currentColor"/><circle cx="18" cy="13" r=".6" fill="currentColor"/>';
const LG_GAMES_HTML="<!doctype html>\n<html lang=\"ru\"><head><meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover\">\n<title>Игра</title>\n<style>\n:root{--bg:#0c0d1a;--panel:#15162c;--panel2:#1d1f3b;--line:rgba(255,255,255,.08);--text:#eef0ff;--muted:#8d90b8;--a1:#7c5cff;--a2:#22c1ff;--danger:#ff5b7a;--ok:#2bd67b;--gold:#f5b942;--cell:#23264a;--cell2:#2c2f58}\n.light{--bg:#f6f5ff;--panel:#ffffff;--panel2:#efeefe;--line:rgba(20,20,60,.09);--text:#191a33;--muted:#6d6f93;--cell:#e9e7fb;--cell2:#d9d5f6}\n*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}\nhtml,body{margin:0;height:100%;background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,\"SF Pro Text\",Roboto,\"Segoe UI\",Manrope,system-ui,sans-serif;overscroll-behavior:none;-webkit-user-select:none;user-select:none}\n#app{min-height:100%;display:flex;flex-direction:column;padding:calc(env(safe-area-inset-top) + 10px) 16px calc(env(safe-area-inset-bottom) + 16px);max-width:560px;margin:0 auto}\n.top{display:flex;align-items:center;gap:10px}\n.top h1{flex:1;margin:0;font-size:18px;font-weight:800;text-align:center}\n.ib{width:40px;height:40px;border-radius:50%;border:0;background:var(--panel);color:var(--text);display:grid;place-items:center;cursor:pointer;flex:none}\n.ib svg{width:20px;height:20px}\n.chip{display:inline-flex;align-items:center;gap:6px;padding:6px 11px;border-radius:999px;background:var(--panel);font-size:13px;font-weight:700;color:var(--gold)}\n.chip svg{width:15px;height:15px}\n.players{display:flex;align-items:center;gap:10px;margin-top:16px}\n.pl{flex:1;min-width:0;display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:16px;background:var(--panel);border:2px solid transparent;transition:border-color .25s,box-shadow .25s}\n.pl.r{flex-direction:row-reverse;text-align:right}\n.pl.on{border-color:var(--a1);box-shadow:0 0 0 4px color-mix(in srgb,var(--a1) 18%,transparent)}\n.pl .av{width:36px;height:36px;border-radius:50%;display:grid;place-items:center;font-weight:800;color:#fff;flex:none;background:linear-gradient(135deg,var(--a1),var(--a2))}\n.pl .av.o{background:linear-gradient(135deg,#ff8a5b,#ff5b8a)}\n.pl b{display:block;font-size:14px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.pl span{display:block;font-size:12px;color:var(--muted)}\n.pl .mk{width:22px;height:22px;flex:none}\n.vs{font-size:12px;font-weight:800;color:var(--muted)}\n.status{margin:14px 0 4px;text-align:center;font-size:15px;font-weight:700;min-height:22px}\n.status.me{color:var(--a1)}\n.board-wrap{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:8px 0}\n/* крестики-нолики */\n.ttt{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));grid-template-rows:repeat(3,minmax(0,1fr));gap:8px;width:min(86vw,340px);height:min(86vw,340px)}\n.ttt button{border:0;border-radius:18px;background:var(--panel);display:block;position:relative;cursor:pointer;padding:0;min-width:0;min-height:0;width:100%;height:100%;overflow:hidden;transition:transform .12s,background .2s}\n.ttt button:active{transform:scale(.95)}\n.ttt button.win{background:color-mix(in srgb,var(--a1) 26%,var(--panel))}\n.ttt svg{position:absolute;left:18%;top:18%;width:64%;height:64%;overflow:visible}\n.ttt .x line,.mk.x line{stroke:var(--a2);stroke-width:12;stroke-linecap:round}\n.ttt .o circle,.mk.o circle{stroke:#ff6f8e;stroke-width:12;fill:none}\n.mk.x line,.mk.o circle{stroke-width:14}\n.draw line,.draw circle{stroke-dasharray:140;stroke-dashoffset:140;animation:dr .35s ease forwards}\n.draw line+line{animation-delay:.15s}\n@keyframes dr{to{stroke-dashoffset:0}}\n/* шашки */\n.ck{display:grid;grid-template-columns:repeat(8,1fr);width:min(94vw,440px);aspect-ratio:1;border-radius:14px;overflow:hidden;box-shadow:0 10px 30px rgba(0,0,0,.25)}\n.ck div{position:relative;display:grid;place-items:center}\n.ck .l{background:#e9dcc3}.ck .d{background:#8a5a3b}\n.light .ck .l{background:#f1e6d0}.light .ck .d{background:#9b6a48}\n.ck .d.hl{background:#a7743f}.ck .d.last{box-shadow:inset 0 0 0 3px rgba(255,214,102,.55)}\n.ck .dot{position:absolute;width:30%;height:30%;border-radius:50%;background:rgba(124,92,255,.85);box-shadow:0 0 0 4px rgba(124,92,255,.25)}\n.pc{width:78%;height:78%;border-radius:50%;display:grid;place-items:center;transition:transform .15s;box-shadow:0 3px 0 rgba(0,0,0,.35),inset 0 -3px 6px rgba(0,0,0,.18),inset 0 3px 5px rgba(255,255,255,.35)}\n.pc.w{background:radial-gradient(circle at 35% 30%,#ffffff,#e4e1d6)}\n.pc.b{background:radial-gradient(circle at 35% 30%,#4b4b57,#17171d)}\n.pc.sel{transform:scale(1.1);box-shadow:0 0 0 3px var(--a1),0 6px 12px rgba(0,0,0,.35)}\n.pc.can{animation:pul 1.6s ease-in-out infinite}\n@keyframes pul{50%{box-shadow:0 0 0 3px rgba(124,92,255,.55),0 3px 0 rgba(0,0,0,.35)}}\n.pc svg{width:58%;height:58%}\n.pc.w svg{color:#b8892e}.pc.b svg{color:#f5c451}\n/* морской бой */\n.seaT{font-size:13px;font-weight:700;color:var(--muted);margin:6px 0;align-self:flex-start;width:min(92vw,400px);margin-left:auto;margin-right:auto}\n.sea{display:grid;grid-template-columns:repeat(10,1fr);gap:3px;width:min(92vw,400px);aspect-ratio:1}\n.sea.sm{width:min(60vw,250px);gap:2px}\n.sea div{border-radius:5px;background:var(--cell);position:relative;display:grid;place-items:center}\n.sea.big div.t{cursor:pointer}.sea.big div.t:hover{background:var(--cell2)}\n.sea div.sh{background:color-mix(in srgb,var(--a1) 55%,var(--cell))}\n.sea div.hit{background:#ff6f5b}.sea div.sunk{background:#b8344d}\n.sea div.miss::after{content:\"\";width:22%;height:22%;border-radius:50%;background:var(--muted);opacity:.7}\n.sea div.hit::after,.sea div.sunk::after{content:\"\";width:46%;height:46%;background:linear-gradient(45deg,transparent 42%,#fff 42%,#fff 58%,transparent 58%),linear-gradient(-45deg,transparent 42%,#fff 42%,#fff 58%,transparent 58%)}\n.sea div.new{animation:pop .4s ease}\n@keyframes pop{0%{transform:scale(.4)}60%{transform:scale(1.15)}100%{transform:none}}\n/* кнопки */\n.acts{display:flex;gap:10px;margin-top:14px}\n.btn{flex:1;height:52px;border:0;border-radius:16px;font:inherit;font-size:16px;font-weight:800;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;color:#fff;background:linear-gradient(135deg,var(--a1),var(--a2));transition:transform .12s,opacity .2s}\n.btn:active{transform:scale(.97)}.btn[disabled]{opacity:.5}\n.btn.ghost{background:var(--panel);color:var(--text)}.btn.red{background:var(--panel);color:var(--danger)}\n.btn svg{width:20px;height:20px}\n.res{margin-top:14px;padding:16px;border-radius:18px;text-align:center;background:var(--panel);animation:pop .45s ease}\n.res b{display:block;font-size:22px}.res span{display:block;margin-top:4px;color:var(--muted);font-size:14px}\n.res.win{background:linear-gradient(135deg,color-mix(in srgb,var(--a1) 30%,var(--panel)),color-mix(in srgb,var(--a2) 22%,var(--panel)))}\n.err{position:fixed;left:50%;bottom:calc(env(safe-area-inset-bottom) + 24px);transform:translateX(-50%) translateY(20px);background:#1b1c30;color:#fff;padding:11px 16px;border-radius:14px;font-size:14px;opacity:0;transition:.25s;max-width:90vw;text-align:center;pointer-events:none;z-index:9}\n.err.on{opacity:1;transform:translateX(-50%)}\n.load{flex:1;display:grid;place-items:center;color:var(--muted)}\n.sp{width:28px;height:28px;border:3px solid var(--line);border-top-color:var(--a1);border-radius:50%;animation:sp .8s linear infinite}\n@keyframes sp{to{transform:rotate(360deg)}}\n.ask{position:fixed;inset:0;background:rgba(0,0,0,.45);display:flex;align-items:flex-end;justify-content:center;padding:16px;opacity:0;transition:opacity .25s;z-index:8}\n.ask.on{opacity:1}.askb{width:100%;max-width:420px;background:var(--panel);border-radius:22px;padding:18px;transform:translateY(30px);transition:transform .3s cubic-bezier(.2,.9,.3,1);margin-bottom:env(safe-area-inset-bottom)}\n.ask.on .askb{transform:none}.askb b{display:block;font-size:18px}.askb span{display:block;color:var(--muted);margin-top:4px;font-size:14px}\n.hint{text-align:center;color:var(--muted);font-size:13px;margin-top:8px}\n</style></head>\n<body><div id=\"app\"><div class=\"load\"><div class=\"sp\"></div></div></div><div class=\"err\" id=\"err\"></div>\n<script>\n/*CFG*/\n(function(){\nvar C=window.LUMO_GAME||{}; if(C.theme==='light') document.documentElement.classList.add('light');\nvar G=null, busy=false, sel=null, partial=[], lastVer=-1, timer=null, prevShots=0;\nvar $=function(q){return document.querySelector(q)};\nvar TITLES={ttt:'Крестики-нолики',checkers:'Шашки',sea:'Морской бой'};\nvar I={x:'<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2.4\" stroke-linecap=\"round\"><path d=\"M6 6l12 12M18 6 6 18\"/></svg>',\n gem:'<svg viewBox=\"0 0 24 24\" fill=\"currentColor\"><path d=\"M6.5 3h11l4 6-9.5 12L2.5 9z\" opacity=\".9\"/><path d=\"M2.5 9h19M9 3l3 6 3-6M12 9v12\" stroke=\"#fff\" stroke-opacity=\".35\" stroke-width=\"1\" fill=\"none\"/></svg>',\n crown:'<svg viewBox=\"0 0 24 24\" fill=\"currentColor\"><path d=\"M3 7l4.5 4L12 4l4.5 7L21 7l-2 12H5z\"/></svg>',\n flag:'<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 21V4M5 4h11l-2 4 2 4H5\"/></svg>',\n shuffle:'<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M16 3h5v5M4 20 21 3M21 16v5h-5M15 15l6 6M4 4l5 5\"/></svg>',\n check:'<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2.6\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 12.5l4.5 4.5L19 7\"/></svg>',\n play:'<svg viewBox=\"0 0 24 24\" fill=\"currentColor\"><path d=\"M7 4.5v15l13-7.5z\"/></svg>'};\nfunction esc(s){return String(s==null?'':s).replace(/[&<>\"]/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]})}\nfunction toast(t){var e=$('#err');e.textContent=t;e.classList.add('on');clearTimeout(e._t);e._t=setTimeout(function(){e.classList.remove('on')},2600)}\nfunction ask(t,sub,yes,fn){ var o=document.createElement('div'); o.className='ask'; o.innerHTML='<div class=\"askb\"><b>'+esc(t)+'</b><span>'+esc(sub)+'</span><div class=\"acts\"><button class=\"btn ghost\" data-n>Отмена</button><button class=\"btn\" style=\"background:var(--danger)\" data-y>'+esc(yes)+'</button></div></div>';\n  document.body.appendChild(o); requestAnimationFrame(function(){o.classList.add('on')});\n  var done=function(){ o.classList.remove('on'); setTimeout(function(){o.remove()},250); };\n  o.onclick=function(e){ if(e.target===o||e.target.hasAttribute('data-n')) done(); if(e.target.hasAttribute('data-y')){ done(); fn(); } }; }\nfunction close(){ try{ if(window.webkit&&webkit.messageHandlers&&webkit.messageHandlers.lumo) return webkit.messageHandlers.lumo.postMessage('close'); }catch(e){}\n  try{ if(window.LumoBridge) return LumoBridge.leave(); }catch(e){} try{ parent.postMessage({lumoGame:'close'},'*'); }catch(e){} }\nfunction lum(n){var m=n%10,mm=n%100;return n+' '+(m===1&&mm!==11?'люмен':m>=2&&m<=4&&(mm<10||mm>=20)?'люмена':'люменов')}\nfunction api(body){ return fetch(C.api,{method:'POST',headers:{'Content-Type':'application/json',apikey:C.apikey||'',Authorization:'Bearer '+C.token},body:JSON.stringify(body)})\n  .then(function(r){ return r.json().then(function(j){ if(r.status===401) throw new Error('Сессия устарела — закройте и откройте игру заново'); if(j.error) throw new Error(j.error); return j; }); }); }\nfunction act(body){ if(busy) return; busy=true; body.game_id=C.gameId; return api(body).then(function(g){ busy=false; set(g); }).catch(function(e){ busy=false; toast(e.message); poll(); }); }\nfunction set(g){ G=g; lastVer=g.ver; render(); }\nfunction poll(){ if(document.hidden||busy) return; api({action:'get',game_id:C.gameId}).then(function(g){ if(g.ver!==lastVer||!G) set(g); }).catch(function(e){ if(!G) $('#app').innerHTML='<div class=\"load\">'+esc(e.message)+'</div>'; }); }\nfunction startPoll(){ clearInterval(timer); timer=setInterval(poll,1500); }\ndocument.addEventListener('visibilitychange',function(){ if(!document.hidden) poll(); });\nwindow.lumoToken=function(t){ C.token=t; };\n\nfunction me(){return G.me} function iAmP1(){return G.me===G.p1} function player(){return G.me===G.p1||G.me===G.p2}\nfunction oppName(){return iAmP1()?G.p2n:G.p1n}\nfunction statusText(){\n  var g=G;\n  if(g.status==='invite') return g.me===g.p1?'Ждём соперника…':'Вас приглашают сыграть';\n  if(g.status==='declined') return 'Приглашение отклонено';\n  if(g.status==='canceled') return 'Игра отменена';\n  if(g.status==='setup') return (g.state.ready||{})[g.me]?'Ждём, пока соперник расставит корабли':player()?'Расставьте корабли':'Игроки расставляют корабли';\n  if(g.status==='done') return '';\n  if(!player()) return 'Ходит '+(g.turn===g.p1?g.p1n:g.p2n);\n  return g.turn===g.me?'Ваш ход':'Ход соперника';\n}\nfunction mark(kind,isP1){ if(kind==='ttt') return isP1?'<svg class=\"mk x\" viewBox=\"0 0 100 100\"><line x1=\"20\" y1=\"20\" x2=\"80\" y2=\"80\"/><line x1=\"80\" y1=\"20\" x2=\"20\" y2=\"80\"/></svg>':'<svg class=\"mk o\" viewBox=\"0 0 100 100\"><circle cx=\"50\" cy=\"50\" r=\"32\"/></svg>';\n  if(kind==='checkers') return '<span class=\"pc '+(isP1?'w':'b')+'\" style=\"width:22px;height:22px;flex:none\"></span>'; return ''; }\nfunction head(){\n  var g=G, t1=g.status==='active'&&g.turn===g.p1, t2=g.status==='active'&&g.turn===g.p2;\n  var p=function(id,nm,on,cls,isP1){ return '<div class=\"pl '+cls+(on?' on':'')+'\"><div class=\"av'+(isP1?'':' o')+'\">'+esc((nm||'?').charAt(0).toUpperCase())+'</div><div style=\"min-width:0;flex:1\"><b>'+esc(nm||'Ожидание…')+'</b><span>'+(id===g.me?'Вы':g.status==='done'&&g.winner===id?'Победитель':isP1?'Создал игру':'Соперник')+'</span></div>'+mark(g.kind,isP1)+'</div>'; };\n  return '<div class=\"top\"><button class=\"ib\" id=\"gX\" title=\"Закрыть\">'+I.x+'</button><h1>'+TITLES[g.kind]+'</h1>'+(g.stake?'<span class=\"chip\" title=\"Ставка каждого игрока\">'+I.gem+g.stake+'</span>':'<span style=\"width:40px\"></span>')+'</div>'+\n   '<div class=\"players\">'+p(g.p1,g.p1n,t1,'',true)+'<span class=\"vs\">VS</span>'+p(g.p2,g.p2n,t2,'r',false)+'</div>'+\n   '<div class=\"status'+(g.status==='active'&&g.turn===g.me?' me':'')+'\">'+esc(statusText())+'</div>';\n}\nfunction result(){\n  var g=G; if(g.status!=='done') return '';\n  var bank=g.stake*2, win=g.winner===g.me, why={resign:' — соперник сдался',timeout:' — соперник не ходил больше суток',no_moves:'',fleet:'',line:''}[g.result]||'';\n  if(!g.winner) return '<div class=\"res\"><b>Ничья</b><span>'+(g.stake?'Ставки вернулись игрокам':'Хорошая партия')+'</span></div>';\n  if(!player()) return '<div class=\"res\"><b>Победил(а) '+esc(g.winner===g.p1?g.p1n:g.p2n)+'</b>'+(g.stake?'<span>Выигрыш: '+lum(bank)+'</span>':'')+'</div>';\n  if(win) return '<div class=\"res win\"><b>Вы победили'+(g.result==='resign'?'':'!')+'</b><span>'+(g.stake?'Выигрыш: +'+lum(bank):'Отличная игра')+esc(g.result==='resign'||g.result==='timeout'?why:'')+'</span></div>';\n  return '<div class=\"res\"><b>Победил(а) '+esc(oppName())+'</b><span>'+(g.stake?'Ставка ушла сопернику':'В следующий раз получится')+'</span></div>';\n}\nfunction actions(){\n  var g=G, h='';\n  if(g.status==='invite'){\n    if(g.me===g.p1) h='<button class=\"btn red\" data-a=\"cancel\">Отменить'+(g.stake?' и вернуть ставку':'')+'</button>';\n    else h='<button class=\"btn ghost\" data-a=\"decline\">Отклонить</button><button class=\"btn\" data-a=\"join\">'+I.play+(g.stake?'Принять · '+g.stake:'Принять')+'</button>';\n  } else if(g.status==='setup'&&player()&&!(g.state.ready||{})[g.me]){\n    h='<button class=\"btn ghost\" data-a=\"shuffle\">'+I.shuffle+'Перемешать</button><button class=\"btn\" data-a=\"ready\">'+I.check+'Готов</button>';\n  } else if((g.status==='active'||g.status==='setup')&&player()){\n    var stale=g.status==='active'&&g.turn!==g.me&&Date.now()-new Date(g.updated_at).getTime()>864e5;\n    h=(stale?'<button class=\"btn\" data-a=\"claim\">Забрать победу</button>':'')+'<button class=\"btn red\" data-a=\"resign\">'+I.flag+'Сдаться</button>';\n  } else if(g.status!=='active') h='<button class=\"btn ghost\" id=\"gDone\">Закрыть</button>';\n  return h?'<div class=\"acts\">'+h+'</div>':'';\n}\nfunction render(){\n  var g=G, body='';\n  if(g.kind==='ttt') body=renderTTT(); else if(g.kind==='checkers') body=renderCk(); else body=renderSea();\n  var stakeHint=g.status==='invite'&&g.stake?'<div class=\"hint\">Каждый игрок ставит '+lum(g.stake)+'. Победитель забирает '+lum(g.stake*2)+', при ничьей ставки возвращаются.</div>':'';\n  $('#app').innerHTML=head()+'<div class=\"board-wrap\">'+body+'</div>'+result()+stakeHint+actions();\n  $('#gX').onclick=close; var d=$('#gDone'); if(d) d.onclick=close;\n  [].forEach.call(document.querySelectorAll('[data-a]'),function(b){ b.onclick=function(){ var a=b.dataset.a;\n    if(a==='resign') return ask('Сдаться?',G.stake?'Ставка уйдёт сопернику.':'Победа достанется сопернику.','Сдаться',function(){ act({action:'resign'}); });\n    act({action:a}); }; });\n  bind();\n}\n/* ---- крестики-нолики ---- */\nvar tttLast='';\nfunction renderTTT(){\n  var b=G.state.board, w=null, L=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];\n  L.forEach(function(l){ if(b[l[0]]!=='.'&&b[l[0]]===b[l[1]]&&b[l[0]]===b[l[2]]) w=l; });\n  var h='<div class=\"ttt\">';\n  for(var i=0;i<9;i++){ var c=b[i], fresh=c!=='.'&&tttLast&&tttLast[i]==='.';\n    h+='<button data-i=\"'+i+'\" class=\"'+(w&&w.indexOf(i)>=0?'win':'')+'\">'+(c==='x'?'<svg class=\"x'+(fresh?' draw':'')+'\" viewBox=\"0 0 100 100\"><line x1=\"18\" y1=\"18\" x2=\"82\" y2=\"82\"/><line x1=\"82\" y1=\"18\" x2=\"18\" y2=\"82\"/></svg>':c==='o'?'<svg class=\"o'+(fresh?' draw':'')+'\" viewBox=\"0 0 100 100\"><circle cx=\"50\" cy=\"50\" r=\"33\"/></svg>':'')+'</button>'; }\n  tttLast=b; return h+'</div>';\n}\n/* ---- шашки ---- */\nfunction flip(){ return G.me===G.p2; }\nfunction renderCk(){\n  var b=G.state.board, myTurn=G.status==='active'&&G.turn===G.me, moves=myTurn?(G.moves||[]):[], last=G.state.last||[];\n  var cand=moves.filter(function(m){ for(var k=0;k<partial.length;k++){ if(!m[k]||m[k][0]!==partial[k][0]||m[k][1]!==partial[k][1]) return false; } return true; });\n  var dots={}, can={};\n  if(partial.length) cand.forEach(function(m){ var n=m[partial.length]; if(n) dots[n[0]*8+n[1]]=1; });\n  moves.forEach(function(m){ can[m[0][0]*8+m[0][1]]=1; });\n  var lastSet={}; last.forEach(function(s){ lastSet[s[0]*8+s[1]]=1; });\n  var h='<div class=\"ck\">';\n  for(var rr=0;rr<8;rr++) for(var cc=0;cc<8;cc++){\n    var r=flip()?7-rr:rr, c=flip()?7-cc:cc, i=r*8+c, dark=(r+c)%2===1, p=b[i];\n    var selHere=partial.length&&partial[0][0]===r&&partial[0][1]===c;\n    var cur=partial.length&&partial[partial.length-1][0]===r&&partial[partial.length-1][1]===c;\n    h+='<div class=\"'+(dark?'d':'l')+(cur&&partial.length>1?' hl':'')+(lastSet[i]?' last':'')+'\" data-r=\"'+r+'\" data-c=\"'+c+'\">';\n    if(p!=='.') h+='<span class=\"pc '+p.toLowerCase()+(selHere?' sel':'')+(!partial.length&&can[i]?' can':'')+'\">'+(p===p.toUpperCase()?I.crown:'')+'</span>';\n    if(dots[i]) h+='<span class=\"dot\"></span>';\n    h+='</div>';\n  }\n  h+='</div>';\n  if(myTurn&&moves.length&&moves.some(function(m){return m.length>2||Math.abs(m[1][0]-m[0][0])>1&&b[m[0][0]*8+m[0][1]]===b[m[0][0]*8+m[0][1]].toLowerCase()})) h+='<div class=\"hint\">Взятие обязательно</div>';\n  return h;\n}\nfunction ckTap(r,c){\n  var moves=G.moves||[]; if(G.status!=='active'||G.turn!==G.me) return;\n  var starts=moves.filter(function(m){return m[0][0]===r&&m[0][1]===c});\n  if(starts.length&&(!partial.length||partial.length===1)){ partial=[[r,c]]; return render(); }\n  if(!partial.length) return;\n  var next=partial.concat([[r,c]]);\n  var cand=moves.filter(function(m){ if(m.length<next.length) return false; for(var k=0;k<next.length;k++) if(m[k][0]!==next[k][0]||m[k][1]!==next[k][1]) return false; return true; });\n  if(!cand.length){ partial=[]; return render(); }\n  var exact=cand.filter(function(m){return m.length===next.length});\n  if(exact.length&&cand.length===exact.length){ partial=[]; return act({action:'move',path:next}); }\n  partial=next; render();\n}\n/* ---- морской бой ---- */\nfunction seaGrid(cls,cells,clickable){ var h='<div class=\"sea '+cls+'\">'; for(var y=0;y<10;y++) for(var x=0;x<10;x++){ var k=cells[x*10+y]||''; h+='<div class=\"'+k+(clickable&&!k?' t':'')+'\" data-x=\"'+x+'\" data-y=\"'+y+'\"></div>'; } return h+'</div>'; }\nfunction renderSea(){\n  var g=G, mineShips=g.myShips||[], shots=g.state.shots||{}, opp=g.me===g.p1?g.p2:g.p1;\n  var own={}, enemy={};\n  mineShips.forEach(function(s){ s.forEach(function(c){ own[c[0]*10+c[1]]='sh'; }); });\n  (shots[opp]||[]).forEach(function(s){ var k=s.x*10+s.y; own[k]=s.s?'sunk':s.h?'hit':(own[k]?own[k]:'miss'); });\n  var mineShots=shots[g.me]||[], last=g.state.last;\n  mineShots.forEach(function(s){ enemy[s.x*10+s.y]=s.s?'sunk':s.h?'hit':'miss'; });\n  if(g.oppShips) g.oppShips.forEach(function(s){ s.forEach(function(c){ var k=c[0]*10+c[1]; if(!enemy[k]) enemy[k]='sh'; }); });\n  if(last&&last.by===g.me&&enemy[last.x*10+last.y]) enemy[last.x*10+last.y]+=' new';\n  if(last&&last.by!==g.me&&own[last.x*10+last.y]) own[last.x*10+last.y]+=' new';\n  if(!player()) return '<div class=\"hint\">Морской бой идёт между '+esc(g.p1n)+' и '+esc(g.p2n||'…')+'</div>';\n  if(g.status==='setup'||g.status==='invite') return '<div class=\"seaT\">Ваш флот'+(g.status==='setup'&&!mineShips.length?' — нажмите «Перемешать»':'')+'</div>'+seaGrid('',own,false);\n  var info='';\n  if(last){ var whoMe=last.by===g.me; info='<div class=\"hint\">'+(whoMe?(last.sunk?'Корабль потоплен! Стреляйте ещё':last.h?'Попадание! Стреляйте ещё':'Мимо'):(last.sunk?'Соперник потопил ваш корабль':last.h?'Соперник попал':'Соперник промахнулся'))+'</div>'; }\n  return '<div class=\"seaT\">Поле соперника</div>'+seaGrid('big',enemy,g.status==='active'&&g.turn===g.me)+info+'<div class=\"seaT\" style=\"margin-top:12px\">Ваш флот</div>'+seaGrid('sm',own,false);\n}\nfunction bind(){\n  if(G.kind==='ttt') [].forEach.call(document.querySelectorAll('.ttt button'),function(b){ b.onclick=function(){ if(G.status!=='active') return; if(G.turn!==G.me) return toast(player()?'Сейчас ход соперника':'Вы не участвуете в игре'); if(G.state.board[+b.dataset.i]!=='.') return; act({action:'move',i:+b.dataset.i}); }; });\n  if(G.kind==='checkers') [].forEach.call(document.querySelectorAll('.ck div'),function(d){ d.onclick=function(){ ckTap(+d.dataset.r,+d.dataset.c); }; });\n  if(G.kind==='sea') [].forEach.call(document.querySelectorAll('.sea.big div.t'),function(d){ d.onclick=function(){ if(G.turn!==G.me) return toast('Сейчас ход соперника'); act({action:'move',x:+d.dataset.x,y:+d.dataset.y}); }; });\n}\nif(!C.gameId){ $('#app').innerHTML='<div class=\"load\">Игра не найдена</div>'; return; }\npoll(); startPoll();\nwindow.lumoGameTest=function(g){ clearInterval(timer); set(g); };\n})();\n<\/script>\n</body></html>\n";
const LG_TITLES={chess:'Шахматы',ttt:'Крестики-нолики',checkers:'Шашки',sea:'Морской бой'};
const LG_THROWS=[['dice','Кубик'],['darts','Дартс'],['basket','Баскетбол'],['football','Футбол'],['coin','Монетка']];
(function(){ const st=document.createElement('style'); st.textContent=`
.lgsh{display:grid;grid-template-columns:repeat(5,1fr);gap:8px;margin:6px 0 4px}
.lgsh button{border:0;background:var(--panel2);border-radius:16px;padding:12px 4px 9px;color:var(--text);font:inherit;font-size:12px;font-weight:700;display:flex;flex-direction:column;align-items:center;gap:6px;cursor:pointer;transition:transform .12s,background .2s}
.lgsh button:hover{background:var(--active)}.lgsh button:active{transform:scale(.94)}
.lgsh svg{width:38px;height:38px}
.lghd{font-size:12px;font-weight:800;letter-spacing:.4px;color:var(--muted);margin:14px 2px 8px}
.lgg{display:flex;flex-direction:column;gap:8px}
.lgg button{display:flex;align-items:center;gap:12px;border:2px solid transparent;background:var(--panel2);border-radius:16px;padding:10px 12px;color:var(--text);font:inherit;text-align:left;cursor:pointer;transition:border-color .2s}
.lgg button.on{border-color:var(--a1)}
.lgg button i{width:44px;height:44px;border-radius:13px;display:grid;place-items:center;flex:none}
.lgg button i svg{width:28px;height:28px}
.lgg button b{display:block;font-size:15px}.lgg button span{display:block;font-size:12.5px;color:var(--muted)}
.lgst{display:flex;gap:6px;flex-wrap:wrap;margin-top:4px}
.lgst button{border:0;border-radius:12px;padding:8px 12px;background:var(--panel2);color:var(--text);font:inherit;font-weight:700;font-size:13.5px;cursor:pointer;display:flex;align-items:center;gap:5px}
.lgst button.on{background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff}
.lgst button svg{width:14px;height:14px}
.lgst input{width:96px;border:0;border-radius:12px;padding:8px 10px;background:var(--panel2);color:var(--text);font:inherit;font-weight:700;font-size:13.5px;outline:0}
.lgnote{font-size:12.5px;color:var(--muted);margin-top:8px;line-height:1.4}
.b.lgdb{padding:8px 10px 6px;min-width:150px;text-align:center}
.lgd{width:132px;height:132px;margin:2px auto 0;display:block}
.lgd.anim{animation:lgRoll 1.1s cubic-bezier(.3,.6,.4,1)}
.lgd.anim.coin{animation:lgFlip 1.1s cubic-bezier(.3,.6,.4,1)}
@keyframes lgRoll{0%{transform:translateY(-30px) rotate(-200deg) scale(.6);opacity:.2}55%{transform:translateY(6px) rotate(20deg) scale(1.05);opacity:1}75%{transform:translateY(-6px) rotate(-6deg)}100%{transform:none}}
@keyframes lgFlip{0%{transform:translateY(-34px) rotateY(0) scale(.7)}60%{transform:translateY(4px) rotateY(1440deg) scale(1.05)}100%{transform:rotateY(1800deg)}}
.lgres{font-weight:800;font-size:15px;margin-top:2px}
.lgd.anim+.lgres{animation:lgIn .3s ease 1s both}
@keyframes lgIn{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:none}}
.b.lggb{min-width:240px;max-width:300px}
.lggh{display:flex;gap:11px;align-items:center}
.lggh i{width:46px;height:46px;border-radius:14px;display:grid;place-items:center;flex:none}
.lggh i svg{width:30px;height:30px}
.lggh b{display:block;font-size:15.5px}.lggh span{display:block;font-size:13px;opacity:.78}
.lggp{margin-top:8px;font-size:13.5px;display:flex;align-items:center;gap:6px;flex-wrap:wrap}
.lggp .vs{opacity:.6;font-size:12px;font-weight:800}
.lggst{display:inline-flex;align-items:center;gap:4px;font-weight:800;color:#f5b942}
.lggst svg{width:14px;height:14px}
.lggbtn{margin-top:10px;width:100%;height:40px;border:0;border-radius:12px;font:inherit;font-weight:800;font-size:14.5px;cursor:pointer;background:rgba(255,255,255,.18);color:inherit}
.m:not(.me) .lggbtn{background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff}
.m:not(.me) .lggbtn.ghost{background:var(--panel2);color:var(--text)}
#lgOv{position:fixed;inset:0;z-index:2147483000;background:var(--bg);transform:translateY(100%);transition:transform .38s cubic-bezier(.2,.9,.3,1)}
#lgOv.on{transform:none}
#lgOv iframe{width:100%;height:100%;border:0;display:block}
@media(min-width:900px){#lgOv{inset:auto;left:50%;top:50%;width:480px;height:min(860px,94vh);border-radius:26px;overflow:hidden;box-shadow:0 30px 80px rgba(0,0,0,.5);transform:translate(-50%,-40%) scale(.96);opacity:0;transition:transform .3s,opacity .3s}#lgOv.on{transform:translate(-50%,-50%);opacity:1}}
#lgBg{position:fixed;inset:0;z-index:2147482999;background:rgba(0,0,0,.45);opacity:0;transition:opacity .3s}#lgBg.on{opacity:1}
`; document.head.appendChild(st); })();

const LG_COL={chess:'linear-gradient(135deg,#4a4f5c,#16181d)',ttt:'linear-gradient(135deg,#22c1ff,#3a7bff)',checkers:'linear-gradient(135deg,#a7743f,#6b4426)',sea:'linear-gradient(135deg,#2bb3ff,#1460c8)'};
function lgIcon(k){
  if(k==='chess') return '<svg viewBox="0 0 24 24"><path fill="#fff" d="M7 20c0-4 1.5-6 4-8-1.6 0-3 .8-4 2l-2-1.6c-.5-.7-.5-1.5 0-2.2 1.8-2.8 4.3-5 7.3-5.8L13 3l1.2 2.3c2.8 1.6 4.5 4.8 4.5 9 0 2-.3 3.6-.8 5.7z"/><rect x="5" y="20.3" width="14" height="1.8" rx="0.9" fill="#fff"/></svg>';
  if(k==='ttt') return '<svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round"><path d="M4 4l6 6M10 4 4 10"/><circle cx="17" cy="17" r="3.4"/><path d="M8.5 13v7M15.5 4v7M13 8.5h7M4 15.5h7" opacity=".45" stroke-width="1.6"/></svg>';
  if(k==='checkers') return '<svg viewBox="0 0 24 24"><ellipse cx="12" cy="15.5" rx="8" ry="3.4" fill="#2a1a10"/><rect x="4" y="10" width="16" height="5.5" fill="#2a1a10"/><ellipse cx="12" cy="10" rx="8" ry="3.4" fill="#f4ead6"/><ellipse cx="12" cy="10" rx="4.6" ry="1.9" fill="none" stroke="#c9a46a" stroke-width="1.2"/></svg>';
  return '<svg viewBox="0 0 24 24" fill="#fff"><path d="M3 15h18l-2.6 4.2a2 2 0 0 1-1.7.8H7.3a2 2 0 0 1-1.7-.8z"/><path d="M11 3.5v10H5.5z" opacity=".9"/><path d="M12.5 6v7.5H18z" opacity=".65"/></svg>'; }
function lgThrowSvg(k,v){
  if(k==='dice'){ const P_={1:[[50,50]],2:[[30,30],[70,70]],3:[[28,28],[50,50],[72,72]],4:[[30,30],[70,30],[30,70],[70,70]],5:[[28,28],[72,28],[50,50],[28,72],[72,72]],6:[[30,26],[70,26],[30,50],[70,50],[30,74],[70,74]]}[v]||[];
    return `<svg viewBox="0 0 100 100"><defs><linearGradient id="lgdg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#dcd8f4"/></linearGradient></defs><rect x="10" y="10" width="80" height="80" rx="20" fill="url(#lgdg)" stroke="rgba(0,0,0,.12)" stroke-width="2"/>${P_.map(p=>`<circle cx="${p[0]}" cy="${p[1]}" r="8" fill="${v===1?'#e0284f':'#25264a'}"/>`).join('')}</svg>`; }
  if(k==='darts'){ const R_={6:[50,50],5:[56,42],4:[38,58],3:[66,64],2:[30,34],1:[88,14]}[v]||[50,50];
    return `<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="42" fill="#25264a"/><circle cx="50" cy="50" r="34" fill="#f2efe4"/><circle cx="50" cy="50" r="26" fill="#e0284f"/><circle cx="50" cy="50" r="18" fill="#f2efe4"/><circle cx="50" cy="50" r="10" fill="#2bb673"/><circle cx="50" cy="50" r="4" fill="#e0284f"/>
      <g transform="translate(${R_[0]} ${R_[1]}) rotate(-35)"><rect x="-1.6" y="-26" width="3.2" height="24" rx="1.4" fill="#5a5d86"/><path d="M0-30l-7-8h14z" fill="#7c5cff"/><path d="M-1.6-2h3.2L0 3z" fill="#ccc"/></g></svg>`; }
  if(k==='basket'){ const ok=v>=4;
    return `<svg viewBox="0 0 100 100"><rect x="18" y="8" width="64" height="40" rx="5" fill="#f2efe4" stroke="#c7c3b5" stroke-width="2"/><rect x="38" y="22" width="24" height="16" fill="none" stroke="#e0284f" stroke-width="2.5"/>
      <path d="M32 44h36l-6 22H38z" fill="none" stroke="#fff" stroke-width="2" stroke-dasharray="3 3"/><rect x="30" y="41" width="40" height="5" rx="2.5" fill="#ff6a2b"/>
      <g transform="translate(${ok?50:74} ${ok?62:76})"><circle r="13" fill="#ff8a3d"/><path d="M-13 0h26M0-13v26M-9-9q9 9 0 18M9-9q-9 9 0 18" stroke="#7a2e0a" stroke-width="1.6" fill="none"/></g></svg>`; }
  if(k==='football'){ const ok=v>=3;
    return `<svg viewBox="0 0 100 100"><path d="M10 70V24h80v46" fill="none" stroke="#f2efe4" stroke-width="4"/><path d="M14 28h72v40H14z" fill="none" stroke="rgba(255,255,255,.35)" stroke-width="1" stroke-dasharray="4 4"/><rect x="0" y="80" width="100" height="20" fill="#2bb673" opacity=".7"/>
      <g transform="translate(${ok?40:88} ${ok?48:22})"><circle r="12" fill="#fff" stroke="#222" stroke-width="1.5"/><path d="M0-5l5 3.6-2 6h-6l-2-6z" fill="#222"/></g></svg>`; }
  return `<svg viewBox="0 0 100 100"><defs><radialGradient id="lgcg" cx=".35" cy=".3"><stop offset="0" stop-color="#ffe7a1"/><stop offset="1" stop-color="#d79b22"/></radialGradient></defs><circle cx="50" cy="50" r="40" fill="url(#lgcg)" stroke="#b07a12" stroke-width="3"/><circle cx="50" cy="50" r="31" fill="none" stroke="#b07a12" stroke-width="1.5" stroke-dasharray="2 3"/>
    <text x="50" y="62" text-anchor="middle" font-size="34" font-weight="800" fill="#8a5c08" font-family="Georgia,serif">${v===1?'О':'Р'}</text></svg>`; }
function lgThrowLabel(k,v){
  if(k==='dice') return 'Выпало '+v;
  if(k==='darts') return v===6?'В яблочко!':v===1?'Мимо':'Очков: '+v;
  if(k==='basket') return v>=4?'Попал!':'Мимо';
  if(k==='football') return v>=3?'Гол!':'Мимо';
  return v===1?'Орёл':'Решка'; }
const lgSeen=new Set();
const lgHm=d=>String(d.getHours()).padStart(2,'0')+':'+String(d.getMinutes()).padStart(2,'0');
function lgWrap(m,inner,cls){ const mine=m.sender_id===S.me.id; const c=cur()||{};
  const nm=c.type==='group'&&!mine?`<div style="font-weight:700;font-size:13px;color:var(--a2);margin-bottom:4px;text-align:left">${esc(profName(m.sender_id))}</div>`:'';
  return `<div class="m ${mine?'me':''} tail grp first" data-id="${m.id}"><div class="b ${cls}">${nm}${inner}<div class="tm">${lgHm(new Date(m.created_at))}</div>${reactsHtml(m)}</div></div>`; }
function lgDiceHtml(m){ const mt=m.meta||{}, k=mt.g||'dice', v=+mt.v||1;
  const fresh=!lgSeen.has(m.id)&&Date.now()-new Date(m.created_at).getTime()<6000; lgSeen.add(m.id);
  return lgWrap(m,`<canvas class="lgd lgcv" data-k="${k}" data-v="${v}" data-id="${m.id}"${fresh?' data-fresh="1"':''}></canvas><div class="lgres">${esc(lgThrowLabel(k,v))}</div>`,'lgdb'); }
function lgGameStatus(mt,me){
  const st=mt.st||'invite';
  if(st==='invite') return mt.p1===me?'Ждём соперника':'Приглашение сыграть';
  if(st==='setup') return 'Расстановка кораблей';
  if(st==='active') return 'Идёт игра';
  if(st==='declined') return 'Приглашение отклонено';
  if(st==='canceled') return 'Игра отменена';
  return mt.winner?(mt.winner===me?'Вы победили':'Победил(а) '+(mt.wn||'')):'Ничья'; }
function lgGameHtml(m){ const mt=m.meta||{}, me=S.me.id, k=mt.g||'ttt', st=mt.st||'invite';
  const players=mt.p2?`<b>${esc(mt.p1n||'')}</b><span class="vs">VS</span><b>${esc(mt.p2n||'')}</b>`:`<b>${esc(mt.p1n||profName(m.sender_id))}</b><span class="vs">VS</span><span style="opacity:.7">ждём соперника</span>`;
  const btn=st==='invite'&&mt.p1!==me&&m.sender_id!==me?'Принять':st==='invite'?'Открыть':st==='active'||st==='setup'?((mt.p1===me||mt.p2===me)?'Играть':'Смотреть'):'Посмотреть';
  return lgWrap(m,`<div class="lggh"><i style="background:${LG_COL[k]}">${lgIcon(k)}</i><div><b>${LG_TITLES[k]||'Игра'}</b><span>${esc(lgGameStatus(mt,me))}</span></div></div>
<div class="lggp">${players}${mt.stake?`<span style="flex:1"></span><span class="lggst">${ic('gem')}${mt.stake}</span>`:''}</div>
<button class="lggbtn${btn==='Посмотреть'?' ghost':''}" data-lgopen="${esc(mt.game||'')}">${btn}</button>`,'lggb'); }
{ const _lf=window.lfMsg; window.lfMsg=m=>{ if(m&&!m.deleted){ if(m.kind==='dice') return lgDiceHtml(m); if(m.kind==='game') return lgGameHtml(m); } return _lf?_lf(m):null; }; }

function lgDark(){ const c=getComputedStyle(document.body).backgroundColor.match(/\d+/g)||[0,0,0]; return (+c[0]*.3+ +c[1]*.59+ +c[2]*.11)<128; }
async function lgOpen(gameId){ if(!gameId) return; const {data:{session}}=await sb.auth.getSession(); if(!session) return toast('Войдите заново');
  document.getElementById('lgOv')?.remove(); document.getElementById('lgBg')?.remove();
  const cfg={api:SUPABASE_URL+'/functions/v1/lumo-games',apikey:SUPABASE_KEY,token:session.access_token,gameId,theme:lgDark()?'dark':'light',mini:true};
  const bg=document.createElement('div'); bg.id='lgBg'; const o=document.createElement('div'); o.id='lgOv';
  const fr=document.createElement('iframe'); fr.srcdoc=(window.__lgHtml||LG_GAMES_HTML).replace('/*CFG*/','window.LUMO_GAME='+JSON.stringify(cfg)+';'); o.appendChild(fr);
  document.body.appendChild(bg); document.body.appendChild(o); requestAnimationFrame(()=>requestAnimationFrame(()=>{ o.classList.add('on'); bg.classList.add('on'); }));
  bg.onclick=lgClose; }
function lgClose(){ const o=document.getElementById('lgOv'), bg=document.getElementById('lgBg'); if(!o) return; o.classList.remove('on'); bg&&bg.classList.remove('on'); setTimeout(()=>{ o.remove(); bg&&bg.remove(); },400); }
addEventListener('message',e=>{ if(e.data&&e.data.lumoGame==='close') lgClose(); });
addEventListener('keydown',e=>{ if(e.key==='Escape'&&document.getElementById('lgOv')) lgClose(); });
document.addEventListener('click',e=>{ const b=e.target.closest&&e.target.closest('[data-lgopen]'); if(!b) return; e.stopPropagation(); e.preventDefault(); lgOpen(b.dataset.lgopen); },true);

async function lgCall(body){ const {data:{session}}=await sb.auth.getSession();
  const r=await fetch(SUPABASE_URL+'/functions/v1/lumo-games',{method:'POST',headers:{'Content-Type':'application/json',apikey:SUPABASE_KEY,Authorization:'Bearer '+(session&&session.access_token)},body:JSON.stringify(body)});
  const j=await r.json().catch(()=>({error:'Ошибка сети'})); if(j.error) throw new Error(j.error); return j; }
window.lmGames=()=>{ const c=cur(); if(!c) return; const chatId=c.chat_id;
  if(c.type==='channel') return toast('Игры доступны в личных чатах и группах');
  let game='ttt', stake=0, clk=[0,0];
  const desc={chess:'Классические шахматы по всем правилам',ttt:'Три в ряд на поле 3×3',checkers:'Русские шашки, взятие обязательно',sea:'Флот 10 кораблей, поле 10×10'};
  const close=modal('Игры',`<div class="lghd">БРОСИТЬ В ЧАТ</div><div class="lgsh">${LG_THROWS.map(t=>`<button data-th="${t[0]}">${lgThrowSvg(t[0],t[0]==='dice'?5:t[0]==='coin'?1:t[0]==='darts'?6:5)}${t[1]}</button>`).join('')}</div>
<div class="lghd">ИГРАТЬ ВДВОЁМ</div><div class="lgg">${Object.keys(LG_TITLES).map(k=>`<button data-gk="${k}" class="${k===game?'on':''}"><i style="background:${LG_COL[k]}">${lgIcon(k)}</i><div><b>${LG_TITLES[k]}</b><span>${desc[k]}</span></div></button>`).join('')}</div>
<div id="lgClkW" style="display:none"><div class="lghd">ТАЙМЕР</div><div class="lgst">${[[0,0,'Без таймера'],[1,0,'1 мин'],[3,2,'3 + 2'],[5,0,'5 мин'],[10,0,'10 мин'],[15,10,'15 + 10'],[30,0,'30 мин']].map(c=>`<button data-ck="${c[0]}_${c[1]}" class="${c[0]?'':'on'}">${c[2]}</button>`).join('')}</div><div class="lgnote" id="lgClkN">Без ограничения времени: соперник может думать над ходом до суток.</div></div>
<div class="lghd">СТАВКА ЛЮМЕНАМИ</div><div class="lgst">${[0,10,50,100,500].map(v=>`<button data-sk="${v}" class="${v===stake?'on':''}">${v?ic('gem')+v:'Без ставки'}</button>`).join('')}<input id="lgSk" type="number" min="0" max="1000" placeholder="Своя"></div>
<div class="lgnote">Ставку вносят оба игрока, победитель забирает обе. При ничьей ставки возвращаются. Если соперник не примет приглашение, ставку можно вернуть отменой. Максимум — 1000 люменов.</div>`,
   [['Отмена','ghost'],['Пригласить','primary',async cl=>{ const btn=document.querySelector('.ov .modal .btn.primary'); if(btn) btn.disabled=true;
      try{ const g=await lgCall({action:'new',chat_id:chatId,kind:game,stake,...(clk[0]&&(game==='chess'||game==='checkers')?{clock_min:clk[0],clock_inc:clk[1]}:{})}); cl(); toast('Приглашение отправлено'); lgOpen(g.id); }catch(err){ toast(err.message); if(btn) btn.disabled=false; } }]]);
  const ov=[...document.querySelectorAll('.ov')].pop(); if(!ov) return;
  ov.querySelectorAll('[data-th]').forEach(b=>b.onclick=async()=>{ close(); const {error}=await sb.rpc('lm_throw',{p_chat:chatId,p_kind:b.dataset.th}); if(error) toast(error.message); });
  ov.querySelectorAll('[data-gk]').forEach(b=>b.onclick=()=>{ game=b.dataset.gk; ov.querySelectorAll('[data-gk]').forEach(x=>x.classList.toggle('on',x===b)); const w=ov.querySelector('#lgClkW'); if(w) w.style.display=(game==='chess'||game==='checkers')?'':'none'; });
  ov.querySelectorAll('[data-ck]').forEach(b=>b.onclick=()=>{ clk=b.dataset.ck.split('_').map(Number); ov.querySelectorAll('[data-ck]').forEach(x=>x.classList.toggle('on',x===b));
    ov.querySelector('#lgClkN').textContent=clk[0]?`У каждого ${clk[0]} мин на партию${clk[1]?` и +${clk[1]} сек за ход`:''}. Время вышло — поражение. Если соперник выйдет из игры, часы остановятся, а через 30 секунд победа достанется вам.`:'Без ограничения времени: соперник может думать над ходом до суток.'; });
  const inp=ov.querySelector('#lgSk');
  ov.querySelectorAll('[data-sk]').forEach(b=>b.onclick=()=>{ stake=+b.dataset.sk; inp.value=''; ov.querySelectorAll('[data-sk]').forEach(x=>x.classList.toggle('on',x===b)); });
  inp.oninput=()=>{ let v=Math.floor(+inp.value||0); if(v>1000){ v=1000; inp.value=1000; } stake=Math.max(0,v); ov.querySelectorAll('[data-sk]').forEach(x=>x.classList.toggle('on',!inp.value&&+x.dataset.sk===stake)); }; };

/* ===== Экономия трафика: видео историй и полноэкранные видео скачиваются один раз и дальше играют из кэша браузера ===== */
(function(){
  const CN='lumo-video-v1', MAX_ONE=60*1024*1024, MAX_ALL=400*1024*1024, IDX='lumoVidIdx';
  const ok=('caches' in window)&&window.isSecureContext;
  const blobs=new Map(), pend=new Map();
  const isStorage=u=>/\/storage\/v1\/object\/public\//.test(u||'')&&!/^blob:/.test(u||'');
  const clean=u=>String(u||'').split('#')[0];
  const idx=()=>{ try{ return JSON.parse(localStorage.getItem(IDX)||'[]'); }catch(e){ return []; } };
  const setIdx=a=>{ try{ localStorage.setItem(IDX,JSON.stringify(a.slice(-300))); }catch(e){} };
  async function trim(cache){ let a=idx(), tot=a.reduce((s,x)=>s+(x.s||0),0); while(tot>MAX_ALL&&a.length){ const x=a.shift(); tot-=x.s||0; try{ await cache.delete(x.u); }catch(e){} } setIdx(a); }
  async function get(u){
    if(blobs.has(u)) return blobs.get(u);
    if(pend.has(u)) return pend.get(u);
    const p=(async()=>{
      const cache=await caches.open(CN);
      let r=await cache.match(u);
      if(!r){
        const ctl=new AbortController();
        const full=await fetch(u,{signal:ctl.signal}); if(!full.ok) return null;
        const len=+(full.headers.get('content-length')||0);
        if(len>MAX_ONE){ ctl.abort(); return null; }
        const b=await full.blob();
        await cache.put(u,new Response(b,{headers:{'Content-Type':b.type||'video/mp4','Content-Length':String(b.size)}}));
        const a=idx().filter(x=>x.u!==u); a.push({u,s:b.size}); setIdx(a); trim(cache);
        r=await cache.match(u);
      } else { const a=idx(); const i=a.findIndex(x=>x.u===u); if(i>=0){ a.push(a.splice(i,1)[0]); setIdx(a); } }
      if(!r) return null;
      const url=URL.createObjectURL(await r.blob()); blobs.set(u,url); return url;
    })().catch(()=>null).finally(()=>pend.delete(u));
    pend.set(u,p); return p;
  }
  const SEL='.stmedia video,#vplayer video,#lightbox video,.ov .modal video[controls]';
  function take(v){
    if(v.dataset.lvc) return; const src=v.getAttribute('src'); if(!isStorage(src)) return;
    v.dataset.lvc=1; const u=clean(src), frag=src.includes('#')?'#'+src.split('#')[1]:'';
    const auto=v.autoplay||v.hasAttribute('autoplay');
    v.removeAttribute('src'); try{ v.load(); }catch(e){}
    get(u).then(b=>{ if(!b) v.dataset.lvc='skip'; v.src=(b||src)+(b?frag:''); if(auto){ const pp=v.play(); if(pp&&pp.catch) pp.catch(()=>{}); } });
  }
  if(ok){
    new MutationObserver(ms=>{ for(const m of ms){ for(const n of m.addedNodes){ if(n.nodeType!==1) continue;
      if(n.matches&&n.matches(SEL)) take(n); n.querySelectorAll&&n.querySelectorAll(SEL).forEach(take); }
      if(m.type==='attributes'&&m.target.dataset&&m.target.dataset.lvc!=='skip'&&m.target.matches&&m.target.matches(SEL)&&isStorage(m.target.getAttribute('src'))){ delete m.target.dataset.lvc; take(m.target); } } })
      .observe(document.documentElement,{childList:true,subtree:true,attributes:true,attributeFilter:['src']});
  }
})();

/* ===== «Моя история»: долгое нажатие / правая кнопка — как в приложении (добавить, опубликованные, архив) ===== */
(function(){
  const st=document.createElement('style'); st.textContent='.setgrp.pesg{margin:0 0 14px}'; document.head.appendChild(st);
  const fire=id=>{ const d=document.createElement('div'); d.id=id; d.style.display='none'; document.body.appendChild(d); d.click(); d.remove(); };
  const mine=t=>{ const b=t.closest&&t.closest('.stbar .stit'); return b&&b===b.parentElement.querySelector('.stit')?b:null; };
  function menu(b){ dropMenu(b,[['plus','Добавить историю',()=>{ const a=b.querySelector('[data-st-add]'); if(a) a.click(); }],
    ['tgrid','Опубликованные истории',()=>fire('tgSPosts')],['tarch','Архив историй',()=>fire('tgSArc')]]); }
  document.addEventListener('contextmenu',e=>{ const b=mine(e.target); if(!b) return; e.preventDefault(); e.stopPropagation(); menu(b); },true);
  let lp=null, lpFired=false;
  document.addEventListener('touchstart',e=>{ const b=mine(e.target); if(!b) return; lpFired=false; clearTimeout(lp); lp=setTimeout(()=>{ lpFired=true; navigator.vibrate&&navigator.vibrate(15); menu(b); },480); },{passive:true,capture:true});
  ['touchend','touchmove','touchcancel'].forEach(ev=>document.addEventListener(ev,()=>clearTimeout(lp),{passive:true,capture:true}));
  document.addEventListener('click',e=>{ if(lpFired&&mine(e.target)){ lpFired=false; e.preventDefault(); e.stopPropagation(); } },true);
})();

/* ===== Видеозвонок: кнопки прячутся через 5 секунд, касание возвращает; «картинка в картинке» при сворачивании ===== */
(function(){
  const st=document.createElement('style'); st.textContent=`
#call .cbtns,#call .spkl,#call #cui>div[style*="position:absolute"],#cPip{transition:opacity .45s ease,transform .45s ease}
#call.cidle .cbtns,#call.cidle .spkl,#call.cidle #cui>div[style*="position:absolute"],#call.cidle #cPip{opacity:0;transform:translateY(24px);pointer-events:none}
#call.cidle #cui>div[style*="position:absolute"],#call.cidle #cPip{transform:translateY(-16px)}
#cPip{position:absolute;top:calc(14px + env(safe-area-inset-top));right:16px;z-index:5;width:44px;height:44px;border-radius:50%;border:0;background:rgba(0,0,0,.35);color:#fff;display:none;place-items:center;cursor:pointer;-webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px)}
#cPip svg{width:22px;height:22px}
#call.vid #cPip{display:grid}
#call.vid #lv{top:calc(66px + env(safe-area-inset-top))}`; document.head.appendChild(st);
  const PIP_IC='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2.5" y="4.5" width="19" height="15" rx="2.5"/><rect x="12" y="11" width="7" height="6" rx="1.2" fill="currentColor" stroke="none"/></svg>';
  let last=Date.now(), swallow=0;
  const vidOn=c=>{ const rv=c.querySelector('#rv'); return !!(rv&&!rv.classList.contains('hidden')&&rv.srcObject) || ['#rimg','#rcv'].some(q=>{ const e=c.querySelector(q); return e&&!e.classList.contains('hidden'); }); };
  const pipOk=()=>!!(document.pictureInPictureEnabled||(HTMLVideoElement.prototype.webkitSetPresentationMode));
  async function pip(){ const rv=document.querySelector('#call #rv'); if(!rv||rv.classList.contains('hidden')) return;
    try{ if(document.pictureInPictureElement) return await document.exitPictureInPicture();
      if(rv.requestPictureInPicture) return await rv.requestPictureInPicture();
      if(rv.webkitSetPresentationMode) rv.webkitSetPresentationMode(rv.webkitPresentationMode==='picture-in-picture'?'inline':'picture-in-picture');
    }catch(e){} }
  function wake(){ last=Date.now(); const c=document.getElementById('call'); if(c) c.classList.remove('cidle'); }
  document.addEventListener('pointerdown',e=>{ const c=document.getElementById('call'); if(!c||!c.contains(e.target)) return;
    if(c.classList.contains('cidle')){ e.preventDefault(); e.stopPropagation(); swallow=Date.now(); } wake(); },true);
  document.addEventListener('click',e=>{ if(Date.now()-swallow<700&&document.getElementById('call')&&document.getElementById('call').contains(e.target)){ swallow=0; e.preventDefault(); e.stopPropagation(); } },true);
  setInterval(()=>{ const c=document.getElementById('call'); if(!c) return;
    const on=vidOn(c); c.classList.toggle('vid',on&&pipOk());
    let b=document.getElementById('cPip');
    if(!b){ b=document.createElement('button'); b.id='cPip'; b.title='Картинка в картинке'; b.innerHTML=PIP_IC; b.onclick=e=>{ e.stopPropagation(); pip(); }; c.appendChild(b); }
    const rv=c.querySelector('#rv'); if(rv&&!rv.dataset.pipset){ rv.dataset.pipset=1; rv.autoPictureInPicture=true; rv.setAttribute('autopictureinpicture',''); }
    if(!on){ c.classList.remove('cidle'); return; }
    if(Date.now()-last>5000) c.classList.add('cidle');
  },1000);
  // свернули вкладку во время видеозвонка — браузер может сам открыть окошко с собеседником
  try{ navigator.mediaSession&&navigator.mediaSession.setActionHandler('enterpictureinpicture',()=>pip()); }catch(e){}
  document.addEventListener('visibilitychange',()=>{ const c=document.getElementById('call'); if(!c) return;
    if(document.hidden&&vidOn(c)&&!document.pictureInPictureElement){ pip(); }
    if(!document.hidden) wake(); });
})();

/* ===== Видеозвонок: видео собеседника целиком, если его форма не совпадает с экраном (телефон ↔ ПК) ===== */
(function(){
  const st=document.createElement('style');
  st.textContent='#call #rv.lfit,#call #rimg.lfit,#call #rcv.lfit{object-fit:contain!important}';
  document.head.appendChild(st);
  function fit(el,w,h){ if(!el||!w||!h) return; const c=el.parentElement; if(!c) return;
    const vr=w/h, cr=c.clientWidth/Math.max(1,c.clientHeight);
    el.classList.toggle('lfit', Math.max(vr,cr)/Math.min(vr,cr)>1.25); }
  setInterval(()=>{ const c=document.getElementById('call'); if(!c) return;
    const rv=c.querySelector('#rv'), im=c.querySelector('#rimg'), cv=c.querySelector('#rcv');
    if(rv) fit(rv,rv.videoWidth,rv.videoHeight);
    if(im) fit(im,im.naturalWidth,im.naturalHeight);
    if(cv) fit(cv,cv.width,cv.height);
  },700);
})();

/* ===== Черновики: недописанный текст хранится по чатам (и после перезагрузки), в списке чатов — «Черновик: …» ===== */
function lmDraftKey(){ return S.me&&S.me.id?'lm_drafts_'+S.me.id:null; }
function lmDraftsSave(){ const k=lmDraftKey(); if(!k) return; try{ const o={}; drafts.forEach((v,id)=>{ if(id&&v&&v.trim()) o[id]=v.slice(0,4000); }); if(Object.keys(o).length) localStorage.setItem(k,JSON.stringify(o)); else localStorage.removeItem(k); }catch(e){} }
(function(){
  const st=document.createElement('style'); st.textContent='.row .pv .drf{color:#e5484d;font-weight:600}'; document.head.appendChild(st);
  let loaded=false;
  const ld=setInterval(()=>{ const k=lmDraftKey(); if(!k) return; clearInterval(ld); loaded=true;
    try{ const o=JSON.parse(localStorage.getItem(k)||'{}'); for(const id in o){ if(!drafts.has(id)&&o[id]) drafts.set(id,o[id]); } }catch(e){}
    if(S.cur&&drafts.get(S.cur)&&!$('#txt').value){ $('#txt').value=drafts.get(S.cur); try{ autoGrow(); }catch(e){} }
    try{ renderList(); }catch(e){} },300);
  let t;
  document.addEventListener('input',e=>{ if(!e.target||e.target.id!=='txt'||!S.cur||!loaded) return; clearTimeout(t); t=setTimeout(saveDraft,400); },true);
  const flush=()=>{ if(S.cur&&loaded) saveDraft(); };
  addEventListener('pagehide',flush); document.addEventListener('visibilitychange',()=>{ if(document.hidden) flush(); });
  document.addEventListener('click',e=>{ if(e.target.closest&&e.target.closest('#sDrafts')) setTimeout(()=>{ if(!Object.keys(localStorage).some(k=>/^lm_drafts_/.test(k))){ drafts.clear(); try{ renderList(); }catch(e){} } },600); },true);
})();

/* ===== Стикеры с сервера (наборы задаются в lm_config.look.stickers) ===== */
(function(){ const st=document.createElement('style'); st.textContent='.rstk{width:120px;height:120px;object-fit:contain;display:block}.eg.stk .rstk{width:100%;height:auto;aspect-ratio:1}.eg.stk .rspk{grid-column:1/-1;font-size:12px;font-weight:700;color:var(--muted);padding:8px 4px 2px}'; document.head.appendChild(st); })();

/* ===== Подарки другого пользователя: весь список и карточка подарка ===== */
(function(){
  const RR={rare:['Редкий','#22c7e0'],epic:['Эпический','#ff8a3d'],legendary:['Легендарный','#b069ff'],mythic:['Мифический','#ffc247'],ultra:['Божественный','#ff2ec4']};
  const st=document.createElement('style');
  st.textContent='.lxgrow .lxsec,.lxgrow .lxg{cursor:pointer}.lxgrow .lxsec .all{float:right;color:var(--a1);letter-spacing:0}.ugg{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px}.ugg .g{background:var(--panel2);border-radius:16px;padding:6px;text-align:center;cursor:pointer;min-width:0}.ugg .g .lxif{width:100%;aspect-ratio:1;border-radius:12px}.ugg .g b{display:block;font-size:12px;margin-top:4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}';
  document.head.appendChild(st);
  async function load(u){ const {data,error}=await sb.rpc('lm_gift_mine',{p_user:u}); if(error) throw error; return data||[]; }
  async function card(o,u){
    let from=null; if(o.from_user){ if(!S.profiles.get(o.from_user)) await profGet([o.from_user]).catch(()=>{}); from=S.profiles.get(o.from_user); }
    const r=RR[o.rarity]||['','#888']; const d=o.at?new Date(o.at):null;
    const w=document.createElement('div'); w.className='lxsh';
    w.innerHTML=`<div class="sh"><button class="x">${ic('x')}</button>${window.art(o.gift_id,'')}<h2>${esc(o.name)}</h2>
    <div class="d">№${o.serial} из ${o.supply} · <b style="color:${r[1]}">${r[0]}</b><br>Подарок в профиле ${esc(profName(u))}.</div>
    <div class="tb"><div class="tr"><div class="l">От</div><div class="r">${from?`${avatar({name:from.name,avatar:from.avatar_url,color:from.color},'xs')}<a>${esc(from.name)}</a>`:'Купил сам'}</div></div>
    <div class="tr"><div class="l">Дата</div><div class="r">${d?esc(d.toLocaleDateString('ru-RU')):'—'}</div></div>
    <div class="tr"><div class="l">Стоимость</div><div class="r">${o.price!=null?esc(o.price+' '+plural(o.price,'люмен','люмена','люменов')):'—'}</div></div></div>
    <button class="ok">OK</button></div>`;
    const cl=()=>w.remove(); w.onclick=e=>{ if(e.target===w) cl(); };
    w.querySelector('.x').onclick=cl; w.querySelector('.ok').onclick=cl; document.body.appendChild(w);
  }
  async function list(u){
    const close=modal('Подарки · '+esc(profName(u)),'<div id="ugg"><div class="em">Загрузка…</div></div>',[]);
    try{ try{ const {data:ga}=await sb.rpc('lm_gift_art'); if(ga&&typeof ga==='object') window.__gart=ga; }catch(e){}
      const L=await load(u); const el=document.getElementById('ugg'); if(!el) return;
      el.innerHTML=L.length?`<div class="ugg">${L.map((o,i)=>`<div class="g" data-i="${i}">${window.art(o.gift_id,'')}<b style="color:${(RR[o.rarity]||[0,'#888'])[1]}">${esc(o.name)} №${o.serial}</b></div>`).join('')}</div>`:'<div class="em">Подарков пока нет</div>';
      el.querySelectorAll('[data-i]').forEach(x=>x.onclick=()=>card(L[+x.dataset.i],u));
    }catch(e){ toast('Не удалось загрузить подарки'); }
  }
  document.addEventListener('click',e=>{
    const row=e.target.closest&&e.target.closest('.lxgrow'); if(!row) return;
    const a=row.previousElementSibling; const u=a&&a.dataset&&a.dataset.lxu; if(!u) return;
    e.stopImmediatePropagation(); e.preventDefault();
    const g=e.target.closest('.lxg');
    if(g){ const i=[...row.querySelectorAll('.lxg')].indexOf(g); load(u).then(L=>{ if(L[i]) card(L[i],u); }).catch(()=>{}); }
    else list(u);
  },true);
  new MutationObserver(()=>{ document.querySelectorAll('.lxgrow .lxsec:not([data-all])').forEach(h=>{ h.dataset.all=1; h.insertAdjacentHTML('beforeend','<span class="all">Все</span>'); }); }).observe(document.body,{childList:true,subtree:true});
})();

/* ===== Броски: живые анимации (кубик, монетка, баскетбол, футбол, дартс) ===== */
/* Lumo — анимации бросков: кубик, монетка, баскетбол, футбол, дартс.
   Один и тот же код в веб-версии и в приложениях (WebView). Всё детерминировано:
   результат (v) определяет траекторию, кадр t считается чистой функцией — финальный кадр всегда один и тот же. */
(function (root) {
  'use strict';
  const W = 300, H = 300;
  const TAU = Math.PI * 2;
  const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
  const lerp = (a, b, t) => a + (b - a) * t;
  const easeOut = t => 1 - Math.pow(1 - t, 3);
  const easeInOut = t => t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
  // детерминированный «случай» от сида
  const rnd = s => { let x = Math.sin(s * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); };

  // ---------- 3D: кватернионы ----------
  const qMul = (a, b) => [
    a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3],
    a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2],
    a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1],
    a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0]];
  const qAxis = (x, y, z, ang) => { const l = Math.hypot(x, y, z) || 1, s = Math.sin(ang / 2); return [Math.cos(ang / 2), x / l * s, y / l * s, z / l * s]; };
  const qRot = (q, v) => {
    const [w, x, y, z] = q, [vx, vy, vz] = v;
    const ix = w * vx + y * vz - z * vy, iy = w * vy + z * vx - x * vz, iz = w * vz + x * vy - y * vx, iw = -x * vx - y * vy - z * vz;
    return [ix * w + iw * -x + iy * -z - iz * -y, iy * w + iw * -y + iz * -x - ix * -z, iz * w + iw * -z + ix * -y - iy * -x];
  };
  const qFromTo = (a, b) => { // кратчайший поворот вектора a в b
    const d = a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    if (d < -0.9999) { const ax = Math.abs(a[0]) < .9 ? [1, 0, 0] : [0, 1, 0]; const c = [a[1] * ax[2] - a[2] * ax[1], a[2] * ax[0] - a[0] * ax[2], a[0] * ax[1] - a[1] * ax[0]]; return qAxis(c[0], c[1], c[2], Math.PI); }
    const c = [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
    const q = [1 + d, c[0], c[1], c[2]]; const l = Math.hypot(...q); return q.map(x => x / l);
  };

  // ---------- общие рисовалки ----------
  function shadow(ctx, x, y, rx, ry, a) {
    const g = ctx.createRadialGradient(x, y, 0, x, y, rx);
    g.addColorStop(0, `rgba(0,0,0,${a})`); g.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.save(); ctx.translate(x, y); ctx.scale(1, ry / rx); ctx.translate(-x, -y);
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, rx, 0, TAU); ctx.fill(); ctx.restore();
  }
  function rrect(ctx, x, y, w, h, r) { ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath(); }

  // ======================================================================
  // КУБИК: настоящий 3D-кубик, падает, отскакивает, кувыркается и ложится нужной гранью
  // ======================================================================
  const DICE_FACES = [ // нормаль, «вверх» на грани, число
    { n: [0, 0, 1], u: [1, 0, 0], v: 1 }, { n: [0, 0, -1], u: [-1, 0, 0], v: 6 },
    { n: [1, 0, 0], u: [0, 0, -1], v: 3 }, { n: [-1, 0, 0], u: [0, 0, 1], v: 4 },
    { n: [0, 1, 0], u: [1, 0, 0], v: 2 }, { n: [0, -1, 0], u: [1, 0, 0], v: 5 }];
  const PIPS = { 1: [[0, 0]], 2: [[-1, -1], [1, 1]], 3: [[-1, -1], [0, 0], [1, 1]], 4: [[-1, -1], [1, -1], [-1, 1], [1, 1]],
    5: [[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]], 6: [[-1, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [1, 1]] };
  const DICE_T = 2.3;
  // высота и сдвиг: падение с отскоками (настоящая баллистика с потерей энергии)
  function bounceY(t, h0, g, e, n) {
    // свободное падение с h0, затем n отскоков с коэффициентом e; возвращает высоту и номер удара
    let tt = t, v = Math.sqrt(2 * g * h0), t0 = v / g; // время первого падения
    if (tt < t0) return { y: h0 - .5 * g * tt * tt, hit: 0, since: -1 };
    tt -= t0; let k = 1;
    while (k <= n) { v *= e; const dur = 2 * v / g; if (tt < dur) return { y: v * tt - .5 * g * tt * tt, hit: k, since: tt }; tt -= dur; k++; }
    return { y: 0, hit: n + 1, since: tt };
  }
  function diceQ(v, t) {
    const f = DICE_FACES.find(x => x.v === v);
    // финальная ориентация: нужная грань смотрит на зрителя, плюс лёгкий наклон, чтобы был виден объём
    let q = qFromTo(f.n, [0, 0, 1]);
    const tilt = qMul(qAxis(0, 1, 0, -.42), qAxis(1, 0, 0, .5));
    q = qMul(tilt, q);
    // кувырок: оставшийся угол экспоненциально гаснет, на каждом ударе ось немного меняется
    const k = 2.4, D = DICE_T - .25;
    const tt = Math.min(t, D);
    const rem = (Math.exp(-k * tt) - Math.exp(-k * D)) / (1 - Math.exp(-k * D));
    const ang = rem * TAU * (2.2 + rnd(v) * .6);
    const ax = [.6 + rnd(v + 1) * .5, 1, .3 + rnd(v + 2) * .4];
    const spin = qAxis(ax[0], ax[1], ax[2], ang);
    // покачивание при окончательной остановке
    const wob = t > D - .35 ? Math.sin((t - (D - .35)) * 26) * Math.exp(-(t - (D - .35)) * 9) * .05 : 0;
    return qMul(qAxis(1, 0, 1, wob), qMul(q, spin));
  }
  function drawDice(ctx, v, t) {
    const S = 52, F = 520; // полуребро и «фокус» перспективы
    const b = bounceY(Math.max(0, t - .05), 150, 1500, .38, 3);
    const xs = lerp(-60, 0, easeOut(clamp(t / 1.3, 0, 1)));
    const cx = 150 + xs, cyFloor = 150, cy = cyFloor - b.y;
    // тень: чем выше кубик, тем она меньше и прозрачнее
    const hk = clamp(b.y / 150, 0, 1);
    shadow(ctx, cx + 6, cyFloor + 52, 70 * (1 - hk * .45), 20 * (1 - hk * .45), .38 * (1 - hk * .6));
    // «сплющивание» при ударе
    let sq = 1;
    if (b.hit >= 1 && b.since >= 0 && b.since < .06) sq = 1 - .12 * Math.sin(b.since / .06 * Math.PI) / b.hit;
    const q = diceQ(v, t);
    const L = (() => { const l = [-.35, .42, .84], n = Math.hypot(...l); return l.map(x => x / n); })();
    const proj = p => { const s = F / (F - p[2]); return [cx + p[0] * s, cy + 46 - p[1] * s * sq + (1 - sq) * 46]; };
    const faces = DICE_FACES.map(f => {
      const n = qRot(q, f.n); const u = qRot(q, f.u); const w = [n[1] * u[2] - n[2] * u[1], n[2] * u[0] - n[0] * u[2], n[0] * u[1] - n[1] * u[0]];
      const c = n.map(x => x * S);
      return { f, n, u, w, c, z: c[2] };
    }).filter(o => o.n[2] > 0.02).sort((a, b) => a.z - b.z);
    for (const o of faces) {
      const P = (a, bb) => proj([o.c[0] + o.u[0] * a * S + o.w[0] * bb * S, o.c[1] + o.u[1] * a * S + o.w[1] * bb * S, o.c[2] + o.u[2] * a * S + o.w[2] * bb * S]);
      const c0 = P(0, 0), ua = P(1, 0), wa = P(0, 1);
      const lit = clamp(.7 + .38 * (o.n[0] * L[0] + o.n[1] * L[1] + o.n[2] * L[2]), .55, 1.06);
      // основа грани без скругления — закрывает щели между гранями на рёбрах
      const k0 = P(-1, -1), k1 = P(1, -1), k2 = P(1, 1), k3 = P(-1, 1);
      ctx.fillStyle = `rgb(${200 * lit | 0},${192 * lit | 0},${180 * lit | 0})`;
      ctx.beginPath(); ctx.moveTo(k0[0], k0[1]); ctx.lineTo(k1[0], k1[1]); ctx.lineTo(k2[0], k2[1]); ctx.lineTo(k3[0], k3[1]); ctx.closePath(); ctx.fill();
      ctx.save();
      ctx.setTransform(ctx.__dpr * (ua[0] - c0[0]), ctx.__dpr * (ua[1] - c0[1]), ctx.__dpr * (wa[0] - c0[0]), ctx.__dpr * (wa[1] - c0[1]), ctx.__dpr * c0[0], ctx.__dpr * c0[1]);
      // грань со скруглением
      const g = ctx.createLinearGradient(-1, -1, 1, 1);
      g.addColorStop(0, `rgb(${255 * lit | 0},${252 * lit | 0},${246 * lit | 0})`);
      g.addColorStop(1, `rgb(${232 * lit | 0},${224 * lit | 0},${214 * lit | 0})`);
      ctx.fillStyle = g; rrect(ctx, -.97, -.97, 1.94, 1.94, .3); ctx.fill();
      ctx.lineWidth = .02; ctx.strokeStyle = `rgba(0,0,0,${.18})`; ctx.stroke();
      // точки: с тенью-углублением
      const pts = PIPS[o.f.v], r = o.f.v === 1 ? .26 : .19, d = .52;
      for (const p of pts) {
        ctx.fillStyle = o.f.v === 1 ? '#d8263b' : '#1c1a24';
        ctx.beginPath(); ctx.arc(p[0] * d, p[1] * d, r, 0, TAU); ctx.fill();
        ctx.fillStyle = 'rgba(255,255,255,.22)'; ctx.beginPath(); ctx.arc(p[0] * d + r * .25, p[1] * d + r * .25, r * .55, 0, TAU); ctx.fill();
      }
      // блик
      if (lit > .9) { const hg = ctx.createRadialGradient(-.5, -.6, 0, -.5, -.6, 1.4); hg.addColorStop(0, `rgba(255,255,255,${(lit - .9) * 2.2})`); hg.addColorStop(1, 'rgba(255,255,255,0)'); ctx.fillStyle = hg; rrect(ctx, -1, -1, 2, 2, .34); ctx.fill(); }
      ctx.restore();
    }
  }

  // ======================================================================
  // МОНЕТКА: подброс, кувырки, падение, «юла» на столе (как настоящая монета)
  // ======================================================================
  const COIN_T = 2.8;
  function drawCoin(ctx, v, t) {
    const R = 62, TH = 9, F = 600;
    // полёт вверх-вниз, затем пара отскоков
    const up = 1.05, hMax = 118;
    let y, flipAng, hitK = 0;
    const rest = v === 1 ? 0 : Math.PI;
    const totalFlips = 7 * TAU;
    if (t < up) { const k = t / up; y = hMax * (1 - Math.pow(2 * k - 1, 2)); }
    else { const b = bounceY(t - up, 0.0001, 1600, .3, 2); y = b.y; hitK = b.hit; y = Math.max(0, y); }
    // вращение: быстро в полёте, затем гаснет
    const tf = clamp(t / (up + .25), 0, 1);
    flipAng = rest + totalFlips * (1 - easeOut(tf)) + (t > up ? 0 : 0);
    // после приземления — «юла»: наклон оси вращается и затухает (диск Эйлера)
    const land = up + .25;
    let tiltX = -.9, prec = 0;
    if (t > land) { const s = t - land; const a = .28 * Math.exp(-s * 2.2); prec = s * (9 + s * 10); tiltX += a * Math.cos(prec); flipAng = rest + a * Math.sin(prec) * .9; }
    // итоговая ориентация: монета лежит на столе, видна сверху-спереди
    const q = qMul(qAxis(1, 0, 0, tiltX), qAxis(1, 0, 0, flipAng));
    const cx = 150, floor = 214, cy = floor - y;
    const hk = clamp(y / hMax, 0, 1);
    shadow(ctx, cx + 4, floor + 34, 78 * (1 - hk * .4), 22 * (1 - hk * .4), .35 * (1 - hk * .6));
    const proj = p => { const s = F / (F - p[2]); return [cx + p[0] * s, cy + 18 - p[1] * s]; };
    const n = qRot(q, [0, 0, 1]), u = qRot(q, [1, 0, 0]), w = qRot(q, [0, 1, 0]);
    const front = n[2] >= 0; // какая сторона смотрит на нас
    const faceC = s => n.map(x => x * TH / 2 * s);
    // ребро монеты (рифлёное)
    const N = 48;
    const rim = s => { const c = faceC(s), arr = []; for (let i = 0; i < N; i++) { const a = i / N * TAU; arr.push(proj([c[0] + (u[0] * Math.cos(a) + w[0] * Math.sin(a)) * R, c[1] + (u[1] * Math.cos(a) + w[1] * Math.sin(a)) * R, c[2] + (u[2] * Math.cos(a) + w[2] * Math.sin(a)) * R])); } return arr; };
    const A = rim(front ? 1 : -1), B = rim(front ? -1 : 1);
    ctx.fillStyle = '#9c7413';
    for (let i = 0; i < N; i++) { const j = (i + 1) % N; ctx.beginPath(); ctx.moveTo(A[i][0], A[i][1]); ctx.lineTo(A[j][0], A[j][1]); ctx.lineTo(B[j][0], B[j][1]); ctx.lineTo(B[i][0], B[i][1]); ctx.closePath(); ctx.fillStyle = i % 2 ? '#a77d17' : '#8c6610'; ctx.fill(); }
    // видимая сторона
    const c = proj(faceC(front ? 1 : -1));
    const ua = (() => { const p = faceC(front ? 1 : -1); return proj([p[0] + u[0] * R, p[1] + u[1] * R, p[2] + u[2] * R]); })();
    const wa = (() => { const p = faceC(front ? 1 : -1); return proj([p[0] + w[0] * R, p[1] + w[1] * R, p[2] + w[2] * R]); })();
    ctx.save();
    ctx.setTransform(ctx.__dpr * (ua[0] - c[0]), ctx.__dpr * (ua[1] - c[1]), ctx.__dpr * (wa[0] - c[0]) * (front ? -1 : 1), ctx.__dpr * (wa[1] - c[1]) * (front ? -1 : 1), ctx.__dpr * c[0], ctx.__dpr * c[1]);
    const lit = clamp(.92 + .25 * (n[2] * (front ? 1 : -1)) - .1 * Math.abs(n[1]), .78, 1.12);
    coinFace(ctx, front, lit); // «передняя» сторона — орёл, задняя — решка
    ctx.restore();
    void hitK;
  }
  function coinFace(ctx, heads, lit) {
    const g = ctx.createRadialGradient(-.35, -.4, .1, 0, 0, 1.15);
    const k = x => Math.round(clamp(x * lit, 0, 255));
    g.addColorStop(0, `rgb(${k(255)},${k(236)},${k(160)})`); g.addColorStop(.55, `rgb(${k(232)},${k(184)},${k(62)})`); g.addColorStop(1, `rgb(${k(176)},${k(128)},${k(22)})`);
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(0, 0, 1, 0, TAU); ctx.fill();
    ctx.lineWidth = .05; ctx.strokeStyle = 'rgba(120,80,0,.55)'; ctx.beginPath(); ctx.arc(0, 0, .86, 0, TAU); ctx.stroke();
    // насечки по кругу
    ctx.strokeStyle = 'rgba(120,80,0,.35)'; ctx.lineWidth = .02;
    for (let i = 0; i < 60; i++) { const a = i / 60 * TAU; ctx.beginPath(); ctx.moveTo(Math.cos(a) * .9, Math.sin(a) * .9); ctx.lineTo(Math.cos(a) * .97, Math.sin(a) * .97); ctx.stroke(); }
    ctx.fillStyle = 'rgba(110,70,0,.85)';
    if (heads) {
      // орёл: стилизованная птица с крыльями
      ctx.beginPath();
      ctx.moveTo(0, -.52); ctx.bezierCurveTo(.1, -.5, .14, -.38, .08, -.3);
      ctx.bezierCurveTo(.3, -.36, .55, -.3, .66, -.08); ctx.bezierCurveTo(.5, -.12, .38, -.06, .3, .02);
      ctx.bezierCurveTo(.44, .02, .5, .1, .46, .18); ctx.bezierCurveTo(.34, .12, .22, .14, .14, .2);
      ctx.lineTo(.2, .48); ctx.lineTo(0, .38); ctx.lineTo(-.2, .48); ctx.lineTo(-.14, .2);
      ctx.bezierCurveTo(-.22, .14, -.34, .12, -.46, .18); ctx.bezierCurveTo(-.5, .1, -.44, .02, -.3, .02);
      ctx.bezierCurveTo(-.38, -.06, -.5, -.12, -.66, -.08); ctx.bezierCurveTo(-.55, -.3, -.3, -.36, -.08, -.3);
      ctx.bezierCurveTo(-.14, -.38, -.1, -.5, 0, -.52); ctx.closePath(); ctx.fill();
      ctx.fillStyle = `rgba(255,240,190,${.35 * lit})`; ctx.beginPath(); ctx.arc(-.03, -.42, .035, 0, TAU); ctx.fill();
    } else {
      // решка: номинал
      ctx.font = 'bold 0.78px Georgia, serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText('1', 0, -.08);
      ctx.font = 'bold 0.2px sans-serif'; ctx.fillText('ЛЮМЕН', 0, .42);
      ctx.lineWidth = .04; ctx.strokeStyle = 'rgba(110,70,0,.7)';
      ctx.beginPath(); ctx.arc(0, -.05, .62, Math.PI * .15, Math.PI * .85, true); ctx.stroke();
    }
    // блик
    const hg = ctx.createLinearGradient(-1, -1, 1, 1); hg.addColorStop(.3, 'rgba(255,255,255,0)'); hg.addColorStop(.45, `rgba(255,255,255,${.28 * lit})`); hg.addColorStop(.6, 'rgba(255,255,255,0)');
    ctx.fillStyle = hg; ctx.beginPath(); ctx.arc(0, 0, 1, 0, TAU); ctx.fill();
  }

  // ======================================================================
  // БАСКЕТБОЛ: честная физика (гравитация, отскоки от дужки и щита, вращение мяча)
  // ======================================================================
  const BB = { r: 12, g: 980, rimF: [206, 118], rimB: [246, 118], rimR: 2.6, boardX: 252, boardTop: 54, boardBot: 132, floor: 262, e: .62, eb: .72 };
  // начальные скорости подобраны заранее так, чтобы получился нужный исход (см. tools/tune_basket.js)
  const BB_SHOTS = { 1: [150, -454], 2: [172, -540], 3: [296, -540], 4: [196, -540], 5: [210, -544] };
  function simBasket(v) {
    const [vx0, vy0] = BB_SHOTS[v] || BB_SHOTS[5];
    let x = 46, y = 222, vx = vx0, vy = vy0, rot = 0, w = -9;
    const dt = 1 / 240, out = [];
    let scored = false, touched = false, netHit = -1, floorAt = -1;
    for (let i = 0; i < 240 * 3.2; i++) {
      vy += BB.g * dt; x += vx * dt; y += vy * dt; rot += w * dt;
      // дужка: две точки (передняя и задняя)
      for (const p of [BB.rimF, BB.rimB]) {
        const dx = x - p[0], dy = y - p[1], d = Math.hypot(dx, dy), md = BB.r + BB.rimR;
        if (d < md) {
          const nx = dx / d, ny = dy / d; x = p[0] + nx * md; y = p[1] + ny * md;
          const vn = vx * nx + vy * ny; if (vn < 0) { vx -= (1 + BB.e) * vn * nx; vy -= (1 + BB.e) * vn * ny; vx *= .92; w += vn * .02; touched = true; }
        }
      }
      // щит
      if (x + BB.r > BB.boardX && y > BB.boardTop && y < BB.boardBot && vx > 0) { x = BB.boardX - BB.r; vx = -vx * BB.eb; w = -w * .6; touched = true; }
      // пол
      if (y + BB.r > BB.floor) { y = BB.floor - BB.r; if (vy > 0) { vy = -vy * .5; if (floorAt < 0) floorAt = i; } vx *= .55; w = vx / BB.r; }
      // попадание: центр мяча прошёл сверху вниз между точками дужки
      if (!scored && vy > 0 && y > BB.rimF[1] && y - vy * dt <= BB.rimF[1] && x > BB.rimF[0] && x < BB.rimB[0]) { scored = true; netHit = i; }
      // в сетке мяч тормозит
      if (scored && y > BB.rimF[1] && y < BB.rimF[1] + 46) { vx *= .95; vy *= .975; x = lerp(x, (BB.rimF[0] + BB.rimB[0]) / 2, .08); }
      // стойка кольца
      if (x + BB.r > 272 && y > 40 && vx > 0) { x = 272 - BB.r; vx = -vx * .35; }
      out.push([x, y, rot]);
    }
    return { path: out, scored, touched, netHit, dt, end: floorAt < 0 ? 3 : Math.min(3, floorAt * dt + .9) };
  }
  const BBC = {};
  const basket = v => BBC[v] || (BBC[v] = simBasket(v));
  const BASKET_T = 3.0;
  function drawBasket(ctx, v, t) {
    const s = basket(v); const i = clamp(Math.floor(Math.min(t, s.end) / s.dt), 0, s.path.length - 1);
    const [x, y, rot] = s.path[i];
    ctx.translate(150, 160); ctx.scale(1.13, 1.13); ctx.translate(-160, -150);
    // пол и тень
    const fl = ctx.createLinearGradient(0, BB.floor - 6, 0, BB.floor + 30); fl.addColorStop(0, 'rgba(200,140,80,.0)'); fl.addColorStop(.3, 'rgba(196,132,74,.35)'); fl.addColorStop(1, 'rgba(160,100,50,0)');
    ctx.fillStyle = fl; ctx.fillRect(0, BB.floor - 6, W, 36);
    shadow(ctx, x, BB.floor + 2, 20 * (1 - clamp((BB.floor - y) / 260, 0, .6)), 5, .35 * (1 - clamp((BB.floor - y) / 260, 0, .7)));
    // стойка и щит
    ctx.fillStyle = '#5b6170'; ctx.fillRect(272, 40, 8, BB.floor - 40);
    ctx.fillStyle = '#4a4f5c'; ctx.fillRect(254, 86, 20, 6);
    const bg = ctx.createLinearGradient(BB.boardX, 0, BB.boardX + 10, 0); bg.addColorStop(0, '#f4f7fb'); bg.addColorStop(1, '#c9d2de');
    ctx.fillStyle = bg; rrect(ctx, BB.boardX, BB.boardTop - 10, 9, BB.boardBot - BB.boardTop + 20, 2); ctx.fill();
    ctx.fillStyle = '#e8492f'; ctx.fillRect(BB.boardX, 88, 3, 30);
    // задняя часть дужки и сетка (за мячом)
    const netSw = s.netHit >= 0 && i >= s.netHit ? Math.exp(-(i - s.netHit) * s.dt * 4) * Math.sin((i - s.netHit) * s.dt * 22) : 0;
    const ballInNet = s.scored && y > BB.rimF[1] - 4 && y < BB.rimF[1] + 52 && x > BB.rimF[0] - 6 && x < BB.rimB[0] + 6;
    drawNet(ctx, netSw, ballInNet ? (y - BB.rimF[1]) : -1);
    ctx.strokeStyle = '#c2410c'; ctx.lineWidth = 3; ctx.beginPath(); ctx.ellipse((BB.rimF[0] + BB.rimB[0]) / 2, BB.rimF[1], 20, 4, 0, Math.PI, TAU); ctx.stroke();
    // мяч
    ball(ctx, x, y, BB.r, rot);
    // передняя часть дужки поверх мяча
    ctx.strokeStyle = '#ea580c'; ctx.lineWidth = 3.4; ctx.beginPath(); ctx.ellipse((BB.rimF[0] + BB.rimB[0]) / 2, BB.rimF[1], 20, 4, 0, 0, Math.PI); ctx.stroke();
    ctx.fillStyle = '#9a3412'; ctx.fillRect(BB.rimB[0], BB.rimF[1] - 2, BB.boardX - BB.rimB[0], 3);
  }
  function drawNet(ctx, sw, ballDepth) {
    const top = BB.rimF[1], l = BB.rimF[0], r = BB.rimB[0], cx = (l + r) / 2;
    ctx.strokeStyle = 'rgba(255,255,255,.85)'; ctx.lineWidth = 1;
    const rows = 5, cols = 7;
    const pt = (c, rr) => {
      const k = rr / rows; let half = lerp(20, 11, k);
      if (ballDepth >= 0) { const dist = Math.abs(rr / rows * 44 - ballDepth); if (dist < 16) half += (16 - dist) * .55; }
      const xx = cx + (c / (cols - 1) - .5) * 2 * half + sw * 5 * k;
      return [xx, top + k * 44 + Math.abs(sw) * 3 * k];
    };
    for (let c = 0; c < cols; c++) { ctx.beginPath(); for (let rr = 0; rr <= rows; rr++) { const p = pt(c + (rr % 2) * .5 - .25, rr); rr ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); }
    for (let rr = 1; rr <= rows; rr++) { ctx.beginPath(); for (let c = 0; c < cols; c++) { const p = pt(c, rr); c ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); }
    void l; void r;
  }
  function ball(ctx, x, y, r, rot) {
    const g = ctx.createRadialGradient(x - r * .35, y - r * .4, r * .1, x, y, r);
    g.addColorStop(0, '#ffb46b'); g.addColorStop(.6, '#f2731c'); g.addColorStop(1, '#b8480b');
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill();
    ctx.save(); ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.clip(); ctx.translate(x, y); ctx.rotate(rot);
    ctx.strokeStyle = 'rgba(40,16,4,.85)'; ctx.lineWidth = r * .09;
    ctx.beginPath(); ctx.moveTo(-r, 0); ctx.lineTo(r, 0); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, -r); ctx.lineTo(0, r); ctx.stroke();
    ctx.beginPath(); ctx.arc(-r * 1.25, 0, r * .95, -.9, .9); ctx.stroke();
    ctx.beginPath(); ctx.arc(r * 1.25, 0, r * .95, Math.PI - .9, Math.PI + .9); ctx.stroke();
    ctx.restore();
  }

  // ======================================================================
  // ФУТБОЛ: вид из-за мяча, ворота в перспективе, вратарь прыгает, сетка прогибается
  // ======================================================================
  const FOOT_T = 2.7;
  // цель удара в координатах ворот (x: -1..1 — от штанги до штанги, y: 0..1 — от земли до перекладины)
  const FOOT_SHOTS = {
    1: { tx: 1.45, ty: .35, keeper: -.2, kind: 'wide' },     // мимо, рядом со штангой
    2: { tx: -.55, ty: .45, keeper: -.55, kind: 'save' },    // вратарь отбивает
    3: { tx: -.78, ty: .16, keeper: .45, kind: 'goal' },     // низом в угол
    4: { tx: .8, ty: .86, keeper: .25, kind: 'goal' },       // в «девятку»
    5: { tx: .2, ty: .62, keeper: -.7, kind: 'goal' }        // вратарь прыгнул не туда
  };
  function drawFoot(ctx, v, t) {
    const sh = FOOT_SHOTS[v] || FOOT_SHOTS[3];
    // перспектива: z=0 — у мяча, z=1 — линия ворот
    const hor = 96, gw = 150, gh = 66; // ворота на экране
    const gx = 150, gy = 168; // центр линии ворот (низ)
    const P = (x, y, z) => { const s = lerp(1, .32, Math.pow(z, .8)); const sx = 150 + (gx - 150) * z + x * s * 230; const sy = lerp(270, gy, Math.pow(z, .85)) - y * s * 200; return [sx, sy, s]; };
    // газон
    const grass = ctx.createLinearGradient(0, hor, 0, H);
    grass.addColorStop(0, '#2f8f46'); grass.addColorStop(1, '#1f6b33');
    ctx.fillStyle = grass; rrect(ctx, 6, hor, W - 12, H - hor - 6, 22); ctx.fill();
    ctx.save(); rrect(ctx, 6, hor, W - 12, H - hor - 6, 22); ctx.clip();
    for (let i = 0; i < 6; i++) { ctx.fillStyle = i % 2 ? 'rgba(255,255,255,.05)' : 'rgba(0,0,0,.05)'; const y0 = lerp(hor, H, Math.pow(i / 6, 1.6)), y1 = lerp(hor, H, Math.pow((i + 1) / 6, 1.6)); ctx.fillRect(0, y0, W, y1 - y0); }
    // разметка штрафной
    ctx.strokeStyle = 'rgba(255,255,255,.55)'; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(20, gy + 2); ctx.lineTo(280, gy + 2); ctx.stroke();
    ctx.beginPath(); const a1 = P(-1.1, 0, .55), a2 = P(1.1, 0, .55); ctx.moveTo(gx - gw * .8, gy + 2); ctx.lineTo(a1[0], a1[1]); ctx.lineTo(a2[0], a2[1]); ctx.lineTo(gx + gw * .8, gy + 2); ctx.stroke();
    ctx.restore();
    // мяч: путь
    const tKick = .35, tFly = 1.0;
    const k = clamp((t - tKick) / tFly, 0, 1);
    let bx, by, bz, saved = false, post = false;
    const goal = sh.kind === 'goal';
    const gX = x => x * gw / 2 / 230 / .32, gY = y => y * gh / 200 / .32; // перевод координат ворот в мир
    const tx = gX(sh.tx), ty = gY(sh.ty);
    if (t < tKick) { bx = 0; by = 0; bz = 0; }
    else if (k < 1) { const kk = k * (1.25 - .25 * k); /* мяч слегка тормозит в воздухе */ bx = tx * kk + Math.sin(kk * Math.PI) * .06 * Math.sign(sh.tx || 1); by = ty * kk + Math.sin(kk * Math.PI) * .16; bz = kk; }
    else {
      // после ворот
      const s = t - tKick - tFly;
      if (goal) { bx = tx; by = Math.max(0, ty - s * s * 1.8); bz = 1 + Math.min(.12, s * .5); }
      else if (sh.kind === 'save') { saved = true; bx = tx - s * .9; by = Math.max(0, ty + s * .5 - s * s * 2.4); bz = 1 - s * .45; }
      else { post = true; bx = tx + s * .2; by = Math.max(0, ty - s * s * 1.6); bz = 1 + s * .5; }
    }
    // вратарь: стоит, реагирует, прыгает
    const kj = clamp((t - tKick - .25) / .55, 0, 1);
    const kx = lerp(0, sh.keeper, easeOut(kj)) * gw / 2;
    const kLift = Math.sin(kj * Math.PI) * 14 * Math.abs(sh.keeper);
    const kAng = sh.keeper * easeOut(kj) * 1.25;
    // ворота: задняя сетка
    const L = gx - gw / 2, R = gx + gw / 2, T = gy - gh, depth = 18;
    const bulge = goal && t > tKick + tFly ? Math.exp(-(t - tKick - tFly) * 3.2) * 10 : 0;
    const hitX = gx + sh.tx * gw / 2, hitY = gy - sh.ty * gh;
    ctx.strokeStyle = 'rgba(255,255,255,.5)'; ctx.lineWidth = .8;
    const netP = (u, w) => { const x = lerp(L + 8, R - 8, u), y = lerp(T - depth * .4, gy - 2, w); const d = Math.hypot(x - hitX, y - hitY); const b = bulge * Math.max(0, 1 - d / 50); return [x + (x - gx) * .0, y - depth * .2 - b * .4, b]; };
    for (let i = 0; i <= 14; i++) { ctx.beginPath(); for (let j = 0; j <= 8; j++) { const p = netP(i / 14, j / 8); j ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); }
    for (let j = 0; j <= 8; j++) { ctx.beginPath(); for (let i = 0; i <= 14; i++) { const p = netP(i / 14, j / 8); i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); }
    ctx.strokeStyle = 'rgba(255,255,255,.55)'; ctx.beginPath(); ctx.moveTo(L, T); ctx.lineTo(L + 8, T - depth * .5); ctx.lineTo(R - 8, T - depth * .5); ctx.lineTo(R, T); ctx.moveTo(L + 8, T - depth * .5); ctx.lineTo(L + 8, gy - 4); ctx.moveTo(R - 8, T - depth * .5); ctx.lineTo(R - 8, gy - 4); ctx.stroke();
    // мяч за вратарём, если залетел в ворота
    const bp = P(bx, by, Math.min(bz, 1.1));
    const br = 19 * (bp[2] * .55 + .45) * (bz > 1 ? .92 : 1);
    const ballBehind = bz >= .98;
    const drawBall = () => {
      shadow(ctx, P(bx, 0, Math.min(bz, 1.1))[0], P(bx, 0, Math.min(bz, 1.1))[1] + 2, br * 1.1, br * .35, .35);
      soccer(ctx, bp[0], bp[1] - br, br, t * (t > tKick ? 16 : 0) * (1 - k * .5));
    };
    if (ballBehind) drawBall();
    keeper(ctx, gx + kx, gy - 2 - kLift, kAng, saved ? 1 : 0);
    // штанги и перекладина
    ctx.strokeStyle = '#ffffff'; ctx.lineWidth = 4.5; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(L, gy); ctx.lineTo(L, T); ctx.lineTo(R, T); ctx.lineTo(R, gy); ctx.stroke(); ctx.lineCap = 'butt';
    if (!ballBehind) drawBall();
    // вспышка «ГОЛ»
    if (goal && t > tKick + tFly) {
      const s = t - tKick - tFly; const a = clamp(s * 3, 0, 1) * clamp((2.5 - s) * 2, 0, 1);
      ctx.save(); ctx.globalAlpha = a; ctx.fillStyle = 'rgba(255,255,255,.95)'; ctx.font = '900 30px system-ui,-apple-system,Segoe UI,Roboto,sans-serif'; ctx.textAlign = 'center';
      ctx.shadowColor = 'rgba(0,0,0,.45)'; ctx.shadowBlur = 8; ctx.fillText('ГОЛ!', 150, 70 - easeOut(clamp(s * 2, 0, 1)) * 8); ctx.restore();
    }
    void post; void hor;
  }
  function keeper(ctx, x, y, ang, saving) {
    ctx.save(); ctx.translate(x, y); ctx.rotate(ang);
    // тень вратаря
    ctx.fillStyle = '#ffd23f'; // форма
    ctx.strokeStyle = '#1e1e28'; ctx.lineWidth = 4; ctx.lineCap = 'round';
    // ноги
    ctx.beginPath(); ctx.moveTo(-4, -18); ctx.lineTo(-7, 0); ctx.moveTo(4, -18); ctx.lineTo(7, 0); ctx.stroke();
    // туловище
    rrect(ctx, -8, -40, 16, 24, 5); ctx.fill();
    // руки вверх-в стороны
    ctx.strokeStyle = '#ffd23f'; ctx.lineWidth = 4.5;
    ctx.beginPath(); ctx.moveTo(-7, -36); ctx.lineTo(-18 - saving * 4, -50); ctx.moveTo(7, -36); ctx.lineTo(18 + saving * 4, -50); ctx.stroke();
    ctx.fillStyle = '#f5f5f5'; ctx.beginPath(); ctx.arc(-19 - saving * 4, -52, 3.6, 0, TAU); ctx.arc(19 + saving * 4, -52, 3.6, 0, TAU); ctx.fill();
    // голова
    ctx.fillStyle = '#e7b48f'; ctx.beginPath(); ctx.arc(0, -47, 6, 0, TAU); ctx.fill();
    ctx.fillStyle = '#3b2a20'; ctx.beginPath(); ctx.arc(0, -49, 6, Math.PI, TAU); ctx.fill();
    ctx.restore(); ctx.lineCap = 'butt';
  }
  function soccer(ctx, x, y, r, rot) {
    const g = ctx.createRadialGradient(x - r * .35, y - r * .4, r * .1, x, y, r);
    g.addColorStop(0, '#ffffff'); g.addColorStop(.7, '#e9ecf1'); g.addColorStop(1, '#a9b0bc');
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill();
    ctx.save(); ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.clip(); ctx.translate(x, y); ctx.rotate(rot);
    ctx.fillStyle = '#1d1f27';
    const pent = (cx, cy, s) => { ctx.beginPath(); for (let i = 0; i < 5; i++) { const a = -Math.PI / 2 + i * TAU / 5; const px = cx + Math.cos(a) * s, py = cy + Math.sin(a) * s; i ? ctx.lineTo(px, py) : ctx.moveTo(px, py); } ctx.closePath(); ctx.fill(); };
    pent(0, 0, r * .36);
    for (let i = 0; i < 5; i++) { const a = -Math.PI / 2 + i * TAU / 5 + Math.PI / 5; pent(Math.cos(a) * r * .95, Math.sin(a) * r * .95, r * .3); }
    ctx.restore();
  }

  // ======================================================================
  // ДАРТС: дротик летит к мишени, втыкается, мишень и дротик дрожат
  // ======================================================================
  const DART_T = 1.9;
  const DART_HIT = { 6: [0, 0], 5: [7, -13], 4: [-34, 44], 3: [44, 28], 2: [-63, -46], 1: [104, 78] };
  const SEG = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5];
  function drawDarts(ctx, v, t) {
    const cx = 150, cy = 132, R = 104;
    const tFly = .55, tHit = .2 + tFly;
    const hit = DART_HIT[v] || DART_HIT[3];
    const miss = v === 1;
    const shake = t > tHit ? Math.sin((t - tHit) * 48) * Math.exp(-(t - tHit) * 9) : 0;
    // стена
    ctx.save(); ctx.translate(shake * 1.2, 0);
    // мишень
    ctx.fillStyle = '#1b1b1f'; ctx.beginPath(); ctx.arc(cx, cy, R + 12, 0, TAU); ctx.fill();
    const ring = (r0, r1, c1, c2) => { for (let i = 0; i < 20; i++) { const a0 = (i - .5) / 20 * TAU - Math.PI / 2, a1 = (i + .5) / 20 * TAU - Math.PI / 2; ctx.fillStyle = i % 2 ? c2 : c1; ctx.beginPath(); ctx.arc(cx, cy, r1, a0, a1); ctx.arc(cx, cy, r0, a1, a0, true); ctx.closePath(); ctx.fill(); } };
    ring(R * .62, R, '#efe6cf', '#1f1f23');
    ring(R * .9, R, '#d32f2f', '#2e7d32');
    ring(R * .1, R * .58, '#efe6cf', '#1f1f23');
    ring(R * .54, R * .6, '#d32f2f', '#2e7d32');
    ctx.fillStyle = '#2e7d32'; ctx.beginPath(); ctx.arc(cx, cy, R * .1, 0, TAU); ctx.fill();
    ctx.fillStyle = '#d32f2f'; ctx.beginPath(); ctx.arc(cx, cy, R * .045, 0, TAU); ctx.fill();
    ctx.strokeStyle = 'rgba(200,200,200,.45)'; ctx.lineWidth = .8; ctx.beginPath(); ctx.arc(cx, cy, R, 0, TAU); ctx.stroke();
    ctx.fillStyle = '#f2f2f2'; ctx.font = 'bold 9px system-ui,sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    SEG.forEach((n, i) => { const a = i / 20 * TAU - Math.PI / 2; ctx.fillText(String(n), cx + Math.cos(a) * (R + 6.5), cy + Math.sin(a) * (R + 6.5)); });
    // блик
    const hg = ctx.createRadialGradient(cx - 40, cy - 50, 5, cx, cy, R + 12); hg.addColorStop(0, 'rgba(255,255,255,.12)'); hg.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = hg; ctx.beginPath(); ctx.arc(cx, cy, R + 12, 0, TAU); ctx.fill();
    ctx.restore();
    // дротик
    const k = clamp((t - .2) / tFly, 0, 1);
    if (t < .2) return;
    const tx = cx + hit[0], ty = cy + hit[1];
    if (k < 1) {
      // летит от зрителя: большой и снизу → маленький у цели, по дуге
      const e = easeInOut(k) * .4 + k * .6;
      const x = lerp(170, tx, e), y = lerp(330, ty, e) - Math.sin(k * Math.PI) * 60;
      const sc = lerp(3.6, 1.7, Math.pow(k, .7));
      dart(ctx, x, y, sc, (1 - k) * .4 - .15, 0);
    } else {
      // воткнулся (при промахе — в стену рядом с мишенью) и дрожит
      const s = t - tHit; const wob = Math.sin(s * 40) * Math.exp(-s * 7) * .22;
      dart(ctx, tx + (miss ? 0 : shake * 1.2), ty, 1.7, -.2 + wob, 1);
    }
  }
  function dart(ctx, x, y, sc, ang, stuck) {
    ctx.save(); ctx.translate(x, y); ctx.rotate(ang); ctx.scale(sc, sc);
    // вид немного сбоку: игла впереди (вверх), оперение сзади (вниз)
    if (stuck) { ctx.fillStyle = 'rgba(0,0,0,.35)'; ctx.beginPath(); ctx.ellipse(6, 26, 4, 14, -.2, 0, TAU); ctx.fill(); }
    ctx.strokeStyle = '#c9ccd4'; ctx.lineWidth = 1.6; ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(0, 8); ctx.stroke();
    const bg = ctx.createLinearGradient(-3, 0, 3, 0); bg.addColorStop(0, '#6b7280'); bg.addColorStop(.5, '#e5e7eb'); bg.addColorStop(1, '#4b5563');
    ctx.fillStyle = bg; rrect(ctx, -3, 8, 6, 20, 2.5); ctx.fill();
    ctx.strokeStyle = 'rgba(0,0,0,.35)'; ctx.lineWidth = .6; for (let i = 0; i < 5; i++) { ctx.beginPath(); ctx.moveTo(-3, 11 + i * 3.6); ctx.lineTo(3, 11 + i * 3.6); ctx.stroke(); }
    ctx.fillStyle = '#374151'; ctx.fillRect(-1.2, 28, 2.4, 10);
    ctx.fillStyle = '#7c5cff'; ctx.beginPath(); ctx.moveTo(0, 34); ctx.lineTo(-10, 50); ctx.lineTo(-2, 46); ctx.closePath(); ctx.fill();
    ctx.fillStyle = '#22c1ff'; ctx.beginPath(); ctx.moveTo(0, 34); ctx.lineTo(10, 50); ctx.lineTo(2, 46); ctx.closePath(); ctx.fill();
    ctx.restore();
  }

  // ---------- общее API ----------
  const SCENES = { dice: [drawDice, DICE_T], coin: [drawCoin, COIN_T], basket: [drawBasket, BASKET_T], football: [drawFoot, FOOT_T], darts: [drawDarts, DART_T] };
  function setup(cv) {
    const dpr = Math.min(3, (root.devicePixelRatio || 1));
    const css = cv.clientWidth || cv.width || 160;
    const px = Math.round(css * dpr);
    if (cv.width !== px) { cv.width = px; cv.height = px; }
    const ctx = cv.getContext('2d');
    ctx.__dpr = px / W;
    return ctx;
  }
  function frame(cv, kind, v, t) {
    const sc = SCENES[kind] || SCENES.dice; const ctx = setup(cv);
    ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.clearRect(0, 0, cv.width, cv.height);
    ctx.setTransform(ctx.__dpr, 0, 0, ctx.__dpr, 0, 0);
    sc[0](ctx, v, Math.min(t, sc[1]));
  }
  const api = {
    duration: (k, v) => k === 'basket' && v ? basket(v).end : (SCENES[k] || SCENES.dice)[1],
    /** нарисовать финальный кадр (результат уже известен) */
    final(cv, kind, v) { frame(cv, kind, v, 99); },
    /** проиграть анимацию; onEnd вызовется по окончании; onHit — в момент удара/приземления (для вибрации) */
    play(cv, kind, v, onEnd, onHit) {
      const D = api.duration(kind, v); let st = null, stop = false;
      const hitAt = { dice: .62, coin: 1.08, basket: 1.1, football: 1.35, darts: .76 }[kind] || 1;
      let hitDone = false;
      const step = ts => {
        if (stop) return; if (st == null) st = ts;
        const t = (ts - st) / 1000;
        frame(cv, kind, v, t);
        if (!hitDone && t >= hitAt) { hitDone = true; onHit && onHit(); }
        if (t < D) root.requestAnimationFrame(step); else onEnd && onEnd();
      };
      root.requestAnimationFrame(step);
      return () => { stop = true; };
    },
    frame,
    _sim: { basket: simBasket, BB, BB_SHOTS }
  };
  root.LumoThrows = api;
  if (typeof module !== 'undefined') module.exports = api;
})(typeof window !== 'undefined' ? window : globalThis);
(function(){
  const st=document.createElement('style');
  st.textContent='.lgcv{width:150px!important;height:150px!important;display:block;margin:2px auto 0}.lgres.lgwait{opacity:0}.lgres{transition:opacity .25s}';
  document.head.appendChild(st);
  const started=new Map();
  function handle(cv){
    if(cv.dataset.done) return; cv.dataset.done=1;
    const k=cv.dataset.k, v=+cv.dataset.v, id=cv.dataset.id, res=cv.nextElementSibling;
    const show=()=>{ if(res) res.classList.remove('lgwait'); };
    if(cv.dataset.fresh&&!started.has(id)) started.set(id,performance.now());
    const t0=started.get(id), D=LumoThrows.duration(k,v);
    if(t0==null||(performance.now()-t0)/1000>=D){ LumoThrows.final(cv,k,v); show(); return; }
    if(res) res.classList.add('lgwait');
    let hit=false; const hitAt={dice:.62,coin:1.08,basket:1.1,football:1.35,darts:.76}[k]||1;
    const step=()=>{ if(!cv.isConnected) return; const t=(performance.now()-t0)/1000; LumoThrows.frame(cv,k,v,t);
      if(!hit&&t>=hitAt){ hit=true; try{ navigator.vibrate&&navigator.vibrate(18); }catch(e){} }
      if(t<D) requestAnimationFrame(step); else show(); };
    requestAnimationFrame(step);
  }
  const scan=()=>document.querySelectorAll('canvas.lgcv:not([data-done])').forEach(handle);
  new MutationObserver(scan).observe(document.body,{childList:true,subtree:true}); scan();
})();

/* ===== Игры вдвоём: страница игр берётся с сервера (lm_games_html), встроенная — запасная ===== */
(function(){ let t=0; const load=()=>{ if(Date.now()-t<300000) return; t=Date.now();
  try{ sb.rpc('lm_games_html').then(r=>{ const h=r&&r.data&&r.data.html; if(typeof h==='string'&&h.indexOf('/*CFG*/')>=0) window.__lgHtml=h; }).catch(()=>{}); }catch(e){} };
  setTimeout(load,4000); document.addEventListener('click',e=>{ if(e.target.closest&&e.target.closest('[data-lgopen],[data-th]')) load(); },true); })();

/* ===== Эмодзи-статусы: нарисованные значки с анимацией (исходник web/status/gen.py) ===== */
window.LSTAT={"fire": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-fire\"><style>.lsf-o{transform-origin:50px 92px;animation:lsf-o 1s ease-in-out infinite}@keyframes lsf-o{0%,100%{transform:scale(1,1) skewX(0)}25%{transform:scale(.95,1.06) skewX(-3deg)}50%{transform:scale(1.04,.96) skewX(1.5deg)}75%{transform:scale(.97,1.04) skewX(3deg)}}.lsf-i{transform-origin:50px 92px;animation:lsf-i .5s ease-in-out infinite}@keyframes lsf-i{0%,100%{transform:scale(1,1)}50%{transform:scale(.9,1.1) skewX(-4deg)}}.lsf-c{transform-origin:50px 84px;animation:lsf-c .5s ease-in-out infinite}@keyframes lsf-c{0%,100%{transform:scale(1)}50%{transform:scale(1.18,.9)}}.lsf-g{transform-origin:50px 70px;animation:lsf-g 1s ease-in-out infinite}@keyframes lsf-g{0%,100%{opacity:.7;transform:scale(1)}50%{opacity:1;transform:scale(1.1)}}.lsf-s{animation:lsf-s 1s linear infinite;opacity:0}@keyframes lsf-s{0%{transform:translate(0,0) scale(1);opacity:0}15%{opacity:1}100%{transform:translate(var(--dx),-46px) scale(.2);opacity:0}}</style><defs><linearGradient id=\"ls_f1\" x1=\"0\" y1=\"1\" x2=\"0\" y2=\"0\"><stop offset=\"0\" stop-color=\"#ffd23f\"/><stop offset=\"0.45\" stop-color=\"#ff7a1a\"/><stop offset=\"1\" stop-color=\"#e0211b\"/></linearGradient><linearGradient id=\"ls_f2\" x1=\"0\" y1=\"1\" x2=\"0\" y2=\"0\"><stop offset=\"0\" stop-color=\"#fff7c2\"/><stop offset=\"0.5\" stop-color=\"#ffd43b\"/><stop offset=\"1\" stop-color=\"#ff9a1f\"/></linearGradient><radialGradient id=\"ls_f3\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ffffff\"/><stop offset=\"0.6\" stop-color=\"#fff3a6\"/><stop offset=\"1\" stop-color=\"#ffd43b\" stop-opacity=\"0\"/></radialGradient><radialGradient id=\"ls_f4\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ff8a1f\" stop-opacity=\"0.55\"/><stop offset=\"1\" stop-color=\"#ff8a1f\" stop-opacity=\"0\"/></radialGradient></defs><ellipse class=\"lsf-g\" cx=\"50\" cy=\"66\" rx=\"44\" ry=\"40\" fill=\"url(#ls_f4)\"/><g class=\"lsf-o\"><path d=\"M50 5 C57 22 78 34 78 59 C78 79 65 93 50 93 C35 93 22 79 22 59 C22 47 28 38 35 30 C36 40 41 45 46 45 C41 31 43 16 50 5Z\" fill=\"url(#ls_f1)\"/></g><g class=\"lsf-i\"><path d=\"M51 42 C55 53 66 60 66 73 C66 85 58 92 50 92 C42 92 34 85 34 73 C34 65 39 60 43 54 C44 61 47 63 50 63 C47 56 48 49 51 42Z\" fill=\"url(#ls_f2)\"/></g><ellipse class=\"lsf-c\" cx=\"50\" cy=\"82\" rx=\"9\" ry=\"10\" fill=\"url(#ls_f3)\"/><circle class=\"lsf-s\" style=\"--dx:-8px\" cx=\"33\" cy=\"40\" r=\"2.6\" fill=\"#ffd23f\"/><circle class=\"lsf-s\" style=\"--dx:7px;animation-delay:-.4s\" cx=\"68\" cy=\"44\" r=\"2.2\" fill=\"#ff9a1f\"/><circle class=\"lsf-s\" style=\"--dx:3px;animation-delay:-.7s\" cx=\"56\" cy=\"24\" r=\"1.8\" fill=\"#fff3a6\"/></svg>", "heart": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-heart\"><style>.lsh-b{transform-origin:50px 52px;animation:lsh-b 1s cubic-bezier(.4,0,.2,1) infinite}@keyframes lsh-b{0%,100%{transform:scale(1)}12%{transform:scale(1.14)}26%{transform:scale(.98)}38%{transform:scale(1.08)}55%{transform:scale(1)}}.lsh-g{transform-origin:50px 50px;animation:lsh-g 1s ease-out infinite}@keyframes lsh-g{0%{transform:scale(.7);opacity:.9}60%,100%{transform:scale(1.25);opacity:0}}.lsh-tw{animation:lsh-tw 1s ease-in-out infinite}@keyframes lsh-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><radialGradient id=\"ls_h1\" cx=\"0.36\" cy=\"0.3\" r=\"0.8\"><stop offset=\"0\" stop-color=\"#ff9db0\"/><stop offset=\"0.35\" stop-color=\"#ff3b62\"/><stop offset=\"0.8\" stop-color=\"#e01245\"/><stop offset=\"1\" stop-color=\"#a80a33\"/></radialGradient><linearGradient id=\"ls_h2\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#ffffff\" stop-opacity=\"0.75\"/><stop offset=\"1\" stop-color=\"#ffffff\" stop-opacity=\"0\"/></linearGradient><radialGradient id=\"ls_h3\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ff2d55\" stop-opacity=\"0.5\"/><stop offset=\"1\" stop-color=\"#ff2d55\" stop-opacity=\"0\"/></radialGradient><clipPath id=\"ls_hc\"><path d=\"M50 89 C19 67 7 51 7 33 C7 19 18 9 31 9 C39 9 46 13 50 21 C54 13 61 9 69 9 C82 9 93 19 93 33 C93 51 81 67 50 89Z\"/></clipPath></defs><circle class=\"lsh-g\" cx=\"50\" cy=\"50\" r=\"46\" fill=\"url(#ls_h3)\"/><g class=\"lsh-b\"><path d=\"M50 89 C19 67 7 51 7 33 C7 19 18 9 31 9 C39 9 46 13 50 21 C54 13 61 9 69 9 C82 9 93 19 93 33 C93 51 81 67 50 89Z\" fill=\"url(#ls_h1)\"/><g clip-path=\"url(#ls_hc)\"><ellipse cx=\"50\" cy=\"96\" rx=\"52\" ry=\"26\" fill=\"#7a0626\" opacity=\".35\"/><ellipse cx=\"29\" cy=\"27\" rx=\"15\" ry=\"10\" transform=\"rotate(-32 29 27)\" fill=\"url(#ls_h2)\"/><ellipse cx=\"70\" cy=\"22\" rx=\"8\" ry=\"4.5\" transform=\"rotate(24 70 22)\" fill=\"#fff\" opacity=\".28\"/></g></g><path class=\"lsh-tw\" style=\"transform-origin:84px 14px;\" d=\"M84 7 C85.54 12.46 85.54 12.46 91 14 C85.54 15.54 85.54 15.54 84 21 C82.46 15.54 82.46 15.54 77 14 C82.46 12.46 82.46 12.46 84 7Z\" fill=\"#fff\"/><path class=\"lsh-tw\" style=\"transform-origin:14px 70px;animation-delay:-.5s\" d=\"M14 65 C15.1 68.9 15.1 68.9 19 70 C15.1 71.1 15.1 71.1 14 75 C12.9 71.1 12.9 71.1 9 70 C12.9 68.9 12.9 68.9 14 65Z\" fill=\"#fff\"/></svg>", "star": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-star\"><style>.lss-b{transform-origin:50px 53px;animation:lss-b 2s ease-in-out infinite}@keyframes lss-b{0%,100%{transform:rotate(-7deg) scale(1)}50%{transform:rotate(7deg) scale(1.07)}}.lss-g{transform-origin:50px 53px;animation:lss-g 1s ease-in-out infinite}@keyframes lss-g{0%,100%{transform:scale(.9);opacity:.6}50%{transform:scale(1.12);opacity:1}}.lss-w{animation:lss-w 2s ease-in-out infinite}@keyframes lss-w{0%,35%{transform:translateX(-80px)}75%,100%{transform:translateX(80px)}}.lss-tw{animation:lss-tw 1s ease-in-out infinite}@keyframes lss-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><linearGradient id=\"ls_s1\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#ffe680\"/><stop offset=\"1\" stop-color=\"#f29a0b\"/></linearGradient><radialGradient id=\"ls_s2\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ffd23f\" stop-opacity=\"0.6\"/><stop offset=\"1\" stop-color=\"#ffd23f\" stop-opacity=\"0\"/></radialGradient><linearGradient id=\"ls_s3\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0\" stop-color=\"#fff\" stop-opacity=\"0\"/><stop offset=\"0.5\" stop-color=\"#fff\" stop-opacity=\"0.85\"/><stop offset=\"1\" stop-color=\"#fff\" stop-opacity=\"0\"/></linearGradient><clipPath id=\"ls_sc\"><path d=\"M50.0 10.0 L61.2 37.6 L90.9 39.7 L68.1 58.9 L75.3 87.8 L50.0 72.0 L24.7 87.8 L31.9 58.9 L9.1 39.7 L38.8 37.6Z\"/></clipPath></defs><circle class=\"lss-g\" cx=\"50\" cy=\"53\" r=\"48\" fill=\"url(#ls_s2)\"/><g class=\"lss-b\"><path d=\"M50.0 10.0 L61.2 37.6 L90.9 39.7 L68.1 58.9 L75.3 87.8 L50.0 72.0 L24.7 87.8 L31.9 58.9 L9.1 39.7 L38.8 37.6Z\" fill=\"url(#ls_s1)\" stroke=\"url(#ls_s1)\" stroke-width=\"7\" stroke-linejoin=\"round\"/><g clip-path=\"url(#ls_sc)\"><path d=\"M50 53 L50.0 10.0 L61.2 37.6Z\" fill=\"#fff4b8\"/><path d=\"M50 53 L61.2 37.6 L90.9 39.7Z\" fill=\"#ffd84a\"/><path d=\"M50 53 L90.9 39.7 L68.1 58.9Z\" fill=\"#ffbf1f\"/><path d=\"M50 53 L68.1 58.9 L75.3 87.8Z\" fill=\"#f29a0b\"/><path d=\"M50 53 L75.3 87.8 L50.0 72.0Z\" fill=\"#ffcf3a\"/><path d=\"M50 53 L50.0 72.0 L24.7 87.8Z\" fill=\"#ffe680\"/><path d=\"M50 53 L24.7 87.8 L31.9 58.9Z\" fill=\"#ffc22e\"/><path d=\"M50 53 L31.9 58.9 L9.1 39.7Z\" fill=\"#e88d07\"/><path d=\"M50 53 L9.1 39.7 L38.8 37.6Z\" fill=\"#ffb81a\"/><path d=\"M50 53 L38.8 37.6 L50.0 10.0Z\" fill=\"#ffe98f\"/><g class=\"lss-w\"><polygon points=\"38,0 54,0 44,100 28,100\" fill=\"url(#ls_s3)\"/></g></g><path d=\"M50.0 10.0 L61.2 37.6 L90.9 39.7 L68.1 58.9 L75.3 87.8 L50.0 72.0 L24.7 87.8 L31.9 58.9 L9.1 39.7 L38.8 37.6Z\" fill=\"none\" stroke=\"#fff6c9\" stroke-width=\"1.2\" stroke-linejoin=\"round\" opacity=\".7\"/></g><path class=\"lss-tw\" style=\"transform-origin:86px 18px;\" d=\"M86 10 C87.76 16.24 87.76 16.24 94 18 C87.76 19.76 87.76 19.76 86 26 C84.24 19.76 84.24 19.76 78 18 C84.24 16.24 84.24 16.24 86 10Z\" fill=\"#fff\"/><path class=\"lss-tw\" style=\"transform-origin:13px 30px;animation-delay:-.35s\" d=\"M13 24.5 C14.21 28.79 14.21 28.79 18.5 30 C14.21 31.21 14.21 31.21 13 35.5 C11.79 31.21 11.79 31.21 7.5 30 C11.79 28.79 11.79 28.79 13 24.5Z\" fill=\"#fff\"/><path class=\"lss-tw\" style=\"transform-origin:80px 84px;animation-delay:-.7s\" d=\"M80 79 C81.1 82.9 81.1 82.9 85 84 C81.1 85.1 81.1 85.1 80 89 C78.9 85.1 78.9 85.1 75 84 C78.9 82.9 78.9 82.9 80 79Z\" fill=\"#fff\"/></svg>", "rocket": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-rocket\"><style>.lsr-b{transform-origin:50px 50px;animation:lsr-b .5s ease-in-out infinite}@keyframes lsr-b{0%,100%{transform:rotate(45deg) scale(.88) translate(0,0)}50%{transform:rotate(45deg) scale(.88) translate(1px,-2px)}}.lsr-f{transform-origin:50px 78px;animation:lsr-f .25s ease-in-out infinite}@keyframes lsr-f{0%,100%{transform:scale(1,1)}50%{transform:scale(.82,1.22)}}.lsr-f2{transform-origin:50px 78px;animation:lsr-f .25s ease-in-out -.12s infinite}.lsr-l{animation:lsr-l .5s linear infinite}@keyframes lsr-l{0%{transform:translate(26px,-26px);opacity:0}20%{opacity:.9}100%{transform:translate(-26px,26px);opacity:0}}</style><defs><linearGradient id=\"ls_r1\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0\" stop-color=\"#c9d3e6\"/><stop offset=\"0.35\" stop-color=\"#ffffff\"/><stop offset=\"0.7\" stop-color=\"#eef2f8\"/><stop offset=\"1\" stop-color=\"#9aa7c2\"/></linearGradient><linearGradient id=\"ls_r2\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0\" stop-color=\"#ff6b6b\"/><stop offset=\"1\" stop-color=\"#c9182e\"/></linearGradient><radialGradient id=\"ls_r3\" cx=\"0.4\" cy=\"0.35\" r=\"0.7\"><stop offset=\"0\" stop-color=\"#bff0ff\"/><stop offset=\"0.6\" stop-color=\"#3aa7ff\"/><stop offset=\"1\" stop-color=\"#1456c8\"/></radialGradient><linearGradient id=\"ls_r4\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#fff7c2\"/><stop offset=\"0.4\" stop-color=\"#ffc531\"/><stop offset=\"1\" stop-color=\"#ff5a1f\" stop-opacity=\"0\"/></linearGradient><linearGradient id=\"ls_r5\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#ffffff\"/><stop offset=\"1\" stop-color=\"#8fe3ff\" stop-opacity=\"0\"/></linearGradient></defs><path class=\"lsr-l\" d=\"M84 30 l-12 12\" stroke=\"#fff\" stroke-width=\"2.4\" stroke-linecap=\"round\" opacity=\".8\"/><path class=\"lsr-l\" style=\"animation-delay:-.2s\" d=\"M70 86 l-9 9\" stroke=\"#bfe3ff\" stroke-width=\"2\" stroke-linecap=\"round\"/><path class=\"lsr-l\" style=\"animation-delay:-.35s\" d=\"M26 16 l-8 8\" stroke=\"#fff\" stroke-width=\"1.8\" stroke-linecap=\"round\"/><g class=\"lsr-b\"><path class=\"lsr-f\" d=\"M41 76 C41 90 46 100 50 108 C54 100 59 90 59 76Z\" fill=\"url(#ls_r4)\"/><path class=\"lsr-f2\" d=\"M45 76 C45 86 48 93 50 98 C52 93 55 86 55 76Z\" fill=\"url(#ls_r5)\"/><path d=\"M34 58 L22 76 L24 82 L38 74Z\" fill=\"url(#ls_r2)\"/><path d=\"M66 58 L78 76 L76 82 L62 74Z\" fill=\"url(#ls_r2)\"/><path d=\"M50 4 C64 16 68 38 66 58 L62 78 L38 78 L34 58 C32 38 36 16 50 4Z\" fill=\"url(#ls_r1)\"/><path d=\"M50 4 C57 10 61.5 18 64 27 C55 23 45 23 36 27 C38.5 18 43 10 50 4Z\" fill=\"url(#ls_r2)\"/><path d=\"M47 60 L50 86 L53 60Z\" fill=\"url(#ls_r2)\"/><circle cx=\"50\" cy=\"42\" r=\"10.5\" fill=\"#5a6a8c\"/><circle cx=\"50\" cy=\"42\" r=\"8\" fill=\"url(#ls_r3)\"/><path d=\"M44.5 39 a6.5 6.5 0 0 1 7 -4.5\" stroke=\"#fff\" stroke-width=\"1.8\" fill=\"none\" stroke-linecap=\"round\" opacity=\".85\"/><rect x=\"38\" y=\"74\" width=\"24\" height=\"5\" rx=\"2\" fill=\"#5a6a8c\"/><path d=\"M41 14 C38 24 37 40 38 56\" stroke=\"#fff\" stroke-width=\"2.4\" fill=\"none\" stroke-linecap=\"round\" opacity=\".55\"/></g></svg>", "crown": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-crown\"><style>.lsc-b{transform-origin:50px 60px;animation:lsc-b 2s ease-in-out infinite}@keyframes lsc-b{0%,100%{transform:translateY(1.5px) rotate(-3deg)}50%{transform:translateY(-2.5px) rotate(3deg)}}.lsc-w{animation:lsc-w 2s ease-in-out infinite}@keyframes lsc-w{0%,30%{transform:translateX(-95px)}70%,100%{transform:translateX(95px)}}.lsc-j{animation:lsc-j 1s ease-in-out infinite}@keyframes lsc-j{0%,100%{filter:brightness(1)}50%{filter:brightness(1.35)}}.lsc-tw{animation:lsc-tw 1s ease-in-out infinite}@keyframes lsc-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><linearGradient id=\"ls_c1\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#fff3b0\"/><stop offset=\"0.35\" stop-color=\"#ffd43b\"/><stop offset=\"0.75\" stop-color=\"#f2a007\"/><stop offset=\"1\" stop-color=\"#b96f00\"/></linearGradient><linearGradient id=\"ls_c2\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#ffe680\"/><stop offset=\"0.5\" stop-color=\"#f2a007\"/><stop offset=\"1\" stop-color=\"#a05e00\"/></linearGradient><radialGradient id=\"ls_c3\" cx=\"0.35\" cy=\"0.3\" r=\"0.75\"><stop offset=\"0\" stop-color=\"#ffd0e1\"/><stop offset=\"0.5\" stop-color=\"#ff3b7a\"/><stop offset=\"1\" stop-color=\"#a3073f\"/></radialGradient><radialGradient id=\"ls_c4\" cx=\"0.35\" cy=\"0.3\" r=\"0.75\"><stop offset=\"0\" stop-color=\"#d6f4ff\"/><stop offset=\"0.5\" stop-color=\"#33b6ff\"/><stop offset=\"1\" stop-color=\"#0b5fb8\"/></radialGradient><linearGradient id=\"ls_c5\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0\" stop-color=\"#fff\" stop-opacity=\"0\"/><stop offset=\"0.5\" stop-color=\"#fff\" stop-opacity=\"0.9\"/><stop offset=\"1\" stop-color=\"#fff\" stop-opacity=\"0\"/></linearGradient><clipPath id=\"ls_cc\"><path d=\"M14 74 L8 30 L30 47 L41 16 L50 40 L59 16 L70 47 L92 30 L86 74Z\"/><rect x=\"11\" y=\"72\" width=\"78\" height=\"16\" rx=\"5\"/></clipPath></defs><g class=\"lsc-b\"><path d=\"M14 74 L8 30 L30 47 L41 16 L50 40 L59 16 L70 47 L92 30 L86 74Z\" fill=\"url(#ls_c1)\" stroke=\"url(#ls_c1)\" stroke-width=\"5\" stroke-linejoin=\"round\"/><path d=\"M14 74 L8 30 L20 39 L24 74Z\" fill=\"#fff\" opacity=\".22\"/><path d=\"M41 16 L50 40 L46 44 L37 28Z\" fill=\"#fff\" opacity=\".28\"/><path d=\"M70 47 L92 30 L86 74 L76 74Z\" fill=\"#8a4d00\" opacity=\".22\"/><rect x=\"11\" y=\"72\" width=\"78\" height=\"16\" rx=\"5\" fill=\"url(#ls_c2)\"/><rect x=\"13\" y=\"74\" width=\"74\" height=\"4\" rx=\"2\" fill=\"#fff\" opacity=\".4\"/><g clip-path=\"url(#ls_cc)\"><g class=\"lsc-w\"><polygon points=\"40,0 58,0 46,100 28,100\" fill=\"url(#ls_c5)\"/></g></g><circle cx=\"8\" cy=\"29\" r=\"6\" fill=\"url(#ls_c1)\"/><circle cx=\"92\" cy=\"29\" r=\"6\" fill=\"url(#ls_c1)\"/><circle cx=\"41\" cy=\"15\" r=\"6\" fill=\"url(#ls_c1)\"/><circle cx=\"59\" cy=\"15\" r=\"6\" fill=\"url(#ls_c1)\"/><circle cx=\"6.5\" cy=\"27\" r=\"2\" fill=\"#fff\" opacity=\".7\"/><circle cx=\"39.5\" cy=\"13\" r=\"2\" fill=\"#fff\" opacity=\".7\"/><circle cx=\"57.5\" cy=\"13\" r=\"2\" fill=\"#fff\" opacity=\".7\"/><circle cx=\"90.5\" cy=\"27\" r=\"2\" fill=\"#fff\" opacity=\".7\"/><g class=\"lsc-j\"><path d=\"M50 50 L59 60 L50 70 L41 60Z\" fill=\"url(#ls_c3)\"/><path d=\"M50 50 L59 60 L50 60Z\" fill=\"#fff\" opacity=\".35\"/></g><g class=\"lsc-j\" style=\"animation-delay:-.5s\"><circle cx=\"26\" cy=\"62\" r=\"5.5\" fill=\"url(#ls_c4)\"/><circle cx=\"74\" cy=\"62\" r=\"5.5\" fill=\"url(#ls_c4)\"/><circle cx=\"24.5\" cy=\"60.5\" r=\"1.6\" fill=\"#fff\" opacity=\".8\"/><circle cx=\"72.5\" cy=\"60.5\" r=\"1.6\" fill=\"#fff\" opacity=\".8\"/></g><circle cx=\"30\" cy=\"80\" r=\"3\" fill=\"url(#ls_c3)\"/><circle cx=\"50\" cy=\"80\" r=\"3\" fill=\"url(#ls_c4)\"/><circle cx=\"70\" cy=\"80\" r=\"3\" fill=\"url(#ls_c3)\"/></g><path class=\"lsc-tw\" style=\"transform-origin:88px 10px;\" d=\"M88 3 C89.54 8.46 89.54 8.46 95 10 C89.54 11.54 89.54 11.54 88 17 C86.46 11.54 86.46 11.54 81 10 C86.46 8.46 86.46 8.46 88 3Z\" fill=\"#fff\"/><path class=\"lsc-tw\" style=\"transform-origin:12px 12px;animation-delay:-.5s\" d=\"M12 7 C13.1 10.9 13.1 10.9 17 12 C13.1 13.1 13.1 13.1 12 17 C10.9 13.1 10.9 13.1 7 12 C10.9 10.9 10.9 10.9 12 7Z\" fill=\"#fff\"/></svg>", "gem": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-gem\"><style>.lsg-b{transform-origin:50px 52px;animation:lsg-b 2s ease-in-out infinite}@keyframes lsg-b{0%,100%{transform:translateY(1.5px) rotate(-4deg)}50%{transform:translateY(-2.5px) rotate(4deg)}}.lsg-w{animation:lsg-w 2s ease-in-out infinite}@keyframes lsg-w{0%,25%{transform:translateX(-95px)}65%,100%{transform:translateX(95px)}}.lsg-g{transform-origin:50px 52px;animation:lsg-g 1s ease-in-out infinite}@keyframes lsg-g{0%,100%{opacity:.55;transform:scale(.95)}50%{opacity:1;transform:scale(1.1)}}.lsg-f{animation:lsg-f 1s ease-in-out infinite}@keyframes lsg-f{0%,100%{opacity:0}50%{opacity:.5}}.lsg-tw{animation:lsg-tw 1s ease-in-out infinite}@keyframes lsg-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><linearGradient id=\"ls_g5\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0\" stop-color=\"#fff\" stop-opacity=\"0\"/><stop offset=\"0.5\" stop-color=\"#fff\" stop-opacity=\"0.9\"/><stop offset=\"1\" stop-color=\"#fff\" stop-opacity=\"0\"/></linearGradient><radialGradient id=\"ls_g6\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#4cc9ff\" stop-opacity=\"0.55\"/><stop offset=\"1\" stop-color=\"#4cc9ff\" stop-opacity=\"0\"/></radialGradient><clipPath id=\"ls_gc\"><path d=\"M26 14 L74 14 L94 40 L50 92 L6 40Z\"/></clipPath></defs><circle class=\"lsg-g\" cx=\"50\" cy=\"52\" r=\"48\" fill=\"url(#ls_g6)\"/><g class=\"lsg-b\"><path d=\"M26 14 L74 14 L94 40 L50 92 L6 40Z\" fill=\"#1e7fe0\" stroke=\"#1e7fe0\" stroke-width=\"4\" stroke-linejoin=\"round\"/><path d=\"M26 14 L38 40 L6 40Z\" fill=\"#7fd8ff\"/><path d=\"M26 14 L50 14 L38 40Z\" fill=\"#c8f1ff\"/><path d=\"M50 14 L62 40 L38 40Z\" fill=\"#8fe0ff\"/><path d=\"M50 14 L74 14 L62 40Z\" fill=\"#5cc4ff\"/><path d=\"M74 14 L94 40 L62 40Z\" fill=\"#2f9df2\"/><path d=\"M6 40 L38 40 L50 92Z\" fill=\"#3fb0ff\"/><path d=\"M38 40 L62 40 L50 92Z\" fill=\"#6fd0ff\"/><path d=\"M62 40 L94 40 L50 92Z\" fill=\"#1669c9\"/><path class=\"lsg-f\" d=\"M38 40 L62 40 L50 92Z\" fill=\"#fff\"/><path class=\"lsg-f\" style=\"animation-delay:-.5s\" d=\"M26 14 L38 40 L6 40Z\" fill=\"#fff\"/><g clip-path=\"url(#ls_gc)\"><g class=\"lsg-w\"><polygon points=\"40,0 56,0 44,100 28,100\" fill=\"url(#ls_g5)\"/></g></g><path d=\"M26 14 L74 14 L94 40 L6 40Z M38 40 L26 14 M62 40 L74 14 M38 40 L50 14 L62 40 M38 40 L50 92 L62 40\" fill=\"none\" stroke=\"#e9fbff\" stroke-width=\"1\" stroke-linejoin=\"round\" opacity=\".7\"/></g><path class=\"lsg-tw\" style=\"transform-origin:88px 14px;\" d=\"M88 6 C89.76 12.24 89.76 12.24 96 14 C89.76 15.76 89.76 15.76 88 22 C86.24 15.76 86.24 15.76 80 14 C86.24 12.24 86.24 12.24 88 6Z\" fill=\"#fff\"/><path class=\"lsg-tw\" style=\"transform-origin:12px 20px;animation-delay:-.4s\" d=\"M12 14.5 C13.21 18.79 13.21 18.79 17.5 20 C13.21 21.21 13.21 21.21 12 25.5 C10.79 21.21 10.79 21.21 6.5 20 C10.79 18.79 10.79 18.79 12 14.5Z\" fill=\"#fff\"/><path class=\"lsg-tw\" style=\"transform-origin:80px 80px;animation-delay:-.75s\" d=\"M80 75 C81.1 78.9 81.1 78.9 85 80 C81.1 81.1 81.1 81.1 80 85 C78.9 81.1 78.9 81.1 75 80 C78.9 78.9 78.9 78.9 80 75Z\" fill=\"#fff\"/></svg>", "bolt": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-bolt\"><style>.lsb-b{transform-origin:50px 50px;animation:lsb-b 1s linear infinite}@keyframes lsb-b{0%,100%{transform:translate(0,0) scale(1)}6%{transform:translate(-1.5px,1px) scale(1.06)}12%{transform:translate(1.5px,-1px) scale(1.03)}18%{transform:translate(-.8px,.5px) scale(1.05)}26%{transform:translate(0,0) scale(1)}}.lsb-g{transform-origin:50px 50px;animation:lsb-g 1s ease-out infinite}@keyframes lsb-g{0%{opacity:.2;transform:scale(.8)}8%{opacity:1;transform:scale(1.2)}40%,100%{opacity:.3;transform:scale(.9)}}.lsb-f{animation:lsb-f 1s ease-out infinite}@keyframes lsb-f{0%{opacity:0}6%{opacity:.95}30%,100%{opacity:0}}.lsb-z{stroke-dasharray:26;animation:lsb-z 1s linear infinite}@keyframes lsb-z{0%{stroke-dashoffset:26;opacity:0}10%{opacity:1}45%{stroke-dashoffset:-26;opacity:0}100%{stroke-dashoffset:-26;opacity:0}}</style><defs><linearGradient id=\"ls_b1\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#fff7b0\"/><stop offset=\"0.4\" stop-color=\"#ffd60a\"/><stop offset=\"1\" stop-color=\"#ff9500\"/></linearGradient><radialGradient id=\"ls_b2\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ffe45c\" stop-opacity=\"0.7\"/><stop offset=\"1\" stop-color=\"#ffe45c\" stop-opacity=\"0\"/></radialGradient><clipPath id=\"ls_bc\"><path d=\"M60 4 L20 56 L44 56 L36 96 L82 40 L56 40Z\"/></clipPath></defs><circle class=\"lsb-g\" cx=\"50\" cy=\"50\" r=\"48\" fill=\"url(#ls_b2)\"/><path class=\"lsb-z\" d=\"M14 26 l6 6 l-4 4 l7 7\" stroke=\"#fff7b0\" stroke-width=\"2.4\" fill=\"none\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/><path class=\"lsb-z\" style=\"animation-delay:-.15s\" d=\"M90 62 l-6 5 l4 4 l-7 6\" stroke=\"#fff7b0\" stroke-width=\"2.4\" fill=\"none\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/><g class=\"lsb-b\"><path d=\"M60 4 L20 56 L44 56 L36 96 L82 40 L56 40Z\" fill=\"url(#ls_b1)\" stroke=\"url(#ls_b1)\" stroke-width=\"5\" stroke-linejoin=\"round\"/><g clip-path=\"url(#ls_bc)\"><path d=\"M60 4 L20 56 L30 56 L62 14Z\" fill=\"#fff\" opacity=\".45\"/><path d=\"M82 40 L36 96 L44 70 L70 40Z\" fill=\"#c25e00\" opacity=\".25\"/></g><path class=\"lsb-f\" d=\"M60 4 L20 56 L44 56 L36 96 L82 40 L56 40Z\" fill=\"#fff\" stroke=\"#fff\" stroke-width=\"5\" stroke-linejoin=\"round\"/></g></svg>", "ghost": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-ghost\"><style>.lsgh-b{transform-origin:50px 50px;animation:lsgh-b 2s ease-in-out infinite}@keyframes lsgh-b{0%,100%{transform:translateY(3px) rotate(-4deg)}50%{transform:translateY(-5px) rotate(4deg)}}.lsgh-e{transform-origin:50px 42px;animation:lsgh-e 2s linear infinite}@keyframes lsgh-e{0%,44%,52%,100%{transform:scaleY(1)}48%{transform:scaleY(.1)}}.lsgh-s{transform-origin:50px 95px;animation:lsgh-s 2s ease-in-out infinite}@keyframes lsgh-s{0%,100%{transform:scale(1.05);opacity:.3}50%{transform:scale(.75);opacity:.16}}.lsgh-g{transform-origin:50px 50px;animation:lsgh-g 2s ease-in-out infinite}@keyframes lsgh-g{0%,100%{opacity:.5}50%{opacity:1}}</style><defs><linearGradient id=\"ls_gh1\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#ffffff\"/><stop offset=\"0.6\" stop-color=\"#eef1fb\"/><stop offset=\"1\" stop-color=\"#c3c9e6\"/></linearGradient><radialGradient id=\"ls_gh2\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#b9a6ff\" stop-opacity=\"0.5\"/><stop offset=\"1\" stop-color=\"#b9a6ff\" stop-opacity=\"0\"/></radialGradient><clipPath id=\"ls_ghc\"><path d=\"M50 8 C28 8 16 26 16 46 L16 84 C16 90 21 91 25 87 L32 80 L40 89 C42 91 44 91 46 89 L50 84 L54 89 C56 91 58 91 60 89 L68 80 L75 87 C79 91 84 90 84 84 L84 46 C84 26 72 8 50 8Z\"/></clipPath></defs><ellipse class=\"lsgh-s\" cx=\"50\" cy=\"95\" rx=\"26\" ry=\"4\" fill=\"#000\"/><circle class=\"lsgh-g\" cx=\"50\" cy=\"48\" r=\"48\" fill=\"url(#ls_gh2)\"/><g class=\"lsgh-b\"><path d=\"M50 8 C28 8 16 26 16 46 L16 84 C16 90 21 91 25 87 L32 80 L40 89 C42 91 44 91 46 89 L50 84 L54 89 C56 91 58 91 60 89 L68 80 L75 87 C79 91 84 90 84 84 L84 46 C84 26 72 8 50 8Z\" fill=\"url(#ls_gh1)\"/><g clip-path=\"url(#ls_ghc)\"><path d=\"M84 30 L84 95 L66 95 C74 76 76 50 68 22Z\" fill=\"#8f97c9\" opacity=\".28\"/><ellipse cx=\"34\" cy=\"26\" rx=\"9\" ry=\"14\" transform=\"rotate(24 34 26)\" fill=\"#fff\" opacity=\".9\"/></g><g class=\"lsgh-e\"><ellipse cx=\"38\" cy=\"42\" rx=\"6\" ry=\"8.5\" fill=\"#23233a\"/><ellipse cx=\"62\" cy=\"42\" rx=\"6\" ry=\"8.5\" fill=\"#23233a\"/><circle cx=\"40\" cy=\"38.5\" r=\"2.4\" fill=\"#fff\"/><circle cx=\"64\" cy=\"38.5\" r=\"2.4\" fill=\"#fff\"/></g><ellipse cx=\"50\" cy=\"60\" rx=\"5.5\" ry=\"7\" fill=\"#23233a\"/><ellipse cx=\"50\" cy=\"63.5\" rx=\"3.4\" ry=\"3\" fill=\"#ff7b95\"/><ellipse cx=\"27\" cy=\"54\" rx=\"5\" ry=\"3\" fill=\"#ff9db0\" opacity=\".55\"/><ellipse cx=\"73\" cy=\"54\" rx=\"5\" ry=\"3\" fill=\"#ff9db0\" opacity=\".55\"/></g></svg>", "sun": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-sun\"><style>.lssu-r{transform-origin:50px 50px;animation:lssu-r 2s linear infinite}@keyframes lssu-r{to{transform:rotate(60deg)}}.lssu-p{transform-origin:50px 50px;animation:lssu-p 1s ease-in-out infinite}@keyframes lssu-p{0%,100%{transform:scale(1)}50%{transform:scale(1.04)}}.lssu-c{transform-origin:50px 50px;animation:lssu-c 1s ease-in-out infinite}@keyframes lssu-c{0%,100%{transform:scale(1)}50%{transform:scale(1.05)}}.lssu-g{transform-origin:50px 50px;animation:lssu-g 1s ease-in-out infinite}@keyframes lssu-g{0%,100%{opacity:.6;transform:scale(.92)}50%{opacity:1;transform:scale(1.06)}}</style><defs><radialGradient id=\"ls_su1\" cx=\"0.38\" cy=\"0.34\" r=\"0.75\"><stop offset=\"0\" stop-color=\"#fffbd6\"/><stop offset=\"0.35\" stop-color=\"#ffe14d\"/><stop offset=\"0.8\" stop-color=\"#ffb300\"/><stop offset=\"1\" stop-color=\"#f08a00\"/></radialGradient><linearGradient id=\"ls_su2\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#ffe45c\"/><stop offset=\"1\" stop-color=\"#ff9a00\"/></linearGradient><radialGradient id=\"ls_su3\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ffd23f\" stop-opacity=\"0.65\"/><stop offset=\"0.6\" stop-color=\"#ffb300\" stop-opacity=\"0.2\"/><stop offset=\"1\" stop-color=\"#ffb300\" stop-opacity=\"0\"/></radialGradient></defs><circle class=\"lssu-g\" cx=\"50\" cy=\"50\" r=\"50\" fill=\"url(#ls_su3)\"/><g class=\"lssu-r\"><g class=\"lssu-p\"><path transform=\"rotate(0 50 50)\" d=\"M46 19 L50 2 L54 19Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(30 50 50)\" d=\"M46 21 L50 9 L54 21Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(60 50 50)\" d=\"M46 19 L50 2 L54 19Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(90 50 50)\" d=\"M46 21 L50 9 L54 21Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(120 50 50)\" d=\"M46 19 L50 2 L54 19Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(150 50 50)\" d=\"M46 21 L50 9 L54 21Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(180 50 50)\" d=\"M46 19 L50 2 L54 19Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(210 50 50)\" d=\"M46 21 L50 9 L54 21Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(240 50 50)\" d=\"M46 19 L50 2 L54 19Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(270 50 50)\" d=\"M46 21 L50 9 L54 21Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(300 50 50)\" d=\"M46 19 L50 2 L54 19Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/><path transform=\"rotate(330 50 50)\" d=\"M46 21 L50 9 L54 21Z\" fill=\"url(#ls_su2)\" stroke=\"url(#ls_su2)\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/></g></g><g class=\"lssu-c\"><circle cx=\"50\" cy=\"50\" r=\"25\" fill=\"url(#ls_su1)\"/><ellipse cx=\"41\" cy=\"40\" rx=\"10\" ry=\"6.5\" transform=\"rotate(-35 41 40)\" fill=\"#fff\" opacity=\".55\"/><path d=\"M70 62 A25 25 0 0 1 36 71 A28 28 0 0 0 70 62Z\" fill=\"#d97400\" opacity=\".3\"/></g></svg>", "moon": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-moon\"><style>.lsm-b{transform-origin:50px 52px;animation:lsm-b 2s ease-in-out infinite}@keyframes lsm-b{0%,100%{transform:rotate(-9deg)}50%{transform:rotate(7deg)}}.lsm-g{transform-origin:46px 52px;animation:lsm-g 2s ease-in-out infinite}@keyframes lsm-g{0%,100%{opacity:.55}50%{opacity:1}}.lsm-tw{animation:lsm-tw 1s ease-in-out infinite}@keyframes lsm-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><radialGradient id=\"ls_m1\" cx=\"0.3\" cy=\"0.35\" r=\"0.8\"><stop offset=\"0\" stop-color=\"#fffbe0\"/><stop offset=\"0.45\" stop-color=\"#ffe38a\"/><stop offset=\"1\" stop-color=\"#f0b83a\"/></radialGradient><radialGradient id=\"ls_m2\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ffe9a0\" stop-opacity=\"0.5\"/><stop offset=\"1\" stop-color=\"#ffe9a0\" stop-opacity=\"0\"/></radialGradient><clipPath id=\"ls_mc\"><path d=\"M62 8 A44 44 0 1 0 92 66 A36 36 0 0 1 62 8Z\"/></clipPath></defs><circle class=\"lsm-g\" cx=\"46\" cy=\"52\" r=\"50\" fill=\"url(#ls_m2)\"/><g class=\"lsm-b\"><path d=\"M62 8 A44 44 0 1 0 92 66 A36 36 0 0 1 62 8Z\" fill=\"url(#ls_m1)\"/><g clip-path=\"url(#ls_mc)\"><path d=\"M30 92 A44 44 0 0 0 92 66 A40 40 0 0 1 22 80Z\" fill=\"#c98a12\" opacity=\".28\"/><circle cx=\"34\" cy=\"38\" r=\"7\" fill=\"#e0a82e\" opacity=\".5\"/><circle cx=\"33\" cy=\"37\" r=\"5.2\" fill=\"#f7cf63\" opacity=\".6\"/><circle cx=\"28\" cy=\"62\" r=\"4.5\" fill=\"#e0a82e\" opacity=\".5\"/><circle cx=\"46\" cy=\"76\" r=\"6\" fill=\"#e0a82e\" opacity=\".45\"/><circle cx=\"45\" cy=\"75\" r=\"4.3\" fill=\"#f7cf63\" opacity=\".5\"/><circle cx=\"48\" cy=\"22\" r=\"3\" fill=\"#e0a82e\" opacity=\".45\"/><path d=\"M24 30 A44 44 0 0 1 50 9\" stroke=\"#fff\" stroke-width=\"3.5\" fill=\"none\" stroke-linecap=\"round\" opacity=\".6\"/></g></g><path class=\"lsm-tw\" style=\"transform-origin:78px 30px;\" d=\"M78 21 C79.98 28.02 79.98 28.02 87 30 C79.98 31.98 79.98 31.98 78 39 C76.02 31.98 76.02 31.98 69 30 C76.02 28.02 76.02 28.02 78 21Z\" fill=\"#fff\"/><path class=\"lsm-tw\" style=\"transform-origin:88px 52px;animation-delay:-.5s\" d=\"M88 47 C89.1 50.9 89.1 50.9 93 52 C89.1 53.1 89.1 53.1 88 57 C86.9 53.1 86.9 53.1 83 52 C86.9 50.9 86.9 50.9 88 47Z\" fill=\"#fff\"/><path class=\"lsm-tw\" style=\"transform-origin:68px 50px;animation-delay:-.25s\" d=\"M68 46 C68.88 49.12 68.88 49.12 72 50 C68.88 50.88 68.88 50.88 68 54 C67.12 50.88 67.12 50.88 64 50 C67.12 49.12 67.12 49.12 68 46Z\" fill=\"#fff\"/></svg>", "clover": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-clover\"><style>.lscl-b{transform-origin:50px 94px;animation:lscl-b 2s ease-in-out infinite}@keyframes lscl-b{0%,100%{transform:rotate(-7deg)}50%{transform:rotate(7deg)}}.lscl-l{transform-origin:50px 47px;animation:lscl-l 2s ease-in-out infinite}@keyframes lscl-l{0%,100%{transform:rotate(6deg) scale(1)}50%{transform:rotate(-6deg) scale(1.05)}}.lscl-g{animation:lscl-g 2s ease-in-out infinite}@keyframes lscl-g{0%,100%{opacity:.5}50%{opacity:1}}.lscl-tw{animation:lscl-tw 1s ease-in-out infinite}@keyframes lscl-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><radialGradient id=\"ls_cl1\" cx=\"0.35\" cy=\"0.25\" r=\"0.85\"><stop offset=\"0\" stop-color=\"#8ff0a0\"/><stop offset=\"0.5\" stop-color=\"#2fc45a\"/><stop offset=\"1\" stop-color=\"#128a3c\"/></radialGradient><linearGradient id=\"ls_cl2\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#2fc45a\"/><stop offset=\"1\" stop-color=\"#0f7a37\"/></linearGradient><radialGradient id=\"ls_cl3\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#5ee07f\" stop-opacity=\"0.5\"/><stop offset=\"1\" stop-color=\"#5ee07f\" stop-opacity=\"0\"/></radialGradient></defs><circle class=\"lscl-g\" cx=\"50\" cy=\"47\" r=\"48\" fill=\"url(#ls_cl3)\"/><g class=\"lscl-b\"><path d=\"M51 50 C52 66 58 80 66 92\" stroke=\"url(#ls_cl2)\" stroke-width=\"5\" fill=\"none\" stroke-linecap=\"round\"/><g class=\"lscl-l\"><g transform=\"rotate(0 50 47)\"><path d=\"M50 46 C40 36 26 34 26 22 C26 13 36 8 43 13 C47 16 49 20 50 24 C51 20 53 16 57 13 C64 8 74 13 74 22 C74 34 60 36 50 46Z\" fill=\"url(#ls_cl1)\"/><path d=\"M50 44 L50 25\" stroke=\"#0f7a37\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".6\"/><path d=\"M34 14 C29 16 28 22 31 27\" stroke=\"#fff\" stroke-width=\"2.6\" fill=\"none\" stroke-linecap=\"round\" opacity=\".5\"/></g><g transform=\"rotate(90 50 47)\"><path d=\"M50 46 C40 36 26 34 26 22 C26 13 36 8 43 13 C47 16 49 20 50 24 C51 20 53 16 57 13 C64 8 74 13 74 22 C74 34 60 36 50 46Z\" fill=\"url(#ls_cl1)\"/><path d=\"M50 44 L50 25\" stroke=\"#0f7a37\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".6\"/><path d=\"M34 14 C29 16 28 22 31 27\" stroke=\"#fff\" stroke-width=\"2.6\" fill=\"none\" stroke-linecap=\"round\" opacity=\".5\"/></g><g transform=\"rotate(180 50 47)\"><path d=\"M50 46 C40 36 26 34 26 22 C26 13 36 8 43 13 C47 16 49 20 50 24 C51 20 53 16 57 13 C64 8 74 13 74 22 C74 34 60 36 50 46Z\" fill=\"url(#ls_cl1)\"/><path d=\"M50 44 L50 25\" stroke=\"#0f7a37\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".6\"/><path d=\"M34 14 C29 16 28 22 31 27\" stroke=\"#fff\" stroke-width=\"2.6\" fill=\"none\" stroke-linecap=\"round\" opacity=\".5\"/></g><g transform=\"rotate(270 50 47)\"><path d=\"M50 46 C40 36 26 34 26 22 C26 13 36 8 43 13 C47 16 49 20 50 24 C51 20 53 16 57 13 C64 8 74 13 74 22 C74 34 60 36 50 46Z\" fill=\"url(#ls_cl1)\"/><path d=\"M50 44 L50 25\" stroke=\"#0f7a37\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".6\"/><path d=\"M34 14 C29 16 28 22 31 27\" stroke=\"#fff\" stroke-width=\"2.6\" fill=\"none\" stroke-linecap=\"round\" opacity=\".5\"/></g><circle cx=\"50\" cy=\"47\" r=\"4\" fill=\"#0f7a37\"/><circle cx=\"49\" cy=\"46\" r=\"1.6\" fill=\"#8ff0a0\"/></g></g><path class=\"lscl-tw\" style=\"transform-origin:86px 16px;\" d=\"M86 9 C87.54 14.46 87.54 14.46 93 16 C87.54 17.54 87.54 17.54 86 23 C84.46 17.54 84.46 17.54 79 16 C84.46 14.46 84.46 14.46 86 9Z\" fill=\"#fff\"/><path class=\"lscl-tw\" style=\"transform-origin:14px 78px;animation-delay:-.5s\" d=\"M14 73 C15.1 76.9 15.1 76.9 19 78 C15.1 79.1 15.1 79.1 14 83 C12.9 79.1 12.9 79.1 9 78 C12.9 76.9 12.9 76.9 14 73Z\" fill=\"#fff\"/></svg>", "note": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-note\"><style>.lsn-b{transform-origin:50px 90px;animation:lsn-b 1s cubic-bezier(.4,0,.3,1) infinite}@keyframes lsn-b{0%,100%{transform:translateY(0) rotate(-5deg) scale(1,1)}15%{transform:translateY(2px) rotate(-5deg) scale(1.06,.92)}50%{transform:translateY(-7px) rotate(5deg) scale(.97,1.04)}}.lsn-w{transform-origin:20px 60px;animation:lsn-w 1s ease-out infinite;fill:none;stroke-linecap:round}@keyframes lsn-w{0%{transform:scale(.5);opacity:0}25%{opacity:.9}100%{transform:scale(1.25);opacity:0}}.lsn-g{animation:lsn-g 1s ease-in-out infinite}@keyframes lsn-g{0%,100%{opacity:.5}50%{opacity:1}}.lsn-m{animation:lsn-m 2s linear infinite;opacity:0}@keyframes lsn-m{0%{transform:translate(0,8px) rotate(-10deg) scale(.6);opacity:0}20%{opacity:1}100%{transform:translate(6px,-26px) rotate(14deg) scale(1);opacity:0}}</style><defs><linearGradient id=\"ls_n1\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0\" stop-color=\"#c9a6ff\"/><stop offset=\"0.5\" stop-color=\"#8b5cf6\"/><stop offset=\"1\" stop-color=\"#4c1fb8\"/></linearGradient><radialGradient id=\"ls_n2\" cx=\"0.35\" cy=\"0.3\" r=\"0.8\"><stop offset=\"0\" stop-color=\"#e6d6ff\"/><stop offset=\"0.5\" stop-color=\"#9b6dff\"/><stop offset=\"1\" stop-color=\"#4c1fb8\"/></radialGradient><radialGradient id=\"ls_n3\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#9b6dff\" stop-opacity=\"0.5\"/><stop offset=\"1\" stop-color=\"#9b6dff\" stop-opacity=\"0\"/></radialGradient></defs><circle class=\"lsn-g\" cx=\"52\" cy=\"52\" r=\"48\" fill=\"url(#ls_n3)\"/><g class=\"lsn-m\" style=\"\"><ellipse cx=\"86\" cy=\"30\" rx=\"4\" ry=\"3\" transform=\"rotate(-20 86 30)\" fill=\"#c9a6ff\"/><path d=\"M89.5 30 v-12 l5 3\" stroke=\"#c9a6ff\" stroke-width=\"1.8\" fill=\"none\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/></g><g class=\"lsn-m\" style=\"animation-delay:-1s\"><ellipse cx=\"12\" cy=\"34\" rx=\"4\" ry=\"3\" transform=\"rotate(-20 12 34)\" fill=\"#c9a6ff\"/><path d=\"M15.5 34 v-12 l5 3\" stroke=\"#c9a6ff\" stroke-width=\"1.8\" fill=\"none\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/></g><g class=\"lsn-b\"><path d=\"M36 20 L82 9 L82 25 L36 36Z\" fill=\"url(#ls_n1)\"/><path d=\"M36 20 L82 9 L82 13 L36 24Z\" fill=\"#fff\" opacity=\".35\"/><rect x=\"33\" y=\"20\" width=\"7\" height=\"56\" rx=\"3.5\" fill=\"url(#ls_n1)\"/><rect x=\"77\" y=\"9\" width=\"7\" height=\"56\" rx=\"3.5\" fill=\"url(#ls_n1)\"/><ellipse cx=\"27\" cy=\"76\" rx=\"14.5\" ry=\"11\" transform=\"rotate(-22 27 76)\" fill=\"url(#ls_n2)\"/><ellipse cx=\"71\" cy=\"65\" rx=\"14.5\" ry=\"11\" transform=\"rotate(-22 71 65)\" fill=\"url(#ls_n2)\"/><ellipse cx=\"22\" cy=\"71\" rx=\"5\" ry=\"3\" transform=\"rotate(-22 22 71)\" fill=\"#fff\" opacity=\".6\"/><ellipse cx=\"66\" cy=\"60\" rx=\"5\" ry=\"3\" transform=\"rotate(-22 66 60)\" fill=\"#fff\" opacity=\".6\"/></g></svg>", "snow": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-snow\"><style>.lssn-r{transform-origin:50px 50px;animation:lssn-r 2s linear infinite}@keyframes lssn-r{to{transform:rotate(60deg)}}.lssn-p{transform-origin:50px 50px;animation:lssn-p 1s ease-in-out infinite}@keyframes lssn-p{0%,100%{transform:scale(.96)}50%{transform:scale(1.04)}}.lssn-g{animation:lssn-g 1s ease-in-out infinite}@keyframes lssn-g{0%,100%{opacity:.5}50%{opacity:1}}.lssn-tw{animation:lssn-tw 1s ease-in-out infinite}@keyframes lssn-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><linearGradient id=\"ls_sn1\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#e9fbff\"/><stop offset=\"0.5\" stop-color=\"#8fd8ff\"/><stop offset=\"1\" stop-color=\"#3aa0f0\"/></linearGradient><radialGradient id=\"ls_sn2\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ffffff\"/><stop offset=\"0.6\" stop-color=\"#bfeaff\"/><stop offset=\"1\" stop-color=\"#5ab8f7\"/></radialGradient><radialGradient id=\"ls_sn3\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#8fd8ff\" stop-opacity=\"0.55\"/><stop offset=\"1\" stop-color=\"#8fd8ff\" stop-opacity=\"0\"/></radialGradient></defs><circle class=\"lssn-g\" cx=\"50\" cy=\"50\" r=\"49\" fill=\"url(#ls_sn3)\"/><g class=\"lssn-p\"><g class=\"lssn-r\"><g transform=\"rotate(0 50 50)\"><path d=\"M50 50 L50 7\" stroke=\"url(#ls_sn1)\" stroke-width=\"6\" stroke-linecap=\"round\"/><path d=\"M50 22 L40 12 M50 22 L60 12 M50 35 L39 25 M50 35 L61 25\" stroke=\"url(#ls_sn1)\" stroke-width=\"4.6\" stroke-linecap=\"round\" fill=\"none\"/><path d=\"M50 48 L50 9\" stroke=\"#fff\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".8\"/></g><g transform=\"rotate(60 50 50)\"><path d=\"M50 50 L50 7\" stroke=\"url(#ls_sn1)\" stroke-width=\"6\" stroke-linecap=\"round\"/><path d=\"M50 22 L40 12 M50 22 L60 12 M50 35 L39 25 M50 35 L61 25\" stroke=\"url(#ls_sn1)\" stroke-width=\"4.6\" stroke-linecap=\"round\" fill=\"none\"/><path d=\"M50 48 L50 9\" stroke=\"#fff\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".8\"/></g><g transform=\"rotate(120 50 50)\"><path d=\"M50 50 L50 7\" stroke=\"url(#ls_sn1)\" stroke-width=\"6\" stroke-linecap=\"round\"/><path d=\"M50 22 L40 12 M50 22 L60 12 M50 35 L39 25 M50 35 L61 25\" stroke=\"url(#ls_sn1)\" stroke-width=\"4.6\" stroke-linecap=\"round\" fill=\"none\"/><path d=\"M50 48 L50 9\" stroke=\"#fff\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".8\"/></g><g transform=\"rotate(180 50 50)\"><path d=\"M50 50 L50 7\" stroke=\"url(#ls_sn1)\" stroke-width=\"6\" stroke-linecap=\"round\"/><path d=\"M50 22 L40 12 M50 22 L60 12 M50 35 L39 25 M50 35 L61 25\" stroke=\"url(#ls_sn1)\" stroke-width=\"4.6\" stroke-linecap=\"round\" fill=\"none\"/><path d=\"M50 48 L50 9\" stroke=\"#fff\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".8\"/></g><g transform=\"rotate(240 50 50)\"><path d=\"M50 50 L50 7\" stroke=\"url(#ls_sn1)\" stroke-width=\"6\" stroke-linecap=\"round\"/><path d=\"M50 22 L40 12 M50 22 L60 12 M50 35 L39 25 M50 35 L61 25\" stroke=\"url(#ls_sn1)\" stroke-width=\"4.6\" stroke-linecap=\"round\" fill=\"none\"/><path d=\"M50 48 L50 9\" stroke=\"#fff\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".8\"/></g><g transform=\"rotate(300 50 50)\"><path d=\"M50 50 L50 7\" stroke=\"url(#ls_sn1)\" stroke-width=\"6\" stroke-linecap=\"round\"/><path d=\"M50 22 L40 12 M50 22 L60 12 M50 35 L39 25 M50 35 L61 25\" stroke=\"url(#ls_sn1)\" stroke-width=\"4.6\" stroke-linecap=\"round\" fill=\"none\"/><path d=\"M50 48 L50 9\" stroke=\"#fff\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".8\"/></g><polygon points=\"50,39 59.5,44.5 59.5,55.5 50,61 40.5,55.5 40.5,44.5\" fill=\"url(#ls_sn2)\"/><polygon points=\"50,43 56,46.5 56,53.5 50,57 44,53.5 44,46.5\" fill=\"#fff\" opacity=\".7\"/></g></g><path class=\"lssn-tw\" style=\"transform-origin:84px 16px;\" d=\"M84 9 C85.54 14.46 85.54 14.46 91 16 C85.54 17.54 85.54 17.54 84 23 C82.46 17.54 82.46 17.54 77 16 C82.46 14.46 82.46 14.46 84 9Z\" fill=\"#fff\"/><path class=\"lssn-tw\" style=\"transform-origin:14px 82px;animation-delay:-.5s\" d=\"M14 76.5 C15.21 80.79 15.21 80.79 19.5 82 C15.21 83.21 15.21 83.21 14 87.5 C12.79 83.21 12.79 83.21 8.5 82 C12.79 80.79 12.79 80.79 14 76.5Z\" fill=\"#fff\"/><path class=\"lssn-tw\" style=\"transform-origin:88px 76px;animation-delay:-.25s\" d=\"M88 72 C88.88 75.12 88.88 75.12 92 76 C88.88 76.88 88.88 76.88 88 80 C87.12 76.88 87.12 76.88 84 76 C87.12 75.12 87.12 75.12 88 72Z\" fill=\"#fff\"/></svg>", "trophy": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-trophy\"><style>.lst-b{transform-origin:50px 94px;animation:lst-b 1s cubic-bezier(.4,0,.3,1) infinite}@keyframes lst-b{0%,100%{transform:translateY(0) scale(1,1)}20%{transform:translateY(1.5px) scale(1.04,.96)}55%{transform:translateY(-4px) scale(.98,1.03)}}.lst-w{animation:lst-w 2s ease-in-out infinite}@keyframes lst-w{0%,30%{transform:translateX(-70px)}70%,100%{transform:translateX(70px)}}.lst-g{animation:lst-g 1s ease-in-out infinite}@keyframes lst-g{0%,100%{opacity:.5}50%{opacity:1}}.lst-tw{animation:lst-tw 1s ease-in-out infinite}@keyframes lst-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><linearGradient id=\"ls_t1\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0\" stop-color=\"#b8780a\"/><stop offset=\"0.25\" stop-color=\"#ffd43b\"/><stop offset=\"0.45\" stop-color=\"#fff3b0\"/><stop offset=\"0.7\" stop-color=\"#f2a007\"/><stop offset=\"1\" stop-color=\"#a86400\"/></linearGradient><linearGradient id=\"ls_t2\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0\" stop-color=\"#8a5200\"/><stop offset=\"0.4\" stop-color=\"#f2b01a\"/><stop offset=\"1\" stop-color=\"#7a4700\"/></linearGradient><linearGradient id=\"ls_t3\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0\" stop-color=\"#5a3a22\"/><stop offset=\"0.5\" stop-color=\"#8a5a36\"/><stop offset=\"1\" stop-color=\"#3f2714\"/></linearGradient><linearGradient id=\"ls_t5\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0\" stop-color=\"#fff\" stop-opacity=\"0\"/><stop offset=\"0.5\" stop-color=\"#fff\" stop-opacity=\"0.9\"/><stop offset=\"1\" stop-color=\"#fff\" stop-opacity=\"0\"/></linearGradient><radialGradient id=\"ls_t6\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ffd23f\" stop-opacity=\"0.5\"/><stop offset=\"1\" stop-color=\"#ffd23f\" stop-opacity=\"0\"/></radialGradient><clipPath id=\"ls_tc\"><path d=\"M26 10 L74 10 C74 36 68 56 50 60 C32 56 26 36 26 10Z\"/></clipPath></defs><circle class=\"lst-g\" cx=\"50\" cy=\"40\" r=\"48\" fill=\"url(#ls_t6)\"/><g class=\"lst-b\"><path d=\"M28 16 C10 14 8 34 28 40\" stroke=\"url(#ls_t2)\" stroke-width=\"6\" fill=\"none\" stroke-linecap=\"round\"/><path d=\"M72 16 C90 14 92 34 72 40\" stroke=\"url(#ls_t2)\" stroke-width=\"6\" fill=\"none\" stroke-linecap=\"round\"/><path d=\"M44 58 L56 58 L58 76 L42 76Z\" fill=\"url(#ls_t2)\"/><path d=\"M26 10 L74 10 C74 36 68 56 50 60 C32 56 26 36 26 10Z\" fill=\"url(#ls_t1)\"/><rect x=\"23\" y=\"6\" width=\"54\" height=\"8\" rx=\"4\" fill=\"url(#ls_t1)\"/><rect x=\"25\" y=\"7.5\" width=\"50\" height=\"2.4\" rx=\"1.2\" fill=\"#fff\" opacity=\".5\"/><g clip-path=\"url(#ls_tc)\"><g class=\"lst-w\"><polygon points=\"42,0 56,0 46,70 32,70\" fill=\"url(#ls_t5)\"/></g></g><path opacity=\".9\" style=\"transform-origin:50px 32px;\" d=\"M50 21 C52.42 29.58 52.42 29.58 61 32 C52.42 34.42 52.42 34.42 50 43 C47.58 34.42 47.58 34.42 39 32 C47.58 29.58 47.58 29.58 50 21Z\" fill=\"#fff3b0\"/><rect x=\"34\" y=\"74\" width=\"32\" height=\"7\" rx=\"3\" fill=\"url(#ls_t1)\"/><rect x=\"26\" y=\"80\" width=\"48\" height=\"14\" rx=\"4\" fill=\"url(#ls_t3)\"/><rect x=\"38\" y=\"84\" width=\"24\" height=\"6\" rx=\"2\" fill=\"url(#ls_t1)\"/></g><path class=\"lst-tw\" style=\"transform-origin:86px 12px;\" d=\"M86 5 C87.54 10.46 87.54 10.46 93 12 C87.54 13.54 87.54 13.54 86 19 C84.46 13.54 84.46 13.54 79 12 C84.46 10.46 84.46 10.46 86 5Z\" fill=\"#fff\"/><path class=\"lst-tw\" style=\"transform-origin:12px 60px;animation-delay:-.5s\" d=\"M12 55 C13.1 58.9 13.1 58.9 17 60 C13.1 61.1 13.1 61.1 12 65 C10.9 61.1 10.9 61.1 7 60 C10.9 58.9 10.9 58.9 12 55Z\" fill=\"#fff\"/></svg>", "skull": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-skull\"><style>.lssk-b{transform-origin:50px 90px;animation:lssk-b 2s ease-in-out infinite}@keyframes lssk-b{0%,100%{transform:rotate(-5deg)}50%{transform:rotate(5deg)}}.lssk-j{animation:lssk-j .5s ease-in-out infinite}@keyframes lssk-j{0%,100%{transform:translateY(0)}50%{transform:translateY(4.5px)}}.lssk-e{animation:lssk-e 1s ease-in-out infinite}@keyframes lssk-e{0%,100%{opacity:.35}50%{opacity:1}}.lssk-g{animation:lssk-e 1s ease-in-out infinite}</style><defs><radialGradient id=\"ls_sk1\" cx=\"0.38\" cy=\"0.28\" r=\"0.85\"><stop offset=\"0\" stop-color=\"#ffffff\"/><stop offset=\"0.55\" stop-color=\"#eceff5\"/><stop offset=\"1\" stop-color=\"#b3bacb\"/></radialGradient><linearGradient id=\"ls_sk2\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#f4f6fa\"/><stop offset=\"1\" stop-color=\"#b3bacb\"/></linearGradient><radialGradient id=\"ls_sk3\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#7dffb0\"/><stop offset=\"0.5\" stop-color=\"#18d66b\"/><stop offset=\"1\" stop-color=\"#18d66b\" stop-opacity=\"0\"/></radialGradient><radialGradient id=\"ls_sk4\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#3dff8f\" stop-opacity=\"0.45\"/><stop offset=\"1\" stop-color=\"#3dff8f\" stop-opacity=\"0\"/></radialGradient><clipPath id=\"ls_skc\"><path d=\"M50 6 C26 6 12 22 12 42 C12 54 17 62 25 67 L25 74 C25 78 28 80 32 80 L68 80 C72 80 75 78 75 74 L75 67 C83 62 88 54 88 42 C88 22 74 6 50 6Z\"/></clipPath></defs><circle class=\"lssk-g\" cx=\"50\" cy=\"48\" r=\"48\" fill=\"url(#ls_sk4)\"/><g class=\"lssk-b\"><g class=\"lssk-j\"><path d=\"M30 74 L70 74 L67 90 C66 94 63 96 59 96 L41 96 C37 96 34 94 33 90Z\" fill=\"url(#ls_sk2)\"/><path d=\"M40 78 v12 M50 78 v13 M60 78 v12\" stroke=\"#7b8296\" stroke-width=\"2.2\" stroke-linecap=\"round\"/></g><path d=\"M50 6 C26 6 12 22 12 42 C12 54 17 62 25 67 L25 74 C25 78 28 80 32 80 L68 80 C72 80 75 78 75 74 L75 67 C83 62 88 54 88 42 C88 22 74 6 50 6Z\" fill=\"url(#ls_sk1)\"/><g clip-path=\"url(#ls_skc)\"><path d=\"M88 30 L88 82 L64 82 C76 68 82 48 76 20Z\" fill=\"#7b8296\" opacity=\".25\"/><ellipse cx=\"33\" cy=\"22\" rx=\"12\" ry=\"7\" transform=\"rotate(-28 33 22)\" fill=\"#fff\" opacity=\".85\"/></g><ellipse cx=\"33\" cy=\"46\" rx=\"11\" ry=\"12.5\" transform=\"rotate(8 33 46)\" fill=\"#1d1f2b\"/><ellipse cx=\"67\" cy=\"46\" rx=\"11\" ry=\"12.5\" transform=\"rotate(-8 67 46)\" fill=\"#1d1f2b\"/><circle class=\"lssk-e\" cx=\"33\" cy=\"47\" r=\"7\" fill=\"url(#ls_sk3)\"/><circle class=\"lssk-e\" cx=\"67\" cy=\"47\" r=\"7\" fill=\"url(#ls_sk3)\"/><path d=\"M50 54 L44.5 65 C46.5 67 48.5 66 50 64 C51.5 66 53.5 67 55.5 65Z\" fill=\"#1d1f2b\"/><path d=\"M36 80 v-7 M43 80 v-8 M50 80 v-8 M57 80 v-8 M64 80 v-7\" stroke=\"#7b8296\" stroke-width=\"2.2\" stroke-linecap=\"round\"/></g></svg>", "pumpkin": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-pumpkin\"><style>.lsp-b{transform-origin:50px 92px;animation:lsp-b 1s cubic-bezier(.4,0,.3,1) infinite}@keyframes lsp-b{0%,100%{transform:scale(1,1)}20%{transform:scale(1.05,.95)}55%{transform:scale(.98,1.03) translateY(-2px)}}.lsp-f{animation:lsp-f .5s ease-in-out infinite}@keyframes lsp-f{0%,100%{opacity:1}40%{opacity:.6}70%{opacity:.9}}.lsp-g{transform-origin:50px 60px;animation:lsp-g .5s ease-in-out infinite}@keyframes lsp-g{0%,100%{opacity:.9;transform:scale(1.05)}50%{opacity:.55;transform:scale(.95)}}</style><defs><radialGradient id=\"ls_p1\" cx=\"0.36\" cy=\"0.28\" r=\"0.8\"><stop offset=\"0\" stop-color=\"#ffc266\"/><stop offset=\"0.45\" stop-color=\"#ff8a1f\"/><stop offset=\"0.85\" stop-color=\"#e2620a\"/><stop offset=\"1\" stop-color=\"#b04a06\"/></radialGradient><radialGradient id=\"ls_p2\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#fff7c2\"/><stop offset=\"0.6\" stop-color=\"#ffd23f\"/><stop offset=\"1\" stop-color=\"#ff9a1f\"/></radialGradient><linearGradient id=\"ls_p3\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#6fae4f\"/><stop offset=\"1\" stop-color=\"#2f6b2a\"/></linearGradient><radialGradient id=\"ls_p4\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#ff9a1f\" stop-opacity=\"0.55\"/><stop offset=\"1\" stop-color=\"#ff9a1f\" stop-opacity=\"0\"/></radialGradient></defs><circle class=\"lsp-g\" cx=\"50\" cy=\"58\" r=\"48\" fill=\"url(#ls_p4)\"/><g class=\"lsp-b\"><path d=\"M47 24 C45 14 50 7 59 5 C62 4 65 6 64 10 C58 11 55 16 55 24Z\" fill=\"url(#ls_p3)\"/><path d=\"M50 20 C22 18 6 34 6 56 C6 78 24 94 50 94 C76 94 94 78 94 56 C94 34 78 18 50 20Z\" fill=\"url(#ls_p1)\"/><path d=\"M28 24 C18 40 18 74 30 90 M50 20 C44 40 44 76 50 94 M72 24 C82 40 82 74 70 90\" stroke=\"#b04a06\" stroke-width=\"2.4\" fill=\"none\" stroke-linecap=\"round\" opacity=\".5\"/><ellipse cx=\"27\" cy=\"38\" rx=\"9\" ry=\"13\" transform=\"rotate(18 27 38)\" fill=\"#fff\" opacity=\".3\"/><g fill=\"#5a2406\" transform=\"translate(0,-1.8)\"><path d=\"M24 46 L40 46 L32 60Z\"/><path d=\"M76 46 L60 46 L68 60Z\"/><path d=\"M46 60 L50 67 L54 60Z\"/><path d=\"M20 68 C30 78 40 82 50 81 C60 82 70 78 80 68 C76 78 68 86 60 88 L57 82 L53 89 L50 83 L47 89 L43 82 L40 88 C32 86 24 78 20 68Z\"/></g><g class=\"lsp-f\" fill=\"url(#ls_p2)\"><path d=\"M24 46 L40 46 L32 60Z\"/><path d=\"M76 46 L60 46 L68 60Z\"/><path d=\"M46 60 L50 67 L54 60Z\"/><path d=\"M20 68 C30 78 40 82 50 81 C60 82 70 78 80 68 C76 78 68 86 60 88 L57 82 L53 89 L50 83 L47 89 L43 82 L40 88 C32 86 24 78 20 68Z\"/></g></g></svg>", "confetti": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-confetti\"><style>.lsco-p{transform-origin:48px 52px;animation:lsco-p 1s cubic-bezier(.15,.6,.35,1) infinite;opacity:0}@keyframes lsco-p{0%{transform:translate(0,0) rotate(0) scale(.4);opacity:0}10%{opacity:1}70%{opacity:1}100%{transform:translate(var(--dx),calc(var(--dy) + 14px)) rotate(var(--r)) scale(1);opacity:0}}.lsco-b{transform-origin:20px 84px;animation:lsco-b 1s cubic-bezier(.3,0,.3,1) infinite}@keyframes lsco-b{0%,100%{transform:rotate(0) scale(1)}8%{transform:rotate(-5deg) scale(1.07,.95)}25%{transform:rotate(2deg) scale(.98,1.02)}45%{transform:rotate(0) scale(1)}}.lsco-tw{animation:lsco-tw 1s ease-in-out infinite}@keyframes lsco-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><linearGradient id=\"ls_co1\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0\" stop-color=\"#ffd23f\"/><stop offset=\"1\" stop-color=\"#ff8a1f\"/></linearGradient><clipPath id=\"ls_coc\"><path d=\"M8 92 L30 34 L66 70Z\"/></clipPath></defs><g class=\"lsco-p\" style=\"--dx:20.7px;--dy:-31.4px;--r:-312deg;animation-delay:-0.01s\"><rect x=\"45\" y=\"50\" width=\"7\" height=\"4\" rx=\"1\" fill=\"#ff3b62\"/></g><g class=\"lsco-p\" style=\"--dx:12.6px;--dy:-44.4px;--r:205deg;animation-delay:-0.01s\"><circle cx=\"48\" cy=\"52\" r=\"2.6\" fill=\"#3aa7ff\"/></g><g class=\"lsco-p\" style=\"--dx:13.6px;--dy:-42.0px;--r:-388deg;animation-delay:-0.14s\"><path d=\"M44 52 q3 -5 6 0 t6 0\" stroke=\"#ffd23f\" stroke-width=\"2.2\" fill=\"none\" stroke-linecap=\"round\"/></g><g class=\"lsco-p\" style=\"--dx:35.5px;--dy:-45.1px;--r:-284deg;animation-delay:-0.08s\"><rect x=\"45\" y=\"50\" width=\"7\" height=\"4\" rx=\"1\" fill=\"#2fc45a\"/></g><g class=\"lsco-p\" style=\"--dx:13.5px;--dy:-34.3px;--r:-217deg;animation-delay:-0.58s\"><circle cx=\"48\" cy=\"52\" r=\"2.6\" fill=\"#b06cff\"/></g><g class=\"lsco-p\" style=\"--dx:29.4px;--dy:-24.9px;--r:-383deg;animation-delay:-0.08s\"><path d=\"M44 52 q3 -5 6 0 t6 0\" stroke=\"#ff8a1f\" stroke-width=\"2.2\" fill=\"none\" stroke-linecap=\"round\"/></g><g class=\"lsco-p\" style=\"--dx:36.6px;--dy:-27.7px;--r:391deg;animation-delay:-0.87s\"><rect x=\"45\" y=\"50\" width=\"7\" height=\"4\" rx=\"1\" fill=\"#22d3c5\"/></g><g class=\"lsco-p\" style=\"--dx:27.5px;--dy:-30.7px;--r:-209deg;animation-delay:-0.35s\"><circle cx=\"48\" cy=\"52\" r=\"2.6\" fill=\"#ff6fb5\"/></g><g class=\"lsco-p\" style=\"--dx:24.2px;--dy:-39.0px;--r:399deg;animation-delay:-0.61s\"><path d=\"M44 52 q3 -5 6 0 t6 0\" stroke=\"#ff3b62\" stroke-width=\"2.2\" fill=\"none\" stroke-linecap=\"round\"/></g><g class=\"lsco-p\" style=\"--dx:13.4px;--dy:-44.3px;--r:-516deg;animation-delay:-0.36s\"><rect x=\"45\" y=\"50\" width=\"7\" height=\"4\" rx=\"1\" fill=\"#3aa7ff\"/></g><g class=\"lsco-p\" style=\"--dx:36.6px;--dy:-43.8px;--r:302deg;animation-delay:-0.11s\"><circle cx=\"48\" cy=\"52\" r=\"2.6\" fill=\"#ffd23f\"/></g><g class=\"lsco-p\" style=\"--dx:26.4px;--dy:-37.6px;--r:-520deg;animation-delay:-0.76s\"><path d=\"M44 52 q3 -5 6 0 t6 0\" stroke=\"#2fc45a\" stroke-width=\"2.2\" fill=\"none\" stroke-linecap=\"round\"/></g><g class=\"lsco-p\" style=\"--dx:34.2px;--dy:-36.4px;--r:413deg;animation-delay:-0.11s\"><rect x=\"45\" y=\"50\" width=\"7\" height=\"4\" rx=\"1\" fill=\"#b06cff\"/></g><g class=\"lsco-p\" style=\"--dx:52.5px;--dy:-11.6px;--r:188deg;animation-delay:-0.61s\"><circle cx=\"48\" cy=\"52\" r=\"2.6\" fill=\"#ff8a1f\"/></g><g class=\"lsco-b\"><path d=\"M8 92 L30 34 L66 70Z\" fill=\"url(#ls_co1)\"/><g clip-path=\"url(#ls_coc)\"><path d=\"M14 76 L24 50 L36 62 L22 88Z\" fill=\"#ff3b62\"/><path d=\"M36 86 L50 54 L60 64 L46 90Z\" fill=\"#b06cff\" opacity=\".95\"/><path d=\"M8 92 L30 34 L36 40 L14 96Z\" fill=\"#fff\" opacity=\".28\"/></g><ellipse cx=\"48\" cy=\"52\" rx=\"25.5\" ry=\"6\" transform=\"rotate(45 48 52)\" fill=\"#a8480a\"/><ellipse cx=\"48\" cy=\"52\" rx=\"22\" ry=\"3.6\" transform=\"rotate(45 48 52)\" fill=\"#5a2406\"/></g><path class=\"lsco-tw\" style=\"transform-origin:84px 14px;\" d=\"M84 7 C85.54 12.46 85.54 12.46 91 14 C85.54 15.54 85.54 15.54 84 21 C82.46 15.54 82.46 15.54 77 14 C82.46 12.46 82.46 12.46 84 7Z\" fill=\"#ffd23f\"/><path class=\"lsco-tw\" style=\"transform-origin:90px 62px;animation-delay:-.5s\" d=\"M90 57 C91.1 60.9 91.1 60.9 95 62 C91.1 63.1 91.1 63.1 90 67 C88.9 63.1 88.9 63.1 85 62 C88.9 60.9 88.9 60.9 90 57Z\" fill=\"#fff\"/></svg>", "witch": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" class=\"lst-witch\"><style>.lsw-b{transform-origin:50px 84px;animation:lsw-b 2s ease-in-out infinite}@keyframes lsw-b{0%,100%{transform:rotate(-6deg) translateY(1px)}50%{transform:rotate(6deg) translateY(-3px)}}.lsw-t{transform-origin:60px 28px;animation:lsw-t 2s ease-in-out infinite}@keyframes lsw-t{0%,100%{transform:rotate(5deg)}50%{transform:rotate(-7deg)}}.lsw-g{animation:lsw-g 1s ease-in-out infinite}@keyframes lsw-g{0%,100%{opacity:.5}50%{opacity:1}}.lsw-tw{animation:lsw-tw 1s ease-in-out infinite}@keyframes lsw-tw{0%,100%{transform:scale(.2) rotate(0);opacity:0}50%{transform:scale(1) rotate(45deg);opacity:1}}</style><defs><linearGradient id=\"ls_w1\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0\" stop-color=\"#8b5cf6\"/><stop offset=\"0.5\" stop-color=\"#5b2bd1\"/><stop offset=\"1\" stop-color=\"#2c1178\"/></linearGradient><linearGradient id=\"ls_w2\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#6d3be0\"/><stop offset=\"0.5\" stop-color=\"#3f1a9e\"/><stop offset=\"1\" stop-color=\"#210a5c\"/></linearGradient><linearGradient id=\"ls_w3\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#fff3b0\"/><stop offset=\"0.5\" stop-color=\"#ffd43b\"/><stop offset=\"1\" stop-color=\"#f2a007\"/></linearGradient><radialGradient id=\"ls_w4\" cx=\"0.5\" cy=\"0.5\" r=\"0.5\"><stop offset=\"0\" stop-color=\"#a06cff\" stop-opacity=\"0.55\"/><stop offset=\"1\" stop-color=\"#a06cff\" stop-opacity=\"0\"/></radialGradient><clipPath id=\"ls_wc\"><path d=\"M24 72 C32 48 40 22 62 6 C64 5 66 7 64 9 C58 16 60 22 66 26 C60 28 58 34 62 44 C66 54 72 64 76 72Z\"/></clipPath></defs><circle class=\"lsw-g\" cx=\"50\" cy=\"52\" r=\"48\" fill=\"url(#ls_w4)\"/><g class=\"lsw-b\"><ellipse cx=\"50\" cy=\"78\" rx=\"46\" ry=\"13\" fill=\"url(#ls_w2)\"/><ellipse cx=\"50\" cy=\"75.5\" rx=\"40\" ry=\"8\" fill=\"#7a4cf0\" opacity=\".35\"/><g class=\"lsw-t\"><path d=\"M24 72 C32 48 40 22 62 6 C64 5 66 7 64 9 C58 16 60 22 66 26 C60 28 58 34 62 44 C66 54 72 64 76 72Z\" fill=\"url(#ls_w1)\"/><g clip-path=\"url(#ls_wc)\"><path d=\"M24 72 C32 48 40 22 62 6 L56 8 C40 24 34 48 30 72Z\" fill=\"#fff\" opacity=\".22\"/><path d=\"M62 44 C66 54 72 64 76 72 L62 72 C62 62 60 52 56 44Z\" fill=\"#170640\" opacity=\".3\"/><path d=\"M22 60 L78 60 L80 74 L20 74Z\" fill=\"#1d0b4a\"/><path d=\"M22 60 L78 60 L78.5 63 L21.5 63Z\" fill=\"#fff\" opacity=\".12\"/></g><rect x=\"41\" y=\"57\" width=\"18\" height=\"15\" rx=\"3\" fill=\"url(#ls_w3)\"/><rect x=\"45.5\" y=\"61\" width=\"9\" height=\"7\" rx=\"1.5\" fill=\"#1d0b4a\"/><path d=\"M43 59 h14\" stroke=\"#fff\" stroke-width=\"1.6\" stroke-linecap=\"round\" opacity=\".6\"/></g></g><path class=\"lsw-tw\" style=\"transform-origin:84px 22px;\" d=\"M84 14 C85.76 20.24 85.76 20.24 92 22 C85.76 23.76 85.76 23.76 84 30 C82.24 23.76 82.24 23.76 76 22 C82.24 20.24 82.24 20.24 84 14Z\" fill=\"#ffe680\"/><path class=\"lsw-tw\" style=\"transform-origin:16px 30px;animation-delay:-.5s\" d=\"M16 24 C17.32 28.68 17.32 28.68 22 30 C17.32 31.32 17.32 31.32 16 36 C14.68 31.32 14.68 31.32 10 30 C14.68 28.68 14.68 28.68 16 24Z\" fill=\"#ffe680\"/><path class=\"lsw-tw\" style=\"transform-origin:88px 56px;animation-delay:-.25s\" d=\"M88 52 C88.88 55.12 88.88 55.12 92 56 C88.88 56.88 88.88 56.88 88 60 C87.12 56.88 87.12 56.88 84 56 C87.12 55.12 87.12 55.12 88 52Z\" fill=\"#fff\"/></svg>"};
(function(){ const st=document.createElement('style'); st.textContent='.aemo.lst{width:1.3em;height:1.3em;vertical-align:-.28em;animation:none}.aemo.lst svg{overflow:hidden;animation:none}'; document.head.appendChild(st); })();
/* ===== Анимированные эмодзи: сообщение из одних эмодзи показывается живым (анимации Noto, как в Telegram) ===== */
function bemoParts(t){ t=String(t||'').trim(); try{ return [...new Intl.Segmenter(undefined,{granularity:'grapheme'}).segment(t)].map(x=>x.segment).filter(s=>s.trim()); }catch(e){ return [...t].filter(s=>s.trim()); } }
function bemoCode(g){ return [...g].map(c=>c.codePointAt(0).toString(16)).join('_'); }
function bemoHtml(t){ const gs=bemoParts(t); const sz=gs.length===1?128:gs.length===2?96:gs.length===3?76:58;
return gs.map(g=>`<img class="bemo" width="${sz}" height="${sz}" alt="${esc(g)}" draggable="false" src="https://fonts.gstatic.com/s/e/notoemoji/latest/${bemoCode(g)}/512.webp">`).join(''); }
document.addEventListener('error',e=>{ const img=e.target; if(!img||!img.classList||!img.classList.contains('bemo')) return;
  const m=img.src.match(/latest\/([^/]+)\//); const c=m&&m[1];
  // у части эмодзи файл без «fe0f» — пробуем так; нет анимации — обычное эмодзи, но тоже живое
  if(c&&c.includes('_fe0f')&&!img.dataset.r){ img.dataset.r='1'; img.src=img.src.replace(c,c.replace(/_fe0f/g,'')); return; }
  const s=document.createElement('span'); s.className='bemo-t'; s.textContent=img.alt; s.style.fontSize=Math.round(img.width*0.78)+'px'; img.replaceWith(s);
},true);
document.addEventListener('click',e=>{ const b=e.target.closest&&e.target.closest('.bemo,.bemo-t'); if(!b) return; b.classList.remove('bpop'); void b.offsetWidth; b.classList.add('bpop'); },true);
(function(){ const st=document.createElement('style'); st.textContent='.bemo{display:inline-block;object-fit:contain;vertical-align:bottom;user-select:none;-webkit-user-drag:none;animation:bemoIn .35s cubic-bezier(.2,1.6,.4,1)}.bemo-t{display:inline-block;line-height:1;animation:bemoIn .35s cubic-bezier(.2,1.6,.4,1),bemoBob 1.6s ease-in-out .35s infinite}.bpop{animation:bemoPop .5s cubic-bezier(.2,1.6,.4,1)!important}@keyframes bemoIn{from{transform:scale(.3);opacity:0}to{transform:scale(1);opacity:1}}@keyframes bemoPop{0%{transform:scale(1)}40%{transform:scale(1.25) rotate(-6deg)}100%{transform:scale(1)}}@keyframes bemoBob{0%,100%{transform:translateY(0) scale(1)}30%{transform:translateY(-6%) scale(1.06)}60%{transform:translateY(0) scale(.97)}}@media (prefers-reduced-motion:reduce){.bemo,.bemo-t{animation:none!important}}'; document.head.appendChild(st); })();

/* ===== Шапка чата «жидкое стекло», как на iPhone ===== */
(function(){ const st=document.createElement('style'); st.textContent="#chathead{background:transparent!important;backdrop-filter:none!important;-webkit-backdrop-filter:none!important;border-bottom:0!important;gap:8px!important;padding-left:12px!important;padding-right:12px!important}#chathead>.ib,#chathead .who{background:color-mix(in srgb,var(--panel) 72%,transparent);-webkit-backdrop-filter:blur(22px) saturate(1.7);backdrop-filter:blur(22px) saturate(1.7);border:1px solid rgba(255,255,255,.13);box-shadow:0 8px 24px rgba(0,0,0,.35),inset 0 1px 0 rgba(255,255,255,.09)}:root[data-theme=\"light\"] #chathead>.ib,:root[data-theme=\"light\"] #chathead .who{background:color-mix(in srgb,var(--panel) 76%,transparent);border-color:rgba(255,255,255,.85);box-shadow:0 8px 24px rgba(40,30,90,.12),inset 0 1px 0 rgba(255,255,255,.9)}#chathead>.ib{width:50px;height:50px;min-width:50px;border-radius:25px;display:grid;place-items:center;transition:transform .15s}#chathead>.ib:active{transform:scale(.92)}#chathead #back{order:0}#chathead .who{order:1}#hCall{order:2}#hVideo{order:3}#hSearch{order:4}#hMore{order:5}#chathead .who{height:56px;border-radius:28px;padding:5px 14px 5px 5px;gap:10px!important;flex:1;min-width:0;transition:transform .15s}#chathead .who:active{transform:scale(.98)}#chathead .who>div:last-child{flex:1;min-width:0;text-align:center}#chathead .who .nm{justify-content:center}#chathead .e2elk{display:none!important}#chathead #hSearch{display:none!important}#hCall:not(.hidden){width:54px;border-radius:25px 0 0 25px;border-right:0;padding-left:6px;clip-path:inset(-30px 0 -30px -30px)}#hCall:not(.hidden)~#hVideo:not(.hidden){width:54px;border-radius:0 25px 25px 0;border-left:0;margin-left:-8px;padding-right:6px;clip-path:inset(-30px -30px -30px 0)}#chathead>#hSearch,#chathead>#hMore{width:44px;height:44px;min-width:44px;border-radius:22px}@media (max-width:520px){#chathead{gap:6px!important;padding-left:8px!important;padding-right:8px!important}#chathead>#hSearch,#chathead>#hMore{width:40px;height:40px;min-width:40px}#hCall:not(.hidden),#hCall:not(.hidden)~#hVideo:not(.hidden){width:48px}}"; document.head.appendChild(st); })();

/* ===== Профиль (панель справа) открывается и закрывается плавно ===== */
(function(){ const el=document.getElementById('info'); if(!el||!el.animate) return;
  let busy=false, wasHidden=el.classList.contains('hidden');
  const off=()=>innerWidth<=800?'100%':'48px';
  const reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;
  new MutationObserver(()=>{ const h=el.classList.contains('hidden'); if(busy||h===wasHidden) return;
    if(reduce){ wasHidden=h; return; }
    if(!h){ wasHidden=false;
      el.animate([{transform:`translateX(${off()})`,opacity:0},{transform:'none',opacity:1}],{duration:340,easing:'cubic-bezier(.2,.9,.25,1)'});
      const kids=[...el.children].slice(0,6);
      kids.forEach((k,i)=>k.animate([{transform:'translateY(10px)',opacity:0},{transform:'none',opacity:1}],{duration:380,delay:60+i*35,easing:'cubic-bezier(.2,.9,.25,1)',fill:'backwards'}));
    } else { busy=true; el.classList.remove('hidden');
      const a=el.animate([{transform:'none',opacity:1},{transform:`translateX(${off()})`,opacity:0}],{duration:230,easing:'cubic-bezier(.4,0,.8,.4)',fill:'forwards'});
      a.onfinish=()=>{ el.classList.add('hidden'); a.cancel(); wasHidden=true; busy=false; };
    }
  }).observe(el,{attributes:true,attributeFilter:['class']});
})();

/* ===== Интерфейс: закреплённые чаты кружками, заготовки при загрузке, «@» к упоминаниям, стеклянные кнопки ===== */
function pinRowHtml(L){ if(!L.length) return '';
  return `<div class="pinrow">${L.map(c=>{ const nm=c.type==='private'&&c.peer_id===S.me.id?'Избранное':String(chatName(c)).split(' ')[0];
    return `<div class="pinb" data-pin="${c.chat_id}" title="${esc(chatName(c))}"><div class="pav">${chatAv(c)}${c.unread>0?`<b class="${c.muted?'mute':''}">${c.unread>99?'99+':c.unread}</b>`:''}</div><span class="${c.unread>0?'u':''}">${esc(nm)}</span></div>`; }).join('')}</div>`; }
document.addEventListener('click',e=>{ const b=e.target.closest&&e.target.closest('.pinb'); if(!b) return; e.stopPropagation(); openChat(b.dataset.pin); },true);
function skelHtml(){ let h=''; for(let i=0;i<8;i++) h+=`<div class="skr" style="animation-delay:${i*80}ms"><i></i><div><s></s><s></s></div></div>`; return h; }
(function(){
  const st=document.createElement('style');
  st.textContent=".pinrow{display:flex;gap:10px;overflow-x:auto;padding:6px 10px 8px;scrollbar-width:none}.pinrow::-webkit-scrollbar{display:none}"
  +".pinb{width:68px;flex:none;display:flex;flex-direction:column;align-items:center;gap:5px;cursor:pointer;border-radius:16px;padding:4px 0;transition:transform .15s}.pinb:active{transform:scale(.94)}"
  +".pinb .pav{position:relative}.pinb .av{width:58px;height:58px;font-size:20px}.pinb .pav b{position:absolute;top:-3px;right:-5px;min-width:20px;height:20px;padding:0 5px;border-radius:10px;background:var(--a1);color:#fff;font-size:11px;font-weight:800;display:grid;place-items:center;border:2px solid var(--bg)}.pinb .pav b.mute{background:#a3a6b8}"
  +".pinb span{font-size:12px;color:var(--text);max-width:68px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.pinb span.u{font-weight:700}"
  +".skr{display:flex;align-items:center;gap:12px;padding:10px 14px;animation:skp .9s ease-in-out infinite alternate}.skr i{width:54px;height:54px;border-radius:50%;background:color-mix(in srgb,var(--text) 8%,transparent);flex:none}.skr div{display:flex;flex-direction:column;gap:9px;flex:1}.skr s{display:block;height:12px;width:140px;border-radius:6px;background:color-mix(in srgb,var(--text) 8%,transparent)}.skr s+s{height:10px;width:min(220px,70%);background:color-mix(in srgb,var(--text) 6%,transparent)}@keyframes skp{to{opacity:.45}}"
  +"#down,#mentBtn{background:color-mix(in srgb,var(--panel) 72%,transparent)!important;-webkit-backdrop-filter:blur(20px) saturate(1.6);backdrop-filter:blur(20px) saturate(1.6);border:1px solid rgba(255,255,255,.14);color:var(--text)!important;transition:transform .15s,opacity .2s}#down:active,#mentBtn:active{transform:scale(.92)}"
  +":root[data-theme=\"light\"] #down,:root[data-theme=\"light\"] #mentBtn{border-color:rgba(255,255,255,.85)}"
  +"#mentBtn{position:absolute;right:20px;bottom:148px;width:48px;height:48px;border-radius:50%;box-shadow:var(--shadow);display:grid;place-items:center;z-index:4;font-size:21px;font-weight:800;color:var(--a1)!important;cursor:pointer}#mentBtn .badge{position:absolute;top:-6px;right:-4px}#mentBtn.nodown{bottom:90px}"
  +".day span{background:color-mix(in srgb,var(--panel) 70%,transparent)!important;-webkit-backdrop-filter:blur(16px) saturate(1.5);backdrop-filter:blur(16px) saturate(1.5);color:var(--text)!important;border:1px solid rgba(255,255,255,.12)}";
  document.head.appendChild(st);
  // «@» — непрочитанные сообщения, где упомянули меня
  const btn=document.createElement('button'); btn.id='mentBtn'; btn.className='hidden'; btn.type='button';
  const down=document.getElementById('down'); if(down&&down.parentNode) down.parentNode.insertBefore(btn,down);
  let chatAt=null, since=0; const seen=new Set();
  function pending(){ const u=S.me&&S.me.username; if(!u||!S.cur) return [];
    if(chatAt!==S.cur){ chatAt=S.cur; seen.clear(); const c=S.chatMap&&S.chatMap.get(S.cur); since=c&&c.last_read_at?new Date(c.last_read_at).getTime():Date.now(); }
    const tag='@'+u.toLowerCase(), box=document.getElementById('msgs'); const r=box?box.getBoundingClientRect():null;
    return (S.msgs.get(S.cur)||[]).filter(m=>{ if(m.sender_id===S.me.id||m.deleted||seen.has(m.id)) return false;
      if(new Date(m.created_at).getTime()<=since||!String(m.body||'').toLowerCase().includes(tag)) return false;
      const el=r&&document.querySelector(`.m[data-id="${m.id}"]`); if(el){ const q=el.getBoundingClientRect(); if(q.bottom>r.top&&q.top<r.bottom){ seen.add(m.id); return false; } }
      return true; }); }
  setInterval(()=>{ if(document.hidden) return; const p=pending(); btn.classList.toggle('hidden',!p.length);
    btn.classList.toggle('nodown',!down||down.classList.contains('hidden'));
    btn.innerHTML='@'+(p.length?`<span class="badge">${p.length}</span>`:''); btn._first=p.length?p[0].id:null; },700);
  btn.onclick=()=>{ if(btn._first){ seen.add(btn._first); jumpTo(btn._first); } };
})();

/* ===== Приглашения: ссылка lumomess.ru/#ref=юзернейм — после входа новичку и пригласившему по 25 люменов ===== */
(function(){ const m=location.hash.match(/^#ref=([a-z0-9_]{3,})/i); if(!m) return;
  try{ localStorage.setItem('lm_ref',m[1]); }catch(e){}
  try{ history.replaceState(null,'',location.pathname+location.search); }catch(e){} })();
(function refWait(){ let r=null; try{ r=localStorage.getItem('lm_ref'); }catch(e){} if(!r) return;
  if(!(S&&S.me&&S.me.id)) { setTimeout(refWait,2000); return; }
  sb.rpc('lm_claim_referral',{p_username:r}).then(({data})=>{ try{ localStorage.removeItem('lm_ref'); }catch(e){}
    if(data&&data.ok) toast('Вам и пригласившему начислено по 25 люменов'); },()=>{}); })();

/* ===== Игры: свернуть игру полоской вниз, баннер о сообщениях во время игры ===== */
(function(){
  const st=document.createElement('style');
  st.textContent="#lgOv .lgbar{display:none;position:absolute;left:0;right:0;top:0;height:64px;z-index:3;align-items:center;gap:12px;padding:0 12px;background:var(--panel);cursor:pointer}"
  +"#lgOv.mini .lgbar{display:flex}#lgOv .lgbar i{width:40px;height:40px;border-radius:12px;display:grid;place-items:center;flex:none}#lgOv .lgbar i svg{width:24px;height:24px}"
  +"#lgOv .lgbar b{display:block;font-size:15px;color:var(--text)}#lgOv .lgbar span{display:block;font-size:13px;color:var(--muted)}#lgOv .lgbar span.me{color:var(--a1)}"
  +"#lgOv .lgbar em{margin-left:auto;width:34px;height:34px;border-radius:50%;display:grid;place-items:center;background:color-mix(in srgb,var(--text) 7%,transparent);color:var(--muted);font-style:normal}"
  +"#lgOv.mini{top:auto!important;bottom:calc(env(safe-area-inset-bottom) + 84px)!important;left:50%!important;width:min(480px,calc(100vw - 20px))!important;height:64px!important;border-radius:20px!important;overflow:hidden;transform:translateX(-50%)!important;opacity:1!important;box-shadow:0 14px 34px rgba(0,0,0,.3);transition:all .45s cubic-bezier(.2,.9,.25,1)!important}"
  +"#lgOv.mini iframe{pointer-events:none}"
  +"@media (min-width:900px){#lgOv.mini{left:auto!important;right:20px;bottom:20px!important;transform:none!important;width:360px!important}}"
  +"#lgBan{position:fixed;left:50%;top:calc(env(safe-area-inset-top) + 10px);transform:translate(-50%,-140%);width:min(460px,calc(100vw - 20px));z-index:2147483600;display:flex;align-items:center;gap:12px;padding:12px;border-radius:20px;background:var(--panel);box-shadow:0 14px 34px rgba(0,0,0,.35);cursor:pointer;transition:transform .35s cubic-bezier(.2,.9,.3,1)}"
  +"#lgBan.on{transform:translate(-50%,0)}#lgBan b{display:block;font-size:15px}#lgBan span{display:block;font-size:14px;color:var(--muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;max-width:340px}";
  document.head.appendChild(st);
  function ov(){ return document.getElementById('lgOv'); }
  function mini(on){ const o=ov(); if(!o) return; const fr=o.querySelector('iframe');
    if(on){ if(fr&&!fr.style.height) fr.style.height=o.offsetHeight+'px'; o.classList.add('mini'); document.getElementById('lgBg')?.classList.remove('on'); }
    else { o.classList.remove('mini'); document.getElementById('lgBg')?.classList.add('on'); setTimeout(()=>{ if(fr&&!o.classList.contains('mini')) fr.style.height=''; },460); } }
  window.lgMini=mini;
  addEventListener('message',e=>{ const d=e.data&&e.data.lumoGame; if(typeof d!=='string') return; const o=ov(); if(!o) return;
    if(d==='minimize') mini(true);
    else if(d.indexOf('info|')===0){ const p=d.split('|'); let bar=o.querySelector('.lgbar');
      if(!bar){ bar=document.createElement('div'); bar.className='lgbar'; o.appendChild(bar); bar.onclick=()=>mini(false); }
      bar.innerHTML=`<i style="background:${LG_COL[p[3]]||'var(--a1)'}">${lgIcon(p[3])}</i><div><b>${esc(p[1])}</b><span class="${p[2].indexOf('Ваш ход')===0?'me':''}">${esc(p[2])}</span></div><em><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 15l6-6 6 6"/></svg></em>`; } });
  // сообщение из другого чата, пока открыта игра: баннер сверху, нажать — игра вниз, чат открыт
  const _notify=notify;
  notify=function(m){ try{ const o=ov(); if(o&&!o.classList.contains('mini')&&m&&m.kind!=='call'){ const c=S.chatMap.get(m.chat_id); if(c) lgBanner(m,c); } }catch(e){} return _notify.apply(this,arguments); };
  let banT=0;
  function lgBanner(m,c){ let b=document.getElementById('lgBan'); if(!b){ b=document.createElement('div'); b.id='lgBan'; document.body.appendChild(b); }
    const txt=m.kind==='text'?(m.body||''):({image:'Фото',video:'Видео',voice:'Голосовое сообщение',video_note:'Видеосообщение',sticker:'Стикер',game:'Приглашение в игру'})[m.kind]||'Сообщение';
    b.innerHTML=`${chatAv(c)}<div style="min-width:0"><b>${esc(chatName(c))}</b><span>${esc(txt)}</span></div>`;
    b.onclick=()=>{ b.classList.remove('on'); mini(true); openChat(m.chat_id); };
    requestAnimationFrame(()=>b.classList.add('on')); clearTimeout(banT); banT=setTimeout(()=>b.classList.remove('on'),4500); }
})();

/* ===== Политика конфиденциальности и согласие (152-ФЗ) ===== */
(()=>{
const POL="<h1>Политика конфиденциальности Lumo</h1>\n<p>Редакция от 13 ноября 2026 года</p>\n<p>Эта политика объясняет, какие персональные данные обрабатывает мессенджер Lumo (приложения для iPhone, Android, Windows и веб-версия на lumomess.ru), зачем, сколько хранит и как их удалить. Политика составлена в соответствии с Федеральным законом № 152-ФЗ «О персональных данных».</p>\n<h2>1. Оператор</h2>\n<p>Оператор персональных данных: Закиров Эмиль Ильшатович, применяющий специальный налоговый режим «Налог на профессиональный доход».</p>\n<p>ИНН: 770381855415.</p>\n<p>Адрес для обращений по персональным данным: lumomessage@gmail.com.</p>\n<h2>2. Какие данные мы обрабатываем</h2>\n<p><b>Данные аккаунта.</b> Юзернейм, пароль (хранится только в виде необратимого хеша), имя и фамилия, описание «о себе», дата рождения (если вы её укажете), фото или видео профиля, оформление профиля.</p>\n<p><b>Номер телефона</b> — если вы входите по номеру или привязываете его к аккаунту.</p>\n<p><b>Контакты из телефонной книги</b> — только если вы разрешите доступ. Номера используются, чтобы показать, кто из ваших знакомых уже есть в Lumo, и сразу добавить их в контакты. Без разрешения Lumo работает полностью.</p>\n<p><b>Сообщения и файлы.</b> Текст сообщений, фото, видео, голосовые и видеосообщения, файлы, истории, реакции, которые вы отправляете. Текст сообщений в личных чатах защищён сквозным шифрованием: ключ хранится только на ваших устройствах, оператор не может прочитать такие сообщения. Сообщения в группах и каналах хранятся на сервере в незашифрованном виде, чтобы их видели все участники.</p>\n<p><b>Звонки.</b> Время, длительность и участники звонка. Звук и видео звонков не записываются и не сохраняются. Звонки один на один идут напрямую между устройствами, групповые — через сервер звонков без записи.</p>\n<p><b>Подтверждение личности (по желанию).</b> Если вы подаёте заявку на отметку «подтверждён», вы отправляете фото документа и селфи с кодом. Эти фото хранятся в закрытом хранилище, доступны только модераторам по временной ссылке и удаляются сразу после решения по заявке.</p>\n<p><b>Люмены, подарки и Premium.</b> Баланс, история начислений и списаний, полученные и отправленные подарки, статус подписки.</p>\n<p><b>Технические данные.</b> IP-адрес, модель и система устройства, версия приложения, время входа и последней активности, список устройств с выполненным входом, ключи для отправки уведомлений, отчёты о сбоях приложения.</p>\n<p><b>Связь с Telegram (по желанию).</b> Идентификатор Telegram — если вы включите уведомления или вход через Telegram.</p>\n<p>Мы не продаём данные, не показываем рекламу и не передаём данные рекламным сетям.</p>\n<h2>3. Зачем мы обрабатываем данные</h2>\n<ul>\n<li>чтобы вы могли зарегистрироваться, войти и пользоваться мессенджером: переписываться, звонить, создавать группы и каналы;</li>\n<li>чтобы доставлять сообщения и уведомления на все ваши устройства;</li>\n<li>чтобы защищать аккаунты и пользователей: выявлять взлом, спам и мошенничество, рассматривать жалобы, блокировать нарушителей;</li>\n<li>чтобы подтверждать личность по вашей заявке;</li>\n<li>чтобы находить и исправлять ошибки в работе приложения.</li>\n</ul>\n<h2>4. Основания обработки</h2>\n<ul>\n<li>исполнение пользовательского соглашения, стороной которого вы являетесь (п. 5 ч. 1 ст. 6 152-ФЗ), — для работы мессенджера;</li>\n<li>ваше согласие (п. 1 ч. 1 ст. 6 152-ФЗ) — для контактов из телефонной книги, подтверждения личности и связи с Telegram. Согласие можно отозвать в любой момент.</li>\n</ul>\n<p>Согласие на обработку данных вы даёте при регистрации, отметив соответствующий пункт.</p>\n<h2>5. Где хранятся данные и кому передаются</h2>\n<p>Данные хранятся на серверах облачной платформы Supabase. Серверы находятся в Ирландии (Европейский союз, регион eu-west-1). Ирландия — участник Конвенции Совета Европы о защите физических лиц при автоматизированной обработке персональных данных, то есть страна с адекватной защитой прав субъектов персональных данных; хранение данных там является трансграничной передачей, о которой оператор уведомляет Роскомнадзор.</p>\n<p>Для работы сервиса данные передаются только:</p>\n<ul>\n<li>другим пользователям, с которыми вы переписываетесь, в объёме, который вы сами отправляете и разрешаете в настройках конфиденциальности;</li>\n<li>сервисам доставки уведомлений операционных систем — служебный ключ устройства и текст уведомления (уведомления можно отключить или скрыть их текст в настройках);</li>\n<li>в Telegram — уведомления о новых сообщениях, только если вы сами включили эту функцию;</li>\n<li>серверу групповых звонков LiveKit — только во время звонка, без записи.</li>\n</ul>\n<h2>6. Сколько хранятся данные</h2>\n<ul>\n<li>данные аккаунта, сообщения и файлы — пока существует аккаунт;</li>\n<li>сообщения, которые вы удалили «у всех», удаляются с сервера;</li>\n<li>фото для подтверждения личности — до решения по заявке, но не дольше 3 дней;</li>\n<li>технические журналы и отчёты о сбоях — не дольше 1 года.</li>\n</ul>\n<h2>7. Как удалить данные</h2>\n<p>Удалить аккаунт можно прямо в приложении: на телефоне — Настройки → Изменить профиль → Удалить аккаунт, в приложении для Windows — Настройки → Приватность → Удалить аккаунт, в веб-версии — Настройки → Профиль → Удалить аккаунт. При удалении безвозвратно удаляются профиль, загруженные вами файлы, личные чаты и ключ входа. Сообщения, которые вы отправили в группы и каналы, остаются у их участников; их можно удалить «у всех» до удаления аккаунта или по запросу на адрес ниже.</p>\n<p>Вы также можете написать на lumomessage@gmail.com, чтобы узнать, какие ваши данные мы обрабатываем, уточнить, исправить или удалить их, отозвать согласие. Мы ответим в течение 10 рабочих дней.</p>\n<h2>8. Защита данных</h2>\n<p>Соединение с сервером шифруется (HTTPS). Текст личных сообщений защищён сквозным шифрованием. Пароли хранятся только в виде хеша. Доступ к данным на сервере ограничен правилами, которые разрешают каждому пользователю видеть только свои чаты.</p>\n<h2>9. Дети</h2>\n<p>Lumo не предназначен для детей младше 14 лет. Если вы узнали, что ребёнок младше 14 лет зарегистрировался без согласия родителей, напишите нам — мы удалим аккаунт.</p>\n<h2>10. Изменения политики</h2>\n<p>Мы можем обновлять эту политику. Новая редакция публикуется в приложении и на lumomess.ru/?privacy, дата редакции указывается вверху.</p>";
const st=document.createElement('style');
st.textContent=`#polv{position:fixed;inset:0;z-index:99999;background:var(--bg,#0c0d1a);color:var(--text,#eef0ff);overflow:auto;font:15px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif}
#polv .pw{max-width:760px;margin:0 auto;padding:22px 20px 60px}#polv h1{font-size:26px;margin:8px 0 6px}#polv h2{font-size:18px;margin:22px 0 6px}
#polv p,#polv li{color:var(--text,#eef0ff);opacity:.92}#polv ul{padding-left:20px}#polv .pc{position:sticky;top:0;display:flex;justify-content:flex-end;padding:12px 16px;background:inherit}
#polv .pc button{border:0;border-radius:99px;width:38px;height:38px;background:rgba(255,255,255,.1);color:inherit;font-size:18px;cursor:pointer}
.lmagree{display:flex;gap:9px;align-items:flex-start;font-size:13px;line-height:1.4;color:var(--muted,#8d90b8);margin:8px 2px 2px;text-align:left}
.lmagree input{margin-top:2px;width:17px;height:17px;accent-color:var(--a1,#7c5cff);flex:none}.lmagree a{color:var(--a1,#7c5cff);font-weight:600;cursor:pointer;text-decoration:none}`;
document.head.appendChild(st);
window.lmPolicy=(page)=>{ let d=document.getElementById('polv'); if(d) d.remove(); d=document.createElement('div'); d.id='polv';
  d.innerHTML=(page?'':'<div class="pc"><button aria-label="Закрыть">✕</button></div>')+'<div class="pw">'+POL+'</div>';
  const b=d.querySelector('.pc button'); if(b) b.onclick=()=>d.remove(); document.body.appendChild(d); };
if(/[?&]privacy\b/.test(location.search)) { lmPolicy(true); document.title='Политика конфиденциальности — Lumo'; }
const ins=()=>{
  const err=document.getElementById('aErr'); if(!err||document.getElementById('aAgree')) return;
  const w=document.createElement('label'); w.className='lmagree'; w.id='aAgreeW';
  w.innerHTML='<input type="checkbox" id="aAgree"><span>Принимаю <a id="aPolL">Политику конфиденциальности</a> и даю согласие на обработку моих персональных данных</span>';
  err.parentNode.insertBefore(w,err);
  document.getElementById('aPolL').onclick=e=>{ e.preventDefault(); e.stopPropagation(); lmPolicy(); };
};
ins(); setTimeout(ins,600);
const need=()=>{ const c=document.getElementById('aAgree'); if(c&&!c.checked){ const e=document.getElementById('aErr'); if(e) e.textContent='Чтобы продолжить, примите Политику конфиденциальности'; return true; } return false; };
// регистрация (кнопка, Enter) и вход через Telegram
document.addEventListener('submit',e=>{ if(typeof regMode!=='undefined'&&regMode&&need()){ e.preventDefault(); e.stopImmediatePropagation(); } },true);
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('#aBtn,#tgLogin,#tgLoginBtn,.tglogin'); if(!t) return;
  if((t.id==='aBtn'&&typeof regMode!=='undefined'&&regMode)||t.id!=='aBtn'){ if(need()){ e.preventDefault(); e.stopImmediatePropagation(); } } },true);
// ссылка в настройках — рядом с «Удалить аккаунт»
const setLink=()=>{ const del=document.getElementById('sDelAcc'); if(!del||document.getElementById('sPolicy')) return;
  const r=document.createElement('div'); r.className='perow'; r.id='sPolicy'; r.textContent='Политика конфиденциальности'; r.onclick=()=>lmPolicy();
  del.parentNode.insertBefore(r,del); };
new MutationObserver(setLink).observe(document.body,{childList:true,subtree:true});
})();




boot();
})();

}
