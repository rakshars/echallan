# CitiWatch (E-Challan Management System) 🚨📱

An advanced, highly-professional Flutter mobile application designed to empower citizens and streamline traffic violation policing. Built with a pristine white-themed modern UI, the app boasts **On-Device Artificial Intelligence** for automatic license plate reading and **Real-Time GPS Location** tracking.

## 🌟 Key Features

### 🔥 For Citizens
*   **Intelligent Reporting**: Report traffic violations instantly by uploading photo/video evidence.
*   **On-Device AI (ML Kit)**: Upload an image and the app automatically scans and extracts the vehicle's number plate using Google ML Kit Text Recognition (Optimized for Indian Registration plates).
*   **Live GPS Tracking**: Automatically fetches exact geospatial coordinates and reverse-geocodes them into a readable address before submission.
*   **Gamified Dashboard**: Track the real-time status (Pending, Approved, Rejected) of all your submitted reports on a beautifully designed, scrollable dashboard with an "Active Contributor" hero card.

### 👮 For Police Officers
*   **Command Center Dashboard**: A premium data-focused dashboard featuring "Live Intelligence" summary cards (Total, Pending, Approved, Rejected).
*   **Feed Filtering**: Segmented control tabs allow officers to quickly filter incident feeds by their status.
*   **Review & Moderation Workspace**: Officers can view all incident data natively within the app.
*   **Native Evidence Player**: Tap on a violation to reveal expandable accordions featuring high-quality image reviews and inline video playback with scrubbing capabilities.

### ⚙️ Core Technical Features
*   **Supabase Backend**: Fully integrated with Supabase PostgreSQL for Realtime Data and Supabase Storage for secure Image and Video handling.
*   **Role-Based Smart Routing**: The animated boot Splash Screen actively verifies Supabase tokens and automatically navigates the session to either the Citizen Dashboard or the Police Dashboard.
*   **Premium Visuals**: Makes heavy use of `Google Fonts (Poppins & Inter)`, soft drop shadows, sleek color gradients, and micro-animations via `flutter_animate` to ensure a "wow" factor upon every click.

---

## 🚀 How to Run & Set Up the Project

### 1. Prerequisites
*   Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (Version 3.19.0 or later recommended).
*   Have an active Android Studio / Xcode installation for building the app.
*   Create a Supabase project at [Supabase.com](https://supabase.com).

### 2. Configure Environment Variables
Inside the root folder of the project, create a new file named `.env`.

Populate your `.env` file with your precise Supabase project credentials:
```env
SUPABASE_URL=https://[YOUR_PROJECT_REF].supabase.co
SUPABASE_ANON_KEY=[YOUR_PROJECT_ANON_KEY]
```
*(Do not commit this file to public version control!)*

### 3. Install Dependencies
Run the following command in your terminal to fetch the required packages:
```bash
flutter pub get
```

### 4. Build and Run
Since the app heavily utilizes native device features (Camera, Geolocation, Video Player, and Google ML Kit Text Recognition Engine), we highly recommend testing this app on a **Real Physical Device** rather than a simulator for optimal performance.

To build and run:
```bash
flutter run
```

---

## 🏗️ Supabase Database Schema
If you are initializing the backend for the first time, you will need a `violations` table and a `reports_media` storage bucket.
Ensure your `violations` table has the following minimum columns:
*   `id` (uuid)
*   `user_id` (uuid)
*   `number_plate` (text)
*   `violation_types` (text[]) 
*   `location_text` (text)
*   `latitude` (double precision)
*   `longitude` (double precision)
*   `description` (text)
*   `image_path` (text)
*   `video_path` (text)
*   `status` (text) DEFAULT 'pending'
*   `created_at` (timestamp)

---
*Built with ❤️ for safer roads.*
