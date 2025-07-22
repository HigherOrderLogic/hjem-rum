{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.types) listOf str;

  toFlags = concatStringsSep " " cfg.flags;

  cfg = config.rum.programs.zoxide;
in {
  options.rum.programs.zoxide = {
    enable = mkEnableOption "zoxide";

    package = mkPackageOption pkgs "zoxide" {nullable = true;};

    flags = mkOption {
      type = listOf str;
      default = [];
      example = [
        "--cmd cd"
      ];
      description = ''
        Command-line flags passed to `zoxide init`.
        Please reference [zoxide's documentation] for configuration options.

        [zoxide's documentation]: https://github.com/ajeetdsouza/zoxide#flags
      '';
    };

    integrations = {
      fish.enable = mkEnableOption "zoxide integration with fish";
      zsh.enable = mkEnableOption "zoxide integration with zsh";
      nushell.enable = mkEnableOption "zoxide integration with nushell";
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != true) [cfg.package];
    files = {
      /*
      Needs to be added to the end of the shell configuration files, hence the `mkIf` and `mkAfter`.
      https://github.com/ajeetdsouza/zoxide#installation
      */
      ".config/fish/config.fish".text = mkIf (config.rum.programs.fish.enable && cfg.integrations.fish.enable) (
        mkAfter "${getExe cfg.package} init fish ${toFlags} | source"
      );
      ".zshrc".text = mkIf (config.rum.programs.zsh.enable && cfg.integrations.zsh.enable) (
        mkAfter ''eval "$(${getExe cfg.package} init zsh ${toFlags})"''
      );
      ".config/nushell/config.nu".text = mkIf (config.rum.programs.nushell.enable && cfg.integrations.nushell.enable) (
        mkAfter ''
          source ${
            pkgs.runCommand "zoxide-init-nu" {} ''${getExe cfg.package} init nushell ${toFlags} >> "$out"''
          }
        ''
      );
    };
  };
}
