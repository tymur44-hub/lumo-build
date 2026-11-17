using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.Web.WebView2.Core;

namespace Lumo.UI;

/// <summary>
/// Раздел «Люмены и Premium» для ПК (как «Звёзды» в Telegram): живой кристалл, баланс, пополнение картой,
/// ежедневный бонус, перевод друзьям, Premium и история операций с вкладками.
/// </summary>
public sealed class WalletWeb : Grid, IFillPage
{
    readonly WebView2 web = new() { DefaultBackgroundColor = Windows.UI.Color.FromArgb(255, 0x0E, 0x0F, 0x22) };
    readonly Action? openGifts;
    bool ready;

    public WalletWeb(Action? openGifts = null)
    {
        this.openGifts = openGifts;
        Background = T.ChatBg;
        Children.Add(web);
        Loaded += async (_, _) => { if (!ready) await Init(); };
        Action onPaid = () => _ = Push();
        Loaded += (_, _) => Pay.Paid += onPaid;
        Unloaded += (_, _) => Pay.Paid -= onPaid;
    }

    async Task Init()
    {
        ready = true;
        try
        {
            await WebEnv.Setup(web);
            var cw = web.CoreWebView2;
            File.WriteAllText(Path.Combine(WebEnv.WebDir, "wallet.html"), Html);
            cw.WebMessageReceived += async (_, e) => await OnMsg(e.TryGetWebMessageAsString());
            cw.NavigationCompleted += async (_, _) =>
            {
                await Push();
                if (Environment.GetEnvironmentVariable("LUMO_DEMO") == "1")
                {
                    await Task.Delay(1500);
                    try { var dir = Path.Combine(Prefs.Dir, "shots"); Directory.CreateDirectory(dir); using var fs = File.Create(Path.Combine(dir, "web-wallet.png")); await cw.CapturePreviewAsync(CoreWebView2CapturePreviewImageFormat.Png, fs.AsRandomAccessStream()); } catch (Exception ex) { App.Log("capture: " + ex.Message); }
                }
            };
            cw.Navigate("https://lumo.web.local/wallet.html");
        }
        catch (Exception e) { App.Log("wallet web: " + e); Children.Add(T.Txt("Не удалось открыть люмены: " + e.Message, 13, T.Danger)); }
    }

    static string Title(string kind, string? who) => kind switch
    {
        "tip_in" or "tip_out" => who ?? "Пользователь",
        "buy" => "Покупка люменов", "daily" => "Ежедневный бонус", "grant" => "Начисление от Lumo",
        "gift_buy" => "Покупка подарка", "gift_sell" => "Продажа подарка",
        "game_win" => "Выигрыш в игре", "game_stake" => "Ставка в игре", "game_refund" => "Возврат ставки",
        _ => "Операция",
    };

    /// <summary>Отправить странице баланс, Premium и историю</summary>
    public async Task Push()
    {
        try
        {
            var w = await Api.Rpc("lm_wallet_me");
            var hist = (await Api.Rpc("lm_wallet_history", new JsonObject { ["p_limit"] = 100 })) as JsonArray ?? new JsonArray();
            var ids = hist.OfType<JsonObject>().Select(o => o.Str("ref_user")).Where(x => x != null).Select(x => x!).Distinct().ToList();
            if (ids.Count > 0) await Store.LoadProfiles(ids);
            string? until = null;
            try
            {
                var pr = await Api.Rpc("lm_my_premium");
                var po = pr as JsonObject ?? (pr as JsonArray)?.OfType<JsonObject>().FirstOrDefault();
                until = po?.Str("until");
            }
            catch { }
            var ops = new JsonArray();
            foreach (var o in hist.OfType<JsonObject>())
            {
                var kind = o.Str("kind") ?? ""; var u = o.Str("ref_user");
                Store.Profiles.TryGetValue(u ?? "", out var pf);
                var who = u != null ? Store.DisplayName(u) : null;
                var at = o.Date("created_at")?.ToLocalTime();
                ops.Add(new JsonObject
                {
                    ["kind"] = kind, ["delta"] = o.Long("delta") ?? 0, ["title"] = Title(kind, who),
                    ["sub"] = kind switch { "tip_in" => "Отправил(а) вам люмены", "tip_out" => "Вы отправили люмены", "buy" => "Оплата картой", _ => null },
                    ["date"] = at?.ToString("d MMM yyyy, HH:mm", new System.Globalization.CultureInfo("ru-RU")) ?? "",
                    ["avatar"] = pf?.AvatarUrl, ["initial"] = who is { Length: > 0 } ? who[..1].ToUpper() : null, ["color"] = pf?.Color ?? 0,
                });
            }
            var data = new JsonObject
            {
                ["balance"] = w.Long("balance") ?? 0, ["streak"] = w.Int("streak") ?? 0, ["canClaim"] = w.Bool("can_claim"),
                ["premium"] = Store.Me?.Premium == true,
                ["until"] = until != null && DateTimeOffset.TryParse(until, out var ud) ? ud.ToLocalTime().ToString("d MMMM yyyy", new System.Globalization.CultureInfo("ru-RU")) : null,
                ["ops"] = ops,
            };
            await web.CoreWebView2.ExecuteScriptAsync("window.lumo && lumo.render(" + data.ToJsonString() + ")");
        }
        catch (Exception e) { App.Log("wallet push: " + e.Message); try { await web.CoreWebView2.ExecuteScriptAsync("window.lumo && lumo.error(" + JsonValue.Create(e.Message)!.ToJsonString() + ")"); } catch { } }
    }

