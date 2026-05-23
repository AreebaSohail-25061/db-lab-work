USE NUSUK_Database;


INSERT INTO nationalities (country_name, iso_code, region, language_preference) VALUES
('Saudi Arabia',      'SAU', 'Middle East',    'Arabic'),
('Pakistan',          'PAK', 'South Asia',     'Urdu'),
('India',             'IND', 'South Asia',     'Hindi'),
('Bangladesh',        'BGD', 'South Asia',     'Bengali'),
('Indonesia',         'IDN', 'Southeast Asia', 'Indonesian'),
('Malaysia',          'MYS', 'Southeast Asia', 'Malay'),
('Turkey',            'TUR', 'Europe/Asia',    'Turkish'),
('Egypt',             'EGY', 'North Africa',   'Arabic'),
('Nigeria',           'NGA', 'West Africa',    'English'),
('Senegal',           'SEN', 'West Africa',    'French'),
('Morocco',           'MAR', 'North Africa',   'Arabic'),
('United Kingdom',    'GBR', 'Europe',         'English'),
('United States',     'USA', 'North America',  'English'),
('Canada',            'CAN', 'North America',  'English'),
('France',            'FRA', 'Europe',         'French'),
('Germany',           'DEU', 'Europe',         'German'),
('Iran',              'IRN', 'Middle East',    'Farsi'),
('Afghanistan',       'AFG', 'Central Asia',   'Dari'),
('Somalia',           'SOM', 'East Africa',    'Somali'),
('Sudan',             'SDN', 'East Africa',    'Arabic');
 
 

-- ===================< HOLY SITES >=================== 
 
INSERT INTO holy_sites (site_name, city, description, prayer_times_applicable) VALUES
('Masjid al-Haram',         'Makkah',  'The Grand Mosque surrounding the Kaaba',                  TRUE),
('Kaaba',                   'Makkah',  'The cubic structure at the center of Masjid al-Haram',    TRUE),
('Zamzam Well',             'Makkah',  'Sacred well inside Masjid al-Haram complex',              FALSE),
('Mount Arafat',            'Makkah',  'The plain of Arafat where pilgrims gather on 9 Dhul Hijjah', FALSE),
('Muzdalifah',              'Makkah',  'Open area between Mina and Arafat',                       FALSE),
('Mina',                    'Makkah',  'Valley near Makkah where pilgrims stay during Hajj',      FALSE),
('Jamarat Bridge',          'Makkah',  'Site of the symbolic stoning of the devil',               FALSE),
('Cave of Hira',            'Makkah',  'Cave on Jabal al-Nour where first revelation descended',  FALSE),
('Cave of Thawr',           'Makkah',  'Cave on Mount Thawr used during the Hijra',               FALSE),
('Masjid al-Nabawi',        'Madinah', 'The Prophet\'s Mosque in Madinah',                        TRUE),
('Rawdah al-Sharif',        'Madinah', 'Garden between the Prophet\'s pulpit and tomb',           TRUE),
('Masjid Quba',             'Madinah', 'The first mosque built in Islam',                         TRUE);
 
 
-- ===================< HOTELS >=================== 
 
