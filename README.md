# Tiempo

Tiempo is a macOS time-tracking app. Track work against projects and tasks, get break reminders across your workday, and show or hide the window from the menu bar.

## Requirements

- A Mac running macOS 15 or later
- [Xcode](https://developer.apple.com/xcode/) installed (from the Mac App Store or Apple Developer)

## Build and install

These steps create a Release build and install it in Applications so you can launch Tiempo like any other Mac app.

1. Quit Tiempo if it is already running (the menu bar timer counts as running):

   ```bash
   osascript -e 'quit app "Tiempo"'
   ```

2. From the project root, archive the app:

   ```bash
   cd /path/to/tiempo
   xcodebuild -project Tiempo.xcodeproj -scheme Tiempo -archivePath build/Tiempo.xcarchive archive
   ```

3. Replace the installed copy and open it:

   ```bash
   rm -rf /Applications/Tiempo.app
   ditto build/Tiempo.xcarchive/Products/Applications/Tiempo.app /Applications/Tiempo.app
   open -a /Applications/Tiempo.app
   ```

After that, launch Tiempo from Applications, Spotlight, or Launchpad. The timer icon in the menu bar shows or hides the window.

### Install from Xcode

You can also archive from Xcode:

1. Open `Tiempo.xcodeproj` in Xcode.
2. Choose **Product → Archive**.
3. When the Organizer opens, select the archive and use **Distribute App** (or locate `Tiempo.app` inside the archive) and copy it to `/Applications`.

## Develop in Xcode

Open `Tiempo.xcodeproj` and press **Run**. That launches a Debug build for development. It does not update the copy in Applications. Use the archive steps above whenever you want a new installed Release build.

## Notes

- The installed app is signed for local use on your Mac. It is not notarized for sharing with other people.
- Your projects and tasks are stored under `~/Library/Application Support/com.tiempo.app/`.
- Quit Tiempo before replacing `/Applications/Tiempo.app` so the old process is not left running.
