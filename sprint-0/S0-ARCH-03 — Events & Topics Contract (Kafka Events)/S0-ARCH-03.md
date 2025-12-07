# S0-ARCH-03 — Events & Topics Contract (Kafka Events)

**DL Asset Track — Sprint 0 Architecture Deliverable**

## 1. Overview

This document defines the Kafka event contracts, including:

*   Event names & topic naming conventions
*   JSON Schemas (Draft-07) for all core events
*   Guidance for topic retention, partitioning, compaction
*   Producer & consumer rules (ordering, idempotency, compatibility)
*   Operational best practices

**Events covered:**

*   `dl.asset.location.update`
*   `dl.asset.status`
*   `dl.shipment.status`

These events form the backbone of real-time visibility across assets and shipments.

## 2. Topic Naming Conventions

| Event Type | Topic Name | Partition Key | Notes |
| :--- | :--- | :--- | :--- |
| Asset location update | `dl.asset.location.update` | `asset_uuid` | High-volume telemetry stream |
| Asset status change | `dl.asset.status` | `asset_uuid` | Compact for latest state |
| Shipment status change | `dl.shipment.status` | `shipment_uuid` | Compact & delete for history |

**Rules:**

*   Topic names are lowercase, dot-delimited, and versionless.
*   Schema evolution is handled in Schema Registry, not topic name.
*   Partition key must guarantee ordering per entity (asset/shipment).

## 3. Event Envelope (Required for All Events)

All events share a standard envelope:

```json
{
  "eventId": "uuid-v4",
  "eventType": "dl.asset.location.update",
  "eventVersion": "1.0",
  "producedAt": "2025-12-07T06:14:00Z",
  "source": "tracking-service",
  "payload": {}
}
```

**Fields:**

*   **eventId**: Unique ID for deduplication
*   **eventType**: Canonical event name
*   **eventVersion**: Schema version
*   **producedAt**: ISO8601 UTC timestamp
*   **source**: Producer service
*   **payload**: Event-specific data

## 4. JSON Schemas

### 4.1 Location Update — `dl.asset.location.update`

**File:** `dl.asset.location.update-1.0.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "dl.asset.location.update:1.0",
  "title": "dl.asset.location.update",
  "type": "object",
  "required": [
    "eventId","eventType","eventVersion","producedAt","source","payload"
  ],
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "type": "string", "const": "dl.asset.location.update" },
    "eventVersion": { "type": "string" },
    "producedAt": { "type": "string", "format": "date-time" },
    "source": { "type": "string" },

    "payload": {
      "type": "object",
      "required": [
        "asset_uuid","device_id","recorded_at","latitude","longitude"
      ],
      "properties": {
        "asset_uuid": { "type": "string", "format": "uuid" },
        "device_id": { "type": "string" },
        "recorded_at": { "type": "string", "format": "date-time" },
        "received_at": { "type": ["string","null"], "format": "date-time" },
        "latitude": { "type": "number", "minimum": -90, "maximum": 90 },
        "longitude": { "type": "number", "minimum": -180, "maximum": 180 },
        "heading": { "type": ["number","null"], "minimum": 0, "maximum": 360 },
        "speed_kmph": { "type": ["number","null"], "minimum": 0 },
        "altitude_m": { "type": ["number","null"] },
        "accuracy_m": { "type": ["number","null"] },
        "fix_type": { "type": ["string","null"] },
        "battery_percent": { "type": ["number","null"], "minimum": 0, "maximum": 100 },
        "raw_payload": { "type": ["object","null"], "additionalProperties": true },
        "metadata": { "type": ["object","null"], "additionalProperties": true }
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
```

### 4.2 Asset Status — `dl.asset.status`

