require 'yaml'

MESSAGES = YAML.load_file('twenty_one.yml')

module Promptable
  def prompt(message)
    puts(message)
  end

  def new_line
    prompt('')
  end

  def pause
    sleep 1
  end

  def longer_pause
    sleep 3
  end
end

module Cards
  RANK = { 2 => 2, 3 => 3, 4 => 4, 5 => 5,
           6 => 6, 7 => 7, 8 => 8, 9 => 9,
           10 => 10, 'jack' => 10, 'queen' => 10,
           'king' => 10, 'ace' => 11 }.freeze
  SUIT = %w(♣ ♥ ♠ ♦).freeze

  DECK = SUIT.product(RANK.keys).freeze
end

class Deck
  attr_reader :current_pack

  def initialize
    reset
  end

  def deal
    current_pack.shift
  end

  def reset
    new_pack
  end

  private

  attr_writer :current_pack

  def new_pack
    @current_pack = Cards::DECK.shuffle
  end
end

module Formattable
  include Promptable

  def format_hand
    hand
      .flatten
      .each_slice(2)
      .map { |card| "[ #{card.first} #{card.last} ]" }
      .join
  end
end

module Revealable
  include Promptable

  def display_hand
    prompt("--- #{name} : #{total}")
    prompt(format_hand)
    new_line
  end

  def display_latest_card
    pause
    prompt("--- card drawn by #{name}")
    prompt("[ #{hand.last.first} #{hand.last.last} ]")
    new_line
  end
end

module Hand
  def ace_count
    hand
      .map(&:last)
      .count('ace')
  end

  def non_aces_sum
    hand
      .map(&:last)
      .reject { |card| card == 'ace' }
      .map { |card| Cards::RANK[card] }
      .sum
  end

  def correct_for_aces
    ace_count.times do
      self.total = if (non_aces_sum + 11) > 21
                     total + 1
                   else
                     total + 11
                   end
    end
  end

  def update_total
    self.total = non_aces_sum

    if ace_count.zero?
      total
    else
      correct_for_aces
    end
  end

  def busted?
    total > 21
  end

  def not_busted?
    !busted?
  end

  def more_points_than?(other_player)
    total > other_player.total
  end

  def beats?(other_player)
    more_points_than?(other_player) && not_busted?
  end
end

class Participant
  include Hand
  include Formattable
  include Revealable

  attr_reader :name, :total, :hand

  def initialize
    set_name
    reset
  end

  def receive_cards(deck)
    cards_added_to_hand(deck)
  end

  def wins
    prompt("#{name} wins!")
  end

  def loses
    prompt("ohhh no ... #{name} busted")
  end

  def reset
    clear_cards_and_points
  end

  private

  attr_writer :name, :total

  def clear_cards_and_points
    @total = 0
    @hand = []
  end

  def cards_added_to_hand(deck)
    hand << deck
  end
end

class Player < Participant
  attr_reader :hits, :stays

  def initialize
    super
    @hits = 'h'
    @stays = 's'
  end

  private

  def set_name
    prompt(MESSAGES['enter_name'])
    self.name = gets.chomp.downcase
  end
end

class Dealer < Participant
  def hits
    prompt("#{name} hits ...")
  end

  def stays
    total >= 17
  end

  def format_partial_hand
    "[ #{hand.first.join(' ')} ][ ? ]"
  end

  def display_partial_hand
    prompt("--- #{name} : ?")
    prompt(format_partial_hand)
    new_line
  end

  private

  def set_name
    self.name = %w(joe marc stelios).sample
  end
end

