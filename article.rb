require 'bundler/setup'
require 'sqlite3'
require 'lotus/model'
require 'lotus/model/adapters/sql_adapter'

connection_uri = "sqlite://#{ __dir__ }/articles.db"

database = Sequel.connect(connection_uri)

database.create_table! :authors do 
  primary_key :id
  String :name
end

database.create_table! :articles do
  primary_key :id
  Integer :author_id, null: false
  String :title
  Integer :comments_count, default: 0
  Boolean :published, default: false
end

class Author
  include Lotus::Entity
  attributes :name
end

class Article
  include Lotus::Entity
  attributes :author_id, :title, :comments_count, :published

  def published?
    !!published
  end

  def publish!
    @published = true
  end
end

class AuthorRepository
  include Lotus::Repository
end

class ArticleRepository
  include Lotus::Repository
  def self.most_recent_by_author(author, limit = 8)
    query do
      where(author_id: author.id).
        desc(:id).
        limit(limit)
    end
  end

  def self.most_recent_published_by_author(author, limit = 8)
    most_recent_by_author(author, limit).published
  end

  def self.published
    query do
      where(published: true)
    end
  end

  def self.drafts
    exclude published
  end

  def self.rank
    published.desc(:comments_count)
  end

  def self.best_article_ever
    rank.limit(1).first
  end

  def self.comments_average
    query.average(:comments_count)
  end
end

Lotus::Model.configure do
  adapter type: :sql, uri: connection_uri
  mapping do
    collection :authors do
      entity Author
      repository AuthorRepository

      attribute :id, Integer
      attribute :name, String
    end

    collection :articles do
      entity Article
      repository ArticleRepository

      attribute :id, Integer
      attribute :author_id, Integer
      attribute :title, String
      attribute :comments_count, Integer
      attribute :published, Boolean
    end
  end
end.load!

author = Author.new(name: 'Luca')
author = AuthorRepository.create(author)

articles = [
  Article.new(title: 'Announcing Lotus', author_id: author.id, comments_count: 123, published: true),
  Article.new(title: 'Introducing Lotus::Router', author_id: author.id, comments_count: 63,  published: true),
  Article.new(title: 'Introducing Lotus::Controller', author_id: author.id, comments_count: 82,  published: true),
  Article.new(title: 'Introducing Lotus::Model', author_id: author.id)
]

articles.each do |article|
  ArticleRepository.create(article)
end

puts ArticleRepository.first  
puts ArticleRepository.last 

puts ArticleRepository.drafts

puts ArticleRepository.rank
puts ArticleRepository.best_article_ever 

puts ArticleRepository.comments_average
puts ArticleRepository.most_recent_by_author(author)
puts ArticleRepository.most_recent_published_by_author(author)
