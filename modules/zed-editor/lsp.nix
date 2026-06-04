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
}
