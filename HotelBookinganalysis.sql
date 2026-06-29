-- create database hotel_booking;
use hotel_booking;

-- # Table Creation
/*create table hotel_bookings(
booking_id varchar(20),
customer_id varchar(20),
customer_name varchar(100),
customer_segment varchar(50),
customer_signup_date varchar(50),
customer_home_city varchar(100),
customer_loyalty_tier varchar(50),
property_id varchar(20),
property_name varchar(100),
property_city varchar(100),
property_star_rating varchar(20),
property_type varchar(50),
property_total_rooms varchar(20),
booking_date varchar(50),
checkin_date varchar(50),
checkout_date varchar(50),
room_type varchar(50),
num_rooms varchar(20),
nights varchar(20),
booking_channel varchar(50),
adr varchar(50),
discount_amount varchar(50),
coupon_code varchar(50),
total_amount varchar(50),
payment_method varchar(50),
booking_status varchar(50),
review_rating varchar(20),
review_date varchar(50)); */

-- # Checking
select count(*) as total_rows from hotel_bookings;

-- Footnote 1 section 1 A1 -- invalid stay
select count(*) as invalid_stays from hotel_bookings where checkout_date <= checkin_date;

-- Footnote2
select count(*) as booking_before_signup from hotel_bookings where booking_date < customer_signup_date;

-- Footnote 3
select COUNT(*) as zero_room_bookings from hotel_bookings where num_rooms = 0;

-- Footnote 4
select property_name, count(distinct property_id) as property_ids, count(distinct property_city) as cities
from hotel_bookings group by property_name having count(distinct property_id) > 1;

-- footnote 5
select count(*) as cancelled_with_review from hotel_bookings where booking_status = 'Cancelled' 
and review_rating is not null and review_rating <> '';

-- footnote 6  -- section 1 A2 -- computing review ratings and mean
select customer_segment, min(cast(review_rating as decimal(5,2))) as min_rating,
max(cast(review_rating as decimal(5,2))) as max_rating,
round(avg(cast(review_rating as decimal(5,2))),2) as avg_rating
from hotel_bookings where review_rating is not null and review_rating <> '' group by customer_segment;

-- footnote 7
select customer_loyalty_tier, count(*) as total from hotel_bookings group by customer_loyalty_tier;

-- footnote 8
select round(sum(total_amount),2) as booked_revenue from hotel_bookings;
select round(sum(total_amount),2) as situation_revenue from hotel_bookings where booking_status='Completed';

--  section 1 A3 -- Revenue for Luxury
select
round(sum(total_amount),2) as lux_revenue
from hotel_bookings where property_type = 'Luxury' and booking_status = 'Completed' 
and checkout_date > checkin_date and num_rooms > 0;

--  Section 2 A1 -- cancellation Landscape
select booking_status, count(*) as bookings,round(count(*) * 100.0 /(select count(*) from hotel_bookings),2) as percentage
from hotel_bookings group by booking_status;

-- section 2  -- custom segment Analysis
select customer_segment, count(*) as total_bookings,
sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled_bookings,
round(sum(case when booking_status = 'Cancelled' then 1 else 0 end) * 100.0/ count(*), 2) as cancellation_rate
from hotel_bookings group by customer_segment order by cancellation_rate desc;

-- section 2 A2 -- rate vs volume
select booking_channel, count(*) as total_bookings,
sum(case when booking_status='Cancelled' then 1 else 0 end) as cancelled_bookings,
round(sum(case when booking_status='Cancelled' then 1 else 0 end)*100.0/ count(*),2) as cancellation_rate
from hotel_bookings group by booking_channel order by cancellation_rate desc;

-- section 2 - A3 Lead time effect
select booking_channel, 
round(avg(datediff(checkin_date, booking_date)), 2) as avg_lead_time_days
from hotel_bookings group by booking_channel order by avg_lead_time_days desc;

-- section 2 A3 - channel Mix effect
select booking_channel, count(*) as bookings,
round(count(*) * 100.0 / (select count(*) from hotel_bookings), 2) as booking_share_pct
from hotel_bookings group by booking_channel order by bookings desc;

-- section 2 A3 - city and season effect
select property_city, month(checkin_date) as month_num, count(*) as bookings,
sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled_bookings,
round(sum(case when booking_status = 'Cancelled' then 1 else 0 end) * 100.0 / count(*),2) as cancellation_rate
from hotel_bookings group by property_city, month(checkin_date) order by cancellation_rate desc limit 10;


-- section 3
-- Customer table
/*create table customers(
customer_id int primary key,
customer_name varchar(100) not null,
customer_segment varchar(20) not null,
customer_signup_date date not null,
customer_home_city varchar(50),
customer_loyalty_tier varchar(20));

-- properties table
create table properties(
property_id int primary key,
property_name varchar(100) not null,
property_city varchar(50) not null,
property_type varchar(20),
property_star_rating decimal(2,1),
unique(property_name, property_city));

-- booking table
create table bookings(
booking_id int primary key,
customer_id int not null,
property_id int not null,
booking_date date not null,
checkin_date date not null,
checkout_date date not null,
num_rooms int not null,
total_amount decimal(12,2) not null,
booking_channel varchar(30),
booking_status varchar(20),
foreign key(customer_id) references customers(customer_id),
foreign key(property_id) references properties(property_id),
check(checkout_date > checkin_date),
check(num_rooms > 0));

-- review table
create table reviews(
review_id int auto_increment primary key,
booking_id int not null,
review_rating decimal(3,1),
foreign key(booking_id) references bookings(booking_id));*/

-- section 3 -- A 1
with property_revenue as(select property_city, property_id, property_name, sum(total_amount) as revenue
from hotel_bookings where booking_status = 'Completed'
group by property_city, property_id, property_name), ranked_properties as (select *, rank() over(partition by property_city
order by revenue desc) as rnk 
from property_revenue) select property_city, property_id, property_name, revenue from ranked_properties where rnk = 1;

-- section 3 A2 
with booking_gaps as(select customer_id, datediff(checkin_date, lag(checkin_date) over(partition by customer_id order by checkin_date)) as gap_days
from hotel_bookings where booking_status = 'Completed'), avg_gap as (select customer_id, avg(gap_days) as avg_gap_days
from booking_gaps where gap_days is not null group by customer_id)
select count(*) as customers_under_30_days from avg_gap where avg_gap_days < 30;

select booking_id, property_city, booking_status, checkin_date
from hotel_bookings where property_city in ('Goa','Manali') and year(checkin_date)=2024;
