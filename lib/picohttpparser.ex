defmodule PicoHTTPParser do
  @moduledoc """
  Parse HTTP packets using picohttpparser.
  """

  def parse_request(_request), do: :erlang.nif_error(:undef)

  @compile {:autoload, false}
  @on_load {:load_nif, 0}

  @doc false
  def load_nif do
    :code.priv_dir(:picohttpparser)
    |> :filename.join(~c"picohttpparser_nif")
    |> :erlang.load_nif(0)
  end
end
