DROP DATABASE IF EXISTS NUSUK_Database;
CREATE DATABASE NUSUK_Database;
USE NUSUK_Database;

--===================<NATIONALITIES>===================

CREATE TABLE nationalities (
    nationality_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE,
    iso_code CHAR(3) NOT NULL UNIQUE,-- country's unique name in abbrivated form    
    region VARCHAR(50),
    language_preference VARCHAR(50),
    CONSTRAINT ck_country_name CHECK (country_name IS NOT NULL AND country_name != ''),
    CONSTRAINT ck_iso_code CHECK (iso_code IS NOT NULL AND LENGTH(iso_code) = 3)
);

--===================<HOLY SIES>===================

CREATE TABLE holy_sites (
    site_id INT AUTO_INCREMENT PRIMARY KEY,    
    site_name VARCHAR(100) NOT NULL,
    city ENUM('Makkah', 'Madinah') NOT NULL,
    description VARCHAR(255),
    prayer_times_applicable BOOLEAN DEFAULT TRUE,
    CONSTRAINT ck_site_name CHECK (site_name IS NOT NULL AND site_name != '')
);

--===================<HOTELS>===================

CREATE TABLE hotels (
    hotel_id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_name VARCHAR(100) NOT NULL UNIQUE,
    location_area VARCHAR(100) NOT NULL,
    star_rating INT NOT NULL,
    contact_number VARCHAR(20),
    email VARCHAR(100),
    total_rooms INT,
    address TEXT,
    CONSTRAINT ck_star_rating CHECK (star_rating BETWEEN 3 AND 5),
    CONSTRAINT ck_contact CHECK (contact_number IS NOT NULL OR email IS NOT NULL)
);


--===================<TRANSPORT PROVIDERS>===================


CREATE TABLE transport_providers (
    provider_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL UNIQUE,
    contact_number VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    service_type ENUM('Bus', 'Train', 'Airport Transfer', 'Shuttle', 'Coach') NOT NULL,
    capacity INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT ck_transport_providers_capacity CHECK (capacity > 0),
    CONSTRAINT ck_provider_contact CHECK (email IS NOT NULL OR contact_number IS NOT NULL)
);

--===================<GUIDES>===================


CREATE TABLE guides (
    guide_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    nationality_id INT NOT NULL,
    license_number VARCHAR(30) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    languages VARCHAR(150) NOT NULL,

    is_active BOOLEAN DEFAULT TRUE,

    rating_average DECIMAL(3,2) DEFAULT 0.00,
    total_pilgrim_count INT DEFAULT 0,
    
    FOREIGN KEY (nationality_id) REFERENCES nationalities(nationality_id) ON DELETE RESTRICT,
    CONSTRAINT ck_license CHECK (license_number IS NOT NULL AND license_number != ''),
    CONSTRAINT ck_languages CHECK (languages IS NOT NULL AND CHAR_LENGTH(languages) > 0),
    CONSTRAINT ck_rating CHECK (rating_average BETWEEN 0 AND 5)
);

--===================<HAJJ PHASES>===================

CREATE TABLE hajj_phases (
    phase_id INT AUTO_INCREMENT PRIMARY KEY,
    phase_name VARCHAR(50) NOT NULL UNIQUE,
    phase_order INT NOT NULL UNIQUE, -- the order of hajj in these steps 1-4
    description VARCHAR(255),
    is_mandatory BOOLEAN DEFAULT TRUE,
    CONSTRAINT ck_phase_order CHECK (phase_order BETWEEN 1 AND 5)
);









--===================<TIME SLOTS>===================

CREATE TABLE time_slots (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    site_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    max_capacity INT NOT NULL,
    current_occupancy INT DEFAULT 0,
    is_open BOOLEAN DEFAULT TRUE,
    
    FOREIGN KEY (site_id) REFERENCES holy_sites(site_id) ON DELETE RESTRICT,

    CONSTRAINT ck_time_order CHECK (start_time < end_time),
    CONSTRAINT ck_time_slots_capacity CHECK (max_capacity > 0),
    CONSTRAINT ck_occupancy CHECK (current_occupancy >= 0 AND current_occupancy <= max_capacity),
    UNIQUE KEY uk_site_time (site_id, start_time)
);

--===================<PILGIRMS>===================


