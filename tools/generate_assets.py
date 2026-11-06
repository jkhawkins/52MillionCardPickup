#!/usr/bin/env python3
"""Original procedural art/audio. Requires Pillow and NumPy only.
All output is replaceable; no external samples or copyrighted card artwork.
"""
from pathlib import Path
import math, wave, struct
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'assets/art'; AUDIO=ROOT/'assets/audio'
ART.mkdir(parents=True,exist_ok=True); AUDIO.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(52000000)
# Baize: fine fiber noise, subtle woven variation and a restrained vignette.
w,h=1280,800
y,x=np.mgrid[0:h,0:w]
noise=rng.normal(0,2.4,(h,w))
weave=1.1*np.sin(x*1.7)+0.8*np.sin(y*2.1)
vignette=1-0.22*((x-w/2)/(w/2))**2-0.16*((y-h/2)/(h/2))**2
base=np.stack([20*vignette,74*vignette,57*vignette],axis=2)
felt=np.clip(base+(noise+weave)[...,None],0,255).astype(np.uint8)
Image.fromarray(felt).save(ART/'felt.png')
# Original icon: a fanned deck with a brass counting ring.
icon='''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><rect width="256" height="256" rx="48" fill="#0d2b23"/><circle cx="128" cy="128" r="100" fill="none" stroke="#c9a55c" stroke-width="6"/><g transform="translate(128 132)"><rect x="-54" y="-76" width="108" height="152" rx="12" fill="#d8d0bd" transform="rotate(-16)"/><rect x="-54" y="-76" width="108" height="152" rx="12" fill="#eee8d8" transform="rotate(-7)"/><rect x="-54" y="-76" width="108" height="152" rx="12" fill="#faf6e9" stroke="#c9a55c" stroke-width="3"/><path d="M0 38C-8 24-34 8-34-10c0-22 28-27 34-7 6-20 34-15 34 7 0 18-26 34-34 48Z" fill="#a33a32"/><path d="M-7 34h14l5 16h-24Z" fill="#a33a32"/><text x="-38" y="-48" font-family="serif" font-size="24" font-weight="bold" fill="#a33a32">A</text></g></svg>'''
(ART/'icon.svg').write_text(icon)
# Small original mechanical helper sprite, used by the table renderer.
helper='''<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><ellipse cx="48" cy="82" rx="30" ry="7" fill="#061b15" opacity=".5"/><path d="M28 58 18 74M68 58 78 74" stroke="#b58b45" stroke-width="8" stroke-linecap="round"/><rect x="24" y="30" width="52" height="40" rx="12" fill="#b58b45" stroke="#e4c783" stroke-width="3"/><rect x="30" y="36" width="40" height="20" rx="8" fill="#173c31"/><circle cx="40" cy="46" r="4" fill="#f4e8bd"/><circle cx="58" cy="46" r="4" fill="#f4e8bd"/><path d="M48 30V16" stroke="#b58b45" stroke-width="5"/><circle cx="48" cy="13" r="6" fill="#e4c783"/><path d="M30 70v10M66 70v10" stroke="#8a6834" stroke-width="9" stroke-linecap="round"/></svg>'''
(ART/'helper.svg').write_text(helper)
SR=22050
def write_wav(name, data):
    data=np.asarray(data,dtype=np.float64)
    peak=np.max(np.abs(data))
    if peak>0.92: data=data*0.92/peak
    pcm=(np.clip(data,-1,1)*32767).astype('<i2')
    with wave.open(str(AUDIO/f'{name}.wav'),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR); f.writeframes(pcm.tobytes())
def env(n,attack=.004,decay=.08):
    t=np.arange(n)/SR
    return np.minimum(1,t/attack)*np.exp(-t/decay)
def tone(freq,dur,decay=.12,noise=0):
    n=int(SR*dur);t=np.arange(n)/SR
    return (np.sin(2*np.pi*freq*t)+.22*np.sin(2*np.pi*freq*2.01*t)+noise*rng.normal(0,1,n))*env(n,.002,decay)
write_wav('pickup',tone(740,.09,.025,.35))
write_wav('deposit',tone(1050,.06,.018,.22))
write_wav('ui',tone(520,.08,.03,.05))
write_wav('buy',tone(660,.16,.06,.08)+np.pad(tone(990,.16,.06),(int(.055*SR),0))[:int(.16*SR)])
write_wav('block',tone(150,.13,.04,.12))
write_wav('helper',tone(220,.08,.025,.45))
write_wav('lucky',tone(880,.3,.09)+np.pad(tone(1320,.25,.08),int(.07*SR))[:int(.3*SR)])
write_wav('ability',tone(330,.45,.14,.05)+tone(660,.45,.14))
deck=np.zeros(int(SR*.8))
for i,f in enumerate([523.25,659.25,783.99,1046.5]):
    s=tone(f,.45,.16);off=int(i*.09*SR);deck[off:off+len(s)]+=s*.55
write_wav('deck',deck)
write_wav('foil',tone(1760,.35,.12)+tone(2093,.35,.12)*.5)
# Seamless 16-second stems. Integer cycle counts avoid clicks at loop boundaries.
dur=16.0;n=int(SR*dur);t=np.arange(n)/SR
def pad_note(freq,start,length,amp=.12):
    out=np.zeros(n);ln=int(length*SR);tt=np.arange(ln)/SR
    e=np.minimum(1,tt/.4)*np.minimum(1,(length-tt)/.8)
    sig=(np.sin(2*np.pi*freq*tt)+.25*np.sin(2*np.pi*freq*2*tt))*e*amp
    idx=(int(start*SR)+np.arange(ln))%n;out[idx]+=sig;return out
base=np.zeros(n)
chords=[(130.81,164.81,196.0),(110.0,130.81,164.81),(87.31,110.0,130.81),(98.0,123.47,146.83)]
for bar,chord in enumerate(chords):
    for f in chord: base+=pad_note(f,bar*4,4,.055)
write_wav('music_base',base)
helpers=np.zeros(n)
for beat in range(32):
    s=tone(196 if beat%2 else 261.63,.18,.045,.08)*.16
    off=int(beat*.5*SR);helpers[off:off+len(s)]+=s
write_wav('music_helpers',helpers)
seek=np.zeros(n)
for i,f in enumerate([523.25,659.25,783.99,659.25,587.33,783.99,880,783.99]): seek+=pad_note(f,i*2,1.4,.05)
write_wav('music_seekers',seek)
suit=np.zeros(n)
for i,f in enumerate([392,440,523.25,587.33]): suit+=pad_note(f,i*4+1,2.5,.045)
write_wav('music_suits',suit)
amb=rng.normal(0,.012,n)
amb=np.convolve(amb,np.ones(64)/64,mode='same')
write_wav('ambience',amb)
print('Generated original felt, icon, helper and 14 audio assets.')
