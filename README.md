# unbound-docker

[Unbound](https://unbound.net) is a validating, recursive, caching DNS resolver.

[![](https://images.microbadger.com/badges/version/klutchell/unbound:amd64.svg)](https://microbadger.com/images/klutchell/unbound:amd64 "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/commit/klutchell/unbound:amd64.svg)](https://microbadger.com/images/klutchell/unbound:amd64 "Get your own commit badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/klutchell/unbound:amd64.svg)](https://microbadger.com/images/klutchell/unbound:amd64 "Get your own image badge on microbadger.com")

[![](https://images.microbadger.com/badges/version/klutchell/unbound:armv7hf.svg)](https://microbadger.com/images/klutchell/unbound:armv7hf "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/commit/klutchell/unbound:armv7hf.svg)](https://microbadger.com/images/klutchell/unbound:armv7hf "Get your own commit badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/klutchell/unbound:armv7hf.svg)](https://microbadger.com/images/klutchell/unbound:armv7hf "Get your own image badge on microbadger.com")

## Build

```bash
# build for amd64
make ARCH=amd64

# build for armv7hf
make ARCH=armv7hf
```

## Deploy

```bash
# deploy on amd64
docker run -p 5353:53/tcp -p 5353:53/udp -d klutchell/unbound:amd64

# deploy on armv7hf
docker run -p 5353:53/tcp -p 5353:53/udp -d klutchell/unbound:armv7hf
```

## Environment

|Name|Description|Example|
|---|---|---|
|`TZ`|(optional) container timezone|`America/Toronto`|

## Usage

https://nlnetlabs.nl/documentation/unbound/

## Testing

You can test DNSSEC validation using
```bash
dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5353
dig sigok.verteiltesysteme.net @127.0.0.1 -p 5353
```
The first command should give a status report of SERVFAIL and no IP address. The second should give NOERROR plus an IP address.

## Contributing

```bash
# bump patch version
make tag BUMP=patch

# bump minor version
make tag BUMP=minor

# bump major version
make tag BUMP=major

# push amd64 image to docker hub
make push ARCH=amd64

# push armv7hf image to docker hub
make push ARCH=armv7hf
```

## Author

Kyle Harding <kylemharding@gmail.com>

## Acknowledgments

* [nlnetlabs.nl](https://nlnetlabs.nl/)
* [balena.io](https://www.balena.io/)
* [pi-hole.net](https://pi-hole.net/)
* [Eduardo Rocha](https://github.com/folhabranca)
* [Matthew Vance](https://github.com/MatthewVance)

## References

* https://www.balena.io/docs/reference/base-images/base-images/
* https://www.nlnetlabs.nl/svn/unbound/trunk/doc/example.conf.in
* https://docs.pi-hole.net/guides/unbound/
* https://github.com/folhabranca/docker-unbound
* https://github.com/MatthewVance/unbound-docker
* http://dnssec.vs.uni-due.de/
* https://nlnetlabs.nl/documentation/unbound/howto-anchor/
* http://www.linuxfromscratch.org/blfs/view/svn/server/unbound.html
* https://nlnetlabs.nl/documentation/unbound/howto-setup/

## License

[MIT License](./LICENSE)