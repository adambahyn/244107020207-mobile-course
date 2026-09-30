"""Screenshot lewat CDP supaya bisa memotret state loading yang sedang berjalan.

Chrome headless `--screenshot` tidak bisa: ia memakai virtual time dan langsung
memajukan waktu sampai halaman "tenang", jadi spinner sudah hilang saat difoto.
Di sini halaman dimuat sungguhan lalu difoto pada detik yang diminta.

  python tools/shot_cdp.py <url> <tunggu-detik> <keluaran.png>
"""
import asyncio
import base64
import json
import subprocess
import sys
import urllib.request

import websockets

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"


async def shot(url: str, wait_s: float, out: str, port: int = 9333):
    proc = subprocess.Popen(
        [
            CHROME,
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            "--hide-scrollbars",
            f"--remote-debugging-port={port}",
            "--window-size=430,900",
            "about:blank",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        for _ in range(50):
            try:
                targets = json.load(
                    urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list")
                )
                page = next(t for t in targets if t["type"] == "page")
                break
            except Exception:
                await asyncio.sleep(0.2)
        else:
            raise RuntimeError("DevTools tidak siap")

        async with websockets.connect(page["webSocketDebuggerUrl"], max_size=None) as ws:
            counter = iter(range(1, 1000))

            async def send(method, **params):
                mid = next(counter)
                await ws.send(json.dumps({"id": mid, "method": method, "params": params}))
                while True:
                    msg = json.loads(await ws.recv())
                    if msg.get("id") == mid:
                        return msg.get("result", {})

            await send("Page.enable")
            await send("Emulation.setDeviceMetricsOverride",
                       width=430, height=900, deviceScaleFactor=2, mobile=True)
            await send("Page.navigate", url=url)
            await asyncio.sleep(wait_s)
            data = await send("Page.captureScreenshot", format="png")
            with open(out, "wb") as handle:
                handle.write(base64.b64decode(data["data"]))
            print(f"tersimpan: {out}")
    finally:
        proc.terminate()


if __name__ == "__main__":
    asyncio.run(shot(sys.argv[1], float(sys.argv[2]), sys.argv[3]))
