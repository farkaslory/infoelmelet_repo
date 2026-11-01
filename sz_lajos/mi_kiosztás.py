"""
Kölcsönös információ a 16-QAM két címkézésénél (saját és Gray), bit/szimbólumban.

Kiszámolt mennyiségek (egy 16-QAM szimbólumra):
  I(F;Y)      – a finom bitek (f_I, f_Q) információja, a durva réteg ismeretlen
  I(D;Y|F)    – a durva bitek (d_I, d_Q) információja a finom bitek ismeretében
  I(X;Y)      – a konstelláció kölcsönös információja egyenletes bemenettel
                (= I(F;Y) + I(D;Y|F), láncszabály)
  sum I(B_i;Y) – bitenkénti (BICM) ráta: a négy bit feltétel nélküli
                kölcsönös információinak összege

Modell: x = (l_I + j l_Q)/sqrt(10), l in {-3,-1,1,3}, E_s = 1,
        y = x + w, w ~ CN(0, N0), N0 = 10^(-EsN0_dB/10).
A valós és a képzetes tengely független és azonos eloszlású (négyzetes QAM,
körszimmetrikus zaj), ezért a számítás egy tengelyen (4-PAM,
zajvariancia N0/2) történik, és minden mennyiség pontosan kétszerese a
tengelyenkéntinek.

Címkézés tengelyenként (d = durva, f = finom, beta(b) = 1 - 2b):
  saját: l = 2*beta(d) + beta(f)     -> -3:11, -1:10, 1:01, 3:00
  Gray : l = beta(d) * (2 + beta(f)) -> -3:10, -1:11, 1:01, 3:00

Futtatás: python mi_16qam.py
"""

import numpy as np
from scipy.optimize import brentq

N_SAMPLES = 2_000_000   # Monte Carlo minták száma SNR-pontonként
SEED = 1
SNR_DB = [6, 9, 12]     # E_s/N_0 [dB]


def beta(b):
    return 1 - 2 * b


# A négy tengelyenkénti pont bitjei: (d, f)
BITS = np.array([(0, 0), (0, 1), (1, 0), (1, 1)])
D, F = BITS[:, 0], BITS[:, 1]

LABELINGS = {
    "saját": (2 * beta(D) + beta(F)) / np.sqrt(10),
    "Gray": (beta(D) * (2 + beta(F))) / np.sqrt(10),
}


def log2_sum(logp, mask):
    """log2( sum_{j: mask[i, j]} exp(logp[i, j]) ) soronként, stabilan."""
    lp = np.where(mask, logp, -np.inf)
    m = lp.max(axis=1, keepdims=True)
    return (m[:, 0] + np.log(np.exp(lp - m).sum(axis=1))) / np.log(2)


def axis_mi(levels, EsN0_dB, n=N_SAMPLES, rng=None):
    """Tengelyenkénti kölcsönös információk (bit/dimenzió)."""
    rng = np.random.default_rng(SEED) if rng is None else rng
    N0 = 10 ** (-EsN0_dB / 10)
    sigma = np.sqrt(N0 / 2)

    idx = rng.integers(0, 4, n)                     # egyenletes bemenet
    u = levels[idx] + sigma * rng.standard_normal(n)
    # ln p(u | x_j) a konstans tag nélkül, minden j-re
    logp = -(u[:, None] - levels[None, :]) ** 2 / N0

    d, f = D[idx], F[idx]
    all_ = np.ones((n, 4), bool)
    same_f = F[None, :] == f[:, None]
    same_d = D[None, :] == d[:, None]
    same_x = np.arange(4)[None, :] == idx[:, None]

    I_X = 2 - np.mean(log2_sum(logp, all_) - log2_sum(logp, same_x))
    I_F = 1 - np.mean(log2_sum(logp, all_) - log2_sum(logp, same_f))
    I_D_F = 1 - np.mean(log2_sum(logp, same_f) - log2_sum(logp, same_f & same_d))
    I_D = 1 - np.mean(log2_sum(logp, all_) - log2_sum(logp, same_d))
    return {"I_F": I_F, "I_D_F": I_D_F, "I_X": I_X, "BICM": I_F + I_D}


def symbol_mi(levels, EsN0_dB):
    """16-QAM szimbólumonkénti értékek (bit/szimbólum) = 2 x tengelyenkénti."""
    return {k: 2 * v for k, v in axis_mi(levels, EsN0_dB).items()}


def snr_for_rate(fn, target, lo=-5.0, hi=20.0):
    """Az az E_s/N_0 [dB], ahol fn(snr) = target."""
    return brentq(lambda s: fn(s) - target, lo, hi, xtol=1e-3)


if __name__ == "__main__":
    res = {name: {s: symbol_mi(lv, s) for s in SNR_DB}
           for name, lv in LABELINGS.items()}

    print("E_s/N_0 [dB]             " + "".join(f"{s:>16}" for s in SNR_DB))
    for name in LABELINGS:
        row = "".join(f"{res[name][s]['I_F']:7.2f} + {res[name][s]['I_D_F']:5.2f} "
                      for s in SNR_DB)
        print(f"{name:6s} I(F;Y)+I(D;Y|F)   {row}")
    print("I(X;Y)                   " + "".join(
        f"{res['saját'][s]['I_X']:16.2f}" for s in SNR_DB))
    print("szinkron Gray, bitenként " + "".join(
        f"{res['Gray'][s]['BICM']:16.2f}" for s in SNR_DB))

    # SNR-különbség 2 bit/szimbólum rátánál: I(X;Y) vs. Gray-BICM
    gray = LABELINGS["Gray"]
    s_cm = snr_for_rate(lambda s: symbol_mi(gray, s)["I_X"], 2.0)
    s_bicm = snr_for_rate(lambda s: symbol_mi(gray, s)["BICM"], 2.0)
    print(f"\n2 bit/szimbólumnál: I(X;Y) -> {s_cm:.2f} dB, "
          f"Gray-BICM -> {s_bicm:.2f} dB, különbség {s_bicm - s_cm:.2f} dB")