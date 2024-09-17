class HomeController < ApplicationController
  def index
    @lists = List.all
    @cards = Card.all
  end
end
