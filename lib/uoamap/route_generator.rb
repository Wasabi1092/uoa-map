require_relative 'route'
require_relative 'map'

# A class for organising maps and routes
class RouteGenerator
  # RouteGenerator stores precalculated routes and maps
  #
  # init function for RouteGenerator
  def initialize
    # all values are empty because allowing maps and names to be passed immediately would be too messy
    @maps = {}
    @routes = {}
    @walk_speed = 1.65 # metres per second
  end

  # add_map binds a map to a name
  def add_map(name, map)
    # name: string referencing the name of the map. must be unique
    # map: Map object that has been filled (preferably)
    # returns nothing
    @maps[name] = map
  end

  # A function to calculate the shortest route with the given index
  def calculate_route(event, stairs=1)
    # name: the name of the map to lookup
    # start_index: the index of the starting node
    # end_index: the index of the end node
    # stairs: a bool which determines whether stairs should be used (True) or ignored (False)
    # returns [distance, path[]]
    # distance is a float, rounded to 1 d.p.
    # path[] is an array of indexes, which each value referencing the index of the previous node in the shortest path traversal
    map = event.map
    start_index, end_index = event.start_index, event.end_index
    result = @routes[[map, start_index, end_index, stairs]]
    if result != nil then
      return result
    end
    map_object = @maps[map]
    @routes[[map, start_index, end_index, stairs]] = result = map_object.shortest_path(event, stairs)
    return result
  end

  # A function to return all map keys
  def map_names
    @maps.keys
  end

  # A function to estimate the time required for walking
  def estimate_time(name, start_index, end_index)
    # name: the name of the map to use
    # start_index: the index of the start node
    # end_index: the index of the end node

    # return value: time needed for walking from start node to end node (estimated)
    route = calculate_route(name, start_index, end_index)
    return route[end_index] /(3 * @walk_speed)
  end

  # A function to return all maps
  def maps
    @maps
  end
end
