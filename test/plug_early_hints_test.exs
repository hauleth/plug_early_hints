defmodule PlugEarlyHintsTest do
  use ExUnit.Case
  use PlugTestHTTP2

  @subject PlugEarlyHints

  test "compiles with `:callback` as &Mod.fun/arity" do
    Plug.Builder.compile(
      __ENV__,
      [
        {@subject, [paths: ["/foo": []], callback: &__MODULE__.identity/2], []}
      ],
      []
    )
  end

  test "compiles with `:enable` as &Mod.fun/arity" do
    Plug.Builder.compile(
      __ENV__,
      [
        {@subject, [paths: ["/foo": []], enable: &__MODULE__.always/1], []}
      ],
      []
    )
  end

  test "sends early hints" do
    opts =
      @subject.init(
        paths: ["/foo": [rel: "prefetch"], "https://example.test": [rel: :preconnect]]
      )

    conn =
      conn(:get, "/")
      |> @subject.call(opts)
      |> Plug.Conn.send_resp(200, "")

    informs = sent_informs(conn)

    assert {103,
            [{"link", "</foo>; rel=prefetch"}, {"link", "<https://example.test>; rel=preconnect"}]} in informs
  end

  test "do not send early hints if disabled" do
    opts =
      @subject.init(
        paths: ["/foo": [rel: "prefetch"]],
        enable: &__MODULE__.never/1
      )

    conn =
      conn(:get, "/")
      |> @subject.call(opts)
      |> Plug.Conn.send_resp(200, "")

    assert [] == sent_informs(conn)
  end

  test "do not send early hints on HTTP/1" do
    opts = @subject.init(paths: ["/foo": [rel: "prefetch"]])

    conn =
      conn(:get, "/", :"HTTP/1")
      |> @subject.call(opts)
      |> Plug.Conn.send_resp(200, "")

    assert [] == sent_informs(conn)
  end

  test "do not send early hints on HTTP/1.1" do
    opts = @subject.init(paths: ["/foo": [rel: "prefetch"]])

    conn =
      conn(:get, "/", :"HTTP/1.1")
      |> @subject.call(opts)
      |> Plug.Conn.send_resp(200, "")

    assert [] == sent_informs(conn)
  end

  test "allow modyfying the paths" do
    opts =
      @subject.init(
        paths: ["/foo": [rel: "prefetch"]],
        callback: &__MODULE__.add_test/2
      )

    conn =
      conn(:get, "/")
      |> @subject.call(opts)
      |> Plug.Conn.send_resp(200, "")

    informs = sent_informs(conn)
    assert {103, [{"link", "<test/foo>; rel=prefetch"}]} in informs
  end

  test "allow ignoring the paths" do
    opts =
      @subject.init(
        paths: [
          "/foo": [rel: "prefetch"],
          "bar/baz": [rel: "prefetch"]
        ],
        callback: &__MODULE__.ignore_non_root/2
      )

    conn =
      conn(:get, "/")
      |> @subject.call(opts)
      |> Plug.Conn.send_resp(200, "")

    informs = sent_informs(conn)
    assert {103, [{"link", "</foo>; rel=prefetch"}]} in informs
  end

  def always(_conn), do: true
  def never(_conn), do: false
  def maybe(conn), do: conn.private[:hint]

  def identity(_conn, path), do: path
  def add_test(_conn, path), do: Path.join("test", path)

  def ignore_non_root(_conn, "/" <> _ = path), do: path
  def ignore_non_root(_conn, _path), do: nil
end
