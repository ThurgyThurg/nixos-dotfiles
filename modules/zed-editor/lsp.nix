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
  markdown = {
    settings = {
      format_on_save = "on";
  };
};
