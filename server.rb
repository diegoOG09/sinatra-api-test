require 'sinatra'
require 'sinatra/cors'
require 'mongoid'
require 'sinatra/namespace'

# DB setup
Mongoid.load! "mongoid.config"

set :allow_origin, "http://127.0.0.1:5500 http://localhost:4567/api/v1/books"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type,acces-control-allow-origin"
set :expose_headers, "location,link"

# Models
class Book
  include Mongoid::Document

  field :title, type: String
  field :author, type: String
  field :isbn, type: String
  field :image, type: String

  validates :title, presence: true
  validates :author, presence: true
  validates :isbn, presence: true
  validates :image, presence: true

  index({ title: 'text' })
  index({ isbn:1 }, { unique: true, name: "isbn_index" })

  scope :title, -> (title) { where(title: /^#{title}/) }
  scope :isbn, -> (isbn) { where(isbn: isbn)  }
  scope :author, -> (author) { where(author: author) }
  scope :image, -> (image) { where(image: image) }
end

class Movie
  include Mongoid::Document

  field :title, type: String
  field :director, type: String
  field :image, type: String
  field :rating, type: Numeric

  validates :title, presence: true
  validates :director, presence: true
  validates :image, presence: true
  validates :rating, presence: true

  index({ title: 'text' })

  scope :title, -> (title) { where(title: /^#{title}/) }
  scope :director, -> (director) { where(director: director) }
  scope :image, -> (image) { where(image: image) }
  scope :rating, -> (rating) { where(rating: rating) }
end

class Show
  include Mongoid::Document

  field :title, type: String
  field :director, type: String
  field :image, type: String
  field :rating, type: Numeric

  validates :title, presence: true
  validates :director, presence: true
  validates :image, presence: true
  validates :rating, presence: true

  index({ title: 'text' })

  scope :title, -> (title) { where(title: /^#{title}/) }
  scope :director, -> (director) { where(director: director) }
  scope :image, -> (image) { where(image: image) }
  scope :rating, -> (rating) { where(rating: rating) }
end

# Serializers
class BookSerializer
  def initialize(book)
    @book = book
  end

  def as_json(*)
    data = {
      id: @book.id.to_s,
      title: @book.title,
      author: @book.author,
      isbn: @book.isbn,
      image: @book.image
    }
    data[:errors] = @book.errors if@book.errors.any?
    data
  end
end

class MovieSerializer
  def initialize(movie)
    @movie = movie
  end

  def as_json(*)
    data = {
      id: @movie.id.to_s,
      title: @movie.title,
      director: @movie.director,
      image: @movie.image
    }
    data[:errors] = @movie.errors if@movie.errors.any?
    data
  end
end

class ShowSerializer
  def initialize(movie)
    @show = movie
  end

  def as_json(*)
    data = {
      id: @movie.id.to_s,
      title: @movie.title,
      director: @movie.director,
      image: @movie.image
    }
    data[:errors] = @show.errors if@show.errors.any?
    data
  end
end

# Endpoints
get '/' do
  'Welcome to my favorites books, movies and shows'
end

namespace '/api/v1' do

  before do
    content_type 'application/json'
  end

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
    end

    def json_params
      begin
        JSON.parse(request.body.read)
      rescue
        halt 400, { message:'Invalid JSON' }.to_json
      end
    end

    def book
      @book ||= Book.where(id: params[:id].first)
    end

    def movie
      @movie ||= Movie.where(id: params[:id].first)
    end

    def show
      @show ||= Show.where(id: params[:id].first)
    end

    def halt_if_not_found!
      halt(404, { message: 'Item not found' }.to_json) unless book
    end

    def halt_if_not_found_movie!
      halt(404, { message: 'Movie not found'  }.to_json) unless movie
    end

    def halt_if_not_found_show!
      halt(404, { message: 'Show not found' }.to_json) unless show
    end

    def serialize(book)
      BookSerializer.new(book).to_json
    end

    def serialize_movie(movie)
      MovieSerializer.new(movie).to_json
    end

    def serialize_show(movie)
      ShowSerializer.new(show).to_json
    end
  end

  # Books
  get '/books' do
    books = Book.all
    [:title, :isbn, :author].each do |filter|
      books = books.send(filter, params[filter]) if params[filter]
    end

    books.map { |book| BookSerializer.new(book)  }.to_json
  end

  # GET
  get '/books/:id' do |id|
    halt_if_not_found!
    serialize(book)
  end

  # POST
  post '/books' do
    book = Book.new(json_params)
    halt 422, serialize(book) unless book.save
    response.headers['Location'] = "#{base_url}/api/v1/books/#{book.id}"
    status 201
  end

  # PATCH
  patch '/books/:id' do |id|
    halt_if_not_found!
    halt 422, serialize(book) unless book.update_attributes(json_params)
    serialize(book)
  end

  # DELETE
  delete '/books/:id' do |id|
    book.destroy if book
    status 204
  end

  # Movies
  get '/movies' do
    'Welcome to movies list'
    movies = Movie.all
    [:title, :director, :platform].each do |filter|
      movies = movies.send(filter, params[filter]) if params[filter]
    end

    movies.map { |book| MovieSerializer.new(movie) }.to_json
  end

  get '/movies/:id' do |id|
    halt_if_not_found_movie!
    serialize(movie)
  end

  post '/movies' do |id|
    movie = Movie.new(json_params)
    halt 422, serialize(movie) unless movie.save
    response.headers['Location'] = "#{base_url}/api/v1/movies/#{movie.id}"
    status 201
  end

  patch '/movies/:id' do |id|
    halt_if_not_found_movie!
    halt 422, serialize(movie) unless movie.update_attributes(json_params)
    serialize(movie)
  end

  delete '/movies/:id' do |id|
    movie.destroy if movie
    status 404
  end

  # Shows
  get '/shows' do
    'Welcome to Show list'
    shows = Show.all
    [:title, :director, :platform].each do |filter|
      shows = shows.send(filter, params[filter]) if params[filters]
    end

    shows.map { |book| ShowSerializer.new(show) }.to_json
  end

  get '/shows/:id' do |id|
    halt_if_not_found_show!
    serialize(show)
  end

  post '/shows' do |id|
    show = Show.new(json_params)
    halt 422, serialize(show) unless show.save
    response.headers['Location'] = "#{base_url}/api/v1/shows/#{show.id}"
    status 201
  end

  patch '/shows/:id' do |id|
    halt_if_not_found_show!
    halt 422, serialize(show) unless show.update_attributes(json_params)
    serialize(show)
  end

  delete '/shows/:id' do |id|
    show.destroy if show
    status 404
  end

end

