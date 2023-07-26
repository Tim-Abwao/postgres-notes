BEGIN;

CREATE TABLE public.products (
    name            varchar(50) PRIMARY KEY,
    items_in_stock  integer,
    price           numeric(7,2)
);
INSERT INTO public.products (name, items_in_stock, price) VALUES
  ('Apples', 100, 25.00),
  ('Bananas', 32, 10.00),
  ('Cherries', 74, 3.00),
  ('Kiwis', 54, 5.00),
  ('Lemons', 49, 4.00),
  ('Mangoes', 38, 30.00),
  ('Pineapples', 26, 35.00),
  ('Spinach', 19, 7.50),
  ('Tomatoes', 43, 4.50),
  ('Watermelons', 22, 42.00);

CREATE TABLE public.suppliers (
    name        varchar(50) PRIMARY KEY,
    products    text[],
    address     varchar(50)
);
INSERT INTO public.suppliers VALUES
  ('ACME Fruits Ltd', '{Bananas}', '123 abcd'),
  ('City Merchants', '{Bananas}', '234, bcd'),
  ('Green Thumb Corp.', '{Spinach}', '345, cde'),
  ('Jolly Grocers', '{Apples, Cherries}', '456, def'),
  ('Planet Farms', '{Apples, Coconuts}', '567, efg'),
  ('Tropical Paradise Ltd', '{Kiwis, Lemons, Mangoes}', '678 , fgh'),
  ('Village Growers Association', '{Apples, Mangoes, Tomatoes}', '789, ghi'),
  ('Zing Gardens', '{Pineapples, Watermelons}', '8910, hij');

CREATE TABLE public.purchases (
  supplier_name       varchar(70) REFERENCES public.suppliers(name),
  product_name        varchar(50) REFERENCES public.products(name),
  units               int,
  unit_price          numeric(7,2),
  last_delivery_date  date
);
INSERT INTO public.purchases (supplier_name, product_name, units, unit_price, last_delivery_date) VALUES
  ('ACME Fruits Ltd', 'Bananas', 20, 8.50, '2023-07-23'),
  ('Green Thumb Corp.', 'Spinach', 12, 5.95, '2023-07-24'),
  ('Jolly Grocers', 'Apples', 24, 23.80, '2023-07-24'),
  ('Planet Farms', 'Apples', 36, 24.10, '2023-07-25'),
  ('City Merchants', 'Bananas', 50, 9.00000, '2023-07-25'),
  ('Zing Gardens', 'Watermelons', 12, 39.95, '2023-07-25'),
  ('Village Growers Association', 'Mangoes', 36, 28.50, '2023-07-25'),
  ('Tropical Paradise Ltd', 'Lemons', 24, 3.25, '2023-07-25'),
  ('Tropical Paradise Ltd', 'Kiwis', 12, 4.00, '2023-07-25'),
  ('Jolly Grocers', 'Cherries', 120, 2.15, '2023-07-26'),
  ('Zing Gardens', 'Pineapples', 12, 33.75, '2023-07-26'),
  ('City Merchants', 'Bananas', 30, 8.00, '2023-07-26'),
  ('Tropical Paradise Ltd', 'Mangoes', 24, 29.05, '2023-07-28'),
  ('Village Growers Association', 'Tomatoes', 36, 3.80, '2023-07-28'),
  ('Village Growers Association', 'Apples', 12, 23.50, '2023-07-28');

COMMIT;
