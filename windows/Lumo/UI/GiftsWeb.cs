using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.Web.WebView2.Core;

namespace Lumo.UI;

/// <summary>
/// Подарки для ПК: живая страница (анимированные подарки, блики, конфетти) во встроенном веб-движке.
/// Покупка, скрытие, продажа и баланс — через сообщения странице и обратно.
/// </summary>
public sealed class GiftsWeb : Grid, IFillPage
{
    readonly WebView2 web = new() { DefaultBackgroundColor = Microsoft.UI.Colors.Transparent };
    readonly string? to;
    readonly Action openWallet;
    readonly Action? done;
    bool ready;

    public GiftsWeb(string? to, Action openWallet, Action? done = null)
    {
        this.to = to; this.openWallet = openWallet; this.done = done;
        Background = T.ChatBg;
        Children.Add(web);
        Loaded += async (_, _) => { if (!ready) await Init(); };
    }

    async Task Init()
    {
        ready = true;
        try
        {
            await WebEnv.Setup(web);
            var cw = web.CoreWebView2;
            File.WriteAllText(Path.Combine(WebEnv.WebDir, "gifts.html"), Html);
            cw.WebMessageReceived += async (_, e) => await OnMsg(e.TryGetWebMessageAsString());
            cw.NavigationCompleted += async (_, _) => await Push();
            cw.Navigate("https://lumo.web.local/gifts.html");
        }
        catch (Exception e) { App.Log("gifts web: " + e); Children.Add(T.Txt("Не удалось открыть подарки: " + e.Message, 13, T.Danger)); }
    }

