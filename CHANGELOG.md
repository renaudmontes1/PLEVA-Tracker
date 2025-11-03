# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.6] - 2025-11-02

### Added
- Additional papule count tracking regions:
  - Belly
  - Left and Right Feet
- Optimized papule count entry form with dual-column layout for better space utilization
- Automatic scroll to latest data in trend charts for improved user experience

### Changed
- Reorganized papule count section into paired rows (Face-Neck, Chest-Back, etc.)
- Location field hidden from UI while maintaining backwards compatibility
- Improved entry form data loading reliability

### Fixed
- Fixed issue where latest entry would not display data correctly when opened
- Resolved view reuse issues in entry editing sheets

## [1.0.3] - 2025-05-25

### Added
- Additional papule count tracking regions:
  - Face
  - Neck

## [1.0.2] - 2025-03-25

### Fixed
- Improved WeeklyTrendChart x-axis date formatting and scale configuration
- Enhanced chart readability with proper date interval displays

## [1.0.1] - 2025-03-25

### Added
- Detailed papule count tracking for specific body regions:
  - Chest
  - Left and Right Arms
  - Back
  - Buttocks
  - Left and Right Legs
- Total papule count display in entry list
- Numeric input fields with keyboard controls for papule counts

## [1.0.0] - 2025-03-07

### Added
- Initial release of PLEVA Diary
- Weekly calendar view for tracking entries
- Entry creation and editing functionality
- Photo attachment support
- Severity tracking (1-5 scale)
- Weekly summary generation using Azure OpenAI
- Settings page with Azure OpenAI configuration
- Location tracking for affected areas