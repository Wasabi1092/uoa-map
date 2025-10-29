# Coords is a data structure for organising a set of x, y, and z values
Coords = Struct.new(:x_value, :y_value, :z_value)
# Has values x_value, y_value, and z_value

# MapNode is a coordinate position on a Map
# MapNode is a coordinate position on a Map
class MapNode
  # It represents the physical position in the world, using the Map as a scale
  def initialize(x_value, y_value, z_value, id)
    @coords = Coords.new(x_value, y_value, z_value)
    @adj = []
    @id = id
  end

  # Add an adjacent node to the current node
  def add_adj(node, index)
    # node - the MapNode that the node is adjacent to
    # adj - int, either 0 or 1, that represents whether the path exists
    # add_adj automatically calculates the weighting for the connection
    # return value - none
    target_coords = node.coords;
    @adj[index] = (((target_coords.x_value-@coords.x_value)**2 + (target_coords.y_value-@coords.y_value)**2 + (target_coords.z_value-@coords.z_value) **2)**0.5).round(1)
  end

  # set_adj sets all adjacent values for the node
  def set_adj(arr)
    # arr is an array of integers that are already calculated for the node
    @adj = arr
  end

  # display function for MapNodes
  def display()
    # This function prints out the ID, (x, y, z) coordinates of the MapNode object
    printf "Node %d | %d, %d, %d\n", id, @coords.x_value, @coords.y_value, @coords.z_value
  end

  attr_reader :coords
  attr_reader :adj
  attr_reader :id
end
