"""A Jupyter extension to perform OAuth2 flows (e.g. token, code) in notebooks."""

__version__ = '0.1.1'

import ipykernel.comm


def _jupyter_server_extension_paths():
    return [{
        "module": "ipython_oidc_client.server"
    }]


def _jupyter_nbextension_paths():
    return [{
        "section": "notebook",
        "src": "client",
        "dest": "ipython_oidc_client",
        "require": "ipython_oidc_client/main"
    }]


def authenticate(provider, variable):
    comm = ipykernel.comm.Comm(target_name='oauth_authenticate')

    @comm.on_msg
    def _recv(msg):
        variable['access_token'] = msg['content']['data']

    comm.send(provider)
