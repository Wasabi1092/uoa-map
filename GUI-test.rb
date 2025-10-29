#!/usr/bin/env ruby
require 'gtk3'

class Screen
    public
    def initialize
        @viewpos_x = 0
        @viewpos_y = 0
        @zoom_scale = 0.615
        @drawing_size = 500
        @map_width = 1443.0
        @map_height = 814.0
        @panning = false
        @avoid_steps = false
        @screen_state
        load_main_ui
        load_set_route_ui
        load_preferences_ui
        load_image
        setup_mouse_events
    end

    def run
        @window.show_all
        set_route_state # default state is set route
        Gtk.main
    end

    private
    def load_main_ui
        # create window
        @window = Gtk::Window.new("UoA Map")
        @window.set_default_size(500, 800)
        @window.set_resizable(false)
        @window.signal_connect("destroy"){
            Gtk.main_quit
        }
        @window_box = Gtk::Box.new(:vertical)
        @window.add(@window_box)
        
        # create the main box with a DrawingArea for the map at the top
        @main_box = Gtk::Box.new(:vertical)
        @window_box.pack_start(@main_box)
        @drawing_area = Gtk::DrawingArea.new
        @drawing_area.set_size_request(@drawing_size, @drawing_size)
        @main_box.pack_start(@drawing_area, fill:true, padding:10)

        # create a map controls box with buttons to zoom in/out
        controls_box = Gtk::Box.new(:horizontal)
        @main_box.pack_start(controls_box, fill:true)
        preferences_button = Gtk::Button.new(label:"Preferences")
        preferences_button.signal_connect("clicked") {
            preferences_state
        }
        zoom_in_button = Gtk::Button.new(label:"+")
        zoom_in_button.signal_connect("clicked") {
            zoom_in_clicked
        }
        zoom_out_button = Gtk::Button.new(label:"-")
        zoom_out_button.signal_connect("clicked") {
            zoom_out_clicked
        }
        set_route_button = Gtk::Button.new(label:"Set Route")
        set_route_button.signal_connect("clicked") {
            set_route_state
        }
        controls_box.pack_start(preferences_button, expand:true, fill:true, padding:20)
        controls_box.pack_start(zoom_in_button, expand:true, padding:10)
        controls_box.pack_start(zoom_out_button, expand:true, padding:10)
        controls_box.pack_start(set_route_button, expand:true, fill:true, padding:20)

        # setup drawing the map in the DrawingArea
        @drawing_area.signal_connect("draw") do |widget, cairo|
            display_map(cairo)
        end
    end

    def load_set_route_ui
        # create the set route box, with combo boxes for location and destination, and a button to request route
        @set_route_box = Gtk::Box.new(:vertical)
        @main_box.pack_start(@set_route_box, fill:true, padding:10)
        # title 'Set Route'
        set_route_label = Gtk::Label.new
        set_route_label.set_markup("<span weight='bold' size='15000'>Set Route</span>")
        @set_route_box.pack_start(set_route_label, expand:true, fill:true, padding:10)
        # location label and combo box
        @location_box = Gtk::Box.new(:horizontal)
        @set_route_box.pack_start(@location_box, fill:true, padding:10)
        location_label = Gtk::Label.new("Location:")
        @location_box.pack_start(location_label, expand:true, fill:true, padding:10)
        location_combo = Gtk::ComboBoxText.new
        @location_box.pack_start(location_combo, expand:true, fill:true, padding: 10)
        location_combo.append_text("[Choose location]")
        location_combo.append_text("Location 1") ###########
        location_combo.append_text("Location 2")
        location_combo.set_active(0)
        # destination label and combo box
        @destination_box = Gtk::Box.new(:horizontal)
        @set_route_box.pack_start(@destination_box, fill:true, padding:10)
        destination_label = Gtk::Label.new("Destination:")
        @destination_box.pack_start(destination_label, expand:true, fill:true, padding:10)
        destination_combo = Gtk::ComboBoxText.new
        @destination_box.pack_start(destination_combo, expand:true, fill:true, padding: 10)
        destination_combo.append_text("[Choose destination]")
        destination_combo.append_text("Destination 1") ###########
        destination_combo.append_text("Destination 2")
        destination_combo.set_active(0)
        # request route button
        req_route_box = Gtk::Box.new(:horizontal)
        @set_route_box.pack_start(req_route_box, fill:true, padding:20)
        req_route_button = Gtk::Button.new(label:"Request Route")
        req_route_button.signal_connect("clicked") {
            if location_combo.active != 0 && destination_combo.active != 0
                request_route(location_combo.active_text, destination_combo.active_text)
            end
        }
        req_route_box.pack_start(req_route_button, expand:true)
    end

    def load_preferences_ui
        # create the preferences box, with the title 'Preferences'
        @preferences_box = Gtk::Box.new(:vertical)
        preferences_label = Gtk::Label.new
        preferences_label.set_markup("<span weight='bold' size='15000'>Preferences</span>")
        @preferences_box.pack_start(preferences_label, expand:true, fill:true, padding:20)
        # create another box in preferences, with a label and switch for the 'avoid steps' toggle, and a done button
        avoid_steps_box = Gtk::Box.new(:horizontal)
        @preferences_box.pack_start(avoid_steps_box, fill:true, padding:10)
        avoid_steps_label = Gtk::Label.new("Avoid Steps:")
        avoid_steps_switch = Gtk::Switch.new
        avoid_steps_switch.signal_connect('state-set') do |widget, state|
            @avoid_steps = state
            false # to allow default behaviour (colour change when switched)
        end
        avoid_steps_box.pack_start(avoid_steps_label, fill:true, padding:10)
        avoid_steps_box.pack_start(avoid_steps_switch, fill:true, padding:10)
        # create a 'return to map' button at the bottom of the preferences box
        return_box = Gtk::Box.new(:horizontal)
        return_box.set_margin_top(625)
        @preferences_box.pack_start(return_box, fill:true)
        return_button = Gtk::Button.new(label:"Return to Map")
        return_button.signal_connect("clicked") {
            set_route_state
        }
        return_box.pack_start(return_button, expand:true)
    end

    def load_image
        # if the map image exists, load it into a pixbuf
        if File.exist?("campus-map-cropped.png")
            @map_pixbuf = GdkPixbuf::Pixbuf.new(file:"campus-map-cropped.png")
        else
            @map_pixbuf = nil
            print "'campus-map-cropped.png' not found\n"
        end
    end

    def display_map(cairo)
        if @map_pixbuf != nil
            # translate and zoom according to view position and zoom scale, then display map image
            cairo.save
            cairo.translate(@viewpos_x, @viewpos_y)
            cairo.scale(@zoom_scale, @zoom_scale)
            cairo.set_source_pixbuf(@map_pixbuf, 0, 0)
            cairo.paint
            cairo.restore
        else
            cairo.move_to(200,230)
            cairo.show_text("Map Image Unavailable")
        end
    end

    def setup_mouse_events
        # setup mouse events for panning the map
        @drawing_area.add_events([Gdk::EventMask::BUTTON_PRESS_MASK, Gdk::EventMask::BUTTON_RELEASE_MASK, 
        Gdk::EventMask::POINTER_MOTION_MASK])
        @drawing_area.signal_connect("button-press-event") do |widget, event|
            @panning = true
            @prev_mouse_x = event.x
            @prev_mouse_y = event.y
        end
        @drawing_area.signal_connect("button-release-event") do |widget, event|
            @panning = false
        end
        @drawing_area.signal_connect("motion-notify-event") do |widget, event|
            if @panning
                # update view position with mouse movement
                diff_x = event.x - @prev_mouse_x
                diff_y = event.y - @prev_mouse_y
                @prev_mouse_x = event.x
                @prev_mouse_y = event.y
                # update view position
                change_viewpos(diff_x, diff_y)
                @drawing_area.queue_draw
            end
        end
    end

    def change_viewpos(diff_x, diff_y)
        @viewpos_x += diff_x
        @viewpos_y += diff_y
        # keep the view within the map's edges
        if @viewpos_x > 0
            @viewpos_x = 0
        end
        if @viewpos_x < -1*@zoom_scale*@map_width + @drawing_size
            @viewpos_x = -1*@zoom_scale*@map_width + @drawing_size
        end
        if @viewpos_y > 0
            @viewpos_y = 0
        end
        if @viewpos_y < -1*@zoom_scale*@map_height + @drawing_size
            @viewpos_y = -1*@zoom_scale*@map_height + @drawing_size
        end
    end

    def zoom_in_clicked
        # convert center of view pos to map pos
        map_pos_x = (@drawing_size / 2.0 - @viewpos_x) / @zoom_scale
        map_pos_y = (@drawing_size / 2.0 - @viewpos_y) / @zoom_scale
        # increase scale (max 2)
        @zoom_scale = @zoom_scale * 4/3
        if @zoom_scale > 2
            @zoom_scale = 2.0
        end
        # convert map pos back to center of view pos
        @viewpos_x = @drawing_size / 2.0 - map_pos_x*@zoom_scale
        @viewpos_y = @drawing_size / 2.0 - map_pos_y*@zoom_scale
        @drawing_area.queue_draw
    end

    def zoom_out_clicked
        # convert center of view pos to map pos
        map_pos_x = (@drawing_size / 2.0 - @viewpos_x) / @zoom_scale
        map_pos_y = (@drawing_size / 2.0 - @viewpos_y) / @zoom_scale
        # decrease scale (min 0.615)
        @zoom_scale = @zoom_scale * 3/4
        if @zoom_scale < 0.615
            @zoom_scale = 0.615
        end
        # convert map pos back to center of view pos
        @viewpos_x = @drawing_size / 2.0 - map_pos_x*@zoom_scale
        @viewpos_y = @drawing_size / 2.0 - map_pos_y*@zoom_scale
        change_viewpos(0, 0) # make sure it doesn't zoom out past the edge of the map
        @drawing_area.queue_draw
    end

    def preferences_state
        @screen_state = "Preferences"
        if @window_box.children.include?(@main_box)
            @window_box.remove(@main_box)
        end
        @window_box.pack_start(@preferences_box)
        @window.show_all
    end

    def set_route_state
        @screen_state = "Set Route"
        if @window_box.children.include?(@preferences_box)
            @window_box.remove(@preferences_box)
        end
        if !@window_box.children.include?(@main_box)
            @window_box.pack_start(@main_box)
        end
        if !@main_box.children.include?(@set_route_box)
            @window_box.pack_start(@set_route_box)
        end
        @window.show_all
    end

    def request_route(location, destination)
        print "Requesting route from #{location} to #{destination}\n"
        ######################
    end
end

Gtk.init
screen = Screen.new
screen.run
