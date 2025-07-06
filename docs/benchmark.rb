# frozen_string_literal: true

require 'benchmark'
require 'memory_profiler'
require_relative 'lib/patternist'

# Performance benchmarking script for Patternist modules
class PatternistBenchmark
  def self.run_all_benchmarks
    puts "=== Patternist Performance Benchmarks ==="
    puts "Ruby version: #{RUBY_VERSION}"
    puts "Ruby engine: #{RUBY_ENGINE}"
    puts

    memory_benchmark
    speed_benchmark
    allocation_benchmark
  end

  def self.memory_benchmark
    puts "=== Memory Usage Analysis ==="
    
    report = MemoryProfiler.report do
      controller_class = create_test_controller
      100.times do
        controller = controller_class.new
        controller.index
        controller.show
        controller.new
      end
    end

    puts "Total allocated: #{report.total_allocated} objects"
    puts "Total retained: #{report.total_retained} objects"
    puts "Allocated memory: #{report.total_allocated_memsize} bytes"
    puts "Retained memory: #{report.total_retained_memsize} bytes"
    puts

    # Top allocations
    puts "Top 5 allocated object types:"
    report.allocated_memory_by_class.first(5).each do |klass, size|
      puts "  #{klass}: #{size} bytes"
    end
    puts
  end

  def self.speed_benchmark
    puts "=== Speed Benchmarks ==="
    
    controller_class = create_test_controller
    
    Benchmark.bm(30) do |x|
      x.report("Controller instantiation:") do
        1000.times { controller_class.new }
      end

      controller = controller_class.new
      
      x.report("resource_class (cached):") do
        1000.times { controller.resource_class }
      end

      x.report("resource_name (cached):") do
        1000.times { controller.resource_name }
      end

      x.report("collection_name:") do
        1000.times { controller.collection_name }
      end

      x.report("instance_variable access:") do
        1000.times { controller.resource }
      end

      x.report("index action:") do
        1000.times { controller.index }
      end

      x.report("show action:") do
        1000.times do
          controller.params = { id: 1 }
          controller.show
        end
      end

      x.report("create action:") do
        1000.times do
          controller.params = { post: { title: 'Test', body: 'Content' } }
          controller.create
        rescue StandardError
          # Expected for this benchmark
        end
      end
    end
    puts
  end

  def self.allocation_benchmark
    puts "=== Object Allocation Analysis ==="
    
    controller_class = create_test_controller
    
    # Test resource_class method allocation
    puts "resource_class method allocations:"
    result = ObjectSpace.each_object(String).count
    controller = controller_class.new
    100.times { controller.resource_class }
    new_result = ObjectSpace.each_object(String).count
    puts "  String objects created: #{new_result - result}"

    # Test collection_name method allocation
    puts "collection_name method allocations:"
    result = ObjectSpace.each_object(String).count
    100.times { controller.collection_name }
    new_result = ObjectSpace.each_object(String).count
    puts "  String objects created: #{new_result - result}"
    
    puts
  end

  def self.create_test_controller
    # Create a mock Post class
    post_class = Class.new do
      attr_accessor :id, :title, :body, :errors
      
      def self.name
        'Post'
      end
      
      def self.all
        %w[post1 post2 post3]
      end
      
      def self.find(id)
        new.tap { |p| p.id = id }
      end
      
      def initialize(attrs = {})
        @title = attrs[:title]
        @body = attrs[:body]
        @errors = []
      end
      
      def save
        true
      end
      
      def update(attrs)
        @title = attrs[:title] if attrs[:title]
        @body = attrs[:body] if attrs[:body]
        true
      end
      
      def destroy
        true
      end
    end
    
    Object.const_set('Post', post_class) unless Object.const_defined?('Post')
    
    # Create test controller
    Class.new do
      include Patternist::Controller
      
      attr_accessor :params
      
      def initialize
        @params = {}
      end
      
      def self.name
        'PostsController'
      end
      
      def respond_to
        yield(format_mock)
      end
      
      def redirect_to(resource, options = {})
        # Mock redirect
      end
      
      def render(template, options = {})
        # Mock render
      end
      
      private
      
      def resource_params
        params.require(:post).permit(:title, :body)
      rescue StandardError
        {}
      end
      
      def format_mock
        @format_mock ||= Class.new do
          def html
            yield if block_given?
          end
          
          def json
            yield if block_given?
          end
        end.new
      end
    end
  end
end

# Add memory profiler dependency check
begin
  require 'memory_profiler'
rescue LoadError
  puts "Installing memory_profiler gem for benchmarking..."
  system('gem install memory_profiler')
  require 'memory_profiler'
end

# Run benchmarks if this file is executed directly
if __FILE__ == $0
  PatternistBenchmark.run_all_benchmarks
end
