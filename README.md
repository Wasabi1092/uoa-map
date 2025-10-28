# uoa-map

## Dependencies

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
ruby GUI-test.rb
```

## Testing the map generation
```bash
cd lib

ruby uoamap.rb
```
