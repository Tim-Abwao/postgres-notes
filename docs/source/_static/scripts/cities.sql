BEGIN;
DROP TABLE IF EXISTS cities CASCADE;
CREATE TABLE cities (
    name        varchar(80),
    location    point
);
INSERT INTO cities VALUES
    ('Nairobi', '(-1.28333, 36.81667)'),
    ('Mombasa', '(-4.05466, 39.66359)');
COMMIT;
