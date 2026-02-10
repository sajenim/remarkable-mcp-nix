# remarkable-mcp-nix

NixOS and Home Manager modules for [remarkable-mcp](https://github.com/SamMorrowDrums/remarkable-mcp) with secrets management.

## Installation

Add to your flake inputs and include the appropriate module:

```nix
{
  inputs.remarkable-mcp.url = "github:sajenim/remarkable-mcp-nix";

  # NixOS
  nixosConfigurations.host = nixpkgs.lib.nixosSystem {
    modules = [ remarkable-mcp.nixosModules.default ];
  };

  # Home Manager
  homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
    modules = [ remarkable-mcp.homeManagerModules.default ];
  };
}
```

## Configuration

```nix
{
  services.remarkable-mcp = {
    enable = true;
    mode = "ssh";  # or "cloud"

    secrets = {
      sshKeyFile = config.age.secrets.remarkable-ssh.path;      # SSH mode
      # cloudTokenFile = config.age.secrets.remarkable-token.path;  # cloud mode
      googleVisionKeyFile = config.age.secrets.google-vision.path;  # optional
    };

    remarkable = {
      host = "10.11.99.1";  # SSH mode only
      ocrBackend = "google";
      # rootPath = "/My Folder";  # optional: limit access
    };
  };
}
```

NixOS module also requires `user = "youruser";` to specify which user gets `uv` installed.

## Usage

Add to your `.mcp.json`:

```json
{
  "mcpServers": {
    "remarkable": { "command": "remarkable-mcp" }
  }
}
```

## Cloud Mode Setup

Register your device before enabling the module:
```bash
nix shell nixpkgs#uv -c uvx remarkable-mcp --register YOUR_CODE
```
Get `YOUR_CODE` from [my.remarkable.com/device/desktop/connect](https://my.remarkable.com/device/desktop/connect).

## OCR Backends

| Backend | Requires | Best For |
|---------|----------|----------|
| `google` | API key | Handwriting (most accurate) |
| `sampling` | Nothing | Handwriting (uses AI client) |
| `tesseract` | Nothing | Printed text only |
| `auto` | Optional API key | Automatic selection |

## License

MIT