INSERT INTO hotels (hotel_name, location_area, star_rating, contact_number, email, total_rooms, address) VALUES
('Makkah Royal Clock Tower Hotel',  'Makkah – Ajyad',           5, '+966-12-5710000', 'reservations@clocktower.com.sa',   858, 'Ajyad Street, Makkah'),
('Swissôtel Al Maqam Makkah',       'Makkah – Abraj Al-Bait',   5, '+966-12-5710100', 'reservations@swissotel-makkah.com',  1496, 'Abraj Al-Bait Towers, Makkah'),
('Hilton Suites Makkah',            'Makkah – Ibrahim Al Khalil',5, '+966-12-5710200', 'makkah.hilton@hilton.com',          346, 'Ibrahim Al Khalil Road, Makkah'),
('Le Meridien Makkah',              'Makkah – Ajyad',           5, '+966-12-5710300', 'lemeridien.makkah@marriott.com',    479, 'Ajyad Street, Makkah'),
('Pullman ZamZam Makkah',           'Makkah – Abraj Al-Bait',   5, '+966-12-5710400', 'h7530@accor.com',                   1300, 'Abraj Al-Bait Complex, Makkah'),
('Dar Al Tawhid Intercontinental',  'Makkah – Al-Aziziyah',     5, '+966-12-5710500', 'makkah@ihg.com',                    802, 'Al-Aziziyah, Makkah'),
('Al Meroz Hotel Makkah',           'Makkah – Al-Nakkasah',     4, '+966-12-5710600', 'info@almeroz.com',                  450, 'Al-Nakkasah Street, Makkah'),
('Elaf Kinda Hotel',                'Makkah – Al-Abrar',        4, '+966-12-5710700', 'kinda@elafhotels.com',              620, 'Al-Abrar Street, Makkah'),
('Madinah Hilton Hotel',            'Madinah – Central Area',   5, '+966-14-8500100', 'madinah.hilton@hilton.com',         678, 'King Faisal Road, Madinah'),
('Anwar Al Madinah Mövenpick',      'Madinah – Al Haram',       5, '+966-14-8500200', 'anwar.madinah@movenpick.com',       700, 'Al-Masjid Al-Nabawi Street, Madinah'),
('Oberoi Madinah',                  'Madinah – Al Haram',       5, '+966-14-8500300', 'reservations.madinah@oberoihotels.com', 500, 'King Abdulaziz Road, Madinah'),
('Shaza Al Madinah Hotel',          'Madinah – Al Haram',       5, '+966-14-8500400', 'reservations@shazahotels.com',      307, 'Sultan Road, Madinah'),
('Al Eiman Royal Hotel',            'Madinah – Central Area',   4, '+966-14-8500500', 'info@aleiman.com',                  400, 'Central Madinah'),
('Madinah Marriott Hotel',          'Madinah – Al Haram',       5, '+966-14-8500600', 'madinah@marriott.com',              620, 'Syed Al-Shuhada Street, Madinah'),
('Al Haram Hotel Makkah',           'Makkah – Al Haram',        3, '+966-12-5710800', 'info@alharamhotel.com',             300, 'Al Haram District, Makkah');
 
 
-- ===================< TRANSPORT PROVIDERS >=================== 
 
INSERT INTO transport_providers (company_name, contact_number, email, service_type, capacity, is_active) VALUES
('Al Naqil Transport Co.',          '+966-12-6010001', 'info@alnaqil.com.sa',       'Bus',              55,  TRUE),
('Saptco Pilgrim Services',         '+966-12-6010002', 'pilgrim@saptco.com.sa',     'Coach',            60,  TRUE),
('Haramain High Speed Rail',        '+966-12-6010003', 'info@hhrsupport.com.sa',    'Train',           450,  TRUE),
('Al Mashair Al Mugaddassah Metro', '+966-12-6010004', 'metro@almashair.com.sa',    'Train',           300,  TRUE),
('Makkah Airport Shuttles',         '+966-12-6010005', 'reservations@mkshuttle.com','Airport Transfer', 20,  TRUE),
('Rafiq Hajj Transport',            '+966-12-6010006', 'info@rafiqhajj.com',        'Bus',              50,  TRUE),
('Taqdeer Coach Lines',             '+966-12-6010007', 'ops@taqdeercoach.com',       'Coach',            65,  TRUE),
('Zamzam Shuttle Services',         '+966-12-6010008', 'info@zamzamshuttles.com',   'Shuttle',          15,  TRUE),
('Baraka Bus Company',              '+966-12-6010009', 'info@barakabus.com',         'Bus',              50,  FALSE),
('Nour Transport LLC',              '+966-12-6010010', 'ops@nourtransport.com',      'Airport Transfer', 25,  TRUE),
('Al Azizia Coaches',               '+966-12-6010011', 'bookings@alazizia.com',      'Coach',            70,  TRUE),
('Safa Marwa Minibus Services',     '+966-12-6010012', 'info@safamarwa.com',         'Shuttle',          12,  TRUE);
 
 
-- ===================< GUIDES >=================== 
 
