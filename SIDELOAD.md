# Sideloading GGUF Models to Your Neural Farm Phones

Get models onto your iPhone and Pixel without waiting on slow in-app downloads. Use your Mac’s connection to download, then transfer via USB.

---

## 1. Download the models on your Mac

Use these direct links (or run `./sideload_models.sh --download` and the script will fetch them into `~/Downloads`):

| Device | Model | File | Direct link |
|--------|--------|------|-------------|
| **iPhone 15 Pro Max** | Llama 3.2 3B Instruct | `Llama-3.2-3B-Instruct-Q4_K_M.gguf` | [Hugging Face](https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf) |
| **Pixel 8 Pro** | Gemma 3 4B Instruct | `gemma-3-4b-it-Q4_K_M.gguf` | [Hugging Face](https://huggingface.co/ggml-org/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf) |

Save (or move) both files into **`~/Downloads`**.

---

## 2. Run the sideload script

From the project folder:

```bash
cd ~/neural-farm
chmod +x sideload_models.sh
./sideload_models.sh
```

- If any file is missing, the script will tell you. Run `./sideload_models.sh --download` to have it download missing files into `~/Downloads`.
- The script will:
  - Check if the **iPhone** is connected via USB and give **step-by-step Finder instructions** (drag the Llama `.gguf` into PocketPal AI’s Files).
  - Check if **adb** is available and an **Android** device is connected; if so, **push** the Gemma `.gguf` to the device’s `Download` folder.

---

## 3. Manual steps (when the script can’t do it)

### iPhone (PocketPal AI)

1. Connect the iPhone with USB-C and unlock it.
2. On the Mac: **Finder** → select **iPhone** in the sidebar → open the **Files** tab.
3. In the app list, select **PocketPal AI**.
4. From your Mac, drag **`Llama-3.2-3B-Instruct-Q4_K_M.gguf`** from `~/Downloads` into that PocketPal AI file area.

### Pixel (PocketPal Android)

1. Connect the Pixel with USB-C.
2. On the phone, when the USB notification appears, choose **File transfer** (MTP).
3. **Option A, Script (if adb is installed):** Run `./sideload_models.sh`; it will push `gemma-3-4b-it-Q4_K_M.gguf` to the device **Download** folder.
4. **Option B, Manual:** On the Mac, open **Finder** (or Android File Transfer) and copy **`gemma-3-4b-it-Q4_K_M.gguf`** into the phone’s **Download** folder.
5. On the Pixel: open **PocketPal** → **+** (or “Add”) → **Import from Local Storage** → choose the file from **Download**.

---

## 4. In the apps after the file is on the device

1. Open **PocketPal** (iOS or Android).
2. Go to **Models** (or equivalent).
3. Tap **Add** / **+** → **Add local model** (or “Import”).
4. Select the `.gguf` you just moved.
5. In the model settings, set the **chat template**:
   - **iPhone:** **Llama 3**
   - **Pixel:** **Gemma**

Then start the local server (e.g. on port 8080) when you’re ready to use the Neural Farm.
