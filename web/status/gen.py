"""Эмодзи-статусы Lumo: 18 нарисованных значков с анимацией (SVG + CSS).
Один исходник для всех платформ: веб вставляет SVG как есть, приложения получают ленты кадров (build.js).
Все анимации кратны 2 секундам — цикл бесшовный."""
import math, os, json

OUT = os.path.dirname(os.path.abspath(__file__))
LOOP = 2.0

def svg(key, defs, body, css):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" class="lst-{key}">'
            f'<style>{css}</style><defs>{defs}</defs>{body}</svg>')

def lin(i, stops, x1=0, y1=0, x2=0, y2=1):
    s = ''.join(f'<stop offset="{o}" stop-color="{c}"' + (f' stop-opacity="{a[0]}"' if a else '') + '/>' for o, c, *a in stops)
    return f'<linearGradient id="{i}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>'

def rad(i, stops, cx=.5, cy=.5, r=.5, fx=None, fy=None):
    s = ''.join(f'<stop offset="{o}" stop-color="{c}"' + (f' stop-opacity="{a[0]}"' if a else '') + '/>' for o, c, *a in stops)
    f = (f' fx="{fx}" fy="{fy}"' if fx is not None else '')
    return f'<radialGradient id="{i}" cx="{cx}" cy="{cy}" r="{r}"{f}>{s}</radialGradient>'

def sparkle(x, y, r, cls, fill='#fff', style=''):
    """четырёхлучевая искра"""
    k = r * .22
    d = f'M{x} {y-r} C{x+k} {y-k} {x+k} {y-k} {x+r} {y} C{x+k} {y+k} {x+k} {y+k} {x} {y+r} C{x-k} {y+k} {x-k} {y+k} {x-r} {y} C{x-k} {y-k} {x-k} {y-k} {x} {y-r}Z'
    return f'<path class="{cls}" style="transform-origin:{x}px {y}px;{style}" d="{d}" fill="{fill}"/>'

TW = lambda k: f'.{k}-tw{{animation:{k}-tw 1s ease-in-out infinite}}@keyframes {k}-tw{{0%,100%{{transform:scale(.2) rotate(0);opacity:0}}50%{{transform:scale(1) rotate(45deg);opacity:1}}}}'

ICONS = {}

# ---------------------------------------------------------------- огонь
def fire():
    k = 'f'
    defs = (lin('f1', [(0, '#ffd23f'), (.45, '#ff7a1a'), (1, '#e0211b')], 0, 1, 0, 0) +
            lin('f2', [(0, '#fff7c2'), (.5, '#ffd43b'), (1, '#ff9a1f')], 0, 1, 0, 0) +
            rad('f3', [(0, '#ffffff'), (.6, '#fff3a6'), (1, '#ffd43b', 0)]) +
            rad('f4', [(0, '#ff8a1f', .55), (1, '#ff8a1f', 0)]))
    css = (f'.{k}-o{{transform-origin:50px 92px;animation:{k}-o 1s ease-in-out infinite}}'
           f'@keyframes {k}-o{{0%,100%{{transform:scale(1,1) skewX(0)}}25%{{transform:scale(.95,1.06) skewX(-3deg)}}50%{{transform:scale(1.04,.96) skewX(1.5deg)}}75%{{transform:scale(.97,1.04) skewX(3deg)}}}}'
           f'.{k}-i{{transform-origin:50px 92px;animation:{k}-i .5s ease-in-out infinite}}'
           f'@keyframes {k}-i{{0%,100%{{transform:scale(1,1)}}50%{{transform:scale(.9,1.1) skewX(-4deg)}}}}'
           f'.{k}-c{{transform-origin:50px 84px;animation:{k}-c .5s ease-in-out infinite}}@keyframes {k}-c{{0%,100%{{transform:scale(1)}}50%{{transform:scale(1.18,.9)}}}}'
           f'.{k}-g{{transform-origin:50px 70px;animation:{k}-g 1s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.7;transform:scale(1)}}50%{{opacity:1;transform:scale(1.1)}}}}'
           f'.{k}-s{{animation:{k}-s 1s linear infinite;opacity:0}}@keyframes {k}-s{{0%{{transform:translate(0,0) scale(1);opacity:0}}15%{{opacity:1}}100%{{transform:translate(var(--dx),-46px) scale(.2);opacity:0}}}}')
    body = ('<ellipse class="f-g" cx="50" cy="66" rx="44" ry="40" fill="url(#f4)"/>'
            '<g class="f-o"><path d="M50 5 C57 22 78 34 78 59 C78 79 65 93 50 93 C35 93 22 79 22 59 C22 47 28 38 35 30 C36 40 41 45 46 45 C41 31 43 16 50 5Z" fill="url(#f1)"/>''</g>'
            '<g class="f-i"><path d="M51 42 C55 53 66 60 66 73 C66 85 58 92 50 92 C42 92 34 85 34 73 C34 65 39 60 43 54 C44 61 47 63 50 63 C47 56 48 49 51 42Z" fill="url(#f2)"/></g>'
            '<ellipse class="f-c" cx="50" cy="82" rx="9" ry="10" fill="url(#f3)"/>'
            '<circle class="f-s" style="--dx:-8px" cx="33" cy="40" r="2.6" fill="#ffd23f"/>'
            '<circle class="f-s" style="--dx:7px;animation-delay:-.4s" cx="68" cy="44" r="2.2" fill="#ff9a1f"/>'
            '<circle class="f-s" style="--dx:3px;animation-delay:-.7s" cx="56" cy="24" r="1.8" fill="#fff3a6"/>')
    return svg('fire', defs, body, css)
ICONS['fire'] = fire

# ---------------------------------------------------------------- сердце
def heart():
    k = 'h'
    H = 'M50 89 C19 67 7 51 7 33 C7 19 18 9 31 9 C39 9 46 13 50 21 C54 13 61 9 69 9 C82 9 93 19 93 33 C93 51 81 67 50 89Z'
    defs = (rad('h1', [(0, '#ff9db0'), (.35, '#ff3b62'), (.8, '#e01245'), (1, '#a80a33')], .36, .3, .8) +
            lin('h2', [(0, '#ffffff', .75), (1, '#ffffff', 0)]) +
            rad('h3', [(0, '#ff2d55', .5), (1, '#ff2d55', 0)]) +
            f'<clipPath id="hc"><path d="{H}"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 52px;animation:{k}-b 1s cubic-bezier(.4,0,.2,1) infinite}}'
           f'@keyframes {k}-b{{0%,100%{{transform:scale(1)}}12%{{transform:scale(1.14)}}26%{{transform:scale(.98)}}38%{{transform:scale(1.08)}}55%{{transform:scale(1)}}}}'
           f'.{k}-g{{transform-origin:50px 50px;animation:{k}-g 1s ease-out infinite}}@keyframes {k}-g{{0%{{transform:scale(.7);opacity:.9}}60%,100%{{transform:scale(1.25);opacity:0}}}}' + TW(k))
    body = ('<circle class="h-g" cx="50" cy="50" r="46" fill="url(#h3)"/>'
            f'<g class="h-b"><path d="{H}" fill="url(#h1)"/>'
            '<g clip-path="url(#hc)"><ellipse cx="50" cy="96" rx="52" ry="26" fill="#7a0626" opacity=".35"/>'
            '<ellipse cx="29" cy="27" rx="15" ry="10" transform="rotate(-32 29 27)" fill="url(#h2)"/>'
            '<ellipse cx="70" cy="22" rx="8" ry="4.5" transform="rotate(24 70 22)" fill="#fff" opacity=".28"/></g></g>' +
            sparkle(84, 14, 7, 'h-tw') + sparkle(14, 70, 5, 'h-tw', style='animation-delay:-.5s'))
    return svg('heart', defs, body, css)
