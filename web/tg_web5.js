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
