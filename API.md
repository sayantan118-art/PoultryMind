# API Documentation

REST API endpoints for Poultry Farm Command Center.

Base URL: `https://api.yourdomain.com/api/v1`

---

## Authentication

### Owner Login (Email + Password)

```http
POST /auth/owner-login
Content-Type: application/json

{
  "email": "owner@farm.com",
  "password": "SecurePassword123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "user_id": "uuid",
    "role": "owner",
    "full_name": "Farm Owner"
  }
}
```

### Supervisor Login (PIN)

```http
POST /auth/supervisor-login
Content-Type: application/json

{
  "phone": "+919876543210",
  "pin": "1234"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "user_id": "uuid",
    "role": "supervisor",
    "full_name": "Supervisor Name",
    "assigned_farm_id": "farm-uuid"
  }
}
```

---

## Endpoints

### Health Check

```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "environment": "development"
}
```

---

### Farms

#### List All Farms (Owner Only)

```http
GET /farms
Authorization: Bearer <token>
```

**Response:**
```json
{
  "farms": [
    {
      "farm_id": "uuid-1",
      "farm_name": "Farm 1 (North)",
      "farm_code": "F1",
      "district": "District A",
      "state": "Maharashtra",
      "is_active": true,
      "created_at": "2025-01-15T10:30:00Z"
    }
  ]
}
```

#### Get Single Farm

```http
GET /farms/{farm_id}
Authorization: Bearer <token>
```

---

### Sheds

#### List Sheds for Farm

```http
GET /farms/{farm_id}/sheds
Authorization: Bearer <token>
```

**Response:**
```json
{
  "sheds": [
    {
      "shed_id": "uuid",
      "shed_name": "Shed A-1",
      "shed_number": 1,
      "capacity_birds": 5000,
      "shed_type": "conventional",
      "ventilation_type": "natural",
      "created_at": "2025-01-15T10:30:00Z"
    }
  ]
}
```

#### Create Shed

```http
POST /farms/{farm_id}/sheds
Authorization: Bearer <token>
Content-Type: application/json

{
  "shed_name": "Shed B-1",
  "shed_number": 2,
  "capacity_birds": 5000,
  "shed_type": "conventional",
  "length_ft": 100,
  "width_ft": 50,
  "ventilation_type": "natural",
  "feeder_type": "automatic",
  "drinker_type": "nipple"
}
```

---

### Flocks

#### List Active Flocks

```http
GET /farms/{farm_id}/flocks?status=active
Authorization: Bearer <token>
```

**Response:**
```json
{
  "flocks": [
    {
      "flock_id": "uuid",
      "flock_code": "F1-S1-2025-001",
      "shed_id": "uuid",
      "breed_id": "uuid",
      "placement_date": "2025-01-15",
      "initial_birds_placed": 5000,
      "net_birds_started": 4950,
      "flock_status": "active",
      "bird_age_days": 45,
      "flock_stage": "grower"
    }
  ]
}
```

#### Create Flock (Owner Only)

```http
POST /farms/{farm_id}/flocks
Authorization: Bearer <token>
Content-Type: application/json

{
  "flock_code": "F1-S1-2025-002",
  "shed_id": "uuid",
  "breed_id": "uuid",
  "placement_date": "2025-01-20",
  "initial_birds_placed": 5000,
  "dead_on_arrival": 50,
  "source_hatchery": "Hatchery XYZ",
  "chick_batch_ref": "BATCH-2025-001"
}
```

---

### Daily Flock Snapshot

#### Get Today's Snapshot

```http
GET /farms/{farm_id}/flocks/{flock_id}/snapshot/today
Authorization: Bearer <token>
```

