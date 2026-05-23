# NUSUK — Sacred Journey Management Platform

Full-stack Flask + MySQL web application for Hajj & Umrah management.
Gold × Black × White design, Islamic geometric aesthetic, light/dark mode.

---

## Prerequisites
- Python 3.9+
- MySQL 8.0+ with `NUSUK_Database` already created
  (run `01_schema.sql`, `02_reference_data.sql`, `03_client_data.sql` first)

---

## Setup

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Configure database (edit app.py or use env vars)
export DB_HOST=localhost
export DB_USER=root
export DB_PASSWORD=your_password

# 3. Run
python app.py
```

Open **http://localhost:5000**

---

## Default Accounts (auto-created on first run)

| Role     | Email                  | Password           |
|----------|------------------------|--------------------|
| Admin    | admin@nusuk.sa         | Admin@Nusuk2025    |
| Analyst  | analyst@nusuk.sa       | Analyst@Nusuk2025  |
| User     | register at /register  | your choice        |

---

## Roles & Permissions

### 🤲 User (Pilgrim)
- Register account (creates `user_accounts` + `pilgrims` records)
- View only their own profile, health records, visas, special needs
- Create bookings (hotel + transport + guide)
- Request entry permits for holy site time slots
- Rate hotels, transport, guides **after** booking is Completed

### 🛡️ Admin
- Full platform management
- Toggle / delete user accounts, change roles
- Update pilgrim registration status (Active / Suspended / Banned)
- Add new Guides (with license, languages, nationality)
- Add new Holy Sites (Makkah / Madinah)
- Update booking statuses (Pending → Confirmed → Paid → Completed)
- View all bookings and recent users

### 📊 Analyst (Read-Only)
- Revenue by payment method
- Bookings by status breakdown
- Top guides by rating
- Pilgrim nationality distribution
- Holy site occupancy percentages
- Permit type & status breakdown
- Hotel booking demand
- Pilgrim registration status overview

---

## Project Structure

```
nusuk/
├── app.py                   # Flask application & all routes
├── requirements.txt
├── templates/
│   ├── base.html            # Base layout (nav, flash, footer)
│   ├── index.html           # Landing page
│   ├── auth/
│   │   ├── login.html
│   │   └── register.html
│   ├── user/
│   │   ├── dashboard.html   # Quran verse + Adhan + Hajj progress
│   │   ├── profile.html
│   │   ├── bookings.html    # Book hotel/transport/guide + rate
│   │   └── permits.html     # Request & view permits
│   ├── admin/
│   │   ├── dashboard.html
│   │   ├── users.html       # Manage users (edit/delete/role)
│   │   ├── guides.html      # Add & manage guides
│   │   ├── sites.html       # Add & view holy sites
│   │   └── bookings.html    # Update booking statuses
│   └── analyst/
│       └── dashboard.html   # Read-only analytics
└── static/
    ├── css/style.css        # Full design system
    └── js/main.js           # Theme, Adhan calc, modals, charts
```

---

## DB Extension Tables (auto-created by `init_db()`)

```sql
-- Accounts for all roles (linked to pilgrims for users)
user_accounts (account_id, username, email, password_hash, role, pilgrim_id, is_active, created_at)

-- Service ratings after completed bookings
service_ratings (rating_id, pilgrim_id, booking_id, service_type, service_id, rating, comment)
```

---

## Features

- **Adhan Times** — Pure JS prayer time calculator (MWL method), no API needed.
  Shows times for user's GPS location, Makkah, and Madinah.
- **Quran Verse** — Authentic Hajj-related verses; refreshes on request.
- **Dark / Light Mode** — Persisted in localStorage.
- **Islamic Geometric Pattern** — SVG tile background at low opacity.
- **Transactions** — Permit issuance uses `FOR UPDATE` + commit/rollback.
- **Date Constraints** — Enforced at DB level and in Flask before insert.
- **Role Guards** — `@login_required` + `@role_required` decorators on every route.
