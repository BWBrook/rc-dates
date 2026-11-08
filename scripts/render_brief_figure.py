"""Brief figure: one archive, four curves, depending on which date each site keeps.

    uv run --with matplotlib python scripts/render_brief_figure.py

Reads the accepted empirical curves (out/empirical-sampling/) and writes
manuscript/figures/figB1_brief.png. SPD curves for the 540-date, 68-site benchmark: all dates, and
one date per site kept by three rules applied to every site (random-1 is the mean of 1,000 draws).
"""

import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
EMP = ROOT / "out" / "empirical-sampling"


def curve(path, **match):
    rows = [r for r in csv.DictReader(open(path)) if all(r.get(k) == v for k, v in match.items())]
    rows.sort(key=lambda r: float(r["calBP"]))
    return [float(r["calBP"]) / 1000 for r in rows], [float(r["mean"]) * 100 for r in rows]


base = curve(EMP / "figure1_baseline_curves.csv", method="SPD")
panels = [
    ("Keep each site's oldest date", curve(EMP / "figure2_sampling_curves.csv", method="SPD", strategy="oldest",
                                           proportion="1"), "#c0392b"),
    ("Keep one date per site at random", curve(EMP / "figure2_sampling_curves.csv", method="SPD",
                                               strategy_label="random-1", proportion="1"), "#4d4d4d"),
    ("Keep each site's youngest date", curve(EMP / "figure2_sampling_curves.csv", method="SPD", strategy="youngest",
                                             proportion="1"), "#1f5fa8"),
]


def mean_age(x, y):
    return sum(a * b for a, b in zip(x, y)) / sum(y)


plt.rcParams.update({"font.size": 12, "font.family": "DejaVu Sans"})
fig, axes = plt.subplots(3, 1, figsize=(7.2, 4.9), dpi=300, sharex=True)
for ax, (title, (x, y), colour) in zip(axes, panels):
    top = max(max(y), max(base[1])) * 1.25
    ax.fill_between(*base, color="#d9d9d9", lw=0)
    ax.plot(x, y, color=colour, lw=2.2)
    for m, c in ((mean_age(*base), "#8c8c8c"), (mean_age(x, y), colour)):
        ax.plot([m], [top * 0.93], marker="v", ms=9, color=c, clip_on=False)
    ax.set_title(title, loc="left", color=colour, fontweight="bold", fontsize=12, pad=2)
    ax.set_ylim(0, top)
    ax.set_yticks([])
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
axes[-1].set_xlim(12, 0)
axes[-1].set_xlabel("Thousands of years ago")
fig.tight_layout(h_pad=0.4)
out = ROOT / "manuscript" / "figures" / "figB1_brief.png"
fig.savefig(out)
print("wrote", out)