ICONS['heart'] = heart

# ---------------------------------------------------------------- звезда
def star():
    k = 's'
    cx, cy, R, r = 50, 53, 43, 19
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = R if i % 2 == 0 else r
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    outline = 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + 'Z'
    facets = ''
    shades = ['#fff4b8', '#ffd84a', '#ffbf1f', '#f29a0b', '#ffcf3a', '#ffe680', '#ffc22e', '#e88d07', '#ffb81a', '#ffe98f']
    for i in range(10):
        a, b = pts[i], pts[(i + 1) % 10]
        facets += f'<path d="M{cx} {cy} L{a[0]:.1f} {a[1]:.1f} L{b[0]:.1f} {b[1]:.1f}Z" fill="{shades[i]}"/>'
    defs = (lin('s1', [(0, '#ffe680'), (1, '#f29a0b')]) + rad('s2', [(0, '#ffd23f', .6), (1, '#ffd23f', 0)]) +
            lin('s3', [(0, '#fff', 0), (.5, '#fff', .85), (1, '#fff', 0)], 0, 0, 1, 0) + f'<clipPath id="sc"><path d="{outline}"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 53px;animation:{k}-b 2s ease-in-out infinite}}'
           f'@keyframes {k}-b{{0%,100%{{transform:rotate(-7deg) scale(1)}}50%{{transform:rotate(7deg) scale(1.07)}}}}'
           f'.{k}-g{{transform-origin:50px 53px;animation:{k}-g 1s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{transform:scale(.9);opacity:.6}}50%{{transform:scale(1.12);opacity:1}}}}'
           f'.{k}-w{{animation:{k}-w 2s ease-in-out infinite}}@keyframes {k}-w{{0%,35%{{transform:translateX(-80px)}}75%,100%{{transform:translateX(80px)}}}}' + TW(k))
    body = ('<circle class="s-g" cx="50" cy="53" r="48" fill="url(#s2)"/>'
            f'<g class="s-b"><path d="{outline}" fill="url(#s1)" stroke="url(#s1)" stroke-width="7" stroke-linejoin="round"/>'
            f'<g clip-path="url(#sc)">{facets}<g class="s-w"><polygon points="38,0 54,0 44,100 28,100" fill="url(#s3)"/></g></g>'
            f'<path d="{outline}" fill="none" stroke="#fff6c9" stroke-width="1.2" stroke-linejoin="round" opacity=".7"/></g>' +
            sparkle(86, 18, 8, 's-tw') + sparkle(13, 30, 5.5, 's-tw', style='animation-delay:-.35s') + sparkle(80, 84, 5, 's-tw', style='animation-delay:-.7s'))
    return svg('star', defs, body, css)
ICONS['star'] = star

# ---------------------------------------------------------------- ракета
def rocket():
    k = 'r'
    defs = (lin('r1', [(0, '#c9d3e6'), (.35, '#ffffff'), (.7, '#eef2f8'), (1, '#9aa7c2')], 0, 0, 1, 0) +
            lin('r2', [(0, '#ff6b6b'), (1, '#c9182e')], 0, 0, 1, 0) +
            rad('r3', [(0, '#bff0ff'), (.6, '#3aa7ff'), (1, '#1456c8')], .4, .35, .7) +
            lin('r4', [(0, '#fff7c2'), (.4, '#ffc531'), (1, '#ff5a1f', 0)]) +
            lin('r5', [(0, '#ffffff'), (1, '#8fe3ff', 0)]))
    css = (f'.{k}-b{{transform-origin:50px 50px;animation:{k}-b .5s ease-in-out infinite}}@keyframes {k}-b{{0%,100%{{transform:rotate(45deg) scale(.88) translate(0,0)}}50%{{transform:rotate(45deg) scale(.88) translate(1px,-2px)}}}}'
           f'.{k}-f{{transform-origin:50px 78px;animation:{k}-f .25s ease-in-out infinite}}@keyframes {k}-f{{0%,100%{{transform:scale(1,1)}}50%{{transform:scale(.82,1.22)}}}}'
           f'.{k}-f2{{transform-origin:50px 78px;animation:{k}-f .25s ease-in-out -.12s infinite}}'
           f'.{k}-l{{animation:{k}-l .5s linear infinite}}@keyframes {k}-l{{0%{{transform:translate(26px,-26px);opacity:0}}20%{{opacity:.9}}100%{{transform:translate(-26px,26px);opacity:0}}}}')
    body = ('<path class="r-l" d="M84 30 l-12 12" stroke="#fff" stroke-width="2.4" stroke-linecap="round" opacity=".8"/>'
            '<path class="r-l" style="animation-delay:-.2s" d="M70 86 l-9 9" stroke="#bfe3ff" stroke-width="2" stroke-linecap="round"/>'
            '<path class="r-l" style="animation-delay:-.35s" d="M26 16 l-8 8" stroke="#fff" stroke-width="1.8" stroke-linecap="round"/>'
            '<g class="r-b">'
            '<path class="r-f" d="M41 76 C41 90 46 100 50 108 C54 100 59 90 59 76Z" fill="url(#r4)"/>'
            '<path class="r-f2" d="M45 76 C45 86 48 93 50 98 C52 93 55 86 55 76Z" fill="url(#r5)"/>'
            '<path d="M34 58 L22 76 L24 82 L38 74Z" fill="url(#r2)"/><path d="M66 58 L78 76 L76 82 L62 74Z" fill="url(#r2)"/>'
            '<path d="M50 4 C64 16 68 38 66 58 L62 78 L38 78 L34 58 C32 38 36 16 50 4Z" fill="url(#r1)"/>'
            '<path d="M50 4 C57 10 61.5 18 64 27 C55 23 45 23 36 27 C38.5 18 43 10 50 4Z" fill="url(#r2)"/>'
            '<path d="M47 60 L50 86 L53 60Z" fill="url(#r2)"/>'
            '<circle cx="50" cy="42" r="10.5" fill="#5a6a8c"/><circle cx="50" cy="42" r="8" fill="url(#r3)"/>'
            '<path d="M44.5 39 a6.5 6.5 0 0 1 7 -4.5" stroke="#fff" stroke-width="1.8" fill="none" stroke-linecap="round" opacity=".85"/>'
            '<rect x="38" y="74" width="24" height="5" rx="2" fill="#5a6a8c"/>'
            '<path d="M41 14 C38 24 37 40 38 56" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round" opacity=".55"/>'
            '</g>')
    return svg('rocket', defs, body, css)
ICONS['rocket'] = rocket

