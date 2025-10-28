class String
  def is_num?
    true if Float(self) rescue false
  end
end
