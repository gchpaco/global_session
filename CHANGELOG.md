3.2.1 (2015-07-10)
---------------

Fixed a bug with automatic cookie renewal; cookies were not being renewed unless
the `authority` directive was present in the configuration.

3.2.0 (2015-07-08)
------------------

If cookie domain is omitted from configuration, the Rack middleware will 
guess a suitable domain by looking at the HTTP Host header (or `X-Forwarded-Host` 
if it is present, i.e. the request has passed through a load balancer). The
heuristic for HTTP-host-to-cookie-domain is:

* Numeric IPv4: `127.0.0.1` -> _no_ domain
* 1-component: `localhost` -> _no_ domain
* 2-component: `example.com` -> `example.com` 
* N-component: `foo.test.example.com` -> `test.example.com`

This doesn't handle country-code TLDs (`.co.uk`) so you'll still need to specify
the cookie domain for Web sites under a ccTLD.

The Rack middleware will guess whether to add the `secure` flag to cookies
based on `rack.url_scheme` (or `X-Forwarded-Proto` if it is present).

3.1 (2015-01-27)
----------------

Split Directory class into Directory & Keystore, retaining some backward-compatibility shims
inside Directory. In v4, these shims will be removed and all key management concerns will be
handled by Keystore; the Directory class will be limited to session creation, renewal, and
validity checking.

The `trust` and `authority` configuration elements have been deprecated, as ha
the ability to pass a keystore directory to `Directory.new`. Instead, the
configuration should contain a `keystore` that tells the gem where to find its
public and private keys; every public key is implicitly trusted, and if some
private key is found, the app is an authority (otherwise it's not an authority
and sessions are read-only). Example new configuration:

    keystore:
      public:
        - config/authorities
        - config/other_dir_with_keys_i_should_trust
      private: /etc/my_private.key
      
As with any other Global Session configuration, this stanza can appear under
`common` or under an enivronment-specific section (`staging`, `production`, etc).

Finally, you can pass a private key location in the environment variable named
`GLOBAL_SESSION_PRIVATE_KEY` instead of including that information in the
configuration.

3.0 (2013-10-03)
----------------

The format of the global session cookie has been reinvented again! It once again uses JSON
(because msgpack was not widely supported in other languages/OSes) but retains the compact
array encoding introduced in v2.

The cryptographic signature scheme has been changed for better compatibility; we now use
PKCS1 v1.5 sign and verify operations instead of "raw" RSA. v2 and v1 sessions are fully
supported for read/write, but any session created with the v3 gem will use the v3 crypto
scheme.

2.0 (2012-11-06)
----------------

The format of the global session cookie has been reinvented; it now uses msgpack and delegates
all crypto to RightSupport::Crypto::SignedHash. Together with a few other optimizations, the
size of the cookie has shrunk by about 30%.

The gem remains capable of reading and writing V1 format cookies, but all new cookies are created
with the V2 format.

The "integrated" feature is no longer supported for the Rails integration layer; global session
attributes must always be accessed separately from local session attributes, through the
#global_session reader method that is mixed into ActionController::Base.

1.0 (2011-01-01)
----------------

General Availability release. Mostly interface-compatible with 0.9.

0.9 (2010-12-07)
----------------

Rack middleware implementation is feature-complete and has major spec coverage. Rails integration
is untested and may contain bugs.

0.9.0 (2010-12-22)
----------------

Initial commit ported from 'rack' branch of old has_global_session project
