#!/bin/bash

# Setup script for Bitwarden CLI from source
# This script initializes the git submodule and builds the CLI locally

set -e

echo "🔧 Setting up Bitwarden CLI from source..."

# Check if we're in the right directory
if [ ! -f "clickable.yaml" ]; then
    echo "❌ Error: This script must be run from the sealed project root directory"
    exit 1
fi

# Initialize git submodules
echo "📦 Initializing git submodules..."
git submodule update --init --recursive

# Check if Node.js is available
if ! command -v node >/dev/null 2>&1; then
    echo "❌ Error: Node.js is required but not found in PATH."
    echo "Please install Node.js 16 or later."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo "❌ Error: Node.js 16 or later is required. Found version: $(node --version)"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"

# Build Bitwarden CLI
echo "🔨 Building Bitwarden CLI from source..."
cd bitwarden-cli

echo "📥 Installing dependencies..."
npm install

echo "🔗 Initializing submodules..."
npm run sub:init

echo "🏗️  Building CLI..."
npm run build

cd ..

# Create lib directory and CLI wrapper
echo "📁 Creating CLI wrapper..."
mkdir -p lib

# Remove old binary if it exists
rm -f lib/bw

# Create the CLI wrapper script
cat > lib/bw << 'EOF'
#!/bin/bash

# Bitwarden CLI - Built from source
# This script runs the Bitwarden CLI using Node.js

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$SCRIPT_DIR/../bitwarden-cli"

# Check if Node.js is available
if ! command -v node >/dev/null 2>&1; then
    echo "Error: Node.js is required but not found in PATH."
    echo "Please install Node.js 16 or later."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo "Error: Node.js 16 or later is required. Found version: $(node --version)"
    exit 1
fi

# Verify CLI build exists
if [ ! -f "$CLI_DIR/build/bw.js" ]; then
    echo "Error: Bitwarden CLI build not found at $CLI_DIR/build/bw.js"
    echo "Please run scripts/setup-bitwarden-cli.sh to build the CLI"
    exit 1
fi

# Execute the Bitwarden CLI
exec node "$CLI_DIR/build/bw.js" "$@"
EOF

chmod +x lib/bw

# Test the CLI
echo "🧪 Testing CLI build..."
if ./lib/bw --help >/dev/null 2>&1; then
    echo "✅ Bitwarden CLI built successfully!"
    echo "📍 CLI location: lib/bw"
    echo "🔍 CLI version: $(./lib/bw --version)"
else
    echo "❌ CLI test failed"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "The Bitwarden CLI has been built from source and is ready to use."
echo "This eliminates the security risk of downloading pre-built binaries from third parties."
echo ""
echo "Next steps:"
echo "1. Commit the .gitmodules file: git add .gitmodules && git commit -m 'Add Bitwarden CLI as submodule'"
echo "2. Push to trigger the new CI/CD pipeline: git push"
echo "3. The GitHub Actions will now build the CLI from source instead of downloading it"
echo ""
