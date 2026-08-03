# MedInfo: An AI-Based Medicine Information and Ordering System 

A Flutter-based mobile application for medicine information and online medicine shopping, with an integrated AI chatbot for medicine-related queries.

## Overview

MedInfo BD helps users search for medicines, view detailed information, order medicines online, track dosage reminders, and get AI-assisted answers about medicines through **MedAI**, a built-in chatbot. The app supports bilingual (English/Bengali) content for medicine details and the MedAI chatbot, while the rest of the app UI remains in English.

## Features

- **Medicine Catalog** — Browse and search medicines with category filters, sourced from a Kaggle medicine dataset, backed by Firestore for real-time updates.
- **Medicine Details & Shopping Cart** — View detailed medicine information and add items to a cart with quantity controls.
- **Order Management** — Place orders, view order history, and track order details.
- **MedAI Chatbot** — AI-powered chatbot (powered by the Groq API) that answers medicine-related questions, with relevant-medicine pre-filtering and a Banglish symptom-keyword map to manage token usage.
- **Medicine Reminders** — Per-account dosage reminders with repeat types, weekday scheduling, and active/inactive toggling, using local notifications and exact-alarm scheduling.
- **User Profiles** — Medical profile fields including blood group, weight, height, health conditions, and emergency contact.
- **Notifications** — In-app notifications for order status (confirmed, placed, delivered), separate from medicine reminder notifications.
- **Health Tips** — Curated health tips within the app.
- **Medicine Reviews** — Users can leave reviews for medicines.
- **Admin Dashboard** — Overview statistics, medicine inventory management, order management, and user management (via a separate `AdminShell`).
- **Authentication** — Email/password and Google Sign-in via Firebase Authentication.
- **Dark Mode** — Time-based greetings and dark-mode toggle on the home screen.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| State Management | GetX |
| Backend / Auth | Firebase Authentication, Firebase Firestore |
| AI Chatbot | Groq API |
| Local Storage | SharedPreferences (per-account reminder data) |
| Notifications | Local notifications with exact alarm scheduling |
| Diagramming | PlantUML |
| Design | Figma (system architecture and app logo) |
| Data Source | Kaggle medicine dataset (`medicine.csv`) |
| Image Hosting | imgbb |

## App Structure

- `AppShell` (`_MainShell`) — Main bottom-navigation shell for regular users.
- `AdminShell` — Separate navigation shell for admin logins, defined in its own `admin_shell.dart` file.
- `AppController` — Central GetX controller managing app-wide reactive state, including the shopping cart (`RxList<Medicine> cart`).
- `MedicineService` — Firestore-backed CRUD stream service for medicine data.
- `OrderService` — Handles order creation, checkout, and order history.
- `ReminderService` — Manages dosage reminders with `init()`, `rescheduleAllOnLogin()`, and `cancelAllOnLogout()`.

## Design

The app follows a blue-to-teal gradient theme (`#3B82C4` → `#0F6E56`), matching the app logo. This theme is applied consistently across the hero search card, bottom navigation, drawer header, profile avatar, and authentication pages.

## Roadmap

- Enhanced notifications
- Branded icon for the MedAI chatbot
- Home page redesign
- Medicine image support improvements
- Cart quantity selection improvements
- Branded app bar

## Known Limitations

- The admin panel does not yet enforce role-based access control to block non-admin users from admin routes; it currently only allows admins to view the list of registered users.

## Getting Started

1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Configure Firebase for your project (Authentication and Firestore).
4. Add your Groq API key for the MedAI chatbot.
5. Run the app with `flutter run`.

## License

This project is developed for academic purposes as part of a Mobile Computing course project.