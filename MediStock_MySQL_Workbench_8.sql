-- ====================================================================================
-- PROJECT: MEDISTOCK — MEDICINE INVENTORY MANAGEMENT & BUYER ORDERING SYSTEM
-- SCRIPT: MediStock_MySQL_Workbench_8.sql
-- TARGET DBMS: MySQL Workbench 8.0 / MySQL Server 8.0+
-- ARCHITECTURAL PATTERN: Unified Healthcare Inventory & Customer Fulfillment Model
-- CREATED: 2026-10-30
-- ENCODING: UTF-8 (utf8mb4)
-- ENGINE: InnoDB (ACID Compliant Transactions)
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- 0. SAFE ENVIRONMENT CONFIGURATION
-- ------------------------------------------------------------------------------------
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

-- ------------------------------------------------------------------------------------
-- 1. DATABASE SCHEMA INITIALIZATION
-- ------------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS `medistock_db`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `medistock_db`;

-- ====================================================================================
-- SECTION A: CORE FOUNDATION & USER ACCESS (RBAC)
-- ====================================================================================

-- Table 1: STORES / PHARMACIES
-- Supports single-store deployment by default while providing clean multi-store isolation.
CREATE TABLE IF NOT EXISTS `stores` (
    `id` VARCHAR(36) NOT NULL,
    `store_code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `license_number` VARCHAR(80) NOT NULL,
    `phone` VARCHAR(25) NOT NULL,
    `email` VARCHAR(120) NOT NULL,
    `address` VARCHAR(255) NOT NULL,
    `city` VARCHAR(80) NOT NULL,
    `state` VARCHAR(80) NOT NULL,
    `postal_code` VARCHAR(20) NOT NULL,
    `country` VARCHAR(60) NOT NULL DEFAULT 'India',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_store_code` (`store_code`),
    UNIQUE KEY `uq_store_license` (`license_number`),
    KEY `idx_store_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 2: USERS
-- Houses all application users (Buyers, Inventory Managers, Pharmacists, and Administrators).
-- Passwords must store secure BCrypt/Argon2 hashes (never plaintext).
CREATE TABLE IF NOT EXISTS `users` (
    `id` VARCHAR(36) NOT NULL,
    `store_id` VARCHAR(36) NULL,
    `role` ENUM('BUYER', 'INVENTORY_MANAGER', 'PHARMACIST', 'ADMIN') NOT NULL DEFAULT 'BUYER',
    `full_name` VARCHAR(120) NOT NULL,
    `email` VARCHAR(120) NOT NULL,
    `phone` VARCHAR(25) NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `status` ENUM('ACTIVE', 'INACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    `last_login_at` DATETIME NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_email` (`email`),
    KEY `idx_user_role` (`role`),
    KEY `idx_user_store` (`store_id`),
    CONSTRAINT `fk_users_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 3: USER DELIVERY ADDRESSES
-- Supports multiple saved delivery locations per customer (Home, Clinic, Office, etc.).
CREATE TABLE IF NOT EXISTS `user_addresses` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `address_label` VARCHAR(50) NOT NULL DEFAULT 'Home',
    `recipient_name` VARCHAR(120) NOT NULL,
    `phone` VARCHAR(25) NOT NULL,
    `street` VARCHAR(255) NOT NULL,
    `city` VARCHAR(80) NOT NULL,
    `state` VARCHAR(80) NOT NULL,
    `postal_code` VARCHAR(20) NOT NULL,
    `country` VARCHAR(60) NOT NULL DEFAULT 'India',
    `is_default` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_addr_user` (`user_id`),
    CONSTRAINT `fk_addr_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================================
-- SECTION B: MEDICINES CATALOG & SUPPLIERS
-- ====================================================================================

-- Table 4: SUPPLIERS
-- Accredited pharmaceutical manufacturers, laboratories, and authorized distributors.
CREATE TABLE IF NOT EXISTS `suppliers` (
    `id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `contact_person` VARCHAR(120) NOT NULL,
    `email` VARCHAR(120) NOT NULL,
    `phone` VARCHAR(30) NOT NULL,
    `address` VARCHAR(255) NOT NULL,
    `status` ENUM('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    `notes` TEXT NULL,
    `created_at` DATE NOT NULL,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_supplier_name` (`name`),
    KEY `idx_supplier_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 5: MEDICINES CATALOG
-- Master pharmaceutical catalog shared seamlessly across Inventory and Buyer shopfront.
CREATE TABLE IF NOT EXISTS `medicines` (
    `id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `generic_name` VARCHAR(150) NOT NULL,
    `category` VARCHAR(80) NOT NULL,
    `manufacturer` VARCHAR(150) NOT NULL,
    `strength` VARCHAR(60) NOT NULL,
    `unit` VARCHAR(50) NOT NULL,
    `min_stock_threshold` INT UNSIGNED NOT NULL DEFAULT 100,
    `selling_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `description` TEXT NULL,
    `requires_prescription` TINYINT(1) NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATE NOT NULL,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_medicine_name_strength` (`name`, `strength`),
    KEY `idx_med_category` (`category`),
    KEY `idx_med_generic` (`generic_name`),
    KEY `idx_med_active` (`is_active`),
    CONSTRAINT `chk_min_stock` CHECK (`min_stock_threshold` >= 0),
    CONSTRAINT `chk_selling_price` CHECK (`selling_price` >= 0.00)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 6: MEDICINE BATCHES (PHYSICAL LOTS & EXPIRY TRACKING)
-- Authoritative inventory tracking at the batch/lot level.
-- Different batches of the same medicine have distinct quantities, purchase costs, and expiry dates.
CREATE TABLE IF NOT EXISTS `medicine_batches` (
    `id` VARCHAR(36) NOT NULL,
    `medicine_id` VARCHAR(36) NOT NULL,
    `batch_number` VARCHAR(60) NOT NULL,
    `supplier_id` VARCHAR(36) NOT NULL,
    `mfg_date` DATE NOT NULL,
    `expiry_date` DATE NOT NULL,
    `initial_quantity` INT UNSIGNED NOT NULL DEFAULT 0,
    `quantity` INT UNSIGNED NOT NULL DEFAULT 0,
    `purchase_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `quarantined` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATE NOT NULL,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_med_batch_number` (`medicine_id`, `batch_number`),
    KEY `idx_batch_expiry` (`expiry_date`),
    KEY `idx_batch_supplier` (`supplier_id`),
    KEY `idx_batch_qty` (`quantity`),
    CONSTRAINT `fk_batches_medicine` FOREIGN KEY (`medicine_id`) 
        REFERENCES `medicines` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_batches_supplier` FOREIGN KEY (`supplier_id`) 
        REFERENCES `suppliers` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_batch_quantity` CHECK (`quantity` >= 0),
    CONSTRAINT `chk_batch_price` CHECK (`purchase_price` >= 0.00),
    CONSTRAINT `chk_batch_dates` CHECK (`expiry_date` > `mfg_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================================
-- SECTION C: BUYER SHOPPING & ENGAGEMENT (STATE PERSISTENCE)
-- ====================================================================================

-- Table 7: SHOPPING CARTS
-- Persistent shopping cart header linked directly to the customer.
CREATE TABLE IF NOT EXISTS `shopping_carts` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_cart` (`user_id`),
    CONSTRAINT `fk_cart_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 8: CART ITEMS
-- Individual items inside the buyer's shopping cart.
CREATE TABLE IF NOT EXISTS `cart_items` (
    `id` VARCHAR(36) NOT NULL,
    `cart_id` VARCHAR(36) NOT NULL,
    `medicine_id` VARCHAR(36) NOT NULL,
    `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cart_medicine` (`cart_id`, `medicine_id`),
    KEY `idx_cart_item_med` (`medicine_id`),
    CONSTRAINT `fk_cart_items_cart` FOREIGN KEY (`cart_id`) 
        REFERENCES `shopping_carts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cart_items_med` FOREIGN KEY (`medicine_id`) 
        REFERENCES `medicines` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `chk_cart_qty` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 9: WISHLIST (SAVED MEDICATIONS)
-- Tracks medications bookmarked by customers for quick re-ordering.
CREATE TABLE IF NOT EXISTS `wishlists` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `medicine_id` VARCHAR(36) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_wishlist_med` (`user_id`, `medicine_id`),
    KEY `idx_wishlist_user` (`user_id`),
    CONSTRAINT `fk_wishlist_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_wishlist_med` FOREIGN KEY (`medicine_id`) 
        REFERENCES `medicines` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 10: NOTIFICATIONS
-- Customer-facing alerts and dispensary updates.
CREATE TABLE IF NOT EXISTS `notifications` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `message` TEXT NOT NULL,
    `type` ENUM('INFO', 'ORDER', 'ALERT', 'WARNING') NOT NULL DEFAULT 'INFO',
    `is_read` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_notif_user` (`user_id`, `is_read`),
    CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================================
-- SECTION D: UNIFIED BUYER-TO-MANAGER ORDER & FULFILLMENT SYSTEM
-- ====================================================================================

-- Table 11: ORDERS (SHARED SINGLE SOURCE OF TRUTH)
-- Single record accessed by both Buyer Dashboard and Inventory Manager Fulfillment Portal.
CREATE TABLE IF NOT EXISTS `orders` (
    `id` VARCHAR(36) NOT NULL,
    `order_number` VARCHAR(50) NOT NULL,
    `store_id` VARCHAR(36) NULL,
    `buyer_id` VARCHAR(36) NULL,
    `status` ENUM(
        'Pending Review',
        'Confirmed',
        'Preparing',
        'Packed',
        'Shipped',
        'Out for Delivery',
        'Delivered',
        'Completed',
        'Rejected',
        'Cancelled'
    ) NOT NULL DEFAULT 'Pending Review',
    
    -- Monetary Breakdown (in INR / ₹)
    `subtotal` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `delivery_fee` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `tax_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `total_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    
    -- Payment Details
    `payment_method` VARCHAR(60) NOT NULL DEFAULT 'Cash on Delivery (COD)',
    `payment_status` VARCHAR(60) NOT NULL DEFAULT 'Pending on Delivery',
    
    -- Customer Contact Snapshot (Preserved even if user profile changes)
    `customer_name` VARCHAR(120) NOT NULL,
    `customer_email` VARCHAR(120) NOT NULL,
    `customer_phone` VARCHAR(30) NOT NULL,
    
    -- Delivery Address Snapshot
    `shipping_street` VARCHAR(255) NOT NULL,
    `shipping_city` VARCHAR(80) NOT NULL,
    `shipping_state` VARCHAR(80) NOT NULL,
    `shipping_postal_code` VARCHAR(20) NOT NULL,
    `shipping_country` VARCHAR(60) NOT NULL DEFAULT 'India',
    
    -- Courier Logistics & Dispatch Details
    `carrier_name` VARCHAR(100) NULL,
    `tracking_reference` VARCHAR(100) NULL,
    
    -- Stock Control Flags
    `stock_reserved` TINYINT(1) NOT NULL DEFAULT 0,
    `stock_deducted` TINYINT(1) NOT NULL DEFAULT 0,
    
    -- Exceptions & Explanations
    `rejection_reason` TEXT NULL,
    `cancellation_reason` TEXT NULL,
    `notes` TEXT NULL,
    
    -- Workflow Progression Timestamps
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `confirmed_at` DATETIME NULL,
    `dispatched_at` DATETIME NULL,
    `delivered_at` DATETIME NULL,
    `completed_at` DATETIME NULL,
    `estimated_delivery` DATE NULL,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_order_number` (`order_number`),
    KEY `idx_orders_buyer` (`buyer_id`),
    KEY `idx_orders_status` (`status`),
    KEY `idx_orders_created` (`created_at`),
    KEY `idx_orders_store` (`store_id`),
    CONSTRAINT `fk_orders_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_orders_buyer` FOREIGN KEY (`buyer_id`) 
        REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `chk_order_total` CHECK (`total_amount` >= 0.00)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 12: ORDER ITEMS
-- Preserves immutable price, strength, and unit snapshot at time of checkout.
CREATE TABLE IF NOT EXISTS `order_items` (
    `id` VARCHAR(36) NOT NULL,
    `order_id` VARCHAR(36) NOT NULL,
    `medicine_id` VARCHAR(36) NOT NULL,
    `medicine_name_snapshot` VARCHAR(150) NOT NULL,
    `generic_name_snapshot` VARCHAR(150) NOT NULL,
    `category_snapshot` VARCHAR(80) NOT NULL,
    `strength_snapshot` VARCHAR(60) NOT NULL,
    `unit_snapshot` VARCHAR(50) NOT NULL,
    `unit_price` DECIMAL(10,2) NOT NULL,
    `quantity` INT UNSIGNED NOT NULL,
    `subtotal` DECIMAL(10,2) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_oi_order` (`order_id`),
    KEY `idx_oi_medicine` (`medicine_id`),
    CONSTRAINT `fk_oi_order` FOREIGN KEY (`order_id`) 
        REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_oi_medicine` FOREIGN KEY (`medicine_id`) 
        REFERENCES `medicines` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_oi_qty` CHECK (`quantity` > 0),
    CONSTRAINT `chk_oi_subtotal` CHECK (`subtotal` >= 0.00)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 13: ORDER ITEM BATCH ALLOCATIONS
-- Tracks the specific physical batch lot(s) allocated for dispensing each order line item.
-- Critical for pharmaceutical compliance, recall tracing, and FIFO lot tracking.
CREATE TABLE IF NOT EXISTS `order_item_batch_allocations` (
    `id` VARCHAR(36) NOT NULL,
    `order_item_id` VARCHAR(36) NOT NULL,
    `batch_id` VARCHAR(36) NOT NULL,
    `batch_number_snapshot` VARCHAR(60) NOT NULL,
    `quantity` INT UNSIGNED NOT NULL,
    `expiry_date_snapshot` DATE NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_oiba_item` (`order_item_id`),
    KEY `idx_oiba_batch` (`batch_id`),
    CONSTRAINT `fk_oiba_order_item` FOREIGN KEY (`order_item_id`) 
        REFERENCES `order_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_oiba_batch` FOREIGN KEY (`batch_id`) 
        REFERENCES `medicine_batches` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_alloc_qty` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 14: ORDER STATUS HISTORY (AUDIT TRAIL)
-- Maintains an append-only timeline of every stage transition across both portals.
CREATE TABLE IF NOT EXISTS `order_status_history` (
    `id` VARCHAR(36) NOT NULL,
    `order_id` VARCHAR(36) NOT NULL,
    `from_status` VARCHAR(50) NULL,
    `to_status` VARCHAR(50) NOT NULL,
    `changed_by_user_id` VARCHAR(36) NULL,
    `changed_by_name` VARCHAR(120) NOT NULL,
    `note` TEXT NULL,
    `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_osh_order` (`order_id`, `timestamp`),
    CONSTRAINT `fk_osh_order` FOREIGN KEY (`order_id`) 
        REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_osh_user` FOREIGN KEY (`changed_by_user_id`) 
        REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================================
-- SECTION E: INVENTORY RESERVATION & STOCK TRANSACTIONS
-- ====================================================================================

-- Table 15: STOCK TRANSACTIONS (AUDIT LEDGER)
-- Complete ledger of every physical stock addition, deduction, and manual adjustment.
CREATE TABLE IF NOT EXISTS `stock_transactions` (
    `id` VARCHAR(36) NOT NULL,
    `store_id` VARCHAR(36) NULL,
    `type` ENUM('STOCK_IN', 'STOCK_OUT', 'ADJUSTMENT') NOT NULL,
    `medicine_id` VARCHAR(36) NOT NULL,
    `batch_id` VARCHAR(36) NOT NULL,
    `quantity` INT NOT NULL,
    `previous_quantity` INT NOT NULL,
    `new_quantity` INT NOT NULL,
    `reference_order_id` VARCHAR(36) NULL,
    `created_by_user_id` VARCHAR(36) NULL,
    `remarks` TEXT NULL,
    `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_st_med` (`medicine_id`),
    KEY `idx_st_batch` (`batch_id`),
    KEY `idx_st_type` (`type`),
    KEY `idx_st_time` (`timestamp`),
    KEY `idx_st_order` (`reference_order_id`),
    CONSTRAINT `fk_st_medicine` FOREIGN KEY (`medicine_id`) 
        REFERENCES `medicines` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_st_batch` FOREIGN KEY (`batch_id`) 
        REFERENCES `medicine_batches` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_st_order` FOREIGN KEY (`reference_order_id`) 
        REFERENCES `orders` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_st_user` FOREIGN KEY (`created_by_user_id`) 
        REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `chk_st_quantities` CHECK (`new_quantity` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================================
-- SECTION F: SUPPLIER PURCHASING & STOCK INWARD (PHASE 2 COMPATIBLE)
-- ====================================================================================

-- Table 16: PURCHASE ORDERS (STORE -> SUPPLIER)
-- Distinct from customer orders. Used by the inventory manager to replenish stock.
CREATE TABLE IF NOT EXISTS `purchase_orders` (
    `id` VARCHAR(36) NOT NULL,
    `po_number` VARCHAR(50) NOT NULL,
    `store_id` VARCHAR(36) NULL,
    `supplier_id` VARCHAR(36) NOT NULL,
    `status` ENUM('DRAFT', 'ORDERED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED') NOT NULL DEFAULT 'DRAFT',
    `order_date` DATE NOT NULL,
    `expected_delivery_date` DATE NULL,
    `actual_receipt_date` DATE NULL,
    `subtotal` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `tax_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `total_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `created_by_user_id` VARCHAR(36) NULL,
    `notes` TEXT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_po_number` (`po_number`),
    KEY `idx_po_supplier` (`supplier_id`),
    KEY `idx_po_status` (`status`),
    CONSTRAINT `fk_po_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_po_supplier` FOREIGN KEY (`supplier_id`) 
        REFERENCES `suppliers` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_po_user` FOREIGN KEY (`created_by_user_id`) 
        REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 17: PURCHASE ORDER ITEMS
CREATE TABLE IF NOT EXISTS `purchase_order_items` (
    `id` VARCHAR(36) NOT NULL,
    `purchase_order_id` VARCHAR(36) NOT NULL,
    `medicine_id` VARCHAR(36) NOT NULL,
    `ordered_quantity` INT UNSIGNED NOT NULL,
    `received_quantity` INT UNSIGNED NOT NULL DEFAULT 0,
    `unit_cost` DECIMAL(10,2) NOT NULL,
    `subtotal` DECIMAL(10,2) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_poi_po` (`purchase_order_id`),
    KEY `idx_poi_med` (`medicine_id`),
    CONSTRAINT `fk_poi_po` FOREIGN KEY (`purchase_order_id`) 
        REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_poi_med` FOREIGN KEY (`medicine_id`) 
        REFERENCES `medicines` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_poi_ordered_qty` CHECK (`ordered_quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================================
-- SECTION G: REPORTING & DASHBOARD ANALYTICS VIEWS
-- ====================================================================================

-- View 1: MEDICINE STOCK SUMMARY
-- Authoritative calculation of net usable stock, reserved lots, and current stock status.
-- Excludes expired lots from usable stock!
CREATE OR REPLACE VIEW `v_medicine_stock_summary` AS
SELECT 
    m.id AS medicine_id,
    m.name AS medicine_name,
    m.generic_name,
    m.category,
    m.manufacturer,
    m.strength,
    m.unit,
    m.min_stock_threshold,
    m.selling_price,
    
    -- Total recorded physical warehouse quantity
    COALESCE(SUM(b.quantity), 0) AS total_physical_stock,
    
    -- Gross usable stock (batches with expiry > CURRENT_DATE and not quarantined)
    COALESCE(SUM(CASE 
        WHEN b.expiry_date > CURRENT_DATE AND b.quarantined = 0 THEN b.quantity 
        ELSE 0 
    END), 0) AS gross_usable_stock,
    
    -- Expired / quarantined stock
    COALESCE(SUM(CASE 
        WHEN b.expiry_date <= CURRENT_DATE OR b.quarantined = 1 THEN b.quantity 
        ELSE 0 
    END), 0) AS expired_stock,
    
    -- Reserved stock from active dispensary orders (Confirmed, Preparing, Packed)
    COALESCE((
        SELECT SUM(oi.quantity)
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.id
        WHERE oi.medicine_id = m.id 
          AND o.status IN ('Confirmed', 'Preparing', 'Packed')
    ), 0) AS reserved_stock,
    
    -- Net usable stock available for customer purchase
    GREATEST(0, 
        COALESCE(SUM(CASE 
            WHEN b.expiry_date > CURRENT_DATE AND b.quarantined = 0 THEN b.quantity 
            ELSE 0 
        END), 0) - 
        COALESCE((
            SELECT SUM(oi.quantity)
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            WHERE oi.medicine_id = m.id 
              AND o.status IN ('Confirmed', 'Preparing', 'Packed')
        ), 0)
    ) AS net_usable_stock,
    
    COUNT(b.id) AS total_batches_count,
    
    -- Stock status determination
    CASE 
        WHEN GREATEST(0, COALESCE(SUM(CASE WHEN b.expiry_date > CURRENT_DATE AND b.quarantined = 0 THEN b.quantity ELSE 0 END), 0) - COALESCE((SELECT SUM(oi.quantity) FROM order_items oi JOIN orders o ON oi.order_id = o.id WHERE oi.medicine_id = m.id AND o.status IN ('Confirmed', 'Preparing', 'Packed')), 0)) = 0 
            THEN 'OUT_OF_STOCK'
        WHEN GREATEST(0, COALESCE(SUM(CASE WHEN b.expiry_date > CURRENT_DATE AND b.quarantined = 0 THEN b.quantity ELSE 0 END), 0) - COALESCE((SELECT SUM(oi.quantity) FROM order_items oi JOIN orders o ON oi.order_id = o.id WHERE oi.medicine_id = m.id AND o.status IN ('Confirmed', 'Preparing', 'Packed')), 0)) <= m.min_stock_threshold 
            THEN 'LOW_STOCK'
        ELSE 'IN_STOCK'
    END AS stock_status

FROM medicines m
LEFT JOIN medicine_batches b ON m.id = b.medicine_id
WHERE m.is_active = 1
GROUP BY m.id, m.name, m.generic_name, m.category, m.manufacturer, m.strength, m.unit, m.min_stock_threshold, m.selling_price;

-- View 2: LOW STOCK ALERTS VIEW
-- Pinpoints items requiring supplier reorder.
CREATE OR REPLACE VIEW `v_low_stock_alerts` AS
SELECT * 
FROM v_medicine_stock_summary
WHERE stock_status IN ('LOW_STOCK', 'OUT_OF_STOCK')
ORDER BY net_usable_stock ASC;

-- View 3: EXPIRING SOON BATCHES VIEW (WITHIN 90 DAYS)
CREATE OR REPLACE VIEW `v_expiring_soon_batches` AS
SELECT 
    b.id AS batch_id,
    b.batch_number,
    m.id AS medicine_id,
    m.name AS medicine_name,
    m.category,
    s.name AS supplier_name,
    b.quantity,
    b.expiry_date,
    DATEDIFF(b.expiry_date, CURRENT_DATE) AS days_until_expiry,
    CASE 
        WHEN DATEDIFF(b.expiry_date, CURRENT_DATE) <= 30 THEN 'CRITICAL'
        WHEN DATEDIFF(b.expiry_date, CURRENT_DATE) <= 60 THEN 'URGENT'
        ELSE 'WARNING'
    END AS alert_urgency
FROM medicine_batches b
JOIN medicines m ON b.medicine_id = m.id
JOIN suppliers s ON b.supplier_id = s.id
WHERE b.expiry_date > CURRENT_DATE 
  AND b.expiry_date <= DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY)
  AND b.quantity > 0
ORDER BY b.expiry_date ASC;

-- View 4: EXPIRED LOTS QUARANTINE VIEW
CREATE OR REPLACE VIEW `v_expired_batches_quarantine` AS
SELECT 
    b.id AS batch_id,
    b.batch_number,
    m.id AS medicine_id,
    m.name AS medicine_name,
    s.name AS supplier_name,
    b.quantity AS quarantined_quantity,
    b.expiry_date,
    ABS(DATEDIFF(b.expiry_date, CURRENT_DATE)) AS days_expired
FROM medicine_batches b
JOIN medicines m ON b.medicine_id = m.id
JOIN suppliers s ON b.supplier_id = s.id
WHERE b.expiry_date <= CURRENT_DATE
ORDER BY b.expiry_date DESC;

-- View 5: INCOMING ORDERS QUEUE (FOR INVENTORY MANAGERS)
CREATE OR REPLACE VIEW `v_incoming_orders_queue` AS
SELECT 
    o.id AS order_id,
    o.order_number,
    o.created_at,
    o.customer_name,
    o.customer_phone,
    o.shipping_city,
    o.shipping_state,
    o.total_amount,
    o.payment_method,
    o.payment_status,
    o.status,
    COUNT(oi.id) AS total_line_items,
    SUM(oi.quantity) AS total_units_ordered
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status = 'Pending Review'
GROUP BY o.id, o.order_number, o.created_at, o.customer_name, o.customer_phone, o.shipping_city, o.shipping_state, o.total_amount, o.payment_method, o.payment_status, o.status
ORDER BY o.created_at ASC;

-- View 6: ACTIVE DISPENSARY FULFILLMENT QUEUE
CREATE OR REPLACE VIEW `v_active_dispensary_queue` AS
SELECT 
    o.id AS order_id,
    o.order_number,
    o.status,
    o.confirmed_at,
    o.customer_name,
    o.shipping_city,
    o.total_amount,
    o.carrier_name,
    o.tracking_reference
FROM orders o
WHERE o.status IN ('Confirmed', 'Preparing', 'Packed', 'Shipped', 'Out for Delivery')
ORDER BY o.confirmed_at ASC;

-- ====================================================================================
-- SECTION H: SAFE DEMONSTRATION SEED DATA
-- ====================================================================================

-- 1. Store
INSERT INTO `stores` (`id`, `store_code`, `name`, `license_number`, `phone`, `email`, `address`, `city`, `state`, `postal_code`, `country`, `is_active`)
VALUES (
    'STO-001',
    'MS-BLR-01',
    'MediStock Central Pharmacy & Dispensary',
    'KA-BLR-2024-PH-8891',
    '+91 80 2345 6789',
    'dispensary@medistock.in',
    '100 Feet Road, HAL 2nd Stage, Indiranagar',
    'Bengaluru',
    'Karnataka',
    '560038',
    'India',
    1
) ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 2. Users (Admin, Inventory Manager, Buyer)
-- Password hash placeholder: BCrypt hash for 'DemoPass@2026'
INSERT INTO `users` (`id`, `store_id`, `role`, `full_name`, `email`, `phone`, `password_hash`, `status`)
VALUES 
(
    'USR-001',
    'STO-001',
    'ADMIN',
    'Dr. Vikram Malhotra',
    'admin@medistock.in',
    '+91 98111 22233',
    '$2a$12$e9gG8V52N1YfV5C2fKkHhe1.sJ4Z6p2k9qLwWdY8nK9m3p7b1.xY6',
    'ACTIVE'
),
(
    'USR-002',
    'STO-001',
    'INVENTORY_MANAGER',
    'Inventory Manager',
    'manager@medistock.in',
    '+91 98222 33344',
    '$2a$12$e9gG8V52N1YfV5C2fKkHhe1.sJ4Z6p2k9qLwWdY8nK9m3p7b1.xY6',
    'ACTIVE'
),
(
    'USR-003',
    NULL,
    'BUYER',
    'Buyer',
    'buyer@medistock.in',
    '+91 98765 43210',
    '$2a$12$e9gG8V52N1YfV5C2fKkHhe1.sJ4Z6p2k9qLwWdY8nK9m3p7b1.xY6',
    'ACTIVE'
) ON DUPLICATE KEY UPDATE `full_name`=VALUES(`full_name`);

-- 3. Customer Delivery Addresses
INSERT INTO `user_addresses` (`id`, `user_id`, `address_label`, `recipient_name`, `phone`, `street`, `city`, `state`, `postal_code`, `country`, `is_default`)
VALUES 
(
    'ADDR-01',
    'USR-003',
    'Home (Default)',
    'Buyer',
    '+91 98765 43210',
    'Flat 402, Green Glen Layout, Bellandur',
    'Bengaluru',
    'Karnataka',
    '560103',
    'India',
    1
),
(
    'ADDR-02',
    'USR-003',
    'Office Clinic',
    'Buyer',
    '+91 98765 12345',
    'Level 4, Tech Park Campus, Outer Ring Road',
    'Bengaluru',
    'Karnataka',
    '560103',
    'India',
    0
) ON DUPLICATE KEY UPDATE `recipient_name`=VALUES(`recipient_name`);

-- 4. Suppliers (Matching INITIAL_SUPPLIERS)
INSERT INTO `suppliers` (`id`, `name`, `contact_person`, `email`, `phone`, `address`, `status`, `notes`, `created_at`)
VALUES
('SUP-001', 'MediCore Pharma Labs', 'Dr. Rajesh Kumar', 'rajesh.k@medicorepharma.in', '+91 80 2345 6781', '742 Electronic City Phase 1, Bengaluru, KA 560100', 'ACTIVE', 'Primary supplier of broad-spectrum antibiotics and respiratory medications.', '2025-01-15'),
('SUP-002', 'Apex LifeSciences Ltd', 'Marcus Vance', 'm.vance@apexlifesciences.io', '+91 80 4123 4567', '1200 Innovation Blvd, Whitefield, Bengaluru, KA 560066', 'ACTIVE', 'Specialized partner for cardiovascular therapeutics and NSAIDs.', '2025-02-10'),
('SUP-003', 'BioHealth Logistics Corp', 'Elena Rostova', 'elena@biohealthlogistics.com', '+91 22 2567 8901', '550 Logistics Parkway, Dock 14, Navi Mumbai, MH 400703', 'ACTIVE', 'Certified cold-chain distributor for GI medications and injectables.', '2025-03-01'),
('SUP-004', 'Global BioPharm Distributors', 'Rajiv Menon', 'rmenon@globalbiopharm.net', '+91 44 2890 1234', '88 Harborview Way, Guindy, Chennai, TN 600032', 'ACTIVE', 'Licensed importer for specialty fluoroquinolones and macrolides.', '2025-04-18'),
('SUP-005', 'NovaCare Medical Supplies', 'Amanda Price', 'contact@novacaremed.com', '+91 40 6789 0123', '310 HealthTech Center, HITEC City, Hyderabad, TG 500081', 'ACTIVE', 'National supplier for daily antipyretics, analgesics, and antihistamines.', '2025-05-22')
ON DUPLICATE KEY UPDATE `contact_person`=VALUES(`contact_person`);

-- 5. Medicines Catalog (Matching INITIAL_MEDICINES)
INSERT INTO `medicines` (`id`, `name`, `generic_name`, `category`, `manufacturer`, `strength`, `unit`, `min_stock_threshold`, `selling_price`, `description`, `requires_prescription`, `is_active`, `created_at`)
VALUES
('MED-001', 'Amoxicillin Trihydrate', 'Amoxicillin', 'Antibiotics', 'GlaxoSmithKline', '500mg', 'Capsules', 200, 165.00, 'Broad-spectrum beta-lactam antibiotic used in the treatment of bacterial infections.', 1, 1, '2025-01-10'),
('MED-002', 'Paracetamol Extra', 'Acetaminophen', 'Analgesics & Antipyretics', 'Johnson & Johnson', '650mg', 'Tablets', 300, 45.00, 'Fast-acting antipyretic and analgesic for fever management and mild-to-moderate pain relief.', 0, 1, '2025-01-12'),
('MED-003', 'Metformin Glucophage', 'Metformin Hydrochloride', 'Antidiabetic', 'Merck Healthcare', '500mg', 'Tablets', 150, 88.00, 'First-line biguanide oral antihyperglycemic medication for type 2 diabetes mellitus management.', 1, 1, '2025-01-15'),
('MED-004', 'Lipitor (Atorvastatin)', 'Atorvastatin Calcium', 'Cardiovascular', 'Pfizer Inc.', '20mg', 'Tablets', 120, 210.00, 'HMG-CoA reductase inhibitor statin used to prevent cardiovascular disease and manage dyslipidemia.', 1, 1, '2025-01-20'),
('MED-005', 'Zithromax (Azithromycin)', 'Azithromycin Dihydrate', 'Antibiotics', 'Pfizer Inc.', '250mg', 'Tablets', 100, 235.00, 'Macrolide antibiotic indicated for respiratory tract infections, enteric infections, and skin ailments.', 1, 1, '2025-02-01'),
('MED-006', 'Prilosec (Omeprazole)', 'Omeprazole Magnesium', 'Gastrointestinal', 'AstraZeneca', '20mg', 'Capsules', 80, 95.00, 'Proton pump inhibitor (PPI) decreasing stomach acid production for GERD and peptic ulcer treatment.', 0, 1, '2025-02-05'),
('MED-007', 'Zyrtec (Cetirizine)', 'Cetirizine Hydrochloride', 'Antihistamines', 'Johnson & Johnson', '10mg', 'Tablets', 140, 60.00, 'Second-generation antihistamine relieving allergy symptoms including allergic rhinitis and urticaria.', 0, 1, '2025-02-14'),
('MED-008', 'Ventolin HFA Inhaler', 'Albuterol Sulfate', 'Respiratory', 'GlaxoSmithKline', '100mcg/dose', 'Inhalers', 50, 320.00, 'Short-acting beta-2 adrenergic receptor agonist providing rapid bronchodilation in asthma and COPD.', 1, 1, '2025-02-20'),
('MED-009', 'Cipro (Ciprofloxacin)', 'Ciprofloxacin HCl', 'Antibiotics', 'Bayer Pharmaceuticals', '500mg', 'Tablets', 90, 175.00, 'Second-generation fluoroquinolone antibiotic targeting severe Gram-negative bacterial infections.', 1, 1, '2025-03-01'),
('MED-010', 'Prinivil (Lisinopril)', 'Lisinopril', 'Cardiovascular', 'Merck & Co.', '10mg', 'Tablets', 110, 110.00, 'ACE inhibitor utilized in the treatment of hypertension, congestive heart failure, and post-MI care.', 1, 1, '2025-03-10')
ON DUPLICATE KEY UPDATE `selling_price`=VALUES(`selling_price`);

-- 6. Medicine Batches (Matching INITIAL_BATCHES with dynamic calendar references)
INSERT INTO `medicine_batches` (`id`, `medicine_id`, `batch_number`, `supplier_id`, `mfg_date`, `expiry_date`, `initial_quantity`, `quantity`, `purchase_price`, `quarantined`, `created_at`)
VALUES
-- Amoxicillin (MED-001)
('BAT-101', 'MED-001', 'AMX-2024-09A', 'SUP-001', DATE_SUB(CURRENT_DATE, INTERVAL 300 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 180 DAY), 400, 320, 125.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 300 DAY)),
('BAT-102', 'MED-001', 'AMX-2023-11C', 'SUP-001', DATE_SUB(CURRENT_DATE, INTERVAL 420 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY),  150,  45, 118.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 420 DAY)),
('BAT-103', 'MED-001', 'AMX-2023-05B', 'SUP-004', DATE_SUB(CURRENT_DATE, INTERVAL 550 DAY), DATE_SUB(CURRENT_DATE, INTERVAL 25 DAY),  100,  20, 112.00, 1, DATE_SUB(CURRENT_DATE, INTERVAL 550 DAY)),

-- Paracetamol (MED-002)
('BAT-104', 'MED-002', 'PAR-2024-02X', 'SUP-002', DATE_SUB(CURRENT_DATE, INTERVAL 240 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 260 DAY), 500, 400,  35.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 240 DAY)),
('BAT-105', 'MED-002', 'PAR-2024-07Y', 'SUP-005', DATE_SUB(CURRENT_DATE, INTERVAL 120 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 380 DAY), 300, 250,  38.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 120 DAY)),

-- Metformin (MED-003)
('BAT-106', 'MED-003', 'MET-2024-01B', 'SUP-002', DATE_SUB(CURRENT_DATE, INTERVAL 310 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 190 DAY), 300, 220,  65.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 310 DAY)),

-- Atorvastatin (MED-004)
('BAT-107', 'MED-004', 'ATV-2023-12A', 'SUP-003', DATE_SUB(CURRENT_DATE, INTERVAL 400 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 22 DAY),  120,  85, 155.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 400 DAY)),
('BAT-108', 'MED-004', 'ATV-2024-05D', 'SUP-001', DATE_SUB(CURRENT_DATE, INTERVAL 150 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 320 DAY), 120,  90, 160.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 150 DAY)),

-- Azithromycin (MED-005) - Low stock trigger
('BAT-109', 'MED-005', 'AZI-2024-03K', 'SUP-004', DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 210 DAY),  50,  42, 175.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY)),

