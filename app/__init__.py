from flask import Flask
from authlib.integrations.flask_client import OAuth  # Import OAuth from Authlib
from app.auth import auth_bp  # Import the auth blueprint
from app.config import Config

# Create the OAuth object
oauth = OAuth()

def create_app():
    app = Flask(__name__)

    # Load configurations from config file
    app.config.from_object(Config)

    # Register Blueprints
    app.register_blueprint(auth_bp, url_prefix='/api/auth')  # URL prefix for all auth routes
    
    return app