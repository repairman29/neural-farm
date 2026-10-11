# Pixel: "Allow USB debugging?" prompt not showing on Mac

The prompt appears **on the phone**, not the Mac. If you don’t see it, the Pixel is usually in **charging-only** mode, so the Mac never gets a debugging connection.

---

## Option A: Use Wireless debugging (no USB prompt)

You can push the model over WiFi and never need the USB “Allow?” prompt.

1. **On Pixel:** Settings → System → **Developer options** → **Wireless debugging** → turn **On**.
2. Tap **“Pair device with pairing code”**. You’ll see an IP and port (e.g. `10.1.10.93:37829`) and a **6-digit code**.
3. **On Mac**, in Terminal:
   ```bash
   cd ~/neural-farm
   chmod +x push_pixel_wireless.sh
   ./push_pixel_wireless.sh 10.1.10.93:37829
   ```
   Replace `10.1.10.93:37829` with the **IP:port** from the Pixel. When prompted, enter the **6-digit code**.
4. The script will pair, connect over WiFi, and push the Gemma file to the Pixel’s Download folder.
5. On the Pixel: open **PocketPal** → **+** → **Import from Local Storage** → **Download** → select the file → set chat template to **Gemma**.

---

## Option B: Fix USB so the prompt appears (Default USB configuration)

1. **Settings → System → Developer options**
2. Find **Default USB configuration** (or **Select USB configuration**).
3. Set it to **File transfer** or **MTP** (not "Charging" or "No data transfer").
4. **Unplug the USB cable**, wait a couple of seconds, then **plug it back in**.
5. On the **Pixel**, you should see **"Allow USB debugging?"**, tap **Allow** (and optionally "Always allow from this computer").

---

## If you still don’t get the prompt

- **Revoke authorizations:** In Developer options, tap **Revoke USB debugging authorizations**, then unplug/replug and allow again when prompted.
- **Cable:** Use a cable that supports data (some USB-C cables are charge-only).
- **Port:** Plug into the Mac directly (avoid hubs if possible).
- **After changing USB config:** Always unplug and replug so the new mode is used.

---

## Check on the Mac

In Terminal, from the project folder:

```bash
~/neural-farm/.android-tools/platform-tools/adb devices
```

You should see your device (not "unauthorized"). Then run:

```bash
~/neural-farm/sideload_models.sh
```

to push the Gemma model to the Pixel.
