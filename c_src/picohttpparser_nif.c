#include <erl_nif.h>
#include <picohttpparser.h>

static ERL_NIF_TERM parse_request(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    ErlNifBinary request_bin;
    if (!enif_inspect_binary(env, argv[0], &request_bin)) {
        return enif_make_badarg(env);
    }

    const char *method, *path;
    int pret, minor_version;
    struct phr_header headers[100];
    size_t method_len, path_len, num_headers;

    num_headers = sizeof(headers) / sizeof(headers[0]);
    pret = phr_parse_request((const char *)request_bin.data, request_bin.size,
                             &method, &method_len, &path, &path_len,
                             &minor_version, headers, &num_headers, 0);

    if (pret < 0) {
        return enif_make_atom(env, "error");
    }

    ERL_NIF_TERM method_term = enif_make_string_len(env, method, method_len, ERL_NIF_LATIN1);
    ERL_NIF_TERM path_term = enif_make_string_len(env, path, path_len, ERL_NIF_LATIN1);
    ERL_NIF_TERM version_term = enif_make_int(env, minor_version);

    ERL_NIF_TERM headers_list = enif_make_list(env, 0);
    for (size_t i = 0; i < num_headers; i++) {
        ERL_NIF_TERM name = enif_make_string_len(env, headers[i].name, headers[i].name_len, ERL_NIF_LATIN1);
        ERL_NIF_TERM value = enif_make_string_len(env, headers[i].value, headers[i].value_len, ERL_NIF_LATIN1);
        ERL_NIF_TERM header = enif_make_tuple2(env, name, value);
        headers_list = enif_make_list_cell(env, header, headers_list);
    }

    return enif_make_tuple4(env, method_term, path_term, version_term, headers_list);
}

static ErlNifFunc nif_funcs[] = {
    {"parse", 1, parse_request}
};

ERL_NIF_INIT(Elixir.PicoHTTPParser.NIF, nif_funcs, NULL, NULL, NULL, NULL)
