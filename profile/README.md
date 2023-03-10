# Hi there 👋



## Template


```bash
command -v curl || (command -v apt && sudo apt-get update && sudo apt-get install -y curl)
command -v curl || (command -v apk && sudo apk add --no-cache -y curl)


NIX_RELEASE_VERSION=2.10.2 \
&& curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh

export NIX_CONFIG='extra-experimental-features = nix-command flakes'


# Precisa das variáveis de ambiente USER e HOME

DIRETORY_TO_CLONE=/home/"$USER"/.config/nixpkgs

nix \
shell \
github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb#{git,bashInteractive,coreutils,gnused,home-manager} \
--command \
bash <<-EOF
    echo $DIRETORY_TO_CLONE
    mkdir -pv $DIRETORY_TO_CLONE

    cd $DIRETORY_TO_CLONE
    
    nix \
    flake \
    init \
    --template \
    github:PedroRegisPOAR/.github/feature/dx-with-nix-and-home-manager#templates.x86_64-linux.baseStartConfigGraphicalFull
    
    sed -i 's/username = ".*";/username = "'$USER'";/g' flake.nix \
    && git init \
    && git status \
    && git add . \
    && nix flake update --override-input nixpkgs github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb \
    && git status \
    && git add .
    
    
    export NIXPKGS_ALLOW_UNFREE=1 \
    && home-manager switch -b backuphm --impure --flake /home/"$USER"/.config/nixpkgs \
    && home-manager generations
    
    
    #
    TARGET_SHELL='zsh' \
    && FULL_TARGET_SHELL=/home/"$USER"/.nix-profile/bin/"$TARGET_SHELL" \
    && echo \
    && ls -al "$FULL_TARGET_SHELL" \
    && echo \
    && echo "$FULL_TARGET_SHELL" | sudo tee -a /etc/shells \
    && echo \
    && sudo \
          -k \
          usermod \
          -s \
          /home/"$USER"/.nix-profile/bin/"$TARGET_SHELL" \
          "$USER"
EOF
```



## Slim, home-manager + nix + zsh + fonts


