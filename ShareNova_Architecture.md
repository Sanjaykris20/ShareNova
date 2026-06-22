# ShareNova — Complete Architecture Guide
### Offline P2P Mode + Online Firebase Mode

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Offline Mode — Nearby Device Sharing](#2-offline-mode--nearby-device-sharing)
   - 2.1 [How devices discover each other](#21-how-devices-discover-each-other)
   - 2.2 [End-to-end encrypted transfer](#22-end-to-end-encrypted-transfer)
   - 2.3 [File expiry & remote revoke](#23-file-expiry--remote-revoke)
   - 2.4 [Team workspace with offline permissions](#24-team-workspace-with-offline-permissions)
   - 2.5 [Passcode-protected file transfer](#25-passcode-protected-file-transfer)
   - 2.6 [Auto-sync rules (offline scheduled transfers)](#26-auto-sync-rules-offline-scheduled-transfers)
   - 2.7 [Transfer analytics (local)](#27-transfer-analytics-local)
3. [Online Mode — Firebase Cloud Layer](#3-online-mode--firebase-cloud-layer)
   - 3.1 [Firebase project structure](#31-firebase-project-structure)
   - 3.2 [Hybrid sync — offline default, cloud fallback](#32-hybrid-sync--offline-default-cloud-fallback)
   - 3.3 [Long-distance room sync](#33-long-distance-room-sync)
   - 3.4 [Shareable web links](#34-shareable-web-links)
   - 3.5 [Push notifications](#35-push-notifications)
   - 3.6 [Cloud audit log backup](#36-cloud-audit-log-backup)
   - 3.7 [AI-powered features (online only)](#37-ai-powered-features-online-only)
4. [Security Model — Offline vs Online](#4-security-model--offline-vs-online)
5. [Screen-by-Screen Firebase Mapping](#5-screen-by-screen-firebase-mapping)
6. [Build Order — What to Build First](#6-build-order--what-to-build-first)

---

## 1. Project Overview

**ShareNova** is a file-sharing app built on three core principles:

- **Offline-first** — every feature works without internet, using Wi-Fi Direct and Bluetooth
- **Privacy by design** — files are encrypted before they leave the sender's device; no server ever holds a readable copy
- **Online as a booster** — Firebase adds range, notifications, and cloud backup without replacing the offline core

### Technology stack

| Layer | Offline | Online |
|---|---|---|
| Transfer protocol | Wi-Fi Direct, Bluetooth 5.0 | Firebase Storage |
| Metadata & rooms | SQLite (Room DB) | Firestore |
| Role enforcement | RSA-signed certificates | Firestore Security Rules |
| Notifications | Local WorkManager | Firebase Cloud Messaging |
| Auth | Device keypair (ECDH) | Firebase Anonymous Auth |
| Expiry enforcement | WorkManager on-device | Cloud Functions cron |

---

## 2. Offline Mode — Nearby Device Sharing

### 2.1 How devices discover each other

When a user taps the **Send** button on the HomeScreen, the app simultaneously activates two discovery channels.

**Wi-Fi Direct discovery** is the primary channel. The app calls `WifiP2pManager.discoverPeers()` which broadcasts a beacon signal. Every other phone running ShareNova in the same area receives this beacon and appears in a peer list. The user sees the DeviceDiscoveryScreen populate in real time as nearby devices appear, showing their display name, signal strength, and current transfer capability (whether they're already transferring something or free to receive).

When a device is selected, the app initiates a `WifiP2pManager.connect()` call. This creates a direct device-to-device Wi-Fi link with no router or internet required. One phone becomes the "group owner" (acts as a temporary local access point) and the other connects to it, producing a private local network between just the two phones. Transfer speeds on this channel reach 200–250 Mbps in ideal conditions.

**Bluetooth discovery** runs in parallel as a fallback for devices that are nearby but where Wi-Fi Direct fails (some older Android versions have inconsistent Wi-Fi Direct support). Bluetooth is used at a lower speed (around 2–3 Mbps) and is also the primary channel for small control signals — delete commands, revoke signals, and role updates — because it is more reliable at short range for tiny payloads than Wi-Fi Direct.

The DeviceDiscoveryScreen radar animation represents this dual-channel scan happening simultaneously. A device appears on the radar when either channel detects it.

---

### 2.2 End-to-end encrypted transfer

Every file transfer, whether offline or online, goes through the same encryption pipeline. The user never has to toggle this — it runs automatically on every send.

#### Step 1 — ECDH handshake

The moment two devices connect (either over Wi-Fi Direct socket or through the Firebase relay), they perform an ECDH (Elliptic Curve Diffie-Hellman) handshake before any file data moves. Each device generates a fresh temporary keypair for this session. They exchange only the **public halves** of their keypairs. Using elliptic curve math, each phone independently computes the same shared secret from its own private key and the other phone's public key. This shared secret becomes the AES-256 session key.

The session key **never travels over the network** at any point. It is derived independently on both devices from the exchanged public keys. An attacker who intercepts all traffic between the two phones still cannot compute the session key without one of the private halves, which never left the device that generated them.

#### Step 2 — Chunked file encryption

The file is split into 1 MB chunks. Each chunk is encrypted with AES-256-GCM using the session key before it leaves the sender's device. GCM mode (Galois/Counter Mode) provides two guarantees simultaneously: the chunk is scrambled (confidentiality) and tagged with an authentication code (integrity). If a chunk arrives corrupted or tampered with, the authentication tag mismatch is detected immediately and the chunk is rejected — there is no "partially decrypted" ambiguous state.

#### Step 3 — Transfer and reassembly

Chunks flow over the established socket connection one at a time. The TransferProgressScreen progress bar maps directly to the chunk count: if a file has 50 chunks and 23 have been received and verified, the progress bar shows 46%. Each chunk is verified before the next is requested, so a corrupt chunk causes that specific chunk to be re-requested rather than failing the entire transfer.

#### Step 4 — Decryption and write

The receiver decrypts each chunk in memory (RAM) and writes the plaintext bytes to local storage only after verification passes. The encrypted bytes are never written to the receiver's storage — they flow through RAM and get decrypted before hitting the filesystem. Once all chunks are received and the file is fully written, the session key is wiped from memory. The key exists for the duration of the transfer only.

---

### 2.3 File expiry & remote revoke

File expiry is the feature that gives the sender permanent control over a file even after it has left their device. It is built on four sub-mechanisms that work together.

#### Setting the timer — what happens at send time

Before hitting send, the sender optionally opens the expiry panel and picks a rule. The available rule types are:

- **Time-based** — "delete after N hours/days from now"
- **View-based** — "delete after N opens"
- **Combined** — "delete after whichever of the above happens first"

This rule is encoded into a small metadata packet alongside the file's name, size, and file ID. The metadata packet is encrypted using the same AES-256-GCM session key as the file itself, so it is tamper-proof. A receiver cannot strip the rule from the file or alter the view limit without breaking the authentication tag.

#### Local enforcement — how the countdown runs without internet

When the receiver's app accepts the file, it writes the expiry rule into a dedicated `file_expiry` table in its local SQLite database (your Room database). The record stores the file ID, the expiry deadline as a Unix timestamp, the maximum allowed view count, the current view count (starts at 0), and a `deleted` boolean.

Two independent enforcement triggers run on the receiver's device:

**On-access trigger** — every time the user taps to open a file through ShareNova's viewer, the app reads the expiry record before rendering any content. If `currentTime > expiryDeadline` or `viewCount >= maxViews`, the app immediately deletes the file from storage and updates the record's `deleted` flag to true. The user sees a "this file has expired" message rather than blank screen. The file never renders if expired.

**Scheduled background trigger** — Android's WorkManager schedules a `PeriodicWorkRequest` to run every 15 minutes. This worker queries all records in `file_expiry` where `deleted = false` and checks each against the current time and view count. Any file that has crossed its deadline gets deleted even if the user never opens it again. This handles the scenario where a file was sent with a 24-hour expiry but the receiver never opened the app until day 3 — the file was already wiped by the background worker long before they saw it.

#### View counting — the detailed mechanic

Every time a file is opened through your app's viewer, the worker increments the `viewCount` field in the local database before rendering. If `viewCount + 1 > maxViews`, the file is deleted on that final opening attempt and a "last view reached" message shows instead of the content. The receiver genuinely cannot open it a third time if the limit was two — the local DB is the source of truth and the check runs before any content is shown.

The honest limitation: if a receiver exports the file to their phone's general storage or screenshots it, those copies exist outside ShareNova's control and are unaffected by the expiry system. This is the same limitation Snapchat has always had. What you can add on top is Android's screenshot detection callback — when a screenshot is taken while ShareNova's viewer is in the foreground, the app can log this event and optionally notify the sender.

#### Remote revoke — two scenarios with different mechanics

**Scenario 1 — Both devices still nearby (Wi-Fi Direct or Bluetooth range)**

The sender opens the file's entry in HistoryScreen and taps "Revoke now." The app broadcasts a small revoke packet (just the file ID and a signed "REVOKE" command) over the existing Bluetooth connection. The receiver's app, even if running in the background, receives this packet through a persistent Bluetooth listener. It immediately deletes the file and writes the tombstone record. The whole process takes under a second. The sender's HistoryScreen updates to show "Revoked" status.

**Scenario 2 — Devices no longer near each other (offline-to-offline revoke)**

The sender taps "Revoke" in HistoryScreen. Since no live connection exists, the app stores the pending revoke command in a local `pending_revokes` table: the file ID, the target device ID, the timestamp, and a `delivered` flag set to false. The revoke stays queued indefinitely.

The delivery moment comes the next time the two devices come within Bluetooth range of each other — in a hallway, a meeting, riding the same bus. ShareNova runs a background Bluetooth service that continuously scans for previously-known device fingerprints. The instant the receiver's phone is detected nearby, the pending revoke packet delivers automatically and silently, the receiver's file is deleted, and the sender's `pending_revokes` record marks `delivered = true`. Neither user has to do anything.

When online mode is enabled (Firebase), this queued revoke is also uploaded to Firestore so delivery happens the next time the receiver's phone opens the app with internet — whichever comes first, physical proximity or internet reconnection.

---

### 2.4 Team workspace with offline permissions

The Team Workspace (your WorkspaceScreen) is a persistent shared file pool that survives across sessions and works without any central server, governed by cryptographic role certificates.

#### Creating a room

The Admin (you, Sanjay) taps "Create room" in WorkspaceScreen. The app generates a room ID from a hash of your device ID and the current timestamp — this is unique and reproducible but never needs a server to validate. A QR code is generated encoding the room ID plus your device's Wi-Fi Direct service UUID and your room public key. This QR code is everything another device needs to join.

The room exists at this point as a single SQLite record on your phone. No cloud, no registration, no API call.

#### Joining process — the live handshake

Rithikaa opens ShareNova, taps "Join room," and scans your QR code. Her phone uses the embedded service UUID to discover your phone over Wi-Fi Direct and opens a socket connection. Her phone sends its own public identity key across this connection. Your phone receives it and shows a join approval dialog on your screen: "Rithikaa wants to join as Editor — Approve?"

When you tap Approve, your phone uses your room's private key (the other half of the room keypair you created when making the room) to sign a certificate for Rithikaa. This certificate is a small data packet containing her device ID, the role you assigned (EDITOR), the room ID, and a timestamp — all signed with your room private key. This signed certificate is sent back to her phone over the same socket and stored in her local database.

From this point, Rithikaa's phone can prove her role to anyone in the room without asking you or any server. She presents the signed certificate and any room member can verify it using the room's public key, which was embedded in the original QR code every member scanned.

#### File pool and mirroring

When Rithikaa uploads a file to the room, her phone does not send it to a server. Instead, it marks the file as belonging to the room in her local database and starts Wi-Fi Direct broadcasting. Any other room member's phone currently nearby automatically detects the new room file (through a continuous room-scoped listener running on the local network) and pulls it. The file now exists on two devices. If Nithya also happens to be nearby, she pulls it too — three devices now hold the file.

This mirroring is why the pool "survives" even if one device is wiped or goes offline permanently. The files exist on every device that was present during a sync.

#### Offline permission enforcement

Before any action (upload, delete, download), the requesting device's app checks the stored certificate locally:

- **Upload** — checks if the device's certificate says EDITOR or ADMIN. If VIEWER, the upload button is disabled and no transfer is attempted.
- **Delete** — checks if ADMIN (can delete anything) or EDITOR (can delete only files where `uploadedBy == myDeviceId`). Viewers see no delete option at all.
- **Role change** — only the ADMIN certificate can sign new certificates. If Rithikaa tried to sign a certificate for a new member, other devices would reject it because the signature would not match the room's public key.

Every action gets written to a local audit log table: actor device ID, action type, file ID, timestamp. This log is the foundation for the cloud audit backup described in the online section.

---

### 2.5 Passcode-protected file transfer

This feature adds a second encryption layer on top of the standard ECDH transfer, controlled by a human-memorable code that the sender communicates to the receiver through a completely separate channel (phone call, in person, WhatsApp message — anything outside ShareNova).

#### How the passcode becomes part of the encryption key

Before sending, if the sender enables passcode protection, they enter a 6-digit code. The app runs this code through PBKDF2 (Password-Based Key Derivation Function 2) with:

- A random 16-byte salt generated fresh for this specific file (using `SecureRandom`)
- 100,000 iterations (this makes brute-force guessing computationally slow — testing all 1 million possible 6-digit codes would take significant time even on dedicated hardware)
- Output: a 256-bit derived key

This derived key is then XOR-combined with the ECDH session key to produce the final composite encryption key. The file is encrypted using this composite key, not just the ECDH key alone.

The salt is stored in plaintext in the file's metadata (storing the salt publicly is safe — its purpose is to prevent precomputed rainbow table attacks, it provides no value to an attacker without the passcode itself). The passcode itself is never stored anywhere on either device, never transmitted, and never goes near Firebase.

#### What the receiver experiences

The receiving app detects the `passcodeProtected: true` flag in the file metadata before downloading the content. Instead of auto-decrypting, it shows a lock screen prompting "Enter the code sent by [sender name]." Once the receiver types in the 6-digit code, the app:

1. Retrieves the stored salt from metadata
2. Runs PBKDF2 with the entered code and the salt
3. XOR-combines the result with the ECDH session key
4. Attempts AES-256-GCM decryption

If the code is correct, the authentication tag matches and the file decrypts cleanly. If the code is wrong, AES-GCM's authentication tag does not match and decryption throws an explicit error — there is no ambiguous partial result. The app increments a local `failedAttempts` counter. After 5 failed attempts, the app wipes the downloaded encrypted blob and writes a tombstone record. The file is gone from the receiver's device.

#### Why this is stronger than a ZIP password

A ZIP password protects a file that already exists in decrypted form on the server or transfer channel. Anyone who intercepts the ZIP file can attempt to crack the password offline at their leisure. In ShareNova's model, the passcode is mathematically baked into the encryption key. Without the correct passcode, the encrypted bytes are computationally indistinguishable from random noise — there is no "file structure" to identify or crack against. The protection is inside the cryptography, not a gate in front of it.

---

### 2.6 Auto-sync rules (offline scheduled transfers)

Auto-sync lets you define conditions under which your phone automatically pushes new files to trusted paired devices without you doing anything manually.

#### Device pairing

Two devices pair once by going through a shortened version of the room-join handshake — QR scan, live key exchange, mutual confirmation. After pairing, each device stores the other's Wi-Fi Direct service UUID and public identity key in a `trusted_devices` table. The pairing is remembered permanently until explicitly removed.

#### Rule definition

The user defines a sync rule in AutoSyncScreen with three components:

- **What to sync** — a specific folder path (e.g., Camera, Downloads, a named project folder)
- **When to trigger** — time-based (every night at 11 PM), network-based (whenever connected to "Home WiFi" SSID), battery-based (only when charging), location-based (when near a paired device)
- **Where to send** — one or more paired devices from the trusted list

These rules are stored locally as rows in a `sync_rules` table. No server is involved.

#### How triggers fire

Android's WorkManager handles time-based and periodic triggers natively — you schedule a `PeriodicWorkRequest` set to check conditions at the defined interval. For Wi-Fi SSID triggers, a `BroadcastReceiver` listens for `WIFI_STATE_CHANGED` broadcasts and checks the connected network name against your rule's target SSID. For proximity triggers, the background Bluetooth scanner that already runs for pending revoke delivery also doubles as the proximity detector for auto-sync — when a trusted device appears in Bluetooth range, any pending auto-sync rules targeting that device can fire.

#### Delta sync — why it doesn't resend everything

When a trigger fires, the app does not blindly resend the entire folder. Instead it computes an MD5 hash of every file in the source folder and compares against a `last_sync_hashes` table that stores the hashes from the previous successful sync. Only files where the current hash differs from the stored hash (new files or modified files) are queued for transfer. After a successful sync, the hash table updates. This means a folder with 500 photos where only 3 are new sends only 3 files, not 500.

---

### 2.7 Transfer analytics (local)

The AnalyticsScreen displays data collected entirely from a local `transfer_log` SQLite table. Every completed transfer writes one row containing: file name, file size in bytes, direction (sent/received), channel used (Wi-Fi Direct / Bluetooth), transfer speed in Mbps computed from size divided by duration, start and end timestamps, whether encryption was applied, and whether a passcode was used.

The dashboard metrics (total files this week, total data moved, average speed, top channel) are simple SQL aggregate queries over this table. There is no network request involved in loading the AnalyticsScreen. CSV export is a straightforward cursor-to-file write.

---

## 3. Online Mode — Firebase Cloud Layer

### 3.1 Firebase project structure

Enable four Firebase services in your project console: **Authentication**, **Firestore**, **Storage**, and **Cloud Messaging**. Realtime Database is not needed — Firestore handles everything more efficiently for this use case.

#### Firestore collection structure

```
/users/{deviceId}
    displayName        (string)
    publicKey          (string — ECDH public key, base64)
    fcmToken           (string — push notification token)
    createdAt          (timestamp)

/rooms/{roomId}
    name               (string)
    adminDeviceId      (string)
    createdAt          (timestamp)
    /members/{deviceId}
        role           (string — ADMIN / EDITOR / VIEWER)
        joinedAt       (timestamp)
        certificate    (string — base64 signed role token)

/files/{fileId}
    roomId             (string — null for direct transfers)
    recipientDeviceId  (string — null for room files)
    uploadedBy         (string — device ID)
    fileName           (string)
    sizeBytes          (number)
    storageRef         (string — path in Firebase Storage)
    encryptedKeyBlob   (string — AES key wrapped with recipient public key)
    expiryTimestamp    (timestamp — null if no expiry)
    maxViews           (number — null if no limit)
    viewCount          (number)
    deleted            (boolean)
    passcodeProtected  (boolean)
    saltHex            (string — PBKDF2 salt if passcode protected)
    createdAt          (timestamp)
    synced             (boolean)

/weblinks/{linkId}
    fileId             (string)
    expiresAt          (timestamp)
    maxClicks          (number)
    clickCount         (number)
    revoked            (boolean)
    createdAt          (timestamp)

/auditlog/{roomId}/entries/{entryId}
    action             (string — UPLOAD / DELETE / REVOKE / ROLE_CHANGE / VIEW)
    actorDeviceId      (string)
    fileId             (string)
    timestamp          (timestamp)
    synced             (boolean)

/pending_revokes/{fileId}
    targetDeviceId     (string)
    revokedBy          (string)
    revokedAt          (timestamp)
    delivered          (boolean)
```

#### Firebase Storage folder structure

```
/transfers/{senderId}/{fileId}/
    chunk_000
    chunk_001
    chunk_002
    ...
    metadata.enc       (encrypted expiry rules and file info)

/weblinks/{linkId}/
    payload.enc        (encrypted file blob for browser download)
```

---

### 3.2 Hybrid sync — offline default, cloud fallback

This is the core feature that bridges offline and online without changing your app's behavior for users who are near each other.

#### Decision logic — how the app picks a path

Every time the user initiates a send, the app runs a quick path-selection check before doing anything:

1. Is any recipient device reachable over Wi-Fi Direct right now? → **Use offline P2P transfer.** Nothing touches Firebase. Transfer completes, a minimal log record is written to Firestore afterward (just the metadata, not the file bytes) for audit purposes.
2. Is the recipient device not reachable locally, but the sender has internet? → **Use Firebase Storage relay.** The file is encrypted on-device exactly as in the offline flow (same ECDH + AES-256-GCM pipeline), then uploaded chunk by chunk to Firebase Storage.
3. Is the recipient unreachable and there is no internet? → **Queue for later.** The file and its intended recipient are stored in a local `pending_sends` table. The app retries using option 1 or 2 as soon as either becomes available.

#### Uploading to Firebase Storage (online path)

Chunks are uploaded using Firebase Storage's resumable upload protocol, which Firebase enables by default for files over 5 MB. If the mobile connection drops mid-upload, the upload resumes from the last successfully uploaded chunk when connectivity returns — the sender does not restart from zero. This is critical for large files over mobile data.

Each chunk's Storage path is `transfers/{senderId}/{fileId}/chunk_{index}`. After all chunks land, the `/files/{fileId}` Firestore document is created with the `storageRef` pointing to the Storage folder, `synced: false`, and the `recipientDeviceId` set to the intended receiver.

#### Downloading on the receiver's side

The receiver's app maintains a persistent Firestore listener: `db.collection('files').where('recipientDeviceId', '==', myDeviceId).where('synced', '==', false)`. This listener fires automatically the instant a new file document appears matching this query. The app downloads each chunk from Storage, decrypts in memory, writes plaintext to local storage, and updates `synced: true` on the Firestore document. If the download is interrupted, the receiver resumes from the last verified chunk using the same resumable protocol.

#### Key design guarantee

The relay server (Firebase) holds only encrypted blobs. The AES session key used to encrypt the chunks was derived from the ECDH handshake and exists only on the two endpoint devices. Firebase cannot decrypt the content even with full administrative access to the Storage bucket.

---

### 3.3 Long-distance room sync

The WorkspaceScreen room works across any distance when members have internet, without changing the role enforcement model.

When a room member uploads a file, their phone creates the same signed file document it always did (file ID, uploader certificate, encrypted blob) and writes it to Firestore under `/files/{fileId}` with the `roomId` set. Every other member's phone maintains a Firestore listener scoped to their rooms: `db.collection('files').where('roomId', '==', currentRoomId).where('deleted', '==', false)`.

Firestore's snapshot listener fires on every other member's phone the instant the new document appears — regardless of city, country, or time zone. The receiver's app downloads the encrypted blob from Storage and verifies the uploader's certificate before accepting the file, using the exact same certificate-checking logic as the offline system. The certificate was signed by the Admin's room private key during the original join handshake, and every member has the room public key, so verification works without any server confirmation.

Role enforcement in the cloud is enforced by Firestore Security Rules (server-side, not just app-side). A rule on the `/files` collection requires that any write operation comes from an authenticated device whose room member record shows role EDITOR or ADMIN. This means even if someone decompiled your APK and tried to write directly to Firestore bypassing your app's checks, the server rejects the write.

---

### 3.4 Shareable web links

The WebShareScreen generates a link that anyone can open in a browser without installing ShareNova.

#### Generation flow

The user taps "Generate Link" in WebShareScreen. The app calls a Firebase Cloud Function rather than writing directly to Firestore. The Cloud Function performs three steps the app cannot safely do itself:

- **Verifies ownership** — checks that the caller's Firebase Auth token matches the `uploadedBy` field of the requested file
- **Generates a cryptographically random link ID** — 32 random bytes encoded as a URL-safe base64 string, unpredictable and not sequentially guessable
- **Creates the web link record** — writes to `/weblinks/{linkId}` with expiry rules, then returns the final URL to the app

The URL format is: `sharenova.web.app/get/{linkId}#{decryptionKeyFragment}`

The portion after `#` (the fragment) contains the decryption key. Browser standards specify that the URL fragment is **never sent to the server** in HTTP requests — it exists only in the browser's memory. This is not a workaround; it is a fundamental property of the HTTP protocol. The Firebase server receives requests for `/get/{linkId}` but never sees the key fragment, so it genuinely cannot decrypt the file content even with full server access.

#### Browser download page

When someone opens the link in any browser, Firebase Hosting serves a small standalone HTML page (separate from the ShareNova app, no install required) that:

1. Reads the `linkId` from the URL path
2. Calls a Cloud Function to verify the link is still valid (not expired, not revoked, not over click limit)
3. If valid, receives the encrypted blob URL from Firebase Storage
4. Downloads the encrypted blob directly in the browser using the Fetch API
5. Extracts the decryption key from the URL fragment (browser-side only, never sent anywhere)
6. Decrypts using the browser's native Web Crypto API
7. Offers the plaintext file as a browser download

The same expiry rules from your offline feature apply: the Cloud Function increments `clickCount` and refuses to serve the blob if `clickCount >= maxClicks` or `currentTime > expiresAt` or `revoked == true`.

---

### 3.5 Push notifications

Firebase Cloud Messaging (FCM) powers all real-time notifications across the app — new file alerts, read receipts, expiry warnings, revoke confirmations, and room join requests.

#### FCM token management

On first launch, after Firebase Auth completes, the app calls `FirebaseMessaging.getInstance().getToken()` and writes the returned token to `/users/{deviceId}/fcmToken`. FCM tokens periodically rotate (Firebase refreshes them for security). Your app listens for `onNewToken` callbacks and updates Firestore whenever the token changes, so notifications always reach the current token.

#### Notification triggers — all run as Cloud Functions

**New file in room** — a Firestore `onCreate` trigger fires whenever a new document appears in `/files`. The Cloud Function reads `roomId`, queries `/rooms/{roomId}/members` to get all member device IDs, fetches each member's FCM token from `/users`, and sends a multicast FCM push to all of them. The notification shows the file name, room name, and sender display name.

**Read receipt** — a Firestore `onUpdate` trigger fires when a file document's `viewCount` field increments. The Cloud Function sends a notification to the `uploadedBy` device: "Rithikaa opened [filename]."

**Expiry warning** — a Firebase Scheduled Cloud Function runs every 30 minutes. It queries all files where `expiryTimestamp` is between now and now-plus-one-hour, and sends a notification to the relevant `recipientDeviceId`: "Your file [filename] expires in less than 1 hour."

**Remote revoke delivered** — when a sender writes `deleted: true` to a file document, an `onUpdate` trigger notifies the `recipientDeviceId` that their file has been remotely wiped, and notifies the `uploadedBy` device confirming delivery.

**Room join request** — when a new pending join document is created, the Admin's device receives a notification: "Rithikaa wants to join [room name] — tap to approve."

---

### 3.6 Cloud audit log backup

Every local audit log entry written to SQLite during offline operations is eventually synced to Firestore at `/auditlog/{roomId}/entries/{entryId}` when internet becomes available. A background WorkManager task (periodic, once per hour) reads all local audit entries where `synced = false`, batch-writes them to Firestore, and marks them `synced = true` locally.

This enables two capabilities the offline-only system cannot offer:

- **Device recovery** — if a member's phone is lost or factory reset, they can reinstall ShareNova, rejoin the room, and see the full room history reconstructed from the cloud log
- **Cross-device history** — the HistoryScreen can optionally show events from other members' perspectives, not just actions taken on the current device

The audit log entries are written with the actor's device ID and timestamp, but do not contain file content. They are safe to store in Firestore in plaintext because they are metadata only — who did what, when, to which file ID.

---

### 3.7 AI-powered features (online only)

These features require a model inference service and cannot run offline.

**Smart file search in WorkspaceScreen** — instead of scrolling through a list to find "the PDF Rithikaa sent last Tuesday," the user types a natural-language query. The search runs against a Firebase Extension (Firestore Search powered by Algolia or a Cloud Function calling a language model) that indexes file names, uploader names, and timestamps. The query "find the slides from last week" resolves to files matching type:presentation, createdAt in last 7 days.

**Auto-summarize** — when a PDF or text document lands in a room, a Cloud Function trigger calls a language model API with the document's text content (extracted server-side from the decrypted blob) and writes a one-sentence summary back to the file's Firestore document. WorkspaceScreen displays this summary as a subtitle under the file name, so room members can see what a file contains before downloading it.

**Auto-tagging** — the same Cloud Function pipeline classifies files by content type (code, slides, dataset, report, image, video) and writes tags to the Firestore document. WorkspaceScreen can then filter the pool by tag, making large rooms navigable.

---

## 4. Security Model — Offline vs Online

| Threat | Offline protection | Online (Firebase) protection |
|---|---|---|
| Transfer interception | AES-256-GCM, ECDH-derived key never transmitted | Same encryption; relay holds encrypted blobs only |
| Unauthorized room upload | RSA-signed certificate verified by every device | Firestore Security Rules enforce role on server |
| Expired file access after deadline | WorkManager deletes on-device | Cloud Function deletes from Storage |
| Passcode brute-force | 5-attempt limit, then local wipe | Same limit enforced app-side; PBKDF2 slows offline cracking |
| Link interception | Key in URL fragment, never sent to server | Web Crypto API decrypts in browser only |
| Server-side data breach | Not applicable (no server) | Firebase holds only ciphertext; key never stored |

---

## 5. Screen-by-Screen Firebase Mapping

| ShareNova Screen | Firebase service used | What it does |
|---|---|---|
| HomeScreen (Send button) | Auth + Storage + Firestore | Path selection: P2P if nearby, Storage upload if not |
| TransferProgressScreen | Storage upload progress listener | Progress bar maps to chunk upload percentage |
| DeviceDiscoveryScreen | Firestore `/users` | Fetches display names and public keys for nearby devices identified by Wi-Fi Direct |
| WorkspaceScreen | Firestore `/rooms` + `/files` realtime listener | Room file pool updates live; role checked against member document |
| HistoryScreen | Firestore `/files` + `/auditlog` | Full transfer history including cloud-synced events |
| WebShareScreen | Cloud Functions | Generates signed random link; Cloud Function enforces ownership |
| AnalyticsScreen | Local SQLite only | No Firebase; all data is local transfer log |
| AutoSyncScreen | Firestore `/sync_rules` (backup) | Rules stored locally + cloud backup for cross-device restore |
| ChatListScreen | Firestore `/messages` (optional) | If chat messages are stored: real-time listener for new messages |
| ProfileScreen | Firestore `/users/{deviceId}` | Reads and writes display name, FCM token refresh |
| SettingsScreen | Firestore `/users/{deviceId}` | Saves notification preferences |

---

## 6. Build Order — What to Build First

Build in this sequence to always have a working, demonstrable app at every stage.

### Phase 1 — Offline core (Week 1–2)

1. Firebase Auth (anonymous — just establishes device identity with no email required)
2. Firestore `/users` collection — store device ID, display name, public key
3. SQLite schema — `file_expiry`, `transfer_log`, `trusted_devices`, `sync_rules`, `pending_revokes`, `audit_log`
4. ECDH handshake + AES-256-GCM transfer pipeline over Wi-Fi Direct socket
5. WorkManager for background expiry checks

At the end of Phase 1: fully working offline send and receive with encryption and expiry.

### Phase 2 — Cloud relay (Week 3)

6. Firebase Storage chunk upload/download pipeline
7. Firestore `/files` collection + path-selection logic (P2P vs Storage)
8. Firestore `/rooms` and `/members` — room creation and member join
9. Firestore Security Rules for role enforcement

At the end of Phase 2: transfers work across any distance; rooms sync across cities.

### Phase 3 — Notifications and links (Week 4)

10. FCM token setup and Firestore token storage
11. Cloud Functions — file upload trigger → multicast notification
12. Cloud Functions — read receipt trigger → sender notification
13. Cloud Functions — scheduled expiry warning
14. Shareable web link generation Cloud Function
15. Firebase Hosting web page for browser-based file receive

At the end of Phase 3: complete feature set working end to end.

### Phase 4 — Polish (Week 5)

16. Audit log cloud sync (batch WorkManager write to Firestore)
17. Auto-summarize Cloud Function (optional, requires external model API)
18. Transfer analytics chart enhancements in AnalyticsScreen
19. Passcode protection UI flow and PBKDF2 integration

---

*Document generated for ShareNova — P2P Encrypted File Sharing App*
*Sanjay K · Department of Information Technology · St. Joseph's College of Engineering*
