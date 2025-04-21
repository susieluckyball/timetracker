# Time Tracker App

A native iOS time tracking application built with Swift and SwiftUI.

## Features
- Track time for different activities
- Add new activities
- View weekly statistics
- Native iOS experience
- Automatic data persistence

## Development Requirements
- Xcode 13 or later
- iOS 15 or later
- Swift 5.5 or later

## Setup Instructions

1. Open the project in Xcode:
   - Open Xcode
   - Select "Open a project or file"
   - Navigate to the TimeTrackerSwift directory
   - Select the project

2. Build and Run:
   - Select your iOS device or simulator
   - Click the "Play" button or press Cmd+R

## Usage

1. Add Activities:
   - Enter the activity name in the text field
   - Click "Add"

2. Track Time:
   - Select an activity from the list
   - Click "Start" to begin tracking
   - Click "Stop" when finished

3. View Statistics:
   - Click "View Weekly Stats" to see your activity time for the past 7 days

## Project Structure

- `Activity.swift`: Data model and storage
- `ContentView.swift`: Main app interface
- `TimeTrackerApp.swift`: App entry point

## Notes

- The app uses UserDefaults for data persistence
- All time tracking data is saved automatically
- The weekly statistics view shows a list of activities and their times
