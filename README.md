# ExpensePilot AI

ExpensePilot AI is a Flutter-based fintech mobile app inspired by modern corporate spend platforms. It helps users track expenses, manage budgets, view card-style spend summaries, and receive AI-like approval recommendations and financial insights.

## Features

- User onboarding with name, monthly budget, and timezone
- Personalized greeting based on saved timezone
- Dark mode and light mode
- Smart dashboard with:
  - total spend
  - budget progress
  - remaining budget
  - AI insights
- Add expense with:
  - formatted currency input
  - category selection
  - note
  - date picker
  - AI suggested category
  - AI recommendation
  - approval workflow status
- Corporate card-inspired screen
- Approval center screen
- Search expenses
- Local data storage using SharedPreferences

## Tech Stack

- Flutter
- Dart
- Provider
- SharedPreferences
- Intl
- currency_text_input_formatter

## AI Logic

This project uses a rule-based AI prototype instead of a real AI API.  
It simulates:
- expense category suggestions
- approval recommendations
- budget alerts
- spending insights

This MVP approach was used to validate the user experience and product workflow before integrating real AI APIs or ML models.

## Screenshots

<p align="center">
  <img src="images/01_splash.png" width="220"/>
  <img src="images/02_onboarding.png" width="220"/>
  <img src="images/03_dashboard_dark.png" width="220"/>
</p>

<p align="center">
  <img src="images/04_dashboard_light.png" width="220"/>
  <img src="images/05_add_expense_ai.png" width="220"/>
  <img src="images/06_cards.png" width="220"/>
</p>

<p align="center">
  <img src="images/07_approvals.png" width="220"/>
  <img src="images/08_search.png" width="220"/>
</p>

## Project Goal

The goal of this project is to demonstrate how a Flutter mobile application can be designed for a fintech/corporate expense management use case with smart recommendations, clean UI, and product-oriented thinking.

## Future Improvements

- Real AI API integration
- Receipt upload and OCR
- Expense analytics charts
- Admin approval actions
- Multi-user team support
- Cloud database integration