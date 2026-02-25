from django.urls import path

from . import views

urlpatterns = [
    path("health", views.health),
    path("compute", views.compute),
    path("payload", views.payload),
]
