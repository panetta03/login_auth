from flask import Blueprint, request, jsonify, session
from app_utils.utilities import generate_nonce
from providers.google_oauth import google_oauth, google_oauth_callback
from . import auth_bp
#from app.services.microsoft_oauth import microsoft_oauth
#from app.services.linkedin_oauth import linkedin_oauth

@auth_bp.route('/test', methods=['GET'])
def test():
    return jsonify({"message": "Auth Blueprint is working!"})

# Login endpoint - Initiates OAuth flow
@auth_bp.route('/login/<provider>', methods=['GET'])
def login(provider):
    nonce = generate_nonce()
    session['nonce'] = nonce
    if provider == 'google':
        return google_oauth(nonce)
    #elif provider == 'microsoft':
       # return microsoft_oauth(nonce)
    #elif provider == 'linkedin':
       # return linkedin_oauth(nonce)
    else:
        return jsonify({'error': 'Provider not supported'}), 400

# Callback endpoint - Handles OAuth response
@auth_bp.route('/callback/<provider>', methods=['GET'])
def callback(provider):
    nonce = session.pop('nonce', None)

    if request.args.get('error') == 'access_denied':
        return jsonify({'error': 'Access Denied', 'message': 'Login canceled by user'}), 401

    try:
        if provider == 'google':
            user_info = google_oauth_callback(nonce)  # Call the callback function directly
        # Add other providers as needed
        else:
            return jsonify({'error': 'Provider not supported'}), 400

        return jsonify({'user_info': user_info}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500