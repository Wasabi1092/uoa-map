#!/usr/bin/env ruby
require 'gtk3'

class Screen
    public
    def initialize
        @viewpos_x = 0
        @viewpos_y = 0
        @scale = 1.0
        @window_width = 500
        @map_width = 1443.0
        @map_height = 814.0
        ######################
        load_ui
        load_image
    end

    def run
        @window.show_all
        Gtk.main
    end

    private
    def load_ui
        # create window
        @window = Gtk::Window.new("UoA Map")
        @window.set_default_size(@window_width, 750)
        @window.signal_connect("destroy"){
            Gtk.main_quit
        }

        # create the main box with a DrawingArea for the map at the top
        main_box = Gtk::Box.new(:vertical)
        @window.add(main_box)
        @drawing_area = Gtk::DrawingArea.new
        @drawing_area.set_size_request(@window_width, @window_width)
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

        # setup mouse events for panning the map
        setup_mouse_events
    end

    def load_image
        if File.exist?("campus-map-cropped.png")
            @map_pixbuf = GdkPixbuf::Pixbuf.new(file:"campus-map-cropped.png")
        else
            @map_pixbuf = nil
            print "'campus-map-cropped.png' not found\n"
        end
    end

    def setup_mouse_events
        @drawing_area.add_events([Gdk::EventMask::BUTTON_PRESS_MASK, Gdk::EventMask::BUTTON_RELEASE_MASK, 
        Gdk::EventMask::POINTER_MOTION_MASK])
        @drawing_area.signal_connect("button-press-event") do |widget, event|
            # print "Mouse press at: #{event.x}, #{event.y}\n"
            ########################
        end
        @drawing_area.signal_connect("button-release-event") do |widget, event|
            # print "Mouse release at: #{event.x}, #{event.y}\n"
            ########################
        end
        @drawing_area.signal_connect("motion-notify-event") do |widget, event|
            # print "."
            ########################
        end
    end

    def display_map(cairo)
        if @map_pixbuf != nil
            cairo.save
            cairo.translate(@viewpos_x, @viewpos_y)
            cairo.scale(@scale*@window_width/@map_height, @scale*@window_width/@map_height)
            cairo.set_source_pixbuf(@map_pixbuf, 0, 0)
            cairo.paint
            cairo.restore
        else
            cairo.move_to(200,230)
            cairo.show_text("Map Image Unavailable")
        end
    end

    def zoom_in_clicked
        # increase scale (max 20)
        @scale = @scale * 4/3
        if @scale > 5 
            @scale = 5.0
        end
        # move position so zooming in on the center, then refresh map
        @drawing_area.queue_draw
    end

    def zoom_out_clicked
        # decrease scale (min 1)
        @scale = @scale * 3/4
        if @scale < 1
            @scale = 1.0
        end
        # move position so zooming in on the center, then refresh map
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