**Response:**
```json
{
  "snapshot_id": "uuid",
  "flock_id": "uuid",
  "snapshot_date": "2025-02-28",
  "bird_age_days": 44,
  "opening_bird_count": 4950,
  "mortality_count": 5,
  "culled_sick_count": 2,
  "closing_bird_count": 4943,
  "eggs_collected": 2471,
  "eggs_broken": 12,
  "eggs_saleable": 2459,
  "hdp_percent": "49.9%",
  "reported_by_name": "John Supervisor",
  "validation_flags": []
}
```

#### Submit Daily Entry

```http
POST /farms/{farm_id}/flocks/{flock_id}/snapshot
Authorization: Bearer <token>
Content-Type: application/json

{
  "bird_age_days": 44,
  "opening_bird_count": 4950,
  "mortality_count": 5,
  "culled_sick_count": 2,
  "other_movements_count": 0,
  "arrivals_count": 0,
  "closing_bird_count": 4943,
  "eggs_collected": 2471,
  "eggs_broken": 12,
  "eggs_floor": 3,
  "reported_by_name": "John Supervisor"
}
```

**Response:**
```json
{
  "snapshot_id": "uuid",
  "validation_flags": [],
  "status": "accepted"
}
```

---

### Vaccines

#### List Vaccine Master

```http
GET /vaccines
Authorization: Bearer <token>
```

**Response:**
```json
{
  "vaccines": [
    {
      "vaccine_id": "uuid",
      "vaccine_name": "Ranikhet Lasota",
      "disease_target": "Newcastle Disease",
      "vaccine_type": "live",
      "conflict_group": "A",
      "default_method": "Drinking Water",
      "min_gap_before_days": 5,
      "min_gap_after_days": 5
    }
  ]
}
```

#### Get Vaccine Schedule for Breed

```http
GET /vaccines/schedule/breed/{breed_id}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "template_id": "uuid",
  "template_name": "BV-380 Standard Schedule",
  "breed_id": "uuid",
  "items": [
    {
      "item_id": "uuid",
      "sequence_number": 1,
      "vaccine_id": "uuid",
      "vaccine_name": "Ranikhet Lasota",
      "target_day": 5,
      "flexibility_window_days": 3,
      "method": "Drinking Water",
      "is_mandatory": true
    }
  ]
}
```

#### Report Vaccine Event

```http
POST /farms/{farm_id}/flocks/{flock_id}/vaccine-event
Authorization: Bearer <token>
Content-Type: application/json

{
  "vaccine_id": "uuid",
  "actual_date": "2025-02-28",
  "actual_method": "Drinking Water",
  "batch_number": "BATCH-2025-001",
  "coverage_percent": "98.5"
}
```

---

### Feed

#### List Feed Formulas

```http
GET /feeds/formulas
Authorization: Bearer <token>
```

**Response:**
```json
{
  "formulas": [
    {
      "formula_id": "uuid",
      "formula_name": "Layer Standard",
      "formula_code": "LAY-001",
      "flock_stage": "layer",
      "version_number": 1,
      "is_active": true
    }
  ]
}
```

#### Get Feed Formula Details

```http
GET /feeds/formulas/{formula_id}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "formula_id": "uuid",
  "formula_name": "Layer Standard",
  "ingredients": [
    {
      "ingredient_id": "uuid",
      "material_name": "Maize",
      "quantity_per_100kg": 60,
      "is_critical": true
    }
  ],
  "target_cp_pct": "16.5",
  "target_energy": "2850"
}
```

#### Create Feed Batch

```http
POST /farms/{farm_id}/feed-batch
Authorization: Bearer <token>
Content-Type: application/json

{
  "batch_code": "BATCH-2025-001",
  "formula_id": "uuid",
  "production_date": "2025-02-28",
  "quantity_kg": 1000
}
```

#### Dispatch Feed to Shed

```http
POST /farms/{farm_id}/feed-dispatch
Authorization: Bearer <token>
Content-Type: application/json

{
  "batch_id": "uuid",
  "to_shed_id": "uuid",
  "to_flock_id": "uuid",
  "qty_dispatched_kg": 250,
  "dispatch_date": "2025-02-28"
}
```

