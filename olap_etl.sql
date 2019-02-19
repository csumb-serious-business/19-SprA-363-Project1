-- clear all tables before ETL
-- (naive approach) -- in real app, would keep track
-- of last updated values and continue from there
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE serious_olap.dim_item;
TRUNCATE TABLE serious_olap.dim_supplier;
TRUNCATE TABLE serious_olap.dim_catalog;
TRUNCATE TABLE serious_olap.dim_inventory;
TRUNCATE TABLE serious_olap.fact_item_catalog;
TRUNCATE TABLE serious_olap.fact_inventory_catalog;
SET FOREIGN_KEY_CHECKS = 1;


-- item is same between oltp/olap
INSERT serious_olap.dim_item (
	SELECT * FROM serious_oltp.item
);


-- supplier is same between oltp/olap
INSERT IGNORE serious_olap.dim_supplier (
    SELECT *
    FROM serious_oltp.supplier
);


-- catalog -- no item_id or supplier_id
INSERT IGNORE serious_olap.dim_catalog (
    SELECT `id`, `price`, `start`, `end`
    FROM serious_oltp.catalog
);


-- inventory -- no item_id or supplier_id
INSERT IGNORE serious_olap.dim_inventory (
    SELECT `id`, `purchase_date`, `quantity`
    FROM serious_oltp.inventory
);


-- item/catalog facts
REPLACE INTO serious_olap.fact_item_catalog (
	SELECT
		null as `id`,
		i.`id` AS `item_id`,
		c.`id` AS `catalog_id`,
		c.`supplier_id` AS `supplier_id`
	FROM serious_oltp.catalog c
		JOIN
	serious_oltp.item i ON c.`item_id` = i.`id`
);


-- iventory/catalog facts
REPLACE INTO serious_olap.fact_inventory_catalog (
    SELECT
		null as `id`,
		v.`id` AS `inventory_id`,
		v.`item_id` AS `item_id`,
		c.`id` AS `catalog_id`,
		v.`supplier_id` AS `supplier_id`
	FROM serious_oltp.catalog c
        JOIN
    serious_oltp.inventory v ON c.`supplier_id` = v.`supplier_id`
        AND c.`item_id` = v.`item_id`
        AND c.`start` < v.`purchase_date`
        AND (c.`end` IS NULL OR c.`end` > v.`purchase_date`)
);
