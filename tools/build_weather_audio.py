"""Deterministic, original weather Foley. Requires numpy; emits stereo PCM WAV.
No recordings, third-party samples, runtime DSP, or gameplay random state.
"""
from pathlib import Path
import json, wave, hashlib
import numpy as np
RATE=22050
OUT=Path(__file__).resolve().parents[1]/'assets/audio/weather'
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(28092026)
records=[]
def noise(seconds,low=80,high=5000,slope=.4):
 n=round(seconds*RATE);f=np.fft.rfftfreq(n,1/RATE)
 spectrum=np.fft.rfft(rng.normal(size=(n,2)),axis=0)
 eq=(np.maximum(f,20)/200)**(-slope)/np.sqrt(1+(f/high)**6)
 eq*=1/np.sqrt(1+(low/np.maximum(f,1))**6);eq[0]=0
 a=np.fft.irfft(spectrum*eq[:,None],n=n,axis=0)
 return a/max(1e-8,float(np.sqrt(np.mean(a*a))))
def save(name,a,peak,loop=False):
 a=a-np.mean(a,axis=0);a*=peak/max(np.max(np.abs(a)),1e-9)
 if not loop:
  ramp=min(len(a)//2,round(RATE*.006));a[:ramp]*=np.linspace(0,1,ramp)[:,None];a[-ramp:]*=np.linspace(1,0,ramp)[:,None]
 pcm=np.round(a*32767).astype('<i2');path=OUT/(name+'.wav')
 with wave.open(str(path),'wb')as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(pcm.tobytes())
 records.append(dict(file=path.name,seconds=len(a)/RATE,peak=float(np.max(np.abs(a))),rms=float(np.sqrt(np.mean(a*a))),loop=loop,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
 return a
n=12*RATE;t=np.arange(n)/RATE
rain=noise(12,160,6500,.20)*(.86+.08*np.sin(t*2*np.pi/12)+.035*np.sin(t*2*np.pi*5/12))[:,None]
# Staggered tiny droplet taps, buried within a steady soft rain bed.
for at in rng.integers(0,n-1200,180):
 dur=1000;et=np.arange(dur)/RATE
 hit=noise(dur/RATE,500,6200,.1)*np.exp(-et*100)[:,None]
 rain[at:at+dur]+=hit*rng.uniform(.08,.45)
save('rain',rain,.54,True)
save('sheltered-rain',noise(12,55,1100,.6)*(.85+.12*np.sin(t*2*np.pi/12))[:,None],.46,True)
t=np.arange(16*RATE)/RATE
wind=noise(16,35,2100,.75)*(.62+.18*np.sin(t*2*np.pi/16)+.12*np.sin(t*2*np.pi*3/16))[:,None]
save('wind',wind,.55,True)
save('snow-wind',noise(16,100,2700,.55)*(.57+.2*np.sin(t*2*np.pi/16)+.08*np.cos(t*2*np.pi*3/16))[:,None],.42,True)
for v in range(1,4):
 sec=4.8+v*.55;t=np.arange(round(sec*RATE))/RATE
 rumble=noise(sec,27,650,.82);crack=noise(sec,300,5800,.08)
 env=(1-np.exp(-t/0.014))*np.exp(-t/(1.25+v*.24))
 rolls=np.zeros(len(t))
 for delay,strength,width in [(0,.8,.5),(.65+v*.09,.65,.5),(1.8,.35,.8),(3.1,.16,.8)]:
  d=np.maximum(0,t-delay);rolls+=strength*(1-np.exp(-d/.07))*np.exp(-d/width)*(t>=delay)
 a=rumble*(env*.4+rolls)[:,None]+crack*(np.exp(-t*22)*(.22/v))[:,None]
 a*=np.minimum(1,(sec-t)/.7)[:,None];save('thunder-'+str(v),a,.82)
for kind in ['snow','splash','damp','wetgrass']:
 for v in range(1,5):
  sec=.24 if kind=='snow' else .19;t=np.arange(round(sec*RATE))/RATE
  if kind=='snow':
   a=noise(sec,400,6300,.1);env=(np.exp(-((t-.035)/.024)**2)+.65*np.exp(-((t-.105)/.040)**2)+.23*np.exp(-((t-.17)/.023)**2));a*=env[:,None]
  elif kind=='splash':
   a=noise(sec,100,3500,.6);env=(1-np.exp(-t/.005))*np.exp(-t*23);a*=env[:,None]
   a+=noise(sec,55,230,.4)*(.35*np.exp(-((t-.03)/.016)**2))[:,None]
  elif kind=='wetgrass':a=noise(sec,350,3400,.3)*(np.exp(-((t-.05)/.03)**2)+.3*np.exp(-((t-.10)/.04)**2))[:,None]
  else:a=noise(sec,100,1500,.6)*((1-np.exp(-t/.004))*np.exp(-t*48))[:,None]
  save(kind+'-'+str(v),a,.57 if kind=='snow' else .48)
(OUT/'SOURCES.json').write_text(json.dumps(dict(generator='tools/build_weather_audio.py',seed=28092026,license='Original procedural VASC audio; no external samples.',sample_rate=RATE,channels=2,files=records),indent=2)+'\n')
print('Built',len(records),'weather sounds;',sum((OUT/r['file']).stat().st_size for r in records),'bytes')
