# Pilfer

Look into your ruby with [rblineprof](https://github.com/tmm1/rblineprof/).

## Usage

Profile a block of code saving the report to the file `profile.log`.

```ruby
reporter = Pilfer::Logger.new('pilfer.log')
profiler = Pilfer::Profiler.new(reporter)
profiler.profile { do_something }
```

The report prints the source of each line of code executed and includes the
total execution time and the number of times the line was executed.

_TODO: Show profile response._

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
Use `#profile_files_matching` and provide a regular expression to limit
profiling to only matching file paths.

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

Restrict the files profiled by passing a regular expression with
`:files_matching`.

```ruby
matcher = %r{^#{Regexp.escape(Rails.root.to_s)}/(app|config|lib|vendor/plugin)}
use Pilfer::Middleware, :files_matching => matcher,
                        :profiler       => profiler
```

You probably don't want to profile _every_ request. The given block will be
evaluated on each request to determine if a profile should be run.

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
```


[pilfer-server]: https://github.com/eric/pilfer-server
