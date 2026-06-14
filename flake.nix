{
    description = "build tools";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };

    outputs = { self, nixpkgs }: 
    let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
        devShells.x86_64-linux.default = pkgs.mkShell {
            packages = with pkgs; [
                zig
                zls

                libGL

                # X11 dependencies for raylib
                libx11
                libx11.dev
                libxcursor
                libxi
                libxinerama
                libxrandr
            ];
        };

    };
}
