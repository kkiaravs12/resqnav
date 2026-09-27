"""
Django settings for ResQNav.
"""

from datetime import timedelta
from pathlib import Path
from decouple import config, Csv

BASE_DIR = Path(__file__).resolve().parent.parent

# ─── Security ─────────────────────────────────────────────────
SECRET_KEY = config('SECRET_KEY', default="django-insecure-m+h@n*_6hdn%^!odw^be__v_ih414k_@-oa!8jjzev6ua6z1=v")

DEBUG = config('DEBUG', default=True, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default="localhost,127.0.0.1,0.0.0.0,testserver", cast=Csv())

# ─── Production Security (auto-enabled when DEBUG=False) ──────
if not DEBUG:
    SECURE_SSL_REDIRECT         = config('SECURE_SSL_REDIRECT',         default=True,  cast=bool)
    SESSION_COOKIE_SECURE       = config('SESSION_COOKIE_SECURE',       default=True,  cast=bool)
    CSRF_COOKIE_SECURE          = config('CSRF_COOKIE_SECURE',          default=True,  cast=bool)
    SECURE_HSTS_SECONDS         = config('SECURE_HSTS_SECONDS',         default=15768000, cast=int)  # 6 months
    SECURE_HSTS_INCLUDE_SUBDOMAINS = config('SECURE_HSTS_INCLUDE_SUBDOMAINS', default=True, cast=bool)
    SECURE_HSTS_PRELOAD         = config('SECURE_HSTS_PRELOAD',         default=True,  cast=bool)
    SECURE_BROWSER_XSS_FILTER   = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS             = 'DENY'

# ─── Installed apps ───────────────────────────────────────────
INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Third-party
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
    "django_filters",
    "drf_spectacular",
    "storages",
    "anymail",
    # Local
    "api",
]

# ─── Middleware ───────────────────────────────────────────────
MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

# ─── Database ─────────────────────────────────────────────────
import dj_database_url

DATABASE_URL = config('DATABASE_URL', default=None)

if DATABASE_URL:
    # Production: Use PostgreSQL
    DATABASES = {
        "default": dj_database_url.config(
            default=DATABASE_URL,
            conn_max_age=600,
            conn_health_checks=True,
        )
    }
else:
    # Development: Use SQLite
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

# ─── Password validation ──────────────────────────────────────
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# ─── Internationalisation ────────────────────────────────────
LANGUAGE_CODE = "en-us"
TIME_ZONE = "Asia/Kolkata"
USE_I18N = True
USE_TZ = True

# ─── Static files ─────────────────────────────────────────────
STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

# ─── Default PK ───────────────────────────────────────────────
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# ─── Django REST Framework ────────────────────────────────────
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_RENDERER_CLASSES": (
        "rest_framework.renderers.JSONRenderer",
    ),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_FILTER_BACKENDS": (
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.SearchFilter",
        "rest_framework.filters.OrderingFilter",
    ),
    "DEFAULT_THROTTLE_CLASSES": (
        "api.throttling.GeneralUserThrottle",
    ),
    "DEFAULT_THROTTLE_RATES": {
        "auth": "5/min",
        "password_reset": "3/hour",
        "email_verification": "10/hour",
        "oauth": "20/hour",
        "general_user": "1000/hour",
        "burst": "100/minute",
        "emergency_alert": "10/minute",
    },
    "EXCEPTION_HANDLER": "api.exceptions.custom_exception_handler",
}

# ─── Frontend URL (used for email deep links / templates) ─────
FRONTEND_URL = config('FRONTEND_URL', default='http://localhost:55573')

