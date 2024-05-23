# Tungsten Moon Tech Demo 2
 
## Overview
Tungsten Moon is a "flight simulator" for spacecraft. The setting is a fictional 600 km diameter moon of solid tungsten metal, orbiting a planet that is orbiting an imaginary sun. Eventually, the game will have objectives, challenges, or a survival aspect, but for now, it is simply a technology demonstrator to prove that the mechanics I have in mind will run acceptably well on reasonable hardware.

The spacecraft controls allow you to control the main rocket thrust, while providing pitch, roll, and yaw torques. The fuel is limited, but there is enough to put the spacecraft into orbit around the moon.

Tungsten Moon will run in VR mode if a VR headset is detected. You can use full keyboard or game controller inputs in either mode. VR hand controllers support grabbing handles and pushing buttons (Vive tested).

## Current Features
* The custom sky shader includes a rotating field of 10,000 random stars, a sun, and a planet. All of these are in motion, relative to each other, at speeds and scales that are physically reasonable. This means that although they *appear* to be stationary, they are actually in full motion.
* Star field brightness is automatically adjusted between barely visible and brilliant, depending on whether the sun or planet are visible in the sky.
* The motion simulation accounts for the tungsten moon itself spinning on its axis. The current rotation period is ten hours. This should give rise to Coriolis effects if you know where to look, although this has not been carefully verified yet.
* The input scheme supports not only keyboard and mouse, but also the Xbox, Playstation and Steam Deck controllers. All control keys have been assigned to make the experience of moving between keyboard and controller more intuitive. There is no user re-configuration possible yet.
* The executable file currently works with the Valve Steam Deck, using the latest Proton emulation layer. The performance is excellent.
* There are several starting locations on the moon that you can choose from, with a very primitive UI. 
* A "radar altimeter" mode activates below 2000 meters altitude and will read correctly down to the surface of the planet.
* Velocity is reported as ground-relative horizontal and vertical components.
* An attitude "nav ball" helps to orient the pilot.
* A horizontal drift indicator shows the cockpit-relative forward/backwards and left/right motion of the ship. This is derived from doppler radar data and will only operate below the 2000 meter radar altitude limit, and when the ship is within 45 degrees of horizontal. Three speed ranges, 1x, 10x, and 100x are selectable with buttons on the display.
* To help with achieving orbit, apoapsis and periapsis altitudes are reported ("ORBITAL APSIDES" AA and PA, respectively) for the current spacecraft altitude and velocity vector.

## Controls
Some inputs perform an alternate function. Pressing the right shoulder button on the controller or the SHIFT key on the keyboard toggles the ALTERNATE control mode. There is also an in-cockpit UI button that you can activate with a mouse or VR controller.
### Interior View
* D-Pad (controller) or WASD (keyboard) control the view direction inside the cockpit. By toggling the ALTERNATE control, you can use these inputs to move your viewpoint forward/backward and left/right.
* If you are using a mouse, hold the RMB (right mouse button) and move the mouse to pan your view. Note: the Steam Deck can be configured wi
### Flight Controls
* The right stick (controller) or direction keys (keyboard) control pitch and roll thrusters. 
* The right left/right (controller) or left/right keys (keyboard) activate the yaw (rotate left/right) thrusters in ALTERNATE mode.
* Keyboards that have a numeric keypad also work in the Orbiter style: pitch control with 8/2, roll with 4/6, and yaw with 1/3.
### Main Thrust Control
* The thrust control starts in "soft lock" mode. While locked, thrust can be increased or decreased with the left stick up/down (controller) or the Ctrl + PG-UP or Ctrl + PG-DN keys on a keyboard (or Ctrl + + or Ctrl + - on keypad)
* The in-cockpit THROTTLE handle works with a mouse or VR hand controller.
* On a game controller, thrust soft lock is toggled using the left shoulder button. The left trigger is used to manually control the thrust from zero to maximum. Once you have a thrust level you like, press the lock button again to hold that thrust.  
* On a keyboard, PG-UP and PG-DN (keypad + or -) immediately set and hold full or zero thrust, respectively. You can then tweak the levels using the Ctrl + PG-UP and PG-DN keys.
* The effect of your throttle input is displayed on the IMU accelerometer. The nominal gravitational acceleration on the surface of the moon is 1.6 m/s/s. If you hold the ship acceleration at 1.6 during flight, then you  will be assured of maintaining a constant velocity, relative to the surface (which could include *no* velocity). When the ship is flown at an angle, it will accelerate sideways under thrust, and slightly *more* than 1.6 m/s/s acceleration is required to maintain altitude.
### Other Controls
* Menu button or Q or ESC key will quit the program.
* X button or X key will toggle attitude rate mode (ON by default). 
* There is an in-cockpit landing light toggle switch. There is no controller button or keyboard key mapped to this switch.
* There is an in-cockpit button for refilling the propellant tank. There is no controller button or key for this.
* B controller button or R key or LEFT VR controller B/Y button will restart at your current scenario location.
* Left stick PUSH (controller) or V key or LEFT VR controller A/X button will reset your view position.
* There is an in-cockpit button to reset the attitude indicator. When the ship is stationary on the ground, the internal gyroscope and accelerometers can determine the rotation axis of the moon, and the ship's orientation with respect to the horizon; pressing reset will initialize the indicator to show true heading (0 degrees N, 90 degrees E, etc.) and tilt. When the ship is aloft, and **not** rotating, then the reset button will force the indicator to show heading of zero degrees and level horizon, regardless of the ship's actual position. This is because there are no external references (i.e. gps satellites or ground beacons) that can determine true orientation or position. Future versions of the game will probably incorporate additional navigational aids and attitude indicator modes.
* The horizontal drift indicator has three ranges (1x, 10x, and 100x) selectable with "radio buttons".
* Keyboard [ or ] keys or RIGHT VR controller B/Y button will select one of five different starting locations above the surface of the moon. Your selected location will be saved and will also become the startup location the next time you run the program. The locations are: +161 degrees longitude, 89.9 degrees latitude, 0 degrees heading
-134 degrees longitude, +31 degrees latitude, 90 degrees heading
+46 degrees longitude, -10 degrees latitude, 0 degrees heading
1 degrees longitude, +85 degrees latitude, 180 degrees heading
-80 degrees longitude, -85 degrees latitude, 0 degrees heading
These starting positions provide various combinations of sun and/or planet shine, or complete darkness. 

## How to Get Started
* Run the program.
* Allow the spacecraft to settle onto the surface, or immediately press PG-UP to begin accelerating away from the surface.
* Once off the ground, press SHIFT (ALTERNATE control mode toggle), then hold left-arrow or right-arrow to start rotating your craft. This will enable you to view the planet and/or sun in the sky (if present).
* Press SHIFT (toggle back out of ALTERNATE control mode)l, then use the right stick (controller) or the arrow keys to pitch/roll into a sideways attitude so you can accelerate horizontally. If you can bring your horizontal speed up to 700 m/s you will enter orbit. Try to adjust A ALT. and P ALT. values to be between 3 and 10 km. Watch the moon roll by.. 
* Try lifting off, then landing softly back on the surface.
* Try lifting off, then moving horizontally a few hundred meters, then landing softly on the surface with has little horizontal motion as possible.

## Known Bugs
* The landing logic occcasionally glitches when landing on the seam between scenery meshes (you fall through the ground). Just press R to start over.

## Road Map
* UI for save/load and different scenarios
* UI for graphics settings
* Add landing pads at various locations.
* Objectives, challenges, achievements.
* Limited resources, requiring resource gathering (survival mode).
* A story.
