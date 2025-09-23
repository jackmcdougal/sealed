# Local Development Guide for Sealed

## Prerequisites

1. **Install Clickable**:
   ```bash
   # Install clickable
   pip3 install --user clickable-ut
   
   # Or via snap
   sudo snap install clickable --classic
   ```

2. **Install Docker**:
   ```bash
   sudo apt update
   sudo apt install docker.io
   sudo usermod -aG docker $USER
   # Log out and back in for group changes to take effect
   ```

## Local Build Process

1. **Initialize submodules**:
   ```bash
   cd /home/jmacdonald/Projects/UT/sealed
   git submodule update --init --recursive
   ```

2. **Build and test on desktop**:
   ```bash
   # This builds everything (including libraries) and runs on desktop
   clickable desktop
   ```

That's it! The `clickable desktop` command automatically:
- Builds the Docker image with Node.js (via image_setup)
- Builds the Bitwarden CLI library 
- Creates the lib/bw wrapper script
- Builds the main application
- Runs it on desktop for testing

## For ARM64 Device Builds

If you need to build for ARM64 devices (not desktop):

```bash
# Build for ARM64 device
clickable build --arch arm64

# Install on connected device
clickable install --arch arm64
```

## Troubleshooting

If `clickable desktop` fails with "lib/bw not found":

1. **Clean and rebuild**:
   ```bash
   clickable clean
   clickable desktop
   ```

2. **Check if submodules are initialized**:
   ```bash
   git submodule status
   # Should show commit hashes, not minus signs
   ```

3. **Force Docker image rebuild**:
   ```bash
   docker system prune -f
   clickable desktop
   ```
