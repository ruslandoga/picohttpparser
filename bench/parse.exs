defmodule Erl do
  def parse(request) do
    {:ok, {:http_request, method, {:abs_path, path}, version}, rest} =
      :erlang.decode_packet(:http_bin, request, [])

    {method, path, version, rest |> parse_headers() |> :lists.reverse()}
  end

  defp parse_headers(rest) do
    case :erlang.decode_packet(:httph_bin, rest, []) do
      {:ok, {:http_header, _, _, k, v}, rest} -> [{k, v} | parse_headers(rest)]
      {:ok, :http_eoh, ""} -> []
    end
  end
end

Benchee.run(
  %{
    "pico" => &PicoHTTPParser.parse/1,
    "erl" => &Erl.parse/1
  },
  inputs: %{"small" => "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n"}
)