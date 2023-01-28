import argparse
from .server import start

default_host = "127.0.0.1"
default_port = 8080

def add_arguments(parser):
    parser.description = "simple json server example"

    parser.add_argument(
        "--tcp", action="store_true",
        help="Use TCP server"
    )
    parser.add_argument(
        "--ws", action="store_true",
        help="Use WebSocket server"
    )
    parser.add_argument(
        "--host", default=default_host,
        help="Bind to this address"
    )
    parser.add_argument(
        "--port", type=int, default=default_port,
        help="Bind to this port"
    )

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    add_arguments(parser)
    args = parser.parse_args()
    start(args)