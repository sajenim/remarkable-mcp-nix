{ config, lib, pkgs, ... }:

let
  cfg = config.services.remarkable-mcp;
in
{
  options.services.remarkable-mcp = {
    enable = lib.mkEnableOption "remarkable-mcp integration";

    user = lib.mkOption {
      type = lib.types.str;
      description = "User account to configure remarkable-mcp for";
    };

    mode = lib.mkOption {
      type = lib.types.enum [ "ssh" "cloud" ];
      default = "ssh";
      description = ''
        Connection mode:
        - ssh: Direct connection via USB/WiFi (requires developer mode)
        - cloud: Via reMarkable cloud API (requires Connect subscription)
      '';
    };

    secrets = {
      googleVisionKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to file containing Google Vision API key.
          The file should contain only the API key, no newlines.
        '';
      };

      cloudTokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to file containing reMarkable cloud token.
          Only used in cloud mode. Generate via: uvx remarkable-mcp --register YOUR_CODE
        '';
      };
    };

    remarkable = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "10.11.99.1";
        description = ''
          Remarkable tablet hostname or SSH config alias.
          Use an SSH alias to configure key-based authentication.
          Only used in SSH mode.
        '';
      };

      ocrBackend = lib.mkOption {
        type = lib.types.enum [ "sampling" "google" "tesseract" "auto" ];
        default = "google";
        description = ''
          OCR backend for handwriting recognition:
          - sampling: Uses client AI model (no API key needed)
          - google: Google Cloud Vision (best accuracy)
          - tesseract: Offline, printed text only
          - auto: Automatic selection
        '';
      };

      rootPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Limit remarkable-mcp access to specific folder";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.mode == "cloud" -> cfg.secrets.cloudTokenFile != null;
        message = "services.remarkable-mcp.secrets.cloudTokenFile is required for cloud mode";
      }
    ];

    users.users.${cfg.user}.packages = [ pkgs.uv ];

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "remarkable-mcp" ''
        set -euo pipefail

        # Static config
        export REMARKABLE_OCR_BACKEND="${cfg.remarkable.ocrBackend}"
        ${lib.optionalString (cfg.mode == "ssh") ''
          export REMARKABLE_SSH_HOST="${cfg.remarkable.host}"
        ''}
        ${lib.optionalString (cfg.remarkable.rootPath != null) ''
          export REMARKABLE_ROOT_PATH="${cfg.remarkable.rootPath}"
        ''}

        # Secrets from files
        ${lib.optionalString (cfg.secrets.googleVisionKeyFile != null) ''
          if [[ -r "${cfg.secrets.googleVisionKeyFile}" ]]; then
            export GOOGLE_VISION_API_KEY=$(${pkgs.coreutils}/bin/cat \
              "${cfg.secrets.googleVisionKeyFile}" | ${pkgs.coreutils}/bin/tr -d '\n')
          fi
        ''}

        ${lib.optionalString (cfg.mode == "cloud" && cfg.secrets.cloudTokenFile != null) ''
          if [[ -r "${cfg.secrets.cloudTokenFile}" ]]; then
            export REMARKABLE_TOKEN=$(${pkgs.coreutils}/bin/cat \
              "${cfg.secrets.cloudTokenFile}" | ${pkgs.coreutils}/bin/tr -d '\n')
          else
            echo "Error: Cannot read cloud token file" >&2
            exit 1
          fi
        ''}

        # Run remarkable-mcp
        exec ${pkgs.uv}/bin/uvx remarkable-mcp ${lib.optionalString (cfg.mode == "ssh") "--ssh"} "$@"
      '')
    ];
  };
}
