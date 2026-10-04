# 🚀 PRODUCT REQUIREMENT DOCUMENT (PRD) - FINAL SPECIFICATION

## 1. PROJECT OVERVIEW & GOALS

* **Product Name:** QuickChat (Daya Engine)
* **Target Platforms:** Android & iOS (Cross-Platform Mobile App)
* **Core Philosophy:** Real-time, Low-Latency, Privacy-First Communication App with Mutual Contact Validation & Dynamic Status Sharing.

---

## 2. CORE FEATURES & DETAILED SPECIFICATIONS

### 2.1 Mutual Contact & Friend Validation Logic

* **Rule:** User A and User B are considered **"Mutual Friends"** ONLY if both users have saved each other's phone numbers in their respective device contacts.
* **Flow & Implementation:**
1. On app init/permission grant, hash local contacts (SHA-256) and upload to backend (`POST /api/v1/contacts/sync`).
2. Backend cross-checks phone hashes against active registered users.
3. Set relationship status in DB: `is_mutual_contact = true` only when bidirectional match exists.
4. Story visibility & online status are strictly guarded by `is_mutual_contact == true`.

### 2.2 Real-Time Direct Messaging (1-on-1 Chat)

* **Real-time Protocol:** WebSockets (Socket.io / Native WS).
* **Message Lifecycle & Read Receipts:**
1. 🕒 **Sending (`status: 0`):** Local pending message with unique client UUID.
2. 🏷️ **Sent (`status: 1` / Single Checkmark):** Saved in Database/Server.
3. 🏷️🏷️ **Delivered (`status: 2` / Double Grey Checkmark):** Pushed & acknowledged by recipient's active socket connection or background push service.
4. 🟦🟦 **Read (`status: 3` / Double Blue Checkmark):** Recipient opens/views the active chat conversation view.

* **Timestamp & Locale:**
* Timestamps are stored in UTC on the server and converted dynamically to recipient's local device system time (`Format: HH:mm` for today, `DD/MM/YY` for older messages).

### 2.3 Group Chat Architecture

* **Capabilities:**
* Create group, add multiple contacts, set group avatar & title.
* Roles: `ADMIN` and `MEMBER`.
* Group Read Receipts: Double Blue Checkmark updates when **ALL active group members** have read the message (`status = 3`).

### 2.4 Story & Status Engine (24-Hour Expiry)

* **Visibility Rule:** Strictly accessible ONLY to validated Mutual Contacts (`is_mutual_contact == true`).
* **Expiration:** Automatic 24-hour lifetime managed by Redis TTL or Scheduled Background Worker.
* **Real-time Viewer Tracking:**
* Track user IDs, timestamp, and read count when mutual contacts view the status.
* Update viewer count indicator on creator's UI in real-time.

---

## 3. UI/UX DESIGN SYSTEM & SCREEN FLOW

### 3.1 Design Guidelines (Referencing Design Kit)

* **Color Palette:**
* Primary Accent: Cyan Blue (`#00A8FF` to `#0275D8` Gradient)
* Secondary Accent: Electric Teal (`#00E5FF`)
* Background: Pure White (`#FFFFFF`) & Slate Light (`#F4F7FB`)
* Text Primary: Dark Navy (`#0A192F`)
* Text Secondary: Muted Grey (`#8892B0`)

* **Typography:** Poppins or Inter (Clean, modern sans-serif).
* **Iconography:** Modern rounded vector icons, double checkmark badge indicator.

### 3.2 Screen Architecture & Flow Mapping

```text
[Splash & Onboarding] ──> [Phone Auth / OTP] ──> [Contact Sync Permission]
                                                               │
┌──────────────────────────────────────────────────────────────┴──────────────────────────────────────────────────────────────┐
│                                                        MAIN APP LAYOUT                                                       │
├───────────────────────────────┬───────────────────────────────┬───────────────────────────────┬──────────────────────────────┤
│       1. CHATS TAB            │       2. STORIES TAB          │       3. GROUPS TAB           │       4. PROFILE TAB         │
│  - Active Chat List           │  - My Story (Add Text/Media) │  - Active Groups List         │  - User Profile & Avatar     │
│  - Unread Badges              │  - Mutual Friends Stories     │  - Real-time Viewer Tray      │  - Create New Group FAB       │
│  - Real-time Read Indicators  │  - Group Admin Controls       │  - Status Message            │  - Privacy & Contact Sync    │
└───────────────────────────────┴───────────────────────────────┴───────────────────────────────┴──────────────────────────────┘
                                                               │
                                                               ▼
                                                      [CHAT DETAIL VIEW]
                                            - Header: User Info & Online Status
                                            - Message Stream (Text, Media, Time)
                                            - Real-time Status Badges (1 Check / 2 Grey / 2 Blue)
                                            - Input Field & Attachment Menu
```

---

## 4. DATABASE SCHEMA (PostgreSQL Reference)

```json
// User Document Schema
{
  "_id": "user_id_uuid",
  "phone_number": "+6281234567890",
  "phone_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "name": "Reynaldi Agiel Fahlevi",
  "avatar_url": "https://cdn.quickchat.com/avatars/user_1.jpg",
  "about_status": "Available",
  "is_online": true,
  "last_seen": "2026-09-17T09:39:25Z",
  "created_at": "2026-09-17T09:39:25Z"
}

// Contacts Junction / Relationship Schema
{
  "_id": "contact_id_uuid",
  "user_id": "user_id_1",
  "target_user_id": "user_id_2",
  "is_mutual_contact": true,
  "updated_at": "2026-09-17T09:39:25Z"
}

// Message Document Schema
{
  "_id": "msg_id_uuid",
  "conversation_id": "conv_id_uuid",
  "sender_id": "user_id_1",
  "receiver_id": "user_id_2", // or group_id
  "content": "Halo, pesan ini sudah dibaca!",
  "media_url": null,
  "status": 3, // 0: Sending, 1: Sent, 2: Delivered, 3: Read
  "created_at": "2026-09-17T09:39:25Z",
  "read_at": "2026-09-17T09:40:00Z"
}

// Story Document Schema
{
  "_id": "story_id_uuid",
  "user_id": "user_id_1",
  "media_url": "https://cdn.quickchat.com/stories/story_1.jpg",
  "caption": "Working on new mobile app! 🚀",
  "expires_at": "2026-09-18T09:39:25Z",
  "viewers": [
    {
      "user_id": "user_id_2",
      "viewed_at": "2026-09-17T09:45:10Z"
    }
  ]
}
```

---

## 5. WEBSOCKET REAL-TIME EVENT PAYLOADS
(Refer to PRD document for details on send_message, message_sent, message_delivered, mark_as_read, message_read_update events)

---

## 6. DEVELOPMENT ROADMAP & EXECUTION STEPS
1. **Step 1:** Initialize Mobile Application setup with state management and design system components.
2. **Step 2:** Setup Backend API & Database Models with Auth & Phone Hash Sync Engine.
3. **Step 3:** Implement WebSocket Gateway handling lifecycle states.
4. **Step 4:** Build UI Screens (Chat List, Chat Room).
5. **Step 5:** Build Story/Status Module.
