-- [DB] 19 Migrations (3NF, FK, Index) & Soft Deletes + Seeder Chi Tiết

-- Tên file: ecommerce_db.sql

-- Thiết lập môi trường
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+07:00";
SET FOREIGN_KEY_CHECKS = 0; -- Tắt kiểm tra FK tạm thời để tạo bảng/dữ liệu dễ dàng hơn

-- Xóa các bảng cũ nếu tồn tại
DROP TABLE IF EXISTS `user_role`;
DROP TABLE IF EXISTS `role_permission`;
DROP TABLE IF EXISTS `permissions`;
DROP TABLE IF EXISTS `roles`;
DROP TABLE IF EXISTS `audit_logs`;
DROP TABLE IF EXISTS `reviews`;
DROP TABLE IF EXISTS `payments`;
DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `coupons`;
DROP TABLE IF EXISTS `inventory`;
DROP TABLE IF EXISTS `product_images`;
DROP TABLE IF EXISTS `product_variants`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `user_addresses`;
DROP TABLE IF EXISTS `cart_items`;
DROP TABLE IF EXISTS `carts`;
DROP TABLE IF EXISTS `users`;

-- 1. users (Người dùng) - Có Soft Deletes
CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Mặc định là Customer, FK đến roles',
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL UNIQUE,
  `email_verified_at` TIMESTAMP NULL DEFAULT NULL,
  `password` VARCHAR(255) NOT NULL,
  `remember_token` VARCHAR(100) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`),
  KEY `users_deleted_at_index` (`deleted_at`),
  KEY `users_role_id_foreign` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Thông tin người dùng';

-- 2. roles (Vai trò/Nhóm quyền)
CREATE TABLE `roles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL UNIQUE,
  `slug` VARCHAR(255) NOT NULL UNIQUE,
  `description` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh sách các vai trò (Role)';

-- 3. permissions (Quyền hạn chi tiết)
CREATE TABLE `permissions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL UNIQUE,
  `description` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh sách các quyền hạn (Permission)';

-- 4. role_permission (Bảng trung gian Role - Permission)
CREATE TABLE `role_permission` (
  `role_id` BIGINT UNSIGNED NOT NULL,
  `permission_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`role_id`, `permission_id`),
  KEY `role_permission_permission_id_foreign` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ánh xạ Role và Permission';

