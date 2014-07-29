class Roll < ActiveRecord::Base
  belongs_to :round
  belongs_to :player

  validate :valid_face_values

  def valid_face_values
    return if parsed_dice_string.all?{|value| value >=1 && value <= 6 }

    errors.add(:dice_string, "face values must be between 1 and 6")
  end

  def count(face, wild=true)
    raise ArgumentError.new("Invalid face value: #{face}") unless face >= 1 && face <= 6

    ret = dice[face]
    ret += dice[1] if wild && face != 1

    ret
  end

  def dice
    unless @dice
      # Map (1..6) to an array of 2 elt arrays [[1, ones], [2, twos], ...]
      # flattening that gives an array [1, ones, 2, twos, ...] and splatting that
      # to Hash[] gives a hash {1 => ones, 2 => twos, ...}
      @dice = Hash[*(1.upto(6).map{|i| [i, parsed_dice_string.count{|elt| elt == i}]}.flatten)]
    end

    @dice
  end

  def dice=(arr)
    self.dice_string = arr.join("-")
  end

  def dice_count
    parsed_dice_string.size
  end

  private
  def parsed_dice_string
    dice_string.split("-").map(&:to_i)
  end
end