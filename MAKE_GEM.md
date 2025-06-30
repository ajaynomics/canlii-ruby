# CanLII Gem Extraction Plan

## Decisions

1. **Gem name**: `canlii-ruby`
2. **Version**: Start with 0.1.0
3. **Remove entirely**: All caching, retry logic, complex timeouts
4. **Namespace**: Flatten to `CanLII::Case` (not `CanLII::Models::Case`)
5. **Configuration**: Standard `ENV["CANLII_API_KEY"]` fallback
6. **No backwards compatibility**: Rails app adapts to gem
7. **Explicit requires**: No Zeitwerk/autoload
8. **Testing**: Minitest only with WebMock

## File Structure

```
canlii-ruby/
├── lib/
│   ├── canlii.rb                 # Main entry, explicit requires
│   └── canlii/
│       ├── version.rb            
│       ├── configuration.rb      # Simple config object
│       ├── errors.rb             # Move as-is from Rails
│       ├── client.rb             # HTTP client
│       ├── base.rb               # with_client pattern
│       ├── database.rb           # Inherits from Base
│       ├── case.rb               # Inherits from Base
│       └── rails/
│           └── railtie.rb        # Logger integration only
├── test/
│   ├── test_helper.rb
│   ├── canlii/*_test.rb         # Move from Rails
│   └── fixtures/                 # Move JSON fixtures
└── canlii-ruby.gemspec
```

## Implementation Steps

### 1. Create Gem

```bash
bundle gem canlii-ruby --test=minitest --no-exe
cd canlii-ruby
```

### 2. Gemspec

```ruby
# canlii-ruby.gemspec
spec.name          = "canlii-ruby"
spec.version       = CanLII::VERSION
spec.summary       = "Ruby client for the CanLII API"
spec.description   = "A lightweight Ruby client for accessing Canadian legal information via the CanLII API"
spec.authors       = ["Your Name"]
spec.email         = ["your.email@example.com"]
spec.homepage      = "https://github.com/youraccount/canlii-ruby"
spec.license       = "MIT"
spec.required_ruby_version = ">= 3.0.0"

spec.files         = Dir["lib/**/*", "README.md", "LICENSE.txt"]
spec.require_paths = ["lib"]

spec.add_dependency "http", "~> 5.0"
spec.add_dependency "activemodel", ">= 6.0"
spec.add_dependency "activesupport", ">= 6.0"

spec.add_development_dependency "minitest", "~> 5.0"
spec.add_development_dependency "webmock", "~> 3.0"
spec.add_development_dependency "rake", "~> 13.0"
spec.add_development_dependency "rubocop-rails-omakase", "~> 1.0"
```

### 3. Core Files to Create

#### lib/canlii.rb
```ruby
require "active_model"
require "http"
require "json"
require "logger"

require_relative "canlii/version"
require_relative "canlii/errors"
require_relative "canlii/configuration"
require_relative "canlii/client"
require_relative "canlii/base"
require_relative "canlii/database"
require_relative "canlii/case"

module CanLII
  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    
    def configure
      yield(configuration)
    end
    
    def with_language(language)
      old_language = configuration.language
      configuration.language = language
      yield
    ensure
      configuration.language = old_language
    end
  end
end

require_relative "canlii/rails/railtie" if defined?(Rails::Railtie)
```

#### lib/canlii/version.rb
```ruby
module CanLII
  VERSION = "0.1.0"
end
```

#### lib/canlii/configuration.rb
```ruby
module CanLII
  class Configuration
    attr_accessor :api_key, :base_url, :language, :logger
    
    def initialize
      @base_url = "https://api.canlii.org/v1"
      @language = "en"
      @api_key = ENV["CANLII_API_KEY"]
      @logger = Logger.new(STDOUT)
    end
    
    def validate!
      raise Error, "API key is required" if api_key.nil? || api_key.empty?
    end
  end
end
```

#### lib/canlii/base.rb (Critical Pattern)
```ruby
module CanLII
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes
    
    class << self
      def with_client(client = nil)
        if client
          old_client = Thread.current[:canlii_client]
          Thread.current[:canlii_client] = client
          yield client
        else
          CanLII.configuration.validate!
          yield current_client
        end
      ensure
        Thread.current[:canlii_client] = old_client if client
      end

      private

      def current_client
        Thread.current[:canlii_client] || Client.new
      end
    end
  end
end
```

#### lib/canlii/client.rb (Enhanced Error Handling)
```ruby
module CanLII
  class Client
    def get(path, params = {})
      params = params.merge(api_key: config.api_key, language: config.language)
      
      response = HTTP.get(build_url(path), params: params)
      handle_response(response)
    end
    
    private
    
    def build_url(path)
      "#{config.base_url}#{path}"
    end
    
    def handle_response(response)
      case response.status
      when 200..299
        JSON.parse(response.body.to_s)
      when 401, 403
        raise AuthenticationError, "Invalid API key"
      when 404
        raise NotFoundError, "Resource not found"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      when 500..599
        raise ResponseError, "Server error: HTTP #{response.status}"
      else
        raise ResponseError, "HTTP #{response.status}: #{response.body}"
      end
    rescue HTTP::Error => e
      raise ConnectionError, "Network error: #{e.message}"
    rescue JSON::ParserError => e
      raise ResponseError, "Invalid JSON response: #{e.message}"
    end
    
    def config
      CanLII.configuration
    end
  end
end
```

### 4. Files to Move