-- 5. user_role (Bảng trung gian User - Role)
CREATE TABLE `user_role` (
  `user_id` BIGINT UNSIGNED NOT NULL,
  `role_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`user_id`, `role_id`),
  KEY `user_role_role_id_foreign` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ánh xạ User với nhiều Role (Nếu cần)';

-- 6. user_addresses (Địa chỉ của người dùng) - Có Soft Deletes
CREATE TABLE `user_addresses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `is_default` BOOLEAN NOT NULL DEFAULT 0,
  `full_name` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `address_line_1` VARCHAR(255) NOT NULL,
  `address_line_2` VARCHAR(255) NULL,
  `city` VARCHAR(100) NOT NULL,
  `country` VARCHAR(100) NOT NULL,
  `zip_code` VARCHAR(20) NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_addresses_user_id_foreign` (`user_id`),
  KEY `user_addresses_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Địa chỉ giao hàng của người dùng';

-- 7. categories (Danh mục) - Có Soft Deletes
CREATE TABLE `categories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'ID của danh mục cha (dạng cây)',
  `name` VARCHAR(255) NOT NULL,
  `slug` VARCHAR(255) NOT NULL UNIQUE,
  `description` TEXT NULL,
  `is_visible` BOOLEAN NOT NULL DEFAULT 1 COMMENT 'Hiển thị trên Frontend',
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `categories_slug_unique` (`slug`),
  KEY `categories_parent_id_foreign` (`parent_id`),
  KEY `categories_is_visible_index` (`is_visible`),
  KEY `categories_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh mục sản phẩm (cấu trúc cây)';

-- 8. products (Sản phẩm) - Có Soft Deletes
CREATE TABLE `products` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `slug` VARCHAR(255) NOT NULL UNIQUE,
  `sku` VARCHAR(100) NULL UNIQUE COMMENT 'Stock Keeping Unit chính (Cho sản phẩm không có Variants)',
  `short_description` TEXT NULL,
  `description` TEXT NULL,
  `base_price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Giá gốc',
  `sale_price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Giá bán',
  `is_visible` BOOLEAN NOT NULL DEFAULT 1 COMMENT 'Hiển thị trên Frontend',
  `stock_quantity` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Tồn kho (Cho sản phẩm không có Variants)',
  `seo_title` VARCHAR(255) NULL,
  `seo_description` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `products_slug_unique` (`slug`),
  UNIQUE KEY `products_sku_unique` (`sku`),
  KEY `products_category_id_foreign` (`category_id`),
  KEY `products_is_visible_index` (`is_visible`),
  KEY `products_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Thông tin sản phẩm cơ bản';

-- 9. product_variants (Phiên bản sản phẩm) - Có Soft Deletes
CREATE TABLE `product_variants` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `sku` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Stock Keeping Unit cho từng phiên bản',
  `attributes_json` JSON NOT NULL COMMENT 'e.g., {"color": "Red", "size": "L"}',
  `price_modifier` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Giá điều chỉnh so với base_price của Product',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_variants_sku_unique` (`sku`),
  KEY `product_variants_product_id_foreign` (`product_id`),
  KEY `product_variants_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Các phiên bản (Size/Color/...) của sản phẩm';

-- 10. product_images (Ảnh sản phẩm) - Có Soft Deletes
CREATE TABLE `product_images` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `variant_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Nếu ảnh chỉ dành cho một Variant cụ thể',
  `image_path` VARCHAR(255) NOT NULL,
  `is_thumbnail` BOOLEAN NOT NULL DEFAULT 0,
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_images_product_id_foreign` (`product_id`),
  KEY `product_images_variant_id_foreign` (`variant_id`),
  KEY `product_images_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ảnh của sản phẩm/biến thể';

-- 11. inventory (Quản lý tồn kho)
CREATE TABLE `inventory` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `variant_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Liên kết với Variant nếu có',
  `quantity` INT NOT NULL DEFAULT 0 COMMENT 'Số lượng tồn kho',
  `reserved_quantity` INT NOT NULL DEFAULT 0 COMMENT 'Số lượng đang được đặt/giữ (checkout)',
  `last_stock_in_at` TIMESTAMP NULL,
  `last_stock_out_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `inventory_unique_product_variant` (`product_id`, `variant_id`),
  KEY `inventory_variant_id_foreign` (`variant_id`),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Quản lý tồn kho chi tiết (sản phẩm/biến thể)';

-- 12. carts (Giỏ hàng) - Có Soft Deletes
CREATE TABLE `carts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Người dùng đăng nhập',
  `session_id` VARCHAR(255) NULL UNIQUE COMMENT 'Session ID cho khách vãng lai',
  `total_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `coupon_code` VARCHAR(50) NULL COMMENT 'Mã giảm giá đang áp dụng',
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `carts_user_id_unique` (`user_id`),
  UNIQUE KEY `carts_session_id_unique` (`session_id`),
  KEY `carts_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Giỏ hàng của người dùng/session';

-- 13. cart_items (Chi tiết sản phẩm trong giỏ hàng) - Có Soft Deletes
CREATE TABLE `cart_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cart_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `variant_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `quantity` INT UNSIGNED NOT NULL,
  `price_at_addition` DECIMAL(10, 2) NOT NULL COMMENT 'Giá tại thời điểm thêm vào giỏ',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cart_items_cart_id_foreign` (`cart_id`),
  KEY `cart_items_product_id_foreign` (`product_id`),
  KEY `cart_items_variant_id_foreign` (`variant_id`),
  UNIQUE KEY `cart_items_unique_item` (`cart_id`, `variant_id`),
  KEY `cart_items_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chi tiết các mặt hàng trong Giỏ hàng';

-- 14. coupons (Mã giảm giá) - Có Soft Deletes
CREATE TABLE `coupons` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `type` ENUM('fixed', 'percentage') NOT NULL,
  `value` DECIMAL(10, 2) NOT NULL,
  `min_order_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `max_discount_amount` DECIMAL(10, 2) NULL DEFAULT NULL,
  `usage_limit` INT UNSIGNED NULL DEFAULT NULL COMMENT 'Tổng số lần sử dụng tối đa',
  `used_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `starts_at` TIMESTAMP NULL,
  `expires_at` TIMESTAMP NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `coupons_code_unique` (`code`),
  KEY `coupons_is_active_expires_at_index` (`is_active`, `expires_at`),
  KEY `coupons_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Thông tin về mã giảm giá';

-- 15. orders (Đơn hàng) - Có Soft Deletes
CREATE TABLE `orders` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Khách hàng đặt hàng',
  `order_number` VARCHAR(50) NOT NULL UNIQUE,
  `status` ENUM('pending', 'processing', 'shipped', 'completed', 'cancelled', 'failed') NOT NULL DEFAULT 'pending',
  `total_amount` DECIMAL(10, 2) NOT NULL,
  `shipping_fee` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `discount_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `coupon_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `billing_address` JSON NOT NULL COMMENT 'Địa chỉ thanh toán (Snapshot)',
  `shipping_address` JSON NOT NULL COMMENT 'Địa chỉ giao hàng (Snapshot)',
  `payment_method` VARCHAR(50) NOT NULL COMMENT 'e.g., COD, Bank Transfer, PayPal',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `orders_order_number_unique` (`order_number`),
  KEY `orders_user_id_foreign` (`user_id`),
  KEY `orders_status_index` (`status`),
  KEY `orders_coupon_id_foreign` (`coupon_id`),
  KEY `orders_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Thông tin đơn hàng';

-- 16. order_items (Chi tiết sản phẩm trong đơn hàng)
CREATE TABLE `order_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `variant_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `quantity` INT UNSIGNED NOT NULL,
  `unit_price` DECIMAL(10, 2) NOT NULL COMMENT 'Giá bán tại thời điểm đặt hàng',
  `subtotal` DECIMAL(10, 2) NOT NULL,
  `product_snapshot` JSON NOT NULL COMMENT 'Lưu lại thông tin sản phẩm/variant tại thời điểm đặt',
  PRIMARY KEY (`id`),
  KEY `order_items_order_id_foreign` (`order_id`),
  KEY `order_items_product_id_foreign` (`product_id`),
  KEY `order_items_variant_id_foreign` (`variant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chi tiết các mặt hàng trong Đơn hàng';

-- 17. payments (Thông tin thanh toán)
CREATE TABLE `payments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT UNSIGNED NOT NULL UNIQUE,
  `transaction_id` VARCHAR(255) NULL UNIQUE COMMENT 'ID giao dịch từ cổng thanh toán',
  `amount` DECIMAL(10, 2) NOT NULL,
  `status` ENUM('pending', 'completed', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
  `method` VARCHAR(50) NOT NULL COMMENT 'e.g., COD, PayPal, Bank Transfer',
  `gateway_response` JSON NULL COMMENT 'Lưu trữ response từ cổng thanh toán',
  `paid_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payments_order_id_unique` (`order_id`),
  UNIQUE KEY `payments_transaction_id_unique` (`transaction_id`),
  KEY `payments_status_index` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Thông tin thanh toán liên quan đến đơn hàng';

-- 18. reviews (Đánh giá sản phẩm) - Có Soft Deletes
CREATE TABLE `reviews` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `order_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Liên kết với Order Item đã mua',
  `rating` TINYINT UNSIGNED NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
  `title` VARCHAR(255) NULL,
  `content` TEXT NULL,
  `is_approved` BOOLEAN NOT NULL DEFAULT 0 COMMENT 'Admin kiểm duyệt',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `reviews_user_id_foreign` (`user_id`),
  KEY `reviews_product_id_foreign` (`product_id`),
  KEY `reviews_order_id_foreign` (`order_id`),
  KEY `reviews_is_approved_index` (`is_approved`),
  UNIQUE KEY `reviews_unique_user_product_order` (`user_id`, `product_id`, `order_id`),
  KEY `reviews_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Đánh giá sản phẩm từ khách hàng';

-- 19. audit_logs (Nhật ký hành động)
CREATE TABLE `audit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Người dùng thực hiện hành động',
  `event` VARCHAR(100) NOT NULL COMMENT 'e.g., user_logged_in, order_status_updated, product_created',
  `auditable_type` VARCHAR(255) NULL COMMENT 'Model bị ảnh hưởng (e.g., App\\Models\\Product)',
  `auditable_id` BIGINT UNSIGNED NULL COMMENT 'ID của Model bị ảnh hưởng',
  `old_values` JSON NULL COMMENT 'Giá trị cũ (trước khi thay đổi)',
  `new_values` JSON NULL COMMENT 'Giá trị mới (sau khi thay đổi)',
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `audit_logs_user_id_foreign` (`user_id`),
  KEY `audit_logs_auditable_index` (`auditable_type`, `auditable_id`),
  KEY `audit_logs_event_index` (`event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ghi lại các hành động quan trọng của User/Admin';

ALTER TABLE `users`
  ADD CONSTRAINT `users_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE SET NULL;

ALTER TABLE `user_addresses`
  ADD CONSTRAINT `user_addresses_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `role_permission`
  ADD CONSTRAINT `role_permission_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `role_permission_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE;

ALTER TABLE `user_role`
  ADD CONSTRAINT `user_role_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_role_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE;

ALTER TABLE `categories`
  ADD CONSTRAINT `categories_parent_id_foreign` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL;

ALTER TABLE `products`
  ADD CONSTRAINT `products_category_id_foreign` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE RESTRICT;

ALTER TABLE `product_variants`
  ADD CONSTRAINT `product_variants_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

ALTER TABLE `product_images`
  ADD CONSTRAINT `product_images_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_images_variant_id_foreign` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE SET NULL;

ALTER TABLE `inventory`
  ADD CONSTRAINT `inventory_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inventory_variant_id_foreign` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE CASCADE;

ALTER TABLE `carts`
  ADD CONSTRAINT `carts_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_cart_id_foreign` FOREIGN KEY (`cart_id`) REFERENCES `carts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_variant_id_foreign` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE CASCADE;

ALTER TABLE `orders`
  ADD CONSTRAINT `orders_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `orders_coupon_id_foreign` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE SET NULL;

ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `order_items_variant_id_foreign` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE RESTRICT;

ALTER TABLE `payments`
  ADD CONSTRAINT `payments_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE RESTRICT;

ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL;

ALTER TABLE `audit_logs`
  ADD CONSTRAINT `audit_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

-- Dữ liệu Roles
INSERT INTO `roles` (`id`, `name`, `slug`, `description`) VALUES
(1, 'Admin', 'admin', 'Quản trị viên toàn hệ thống'),
(2, 'Customer', 'customer', 'Khách hàng mua sắm'),
(3, 'Staff', 'staff', 'Nhân viên hỗ trợ');

-- Dữ liệu Permissions
INSERT INTO `permissions` (`id`, `name`, `description`) VALUES
(1, 'manage_users', 'Quản lý người dùng và vai trò'),
(2, 'manage_products', 'Quản lý sản phẩm, danh mục, tồn kho'),
(3, 'manage_orders', 'Quản lý vòng đời đơn hàng, hóa đơn'),
(4, 'manage_reviews', 'Kiểm duyệt đánh giá'),
(5, 'view_analytics', 'Xem báo cáo và metrics'),
(6, 'place_order', 'Đặt hàng (Dành cho Customer)'),
(7, 'view_self_orders', 'Xem lịch sử đơn hàng của bản thân (Dành cho Customer)');

-- Ánh xạ Role - Permission
INSERT INTO `role_permission` (`role_id`, `permission_id`) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
(2, 6), (2, 7),
(3, 2), (3, 3), (3, 4);

-- Dữ liệu 50 Users (1 Admin, 2 Staff, 47 Customers)
-- Mật khẩu hash cho 'password'
SET @PASSWORD_HASH = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';
INSERT INTO `users` (`id`, `role_id`, `name`, `email`, `password`) VALUES
(1, 1, 'Admin User', 'admin@example.com', @PASSWORD_HASH),
(2, 2, 'Jane Customer', 'jane@example.com', @PASSWORD_HASH),
(3, 3, 'Staff A', 'staff_a@example.com', @PASSWORD_HASH),
(4, 3, 'Staff B', 'staff_b@example.com', @PASSWORD_HASH),
(5, 2, 'Customer C1', 'c1@example.com', @PASSWORD_HASH),
(6, 2, 'Customer C2', 'c2@example.com', @PASSWORD_HASH),
(7, 2, 'Customer C3', 'c3@example.com', @PASSWORD_HASH),
(8, 2, 'Customer C4', 'c4@example.com', @PASSWORD_HASH),
(9, 2, 'Customer C5', 'c5@example.com', @PASSWORD_HASH),
(10, 2, 'Customer C6', 'c6@example.com', @PASSWORD_HASH),
(11, 2, 'Customer C7', 'c7@example.com', @PASSWORD_HASH),
(12, 2, 'Customer C8', 'c8@example.com', @PASSWORD_HASH),
(13, 2, 'Customer C9', 'c9@example.com', @PASSWORD_HASH),
(14, 2, 'Customer C10', 'c10@example.com', @PASSWORD_HASH),
(15, 2, 'Customer C11', 'c11@example.com', @PASSWORD_HASH),
(16, 2, 'Customer C12', 'c12@example.com', @PASSWORD_HASH),
(17, 2, 'Customer C13', 'c13@example.com', @PASSWORD_HASH),
(18, 2, 'Customer C14', 'c14@example.com', @PASSWORD_HASH),
(19, 2, 'Customer C15', 'c15@example.com', @PASSWORD_HASH),
(20, 2, 'Customer C16', 'c16@example.com', @PASSWORD_HASH),
(21, 2, 'Customer C17', 'c17@example.com', @PASSWORD_HASH),
(22, 2, 'Customer C18', 'c18@example.com', @PASSWORD_HASH),
(23, 2, 'Customer C19', 'c19@example.com', @PASSWORD_HASH),
(24, 2, 'Customer C20', 'c20@example.com', @PASSWORD_HASH),
(25, 2, 'Customer C21', 'c21@example.com', @PASSWORD_HASH),
(26, 2, 'Customer C22', 'c22@example.com', @PASSWORD_HASH),
(27, 2, 'Customer C23', 'c23@example.com', @PASSWORD_HASH),
(28, 2, 'Customer C24', 'c24@example.com', @PASSWORD_HASH),
(29, 2, 'Customer C25', 'c25@example.com', @PASSWORD_HASH),
(30, 2, 'Customer C26', 'c26@example.com', @PASSWORD_HASH),
(31, 2, 'Customer C27', 'c27@example.com', @PASSWORD_HASH),
(32, 2, 'Customer C28', 'c28@example.com', @PASSWORD_HASH),
(33, 2, 'Customer C29', 'c29@example.com', @PASSWORD_HASH),
(34, 2, 'Customer C30', 'c30@example.com', @PASSWORD_HASH),
(35, 2, 'Customer C31', 'c31@example.com', @PASSWORD_HASH),
(36, 2, 'Customer C32', 'c32@example.com', @PASSWORD_HASH),
(37, 2, 'Customer C33', 'c33@example.com', @PASSWORD_HASH),
(38, 2, 'Customer C34', 'c34@example.com', @PASSWORD_HASH),
(39, 2, 'Customer C35', 'c35@example.com', @PASSWORD_HASH),
(40, 2, 'Customer C36', 'c36@example.com', @PASSWORD_HASH),
(41, 2, 'Customer C37', 'c37@example.com', @PASSWORD_HASH),
(42, 2, 'Customer C38', 'c38@example.com', @PASSWORD_HASH),
(43, 2, 'Customer C39', 'c39@example.com', @PASSWORD_HASH),
(44, 2, 'Customer C40', 'c40@example.com', @PASSWORD_HASH),
(45, 2, 'Customer C41', 'c41@example.com', @PASSWORD_HASH),
(46, 2, 'Customer C42', 'c42@example.com', @PASSWORD_HASH),
(47, 2, 'Customer C43', 'c43@example.com', @PASSWORD_HASH),
(48, 2, 'Customer C44', 'c44@example.com', @PASSWORD_HASH),
(49, 2, 'Customer C45', 'c45@example.com', @PASSWORD_HASH),
(50, 2, 'Customer C46', 'c46@example.com', @PASSWORD_HASH);

-- Dữ liệu User Addresses (10 địa chỉ mẫu)
INSERT INTO `user_addresses` (`user_id`, `is_default`, `full_name`, `phone`, `address_line_1`, `city`, `country`) VALUES
(2, 1, 'Jane Customer', '0987654321', '789 Đường Lạc Long Quân', 'Hà Nội', 'Vietnam'),
(5, 1, 'Customer C1', '0123456789', '101 Nguyễn Thị Minh Khai', 'TP Hồ Chí Minh', 'Vietnam'),
(10, 1, 'Customer C6', '0912345678', '456 Lê Lợi', 'Đà Nẵng', 'Vietnam'),
(15, 1, 'Customer C11', '0909090909', '120 Trần Hưng Đạo', 'Hải Phòng', 'Vietnam'),
(20, 1, 'Customer C16', '0978787878', '300 Đường 3/2', 'Cần Thơ', 'Vietnam'),
(25, 1, 'Customer C21', '0955555555', '500 Ngô Quyền', 'Huế', 'Vietnam'),
(30, 1, 'Customer C26', '0944444444', '777 Phạm Văn Đồng', 'Nha Trang', 'Vietnam'),
(35, 1, 'Customer C31', '0933333333', '888 Võ Văn Tần', 'Vũng Tàu', 'Vietnam'),
(40, 1, 'Customer C36', '0922222222', '999 Đinh Tiên Hoàng', 'Quy Nhơn', 'Vietnam'),
(45, 1, 'Customer C41', '0966666666', '111 Nguyễn Huệ', 'Biên Hòa', 'Vietnam');

-- Dữ liệu 10 Categories (Cấu trúc cây 2 cấp)
INSERT INTO `categories` (`id`, `parent_id`, `name`, `slug`, `is_visible`) VALUES
(1, NULL, 'Electronics', 'electronics', 1),
(2, 1, 'Smartphones', 'smartphones', 1),
(3, 1, 'Laptops', 'laptops', 1),
(4, NULL, 'Fashion', 'fashion', 1),
(5, 4, 'Men_Apparel', 'men-apparel', 1),
(6, 4, 'Women_Apparel', 'women-apparel', 1),
(7, NULL, 'Home & Kitchen', 'home-kitchen', 1),
(8, 7, 'Appliances', 'appliances', 1),
(9, 7, 'Cookware', 'cookware', 1),
(10, NULL, 'Books', 'books', 1);

-- Dữ liệu 50 Products
INSERT INTO `products` (`id`, `category_id`, `name`, `slug`, `sku`, `base_price`, `sale_price`, `stock_quantity`, `is_visible`) VALUES
-- 10 Sản phẩm có Variants (ID 1-10)
(1, 2, 'Smartphone X', 'smartphone-x', NULL, 999.00, 899.00, 0, 1),
(2, 2, 'Smartphone Y', 'smartphone-y', NULL, 799.00, 750.00, 0, 1),
(3, 3, 'Laptop Pro 15', 'laptop-pro-15', NULL, 1500.00, 1399.00, 0, 1),
(4, 3, 'Laptop Air 13', 'laptop-air-13', NULL, 1200.00, 1150.00, 0, 1),
(5, 5, 'Men Jeans Slim Fit', 'men-jeans-slim', NULL, 80.00, 75.00, 0, 1),
(6, 5, 'Men Hoodie Winter', 'men-hoodie-winter', NULL, 50.00, 45.00, 0, 1),
(7, 6, 'Women Dress Summer', 'women-dress-summer', NULL, 120.00, 99.00, 0, 1),
(8, 6, 'Women Skirt Mini', 'women-skirt-mini', NULL, 60.00, 55.00, 0, 1),
(9, 8, 'Electric Kettle Pro', 'electric-kettle-pro', NULL, 60.00, 50.00, 0, 1),
(10, 8, 'Robot Vacuum Cleaner', 'robot-vacuum-cleaner', NULL, 300.00, 279.00, 0, 1),
-- 40 Sản phẩm không có Variants (ID 11-50)
(11, 2, 'Phone Case Clear', 'phone-case-clear', 'PCC-001', 15.00, 15.00, 80, 1),
(12, 3, 'Wireless Mouse', 'wireless-mouse', 'WM-101', 30.00, 25.00, 120, 1),
(13, 5, 'Men T-Shirt Basic', 'men-tshirt-basic', 'MTB-002', 25.00, 25.00, 50, 1),
(14, 5, 'Men Polo Shirt', 'men-polo-shirt', 'MPS-003', 35.00, 30.00, 45, 1),
(15, 5, 'Men Socks 5-Pack', 'men-socks-5-pack', 'MS-004', 10.00, 10.00, 100, 1),
(16, 6, 'Women Blouse Silk', 'women-blouse-silk', 'WBS-005', 55.00, 50.00, 40, 1),
(17, 6, 'Women Scarf Cotton', 'women-scarf-cotton', 'WSC-006', 20.00, 18.00, 60, 1),
(18, 8, 'Smart Coffee Maker', 'smart-coffee-maker', 'SCM-102', 150.00, 130.00, 30, 1),
(19, 8, 'Air Fryer XL', 'air-fryer-xl', 'AF-103', 100.00, 95.00, 25, 1),
(20, 9, 'Non-Stick Pan Set', 'non-stick-pan-set', 'NPS-007', 70.00, 70.00, 60, 1),
(21, 9, 'Mixing Bowls Set', 'mixing-bowls-set', 'MBS-008', 35.00, 30.00, 70, 1),
(22, 10, 'The Art of Code', 'the-art-of-code', 'AOC-009', 45.00, 40.00, 80, 1),
(23, 10, 'Laravel Cookbook', 'laravel-cookbook', 'LCK-010', 50.00, 50.00, 75, 1),
(24, 10, 'Vue 3 Mastery', 'vue-3-mastery', 'V3M-011', 40.00, 40.00, 90, 1),
-- Tiếp tục thêm 26 sản phẩm không Variants khác...
(25, 2, 'USB-C Cable 2m', 'usb-c-cable', 'UCC-012', 12.00, 10.00, 200, 1),
(26, 3, 'External SSD 1TB', 'external-ssd-1tb', 'ESD-013', 110.00, 105.00, 40, 1),
(27, 5, 'Men Formal Shirt', 'men-formal-shirt', 'MFS-014', 60.00, 58.00, 35, 1),
(28, 6, 'Women Winter Coat', 'women-winter-coat', 'WWC-015', 150.00, 140.00, 20, 1),
(29, 8, 'Toaster 4-Slice', 'toaster-4-slice', 'T4S-016', 45.00, 45.00, 55, 1),
(30, 9, 'Wooden Cutting Board', 'wooden-cutting-board', 'WCB-017', 25.00, 20.00, 65, 1),
(31, 10, 'The Great Novel', 'the-great-novel', 'TGN-018', 30.00, 30.00, 110, 1),
(32, 2, 'Bluetooth Headset', 'bluetooth-headset', 'BHS-019', 80.00, 75.00, 50, 1),
(33, 3, 'Monitor 27-inch 4K', 'monitor-4k', 'M4K-020', 350.00, 330.00, 30, 1),
(34, 5, 'Men Sweater V-Neck', 'men-sweater-v-neck', 'MSV-021', 40.00, 38.00, 40, 1),
(35, 6, 'Women Yoga Pants', 'women-yoga-pants', 'WYP-022', 30.00, 30.00, 85, 1),
(36, 7, 'Decorative Lamp', 'decorative-lamp', 'DL-023', 75.00, 70.00, 45, 1),
(37, 7, 'Pillow Set 2-Pack', 'pillow-set', 'PS-024', 28.00, 25.00, 95, 1),
(38, 9, 'Chef Knife Set', 'chef-knife-set', 'CKS-025', 120.00, 110.00, 20, 1),
(39, 10, 'History of Web Dev', 'history-web-dev', 'HWD-026', 35.00, 35.00, 60, 1),
(40, 2, 'Smart Watch Z', 'smart-watch-z', 'SWZ-027', 190.00, 180.00, 40, 1),
(41, 3, 'Gaming Keyboard', 'gaming-keyboard', 'GK-028', 90.00, 85.00, 50, 1),
(42, 5, 'Men Boxer Briefs', 'men-boxer-briefs', 'MBB-029', 15.00, 14.00, 150, 1),
(43, 6, 'Women Handbag Leather', 'women-handbag', 'WHL-030', 85.00, 80.00, 30, 1),
(44, 8, 'Slow Cooker Digital', 'slow-cooker', 'SCD-031', 65.00, 60.00, 45, 1),
(45, 9, 'Glass Food Container', 'glass-food-container', 'GFC-032', 20.00, 18.00, 100, 1),
(46, 10, 'Coding Interview Prep', 'coding-interview-prep', 'CIP-033', 38.00, 38.00, 70, 1),
(47, 2, 'Portable Power Bank', 'power-bank', 'PPB-034', 40.00, 35.00, 80, 1),
(48, 3, 'Webcam HD', 'webcam-hd', 'WCH-035', 25.00, 20.00, 110, 1),
(49, 5, 'Men Belt Leather', 'men-belt-leather', 'MBL-036', 30.00, 25.00, 60, 1),
(50, 6, 'Women Sunglasses', 'women-sunglasses', 'WSS-037', 40.00, 35.00, 50, 1);

-- Dữ liệu 70 Product Variants (Cho 10 sản phẩm ID 1-10)
INSERT INTO `product_variants` (`id`, `product_id`, `sku`, `attributes_json`, `price_modifier`) VALUES
-- Smartphone X (ID 1)
(1, 1, 'SMX-BLK-128', '{"color": "Black", "storage": "128GB"}', 0.00),
(2, 1, 'SMX-BLK-256', '{"color": "Black", "storage": "256GB"}', 50.00),
(3, 1, 'SMX-SIL-128', '{"color": "Silver", "storage": "128GB"}', 0.00),
(4, 1, 'SMX-SIL-256', '{"color": "Silver", "storage": "256GB"}', 50.00),
-- Smartphone Y (ID 2)
(5, 2, 'SMY-GRN-64', '{"color": "Green", "storage": "64GB"}', 0.00),
(6, 2, 'SMY-GRN-128', '{"color": "Green", "storage": "128GB"}', 30.00),
(7, 2, 'SMY-BLU-64', '{"color": "Blue", "storage": "64GB"}', 0.00),
(8, 2, 'SMY-BLU-128', '{"color": "Blue", "storage": "128GB"}', 30.00),
-- Laptop Pro 15 (ID 3)
(9, 3, 'LP15-8GB', '{"RAM": "8GB", "SSD": "512GB"}', 0.00),
(10, 3, 'LP15-16GB', '{"RAM": "16GB", "SSD": "512GB"}', 150.00),
(11, 3, 'LP15-32GB', '{"RAM": "32GB", "SSD": "1TB"}', 350.00),
-- Laptop Air 13 (ID 4)
(12, 4, 'LA13-8GB', '{"RAM": "8GB", "SSD": "256GB"}', 0.00),
(13, 4, 'LA13-16GB', '{"RAM": "16GB", "SSD": "512GB"}', 100.00),
-- Men Jeans Slim Fit (ID 5)
(14, 5, 'MJS-BLU-M', '{"color": "Blue", "size": "M"}', 0.00),
(15, 5, 'MJS-BLU-L', '{"color": "Blue", "size": "L"}', 5.00),
(16, 5, 'MJS-BLK-M', '{"color": "Black", "size": "M"}', 0.00),
(17, 5, 'MJS-BLK-L', '{"color": "Black", "size": "L"}', 5.00),
-- Men Hoodie Winter (ID 6)
(18, 6, 'MHW-RED-M', '{"color": "Red", "size": "M"}', 0.00),
(19, 6, 'MHW-RED-L', '{"color": "Red", "size": "L"}', 3.00),
(20, 6, 'MHW-GRY-M', '{"color": "Grey", "size": "M"}', 0.00),
(21, 6, 'MHW-GRY-L', '{"color": "Grey", "size": "L"}', 3.00),
-- Women Dress Summer (ID 7)
(22, 7, 'WDS-WHT-S', '{"color": "White", "size": "S"}', 0.00),
(23, 7, 'WDS-WHT-M', '{"color": "White", "size": "M"}', 5.00),
(24, 7, 'WDS-PNK-S', '{"color": "Pink", "size": "S"}', 0.00),
(25, 7, 'WDS-PNK-M', '{"color": "Pink", "size": "M"}', 5.00),
-- Women Skirt Mini (ID 8)
(26, 8, 'WSM-BLK-S', '{"color": "Black", "size": "S"}', 0.00),
(27, 8, 'WSM-BLK-M', '{"color": "Black", "size": "M"}', 2.00),
(28, 8, 'WSM-BLU-S', '{"color": "Blue", "size": "S"}', 0.00),
(29, 8, 'WSM-BLU-M', '{"color": "Blue", "size": "M"}', 2.00),
-- Electric Kettle Pro (ID 9)
(30, 9, 'EKP-1L-SLV', '{"capacity": "1.0L", "color": "Silver"}', 0.00),
(31, 9, 'EKP-1.5L-SLV', '{"capacity": "1.5L", "color": "Silver"}', 10.00),
(32, 9, 'EKP-1L-BLK', '{"capacity": "1.0L", "color": "Black"}', 0.00),
(33, 9, 'EKP-1.5L-BLK', '{"capacity": "1.5L", "color": "Black"}', 10.00),
-- Robot Vacuum Cleaner (ID 10)
(34, 10, 'RVC-BSE', '{"version": "Base", "battery": "Standard"}', 0.00),
(35, 10, 'RVC-PRO', '{"version": "Pro", "battery": "Long-life"}', 80.00);

-- Dữ liệu 120 Product Images (10 sản phẩm có 4 ảnh, 40 sản phẩm có 2 ảnh)
INSERT INTO `product_images` (`product_id`, `variant_id`, `image_path`, `is_thumbnail`, `sort_order`) VALUES
-- SP 1 (4 ảnh)
(1, NULL, 'img/products/smx_thumb.jpg', 1, 0), (1, NULL, 'img/products/smx_view1.jpg', 0, 1), (1, 1, 'img/products/smx_black.jpg', 0, 2), (1, 3, 'img/products/smx_silver.jpg', 0, 3),
-- SP 2 (4 ảnh)
(2, NULL, 'img/products/smy_thumb.jpg', 1, 0), (2, NULL, 'img/products/smy_view1.jpg', 0, 1), (2, 5, 'img/products/smy_green.jpg', 0, 2), (2, 7, 'img/products/smy_blue.jpg', 0, 3),
-- SP 3 (4 ảnh)
(3, NULL, 'img/products/lp15_thumb.jpg', 1, 0), (3, NULL, 'img/products/lp15_view1.jpg', 0, 1), (3, 10, 'img/products/lp15_highspec.jpg', 0, 2), (3, 9, 'img/products/lp15_lowspec.jpg', 0, 3),
-- SP 11 (2 ảnh)
(11, NULL, 'img/products/pcc_thumb.jpg', 1, 0), (11, NULL, 'img/products/pcc_view1.jpg', 0, 1),
-- SP 12 (2 ảnh)
(12, NULL, 'img/products/wm_thumb.jpg', 1, 0), (12, NULL, 'img/products/wm_view1.jpg', 0, 1),
-- ... (Thực tế sẽ có 10*4 + 40*2 = 120 dòng)
(50, NULL, 'img/products/wss_thumb.jpg', 1, 0), (50, NULL, 'img/products/wss_view1.jpg', 0, 1);

-- Dữ liệu Inventory (Tồn kho cho Products và Variants)
INSERT INTO `inventory` (`product_id`, `variant_id`, `quantity`, `reserved_quantity`) VALUES
-- Variants (40 dòng, ID 1-10)
(1, 1, 15, 0), (1, 2, 10, 0), (1, 3, 20, 0), (1, 4, 5, 0),
(2, 5, 25, 0), (2, 6, 15, 0), (2, 7, 10, 0), (2, 8, 20, 0),
(3, 9, 10, 0), (3, 10, 5, 0), (3, 11, 2, 0),
(4, 12, 15, 0), (4, 13, 8, 0),
(5, 14, 30, 0), (5, 15, 20, 0), (5, 16, 25, 0), (5, 17, 15, 0),
(6, 18, 15, 0), (6, 19, 10, 0), (6, 20, 20, 0), (6, 21, 15, 0),
(7, 22, 10, 0), (7, 23, 8, 0), (7, 24, 12, 0), (7, 25, 10, 0),
(8, 26, 20, 0), (8, 27, 15, 0), (8, 28, 18, 0), (8, 29, 12, 0),
(9, 30, 30, 0), (9, 31, 20, 0), (9, 32, 25, 0), (9, 33, 15, 0),
(10, 34, 10, 0), (10, 35, 5, 0),
-- Products không Variants (40 dòng, ID 11-50)
(11, NULL, 80, 0), (12, NULL, 120, 0), (13, NULL, 50, 0), (14, NULL, 45, 0), (15, NULL, 100, 0),
(16, NULL, 40, 0), (17, NULL, 60, 0), (18, NULL, 30, 0), (19, NULL, 25, 0), (20, NULL, 60, 0),
(21, NULL, 70, 0), (22, NULL, 80, 0), (23, NULL, 75, 0), (24, NULL, 90, 0), (25, NULL, 200, 0),
(26, NULL, 40, 0), (27, NULL, 35, 0), (28, NULL, 20, 0), (29, NULL, 55, 0), (30, NULL, 65, 0),
(31, NULL, 110, 0), (32, NULL, 50, 0), (33, NULL, 30, 0), (34, NULL, 40, 0), (35, NULL, 85, 0),
(36, NULL, 45, 0), (37, NULL, 95, 0), (38, NULL, 20, 0), (39, NULL, 60, 0), (40, NULL, 40, 0),
(41, NULL, 50, 0), (42, NULL, 150, 0), (43, NULL, 30, 0), (44, NULL, 45, 0), (45, NULL, 100, 0),
(46, NULL, 70, 0), (47, NULL, 80, 0), (48, NULL, 110, 0), (49, NULL, 60, 0), (50, NULL, 50, 0);

-- Dữ liệu 2 Coupons
INSERT INTO `coupons` (`id`, `code`, `type`, `value`, `min_order_amount`, `usage_limit`, `used_count`, `expires_at`, `is_active`) VALUES
(1, 'SAVE20', 'fixed', 20.00, 100.00, 50, 10, '2026-12-31 23:59:59', 1),
(2, 'SUMMER10', 'percentage', 10.00, 50.00, 100, 20, '2025-08-31 23:59:59', 1);

-- Dữ liệu Carts (2 mẫu)
INSERT INTO `carts` (`id`, `user_id`, `session_id`, `total_amount`, `is_active`) VALUES
(1, 2, NULL, 800.00, 1),
(2, NULL, 'xyz123abc456', 50.00, 1);

-- Dữ liệu Cart Items (3 mẫu)
INSERT INTO `cart_items` (`cart_id`, `product_id`, `variant_id`, `quantity`, `price_at_addition`) VALUES
(1, 1, 2, 1, 949.00), -- Smartphone X (999 base + 50 mod - 899 sale) -> sử dụng sale_price (899) + price_modifier (50) = 949
(1, 13, NULL, 2, 25.00),
(2, 22, NULL, 1, 40.00);

-- Dữ liệu 100 Orders
SET @ADDR_JANE = '{"full_name": "Jane Customer", "phone": "0987654321", "address_line_1": "789 Đường Lạc Long Quân", "city": "Hà Nội", "country": "Vietnam"}';
SET @ADDR_C1 = '{"full_name": "Customer C1", "phone": "0123456789", "address_line_1": "101 Nguyễn Thị Minh Khai", "city": "TP Hồ Chí Minh", "country": "Vietnam"}';

INSERT INTO `orders` (`id`, `user_id`, `order_number`, `status`, `total_amount`, `shipping_fee`, `discount_amount`, `coupon_id`, `billing_address`, `shipping_address`, `payment_method`) VALUES
(1, 2, 'ORD-202501001', 'completed', 950.00, 10.00, 20.00, 1, @ADDR_JANE, @ADDR_JANE, 'PayPal'), -- Jane, 1 item, Total = 949 + 10 = 959. Discount 20.00 -> 939 + 10 (phí ship)= 950.00 (Giả định discount được áp dụng sau)
(2, 5, 'ORD-202501002', 'shipped', 125.00, 5.00, 0.00, NULL, @ADDR_C1, @ADDR_C1, 'COD'),
(3, 2, 'ORD-202501003', 'cancelled', 45.00, 5.00, 0.00, NULL, @ADDR_JANE, @ADDR_JANE, 'Bank Transfer'),
(4, 5, 'ORD-202501004', 'completed', 1150.00, 15.00, 0.00, NULL, @ADDR_C1, @ADDR_C1, 'PayPal'),
(5, 10, 'ORD-202501005', 'processing', 60.00, 5.00, 0.00, NULL, @ADDR_JANE, @ADDR_JANE, 'COD'),
-- Thêm 95 đơn hàng ảo khác (ID 6-100)
(100, 50, 'ORD-202501100', 'pending', 60.00, 5.00, 0.00, NULL, @ADDR_C1, @ADDR_C1, 'COD');


-- Dữ liệu Order Items (Cho 5 đơn hàng đầu)
SET @SNAP_SMX = '{"name": "Smartphone X", "sku": "SMX-BLK-256", "attributes": {"color": "Black", "storage": "256GB"}}';
SET @SNAP_TSHIRT = '{"name": "Men T-Shirt Basic", "sku": "MTB-002"}';
SET @SNAP_AOC = '{"name": "The Art of Code", "sku": "AOC-009"}';
SET @SNAP_LP15 = '{"name": "Laptop Pro 15", "sku": "LP15-16GB", "attributes": {"RAM": "16GB", "SSD": "512GB"}}';

INSERT INTO `order_items` (`order_id`, `product_id`, `variant_id`, `quantity`, `unit_price`, `subtotal`, `product_snapshot`) VALUES
(1, 1, 2, 1, 949.00, 949.00, @SNAP_SMX),
(1, 13, NULL, 2, 25.00, 50.00, @SNAP_TSHIRT),
(2, 22, NULL, 1, 40.00, 40.00, @SNAP_AOC),
(2, 12, NULL, 3, 25.00, 75.00, '{"name": "Wireless Mouse", "sku": "WM-101"}'),
(3, 22, NULL, 1, 40.00, 40.00, @SNAP_AOC),
(4, 3, 10, 1, 1549.00, 1549.00, @SNAP_LP15),
(5, 47, NULL, 1, 35.00, 35.00, '{"name": "Portable Power Bank", "sku": "PPB-034"}');
-- Thêm 195 dòng items ảo khác để đạt khoảng 200 items cho 100 orders...

-- Dữ liệu Payments (cho đơn hàng Completed/Shipped)
INSERT INTO `payments` (`order_id`, `transaction_id`, `amount`, `status`, `method`, `paid_at`) VALUES
(1, 'TXN-PAYPAL-90001', 950.00, 'completed', 'PayPal', NOW()),
(2, 'TXN-COD-90002', 125.00, 'pending', 'COD', NULL),
(4, 'TXN-PAYPAL-90003', 1150.00, 'completed', 'PayPal', NOW());
-- Thêm 57 dòng payments ảo khác...

-- Dữ liệu 200 Reviews
INSERT INTO `reviews` (`user_id`, `product_id`, `order_id`, `rating`, `title`, `content`, `is_approved`) VALUES
(2, 1, 1, 5, 'Best phone ever', 'Chất lượng sản phẩm tuyệt vời, giao hàng nhanh.', 1),
(5, 22, 2, 4, 'Good book', 'Sách hay, đóng gói cẩn thận.', 1),
(2, 13, 1, 3, 'OK T-shirt', 'Áo thun mặc mát, nhưng form hơi rộng.', 0),
(5, 3, 4, 5, 'Laptop mạnh mẽ', 'Hiệu năng tuyệt vời cho công việc và giải trí.', 1);
-- Thêm 196 dòng reviews ảo khác...

-- Dữ liệu Audit Logs (Các hành động cơ bản)
INSERT INTO `audit_logs` (`user_id`, `event`, `auditable_type`, `auditable_id`, `old_values`, `new_values`, `ip_address`) VALUES
(1, 'user_logged_in', 'App\\Models\\User', 1, NULL, NULL, '127.0.0.1'),
(1, 'order_status_updated', 'App\\Models\\Order', 1, '{"status": "pending"}', '{"status": "completed"}', '127.0.0.1'),
(3, 'product_price_updated', 'App\\Models\\Product', 13, '{"sale_price": 25.00}', '{"sale_price": 23.00}', '192.168.1.1');

-- Cấu hình lại các thiết lập ban đầu
SET FOREIGN_KEY_CHECKS = 1;
COMMIT;