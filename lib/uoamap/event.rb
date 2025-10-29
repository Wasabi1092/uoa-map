# a class for wrapping events
class Event
  # Event holds the map to use, the start, and end point to use for the event
  def initialize(name, map, start_index, end_index)
    @name = name # string, can be anything
    @map = map # string, needs to be a valid map name
    @start_index = start_index # index of the starting node in the map
    @end_index = end_index # index of the end node in the map
  end

  attr_reader :name
  attr_reader :map
  attr_reader :start_index
  attr_reader :end_index
end
