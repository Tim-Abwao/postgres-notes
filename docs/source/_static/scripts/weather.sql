BEGIN;
DROP TABLE IF EXISTS weather CASCADE;
CREATE TABLE weather (
    city            varchar(80),
    temp_lo         int,           -- low temperature
    temp_hi         int,           -- high temperature
    prcp            real,          -- precipitation
    date            date
);
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
    VALUES ('Nairobi', 13, 21, 0.1, '2021-05-26'),
           ('Mombasa', 23, 28, 0.0, '2021-05-26'),
           ('Mombasa', 24, 29, 0.05, '2021-05-27'),
           ('Nairobi', 11, 21, 0.2, '2021-05-27');
COMMIT;
