# uoa-map

## Dependencies

 - Ruby

Gems Required
 - json
 - gtk3
 - cairo
 - cairo-gobject

Prepare the ruby dependencies
``` bash
sudo apt install -y libgtk-3-dev build-essential pkg-config

sudo apt install build-essential pkg-config libglib2.0-dev libgirepository1.0-dev libcairo2-dev libgtk-3-dev libgdk-pixbuf2.0-dev gir1.2-gdk-3.0 gir1.2-gdkpixbuf-2.0
```

Then you can install
```bash
gem install cairo
gem install cairo-gobject
gem install gtk3
gem install json
```

## Testing the map generation
```bash
cd lib

ruby maptest.rb
```

## Running the GUI
```bash
cd lib

ruby uoamap.rb
```

## How to Use

- The program should open to the 'Select Route Start/End' page.
- There is an interactive map displayed at the top of the screen, which you can pan by clicking and dragging, or zoom in/out using the +/- buttons at the bottom of the map.
- To request a route, select the start location and the destination from the combo boxes at the bottom of the screen and click the 'Request Route' button.
- The map will automatically move and adjust the zoom level so that the route is centred and fully in view. The route preview will be displayed as a pink line on the map, with larger dots at the start and end. Distance and time estimates will be at the bottom of the screen.
- To open the Settings page, click the Settings (⚙) button in the top right of the map.
- Click the 'Avoid stairs' switch to toggle it on, then click 'Return to Map' at the bottom of the page.
- Select the route start/end, then request a route. The route generator will now avoid stairs when finding the route. 

(We did not have time to thoroughly map out the uni pathways, so the route generator may fail to find a stairs-free route. A simple route that clearly shows a difference between the path with and without stairs is from 'Hub' to 'Bonython Hall'). 

## Known bugs/limitations

- Combo boxes for route start/end do not allow you to scroll for some reason, so it is cumbersome to select locations further down in the list. (but still possible by repeatedly selecting the location at the bottom of the list).
- Distance estimates are roughly correct (checked by comparing with apple maps estimates), however we do not know the actual pixel to distance scale of the map image, so it is not exact.

## Implemented Requirements

- Interactive Map Interface with Google Maps-style functionality (from original SEW1 Report)
- ID 06: Steps Free Navigation Option
- ID 07: Route Preview
- ID 08: Route Cancellation
- ID 10: Building Entrances Display
- ID 14: Estimated Travel Time
- ID 17: Offline Map
