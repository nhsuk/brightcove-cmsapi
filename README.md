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

## Setup 

To use this library you will require a client ID and secret, as well as your brightcove account's ID.
You can find instructions of obtaining these credentials in the [Brightcove docs](https://support.brightcove.com/managing-api-authentication-credentials).

** Setup a basic client **

```ruby
  @client = Brightcove::Cmsapi.new(
    account_id: "my_account_id",
    client_id: "my_client_id",
    client_secret: "my_client_secret")
```

One alternative to this setup that can save you time and boilerplate code would be to call the `.default_api` method.
This assumes you have your credentials and account ID set as environment variables `BRIGHTCOVE_ACCOUNT_ID` `BRIGHTCOVE_CLIENT_ID` `BRIGHTCOVE_CLIENT_SECRET`.

** Alternatively: don't setup the client each time (RECOMMENDED USAGE) **

```ruby
Brightcove::CMSAPI.default_api.get('videos')
```

## Usage examples

** Get a list of available videos in account **

```ruby
@client.get('videos')

# or use the default_api setup:
Brightcove::CMSAPI.default_api.get('videos')
```

Calling `.get` uses the default API settings and simply appends the argument to the API call like this:

`https://cms.api.brightcove.com/v1/accounts/:account_id/videos`

The API defaults are described in [Brightcove's documentation](https://brightcovelearning.github.io/Brightcove-API-References/cms-api/v1/doc/index.html).
To get more than the default 20 results you could call `.get('videos?limit=100')`, however there is a hard limit at 100 results that you can not exceed.
To get around this limit you can use the `.get_all` method as displayed below, this will paginate through the results and return a parsed set of all
a particular resource.

** Get a list of all available videos **

```ruby
Brightcove::CMSAPI.default_api.get_all('video')
```

** Get a list of all available videos in a folder **

```ruby
Brightcove::CMSAPI.default_api.get_all('folder/:folder_id', 'video')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
