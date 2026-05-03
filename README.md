# 🏛️ UniIAM — Identity & Access Management System

A complete **offline-first desktop application** for managing university identities and authentication — built with Flutter and Hive.

---

## 📌 Overview

**UniIAM** is a desktop Identity & Access Management (IAM) system designed for universities.
It provides a centralized solution to manage:

* Students
* Faculty
* Staff
* Contractors
* Alumni

The system runs **entirely locally** — no backend, no cloud, no internet required for core functionality.

---

## ⚙️ Key Features

### 👤 Identity Management

* Supports **12 user categories**, each with custom fields and forms
* Automatic:

  * Unique ID generation
  * Temporary password creation
  * Initial status assignment
* Full **audit trail**:

  * Profile changes
  * Status transitions
  * Timestamps & tracking

### 🔄 Account Lifecycle

Accounts follow a structured lifecycle:

`Pending → Active → Suspended / Inactive → Archived`

* Enforced transitions
* Full history tracking

---

### 🔐 Authentication System

Supports **4 authentication levels**:

1. Password only
2. Password + Email OTP
3. Password + TOTP
4. Full MFA (Password + OTP + TOTP + Security Questions)

Security features:

* Password hashing using **bcrypt (cost 12 + salt)**
* Password policy enforcement (configurable)
* Password reuse prevention
* Account lock after failed attempts
* Full login audit logging

---

### 🧑‍💼 Role-Based Access

| Role        | Permissions                                  |
| ----------- | -------------------------------------------- |
| Student     | View profile, manage password, login history |
| Faculty     | View professional data, manage security      |
| Admin Staff | Full identity management                     |
| IT Admin    | Full authentication & security control       |
| Contractor  | Profile + expiry tracking                    |
| Alumni      | Limited access                               |

---

### 📧 Email OTP

* 8-digit verification code
* Valid for **5 minutes**
* Rate limiting & resend cooldown
* Powered by EmailJS

---

## 🚀 Getting Started

### 📦 Prerequisites

* Flutter SDK 3.x+
* Desktop support enabled (Windows / Linux / macOS)

---

### 🔧 Installation

```bash
git clone  https://github.com/souleyman-benali-cherif/identity-and-access-management.git
cd "folder name"
flutter pub get
flutter run -d windows
```

---

## ⚠️ Required Configuration

Before using the app, update the following:

### 1. IT Admin Email

In `main.dart`:

```dart
personalEmail: 'your-admin-email@example.com',
```

---

### 2. Admin Staff Email

```dart
personalEmail: 'your-staff-email@example.com',
```

---

### 3. EmailJS Setup

Create an account on EmailJS and configure:

* Service ID
* Template ID
* Public Key

Then update:

`lib/services/otp_service.dart`

```dart
const serviceId  = 'YOUR_EMAILJS_SERVICE_ID';
const templateId = 'YOUR_EMAILJS_TEMPLATE_ID';
const publicKey  = 'YOUR_EMAILJS_PUBLIC_KEY';
```

---

## 🔑 Default Credentials

| Role        | Username     | Temporary Password |
| ----------- | ------------ | ------------------ |
| IT Admin    | STF202400001 | Admin@1234         |
| Admin Staff | STF202400002 | Staff@1234         |

⚠️ Password change required on first login.

---

## 🧰 Tech Stack

| Component        | Technology        |
| ---------------- | ----------------- |
| UI               | Flutter (Desktop) |
| Database         | Hive (local)      |
| Password Hashing | bcrypt            |
| OTP              | EmailJS           |
| TOTP             | HMAC-SHA1         |
| Tokens           | UUID v4           |

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

## 💡 Notes

* No external database required
* Designed for academic and demonstration purposes
* Easily extendable to client-server architecture

---
