CREATE DATABASE IF NOT EXISTS hotel_reservation_analytics;
USE hotel_reservation_analytics;


-- 1. DATABASE / TABLE CREATION
-- Dataset tables: guests, hotels, staff, rooms, bookings, stays


DROP TABLE IF EXISTS stays;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS hotels;
DROP TABLE IF EXISTS guests;

SHOW TABLES;

CREATE TABLE guests (
    guest_id VARCHAR(10) PRIMARY KEY,
    guest_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    guest_type VARCHAR(20) NOT NULL,
    preferred_room_type VARCHAR(20),
    loyalty_tier VARCHAR(20),
    account_since DATE
);

CREATE TABLE hotels (
    hotel_id VARCHAR(10) PRIMARY KEY,
    hotel_name VARCHAR(120) NOT NULL,
    city VARCHAR(50) NOT NULL,
    star_rating TINYINT NOT NULL,
    total_rooms INT NOT NULL,
    opened_date DATE
);

CREATE TABLE staff (
    staff_id VARCHAR(10) PRIMARY KEY,
    staff_name VARCHAR(100) NOT NULL,
    hire_date DATE,
    rating DECIMAL(3,2),
    department VARCHAR(50) NOT NULL,
    is_active VARCHAR(3) NOT NULL DEFAULT 'Yes'
);

CREATE TABLE rooms (
    room_id VARCHAR(10) PRIMARY KEY,
    hotel_id VARCHAR(10) NOT NULL,
    room_type VARCHAR(20) NOT NULL,
    floor_number INT NOT NULL,
    max_occupancy INT NOT NULL,
    price_per_night DECIMAL(10,2) NOT NULL,
    is_active VARCHAR(3) NOT NULL DEFAULT 'Yes',
    CONSTRAINT fk_rooms_hotel FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

CREATE TABLE bookings (
    booking_id VARCHAR(10) PRIMARY KEY,
    guest_id VARCHAR(10) NOT NULL,
    hotel_id VARCHAR(10) NOT NULL,
    booking_date DATE NOT NULL,
    room_type_requested VARCHAR(20) NOT NULL,
    booking_channel VARCHAR(30) NOT NULL,
    nights_booked INT NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_bookings_guest FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
    CONSTRAINT fk_bookings_hotel FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

CREATE TABLE stays (
    stay_id VARCHAR(12) PRIMARY KEY,
    booking_id VARCHAR(10) NOT NULL,
    room_id VARCHAR(10) NOT NULL,
    staff_id VARCHAR(10) NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE,
    status VARCHAR(20) NOT NULL,
    nights_stayed INT NOT NULL,
    service_requests INT NOT NULL DEFAULT 0,
    stay_duration_hrs INT NOT NULL,
    CONSTRAINT fk_stays_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    CONSTRAINT fk_stays_room FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    CONSTRAINT fk_stays_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

SELECT COUNT(*) FROM guests;
SELECT * FROM hotels;
SELECT COUNT(*) FROM rooms;
SELECT * FROM staff;
SELECT COUNT(*) FROM bookings;
SELECT COUNT(*) FROM stays;




-- LOAD DATA FROM CSV FILE

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/guests.csv'
INTO TABLE guests
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(guest_id, guest_name, city, guest_type, preferred_room_type, loyalty_tier, @account_since)
SET account_since = STR_TO_DATE(@account_since, '%d-%m-%Y');



LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/bookings.csv'
INTO TABLE bookings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    booking_id,
    guest_id,
    hotel_id,
    @booking_date,
    room_type_requested,
    booking_channel,
    nights_booked,
    total_amount
)
SET booking_date = STR_TO_DATE(@booking_date, '%d-%m-%Y');



LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/stays.csv'
INTO TABLE stays
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    stay_id,
    booking_id,
    room_id,
    staff_id,
    check_in_date,
    check_out_date,
    status,
    nights_stayed,
    service_requests,
    stay_duration_hrs
);
SHOW VARIABLES LIKE 'secure_file_priv';


-- SPRINT 3 : Basic Analysis / Data Exploration

-- 1. What is the total number of guests?
SELECT COUNT(*) AS total_guests
FROM guests;


-- 2. What is the total number of bookings?
SELECT COUNT(*) AS total_bookings
FROM bookings;


-- 3. What is the total number of stays?
SELECT COUNT(*) AS total_stays
FROM stays;


-- 4. What are the different room types available?
SELECT DISTINCT room_type
FROM rooms
ORDER BY room_type;


-- 5. How many staff members are currently active?
SELECT COUNT(*) AS active_staff
FROM staff
WHERE is_active = 'Yes';


-- 6. What are the different booking channels?
SELECT DISTINCT booking_channel
FROM bookings
ORDER BY booking_channel;


-- 7. What is the total booking amount across all bookings?
SELECT ROUND(SUM(total_amount), 2) AS total_booking_amount
FROM bookings;


-- 8. What is the average nights booked per booking?
SELECT ROUND(AVG(nights_booked), 2) AS average_nights_booked
FROM bookings;



-- SPRINT 4: OBJECTIVE-BASED ANALYSIS


-- 4.1 UNDERSTANDING BOOKING DEMAND
-- Business Objective:
-- Understand where and how bookings are being generated.

-- 1. Which hotels generate the highest booking volume and revenue?

SELECT
    h.hotel_id,h.hotel_name,
    COUNT(b.booking_id) AS total_bookings,
    ROUND(SUM(b.total_amount), 2) AS total_revenue
FROM bookings b JOIN hotels h ON b.hotel_id = h.hotel_id
GROUP BY
    h.hotel_id,h.hotel_name
ORDER BY
    total_bookings DESC,total_revenue DESC;



-- 2. Which booking channels yield the highest revenue and longer stay duration?

SELECT
    booking_channel,
    COUNT(booking_id) AS total_bookings,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(nights_booked), 2) AS avg_nights_booked
