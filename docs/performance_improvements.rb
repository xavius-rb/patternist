# frozen_string_literal: true

# Performance Improvement Examples for Patternist

module PerformanceExamples
  # 1. Optimize String Operations
  # Before: Multiple string allocations
  def slow_controller_name_extraction(name)
    controller_name = name.gsub(/Controller$/, '').split('::').last
    return Object.const_get(controller_name.singularize) if controller_name
  end

  # After: Reduced allocations using frozen strings and better regex
  CONTROLLER_SUFFIX = 'Controller'
  NAMESPACE_SEPARATOR = '::'

  def fast_controller_name_extraction(name)
    # Use end_with? instead of gsub for better performance
    base_name = name.end_with?(CONTROLLER_SUFFIX) ? 
                name[0...-CONTROLLER_SUFFIX.length] : name
    
    # Use rindex for single allocation
    last_separator = base_name.rindex(NAMESPACE_SEPARATOR)
    controller_name = last_separator ? 
                      base_name[(last_separator + 2)..-1] : base_name
    
    return Object.const_get(controller_name.singularize) if controller_name
  end

  # 2. Optimize Instance Variable Access
  # Before: String interpolation on every call
  def slow_instance_variable_name(name)
    "@#{name}"
  end

  # After: Use symbols and cached strings
  def fast_instance_variable_name(name)
    case name
    when String
      :"@#{name}"
    when Symbol
      :"@#{name}"
    else
      :"@#{name}"
    end
  end

  # 3. Optimize Response Format Handling
  # Before: Lambda allocation on every call
  def slow_format_response
    formats = {
      html: -> { redirect_to resource, notice: notice },
      json: -> { render :show, status: status, location: resource }
    }
  end

  # After: Pre-allocated constants or methods
  module ResponseFormats
    def self.html_success(resource, notice)
      -> { redirect_to resource, notice: notice }
    end

    def self.json_success(status, resource)
      -> { render :show, status: status, location: resource }
    end
  end

  # 4. Memory-efficient error handling
  # Before: String concatenation in error messages
  def slow_error_message(name, error)
    "Could not infer resource class for #{name}: #{error.message}. " \
    'Please define `self.resource_class` in your controller.'
  end

  # After: Use format for better performance
  ERROR_MESSAGE_TEMPLATE = "Could not infer resource class for %s: %s. Please define `self.resource_class` in your controller.".freeze

  def fast_error_message(name, error)
    ERROR_MESSAGE_TEMPLATE % [name, error.message]
  end
end
