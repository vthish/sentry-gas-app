<div align="center">
  <h1>🛡️ Sentry Gas - Mobile App</h1>
  <p><b>Advanced IoT Gas Monitoring & Automated Safety System</b></p>
  
  <img src="https://img.shields.io/badge/App-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Database-Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
</div>

<br/>

## 🚀 Overview
**Sentry Gas** is a smart IoT solution designed to ensure kitchen safety and monitor gas usage efficiently. This repository contains the **Flutter mobile application** for the system.

🔗 **Hardware & Arduino Firmware Repository:** [sentry-gas-final-arduino_code](https://github.com/vthish/sentry-gas-final-arduino_code)

## ✨ Key Features
* **🔐 Secure Login:** Firebase SMS Authentication for quick and secure phone number login.
* **🚨 Leak Alerts & Auto-Shutoff:** Receive instant push notifications when a gas leak is detected and the system autonomously closes the valve.
* **🎛️ Remote Control:** Manually turn the gas supply ON/OFF safely from anywhere using the app interface.
* **📊 Usage History & Analytics:** Monitor real-time remaining gas volume and track daily/monthly consumption patterns.

## 🛠️ Software Architecture

### 📱 Mobile App (This Repository)
* **Framework:** Flutter (Android/iOS support)
* **Authentication:** Firebase Phone (SMS) Authentication
* **Database:** Firebase Cloud Firestore (Real-time data synchronization)

### ⚙️ Hardware Integration (External Repo)
* **Microcontroller:** Arduino / ESP32
* **Sensors:** MQ-5 Gas Sensor, Load Cell with HX711
* The hardware continuously sends telemetry data to Firestore, which the app listens to in real-time.

## 💡 How The System Works
1. **User Access:** Users authenticate via SMS OTP and connect to their specific gas monitoring hardware node via Firestore.
2. **Real-time Monitoring:** The app fetches real-time weight and sensor data from Firestore, calculated by the hardware's load cell.
3. **Emergency Response:** If the MQ-5 sensor detects a leak, the Arduino closes the solenoid valve instantly and updates the Firestore document. The Flutter app immediately alerts the user.
4. **App Control:** Users can tap the toggle in the app to update the valve state in Firestore, which the ESP32/Arduino reads and executes mechanically.

## 👨‍💻 Developed By
**Venusha Thishan**
*Full Stack Developer | IoT Innovator*
