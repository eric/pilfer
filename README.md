# Pilfer

Profile Ruby code and find out _exactly_ how slow it runs.

Pilfer uses [rblineprof][] to measure how long each line of code takes to
execute and the number of times it was called.

![Pilfer Profile.png](http://cl.ly/image/2a1d332M2w05/Pilfer%20Profile.png)

Take a look at some [Pilfer profiles of the Bundler API site][bundler-pilfer].

## Installation

Using with Bundler is as simple as adding `pilfer` to your `Gemfile`.

```ruby
gem 'pilfer', '~> 1.0.0'
```

Or install it locally like any other gem.

```bash
$ gem install pilfer
```

## Usage

Profile a block of code saving the report to the file `profile.log`.

```ruby
require 'pilfer'

reporter = Pilfer::Logger.new('pilfer.log')
profiler = Pilfer::Profiler.new(reporter)
profiler.profile('bubble sorting') do
  array = (0..100).to_a.shuffle
  bubble_sort array
end
```

Profile your Rack or Rails app using `Pilfer::Middleware`.

```ruby
reporter = Pilfer::Logger.new('pilfer.log')
profiler = Pilfer::Profiler.new(reporter)
use Pilfer::Middleware :profiler => profiler
```

The profile report consists of the wall time and call count for each line of
code executed along with the total wall and CPU times for each file.

```
Profile start="2013-05-12 00:41:16 UTC" description="bubble sorting"
/Users/Larry/Sites/pilfer/sort.rb wall_time=42.5ms cpu_time=29.7ms
                   | require 'pilfer'
                   |
                   | def bubble_sort(container)
    42.5ms (    1) |   loop do
                   |     swapped = false
    42.3ms (   94) |     (container.size-1).times do |i|
    10.2ms ( 9400) |       if (container[i] <=> container[i+1]) == 1
     6.2ms ( 5092) |         container[i], container[i+1] = container[i+1], container[i] # Swap
                   |         swapped = true
                   |       end
                   |     end
                   |     break unless swapped
                   |   end
                   |   container
                   | end
                   |
                   | reporter = Pilfer::Logger.new($stdout)
                   | profiler = Pilfer::Profiler.new(reporter)
                   | profiler.profile_files_matching(/sort\.rb/, 'bubble sorting') do
     0.1ms (    3) |   array = (0..100).to_a.shuffle
    42.5ms (    1) |   bubble_sort array
                   | end
```

### Step 1: Create a reporter

Decide how you want line profiles to be reported. Profiles can be sent to a
[pilfer-server][] or written to a file path or `IO` object.

```ruby
# Send reports to a pilfer-server
reporter = Pilfer::Server.new('https://pilfer.com', 'my-pilfer-server-token')

# Append reports to a file
reporter = Pilfer::Logger.new('pilfer.log')

# Print reports to standard out
reporter = Pilfer::Logger.new($stdout)
```

The absolute path to each profiled file is used in the report. Set the path to
the application root with `:app_root` to have it trimmed from reported file
paths.

```ruby
reporter = Pilfer::Logger.new('pilfer.log')
# Profile start=2013-05-02 14:17:26 UTC
# /Sites/bundler-api/lib/bundler-api/web.rb wall_time=1009.5ms cpu_time=0.5ms
# ...

reporter = Pilfer::Logger.new('pilfer.log', :app_root => '/Sites/bundler-api/')
# Profile start=2013-05-02 14:17:26 UTC
# lib/bundler-api/web.rb wall_time=1009.5ms cpu_time=0.5ms
# ...
```

### Step 2: Create a profiler

A `Profiler` runs the line profiler and sends it to a reporter. Create one
passing the reporter created in the previous step.

```ruby
profiler = Pilfer::Profiler.new(reporter)
```

### Step 3: Profile a block of code

Use `Profiler#profile` to profile a block of code. Optionally, provide a
description of the code being profiling.

```ruby
profiler.profile('bubble sorting') do
  array = (0..100).to_a.shuffle
  bubble_sort array
end
```

Every file that's executed by the block including code outside the
application like gems and standard libraries will be included in the profile.
Use `#profile_files_matching` to limit profiling to files whose paths match a
regular expression.

```ruby
# Only profile Rails models
matcher = %r{^#{Regexp.escape(Rails.root.to_s)}/app/models}
profiler.profile_files_matching(matcher, 'User.find_by_email') do
  User.find_by_email('arthur@dent.com')
end
```

## Extras

### Pilfer Server

[Pilfer Server][pilfer-server] is your own, personal service for collecting
and viewing line profiles gathered by Pilfer. Follow the
[Pilfer Server setup instructions][pilfer-server-readme] to stand up a new
server.

```ruby
reporter = Pilfer::Server.new('https://pilfer.com', 'my-pilfer-server-token')
profiler = Pilfer::Profiler.new(reporter)
profiler.profile('bubble sorting') do
  array = (0..100).to_a.shuffle
  bubble_sort array
end
```

### Rack Middleware

Profile your entire Rack or Rails app using `Pilfer::Middleware`. Pass it a
`Profiler` created with a reporter as normal.

```ruby
reporter = Pilfer::Server.new('https://pilfer.com', 'my-pilfer-server-token')
profiler = Pilfer::Profiler.new(reporter)
use Pilfer::Middleware :profiler => profiler
```

Restrict profiling to files matching a regular expression using the
`:files_matching` option. This calls `Profiler#profile_files_matching` using
the given regular expression.

```ruby
matcher = %r{^#{Regexp.escape(Rails.root.to_s)}/(app|config|lib|vendor/plugin)}
use Pilfer::Middleware, :profiler       => profiler,
                        :files_matching => matcher
```

You almost certainly don't want to profile _every_ request. Provide a block to
determine if a profile should be run on the incoming request.

```ruby
use Pilfer::Middleware, :profiler => profiler do
  # Profile 1% of requests.
  rand(100) == 1
end
```

The Rack environment is available to allow profiling on demand.

```ruby
# Profile requests containing the query string ?profile=true
use Pilfer::Middleware, :profiler => profiler do |env|
  env.query_string.include? 'profile=true'
end

# Profile requests containing a header whose value matches a secret
use Pilfer::Middleware, :profiler => profiler do |env|
  env['HTTP_PROFILE_AUTHORIZATION'] == 'super-secret'
end
```

## Supported Ruby Versions

This library is [tested against][travis] the following Ruby versions.

 - MRI 1.9.3
 - MRI 1.8.7
 - REE

If you need a specific version supported, open and issue or send a pull
request.

## License

The MIT License (MIT)

Copyright (c) 2013 Eric Lindvall and Larry Marburger. See [LICENSE][] for
details.


[rblineprof]:           https://github.com/tmm1/rblineprof
[bundler-pilfer]:       https://pilfer.herokuapp.com/dashboard
[pilfer-server]:        https://github.com/eric/pilfer-server
[pilfer-server-readme]: https://github.com/eric/pilfer-server#readme
[travis]:               https://travis-ci.org/eric/pilfer
[license]:              LICENSE
