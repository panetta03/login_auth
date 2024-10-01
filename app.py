from flask import Flask, redirect, url_for, session, render_template
from authlib.integrations.flask_client import OAuth
import os, json
from app_utils import utilities

app = Flask(__name__)
app.secret_key = 'flubadub3ginqgq3g!!#sd'
app.config.from_object('config')

# Initialize OAuth
oauth = OAuth(app)

# Load OAuth configurations from JSON file
def load_oauth_config(provider_name):
    with open('providers/oauth_config.json') as f:
        oauth_configs = json.load(f)
    return oauth_configs.get(provider_name)

# Register OAuth dynamically based on provider
def register_oauth_provider(provider_name):
    config = load_oauth_config(provider_name)
    if config:
        oauth.register(
            name=provider_name,
            client_id=os.getenv(f'{provider_name.upper()}_CLIENT_ID'),
            client_secret=os.getenv(f'{provider_name.upper()}_CLIENT_SECRET'),
            access_token_url=config['access_token_url'],
            authorize_url=config['authorize_url'],
            client_kwargs={'scope': config['scope']},
            redirect_uri=config['redirect_uri'],
            server_metadata_url=config['server_metadata_url']
        )
    else:
        raise ValueError(f"No OAuth configuration found for provider: {provider_name}")

# Register OAuth providers
register_oauth_provider('google')
register_oauth_provider('microsoft')
register_oauth_provider('facebook')




@app.route('/')
def home():
    return render_template('login.html')

@app.route('/login/<provider>')
def login(provider):

    # Generate a nonce and store it in the session
    nonce = utilities.generate_nonce()
    session['nonce'] = nonce
    # Handle different OAuth providers
    if provider == 'google':
        return oauth.google.authorize_redirect(redirect_uri=url_for('callback', provider='google', _external=True), nonce=nonce)
    elif provider == 'microsoft':
        return oauth.microsoft.authorize_redirect(redirect_uri=url_for('callback', provider='microsoft', _external=True))
    elif provider == 'facebook':
        return oauth.facebook.authorize_redirect(redirect_uri=url_for('callback', provider='facebook', _external=True))
    else:
        return 'Provider not supported', 400

@app.route('/callback/<provider>')
def callback(provider):
    token = None
    # Get the stored nonce from the session
    nonce = session.pop('nonce', None)

    try:
        if provider == 'google':
            token = oauth.google.authorize_access_token()
            user_info = oauth.google.parse_id_token(token, nonce=nonce)
        elif provider == 'microsoft':
            token = oauth.microsoft.authorize_access_token()
            user_info = oauth.microsoft.get('https://graph.microsoft.com/v1.0/me').json()
        elif provider == 'facebook':
            token = oauth.facebook.authorize_access_token()
            user_info = oauth.facebook.get('https://graph.facebook.com/me?fields=id,name,email').json()
        else:
            return 'Provider not supported', 400

        # Store user info in session
        session['user'] = user_info
        return render_template('profile.html', user=user_info)

    except Exception as e:
        return redirect(url_for('login'))


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('home'))

if __name__ == "__main__":
    app.run(debug=True)