-- Omeprazole (MED-006)
('BAT-110', 'MED-006', 'OMP-2024-04F', 'SUP-003', DATE_SUB(CURRENT_DATE, INTERVAL 200 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 160 DAY), 150, 110,  75.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 200 DAY)),
('BAT-111', 'MED-006', 'OMP-2023-08E', 'SUP-002', DATE_SUB(CURRENT_DATE, INTERVAL 500 DAY), DATE_SUB(CURRENT_DATE, INTERVAL 12 DAY),   50,  25,  72.00, 1, DATE_SUB(CURRENT_DATE, INTERVAL 500 DAY)),

-- Cetirizine (MED-007)
('BAT-112', 'MED-007', 'CTZ-2024-06M', 'SUP-005', DATE_SUB(CURRENT_DATE, INTERVAL 140 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 280 DAY), 200, 160,  45.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 140 DAY)),

-- Ventolin Inhaler (MED-008) - Low stock + Expiring soon
('BAT-113', 'MED-008', 'VEN-2024-02H', 'SUP-001', DATE_SUB(CURRENT_DATE, INTERVAL 210 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 8 DAY),    30,  16, 240.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 210 DAY)),

-- Ciprofloxacin (MED-009) - Depleted lot
('BAT-114', 'MED-009', 'CPR-2023-09Z', 'SUP-004', DATE_SUB(CURRENT_DATE, INTERVAL 440 DAY), DATE_SUB(CURRENT_DATE, INTERVAL 40 DAY),   80,   0, 130.00, 1, DATE_SUB(CURRENT_DATE, INTERVAL 440 DAY)),

