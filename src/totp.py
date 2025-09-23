"""
Copyright (C) 2025  Brenno Flávio de Almeida

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3.

sealed is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

import base64
import hashlib
import hmac
import struct
import time


def generate_hotp(secret, counter, digits=6, digest=hashlib.sha1):
    counter_bytes = struct.pack(">Q", counter)
    hmac_digest = hmac.new(secret, counter_bytes, digest).digest()
    offset = hmac_digest[-1] & 0x0F
    truncated = hmac_digest[offset : offset + 4]
    code = struct.unpack(">I", truncated)[0] & 0x7FFFFFFF
    code = code % (10**digits)
    return str(code).zfill(digits)


def generate_totp(secret, time_step=30, digits=6, digest=hashlib.sha1):
    counter = int(time.time() // time_step)
    if isinstance(secret, str):
        secret = secret.upper()
        padding = 8 - len(secret) % 8
        if padding != 8:
            secret += "=" * padding
        secret_bytes = base64.b32decode(secret)
    else:
        secret_bytes = secret
    return generate_hotp(secret_bytes, counter, digits, digest)
