require 'bunny'

class CardsController < ApplicationController
  before_action :set_card, only: %i[ show edit update destroy ]

  # GET /cards or /cards.json
  def index
    @cards = Card.all
  end

  # GET /cards/1 or /cards/1.json
  def show
  end

  # GET /cards/new
  def new
    @card = Card.new
  end

  # GET /cards/1/edit
  def edit
  end

  # POST /cards or /cards.json
  def create
    @card = Card.new(card_params)

    respond_to do |format|
      if @card.save
        format.html { redirect_to card_url(@card), notice: "Card was successfully created." }
        format.json { render :show, status: :created, location: @card }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @card.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cards/1 or /cards/1.json
  def update
    respond_to do |format|
      if @card.update(card_params)
        format.html { redirect_to card_url(@card), notice: "Card was successfully updated." }
        format.json { render :show, status: :ok, location: @card }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @card.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cards/1 or /cards/1.json
  def destroy
    @card.destroy!

    respond_to do |format|
      format.html { redirect_to cards_url, notice: "Card was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def move
    card_id = params[:card_id]
    new_list_id = params[:list_id]

    response = call_rpc(card_id, new_list_id)

    if response['status'] == 'success'
      render json: { status: 'Card moved successfully' }, status: :ok
    else
      render json: { error: response['message'] }, status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_card
      @card = Card.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def card_params
      params.require(:card).permit(:title, :description, :priority, :user_id, :list_id)
    end

    def call_rpc
      connection = Bunny.new
      connection.start

      channel = connection.create_channel
      queue = channel.queue('', exclusive: true)

      correlation_id = SecureRandom.uuid

      exchange = channel.default_exchange
      exchange.publish(
        { card_id: card_id, new_list_id: new_list_id }.json,
        routing_key: 'rpc_card_queue',
        reply_to: queue.name,
        correlation_id: correlation_id
      )

      response = nil

      queue.subscribe(block: true) do |delivery_info, properties ,payload|
        if properties.correlation_id == correlation_id
          response = JSON.parse(payload)
          break
        end
      end

      connection.close
      response
    end
end
