from django.contrib import admin
from django.urls import path
from django.http import JsonResponse
from django.shortcuts import render


def health_check(request):
    return JsonResponse({"status": "healthy", "service": "django-app"})


def index(request):
    return render(request, "index.html")


urlpatterns = [
    path("admin/", admin.site.urls),
    path("health/", health_check, name="health_check"),
    path("", index),
]
