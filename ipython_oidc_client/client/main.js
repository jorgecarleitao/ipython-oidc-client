require.config({
    paths: {
        'oidc': '//cdnjs.cloudflare.com/ajax/libs/oidc-client/1.10.0/oidc-client.min',
        'universal-cookie': '//unpkg.com/universal-cookie@3/umd/universalCookie.min'
    },
    shim: {
        'oidc': {
            exports: 'Oidc',
        },
        'universal-cookie': {
            exports: 'UniversalCookie',
        }
    },
});

const REDIRECT_COOKIE = 'origin'

define([
    'oidc',
    'universal-cookie',
    'base/js/namespace',
], function(oidc, Cookie, Jupyter) {
    function load_ipython_extension() {
        console.info('initiated extension');

        const authenticate = (provider) => {
            const config = {
                authority: provider.authority,
                client_id: provider.client_id,
                redirect_uri: `${window.location.origin}/redirect.html`,
                response_type: provider.response_type,
                scope: provider.scope,
            };

            const userManager = new oidc.UserManager(config)
            return userManager.getUser().then(user => {
                if (user === null || user.expired) {
                    const cookie = new Cookie()
                    cookie.set(REDIRECT_COOKIE, window.location.pathname + window.location.search, {sameSite: 'lax', path: '/'})
                    return userManager.signinRedirect()
                } else {
                    return user['access_token']
                }
            })
        }

        Jupyter.notebook.kernel.comm_manager.register_target('oauth_authenticate',
            function(comm) {
                comm.on_msg((msg) => {
                    authenticate(msg.content.data).then((token) => {
                        comm.send(token)
                    })
                });
            }
        );
    }

    return {
        load_ipython_extension: load_ipython_extension
    };
});
