require 'yaml'

MESSAGES = YAML.load_file('tic_tac_toe.yml')

module Marker
  I_MARKER = ' '
  X_MARKER = 'x'
  O_MARKER = 'o'
end

module Promptable
  def prompt(message)
    puts(message)
  end

  def new_line
    puts ''
  end

  def pause
    sleep 2
  end

  def long_pause
    sleep 3.75
  end

  def longest_pause
    sleep 8.5
  end

  def clear_screen
    system('cls') || system('clear')
  end
end

module Formattable
  include Promptable

  def format_board
    squares
      .values
      .each_slice(squares_per_row)
      .map { |row| row.map { |marker| "|  #{marker}  |" } }
      .flatten
  end

  def top_or_bottom(size)
    prompt(MESSAGES['ceiling'] * size)
  end

  def middle(size)
    prompt(MESSAGES['mid_square'] * size)
  end

  def print_markers(row)
    prompt(row.join)
  end

  def draw
    format_board.each_slice(squares_per_row) do |row|
      top_or_bottom(squares_per_row)
      middle(squares_per_row)
      print_markers(row)
      middle(squares_per_row)
      top_or_bottom(squares_per_row)
    end
  end
end

module Conquerable
  def center_square
    (squares.keys.size / 2) + 1
  end

  def rows
    square_positions.each_slice(squares_per_row).to_a
  end

  def columns
    rows.transpose
  end

  def diagonals
    rows
      .map
      .with_index { |row, idx| row[idx] }
  end

  def reverse_diagonals
    rows
      .reverse_each
      .map
      .with_index { |row, idx| row[idx] }
  end

  def winning_lines
    [rows, columns].flatten(1) << diagonals << reverse_diagonals
  end

  def winning_marker
    winning_lines.each do |line|
      squares = @squares.values_at(*line)

      if x_identitical_markers?(squares)
        return squares.first.marker
      end
    end

    nil
  end

  def x_identitical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != squares_per_row
    markers.min == markers.max
  end

  def someone_won?
    !!winning_marker
  end

  def open_squares
    unoccupied
  end

  def full?
    open_squares.empty?
  end
end

class Board
  include Formattable
  include Conquerable
  include Marker

  attr_reader :squares_per_row, :square_positions, :squares, :gameplay

  def initialize
    standard_gameplay
  end

  def [](key)
    @squares[key].marker
  end

  def []=(key, new_value)
    @squares[key].marker = new_value
  end

  def reset
    set_up_squares
  end

  def custom_gameplay
    custom_grid_size
  end

  def standard_gameplay
    standard_grid_size
  end

  private

  attr_writer :squares_per_row, :square_positions, :squares, :gameplay

  def standard_grid_size
    standard_squares_per_row
    set_up_positions
    set_up_squares
  end

  def standard_squares_per_row
    @squares_per_row = 3
  end

  def set_up_positions
    @square_positions = (1..squares_per_row**2).to_a
  end

  def set_up_squares
    @squares = {}
    square_positions.each { |position| @squares[position] = Square.new }
  end

  def custom_grid_size
    custom_squares_per_row
    set_up_positions
    set_up_squares
  end

  def custom_squares_per_row
    loop do
      prompt <<~CUSTOM
                  => your custom grid size must be an odd
                     number greater than or equal to 3

                CUSTOM
      self.squares_per_row = gets.chomp.to_i
      break if squares_per_row.odd? && squares_per_row >= 3

      prompt(MESSAGES['wrong_grid_size'])
    end
  end

  def grid_size_choice
    choice = nil
    prompt(MESSAGES['board_size'])

    loop do
      prompt(MESSAGES['standard_board_size'])
      prompt(MESSAGES['custome_board_size'])
      choice = gets.chomp.downcase
      break if ['s', 'c'].include? choice

      prompt(MESSAGES['wrong_board_choice'])
    end

    choice
  end

  def unoccupied
    squares.keys.select { |k| @squares[k].unmarked? }
  end
end

