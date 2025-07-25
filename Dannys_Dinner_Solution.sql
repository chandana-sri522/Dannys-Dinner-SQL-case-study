-- 1. What is the total amount each customer spent at the restaurant?
select customer_id,sum(price) as total_spent
from sales s inner join menu m
on s.product_id=m.product_id
group  by customer_id;

/*
Result:
____________________________
|customer_id | total_amount |
|	A    |	76	    |
|	B    |	74	    |
|	C    |	36	    |
_____________________________
*/

-- 2. How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) as no_of_times_visited
from sales 
group  by customer_id;

/* Result
_____________________________________
| customer_id  |  no_of_days_visited |
|	A      |	4	     |
|	B      |	6	     |
|	C      |	2	     |
|___________________________________|

*/

-- 3. What was the first item from the menu purchased by each customer?
with min_order as(select customer_id,min(order_date) as first_purchase_date
from sales
group by customer_id)

select mo.customer_id,group_concat(m.product_name SEPARATOR ',') as product_name 
from min_order mo inner join sales s
on mo.customer_id=s.customer_id and mo.first_purchase_date=s.order_date
join menu m
on s.product_id=m.product_id
group by customer_id,first_purchase_date;

/* Result
_________________________
|customer_id |  product_id|
|    A       | sushi,curry|
|    B       |	curry	  |
|    C       |	ramen     |
|_________________________|

*/

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with prod_count as 
(select product_id,count(*) as count_of_items
from sales
group by product_id),
max_prod as(
select p.product_id,product_name, count_of_items  as cnt, rank() over (order by count_of_items desc) as rnk
from prod_count p join menu m
on p.product_id=m.product_id)

select product_id,product_name,cnt
from max_prod where rnk=1;

/*Result
___________________________________________
|product_id| product_name | total_numbers |
|     3	   |	ramen	  |	8	          |
___________________________________________
*/

-- 5. Which item was the most popular for each customer?
with popular_order as(select customer_id,product_id,count(product_id) as no_of_purchased_items
from sales
group by customer_id,product_id),
highest_purchase_items as(
select customer_id,m.product_name,no_of_purchased_items,
dense_rank() over(partition by customer_id order by no_of_purchased_items desc) as rnk
from popular_order po inner join menu m
on po.product_id=m.product_id)

select customer_id,group_concat(product_name separator ',' )
from highest_purchase_items
where rnk=1
group by 1;

/* Result
_______________________________
|customer_id |	product_name   |
|	A    |	    ramen          |
|	B    |curry,ramen,sushi    |
|	C    |	    ramen          |
|_____________________________ |  
*/


-- 6. Which item was purchased first by the customer after they became a member?
with cte as(
select s.customer_id,m.product_name,
dense_rank() over(partition by customer_id order by order_date asc) as rnk
from sales s  left join members mem
on mem.customer_id=s.customer_id
inner join menu m
on s.product_id=m.product_id
where s.order_date>=mem.join_date)

select customer_id,group_concat(distinct product_name separator ',' ) as  product_name from cte
where rnk=1
group by customer_id;

/*Result  
____________________________
|customer_id | product_name|
|	A        |	curry	   |
|	B        |	sushi	   |
|____________|_____________|
*/


-- 7. Which item was purchased just before the customer became a member?
with cte as(
select s.customer_id,m.product_name,order_date,
dense_rank() over(partition by customer_id order by order_date desc) as rnk
from sales s  left join members mem
on mem.customer_id=s.customer_id
inner join menu m
on s.product_id=m.product_id
where s.order_date < mem.join_date)

select customer_id,group_concat(distinct product_name separator ',' ) as  product_name from cte
where rnk=1
group by customer_id;

/*Result
_____________________________
|customer_id| product_name  |
|	A       |  sushi,curry  |
|	B       |  sushi	    |
|___________________________|
*/

-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id,count(m.product_name) as total_items,sum(price) as total_amount
from sales s  join members mem
on s.customer_id=mem.customer_id
inner join menu m
on s.product_id=m.product_id and 
s.order_date < mem.join_date
group by s.customer_id
order by customer_id;

/* Result
_________________________________________
|customer_id | total_items |total_amount|
|	A        |	2	       |	25	    |
|	B        |	3	       |	40	    |
_________________________________________
*/

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id,
sum(case when m.product_name='sushi' then price*20 else price*10 end )as points 
from sales s join menu m
on s.product_id=m.product_id 
group by customer_id;
 
 /* Result
_____________________
|customer_id| points |
|    A	    |  860   |
|    B	    |  940   |
|    C	    |  360   |
______________________
*/

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?
select s.customer_id,
sum(case when order_date between join_date and date_add(join_date,interval 6 day) 
 then m.price*20 
 else m.price*10 end) as total_points
from sales s 
join menu m
on s.product_id = m.product_id
join members mem
on s.customer_id = mem.customer_id
where month(order_date)=1
group by s.customer_id
order by customer_id;

/* Result
_____________________
|customer_id| points |
|	A       |	1270 |
|	B       |	720  |
______________________
*/


