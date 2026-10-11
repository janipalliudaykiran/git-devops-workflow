
import threading
from http.server import ThreadingHTTPServer
from urllib.error import HTTPError
from urllib.request import urlopen

import pytest

from app.app import AppHandler, get_message, health_check


def test_get_message():
    assert get_message() == "Hello from my DevOps application!"


def test_health_check():
    assert health_check() is True


@pytest.fixture
def server_url():
    server = ThreadingHTTPServer(("127.0.0.1", 0), AppHandler)
    worker = threading.Thread(target=server.serve_forever, daemon=True)
    worker.start()

    yield f"http://127.0.0.1:{server.server_port}"

    server.shutdown()
    worker.join(timeout=3)
    server.server_close()


def test_root_endpoint(server_url):
    with urlopen(f"{server_url}/", timeout=2) as response:
        assert response.status == 200
        assert response.read().decode("utf-8") == (
            "Hello from my DevOps application!"
        )


def test_health_endpoint(server_url):
    with urlopen(f"{server_url}/health", timeout=2) as response:
        assert response.status == 200
        assert response.read().decode("utf-8") == "ok"


def test_unknown_endpoint_returns_404(server_url):
    with pytest.raises(HTTPError) as error:
        urlopen(f"{server_url}/not-found", timeout=2)

    assert error.value.code == 404