# ---------------------------------------------------------------- корона
def crown():
    k = 'c'
    C = 'M14 74 L8 30 L30 47 L41 16 L50 40 L59 16 L70 47 L92 30 L86 74Z'
    defs = (lin('c1', [(0, '#fff3b0'), (.35, '#ffd43b'), (.75, '#f2a007'), (1, '#b96f00')]) +
            lin('c2', [(0, '#ffe680'), (.5, '#f2a007'), (1, '#a05e00')]) +
            rad('c3', [(0, '#ffd0e1'), (.5, '#ff3b7a'), (1, '#a3073f')], .35, .3, .75) +
            rad('c4', [(0, '#d6f4ff'), (.5, '#33b6ff'), (1, '#0b5fb8')], .35, .3, .75) +
            lin('c5', [(0, '#fff', 0), (.5, '#fff', .9), (1, '#fff', 0)], 0, 0, 1, 0) +
            f'<clipPath id="cc"><path d="{C}"/><rect x="11" y="72" width="78" height="16" rx="5"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 60px;animation:{k}-b 2s ease-in-out infinite}}@keyframes {k}-b{{0%,100%{{transform:translateY(1.5px) rotate(-3deg)}}50%{{transform:translateY(-2.5px) rotate(3deg)}}}}'
           f'.{k}-w{{animation:{k}-w 2s ease-in-out infinite}}@keyframes {k}-w{{0%,30%{{transform:translateX(-95px)}}70%,100%{{transform:translateX(95px)}}}}'
           f'.{k}-j{{animation:{k}-j 1s ease-in-out infinite}}@keyframes {k}-j{{0%,100%{{filter:brightness(1)}}50%{{filter:brightness(1.35)}}}}' + TW(k))
    body = (f'<g class="c-b"><path d="{C}" fill="url(#c1)" stroke="url(#c1)" stroke-width="5" stroke-linejoin="round"/>'
            '<path d="M14 74 L8 30 L20 39 L24 74Z" fill="#fff" opacity=".22"/><path d="M41 16 L50 40 L46 44 L37 28Z" fill="#fff" opacity=".28"/>'
            '<path d="M70 47 L92 30 L86 74 L76 74Z" fill="#8a4d00" opacity=".22"/>'
            '<rect x="11" y="72" width="78" height="16" rx="5" fill="url(#c2)"/><rect x="13" y="74" width="74" height="4" rx="2" fill="#fff" opacity=".4"/>'
            '<g clip-path="url(#cc)"><g class="c-w"><polygon points="40,0 58,0 46,100 28,100" fill="url(#c5)"/></g></g>'
            '<circle cx="8" cy="29" r="6" fill="url(#c1)"/><circle cx="92" cy="29" r="6" fill="url(#c1)"/><circle cx="41" cy="15" r="6" fill="url(#c1)"/><circle cx="59" cy="15" r="6" fill="url(#c1)"/>'
            '<circle cx="6.5" cy="27" r="2" fill="#fff" opacity=".7"/><circle cx="39.5" cy="13" r="2" fill="#fff" opacity=".7"/><circle cx="57.5" cy="13" r="2" fill="#fff" opacity=".7"/><circle cx="90.5" cy="27" r="2" fill="#fff" opacity=".7"/>'
            '<g class="c-j"><path d="M50 50 L59 60 L50 70 L41 60Z" fill="url(#c3)"/><path d="M50 50 L59 60 L50 60Z" fill="#fff" opacity=".35"/></g>'
            '<g class="c-j" style="animation-delay:-.5s"><circle cx="26" cy="62" r="5.5" fill="url(#c4)"/><circle cx="74" cy="62" r="5.5" fill="url(#c4)"/>'
            '<circle cx="24.5" cy="60.5" r="1.6" fill="#fff" opacity=".8"/><circle cx="72.5" cy="60.5" r="1.6" fill="#fff" opacity=".8"/></g>'
            '<circle cx="30" cy="80" r="3" fill="url(#c3)"/><circle cx="50" cy="80" r="3" fill="url(#c4)"/><circle cx="70" cy="80" r="3" fill="url(#c3)"/></g>' +
            sparkle(88, 10, 7, 'c-tw') + sparkle(12, 12, 5, 'c-tw', style='animation-delay:-.5s'))
    return svg('crown', defs, body, css)
ICONS['crown'] = crown

# ---------------------------------------------------------------- алмаз
def gem():
    k = 'g'
    O = 'M26 14 L74 14 L94 40 L50 92 L6 40Z'
    defs = (lin('g5', [(0, '#fff', 0), (.5, '#fff', .9), (1, '#fff', 0)], 0, 0, 1, 0) + rad('g6', [(0, '#4cc9ff', .55), (1, '#4cc9ff', 0)]) +
            f'<clipPath id="gc"><path d="{O}"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 52px;animation:{k}-b 2s ease-in-out infinite}}@keyframes {k}-b{{0%,100%{{transform:translateY(1.5px) rotate(-4deg)}}50%{{transform:translateY(-2.5px) rotate(4deg)}}}}'
           f'.{k}-w{{animation:{k}-w 2s ease-in-out infinite}}@keyframes {k}-w{{0%,25%{{transform:translateX(-95px)}}65%,100%{{transform:translateX(95px)}}}}'
           f'.{k}-g{{transform-origin:50px 52px;animation:{k}-g 1s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.55;transform:scale(.95)}}50%{{opacity:1;transform:scale(1.1)}}}}'
           f'.{k}-f{{animation:{k}-f 1s ease-in-out infinite}}@keyframes {k}-f{{0%,100%{{opacity:0}}50%{{opacity:.5}}}}' + TW(k))
    body = ('<circle class="g-g" cx="50" cy="52" r="48" fill="url(#g6)"/><g class="g-b">'
            f'<path d="{O}" fill="#1e7fe0" stroke="#1e7fe0" stroke-width="4" stroke-linejoin="round"/>'
            # верхние грани
            '<path d="M26 14 L38 40 L6 40Z" fill="#7fd8ff"/><path d="M26 14 L50 14 L38 40Z" fill="#c8f1ff"/><path d="M50 14 L62 40 L38 40Z" fill="#8fe0ff"/>'
            '<path d="M50 14 L74 14 L62 40Z" fill="#5cc4ff"/><path d="M74 14 L94 40 L62 40Z" fill="#2f9df2"/>'
            # нижние грани
            '<path d="M6 40 L38 40 L50 92Z" fill="#3fb0ff"/><path d="M38 40 L62 40 L50 92Z" fill="#6fd0ff"/><path d="M62 40 L94 40 L50 92Z" fill="#1669c9"/>'
            '<path class="g-f" d="M38 40 L62 40 L50 92Z" fill="#fff"/><path class="g-f" style="animation-delay:-.5s" d="M26 14 L38 40 L6 40Z" fill="#fff"/>'
            '<g clip-path="url(#gc)"><g class="g-w"><polygon points="40,0 56,0 44,100 28,100" fill="url(#g5)"/></g></g>'
            '<path d="M26 14 L74 14 L94 40 L6 40Z M38 40 L26 14 M62 40 L74 14 M38 40 L50 14 L62 40 M38 40 L50 92 L62 40" fill="none" stroke="#e9fbff" stroke-width="1" stroke-linejoin="round" opacity=".7"/></g>' +
            sparkle(88, 14, 8, 'g-tw') + sparkle(12, 20, 5.5, 'g-tw', style='animation-delay:-.4s') + sparkle(80, 80, 5, 'g-tw', style='animation-delay:-.75s'))
    return svg('gem', defs, body, css)
