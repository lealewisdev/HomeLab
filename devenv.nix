{ pkgs, ... }:

{
  packages = [
    pkgs.hadolint
    pkgs.prek
    pkgs.nixfmt
    pkgs.typos
    pkgs.ansible-lint
  ];
  env.LC_ALL = "C.UTF-8";
  env.LANG = "C.UTF-8";
  scripts.lint.exec = "prek run --all-files";
}
