# remarkable-mcp-nix

NixOS and Home Manager modules for [remarkable-mcp](https://github.com/SamMorrowDrums/remarkable-mcp) with secrets management.

## What This Does

Provides a `remarkable-mcp` wrapper that:
- Reads secrets from files at runtime
- Sets environment variables
- Calls `uvx remarkable-mcp` with correct flags

## Requirements

- NixOS or Home Manager
- Remarkable tablet with either:
  - [Developer mode enabled](https://remarkable.guide/guide/access/ssh.html) (SSH mode)
  - reMarkable Connect subscription (cloud mode)
- Google Cloud Vision API key (optional, for handwriting OCR)

## Installation

### NixOS

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    remarkable-mcp.url = "github:YOUR_USERNAME/remarkable-mcp-nix";
  };

  outputs = { nixpkgs, remarkable-mcp, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      modules = [
        remarkable-mcp.nixosModules.default
      ];
    };
  };
}
```

### Home Manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    remarkable-mcp.url = "github:YOUR_USERNAME/remarkable-mcp-nix";
  };

  outputs = { nixpkgs, home-manager, remarkable-mcp, ... }: {
    homeConfigurations.youruser = home-manager.lib.homeManagerConfiguration {
      modules = [
        remarkable-mcp.homeManagerModules.default
      ];
    };
  };
}
```

## Configuration

### NixOS

#### SSH Mode (default)

```nix
{
  services.remarkable-mcp = {
    enable = true;
    user = "youruser";
    mode = "ssh";

    secrets = {
      googleVisionKeyFile = "/run/secrets/google-vision-api-key";
      sshKeyFile = "/run/secrets/remarkable-ssh-key";
    };

    remarkable = {
      host = "10.11.99.1";  # USB default
      ocrBackend = "google";
    };
  };
}
```

#### Cloud Mode

First, generate a token:
```bash
uvx remarkable-mcp --register YOUR_CODE
# Get YOUR_CODE from my.remarkable.com/device/desktop/connect
```

```nix
{
  services.remarkable-mcp = {
    enable = true;
    user = "youruser";
    mode = "cloud";

    secrets = {
      googleVisionKeyFile = "/run/secrets/google-vision-api-key";
      cloudTokenFile = "/run/secrets/remarkable-cloud-token";
    };

    remarkable.ocrBackend = "google";
  };
}
```

#### With agenix

```nix
{
  age.secrets = {
    google-vision-api-key.file = ./secrets/google-vision.age;
    remarkable-ssh-key = {
      file = ./secrets/remarkable-ssh.age;
      mode = "600";
    };
  };

  services.remarkable-mcp = {
    enable = true;
    user = "youruser";
    secrets = {
      googleVisionKeyFile = config.age.secrets.google-vision-api-key.path;
      sshKeyFile = config.age.secrets.remarkable-ssh-key.path;
    };
  };
}
```

### Home Manager

#### SSH Mode (default)

```nix
{
  services.remarkable-mcp = {
    enable = true;
    mode = "ssh";

    secrets = {
      googleVisionKeyFile = "/run/secrets/google-vision-api-key";
      sshKeyFile = "/run/secrets/remarkable-ssh-key";
    };

    remarkable = {
      host = "10.11.99.1";
      ocrBackend = "google";
    };
  };
}
```

#### Cloud Mode

```nix
{
  services.remarkable-mcp = {
    enable = true;
    mode = "cloud";

    secrets = {
      googleVisionKeyFile = "/run/secrets/google-vision-api-key";
      cloudTokenFile = "/run/secrets/remarkable-cloud-token";
    };

    remarkable.ocrBackend = "google";
  };
}
```

#### With agenix (via NixOS)

When using Home Manager as a NixOS module, you can reference agenix secrets:

```nix
{
  services.remarkable-mcp = {
    enable = true;
    secrets = {
      googleVisionKeyFile = config.age.secrets.google-vision-api-key.path;
      sshKeyFile = config.age.secrets.remarkable-ssh-key.path;
    };
  };
}
```

## Usage

After rebuilding, create a `.mcp.json` in your project:

```json
{
  "mcpServers": {
    "remarkable": {
      "command": "remarkable-mcp",
      "args": []
    }
  }
}
```

That's it. MCP clients will use the wrapper which handles secrets.

## Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the module |
| `user` | string | required | User to install `uv` for (NixOS only) |
| `mode` | `"ssh"` \| `"cloud"` | `"ssh"` | Connection mode |
| `secrets.googleVisionKeyFile` | path | `null` | Google Vision API key file |
| `secrets.sshKeyFile` | path | `null` | SSH private key file (SSH mode) |
| `secrets.cloudTokenFile` | path | `null` | Cloud token file (cloud mode) |
| `remarkable.host` | string | `"10.11.99.1"` | Tablet IP (SSH mode) |
| `remarkable.ocrBackend` | enum | `"google"` | OCR backend |
| `remarkable.rootPath` | string | `null` | Limit to specific folder |

## OCR Backends

| Backend | Requires | Best For |
|---------|----------|----------|
| `google` | API key | Handwriting (most accurate) |
| `sampling` | Nothing | Handwriting (uses AI client) |
| `tesseract` | Nothing | Printed text only |
| `auto` | Optional API key | Automatic selection |

## License

MIT
