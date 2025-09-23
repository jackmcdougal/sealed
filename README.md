# Sealed

[![OpenStore](https://open-store.io/badges/en_US.png)](https://open-store.io/app/sealed.brennoflavio)

A Bitwarden Password Manager Client for Ubuntu Touch

## Development

To run this App, you'll need a copy of Bitwarden CLI (arm build).

Currenlty Bitwarden does not provide arm linux builds on their GitHub releases.

But you can grab a pre built binary from their [Github Action](https://github.com/bitwarden/clients/actions/workflows/build-cli.yml):
- Open above link
- Search for job "CLI linux-arm64 - open source license"
- Inside the job, look for the step "Upload unix zip asset"
- Open the logs, there will be an Artifact Download URL
- Download and extract the binary inside the `lib` folder in the root of this repository

This project expects to call the binary in the location `lib/bw`.

For convenience, the binary that this application is currenlty developed can be [downloaded here](https://f005.backblazeb2.com/file/sealed-bitwarden-cli/bw)

## License

Copyright (C) 2025  Brenno Flávio de Almeida

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3, as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranties of MERCHANTABILITY, SATISFACTORY
QUALITY, or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.
