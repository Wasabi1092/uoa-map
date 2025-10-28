require_relative 'map_node'
# a class to hold all routes from a given point
class Route
  # route holds the shortest distances and their paths from a given index
  def initialize(distances, paths, start_index)
    @distances = distances
    @paths = paths
    @start_index = start_index
  end
  def display(node_end_index)
    printf "Distance %f units\n", distances[node_end_index]
    index = node_end_index
    order = []
    while true do
      order.unshift(index)
      if index == start_index then
        break
      end
      index = paths[index]
    end
    printf "Path: "
    order.each_with_index do |item, index|
      if index == (order.length-1) then
        printf"Node %d", item
        break
      else
        printf "Node %d -> ", item
      end
    end
    printf "\n========\n"
  end
  attr_reader :distances
  attr_reader :paths
  attr_reader :start_index
end
