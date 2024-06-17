#include <assert.h>
#include <erl_nif.h>
#include <picohttpparser.h>
#include <string.h>

static ERL_NIF_TERM am_nil;
static ERL_NIF_TERM am_badarg;

static int
on_load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
{
  am_nil = enif_make_atom(env, "nil");
  am_badarg = enif_make_atom(env, "badarg");
  return 0;
}

static ERL_NIF_TERM
make_badarg(ErlNifEnv *env, ERL_NIF_TERM arg)
{
  ERL_NIF_TERM badarg = enif_make_tuple2(env, am_badarg, arg);
  return enif_raise_exception(env, badarg);
}

static ERL_NIF_TERM
parse_request(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
  ErlNifBinary request_bin;

  if (!enif_inspect_binary(env, argv[0], &request_bin))
    return make_badarg(env, argv[0]);

  const char *method, *path;
  int pret, minor_version;

  // TODO
  struct phr_header headers[256];
  size_t method_len, path_len, num_headers;

  num_headers = sizeof(headers) / sizeof(headers[0]);
  pret = phr_parse_request((const char *)request_bin.data, request_bin.size,
                           &method, &method_len, &path, &path_len,
                           &minor_version, headers, &num_headers, 0);

  // TODO
  if (pret < 0)
    return am_nil;

  ERL_NIF_TERM method_term = enif_make_sub_binary(env, argv[0], method - (const char *)request_bin.data, method_len);
  ERL_NIF_TERM path_term = enif_make_sub_binary(env, argv[0], path - (const char *)request_bin.data, path_len);
  ERL_NIF_TERM minor_version_term = enif_make_int(env, minor_version);

  ERL_NIF_TERM headers_list = enif_make_list(env, 0);

  for (size_t i = num_headers; i-- > 0;) // Count down from num_headers-1 to 0
  {
    ERL_NIF_TERM name = enif_make_sub_binary(env, argv[0], headers[i].name - (const char *)request_bin.data, headers[i].name_len);
    ERL_NIF_TERM value = enif_make_sub_binary(env, argv[0], headers[i].value - (const char *)request_bin.data, headers[i].value_len);
    ERL_NIF_TERM header = enif_make_tuple2(env, name, value);
    headers_list = enif_make_list_cell(env, header, headers_list);
  }

  return enif_make_tuple4(env, method_term, path_term, minor_version_term, headers_list);
}

static ErlNifFunc nif_funcs[] = {
    // TODO yeilding
    {"parse_request", 1, parse_request, 0},
};

ERL_NIF_INIT(Elixir.PicoHTTPParser, nif_funcs, on_load, NULL, NULL, NULL)