**File:** `dl.asset.status-1.0.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "dl.asset.status:1.0",
  "title": "dl.asset.status",
  "type": "object",
  "required": [
    "eventId","eventType","eventVersion","producedAt","source","payload"
  ],
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "type": "string", "const": "dl.asset.status" },
    "eventVersion": { "type": "string" },
    "producedAt": { "type": "string", "format": "date-time" },
    "source": { "type": "string" },

    "payload": {
      "type": "object",
      "required": ["asset_uuid","status","updated_by","updated_at"],
      "properties": {
        "asset_uuid": { "type": "string", "format": "uuid" },
        "status": { "type": "string" },
        "previous_status": { "type": ["string","null"] },
        "reason": { "type": ["string","null"] },
        "updated_by": { "type": "string" },
        "updated_at": { "type": "string", "format": "date-time" },
        "metadata": { "type": ["object","null"], "additionalProperties": true }
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
```

### 4.3 Shipment Status — `dl.shipment.status`

**File:** `dl.shipment.status-1.0.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "dl.shipment.status:1.0",
  "title": "dl.shipment.status",
  "type": "object",
  "required": [
    "eventId","eventType","eventVersion","producedAt","source","payload"
  ],
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "type": "string", "const": "dl.shipment.status" },
    "eventVersion": { "type": "string" },
    "producedAt": { "type": "string", "format": "date-time" },
    "source": { "type": "string" },

    "payload": {
      "type": "object",
      "required": ["shipment_uuid","status","updated_at"],
      "properties": {
        "shipment_uuid": { "type": "string", "format": "uuid" },
        "status": { "type": "string" },
        "previous_status": { "type": ["string","null"] },
        "location": {
          "type": ["object","null"],
          "properties": {
            "latitude": { "type": "number" },
            "longitude": { "type": "number" },
            "recorded_at": { "type": ["string","null"], "format": "date-time" }
          },
          "additionalProperties": false
        },
        "updated_by": { "type": ["string","null"] },
        "updated_at": { "type": "string", "format": "date-time" },
        "notes": { "type": ["string","null"] },
        "metadata": { "type": ["object","null"], "additionalProperties": true }
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
```

## 5. Topic Configuration Guidelines

| Topic | Partitions | RF | cleanup.policy | retention.ms | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `dl.asset.location.update` | 12–48 | 3 | delete | 604800000 (7 days) | High volume, raw telemetry |
| `dl.asset.status` | 6–12 | 3 | compact | forever | Maintain latest status |
| `dl.shipment.status` | 6–12 | 3 | compact,delete | 2592000000 (30 days) | Keep latest + limited history |
| `dl.asset.lastknown` (optional) | 12 | 3 | compact | forever | Latest location snapshot |

**Keying strategy:**

*   Asset events → key = `asset_uuid`
*   Shipment events → key = `shipment_uuid`

## 6. Schema Evolution Rules

*   **Default compatibility:** BACKWARD
*   Add fields only as optional
*   Never change type of required fields
*   Deprecate instead of deleting
*   Use `eventVersion` for schema tracking

## 7. Producer Rules

*   Must include CID (`eventId`) for idempotency
*   Validate payload against JSON schema
*   Use `asset_uuid` or `shipment_uuid` as Kafka key
*   Include `producedAt` timestamp
*   Send to DLQ on schema/error failures

## 8. Consumer Rules

*   Process idempotently using `eventId`
*   Maintain ordering per entity (partition key ensures this)
*   **For telemetry:**
    *   Use `recorded_at` to ignore older events
*   **For status:**
    *   Update state only if `updated_at` is newer
*   DLQ retry or operator intervention for poison messages

## 9. DLQ (Dead Letter Queue) Pattern

**DLQ topics:**

*   `dl.dlq.asset.location.update`
*   `dl.dlq.asset.status`
*   `dl.dlq.shipment.status`

**DLQ message format:**

```json
{
  "failedEvent": { ... original event ... },
  "errorType": "VALIDATION_ERROR",
  "errorMessage": "latitude out of range",
  "failedAt": "2025-12-07T06:14:20Z"
}
```

## 10. Monitoring Requirements

*   Consumer lag (records + time)
*   Producer failures
*   DLQ growth
*   Broker disk usage
*   Partition skew
*   Schema registry rejection rates

## 11. Summary

This document defines the official Kafka event contract for:

*   Real-time asset tracking
*   Shipment lifecycle updates
*   Asset lifecycle updates