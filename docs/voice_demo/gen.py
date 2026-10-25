import wave, math, random, struct
SR = 22050
def osc(kind, p):
    p %= 1.0
    if kind == "sq": return 1.0 if p < 0.5 else -1.0
    if kind == "pulse": return 1.0 if p < 0.3 else -1.0
    if kind == "saw": return p * 2 - 1
    if kind == "tri": return 1 - 4 * abs(p - 0.5)
    return math.sin(p * math.tau)

def voice(text, base, wave_kind, dur, glide, rasp, vib, seed, step=0.06):
    rnd = random.Random(seed)
    out = []
    lp = 0.0
    for ch in text:
        if ch in ".!?":
            out += [0.0] * int(SR * 0.28); continue
        if ch == ",":
            out += [0.0] * int(SR * 0.14); continue
        if ch == " ":
            out += [0.0] * int(SR * 0.05); continue
        k = (ord(ch.lower()) * 7919) % 11
        f0 = base * (0.85 + k * 0.045)
        n = int(SR * dur * (0.8 + (k % 3) * 0.15))
        ph = 0.0
        for i in range(n):
            t = i / n
            f = f0 * (1 + glide * (t - 0.3) ) * (1 + vib * math.sin(t * 25))
            ph += f / SR
            v = osc(wave_kind, ph) * 0.6 + osc("sine", ph * 2) * 0.25
            lp += (rnd.uniform(-1, 1) - lp) * 0.25
            v += lp * rasp
            a = min(1.0, t / 0.08) * (1 - t) ** 1.3
            out.append(v * a * 0.5)
        out += [0.0] * int(SR * 0.012)
    return out

def save(name, data):
    pk = max(abs(x) for x in data) or 1
    with wave.open(name, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(x / pk * 0.85 * 32000)) for x in data))

line = "Witaj, wędrowcze! Kury zniosły dziś złote jajka. Uważaj na lisa, bo jest groźny!"
save("kogut.wav",  voice(line, 190, "saw", 0.075, 0.5, 0.25, 0.02, 1))
save("kura.wav",   voice(line, 420, "pulse", 0.06, 0.35, 0.05, 0.04, 2))
save("piskle.wav", voice(line, 760, "tri", 0.05, 0.6, 0.0, 0.06, 3))
save("boss.wav",   voice("Nikt nie pokona mnie! Zostaniesz zjedzony!", 85, "saw", 0.13, -0.25, 0.4, 0.03, 4))