-- Lisinopril (MED-010)
('BAT-115', 'MED-010', 'LIS-2024-05P', 'SUP-003', DATE_SUB(CURRENT_DATE, INTERVAL 160 DAY), DATE_ADD(CURRENT_DATE, INTERVAL 340 DAY), 200, 175,  80.00, 0, DATE_SUB(CURRENT_DATE, INTERVAL 160 DAY))
ON DUPLICATE KEY UPDATE `quantity`=VALUES(`quantity`);

-- 7. Buyer Wishlist
INSERT INTO `wishlists` (`id`, `user_id`, `medicine_id`, `created_at`)
VALUES 
('WSH-01', 'USR-003', 'MED-001', NOW()),
('WSH-02', 'USR-003', 'MED-008', NOW())
ON DUPLICATE KEY UPDATE `created_at`=VALUES(`created_at`);

-- 8. Customer Orders (Single Source of Truth)
-- Order 1: Newly Placed (Pending Review)
INSERT INTO `orders` (
    `id`, `order_number`, `store_id`, `buyer_id`, `status`,
    `subtotal`, `delivery_fee`, `tax_amount`, `total_amount`,
    `payment_method`, `payment_status`,
    `customer_name`, `customer_email`, `customer_phone`,
    `shipping_street`, `shipping_city`, `shipping_state`, `shipping_postal_code`, `shipping_country`,
    `carrier_name`, `tracking_reference`,
    `stock_reserved`, `stock_deducted`,
    `created_at`, `estimated_delivery`
) VALUES (
    'ORD-2026-9501', 'ORD-2026-9501', 'STO-001', 'USR-003', 'Pending Review',
    465.00, 40.00, 23.25, 528.25,
    'Cash on Delivery (COD)', 'Pending on Delivery',
    'Buyer', 'buyer@medistock.in', '+91 98765 43210',
    'Flat 402, Green Glen Layout, Bellandur', 'Bengaluru', 'Karnataka', '560103', 'India',
    NULL, NULL,
    0, 0,
    DATE_SUB(NOW(), INTERVAL 35 MINUTE),
    DATE_ADD(CURRENT_DATE, INTERVAL 2 DAY)
) ON DUPLICATE KEY UPDATE `total_amount`=VALUES(`total_amount`);

