-- schema.sql
-- MySQL schema for DL Asset Track (core tables)
CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL UNIQUE,
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  full_name VARCHAR(255),
  role VARCHAR(50),
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX (email),
  INDEX (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE assets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL UNIQUE,
  asset_type VARCHAR(50) NOT NULL,
  serial_number VARCHAR(128),
  model VARCHAR(128),
  owner_user_id BIGINT UNSIGNED,
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (uuid),
  INDEX (serial_number),
  INDEX (owner_user_id),
  CONSTRAINT fk_assets_owner FOREIGN KEY (owner_user_id) REFERENCES users(id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE locations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  asset_uuid CHAR(36) NOT NULL,
  device_id VARCHAR(128) NULL,
  recorded_at TIMESTAMP NOT NULL,
  received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  latitude DECIMAL(10,7) NOT NULL,
  longitude DECIMAL(10,7) NOT NULL,
  heading SMALLINT UNSIGNED NULL,
  speed DECIMAL(6,2) NULL,
  altitude DECIMAL(8,2) NULL,
  raw_payload JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_loc_asset_time (asset_uuid, recorded_at),
  INDEX idx_loc_device_time (device_id, recorded_at),
  INDEX idx_loc_received_at (received_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE shipments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL UNIQUE,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'CREATED',
  origin_address TEXT,
  destination_address TEXT,
  planned_pickup_at TIMESTAMP NULL,
  planned_delivery_at TIMESTAMP NULL,
  actual_pickup_at TIMESTAMP NULL,
  actual_delivery_at TIMESTAMP NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (uuid),
  INDEX (created_by_user_id),
  INDEX (status),
  CONSTRAINT fk_shipments_user FOREIGN KEY (created_by_user_id) REFERENCES users(id)
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE shipment_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  shipment_uuid CHAR(36) NOT NULL,
  asset_uuid CHAR(36) NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  packed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_shipment_asset (shipment_uuid, asset_uuid),
  INDEX (asset_uuid),
  INDEX (shipment_uuid),
  CONSTRAINT fk_si_shipment FOREIGN KEY (shipment_uuid) REFERENCES shipments(uuid)
    ON DELETE CASCADE,
  CONSTRAINT fk_si_asset FOREIGN KEY (asset_uuid) REFERENCES assets(uuid)
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE domain_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  aggregate_type VARCHAR(50) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(100) NOT NULL,
  payload JSON NOT NULL,
  produced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  consumed BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  INDEX (aggregate_uuid),
  INDEX (event_type),
  INDEX (produced_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