CREATE TABLE pilgrims (
    pilgrim_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    passport_number VARCHAR(20) NOT NULL UNIQUE,
    nationality_id INT NOT NULL,
    date_of_birth DATE NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(20),
    registration_status ENUM('Pending', 'Active', 'Suspended', 'Banned') DEFAULT 'Pending',
    
    FOREIGN KEY (nationality_id) REFERENCES nationalities(nationality_id) ON DELETE RESTRICT,

    CONSTRAINT ck_pilgrims_name CHECK (first_name IS NOT NULL AND first_name != ''),
    CONSTRAINT ck_pilgrims_email CHECK (email LIKE '%@%.%')
);


--===================<PERMITS>===================


CREATE TABLE permits (
    permit_id INT AUTO_INCREMENT PRIMARY KEY,
    pilgrim_id INT NOT NULL,
    slot_id INT NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    status ENUM('Active', 'Used', 'Expired', 'Cancelled') DEFAULT 'Active',
    permit_type ENUM('Umrah', 'Hajj', 'Prayer') NOT NULL,
    FOREIGN KEY (pilgrim_id) REFERENCES pilgrims(pilgrim_id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES time_slots(slot_id) ON DELETE RESTRICT,
    CONSTRAINT ck_permit_dates CHECK (issue_date <= expiry_date),
    UNIQUE KEY uk_pilgrim_slot (pilgrim_id, slot_id, issue_date)
);

--===================<HEATH RECORDS>===================


CREATE TABLE health_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    pilgrim_id INT NOT NULL,
    vaccination_type VARCHAR(50) NOT NULL,
    vaccination_date DATE NOT NULL,
    expiry_date DATE,
    verification_status ENUM('Verified', 'Pending', 'Rejected') DEFAULT 'Pending',
    FOREIGN KEY (pilgrim_id) REFERENCES pilgrims(pilgrim_id) ON DELETE CASCADE,    
    CONSTRAINT ck_vacc_dates CHECK (vaccination_date <= expiry_date OR expiry_date IS NULL)
);

--===================<VISAS>===================


CREATE TABLE visas (
    visa_id INT AUTO_INCREMENT PRIMARY KEY,
    pilgrim_id INT NOT NULL,
    visa_number VARCHAR(50) NOT NULL UNIQUE,
    visa_type ENUM('Umrah', 'Hajj', 'Tourist') NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,    
    FOREIGN KEY (pilgrim_id) REFERENCES pilgrims(pilgrim_id) ON DELETE CASCADE,
    CONSTRAINT ck_visa_dates CHECK (issue_date <= expiry_date)
);

--===================<PILGRIM GROPUS>===================

CREATE TABLE pilgrim_groups (
    group_id INT AUTO_INCREMENT PRIMARY KEY,
    group_name VARCHAR(100) NOT NULL,
    guide_id INT, -- the guide alloted
    organization_name VARCHAR(100),
    group_type ENUM('Umrah', 'Hajj', 'Mixed') NOT NULL,
    total_pilgrims INT NOT NULL,
    created_date DATE NOT NULL,
    departure_date DATE,
    return_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    group_discount_percentage INT DEFAULT 0,
    FOREIGN KEY (guide_id) REFERENCES guides(guide_id) ON DELETE SET NULL,
    CONSTRAINT ck_total_pilgrims CHECK (total_pilgrims > 0),
    CONSTRAINT ck_pilgrim_groups_dates CHECK (departure_date IS NULL OR return_date IS NULL OR departure_date < return_date),
    CONSTRAINT ck_pilgrim_groups_discount CHECK (group_discount_percentage BETWEEN 0 AND 100)
);

--===================<SPECIAL NEEDS>===================

CREATE TABLE special_needs (
    need_id INT AUTO_INCREMENT PRIMARY KEY,
    pilgrim_id INT NOT NULL,
    need_type ENUM('Wheelchair', 'Mobility_Aid', 'Dietary', 'Medical', 'Language', 'Other') NOT NULL,
    description VARCHAR(255) NOT NULL,
    severity ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    FOREIGN KEY (pilgrim_id) REFERENCES pilgrims(pilgrim_id) ON DELETE CASCADE,
    
    CONSTRAINT ck_need_desc CHECK (description IS NOT NULL AND description != '')
);


--===================<BOOKINGS>===================


