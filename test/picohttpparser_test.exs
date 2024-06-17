defmodule PicoHTTPParserTest do
  use ExUnit.Case, async: true

  test "it works" do
    packet = "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n"
    assert PicoHTTPParser.parse(packet) == {~c"GET", ~c"/", 1, [{~c"Host", ~c"example.com"}]}
  end

  # https://github.com/erlang/otp/pull/6900
  describe "ipv6" do
    test "with port" do
      packet =
        "GET http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:4000/echo_components HTTP/1.1\r\nhost: orange\r\n\r\n"

      assert PicoHTTPParser.parse(packet) ==
               {~c"GET",
                ~c"http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:4000/echo_components", 1,
                [{~c"host", ~c"orange"}]}

      # compare to
      assert :erlang.decode_packet(:http_bin, packet, []) ==
               {:ok,
                {:http_request, :GET,
                 {:absoluteURI, :http, "[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]", 4000,
                  "/echo_components"}, {1, 1}}, "host: orange\r\n\r\n"}
    end

    test "no port" do
      packet =
        "GET http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]/1234 HTTP/1.1\r\nhost: orange\r\n\r\n"

      assert PicoHTTPParser.parse(packet) ==
               {~c"GET", ~c"http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]/1234", 1,
                [{~c"host", ~c"orange"}]}

      # compare to
      assert :erlang.decode_packet(:http_bin, packet, []) ==
               {:ok,
                {:http_request, :GET,
                 {:absoluteURI, :http, "[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]", :undefined,
                  "/1234"}, {1, 1}}, "host: orange\r\n\r\n"}
    end

    test "short ipv6 form" do
      packet = "GET http://[::1]/1234 HTTP/1.1\r\nhost: orange\r\n\r\n"

      assert PicoHTTPParser.parse(packet) ==
               {~c"GET", ~c"http://[::1]/1234", 1, [{~c"host", ~c"orange"}]}

      # compare to
      assert :erlang.decode_packet(:http_bin, packet, []) ==
               {:ok,
                {:http_request, :GET, {:absoluteURI, :http, "[::1]", :undefined, "/1234"},
                 {1, 1}}, "host: orange\r\n\r\n"}
    end

    # TODO
    test "missing `]`" do
      packet =
        "GET http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210:4000/echo_components HTTP/1.1\r\nhost: orange\r\n\r\n"

      assert PicoHTTPParser.parse(packet) ==
               {~c"GET", ~c"http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210:4000/echo_components",
                1, [{~c"host", ~c"orange"}]}

      # compare to
      assert :erlang.decode_packet(:http_bin, packet, []) ==
               {:ok,
                {
                  :http_request,
                  :GET,
                  # hm...
                  {:absoluteURI, :http, "[FEDC", :undefined, "/echo_components"},
                  {1, 1}
                }, "host: orange\r\n\r\n"}
    end
  end
end
