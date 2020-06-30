import os
from notebook.base.handlers import IPythonHandler
from notebook.utils import url_path_join


def load_jupyter_server_extension(nb_app):

    class CallbackHandler(IPythonHandler):
        def get(self):
            with open(os.path.join(os.path.dirname(__file__), 'static', 'redirect.html')) as f:
                self.write(f.read())

    host_pattern = '.*$'
    base_url = nb_app.web_app.settings['base_url']

    nb_app.web_app.add_handlers(
        host_pattern,
        [(url_path_join(base_url, '/redirect.html'), CallbackHandler)]
    )

    nb_app.log.info("ipyauth callback server extension enabled")