INSERT INTO `order_items` (`id`, `order_id`, `medicine_id`, `medicine_name_snapshot`, `generic_name_snapshot`, `category_snapshot`, `strength_snapshot`, `unit_snapshot`, `unit_price`, `quantity`, `subtotal`)
VALUES 
('OI-9501-1', 'ORD-2026-9501', 'MED-001', 'Amoxicillin Trihydrate', 'Amoxicillin', 'Antibiotics', '500mg', 'Capsules', 165.00, 2, 330.00),
('OI-9501-2', 'ORD-2026-9501', 'MED-002', 'Paracetamol Extra', 'Acetaminophen', 'Analgesics & Antipyretics', '650mg', 'Tablets', 45.00, 3, 135.00)
ON DUPLICATE KEY UPDATE `subtotal`=VALUES(`subtotal`);

INSERT INTO `order_status_history` (`id`, `order_id`, `from_status`, `to_status`, `changed_by_user_id`, `changed_by_name`, `note`, `timestamp`)
VALUES 
('OSH-9501-1', 'ORD-2026-9501', NULL, 'Pending Review', 'USR-003', 'Buyer', 'Prescription order submitted via MediStock Store.', DATE_SUB(NOW(), INTERVAL 35 MINUTE))
ON DUPLICATE KEY UPDATE `note`=VALUES(`note`);