ICONS['gem'] = gem

# ---------------------------------------------------------------- молния
def bolt():
    k = 'b'
    B = 'M60 4 L20 56 L44 56 L36 96 L82 40 L56 40Z'
    defs = (lin('b1', [(0, '#fff7b0'), (.4, '#ffd60a'), (1, '#ff9500')]) + rad('b2', [(0, '#ffe45c', .7), (1, '#ffe45c', 0)]) +
            f'<clipPath id="bc"><path d="{B}"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 50px;animation:{k}-b 1s linear infinite}}@keyframes {k}-b{{0%,100%{{transform:translate(0,0) scale(1)}}6%{{transform:translate(-1.5px,1px) scale(1.06)}}12%{{transform:translate(1.5px,-1px) scale(1.03)}}18%{{transform:translate(-.8px,.5px) scale(1.05)}}26%{{transform:translate(0,0) scale(1)}}}}'
           f'.{k}-g{{transform-origin:50px 50px;animation:{k}-g 1s ease-out infinite}}@keyframes {k}-g{{0%{{opacity:.2;transform:scale(.8)}}8%{{opacity:1;transform:scale(1.2)}}40%,100%{{opacity:.3;transform:scale(.9)}}}}'
           f'.{k}-f{{animation:{k}-f 1s ease-out infinite}}@keyframes {k}-f{{0%{{opacity:0}}6%{{opacity:.95}}30%,100%{{opacity:0}}}}'
           f'.{k}-z{{stroke-dasharray:26;animation:{k}-z 1s linear infinite}}@keyframes {k}-z{{0%{{stroke-dashoffset:26;opacity:0}}10%{{opacity:1}}45%{{stroke-dashoffset:-26;opacity:0}}100%{{stroke-dashoffset:-26;opacity:0}}}}')
    body = ('<circle class="b-g" cx="50" cy="50" r="48" fill="url(#b2)"/>'
            '<path class="b-z" d="M14 26 l6 6 l-4 4 l7 7" stroke="#fff7b0" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
            '<path class="b-z" style="animation-delay:-.15s" d="M90 62 l-6 5 l4 4 l-7 6" stroke="#fff7b0" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<g class="b-b"><path d="{B}" fill="url(#b1)" stroke="url(#b1)" stroke-width="5" stroke-linejoin="round"/>'
            '<g clip-path="url(#bc)"><path d="M60 4 L20 56 L30 56 L62 14Z" fill="#fff" opacity=".45"/><path d="M82 40 L36 96 L44 70 L70 40Z" fill="#c25e00" opacity=".25"/></g>'
            f'<path class="b-f" d="{B}" fill="#fff" stroke="#fff" stroke-width="5" stroke-linejoin="round"/></g>')
    return svg('bolt', defs, body, css)
ICONS['bolt'] = bolt

# ---------------------------------------------------------------- привидение
def ghost():
    k = 'gh'
    G = 'M50 8 C28 8 16 26 16 46 L16 84 C16 90 21 91 25 87 L32 80 L40 89 C42 91 44 91 46 89 L50 84 L54 89 C56 91 58 91 60 89 L68 80 L75 87 C79 91 84 90 84 84 L84 46 C84 26 72 8 50 8Z'
    defs = (lin('gh1', [(0, '#ffffff'), (.6, '#eef1fb'), (1, '#c3c9e6')]) + rad('gh2', [(0, '#b9a6ff', .5), (1, '#b9a6ff', 0)]) +
            f'<clipPath id="ghc"><path d="{G}"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 50px;animation:{k}-b 2s ease-in-out infinite}}@keyframes {k}-b{{0%,100%{{transform:translateY(3px) rotate(-4deg)}}50%{{transform:translateY(-5px) rotate(4deg)}}}}'
           f'.{k}-e{{transform-origin:50px 42px;animation:{k}-e 2s linear infinite}}@keyframes {k}-e{{0%,44%,52%,100%{{transform:scaleY(1)}}48%{{transform:scaleY(.1)}}}}'
           f'.{k}-s{{transform-origin:50px 95px;animation:{k}-s 2s ease-in-out infinite}}@keyframes {k}-s{{0%,100%{{transform:scale(1.05);opacity:.3}}50%{{transform:scale(.75);opacity:.16}}}}'
           f'.{k}-g{{transform-origin:50px 50px;animation:{k}-g 2s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.5}}50%{{opacity:1}}}}')
    body = ('<ellipse class="gh-s" cx="50" cy="95" rx="26" ry="4" fill="#000"/><circle class="gh-g" cx="50" cy="48" r="48" fill="url(#gh2)"/>'
            f'<g class="gh-b"><path d="{G}" fill="url(#gh1)"/>'
            '<g clip-path="url(#ghc)"><path d="M84 30 L84 95 L66 95 C74 76 76 50 68 22Z" fill="#8f97c9" opacity=".28"/>'
            '<ellipse cx="34" cy="26" rx="9" ry="14" transform="rotate(24 34 26)" fill="#fff" opacity=".9"/></g>'
            '<g class="gh-e"><ellipse cx="38" cy="42" rx="6" ry="8.5" fill="#23233a"/><ellipse cx="62" cy="42" rx="6" ry="8.5" fill="#23233a"/>'
            '<circle cx="40" cy="38.5" r="2.4" fill="#fff"/><circle cx="64" cy="38.5" r="2.4" fill="#fff"/></g>'
            '<ellipse cx="50" cy="60" rx="5.5" ry="7" fill="#23233a"/><ellipse cx="50" cy="63.5" rx="3.4" ry="3" fill="#ff7b95"/>'
            '<ellipse cx="27" cy="54" rx="5" ry="3" fill="#ff9db0" opacity=".55"/><ellipse cx="73" cy="54" rx="5" ry="3" fill="#ff9db0" opacity=".55"/></g>')
    return svg('ghost', defs, body, css)
ICONS['ghost'] = ghost

# ---------------------------------------------------------------- солнце
def sun():
    k = 'su'
    rays = ''
    for i in range(12):
        a = i * 30
        long = i % 2 == 0
        rays += (f'<path transform="rotate({a} 50 50)" d="M46 {19 if long else 21} L50 {2 if long else 9} L54 {19 if long else 21}Z" fill="url(#su2)" stroke="url(#su2)" stroke-width="2.5" stroke-linejoin="round"/>')
    defs = (rad('su1', [(0, '#fffbd6'), (.35, '#ffe14d'), (.8, '#ffb300'), (1, '#f08a00')], .38, .34, .75) +
            lin('su2', [(0, '#ffe45c'), (1, '#ff9a00')]) + rad('su3', [(0, '#ffd23f', .65), (.6, '#ffb300', .2), (1, '#ffb300', 0)]))
    css = (f'.{k}-r{{transform-origin:50px 50px;animation:{k}-r 2s linear infinite}}@keyframes {k}-r{{to{{transform:rotate(60deg)}}}}'
           f'.{k}-p{{transform-origin:50px 50px;animation:{k}-p 1s ease-in-out infinite}}@keyframes {k}-p{{0%,100%{{transform:scale(1)}}50%{{transform:scale(1.04)}}}}'
           f'.{k}-c{{transform-origin:50px 50px;animation:{k}-c 1s ease-in-out infinite}}@keyframes {k}-c{{0%,100%{{transform:scale(1)}}50%{{transform:scale(1.05)}}}}'
           f'.{k}-g{{transform-origin:50px 50px;animation:{k}-g 1s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.6;transform:scale(.92)}}50%{{opacity:1;transform:scale(1.06)}}}}')
    body = ('<circle class="su-g" cx="50" cy="50" r="50" fill="url(#su3)"/>'
            f'<g class="su-r"><g class="su-p">{rays}</g></g>'
            '<g class="su-c"><circle cx="50" cy="50" r="25" fill="url(#su1)"/>'
            '<ellipse cx="41" cy="40" rx="10" ry="6.5" transform="rotate(-35 41 40)" fill="#fff" opacity=".55"/>'
            '<path d="M70 62 A25 25 0 0 1 36 71 A28 28 0 0 0 70 62Z" fill="#d97400" opacity=".3"/></g>')
    return svg('sun', defs, body, css)
