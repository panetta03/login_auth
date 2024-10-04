from flask import Blueprint

# Create the Blueprint instance for the auth module
auth_bp = Blueprint('auth', __name__)

# Import routes to register them with the Blueprint
from app.auth import routes  # Make sure routes.py exists in app/auth