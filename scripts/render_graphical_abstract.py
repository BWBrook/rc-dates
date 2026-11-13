"""Graphical abstract: which date a site keeps can decide the story a regional curve tells.

    python3 scripts/render_graphical_abstract.py

Writes manuscript/figures/graphical_abstract.{svg,pdf,png} (PDF and PNG through Inkscape). Every number
and curve is read from accepted evidence:

  panel 2  out/empirical-sampling/figure{1_baseline,2_sampling}_curves.csv (SPD curves) and
           curve_distance_summaries.csv (mean shifts; claims C02, C03)
  panel 3  out/revision/signed-models/truth_state_confusion.csv (l1, all sites, ten-fold; C10, C12, C13)
  panel 4  out/revision/effect-size-20261018/stage6_dose_response.csv (opposing rule; C18-C20)
"""

import csv
import subprocess
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EMP = ROOT / "out" / "empirical-sampling"
OUT = ROOT / "manuscript" / "figures" / "graphical_abstract"

W, H = 1700, 1240  # 0.1 mm units: 170 x 124 mm
INK, MUTED, FAINT, RULE = "#1f2328", "#5b6069", "#9aa0a8", "#d6d9de"
COL = {"oldest": "#b8432b", "youngest": "#2463a6", "random": "#3b3f45", "both": "#7a4c9e"}
SOIL = ["#f3ece0", "#ebdfcb", "#e2d1b5", "#d8c39f"]
WRONG, WRONG_INK = "#fcefd3", "#8a5600"
FONT = "Inter"

svg = []


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def text(x, y, s, size=26, fill=INK, weight=400, anchor="start", italic=False, extra=""):
    style = ' font-style="italic"' if italic else ""
    svg.append(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{fill}" font-weight="{weight}" '
               f'text-anchor="{anchor}"{style}{extra}>{esc(s)}</text>')


def tspans(x, y, parts, size=26, anchor="start"):
    inner = "".join(f'<tspan fill="{c}" font-weight="{w}">{esc(s)}</tspan>' for s, c, w in parts)
    svg.append(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" text-anchor="{anchor}" xml:space="preserve">{inner}</text>')


def line(x1, y1, x2, y2, stroke=INK, width=2, extra=""):
    svg.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{stroke}" '
               f'stroke-width="{width}" stroke-linecap="round"{extra}/>')


def path(d, stroke="none", width=2, fill="none", extra=""):
    svg.append(f'<path d="{d}" stroke="{stroke}" stroke-width="{width}" fill="{fill}" '
               f'stroke-linejoin="round" stroke-linecap="round"{extra}/>')


def rect(x, y, w, h, fill, rx=0, stroke="none", width=0):
    svg.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" fill="{fill}" '
               f'stroke="{stroke}" stroke-width="{width}"/>')


def circle(x, y, r, fill, stroke="none", width=0):
    svg.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>')


def heading(x, y, n, s):
    circle(x + 17, y - 11, 17, INK)
    text(x + 17, y - 2, str(n), size=24, fill="white", weight=700, anchor="middle")
    text(x + 46, y, s, size=31, weight=650)


def arrowhead(x, y, direction, size=11, fill=INK):
    s = size if direction == "right" else -size
    path(f"M{x:.1f},{y:.1f} L{x - s:.1f},{y - size * 0.62:.1f} L{x - s:.1f},{y + size * 0.62:.1f} Z", fill=fill)


# Evidence ----------------------------------------------------------------------------------------------


def rows(path_, **match):
    return [r for r in csv.DictReader(open(path_)) if all(r.get(k) == v for k, v in match.items())]


def curve(path_, **match):
    rs = sorted(rows(path_, **match), key=lambda r: float(r["calBP"]))
    return [float(r["calBP"]) / 1000 for r in rs], [float(r["mean"]) for r in rs]


def mean_age(c):
    x, y = c
    return sum(a * b for a, b in zip(x, y)) / sum(y)


