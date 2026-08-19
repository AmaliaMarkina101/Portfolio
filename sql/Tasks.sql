--Задачи основаны на БД, описанной в диаграмме "Проектирование_БД_ER"

-- 1.Вывести 5 ресторанов с самой высокой выручкой.
SELECT R.name, sum(OI.price*OI.quantity) as earnings
FROM Restaurant R LEFT JOIN Dish D ON (R.id_restaurant=D.id_restaurant) 
LEFT JOIN Order_item OI ON (OI.id_dish=D.id_dish) 
GROUP BY R.name, R.id_restaurant 
ORDER BY earnings DESC
LIMIT 5;

--2.Вывести пользователей, которые ничего не заказывали.
SELECT U.id_user, U.full_name 
FROM User U LEFT JOIN Order O ON (U.id_user=O.id_user) 
WHERE O.id_order IS NULL

--3. Добавить в таблицу User колонку loyalty_status ('Новичок', 'Знаток', 'Эксперт', 'Гурман') и подставить значения 
--на основе кол-ва их заказов (50% - новичок, 25% - знаток,15% - эксперт,10% - гурман).

--Логика:
--Добавить колонку в таблицу
--Во вложенном подзапросе создать таблицу из id пользователя, его имени, накопительное кол-во заказов, общее кол-во у всех заказов
--С полученной таблицей подставить значения на основе того, в какой диапазон от общего кол-ва заказов попала накопительныя сумма пользователя
ALTER TABLE User ADD COLUMN loyalty_status ENUM('Новичок', 'Знаток', 'Эксперт', 'Гурман');

UPDATE User u
JOIN (SELECT u.id_user, u.full_name,
    SUM(COUNT(o.id_order)) OVER (ORDER BY COUNT(o.id_order) DESC) AS a,
    SUM(COUNT(o.id_order)) OVER () AS total_sum_orders
    FROM User u LEFT JOIN `Order` o ON u.id_user = o.id_user
    GROUP BY u.id_user) s ON u.id_user = s.id_user
SET u.loyalty_status = CASE 
    WHEN s.a <= ROUND(s.total_sum_orders * 0.50) THEN 'Новичок'
    WHEN s.a <= ROUND(s.total_sum_orders * 0.75) THEN 'Знаток'
    WHEN s.a <= ROUND(s.total_sum_orders * 0.90) THEN 'Эксперт'
    ELSE 'Гурман'
END;

--4.Вывести среднюю разницу между примерным временем доставки и фактической.
--Логика:
--Во вложенном подзапросе создать таблицу из id ресторана и разницы между примерным временем доставки и фактической
--Вывести имя ресторана и среднюю разницу ожидания по ресторану (из-за этого группировка по его id)

SELECT R.name, AVG(a.delay_min) AS avg_time_of_delay FROM (
    SELECT R.id_restaurant, TIMESTAMPDIFF(MINUTE,OT.created,OT.delivered) - R.prep_time - 30 as delay_min
    FROM Order_time OT JOIN Order O ON (OT.id_order=O.id_order)
    JOIN Order_item OI ON (O.id_order=OI.id_order)
    JOIN Dish D ON (OI.id_dish=D.id_dish) 
    JOIN Restaurant R ON (R.id_restaurant=D.id_restaurant) 
    WHERE OT.delivered IS NOT NULL
    GROUP BY O.id_order, R.id_restaurant) AS a 
GROUP by R.id_restaurant;

--5.Вывести самое популярный напиток, суп, гарнир и десерт каждого ресторана
--Логика:
--Создать временную таблицу, так как надо отфильтровать результат оконной функции
--В временной таблице посчитать общее кол-во проданных блюд по каждой позиции,   
--создать партицию по id ресторана и типу блюда
--Вывести самые первые значения партиции
WITH a AS (
    SELECT R.name AS restaurant_name, D.type AS category, D.name AS dish_name, SUM(OI.quantity) AS order_sum, 
    RANK() OVER (PARTITION BY R.id_restaurant, D.type 
    ORDER BY SUM(OI.quantity) DESC) AS rank FROM Restaurant R
    INNER JOIN Dish D ON R.id_restaurant = D.id_restaurant
    INNER JOIN Order_item OI ON D.id_dish = OI.id_dish
    INNER JOIN Order O ON OI.id_order = O.id_order
    WHERE O.status_order != 'Отменен'
    GROUP BY R.id_restaurant, R.name, D.type, D.name)
SELECT restaurant_name, category, dish_name, order_sum
FROM a
WHERE rank = 1
ORDER BY restaurant_name, category;


--6.Вывести самый прибыльный час по каждому дню недели (по самому большому кол-ву заказов)
--Логика:
--Создать временную таблицу, чтобы потом отфильтровать результат оконной функции
--В ней выделить день недели, час из времени создания заказа, кол-во заказов на данный час
--Создать партицию по дням недели,присвоить каждому часу ранг по убыванию 
--Вывести только первые часы (у которых ранг=1)

WITH hourly_stats AS (
    SELECT DAYOFWEEK(OT.created) AS day_of_week, HOUR(OT.created) AS `hour`, COUNT(O.id_order) AS orders_count, 
    RANK() OVER (PARTITION BY DAYOFWEEK(OT.created) ORDER BY COUNT(O.id_order) DESC) AS hour_rank
    FROM Order_time OT
    INNER JOIN Order O ON OT.id_order = O.id_order
    WHERE O.status_order != 'Отменен'
    GROUP BY DAYOFWEEK(OT.created), HOUR(OT.created) )
SELECT CASE day_of_week
        WHEN 1 THEN 'Воскресенье'
        WHEN 2 THEN 'Понедельник'
        WHEN 3 THEN 'Вторник'
        WHEN 4 THEN 'Среда'
        WHEN 5 THEN 'Четверг'
        WHEN 6 THEN 'Пятница'
        WHEN 7 THEN 'Суббота'
    END, `hour`, orders_count
FROM hourly_stats
WHERE hour_rank = 1
ORDER BY day_of_week;

