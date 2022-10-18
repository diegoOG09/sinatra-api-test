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

# Endpoints
get '/' do
  'Welcome to Booklist!'
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

    def halt_if_not_found!
      halt(404, { message: 'Book Not Found' }.to_json) unless book
    end

    def serialize(book)
      BookSerializer.new(book).to_json
    end
  end

  get '/books' do
    books = Book.all
    [:title, :isbn, :author].each do |filter|
      books = books.send(filter, params[filter]) if params[filter]
    end

    books.map { |book| BookSerializer.new(book)  }.to_json
  end

  get '/books/:id' do |id|
    halt_if_not_found!
    serialize(book)
  end

  post '/books' do
    book = Book.new(json_params)
    halt 422, serialize(book) unless book.save
    response.headers['Location'] = "#{base_url}/api/v1/books/#{book.id}"
    status 201
  end

  patch '/books/:id' do |id|
    halt_if_not_found!
    halt 422, serialize(book) unless book.update_attributes(json_params)
    serialize(book)
  end

  delete '/books/:id' do |id|
    book.destroy if book
    status 204
  end

  get '/movies' do
    movies = Movie.all
    [:title, :director, :platform].each do |filter|
      movies = movies.send(filter, params[filter]) if params[filter]
    end
  end

end

