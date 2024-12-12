defmodule PicoHTTPParserTest do
  use ExUnit.Case, async: true

  test "incomplete packet" do
    packet = "GET / HTTP/1.1\r\nHost: example.com\r\n"
    assert PicoHTTPParser.parse_request(packet) == -2
  end

  test "request with body" do
    packet = "POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: 5\r\n\r\nhello"

    assert PicoHTTPParser.parse_request(packet) ==
             {"POST", "/", 1, [{"Host", "example.com"}, {"Content-Length", "5"}], "hello"}
  end

  test "it works" do
    packet = "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n"
    assert PicoHTTPParser.parse_request(packet) == {"GET", "/", 1, [{"Host", "example.com"}], ""}

    packet =
      "GET /wp-content/uploads/2010/03/hello-kitty-darth-vader-pink.jpg HTTP/1.1\r\n" <>
        "Host: www.kittyhell.com\r\n" <>
        "User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; ja-JP-mac; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 " <>
        "Pathtraq/0.9\r\n" <>
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n" <>
        "Accept-Language: ja,en-us;q=0.7,en;q=0.3\r\n" <>
        "Accept-Encoding: gzip,deflate\r\n" <>
        "Accept-Charset: Shift_JIS,utf-8;q=0.7,*;q=0.7\r\n" <>
        "Keep-Alive: 115\r\n" <>
        "Connection: keep-alive\r\n" <>
        "Cookie: wp_ozh_wsa_visits=2; wp_ozh_wsa_visit_lasttime=xxxxxxxxxx; " <>
        "__utma=xxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.x; " <>
        "__utmz=xxxxxxxxx.xxxxxxxxxx.x.x.utmccn=(referral)|utmcsr=reader.livedoor.com|utmcct=/reader/|utmcmd=referral\r\n" <>
        "\r\n"

    assert PicoHTTPParser.parse_request(packet) ==
             {"GET", "/wp-content/uploads/2010/03/hello-kitty-darth-vader-pink.jpg", 1,
              [
                {"Host", "www.kittyhell.com"},
                {"User-Agent",
                 "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; ja-JP-mac; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 Pathtraq/0.9"},
                {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
                {"Accept-Language", "ja,en-us;q=0.7,en;q=0.3"},
                {"Accept-Encoding", "gzip,deflate"},
                {"Accept-Charset", "Shift_JIS,utf-8;q=0.7,*;q=0.7"},
                {"Keep-Alive", "115"},
                {"Connection", "keep-alive"},
                {"Cookie",
                 "wp_ozh_wsa_visits=2; wp_ozh_wsa_visit_lasttime=xxxxxxxxxx; __utma=xxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.x; __utmz=xxxxxxxxx.xxxxxxxxxx.x.x.utmccn=(referral)|utmcsr=reader.livedoor.com|utmcct=/reader/|utmcmd=referral"}
              ], ""}

    assert Erl.parse(packet) ==
             {:GET, {:abs_path, "/wp-content/uploads/2010/03/hello-kitty-darth-vader-pink.jpg"},
              {1, 1},
              [
                {"Host", "www.kittyhell.com"},
                {"User-Agent",
                 "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; ja-JP-mac; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 Pathtraq/0.9"},
                {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
                {"Accept-Language", "ja,en-us;q=0.7,en;q=0.3"},
                {"Accept-Encoding", "gzip,deflate"},
                {"Accept-Charset", "Shift_JIS,utf-8;q=0.7,*;q=0.7"},
                {"Keep-Alive", "115"},
                {"Connection", "keep-alive"},
                {"Cookie",
                 "wp_ozh_wsa_visits=2; wp_ozh_wsa_visit_lasttime=xxxxxxxxxx; __utma=xxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.x; __utmz=xxxxxxxxx.xxxxxxxxxx.x.x.utmccn=(referral)|utmcsr=reader.livedoor.com|utmcct=/reader/|utmcmd=referral"}
              ]}
  end

  # https://github.com/erlang/otp/pull/6900
  describe "ipv6" do
    test "with port" do
      packet =
        "GET http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:4000/echo_components HTTP/1.1\r\nhost: orange\r\n\r\n"

      assert PicoHTTPParser.parse_request(packet) ==
               {"GET", "http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:4000/echo_components", 1,
                [{"host", "orange"}], ""}

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

      assert PicoHTTPParser.parse_request(packet) ==
               {"GET", "http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]/1234", 1,
                [{"host", "orange"}], ""}

      # compare to
      assert :erlang.decode_packet(:http_bin, packet, []) ==
               {:ok,
                {:http_request, :GET,
                 {:absoluteURI, :http, "[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]", :undefined,
                  "/1234"}, {1, 1}}, "host: orange\r\n\r\n"}
    end

    test "short ipv6 form" do
      packet = "GET http://[::1]/1234 HTTP/1.1\r\nhost: orange\r\n\r\n"

      assert PicoHTTPParser.parse_request(packet) ==
               {"GET", "http://[::1]/1234", 1, [{"host", "orange"}], ""}

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

      assert PicoHTTPParser.parse_request(packet) ==
               {"GET", "http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210:4000/echo_components", 1,
                [{"host", "orange"}], ""}

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
