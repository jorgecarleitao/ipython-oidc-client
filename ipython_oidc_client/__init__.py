"""A Jupyter extension to """

__version__ = '0.1.0'

import ipykernel.comm


def _jupyter_server_extension_paths():
    return [{
        "module": "ipython_oidc_client.server"
    }]


def authenticate(provider, global_variable='access_token'):
    my_comm = ipykernel.comm.Comm(target_name='oauth_authenticate')

    @my_comm.on_msg
    def _recv(msg):
        globals()[global_variable] = msg['content']['data']

    my_comm.send(provider)
