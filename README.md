# Track My Tasks

A Flutter-based desktop time tracking application for efficiently managing and tracking time spent on various tasks.

## Features

- **Task Management**: Create, edit, and delete tasks
- **Time Tracking**: Start and stop timers for tasks
- **Work Location Tracking**: Record whether you're working from home or office
- **Time Reports**: View daily, weekly, or monthly summaries of all tracked tasks with their durations
- **Data Export**: Export your time tracking data as CSV
- **Light/Dark Theme**: Switch between light and dark mode
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
2. Choose your work location (home or office)
3. Stop tracking by clicking the "Stop Tracking" button
4. View your daily summary to see how much time you've spent on each task

### Time Reports

1. Navigate to the Summary tab to view your time tracking data
2. Choose between daily, weekly, or monthly report views
3. See a breakdown of time spent on each task
4. View time distribution by category and work location (home vs. office)
5. Navigate between different time periods using the arrow buttons
6. Export your data as CSV for further analysis

## Architecture

- **Models**: Task and TimeEntry classes for data representation
- **Services**: 
  - DatabaseService: SQLite database operations
  - TaskService: Business logic for task and time entry management
  - ThemeService: Light/dark theme management
- **UI**: Home, TaskList, and DailySummary screens for user interaction

## Dependencies

- sqflite: SQLite database integration
- sqflite_common_ffi: SQLite for desktop platforms
- path_provider: File system access
- window_manager: Desktop window management
- intl: Date formatting
- provider: State management
- excel & csv: Data export functionality
