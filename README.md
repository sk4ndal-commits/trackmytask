# Track My Tasks

A Flutter-based desktop time tracking assistant that runs silently in the background with a system tray icon.

## Features

- **Task Management**: Create, edit, and delete tasks
- **Time Tracking**: Start and stop timers for tasks
- **System Tray Integration**: Access the app from the system tray
- **Daily Summary**: View a summary of all tracked tasks with their durations
- **Background Operation**: App runs silently in the background
- **Cross-Platform**: Works on Windows, macOS, and Linux

## Getting Started

### Prerequisites

- Flutter SDK (version 3.6.0 or higher)
- Dart SDK (version 3.0.0 or higher)

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run -d windows` (or macos/linux) to start the application

## Usage

### Managing Tasks

1. Click the "+" button to add a new task
2. Use the task list screen to view, edit, and delete tasks

### Tracking Time

1. Start tracking time by clicking the "Start Tracking" button and selecting a task
2. Stop tracking by clicking the "Stop Tracking" button
3. View your daily summary to see how much time you've spent on each task

### System Tray

- The app runs in the system tray for easy access
- Right-click the tray icon to see options:
  - Start/stop tracking
  - Open the main app window
  - View daily summary
  - Exit the application

## Architecture

- **Models**: Task and TimeEntry classes for data representation
- **Services**: Database, Task, and SystemTray services for business logic
- **UI**: Home, TaskList, and DailySummary screens for user interaction

## Dependencies

- sqflite: SQLite database integration
- path_provider: File system access
- tray_manager: System tray functionality
- window_manager: Desktop window management
- intl: Date formatting
- provider: State management
# trackmytask
