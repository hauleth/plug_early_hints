ExUnit.start()

defmodule PlugTestHTTP2 do
  @behaviour Plug.Conn.Adapter

  defmacro __using__(_opts) do
    quote do
      import Plug.Test, except: [conn: 2, conn: 3]
      import Plug.Conn
      import unquote(__MODULE__), only: [conn: 2, conn: 3]
    end
  end

  @error {:error, :unimplemented}

  def conn(method, path, version \\ :"HTTP/2"),
    do:
      Plug.Adapters.Test.Conn.conn(
        %Plug.Conn{adapter: {__MODULE__, version}},
        method,
        path,
        nil
      )

  def chunk(_payload, _body), do: @error
  def get_http_protocol(payload), do: payload
  def get_peer_data(_payload), do: %{address: {127, 0, 0, 1}, port: 2137, ssl_cert: nil}
  def inform(_payload, _status, _headers), do: @error
  def push(_payload, _path, _headers), do: @error
  def read_req_body(_payload, _options), do: @error
  def send_chunked(_payload, _status, _headers), do: @error
  def send_file(_payload, _status, _headers, _file, _offset, _length), do: @error
  def send_resp(_payload, _status, _headers, _body), do: @error
end