    string? sendTo;

    async Task OnMsg(string? raw)
    {
        if (raw == null) return;
        JsonNode? m; try { m = JsonNode.Parse(raw); } catch { return; }
        switch (m.Str("t"))
        {
            case "buy": await Pay.Create("lum", m.Int("qty") ?? 0); await Done(); break;
            case "prem": await Pay.Create("prem", m.Int("m") ?? 12); await Done(); break;
            case "claim":
                try { var r = await Api.Rpc("lm_wallet_daily"); var n = r.Int("amount") ?? 0; Store.Say("Получено: " + n + " " + Fmt.Plural(n, "люмен", "люмена", "люменов")); }
                catch (Exception e) { Store.Say(e.Message); }
                await Push(); break;
            case "friend":
            {
                var to = await Gifts.PickRecipient();
                if (string.IsNullOrEmpty(to)) { await Done(); return; }
                sendTo = to;
                await web.CoreWebView2.ExecuteScriptAsync("lumo.askAmount(" + JsonValue.Create(Store.DisplayName(to))!.ToJsonString() + ")");
                break;
            }
            case "send":
            {
                if (sendTo == null) return;
                try
                {
                    var n = m.Int("amount") ?? 0;
                    await Api.Rpc("lm_wallet_send", new JsonObject { ["p_user"] = sendTo, ["p_amount"] = n });
                    Store.Say("Отправлено " + n + " " + Fmt.Plural(n, "люмен", "люмена", "люменов") + " для " + Store.DisplayName(sendTo));
                }
                catch (Exception e) { Store.Say(e.Message); }
                sendTo = null; await Push(); break;
            }
            case "gifts": openGifts?.Invoke(); break;
        }
    }

    async Task Done() { try { await web.CoreWebView2.ExecuteScriptAsync("lumo.idle()"); } catch { } }

