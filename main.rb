require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?

set :bind, '0.0.0.0'
set :sessions, true

helpers do

  SUITS = ['C', 'D', 'H', 'S']
  VALUES = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']

  def error(msg)
    session[:error] = msg
  end

  def victory_message(msg)
    session[:victory_message] = msg
  end

  def shuffle_deck(deck)
    deck.shuffle!
  end

  def card_image(card = nil)
    return "/images/cards/#{suit_to_text(card[1])}_#{value_to_text(card[0])}.jpg" unless card.nil?
    return "/images/cards/cover.jpg"
  end

  def suit_to_text(symbol)
    case symbol
      when 'C'
        return 'clubs'
      when 'D'
        return 'diamonds'
      when 'H'
        return 'hearts'
      when 'S'
        return 'spades'
    end
  end

  def value_to_text(value)
    case value
      when 'A'
        return 'ace'
      when 'J'
        return 'jack'
      when 'Q'
        return 'queen'
      when 'K'
        return 'king'
      else
        return value.to_s
    end
  end

  def init_deck
    shuffle_deck(VALUES.product(SUITS))
  end

  def deal_card(cards, deck)
    card = deck.sample
    deck.delete(card)
    cards.push(card)
  end

  def win(msg, payout)
    victory_message("<b>You Win!</b> #{msg}<br>Payout: <b>$#{session[:player_bet]*payout}</b> (#{payout}x Multiplier)")
    session[:player_cash] += session[:player_bet]*payout
  end

  def lose(msg)
    error("<b>You Lose</b> #{msg}")
  end

  def check_for_outcome
    player_total = get_card_total(session[:player_cards])
    dealer_total = get_card_total(session[:dealer_cards])

    if dealer_total == 21 && player_total < 21
      lose('Dealer has Blackjack')
    elsif player_total > 21
      lose('Player Busted')
    elsif dealer_total == player_total
      victory_message('Game is a draw')
      session[:player_cash] += session[:player_bet]
    elsif player_total == 21
      win('Blackjack!', 3)
    elsif dealer_total > 21
      win('Dealer Busted', 2)
    elsif player_total < 21 && dealer_total < player_total
      win('Player has Higher Hand', 2)
    elsif dealer_total > player_total
      lose('Dealer has Higher Hand')
    end
  end

  def get_card_total(cards)
    total = 0
    cards.each do |card|
      x = card[0]
      case x
        when 'A'
          total += 11
        when 'J', 'Q', 'K'
          total += 10
        else
          total += x.to_i
      end
    end

    # If the player has an ace, we don't want to push them over 21, so we'll subtract 10 to compensate
    cards.each do |card|
      x = card[0]
      if x == 'A'
        total -= 10 if total > 21
      end
    end

    return total
  end

  def run_game

    if session[:initializing]
      session[:player_cards] = []
      session[:dealer_cards] = []
      session[:deck] = init_deck

      if session[:player_bet] > session[:player_cash]
        error('You do not have enough cash left for your current bet amount, please choose another amount, or begin a new game.')
        redirect '/bet'
      end

      session[:player_cash] -= session[:player_bet]

      # Initial Deal
      2.times { deal_card(session[:player_cards], session[:deck]); deal_card(session[:dealer_cards], session[:deck]); }

      session[:initializing] = false
    end

    if (get_card_total(session[:player_cards]) >= 21 || get_card_total(session[:dealer_cards]) >= 21) && session[:running]
      check_for_outcome
      session[:running] = false
    end

  end

end

get '/' do
  redirect '/new_game' if (session[:player_name] == nil || session[:player_name] == '')
  redirect '/bet' if session[:player_bet] <= 0
  redirect '/game_over' if session[:player_cash] <= 0

  run_game

  erb :index
end

get '/new_game' do
  session[:initializing] = true
  session[:running] = true
  session[:player_name] = nil
  session[:player_cash] = 500.0
  session[:player_bet] = 0
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:deck] = []
  redirect '/set_name'
end

get '/deal' do
  session[:initializing] = true
  session[:running] = true
  redirect '/'
end

get '/bet' do
  session[:player_bet] = 0.0
  erb :bet
end

get '/game_over' do
  erb :game_over
end

get '/quit' do
  erb :quit
end

get '/hit' do
  if session[:running]
    deal_card(session[:player_cards], session[:deck])
  end
  redirect '/'
end

get '/stay' do
  deal_card(session[:dealer_cards], session[:deck]) until get_card_total(session[:dealer_cards]) >= 17
  check_for_outcome
  session[:running] = false
  redirect '/'
end

post '/bet' do
  amount = params[:player_bet].strip.to_f
  error('You must enter a positive bet amount. (> 0.01)') if amount < 0.01
  error("You must enter a valid bet amount (0.01 - #{session[:player_cash]})") if amount == 0 || amount > session[:player_cash]
  if amount > 0.01 && amount <= session[:player_cash]
    session[:player_bet] = amount
  end
  redirect '/deal'
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  name = params[:player_name].strip.to_s
  if name == ''
    error('Please provide a name before continuing.')
  else
    victory_message("Hi, #{name}! We've started you off with $#{session[:player_cash]}0 to start, good luck, and have fun!")
  end
  session[:player_name] = name
  redirect '/'
end