FROM bookings
GROUP BY booking_channel
ORDER BY total_revenue DESC;


-- 3. What room types are requested most frequently?

SELECT
    room_type_requested,
    COUNT(booking_id) AS total_requests
FROM bookings
GROUP BY room_type_requested
ORDER BY total_requests DESC;



-- SPRINT 4.2: UNDERSTAND GUEST BOOKING BEHAVIOUR

-- Q1. Which guests have made the highest number of bookings?

SELECT
    g.guest_id,
    g.guest_name,
    COUNT(b.booking_id) AS total_bookings
FROM guests g
JOIN bookings b
    ON g.guest_id = b.guest_id
GROUP BY g.guest_id, g.guest_name
ORDER BY total_bookings DESC;


-- Q2. Which guests have the highest total booking amount?

SELECT
    g.guest_id,
    g.guest_name,
    COUNT(b.booking_id) AS total_bookings,
    ROUND(SUM(b.total_amount), 2) AS total_spending
FROM guests g
JOIN bookings b
    ON g.guest_id = b.guest_id
GROUP BY g.guest_id, g.guest_name
ORDER BY total_spending DESC
LIMIT 10;




-- Q3. How does booking activity differ between Individual
--     and Corporate guests?

SELECT
    g.guest_type,
    COUNT(DISTINCT g.guest_id) AS number_of_guests,
    COUNT(b.booking_id) AS total_bookings,
    ROUND(SUM(b.total_amount), 2) AS total_booking_amount,
    ROUND(AVG(b.total_amount), 2) AS average_booking_amount
FROM guests g
LEFT JOIN bookings b
    ON g.guest_id = b.guest_id
GROUP BY g.guest_type
ORDER BY total_booking_amount DESC;


-- Q4. Which hotels are most frequently used by guests?

SELECT
    h.hotel_id,
    h.hotel_name,
    COUNT(DISTINCT b.guest_id) AS unique_guests,
    COUNT(b.booking_id) AS total_bookings
