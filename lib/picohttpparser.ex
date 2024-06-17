defmodule PicoHTTPParser do
  @moduledoc """
  Documentation for `PicoHTTPParser`.
  """

  alias PicoHTTPParser.NIF

  def parse(request), do: NIF.parse(request)
end
