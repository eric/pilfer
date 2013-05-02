# Pilfer

Look into your ruby with [rblineprof](https://github.com/tmm1/rblineprof/).

## Usage

Profile a block of code saving the report to the file `profile.log`.

```ruby
reporter = Pilfer::Logger.new('pilfer.log')
profiler = Pilfer::Profiler.new(reporter)
profiler.profile { do_something }
```

Profile your Rack or Rails app using `Pilfer::Middleware`.

```ruby
reporter = Pilfer::Logger.new($stdout, :app_root => Rails.root)
profiler = Pilfer::Profiler.new(reporter)
use Pilfer::Middleware :profiler => profiler
```

The report prints the source of each line of code executed and includes the
total execution time and the number of times the line was executed.

```
Profile start=2013-05-02 14:17:26 UTC
test.rb wall_time=1009.5ms cpu_time=0.5ms
                   | require 'bundler/setup'
                   | require 'pilfer/logger'
                   | require 'pilfer/profiler'
                   |
                   | l = Pilfer::Logger.new('log')
                   | p = Pilfer::Profiler.new(l)
                   | p.profile_files_matching('/Users/Larry/Sites/pilfer/test.rb') do
  1009.5ms (    1) |   10.times do
  1009.3ms (   10) |     sleep 0.1
                   |   end
                   | end
```

### Step 1: Create a reporter

Profiles can be sent to a [pilfer-server][] or written to a file or `IO`
object.

```ruby
reporter = Pilfer::Server.new('https://pilfer.com', 'abc123')
reporter = Pilfer::Logger.new('pilfer.log')
reporter = Pilfer::Logger.new($stdout)
```

The absolute path to each profiled file is used in the report. Set the path to
the application root with `:app_root` to have it trimmed from reported file
paths.

```ruby
reporter = Pilfer::Logger.new($stdout, :app_root => '/my/app')
```

### Step 2: Create a profiler

Pass the reporter to a new `Pilfer::Profiler`.

```ruby
profiler = Pilfer::Profiler.new(reporter)
```

### Step 3: Profile a block of code

Profile a block of code with `#profile`.

```ruby
profiler.profile { do_something }
```

Every file that's executed by the block--including code outside the
application like gems and standard libraries--will be included in the profile.
Use `#profile_files_matching` to limit profiling to files matching a regular
expression.

```ruby
matcher = %r{^#{Regexp.escape(Rails.root.to_s)}/app/models}
profiler.profile_files_matching(matcher) { do_something }
```

## Pilfer Server

[pilfer-server][] is your own, personal service for collecting and viewing
profile reports. Follow the [pilfer-server setup instructions][pilfer-server]
to stand up a new server and send it reports using its URL and token.

```ruby
reporter = Pilfer::Server.new('https://pilfer.com', 'abc123')
```

## Rack Middleware

Profile your Rack or Rails app using `Pilfer::Middleware`.

```ruby
reporter = Pilfer::Logger.new($stdout, :app_root => Rails.root)
profiler = Pilfer::Profiler.new(reporter)
use Pilfer::Middleware :profiler => profiler
```

Restrict profiling to files matching a regular expression using the
`:files_matching` option.

```ruby
matcher = %r{^#{Regexp.escape(Rails.root.to_s)}/(app|config|lib|vendor/plugin)}
use Pilfer::Middleware, :profiler       => profiler,
                        :files_matching => matcher
```

You probably don't want to profile _every_ request. Provide a block to
determine if a profile should be run on the incoming request.

```ruby
use Pilfer::Middleware, :profiler => profiler do
  # Profile 1% of requests.
  rand(100) == 1
end
```

The Rack environment is available to allow profiling on demand.

```ruby
use Pilfer::Middleware, :profiler => profiler do |env|
  env.query_string.include? 'profile=true'
end

use Pilfer::Middleware, :profiler => profiler do |env|
  env['HTTP_PROFILE_AUTHORIZATION'] == 'super-secret'
end
```


[pilfer-server]: https://github.com/eric/pilfer-server
