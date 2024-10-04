import os
import json
from authlib.integrations.flask_client import OAuth

# Create the OAuth instance
oauth = OAuth()

# Function to load provider configurations from JSON file
def load_oauth_config():
    config_path = os.path.join(os.path.dirname(__file__), 'oauth_config.json')
    with open(config_path) as f:
        return json.load(f)

# Register OAuth providers based on the loaded configuration
def register_oauth_providers(app):
    oauth_config = load_oauth_config()


    # Loop through each provider in the JSON config and register them
    for provider_name, provider_config in oauth_config.items():
        oauth.register(
            name=provider_name,
            client_id=os.getenv(f'{provider_name.upper()}_CLIENT_ID'),  # Get from environment
            client_secret=os.getenv(f'{provider_name.upper()}_CLIENT_SECRET'),  # Get from environment
            access_token_url=provider_config['access_token_url'],
            authorize_url=provider_config['authorize_url'],
            client_kwargs={'scope': provider_config['scope']},
            server_metadata_url=provider_config['server_metadata_url']
        )
    
    # Initialize the OAuth instance with the Flask app
    oauth.init_app(app)

    return oauth
