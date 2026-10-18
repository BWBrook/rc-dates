#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["matplotlib==3.11.2", "numpy==2.5.4"]
# ///
"""Illustrate the exact-age order statistics already derived in SI S2.6.

This is an analytic teaching figure, not a calibrated simulation or model fit.
It uses a fixed five dates per hypothetical site and no archaeological inputs.
Run with `make concept-figure`; the scientific R environment is unchanged.
"""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


ROOT = Path(__file__).resolve().parents[1]


def densities(u, increasing=False, n=5):
    """u runs from the recent (0) to the old (1) end of the interval."""
    if increasing:
        truth = (20.0 - 18.0 * u) / 11.0
        cdf = (20.0 * u - 9.0 * u**2) / 11.0
    else:
        truth = np.ones_like(u)
        cdf = u
    oldest = n * cdf ** (n - 1) * truth
    youngest = n * (1.0 - cdf) ** (n - 1) * truth
    return truth, oldest, youngest, (oldest + youngest) / 2.0


def main():
    u = np.linspace(0.0, 1.0, 20001)
    plt.rcParams.update({
        "font.family": "DejaVu Sans", "font.size": 10,
        "axes.spines.top": False, "axes.spines.right": False,
        "pdf.fonttype": 42, "savefig.facecolor": "white",
    })
    fig, axes = plt.subplots(1, 2, figsize=(8.3, 3.8), sharey=True)
    labels = ["All dates / random retention", "Oldest retained",
              "Youngest retained", "Both extrema retained"]
    colours = ["#505050", "#B84716", "#2166AC", "#7B3294"]
    styles = ["--", "-", "-", "-."]
    handles = []
    for ax, increasing, title in zip(
        axes, [False, True],
        ["A  Constant history", "B  Linear increase towards the present"],
    ):
        curves = densities(u, increasing=increasing)
        for curve, label, colour, style in zip(curves, labels, colours, styles):
            area = np.trapezoid(curve, u)
            if abs(area - 1.0) > 1e-6:
                raise ValueError(f"Non-unit density: {title}, {label}, {area}")
            line, = ax.plot(u, curve, label=label, color=colour,
                            linestyle=style, linewidth=1.9)
            if increasing:
                handles.append(line)
        ax.set_xlim(1, 0)
        ax.set_ylim(0, 9.5)
        ax.set_xticks([1, 0.5, 0], ["Older", "", "Recent"])
        ax.get_xticklabels()[0].set_ha("left")
        ax.get_xticklabels()[-1].set_ha("right")
        ax.set_xlabel("Position in the age interval")
        ax.set_title(title, loc="left", fontsize=10, pad=9)
        ax.tick_params(direction="out")
    axes[0].set_ylabel("Density relative to a uniform history")
    fig.legend(handles, labels, loc="lower center", ncol=2, frameon=False,
               bbox_to_anchor=(0.51, 0.005), fontsize=9)
    fig.subplots_adjust(left=0.075, right=0.985, top=0.88, bottom=0.28, wspace=0.12)
    target = ROOT / "manuscript/figures/retention_mechanism.pdf"
    fig.savefig(target, metadata={"CreationDate": None, "ModDate": None})
    preview = ROOT / "tmp/editorial_rework_20261018/retention_mechanism.png"
    preview.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(preview, dpi=180)
    plt.close(fig)
    print(target)


if __name__ == "__main__":
    main()