-- Order 2: Accepted & Packed in Dispensary (Packed, Reserved)
INSERT INTO `orders` (
    `id`, `order_number`, `store_id`, `buyer_id`, `status`,
    `subtotal`, `delivery_fee`, `tax_amount`, `total_amount`,
    `payment_method`, `payment_status`,
    `customer_name`, `customer_email`, `customer_phone`,
    `shipping_street`, `shipping_city`, `shipping_state`, `shipping_postal_code`, `shipping_country`,
    `carrier_name`, `tracking_reference`,
    `stock_reserved`, `stock_deducted`,
    `created_at`, `confirmed_at`, `estimated_delivery`
) VALUES (
    'ORD-2026-9430', 'ORD-2026-9430', 'STO-001', 'USR-003', 'Packed',
    190.00, 40.00, 9.50, 239.50,
    'Pharmacy Counter Pickup', 'Pending Counter Settlement',
    'Buyer', 'buyer@medistock.in', '+91 98765 43210',
    'Flat 402, Green Glen Layout, Bellandur', 'Bengaluru', 'Karnataka', '560103', 'India',
    NULL, NULL,
    1, 0,
    DATE_SUB(NOW(), INTERVAL 18 HOUR),
    DATE_SUB(NOW(), INTERVAL 16 HOUR),
    DATE_ADD(CURRENT_DATE, INTERVAL 1 DAY)
) ON DUPLICATE KEY UPDATE `total_amount`=VALUES(`total_amount`);

