# MediStock — Medicine Inventory Management System
## Phase 1: Complete Frontend Development

MediStock is a modern, responsive, healthcare-grade pharmacy and medicine inventory management SaaS system designed for hospital networks, clinical pharmacies, and warehouse dispensaries.

---

## 🛠 Technology Stack

- **Framework**: React 18
- **Build Tool**: Vite 5
- **Routing**: React Router DOM v6
- **Icons**: Lucide React
- **Data Visualizations**: Recharts
- **Styling**: Modern Custom CSS3 with Design Tokens (CSS Variables, Flexbox, CSS Grid)
- **State & Data Layer**: React Context API with LocalStorage browser persistence and asynchronous simulated API service abstraction (`src/services/api.js`)

---

## 🚀 Getting Started

### Prerequisites
- Node.js (v18+ recommended)
- npm (v9+)

### Installation & Launch
```bash
# 1. Install dependencies
npm install

# 2. Start the development server
npm run dev

# 3. Access in browser
# http://localhost:5173
```

### Production Build
```bash
# Build production bundle
npm run build

# Preview production build locally
npm run preview
```

---

## 📦 Project Architecture

```
MEDICINE_INV/
├── public/
│   └── favicon.svg              # Custom medical logo favicon
├── src/
│   ├── components/
│   │   ├── common/              # Reusable UI component library
│   │   │   ├── ConfirmDialog.jsx
│   │   │   ├── DataTable.jsx
│   │   │   ├── EmptyState.jsx
│   │   │   ├── FilterDropdown.jsx
│   │   │   ├── FormField.jsx
│   │   │   ├── LoadingState.jsx
│   │   │   ├── Modal.jsx
│   │   │   ├── PageHeader.jsx
│   │   │   ├── Pagination.jsx
│   │   │   ├── SearchBar.jsx
│   │   │   ├── StatCard.jsx
│   │   │   ├── StatusBadge.jsx
│   │   │   └── ToastNotification.jsx
│   │   ├── layout/              # Responsive App Shell
│   │   │   ├── Layout.jsx
│   │   │   ├── Navbar.jsx
│   │   │   └── Sidebar.jsx
│   │   └── modals/              # Business domain modals
│   │       ├── BatchDetailsModal.jsx
│   │       ├── BatchModal.jsx
│   │       ├── MedicineDetailsModal.jsx
│   │       ├── MedicineModal.jsx
│   │       ├── SupplierDetailsModal.jsx
│   │       ├── SupplierModal.jsx
│   │       └── TransactionModal.jsx
│   ├── context/
│   │   └── InventoryContext.jsx # Single source of truth & shared reactive state
│   ├── mock/                    # Seed mock datasets
│   │   ├── batches.js
│   │   ├── index.js
│   │   ├── medicines.js
│   │   ├── suppliers.js
│   │   └── transactions.js
│   ├── pages/                   # Main Application Pages
│   │   ├── BatchesPage.jsx
│   │   ├── DashboardPage.jsx
│   │   ├── MedicinesPage.jsx
│   │   ├── SuppliersPage.jsx
│   │   └── TransactionsPage.jsx
│   ├── services/
│   │   └── api.js               # Service layer prepared for Java Spring Boot REST API
│   ├── styles/                  # Modular Design System CSS
│   │   ├── components.css
│   │   ├── dashboard.css
│   │   ├── index.css
│   │   └── layout.css
│   ├── utils/                   # Shared utility modules
│   │   ├── dateUtils.js
│   │   ├── formatters.js
│   │   └── validators.js
│   ├── App.jsx
│   └── main.jsx
├── index.html
├── package.json
└── vite.config.js
```

---

## 🌟 Key Features & Business Rules Implemented

### 1. Dashboard Page
- **KPI Summary Cards**: Computed dynamically from active batch quantities:
  - Total Medicines
  - Total Available Stock
  - Low Stock Medicines
  - Expiring Soon (< 30 days)
  - Expired Batches (< 0 days)
- **Analytics Visualizations**:
  - Stock distribution by medicine category (Bar Chart)
  - 7-day inbound vs outbound stock movement trends (Area Chart)
- **Critical Alert Banner**: Surfaces immediate alerts if batches require quarantine or safety buffers are breached.
- **Preview Tables**: Direct access to low-stock medicines, upcoming expirations, and recent transactions.

### 2. Medicine Catalogue (`/medicines`)
- Dynamic batch-level inventory roll-up: Total available stock is calculated strictly from active batches rather than duplicate static numbers.
- Full CRUD: Add, Edit, Delete (with active batch dependency guard), and View Details modal.
- View Details modal lists every batch currently registered for that medicine with individual quantities and expiry dates.
- Search by medicine name, generic name, ID, or manufacturer.
- Filter by category and stock status (In Stock, Low Stock, Out of Stock).
- Multi-column sorting and pagination.

### 3. Batches & Expiry Control (`/batches`)
- Date-aware calculations dynamically computing days remaining or days past expiry.
- Status classification:
  - **Expired**: Expiry date earlier than today (highlighted in soft red).
  - **Expiring Soon**: Expiry date within the next 30 days (highlighted in amber).
  - **Valid**: Expiry date more than 30 days away.
- Add Batch form with manufacturing date and expiry date validation (`mfgDate <= expiryDate`).
- Full CRUD, supplier filtering, status filtering, lot valuation calculation (`quantity * purchasePrice`).
- Expired batches are preserved for pharmaceutical compliance and historical audit.

### 4. Suppliers Directory (`/suppliers`)
- Vendor registry with verified contact persons, telephone numbers, emails, and facility addresses.
- Displays number of active associated batches for each vendor.
- View Supplier Details modal with list of batches supplied by that vendor.
- Deletion Protection: Blocks deletion if active inventory batches depend on the supplier, explaining why to the user.

### 5. Stock Transactions Ledger (`/transactions`)
- Supports **Stock In**, **Stock Out**, and **Adjustment**.
- Context-aware modal: Selecting a medicine filters batch choices to only valid lots for that medicine and displays its real-time stock balance.
- **Strict Clinical Business Rules**:
  - `Stock Out` rejects quantities greater than available stock.
  - `Stock Out` strictly disallows issuing stock from expired batches.
  - `Adjustment` allows entering verified physical inventory counts and records variances.
- Double-confirmation review modal prior to submitting transactions.
- Audit trail modal showing previous quantity, delta, and post-transaction balance.

### 6. Persistence & State Management
- All operations update the shared `InventoryContext` and persist in browser `localStorage`.
- Changes survive page reloads.
- Includes a "Reset Demo Data" option in the sidebar to easily restore the default demo scenario.

---

## 🔗 Phase 2 — Future Java Spring Boot & MySQL Integration

The frontend was strictly architected with clean separation of concerns:
- `src/services/api.js` encapsulates all data communication.
- In Phase 2, the simulated asynchronous methods in `api.js` will map 1:1 to Spring Boot REST controllers:
  - `GET /api/v1/medicines`, `POST /api/v1/medicines`, `PUT /api/v1/medicines/{id}`, `DELETE /api/v1/medicines/{id}`
  - `GET /api/v1/batches`, `POST /api/v1/batches`, `PUT /api/v1/batches/{id}`, `DELETE /api/v1/batches/{id}`
  - `GET /api/v1/suppliers`, `POST /api/v1/suppliers`, `PUT /api/v1/suppliers/{id}`, `DELETE /api/v1/suppliers/{id}`
  - `GET /api/v1/transactions`, `POST /api/v1/transactions`
- No presentation components need to be modified when switching from mock data to the backend REST API.