ICONS['sun'] = sun

# ---------------------------------------------------------------- луна
def moon():
    k = 'm'
    M = 'M62 8 A44 44 0 1 0 92 66 A36 36 0 0 1 62 8Z'
    defs = (rad('m1', [(0, '#fffbe0'), (.45, '#ffe38a'), (1, '#f0b83a')], .3, .35, .8) + rad('m2', [(0, '#ffe9a0', .5), (1, '#ffe9a0', 0)]) +
            f'<clipPath id="mc"><path d="{M}"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 52px;animation:{k}-b 2s ease-in-out infinite}}@keyframes {k}-b{{0%,100%{{transform:rotate(-9deg)}}50%{{transform:rotate(7deg)}}}}'
           f'.{k}-g{{transform-origin:46px 52px;animation:{k}-g 2s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.55}}50%{{opacity:1}}}}' + TW(k))
    body = ('<circle class="m-g" cx="46" cy="52" r="50" fill="url(#m2)"/>'
            f'<g class="m-b"><path d="{M}" fill="url(#m1)"/>'
            '<g clip-path="url(#mc)"><path d="M30 92 A44 44 0 0 0 92 66 A40 40 0 0 1 22 80Z" fill="#c98a12" opacity=".28"/>'
            '<circle cx="34" cy="38" r="7" fill="#e0a82e" opacity=".5"/><circle cx="33" cy="37" r="5.2" fill="#f7cf63" opacity=".6"/>'
            '<circle cx="28" cy="62" r="4.5" fill="#e0a82e" opacity=".5"/><circle cx="46" cy="76" r="6" fill="#e0a82e" opacity=".45"/><circle cx="45" cy="75" r="4.3" fill="#f7cf63" opacity=".5"/>'
            '<circle cx="48" cy="22" r="3" fill="#e0a82e" opacity=".45"/>'
            '<path d="M24 30 A44 44 0 0 1 50 9" stroke="#fff" stroke-width="3.5" fill="none" stroke-linecap="round" opacity=".6"/></g></g>' +
            sparkle(78, 30, 9, 'm-tw') + sparkle(88, 52, 5, 'm-tw', style='animation-delay:-.5s') + sparkle(68, 50, 4, 'm-tw', style='animation-delay:-.25s'))
    return svg('moon', defs, body, css)
ICONS['moon'] = moon

# ---------------------------------------------------------------- клевер
def clover():
    k = 'cl'
    leaf = 'M50 46 C40 36 26 34 26 22 C26 13 36 8 43 13 C47 16 49 20 50 24 C51 20 53 16 57 13 C64 8 74 13 74 22 C74 34 60 36 50 46Z'
    leaves = ''.join(f'<g transform="rotate({a} 50 47)"><path d="{leaf}" fill="url(#cl1)"/><path d="M50 44 L50 25" stroke="#0f7a37" stroke-width="1.6" stroke-linecap="round" opacity=".6"/>'
                     f'<path d="M34 14 C29 16 28 22 31 27" stroke="#fff" stroke-width="2.6" fill="none" stroke-linecap="round" opacity=".5"/></g>' for a in (0, 90, 180, 270))
    defs = (rad('cl1', [(0, '#8ff0a0'), (.5, '#2fc45a'), (1, '#128a3c')], .35, .25, .85) + lin('cl2', [(0, '#2fc45a'), (1, '#0f7a37')]) +
            rad('cl3', [(0, '#5ee07f', .5), (1, '#5ee07f', 0)]))
    css = (f'.{k}-b{{transform-origin:50px 94px;animation:{k}-b 2s ease-in-out infinite}}@keyframes {k}-b{{0%,100%{{transform:rotate(-7deg)}}50%{{transform:rotate(7deg)}}}}'
           f'.{k}-l{{transform-origin:50px 47px;animation:{k}-l 2s ease-in-out infinite}}@keyframes {k}-l{{0%,100%{{transform:rotate(6deg) scale(1)}}50%{{transform:rotate(-6deg) scale(1.05)}}}}'
           f'.{k}-g{{animation:{k}-g 2s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.5}}50%{{opacity:1}}}}' + TW(k))
    body = ('<circle class="cl-g" cx="50" cy="47" r="48" fill="url(#cl3)"/><g class="cl-b">'
            '<path d="M51 50 C52 66 58 80 66 92" stroke="url(#cl2)" stroke-width="5" fill="none" stroke-linecap="round"/>'
            f'<g class="cl-l">{leaves}<circle cx="50" cy="47" r="4" fill="#0f7a37"/><circle cx="49" cy="46" r="1.6" fill="#8ff0a0"/></g></g>' +
            sparkle(86, 16, 7, 'cl-tw') + sparkle(14, 78, 5, 'cl-tw', style='animation-delay:-.5s'))
    return svg('clover', defs, body, css)
ICONS['clover'] = clover

