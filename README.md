# PLEVA Tracker

A comprehensive iOS application designed to help patients track and monitor PLEVA (Pityriasis Lichenoides et Varioliformis Acuta) symptoms over time.

## Features

### Symptom Tracking
- Daily diary entries with severity ratings (1-5 scale)
- Detailed papule count tracking for specific body regions:
  - Face
  - Neck
  - Chest
  - Arms (Left/Right)
  - Back
  - Buttocks
  - Legs (Left/Right)
- Location notes for affected areas
- Photo attachments for visual tracking
- Personal notes and observations

### Analysis & Insights
- Weekly calendar view for easy navigation
- Weekly trend charts showing symptom progression
- AI-powered weekly summaries using Azure OpenAI
- Visual severity indicators
- Total papule count tracking

## Initial Checklist

1- Get a Mac, pretty obvious but you can get one for $150 dollars on Ebay :)

2- Install Xcode

3- Install VS Code and ensure it has the coding-with-Agent experience enabled

4- Signup for GitHub Copilot, it’s $10 dollars a month, totally worth it!

5- Create an account in Azure

6- Create an Apple Developer account, you can opt to not pay yet for the annual subscription if you will be testing your app locally and not deploy to App Store.

7- In VS Code, install the Swift extension

8- Create an empty project in Xcode: iOS app, swift, 

9- Open app project in VS Code

10- Start using Agent mode to add functionality

11- Go back to Xcode and in the Signing and Capabilities section, ensure that for the iOS, you choose a Development team, which in this case can be your Apple developer account

12- In your iPhone, search for 'Developer Mode' in Settings and enable it

13- When deploying to iPhone, ensure that the first time you go to Settings, search for VPN and choose VPN & Device Management and in the Developer App, authorize your new app

Notes:
1- Use Claude 3.5, we tried Claude 3.7 and it stopped responding after a while without completing the whole answer when first creating the base app

2- If VS Code can’t successfully edit the plist file for the first time as in Xcode is not visible!
  Go to Project navigator and add a new row with key and value, this is where the Azure Open AI keys need to be stored
  First time you add a new row, then the plist.info file gets created


## Technical Requirements

- iOS 17.0 or later
- iPhone and iPad compatible
- Xcode 15.2 or later
- Swift 5.0
- SwiftData for persistence
- Azure OpenAI API credentials (required for AI summaries)

## Setup

1. Clone the repository
2. Copy `PLEVA-Tracker-Info.template.plist` to `PLEVA-Tracker-Info.plist`
3. Add your Azure OpenAI credentials to `PLEVA-Tracker-Info.plist`:
   - `AZURE_OPENAI_KEY`
   - `AZURE_OPENAI_ENDPOINT`
   - `AZURE_OPENAI_DEPLOYMENT`
4. Open `PLEVA Tracker.xcodeproj` in Xcode
5. Build and run the project

## Configuration

The app requires valid Azure OpenAI credentials for the weekly summary feature. These can be configured in:
- `PLEVA-Tracker-Info.plist`

## Privacy & Security

- All data is stored locally on the device
- Photos are stored securely in the app's sandbox
- No data is transmitted except for anonymous symptom descriptions to Azure OpenAI for summary generation

## License

Free to use and modify

## Version History

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.
