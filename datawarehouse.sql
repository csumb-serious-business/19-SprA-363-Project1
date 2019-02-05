-- create/recreate database
DROP DATABASE IF EXISTS serious_project_1_warehouse;

CREATE DATABASE serious_project_1_warehouse;
USE serious_project_1_warehouse;

CREATE TABLE item (
	`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(64) NOT NULL,
    `need` INT NOT NULL DEFAULT 0
);


CREATE TABLE supplier (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(64) NOT NULL,
    `address` VARCHAR(256) NOT NULL,
    `phone` VARCHAR(10) NOT NULL
);


CREATE TABLE catalog (
    `item_id` INT NOT NULL,
    `supplier_id` INT NOT NULL,
    `price` DOUBLE NOT NULL,
    `start` DATE NOT NULL,
    `end` DATE,
    PRIMARY KEY (`item_id`, `supplier_id`, `start`),
    CONSTRAINT catalog_fk_supplier FOREIGN KEY (`supplier_id`)
        REFERENCES supplier (`id`),
	CONSTRAINT catalog_fk_item FOREIGN KEY (`item_id`)
        REFERENCES item (`id`)
);


CREATE TABLE inventory (
	`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `item_id` INT NOT NULL,
    `supplier_id` INT NOT NULL,
    `purchase_date` DATE NOT NULL,
    `quantity` INT NOT NULL DEFAULT 0,
    CONSTRAINT inventory_fk_item FOREIGN KEY (`item_id`)
        REFERENCES item (`id`),
	CONSTRAINT inventory_fk_supplier FOREIGN KEY (`supplier_id`)
        REFERENCES supplier (`id`)
);

-- fact table
CREATE TABLE fact (
	`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`item_id` INT NOT NULL,
	`supplier_id` INT NOT NULL,
	-- `catalog_id` INT NOT NULL,
    `purchase_date` DATE NOT NULL,
    `quantity` INT NOT NULL DEFAULT 0,
	-- `need` INT NOT NULL DEFAULT 0
	-- `price` DOUBLE NOT NULL,
	-- `start` DATE NOT NULL,
    -- `end` DATE,
    -- todo 1: this is showing up as the primary key
    CONSTRAINT fact_fk_inventory FOREIGN KEY (`id`)
		REFERENCES inventory (`id`),
	
    CONSTRAINT fact_fk_item FOREIGN KEY (`item_id`)
		REFERENCES item (`id`),       
    
    CONSTRAINT fact_fk_supplier FOREIGN KEY (`supplier_id`)
        REFERENCES supplier (`id`)
 	
    -- todo 2: there is no catalog id
	-- todo 3: do i need to add purchase_date and quantity as foreign keys
	-- CONSTRAINT fact_fk_purchase_date FOREIGN KEY (`purchase_date`)
	-- REFERENCES inventory (`purchase_date`),

	-- CONSTRAINT fact_fk_quantity FOREIGN KEY (`quantity`)
	-- REFERENCES inventory (`quantity`)        

);
-- add items
INSERT INTO item (name)
VALUES 
	("Soccer Ball"),
    ("Hat"),
    ("LED TV"),
    ("Multivitamin"),
    ("Oil Filter"),
    ("Red Balloons");


-- add suppliers
INSERT INTO supplier (`name`, `address`, `phone`)
VALUES 
("Big 5",          "2140 Cleveland Ave #104, Madera, CA 93637", "5596742159"),
("Target",         "3280 R St, Merced, CA 95348",               "2097253482"),
("CVS",            "4077 W Clinton Ave, Fresno, CA 93722",      "5592713177"),
("AutoZone",       "3785 W Shields Ave, Fresno, CA 93722",      "5592773744"),
("Party City",     "4320 W Shaw Ave, Fresno, CA 93722",         "5592757767"),
("Barnes & Noble", "1720 W Olive Ave, Merced, CA 95348",        "2093860571");


-- add catalog items
INSERT INTO catalog (`item_id`, `supplier_id`, `price`, `start`)
VALUES
(1, 1,  15.00, '2019-01-01'),
(2, 1,  19.99, '2019-01-01'),
(3, 2, 399.99, '2019-01-01'),
(4, 3,  10.49, '2019-01-01'),
(5, 4,   9.99, '2019-01-01'),
(6, 5,   4.99, '2019-01-01');

-- add inventory
INSERT INTO inventory (`item_id`, `supplier_id`, `purchase_date`, `quantity`)
VALUES
(1,  1, '2019-02-01', 2),
(3,  2, '2019-02-01', 1),
(4,  3, '2019-02-01', 3),
(5,  4, '2019-02-01', 2),
(6,  5, '2019-02-01', 99);
