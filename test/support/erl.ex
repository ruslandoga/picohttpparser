defmodule Erl do
  def parse(request) do
    {:ok, {:http_request, method, path, version}, rest} =
      :erlang.decode_packet(:http_bin, request, [])

    {method, path, version, parse_headers(rest)}
  end

  defp parse_headers(rest) do
    case :erlang.decode_packet(:httph_bin, rest, []) do
      {:ok, {:http_header, _, _, k, v}, rest} -> [{k, v} | parse_headers(rest)]
      {:ok, :http_eoh, ""} -> []
    end
  end
end
