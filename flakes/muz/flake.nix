{
  description = "Flake: Pure Data / tracker-focused retro-music dev shell";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # set allowUnfree = true if you want some unfree synths/trackers later
          config = { allowUnfree = true; };
        };

        musicPkgs = with pkgs; [
          # core: Pure Data (Pd)
          puredata   # exposes 'pdsend/pdreceive' etc and 'pd' binary

          # JACK / audio routing
          jack2
          qjackctl
          alsa-utils
          pipewire # optional modern backend

          # Classic trackers & chiptune tools
          milkytracker
          schismtracker

          # Emulators helpful for vintage sound testing
          dosbox-staging
          fceux
          scummvm

          # Synths / samplers / utilities
          fluidsynth
          zynaddsubfx
          sox
          ffmpeg
          mpv
          cava

          # GUI helpers / recording
          audacity
        ];

      in {
        devShells.default = pkgs.mkShell {
          name = "pd-music-shell";

          buildInputs = musicPkgs;

          # Useful runtime environment (JACK settings, Pd-friendly aliases)
          shellHook = ''
            echo "🎛️  Entered Pure Data music dev shell"
            echo " - To manage JACK: run 'qjackctl' or 'jack_control --help'"
            echo " - To run Pd (GUI):       pd"
            echo " - To run Pd (nogui):     pd -nogui -open yourpatch.pd"
            echo " - To send OSC/MIDI test: use 'pdsend' / 'pdreceive' and 'fluidsynth'"

            # sensible default JACK envs for low-latency experimenting
            export JACK_DEFAULT_OUTPUTS=2
            export JACK_DEFAULT_INPUTS=2
            export PULSE_LATENCY_MSEC=60

            # Helpful aliases
            alias start-jack="qjackctl & disown; echo 'qjackctl started'"
            alias pdnogui='pd -nogui'
            alias pdopen='pd -open'
            alias vstest='fluidsynth -a jack -m alsa_seq /usr/share/sounds/sf2/FluidR3_GM.sf2'
            alias record-audio='ffmpeg -f jack -i system:playback -t 00:00:30 out.wav'

            # small function to connect Pd to system playback via JACK (requires jackd running)
            pd2system() {
              if ! command -v jack_lsp >/dev/null 2>&1; then
                echo "jack_lsp not found; start jackd / qjackctl first"
                return 1
              fi
              echo "Connecting Pd -> system playback (JACK)"
              # attempt to connect "pd" output ports to system playback ports
              # ignore errors if ports not present
              jack_connect pd:out_1 system:playback_1 2>/dev/null || true
              jack_connect pd:out_2 system:playback_2 2>/dev/null || true
              echo "Done (errors ignored if ports missing)"
            }

            echo
            echo "Shortcuts: start-jack | pd | pdnogui | pd2system | vstest"
          '';
        };
      });
}

