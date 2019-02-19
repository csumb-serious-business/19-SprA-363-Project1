-- create/recreate database
DROP DATABASE IF EXISTS serious_olap;

CREATE DATABASE serious_olap;
USE serious_olap;


-- dimensions -- structurally different from oltp versions
CREATE TABLE dim_item (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(64) NOT NULL,
    `need` INT NOT NULL DEFAULT 0
);


CREATE TABLE dim_supplier (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(64) NOT NULL,
    `address` VARCHAR(256) NOT NULL,
    `phone` VARCHAR(10) NOT NULL
);


CREATE TABLE dim_catalog (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `price` DOUBLE NOT NULL,
    `start` DATE NOT NULL,
    `end` DATE
);


CREATE TABLE dim_inventory (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `purchase_date` DATE NOT NULL,
    `quantity` INT NOT NULL DEFAULT 0
);


-- item catalog fact table -- for queries on needed items and pricing
CREATE TABLE fact_item_catalog (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `item_id` INT NOT NULL,
    `catalog_id` INT NOT NULL,
    `supplier_id` INT NOT NULL,
    CONSTRAINT itemcat_fk_item FOREIGN KEY (`item_id`)
        REFERENCES dim_item (`id`),
    CONSTRAINT itemcat_fk_catalog FOREIGN KEY (`catalog_id`)
        REFERENCES dim_catalog (`id`),
    CONSTRAINT itemcat_fk_supplier FOREIGN KEY (`supplier_id`)
        REFERENCES dim_supplier (`id`)
);


-- view -- inventory item details
CREATE VIEW view_item_catalog AS
SELECT
    f.id,
    i.`name` AS `item`,
    i.`need`,
    c.`price`,
    c.`start`,
    c.`end`,
    s.`name` AS `supplier`,
    s.`address` AS `supplier_address`,
    s.`phone` AS `supplier_phone`
FROM fact_item_catalog f
    JOIN dim_item i ON f.`item_id` = i.`id`
    JOIN dim_catalog c ON f.`catalog_id` = c.`id`
    JOIN dim_supplier s ON f.`supplier_id` = s.`id`;


-- inventory catalog fact table -- for queries on item purchases & inventory
CREATE TABLE fact_inventory_catalog (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `inventory_id` INT NOT NULL,
    `item_id` INT NOT NULL,
    `catalog_id` INT NOT NULL,
    `supplier_id` INT NOT NULL,
    CONSTRAINT invcat_fk_inventory FOREIGN KEY (`inventory_id`)
        REFERENCES dim_inventory (`id`),
    CONSTRAINT invcat_fk_item FOREIGN KEY (`item_id`)
        REFERENCES dim_item (`id`),
    CONSTRAINT invcat_fk_catalog FOREIGN KEY (`catalog_id`)
        REFERENCES dim_catalog (`id`),
    CONSTRAINT invcat_fk_supplier FOREIGN KEY (`supplier_id`)
        REFERENCES dim_supplier (`id`)
);


-- view -- inventory catalog details
CREATE VIEW view_inventory_catalog AS
SELECT
    f.id,
    i.`name` AS `item`,
    i.`need`,
    c.`price`,
    c.`start`,
    c.`end`,
    v.`purchase_date`,
    v.`quantity`,
    s.`name` AS `supplier`,
    s.`address` AS `supplier_address`,
    s.`phone` AS `supplier_phone`
FROM fact_inventory_catalog f
    JOIN dim_item i ON f.`item_id` = i.`id`
    JOIN dim_catalog c ON f.`catalog_id` = c.`id`
    JOIN dim_inventory v ON f.`inventory_id` = v.`id`
    JOIN dim_supplier s ON f.`supplier_id` = s.`id`;


-- view -- daily inventory spending
CREATE VIEW view_spending_by_day AS
SELECT
    `purchase_date` AS `date`,
    sum(`price` * `quantity`) AS `spent`
FROM view_inventory_catalog
GROUP BY `purchase_date`;