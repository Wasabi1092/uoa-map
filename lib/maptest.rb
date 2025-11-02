require 'json'

# custom classes go here
require './uoamap/event.rb'
require './uoamap/map.rb'
require './uoamap/map_node.rb'
require './uoamap/route.rb'
require './uoamap/string.rb'
require './uoamap/route_generator.rb'

# initialise maps
def init_map(map="nt-map")
  # load map points and connections
  nt_map = File.read("./maps/#{map}/map_points.json")
  map_data = JSON.parse(nt_map)
  nodes = []
  key_locations = {}
  stairs = []
  map_data['points'].each_with_index do |item, index|
    nodes.push(MapNode.new(item['x'], item['y'], 0, index))
    if (!(item['id'].is_num?)) then
      key_locations[item['id']] = index
    end
  end

  map_data['connections'].each do |item|
    start_index = item['from']
    end_index = item['to']
    if (start_index.is_num?) then
      start_index = start_index.to_i
    else
      start_index = key_locations[start_index]
    end
    if (end_index.is_num?) then
      end_index = end_index.to_i
    else
      end_index = key_locations[end_index]
    end
    nodes[start_index].add_adj(nodes[end_index], end_index)
    nodes[end_index].add_adj(nodes[start_index], start_index)
  end

  map = Map.new()

  nodes.each do |item|
    map.add_node(item)
  end

  map_data['connections'].each do |item|
    start_index = item['from']
    end_index = item['to']
    if (start_index.is_num?) then
      start_index = start_index.to_i
    else
      start_index = key_locations[start_index]
    end
    if (end_index.is_num?) then
      end_index = end_index.to_i
    else
      end_index = key_locations[end_index]
    end

    if item["stairs"] then
      map.add_stairs(start_index, end_index)
    end
  end
  return map, key_locations
end

def test_map ()
  # init_map returns the map object and the key locations which we can use to bind values.
  map, key_locations = init_map()

  # create a generator object which will hold all of our maps
  generator = RouteGenerator.new()

  # add the map to the generator and give it a name
  generator.add_map("north_terrace", map)

  # now we need a test event just to hold the values here
  test_event = Event.new("Event", "north_terrace", key_locations["hub_w1"], key_locations["darling_west"], false)

  # then we can pass the event into the generator to calculate the route
  route = generator.calculate_route(test_event)

  # display function for the route
  route.display(test_event.end_index)

  # route.paths holds the parents, so you'll need to traverse it backwards if you want the visited nodes
end

test_map()