module Displayable
  include Promptable

  def clear_screen
    system('clear') || system('cls')
  end

  def pause_and_clear_screen
    pause
    clear_screen
  end

  def longer_pause_and_clear_screen
    longer_pause
    clear_screen
  end

  def pause_and_linebreak
    pause
    new_line
  end

  def pause_linebreak_and_clear_screen
    pause
    new_line
    clear_screen
  end

  def linebreak_pause_linebreak
    new_line
    longer_pause
    new_line
  end

  def flip_them_over
    prompt(MESSAGES['flip_cards'])
  end

  def nobody_wins
    prompt(MESSAGES['tie'])
  end

  def welcome_to_the_table
    pause_and_clear_screen
    prompt("welcome to the table, #{player.name}")
    longer_pause_and_clear_screen
  end

  def cards_dealt
    prompt(MESSAGES['cards_dealt'])
    longer_pause_and_clear_screen
  end

  def display_welcome_message
    welcome_to_the_table
    cards_dealt
  end

  def display_flop
    player.display_hand
    dealer.display_partial_hand
  end

  def display_all_cards
    player.display_hand
    dealer.display_hand
  end

  def display_goodbye_message
    pause_and_clear_screen
    prompt(MESSAGES['goodbye'])
    new_line
  end
end

module Winnable
  def dealer_wins_through_points
    pause_and_clear_screen
    flip_them_over
    pause_and_linebreak
    dealer.wins
    new_line
  end

  def dealer_wins_through_bust
    pause_and_clear_screen
    player.loses
    pause_and_linebreak
    dealer.wins
    new_line
  end

  def player_wins_through_points
    clear_screen
    flip_them_over
    pause_linebreak_and_clear_screen
    player.wins
    new_line
  end

  def player_wins_through_bust
    clear_screen
    dealer.loses
    pause_and_linebreak
    player.wins
    new_line
  end

  def its_a_push
    clear_screen
    flip_them_over
    pause_and_linebreak
    nobody_wins
    new_line
  end
end

class Game
  include Winnable
  include Displayable

  attr_reader :player, :dealer, :deck

  def initialize
    @player = Player.new
    @dealer = Dealer.new
    @deck = Deck.new
  end

  def play
    display_welcome_message

    loop do
      game_mechanics
      break unless play_again?
      clear_screen
    end

    display_goodbye_message
  end

  private

  def determine_winner
    if someone_busted?
      winner_through_bust
    elsif someone_won?
      winner_through_points
    else
      its_a_push
    end
  end

  def deal_cards
    2.times do
      player.receive_cards(deck.deal)
      player.update_total
      dealer.receive_cards(deck.deal)
      dealer.update_total
    end
  end

  def game_mechanics
    deal_cards
    display_flop
    player_turn
    dealer_turn
    determine_winner
    display_all_cards
    reset
  end

  def play_again?
    choice = nil

    loop do
      prompt(MESSAGES['play_again'])
      choice = gets.chomp.downcase
      break if %(y n).include? choice

      prompt(MESSAGES['invalid_play_again'])
    end

    choice == 'y'
  end

  # Winning Logic

  def someone_busted?
    player.busted? || dealer.busted?
  end

  def someone_won?
    player.beats?(dealer) || dealer.beats?(player)
  end

  def winner_through_bust
    if player.busted?
      dealer_wins_through_bust
    else
      player_wins_through_bust
    end
  end

  def winner_through_points
    if player.beats?(dealer)
      player_wins_through_points
    else
      dealer_wins_through_points
    end
  end

  # Player game mechanics

  def player_hits_or_stays?
    choice = nil

    loop do
      prompt(MESSAGES['hit_or_stay'])
      choice = gets.chomp.downcase
      break if %w(h s).include? choice

      prompt(MESSAGES['invalid_hit_or_stay'])
    end

    choice
  end

  def player_gameplay
    player.receive_cards(deck.deal)
    player.update_total
    player.display_latest_card
    player.display_hand
  end

  def player_turn
    loop do
      choice = player_hits_or_stays?

      if choice == player.hits
        clear_screen
        player_gameplay
        break if player.busted?
      end

      break if choice == player.stays
    end
  end

  # Dealer game mechanics

  def dealer_gameplay
    dealer.hits
    dealer.receive_cards(deck.deal)
    dealer.update_total
    pause
    dealer.display_partial_hand
  end

  def dealer_turn
    loop do
      break if player.busted? || dealer.stays

      dealer_gameplay
    end
  end

  # Reset player, dealer and deck stats

  def reset
    player.reset
    dealer.reset
    deck.reset
  end
end

Game.new.play
