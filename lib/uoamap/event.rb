# a class for wrapping events
class Event
  # Event holds the map to use, the start, and end point to use for the event
  def initialize(name, map, start_index, end_index)
    @name = name
    @map = map
    @start_index = start_index
    @end_index = end_index
  end

  attr_reader :name
  attr_reader :map
  attr_reader :start_index
  attr_reader :end_index
end
