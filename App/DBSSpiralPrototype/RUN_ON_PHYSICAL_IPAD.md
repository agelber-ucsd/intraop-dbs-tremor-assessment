# Running DBS Spiral Prototype on a Physical iPad

This project is an Xcode iPadOS app. You can download the ZIP directly, but the iPad cannot compile or install the Xcode project by itself. To run it on a physical iPad you need a Mac with Xcode, a USB-C/Lightning cable or wireless device pairing, and an Apple Account signed into Xcode.

## 0) Requirements

- Mac with a current version of Xcode installed.
- iPad running iPadOS 17.0 or later. The project's deployment target is currently set to 17.0.
- Apple Account signed into Xcode.
- Apple Pencil recommended; finger input also works for basic testing.
- USB-C or Lightning cable for first setup. Wireless debugging can be configured later.

A paid Apple Developer Program membership is not required for quick personal on-device testing, but Personal Team/free provisioning has limitations and profiles expire after 7 days, so you may need to rebuild/reinstall periodically. For TestFlight, broader team testing, or hospital/institutional distribution, use a paid Apple Developer Program account.

## 1) Download and unzip

1. Download `DBSSpiralPrototype_with_iPad_Instructions.zip`.
2. Double-click the ZIP on your Mac to unzip it.
3. Open the folder `DBSSpiralPrototype`.
4. Double-click `DBSSpiralPrototype.xcodeproj`.

Do not open only the Swift files. Open the `.xcodeproj` file.

## 2) Add your Apple Account to Xcode

1. In Xcode, choose `Xcode > Settings...` from the Mac menu bar.
2. Click `Accounts`.
3. Click `+` and add your Apple Account.
4. Close Settings after the account appears.

## 3) Set signing

1. In Xcode's left navigator, click the blue project icon: `DBSSpiralPrototype`.
2. Under `Targets`, select `DBSSpiralPrototype`.
3. Open the `Signing & Capabilities` tab.
4. Check `Automatically manage signing`.
5. In `Team`, choose your Personal Team or Apple Developer Program team.
6. Change the Bundle Identifier from:

   `com.example.DBSSpiralPrototype`

   to something unique, for example:

   `com.yourlastname.DBSSpiralPrototype`

The `com.example...` bundle ID often causes signing errors because it is generic and may not be unique enough for your account.

## 4) Connect and trust the iPad

1. Unlock the iPad.
2. Connect it to the Mac by cable.
3. On the iPad, tap `Trust This Computer` if prompted.
4. Enter the iPad passcode if prompted.
5. In Xcode, choose `Window > Devices and Simulators`.
6. Confirm the iPad appears in the left-hand device list.

If Xcode says the device is preparing or downloading symbols, let it finish before running.

## 5) Enable Developer Mode on iPad

For iPadOS 16 and later, Developer Mode is required to run development apps.

1. On the iPad, open `Settings`.
2. Go to `Privacy & Security`.
3. Scroll to `Developer Mode`.
4. Turn `Developer Mode` on.
5. Restart the iPad when prompted.
6. After restart, unlock the iPad and tap `Turn On` when asked to confirm Developer Mode.
7. Enter the iPad passcode if prompted.

If `Developer Mode` is not visible, connect the iPad to Xcode first, open `Window > Devices and Simulators`, and try running/preparing the device once. The setting usually appears after Xcode recognizes the device.

## 6) Select the physical iPad as the run target

1. At the top of Xcode, near the Run ▶ button, open the scheme/device selector.
2. Choose your iPad under `iOS Device`, not an iPad simulator.
3. Make sure the scheme says `DBSSpiralPrototype`.

## 7) Build and run

1. Click the Run ▶ button, or choose `Product > Run`.
2. Xcode will build, sign, install, and launch the app on the iPad.
3. Keep the iPad unlocked during first install.
4. When the app launches, enter a Subject ID and trial label, then draw the spiral.

## 8) Export a trial JSON

1. Complete a spiral trace.
2. Tap the app's export/share button.
3. Save the JSON to Files, AirDrop it, or send it to yourself.
4. Treat exported data as potentially identifiable research data if you enter patient identifiers.

## Common problems and fixes

### Problem: `Signing for DBSSpiralPrototype requires a development team`
Fix: Select the project > target > `Signing & Capabilities` > choose a Team.

### Problem: `Failed to register bundle identifier`
Fix: Change `com.example.DBSSpiralPrototype` to a unique bundle identifier, such as `com.yourlastname.DBSSpiralPrototype`.

### Problem: `Developer Mode disabled`
Fix: On the iPad, go to `Settings > Privacy & Security > Developer Mode`, turn it on, restart, and confirm.

### Problem: iPad does not appear in Xcode
Fix: Unlock the iPad, reconnect cable, tap `Trust This Computer`, try another cable/port, then open `Window > Devices and Simulators`.

### Problem: `iPadOS version is lower than deployment target`
Fix: Update the iPad to iPadOS 17 or later, or in Xcode lower `IPHONEOS_DEPLOYMENT_TARGET` after confirming the app still builds.

### Problem: App worked before but will not open later
Fix: If using a free Personal Team, the provisioning profile may have expired. Reconnect the iPad to Xcode and run the project again.

## Safer testing notes

This is a research/development prototype only. It is not validated, not calibrated, and not intended for clinical care, DBS targeting, lead placement, or intraoperative decision-making. Use de-identified subject IDs during testing.
