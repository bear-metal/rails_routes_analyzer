[![Build Status](https://travis-ci.org/bear-metal/rails_routes_analyzer.svg)](https://travis-ci.org/bear-metal/rails_routes_analyzer)

Adds rake tasks to detect extraneous routes and unreachable controller actions in Ruby on Rails applications. It's able to provide suggestions on how to change routes.rb to avoid defining dead routes.

It can also add comments to routes files (even when there are multiple) to suggest fixes and for certain common patterns optionally apply those fixes automatically.

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
rake routes:dead:annotate [ROUTES_FILE=path/to/routes.rb]
rake routes:dead:fix      [ROUTES_FILE=path/to/routes.rb]

# Best used like this:
rake routes:dead:annotate > config/routest.rb.new
mv config/routes.rb.new config/routes.rb
# And then update the file as requested in any SUGGESTION comments
```

_routes:dead:annotate_ generates a commented version of a routes file. _routes:dead:fix_ generates a partly automatically fixed and partly commented version of a routes file. Without specifying a file in ROUTES_FILE parameter one is automatically picked provided that it is the only one that has problems, if there are more they will all be listed and a single name will have to be provided in the ROUTES_FILE parameter.

#### Additional options:

``` sh
ONLY_ONLY=1      # suggestions for resource routes will only generate "only:" regardless of how many elements are listed.
ONLY_EXCEPT=1    # suggestions for resource routes will only generate "except:" regardless of how many elements are listed.
ROUTES_VERBOSE=1 # more verbosity, currently this means listing which non-existing actions a given call provides routes for.
```

``` sh
rake routes:dead:annotate:inplace [ROUTES_FILE=path/to/routes.rb]
rake routes:dead:fix:inplace      [ROUTES_FILE=path/to/routes.rb]

rake routes:dead:annotate:inplace[force] [ROUTES_FILE=path/to/routes.rb]
rake routes:dead:fix:inplace[force]      [ROUTES_FILE=path/to/routes.rb]
```

Same as above but these commands change existing routes file content instead of printing it to standard output. By default they'll refuse to change a file if it's outside Rails root or has uncommited changes. To get around this protection set the ROUTES_FORCE=1 parameter.


```sh
rake actions:missing_route
rake actions:missing_route[gems,modules,duplicates,full,metadata] # parameters can be combined in all ways
```

Lists all action methods for all controllers which have no route pointing to them. By default ignores methods coming from gems, included modules or inherited from a parent controller. Uses the ActionController#Base.action\_methods method which usually returns a list of all public methods of the controller class excluding any special Rails provided methods.

Generally it's not a problem to have ActionController#Base.action\_methods list non-actions given Rails no longer uses default routes that would benefit from proper limits on what is and what isn't an action. However there is also no obvious reason to be unable to correct it and possibly be able to use the more accurate metadata somewhere else (such as this tool).

The easiest way to remove non-actions from ActionController#Base.action\_methods is to make them protected or private. If that's not possible the other alternative is to override the action\_methods method itself and remove the relevant methods from the returned action list (this is more complicated and much more effort to keep updated.)

```sh
rake actions:list_all
rake actions:list_all[gems,modules,duplicates,full,metadata] # parameters can be combined in all ways
```

#### Additional options:
_(applies to both actions:missing\_route and actions:list\_all)_

``` sh
ROUTES_DUPLICATES=1 # report actions inherited from parent controllers (can generate a lot of noise)
ROUTES_GEMS=1       # includes actions that appear to be implemented by gems
ROUTES_MODULES=1    # includes public controller methods inherited from modules that are listed in action_methods
ROUTES_FULL_PATH=1  # disables file path shortening
ROUTES_METADATA=1   # lists collected data per action such as which gem it's from, if it's inherited from a superclass
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bear-metal/rails_routes_analyzer.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

Copyright (c) 2016 Tarmo Tänav, [Bear Metal OÜ](http://bearmetal.eu), 
