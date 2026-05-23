USE NUSUK_Database;

--All the active permit in alphabetical order for every Holy site
WITH ActivePermits AS (
    SELECT t.site_id, COUNT(p.permit_id) AS total_active_permits
    FROM time_slots t
    JOIN permits p ON t.slot_id = p.slot_id
    WHERE p.status = 'Active'
    GROUP BY t.site_id
)
SELECT hs.site_name, ap.total_active_permits
FROM holy_sites hs
JOIN ActivePermits ap ON hs.site_id = ap.site_id
ORDER BY hs.site_name ASC;


--Give me a list of all pilgrims who have 'High' or 'Critical'
-- severity special needs, along with their exact need description and their assigned guide's phone number
SELECT  p.first_name, p.last_name,sn.need_type,sn.description,g.first_name AS guide_name,g.phone_number AS guide_emergency_contact
FROM pilgrims p
JOIN special_needs sn ON p.pilgrim_id = sn.pilgrim_id
JOIN bookings b ON p.pilgrim_id = b.pilgrim_id
JOIN pilgrim_groups pg ON b.group_id = pg.group_id
JOIN guides g ON pg.guide_id = g.guide_id
WHERE sn.severity IN ('High', 'Critical') 
  AND b.status = 'Confirmed'
ORDER BY sn.need_type ASC;


--We need to find any pilgrims who have a 'Confirmed' 
--booking but their vaccination records are still 'Pending' or 'Rejected'.
SELECT 
    p.passport_number, 
    p.first_name, 
    p.last_name, 
    hr.vaccination_type, 
    hr.verification_status
FROM pilgrims p
JOIN health_records hr ON p.pilgrim_id = hr.pilgrim_id
JOIN bookings b ON p.pilgrim_id = b.pilgrim_id
WHERE hr.verification_status IN ('Pending', 'Rejected')
  AND b.status = 'Confirmed'
ORDER BY p.last_name ASC;


SELECT 
    method, 
    COUNT(payment_id) AS total_transactions, 
    SUM(amount) AS total_revenue
FROM payments
WHERE status = 'Completed' AND amount > 0
GROUP BY method
ORDER BY total_revenue ASC;

--The Mina tent city site has been declared temporarily unsafe due to weather. 
--Get me the IDs, names, and phone numbers of all pilgrims who have active permits for this site.
SELECT DISTINCT 
    p.pilgrim_id, 
    p.first_name, 
    p.last_name, 
    p.phone_number, 
    hs.site_name
FROM pilgrims p
JOIN permits pm ON p.pilgrim_id = pm.pilgrim_id
JOIN time_slots ts ON pm.slot_id = ts.slot_id
JOIN holy_sites hs ON ts.site_id = hs.site_id
WHERE hs.site_name = 'Mina' 
  AND pm.status = 'Active'
ORDER BY p.pilgrim_id ASC;

UPDATE permits
SET status = 'Expired'
WHERE expiry_date < CURRENT_DATE() AND status = 'Active';


DELETE FROM bookings
WHERE status = 'Cancelled' AND total_price < 10000.00;







SELECT 
    (SELECT COUNT(*) FROM nationalities) +
    (SELECT COUNT(*) FROM holy_sites) +
    (SELECT COUNT(*) FROM hotels) +
    (SELECT COUNT(*) FROM transport_providers) +
    (SELECT COUNT(*) FROM guides) +
    (SELECT COUNT(*) FROM hajj_phases) +
    (SELECT COUNT(*) FROM time_slots) +
    (SELECT COUNT(*) FROM pilgrims) +
    (SELECT COUNT(*) FROM permits) +
    (SELECT COUNT(*) FROM health_records) +
    (SELECT COUNT(*) FROM visas) +
    (SELECT COUNT(*) FROM pilgrim_groups) +
    (SELECT COUNT(*) FROM special_needs) +
    (SELECT COUNT(*) FROM bookings) +
    (SELECT COUNT(*) FROM booking_details) +
    (SELECT COUNT(*) FROM payments) +
    (SELECT COUNT(*) FROM payment_items) +
    (SELECT COUNT(*) FROM hajj_progress) 
AS Grand_Total_Rows;

SELECT 'Nationalities' AS table_name, COUNT(*) AS row_count FROM nationalities
UNION ALL SELECT 'Holy Sites', COUNT(*) FROM holy_sites
UNION ALL SELECT 'Hotels', COUNT(*) FROM hotels
UNION ALL SELECT 'Transport Providers', COUNT(*) FROM transport_providers
UNION ALL SELECT 'Guides', COUNT(*) FROM guides
UNION ALL SELECT 'Hajj Phases', COUNT(*) FROM hajj_phases
UNION ALL SELECT 'Time Slots', COUNT(*) FROM time_slots
UNION ALL SELECT 'Pilgrims', COUNT(*) FROM pilgrims
UNION ALL SELECT 'Permits', COUNT(*) FROM permits
UNION ALL SELECT 'Health Records', COUNT(*) FROM health_records
UNION ALL SELECT 'Visas', COUNT(*) FROM visas
UNION ALL SELECT 'Groups', COUNT(*) FROM pilgrim_groups
UNION ALL SELECT 'Special Needs', COUNT(*) FROM special_needs
UNION ALL SELECT 'Bookings', COUNT(*) FROM bookings
UNION ALL SELECT 'Booking Details', COUNT(*) FROM booking_details
UNION ALL SELECT 'Payments', COUNT(*) FROM payments
UNION ALL SELECT 'Payment Items', COUNT(*) FROM payment_items
UNION ALL SELECT 'Hajj Progress', COUNT(*) FROM hajj_progress;