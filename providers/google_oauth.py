from app.oauth import oauth
from flask import url_for


def google_oauth(nonce):
    redirect_uri = url_for('auth.callback', provider='google', _external=True)
    return oauth.google.authorize_redirect(redirect_uri, nonce=nonce)

def google_oauth_callback(nonce):
    token = oauth.google.authorize_access_token()
    user_info = oauth.google.parse_id_token(token, nonce=nonce)
    return user_info
