import math
import time

from django.conf import settings
from django.http import JsonResponse


def health(request):
    return JsonResponse({
        "status": "ok",
        "app": "django-bench",
        "version": settings.APP_VERSION,
    })


def compute(request):
    n_str = request.GET.get("n", "10000")
    try:
        n = int(n_str)
        if n < 2:
            raise ValueError
    except (ValueError, TypeError):
        return JsonResponse({"error": "invalid parameter n"}, status=400)

    start = time.time()
    count = count_primes(n)
    duration_ms = (time.time() - start) * 1000

    return JsonResponse({
        "app": "django-bench",
        "version": settings.APP_VERSION,
        "n": n,
        "prime_count": count,
        "duration_ms": round(duration_ms, 3),
    })


def payload(request):
    size_str = request.GET.get("size", "100")
    try:
        size = int(size_str)
        if size < 1:
            raise ValueError
    except (ValueError, TypeError):
        return JsonResponse({"error": "invalid parameter size"}, status=400)

    start = time.time()
    items = [
        {"id": i, "name": f"item-{i}", "value": i * 42, "active": i % 2 == 0}
        for i in range(size)
    ]
    duration_ms = (time.time() - start) * 1000

    return JsonResponse({
        "app": "django-bench",
        "version": settings.APP_VERSION,
        "item_count": size,
        "duration_ms": round(duration_ms, 3),
        "items": items,
    })


def count_primes(n):
    count = 0
    for i in range(2, n + 1):
        if is_prime(i):
            count += 1
    return count


def is_prime(n):
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False
    for i in range(3, int(math.sqrt(n)) + 1, 2):
        if n % i == 0:
            return False
    return True
