Benchee.run(
  %{
    "pico" => &PicoHTTPParser.parse/1,
    "erl" => &Erl.parse/1
  },
  inputs: %{"small" => "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n"}
)
