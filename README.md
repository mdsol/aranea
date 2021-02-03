Aranea
======

Aranea is a gem to use in fault-tolerance testing. It simulates a remote dependency failing, so that you can see how your project reacts.

In Dungeons and Dragons, an Aranea is a giant spider that will ambush a group of adventurers using its illusion powers, then immobilize the strongest member, forcing the others to battle without a key ally.

Aranea currently only works with Faraday clients.

# Activating Aranea in a Deployed Rails or Rack Application

If Aranea has already been set up and configured to run in your testing environment, you can switch it on via a POST request to `/disable`. For example, in your shell, you could write

```sh
curl -d "" https://myapp-sandbox.example.com/disable?dependency=google
```

Your app should return the message "For the next 5 minutes, all requests to urls containing 'google' will 500". You can then see how your app would behave if google were down, without the bother of having to actually DOS google.

You must specify a dependency. If you want *all* external requests to fail, set `dependency=.`.  Any regular expression syntax will work, so if you want a subset of dependencies to fail, use a pipe-delimited list (`dependency=google|yahoo`).

You can override the duration of the test by specifying `minutes=` with a number from 1 to 60.

You can optionally specify the response body by setting `response=` and also the response header by setting `header=`. The endpoint to create a stubbed response uses query parameters, so your `response` and `header` fields must be URL encoded. For example, to return a response `{ "errors": "test_error" }`, you must send `response=%7B%20%22errors%22%3A%20%22test_error%22%20%7D`.

You can also override the simulated response code, if your app is meant to handle different failures differently. `?dependency=google&failure=404` will simulate a 404 (Not Found) response instead of a 500 (Internal Server Error). `?dependency=google&failure=timeout` will pretend the server never responded at all (although it will raise an error instantly; the illusion is not perfect).

**Sample calls and their effects:**

`https://myapp-sandbox.example.com/disable?dependency=google`. For the next 5 minutes, all requests to urls containing 'google' will 500.

`https://myapp-sandbox.example.com/disable?dependency=.&failure=403` For the next 5 minutes, all external requests will 403.

`https://myapp-sandbox.example.com/disable?dependency=sheep&failure=ssl_error` For the next 5 minutes, all external requests to urls containing `sheep` will raise a Faraday::SSLError.

`https://myapp-sandbox.example.com/disable?dependency=google|yahoo&minutes=10` For the next 10 minutes, all requests to urls containing 'google' and/or 'yahoo' will 500.

`https://myapp-sandbox.example.com/disable?dependency=google|yahoo&minutes=10&failure=timeout` For the next 10 minutes, all requests to urls containing 'google' and/or 'yahoo' will raise a Timeout error.

`https://myapp-sandbox.example.com/disable?dependency=google|yahoo&minutes=10&failure=timeout&response=%7B%20%22errors%22%3A%20%22test_error%22%20%7D` Similar to the above example, except all external requests that match will now return `{ "errors": "test_error" }`.

`https://myapp-sandbox.example.com/disable?dependency=google|yahoo&minutes=10&failure=timeout&response=%7B%20%22errors%22%3A%20%22test_error%22%20%7D&headers=%7B%20%22Content-Type%22%3A%20%22application%2Fjson%22%20%7D` Similar to the above example, except all external requests that match will now return `{ "errors": "test_error" }`, and will return the header `{ "Content-Type": "application/json" }`

# Activating Aranea Programmatically

From inside your application, you can run

```ruby
Aranea::Failure.create(
  pattern: /google/,
  minutes: 5,
  failure: 503,
  response_hash: { "errors": "test_error" },
  response_headers_hash: { "Content-Type": "application/json" }
)
```

All parameters are required in this form. They may alternatively be provided as strings ('google','5').

# Adding Aranea To Your Project

In your Gemfile:

```ruby
gem 'aranea'
```

In your Faraday middleware stack (wherever and however you configure it):

```ruby
use Aranea::Faraday::FailureSimulator
```

Similarly, in your Rack middleware stack:

```ruby
if ENV['USE_ARANEA']
  use Aranea::Rack::FailureCreator
end
```

You'll want to ensure that Aranea (or at minimum the Rack middleware) is not active in production!

# Caveats and Limitations

Aranea needs to be included manually into every Faraday stack you have. If you miss one, or if you have a gem that makes http requests without using Faraday, your fault-tolerance test may falsely pass. Pull requests are welcome for compatibility with other http clients (aws-sdk is on the wishlist).

Failures are not necessarily shared between processes. Aranea will use `Rails.cache` if it exists and is available when it starts up, so if `Rails.cache` is shared between processes, a POST that hits one app worker will disable requests from all of them. But if you're not using Rails, your cache is in-memory, your cache is a file cache and your workers can be on different servers, or something else goes wrong, then some requests are likely to get through. In particular, jobs executed in the background may not hit the failure, even if they execute within the specified time frame.

# Owners

Aranea is (c) Medidata Solutions Worldwide and owned by whoever committed to it most recently. Original concept by Matthew Szenher.