INSERT INTO `order_items` (`id`, `order_id`, `medicine_id`, `medicine_name_snapshot`, `generic_name_snapshot`, `category_snapshot`, `strength_snapshot`, `unit_snapshot`, `unit_price`, `quantity`, `subtotal`)
VALUES 
('OI-9430-1', 'ORD-2026-9430', 'MED-006', 'Prilosec (Omeprazole)', 'Omeprazole Magnesium', 'Gastrointestinal', '20mg', 'Capsules', 95.00, 2, 190.00)
ON DUPLICATE KEY UPDATE `subtotal`=VALUES(`subtotal`);

INSERT INTO `order_item_batch_allocations` (`id`, `order_item_id`, `batch_id`, `batch_number_snapshot`, `quantity`, `expiry_date_snapshot`, `created_at`)
VALUES 
('OIBA-9430-1', 'OI-9430-1', 'BAT-110', 'OMP-2024-04F', 2, DATE_ADD(CURRENT_DATE, INTERVAL 160 DAY), DATE_SUB(NOW(), INTERVAL 16 HOUR))
ON DUPLICATE KEY UPDATE `quantity`=VALUES(`quantity`);

INSERT INTO `order_status_history` (`id`, `order_id`, `from_status`, `to_status`, `changed_by_user_id`, `changed_by_name`, `note`, `timestamp`)
VALUES 
('OSH-9430-1', 'ORD-2026-9430', NULL, 'Pending Review', 'USR-003', 'Buyer', 'Order submitted by customer', DATE_SUB(NOW(), INTERVAL 18 HOUR)),
('OSH-9430-2', 'ORD-2026-9430', 'Pending Review', 'Confirmed', 'USR-002', 'Inventory Manager', 'Order accepted. Batch lots verified and reserved.', DATE_SUB(NOW(), INTERVAL 16 HOUR)),
('OSH-9430-3', 'ORD-2026-9430', 'Confirmed', 'Preparing', 'USR-002', 'Inventory Manager', 'Medicines retrieved from pharmacy dispensary shelf.', DATE_SUB(NOW(), INTERVAL 10 HOUR)),
('OSH-9430-4', 'ORD-2026-9430', 'Preparing', 'Packed', 'USR-002', 'Inventory Manager', 'Sealed in clinical tamper-evident packaging. Ready for dispatch.', DATE_SUB(NOW(), INTERVAL 4 HOUR))
ON DUPLICATE KEY UPDATE `note`=VALUES(`note`);