# ─── Simple JWT ───────────────────────────────────────────────
SIMPLE_JWT = {
    # Access token valid for 7 days (convenient for development)
    "ACCESS_TOKEN_LIFETIME":  timedelta(days=7),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=30),
    "ROTATE_REFRESH_TOKENS":  True,
    "BLACKLIST_AFTER_ROTATION": False,
    "UPDATE_LAST_LOGIN": True,
    "ALGORITHM": "HS256",
    "AUTH_HEADER_TYPES": ("Bearer",),
    "AUTH_HEADER_NAME": "HTTP_AUTHORIZATION",
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
    "AUTH_TOKEN_CLASSES": ("rest_framework_simplejwt.tokens.AccessToken",),
    "TOKEN_TYPE_CLAIM": "token_type",
}

# ─── CORS ─────────────────────────────────────────────────────
# For production: set CORS_ALLOWED_ORIGINS in .env (comma-separated).
# Leave empty + DEBUG=True to allow all origins (dev convenience).
_cors_origins = config('CORS_ALLOWED_ORIGINS', default='', cast=Csv())
if _cors_origins:
    CORS_ALLOWED_ORIGINS = [o.rstrip('/') for o in _cors_origins if o]
    CORS_ALLOW_CREDENTIALS = True
else:
    CORS_ALLOW_ALL_ORIGINS = True

CORS_ALLOW_HEADERS = [
    "accept",
    "accept-encoding",
    "authorization",
    "content-type",
    "dnt",
    "origin",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
]

CORS_ALLOW_METHODS = [
    "DELETE",
    "GET",
    "OPTIONS",
    "PATCH",
    "POST",
    "PUT",
]

# CSRF trusted origins (mirror CORS origins when explicitly set)
if _cors_origins:
    CSRF_TRUSTED_ORIGINS = [o.rstrip('/') for o in _cors_origins if o]


# ─── Email Configuration ──────────────────────────────────────
EMAIL_BACKEND = config('EMAIL_BACKEND', default='django.core.mail.backends.filebased.EmailBackend')
EMAIL_FILE_PATH = config('EMAIL_FILE_PATH', default=BASE_DIR / 'emails')
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL', default='noreply@resqnav.com')

# ─── SMS Configuration (MSG91) ────────────────────────────────
# Get your MSG91 API key from https://msg91.com/
MSG91_AUTH_KEY = config('MSG91_AUTH_KEY', default='')
MSG91_SENDER_ID = config('MSG91_SENDER_ID', default='RESQNV')
MSG91_ROUTE = config('MSG91_ROUTE', default='4')  # 4 = Transactional
MSG91_TEMPLATE_ID = config('MSG91_TEMPLATE_ID', default='')

# ─── Twilio Configuration (Alternative) ───────────────────────
TWILIO_ACCOUNT_SID = config('TWILIO_ACCOUNT_SID', default='')
TWILIO_AUTH_TOKEN = config('TWILIO_AUTH_TOKEN', default='')
TWILIO_PHONE_NUMBER = config('TWILIO_PHONE_NUMBER', default='')

# ─── Logging ──────────────────────────────────────────────────
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '[{levelname}] {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'file': {
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'resqnav.log',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'api': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}


# ─── Redis Cache Configuration ────────────────────────────────
REDIS_URL = config('REDIS_URL', default='redis://localhost:6379/0')
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'SOCKET_CONNECT_TIMEOUT': 5,
            'SOCKET_TIMEOUT': 5,
            'COMPRESSOR': 'django_redis.compressors.zlib.ZlibCompressor',
            'IGNORE_EXCEPTIONS': True,
        }
    }
}

# ─── AWS S3 Configuration ─────────────────────────────────────
USE_S3 = config('USE_S3', default=False, cast=bool)

