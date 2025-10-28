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
        ######################
        load_ui
        load_image
        setup_mouse_events
    end

    def run
        @window.show_all
        Gtk.main
    end

    private
    def load_ui
        # create window
        @window = Gtk::Window.new("UoA Map")
        @window.set_default_size(500, 750)
        @window.signal_connect("destroy"){
            Gtk.main_quit
        }

        # create the main box with a DrawingArea for the map at the top
        main_box = Gtk::Box.new(:vertical)
        @window.add(main_box)
        @drawing_area = Gtk::DrawingArea.new
        @drawing_area.set_size_request(@drawing_size, @drawing_size)
        main_box.pack_start(@drawing_area, fill:true, padding:10)

        # create a map controls box with buttons to zoom in/out
        controls_box = Gtk::Box.new(:horizontal)
        main_box.pack_start(controls_box, fill:true, padding:10)
        @zoom_in_button = Gtk::Button.new(label:"+")
        @zoom_in_button.signal_connect("clicked") {
            zoom_in_clicked
        }
        @zoom_out_button = Gtk::Button.new(label:"-")
        @zoom_out_button.signal_connect("clicked") {
            zoom_out_clicked
        }
        controls_box.pack_start(@zoom_in_button, expand:true, fill:true, padding:20)
        controls_box.pack_start(@zoom_out_button, expand:true, fill:true, padding:20)

        # create the search box at the bottom, with an entry and a button
        search_box = Gtk::Box.new(:horizontal)
        main_box.pack_start(search_box, fill:true, padding:10)
        @search_entry = Gtk::Entry.new
        @search_entry.placeholder_text = "Enter Location"
        @search_button = Gtk::Button.new(label:"Search")
        @search_button.signal_connect("clicked") {
            search_clicked
        }
        search_box.pack_start(@search_entry, expand:true, fill:true, padding:20)
        search_box.pack_start(@search_button, expand:true, fill:true, padding:20)

        # setup drawing the map in the DrawingArea
        @drawing_area.signal_connect("draw") do |widget, cairo|
            display_map(cairo)
        end
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

    def search_clicked
        print "Searching for " + @search_entry.text + "\n"
        ########################
    end
end

Gtk.init
screen = Screen.new
screen.run
