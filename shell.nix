{
  pkgs ? import <nixpkgs> {}
}:

pkgs.mkShell {
  name = "dev-environment";
  buildInputs = [
    pkgs.gimp
  ];
  shellHook = ''
    echo "Start using gimp..."
  '';
}