base = curve(EMP / "figure1_baseline_curves.csv", method="SPD")
sampled = {
    "oldest": curve(EMP / "figure2_sampling_curves.csv", method="SPD", strategy="oldest", proportion="1"),
    "random": curve(EMP / "figure2_sampling_curves.csv", method="SPD", strategy_label="random-1", proportion="1"),
    "youngest": curve(EMP / "figure2_sampling_curves.csv", method="SPD", strategy="youngest", proportion="1"),
}
shift = {}
for label, key in (("oldest", "oldest"), ("youngest", "youngest"), ("random-1", "random")):
    (r,) = rows(EMP / "curve_distance_summaries.csv", strategy_label=label, proportion="1",
                comparison="mean_calBP_shift_vs_all", method="SPD")
    shift[key] = float(r["mean"])
n_dates, n_sites = 540, 68

conf = defaultdict(Counter)
for r in rows(ROOT / "out/revision/signed-models/truth_state_confusion.csv", type="l1", prop="1"):
    s = r["selected_state"]
    concluded = "steady" if s == "uni" else ("falling" if s.endswith("dec") else "rising")
    truth = {"decrease": "falling", "constant": "steady", "increase": "rising"}[r["true_direction"]]
    conf[(r["strategy"], truth)][concluded] += int(r["n"])

dose = defaultdict(list)
for r in rows(ROOT / "out/revision/effect-size-20261018/stage6_dose_response.csv", role="adverse"):
    if r["strategy"] in ("r_old", "r_young") and float(r["ratio"]) > 1:
        dose[(float(r["prop"]), float(r["ratio"]))].append(float(r["reversal_rate"]))


def pct(v):
    p = 100 * v
    return f"{p:.0f}%" if abs(p - round(p)) < 0.05 or p < 99 else f"{p:.1f}%"


# Glyphs ------------------------------------------------------------------------------------------------

DOT_Y = [0.13, 0.33, 0.52, 0.70, 0.88]  # fractions down a section; deeper is older
DOT_X = [0.62, 0.35, 0.58, 0.30, 0.52]
KEEP = {"oldest": [4], "youngest": [0], "random": [2], "both": [0, 4]}


def section(x, y, w, h, rx=6):
    svg.append(f'<clipPath id="c{len(svg)}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}"/></clipPath>')
    cid = f"c{len(svg) - 1}"
    svg.append(f'<g clip-path="url(#{cid})">')
    bands = [0, 0.24, 0.45, 0.63, 1.0]
    for i, colour in enumerate(SOIL):
        y0, y1 = y + bands[i] * h, y + bands[i + 1] * h + 2
        wob = h * 0.025
        path(f"M{x - 2},{y0} C{x + w * 0.3},{y0 - wob} {x + w * 0.6},{y0 + wob} {x + w + 2},{y0} "
             f"L{x + w + 2},{y1 + 10} L{x - 2},{y1 + 10} Z", fill=colour)
    svg.append("</g>")
    rect(x, y, w, h, "none", rx=rx, stroke="#c9b48f", width=1.5)


def site_icon(x, y, rule, w=34, h=52):
    section(x, y, w, h, rx=4)
    for i, (fy, fx) in enumerate(zip(DOT_Y, DOT_X)):
        if i in KEEP[rule]:
            circle(x + fx * w, y + fy * h, round(w * 0.16, 1), COL[rule], stroke="white", width=1.2)
        else:
            circle(x + fx * w, y + fy * h, round(w * 0.1, 1), "white", stroke=FAINT, width=1.2)


def trend(x, y, w, h, direction, colour=INK, width=4):
    dy = {"falling": h / 2, "steady": 0, "rising": -h / 2}[direction]
    x0, x1 = x - w / 2, x + w / 2
    y0, y1 = y - dy, y + dy
    path(f"M{x0:.1f},{y0:.1f} L{x1 - 6:.1f},{y1 - dy * 12 / w:.1f}", stroke=colour, width=width)
    ang = {"falling": 0.62, "steady": 0, "rising": -0.62}[direction]
    import math
    a = math.atan2(2 * dy, w)
    s = 13
    px, py = x1, y1
    p1 = (px - s * math.cos(a) + s * 0.55 * math.sin(a), py - s * math.sin(a) - s * 0.55 * math.cos(a))
    p2 = (px - s * math.cos(a) - s * 0.55 * math.sin(a), py - s * math.sin(a) + s * 0.55 * math.cos(a))
    path(f"M{px:.1f},{py:.1f} L{p1[0]:.1f},{p1[1]:.1f} L{p2[0]:.1f},{p2[1]:.1f} Z", fill=colour)
    del ang


# Headline ----------------------------------------------------------------------------------------------

