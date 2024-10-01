from flask import Flask, redirect, url_for, session, render_template
from authlib.integrations.flask_client import OAuth
import os
import random
import string
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
app.secret_key = 'flubadub3ginqgq3g!!#sd'
app.config.from_object('config')

# Initialize OAuth
oauth = OAuth(app)

# Google OAuth configuration
google = oauth.register(
    name='google',
    client_id=os.getenv('GOOGLE_CLIENT_ID'),
    client_secret=os.getenv('GOOGLE_CLIENT_SECRET'),
    access_token_url='https://oauth2.googleapis.com/token',
    authorize_url='https://accounts.google.com/o/oauth2/auth',
    authorize_params=None,
    client_kwargs={'scope': 'openid email profile'},
    redirect_uri='http://localhost:5000/login/callback',
    server_metadata_url='https://accounts.google.com/.well-known/openid-configuration'
)

# Microsoft OAuth configuration
microsoft = oauth.register(
    name='microsoft',
    client_id=os.getenv('MICROSOFT_CLIENT_ID'),
    client_secret=os.getenv('MICROSOFT_CLIENT_SECRET'),
    access_token_url='https://login.microsoftonline.com/common/oauth2/v2.0/token',
    authorize_url='https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
    authorize_params=None,
    access_token_params=None,
    client_kwargs={'scope': 'https://graph.microsoft.com/User.Read'},
    redirect_uri=os.getenv('MICROSOFT_REDIRECT_URI')
)

# LinkedIn OAuth configuration
linkedin = oauth.register(
    name='linkedin',
    client_id=os.getenv('LINKEDIN_CLIENT_ID'),
    client_secret=os.getenv('LINKEDIN_CLIENT_SECRET'),
    access_token_url='https://www.linkedin.com/oauth/v2/accessToken',
    authorize_url='https://www.linkedin.com/oauth/v2/authorization',
    authorize_params=None,
    access_token_params=None,
    client_kwargs={'scope': 'r_liteprofile r_emailaddress'},
    redirect_uri=os.getenv('LINKEDIN_REDIRECT_URI')
)

# Function to generate a nonce (random string)
def generate_nonce(length=16):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

@app.route('/')
def home():
    return render_template('login.html')

@app.route('/login/<provider>')
def login(provider):

    # Generate a nonce and store it in the session
    nonce = generate_nonce()
    session['nonce'] = nonce
    if provider == 'google':
        return google.authorize_redirect(redirect_uri=url_for('callback', provider='google', _external=True),nonce = nonce)
    elif provider == 'microsoft':
        return microsoft.authorize_redirect(redirect_uri=url_for('callback', provider='microsoft', _external=True))
    elif provider == 'linkedin':
        return linkedin.authorize_redirect(redirect_uri=url_for('callback', provider='linkedin', _external=True))
    else:
        return 'Provider not supported', 400

@app.route('/callback/<provider>')
def callback(provider):
    token = None
    # Get the stored nonce from the session
    nonce = session.pop('nonce', None)

    if provider == 'google':
        token = google.authorize_access_token()
        user_info = google.parse_id_token(token, nonce = nonce)
    elif provider == 'microsoft':
        token = microsoft.authorize_access_token()
        user_info = microsoft.get('https://graph.microsoft.com/v1.0/me').json()
    elif provider == 'linkedin':
        token = linkedin.authorize_access_token()
        user_info = linkedin.get('https://api.linkedin.com/v2/me').json()
    else:
        return 'Provider not supported', 400


    # Store user info in session or handle it accordingly
    session['user'] = user_info
    return render_template('profile.html', user=user_info)


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('home'))

if __name__ == "__main__":
    app.run(debug=True)
