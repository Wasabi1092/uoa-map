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

## Running the GUI
```bash
cd lib

ruby uoamap.rb
```

## Testing the map generation
```bash
cd lib

ruby maptest.rb
```

## Known bugs/limitations

- combo boxes for route start/end do not allow you to scroll for some reason, so it is cumbersome to select locations further down in the list. (but still possible by repeatedly selecting the location at the bottom of the list).
- distance estimates are roughly correct (checked by comparing with apple maps estimates), however we do not know the actual pixel to distance scale of the map image, so so it is not exact.

## Implemented Requirements

- Interactive Map Interface with Google Maps-style functionality (from original SEW1 Report)
- ID 06: Steps Free Navigation Option
- ID 07: Route Preview
- ID 08: Route Cancellation
- ID 10: Building Entrances Display
- ID 14: Estimated Travel Time
- ID 17: Offline Map
