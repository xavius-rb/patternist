# Patternist AI Coding Agent Instructions

## Project Overview
Rails controller pattern library (Ruby gem) providing RESTful CRUD via mixins. Core: `Patternist::Controller` module includes `Helpers`, `ResponseHandling`, and `Restful`.

## Architecture

### Module Hierarchy
- `Patternist::Controller` → includes `Controllers::ActionPack::Restful`
- `Restful` → includes `Helpers` + `ResponseHandling` + `InstanceMethods` (CRUD actions)
- **Automatic resource inference**: `PostsController` → `Post` class via `infer_resource_class` (strips "Controller", handles namespaces with `::`)

### Key Components
- **Helpers** ([lib/patternist/controllers/actionpack/helpers.rb](lib/patternist/controllers/actionpack/helpers.rb)): Resource naming (`resource_class`, `resource_name`, `collection_name`), caching via instance vars (`@resource_class ||= ...`)
- **ResponseHandling** ([lib/patternist/controllers/actionpack/response_handling.rb](lib/patternist/controllers/actionpack/response_handling.rb)): `format_response` method with block-based success/failure, HTML/JSON duality
- **Restful** ([lib/patternist/controllers/actionpack/restful.rb](lib/patternist/controllers/actionpack/restful.rb)): 7 RESTful actions (index, show, new, edit, create, update, destroy)

## Development Workflows

**Setup**: `bundle install`
**Test**: `bundle exec rake spec` (runs RSpec + SimpleCov coverage → [coverage/index.html](coverage/index.html))
**Lint**: `bundle exec rubocop` (includes `rubocop-rspec` plugin)
**Default task**: `rake` = spec + rubocop

## Testing Conventions

**Location**: [spec/patternist/](spec/patternist/) mirrors [lib/patternist/](lib/patternist/) structure
**Pattern**: Use dummy controller classes with `Class.new { include Patternist::... }` (see [spec/patternist/controller_spec.rb](spec/patternist/controller_spec.rb))
**Stubs**: Mock `Post` class with `stub_const`, fake `respond_to` with format stubs
**Critical**: Test both success/failure paths for `format_response` blocks

## Code Patterns

### String Optimization (from [docs/PERFORMANCE_ASSESSMENT.md](docs/PERFORMANCE_ASSESSMENT.md))
```ruby
# GOOD: Use constants + slicing (current pattern)
CONTROLLER_SUFFIX = 'Controller'
name.end_with?(CONTROLLER_SUFFIX) ? name[0...-CONTROLLER_SUFFIX.length] : name

# AVOID: Regex/gsub/split (creates temp objects)
name.gsub(/Controller$/, '').split('::')
```

### Memoization (everywhere)
```ruby
def resource_class = @resource_class ||= self.class.resource_class
```

### Required Method Contract
Controllers **must** define `resource_params` (raises `NotImplementedError` otherwise):
```ruby
def resource_params
  params.require(:post).permit(:title, :body)
end
```

### CustomizationsOverride `resource_location` for custom redirects (default: returns resource itself)
Override `build_resource` for custom initialization (default: `resource_class.new`)

## Error Handling
- `Patternist::NameError`: Resource class inference fails (namespace in [lib/patternist.rb](lib/patternist.rb))
- `Patternist::NotImplementedError`: Missing `resource_params` definition

## Dependencies
- ActionPack >= 5.0, < 9.0 (only external dependency)
- Ruby >= 3.1.0
- CI tests Ruby 3.1, 3.2, 3.3, 3.4

## Module Inclusion Side Effects
Including `Patternist::Controller` automatically:
1. Calls `self.included(base)` hooks down the chain
2. Adds ClassMethods (`.resource_class`, `.resource_name`) via `extend`
3. Adds InstanceMethods (all CRUD actions + helpers)
