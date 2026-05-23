USE NUSUK_Database;

CREATE USER 'nusuk_admin'@'localhost' IDENTIFIED BY 'AdminPass123!';
CREATE USER 'nusuk_staff'@'localhost' IDENTIFIED BY 'StaffPass123!';
CREATE USER 'nusuk_analyst'@'localhost' IDENTIFIED BY 'AnalystPass123!';



-- ADMIN: Full access to everything
GRANT ALL PRIVILEGES ON NUSUK_Database.* TO 'nusuk_admin'@'localhost';



-- STAFF: Can read, insert, and update specific daily operational tables
GRANT SELECT, INSERT, UPDATE ON NUSUK_Database.pilgrims TO 'nusuk_staff'@'localhost';
GRANT SELECT, INSERT, UPDATE ON NUSUK_Database.bookings TO 'nusuk_staff'@'localhost';
GRANT SELECT, INSERT, UPDATE ON NUSUK_Database.permits TO 'nusuk_staff'@'localhost';
GRANT SELECT, INSERT, UPDATE ON NUSUK_Database.health_records TO 'nusuk_staff'@'localhost';




-- ANALYST: Can ONLY read data, but can read it from anywhere for analyzing
GRANT SELECT ON NUSUK_Database.* TO 'nusuk_analyst'@'localhost';



GRANT DELETE ON NUSUK_Database.permits TO 'nusuk_staff'@'localhost';

REVOKE DELETE ON NUSUK_Database.permits FROM 'nusuk_staff'@'localhost';


FLUSH PRIVILEGES;