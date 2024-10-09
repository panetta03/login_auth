import pytest
from flask import url_for

@pytest.fixture
def client():
    from app import create_app
    app = create_app('test')
    return app.test_client()

def test_google_login_redirect(client):
    """Test that Google login redirects to OAuth."""
    response = client.get('/api/auth/login/google', follow_redirects=False)
    assert response.status_code == 302
    assert 'accounts.google.com' in response.headers['Location']

# def test_facebook_login_redirect(client):
#     """Test that Facebook login redirects to OAuth."""
#     response = client.get('/api/auth/login/facebook', follow_redirects=False)
#     assert response.status_code == 302
#     assert 'facebook.com' in response.headers['Location']

# def test_unauthenticated_profile_access(client):
#     """Test access to protected profile route without authentication."""
#     response = client.get('/api/auth/profile')
#     assert response.status_code == 401