if USE_S3:
    AWS_STORAGE_BUCKET_NAME = config('AWS_STORAGE_BUCKET_NAME')
    AWS_S3_REGION_NAME = config('AWS_S3_REGION_NAME', default='us-east-1')
    AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'
    AWS_S3_OBJECT_PARAMETERS = {'CacheControl': 'max-age=86400'}
    
    # Static/Media files
    STATIC_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/static/'
    STATIC_ROOT = BASE_DIR / 'staticfiles'
    MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/media/'
    MEDIA_ROOT = BASE_DIR / 'mediafiles'
    
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    STATICFILES_STORAGE = 'storages.backends.s3boto3.S3StaticStorage'
    
    # S3 credentials
    AWS_ACCESS_KEY_ID = config('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = config('AWS_SECRET_ACCESS_KEY')
    AWS_S3_SIGNATURE_VERSION = 's3v4'
else:
    STATIC_URL = '/static/'
    STATIC_ROOT = BASE_DIR / 'staticfiles'
    MEDIA_URL = '/media/'
    MEDIA_ROOT = BASE_DIR / 'mediafiles'

# ─── Sentry Error Tracking ───────────────────────────────────
SENTRY_DSN = config('SENTRY_DSN', default='')
if SENTRY_DSN and not DEBUG:
    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration
    from sentry_sdk.integrations.celery import CeleryIntegration
    
    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[
            DjangoIntegration(),
            CeleryIntegration(),
        ],
        traces_sample_rate=0.1,
        send_default_pii=False,
        environment=config('ENVIRONMENT', default='development'),
    )

# ─── Celery Configuration ─────────────────────────────────────
CELERY_BROKER_URL = REDIS_URL
CELERY_RESULT_BACKEND = REDIS_URL
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE

# ─── API Documentation (Swagger) ──────────────────────────────
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_RENDERER_CLASSES": (
        "rest_framework.renderers.JSONRenderer",
    ),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_FILTER_BACKENDS": (
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.SearchFilter",
        "rest_framework.filters.OrderingFilter",
    ),
    "DEFAULT_THROTTLE_CLASSES": (
        "api.throttling.GeneralUserThrottle",
    ),
    "DEFAULT_THROTTLE_RATES": {
        "auth": "5/min",
        "password_reset": "3/hour",
        "email_verification": "10/hour",
        "oauth": "5/min",
        "general_user": "1000/hour",
        "burst": "100/minute",
        "emergency_alert": "10/minute"
    },
    "EXCEPTION_HANDLER": "api.exceptions.custom_exception_handler",
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
}

# ─── API Documentation (drf-spectacular) ──────────────────────
SPECTACULAR_SETTINGS = {
    'TITLE': 'ResQNav API',
    'DESCRIPTION': 'Emergency Response & Navigation API - Production-ready backend for emergency services, SOS alerts, and location tracking.',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'SCHEMA_PATH_PREFIX': '/api/',
    'COMPONENT_SPLIT_REQUEST': True,
    'SORT_OPERATIONS': True,
    'SERVE_AUTHENTICATION': [],
    'SERVE_PERMISSIONS': [],
    'SWAGGER_UI_SETTINGS': {
        'deepLinking': True,
        'persistAuthorization': True,
        'displayOperationId': True,
        'displayRequestDuration': True,
        'filter': True,
        'supportedSubmitMethods': ['get', 'post', 'put', 'patch', 'delete'],
    },
    'REDOC_UI_SETTINGS': {
        'hideDownloadButton': False,
        'theme': {
            'colors': {
                'primary': {
                    'main': '#667eea'
                }
            }
        }
    },
    'AUTHENTICATION_WHITELIST': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'SCHEMA_COERCE_PATH_PK': True,
    'SCHEMA_COERCE_METHOD_NAMES': {
        'retrieve': 'get',
        'destroy': 'delete',
    },
    'ENUM_NAME_OVERRIDES': {
        'ValidationErrorEnum': 'rest_framework.serializers.ValidationError',
    },
    'POSTPROCESSING_HOOKS': [],
    'PREPROCESSING_HOOKS': [
        'drf_spectacular.hooks.preprocess_exclude_path_format',
    ]
}

# ─── Simple JWT Configuration ─────────────────────────────────
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
}

# ─── Security Headers ────────────────────────────────────────
if not DEBUG:
    # HTTPS redirect
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    
    # HSTS
    SECURE_HSTS_SECONDS = 31536000  # 1 year
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    
    # Security headers
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    
    # Referrer policy
    SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'
