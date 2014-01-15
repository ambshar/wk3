require 'rubygems'
require 'sinatra'
require 'sinatra/contrib/all'
require 'pry'

set :sessions, true
BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
STARTING_CASH = 500

helpers do
  def calculate_total(cards)
    arr = cards.map{|e| e[1] }

    total = 0
    arr.each do |value|
      if value == "A"
        total += 11
      elsif value.to_i == 0 # J, Q, K
        total += 10
      else
        total += value.to_i
      end
    end

  #correct for Aces
    arr.select{|e| e == "A"}.count.times do
      total -= 10 if total > BLACKJACK_AMOUNT
    end

    total
  end

  def card_image(card) #['H', '4']
   suit = case card[0]
        when 'C'
          "clubs"
        when 'S'
          "spades"
        when 'D'
          "diamonds"
        when 'H'
          "hearts"
        end

   value = card[1]
    if ['J','Q','K','A'].include?(value)
      value = case card[1]
        when 'J'then "jack"
        when 'Q' then "queen"
        when 'K' then "king"
        when 'A' then "ace"
       end
    end
   "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image' height='175' width='120'>"

   
  end

  def winner!(msg)
    
      @show_hit_or_stay_buttons = false
    
    @success = "<strong> #{session[:player_name]} wins. </strong>#{msg}"
    @play_again = true
    @win=true

  end

  def loser!(msg)
    @show_hit_or_stay_buttons = false
    @error = "<strong> #{session[:player_name]} loses. </strong>#{msg}"
    @play_again = true
    @win=false
  end

  def tie!(msg)
    @show_hit_or_stay_buttons = false
    @success = "<strong> It's a tie. </strong>#{msg}"
    @play_again = true
    @tie = true
  end

  def calculate_total_cash(bet)
    cash = session[:total_cash]
    
      if @win && @blackjack
        payout = (3*bet.to_i/2)
        cash += payout

      elsif @win
        payout = bet.to_i
        cash += payout
      elsif @win == false
        
        cash -= bet.to_i

      else  #tie
        cash = session[:total_cash]
      end
      return session[:total_cash] =  cash
      

    

      
      #binding.pry
  end
  
  def is_busted?(total)
    if total > BLACKJACK_AMOUNT
    true
    end

  end

end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end 
end


get '/new_player' do
  
  erb :new_player
end


post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end
  if params[:initial_bet_amount].empty?
    @error = "Enter bet amount"
    halt erb(:new_player)
  end

  if params[:initial_bet_amount].to_i==0 

    @error = "Enter multiples of 10"
    halt erb(:new_player)
  end

  if params[:initial_bet_amount].to_i> STARTING_CASH 

    @error = "You are betting more than you have"
    halt erb(:new_player)
  end


    session[:bet_amount] = params[:initial_bet_amount]
    session[:total_cash] = STARTING_CASH

    session[:player_name] = params[:player_name]
    redirect '/game'

end




get '/game' do
  
  session[:turn] = session[:player_name]
  #create a deck, shuffle and put it in session
  suits = ['H', 'D', 'S', 'C']
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']

  session[:deck] = suits.product(cards).shuffle!
  

  
  session[:player_cards] = []
  session[:dealer_cards] = []


  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  
  #session[:player_cards] << ['H','A']
  #session[:dealer_cards] << ['S','A']
  
  #session[:player_cards] << ['S','Q']
  #session[:dealer_cards] << ['H','K']
  


  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
      
    
    redirect '/game/compare'
    
  end


  erb :game

end

post '/game' do
  if params[:bet_amount].empty?
    @play_again=true
    @show_hit_or_stay_buttons = false
    @error = "Enter bet amount"
    halt erb(:game)
  end

  if params[:bet_amount].to_i==0 

    @error = "Enter numeric value"
    @play_again=true
    @show_hit_or_stay_buttons = false
    halt erb(:game)
  end
  

  if params[:bet_amount].to_i> session[:total_cash] 

    @error = "You are betting more than you have"
    @play_again=true
    @show_hit_or_stay_buttons = false
    halt erb(:game)
  end

  session[:bet_amount] = params[:bet_amount]

  
  redirect '/game'

end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])

  if player_total ==BLACKJACK_AMOUNT
    winner!("Congratulations! #{session[:player_name]} hit blackjack")
    

  elsif player_total>BLACKJACK_AMOUNT
    loser!("Sorry, looks like #{session[:player_name]} busted at #{player_total}")
    
  end
  
  
    erb :game
  
end




post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay"
  
  redirect '/game/dealer'

end

post '/game/player/double_down' do
  session[:bet_amount] = 2*session[:bet_amount].to_i
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])

  
  if is_busted?(player_total)
    
    loser!("Sorry, looks like #{session[:player_name]} busted at #{player_total}")
    erb :game
  else

    redirect '/game/dealer'
  end
end





get '/game/dealer' do
  @show_hit_or_stay_buttons = false
  
  session[:turn] = "dealer"
  dealer_total = calculate_total(session[:dealer_cards])
  

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Sorry dealer hit blackjack")
    
    

  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("The dealer busted at #{dealer_total}")
    
    
  elsif dealer_total >= DEALER_MIN_HIT
    
    redirect '/game/compare'

  else
   @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards]<<session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  
  if player_total != BLACKJACK_AMOUNT
    if player_total < dealer_total
      loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
      
    elsif player_total > dealer_total
      
      winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
      
    else
      tie!("Both #{session[:player_name]} and dealer stayed at #{player_total}")
    end
  elsif player_total > dealer_total
     @blackjack = true  #player got blackjack in two cards payout is 3:2
    winner!("Congratulations! #{session[:player_name]} hit blackjack")
  else
    loser!("Both #{session[:player_name]} and dealer hit Blackjack")
      
  end

  erb :game
end


get '/game_over' do
erb :game_over
end

