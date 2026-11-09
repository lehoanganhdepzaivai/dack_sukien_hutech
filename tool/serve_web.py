"""Serve a Flutter Web build with correct ES module MIME types on Windows."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class WebHandler(SimpleHTTPRequestHandler):
    # Windows registry can map .mjs to text/plain, which browsers reject.
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        '.mjs': 'text/javascript',
        '.js': 'text/javascript',
        '.wasm': 'application/wasm',
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8080)
    parser.add_argument('--bind', default='127.0.0.1')
    parser.add_argument('--directory', default='build/web')
    args = parser.parse_args()
    directory = Path(args.directory).resolve(strict=True)
    if not (directory / 'index.html').is_file():
        parser.error('Build Flutter Web first: flutter build web --release')
    server = ThreadingHTTPServer(
        (args.bind, args.port), partial(WebHandler, directory=str(directory))
    )
    print(f'Serving {directory} at http://{args.bind}:{args.port}', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
