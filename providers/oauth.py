# Google OAuth configuration
google = oauth.register(
    name='google',
    client_id=os.getenv('GOOGLE_CLIENT_ID'),
    client_secret=os.getenv('GOOGLE_CLIENT_SECRET'),
    access_token_url='https://accounts.google.com/o/oauth2/token',
    authorize_url='https://accounts.google.com/o/oauth2/auth',
    authorize_params=None,
    access_token_params=None,
    client_kwargs={'scope': 'openid profile email'},
    redirect_uri=os.getenv('GOOGLE_REDIRECT_URI')
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