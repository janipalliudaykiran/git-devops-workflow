from app.app import get_message, health_check


def test_get_message():
    assert get_message() == "Hello from my DevOps application!"


def test_health_check():
    assert health_check() == "OK"
