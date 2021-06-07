# PlugEarlyHints

Convenience plug for sending [HTTP 103 Early Hints][mdn-103].

This is useful for static resources that will be **for sure** required by
the resulting page. For example you can use it for informing the client
that you will need CSS later, so it can start fetching it right now.

## Installation

```elixir
def deps do
  [
    {:plug_early_hints, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
plug PlugEarlyHints,
  # List all resources that will be needed later when rendering page
  paths: [
    # External resources that will be connected to as we will use
    # different resources from it. It will speedup as the TLS handshake
    # will be already ended, so we will be able to fetch resources
    # right away
    "https://gravatar.com/": [rel: "dns-prefetch"],
    "https://gravatar.com/": [rel: "preconnect"],
    # "Regular" resources. We need to set `:as` to inform the client
    # (browser) what kinf of resource it is, so it will be able to
    # properly connect them
    "/css/app.css": [rel: "preload", as: "style"],
    "/js/app.js": [rel: "preload", as: "script"],
    # Preloading fonts will require additional `:type` and `:crossorgin`
    # to allow CSS engine to properly detect when apply the resource as
    # well as to prevent double load.
    "/fonts/recursive.woff2": [
      rel: "preload",
      as: "font",
      crossorgin: :anonymous,
      type: "font/woff2"
    ]
  ]
```

For more information about available options check out [MDN `Link`][mdn-link].

[mdn-103]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/103 "103 Early Hints"
[mdn-link]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Link "Link"

## License

See [LICENSE](LICENSE).
