{
  agent_servers = {
    claude-acp.type = "registry";
  };
  hour_format = "hour12";
  vim_mode = false;
  load_direnv = "shell_hook";
  base_keymap = "VSCode";
  icon_theme = "Zed (Default)";
  show_whitespaces = "trailing";
  ui_font_size = 14;
  buffer_font_size = 12;
  theme.mode = dark;
  formatter = "language_server";
  telemetry = {
    diagnostics = false;
    metrics = false;
  };
  sessions.trust_all_worktrees = true;
}
