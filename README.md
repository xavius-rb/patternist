# Patternist

[![Ruby](https://github.com/xavius-rb/patternist/actions/workflows/main.yml/badge.svg)](https://github.com/xavius-rb/patternist/actions/workflows/main.yml)
[![Gem Version](https://badge.fury.io/rb/patternist.svg)](https://badge.fury.io/rb/patternist)

Patternist is a Ruby gem that provides reusable utilities and patterns for Ruby and Rails applications. It offers a collection of modules designed to reduce boilerplate code and standardize and protect common patterns.

## Features

- **Controller Helpers**: Automatic resource inference and naming conventions
- **RESTful Actions**: Complete CRUD operations with minimal configuration
- **Response Handling**: Unified response formatting for HTML and JSON
- **Rails Integration**: Seamless integration with Rails applications
- **Error Handling**: Comprehensive error handling with custom exceptions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'patternist'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install patternist
```

## Usage

### RESTful Controller

The `Patternist::Controller` module provides complete CRUD operations:

```ruby
class PostsController < ApplicationController
  include Patternist::Controller

  private

  def resource_params
    params.require(:post).permit(:title, :body)
  end
end
```

This automatically provides all standard RESTful actions:
- `index` - Lists all resources
- `show` - Shows a single resource
- `new` - Prepares a new resource
- `create` - Creates a new resource
- `edit` - Prepares a resource for editing
- `update` - Updates an existing resource
- `destroy` - Destroys a resource

### Controller Helpers

The `Patternist::Controllers::ActionPack::Helpers` module provides automatic resource inference and helper methods for controllers:

```ruby
class PostsController < ApplicationController
  include Patternist::Controllers::ActionPack::Helpers

  def index
    # Automatically infers @posts from controller name
    set_collection_instance(Post.all)
  end

  def show
    # Automatically infers @post from controller name
    set_resource_instance(Post.find(params[:id]))
  end
end
```

### Helper Methods

The helpers module provides several useful methods:

- `resource_class` - Inferred model class (e.g., `Post` for `PostsController`)
- `resource_name` - Underscored resource name (e.g., `"post"`)
- `resource_class_name` - Human-readable resource name (e.g., `"Post"`)
- `collection_name` - Pluralized resource name (e.g., `"posts"`)
- `instance_variable_name` - Instance variable name for a resource
- `resource` - Get the resource instance variable
- `id_param` - Get the ID parameter from params


### Response Handling

The `Patternist::Controllers::ActionPack::ResponseHandling` module provides unified response formatting:

```ruby
class PostsController < ApplicationController
  include Patternist::Controllers::ActionPack::ResponseHandling

  def create
    @post = Post.new(post_params)

    format_response(@post,
                    notice: "Post created successfully",
                    status: :created,
                    on_error_render: :new) do
      @post.save
    end
  end
end
```

#### Custom Response Formats

You can customize response handling with custom format handlers:

```ruby
format_response(@post,
                notice: "Success",
                status: :ok,
                on_error_render: :edit,
                formats: {
                  html: -> { redirect_to custom_path },
                  json: -> { render json: custom_serializer(@post) },
                  error_html: -> { render :custom_error },
                  error_json: -> { render json: { error: "Custom error" } }
                }) do
  @post.update(post_params)
end
```


## API Reference

### Patternist::Controllers::ActionPack::Helpers

Provides helper methods for resource handling and naming conventions.

**Class Methods:**
- `resource_class` - Returns the inferred resource class
- `resource_name` - Returns the underscored resource name

**Instance Methods:**
- `resource_class` - Returns the resource class
- `resource_name` - Returns the resource name
- `resource_class_name` - Returns the human-readable resource name
- `collection_name` - Returns the pluralized resource name
- `instance_variable_name(name)` - Returns instance variable name
- `resource` - Returns the resource instance
- `id_param` - Returns the ID parameter
- `set_collection_instance(value)` - Sets the collection instance variable
- `set_resource_instance(value)` - Sets the resource instance variable

### Patternist::Controllers::ActionPack::Restful

Provides standard RESTful actions for controllers.

**Actions:**
- `index` - Lists all resources
- `show` - Shows a single resource
- `new` - Prepares a new resource
- `create` - Creates a new resource
- `edit` - Prepares a resource for editing
- `update` - Updates an existing resource
- `destroy` - Destroys a resource

**Required Methods:**
- `resource_params` - Must be implemented to define permitted parameters

### Patternist::Controllers::ActionPack::ResponseHandling

Provides unified response formatting for different formats.

**Methods:**
- `format_response(resource, notice:, status:, on_error_render:, formats: {}, &block)` - Handles response formatting

## Requirements

- Ruby >= 3.1.0
- ActionPack >= 4.0 (for Rails integration)


## Examples

### Basic Usage with All Features

```ruby
class PostsController < ApplicationController
  include Patternist::Controller

  # All RESTful actions are automatically provided

  private

  def resource_params
    params.require(:post).permit(:title, :body, :published)
  end

  # Optional: Override collection for custom scoping
  def collection
    current_user.posts.published.includes(:author)
  end
end
```

### Custom Namespace Handling

```ruby
class Admin::PostsController < ApplicationController
  include Patternist::Controller

  # Automatically infers Post class from Admin::PostsController

  private

  def resource_params
    params.require(:post).permit(:title, :body, :featured)
  end
end
```

### API Controller with Custom Responses

```ruby
class Api::V1::PostsController < ApplicationController
  include Patternist::Controller

  def create
    set_resource_instance(resource_class.new(resource_params))

    format_response(resource,
                    notice: "Post created successfully",
                    status: :created,
                    on_error_render: :new,
                    formats: {
                      json: -> { render json: resource, serializer: PostSerializer },
                      error_json: -> { render json: { errors: resource.errors.full_messages } }
                    }) do
      resource.save
    end
  end

  private

  def resource_params
    params.require(:post).permit(:title, :body)
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version, update the version number in `version.rb`, update the CHANGELOG.md, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Testing

Run the test suite with:

```bash
bundle exec rspec
```

### Code Quality

The project follows standard Ruby conventions and uses RSpec for testing.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/xavius-rb/patternist. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/xavius-rb/patternist/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Patternist project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/xavius-rb/patternist/blob/main/CODE_OF_CONDUCT.md).