```bash
command -v curl || (command -v apt && sudo apt-get update && sudo apt-get install -y curl)
command -v curl || (command -v apk && sudo apk add --no-cache -y curl)

NIX_RELEASE_VERSION=2.10.2 \
&& curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh

export NIX_CONFIG='extra-experimental-features = nix-command flakes'

nix \
shell \
github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb#{git,bashInteractive,coreutils,gnused,home-manager} \
--command \
bash <<-EOF

  echo $PATH | tr ':' '\n'

  {
  mkdir -pv /home/"$USER"/.config/nixpkgs \
  && ls -al /home/"$USER"/.config/nixpkgs \
  && tee /home/"$USER"/.config/nixpkgs/home.nix <<'NESTEDEOF'
  { pkgs, ... }:

  {

    home.packages = with pkgs; [
      btop
      coreutils
      curl
      git
      jq
      neovim
      openssh
      shadow
      tmate
      zsh

       (
         writeScriptBin "ix" ''
            "$@" | "curl" -F 'f:1=<-' ix.io
         ''
       )

       (
         writeScriptBin "gphms" ''
          echo $(cd "$HOME/.config/nixpkgs" && git pull) \
          && export NIXPKGS_ALLOW_UNFREE=1; \
          home-manager switch --impure --flake "$HOME/.config/nixpkgs"
         ''
       )

       (
         writeScriptBin "nr" ''
          nix repl --expr 'import <nixpkgs> {}'
         ''
       )

       (
         writeScriptBin "nfm" ''
           #! \${pkgs.runtimeShell} -e
           nix flake metadata $1 --json | jq -r '.url'
         ''
       )

    ];

    nix = {
      enable = true;
       package = pkgs.nixVersions.nix_2_10;
       extraOptions = "experimental-features = nix-command flakes";
    };

      # https://www.reddit.com/r/NixOS/comments/fenb4u/zsh_with_ohmyzsh_with_powerlevel10k_in_nix/
      programs.zsh = {
        # Your zsh config
        enable = true;
        enableCompletion = true;
        dotDir = ".config/zsh";
        enableAutosuggestions = true;
        enableSyntaxHighlighting = true;
        envExtra = ''
          if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
            . ~/.nix-profile/etc/profile.d/nix.sh
          fi
        '';

         # > closed and reopened the terminal. Then it worked.
         # https://discourse.nixos.org/t/home-manager-doesnt-seem-to-recognize-sessionvariables/8488/8
         sessionVariables = {
           LANG = "en_US.utf8";
         };

        historySubstringSearch.enable = true;

        history = {
          save = 50000;
          size = 50000;
          path = "$HOME/.cache/zsh_history";
          expireDuplicatesFirst = true;
        };

        oh-my-zsh = {
          enable = true;
          # plugins = (import ./zsh/plugins.nix) pkgs;
          # https://github.com/Xychic/NixOSConfig/blob/76b638086dfcde981292831106a43022588dc670/home/home-manager.nix
          plugins = [
            "colored-man-pages"
            "colorize"
            "fzf"
            "git"
            "git-extras"
            "github"
            "gitignore"
            "history"
            "history-substring-search"
            "man"
            "ssh-agent"
            "sudo"
            "systemadmin" # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/systemadmin
            "zsh-navigation-tools"
          ];
          theme = "robbyrussell";
        };
      };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        shell = { disabled = false; };
        rlang = { detect_files = [ ]; };
        python = { disabled = true; };
      };
    };

    programs.home-manager = {
      enable = true;
    };
  }
NESTEDEOF


tee /home/"$USER"/.config/nixpkgs/flake.nix <<'NESTEDEOF'
  {
    description = "Home Manager configuration";

    inputs = {
      # Specify the source of Home Manager and Nixpkgs
      home-manager.url = "github:nix-community/home-manager";
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { nixpkgs, home-manager, ... }:
      let
        system = "x86_64-linux";
        username = "vagrant";
      in {
        homeConfigurations.\${username} = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.\${system};

          modules = [
            {
              home = {
                inherit username;
                # TODO: esse caminho muda no Mac!
                homeDirectory = "/home/\${username}";
                stateVersion = "22.11";
              };
              programs.home-manager.enable = true;
            }
             ./home.nix
          ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
      };
  }
NESTEDEOF
} && echo 1234 \
&& cd /home/"$USER"/.config/nixpkgs/ \
&& echo 5678 \
&& sed -i 's/username = ".*";/username = "'$USER'";/g' flake.nix \
&& git init \
&& git status \
&& git add . \
&& nix flake update --override-input nixpkgs github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb \
&& git status \
&& git add .

# Estas linhas precisam das variáveis de ambiente USER e HOME
export NIXPKGS_ALLOW_UNFREE=1 \
&& home-manager switch -b backuphm --impure --flake ~/.config/nixpkgs \
&& home-manager generations


#
TARGET_SHELL='zsh' \
&& FULL_TARGET_SHELL=/home/"$USER"/.nix-profile/bin/"\$TARGET_SHELL" \
&& echo \
&& ls -al "\$FULL_TARGET_SHELL" \
&& echo \
&& echo "\$FULL_TARGET_SHELL" | sudo tee -a /etc/shells \
&& echo \
&& sudo \
      -k \
      usermod \
      -s \
      /home/"$USER"/.nix-profile/bin/"\$TARGET_SHELL" \
      "$USER"
EOF

# sudo reboot

```



## Broken


