class GamesController < ApplicationController
  before_filter :authenticate_user!, :only => :new
  before_filter :game_accessible?, :only => :show

  def new
    @previous_games = current_user.games.recent
  end

  def create
    @game = Game.new
    @game.state = "waiting_for_both_players"
    @game.password = generate_password(8)
    @game.user = current_user

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
      if params[:first_turn] == "1"
        @game.first_turn = player1.id
      else
        @game.first_turn = player2.id
      end
      @game.save
    end
    @words = Game::WORDS
    render :show
  end

  def show
    if current_user
      @player = @game.players.first
    else
      @player = @game.players.last
      if @game.state == "waiting_for_both_players"
        Message.create(:game_id  => @game.id, :message_type  => "notification", :content => "Both players are ready to play")
        if @game.first_turn == @game.players.first.id
          @game.update_state("waiting_for_player1_question")
        else
          @game.update_state("waiting_for_player2_question")
        end
      end
    end  # player 2
    @words = Game::WORDS
  end
  
  def destroy
    @game = Game.find(params[:id])
    @final_card = params[:final_card]
    @player = Player.find(params[:player_id])
    other_player = (@game.players - [@player.id]).first

    if @final_card.to_i == other_player.chosen_card
      @game.update_state("#{@player.name} won")
    else
      @game.update_state("#{other_player.name} won")
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
      if current_user.nil?
        if @game.password != params[:password]
          flash[:error] = "You do not have permissions to access that game. If you would like to start a new game please fill in the details below"
          redirect_to root_path
        end
      else
        if @game.user != current_user
          flash[:error] = "You do not have permissions to access that game. If you would like to start a new game please fill in the details below"
          redirect_to root_path
        end
      end
    end
  end

end