---

### Health Events

#### Report Health Event

```http
POST /farms/{farm_id}/flocks/{flock_id}/health-event
Authorization: Bearer <token>
Content-Type: application/json

{
  "event_type": "respiratory_issue",
  "description": "Birds showing sneezing and nasal discharge",
  "event_date": "2025-02-28",
  "reported_by_name": "John Supervisor"
}
```

#### Get Health Events for Flock

```http
GET /farms/{farm_id}/flocks/{flock_id}/health-events
Authorization: Bearer <token>
```

---

### Bird Movements

#### Report Bird Movement

```http
POST /farms/{farm_id}/flocks/{flock_id}/bird-movement
Authorization: Bearer <token>
Content-Type: application/json

{
  "movement_type": "sold",
  "bird_count": 500,
  "movement_date": "2025-02-28",
  "reported_by_name": "John Supervisor"
}
```

**Response:**
```json
{
  "movement_id": "uuid",
  "status": "pending",
  "requires_owner_approval": true
}
```

#### Approve/Reject Movement (Owner Only)

```http
PATCH /farms/{farm_id}/bird-movement/{movement_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "approved"
}
```

---

### Alerts

#### Get Alerts for Current User

```http
GET /alerts
Authorization: Bearer <token>
```

**Response:**
```json
{
  "alerts": [
    {
      "alert_id": "uuid",
      "alert_level": "critical",
      "alert_type": "high_mortality",
      "title": "High Mortality Detected - Farm 1",
      "body": "Mortality rate exceeds threshold",
      "action_required": true,
      "read_at": null,
      "created_at": "2025-02-28T10:30:00Z"
    }
  ]
}
```

#### Mark Alert as Read

```http
PATCH /alerts/{alert_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "read": true
}
```

---

### Dashboard (Owner)

#### Get Dashboard Summary

```http
GET /dashboard/summary
Authorization: Bearer <token>
```

**Response:**
```json
{
  "farms": [
    {
      "farm_id": "uuid",
      "farm_name": "Farm 1",
      "total_birds": 250000,
      "total_mortality_today": 125,
      "avg_hdp_today": "47.5%",
      "critical_alerts": 2,
      "vaccines_due": 3
    }
  ],
  "total_production_today": 125000,
  "total_mortality_today": 500,
  "critical_alerts": 5
}
```

#### Get Farm Detailed Dashboard

```http
GET /dashboard/farms/{farm_id}
Authorization: Bearer <token>
```

---

## Error Responses

### 400 Bad Request
```json
{
  "status": 400,
  "error": "Invalid request",
  "message": "Bird count cannot exceed shed capacity"
}
```

### 401 Unauthorized
```json
{
  "status": 401,
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

### 403 Forbidden
```json
{
  "status": 403,
  "error": "Forbidden",
  "message": "Supervisors cannot approve movements"
}
```

### 404 Not Found
```json
{
  "status": 404,
  "error": "Not Found",
  "message": "Farm not found"
}
```

### 500 Internal Server Error
```json
{
  "status": 500,
  "error": "Internal Server Error",
  "message": "Database connection failed"
}
```

---

## Rate Limiting

- **General endpoints**: 100 requests/minute
- **Alert endpoints**: 1000 requests/minute
- **Health check**: No limit

**Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

---

## Pagination

All list endpoints support pagination:

```http
GET /farms?page=1&per_page=20
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

---

## Webhooks (Future)

Webhooks for real-time events:
- `flock.created`
- `health.event.created`
- `alert.critical`
- `vaccine.overdue`

---

## SDK/Client Libraries

- **Python**: `pip install poultry-farm-sdk`
- **JavaScript/TypeScript**: `npm install @poultry/sdk`
- **Go**: `go get github.com/poultry-farm/sdk-go`

---

## Support

- Email: api-support@farm.com
- GitHub Issues: https://github.com/yourorg/poultry-farm/issues
- Slack: #api-support channel
