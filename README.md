# Stellar - ADB Gacha Link Scanner

Stellar is a Android application designed to automatically retrieve request history links (*Gacha Links*) from HoYoverse games (Genshin Impact, Honkai: Star Rail, Honkai Impact 3rd, and Zenless Zone Zero) using the ADB Wireless Debugging protocol.

This application uses the Self-Pairing technique, where the application acts as an ADB client that communicates with the Android system on the same device through the `localhost` interface.

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
5. **Copy Link:** Copy the retrieved link and use it on your preferred gacha analysis platform (such as Paimon.moe).

## 🛡 Security & Privacy

- **No Root Required:** This app works entirely at the user level using standard Android Developer features.
- **Local Processing:** All link decryption and extraction processes are performed locally on your device. No sensitive data (such as the `authkey`) is sent to third-party servers by this app.
- **Ephemeral Keys:** TLS certificates are generated uniquely per device and stored in a secure internal directory of the app.

## ⚖️ License

This project was developed for educational purposes and as a personal tool. Stellar is not affiliated with HoYoverse. Use of this application is subject to each game's privacy policy and terms of service.

---
*Developed with ❤️ by elfnd using Flutter & Rust.*