class Square
  include Marker

  attr_accessor :marker

  def initialize(marker = I_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == I_MARKER
  end

  def marked?
    marker != I_MARKER
  end
end

class Player
  include Marker
  include Promptable

  attr_reader :name, :marker, :score

  def initialize
    prepare_attributes
  end

  def standard_gameplay
    standard_marker
  end

  def custom_gameplay(other_player)
    custom_marker(other_player)
  end

  def wins
    self.score += 1
    prompt("#{name} wins!")
  end

  def reset
    set_up_score
  end

  private

  attr_writer :name, :marker, :score

  def prepare_attributes
    set_up_name
    set_up_marker
    set_up_score
  end

  def set_up_marker
    @marker = I_MARKER
  end

  def set_up_score
    @score = 0
  end
end

class Human < Player
  private

  def set_up_name
    prompt(MESSAGES['name'])
    self.name = gets.chomp.downcase
  end

  def standard_marker
    self.marker = X_MARKER
  end

  def custom_marker(other_player)
    if other_player.marker == X_MARKER
      self.marker = O_MARKER
    elsif other_player.marker == O_MARKER
      self.marker = X_MARKER
    else
      choose_marker
    end
  end

  def choose_marker
    loop do
      prompt(MESSAGES['marker_choice'])
      self.marker = gets.chomp.downcase
      break if [X_MARKER, O_MARKER].include? marker

      prompt(MESSAGES['wrong_marker'])
    end
  end
end

class Computer < Player
  private

  def set_up_name
    self.name = ['jon', 'marc', 'stelios'].sample
  end

  def standard_marker
    self.marker = O_MARKER
  end

  def custom_marker(other_player)
    self.marker = if other_player.marker.empty?
                    [X_MARKER, O_MARKER].sample
                  elsif other_player.marker == X_MARKER
                    O_MARKER
                  else
                    X_MARKER
                  end
  end
end

module Displayable
  include Promptable

  def display_welcome_message
    pause
    clear_screen
    prompt(MESSAGES['welcome'] + ", #{human.name}")
    new_line
    long_pause
    clear_screen
  end

  def display_rules
    prompt <<~RULES
            the rules of the game are simple:

            - one point per win
            - first player to 3 points wins the game

            ready?

            ok...let's play

              RULES
    longest_pause
    clear_screen
  end

  def display_gameplay_choice_message
    prompt <<~GAMEPLAY
          before we begin, let's set up the game play

          you have two options:

          standard 
            - 3x3 grid
            - human marker is x
            - computer marker is o
            - human goes first

          custom
            - choose your grid size
            - choose who goes first
            - choose who gets which marker
          
          ok then ...
          
          enter (s) for standard gameplay
          enter (c) for custom gameplay
          GAMEPLAY
  end

  def display_board
    board.draw
  end

  def display_board_and_score
    clear_screen
    display_board
    display_scores
  end

  def display_open_square_choice
    prompt(MESSAGES['choose_square'] + joinor(board.open_squares).to_s)
  end

  def joinor(options, separator = ', ', joiner = 'or')
    case options.size
    when 1 then options.first
    when 2 then options.join(separator)
    else
      options[-1] = "#{joiner} #{options.last}"
      options.join(separator)
    end
  end

  def display_human_score
    prompt("--- #{human.name}")
    prompt("marker: #{human.marker}")
    prompt("wins: #{human.score}")
  end

  def display_computer_score
    prompt("--- #{computer.name}")
    prompt("marker: #{computer.marker}")
    prompt("wins: #{computer.score}")
  end

  def display_scores
    new_line
    display_human_score
    new_line
    display_computer_score
    new_line
  end

  def play_again_message
    prompt(MESSAGES['play_again'])
  end

  def display_goodbye_message
    pause
    clear_screen
    prompt(MESSAGES['goodbye'])
  end
end

class TicTacToe
  include Displayable
  include Marker

  attr_reader :human, :computer, :board,
              :gameplay, :first_player, :current_player

  def initialize
    @human = Human.new
    @computer = Computer.new
    @board = Board.new
    game_attributes
  end

  def play
    display_welcome_message
    display_rules
    set_gameplay

    loop do
      main_game
      break unless play_again?
      reset_scores
    end

    display_goodbye_message
  end

  private

  attr_writer :gameplay, :first_player, :current_player

  def main_game
    loop do
      player_move
      display_result
      break if game_won?
    end
  end

  def player_move
    display_board_and_score

    loop do
      current_player_moves
      break if board.someone_won? || board.full?

      display_board_and_score
    end
  end

  def display_result
    display_board_and_score
    determine_winner
    long_pause
  end

  # Winning logic

  def game_won?
    human.score == 3 ||
      computer.score == 3
  end

  def determine_winner
    case board.winning_marker
    when human.marker
      human.wins
    when computer.marker
      computer.wins
    else
      prompt("it's a tie")
    end
    clear_board
  end

  # Gameplay logic

  def set_gameplay
    choose_gameplay
    choose_markers
  end

  def choose_gameplay
    display_gameplay_choice_message

    loop do
      @gameplay = gets.chomp.downcase
      break if ['s', 'c'].include? gameplay

      prompt(MESSAGES['invalid_choice'])
    end

    clear_screen
  end

  def choose_markers
    if gameplay == 's'
      standard_gameplay
    else
      custom_gameplay
    end
  end

  def standard_gameplay
    human.standard_gameplay
    computer.standard_gameplay
  end

  def custom_gameplay_human_goes_first
    human.custom_gameplay(computer)
    computer.custom_gameplay(human)
  end

  def custom_gameplay_computer_goes_first
    computer.custom_gameplay(human)
    human.custom_gameplay(computer)
    self.current_player = computer
    self.first_player = computer
  end

  def custom_gameplay
    if who_goes_first == 'h'
      custom_gameplay_human_goes_first
    else
      custom_gameplay_computer_goes_first
    end

    board.custom_gameplay
  end

  def who_goes_first
    answer = nil

    loop do
      prompt(MESSAGES['first_move'])
      answer = gets.chomp.downcase
      break if ['h', 'c'].include? answer

      prompt(MESSAGES['invalid_player'])
    end

    answer
  end

  def play_again?
    answer = nil

    loop do
      prompt(MESSAGES['play_again'])
      answer = gets.chomp.downcase
      break if ['y', 'n'].include? answer

      prompt(MESSAGES['invalid_play_again'])
    end

    answer == 'y'
  end

  def current_player_moves
    if human_turn?
      human_moves
      self.current_player = computer
    else
      computer_moves
      self.current_player = human
    end
  end

  # Human and Computer game logic

  def human_turn?
    current_player.marker == human.marker
  end

  def human_moves
    display_open_square_choice
    square = nil

    loop do
      square = gets.chomp.to_i
      break if board.open_squares.include? square

      prompt(MESSAGES['wrong_square'])
    end

    board[square] = human.marker
  end

  def center_square_available?
    square = board.center_square
    board.open_squares.include? square
  end

  def grab_center_square
    return unless center_square_available?

    square = board.center_square
    board[square] = computer.marker
  end

  def grab_random_square
    square = board.open_squares.sample
    board[square] = computer.marker
  end

  def exactly_x_amount_of?(marker, squares)
    target = board.squares_per_row - 1

    (squares.count(marker) == target) &&
      (squares.count(I_MARKER) == 1)
  end

  def attacking_move_available?(squares)
    exactly_x_amount_of?(computer.marker, squares)
  end

  def defensive_move_available?(squares)
    exactly_x_amount_of?(human.marker, squares)
  end

  def target(line)
    line.select { |k| board[k] == I_MARKER }.first
  end

  def current_markers(line)
    board.squares.values_at(*line).map(&:marker)
  end

  def attack_or_defend
    board.winning_lines.any? do |line|
      curr_squares = current_markers(line)

      if attacking_move_available?(curr_squares)
        board[target(line)] = computer.marker
      elsif defensive_move_available?(curr_squares)
        board[target(line)] = computer.marker
      end
    end
  end

  def computer_moves
    attack_or_defend ||
      grab_center_square ||
      grab_random_square
  end

  # Board logic

  def game_attributes
    @current_player = human
    @first_player = human
  end

  def clear_board
    board.reset
    self.current_player = first_player
  end

  def reset_scores
    human.reset
    computer.reset
  end
end

TicTacToe.new.play
