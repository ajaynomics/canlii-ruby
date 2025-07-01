# CanLII Ruby

A lightweight Ruby client for accessing Canadian legal information via the CanLII API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'canlii'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install canlii

## Configuration

### Basic Configuration

```ruby
require 'canlii'

CanLII.configure do |config|
  config.api_key = ENV["CANLII_API_KEY"]
  config.logger = Logger.new(STDOUT)
  config.timeout = 30 # Optional: timeout in seconds (default: 30)
end
```

### Rails Configuration

In `config/initializers/canlii.rb`:

```ruby
CanLII.configure do |config|
  config.api_key = ENV["CANLII_API_KEY"]
  config.logger = Rails.logger
  config.timeout = 30 # Optional: timeout in seconds (default: 30)
end
```

## Usage

### List All Databases

```ruby
databases = CanLII::Database.all
databases.each do |db|
  puts "#{db.database_id}: #{db.name} (#{db.jurisdiction})"
end
```

### Browse Cases

```ruby
# Recent Supreme Court cases
cases = CanLII::Case.browse("csc-scc", limit: 10)
cases.each do |c|
  puts "#{c.citation}: #{c.title}"
end

# Cases from last 30 days
recent = CanLII::Case.browse("onca", 
  published_after: 30.days.ago,
  limit: 100
)
```

### Find Specific Case

```ruby
# Find returns nil if not found
case_detail = CanLII::Case.find("csc-scc", "2024scc1")

# Find! raises error if not found
case_detail = CanLII::Case.find!("csc-scc", "2024scc1")
```

### Language Support

```ruby
# Temporary language switch
CanLII.with_language("fr") do
  databases = CanLII::Database.all  # Returns French names
  cases = CanLII::Case.browse("qcca")  # Quebec cases
end

# Permanent language switch
CanLII.configuration.language = "fr"
```

### Using Custom Clients (Advanced)

```ruby
# For testing or using multiple API keys
mock_client = MyMockClient.new

CanLII::Case.with_client(mock_client) do
  case_detail = CanLII::Case.find("on", "2024onca1")
  # This will use mock_client instead of the default HTTP client
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ajaynomics/canlii-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).