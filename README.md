# CanLII Ruby

A lightweight Ruby client for accessing Canadian legal information via the CanLII API.

## API Access

To use this gem, you'll need a CanLII API key. Request one by filling out the [feedback form](https://www.canlii.org/feedback/feedback.html).

### API Limitations

The CanLII API provides:
- Access to metadata only (not full document text)
- 5,000 queries per day
- 2 requests per second
- 1 request at a time

### Support

CanLII does not provide user support for the API. Please:
- Refer to the [CanLII REST API Documentation](https://www.canlii.org/api/docs/)
- Report API issues via [GitHub](https://github.com/canlii/api_documentation/issues)

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ajaynomics/canlii-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