INSERT INTO guides (first_name, last_name, gender, nationality_id, license_number, phone_number, email, languages, is_active, rating_average, total_pilgrim_count) VALUES
('Ahmed',      'Al-Rashidi',  'Male',   1,  'SA-GD-10001', '+966-50-1010001', 'ahmed.alrashidi@nusuk.sa',   'Arabic, English',               TRUE,  4.85, 1200),
('Muhammad',   'Siddiqui',    'Male',   2,  'SA-GD-10002', '+966-50-1010002', 'muhammad.siddiqui@nusuk.sa', 'Urdu, English, Arabic',          TRUE,  4.72, 980),
('Fatima',     'Yilmaz',      'Female', 7,  'SA-GD-10003', '+966-50-1010003', 'fatima.yilmaz@nusuk.sa',     'Turkish, Arabic, English',       TRUE,  4.90, 1500),
('Hassan',     'Ibrahim',     'Male',   8,  'SA-GD-10004', '+966-50-1010004', 'hassan.ibrahim@nusuk.sa',    'Arabic, French',                 TRUE,  4.60, 750),
('Aisha',      'Rahman',      'Female', 3,  'SA-GD-10005', '+966-50-1010005', 'aisha.rahman@nusuk.sa',      'Hindi, Urdu, English',           TRUE,  4.78, 860),
('Omar',       'Farouq',      'Male',   1,  'SA-GD-10006', '+966-50-1010006', 'omar.farouq@nusuk.sa',       'Arabic, English, French',        TRUE,  4.55, 630),
('Khadijah',   'Abdulkarim',  'Female', 1,  'SA-GD-10007', '+966-50-1010007', 'khadijah.abdulkarim@nusuk.sa','Arabic, English',               TRUE,  4.80, 920),
('Yusuf',      'Malik',       'Male',   2,  'SA-GD-10008', '+966-50-1010008', 'yusuf.malik@nusuk.sa',       'Urdu, Punjabi, English',         TRUE,  4.65, 540),
('Bilal',      'Hossain',     'Male',   4,  'SA-GD-10009', '+966-50-1010009', 'bilal.hossain@nusuk.sa',     'Bengali, English, Arabic',       TRUE,  4.70, 610),
('Maryam',     'Nur',         'Female', 19, 'SA-GD-10010', '+966-50-1010010', 'maryam.nur@nusuk.sa',        'Somali, Arabic, English',        TRUE,  4.40, 320),
('Dawud',      'Setiawan',    'Male',   5,  'SA-GD-10011', '+966-50-1010011', 'dawud.setiawan@nusuk.sa',    'Indonesian, Malay, English',     TRUE,  4.68, 710),
('Zainab',     'Ould Ahmed',  'Female', 10, 'SA-GD-10012', '+966-50-1010012', 'zainab.ouldahmed@nusuk.sa',  'French, Arabic, Wolof',          TRUE,  4.50, 400),
('Abdullah',   'Kofi',        'Male',   9,  'SA-GD-10013', '+966-50-1010013', 'abdullah.kofi@nusuk.sa',     'English, Arabic, Hausa',         FALSE, 4.20, 280),
('Ruqayyah',   'Boukhari',    'Female', 11, 'SA-GD-10014', '+966-50-1010014', 'ruqayyah.boukhari@nusuk.sa', 'Arabic, French, Amazigh',        TRUE,  4.75, 830),
('Ibrahim',    'Karimi',      'Male',   17, 'SA-GD-10015', '+966-50-1010015', 'ibrahim.karimi@nusuk.sa',    'Farsi, Arabic, English',         TRUE,  4.55, 590);
 
 
-- ===================< HAJJ PHASES >=================== (5 rows)
 
INSERT INTO hajj_phases (phase_name, phase_order, description, is_mandatory) VALUES
('Ihram & Miqat',      1, 'Entering the state of Ihram at the Miqat boundary before proceeding to Makkah', TRUE),
('Tawaf & Sai',      2, 'Circumambulation of the Kaaba seven times and walking between Safa and Marwa',  TRUE),
('Wuquf at Arafat',    3, 'Standing at the plain of Arafat on 9th Dhul Hijjah — the pinnacle of Hajj',   TRUE),
('Muzdalifah & Mina',  4, 'Spending the night at Muzdalifah and performing symbolic stoning at Jamarat',   TRUE),
('Farewell Tawaf',     5, 'Final circumambulation of the Kaaba before departing Makkah',                   TRUE);
 
 
-- ===================< TIME SLOTS >=================== (30 rows)
 
