json.extract! board, :id, :name, :date_created, :user_id, :created_at, :updated_at
json.url board_url(board, format: :json)