text(0, 40, "The dates each site contributes can change the story a regional curve tells", size=40, weight=700)

# Panel 1: the choice -----------------------------------------------------------------------------------

P1Y = 120
heading(0, P1Y, 1, "One site, several dates")
sx, sy, sw, sh = 46, P1Y + 40, 140, 330
section(sx, sy, sw, sh, rx=10)
for i, (fy, fx) in enumerate(zip(DOT_Y, DOT_X)):
    circle(sx + fx * sw, sy + fy * sh, 11, INK, stroke="white", width=2.5)
line(sx - 14, sy + 30, sx - 14, sy + sh - 30, stroke=MUTED, width=2)
arrowhead(sx - 14, sy + sh - 22, "right", size=0)
path(f"M{sx - 21},{sy + sh - 40} L{sx - 14},{sy + sh - 26} L{sx - 7},{sy + sh - 40}", stroke=MUTED, width=2)
text(sx - 24, sy + sh / 2, "oldest at the bottom", size=23, fill=MUTED, anchor="middle",
     extra=f' transform="rotate(-90 {sx - 24} {sy + sh / 2})"')
text(sx + sw / 2, sy + sh + 34, "five dates", size=24, fill=MUTED, anchor="middle")

rules = [("oldest", "Oldest"), ("youngest", "Youngest"), ("random", "One at random"), ("both", "Both extremes")]
text(222, P1Y + 52, "What reaches an analysis …", size=24, fill=MUTED, italic=True)
for i, (rule, label) in enumerate(rules):
    iy = P1Y + 78 + i * 74
    site_icon(222, iy - 4, rule, w=38, h=58)
    text(276, iy + 33, label, size=26, fill=COL[rule], weight=650)
text(222, P1Y + 404, "and nothing in a date says which.", size=23.5, fill=MUTED, italic=True)

# Panel 2: the real archive -----------------------------------------------------------------------------

P2X = 560
heading(P2X, P1Y, 2, f"Real dates: {n_dates} from {n_sites} Australian sites")
text(P2X + 46, P1Y + 32, "if each site kept only one date (grey: all dates; ▼ average age)", size=24.5, fill=MUTED)
cx0, cx1 = P2X + 150, W - 26
row_h, row_gap, ry0 = 96, 14, P1Y + 64
xmin, xmax = 12.0, 0.0


def X(age):
    return cx0 + (xmin - age) / (xmin - xmax) * (cx1 - cx0)


def area(c, y0, top, scale, close=True):
    x, y = c
    pts = [(X(a), y0 - v * scale) for a, v in zip(x, y) if xmax <= a <= xmin]
    d = "M" + " L".join(f"{px:.1f},{py:.1f}" for px, py in pts)
    if close:
        d += f" L{pts[-1][0]:.1f},{y0} L{pts[0][0]:.1f},{y0} Z"
    return d


base_mean = mean_age(base)
for i, rule in enumerate(["oldest", "random", "youngest"]):
    y0 = ry0 + (i + 1) * row_h + i * row_gap
    c = sampled[rule]
    top = max(max(c[1]), max(base[1]))
    scale = (row_h - 30) / top
    path(area(base, y0, top, scale), fill="#e3e5e8")
    path(area(c, y0, top, scale, close=False), stroke=COL[rule], width=3.2)
    line(cx0, y0, cx1, y0, stroke=RULE, width=1.5)
    site_icon(P2X + 20, y0 - 62, rule, w=26, h=40)
    text(P2X + 56, y0 - 38, {"oldest": "Oldest", "random": "Random", "youngest": "Youngest"}[rule], size=25,
         fill=COL[rule], weight=650)
    m = mean_age(c)
    ty = y0 - row_h + 8
    gx, mx = X(base_mean), X(m)
    svg.append(f'<path d="M{gx - 9:.1f},{ty - 8} L{gx + 9:.1f},{ty - 8} L{gx:.1f},{ty + 7} Z" fill="{FAINT}"/>')
    svg.append(f'<path d="M{mx - 10:.1f},{ty - 9} L{mx + 10:.1f},{ty - 9} L{mx:.1f},{ty + 8} Z" fill="{COL[rule]}"/>')
    s = shift[rule]
    if rule == "random":
        label = f"about {round(abs(s), -2):.0f} years"
        text(gx + 22, ty + 6, label, size=23, fill=COL[rule], weight=600)
    else:
        lo, hi = sorted((gx, mx))
        line(lo + 16, ty - 1, hi - 16, ty - 1, stroke=COL[rule], width=2.4)
        arrowhead(mx + (16 if mx < gx else -16), ty - 1, "left" if mx < gx else "right", fill=COL[rule])
        word = "older" if s > 0 else "younger"
        label = f"{abs(s):,.0f} years {word}"
        text(lo - 18, ty + 6, label, size=23, fill=COL[rule], weight=600, anchor="end")
