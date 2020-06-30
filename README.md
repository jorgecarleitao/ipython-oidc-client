# OAuth2 on Jupyter Notebook

A notebook extension to perform OAuth2 flows (e.g. token, code) in notebooks.

## Rational

A major challenge in using APIs from notebooks is how to form the trust relationship between the API and the client (notebook).

This problem is often solved by trusting the *host* of the kernel. One pattern to this is the managed identity pattern that all major cloud providers offer. A major disadvantage of this pattern is that any user that can access the execution engine (the kernel through a notebook), can also access whatever API that host has access to. I.e. it does not allow discrimatory access to APIs as it does not separate "access to notebooks" from "access to APIs". This generally leads
to host-based access architectures with one execution environment per set of access policies.

Another pattern to solve this problem is to use a service principal (OAuth2) to access the API through a client secret. This unfortunatelly suffers from the same problems as the managed identity: it yields indiscrimatory access to the data to anyone with access to the execution engine. This pattern has another risk: in the context of a notebook, it is easy to programatically obtain the client secret, which gives an attacker indiscrimatory access to the API from *any host* in a zero trust network.

### This package

This package allows users to perform OAuth2 flows (e.g. token, code) in notebooks. This allows discrimatory access to APIs by individual users.

This uses a standard pattern within the OAuth2 RFCs: the notebook is a client application (SPA) which interacts with the kernel, and users use OAuth2 to form a trust relationship between the kernel, APIs, and the identity provider.

This allows decoupling authorization to the execution environment from authorization
to APIs, allowing jupyterhub to be deployed on a whole organization, and use its identity provider (AD) to manage permissions to specific APIs that the user (e.g. developer) may need from a notebook.

## How to install

```
pip install ipython-oidc-client

jupyter nbextension install ipyoauth_oidc_client/client/
jupyter nbextension enable client/main
jupyter serverextension enable --py ipyoauth_oidc_client
```

On your identity provider (e.g. Azure, Google, Auth0), add a reply url to the path `/redirect.html`,
e.g. `https://example.com/redirect.hml`. For development, use `http://localhost:8888/redirect.html`
or whatever port jupyter is running on.

## How to use

Open a new notebook and run

```
from ipython_oidc_client import authenticate


access_configuration = {
    'authority': 'https://.../.well-known/openid-configuration',
    'client_id': '...',
    'response_type': 'token',
    'scope': 'openid',
}
# valid variables available here: https://github.com/IdentityModel/oidc-client-js/wiki#usermanager

access_token = None
authenticate(provider)  # this changes global access_token (see note in README.md)
```

At this point, you will be redirected to the authentication page of the identity provider declared
in `authority`. Once authenticated (e.g. through MFA), you will be redirected back to the notebook.

Once back to the notebook, re-run the cell above, and `access_token` will be the access token returned by the authority. Re-running the first cell does not trigger a new authentication; in fact, running that cell on any notebook on the same jupyterhub will yield the same access token.

At this point, you can run e.g.s

```
import requests
r = requests.get('...', headers={'Authorization': f'Bearer {access_token}'})
```

Once the token expires (typically after 1 hour), re-run the cell above to get a new token.

This procedure can be repeated for access tokens to multiple APIs within the same notebook, naturally.

### Why global?

Due to a [limitation in Jupyter](https://github.com/jupyter/notebook/issues/3187),
the access token only becomes available to the kernel after the execution of the *whole* cell.
As such, we can't return the token from `authenticate` and instead have to assign it to a global. This may change in the future. `authenticate` has a second argument, `global_variable`, with the
name of the global that you want to assign the variable to:

```python
authenticate(provider, 'my_token')
# my_token is assigned the access token, after execution
```

## Security

This package has to deal with two execution environments:

* javascript, on the browser
* Python, on the kernel 

On the browser, it uses [oidc-client-js(https://github.com/IdentityModel/oidc-client-js) to perform
the oauth2 flows. In Python, it uses this package's source code, which performs a redirect and communicates with the browser.

The flow after running the example above is:

1. The client code is loaded when the kernel starts, loading external client dependencies (see below)
2. The cell is ran, which stores the current path on a cookie and triggers a javascript redirect to the identity provider
3. the identity provider redirects to `/redirect.html` after sucessful authentication
4. the callback client code stores the token and redirects the user to the path in a cookie

This package does not deliver js dependencies; the client needs access to 

* https://cdnjs.cloudflare.com/ajax/libs/oidc-client/1.10.0/oidc-client.min.js
* https://unpkg.com/universal-cookie@3/umd/universalCookie.min.js

this may change in the future.

### Kernel - Browser trust

This package assumes that the kernel is less trustworthy than the browser. This is because, by design, in a notebook environment, it is easy to

* print a variable on an output cell of a notebook and 
* share the notebook with someone

These induce a risk of inadvertedly sharing tokens, in particular refresh tokens. To reduce this risk, the browser only shares access tokens with the kernel, which are extrictly necessary to communicate with an API.

## How to develop

This package has 4 components:

* [js client running on the browser](ipyoauth_oidc_client/client)
* [Python extension running on the server](ipyoauth_oidc_client/server)
* [Python API to authenticate on a notebook](ipyoauth_oidc_client/__init__.py)
* [html/js callback page to process the response from the IP](ipyoauth_oidc_client/server/static/redirect.html)

The easiest way to develop this package is to run

```bash
docker build -t t . && docker run -p 8888:8888 -v $(pwd):/project --rm -it t
```

and open the browser at http://localhost:8888/?token= (note, *not* 127.0.0.1).

This runs a Python-based image with Jupyter and the package installed in a way that
changing the js only requires refreshing the page. Changing the Python code requires re-running the image.
