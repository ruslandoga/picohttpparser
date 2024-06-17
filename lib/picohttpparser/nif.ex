defmodule PicoHTTPParser.NIF do
  @moduledoc false
  @compile {:autoload, false}
  @on_load {:load_nif, 0}

  def load_nif do
    path = :filename.join(:code.priv_dir(:picohttpparser), ~c"picohttpparser_nif")
    :erlang.load_nif(path, 0)
  end

  def parse(_request), do: :erlang.nif_error(:nif_not_loaded)
end
