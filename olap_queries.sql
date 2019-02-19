USE serious_olap;

-- how much was spent in February 2019?
SELECT
	MONTH(`date`) as `month`,
	sum(`spent`) as `spent`
FROM
    view_spending_by_day
WHERE
    MONTH(`date`) = MONTH('2019-02-01')
        AND YEAR(`date`) = YEAR('2019-02-01')
GROUP BY MONTH(`date`);


-- What is the most expensive item we have purchased this month and how many?
SELECT `item`, `quantity`, `price`, `purchase_date`
FROM view_inventory_catalog
WHERE
    MONTH(`purchase_date`) = MONTH(CURRENT_DATE())
ORDER BY price DESC
LIMIT 1;


-- Which catalog items will be discontinued this month?
SELECT `item`, `price`, `end` AS `end_date`
FROM view_item_catalog
WHERE
    MONTH(`end`) = MONTH(CURRENT_DATE());


-- Which items are overstocked?
SELECT
    v.`item`, x.`have`, v.`need`
FROM view_inventory_catalog v
	JOIN (
		SELECT
			`item`,
			SUM(`quantity`) AS `have`,
			(`need` < SUM(`quantity`)) AS `os`
		FROM view_inventory_catalog
		GROUP BY `item` , `need`
	) x ON v.`item` = x.`item`
WHERE x.`os` = 1;



-- Make a shopping list
SELECT v.`item`, (v.`need` - ifnull(x.`have`, 0)) as `to_purchase`
FROM view_item_catalog v LEFT OUTER JOIN (
SELECT
	`item`,
    sum(`quantity`) as `have`,
	(`need` > sum(`quantity`)) as `os`
FROM
	view_inventory_catalog
GROUP BY `item`, `need`
) x ON v.`item` = x.`item`
WHERE (v.`need` - ifnull(x.`have`, 0)) > 0;
