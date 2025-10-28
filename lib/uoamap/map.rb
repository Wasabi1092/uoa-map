require_relative 'route'
require_relative 'map_node'

# Map is a class for handling a map
class Map
  # This doesn't need to map a full area but can be used to map sub areas, connected by their exits

  # init function for Map class
  def initialize()
    # all variables are empty because they will almost always be overloaded later
    # nodes[] are the MapNodes that the Map has
    # adjacent[][] are the vertices of the Map
    # stairs[][] are the vertices that are considered stairs
    # exit[] are the nodes considered exits for the map
    @name = "map"
    @nodes = []
    @adjacent = []
    @stairs = []
    @exit = []
  end

  # addNode adds a node to the list of nodes inside the map
  def add_node(node)
    # node is the MapNode to be added to the map
    # adj is an array of IDs that the MapNode is adjacent to
    # nodes should be fully initialized before the map object is created
    @nodes << node
    temp = node.adj
    res = []
    temp.each_with_index do |item, index|
      res[index] = (item!=nil) ? item : 0
    end
    @adjacent[node.id] = temp
  end

  # add_stairs creates a two-way connection between node1 and node2 and defines it as a stair
  def add_stairs(start_node, end_node)
    # start_node is the MapNode that is part of the stair connection
    # end_node is the other MapNode that is part of the stair connection
    node1_id = start_node.id
    node2_id = end_node.id
    @adjacent[node1_id][node2_id],@adjacent[node2_id][node1_id] = node1.adj[node2_id]
    @stairs[node1_id][node2_id],@stairs[node2_id][node1_id] = 1
  end

  # add_exit adds a node to be recognised as an exit on the map
  def add_exit(index)
    # index is the index of the node inside @nodes that is considered the exit
    @exit << @nodes[index]
  end

  # display function for Map
  def display
    # prints out each node in order
    for node in @nodes do
      node.display()
    end
    return @nodes.length
  end

  # shortestPath is a function that calculates the shortest distance between a start MapNode and end MapNode
  def shortest_path(event, stairs=1)
    #
    # start - the MapNode where the user starts
    # end - the MapNode where the user will end
    # stairs - a bool which determines whether stairs should be used (True) or ignored (False)
    #
    # returns [shortest path, parents[]]
    # shortest path is a distance
    # parents[] is an array that shows the shortest path to every node in the map from the start point.
    size = @nodes.length
    start_node_id = event.start_index
    range_arr = (0..(size-1)).to_a
    distances = Array.new(size, Float::INFINITY)
    distances[start_node_id] = 0
    visited = Array.new(size, false)
    parents = Array.new(size, -1)
    curr_node = -1
    for _ in range_arr do
      min = Float::INFINITY
      for index in range_arr do
        curr_dist = distances[index]
        if !visited[index] and curr_dist < min then
          min = curr_dist
          curr_node=index
        end
      end
      if curr_node == -1 then
        break
      end

      visited[curr_node] = true
      for target_node in range_arr do
        stair_node = @stairs[curr_node]
        if (stair_node != nil && stair_node[target_node] == 1 && !stairs) then
          next
        end
        dist = @adjacent[curr_node][target_node]

        if (dist != 0 && dist != nil) && (!visited[target_node]) then
          target_dist = distances[target_node]
          temp = distances[curr_node] + dist
          if temp < target_dist then
            distances[target_node] = temp
            parents[target_node] = curr_node
          end
        end
      end
    end
    return Route.new(distances, parents, start_node_id)
  end

  attr_reader :nodes
  attr_accessor :name
end
