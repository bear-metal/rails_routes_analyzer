[![Build Status](https://travis-ci.org/bear-metal/rails_route_analyzer.svg)](https://travis-ci.org/bear-metal/rails_route_analyzer)

This gem adds rake tasks to detect extraneous routes and unreachable controller actions Ruby on Rails applications. It tries to provide suggestions on how to change routes.rb to avoid defining dead routes and is also able to generate an annotated version of a route file with suggestions for each line added as comments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_routes_analyzer'
```

And then execute:

    $ bundle

## Usage

``` sh
rake routes:dead
```

Without any additional options this will scan all the routes and check for a matching action for each. For single routes created with methods such as `get' or `post' it will tell you when that line could be removed.

For multi-route calls like `resource' and `resources' it can also let you know if and how to set the :except or :only parameter to better match the actions a controller actually provides. When suggesting :only/:except by default the one that provides a shorter list will be used.

For complex cases where for example a routes are created in a loop for multiple controllers a suggestion will be provided for each iteration but only if that specific iteration created a dead route. Every such suggestion will identify the exact controller to which it applies.

``` sh
rake routes:dead ANNOTATE=1
```

This will output an annotated version of config/routes.rb

``` sh
rake routes:dead ANNOTATE=path/to/any/routes.rb
```

Same as above but allows specifying the exact file to annotate in case the application loads routes from multiple files.

Additional options:

* ONLY\_ONLY=1 - suggestions for resource(s) will only generate "only:" regardless of how many elements are listed.
* ONLY\_EXCEPT=1 - suggestions for resource(s) will only generate "except:" regardless of how many elements are listed.
* VERBOSE=1 - more verbosity, currently this means listing which non-existing actions a given call provides routes for.

```sh
rake routes:missing
```

Additional options:

Lists all action methods for all controllers which have no route pointing to them. This uses the (maybe not so well known) ActionController#Base.action\_methods method which usually returns a list of all public methods of the controller class excluding any special Rails provided methods. To make the output of ActionController#Base.action\_methods it would be ideal to try to make all application-provided controller methods non-public if they are not meant to be callable as an action. Alternatively it's also possible (but less desirable) to override the action\_methods call in any controller class to explicitly remove mis-characterised methods.

* STRICT=1 - causes controller base class provided public methods to be considered as actions for a subclass controller and thus reported as errors if they lack routes. Enabling this can generate a lot of noise for applications that have public non-actions in a controller base class.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails\_routes\_analyzer.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

Copyright (c) 2016 [Bear Metal](http://bearmetal.eu)
