{
  description = "nixpkgs-wayland";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    lib-aggregate = { url = "github:nix-community/lib-aggregate"; };
    nix-eval-jobs = { url = "github:nix-community/nix-eval-jobs"; };
    flake-compat = { url = "github:nix-community/flake-compat"; };
  };

  nixConfig = {
    extra-substituters = [
      "https://nixpkgs-wayland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };

  outputs = inputs:
    let
      inherit (inputs.lib-aggregate) lib;
      inherit (inputs) self;

      waylandOverlay = final: prev:
        let
          template = { attrName, nixpkgsAttrName ? "", extra ? { }, replace ? { }, replaceInput ? { } }: import ./templates/template.nix { inherit prev attrName extra replace nixpkgsAttrName replaceInput; };
          checkMutuallyExclusive = lib.mutuallyExclusive (map (e: e.attrName) attrsExtraChangesNeeded) (map (e: e.attrName) attrsNoExtraChangesNeeded);
          genPackagesGH =
            if checkMutuallyExclusive then
              lib.listToAttrs
                (map
                  (a: {
                    name = a.attrName;
                    value = template a;
                  })
                  (attrsExtraChangesNeeded ++ attrsNoExtraChangesNeeded)
                )
            else throw "some 'attrName' value is in both attrsExtraChangesNeeded and attrsNoExtraChangesNeeded";

          # these need extra nativeBuildInputs or buildInputs or the patches cleared
          attrsExtraChangesNeeded = [
            {
              attrName = "drm_info";
              extra.nativeBuildInputs = [ prev.scdoc ];
            }
            {
              attrName = "swaylock";
              replace.patches = [ ];
            }
            {
              attrName = "grim";
              replace.patches = [ ];
            }
            {
              attrName = "waybar";
              extra.buildInputs = [
                prev.libjack2
                prev.playerctl
              ];
              replace.postUnpack =
                let
                  # Derived from subprojects/cava.wrap
                  libcava = rec {
                    version = "0.9.1";
                    src = prev.fetchFromGitHub {
                      owner = "LukashonakV";
                      repo = "cava";
                      rev = version;
                      hash = "sha256-FnRJJV0poRmw+y4nt1X7Z0ipX86LRK1TJhNKHFk0rTw=";
                    };
                  };
                  # Derived from subprojects/catch2.wrap
                  catch2 = rec {
                    version = "3.5.1";
                    src = prev.fetchFromGitHub {
                      owner = "catchorg";
                      repo = "Catch2";
                      rev = "v${version}";
                      hash = "sha256-OyYNUfnu6h1+MfCF8O+awQ4Usad0qrdCtdZhYgOY+Vw=";
                    };
                  };
                in
                ''
                  (
                    cd "$sourceRoot"
                    cp -R --no-preserve=mode,ownership ${libcava.src} subprojects/cava-${libcava.version}
                    cp -R --no-preserve=mode,ownership ${catch2.src} subprojects/Catch2-${catch2.version}
                    patchShebangs .
                  )
                '';
            }
            {
              attrName = "gtk-layer-shell";
              extra.nativeBuildInputs = [ prev.vala ];
              replace.patches = [ ];
            }
            {
              attrName = "sway-unwrapped";
              extra.buildInputs = [ prev.xorg.xcbutilwm ];
              replaceInput = {
                wlroots = final.wlroots;
                wayland-protocols = final.new-wayland-protocols;
              };
              replace = oldAttrs: {
                patches =
                  let
                    conflicting-patch = (prev.fetchpatch {
                      name = "LIBINPUT_CONFIG_ACCEL_PROFILE_CUSTOM.patch";
                      url = "https://github.com/swaywm/sway/commit/dee032d0a0ecd958c902b88302dc59703d703c7f.diff";
                      hash = "sha256-dx+7MpEiAkxTBnJcsT3/1BO8rYRfNLecXmpAvhqGMD0=";
                    });
                  in
                  lib.remove conflicting-patch oldAttrs.patches;
              };
            }
            {
              attrName = "cage";
              extra.buildInputs = [ prev.xorg.xcbutilwm ];
              replaceInput = {
                wlroots = prev.wlroots_0_16;
              };
              # _FORTIFY_SOURCE requires compiling with optimization (-O)
              # PR https://github.com/NixOS/nixpkgs/pull/232917 added -O0
              replace.CFLAGS = "";
            }
            {
              attrName = "wob";
              extra.buildInputs = [ prev.pixman prev.cmocka ];
            }
            {
              attrName = "libvncserver_master";
              nixpkgsAttrName = "libvncserver";
            }
            {
              attrName = "wayvnc";
              nixpkgsAttrName = "wayvnc";
              extra.buildInputs = [ prev.jansson ];
            }
            {
              attrName = "wf-recorder";
              extra.buildInputs = [ prev.mesa ];
            }
            {
              attrName = "xdg-desktop-portal-wlr";
              nixpkgsAttrName = "xdg-desktop-portal-wlr";
              replace.patches = [ ];
            }
            {
              attrName = "new-wayland-protocols";
              nixpkgsAttrName = "wayland-protocols";
            }
            {
              attrName = "wl-screenrec";
              # soon in nixpkgs
              extra.buildInputs = [ prev.libdrm ];
              replace.doCheck = false;
            }
            {
              attrName = "wbg";
              extra.buildInputs = [ prev.pixman ];
            }
          ];

          # these do not need changes from the package that nixpkgs has
          attrsNoExtraChangesNeeded = lib.attrValues (lib.genAttrs [
            "dunst"
            "gebaar-libinput"
            "glpaper"
            "imv"
            "mako"
            "neatvnc"
            "slurp"
            "swaybg"
            "swayidle"
            "swaylock-effects"
            "wl-clipboard"
            "wlogout"
            "wlr-randr"
            "wofi"
            "wtype"
            "wshowkeys"
            "aml"
            "wdisplays"
            "kanshi"
            "wev"
            "lavalauncher"
            "wlsunset"
            "rootbar"
            "waypipe"
            "sirula"
            "eww"
            "eww-wayland"
            "swww"
            "wlay"
            "i3status-rust"
            "shotman"
          ]
            (s: { attrName = s; }));

          waylandPkgs = genPackagesGH // rec {
            # wlroots-related
            salut = prev.callPackage ./pkgs/salut { };
            wayprompt = prev.callPackage ./pkgs/wayprompt {
              zig = prev.zig_0_11;
            };
            wlvncc = prev.callPackage ./pkgs/wlvncc {
              libvncserver = final.libvncserver_master;
            };
            obs-wlrobs = template {
              nixpkgsAttrName = "obs-studio-plugins.wlrobs";
              attrName = "obs-wlrobs";
            };
            # the above should actually be, but there's eval error and doing
            # 'nix build -f packages.nix' would build all packages in obs-studio-plugins
            # obs-studio-plugins = prev.obs-studio-plugins // {
            #   wlrobs = template {
            #     nixpkgsAttrName = "obs-studio-plugins.wlrobs";
            #     attrName = "wlrobs";
            #   };
            # };
            wldash = prev.callPackage ./pkgs/wldash { };
            wlroots = prev.callPackage ./pkgs/wlroots {
              inherit (prev) wlroots;
              wayland-protocols = final.new-wayland-protocols;
            };

            wl-gammarelay-rs = prev.callPackage ./pkgs/wl-gammarelay-rs { };

            freerdp3 = prev.callPackage ./pkgs/freerdp3 {
              inherit (prev.darwin.apple_sdk.frameworks) AudioToolbox AVFoundation Carbon Cocoa CoreMedia;
              inherit (prev.gst_all_1) gstreamer gst-plugins-base gst-plugins-good;
            };

            # misc
            foot = prev.callPackage ./pkgs/foot {
              inherit foot;
            };
          };
        in
        (waylandPkgs // { inherit waylandPkgs; });
    in
    lib.flake-utils.eachSystem [ "aarch64-linux" "x86_64-linux" "riscv64-linux" ]
      (system:
        let
          pkgsFor = pkgs: overlays:
            import pkgs {
              inherit system overlays;
              config.allowUnfree = true;
              config.allowAliases = false;
            };
          pkgs_ = lib.genAttrs (builtins.attrNames inputs) (inp: pkgsFor inputs."${inp}" [ ]);
          opkgs_ = overlays: lib.genAttrs (builtins.attrNames inputs) (inp: pkgsFor inputs."${inp}" overlays);
          waypkgs = (opkgs_ [ self.overlays.default ]).nixpkgs;
        in
        {
          devShells.default = pkgs_.nixpkgs.mkShell {
            nativeBuildInputs = with pkgs_.nixpkgs; [
              nix
              nushell
              cachix
              cacert
              git
              mercurial
              ripgrep
              sd
              inputs.nix-eval-jobs.outputs.packages.${system}.default
            ];
          };

          formatter = pkgs_.nixpkgs.nixpkgs-fmt;

          bundle = pkgs_.nixpkgs.symlinkJoin {
            name = "nixpkgs-wayland-bundle";
            paths = builtins.attrValues waypkgs.waylandPkgs;
          };

          packages = (waypkgs.waylandPkgs);
        })
    // {
      # overlays have to be outside of eachSystem block
      overlay = waylandOverlay;

      overlays.default = waylandOverlay;
    };
}
