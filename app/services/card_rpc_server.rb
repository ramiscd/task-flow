require 'bunny'
require 'json' # Adicione esta linha para carregar a biblioteca JSON

class CardRPCServer
  def initialize
    @connection = Bunny.new
    @connection.start
    @channel = @connection.create_channel
    @queue = @channel.queue("rpc_card_queue")

    puts "[*] Waiting for RPC requests..."

    subscribe_to_queue
  end

  def subscribe_to_queue
    @queue.subscribe(block: true) do |delivery_info, properties, payload|
      response = process_request(JSON.parse(payload)) # Certifique-se de que 'JSON' está disponível aqui

      @channel.default_exchange.publish(
        response.to_json,
        routing_key: properties.reply_to,
        correlation_id: properties.correlation_id
      )
    end
  end

  def process_request(payload)
    # Processar a solicitação aqui e gerar a resposta adequada
    { status: "success", message: "Card #{payload['card_id']} moved to list #{payload['new_list_id']}" }
  end
end

CardRPCServer.new
