# AirRoom - Classroom Air Quality Monitoring System

A comprehensive indoor air quality (IAQ) monitoring and alert management system designed for educational environments (**AirRoom**). Built on a robust **Java Servlet/JSP (PRJ301)** MVC architecture connected to a **Microsoft SQL Server** database, integrated with an **ESP32 IoT Sensor Node** for real-time telemetry and automated controls.

---

## Project Overview

In enclosed, air-conditioned classrooms with high student density, poor ventilation can lead to excessive accumulation of carbon dioxide (CO2), temperature fluctuations, and potential toxic gas hazards (CO). **AirRoom** addresses these challenges by providing:
- **Continuous Monitoring**: Tracks 4 primary environmental metrics — Temperature, Relative Humidity, Carbon Dioxide (CO2), and Carbon Monoxide (CO).
- **Dynamic Safety Thresholds & Alerts**: Automatically checks measurements against room-specific warning thresholds to generate active safety alerts (`OPENING`).
- **Closed-Loop IoT Measurement Control**: Orchestrates measurements on ESP32 microcontrollers over HTTP REST APIs, supporting both on-demand (Manual) and recurring (Auto) modes.
- **Role-Based Access Control (RBAC)**: Secure multi-tier permissions enforcing least privilege across 3 standard roles in the database: Administrator (`ADMIN`), System Operator (`OPERATOR`), and Read-only Viewer (`VIEWER`).

---

## Architecture & Technology Stack

### 1. Software & Backend
- **Platform**: Java EE (Jakarta/Java Servlet, JSP, JSTL, Filter, Session Management).
- **Database Engine**: Microsoft SQL Server via JDBC (`com.microsoft.sqlserver.jdbc.SQLServerDriver`).
- **Design Pattern**: MVC (Model - View - Controller) with DAO (Data Access Object) and Service layers.
- **Security & Infrastructure**:
  - `AuthFilter`: Enforces URL authorization, session authentication, and role checks.
  - Global **UTF-8** encoding across requests, responses, and JSP pages.
  - Concurrency-safe command leasing with SQL Server transactions (`Device_Command`).

### 2. Frontend & User Interface
- **Core Technologies**: Semantic HTML5, Modern Responsive CSS3, Vanilla JavaScript (ES6+).
- **Data Visualization**: Real-time interactive charts rendered with pure SVG vector paths, allowed safety boundaries, and custom hover tooltips.
- **Asynchronous Workflow**: Non-blocking client polling for measurement status updates and automated countdown timers.

### 3. Hardware & IoT Sensor Node
- **Microcontroller**: ESP32 DevKit V1 (2.4GHz Wi-Fi, HTTP client).
- **Sensors**:
  - **DHT22** (GPIO 15): Digital Temperature & Relative Humidity sensor.
  - **MQ-135** (GPIO 34 / ADC1): Semiconductor sensor calibrated for Carbon Dioxide (CO2) detection.
  - **MQ-7** (GPIO 35 / ADC1): Semiconductor sensor calibrated for Carbon Monoxide (CO) detection.
- **Onboard Feedback & Display**:
  - **16x2 I2C LCD Display** (Address `0x27`): Displays live readings, measurement countdown, and network connection status.
  - **Common-Cathode RGB LED** (Red: GPIO 25, Green: GPIO 26, Blue: GPIO 27): Provides immediate visual status indication based on safety thresholds.
- **Communication Protocol**: RESTful endpoints (`/device/command`, `/device/data`) authenticated via `X-Device-Code` and `X-API-Key` HTTP headers.

---

## Key Features

### 1. Centralized Dashboard
- High-level KPIs: Active classrooms, connected sensor nodes (`is_active = 1`), and pending safety alerts (`OPENING`).
- Real-time university-wide average air quality indicators.
- Live classroom cards displaying instantaneous telemetry and status pills.

### 2. Classroom & Safety Threshold Management
- Search, filter, and inspect classroom metadata (room code, building, capacity).
- Configurable per-room safety thresholds:
  - Maximum Temperature threshold (`temp_warning_threshold`).
  - Maximum Humidity threshold (`humid_warning_threshold`).
  - Maximum CO2 safety limit (`co2_warning_threshold`).
  - Maximum CO safety limit (`co_warning_threshold`).

### 3. Measurement Workflows (Manual & Auto)
- **On-Demand Manual Measurement**:
  - The operator triggers measurement from the web UI.
  - The server creates a `Device_Command` with status `PENDING`.
  - The ESP32 claims the command (`SENT`), performs multi-sample averaging over a 10-second window to eliminate thermal shock noise (`TEMP_EFFECT`), and posts results back.
  - The server persists an `Air_Session`, generates alerts if thresholds are breached, and updates command status to `DONE`.
- **Scheduled Automated Measurement**:
  - Configurable sampling intervals (e.g., 15s, 30s, 1m, 5m).
  - Background execution cycle without requiring repetitive manual input.
  - Unified Start Auto / Stop Auto toggle synchronized directly with database command records.

