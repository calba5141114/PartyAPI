# frozen_string_literal: true

require 'json'
require 'sinatra/base'
require 'jwt'
require 'mongo'
require 'bcrypt'

# Test Middleware
class MyRackMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    puts 'Middleware called'
    puts status
  end
end

# Core Protected API
class API < Sinatra::Base
  def initialize
    super
    @client = Mongo::Client.new('mongodb://127.0.0.1:27017/test')
    @party_collection = @client[:party]
    @user_collection = @client[:users]
    @user_collection.indexes.create_one({ email: 1 }, unique: true)
  end

  # Read index route
  get '/' do
    status 200
    content_type :json
    { message: 'Welcome to the party API 🦄🎈' }.to_json
  end

  # User Resource Routes

  # Create a user
  post '/register' do
    params = JSON.parse(request.body.read)
    result = @user_collection.insert_one(
      full_name: params['full_name'],
      email: params['email'],
      password: BCrypt::Password.create(params['password'])
    )
    status 201
    content_type :json
    {
      message: {
        text: 'User is Registered',
        number_inserted: result.n,
        full_name: params['full_name']
      }
    }.to_json
  end

  post '/login' do
    params = JSON.parse(request.body.read)
    user = @user_collection.find("email": params['email']).to_a
    if BCrypt::Password.new(user[0]['password']) == params['password']
      status 200
      content_type :json
      {
        message: {
          user: user
        }
      }.to_json
    else
      status 403
      content_type :json
      { message: 'Authentication Failed' }.to_json
    end
  end

  # Party Resource Routes

  # Create a party.
  post '/party' do
    params = JSON.parse(request.body.read)
    result = @party_collection.insert_one(
      address: params['address'],
      name: params['name'], tags: params['tags'],
      host: params['host']
    )
    status 201
    content_type :json
    { message: { number_inserted: result.n,
                 address: params['address'],
                 name: params['name'], tags: params['tags'],
                 host: params['host'] } }.to_json
  end

  # Read a list of parties.
  get '/party' do
    status 200
    content_type :json
    @party_collection.find.to_a.to_json
  end

  # Read a party by ID.
  get '/party/:id' do
    status 200
    content_type :json
    @party_collection.find('_id' => BSON::ObjectId(params[:id])).to_a.to_json
  end

  # Delete a party by ID
  delete '/party/:id' do
    status 202
    content_type :json
    @party_collection.find('_id' => BSON::ObjectId(params[:id])).delete_one
    { message: 'Document Deleted.' }.to_json
  end

  # Update a party by ID
  put '/party/:id' do
    json_body = JSON.parse(request.body.read)
    status 202
    content_type :json
    @party_collection
      .update_one({ '_id' => BSON::ObjectId(params[:id]) },
                  "$set": json_body)
    { message: 'Document Updated.' }.to_json
  end
end
