import wave, math, random, struct
SR = 22050
rnd = random.Random(7)

class Res:
    def __init__(s, f, bw):
        r = math.exp(-math.pi * bw / SR)
        s.a1 = -2 * r * math.cos(math.tau * f / SR); s.a2 = r * r
        s.g = 1 - r
        s.y1 = s.y2 = 0.0
    def __call__(s, x):
        y = s.g * x - s.a1 * s.y1 - s.a2 * s.y2
        s.y2 = s.y1; s.y1 = y
        return y

VOW = {"u": (330, 800), "o": (500, 900), "a": (850, 1300), "i": (320, 2300), "e": (500, 1800)}

def syl(f_contour, dur, vowel, noise=0.0, vib=0.0, crack=None, atk=0.02, rel=0.3, jitter=0.01, gain=1.0, bright=1.0):
    """f_contour: lista (t0..1, Hz). crack: (t, Hz skok) przeskok rejestru koguta."""
    n = int(SR * dur)
    f1, f2 = VOW[vowel]
    r1, r2, r3 = Res(f1, 120), Res(f2, 180), Res(3200, 400)
    ph = 0.0
    out = []
    for i in range(n):
        t = i / n
        # interpolacja konturu
        f = f_contour[-1][1]
        for k in range(len(f_contour) - 1):
            ta, fa = f_contour[k]; tb, fb = f_contour[k + 1]
            if ta <= t <= tb:
                f = fa + (fb - fa) * ((t - ta) / max(1e-6, tb - ta)); break
        if crack and t > crack[0]:
            f += crack[1] * (1 if int(t * 90) % 2 == 0 else 0.4)
        f *= 1 + vib * math.sin(t * dur * math.tau * 6) + rnd.uniform(-jitter, jitter)
        ph += f / SR
        src = ((ph % 1.0) * 2 - 1)  # piła = dużo harmonicznych
        src = src * 0.9 + (rnd.uniform(-1, 1)) * noise
        v = r1(src) * 1.2 + r2(src) * 1.0 * bright + r3(src) * 0.3 * bright
        a = min(1.0, t * dur / atk) * (1 - t) ** rel if rel > 0 else min(1.0, t * dur / atk)
        out.append(v * a * 6 * gain)
    return out

def burst(dur=0.02, gain=0.5, lo=True):
    out = []; lp = 0.0
    for i in range(int(SR * dur)):
        lp += (rnd.uniform(-1, 1) - lp) * (0.2 if lo else 0.7)
        out.append(lp * gain * (1 - i / (SR * dur)) ** 2)
    return out

def sil(d): return [0.0] * int(SR * d)

def cat(*p):
    o = []
    for x in p: o += x
    return o

def gdak(base=420, g=1.0):
    return cat(burst(0.025, 0.6 * g), sil(0.015), burst(0.012, 0.5 * g, False),
               syl([(0, base * 1.1), (1, base * 0.6)], 0.14, "a", noise=0.12, jitter=0.04, atk=0.008, rel=1.0, gain=g))

def ko(base=520, g=1.0, vow="o"):
    return syl([(0, base * 0.9), (0.3, base * 1.1), (1, base * 0.85)], 0.11, vow, noise=0.05, atk=0.012, rel=0.9, gain=g)

def ko_ko_ko(base=520):
    o = []
    gap = 0.11
    for k in range(6):
        o += ko(base * (1 + 0.03 * ((k * 5) % 3)), 1.0 - 0.05 * k) + sil(gap); gap *= 0.9
    return o + gdak(base * 0.85)

def kukuryku():
    return cat(
        syl([(0, 420), (1, 560)], 0.17, "u", atk=0.02, rel=0.5), sil(0.05),
        syl([(0, 520), (1, 700)], 0.17, "u", atk=0.02, rel=0.5), sil(0.05),
        syl([(0, 700), (1, 930)], 0.13, "i", atk=0.015, rel=0.5, bright=1.3), sil(0.03),
        syl([(0, 640), (0.25, 1000), (0.55, 1050), (0.8, 880), (1, 520)], 0.9, "u",
            noise=0.1, vib=0.015, crack=(0.55, -120), atk=0.03, rel=0.35, jitter=0.02, gain=1.1)
    )

def piskle():
    o = []
    for k in range(4):
        o += syl([(0, 1500), (0.5, 2100), (1, 1700)], 0.08, "i", atk=0.01, rel=0.8, bright=1.4, gain=0.8) + sil(0.07)
    return o

def save(name, data):
    pk = max(abs(x) for x in data) or 1
    with wave.open(name, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x / pk)) * 0.85 * 32000)) for x in data))

save("kukuryku.wav", kukuryku())
save("ko_ko_ko.wav", ko_ko_ko())
save("gdak.wav", cat(gdak(), sil(0.35), gdak(380), sil(0.35), gdak(460, 0.8)))
save("piskle_pip.wav", piskle())
save("kurnik_mix.wav", cat(ko_ko_ko(), sil(0.5), kukuryku(), sil(0.5), gdak(), sil(0.2), gdak(400), sil(0.4), piskle()))
