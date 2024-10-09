import os

class Config:
    """Base configuration class."""
    
    # Default configurations
    SECRET_KEY = os.getenv('SECRET_KEY', 'default_secret_key')
    DEBUG = False
    TESTING = False
    JSONIFY_PRETTYPRINT_REGULAR = False

    # OAuth Configurations
    GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID')
    GOOGLE_CLIENT_SECRET = os.getenv('GOOGLE_CLIENT_SECRET')
    MICROSOFT_CLIENT_ID = os.getenv('MICROSOFT_CLIENT_ID')
    MICROSOFT_CLIENT_SECRET = os.getenv('MICROSOFT_CLIENT_SECRET')
    FACEBOOK_CLIENT_ID = os.getenv('FACEBOOK_CLIENT_ID')
    FACEBOOK_CLIENT_SECRET = os.getenv('FACEBOOK_CLIENT_SECRET')

    # OAuth Redirect URIs
    GOOGLE_REDIRECT_URI = os.getenv('GOOGLE_REDIRECT_URI', 'http://localhost:5000/api/auth/callback/google')
    MICROSOFT_REDIRECT_URI = os.getenv('MICROSOFT_REDIRECT_URI', 'http://localhost:5000/api/auth/callback/microsoft')
    FACEBOOK_REDIRECT_URI = os.getenv('FACEBOOK_REDIRECT_URI', 'http://localhost:5000/api/auth/callback/facebook')

class DevelopmentConfig(Config):
    """Development configuration class."""
    DEBUG = True
    JSONIFY_PRETTYPRINT_REGULAR = True
    SERVER_NAME = 'localhost:5000'

class TestingConfig(Config):
    """Testing configuration class."""
    TESTING = True
    DEBUG = True
    JSONIFY_PRETTYPRINT_REGULAR = True
    SERVER_NAME = 'localhost:5000'

class ProductionConfig(Config):
    """Production configuration class."""
    SECRET_KEY = os.getenv('SECRET_KEY')
    DEBUG = False
    TESTING = False

# Mapping to easily access configurations
config_by_name = dict(
    dev=DevelopmentConfig,
    test=TestingConfig,
    prod=ProductionConfig
)