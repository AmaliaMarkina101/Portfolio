--Таблица описана в диаграмме "Проектирование_БД_ER"

CREATE DATABASE IF NOT EXISTS order_servise;
USE order_servise;

CREATE TABLE User (
    id_user BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255),
    phone_number VARCHAR(20),
    email VARCHAR(255),
    address VARCHAR(255)
);

CREATE TABLE Courier (
    id_courier BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255),
    phone_number VARCHAR(20),
    status ENUM('Не на работе', 'На смене', 'Доставляет заказ')
);

CREATE TABLE Restaurant (
    id_restaurant BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    address VARCHAR(255),
    status ENUM('Открыт', 'Закрыт'),
    prep_time INT DEFAULT 30
);

CREATE TABLE Restaurant_worktime (
    id_restaurant BIGINT UNSIGNED NOT NULL,
    day_week INT UNSIGNED NOT NULL CHECK(day_week between 1 and 7) COMMENT '1-воскресенье, 2-понедельник и т.д.',
    open_time TIME,
    close_time TIME,
    PRIMARY KEY (id_restaurant, day_week),
    FOREIGN KEY (id_restaurant) REFERENCES Restaurant(id_restaurant)
);

CREATE TABLE Dish (
    id_dish BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    price DECIMAL(10,2),
    type ENUM ('Напиток','Суп','Салат','Закуски','Комбо','Гарнир'),
    cuisine ENUM('Русская','Европейская','Азиатская'),
    status ENUM('Шаблон','Не доступна к заказу','Доступна к заказу'),
    id_restaurant BIGINT UNSIGNED NOT NULL,
    FOREIGN KEY (id_restaurant) REFERENCES Restaurant(id_restaurant)
);

CREATE TABLE `Order` (
    id_order BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    price DECIMAL(10,2) UNSIGNED,
    address VARCHAR(255),
    status_order ENUM('В обработке', 'Готовится', 'Едет к вам', 'Доставлен','Отменен'),
    status_pay_type ENUM('Онлайн', 'При получении'),
    id_user BIGINT UNSIGNED NOT NULL,
    id_courier BIGINT UNSIGNED,
    FOREIGN KEY (id_user) REFERENCES User(id_user),
    FOREIGN KEY (id_courier) REFERENCES Courier(id_courier)
);

CREATE TABLE Order_time (
    id_order_time BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    created DATETIME,
    accepted DATETIME,
    ready DATETIME,
    picked_up DATETIME,
    delivered DATETIME,
    id_order BIGINT UNSIGNED NOT NULL,
    FOREIGN KEY (id_order) REFERENCES `Order`(id_order)
);

CREATE TABLE Order_item (
    id_order_item BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    id_order BIGINT UNSIGNED NOT NULL,
    id_dish BIGINT UNSIGNED NOT NULL,
    FOREIGN KEY (id_order) REFERENCES `Order`(id_order),
    FOREIGN KEY (id_dish) REFERENCES Dish(id_dish)
);