axis_y = ry0 + 3 * row_h + 2 * row_gap
for k in range(0, 13, 2):
    line(X(k), axis_y, X(k), axis_y + 8, stroke=MUTED, width=1.5)
    text(X(k), axis_y + 33, str(k), size=23.5, fill=MUTED, anchor="middle")
text((cx0 + cx1) / 2, axis_y + 62, "thousands of years ago", size=24, fill=MUTED, anchor="middle")
text(cx1, axis_y + 62, "each row on its own scale", size=22, fill=FAINT, anchor="end", italic=True)

# Panel 3: simulated archives ---------------------------------------------------------------------------

P3Y = 650
heading(0, P3Y, 3, "Simulated archives with a known history")
text(46, P3Y + 32, "rule applied at every site; tenfold change; cells: trend concluded", size=24.5, fill=MUTED)
gx0, colw, rowh = 226, 250, 84
hy = P3Y + 66
truths = ["falling", "steady", "rising"]
text(gx0 + 1.5 * colw, hy + 4, "true history", size=23.5, fill=MUTED, anchor="middle")
for j, t in enumerate(truths):
    cx = gx0 + (j + 0.5) * colw
    trend(cx - 42, hy + 40, 54, 30, t, colour=MUTED, width=3.4)
    text(cx + 0, hy + 49, t.capitalize(), size=24, fill=INK, weight=600)
strategies = [("oldest", "r_old", "Oldest"), ("youngest", "r_young", "Youngest"),
              ("random", "r_1", "One at random"), ("both", "r_bracket", "Both extremes")]
for i, (rule, code, label) in enumerate(strategies):
    y = hy + 72 + i * rowh
    site_icon(10, y + 12, rule, w=26, h=40)
    sub = {"oldest": "always falling", "youngest": "always rising"}.get(rule)
    text(48, y + (36 if sub else 47), label, size=24.5, fill=COL[rule], weight=650)
    if sub:
        text(48, y + 63, sub, size=22, fill=COL[rule], italic=True)
    for j, t in enumerate(truths):
        cnt = conf[(code, t)]
        concluded, n = cnt.most_common(1)[0]
        share = n / sum(cnt.values())
        x = gx0 + j * colw
        wrong = concluded != t
        rect(x + 6, y + 6, colw - 12, rowh - 10, WRONG if wrong else "#f6f7f8", rx=10)
        trend(x + 38, y + rowh / 2 + 1, 42, 30, concluded, colour=COL[rule], width=4)
        other = 1 - share
        tag = None
        if wrong:
            tag = "false trend" if t == "steady" else "wrong direction"
        elif other >= 0.05:
            tag = f"{100 * other:.0f}% false trend" if t == "steady" else f"{100 * other:.0f}% missed"
        text(x + 76, y + rowh / 2 + (0 if tag else 10), pct(share), size=27, fill=INK, weight=650)
        if tag:
            text(x + 76, y + rowh / 2 + 27, tag, size=21.5, fill=WRONG_INK, weight=600)
gentle = defaultdict(list)
for r in rows(ROOT / "out/revision/effect-size-20261018/stage6_selection_rates.csv", type="l1", prop="1", ratio="1.5"):
    if r["truth"] != "uni":
        gentle[r["strategy"]].append(float(r["correct_state_rate"]))
note_y = hy + 72 + 4 * rowh + 36
tspans(10, note_y, [("Both extremes", COL["both"], 650),
                    (" avoided reversals, but with gentle (1.5×) trends found the", INK, 400)], size=24.5)
tspans(10, note_y + 31, [(f"true direction in only {min(gentle['r_bracket']) * 100:.0f}–"
                          f"{max(gentle['r_bracket']) * 100:.0f}% of runs (two random dates per site: "
                          f"{min(gentle['r_2']) * 100:.0f}–{max(gentle['r_2']) * 100:.0f}%).", INK, 400)], size=24.5)