INSERT INTO time_slots (site_id, start_time, end_time, max_capacity, current_occupancy, is_open) VALUES
-- Masjid al-Haram (site 1) — Umrah slots spread across the day
(1, '2025-01-15 00:00:00', '2025-01-15 02:00:00', 5000, 3200, TRUE),
(1, '2025-01-15 02:00:00', '2025-01-15 04:00:00', 5000, 1800, TRUE),
(1, '2025-01-15 04:00:00', '2025-01-15 06:00:00', 5000, 4500, TRUE),
(1, '2025-01-15 06:00:00', '2025-01-15 08:00:00', 5000, 5000, FALSE),
(1, '2025-01-15 08:00:00', '2025-01-15 10:00:00', 5000, 3100, TRUE),
(1, '2025-01-15 10:00:00', '2025-01-15 12:00:00', 5000, 2700, TRUE),
(1, '2025-01-15 12:00:00', '2025-01-15 14:00:00', 5000, 4200, TRUE),
(1, '2025-01-15 14:00:00', '2025-01-15 16:00:00', 5000, 3800, TRUE),
(1, '2025-01-15 16:00:00', '2025-01-15 18:00:00', 5000, 4800, TRUE),
(1, '2025-01-15 18:00:00', '2025-01-15 20:00:00', 5000, 5000, FALSE),
(1, '2025-01-15 20:00:00', '2025-01-15 22:00:00', 5000, 4100, TRUE),
(1, '2025-01-15 22:00:00', '2025-01-16 00:00:00', 5000, 2900, TRUE),
-- Mount Arafat (site 4) — Hajj slots
(4, '2025-06-06 08:00:00', '2025-06-06 12:00:00', 50000, 38000, TRUE),
(4, '2025-06-06 12:00:00', '2025-06-06 18:00:00', 50000, 50000, FALSE),
(4, '2025-06-06 18:00:00', '2025-06-06 22:00:00', 50000, 41000, TRUE),
-- Mina (site 6)
(6, '2025-06-07 06:00:00', '2025-06-07 12:00:00', 30000, 22000, TRUE),
(6, '2025-06-07 12:00:00', '2025-06-07 18:00:00', 30000, 28500, TRUE),
(6, '2025-06-07 18:00:00', '2025-06-08 06:00:00', 30000, 25000, TRUE),
-- Jamarat Bridge (site 7)
(7, '2025-06-08 08:00:00', '2025-06-08 10:00:00',  8000,  6500, TRUE),
(7, '2025-06-08 10:00:00', '2025-06-08 12:00:00',  8000,  8000, FALSE),
(7, '2025-06-08 12:00:00', '2025-06-08 14:00:00',  8000,  7200, TRUE),
-- Masjid al-Nabawi (site 10)
(10, '2025-01-16 06:00:00', '2025-01-16 08:00:00', 10000, 7800, TRUE),
(10, '2025-01-16 08:00:00', '2025-01-16 10:00:00', 10000, 9500, TRUE),
(10, '2025-01-16 12:00:00', '2025-01-16 14:00:00', 10000, 6200, TRUE),
(10, '2025-01-16 18:00:00', '2025-01-16 20:00:00', 10000, 9800, TRUE),
-- Rawdah al-Sharif (site 11)
(11, '2025-01-16 08:00:00', '2025-01-16 09:00:00',  2000,  2000, FALSE),
(11, '2025-01-16 09:00:00', '2025-01-16 10:00:00',  2000,  1850, TRUE),
(11, '2025-01-16 10:00:00', '2025-01-16 11:00:00',  2000,  1700, TRUE),
-- Masjid Quba (site 12)
(12, '2025-01-17 08:00:00', '2025-01-17 10:00:00',  5000,  3200, TRUE),
(12, '2025-01-17 10:00:00', '2025-01-17 12:00:00',  5000,  4100, TRUE);
 
 