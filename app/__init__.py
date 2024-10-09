from flask import Flask
from app.oauth import register_oauth_providers
from app.auth import auth_bp
from app.config import config_by_name
import os

def create_app(config_name=None):
    app = Flask(__name__)

    #Set enviornment config
    app.config.from_object(config_by_name.get(config_name or 'dev'))

    # Initialize OAuth providers
    oauth = register_oauth_providers(app)

    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix='/api/auth')

    return app