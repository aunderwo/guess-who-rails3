class GamesController < ApplicationController
  before_filter :authenticate_user!, :only => :new
  before_filter :game_accessible?, :only => :show

  def new

  end

  def create
    @game = Game.new
    @game.state = "waiting_for_both_players"
    @game.password = generate_password(8)

    player1 = Player.new
    player1.name = params[:player1_name]
    player1.chosen_card = rand(24)
    player1.game = @game

    @player = player1

    player2 = Player.new
    player2.name = params[:player2_name]
    player2.chosen_card = rand(24)
    until player2.chosen_card != player1.chosen_card
      player2.chosen_card = rand(24)
    end
    player2.game = @game

    Game.transaction do
      player1.save
      player2.save
      if params[:first_turn] == 1
        @game.first_turn = player1.id
      else
        @game.first_turn = player2.id
      end
      @game.save
    end
    @words = ["a", "head","mouth","eye","eyes","nose","eyes on stalks","skin","one","two","three","blue","green","orange","spotty","squiggly","circular","oval","triangular","happy","sad"]
    render :show
  end

  def show
    @player = @game.players.last
    @words = ["a", "head","mouth","eye","eyes","nose","eyes on stalks","skin","one","two","three","blue","green","orange","spotty","squiggly","circular","oval","triangular","happy","sad"]
    if @game.state = "waiting_for_both_players"
      if @player.id == @game.first_turn
        @game.update_attribute(:state, "waiting_for_player1_question")
      else
        @game.update_attribute(:state, "waiting_for_player1_question")
      end
    end
  end

  private
  def generate_password(len = 8 )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    password = ""
    1.upto(len) { |i| password << chars[rand(chars.size-1)] }
    return password
  end
  def game_accessible?
    if @game.nil?
      @game = Game.find(params[:id])
      if @game.password != params[:password]
        flash[:error] = "You do not have permissions to access that game. If you would like to start a new game please fill in the details below"
        redirect_to root_path
      end
    end
  end

end