# Panel 4: weaker trends --------------------------------------------------------------------------------

P4X = 990
heading(P4X, P3Y, 4, "Weaker trends need fewer sites to flip")
for k, s_ in enumerate(["affected sites keep only the extreme opposing the",
                        "trend (oldest if rising, youngest if falling);",
                        "the other sites keep all their dates"]):
    text(P4X + 46, P3Y + 32 + 28 * k, s_, size=24.5, fill=MUTED)
ax0, ax1, ay0, ay1 = P4X + 106, W - 40, P3Y + 140, P3Y + 392
ratios = [1.5, 2, 3, 5, 10]


def DX(i):
    return ax0 + i * (ax1 - ax0) / (len(ratios) - 1)


def DY(v):
    return ay1 - v * (ay1 - ay0)


for v in (0, 0.5, 1):
    line(ax0 - 10, DY(v), ax1 + 10, DY(v), stroke=RULE, width=1.3)
    text(ax0 - 22, DY(v) + 8, f"{v * 100:.0f}%", size=23, fill=MUTED, anchor="end")
text(ax0 - 84, (ay0 + ay1) / 2, "runs reversed", size=23, fill=MUTED, anchor="middle",
     extra=f' transform="rotate(-90 {ax0 - 84} {(ay0 + ay1) / 2})"')
for i, r in enumerate(ratios):
    text(DX(i), ay1 + 34, f"{r:g}×", size=23.5, fill=MUTED, anchor="middle")
text((ax0 + ax1) / 2, ay1 + 64, "tested sizes of the true change over 11,000 years", size=24, fill=MUTED, anchor="middle")
props = [(1.0, "all sites", INK), (0.75, "three in four sites", "#6b7079"), (0.5, "half the sites", "#9aa0a8")]
for p, label, colour in props:
    lo = [min(dose[(p, r)]) for r in ratios]
    hi = [max(dose[(p, r)]) for r in ratios]
    mid = [sum(dose[(p, r)]) / len(dose[(p, r)]) for r in ratios]
    band = " L".join(f"{DX(i):.1f},{DY(v):.1f}" for i, v in enumerate(hi))
    band += " L" + " L".join(f"{DX(i):.1f},{DY(v):.1f}" for i, v in reversed(list(enumerate(lo))))
    path("M" + band + " Z", fill=colour, extra=' fill-opacity="0.16"')
    path("M" + " L".join(f"{DX(i):.1f},{DY(v):.1f}" for i, v in enumerate(mid)), stroke=colour, width=2.4,
         extra=' stroke-dasharray="2 7"')
    for i, v in enumerate(mid):
        circle(DX(i), DY(v), 8, colour, stroke="white", width=2)
    if p == 1.0:
        text(DX(4), DY(1) - 16, label, size=23.5, fill=colour, weight=650, anchor="end")
    elif p == 0.75:
        text(DX(2) + 16, DY(mid[2]) - 14, label, size=23.5, fill=colour, weight=650)
    else:
        text(DX(0) + 18, DY(mid[0]) - 16, label, size=23.5, fill=colour, weight=650)
text(P4X + 46, ay1 + 108, "Many runs that escaped reversal still read the", size=24.5, fill=INK)
text(P4X + 46, ay1 + 139, "trend as steady.", size=24.5, fill=INK)

# Write -------------------------------------------------------------------------------------------------

doc = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W / 10}mm" height="{H / 10}mm" viewBox="0 0 {W} {H}" '
       f'font-family="{FONT}">\n<rect width="{W}" height="{H}" fill="white"/>\n' + "\n".join(svg) + "\n</svg>\n")
OUT.with_suffix(".svg").write_text(doc)
for ext, args in (("pdf", ["--export-type=pdf", "--export-text-to-path"]),
                  ("png", ["--export-type=png", "--export-dpi=400", "--export-background=white"])):
    subprocess.run(["inkscape", str(OUT.with_suffix(".svg")), *args,
                    f"--export-filename={OUT.with_suffix('.' + ext)}"], check=True, capture_output=True)
print("wrote", *(OUT.with_suffix(e) for e in (".svg", ".pdf", ".png")))
