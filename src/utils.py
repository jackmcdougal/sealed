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

from src.constants import (
    APP_NAME,
    CRASH_REPORT_URL,
)
from src.ut_components import setup

setup(APP_NAME, CRASH_REPORT_URL)

import json
import os
import subprocess
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional

from src.ut_components.config import get_app_data_path, get_config_path


def run_subprocess(args: List[str], env: Optional[Dict[str, str]] = None):
    return subprocess.run(args=args, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env)


@dataclass
class BWResult:
    code: int
    data: str

    def json(self):
        return json.loads(self.data)


def run_bw(args: List[str], env: Optional[Dict[str, str]] = None) -> BWResult:
    final_env = {"XDG_CONFIG_HOME": get_config_path()}
    if env:
        final_env.update(env)

    bw_command = [os.path.join(get_app_data_path(), "bw"), *args, "--raw", "--nointeraction"]
    result = run_subprocess(bw_command, env=final_env)
    if result.returncode != 0:
        raise Exception(result.stdout)
    return BWResult(code=result.returncode, data=result.stdout.strip())


def parse_bw_date(dt: str) -> str:
    if not dt:
        return ""
    return datetime.fromisoformat(dt.replace("Z", "")).strftime("%B %d, %Y. %H:%M")
