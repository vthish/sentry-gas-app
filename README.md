<div align="center">
  <h1>🛡️ Sentry Gas</h1>
  <p><b>Advanced IoT Gas Monitoring & Automated Safety System</b></p>
  
  <img src="https://img.shields.io/badge/Hardware-Arduino%20%7C%20ESP32-blue?style=for-the-badge&logo=arduino" alt="Hardware" />
  <img src="https://img.shields.io/badge/App-React%20Native-61DAFB?style=for-the-badge&logo=react" alt="React Native" />
  <img src="https://img.shields.io/badge/Backend-Node.js-339933?style=for-the-badge&logo=nodedotjs" alt="NodeJS" />
</div>

<br/>

## 🚀 Overview
**Sentry Gas** is a smart IoT solution designed to ensure kitchen safety and monitor gas usage efficiently. It tracks real-time gas levels, maintains detailed usage history, and features an automated fail-safe mechanism that instantly shuts off the gas valve in the event of a leak.

## ✨ Key Features
* **🚨 Leak Detection & Auto-Shutoff:** Instantly detects gas leaks and automatically closes the solenoid valve to prevent accidents.
* **📱 Remote Control:** Turn the gas supply ON/OFF safely from anywhere using the mobile app.
* **📊 Usage History & Analytics:** Monitor daily/monthly gas consumption and track the remaining gas volume.
* **🔔 Real-time Alerts:** Receive instant push notifications for critical events like leaks or low gas levels.

## 🛠️ System Architecture

### ⚙️ Hardware Components
* **Microcontroller:** Arduino / ESP32
* **Gas Detection:** MQ-5 Gas Sensor
* **Volume/Weight Tracking:** Load Cell with HX711 Amplifier
* **Valve Control:** Solenoid Valve & Relay Module

### 💻 Software Stack
* **Mobile Application:** Built for Android/iOS (React Native)
* **Backend API:** Node.js (Handles user authentication and data processing)
* **Database:** Real-time database for storing usage history and telemetry logs

## 💡 How It Works
1. **Continuous Monitoring:** The MQ-5 sensor constantly checks the environment for combustible gases. 
2. **Emergency Response:** If a leak is detected, the system does not wait for user input—the microcontroller instantly triggers the Solenoid Valve to close and sends a high-priority alert to the app.
3. **Usage Calculation:** The Load Cell accurately measures the cylinder's weight, sending data to the cloud to calculate usage history and predict when a refill is needed.
4. **User Control:** Users can manually override the valve state (ON/OFF) and view comprehensive analytics through the mobile dashboard.

## 👨‍💻 Developed By
**K.V. Venusha Thishan**
*Full Stack Developer | IoT Innovator*