### 4. Sensor Device Management
- Register and maintain hardware sensor devices, MAC addresses, and assigned API keys.
- Associate sensor devices to specific classrooms.
- Real-time heartbeat tracking (`last_seen`) and activation toggles (`is_active`).

### 5. Alert Handling & Telemetry History
- Detailed alert log categorized by sensor metric type (`TEMPERATURE`, `HUMID`, `CO2`, `CO`).
- Review and disposition workflow: Authorized roles can `Approve` or `Reject` alerts with resolution notes; `VIEWER` accounts retain read-only access.
- Historical session records (`Air_Session`) with exact timestamps and individual sensor readings.

### 6. User Management & Role-Based Access Control (RBAC)
- Full UTF-8 support for user profiles and Vietnamese full names.
- 3 distinct user roles in the database:
  - **ADMIN**: Complete system administrative privileges (users, classrooms, devices, and system configuration).
  - **OPERATOR**: Station operations, manual/auto measurement triggers, threshold monitoring, and alert handling/resolution.
  - **VIEWER**: Read-only access to classroom metrics, telemetry logs, and air quality status.

---

## Directory Structure

```plaintext
AirRoom/
├── app/
│   ├── src/java/
│   │   ├── controller/      # Web Servlets & IoT REST API endpoints
│   │   ├── dao/             # Data Access Objects (Device, Room, AirSession, Alert...)
│   │   ├── filter/          # AuthFilter (RBAC enforcement & global UTF-8 encoding)
│   │   ├── model/           # Java Bean entities mapping SQL Server schema
│   │   ├── service/         # Business logic (MeasureService) & custom exceptions
│   │   └── util/            # DBContext (JDBC connection), Web utility helpers
│   └── web/
│       ├── assets/
│       │   ├── css/         # Modular stylesheets (dashboard, room detail, measure...)
│       │   └── js/          # Client-side scripts (SVG charts, measure polling, clocks)
│       └── WEB-INF/
│           ├── views/       # JSP presentation templates
│           └── web.xml      # Application deployment descriptor & charset configuration
├── sql/
│   ├── schema.sql           # Database schema definition
│   └── sample_data.sql      # Seed data for testing and development
├── firmware/
│   └── firmware.ino         # ESP32 firmware source code (C++/Arduino)
├── check.md                 # Project implementation task checklist
└── README.md                # System documentation
```

---

## Installation & Deployment

### 1. Prerequisites
- **Java Development Kit (JDK)**: Version 8 or 11+.
- **Servlet Container**: Apache Tomcat 8.5 / 9.0.
- **IDE**: NetBeans IDE (configured with Java Web / Ant support).
- **Database Engine**: Microsoft SQL Server 2017+ (TCP/IP enabled on port 1433, SQL Server Authentication enabled).
- **Firmware Flashing Tool**: Arduino IDE with ESP32 board support installed.

### 2. Database Setup
1. Launch SQL Server Management Studio (SSMS).
2. Execute `sql/schema.sql` (which automatically creates the `AirRoomDB` database, tables, and default role/user accounts).
3. Execute `sql/sample_data.sql` to populate initial test classrooms, devices, and sessions.

### 3. Web Application Configuration
1. Open the project in **NetBeans IDE**.
2. Inspect `app/src/java/util/DBContext.java`:
   - Verify connection properties (`serverName`, `portNumber`, `databaseName`, `user`, `password`).
3. Right-click the project root and select **Clean and Build**.
4. Select **Run** to deploy the application to Apache Tomcat.
5. Access the application in your browser at: `http://localhost:8080/Airroom/` (or your configured context path).

### 4. ESP32 Firmware Configuration & Flashing
1. Open `firmware/firmware.ino` in Arduino IDE.
2. Update network and server credentials:
   - Wi-Fi credentials (`ssid`, `password`) — *must be a 2.4GHz network*.
   - Server host IP and port: `http://<SERVER_IP>:8080/Airroom/device/command` and `/Airroom/device/data`.
   - Matching hardware credentials (`deviceCode`, `apiKey`) as registered in the `Device` database table.
3. Select board: `DOIT ESP32 DEVKIT V1` and the correct COM port.
4. Upload firmware and monitor output via Serial Monitor (Baud rate `115200`).

---

## Default Test Accounts

| Username | Password | Role | Permissions |
| :--- | :--- | :--- | :--- |
| `admin` | `123456` | **ADMIN** | Full administrative access to users, classrooms, devices, and system settings |
| `operator` | `123456` | **OPERATOR** | Triggers manual/auto measurements, monitors live telemetry, processes alerts |
| `viewer` | `123456` | **VIEWER** | Read-only access to classroom metrics and alert status |

---

## License & Academic Note
Developed for the **PRJ301 (Java Web Application)** curriculum at **FPT University**. All rights reserved.
