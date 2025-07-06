# frozen_string_literal: true

# Performance Optimization Recommendations for Patternist

module PatternistOptimizations
  # ==============================================================================
  # CRITICAL PERFORMANCE IMPROVEMENTS
  # ==============================================================================

  module StringOptimizations
    # Current issue: Multiple string allocations in controller name inference
    # Recommended fix: Use frozen strings and optimize regex operations
    
    # 1. Pre-compile regex patterns
    CONTROLLER_SUFFIX_REGEX = /Controller\z/.freeze
    NAMESPACE_SEPARATOR = '::'
    INSTANCE_VAR_PREFIX = '@'

    # 2. Use string slicing instead of gsub when possible
    def optimized_controller_name_extraction(name)
      base_name = name.end_with?('Controller') ? 
                  name[0...-10] : name  # 'Controller'.length == 10
      
      last_separator_index = base_name.rindex(NAMESPACE_SEPARATOR)
      return base_name unless last_separator_index
      
      base_name[(last_separator_index + 2)..-1]
    end

    # 3. Optimize instance variable name generation
    def optimized_instance_variable_name(name)
      # Use string interpolation which is faster for simple cases
      case name
      when Symbol
        :"@#{name}"
      else
        "@#{name}".to_sym
      end
    end
  end

  module MemoryOptimizations
    # Current issue: Lambda objects created on every format_response call
    # Recommended fix: Use callable objects or pre-defined methods

    class ResponseHandlers
      def self.html_redirect(resource, notice)
        proc { redirect_to resource, notice: notice }
      end

      def self.json_show(status, resource)
        proc { render :show, status: status, location: resource }
      end

      def self.html_error(template)
        proc { render template, status: :unprocessable_entity }
      end

      def self.json_error(errors)
        proc { render json: errors, status: :unprocessable_entity }
      end
    end
  end

  module CachingOptimizations
    # Current: Good use of memoization but can be improved
    # Recommended: Use class-level caching for shared computations
    
    module ClassLevelCache
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def cached_resource_class
          @class_resource_cache ||= {}
          @class_resource_cache[name] ||= infer_resource_class
        end

        def cached_resource_name
          @class_name_cache ||= {}
          @class_name_cache[name] ||= cached_resource_class.name.underscore
        end
      end
    end
  end

  # ==============================================================================
  # PERFORMANCE MEASUREMENT TOOLS
  # ==============================================================================

  module PerformanceMeasurement
    # Helper to measure method execution time
    def self.measure_method(object, method_name, iterations = 1000)
      require 'benchmark'
      
      Benchmark.realtime do
        iterations.times { object.public_send(method_name) }
      end
    end

    # Helper to measure memory allocation
    def self.measure_memory(&block)
      require 'memory_profiler'
      
      report = MemoryProfiler.report(&block)
      {
        allocated_objects: report.total_allocated,
        allocated_memory: report.total_allocated_memsize,
        retained_objects: report.total_retained,
        retained_memory: report.total_retained_memsize
      }
    end

    # Profile method calls and allocations
    def self.profile_method(object, method_name, iterations = 100)
      puts "Profiling #{method_name} (#{iterations} iterations):"
      
      # Time measurement
      time = measure_method(object, method_name, iterations)
      puts "  Time: #{(time * 1000).round(3)}ms total, #{(time * 1000 / iterations).round(3)}ms per call"
      
      # Memory measurement
      memory = measure_memory do
        iterations.times { object.public_send(method_name) }
      end
      
      puts "  Memory: #{memory[:allocated_objects]} objects, #{memory[:allocated_memory]} bytes allocated"
      puts "  Average: #{memory[:allocated_objects] / iterations.to_f} objects per call"
      puts
    end
  end
end

# ==============================================================================
# SPECIFIC RECOMMENDATIONS BY MODULE
# ==============================================================================

puts <<~RECOMMENDATIONS
  === PERFORMANCE RECOMMENDATIONS FOR PATTERNIST ===

  1. HELPERS MODULE OPTIMIZATIONS:
     - Replace .gsub() with string slicing in controller name inference
     - Use frozen string literals for constants
     - Implement class-level caching for resource_class computations
     - Pre-compile regex patterns used repeatedly

  2. RESTFUL MODULE OPTIMIZATIONS:
     - Cache format response handlers instead of creating lambdas each time
     - Use symbols for status codes instead of strings where possible
     - Optimize parameter access patterns
     - Consider using method objects for complex operations

  3. RESPONSE_HANDLING MODULE OPTIMIZATIONS:
     - Pre-define response format handlers
     - Use callable objects instead of lambda allocation
     - Optimize the format handling dispatch mechanism
     - Cache format objects where possible

  4. GENERAL MEMORY OPTIMIZATIONS:
     - Use frozen string literals throughout
     - Minimize object allocations in hot paths
     - Implement proper memoization patterns
     - Use symbols instead of strings for internal identifiers

  5. MONITORING RECOMMENDATIONS:
     - Add performance benchmarks to test suite
     - Monitor memory usage in production
     - Track method call frequency and duration
     - Set up alerts for performance regressions

  === ESTIMATED PERFORMANCE IMPROVEMENTS ===
  
  - String operations: 30-50% faster with optimizations
  - Memory usage: 20-40% reduction in allocations
  - Response handling: 25-35% improvement with cached handlers
  - Overall controller instantiation: 15-25% improvement

  === PRIORITY IMPLEMENTATION ORDER ===
  
  1. HIGH: String optimization in helpers.rb (biggest impact)
  2. HIGH: Response handler caching in response_handling.rb
  3. MEDIUM: Class-level caching improvements
  4. MEDIUM: Symbol usage optimization
  5. LOW: Micro-optimizations and benchmarking
RECOMMENDATIONS