-- Order 3: Dispatched & Delivered (Delivered, Stock Deducted)
INSERT INTO `orders` (
    `id`, `order_number`, `store_id`, `buyer_id`, `status`,
    `subtotal`, `delivery_fee`, `tax_amount`, `total_amount`,
    `payment_method`, `payment_status`,
    `customer_name`, `customer_email`, `customer_phone`,
    `shipping_street`, `shipping_city`, `shipping_state`, `shipping_postal_code`, `shipping_country`,
    `carrier_name`, `tracking_reference`,
    `stock_reserved`, `stock_deducted`,
    `created_at`, `confirmed_at`, `dispatched_at`, `delivered_at`
) VALUES (
    'ORD-2026-9210', 'ORD-2026-9210', 'STO-001', 'USR-003', 'Delivered',
    65.00, 40.00, 3.25, 108.25,
    'Cash on Delivery (COD)', 'Paid on Delivery',
    'Buyer', 'buyer@medistock.in', '+91 98765 43210',
    'Flat 402, Green Glen Layout, Bellandur', 'Bengaluru', 'Karnataka', '560103', 'India',
    'MediCourier Express', 'MC-IN-560103',
    1, 1,
    DATE_SUB(NOW(), INTERVAL 60 HOUR),
    DATE_SUB(NOW(), INTERVAL 55 HOUR),
    DATE_SUB(NOW(), INTERVAL 36 HOUR),
    DATE_SUB(NOW(), INTERVAL 3 HOUR)
) ON DUPLICATE KEY UPDATE `total_amount`=VALUES(`total_amount`);

INSERT INTO `order_items` (`id`, `order_id`, `medicine_id`, `medicine_name_snapshot`, `generic_name_snapshot`, `category_snapshot`, `strength_snapshot`, `unit_snapshot`, `unit_price`, `quantity`, `subtotal`)
VALUES 
('OI-9210-1', 'ORD-2026-9210', 'MED-007', 'Zyrtec (Cetirizine)', 'Cetirizine Hydrochloride', 'Antihistamines', '10mg', 'Tablets', 65.00, 1, 65.00)
ON DUPLICATE KEY UPDATE `subtotal`=VALUES(`subtotal`);

INSERT INTO `order_item_batch_allocations` (`id`, `order_item_id`, `batch_id`, `batch_number_snapshot`, `quantity`, `expiry_date_snapshot`, `created_at`)
VALUES 
('OIBA-9210-1', 'OI-9210-1', 'BAT-112', 'CTZ-2024-06M', 1, DATE_ADD(CURRENT_DATE, INTERVAL 280 DAY), DATE_SUB(NOW(), INTERVAL 55 HOUR))
ON DUPLICATE KEY UPDATE `quantity`=VALUES(`quantity`);

INSERT INTO `order_status_history` (`id`, `order_id`, `from_status`, `to_status`, `changed_by_user_id`, `changed_by_name`, `note`, `timestamp`)
VALUES 
('OSH-9210-1', 'ORD-2026-9210', NULL, 'Pending Review', 'USR-003', 'Buyer', 'Order submitted online', DATE_SUB(NOW(), INTERVAL 60 HOUR)),
('OSH-9210-2', 'ORD-2026-9210', 'Pending Review', 'Confirmed', 'USR-002', 'Inventory Manager', 'Order accepted', DATE_SUB(NOW(), INTERVAL 55 HOUR)),
('OSH-9210-3', 'ORD-2026-9210', 'Confirmed', 'Preparing', 'USR-002', 'Inventory Manager', 'Medication prepared', DATE_SUB(NOW(), INTERVAL 48 HOUR)),
('OSH-9210-4', 'ORD-2026-9210', 'Preparing', 'Packed', 'USR-002', 'Inventory Manager', 'Packed in cold-chain courier satchel', DATE_SUB(NOW(), INTERVAL 42 HOUR)),
('OSH-9210-5', 'ORD-2026-9210', 'Packed', 'Shipped', 'USR-002', 'Inventory Manager', 'Dispatched via MediCourier Express (#MC-IN-560103)', DATE_SUB(NOW(), INTERVAL 36 HOUR)),
('OSH-9210-6', 'ORD-2026-9210', 'Shipped', 'Out for Delivery', NULL, 'MediCourier Driver', 'Out for final delivery to doorstep', DATE_SUB(NOW(), INTERVAL 10 HOUR)),
('OSH-9210-7', 'ORD-2026-9210', 'Out for Delivery', 'Delivered', NULL, 'MediCourier Driver', 'Package handed over at delivery address', DATE_SUB(NOW(), INTERVAL 3 HOUR))
ON DUPLICATE KEY UPDATE `note`=VALUES(`note`);