CREATE TABLE bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    pilgrim_id INT NOT NULL,
    group_id INT,
    booking_reference VARCHAR(20) NOT NULL UNIQUE,-- sirf confirmation number hai jo user ko show ho ga reference k liay
    total_price DECIMAL(10,2) NOT NULL,
    booking_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    start_date DATE NOT NULL,-- arrival 
    end_date DATE NOT NULL,-- departure
    status ENUM('Pending', 'Confirmed', 'Paid', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Pending',
    
    FOREIGN KEY (pilgrim_id) REFERENCES pilgrims(pilgrim_id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES pilgrim_groups(group_id) ON DELETE SET NULL,
    
    CONSTRAINT ck_bookings_price CHECK (total_price > 0),
    CONSTRAINT ck_booking_dates CHECK (start_date <= end_date),
    CONSTRAINT ck_booking_date_logic CHECK (booking_date <= start_date),
    UNIQUE KEY uk_pilgrim_date (pilgrim_id, start_date)
);

--===================<BOOKING DETAIL>===================


CREATE TABLE booking_details (
    detail_id INT AUTO_INCREMENT PRIMARY KEY,
    service_type ENUM('Hotel', 'Transport', 'Guide', 'Meal_Plan', 'Insurance', 'Activity') NOT NULL,
    status ENUM('Active', 'Cancelled', 'Refunded') DEFAULT 'Active',

    booking_id INT NOT NULL,
    hotel_id INT,
    provider_id INT,
    guide_id INT,

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    quantity INT DEFAULT 1,-- total quantity like how many hotel nights
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,-- different datatype cuz ta ky auto calculate ho jaye

    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id) ON DELETE SET NULL,
    FOREIGN KEY (provider_id) REFERENCES transport_providers(provider_id) ON DELETE SET NULL,
    FOREIGN KEY (guide_id) REFERENCES guides(guide_id) ON DELETE SET NULL,
    
    CONSTRAINT ck_booking_details_dates CHECK (start_date <= end_date),
    CONSTRAINT ck_booking_details_quantity CHECK (quantity > 0),
    CONSTRAINT ck_booking_details_price CHECK (unit_price > 0)
);

--===================<PAYMENTS>===================


CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    transaction_ref VARCHAR(100) NOT NULL UNIQUE,
    payment_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    method ENUM('Credit_Card', 'Debit_Card', 'Bank_Transfer', 'Mobile_Wallet', 'Cash') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed', 'Refunded') DEFAULT 'Pending',
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    CONSTRAINT ck_payments_amount CHECK (amount > 0)
);


--===================<PAYMENT ITEMS>===================


CREATE TABLE payment_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    item_type ENUM('Hotel', 'Transport', 'Permit', 'Guide', 'Meal', 'Insurance', 'Service_Fee', 'Discount') NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    hotel_id INT,
    provider_id INT,
    guide_id INT,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    discount_percentage INT DEFAULT 0,
    final_price DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price * (1 - discount_percentage/100)) STORED,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id) ON DELETE SET NULL,
    FOREIGN KEY (provider_id) REFERENCES transport_providers(provider_id) ON DELETE SET NULL,
    FOREIGN KEY (guide_id) REFERENCES guides(guide_id) ON DELETE SET NULL,
    
    CONSTRAINT ck_item_quantity CHECK (quantity > 0),
    CONSTRAINT ck_item_price CHECK (unit_price > 0),
    CONSTRAINT ck_item_discount CHECK (discount_percentage BETWEEN 0 AND 100)
);

--===================<HAJJ PROGRESS>===================


CREATE TABLE hajj_progress (
    progress_id INT AUTO_INCREMENT PRIMARY KEY,
    pilgrim_id INT NOT NULL,
    phase_id INT NOT NULL,
    status ENUM('Scheduled', 'In_Progress', 'Completed', 'Skipped') DEFAULT 'Scheduled',
    started_at DATETIME,
    completed_at DATETIME,
    location VARCHAR(100),
    FOREIGN KEY (pilgrim_id) REFERENCES pilgrims(pilgrim_id) ON DELETE CASCADE,
    FOREIGN KEY (phase_id) REFERENCES hajj_phases(phase_id) ON DELETE RESTRICT,
    
    CONSTRAINT ck_phase_times CHECK (started_at IS NULL OR completed_at IS NULL OR started_at < completed_at),
    
    UNIQUE KEY uk_pilgrim_phase (pilgrim_id, phase_id)
);

SELECT USER();

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE permits;
TRUNCATE TABLE pilgrims;
TRUNCATE TABLE time_slots;
TRUNCATE TABLE guides;
TRUNCATE TABLE hajj_phases;
TRUNCATE TABLE holy_sites;
TRUNCATE TABLE transport_providers;
TRUNCATE TABLE hotels;
TRUNCATE TABLE nationalities;

-- 3. Turn the safety lock back on! (Crucial)
SET FOREIGN_KEY_CHECKS = 1;
