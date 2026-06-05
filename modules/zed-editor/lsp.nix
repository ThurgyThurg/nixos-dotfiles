{
  nil = {
    binary = {
      path_lookup = true;
    };
    settings = {
      formatting = {
        command = ["alejandra"];
      };
      diagnostics = {
        ignored = [
          "unused_binding"
        ];
      };
    };
  };
  lua-language-server.binary.path_lookup = true;
}