    const string Html = """
<!doctype html><html lang="ru"><head><meta charset="utf-8">
<style>
:root{--bg:#0e0f22;--panel:#16173a;--panel2:#1d1f45;--line:rgba(255,255,255,.07);--text:#eef0ff;--muted:#8d90b8;--a1:#7c5cff;--a2:#22c1ff;--gold:#f5b942;--ok:#2bc46f;--bad:#ff4d6a}
*{box-sizing:border-box}html,body{margin:0;background:transparent;color:var(--text);font-family:"Segoe UI Variable Text","Segoe UI",sans-serif;-webkit-user-select:none;user-select:none}
body{padding:0 24px 40px;overflow-x:hidden}
.wrap{max-width:560px;margin:0 auto}
.hero{position:relative;height:170px;display:flex;align-items:center;justify-content:center}
.glow{position:absolute;width:230px;height:230px;border-radius:50%;background:radial-gradient(circle,rgba(255,179,71,.38),transparent 62%);animation:gl 3.2s ease-in-out infinite}
@keyframes gl{0%,100%{transform:scale(.92);opacity:.8}50%{transform:scale(1.06);opacity:1}}
.big{width:96px;height:96px;filter:drop-shadow(0 6px 22px rgba(255,140,60,.55));animation:sway 2.6s ease-in-out infinite}
@keyframes sway{0%,100%{transform:rotate(-8deg) scale(.97)}50%{transform:rotate(8deg) scale(1.05)}}
.sp{position:absolute;left:50%;top:50%;width:12px;height:12px;margin:-6px;opacity:0;animation:fly 3s linear infinite}
.sp::before,.sp::after{content:"";position:absolute;left:50%;top:50%;background:currentColor;border-radius:2px}
.sp::before{width:12px;height:2.4px;margin:-1.2px -6px}.sp::after{width:2.4px;height:12px;margin:-6px -1.2px}
@keyframes fly{0%{opacity:0;transform:rotate(var(--a)) translateX(48px) scale(1)}12%{opacity:1}100%{opacity:0;transform:rotate(var(--a)) translateX(118px) scale(.35)}}
h1{margin:0;text-align:center;font-size:27px;font-weight:800}
.desc{margin:8px auto 0;text-align:center;color:var(--muted);font-size:14.5px;line-height:1.45;max-width:420px}
.card{background:var(--panel);border-radius:22px;margin-top:16px}
.balc{padding:18px;text-align:center}
.balc .row{display:flex;align-items:center;justify-content:center;gap:10px}
.balc .n{font-size:42px;font-weight:800;letter-spacing:-.5px}.balc .gem{width:36px;height:36px}
.balc .l{color:var(--muted);font-size:14.5px;margin-top:-2px}
.btns{display:flex;gap:10px;margin-top:14px}
.btn{flex:1;display:flex;align-items:center;justify-content:center;gap:8px;height:48px;border:0;border-radius:14px;font-weight:700;font-size:15.5px;font-family:inherit;cursor:pointer;transition:transform .15s,filter .15s,box-shadow .2s}
.btn:active{transform:scale(.96)}.btn svg{width:18px;height:18px}
.pri{color:#fff;background:linear-gradient(135deg,var(--a1),var(--a2))}.pri:hover{filter:brightness(1.1);box-shadow:0 8px 24px rgba(124,92,255,.45)}
.sec{color:#a996ff;background:rgba(124,92,255,.15)}.sec:hover{background:rgba(124,92,255,.22)}
.sec[disabled]{color:var(--muted);background:rgba(124,92,255,.06);cursor:default}
.link{display:flex;align-items:center;justify-content:center;gap:7px;margin:14px auto 0;color:#a996ff;font-weight:600;font-size:15px;cursor:pointer;width:max-content;padding:6px 10px;border-radius:10px;transition:background .15s}
.link:hover{background:rgba(124,92,255,.12)}.link svg{width:16px;height:16px}
.cap{margin:22px 14px 8px;font-size:12px;font-weight:700;color:var(--muted);letter-spacing:.4px}
.it{display:flex;align-items:center;gap:14px;padding:12px 14px}
.it+.it{border-top:1px solid var(--line)}
.ic{width:36px;height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;flex:none}.ic svg{width:19px;height:19px;fill:#fff}
.it b{display:block;font-size:15px;font-weight:600}.it span{display:block;color:var(--muted);font-size:13px;margin-top:1px}
.it.click{cursor:pointer;border-radius:22px;transition:background .15s}.it.click:hover{background:rgba(255,255,255,.03)}
.prem{display:flex;align-items:center;gap:14px;padding:14px;border-radius:22px;margin-top:16px;background:linear-gradient(135deg,rgba(124,92,255,.35),rgba(255,91,138,.25));border:1px solid rgba(164,139,255,.35)}
.prem .t{flex:1}.prem b{font-size:16px}.prem span{display:block;font-size:13px;color:#d6d0ff;margin-top:2px}
.prem .btn{flex:none;height:40px;padding:0 16px;font-size:14px}
.seg{display:flex;background:var(--panel2);border-radius:999px;padding:3px;margin:22px 0 10px;position:relative}
.seg button{flex:1;position:relative;z-index:1;border:0;background:none;height:34px;border-radius:999px;color:var(--muted);font-weight:600;font-size:14px;font-family:inherit;cursor:pointer;transition:color .2s}
.seg button.on{color:var(--text)}.seg .ind{position:absolute;top:3px;bottom:3px;border-radius:999px;background:var(--panel);box-shadow:0 1px 4px rgba(0,0,0,.3);transition:left .3s cubic-bezier(.2,.9,.3,1.1),width .3s}
.op{display:flex;align-items:center;gap:12px;padding:10px 14px;animation:in .35s ease both}
.op+.op{border-top:1px solid var(--line)}
@keyframes in{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:none}}
.av{width:44px;height:44px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:17px;color:#fff;background-size:cover;background-position:center}
.av svg{width:21px;height:21px;fill:#fff}
.op .t{flex:1;min-width:0}.op b{display:block;font-size:15px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.op span{display:block;font-size:12.5px;color:var(--muted)}
.amt{display:flex;align-items:center;gap:5px;font-weight:700;font-size:16px}.amt .gem{width:17px;height:17px}
.plus{color:var(--ok)}.minus{color:var(--bad)}
.empty{text-align:center;color:var(--muted);padding:30px 0}
.load{display:flex;gap:6px;justify-content:center;padding:40px}.load i{width:9px;height:9px;border-radius:50%;background:var(--a1);animation:dot 1s infinite ease-in-out}.load i:nth-child(2){animation-delay:.15s}.load i:nth-child(3){animation-delay:.3s}
@keyframes dot{0%,100%{transform:scale(.5);opacity:.4}50%{transform:scale(1);opacity:1}}
/* окна поверх страницы */
.dim{position:fixed;inset:0;background:rgba(5,6,18,.6);backdrop-filter:blur(4px);display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .2s;z-index:40}
.dim.on{opacity:1;pointer-events:auto}
.sheet{width:440px;max-width:calc(100% - 32px);max-height:calc(100% - 32px);overflow:auto;background:var(--bg);border:1px solid rgba(255,255,255,.08);border-radius:24px;padding:16px;transform:scale(.95) translateY(10px);transition:transform .25s cubic-bezier(.2,.9,.3,1.2);box-shadow:0 30px 80px rgba(0,0,0,.6)}
.dim.on .sheet{transform:none}
.sh{display:flex;align-items:center;justify-content:space-between}
.x{width:36px;height:36px;border-radius:50%;border:0;background:var(--panel2);color:var(--text);cursor:pointer;display:flex;align-items:center;justify-content:center;transition:background .15s}
.x:hover{background:#2a2c5c}.x svg{width:16px;height:16px;stroke:var(--text);stroke-width:2.4;stroke-linecap:round}
.sb{text-align:right}.sb span{display:block;font-size:12px;color:var(--muted)}.sb b{display:flex;align-items:center;gap:4px;font-size:15px}.sb .gem{width:15px;height:15px}
.mini{height:120px;position:relative;display:flex;align-items:center;justify-content:center}.mini .big{width:70px;height:70px}.mini .glow{width:170px;height:170px}
.sheet h2{margin:0;text-align:center;font-size:23px;font-weight:800}.sheet .sub{text-align:center;color:var(--muted);font-size:14.5px;margin:4px 0 14px}
.pk{display:flex;align-items:center;gap:12px;padding:13px 16px;cursor:pointer;transition:background .15s}
.pk+.pk{border-top:1px solid var(--line)}.pk:hover{background:rgba(255,255,255,.04)}.pk:active{background:rgba(255,255,255,.07)}
.stack{width:70px;height:24px;position:relative;flex:none}.stack .gem{position:absolute;top:0;width:24px;height:24px}
.pk b{flex:1;font-size:16px;font-weight:600}.pk span{color:var(--muted);font-size:15px}
.pk.busy{opacity:.6;pointer-events:none}
.more{display:flex;align-items:center;justify-content:center;gap:5px;margin:12px auto 0;color:#a996ff;font-weight:600;font-size:15px;cursor:pointer;width:max-content;padding:6px 10px;border-radius:10px}
.more:hover{background:rgba(124,92,255,.12)}
.inp{display:flex;align-items:center;gap:10px;height:52px;padding:0 16px;border-radius:16px;background:var(--panel);margin-top:12px}
.inp input{flex:1;border:0;outline:0;background:none;color:var(--text);font-weight:600;font-size:16px;font-family:inherit}.inp input::placeholder{color:var(--muted);font-weight:400}
.inp .gem{width:24px;height:24px}.inp span{color:var(--muted)}
.wide{width:100%;margin-top:12px}
.note{display:flex;gap:8px;color:var(--muted);font-size:12.5px;line-height:1.45;margin-top:14px}.note svg{width:17px;height:17px;flex:none;fill:#2bd67b}
.plan{display:flex;align-items:center;gap:14px;padding:13px 16px;cursor:pointer}.plan+.plan{border-top:1px solid var(--line)}
.rb{width:22px;height:22px;border-radius:50%;border:2px solid rgba(141,144,184,.6);flex:none;display:flex;align-items:center;justify-content:center;transition:all .2s}
.plan.on .rb{border-color:var(--a1);background:var(--a1)}.plan.on .rb::after{content:"";width:8px;height:8px;border-radius:50%;background:#fff}
.plan .t{flex:1}.plan b{font-size:16px;font-weight:600}.plan .bd{font-size:11.5px;font-weight:800;color:#fff;padding:2px 6px;border-radius:6px;background:linear-gradient(135deg,var(--a1),var(--a2));margin-left:6px}
.plan span.pm{display:block;color:var(--muted);font-size:13px}.plan .pr{font-weight:600}
.star{width:84px;height:84px;filter:drop-shadow(0 6px 22px rgba(138,123,255,.6));animation:sway 2.8s ease-in-out infinite}
.err{color:#ff7a90;padding:30px;text-align:center}
</style></head><body><div class="wrap" id="app"><div class="load"><i></i><i></i><i></i></div></div>
<div class="dim" id="dim"><div class="sheet" id="sheet"></div></div>
<svg width="0" height="0" style="position:absolute"><defs><linearGradient id="lg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffe08a"/><stop offset=".5" stop-color="#ff9a3d"/><stop offset="1" stop-color="#ff5e8a"/></linearGradient>
<linearGradient id="sg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#c59bff"/><stop offset="1" stop-color="#6a7bff"/></linearGradient></defs></svg>
<script>
const gem=(c='gem')=>`<svg class="${c}" viewBox="0 0 24 24"><polygon points="12.00,0.48 21.98,6.24 21.98,17.76 12.00,23.52 2.02,17.76 2.02,6.24" fill="url(#lg)" stroke="rgba(255,255,255,.45)" stroke-width="1.08" stroke-linejoin="round"/><polygon points="12.00,5.04 13.27,10.73 18.96,12.00 13.27,13.27 12.00,18.96 10.73,13.27 5.04,12.00 10.73,10.73" fill="#fff"/></svg>`;
const I={
 plus:'<svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" fill="none"/></svg>',
 spark:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2l1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8zM19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9z"/></svg>',
 check:'<svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>',
 gift:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M20 7h-2.2A3 3 0 0012 3.8 3 3 0 006.2 7H4a1 1 0 00-1 1v3a1 1 0 001 1h1v8a1 1 0 001 1h12a1 1 0 001-1v-8h1a1 1 0 001-1V8a1 1 0 00-1-1zm-5-1.5a1.5 1.5 0 010 3h-2V8a1.5 1.5 0 012-2.5zM9 5.5A1.5 1.5 0 0110.5 7v1.5h-2a1.5 1.5 0 01.5-3z"/></svg>',
 cal:'<svg viewBox="0 0 24 24"><path d="M7 2v3M17 2v3M3 9h18M5 5h14a2 2 0 012 2v12a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2z" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/></svg>',
 heart:'<svg viewBox="0 0 24 24"><path d="M12 21s-7.5-4.6-9.5-9.3C1.1 8.3 3.3 5 6.6 5c2 0 3.4 1.1 4.4 2.5C12 6.1 13.4 5 15.4 5c3.3 0 5.5 3.3 4.1 6.7C19.5 16.4 12 21 12 21z"/></svg>',
 game:'<svg viewBox="0 0 24 24"><path d="M7 7h10a5 5 0 015 5v1a4 4 0 01-7 2.6l-.6-.6H9.6l-.6.6A4 4 0 012 13v-1a5 5 0 015-5zm0 3v1.5H5.5v1.5H7v1.5h1.5V13H10v-1.5H8.5V10zm9.5.5a1 1 0 100 2 1 1 0 000-2zm-2 2a1 1 0 100 2 1 1 0 000-2z"/></svg>',
 shield:'<svg viewBox="0 0 24 24"><path d="M12 2l8 3v6c0 5-3.4 9.4-8 11-4.6-1.6-8-6-8-11V5zm-1.2 13.2l5.7-5.7-1.4-1.4-4.3 4.3-2-2-1.4 1.4z"/></svg>',
 card:'<svg viewBox="0 0 24 24"><path d="M3 6a2 2 0 012-2h14a2 2 0 012 2v2H3zm0 4h18v8a2 2 0 01-2 2H5a2 2 0 01-2-2zm3 5v2h5v-2z"/></svg>',
 star:'<svg viewBox="0 0 24 24"><path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z"/></svg>',
 x:'<svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>',
 chev:'<svg viewBox="0 0 24 24" width="14" height="14"><path d="M9 6l6 6-6 6" stroke="currentColor" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>',
 down:'<svg viewBox="0 0 24 24" width="14" height="14"><path d="M6 9l6 6 6-6" stroke="currentColor" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>',
};
const post=o=>{try{window.chrome.webview.postMessage(JSON.stringify(o))}catch(e){}};
const fmt=n=>Number(n).toLocaleString('ru-RU');
const rub=v=>(Math.abs(v-Math.round(v))<.001?fmt(Math.round(v)):v.toLocaleString('ru-RU',{minimumFractionDigits:2,maximumFractionDigits:2}))+' ₽';
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const word=n=>{const m=n%100;if(m>=11&&m<=14)return'люменов';switch(n%10){case 1:return'люмен';case 2:case 3:case 4:return'люмена';default:return'люменов'}};
const COLORS=['#ff7a6b','#a48bff','#36b8ff','#25c99a','#ffb347','#ff6bb5','#5bc0ff','#9ccc65'];
const KIND={buy:[I.card,'#2bd67b','#18a957'],daily:[I.cal,'#ffb347','#ff7a3d'],gift_buy:[I.gift,'#ff7ab8','#c65cff'],gift_sell:[I.gift,'#ff7ab8','#c65cff'],game_win:[I.game,'#8a7bff','#5b5cff'],game_stake:[I.game,'#8a7bff','#5b5cff'],game_refund:[I.game,'#8a7bff','#5b5cff']};
let D=null,tab=0,busy=false;
function hero(cls=''){let s='';for(let i=0;i<12;i++)s+=`<i class="sp" style="--a:${i*30}deg;color:${i%2?'#ff8fb5':'#ffe08a'};animation-delay:${(i*0.25).toFixed(2)}s"></i>`;return `<div class="hero ${cls}"><div class="glow"></div>${s}${gem('big')}</div>`}
function ops(){const a=D.ops.filter(o=>tab==1?o.delta>0:tab==2?o.delta<0:true);
 if(!a.length)return '<div class="empty">Операций пока нет</div>';
 return '<div class="card">'+a.map((o,i)=>{let av;
  if(o.avatar)av=`<div class="av" style="background-image:url('${esc(o.avatar)}')"></div>`;
  else if(o.initial)av=`<div class="av" style="background:${COLORS[((o.color%8)+8)%8]}">${esc(o.initial)}</div>`;
  else{const k=KIND[o.kind]||[I.spark,'#36b8ff','#3a7bff'];av=`<div class="av" style="background:linear-gradient(135deg,${k[1]},${k[2]})">${k[0]}</div>`}
  return `<div class="op" style="animation-delay:${Math.min(i,12)*25}ms">${av}<div class="t"><b>${esc(o.title)}</b>${o.sub?`<span>${esc(o.sub)}</span>`:''}<span>${esc(o.date)}</span></div><div class="amt ${o.delta>0?'plus':'minus'}">${o.delta>0?'+':'−'}${fmt(Math.abs(o.delta))}${gem()}</div></div>`}).join('')+'</div>'}
function draw(){const d=D;const st=d.streak>0?`Серия ${d.streak} дн. подряд — завтра +${Math.min(3+d.streak,10)}`:'Заходите каждый день — до 10 люменов в день';
 document.getElementById('app').innerHTML=hero()+`
 <h1>Люмены Lumo</h1><div class="desc">Покупайте люмены, чтобы дарить подарки, поддерживать авторов и каналы и отправлять их друзьям.</div>
 <div class="card balc"><div class="row">${gem()}<span class="n">${fmt(d.balance)}</span></div><div class="l">Ваш баланс</div>
  <div class="btns"><button class="btn pri" id="bBuy">${I.plus}Пополнить</button><button class="btn sec" id="bClaim" ${d.canClaim?'':'disabled'}>${d.canClaim?I.spark+'Бонус дня':I.check+'Бонус получен'}</button></div></div>
 <div class="link" id="bFriend">${I.gift}Подарить люмены друзьям${I.chev}</div>
 <div class="prem"><div class="ic" style="background:linear-gradient(135deg,#a48bff,#6a7bff)">${I.star}</div><div class="t"><b>Lumo Premium</b><span>${d.premium?(d.until?'Активен до '+esc(d.until):'Подписка активна'):'Дополнительные функции на всех устройствах'}</span></div><button class="btn pri" id="bPrem">${d.premium?'Продлить':'Оформить'}</button></div>
 <div class="cap">ЗАРАБОТАТЬ ЛЮМЕНЫ</div>
 <div class="card"><div class="it"><div class="ic" style="background:#ff9a3d">${I.cal}</div><div><b>Ежедневный бонус</b><span>${st}</span></div></div>
  <div class="it"><div class="ic" style="background:#ff5e8a">${I.heart}</div><div><b>Поддержка от читателей</b><span>Люмены за ваши сообщения и посты в каналах</span></div></div>
  <div class="it"><div class="ic" style="background:#7c5cff">${I.game}</div><div><b>Игры с друзьями</b><span>Ставки и выигрыши в играх Lumo</span></div></div>
  <div class="it click" id="bGifts"><div class="ic" style="background:#c65cff">${I.gift}</div><div><b>Подарки</b><span>Подарки за люмены — дарите и храните в профиле</span></div></div></div>
 <div class="card"><div class="it"><div class="ic" style="background:#2bd67b">${I.shield}</div><div><b>Оплата работает</b><span>Банковской картой через ЮMoney прямо в Lumo. Люмены и Premium зачисляются автоматически, обычно за минуту.</span></div></div></div>
 <div class="seg" id="seg"><span class="ind" id="ind"></span><button>Все операции</button><button>Зачисления</button><button>Списания</button></div>
 <div id="ops">${ops()}</div>`;
 document.getElementById('bBuy').onclick=()=>buySheet();
 document.getElementById('bClaim').onclick=()=>{if(!D.canClaim)return;post({t:'claim'})};
 document.getElementById('bFriend').onclick=()=>post({t:'friend'});
 document.getElementById('bPrem').onclick=()=>premSheet();
 document.getElementById('bGifts').onclick=()=>post({t:'gifts'});
 const bs=[...document.querySelectorAll('#seg button')];bs.forEach((b,i)=>{b.classList.toggle('on',i==tab);b.onclick=()=>{tab=i;bs.forEach((x,j)=>x.classList.toggle('on',j==i));ind();document.getElementById('ops').innerHTML=ops()}});
 requestAnimationFrame(ind)}
function ind(){const b=document.querySelector('#seg button.on'),e=document.getElementById('ind');if(!b||!e)return;e.style.left=b.offsetLeft+'px';e.style.width=b.offsetWidth+'px'}
window.addEventListener('resize',ind);
const dim=document.getElementById('dim'),sheet=document.getElementById('sheet');
dim.onclick=e=>{if(e.target===dim)close()};
document.addEventListener('keydown',e=>{if(e.key==='Escape')close()});
function open(html){sheet.innerHTML=html;dim.classList.add('on');const x=sheet.querySelector('.x');if(x)x.onclick=close}
function close(){dim.classList.remove('on');busy=false}
const head=()=>`<div class="sh"><button class="x" title="Закрыть">${I.x}</button><div class="sb"><span>Баланс</span><b>${gem()}${fmt(D?D.balance:0)}</b></div></div>`;
const PACKS=[[50,1],[100,2],[250,3],[500,4],[1000,5],[2500,6]],EXTRA=[[1500,5],[5000,7]];
function stack(n){let s='';for(let i=n-1;i>=0;i--)s+=gem('gem').replace('class="gem"',`class="gem" style="left:${i*7}px"`);return `<div class="stack">${s}</div>`}
function buySheet(more=false){const list=more?[...PACKS,...EXTRA].sort((a,b)=>a[0]-b[0]):PACKS;
 open(head()+`<div class="mini"><div class="glow"></div>${gem('big')}</div><h2>Купить люмены</h2><div class="sub">Выберите нужное количество</div>
 <div class="card" style="margin-top:0">${list.map(([n,g])=>`<div class="pk" data-n="${n}">${stack(g)}<b>${fmt(n)} ${word(n)}</b><span>${rub(n*1.7)}</span></div>`).join('')}</div>
 ${more?`<div class="inp">${gem()}<input id="cu" placeholder="Своё количество (от 50)" inputmode="numeric" maxlength="4"><span id="cuP"></span></div><button class="btn pri wide" id="cuB" style="display:none"></button>`:`<div class="more" id="more">Показать другие варианты${I.down}</div>`}
 <div class="note">${I.shield}<div>Оплата банковской картой через ЮMoney прямо в Lumo. Люмены зачисляются автоматически, обычно за минуту. 1 люмен = 1,7 ₽.</div></div>`);
 sheet.querySelectorAll('.pk').forEach(p=>p.onclick=()=>pay(+p.dataset.n,p));
 const m=document.getElementById('more');if(m)m.onclick=()=>buySheet(true);
 const cu=document.getElementById('cu');if(cu){const b=document.getElementById('cuB'),pp=document.getElementById('cuP');cu.focus();
  cu.oninput=()=>{cu.value=cu.value.replace(/\D/g,'').slice(0,4);const n=+cu.value||0,ok=n>=50&&n*1.7<=10000;pp.textContent=n?rub(n*1.7):'';b.style.display=n?'flex':'none';b.disabled=!ok;b.style.opacity=ok?1:.5;b.textContent=ok?`Купить ${fmt(n)} ${word(n)} за ${rub(n*1.7)}`:(n<50?'Минимум 50 люменов':'Не больше 10 000 ₽ за раз')};
  b.onclick=()=>{const n=+cu.value||0;if(n>=50&&n*1.7<=10000)pay(n,b)};
  cu.onkeydown=e=>{if(e.key==='Enter')b.click()}}}
function pay(n,el){if(busy)return;busy=true;el&&el.classList.add('busy');post({t:'buy',qty:n});setTimeout(close,250)}
const PLANS=[[12,2490,'Год','−58%'],[6,1490,'Полгода','−38%'],[1,199,'Месяц','']];
function premSheet(sel=12){open(`<div class="sh"><button class="x" title="Закрыть">${I.x}</button></div>
 <div class="mini"><div class="glow" style="background:radial-gradient(circle,rgba(164,139,255,.45),transparent 62%)"></div><svg class="star" viewBox="0 0 24 24"><path fill="url(#sg)" d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z"/></svg></div>
 <h2>${D&&D.premium?'Продлить Lumo Premium':'Lumo Premium'}</h2><div class="sub">Выберите срок подписки</div>
 <div class="card" style="margin-top:0">${PLANS.map(([m,p,t,b])=>`<div class="plan ${m==sel?'on':''}" data-m="${m}"><div class="rb"></div><div class="t"><b>${t}</b>${b?`<span class="bd">${b}</span>`:''}${m>1?`<span class="pm">${rub(p/m)}/мес</span>`:''}</div><div class="pr">${rub(p)}</div></div>`).join('')}</div>
 <button class="btn pri wide" id="pp">Оплатить ${rub(PLANS.find(x=>x[0]==sel)[1])}</button>
 <div class="note">${I.shield}<div>Оплата картой через ЮMoney прямо в Lumo. Premium включается автоматически сразу после оплаты.</div></div>`);
 sheet.querySelectorAll('.plan').forEach(p=>p.onclick=()=>premSheet(+p.dataset.m));
 document.getElementById('pp').onclick=()=>{if(busy)return;busy=true;post({t:'prem',m:sel});setTimeout(close,250)}}
window.lumo={render(d){D=d;draw()},error(e){document.getElementById('app').innerHTML='<div class="err">'+esc(e)+'</div>'},idle(){busy=false},
 askAmount(name){open(`<div class="sh"><button class="x" title="Закрыть">${I.x}</button><div class="sb"><span>Баланс</span><b>${gem()}${fmt(D?D.balance:0)}</b></div></div>
 <div class="mini"><div class="glow"></div>${gem('big')}</div><h2>Отправить люмены</h2><div class="sub">для ${esc(name)}</div>
 <div class="inp">${gem()}<input id="am" value="10" inputmode="numeric" maxlength="6"></div><button class="btn pri wide" id="amB">Отправить</button>`);
 const am=document.getElementById('am');am.focus();am.select();am.oninput=()=>{am.value=am.value.replace(/\D/g,'').slice(0,6)};
 const go=()=>{const n=+am.value||0;if(n<=0)return;post({t:'send',amount:n});close()};document.getElementById('amB').onclick=go;am.onkeydown=e=>{if(e.key==='Enter')go()}}};
</script></body></html>
""";
}