```bash 
command -v curl || (command -v apt && sudo apt-get update && sudo apt-get install -y curl)
command -v curl || (command -v apk && sudo apk add --no-cache -y curl)

NIX_RELEASE_VERSION=2.10.2 \
&& curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh

export NIX_CONFIG='extra-experimental-features = nix-command flakes'

nix \
shell \
github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb#{git,bashInteractive,coreutils,gnused,home-manager} \
--command \
bash <<-EOF
{

  mkdir -pv /home/"$USER"/.config/nixpkgs \
  && ls -al /home/"$USER"/.config/nixpkgs

  tee /home/"$USER"/.config/nixpkgs/home.nix <<'NESTEDEOF'
  { pkgs, ... }:
  {

    home.packages = with pkgs; [
      btop
      coreutils
      curl
      git
      jq
      neovim
      openssh
      shadow
      tmate
      zsh

      #
      nerdfonts

      # Graphical
#      1password-gui
#      discord
#      gimp
#      gitkraken
#      google-chrome
#      kolourpaint
#      obsidian
#      qbittorrent
#      slack
#      spotify
#      tdesktop
#      vscodium

      (
        writeScriptBin "ix" ''
         #! ${pkgs.runtimeShell} -e
           "$@" | "curl" -F 'f:1=<-' ix.io
        ''
      )
      (
        writeScriptBin "erw" ''
         #! ${pkgs.runtimeShell} -e
         echo "$(readlink -f "$(which $1)")"
       ''
       )

      (
        writeScriptBin "crw" ''
         #! ${pkgs.runtimeShell} -e
         cat "$(readlink -f "$(which $1)")"
       ''
      )

      (
        writeScriptBin "generate-new-ed25519-key-pair" ''
         #! ${pkgs.runtimeShell} -e
         ssh-keygen \
         -t ed25519 \
         -C "$(git config user.email)" \
         -f "${HOME}"/.ssh/id_ed25519 \
         -N '' \
         && echo \
         && cat "${HOME}"/.ssh/id_ed25519.pub \
         && echo
        ''
      )

      (
        writeScriptBin "gphms" ''
         #! ${pkgs.runtimeShell} -e
         echo $(cd "$HOME/.config/nixpkgs" && git pull) \
         && export NIXPKGS_ALLOW_UNFREE=1; \
         home-manager switch --impure --flake "$HOME/.config/nixpkgs"
        ''
      )

      (
        writeScriptBin "nr" ''
         #! ${pkgs.runtimeShell} -e
         nix repl --expr 'import <nixpkgs> {}'
        ''
      )

      (
        writeScriptBin "nfm" ''
          #! ${pkgs.runtimeShell} -e
          nix flake metadata $1 --json | jq -r '.url'
        ''
      )
    ];

    nix = {
      enable = true;
      package = pkgs.nixVersions.nix_2_10;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      settings = {
                   # use-sandbox = true;
                   show-trace = false;
                   keep-outputs = true;
                   keep-derivations = true;

                   # One month: 60 * 60 * 24 * 7 * 4 = 2419200
                   tarball-ttl = 60 * 60 * 24 * 7 * 4;
                 };
    };

    nixpkgs.config = {
                       allowBroken = false;
                       allowUnfree = true;
    };


    fonts = {
      fontconfig = {
        enable = true;
      };
    };

    home.extraOutputsToInstall = [
      "/share/zsh"
      "/share/bash"
      "/share/fish"
      "/share/fonts" # fc-cache -frv
      # /etc/fonts
    ];

    # https://www.reddit.com/r/NixOS/comments/fenb4u/zsh_with_ohmyzsh_with_powerlevel10k_in_nix/
    programs.zsh = {
      # Your zsh config
      enable = true;
      enableCompletion = true;
      dotDir = ".config/zsh";
      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;
      envExtra = ''
        if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
          . ~/.nix-profile/etc/profile.d/nix.sh
        fi
      '';

      initExtra = "${pkgs.neofetch}/bin/neofetch";
      autocd = true;

       # > closed and reopened the terminal. Then it worked.
       # https://discourse.nixos.org/t/home-manager-doesnt-seem-to-recognize-sessionvariables/8488/8
       sessionVariables = {
         LANG = "en_US.utf8";
         # fc-match list
         FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
         FONTCONFIG_PATH = "${pkgs.fontconfig.out}/etc/fonts/";
       };

      historySubstringSearch.enable = true;

      history = {
        save = 50000;
        size = 50000;
        path = "$HOME/.cache/zsh_history";
        expireDuplicatesFirst = true;
      };

      oh-my-zsh = {
        enable = true;
        # plugins = (import ./zsh/plugins.nix) pkgs;
        # https://github.com/Xychic/NixOSConfig/blob/76b638086dfcde981292831106a43022588dc670/home/home-manager.nix
        plugins = [
          # "autojump"
          "aws"
          # "cargo"
          "catimg"
          "colored-man-pages"
          "colorize"
          "command-not-found"
          "common-aliases"
          "copyfile"
          "copypath"
          "cp"
          "direnv"
          "docker"
          "docker-compose"
          "emacs"
          "encode64"
          "extract"
          "fancy-ctrl-z"
          "fzf"
          "gcloud"
          "git"
          "git-extras"
          "git-flow-avh"
          "github"
          "gitignore"
          "gradle"
          "history"
          "history-substring-search"
          "kubectl"
          "man"
          "mvn"
          "node"
          "npm"
          "pass"
          "pip"
          "poetry"
          "python"
          "ripgrep"
          "rsync"
          "rust"
          "scala"
          "ssh-agent"
          "sudo"
          "systemadmin" # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/systemadmin
          "systemd"
          "terraform"
          # "thefuck"
          "tig"
          "timer"
          # "tmux" # It needs to be installed
          "vagrant"
          "vi-mode"
          "vim-interaction"
          "yarn"
          "z"
          "zsh-navigation-tools"
        ];
        theme = "robbyrussell";
        # theme = "bira";
        # theme = "powerlevel10k";
        # theme = "powerlevel9k/powerlevel9k";
        # theme = "agnoster";
        # theme = "gallois";
        # theme = "gentoo";
        # theme = "af-magic";
        # theme = "half-life";
        # theme = "rgm";
        # theme = "crcandy";
        # theme = "fishy";
      };
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        shell = { disabled = false; };
        rlang = { detect_files = [ ]; };
        python = { disabled = true; };
      };
    };

    programs.home-manager = {
      enable = true;
    };
  }
NESTEDEOF


tee /home/"$USER"/.config/nixpkgs/flake.nix <<'NESTEDEOF'
  {
    description = "Home Manager configuration";

    inputs = {
      # Specify the source of Home Manager and Nixpkgs
      home-manager.url = "github:nix-community/home-manager";
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { nixpkgs, home-manager, ... }:
      let
        system = "x86_64-linux";
        username = "vagrant";
      in {
        homeConfigurations.\${username} = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.\${system};

          modules = [
            {
              home = {
                inherit username;
                # TODO: esse caminho muda no Mac!
                homeDirectory = "/home/\${username}";
                stateVersion = "22.11";
              };
              programs.home-manager.enable = true;
            }
             ./home.nix
          ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
      };
  }
NESTEDEOF

  echo \
  && cd /home/"$USER"/.config/nixpkgs/ \
  && sed -i 's/username = ".*";/username = "'$USER'";/g' flake.nix \
  && git init \
  && git status \
  && git add . \
  && nix flake update --override-input nixpkgs github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb \
  && git status \
  && git add .

  # Estas linhas precisam das variáveis de ambiente USER e HOME
  export NIXPKGS_ALLOW_UNFREE=1 \
  && home-manager switch -b backuphm --impure --flake "$HOME"/.config/nixpkgs \
  && home-manager generations
  
  #
  TARGET_SHELL='zsh' \
  && FULL_TARGET_SHELL=/home/"$USER"/.nix-profile/bin/"\$TARGET_SHELL" \
  && echo \
  && ls -al "\$FULL_TARGET_SHELL" \
  && echo \
  && echo "\$FULL_TARGET_SHELL" | sudo tee -a /etc/shells \
  && echo \
  && sudo \
        -k \
        usermod \
        -s \
        /home/"$USER"/.nix-profile/bin/"\$TARGET_SHELL" \
        "$USER"  
EOF

# sudo reboot
```