# ---------------------------------------------------------------- нота
def note():
    k = 'n'
    defs = (lin('n1', [(0, '#c9a6ff'), (.5, '#8b5cf6'), (1, '#4c1fb8')], 0, 0, 1, 1) + rad('n2', [(0, '#e6d6ff'), (.5, '#9b6dff'), (1, '#4c1fb8')], .35, .3, .8) +
            rad('n3', [(0, '#9b6dff', .5), (1, '#9b6dff', 0)]))
    css = (f'.{k}-b{{transform-origin:50px 90px;animation:{k}-b 1s cubic-bezier(.4,0,.3,1) infinite}}@keyframes {k}-b{{0%,100%{{transform:translateY(0) rotate(-5deg) scale(1,1)}}15%{{transform:translateY(2px) rotate(-5deg) scale(1.06,.92)}}50%{{transform:translateY(-7px) rotate(5deg) scale(.97,1.04)}}}}'
           f'.{k}-w{{transform-origin:20px 60px;animation:{k}-w 1s ease-out infinite;fill:none;stroke-linecap:round}}@keyframes {k}-w{{0%{{transform:scale(.5);opacity:0}}25%{{opacity:.9}}100%{{transform:scale(1.25);opacity:0}}}}'
           f'.{k}-g{{animation:{k}-g 1s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.5}}50%{{opacity:1}}}}'
           f'.{k}-m{{animation:{k}-m 2s linear infinite;opacity:0}}@keyframes {k}-m{{0%{{transform:translate(0,8px) rotate(-10deg) scale(.6);opacity:0}}20%{{opacity:1}}100%{{transform:translate(6px,-26px) rotate(14deg) scale(1);opacity:0}}}}')
    mini = '<g class="n-m" style="{s}"><ellipse cx="{x}" cy="{y}" rx="4" ry="3" transform="rotate(-20 {x} {y})" fill="#c9a6ff"/><path d="M{x2} {y} v-12 l5 3" stroke="#c9a6ff" stroke-width="1.8" fill="none" stroke-linecap="round" stroke-linejoin="round"/></g>'
    body = ('<circle class="n-g" cx="52" cy="52" r="48" fill="url(#n3)"/>'
            + mini.format(s='', x=86, y=30, x2=89.5) + mini.format(s='animation-delay:-1s', x=12, y=34, x2=15.5) +
            '<g class="n-b"><path d="M36 20 L82 9 L82 25 L36 36Z" fill="url(#n1)"/><path d="M36 20 L82 9 L82 13 L36 24Z" fill="#fff" opacity=".35"/>'
            '<rect x="33" y="20" width="7" height="56" rx="3.5" fill="url(#n1)"/><rect x="77" y="9" width="7" height="56" rx="3.5" fill="url(#n1)"/>'
            '<ellipse cx="27" cy="76" rx="14.5" ry="11" transform="rotate(-22 27 76)" fill="url(#n2)"/><ellipse cx="71" cy="65" rx="14.5" ry="11" transform="rotate(-22 71 65)" fill="url(#n2)"/>'
            '<ellipse cx="22" cy="71" rx="5" ry="3" transform="rotate(-22 22 71)" fill="#fff" opacity=".6"/><ellipse cx="66" cy="60" rx="5" ry="3" transform="rotate(-22 66 60)" fill="#fff" opacity=".6"/></g>')
    return svg('note', defs, body, css)
ICONS['note'] = note

# ---------------------------------------------------------------- снежинка
def snow():
    k = 'sn'
    arm = ('<path d="M50 50 L50 7" stroke="url(#sn1)" stroke-width="6" stroke-linecap="round"/>'
           '<path d="M50 22 L40 12 M50 22 L60 12 M50 35 L39 25 M50 35 L61 25" stroke="url(#sn1)" stroke-width="4.6" stroke-linecap="round" fill="none"/>'
           '<path d="M50 48 L50 9" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".8"/>')
    arms = ''.join(f'<g transform="rotate({a} 50 50)">{arm}</g>' for a in range(0, 360, 60))
    defs = (lin('sn1', [(0, '#e9fbff'), (.5, '#8fd8ff'), (1, '#3aa0f0')]) + rad('sn2', [(0, '#ffffff'), (.6, '#bfeaff'), (1, '#5ab8f7')]) +
            rad('sn3', [(0, '#8fd8ff', .55), (1, '#8fd8ff', 0)]))
    css = (f'.{k}-r{{transform-origin:50px 50px;animation:{k}-r 2s linear infinite}}@keyframes {k}-r{{to{{transform:rotate(60deg)}}}}'
           f'.{k}-p{{transform-origin:50px 50px;animation:{k}-p 1s ease-in-out infinite}}@keyframes {k}-p{{0%,100%{{transform:scale(.96)}}50%{{transform:scale(1.04)}}}}'
           f'.{k}-g{{animation:{k}-g 1s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.5}}50%{{opacity:1}}}}' + TW(k))
    body = ('<circle class="sn-g" cx="50" cy="50" r="49" fill="url(#sn3)"/>'
            f'<g class="sn-p"><g class="sn-r">{arms}<polygon points="50,39 59.5,44.5 59.5,55.5 50,61 40.5,55.5 40.5,44.5" fill="url(#sn2)"/>'
            '<polygon points="50,43 56,46.5 56,53.5 50,57 44,53.5 44,46.5" fill="#fff" opacity=".7"/></g></g>' +
            sparkle(84, 16, 7, 'sn-tw') + sparkle(14, 82, 5.5, 'sn-tw', style='animation-delay:-.5s') + sparkle(88, 76, 4, 'sn-tw', style='animation-delay:-.25s'))
    return svg('snow', defs, body, css)
ICONS['snow'] = snow

# ---------------------------------------------------------------- кубок
def trophy():
    k = 't'
    CUP = 'M26 10 L74 10 C74 36 68 56 50 60 C32 56 26 36 26 10Z'
    defs = (lin('t1', [(0, '#b8780a'), (.25, '#ffd43b'), (.45, '#fff3b0'), (.7, '#f2a007'), (1, '#a86400')], 0, 0, 1, 0) +
            lin('t2', [(0, '#8a5200'), (.4, '#f2b01a'), (1, '#7a4700')], 0, 0, 1, 0) + lin('t3', [(0, '#5a3a22'), (.5, '#8a5a36'), (1, '#3f2714')], 0, 0, 1, 0) +
            lin('t5', [(0, '#fff', 0), (.5, '#fff', .9), (1, '#fff', 0)], 0, 0, 1, 0) + rad('t6', [(0, '#ffd23f', .5), (1, '#ffd23f', 0)]) +
            f'<clipPath id="tc"><path d="{CUP}"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 94px;animation:{k}-b 1s cubic-bezier(.4,0,.3,1) infinite}}@keyframes {k}-b{{0%,100%{{transform:translateY(0) scale(1,1)}}20%{{transform:translateY(1.5px) scale(1.04,.96)}}55%{{transform:translateY(-4px) scale(.98,1.03)}}}}'
           f'.{k}-w{{animation:{k}-w 2s ease-in-out infinite}}@keyframes {k}-w{{0%,30%{{transform:translateX(-70px)}}70%,100%{{transform:translateX(70px)}}}}'
           f'.{k}-g{{animation:{k}-g 1s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.5}}50%{{opacity:1}}}}' + TW(k))
    body = ('<circle class="t-g" cx="50" cy="40" r="48" fill="url(#t6)"/><g class="t-b">'
            '<path d="M28 16 C10 14 8 34 28 40" stroke="url(#t2)" stroke-width="6" fill="none" stroke-linecap="round"/>'
            '<path d="M72 16 C90 14 92 34 72 40" stroke="url(#t2)" stroke-width="6" fill="none" stroke-linecap="round"/>'
            '<path d="M44 58 L56 58 L58 76 L42 76Z" fill="url(#t2)"/>'
            f'<path d="{CUP}" fill="url(#t1)"/><rect x="23" y="6" width="54" height="8" rx="4" fill="url(#t1)"/><rect x="25" y="7.5" width="50" height="2.4" rx="1.2" fill="#fff" opacity=".5"/>'
            '<g clip-path="url(#tc)"><g class="t-w"><polygon points="42,0 56,0 46,70 32,70" fill="url(#t5)"/></g></g>'
            + sparkle(50, 32, 11, '', fill='#fff3b0').replace('class=""', 'opacity=".9"') +
            '<rect x="34" y="74" width="32" height="7" rx="3" fill="url(#t1)"/>'
            '<rect x="26" y="80" width="48" height="14" rx="4" fill="url(#t3)"/><rect x="38" y="84" width="24" height="6" rx="2" fill="url(#t1)"/></g>' +
            sparkle(86, 12, 7, 't-tw') + sparkle(12, 60, 5, 't-tw', style='animation-delay:-.5s'))
    return svg('trophy', defs, body, css)
