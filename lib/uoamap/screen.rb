require 'gtk3'

# A class for the GUI and the user's interactions with the program
class Screen
    public
    def initialize(keywords, key_locations, map, generator)
        # logic related variables
        @keywords = keywords
        @key_locations = key_locations
        @map = map
        @generator = generator
        @avoid_steps = false
        @location
        @destination
        @current_event = nil
        @current_route = nil
        # map related variables
        @viewpos_x = 0
        @viewpos_y = 0
        @min_zoom = 0.318
        @max_zoom = 2.0
        @zoom_scale = 0.318
        @drawing_size = 450
        @map_width = 2037.0 # cropped map: 1443
        @map_height = 1418.0 # cropped map: 814
        @panning = false
        # UI setup
        load_ui_styling
        load_main_ui
        load_set_route_ui
        load_preview_ui
        load_settings_ui
        load_image
        setup_mouse_events
    end

    def run
        @window.show_all
        set_route_state # default state is set route
        Gtk.main
    end

    private
    def load_ui_styling
        css_provider = Gtk::CssProvider.new
        css_provider.load_from_path("gui-resources/style.css")
        Gtk::StyleContext.add_provider_for_screen(Gdk::Screen.default, css_provider, Gtk::StyleProvider::PRIORITY_APPLICATION)
    end

    def load_main_ui
        # create window
        @window = Gtk::Window.new
        @window.set_default_size(450, 800)
        @window.set_resizable(false)
        @window.signal_connect("destroy"){ Gtk.main_quit }
        header_bar = Gtk::HeaderBar.new
        header_bar.set_show_close_button(true)
        header_bar.title = "UoA Map"
        header_bar.style_context.add_class("header-bar")
        @window.set_titlebar(header_bar)

        # create the main boxes
        @window_box = Gtk::Box.new(:vertical)
        @window.add(@window_box)
        @main_box = Gtk::Box.new(:vertical)
        @window_box.pack_start(@main_box)

        # create a DrawingArea for the map
        @drawing_area = Gtk::DrawingArea.new
        @drawing_area.set_size_request(@drawing_size, @drawing_size)
        @main_box.pack_start(@drawing_area, fill:true)
        separator = Gtk::Separator.new(:horizontal)
        @main_box.pack_start(separator, fill:true)

        # create a map controls box with buttons to zoom in/out
        controls_vbox = Gtk::Box.new(:vertical)
        controls_vbox.style_context.add_class("slategray-background")
        @main_box.pack_start(controls_vbox, fill:true)
        controls_hbox = Gtk::Box.new(:horizontal)
        controls_vbox.pack_start(controls_hbox, fill:true, padding:10)
        settings_button = Gtk::Button.new(label:"Settings")
        settings_button.signal_connect("clicked") { settings_state }
        zoom_in_button = Gtk::Button.new(label:"+")
        zoom_in_button.signal_connect("clicked") { zoom_in_clicked }
        zoom_out_button = Gtk::Button.new(label:"–")
        zoom_out_button.signal_connect("clicked") { zoom_out_clicked }
        set_route_button = Gtk::Button.new(label:"Set Route")
        set_route_button.signal_connect("clicked") { set_route_state }
        controls_hbox.pack_start(settings_button, expand:true, fill:true, padding:10)
        controls_hbox.pack_start(zoom_in_button, expand:true, padding:5)
        controls_hbox.pack_start(zoom_out_button, expand:true, padding:5)
        controls_hbox.pack_start(set_route_button, expand:true, fill:true, padding:10)
        controls_separator = Gtk::Separator.new(:horizontal)
        @main_box.pack_start(controls_separator)

        # setup map display in the DrawingArea
        @drawing_area.signal_connect("draw") do |widget, cairo|
            display_map(cairo)
            if @current_event && @current_route
                display_route(cairo)
            end
        end
    end

    def load_set_route_ui
        # create the set route box
        @set_route_box = Gtk::Box.new(:vertical)
        @main_box.pack_start(@set_route_box, fill:true, padding:10)
        # title 'Set Route'
        set_route_label = Gtk::Label.new("Select Route Start/End")
        set_route_label.style_context.add_class("title-text")
        @set_route_box.pack_start(set_route_label, expand:true, fill:true, padding:20)
        # location label and combo box
        @location_box = Gtk::Box.new(:horizontal)
        @location_box.set_halign(:center)
        @set_route_box.pack_start(@location_box, fill:true, padding:10)
        location_label = Gtk::Label.new("     Location:")
        location_label.style_context.add_class("bold")
        @location_box.pack_start(location_label, expand:true, padding:10)
        location_combo = Gtk::ComboBoxText.new
        @location_box.pack_start(location_combo, expand:true, fill:true, padding: 10)
        location_combo.append_text("[Choose location]     ")
        location_combo.set_active(0)
        # destination label and combo box
        @destination_box = Gtk::Box.new(:horizontal)
        @destination_box.set_halign(:center)
        @set_route_box.pack_start(@destination_box, padding:10)
        destination_label = Gtk::Label.new("Destination:")
        destination_label.style_context.add_class("bold")
        @destination_box.pack_start(destination_label, expand:true, padding:10)
        destination_combo = Gtk::ComboBoxText.new
        @destination_box.pack_start(destination_combo, expand:true, fill:true, padding: 10)
        destination_combo.append_text("[Choose destination]")
        destination_combo.set_active(0)
        # fill combo boxes with the location keywords
        @keywords.keys.sort.each do |key|
            location_combo.append_text(key)
            destination_combo.append_text(key)
        end
        # request route button
        req_route_box = Gtk::Box.new(:horizontal)
        @set_route_box.pack_start(req_route_box, fill:true, padding:30)
        req_route_button = Gtk::Button.new(label:"Request Route")
        req_route_button.signal_connect("clicked") {
            if (location_combo.active != 0) && (destination_combo.active != 0) && (location_combo.active != destination_combo.active)
                @location = location_combo.active_text
                @destination = destination_combo.active_text
                request_route
                if @current_event && @current_route
                    preview_state
                    zoom_to_route
                end
            end
        }
        req_route_box.pack_start(req_route_button, expand:true)
    end

    def load_preview_ui
        # create the preview box
        @preview_box = Gtk::Box.new(:vertical)
        @main_box.pack_start(@preview_box, fill:true, padding:10)
        # title 'Route Preview'
        preview_label = Gtk::Label.new("Route Preview")
        preview_label.style_context.add_class("title-text")
        @preview_box.pack_start(preview_label, expand:true, fill:true, padding:20)
        # start, end and distance labels
        @start_label = Gtk::Label.new
        @start_label.style_context.add_class("bold")
        @preview_box.pack_start(@start_label, expand:true, fill:true, padding:5)
        @end_label = Gtk::Label.new
        @end_label.style_context.add_class("bold")
        @preview_box.pack_start(@end_label, expand:true, fill:true, padding:5)
        @distance_label = Gtk::Label.new
        @distance_label.style_context.add_class("bold")
        @preview_box.pack_start(@distance_label, expand:true, fill:true, padding:5)
        # cancel button
        cancel_box = Gtk::Box.new(:horizontal)
        @preview_box.pack_start(cancel_box, fill:true, padding:15)
        cancel_button = Gtk::Button.new(label:"Cancel")
        cancel_button.signal_connect("clicked") {
            set_route_state
        }
        cancel_box.pack_start(cancel_button, expand:true)
    end

    def load_settings_ui
        # create the settings box, with the title 'Settings'
        @settings_box = Gtk::Box.new(:vertical)
        settings_label = Gtk::Label.new("Settings")
        settings_label.style_context.add_class("title-text")
        @settings_box.pack_start(settings_label, expand:true, fill:true, padding:30)
        # create another box in settings, with a label and switch for the 'avoid steps' toggle, and a done button
        avoid_steps_box = Gtk::Box.new(:horizontal)
        avoid_steps_box.set_halign(:center)
        @settings_box.pack_start(avoid_steps_box, expand:true, fill:true, padding:10)
        avoid_steps_label = Gtk::Label.new("Avoid Steps")
        avoid_steps_label.style_context.add_class("bold")
        avoid_steps_switch = Gtk::Switch.new
        avoid_steps_switch.signal_connect('state-set') do |widget, state|
            @avoid_steps = state
            false # to allow default behaviour (colour change when switched)
        end
        avoid_steps_box.pack_start(avoid_steps_label, padding:20)
        avoid_steps_box.pack_start(avoid_steps_switch, padding:20)
        # create a 'return to map' button at the bottom of the settings box
        return_box = Gtk::Box.new(:horizontal)
        return_box.set_margin_top(580)
        @settings_box.pack_start(return_box, fill:true)
        return_button = Gtk::Button.new(label:"Return to Map")
        return_button.signal_connect("clicked") { set_route_state }
        return_box.pack_start(return_button, expand:true)
    end

    def load_image
        # if the map image exists, load it into a pixbuf
        if File.exist?("./maps/nt-map/map.png")
            @map_pixbuf = GdkPixbuf::Pixbuf.new(file:"./maps/nt-map/map.png")
        else
            @map_pixbuf = nil
            print "'./maps/nt-map/map.png' not found\n"
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

    def display_route(cairo)
        node_indexes = @current_route.get_nodes(@current_event.end_index)
        if !@current_event || !@current_route then return end
        # translate and zoom according to view position and zoom scale
        cairo.save
        cairo.translate(@viewpos_x, @viewpos_y)
        cairo.scale(@zoom_scale, @zoom_scale)
        # draw a line between each pair of nodes in the route
        cairo.set_line_width(10)
        cairo.set_source_rgb(1,0,1) # hot pink (1,0,1) or turquoise (0,1,0.7) are both quite visible
        node_indexes.each_cons(2) do |node_a_idx, node_b_idx|
            start_x = @map.nodes[node_a_idx].coords.x_value
            start_y = @map.nodes[node_a_idx].coords.y_value
            end_x = @map.nodes[node_b_idx].coords.x_value
            end_y = @map.nodes[node_b_idx].coords.y_value
            cairo.move_to(start_x, start_y)
            cairo.line_to(end_x, end_y)
        end
        cairo.stroke
        # draw a big dot at start and end, and a small dot at each node to connect the lines smoothly
        node_indexes.each do |idx|
            x = @map.nodes[idx].coords.x_value
            y = @map.nodes[idx].coords.y_value
            if idx == node_indexes[0] || idx == node_indexes[-1]
            cairo.arc(x, y, 10, 0, 2*Math::PI)
            else
            cairo.arc(x, y, 5, 0, 2*Math::PI)
            end
            cairo.fill
        end
        cairo.restore
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
        if @viewpos_x > 0 then @viewpos_x = 0 end
        if @viewpos_x < -1*@zoom_scale*@map_width + @drawing_size
            @viewpos_x = -1*@zoom_scale*@map_width + @drawing_size
        end
        if @viewpos_y > 0 then @viewpos_y = 0 end
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
        if @zoom_scale > @max_zoom then @zoom_scale = @max_zoom end
        # convert map pos back to center of view pos
        @viewpos_x = @drawing_size / 2.0 - map_pos_x*@zoom_scale
        @viewpos_y = @drawing_size / 2.0 - map_pos_y*@zoom_scale
        @drawing_area.queue_draw
    end

    def zoom_out_clicked
        # convert center of view pos to map pos
        map_pos_x = (@drawing_size / 2.0 - @viewpos_x) / @zoom_scale
        map_pos_y = (@drawing_size / 2.0 - @viewpos_y) / @zoom_scale
        # decrease scale (min 0.318)
        @zoom_scale = @zoom_scale * 3/4
        if @zoom_scale < @min_zoom then @zoom_scale = @min_zoom end
        # convert map pos back to center of view pos
        @viewpos_x = @drawing_size / 2.0 - map_pos_x*@zoom_scale
        @viewpos_y = @drawing_size / 2.0 - map_pos_y*@zoom_scale
        change_viewpos(0, 0) # make sure it doesn't zoom out past the edge of the map
        @drawing_area.queue_draw
    end
    
    def zoom_to_route
        node_indexes = @current_route.get_nodes(@current_event.end_index)
        # get route's edges
        min_x = @map.nodes[node_indexes[0]].coords.x_value
        max_x = min_x
        min_y = @map.nodes[node_indexes[0]].coords.y_value
        max_y = min_y
        node_indexes.each do |idx|
            pos_x = @map.nodes[idx].coords.x_value
            pos_y = @map.nodes[idx].coords.y_value
            if pos_x < min_x then min_x = pos_x end
            if pos_x > max_x then max_x = pos_x end
            if pos_y < min_y then min_y = pos_y end
            if pos_y > max_y then max_y = pos_y end
        end
        # set zoom level so all nodes are visible
        padding = 100
        zoom_width = [max_x-min_x + 2*padding, max_y-min_y + 2*padding].max
        @zoom_scale = @map_height / zoom_width * @min_zoom
        if @zoom_scale < @min_zoom then @zoom_scale = @min_zoom end
        if @zoom_scale > @max_zoom then @zoom_scale = @max_zoom end
        # set view position so it's centred on the route
        map_pos_x = min_x - padding
        map_pos_y = min_y - padding
        @viewpos_x = -1 * map_pos_x*@zoom_scale
        @viewpos_y = -1 * map_pos_y*@zoom_scale
        change_viewpos(0, 0)
    end

    def settings_state
        if @window_box.children.include?(@main_box) then @window_box.remove(@main_box) end
        @window_box.pack_start(@settings_box)
        @window.show_all
    end

    def set_route_state
        @current_event = nil
        @current_route = nil
        if @window_box.children.include?(@settings_box) then @window_box.remove(@settings_box) end
        if @main_box.children.include?(@preview_box) then @main_box.remove(@preview_box) end
        if !@window_box.children.include?(@main_box) then @window_box.pack_start(@main_box) end
        if !@main_box.children.include?(@set_route_box) then @main_box.pack_start(@set_route_box) end
        @window.show_all
    end

    def preview_state
        if @main_box.children.include?(@set_route_box) then @main_box.remove(@set_route_box) end
        if !@main_box.children.include?(@preview_box) then @main_box.pack_start(@preview_box) end
        @start_label.text = "Start:  #{@location}\n"
        @end_label.text = "End:  #{@destination}\n"
        distance = @current_route.distances[@current_event.end_index]
        if distance < 1000 then @distance_label.text = "Estimated Distance:  #{distance.round} m\n"
        else @distance_label.text = "Distance:  #{(distance/1000.0).round(2)} km\n" end
    end

    def request_route
        print "\n=== Requesting routes from #{@location} to #{@destination}. (avoid_steps = #{@avoid_steps}) ===\n"
        ################ currently doesnt use avoid_steps
        # find all entrance ids for the selected start and end
        location_ids = @keywords[@location]
        destination_ids = @keywords[@destination]
        # generate a route for each location/destination pair
        events = []
        routes = []
        location_ids.each do |loc_id|
            destination_ids.each do |dest_id|
                event = Event.new("Route request", "north_terrace", @key_locations[loc_id], @key_locations[dest_id])
                route = @generator.calculate_route(event)
                if route
                    events.push(event)
                    routes.push(route)
                end
            end
        end
        # find the route with the lowest distance estimate
        fastest_event = events[0]
        fastest_route = routes[0]
        routes.each_with_index do |route, idx|
            print "Route #{idx+1} distance: #{route.distances[events[idx].end_index]}\n"
            if route.distances[events[idx].end_index] < fastest_route.distances[events[idx].end_index]
                fastest_event = events[idx]
                fastest_route = route
            end
        end
        print "=== Displaying fastest route ===\n"
        fastest_route.display(fastest_event.end_index)
        @current_event = fastest_event
        @current_route = fastest_route
    end
end
