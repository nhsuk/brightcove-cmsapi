# Brightcove::Cmsapi

This gem wraps Brightcove's [CMS API](https://brightcovelearning.github.io/Brightcove-API-References/cms-api/v1/doc/index.html).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'brightcove-cmsapi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install brightcove-cmsapi

## Usage examples

** Get a list of available videos

```ruby
Brightcove::CMSAPI.default_api.get('videos')
```

** Get a list of all available videos in a folder

```ruby
Brightcove::CMSAPI.default_api.get_all('playlist/PLAYLIST_ID_HERE', 'video')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
