defmodule PlugEarlyHints do
  defmodule BadArityError do
    defexception [:function, :arity, :key]

    @impl true
    def message(exception) do
      {:arity, arity} = Function.info(exception.function, :arity)

      "Function passed to #{exception.key} has arity #{arity} while expected" <>
        "arity is #{exception.arity}"
    end
  end

  @moduledoc """
  Convenience plug for sending [HTTP 103 Early Hints][mdn-103].

  This is useful for static resources that will be **for sure** required by
  the resulting page. For example you can use it for informing the client
  that you will need CSS later, so it can start fetching it right now.

  ## Usage

      plug #{inspect(__MODULE__)},
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

  For more information about available options check out [MDN `Link`][mdn-link].

  ## Options

  - `:paths` - enumerable containing pairs in form of `{path, options}`.
  - `:callback` - 2-ary function used for expanding `path` value from `:paths`.
    It is useful for example to expand static assets in Phoenix applications.
    Due to nature of the `Plug` it must be in form of `&Module.function/2`
    (it cannot be `&function/2` nor `fn conn, path -> … end`).
    1st argument will be `conn` passed to the plug and 2nd argument will be
    current path. By default it return `path` unmodified.
  - `:enable` - 1-ary function that will receive `conn` and should return boolean
    whether the early hints should be sent or not. You mostly want to do it only
    for requests returning HTML. The same rules as in `:callback` apply. By default
    uses function that alwayst return `true`.

  [mdn-103]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/103 "103 Early Hints"
  [mdn-link]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Link "Link"
  """

  @behaviour Plug

  require Logger

  @impl true
  def init(opts) do
    enable = get_func(opts, :enable, 1, &__MODULE__.__true__/1)
    paths = Keyword.fetch!(opts, :paths)
    cb = get_func(opts, :callback, 2, &__MODULE__.__id__/2)

    %{
      paths: paths,
      callback: cb,
      enable: enable
    }
  end

  defp get_func(opts, key, arity, default) do
    case Keyword.fetch(opts, key) do
      :error ->
        default

      {:ok, func} when is_function(func, arity) ->
        if Function.info(func, :type) != {:type, :external} do
          Logger.warn(
            "Function passed to `#{inspect(key)}` is not external function, which may cause problems"
          )
        end

        func

      {:ok, func} when is_function(func) ->
        raise BadArityError, function: func, arity: arity, key: key
    end
  end

  @impl true
  def call(conn, %{paths: paths, callback: cb, enable: enable}) do
    if enable.(conn) and :"HTTP/2" == Plug.Conn.get_http_protocol(conn) do
      headers =
        for {path, args} <- paths,
            path = cb.(conn, to_string(path)),
            not is_nil(path),
            do: {"link", encode(path, args)}

      Plug.Conn.inform(conn, :early_hints, headers)
    else
      conn
    end
  end

  defp encode(path, args) do
    encoded_args =
      args
      |> Enum.map(fn {name, value} -> ~s[#{name}=#{value}] end)
      |> Enum.join("; ")

    "<#{path}>; " <> encoded_args
  end

  @doc false
  def __true__(_conn), do: true

  @doc false
  def __id__(_conn, path), do: path
end
