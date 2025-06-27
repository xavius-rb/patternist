# frozen_string_literal: true

# Dummy resource class Activemodel for testing
class Post
  attr_accessor :id

  def initialize(id: nil)
    @id = id
  end

  def self.all
    %w[post1 post2 post3]
  end

  def self.find(id)
    Post.new(id: id)
  end

  def self.name
    'Post'
  end

  def self.model_name
    OpenStruct.new(human: 'Post')
  end
end
