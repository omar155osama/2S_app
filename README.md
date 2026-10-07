# 2S Sales Team Mobile App

## Overview
A robust Flutter mobile application designed for the 2S Home Wear sales team. The app integrates seamlessly with Odoo ERP, allowing the team to browse customers, verify details, and manage Sales Orders from a mobile interface. It supports both online operations and offline synchronization, ensuring sales operations can continue without internet connectivity.

## Features

### Authentication
- **Odoo Authentication:** Direct authentication against the Odoo database via XML-RPC.
- **Session Management:** Securely persists active sessions using `SharedPreferences`.
- **Role Detection:** Verifies internal user privileges.

### Customers
- **Customer List:** Displays an optimized list of active customers (filtered by `customer_rank > 0`).
- **Search:** Real-time name search capability.
- **Customer Details:** Displays comprehensive contact information.
- **Edit Capabilities:** Allows updating customer phone numbers.

### Offline Support
- **Cached Data:** Customer lists, details, and sales orders are cached locally for offline reading.
- **Offline Actions:** Phone number edits and Sales Order confirmations can be executed offline.
- **Auto-Sync:** Background synchronization automatically dispatches pending offline actions to Odoo once network connectivity is restored.

### Sales Orders
- **Role-Based Access:** Exclusively available to Odoo internal users (`base.group_user`).
- **Sales Dashboard:** Overview of all relevant sales orders, statuses, and dates.
- **Order Details:** Detailed product breakdowns, quantities, and financial subtotals.
- **Confirmation:** Confirm Quotations directly into Sales Orders using Odoo's native `action_confirm` workflow.

### UI
- **Light & Dark Theme:** Semantic, high-contrast theming natively supporting system preferences.
- **Responsive Layouts:** Modern CRM-style interface utilizing proportional padding, custom AppBars, and optimized screen flow.
- **State Feedback:** Utilizes `Skeletonizer` for seamless loading states and Snackbars for error reporting.

## Architecture
The application employs a clean, lightweight architecture suitable for mobile ERP integration without over-engineering:

**Presentation → Repository → DataSource → Odoo / Local Storage**

- **Presentation:** Uses `flutter_bloc` (Cubits) to manage UI state and trigger actions.
- **Repository:** Acts as the single source of truth, orchestrating between local cache (offline) and remote XML-RPC calls (online).
- **DataSource:** Contains the concrete implementations for Odoo (`xml_rpc`) and local storage (`shared_preferences`). 

*Note: Domain/UseCase layers were intentionally omitted in favor of a leaner, highly pragmatic architecture.*

## Odoo Integration
The app relies strictly on **XML-RPC** for all backend communication:
- `/xmlrpc/2/common`: Utilized exclusively for `authenticate`.
- `/xmlrpc/2/object`: Utilized for `execute_kw` operations.

**Models Used:**
- `res.users`: For authentication and group verification.
- `res.partner`: For retrieving and modifying customer records.
- `sale.order` & `sale.order.line`: For retrieving quotations and executing confirmations.

**Specific Implementation Details:**
- **Customer Filtering:** Enforces `['customer_rank', '>', 0]`.
- **Internal User Validation:** Validates `base.group_user` via `has_group`.
- **Order Confirmation:** Executes the `action_confirm` method on `sale.order`.

## Configuration
Odoo connection variables are injected securely at compile-time using Dart environment variables. 
By default, the application is configured to point to `https://2s-test.odoo.com` using the `2s-test` database.

You can override these at runtime:
```bash
flutter run --dart-define=ODOO_URL=https://your-odoo-instance.com --dart-define=ODOO_DATABASE=your_database_name
```
*No hardcoded passwords or sensitive tokens are stored in the codebase.*

## Setup
To run the project locally:

1. Retrieve dependencies:
   ```bash
   flutter pub get
   ```
2. Run the application on your desired device:
   ```bash
   flutter run
   ```

## Demo / User Access
Please provide your own valid Odoo user credentials (username and password) on the Login screen. To access the Sales Orders feature, ensure your provided Odoo user is part of the `base.group_user` (Internal User) group.

## Offline Behavior
- **Customers:** Fetched remotely while online and cached. When offline, data is read from the local cache. If a phone number is edited offline, it is marked as a "pending change".
- **Sales Orders:** When a Quotation is confirmed offline, the UI flags the operation as pending. 
- **Synchronization:** The `OfflineSyncManager` listens for network restoration. Upon reconnection, it automatically executes all pending XML-RPC operations and refreshes the local cache.

## Testing
The project embraces a targeted testing strategy:
- **Unit Tests:** For Repositories, DataSources, and Cubits.
- **Widget Tests:** Ensures UI regressions (like loading states and role-based visibility) do not occur.
- **Mocking:** Employs `mocktail` to isolate network and storage layers during execution.

Execute the test suite:
```bash
flutter test
```

## Build
To compile a production-ready Android APK:
```bash
flutter build apk --release
```

## Project Structure
```text
lib/
  core/
    di/               # Dependency Injection
    errors/           # Failure models
    network/          # XML-RPC client, offline sync manager
    routes/           # GoRouter configuration
    theme/            # Semantic Light/Dark themes
  features/
    auth/             # Login, Session management
    customers/        # Customer lists, details, phone editing
    sales_orders/     # Sales dashboard, confirmation logic
    settings/         # Logout, Theme toggles
    splash/           # Initial load screen
  main.dart
```

## Design / Engineering Notes
- **XML-RPC over REST:** Used explicitly per assignment requirements.
- **State Management:** `flutter_bloc` ensures clean separation between UI and logic.
- **Dependency Injection:** `get_it` provides modular decoupling for DataSources and Repositories.
- **Offline Caching:** Handled synchronously via `shared_preferences` mapped against `ConnectivityPlus`.

## Limitations / Notes
- XML-RPC, while universally supported by Odoo, incurs a slightly higher latency compared to modern JSON-RPC endpoints. The app compensates for this by utilizing local caching and `Skeletonizer` UI feedback.
- Depending on device-specific OS network handling, the offline auto-sync may experience a brief 1-second delay upon reconnecting to WiFi before changes propagate to Odoo.
