# Le Petit Chaperon Rouge

Le Petit Chaperon Rouge is a story-driven 3D survival game created with Godot. The player explores a forest, avoids wolves, collects six memory fragments, and uncovers the hidden road.

## Project information

- Engine: Godot Engine 4.7
- Project type: Godot 3D mobile/desktop game
- Main project file: `project.godot`
- Start scene: `ui/app_launcher.tscn`
- Main game scene: `main.tscn`
- Primary target: iOS
- Desktop test platforms: macOS, Windows, or Linux supported by Godot 4.7

## Requirements

To open, compile, and run the project:

1. Install Godot Engine 4.7 from <https://godotengine.org/download/>.
2. Extract the submitted source-code archive to a local folder.
3. Make sure the extracted folder contains `project.godot`, `main.tscn`, and the `assets`, `systems`, `ui`, and `world` folders.

No third-party Godot plugins or external package managers are required. Godot imports the included source assets automatically when the project is opened for the first time.

## Compile and run in the Godot editor

1. Start Godot Engine 4.7.
2. Select **Import**.
3. Browse to the extracted source folder and select `project.godot`.
4. Select **Import & Edit**.
5. Wait until Godot finishes importing all assets. The first import can take several minutes because the project includes 3D models, textures, audio, and fonts.
6. Press **F6** only when testing an individual open scene, or press **F5 / Run Project** to compile and execute the complete application.
7. If Godot asks which scene to run, select `ui/app_launcher.tscn`. It is already configured as the main scene in `project.godot`.

Godot compiles the GDScript files automatically when the project or a scene is run. A separate command-line compiler is not required.

## Desktop controls

- `W`, `A`, `S`, `D`: move
- Mouse movement: look around
- `Space`: jump
- `I`: open or close the memory inventory
- `Esc`: pause or return from a menu

## Mobile controls

- Touch and drag on the left side: move with the virtual joystick
- Drag on the right side: look around
- Tap on the right side: jump
- Use the on-screen BAG and pause buttons for the inventory and pause menu

## Export an executable build

Godot export templates for version 4.7 must be installed before exporting:

1. In Godot, open **Editor > Manage Export Templates**.
2. Download and install the templates for Godot 4.7.
3. Open **Project > Export**.
4. Choose an existing preset or add a preset for the required platform.
5. Select **Export Project** and choose the output location.

For a desktop submission, add a macOS, Windows Desktop, or Linux preset and export the project for that operating system.

## Build and run on iOS

iOS export requires a Mac with Xcode and an Apple ID:

1. Install Xcode and sign in with an Apple ID in **Xcode > Settings > Accounts**.
2. Connect and trust an iPhone, then enable Developer Mode on the device if requested.
3. Install the Godot 4.7 iOS export template.
4. In Godot, open **Project > Export > iOS**.
5. Replace the App Store Team ID and bundle identifier with values belonging to the developer who is building the application.
6. Export the iOS project.
7. Open the generated `.xcodeproj` file in Xcode.
8. Select the application target, open **Signing & Capabilities**, choose the correct Team, and enable **Automatically manage signing**.
9. Select the connected iPhone as the run destination.
10. Press the Xcode **Run** button to compile, install, and execute the application on the phone.

The included `export_presets.cfg` contains the iOS preset used during development. Signing credentials and provisioning profiles are specific to each Apple developer account and are not included in the source package.

## Important folders

- `assets/`: 3D models, textures, character assets, and fonts
- `audio/`: background music and sound effects
- `boss/`: boss scene and behavior
- `collectibles/`: memory fragments and medicine pickups
- `enemies/`: wolf scenes and behavior
- `systems/`: save data, game state, and audio systems
- `ui/`: title screen, menus, status display, inventory, and mobile controls
- `world/`: world interactions, boundaries, obstacles, and hidden-road logic

## Troubleshooting

- If resources appear missing, wait for the initial Godot import to finish and restart the editor.
- If the project opens in a different Godot version, install and use Godot 4.7 to avoid scene or resource conversion issues.
- If iOS signing fails, confirm that the connected phone is registered to the selected Apple development team and that Xcode can create a provisioning profile.
- Generated folders such as `.godot/` and `build/` are intentionally excluded from the source archive. Godot and Xcode recreate them when importing or exporting the project.