| From Rails | To Gem | Changes |
|------------|--------|---------|
| `app/models/canlii/client.rb` | `lib/canlii/client.rb` | Remove Rails dependencies, use gem config |
| `app/models/canlii/database.rb` | `lib/canlii/database.rb` | Inherit from Base |
| `app/models/canlii/case.rb` | `lib/canlii/case.rb` | Inherit from Base |
| `lib/canlii/errors.rb` | `lib/canlii/errors.rb` | None |
| `test/models/canlii/client_test.rb` | `test/canlii/client_test.rb` | Update requires |
| `test/models/canlii/database_test.rb` | `test/canlii/database_test.rb` | Update requires |
| `test/models/canlii/case_test.rb` | `test/canlii/case_test.rb` | Update requires |
| `test/models/canlii/configuration_test.rb` | `test/canlii/configuration_test.rb` | Update requires |
| `test/fixtures/canlii/*` | `test/fixtures/canlii/*` | None |
| `app/models/canlii/README.md` | `README.md` | Update for gem context |
| `app/models/canlii/QUICK_REFERENCE.md` | `docs/QUICK_REFERENCE.md` | Minor updates |

### 5. Rails App Updates

#### New config/initializers/canlii.rb
```ruby
require 'canlii-ruby'

CanLII.configure do |config|
  config.api_key = ENV["BLACKLINE_CANLII_API_KEY"]
  config.logger = Rails.logger
end
```

#### Gemfile
```ruby
# During development
gem 'canlii-ruby', path: '../canlii-ruby'

# After publishing
gem 'canlii-ruby', '~> 0.1'
```

#### lib/canlii/rails/railtie.rb
```ruby
module CanLII
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "canlii.logger" do |app|
        CanLII.configuration.logger = ::Rails.logger
      end
    end
  end
end
```

### 6. Testing

#### test/test_helper.rb
```ruby
require "minitest/autorun"
require "webmock/minitest"
require "canlii-ruby"

class CanLII::TestCase < Minitest::Test
  def setup
    CanLII.configuration.api_key = "test_key"
  end
  
  def teardown
    Thread.current[:canlii_client] = nil
  end
end
```

## Migration Checklist

### Pre-Migration
- [ ] Check all uses of CanLII:: in Rails app
- [ ] Search for any CanLII references in app code: `rg "CanLII" --type ruby`
- [ ] Note any Models:: namespace usage

### Implementation
- [ ] Create gem skeleton
- [ ] Add dependencies to gemspec
- [ ] Create version.rb with VERSION = "0.1.0"
- [ ] Create main canlii.rb with requires
- [ ] Create Configuration class
- [ ] Create Base class with with_client
- [ ] Copy and update Client class from Rails app
- [ ] Move errors.rb unchanged
- [ ] Move and update Database/Case classes (change parent class)
- [ ] Move all 4 test files
- [ ] Move test fixtures
- [ ] Create minimal railtie
- [ ] Add Rakefile with test task
- [ ] Run tests in gem: `bundle exec rake test`

### Rails Integration
- [ ] Add gem to Gemfile with path
- [ ] Create new initializer (replace existing)
- [ ] Update namespace references if any
- [ ] Run Rails tests: `bin/rails test test/models/canlii`
- [ ] Remove old Rails code:
  - [ ] Delete `app/models/canlii/` directory
  - [ ] Delete `lib/canlii/` directory
  - [ ] Delete `config/canlii.yml`
  - [ ] Delete old `config/initializers/canlii.rb`

### Publishing
- [ ] Set version to 0.1.0
- [ ] Build gem locally
- [ ] Test installation
- [ ] Push to RubyGems
- [ ] Update Rails Gemfile to published version

## Critical Technical Notes

### Key Model Methods
```ruby
# lib/canlii/database.rb
module CanLII
  class Database < Base
    attribute :database_id, :string
    attribute :jurisdiction, :string
    attribute :name, :string
    
    class << self
      def all
        with_client do |client|
          response = client.get("/caseDatabases")
          response["caseDatabases"].map { |data| new(data) }
        end
      end
    end
  end
end

# lib/canlii/case.rb  
module CanLII
  class Case < Base
    attribute :database_id, :string
    attribute :case_id, :string
    attribute :title, :string
    attribute :citation, :string
    # ... other attributes
    
    class << self
      def browse(database_id, offset: 0, limit: 100, **options)
        with_client do |client|
          params = { offset: offset, resultCount: limit }.merge(options)
          response = client.get("/caseBrowse/en/#{database_id}", params)
          response["cases"].map { |data| new(data.merge("database_id" => database_id)) }
        end
      end
      
      def find(database_id, case_id)
        with_client do |client|
          response = client.get("/cases/en/#{database_id}/#{case_id}")
          new(response.merge("database_id" => database_id))
        end
      rescue NotFoundError
        nil
      end
    end
  end
end
```

### API Quirks
1. Browse endpoint requires `offset` parameter
2. Case IDs differ between browse/detail: `{"en": "id"}` vs `"id"`
3. Browse returns minimal data, need detail fetch for full info

### Testing Patterns
```ruby
# WebMock setup
require "webmock/minitest"
WebMock.disable_net_connect!(allow_localhost: true)

# Thread safety test
test "with_client restores previous client" do
  initial = CanLII::Client.new
  Thread.current[:canlii_client] = initial
  
  CanLII::Case.with_client(mock_client) do
    # test
  end
  
  assert_same initial, Thread.current[:canlii_client]
end
```

### Error Handling
- Use `response.status` not `response.code` (HTTP.rb specific)
- Case.find returns nil for 404, not error
- Let consumers handle retries

### 7. Rakefile
```ruby
# Rakefile
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

require "rubocop/rake_task"
RuboCop::RakeTask.new

task default: %i[test rubocop]
```

## Next Action

Start with step 1: `bundle gem canlii-ruby --test=minitest --no-exe`
