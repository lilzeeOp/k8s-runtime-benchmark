"""WSGI config for myapp project."""
import os
import time

_boot_start = time.monotonic()

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myapp.settings")

from django.core.wsgi import get_wsgi_application

application = get_wsgi_application()

_startup_ms = (time.monotonic() - _boot_start) * 1000
print(f"django-bench listening (startup: {_startup_ms:.3f}ms)", flush=True)
