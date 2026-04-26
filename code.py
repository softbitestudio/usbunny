import time, ssl, wifi, socketpool, adafruit_requests as requests
import board, displayio, adafruit_imageload, adafruit_cst8xx
import terminalio, adafruit_display_text.label
from adafruit_display_shapes.rect import Rect

# ---------- config ----------
FACES_DIR = "/faces/"
ENDPOINT  = "https://your-pi.local:11434/api/chat"  # Ollama
AUTH      = None                                    # or Bearer token
POKE_TTL  = 3.0                                     # seconds
MAX_CHARS = 120
# ----------------------------

# init display
display = board.DISPLAY
group   = displayio.Group()
display.show(group)

# load faces
faces = {f.stem: adafruit_imageload.load(str(f))[0]
         for f in os.listdir(FACES_DIR) if f.endswith(".bmp")}

def show_face(name):
    group[0] = faces.get(name, faces["neutral"])

# init touch
touch = adafruit_cst8xx.CST8XX(board.I2C())
last_poke = 0
annoyance = 0

# wifi
wifi.radio.connect(os.getenv("CIRCUITPY_WIFI_SSID"), os.getenv("CIRCUITPY_WIFI_PASSWORD"))
pool = socketpool.SocketPool(wifi.radio)
ssl_context = ssl.create_default_context()
session = requests.Session(pool, ssl_context)

# simple word-wrap
def wrap(txt, max_len=24):
    lines, cur = [], ""
    for w in txt.split():
        if len(cur)+len(w)+1 <= max_len:
            cur += (" "+w if cur else w)
        else:
            lines.append(cur); cur=w
    if cur: lines.append(cur)
    return "\n".join(lines)

# streaming LLM call
def ask_llm(prompt, mood):
    payload = {
        "model": "phi3:mini",
        "messages": [
            {"role": "system", "content": f"You are a tiny chaos bunny. Current mood: {mood}"},
            {"role": "user",   "content": prompt}
        ],
        "stream": True,
    }
    with session.post(ENDPOINT, json=payload, headers={"Authorization": AUTH}, stream=True) as resp:
        txt = ""
        for chunk in resp.iter_content(chunk_size=1):
            if chunk:
                txt += chunk.decode()
                if len(txt) >= MAX_CHARS:
                    break
        return wrap(txt)

# ---------- main loop ----------
show_face("neutral")
while True:
    gesture = touch.gesture
    if gesture == 0x0B:                      # poke
        last_poke = time.monotonic()
        x, y = touch.x, touch.y
        if y < 86:                           # top half → eye poke
            mood = "angry"
            annoyance = min(10, annoyance+2)
        else:
            mood = "laugh"
            annoyance = max(0, annoyance-1)
        show_face(mood)
        reply = ask_llm("Someone poked me!", mood)
        label = adafruit_display_text.label.Label(terminalio.FONT, text=reply, color=0xFFFF, x=10, y=100)
        group.append(label)
        time.sleep(3)
        group.pop()

    # decay annoyance
    if time.monotonic() - last_poke > POKE_TTL:
        annoyance = max(0, annoyance-1)
        if annoyance > 5:
            show_face("angry")
        else:
            show_face("neutral")

    time.sleep(0.05)