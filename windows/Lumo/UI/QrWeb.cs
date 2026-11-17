using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using QRCoder;
using Microsoft.Web.WebView2.Core;

namespace Lumo.UI;

/// <summary>
/// QR-код профиля для ПК: как в телефоне — фон, эмодзи «каплей жидкого стекла»,
/// только для просмотра (без «Поделиться»), ссылку можно скопировать.
/// </summary>
public sealed class QrWeb : Grid, IFillPage
{
    readonly WebView2 web = new() { DefaultBackgroundColor = Windows.UI.Color.FromArgb(255, 0x0E, 0x0F, 0x22) };
    bool ready;

    public QrWeb()
    {
        Background = T.ChatBg;
        Children.Add(web);
        Loaded += async (_, _) => { if (!ready) await Init(); };
    }

    static string Link => "https://lumomess.ru/#@" + (Store.Me?.Username ?? "");

    async Task Init()
    {
        ready = true;
        try
        {
            await WebEnv.Setup(web);
            var cw = web.CoreWebView2;
            File.WriteAllText(Path.Combine(WebEnv.WebDir, "qr.html"), Html);
            cw.WebMessageReceived += (_, e) =>
            {
                var m = e.TryGetWebMessageAsString();
                if (m == "copy")
                {
                    var dp = new Windows.ApplicationModel.DataTransfer.DataPackage(); dp.SetText(Link);
                    Windows.ApplicationModel.DataTransfer.Clipboard.SetContent(dp);
                }
                else if (m != null && m.StartsWith("pref:")) Prefs.Set("qr_style", m[5..]);
            };
            cw.NavigationCompleted += async (_, _) =>
            {
                var me = Store.Me;
                using var gen = new QRCodeGenerator();
                using var data = gen.CreateQrCode(Link, QRCodeGenerator.ECCLevel.H);
                var svg = new SvgQRCode(data).GetGraphic(10, "#14143A", "#FFFFFF", false);
                var j = new JsonObject
                {
                    ["name"] = me?.Name ?? "", ["user"] = me?.Username ?? "", ["link"] = Link.Replace("https://", ""),
                    ["avatar"] = me?.AvatarUrl != null ? Net.Px(me.AvatarUrl) : null,
                    ["initials"] = Fmt.Initials(me?.Name ?? "?"),
                    ["qr"] = "data:image/svg+xml;base64," + Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(svg)),
                    ["style"] = Prefs.Get("qr_style"),
                };
                await cw.ExecuteScriptAsync("render(" + j.ToJsonString() + ")");
                if (Environment.GetEnvironmentVariable("LUMO_DEMO") == "1")
                {
                    await Task.Delay(1500);
                    try { var dir = Path.Combine(Prefs.Dir, "shots"); Directory.CreateDirectory(dir); using var fs = File.Create(Path.Combine(dir, "web-qr.png")); await cw.CapturePreviewAsync(CoreWebView2CapturePreviewImageFormat.Png, fs.AsRandomAccessStream()); } catch (Exception ex) { App.Log("capture: " + ex.Message); }
                }
            };
            cw.Navigate("https://lumo.web.local/qr.html");
        }
        catch (Exception e) { App.Log("qr web: " + e); Children.Add(T.Txt("Не удалось открыть QR-код: " + e.Message, 13, T.Danger)); }
    }

    const string Html = """
<!doctype html><html lang="ru"><head><meta charset="utf-8">
<style>
*{box-sizing:border-box}html,body{margin:0;height:100%;background:transparent;color:#eef0ff;font-family:"Segoe UI Variable Text","Segoe UI",sans-serif;-webkit-user-select:none;user-select:none}
body{display:flex;gap:28px;padding:6px 28px 28px;align-items:flex-start;flex-wrap:wrap}
.stage{position:relative;flex:1 1 420px;min-height:560px;border-radius:28px;display:flex;align-items:center;justify-content:center;overflow:hidden;transition:background 0s}
.bgl{position:absolute;inset:0;transition:opacity .6s ease}
.blob{position:absolute;width:340px;height:340px;border-radius:50%;filter:blur(60px);opacity:.45;background:#fff;animation:drift 12s ease-in-out infinite}
.blob.b2{width:260px;height:260px;right:-60px;bottom:-60px;animation-duration:15s;animation-direction:reverse}
@keyframes drift{0%,100%{transform:translate(-30%,-30%)}50%{transform:translate(10%,15%)}}
.card{position:relative;width:340px;background:#fff;border-radius:30px;padding:26px 26px 22px;text-align:center;color:#14163a;box-shadow:0 30px 70px rgba(0,0,0,.35);animation:pop .6s cubic-bezier(.2,.9,.3,1.3)}
@keyframes pop{from{transform:scale(.9) translateY(20px);opacity:0}}
.av{width:72px;height:72px;border-radius:50%;margin:-62px auto 8px;border:5px solid #fff;background:linear-gradient(135deg,#7c5cff,#22c1ff);display:flex;align-items:center;justify-content:center;color:#fff;font-weight:800;font-size:24px;overflow:hidden;box-shadow:0 8px 20px rgba(0,0,0,.2)}
.av img{width:100%;height:100%;object-fit:cover}
.nm{font-weight:900;font-size:21px}.un{color:#7276a0;font-size:15px;margin-top:2px}
.qr{position:relative;width:250px;height:250px;margin:16px auto 6px}.qr img{width:100%;height:100%}
.logo{position:absolute;left:50%;top:50%;width:52px;height:52px;margin:-26px;border-radius:15px;background:linear-gradient(135deg,#7c5cff,#22c1ff);border:4px solid #fff;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:900;font-size:24px;font-style:italic}
.lk{font-size:12.5px;color:#7276a0;margin-top:6px}
.drop{position:absolute;top:-30px;right:-26px;width:84px;height:84px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:42px;
 background:radial-gradient(circle at 35% 30%,rgba(255,255,255,.95),rgba(255,255,255,.35) 45%,rgba(255,255,255,.12) 70%);
 box-shadow:inset 0 -8px 18px rgba(255,255,255,.35),inset 0 6px 12px rgba(255,255,255,.7),0 14px 30px rgba(0,0,0,.25);backdrop-filter:blur(8px);border:1.5px solid rgba(255,255,255,.8)}
.drop::after{content:"";position:absolute;left:18px;top:12px;width:24px;height:12px;border-radius:50%;background:rgba(255,255,255,.9);filter:blur(1px);transform:rotate(-25deg)}
.drop.in{animation:liquid 1s cubic-bezier(.2,.9,.3,1.4) both,wobble 3.2s ease-in-out 1s infinite}
@keyframes liquid{0%{transform:scale(.1);border-radius:50%;filter:blur(8px)}35%{transform:scale(1.18,.86);filter:blur(0)}55%{transform:scale(.9,1.12)}75%{transform:scale(1.05,.96)}100%{transform:scale(1)}}
@keyframes wobble{0%,100%{transform:rotate(-5deg) scale(1)}25%{transform:rotate(3deg) scale(1.03,.97)}50%{transform:rotate(5deg) scale(.98,1.03)}75%{transform:rotate(-2deg) scale(1.02,.98)}}
.side{flex:0 1 330px;display:flex;flex-direction:column;gap:18px}
.box{background:#16173a;border-radius:20px;padding:16px}
.box h3{margin:0 0 12px;font-size:13px;color:#8d90b8;font-weight:600}
.sw{display:grid;grid-template-columns:repeat(4,1fr);gap:10px}
.sw button{height:48px;border-radius:14px;border:2px solid transparent;cursor:pointer;transition:transform .2s cubic-bezier(.2,.9,.3,1.4),border-color .2s}
.sw button:hover{transform:scale(1.07)}.sw button.on{border-color:#fff;transform:scale(1.08)}
.em{display:grid;grid-template-columns:repeat(6,1fr);gap:8px}
.em button{height:42px;border-radius:12px;border:0;background:#1d1f45;font-size:22px;cursor:pointer;color:#eef0ff;transition:transform .2s cubic-bezier(.2,.9,.3,1.4),background .2s}
.em button:hover{transform:scale(1.12)}.em button.on{background:#7c5cff}
.copy{border:0;border-radius:16px;padding:14px;font:700 15px inherit;font-family:inherit;color:#fff;background:linear-gradient(135deg,#7c5cff,#22c1ff);cursor:pointer;transition:transform .15s,box-shadow .2s;display:flex;align-items:center;justify-content:center;gap:8px}
.copy:hover{box-shadow:0 10px 26px rgba(124,92,255,.45)}.copy:active{transform:scale(.96)}
.hint{font-size:12px;color:#8d90b8;line-height:1.45}
</style></head><body>
<div class="stage" id="stage"><div class="bgl" id="bgA"></div><div class="bgl" id="bgB" style="opacity:0"></div><div class="blob"></div><div class="blob b2"></div>
<div class="card"><div class="av" id="av"></div><div class="nm" id="nm"></div><div class="un" id="un"></div>
<div class="qr"><img id="qr" alt=""><div class="logo">L</div></div><div class="lk" id="lk"></div>
<div class="drop" id="drop" style="display:none"></div></div></div>
<div class="side">
<div class="box"><h3>Фон</h3><div class="sw" id="sw"></div></div>
<div class="box"><h3>Эмодзи</h3><div class="em" id="em"></div></div>
<button class="copy" id="copy"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round"><path d="M10 14a5 5 0 007 0l3-3a5 5 0 00-7-7l-1 1"/><path d="M14 10a5 5 0 00-7 0l-3 3a5 5 0 007 7l1-1"/></svg><span id="ct">Скопировать ссылку</span></button>
<div class="hint">Покажите код собеседнику — он отсканирует его камерой в Lumo на телефоне и сразу откроет ваш профиль.</div>
</div>
<script>
const BG=[['#6C5CE7','#A66CFF'],['#0FB9B1','#2D98DA'],['#FF6B9D','#FF9A5A'],['#20BF6B','#0FB9B1'],['#1E1F3B','#3B3F7A'],['#F7B731','#FA8231'],['#EB3B5A','#8854D0'],['#45AAF2','#A5B1FF']];
const EM=['','❤️','🔥','⭐','😎','🎉','🚀','🌈','💎','🌸','👾','🎧','🐱','🍀','⚡','🦄','🎁','👑'];
let st={bg:0,emoji:''},cur='A';
const post=s=>{try{window.chrome.webview.postMessage(s)}catch(e){}};
function setBg(i,instant){const g=BG[i]||BG[0];const nx=cur==='A'?'B':'A';const el=document.getElementById('bg'+nx),old=document.getElementById('bg'+cur);
 el.style.background=`linear-gradient(140deg,${g[0]},${g[1]})`;if(instant){el.style.transition='none';old.style.transition='none'}el.style.opacity=1;old.style.opacity=0;
 setTimeout(()=>{el.style.transition='';old.style.transition=''},30);cur=nx;
 document.querySelectorAll('#sw button').forEach((b,k)=>b.classList.toggle('on',k===i))}
function setEmoji(e){const d=document.getElementById('drop');if(!e){d.style.display='none';d.classList.remove('in')}else{d.textContent=e;d.style.display='flex';d.classList.remove('in');void d.offsetWidth;d.classList.add('in')}
 document.querySelectorAll('#em button').forEach(b=>b.classList.toggle('on',b.dataset.e===e))}
function save(){post('pref:'+JSON.stringify(st))}
document.getElementById('sw').innerHTML=BG.map((g,i)=>`<button style="background:linear-gradient(140deg,${g[0]},${g[1]})" data-i="${i}"></button>`).join('');
document.getElementById('em').innerHTML=EM.map(e=>`<button data-e="${e}">${e||'<svg width=18 height=18 viewBox="0 0 24 24" fill=none stroke="#8d90b8" stroke-width=2.2><circle cx=12 cy=12 r=9 /><path d="M6 18L18 6"/></svg>'}</button>`).join('');
document.querySelectorAll('#sw button').forEach(b=>b.onclick=()=>{st.bg=+b.dataset.i;setBg(st.bg);save()});
document.querySelectorAll('#em button').forEach(b=>b.onclick=()=>{st.emoji=b.dataset.e;setEmoji(st.emoji);save()});
document.getElementById('copy').onclick=()=>{post('copy');const t=document.getElementById('ct');t.textContent='Ссылка скопирована';setTimeout(()=>t.textContent='Скопировать ссылку',1800)};
function render(d){
 document.getElementById('nm').textContent=d.name;document.getElementById('un').textContent='@'+d.user;document.getElementById('lk').textContent=d.link;
 document.getElementById('qr').src=d.qr;
 const av=document.getElementById('av');av.textContent=d.initials;if(d.avatar){const i=new Image();i.onload=()=>{av.textContent='';av.appendChild(i)};i.src=d.avatar}
 try{if(d.style)st=Object.assign(st,JSON.parse(d.style))}catch(e){}
 setBg(st.bg,true);setEmoji(st.emoji)}
</script></body></html>
""";
}
