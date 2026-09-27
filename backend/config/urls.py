from django.contrib import admin
from django.urls import include, path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from drf_spectacular.views import (
    SpectacularAPIView, 
    SpectacularRedocView, 
    SpectacularSwaggerView
)

urlpatterns = [
    path("admin/", admin.site.urls),

    # ─── API Routes ───────────────────────────────────────────
    path(
        "api/",
        include("api.urls"),
    ),

    # ─── Legacy JWT Auth (kept for backward compatibility) ────
    path(
        "api/auth/login/",
        TokenObtainPairView.as_view(),
        name="token_obtain_pair",
    ),

    path(
        "api/auth/refresh/",
        TokenRefreshView.as_view(),
        name="token_refresh",
    ),

    # ─── API Documentation ────────────────────────────────────
    path(
        "api/schema/",
        SpectacularAPIView.as_view(),
        name="schema"
    ),
    path(
        "api/docs/swagger/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path(
        "api/docs/redoc/",
        SpectacularRedocView.as_view(url_name="schema"),
        name="redoc",
    ),
    path(
        "docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="api-docs",
    ),
]