ICONS['trophy'] = trophy

# ---------------------------------------------------------------- череп
def skull():
    k = 'sk'
    S = 'M50 6 C26 6 12 22 12 42 C12 54 17 62 25 67 L25 74 C25 78 28 80 32 80 L68 80 C72 80 75 78 75 74 L75 67 C83 62 88 54 88 42 C88 22 74 6 50 6Z'
    defs = (rad('sk1', [(0, '#ffffff'), (.55, '#eceff5'), (1, '#b3bacb')], .38, .28, .85) + lin('sk2', [(0, '#f4f6fa'), (1, '#b3bacb')]) +
            rad('sk3', [(0, '#7dffb0'), (.5, '#18d66b'), (1, '#18d66b', 0)]) + rad('sk4', [(0, '#3dff8f', .45), (1, '#3dff8f', 0)]) +
            f'<clipPath id="skc"><path d="{S}"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 90px;animation:{k}-b 2s ease-in-out infinite}}@keyframes {k}-b{{0%,100%{{transform:rotate(-5deg)}}50%{{transform:rotate(5deg)}}}}'
           f'.{k}-j{{animation:{k}-j .5s ease-in-out infinite}}@keyframes {k}-j{{0%,100%{{transform:translateY(0)}}50%{{transform:translateY(4.5px)}}}}'
           f'.{k}-e{{animation:{k}-e 1s ease-in-out infinite}}@keyframes {k}-e{{0%,100%{{opacity:.35}}50%{{opacity:1}}}}'
           f'.{k}-g{{animation:{k}-e 1s ease-in-out infinite}}')
    body = ('<circle class="sk-g" cx="50" cy="48" r="48" fill="url(#sk4)"/><g class="sk-b">'
            '<g class="sk-j"><path d="M30 74 L70 74 L67 90 C66 94 63 96 59 96 L41 96 C37 96 34 94 33 90Z" fill="url(#sk2)"/>'
            '<path d="M40 78 v12 M50 78 v13 M60 78 v12" stroke="#7b8296" stroke-width="2.2" stroke-linecap="round"/></g>'
            f'<path d="{S}" fill="url(#sk1)"/>'
            '<g clip-path="url(#skc)"><path d="M88 30 L88 82 L64 82 C76 68 82 48 76 20Z" fill="#7b8296" opacity=".25"/>'
            '<ellipse cx="33" cy="22" rx="12" ry="7" transform="rotate(-28 33 22)" fill="#fff" opacity=".85"/></g>'
            '<ellipse cx="33" cy="46" rx="11" ry="12.5" transform="rotate(8 33 46)" fill="#1d1f2b"/><ellipse cx="67" cy="46" rx="11" ry="12.5" transform="rotate(-8 67 46)" fill="#1d1f2b"/>'
            '<circle class="sk-e" cx="33" cy="47" r="7" fill="url(#sk3)"/><circle class="sk-e" cx="67" cy="47" r="7" fill="url(#sk3)"/>'
            '<path d="M50 54 L44.5 65 C46.5 67 48.5 66 50 64 C51.5 66 53.5 67 55.5 65Z" fill="#1d1f2b"/>'
            '<path d="M36 80 v-7 M43 80 v-8 M50 80 v-8 M57 80 v-8 M64 80 v-7" stroke="#7b8296" stroke-width="2.2" stroke-linecap="round"/></g>')
    return svg('skull', defs, body, css)
ICONS['skull'] = skull

# ---------------------------------------------------------------- тыква
def pumpkin():
    k = 'p'
    FACE = ('<path d="M24 46 L40 46 L32 60Z"/><path d="M76 46 L60 46 L68 60Z"/><path d="M46 60 L50 67 L54 60Z"/>'
            '<path d="M20 68 C30 78 40 82 50 81 C60 82 70 78 80 68 C76 78 68 86 60 88 L57 82 L53 89 L50 83 L47 89 L43 82 L40 88 C32 86 24 78 20 68Z"/>')
    defs = (rad('p1', [(0, '#ffc266'), (.45, '#ff8a1f'), (.85, '#e2620a'), (1, '#b04a06')], .36, .28, .8) +
            rad('p2', [(0, '#fff7c2'), (.6, '#ffd23f'), (1, '#ff9a1f')]) + lin('p3', [(0, '#6fae4f'), (1, '#2f6b2a')]) +
            rad('p4', [(0, '#ff9a1f', .55), (1, '#ff9a1f', 0)]))
    css = (f'.{k}-b{{transform-origin:50px 92px;animation:{k}-b 1s cubic-bezier(.4,0,.3,1) infinite}}@keyframes {k}-b{{0%,100%{{transform:scale(1,1)}}20%{{transform:scale(1.05,.95)}}55%{{transform:scale(.98,1.03) translateY(-2px)}}}}'
           f'.{k}-f{{animation:{k}-f .5s ease-in-out infinite}}@keyframes {k}-f{{0%,100%{{opacity:1}}40%{{opacity:.6}}70%{{opacity:.9}}}}'
           f'.{k}-g{{transform-origin:50px 60px;animation:{k}-g .5s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.9;transform:scale(1.05)}}50%{{opacity:.55;transform:scale(.95)}}}}')
    body = ('<circle class="p-g" cx="50" cy="58" r="48" fill="url(#p4)"/><g class="p-b">'
            '<path d="M47 24 C45 14 50 7 59 5 C62 4 65 6 64 10 C58 11 55 16 55 24Z" fill="url(#p3)"/>'
            '<path d="M50 20 C22 18 6 34 6 56 C6 78 24 94 50 94 C76 94 94 78 94 56 C94 34 78 18 50 20Z" fill="url(#p1)"/>'
            '<path d="M28 24 C18 40 18 74 30 90 M50 20 C44 40 44 76 50 94 M72 24 C82 40 82 74 70 90" stroke="#b04a06" stroke-width="2.4" fill="none" stroke-linecap="round" opacity=".5"/>'
            '<ellipse cx="27" cy="38" rx="9" ry="13" transform="rotate(18 27 38)" fill="#fff" opacity=".3"/>'
            f'<g fill="#5a2406" transform="translate(0,-1.8)">{FACE}</g><g class="p-f" fill="url(#p2)">{FACE}</g></g>')
    return svg('pumpkin', defs, body, css)
ICONS['pumpkin'] = pumpkin

