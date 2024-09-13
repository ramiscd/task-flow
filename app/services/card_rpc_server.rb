require 'buuny'

class CardRPCServer

  def initialize
    connection = Bunny.new
    connection.start

    channel = connection.create_channel
    queue = channel.queue('rpc_card_queue')

    puts '[*] Waiting for RPC requests...'

    queue.subscribe(block: true) do |delivery_info, properties, payload|
      card_data = JSON.parse(payload)
      response = move_card(card_data['card_id'], card_data['new_list_id'])

      channel.default_exchange.publish(
        response.to_json,
        routing_key: properties.reply_to,
        correlation_id: properties.correlation_id
      )
    end
  end

  def move_card(card_id, new_list_id)
    card = Card.find(card_id)
    card.update(list_id: new_list_id)
    { status: 'success', card: card }
  rescue => e
    { status: 'error', message: e.message}
  end
end