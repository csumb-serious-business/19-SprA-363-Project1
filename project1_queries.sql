#What are the the items that have been discontinued (end date) in the current month?
SELECT name AS Item, end AS EndDate 
	FROM catalog c JOIN fact f 
		ON c.item_id = f.item_id 
        JOIN item i
		ON f.id = i.id
	WHERE DAYOFMONTH(end) = DAYOFMONTH(current_date());

#Which items did we purchase the most of this current week to date? 
SELECT name AS Item, purchase_date AS date_purchased
	FROM item it JOIN inventory i
		ON it.id = i.id
	WHERE WEEK(purchase_date, 1) = WEEK(CURRENT_DATE(), 1);

#What are the top three items in our inventory(quantity)?
SELECT name as Item, quantity 
	FROM fact f JOIN item i
		ON f.id = i.id
	ORDER BY quantity ASC 
    LIMIT 3;

#What is the most expensive item we have purchased this month and how many? 
SELECT name as Item, f.quantity, c.price, f.purchase_date
	FROM item i JOIN fact f
		ON i.id = f.id
	JOIN catalog c
		on f.item_id = c.item_id
	WHERE MONTH(purchase_date) = MONTH(CURRENT_DATE()) 
    ORDER BY price ASC
    LIMIT 1;
#What are the three most recent items to go on the shelves(start)? 
SELECT name AS item, start AS starting_date
	FROM item i JOIN fact f
		ON i.id = f.id
	JOIN catalog c
		ON f.item_id = c.item_id
	ORDER BY start ASC
    LIMIT 3;