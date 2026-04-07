# 🚀 Subscription Reaper

> **Take control of your subscriptions. Stop wasting money effortlessly.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)
![Status](https://img.shields.io/badge/Status-Beta-orange)
![Build](https://img.shields.io/badge/Build-Passing-brightgreen)
![PRs](https://img.shields.io/badge/PRs-Welcome-brightgreen)

---


## 🎯 Hero Section

**Subscription Reaper** is a smart desktop app that helps you track, manage, and cancel recurring subscriptions — before they drain your wallet.

💡 *Never forget a subscription again.*

### Why Subscription Reaper?

| Before | After |
|--------|-------|
| ❌ Forgotten renewal dates | ✅ Smart reminders |
| ❌ Wasted money on unused services | ✅ Full visibility |
| ❌ Manual spreadsheet tracking | ✅ One-click management |
| ❌ Difficult cancellation process | ✅ Web Cancel Assistant |

---

## 🧩 Project Overview & Problem Statement

### ❗ The Problem

Modern users subscribe to dozens of services (Netflix, Spotify, Amazon Prime, SaaS tools, free trials), but face common challenges:

| Problem | Impact |
|---------|--------|
| **Forgotten renewal dates** | Unexpected charges on credit cards |
| **Unused subscriptions** | Average user wastes $348/year |
| **Difficult cancellation** | Hidden buttons, endless phone calls |
| **No centralized view** | Logging into 10+ accounts to check |
| **Trial conversion traps** | Forgetting to cancel before billing starts |

### 📊 The Cost of Subscription Neglect
Average user subscriptions: 12-16 active services
Monthly cost: $150-300
Annual wasted spend: $348 (unused services)
Time spent managing: 3+ hours/month


### ✅ The Solution

**Subscription Reaper** centralizes and simplifies subscription management by providing:

- 🏦 **One dashboard** for all subscriptions
- ⏰ **Proactive alerts** before renewal dates
- 🗑️ **Easy deletion** of unwanted services
- 🌐 **Web Cancel Assistant** - helps navigate to cancellation pages
- 💾 **Local-first** - your data stays on your machine

---

## ✨ Key Features

### Core Features

| Feature | Description | Status |
|---------|-------------|--------|
| 📊 **Subscription Tracking** | Manage all subscriptions in one place | ✅ Complete |
| ⏰ **Renewal Alerts** | Never miss billing cycles | ✅ Complete |
| ✏️ **Edit & Organize** | Full CRUD operations for subscriptions | ✅ Complete |
| 🌐 **Web Cancel Assistant** | Helps navigate cancellation pages | ✅ Complete |
| 💾 **Local Storage** | Fast, offline-first experience | ✅ Complete |
| 🖥️ **Windows Desktop UI** | Clean and responsive design | ✅ Complete |
| 📈 **Spending Analytics** | Visualize monthly/yearly costs | 🚧 In Progress |
| 🔔 **Push Notifications** | Desktop alerts for renewals | 📋 Planned |

### Advanced Features

- 🏷️ **Category Organization** – Group by type (Entertainment, Productivity, etc.)
- 💰 **Currency Support** – Multi-currency tracking
- 📅 **Calendar View** – Visual renewal timeline
- 📤 **Export Data** – CSV/JSON backup
- 🔍 **Search & Filter** – Find subscriptions quickly
- 📊 **Spending Trends** – Monthly/yearly comparisons

---

## 🛠️ Tech Stack

### Frontend

| Technology | Purpose | Why Chosen |
|------------|---------|-------------|
| **Flutter (Dart)** | Cross-platform UI framework | Fast iteration, beautiful UI |
| **Material Design 3** | UI components & theming | Modern Windows-native look |
| **Provider/Riverpod** | State management | Simple, reactive architecture |

### Backend

| Technology | Purpose |
|------------|---------|
| ❌ **None** | Local-first architecture – no cloud dependencies |

### Database & Storage

| Technology | Purpose |
|------------|---------|
| **SharedPreferences / Hive** | Local storage for subscription data |
| **JSON serialization** | Data persistence format |

### Utilities

| File | Purpose |
|------|---------|
| `format.dart` | Date, currency, and text formatting |
| `webview2_gate.dart` | WebView2 integration for cancellation assistant |

### Development Tools

| Tool | Purpose |
|------|---------|
| **Flutter SDK 3.x** | Core framework |
| **Dart SDK 3.x** | Programming language |
| **Visual Studio 2022** | Windows desktop build tools |
| **Git** | Version control |

---

## 🏗️ Architecture & Data Flow

### Data Flow Diagram
flowchart LR
    subgraph User Actions
        A[User Input]
        B[View Subscription]
        C[Edit/Delete]
        D[Cancel via Web]
    end
    
    subgraph Application
        E[Flutter UI]
        F[Storage Service]
        G[Subscription Model]
        H[WebView2 Gate]
    end
    
    subgraph Storage
        I[(Local JSON)]
    end
    
    A --> E
    E --> F
    F --> I
    I --> F
    F --> E
    E --> B
    B --> G
    C --> F
    D --> H

## UML Class Diagram
classDiagram
    class Subscription {
        +String id
        +String name
        +double price
        +String currency
        +DateTime renewalDate
        +String category
        +String notes
        +bool isActive
        +getFormattedPrice()
        +getDaysUntilRenewal()
        +isExpiringSoon()
    }
    
    class StorageService {
        -List~Subscription~ _subscriptions
        +Future~List~Subscription~~ loadSubscriptions()
        +Future~void~ saveSubscriptions()
        +Future~void~ addSubscription(Subscription sub)
        +Future~void~ updateSubscription(Subscription sub)
        +Future~void~ deleteSubscription(String id)
        +Future~void~ clearAll()
    }
    
    class FormatUtils {
        +static String formatCurrency(double amount)
        +static String formatDate(DateTime date)
        +static String formatRelativeTime(DateTime date)
        +static int calculateDaysRemaining(DateTime date)
    }
    
    class WebCancelAssistant {
        +String url
        +WebViewController controller
        +Future~void~ loadUrl(String url)
        +Future~void~ navigateToCancellation(String serviceName)
    }
    
    class HomeScreen {
        +List~Subscription~ subscriptions
        +void loadData()
        +void deleteSubscription(String id)
        +void navigateToDetail(Subscription sub)
    }
    
    class EditorScreen {
        +Subscription? editingSubscription
        +void saveSubscription()
        +void validateInputs()
    }
    
    HomeScreen --> StorageService
    HomeScreen --> Subscription
    EditorScreen --> StorageService
    EditorScreen --> Subscription
    DetailScreen --> Subscription
    WebCancelAssistant --> FormatUtils
    StorageService --> Subscription

## Screen Navigation Flow
flowchart TD
    Start([App Launch]) --> Home[Home Screen<br/>Subscription List]
    
    Home --> |FAB Click| EditorNew[Editor Screen<br/>New Subscription]
    Home --> |Tap Subscription| Detail[Detail Screen<br/>View Details]
    Home --> |Settings Icon| Settings[Settings Screen]
    Home --> |Cancel Button| WebCancel[Web Cancel Assistant]
    
    Detail --> |Edit Button| EditorEdit[Editor Screen<br/>Edit Mode]
    Detail --> |Delete Button| Confirm{Confirm Delete?}
    Confirm --> |Yes| Home
    Confirm --> |No| Detail
    
    EditorNew --> |Save| Home
    EditorEdit --> |Save| Detail
    EditorNew --> |Cancel| Home
    EditorEdit --> |Cancel| Detail
    
    WebCancel --> |Back| Home
    Settings --> |Back| Home

## State Management Flow 
stateDiagram-v2
    [*] --> Loading
    Loading --> Loaded: Data fetched
    Loading --> Error: Load failed
    
    Loaded --> Adding: Add clicked
    Adding --> Saving: Form submitted
    Saving --> Loaded: Save complete
    
    Loaded --> Editing: Edit clicked
    Editing --> Saving: Update submitted
    Saving --> Loaded: Update complete
    
    Loaded --> Deleting: Delete clicked
    Deleting --> Loaded: Delete complete
    
    Loaded --> WebCancel: Cancel clicked
    WebCancel --> Loaded: Cancel complete

### 🏛️ High-Level Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        HS[Home Screen]
        DS[Detail Screen]
        ES[Editor Screen]
        SS[Settings Screen]
        WC[Web Cancel Assistant]
    end
    
    subgraph "Business Logic Layer"
        SM[Subscription Model]
        VAL[Validation Logic]
        CALC[Calculation Utils]
    end
    
    subgraph "Data Layer"
        SSvc[Storage Service]
        LocalDB[(Local Storage)]
        CFG[Config Storage]
    end
    
    HS --> SSvc
    ES --> SSvc
    DS --> SM
    WC --> WebView2[WebView2 Control]
    SSvc --> LocalDB
    SSvc --> CFG
