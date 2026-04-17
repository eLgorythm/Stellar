# Stellar - Gacha Link Scanner & Pity Counter

Stellar is an Android application designed to automatically retrieve request history links (*Gacha Links*) and manage gacha statistics for HoYoverse games (**Genshin Impact**, **Honkai: Star Rail**, and **Zenless Zone Zero**) using the ADB Wireless Debugging protocol.

This application uses the Self-Pairing technique, where the application acts as an ADB client that communicates with the Android system on the same device through the `localhost` interface.

## ✨ Key Features

- **Gacha Link Scanner:** Automatically extract the gacha URL from game logs using ADB.
- **Wish History Import:** Download and save your entire wish history locally from HoYoverse servers.
- **Pity Counter:** Track your current pity, average 5-star luck, and "Guaranteed" status for every banner.
- **Multi-Game Support:** Seamlessly switch between Genshin Impact, HSR, and ZZZ.

## 📖 How to Use

1. **Enable Developer Options:** Go to Android settings and enable "Wireless Debugging".
2. **Pairing:**
    - Press the **PAIR** button in the Stellar app.
    - Open the Wireless Debugging settings and select "Pair device with pairing code".
    - Enter the 6-digit code that appears in the Stellar input notification.
3. **Connect:** Once the *Is Paired* status is `True`, press the **CONNECT** button.
4. **Scan Gacha:**
    - Press **SCAN NOW** in the dialog that appears.
    - Open the game (e.g., Genshin Impact) and go to the **History/Request History** page.
    - Wait for the "Link Retrieved!" notification to appear.
5. **Copy Link:** Copy the retrieved link and use it on your preferred gacha analysis platform.
6. **Import History:**
    - Use the **IMPORT** button to fetch your history.
    - Once finished, go to the **Statistics** tab to see your Pity Counter and detailed 5-star history.

## 🛡 Security & Privacy

- **No Root Required:** This app works entirely at the user level using standard Android Developer features.
- **Local Processing:** All link decryption and extraction processes are performed locally on your device. No sensitive data (such as the `authkey`) is sent to third-party servers by this app.
- **Ephemeral Keys:** TLS certificates are generated uniquely per device and stored in a secure internal directory of the app.
- **Data Ownership:** Your wish history is stored as JSON files only on your device's internal storage.

## ⚖️ License

This project was developed for educational purposes and as a personal tool. Stellar is not affiliated with HoYoverse. Use of this application is subject to each game's privacy policy and terms of service.

---
*Developed with ❤️ by elfnd using Flutter & Rust.*