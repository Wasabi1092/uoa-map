#!/usr/bin/env ruby
require 'gtk3'

class Screen
    public
    def initialize
        load_ui
        load_image
        # setup screen state
        ##########################
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

        # create the main box at the top with a DrawingArea for the map
        main_box = Gtk::Box.new(:vertical)
        @window.add(main_box)
        @drawing_area = Gtk::DrawingArea.new
        @drawing_area.set_size_request(500, 500)
        main_box.pack_start(@drawing_area, fill:true, padding:10)

        # create the search box at the bottom, with an entry and a button
        search_box = Gtk::Box.new(:horizontal)
        main_box.pack_start(search_box)
        @search_entry = Gtk::Entry.new
        @search_entry.placeholder_text = "Enter Location"
        @search_button = Gtk::Button.new(label:"Search")
        @search_button.signal_connect("clicked") {
            on_search_clicked
        }
        search_box.pack_start(@search_entry, expand:true, fill:true, padding:20)
        search_box.pack_start(@search_button, expand:true, fill:true, padding:20)

        # setup drawing the map in the DrawingArea
        @drawing_area.signal_connect("draw") do |widget, cairo|
            draw_map(cairo)
        end
    end

    def load_image
        if File.exist?("campus-map-cropped.png")
            @map_pixbuf = GdkPixbuf::Pixbuf.new(file:"campus-map-cropped.png")
        else
            @map_pixbuf = nil
            print "'campus-map-cropped.png' not found\n"
        end
    end

    def draw_map(cairo)
        if @map_pixbuf != nil
            cairo.save
            cairo.scale(500.0/814,500.0/814)
            cairo.set_source_pixbuf(@map_pixbuf, 0, 0)
            cairo.paint
            cairo.restore
        else
            cairo.move_to(200,230)
            cairo.show_text("Map Image Unavailable")
        end
    end

    def on_search_clicked
        print "Searching for " + @search_entry.text + "\n"
        ########################
    end
end

Gtk.init
screen = Screen.new
screen.run
