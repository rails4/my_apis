## API Authentication and Authorization

* *authentication* – identyfikacja, weryfikacja tożsamości
* *authorization* – autoryzacja; uprawnienie; upoważnienie


```
                        START     <---- aplikacja Rails 4 + MongoDB,
                          |             lub aplikacja Sinatra lub – Express,
                          |             albo jakaś inna plikacja www
                   No     |
        /-----------------•
        |                 | Yes
        v                 |
       HTML             JSON            /books,   /books.json
 zwykła aplikacja www     |             /books/4, /books/4.json
                          |
                   No     |
        /-----------------•             dodajemy metadane – root element
        |                 | Yes
        v                 |
  modyfikujemy:           |
    render json: ...      |
                          |
                       /-----\
                       | API |          np. ActiveModel::Serializers
                       \-----/
                          ^    \
                          |     \
                   No     |      \
        /-------------- CORS      \
        |                 |        \  Authenticate requests
        v                 | Yes     \
     DATA lokalne         |          \
     dla aplikacji:       |           \       No
       no_cors.html   share DATA       \----------- http request
                      with World:       \     No
                        cors.html        \--------- http digest
                                          \   Yes
                                           \------- tokens
                                                      model User
                                                      with attrs: email and token
```

Dokumentacja:

* [Cryptographic nonce](http://en.wikipedia.org/wiki/Cryptographic_nonce)
* gem [rails-api](https://github.com/rails-api/rails-api) – Rails for API only applications


### HTTP Basic Auth

As the name may imply, this is a very basic way of doing
authentication.  Here's how it works: You make a string,
`username:password`, then *Base64* encode it, and then send it in an
Authorization header.

### HTTP Digest Authentication

Na razie aplikacja nie jest zabezpieczona w żaden sposób.
Dlatego wykonanie na konsoli:

```sh
curl -i localhost:3000/books/0.json
```
zwraca:

```
HTTP/1.1 200 OK
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Type: application/json; charset=utf-8
ETag: "2cd9a09c7af0cdd5a6ba092f63af084b"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: 9feffcfe-65a3-4c88-a32b-41f76435f634
X-Runtime: 0.003844
Connection: close
Server: thin 1.6.2 codename Doc Brown

{"book":{"id":0,"para":"An Anonymous Volunteer, and David Widger"}}
```

Autentykację dodajemy dopisując w pliku
*app/controllers/application_controller.rb* następujący kod:

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method def require_signin
    authenticate_or_request_with_http_digest do |username|
      if username == "admin"
        "sekret" # password
      end
    end
  end

  before_action :require_signin
end
```

Teraz wykonanie na konsoli:

```sh
curl -i localhost:3000/books/0.json
```

zwraca:

```
HTTP/1.1 401 Unauthorized
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
WWW-Authenticate: Digest realm="Application", qop="auth", algorithm=MD5, nonce="MTM5OTM3MDg3NjoxOGNkNGFhODIxNzlkNWFjOTliOWQyNGRiYmM3ODA5Yg==", opaque="bd74854f3a6f8ff8faa86bbde6b64663"
Content-Type: text/html; charset=utf-8
Cache-Control: no-cache
X-Request-Id: 73ea9d56-85b7-4224-a148-f56e00dac2f0
X-Runtime: 0.016787
Connection: close
Server: thin 1.6.2 codename Doc Brown

HTTP Digest: Access denied.
```

Autentykujemy się tak:

```sh
curl -i localhost:3000/books/0.json --digest -u admin:sekret
```

Wykonanie tego polecenia zwraca:

```
HTTP/1.1 401 Unauthorized
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
WWW-Authenticate: Digest realm="Application", qop="auth", algorithm=MD5, \
  nonce="MTM5OTM3MTY4MDoxZWVkNTMzNmViNWUzNTkzMGE5ZWQ1ZmQ2Zjc1ZmEyNQ==", \
  opaque="bd74854f3a6f8ff8faa86bbde6b64663"
Content-Type: text/html; charset=utf-8
Cache-Control: no-cache
X-Request-Id: 7076190e-ccb1-40c9-8452-cd49f83ecfdf
X-Runtime: 0.002038
Connection: close
Server: thin 1.6.2 codename Doc Brown

HTTP/1.1 200 OK
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Type: application/json; charset=utf-8
ETag: "2cd9a09c7af0cdd5a6ba092f63af084b"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: e9e35997-e556-4f67-bbb6-2f88e1ba7cea
X-Runtime: 0.023140
Connection: close
Server: thin 1.6.2 codename Doc Brown

{"book":{"id":0,"para":"An Anonymous Volunteer, and David Widger"}}
```

**Well, this breaks the ability to log in via the web interface!**