FROM hotels h
JOIN bookings b
    ON h.hotel_id = b.hotel_id
GROUP BY h.hotel_id, h.hotel_name
ORDER BY total_bookings DESC;


-- Q5. How does booking activity differ across loyalty tiers?

SELECT
    g.loyalty_tier,
    COUNT(DISTINCT g.guest_id) AS number_of_guests,
    COUNT(b.booking_id) AS total_bookings,
    ROUND(SUM(b.total_amount), 2) AS total_booking_amount,
    ROUND(AVG(b.total_amount), 2) AS average_booking_amount
FROM guests g
LEFT JOIN bookings b
    ON g.guest_id = b.guest_id
GROUP BY g.loyalty_tier
ORDER BY total_booking_amount DESC;




-- SPRINT 4.3: EVALUATE STAY PERFORMANCE

-- Q1. What are the different stay outcomes and how frequently    does each occur?

SELECT
    status,
    COUNT(*) AS total_stays
FROM stays
GROUP BY status
ORDER BY total_stays DESC;


-- Q2. How do stay outcomes differ across hotels?

SELECT
    h.hotel_id,
    h.hotel_name,
    s.status,
    COUNT(*) AS total_stays
FROM stays s
JOIN bookings b
    ON s.booking_id = b.booking_id
JOIN hotels h
    ON b.hotel_id = h.hotel_id
GROUP BY h.hotel_id, h.hotel_name, s.status
ORDER BY h.hotel_name, total_stays DESC;


-- Q3. Which hotels have the highest number of completed stays?

SELECT
    h.hotel_id,
    h.hotel_name,
    COUNT(*) AS completed_stays
FROM stays s
JOIN bookings b
    ON s.booking_id = b.booking_id
JOIN hotels h
    ON b.hotel_id = h.hotel_id
WHERE s.status = 'Checked-out'
GROUP BY h.hotel_id, h.hotel_name
ORDER BY completed_stays DESC;


-- Q4. Which hotels have the highest cancellation and no-show activity?

SELECT
    h.hotel_id,
    h.hotel_name,
    SUM(CASE
        WHEN s.status = 'Cancelled' THEN 1
        ELSE 0
    END) AS cancelled_stays,
    SUM(CASE
        WHEN s.status = 'No-show' THEN 1
        ELSE 0
    END) AS no_show_stays
FROM stays s
JOIN bookings b
    ON s.booking_id = b.booking_id
JOIN hotels h
    ON b.hotel_id = h.hotel_id
GROUP BY h.hotel_id, h.hotel_name
ORDER BY cancelled_stays + no_show_stays DESC;



-- Q5. How does stay performance change over time?

SELECT
    YEAR(check_in_date) AS stay_year,
    MONTH(check_in_date) AS stay_month,
    COUNT(*) AS total_stays,
    SUM(CASE
        WHEN status = 'Checked-out' THEN 1
        ELSE 0
    END) AS completed_stays,
    SUM(CASE
        WHEN status = 'Cancelled' THEN 1
        ELSE 0
    END) AS cancelled_stays,
    SUM(CASE
        WHEN status = 'No-show' THEN 1
        ELSE 0
    END) AS no_show_stays
FROM stays
GROUP BY YEAR(check_in_date), MONTH(check_in_date)
ORDER BY stay_year, stay_month;




-- SPRINT 4.4: UNDERSTAND STAFF AND ROOM PERFORMANCE

-- Q1. How many stays were handled by each staff member?

SELECT
    st.staff_id,
    st.staff_name,
    COUNT(s.stay_id) AS stays_handled
FROM staff st
LEFT JOIN stays s
    ON st.staff_id = s.staff_id
GROUP BY st.staff_id, st.staff_name
ORDER BY stays_handled DESC;


-- Q2. How do stay outcomes and average stay duration differ across staff members?

SELECT
    st.staff_id,
    st.staff_name,
    s.status,
    COUNT(s.stay_id) AS total_stays,
    ROUND(AVG(s.nights_stayed), 2) AS average_nights_stayed
