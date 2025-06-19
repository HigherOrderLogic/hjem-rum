{
  name = "programs-git";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.git = {
        enable = true;
        settings = {
          user.name = "Bob Rum";
          user.email = "bobrum@snugnug.org";
          merge.conflictstyle = "diff3";
          pull.rebase = true;
          push.autoSetupRemote = true;
          rebase.autoStash = true;
          safe.directory = "/tmp";
        };
        ignore = ''
          .direnv/
        '';
        attributes = ''
          * text=auto
          *.md linguist-detectable=true
        '';
      };
    };
  };

  testScript = ''
    # Waiting for our user to load.
    machine.succeed("loginctl enable-linger bob")
    machine.wait_for_unit("default.target")

    confPath = "/home/bob/.config/git"
    confFiles = [
        "config",
        "ignore",
        "attributes",
    ]
    machine.copy_from_host("${./config.ini}", "/home/bob/config")
    machine.copy_from_host("${./ignore}", "/home/bob/ignore")
    machine.copy_from_host("${./attributes}", "/home/bob/attributes")

    # Checks if the config files exist in the expected places with the expected config.
    for confFile in confFiles:
        machine.succeed(f"[ -r {confPath}/{confFile} ]")
        machine.succeed(f"diff -u -Z -b -B {confPath}/{confFile} /home/bob/{confFile}")

    machine.succeed("su bob -c 'git init'")

    # Test if global ignore applied correctly.
    machine.succeed("su bob -c \"git check-ignore .direnv/\"")
    machine.fail("su bob -c \"git check-ignore .envrc\"")

    # Test if global attribues applied correctly.
    var = machine.succeed("su bob -c 'git check-attr --all .'")
    assert ".: text: auto" in var, "'* text=auto' is not being set"
  '';
}
