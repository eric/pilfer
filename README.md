# Pilfer

Look into your ruby with [rblineprof](https://github.com/tmm1/rblineprof/).

## Usage

### Deploy pilfer-server

[pilfer-server][] is your own, personal service for collecting and viewing
profiles collected by Pilfer. Follow the [pilfer-server
instructions][pilfer-server] to stand up a new server and come back here with
the app's URL and token.

[pilfer-server]: https://github.com/eric/pilfer-server

### Create a reporter

Profiles can be reported to either pilfer-server or logged to a file.

```ruby
reporter = Pilfer::Server.new('https://pilfer.com', 'abc123')
reporter = Pilfer::Logger.new('pilfer.log')
reporter = Pilfer::Logger.new($stdout)
```

### Profile a block of code

After creating the reporter, pass it to a new `Pilfer::Profiler` and profile a
block of code with `#profile`.

```ruby
profiler = Pilfer::Profiler.new(reporter)
profiler.profile { do_something }
# TODO: Show profile response
```

### Options

`Pilfer::Profiler#profile` takes a few optional arguments.

`:app_root`: By default, the full path to each profiled file is used. Pass the
path to the root of the application to use relative paths instead.

```ruby
profiler.profile(:app_root => '/my/app') { do_something }
# TODO: Show profile response
```

`:file_matcher`: By default, all files will be profiled. Provide a regular
expression and profiling will be limited to matching file paths.

```ruby
matcher = %r{^#{Regexp.escape(RAILS_ROOT)}/app/models}
profiler.profile(:file_matcher => matcher) { do_something }
# TODO: Show profile response
```


### Rack Middleware

Profile your Rack app by using `Pilfer::Middleware`.

```ruby
use Pilfer::Middleware, reporter
```

#### Middleware Options

Pass options through to `Pilfer::Profiler#profile`.

```ruby
use Pilfer::Middleware, reporter, :app_root     => '/dev/null',
                                  :file_matcher => %r{...}
```

You probably don't want to profile _every_ request. The given block will be
evaluated on each request to determine if a profile should be run.

```ruby
use Pilfer::Middleware, reporter do |env|
  # Profile 1% of requests.
  rand(100) == 1
end
```
