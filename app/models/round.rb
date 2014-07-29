class Round < ActiveRecord::Base
  include Startable

  belongs_to :game

  has_many :players, through: :game
  has_many :rolls

  scope :bids, ->{ calls.where(bs: false) }

  def before_start
    players.order(:seat_number).each do |p|
      roll = roll_dice(p)
      game.add_event(roll)
    end
  end

  def roll_dice(player)
    raise UsageError.new "Unable to roll after round has started." if started?

    roll = self.rolls.build(player: player)
    roll.dice = (0...player.dice_count).map{ Random.rand(6) + 1 }
    roll.save!

    roll
  end

  def prev_call
    calls.order(:sequence_number).last
  end

  def prev_bid
    @prev_bid ||= bids.order(:sequence_number).last.bid
  end

  def legal_bid?(bid)
    bid > prev_bid
  end

  def bid(player, bid)
    raise UsageError.new "Unable to bid when round is not in progress." unless in_progress?

    seq = prev_bid ? prev_bid.sequence_number + 1 : 0
    call = calls.create(number: bid.number, face_value: face_value, bs: false, player: player, legal: legal_bid?(bid), sequence_number: seq)
    update_attributes(ones_wild: false) if bid.face_value == 1
    game.add_event(call)
  end

  def bs(player)
    raise UsageError.new "Unable to call bs when round is not in progress." unless in_progress?

    seq = prev_bid ? prev_bid.sequence_number + 1 : 0
    call = calls.create(bs: false, player: player, sequence_number: seq)
    game.add_event(call)
  end
end