    static JsonObject GiftJson(string id, string name, string rarity)
    {
        var j = new JsonObject { ["id"] = id, ["name"] = name, ["rarity"] = rarity, ["rarityName"] = Gifts.RarityName(rarity) };
        var png = Path.Combine(AppContext.BaseDirectory, "Assets", "gifts", "gift_" + id + ".png");
        if (File.Exists(png)) j["img"] = "https://lumo.app.local/gifts/gift_" + id + ".png";
        else if (Gifts.Svg(id) is string svg) j["img"] = "data:image/svg+xml;base64," + Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(svg));
        return j;
    }

    /// <summary>Отправить странице свежие данные: каталог, мои подарки, баланс</summary>
    public async Task Push(string? celebrate = null)
    {
        try
        {
            await Gifts.LoadCatalog();
            var bal = await Gifts.Balance();
            var mine = to == null ? await Gifts.Owned(null) : new List<OwnedGift>();
            await Store.LoadProfiles(mine.Where(x => x.From != null).Select(x => x.From!).Distinct().ToList());
            var cat = new JsonArray();
            foreach (var g in Gifts.Catalog)
            {
                var j = GiftJson(g.Id, g.Name, g.Rarity);
                j["price"] = g.Price; j["supply"] = g.Supply; j["left"] = g.Left;
                cat.Add(j);
            }
            var my = new JsonArray();
            foreach (var g in mine)
            {
                var j = GiftJson(g.GiftId, g.Name, g.Rarity);
                j["owned"] = g.Id; j["serial"] = g.Serial; j["supply"] = g.Supply; j["hidden"] = g.Hidden;
                j["from"] = g.From != null ? Store.DisplayName(g.From) : null; j["sell"] = g.Price;
                my.Add(j);
            }
            var data = new JsonObject
            {
                ["to"] = to != null ? Store.DisplayName(to) : null,
                ["balance"] = bal, ["catalog"] = cat, ["mine"] = my, ["celebrate"] = celebrate,
            };
            await web.CoreWebView2.ExecuteScriptAsync("window.lumo && lumo.render(" + data.ToJsonString() + ")");
        }
        catch (Exception e) { App.Log("gifts push: " + e.Message); try { await web.CoreWebView2.ExecuteScriptAsync("window.lumo && lumo.error(" + JsonValue.Create(e.Message)!.ToJsonString() + ")"); } catch { } }
    }

    async Task OnMsg(string? raw)
    {
        if (raw == null) return;
        JsonNode? m; try { m = JsonNode.Parse(raw); } catch { return; }
        var t = m.Str("t");
        switch (t)
        {
            case "wallet": openWallet(); break;
            case "buy":
            {
                var g = Gifts.Catalog.FirstOrDefault(x => x.Id == m.Str("id")); if (g == null) return;
                var target = to;
                if (target == null) { target = await Gifts.PickRecipient(); if (target == null) { await Push(); return; } if (target == "") target = null; }
                var ok = await Gifts.Buy(g, target);
                await Push(ok ? g.Id : null);
                if (ok && to != null && done != null) { await Task.Delay(1600); done(); }
                break;
            }
            case "hide":
            {
                try { await Api.Rpc("lm_gift_hide", new JsonObject { ["p_owned_id"] = m.Int("id"), ["p_hidden"] = m.Bool("hidden") }); } catch (Exception e) { Store.Say(e.Message); }
                await Push(); break;
            }
            case "sell":
            {
                if (App.Win == null || !await Dialogs.Confirm(App.Win, "Продать подарок?", "Продать", "Люмены вернутся на баланс")) { await Push(); return; }
                try { var r = await Api.Rpc("lm_gift_sell", new JsonObject { ["p_owned_id"] = m.Int("id") }); Store.Say("Продано · +" + (r.Int("refund") ?? 0) + " люменов"); }
                catch (Exception e) { Store.Say(e.Message); }
                await Push(); break;
            }
        }
    }

    const string Html = """
<!doctype html><html lang="ru"><head><meta charset="utf-8">
<style>
:root{--bg:#0e0f22;--panel:#16173a;--panel2:#1d1f45;--text:#eef0ff;--muted:#8d90b8;--a1:#7c5cff;--a2:#22c1ff;--gold:#f5b942}
*{box-sizing:border-box}html,body{margin:0;background:transparent;color:var(--text);font-family:"Segoe UI Variable Text","Segoe UI",sans-serif;-webkit-user-select:none;user-select:none}
body{padding:6px 28px 40px;overflow-x:hidden}
.top{display:flex;align-items:center;gap:16px;margin-bottom:18px}
.top h2{margin:0;font-size:15px;font-weight:600;color:var(--muted);flex:1}
.top h2 b{color:var(--text)}
.bal{display:flex;align-items:center;gap:8px;padding:9px 14px 9px 10px;border-radius:16px;background:linear-gradient(135deg,rgba(245,185,66,.18),rgba(245,185,66,.06));border:1px solid rgba(245,185,66,.35);cursor:pointer;transition:transform .18s,box-shadow .18s}
.bal:hover{transform:translateY(-1px);box-shadow:0 6px 24px rgba(245,185,66,.25)}.bal:active{transform:scale(.96)}
.bal .n{font-weight:800;font-size:17px;color:var(--gold)}.bal .l{font-size:11px;color:var(--muted);line-height:1}.bal .ar{color:var(--muted);font-size:14px;margin-left:2px}
.gem{width:22px;height:22px;filter:drop-shadow(0 0 6px rgba(245,185,66,.6))}
.tabs{position:relative;display:inline-flex;background:var(--panel);border-radius:14px;padding:4px;margin-bottom:20px}
.tabs button{position:relative;z-index:1;border:0;background:none;color:var(--muted);font:600 14px inherit;font-family:inherit;padding:9px 20px;cursor:pointer;transition:color .2s}
.tabs button.on{color:#fff}.tabs .ind{position:absolute;top:4px;bottom:4px;border-radius:11px;background:linear-gradient(135deg,var(--a1),var(--a2));transition:left .35s cubic-bezier(.2,.9,.3,1.2),width .35s cubic-bezier(.2,.9,.3,1.2)}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:16px}
.card{position:relative;border-radius:22px;padding:14px 14px 16px;background:var(--panel);overflow:hidden;cursor:default;transition:transform .25s cubic-bezier(.2,.9,.3,1.3),box-shadow .25s;opacity:0;transform:translateY(16px) scale(.97);animation:in .5s cubic-bezier(.2,.9,.3,1.1) forwards}
.card:hover{transform:translateY(-4px) scale(1.02);box-shadow:0 14px 40px rgba(0,0,0,.45),0 0 0 1px rgba(255,255,255,.07)}
@keyframes in{to{opacity:1;transform:none}}
.stage{position:relative;height:150px;border-radius:16px;display:flex;align-items:center;justify-content:center;overflow:hidden}
.stage::before{content:"";position:absolute;inset:-40%;background:radial-gradient(circle at 50% 50%,rgba(255,255,255,.28),transparent 55%);animation:pulse 3.2s ease-in-out infinite}
@keyframes pulse{0%,100%{opacity:.55;transform:scale(.9)}50%{opacity:1;transform:scale(1.05)}}
.stage img{position:relative;width:118px;height:118px;object-fit:contain;filter:drop-shadow(0 10px 18px rgba(0,0,0,.45));animation:float 3.6s ease-in-out infinite}
@keyframes float{0%,100%{transform:translateY(0) rotate(-2deg)}50%{transform:translateY(-9px) rotate(2deg)}}
.card:hover .stage img{animation-duration:1.8s}
.shine::after{content:"";position:absolute;top:0;left:-60%;width:40%;height:100%;background:linear-gradient(100deg,transparent,rgba(255,255,255,.35),transparent);transform:skewX(-18deg);animation:shine 3.8s ease-in-out infinite}
@keyframes shine{0%,60%{left:-60%}100%{left:130%}}
.spark{position:absolute;width:4px;height:4px;border-radius:50%;background:#fff;opacity:0;animation:tw 2.4s ease-in-out infinite}
@keyframes tw{0%,100%{opacity:0;transform:scale(.4)}50%{opacity:.9;transform:scale(1)}}
.r-common{background:linear-gradient(140deg,#3b3f7a,#5a5f9a)}.r-rare{background:linear-gradient(140deg,#1d6fb8,#45aaf2)}.r-epic{background:linear-gradient(140deg,#6a3fc0,#a66cff)}
.r-legendary{background:linear-gradient(140deg,#e08a16,#f7c948)}.r-mythic{background:linear-gradient(140deg,#c8235a,#ff7ab6)}.r-ultra{background:linear-gradient(140deg,#0fb9b1,#7c5cff,#ff5bd1);background-size:200% 200%;animation:hue 6s ease infinite}
@keyframes hue{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
.name{font-weight:700;font-size:15px;margin:12px 2px 2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.meta{display:flex;align-items:center;gap:6px;font-size:12px;color:var(--muted);margin:0 2px}
.pill{font-size:10.5px;font-weight:700;padding:3px 8px;border-radius:9px;color:#fff;text-transform:uppercase;letter-spacing:.3px}
.bar{height:4px;border-radius:2px;background:rgba(255,255,255,.08);margin:10px 2px 0;overflow:hidden}.bar i{display:block;height:100%;border-radius:2px;background:linear-gradient(90deg,var(--a1),var(--a2))}
.buy{display:flex;align-items:center;justify-content:center;gap:7px;width:100%;margin-top:12px;border:0;border-radius:14px;padding:10px;font:700 14px inherit;font-family:inherit;color:#fff;background:linear-gradient(135deg,var(--a1),var(--a2));cursor:pointer;transition:transform .15s,filter .15s,box-shadow .2s}
.buy:hover{filter:brightness(1.12);box-shadow:0 8px 22px rgba(124,92,255,.45)}.buy:active{transform:scale(.95)}
.buy[disabled]{background:var(--panel2);color:var(--muted);cursor:default;box-shadow:none;filter:none}
.buy .gem{width:16px;height:16px}
.serial{position:absolute;top:10px;right:10px;z-index:2;font-size:11px;font-weight:800;padding:3px 8px;border-radius:9px;background:rgba(0,0,0,.45);backdrop-filter:blur(6px)}
.hidden .stage{filter:grayscale(.7) brightness(.6)}.hid{position:absolute;top:10px;left:10px;z-index:2;font-size:11px;padding:3px 8px;border-radius:9px;background:rgba(0,0,0,.45)}
.acts{display:flex;gap:8px;margin-top:12px}.acts button{flex:1;border:0;border-radius:12px;padding:9px 6px;font:600 12.5px inherit;font-family:inherit;color:var(--text);background:var(--panel2);cursor:pointer;transition:background .15s,transform .15s}
.acts button:hover{background:#262856}.acts button:active{transform:scale(.95)}.acts .sell{color:#ffcf6a}
.empty{text-align:center;padding:60px 20px;color:var(--muted)}.empty .big{width:120px;height:120px;margin:0 auto 14px;animation:float 3.6s ease-in-out infinite}
.empty b{display:block;color:var(--text);font-size:17px;margin-bottom:6px}
.load{display:flex;gap:6px;justify-content:center;padding:60px}.load i{width:9px;height:9px;border-radius:50%;background:var(--a1);animation:dot 1s infinite ease-in-out}.load i:nth-child(2){animation-delay:.15s}.load i:nth-child(3){animation-delay:.3s}
@keyframes dot{0%,100%{transform:scale(.5);opacity:.4}50%{transform:scale(1);opacity:1}}
canvas#fx{position:fixed;inset:0;pointer-events:none;z-index:50}
.toast{position:fixed;left:50%;bottom:30px;transform:translate(-50%,40px);opacity:0;padding:12px 20px;border-radius:16px;background:linear-gradient(135deg,var(--a1),var(--a2));font-weight:700;box-shadow:0 10px 30px rgba(0,0,0,.4);transition:all .4s cubic-bezier(.2,.9,.3,1.3);z-index:60}
.toast.on{transform:translate(-50%,0);opacity:1}
.err{color:#ff7a90;padding:30px;text-align:center}
</style></head><body>
<div class="top"><h2 id="who">Коллекционные подарки за люмены</h2>
<div class="bal" id="bal" title="Открыть люмены"><svg class="gem" viewBox="0 0 24 24"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffe08a"/><stop offset="1" stop-color="#f5a623"/></linearGradient></defs><path fill="url(#g)" d="M12 2l3.5 4H21l-9 16L3 6h5.5z"/><path fill="#fff" opacity=".45" d="M8.5 6L12 2l3.5 4z"/></svg>
<div><div class="n" id="balN">…</div><div class="l">люменов</div></div><span class="ar">›</span></div></div>
<div class="tabs" id="tabs"><span class="ind" id="ind"></span><button data-t="shop" class="on">Магазин</button><button data-t="mine">Мои подарки</button></div>
<div id="list"><div class="load"><i></i><i></i><i></i></div></div>
<canvas id="fx"></canvas><div class="toast" id="toast"></div>
<script>
const gem='<svg class="gem" viewBox="0 0 24 24"><path fill="#fff" d="M12 2l3.5 4H21l-9 16L3 6h5.5z"/></svg>';
const post=o=>{try{window.chrome.webview.postMessage(JSON.stringify(o))}catch(e){}};
let D=null,tab='shop';
const fmt=n=>Number(n).toLocaleString('ru-RU');
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const rare=r=>['legendary','mythic','ultra'].includes(r);
function sparks(r){if(!rare(r))return'';let s='';for(let i=0;i<7;i++)s+=`<span class="spark" style="left:${8+Math.random()*84}%;top:${8+Math.random()*80}%;animation-delay:${(Math.random()*2.4).toFixed(2)}s"></span>`;return s}
function art(g){return g.img?`<img src="${g.img}" alt="">`:`<svg viewBox="0 0 24 24" width="80" height="80"><path fill="#fff" d="M20 7h-2.2A3 3 0 0012 3.8 3 3 0 006.2 7H4a1 1 0 00-1 1v3a1 1 0 001 1h1v8a1 1 0 001 1h12a1 1 0 001-1v-8h1a1 1 0 001-1V8a1 1 0 00-1-1z"/></svg>`}
function indicator(){const b=document.querySelector('.tabs button.on');const ind=document.getElementById('ind');ind.style.left=b.offsetLeft+'px';ind.style.width=b.offsetWidth+'px'}
document.querySelectorAll('.tabs button').forEach(b=>b.onclick=()=>{tab=b.dataset.t;document.querySelectorAll('.tabs button').forEach(x=>x.classList.toggle('on',x===b));indicator();draw()});
document.getElementById('bal').onclick=()=>post({t:'wallet'});
function draw(){
 const L=document.getElementById('list');if(!D){return}
 if(tab==='shop'){
  if(!D.catalog.length){L.innerHTML='<div class="empty"><b>Магазин пуст</b>Скоро здесь появятся новые подарки</div>';return}
  L.innerHTML='<div class="grid">'+D.catalog.map((g,i)=>{const sold=g.supply>0&&g.left<=0,can=!sold&&D.balance>=g.price;
   const pct=g.supply>0?Math.max(3,Math.round(g.left/g.supply*100)):100;
   return `<div class="card" style="animation-delay:${i*45}ms"><div class="stage r-${g.rarity} ${rare(g.rarity)?'shine':''}">${sparks(g.rarity)}${art(g)}</div>
   <div class="name">${esc(g.name)}</div><div class="meta"><span class="pill r-${g.rarity}">${esc(g.rarityName)}</span>${g.supply>0?`<span>осталось ${fmt(g.left)} из ${fmt(g.supply)}</span>`:''}</div>
   ${g.supply>0?`<div class="bar"><i style="width:${pct}%"></i></div>`:''}
   <button class="buy" data-id="${esc(g.id)}" ${can?'':'disabled'} title="${can?'':(sold?'':'Не хватает люменов')}">${sold?'Раскуплено':gem+fmt(g.price)}</button></div>`}).join('')+'</div>';
  L.querySelectorAll('.buy:not([disabled])').forEach(b=>b.onclick=()=>{b.disabled=true;b.innerHTML='<span class="load" style="padding:0"><i></i><i></i><i></i></span>';post({t:'buy',id:b.dataset.id})});
 }else{
  if(!D.mine.length){L.innerHTML=`<div class="empty"><div class="big">${art({})}</div><b>Пока нет подарков</b>Купите первый в магазине — он появится здесь и в вашем профиле</div>`;return}
  L.innerHTML='<div class="grid">'+D.mine.map((g,i)=>`<div class="card ${g.hidden?'hidden':''}" style="animation-delay:${i*45}ms"><span class="serial">№${fmt(g.serial)}${g.supply?' из '+fmt(g.supply):''}</span>${g.hidden?'<span class="hid">скрыт</span>':''}
   <div class="stage r-${g.rarity} ${rare(g.rarity)?'shine':''}">${sparks(g.rarity)}${art(g)}</div>
   <div class="name">${esc(g.name)}</div><div class="meta">${g.from?'от '+esc(g.from):esc(g.rarityName)}</div>
   <div class="acts"><button data-a="hide" data-id="${g.owned}" data-h="${g.hidden?0:1}">${g.hidden?'Показать':'Скрыть'}</button>${g.sell?`<button class="sell" data-a="sell" data-id="${g.owned}">Продать · ${fmt(g.sell)}</button>`:''}</div></div>`).join('')+'</div>';
  L.querySelectorAll('.acts button').forEach(b=>b.onclick=()=>{b.disabled=true;post(b.dataset.a==='hide'?{t:'hide',id:+b.dataset.id,hidden:b.dataset.h==='1'}:{t:'sell',id:+b.dataset.id})});
 }
}
function toast(t){const e=document.getElementById('toast');e.textContent=t;e.classList.add('on');setTimeout(()=>e.classList.remove('on'),2200)}
function confetti(){const c=document.getElementById('fx'),x=c.getContext('2d');c.width=innerWidth;c.height=innerHeight;
 const cols=['#7c5cff','#22c1ff','#f5b942','#ff5b8a','#3ee0a0','#fff'];const P=[];for(let i=0;i<160;i++)P.push({x:c.width/2,y:c.height*0.45,vx:(Math.random()-.5)*16,vy:-Math.random()*15-4,s:Math.random()*7+4,r:Math.random()*6,vr:(Math.random()-.5)*.4,c:cols[i%cols.length],l:1});
 let f=0;(function step(){x.clearRect(0,0,c.width,c.height);P.forEach(p=>{p.vy+=.45;p.vx*=.99;p.x+=p.vx;p.y+=p.vy;p.r+=p.vr;p.l-=.008;x.save();x.globalAlpha=Math.max(0,p.l);x.translate(p.x,p.y);x.rotate(p.r);x.fillStyle=p.c;x.fillRect(-p.s/2,-p.s/4,p.s,p.s/2);x.restore()});if(++f<160)requestAnimationFrame(step);else x.clearRect(0,0,c.width,c.height)})()}
let shown=0;
window.lumo={render(d){const first=!D;D=d;
 document.getElementById('balN').textContent=fmt(d.balance);
 document.getElementById('who').innerHTML=d.to?'Подарок для <b>'+esc(d.to)+'</b>':'Коллекционные подарки за люмены';
 document.getElementById('tabs').style.display=d.to?'none':'inline-flex';
 if(d.to)tab='shop';
 indicator();draw();
 if(d.celebrate){confetti();toast(d.to?'Подарок отправлен':'Подарок у вас!')}},
 error(m){document.getElementById('list').innerHTML='<div class="err">'+esc(m)+'</div>'}};
addEventListener('resize',indicator);setTimeout(indicator,50);
</script></body></html>
""";
}
