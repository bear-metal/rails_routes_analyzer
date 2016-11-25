[![Build Status](https://travis-ci.org/bear-metal/rails_routes_analyzer.svg)](https://travis-ci.org/bear-metal/rails_routes_analyzer)

Adds rake tasks to detect extraneous routes and unreachable controller actions Ruby on Rails applications. It's also able to provide suggestions on how to change routes.rb to avoid defining dead routes and can generate an annotated version of a route file with suggestions for each line added as comments.

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
rake routes:annotate_dead [ANNOTATE=path/to/routes.rb]

# Best used like this:
rake routes:annotate_dead > config/routest.rb.new
mv config/routes.rb.new config/routes.rb
# And then update the file as requested in any SUGGESTION comments
```

Will output an annotated version of config/routes.rb or any other routes file as provided in the ANNOTATE parameter.


#### Additional options:

``` sh
ONLY_ONLY=1      # suggestions for resource routes will only generate "only:" regardless of how many elements are listed.
ONLY_EXCEPT=1    # suggestions for resource routes will only generate "except:" regardless of how many elements are listed.
ROUTES_VERBOSE=1 # more verbosity, currently this means listing which non-existing actions a given call provides routes for.
```

```sh
rake routes:missing
```

#### Additional options:

Lists all action methods for all controllers which have no route pointing to them (with ALL=1 it can also list every action). Uses the ActionController#Base.action\_methods method which usually returns a list of all public methods of the controller class excluding any special Rails provided methods.

Generally it's not a problem to have ActionController#Base.action\_methods list non-actions given Rails no longer uses default routes that would benefit from proper limits on what is and what isn't an action. However there is also no obvious reason to be unable to correct it and possibly be able to use the more accurate metadata somewhere else (such as this tool).

The easiest way to remove non-actions from ActionController#Base.action\_methods would be to make them protected or private. If that's not possible the other alternative is to override the action\_methods method itself and remove the relevant methods from the returned action list (this is more complicated and much more effort to keep updated.)

``` sh
ROUTES_DUPLICATES=1 # causes controller base class provided public methods to be considered as actions for a subclass controller and thus reported as errors if they lack routes. Enabling this can generate a lot of noise for applications that have public non-actions in a controller base class.
ROUTES_GEMS=1       # includes actions that appear to be implemented by gems.
ROUTES_MODULES=1    # includes public controller methods inherited from modules that are listed in action_methods.
ROUTES_FULL_PATH=1  # disables file path shortening
ROUTES_METADATA=1   # lists collected data per action such as which gem it's from, if it's inherited from a superclass.
ROUTES_ALL=1        # lists all actions instead of only the ones that don't have routes.
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bear-metal/rails_routes_analyzer.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

Copyright (c) 2016 [Bear Metal](http://bearmetal.eu)
