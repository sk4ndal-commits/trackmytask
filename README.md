# Track My Tasks

A Flutter-based desktop time tracking application for efficiently managing and tracking time spent on various tasks.

## Features

- **Task Management**: Create, edit, and delete tasks
- **Time Tracking**: Start and stop timers for tasks
- **Work Location Tracking**: Record whether you're working from home or office
- **Daily Summary**: View a summary of all tracked tasks with their durations
- **Data Export**: Export your time tracking data as CSV
- **Light/Dark Theme**: Switch between light and dark mode
- **Cross-Platform**: Works on Windows, macOS, and Linux


## Technologies

- Database / persistence — `sqflite` (mobile), `sqflite_common_ffi` (desktop) and `path_provider` (for locating DB files). Used for storing tasks and time entries.
- Task & time models — `lib/models/task.dart` and `lib/models/time_entry.dart` represent application data.
- State management — `provider` (used in services and UI to share app state).
- Desktop integration / window control — `window_manager` (desktop-specific window handling and behavior).
- Date/time formatting & localisation — `intl` (formatting dates and durations shown in the UI).
- User preferences — `shared_preferences` (store simple user settings such as theme choice).
- Data export — `excel` (XLSX) and `csv` (CSV export) for exporting tracked data.
- Theme handling — `lib/services/theme_service.dart` and `lib/widgets/theme_toggle_button.dart` provide light/dark theme switching.
- Testing & linting (dev) — `flutter_test` and `flutter_lints` used during development and CI for tests and lint rules.