# ---------------------------------------------------------------- хлопушка
def confetti():
    k = 'co'
    defs = (lin('co1', [(0, '#ffd23f'), (1, '#ff8a1f')], 0, 0, 1, 1) + '<clipPath id="coc"><path d="M8 92 L30 34 L66 70Z"/></clipPath>')
    cols = ['#ff3b62', '#3aa7ff', '#ffd23f', '#2fc45a', '#b06cff', '#ff8a1f', '#22d3c5', '#ff6fb5']
    pieces = ''
    import random
    rnd = random.Random(7)
    for i in range(14):
        ang = math.radians(rnd.uniform(-78, -12))
        dist = rnd.uniform(34, 58)
        dx, dy = math.cos(ang) * dist, math.sin(ang) * dist
        delay = -rnd.choice([0, .25, .5, .75]) - rnd.uniform(0, .15)
        c = cols[i % len(cols)]
        rot = rnd.choice([-1, 1]) * rnd.uniform(180, 540)
        st = f'--dx:{dx:.1f}px;--dy:{dy:.1f}px;--r:{rot:.0f}deg;animation-delay:{delay:.2f}s'
        shape = i % 3
        if shape == 0: el = f'<rect x="45" y="50" width="7" height="4" rx="1" fill="{c}"/>'
        elif shape == 1: el = f'<circle cx="48" cy="52" r="2.6" fill="{c}"/>'
        else: el = f'<path d="M44 52 q3 -5 6 0 t6 0" stroke="{c}" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
        pieces += f'<g class="co-p" style="{st}">{el}</g>'
    css = (f'.{k}-p{{transform-origin:48px 52px;animation:{k}-p 1s cubic-bezier(.15,.6,.35,1) infinite;opacity:0}}'
           f'@keyframes {k}-p{{0%{{transform:translate(0,0) rotate(0) scale(.4);opacity:0}}10%{{opacity:1}}70%{{opacity:1}}100%{{transform:translate(var(--dx),calc(var(--dy) + 14px)) rotate(var(--r)) scale(1);opacity:0}}}}'
           f'.{k}-b{{transform-origin:20px 84px;animation:{k}-b 1s cubic-bezier(.3,0,.3,1) infinite}}@keyframes {k}-b{{0%,100%{{transform:rotate(0) scale(1)}}8%{{transform:rotate(-5deg) scale(1.07,.95)}}25%{{transform:rotate(2deg) scale(.98,1.02)}}45%{{transform:rotate(0) scale(1)}}}}' + TW(k))
    body = (pieces + '<g class="co-b"><path d="M8 92 L30 34 L66 70Z" fill="url(#co1)"/>'
            '<g clip-path="url(#coc)"><path d="M14 76 L24 50 L36 62 L22 88Z" fill="#ff3b62"/><path d="M36 86 L50 54 L60 64 L46 90Z" fill="#b06cff" opacity=".95"/>'
            '<path d="M8 92 L30 34 L36 40 L14 96Z" fill="#fff" opacity=".28"/></g>'
            '<ellipse cx="48" cy="52" rx="25.5" ry="6" transform="rotate(45 48 52)" fill="#a8480a"/><ellipse cx="48" cy="52" rx="22" ry="3.6" transform="rotate(45 48 52)" fill="#5a2406"/></g>' +
            sparkle(84, 14, 7, 'co-tw', fill='#ffd23f') + sparkle(90, 62, 5, 'co-tw', fill='#fff', style='animation-delay:-.5s'))
    return svg('confetti', defs, body, css)
ICONS['confetti'] = confetti

# ---------------------------------------------------------------- шляпа ведьмы
def witch():
    k = 'w'
    HAT = 'M24 72 C32 48 40 22 62 6 C64 5 66 7 64 9 C58 16 60 22 66 26 C60 28 58 34 62 44 C66 54 72 64 76 72Z'
    defs = (lin('w1', [(0, '#8b5cf6'), (.5, '#5b2bd1'), (1, '#2c1178')], 0, 0, 1, 1) + lin('w2', [(0, '#6d3be0'), (.5, '#3f1a9e'), (1, '#210a5c')]) +
            lin('w3', [(0, '#fff3b0'), (.5, '#ffd43b'), (1, '#f2a007')]) + rad('w4', [(0, '#a06cff', .55), (1, '#a06cff', 0)]) +
            f'<clipPath id="wc"><path d="{HAT}"/></clipPath>')
    css = (f'.{k}-b{{transform-origin:50px 84px;animation:{k}-b 2s ease-in-out infinite}}@keyframes {k}-b{{0%,100%{{transform:rotate(-6deg) translateY(1px)}}50%{{transform:rotate(6deg) translateY(-3px)}}}}'
           f'.{k}-t{{transform-origin:60px 28px;animation:{k}-t 2s ease-in-out infinite}}@keyframes {k}-t{{0%,100%{{transform:rotate(5deg)}}50%{{transform:rotate(-7deg)}}}}'
           f'.{k}-g{{animation:{k}-g 1s ease-in-out infinite}}@keyframes {k}-g{{0%,100%{{opacity:.5}}50%{{opacity:1}}}}' + TW(k))
    body = ('<circle class="w-g" cx="50" cy="52" r="48" fill="url(#w4)"/><g class="w-b">'
            '<ellipse cx="50" cy="78" rx="46" ry="13" fill="url(#w2)"/><ellipse cx="50" cy="75.5" rx="40" ry="8" fill="#7a4cf0" opacity=".35"/>'
            f'<g class="w-t"><path d="{HAT}" fill="url(#w1)"/>'
            '<g clip-path="url(#wc)"><path d="M24 72 C32 48 40 22 62 6 L56 8 C40 24 34 48 30 72Z" fill="#fff" opacity=".22"/>'
            '<path d="M62 44 C66 54 72 64 76 72 L62 72 C62 62 60 52 56 44Z" fill="#170640" opacity=".3"/>'
            '<path d="M22 60 L78 60 L80 74 L20 74Z" fill="#1d0b4a"/><path d="M22 60 L78 60 L78.5 63 L21.5 63Z" fill="#fff" opacity=".12"/></g>'
            '<rect x="41" y="57" width="18" height="15" rx="3" fill="url(#w3)"/><rect x="45.5" y="61" width="9" height="7" rx="1.5" fill="#1d0b4a"/>'
            '<path d="M43 59 h14" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".6"/></g></g>' +
            sparkle(84, 22, 8, 'w-tw', fill='#ffe680') + sparkle(16, 30, 6, 'w-tw', fill='#ffe680', style='animation-delay:-.5s') + sparkle(88, 56, 4, 'w-tw', fill='#fff', style='animation-delay:-.25s'))
    return svg('witch', defs, body, css)
ICONS['witch'] = witch

if __name__ == '__main__':
    out = {}
    for key, fn in ICONS.items():
        s = fn()
        # уникальные имена классов и id, чтобы значок можно было вставлять прямо в страницу
        import re
        kk = re.search(r'<style>\.([a-z]+)-', s).group(1)
        s = re.sub(r'(?<![\w#-])' + kk + r'-([a-z][a-z0-9]*)', 'ls' + kk + r'-\1', s)
        s = s.replace('id="', 'id="ls_').replace('url(#', 'url(#ls_')
        open(os.path.join(OUT, key + '.svg'), 'w', encoding='utf-8').write(s)
        out[key] = s
    # для веб-версии: один файл с картой значков
    js = '/* ===== Эмодзи-статусы: нарисованные значки с анимацией (исходник web/status/gen.py) ===== */\nwindow.LSTAT=' + json.dumps(out, ensure_ascii=False) + ';\n'
    open(os.path.join(OUT, 'status_inline.js'), 'w', encoding='utf-8').write(js)
    print('ok', len(out), sum(len(v) for v in out.values()))
