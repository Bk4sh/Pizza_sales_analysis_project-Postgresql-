select * from order_details;
select * from orders;
select * from pizzas;
select * from pizza_types;

-- Retrieve the total number of orders placed.
select count(*) from orders;

-- Calculate the total revenue generated from pizza sales.
select
	round(sum(pizzas.price * order_details.quantity)::numeric, 2) as total_revenue
from order_details join pizzas on order_details.pizza_id = pizzas.pizza_id;

-- Identify the highest-priced pizza.
select
	pizza_types.name, pizzas.price
from pizzas join pizza_types on pizzas.pizza_type_id = pizza_types.pizza_type_id
where pizzas.price = (select max(price) from pizzas);

-- Identify the most common pizza size ordered.
select
	pizzas.size, count(order_details_id) as order_count
from order_details join pizzas on order_details.pizza_id = pizzas.pizza_id
group by pizzas.size order by count(order_details_id) desc;

-- List the top 5 most ordered pizza types along with their quantities.
select
	pt.name, sum(od.quantity) as total_ordered
from pizza_types pt
join pizzas p on pt.pizza_type_id = p.pizza_type_id
join order_details od on p.pizza_id = od.pizza_id
group by pt.name order by sum(od.quantity) desc limit 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered.
select
	pt.category, sum(od.quantity) as total_ordered_by_category
from pizza_types pt
left join pizzas p on pt.pizza_type_id = p.pizza_type_id
join order_details od on p.pizza_id = od.pizza_id
group by pt.category order by sum(od.quantity) desc;

-- Determine the distribution of orders by hour of the day.
select
	extract(hour from order_time) as hour, count(order_id) as orders_by_hour
from orders group by extract(hour from order_time) order by count(order_id) desc;

-- Join relevant tables to find the category-wise distribution of pizzas.
select
	category, count(pizza_type_id) as total_pizzas
from pizza_types group by category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
with DailyTotalPizzas as (
	select
		o.order_date, sum(quantity) as total_pizzas
	from orders o
	join order_details od on o.order_id = od.order_id
	group by o.order_date
)
select round(avg(total_pizzas), 2) as avg_pizzas_per_day from DailyTotalPizzas;

-- Determine the top 3 most ordered pizza types based on revenue.
select
	pt.name, sum(od.quantity * p.price) as revenue_by_pizzas
from pizza_types pt
join pizzas p on pt.pizza_type_id = p.pizza_type_id
join order_details od on p.pizza_id = od.pizza_id
group by pt.name order by sum(od.quantity * p.price) desc limit 3;

-- Calculate the percentage contribution of each pizza type to total revenue.
with CategoryRevenue as (
	select
		pt.category, sum(od.quantity * p.price) as revenue_by_pizzas
	from pizza_types pt
	join pizzas p on pt.pizza_type_id = p.pizza_type_id
	join order_details od on p.pizza_id = od.pizza_id
	group by pt.category
),
TotalRevenue as (
	select
		sum(revenue_by_pizzas) as total_revenue
	from CategoryRevenue
)
select
	category, cast((100.0 * (revenue_by_pizzas/total_revenue)) as numeric(10,2)) as percentage
from CategoryRevenue, TotalRevenue order by percentage desc;

-- Analyze the cumulative revenue generated over time.
with OrderTotalRevenue as (
	select
		o.order_date,
		sum(od.quantity * p.price) as total
	from orders o
	join order_details od on o.order_id = od.order_id
	join pizzas p on od.pizza_id = p.pizza_id
	group by o.order_date
)
select
	order_date,
	cast(sum(total) over(order by order_date) as numeric(10,2)) as running_revenue
from OrderTotalRevenue;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
with PizzaRevenueByType as (
	select
		pt.name, pt.category, sum(od.quantity * p.price) as revenue
	from pizza_types pt
	join pizzas p on pt.pizza_type_id = p.pizza_type_id
	join order_details od on p.pizza_id = od.pizza_id
	group by pt.name, pt.category
),
TopPizzasByCategory as (
	select
		name, category, revenue,
		row_number() over(partition by category order by revenue desc) as ranking
	from PizzaRevenueByType
)
select
	name, category, revenue
from TopPizzasByCategory where ranking <= 3;