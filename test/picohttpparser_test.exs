defmodule PicoHTTPParserTest do
  use ExUnit.Case, async: true

  test "it works" do
    assert {~c"GET", ~c"/", 1, [{~c"Host", ~c"example.com"}]} =
             PicoHTTPParser.parse("GET / HTTP/1.1\r\nHost: example.com\r\n\r\n")
  end
end
