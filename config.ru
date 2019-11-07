# frozen_string_literal: true

require File.expand_path 'app.rb', __dir__

Rack::Handler::Thin.run Rack::URLMap.new(
  '/api' => API
)
