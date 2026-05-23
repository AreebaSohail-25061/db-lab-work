USE NUSUK_Database;

START TRANSACTION;
UPDATE time_slots 
SET current_occupancy = current_occupancy + 1 
WHERE slot_id = 2;
INSERT INTO permits (pilgrim_id, slot_id, issue_date, expiry_date, status, permit_type)
VALUES (4, 2, CURRENT_DATE(), DATE_ADD(CURRENT_DATE(), INTERVAL 14 DAY), 'Active', 'Umrah');
COMMIT;
SELECT slot_id, current_occupancy FROM time_slots WHERE slot_id = 2;
SELECT * FROM permits WHERE pilgrim_id = 4 AND slot_id = 2;

SELECT booking_id, status FROM bookings WHERE booking_id = 2;





START TRANSACTION;
UPDATE bookings 
SET status = 'Paid' 
WHERE booking_id = 2;
INSERT INTO payments (booking_id, transaction_ref, payment_date, amount, method, status)
VALUES (2, 'TXN-DECLINED-999', CURRENT_DATE(), 12500.00, 'Credit_Card', 'Failed');
ROLLBACK;
SELECT booking_id, status FROM bookings WHERE booking_id = 2;