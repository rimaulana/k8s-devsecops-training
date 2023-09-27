
def test_home_page(app, client):
    """
    GIVEN a Flask application configured for testing
    WHEN the '/' page is requested (GET)
    THEN check that the response is valid
    """

    # Create a test client using the Flask application configured for testing
    del app
    response = client.get('/')
    assert response.status_code == 200
    assert b"Hello World!" in response.data