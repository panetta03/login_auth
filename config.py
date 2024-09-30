import os

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY')  # Use AWS Secrets Manager for this key if needed
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False