FROM staff st
JOIN stays s
    ON st.staff_id = s.staff_id
GROUP BY
    st.staff_id,
    st.staff_name,
    s.status
ORDER BY
    st.staff_name,
    total_stays DESC;


-- Q3. How are rooms being used across different room types?

SELECT
    r.room_type,
    COUNT(s.stay_id) AS total_stays,
    COUNT(DISTINCT r.room_id) AS rooms_used
FROM rooms r
LEFT JOIN stays s
    ON r.room_id = s.room_id
GROUP BY r.room_type
ORDER BY total_stays DESC;


-- Q4. Which individual rooms have the highest usage?

SELECT
    r.room_id,
    r.hotel_id,
    r.room_type,
    COUNT(s.stay_id) AS total_stays
FROM rooms r
LEFT JOIN stays s
    ON r.room_id = s.room_id
GROUP BY r.room_id, r.hotel_id, r.room_type
ORDER BY total_stays DESC;


-- Q5. Which staff members have the highest average stay duration?

SELECT
    st.staff_id,
    st.staff_name,
    COUNT(s.stay_id) AS total_stays,
    ROUND(AVG(s.nights_stayed), 2) AS average_nights_stayed
FROM staff st
JOIN stays s
    ON st.staff_id = s.staff_id
GROUP BY st.staff_id, st.staff_name
HAVING COUNT(s.stay_id) > 0
ORDER BY average_nights_stayed DESC;


-- SPRINT 4.5: IDENTIFY BOOKING AND STAY PROBLEMS

-- Q1. How many stays resulted in cancellations or no-shows?

SELECT
    status,
    COUNT(*) AS total_problem_stays
FROM stays
WHERE status IN ('Cancelled', 'No-show')
GROUP BY status
ORDER BY total_problem_stays DESC;


-- Q2. What are the most common stay statuses?

SELECT
    status,
    COUNT(*) AS total_stays,
    ROUND(
        100.0 * COUNT(*) /
        NULLIF((SELECT COUNT(*) FROM stays), 0),
        2
    ) AS percentage_of_stays
FROM stays
GROUP BY status
ORDER BY total_stays DESC;


-- Q3. Do bookings with more service requests have different   stay outcomes?

SELECT
    CASE
        WHEN service_requests = 0 THEN 'No Requests'
        WHEN service_requests BETWEEN 1 AND 2 THEN '1-2 Requests'
        ELSE '3+ Requests'
    END AS request_group,
    status,
    COUNT(*) AS total_stays
FROM stays
GROUP BY
    CASE
        WHEN service_requests = 0 THEN 'No Requests'
        WHEN service_requests BETWEEN 1 AND 2 THEN '1-2 Requests'
        ELSE '3+ Requests'
    END,
    status
ORDER BY request_group, total_stays DESC;


-- Q4. Which hotels have the most cancellation and no-show problems?

SELECT
    h.hotel_id,h.hotel_name,
    COUNT(*) AS problem_stays
FROM stays s
JOIN bookings b ON s.booking_id = b.booking_id
JOIN hotels h ON b.hotel_id = h.hotel_id
WHERE s.status IN ('Cancelled', 'No-show')
GROUP BY h.hotel_id, h.hotel_name
ORDER BY problem_stays DESC;


-- Q5. What is the problem-stay rate for each hotel?

SELECT
    h.hotel_id,
    h.hotel_name,
    COUNT(*) AS total_stays,
    SUM(
        CASE
            WHEN s.status IN ('Cancelled', 'No-show')
            THEN 1
            ELSE 0
        END
    ) AS problem_stays,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN s.status IN ('Cancelled', 'No-show')
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS problem_rate_percentage
FROM stays s
JOIN bookings b
    ON s.booking_id = b.booking_id
JOIN hotels h
    ON b.hotel_id = h.hotel_id
GROUP BY h.hotel_id, h.hotel_name
ORDER BY problem_rate_percentage DESC;
