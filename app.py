from flask import Flask
from app.auth import auth_bp
from app.oauth import register_oauth_providers  # Import the auth blueprint
import os

def create_app():
    # Initialize the Flask app
    app = Flask(__name__)

    # Load configurations from environment variables or config files
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your_default_secret_key')

    # Register OAuth providers from JSON config
    oauth = register_oauth_providers(app)

    # Register Blueprints
    app.register_blueprint(auth_bp, url_prefix='/api/auth')  # Use /api/auth as the base URL

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)