-- 9. Historical Stock Transactions (Matching INITIAL_TRANSACTIONS)
INSERT INTO `stock_transactions` (`id`, `store_id`, `type`, `medicine_id`, `batch_id`, `quantity`, `previous_quantity`, `new_quantity`, `reference_order_id`, `created_by_user_id`, `remarks`, `timestamp`)
VALUES
('TXN-901', 'STO-001', 'STOCK_OUT',  'MED-002', 'BAT-104',  50, 450, 400, NULL,            'USR-002', 'Dispensed to Outpatient Pharmacy Counter A',                  DATE_SUB(NOW(), INTERVAL 2 HOUR)),
('TXN-902', 'STO-001', 'STOCK_IN',   'MED-001', 'BAT-101', 100, 220, 320, NULL,            'USR-002', 'Received monthly scheduled shipment from MediCore Pharma',   DATE_SUB(NOW(), INTERVAL 8 HOUR)),
('TXN-903', 'STO-001', 'STOCK_OUT',  'MED-004', 'BAT-108',  30, 120,  90, NULL,            'USR-002', 'Cardiology Department ward transfer',                         DATE_SUB(NOW(), INTERVAL 24 HOUR)),
('TXN-904', 'STO-001', 'ADJUSTMENT', 'MED-006', 'BAT-110', 110, 115, 110, NULL,            'USR-002', 'Inventory count adjustment: 5 damaged packaging units quarantined', DATE_SUB(NOW(), INTERVAL 48 HOUR)),
('TXN-905', 'STO-001', 'STOCK_OUT',  'MED-007', 'BAT-112',  40, 200, 160, NULL,            'USR-002', 'Allergy Clinic seasonal replenishment',                       DATE_SUB(NOW(), INTERVAL 72 HOUR)),
('TXN-906', 'STO-001', 'STOCK_IN',   'MED-010', 'BAT-115',  75, 100, 175, NULL,            'USR-002', 'Purchase Order #PO-4481 delivery accepted',                  DATE_SUB(NOW(), INTERVAL 96 HOUR)),
('TXN-907', 'STO-001', 'STOCK_OUT',  'MED-008', 'BAT-113',  14,  30,  16, NULL,            'USR-002', 'Emergency Room asthma crisis supply request',                 DATE_SUB(NOW(), INTERVAL 120 HOUR)),
('TXN-908', 'STO-001', 'STOCK_OUT',  'MED-007', 'BAT-112',   1, 161, 160, 'ORD-2026-9210', 'USR-002', 'Customer Order Dispatch #ORD-2026-9210',                     DATE_SUB(NOW(), INTERVAL 36 HOUR))
ON DUPLICATE KEY UPDATE `remarks`=VALUES(`remarks`);

-- 10. Sample Supplier Purchase Order
INSERT INTO `purchase_orders` (`id`, `po_number`, `store_id`, `supplier_id`, `status`, `order_date`, `expected_delivery_date`, `subtotal`, `tax_amount`, `total_amount`, `created_by_user_id`, `notes`, `created_at`)
VALUES (
    'PO-2026-001',
    'PO-2026-001',
    'STO-001',
    'SUP-001',
    'ORDERED',
    CURRENT_DATE,
    DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY),
    25000.00,
    1250.00,
    26250.00,
    'USR-002',
    'Replenishment of Amoxicillin 500mg and Ventolin Inhalers following quarterly audit.',
    NOW()
) ON DUPLICATE KEY UPDATE `total_amount`=VALUES(`total_amount`);

INSERT INTO `purchase_order_items` (`id`, `purchase_order_id`, `medicine_id`, `ordered_quantity`, `received_quantity`, `unit_cost`, `subtotal`)
VALUES 
('POI-001-1', 'PO-2026-001', 'MED-001', 150, 0, 120.00, 18000.00),
('POI-001-2', 'PO-2026-001', 'MED-008',  30, 0, 233.33,  7000.00)
ON DUPLICATE KEY UPDATE `subtotal`=VALUES(`subtotal`);

-- ------------------------------------------------------------------------------------
-- 0. RESTORE ENVIRONMENT CONFIGURATION
-- ------------------------------------------------------------------------------------
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

-- ====================================================================================
-- SECTION I: SCHEMA & DATA VALIDATION VERIFICATION QUERIES
-- Execute these queries in MySQL Workbench 8.0 to verify database integrity.
-- ====================================================================================

-- 1. Verify Table Record Counts
SELECT 'stores' AS `table_name`, COUNT(*) AS `row_count` FROM `stores`
UNION ALL SELECT 'users', COUNT(*) FROM `users`
UNION ALL SELECT 'user_addresses', COUNT(*) FROM `user_addresses`
UNION ALL SELECT 'suppliers', COUNT(*) FROM `suppliers`
UNION ALL SELECT 'medicines', COUNT(*) FROM `medicines`
UNION ALL SELECT 'medicine_batches', COUNT(*) FROM `medicine_batches`
UNION ALL SELECT 'orders', COUNT(*) FROM `orders`
UNION ALL SELECT 'order_items', COUNT(*) FROM `order_items`
UNION ALL SELECT 'order_item_batch_allocations', COUNT(*) FROM `order_item_batch_allocations`
UNION ALL SELECT 'order_status_history', COUNT(*) FROM `order_status_history`
UNION ALL SELECT 'stock_transactions', COUNT(*) FROM `stock_transactions`
UNION ALL SELECT 'purchase_orders', COUNT(*) FROM `purchase_orders`;

-- 2. Inspect Calculated Stock Summary View
SELECT 
    medicine_id,
    medicine_name,
    category,
    min_stock_threshold,
    total_physical_stock,
    gross_usable_stock,
    reserved_stock,
    net_usable_stock,
    expired_stock,
    stock_status
FROM `v_medicine_stock_summary`
ORDER BY medicine_id;

-- 3. Inspect Low Stock & Out of Stock Alerts
SELECT * FROM `v_low_stock_alerts`;

-- 4. Inspect Batches Expiring Soon (Within 90 Days)
SELECT * FROM `v_expiring_soon_batches`;

-- 5. Inspect Quarantined / Expired Batches
SELECT * FROM `v_expired_batches_quarantine`;

-- 6. Inspect Incoming Orders Awaiting Manager Review
SELECT * FROM `v_incoming_orders_queue`;

-- 7. Inspect Active Dispensary Orders Queue
SELECT * FROM `v_active_dispensary_queue`;

-- 8. Verify Foreign Key Cascade and Audit Integrity
SELECT 
    o.order_number,
    o.status,
    o.customer_name,
    o.total_amount,
    oi.medicine_name_snapshot,
    oi.quantity AS ordered_qty,
    oiba.batch_number_snapshot,
    oiba.quantity AS batch_allocated_qty,
    oiba.expiry_date_snapshot
FROM `orders` o
JOIN `order_items` oi ON o.id = oi.order_id
LEFT JOIN `order_item_batch_allocations` oiba ON oi.id = oiba.order_item_id
ORDER BY o.order_number, oi.id;

-- ====================================================================================
-- END OF SCRIPT: MediStock_MySQL_Workbench_8.sql
-- ====================================================================================
