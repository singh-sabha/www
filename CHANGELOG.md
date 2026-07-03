# Changelog

## [1.5.0](https://github.com/singh-sabha/www/compare/v1.4.0...v1.5.0) (2026-07-03)


### Features

* use an S3 bucket instead of pod-local storage ([8c56ce3](https://github.com/singh-sabha/www/commit/8c56ce3c8d141ded184272f7afd2a4de7b4a4f12))

## [1.4.0](https://github.com/singh-sabha/www/compare/v1.3.1...v1.4.0) (2026-07-02)


### Features

* add Oban ([2ec0d5d](https://github.com/singh-sabha/www/commit/2ec0d5d3593e5f8db96775c030d64c740559d9a6))
* improve design ([5941f04](https://github.com/singh-sabha/www/commit/5941f04ab65585fd277266d6da30f2fa4983fc56))
* now able to parse images and extract relevant events ([f0c3a5c](https://github.com/singh-sabha/www/commit/f0c3a5c1df9407fbb29bf10467df04eea17b0209))


### Bug Fixes

* allow for proper noun casing ([854118a](https://github.com/singh-sabha/www/commit/854118a1cdc4cb571b34ad21bbe27c6646567407))
* dangling updates ([843c80b](https://github.com/singh-sabha/www/commit/843c80b7b87fc1b584177851700e7faa02960adf))
* modal not closing after clicking "Save changes" ([f0c3a5c](https://github.com/singh-sabha/www/commit/f0c3a5c1df9407fbb29bf10467df04eea17b0209))
* reset processing flag after successful ingestion ([f0c3a5c](https://github.com/singh-sabha/www/commit/f0c3a5c1df9407fbb29bf10467df04eea17b0209))
* should be using updated event instead of of desync'd version ([3b75d73](https://github.com/singh-sabha/www/commit/3b75d7341081c4bdb6cbe0513ec8ad7f23198a0d))

## [1.3.1](https://github.com/singh-sabha/www/compare/v1.3.0...v1.3.1) (2026-06-22)


### Bug Fixes

* remove `n8n` integration ([7733eaf](https://github.com/singh-sabha/www/commit/7733eaf4f263649b74390a944c6d2683c86ad347))

## [1.3.0](https://github.com/singh-sabha/www/compare/v1.2.7...v1.3.0) (2026-05-25)


### Features

* use a GenServer to fetch live stream ([32eab1a](https://github.com/singh-sabha/www/commit/32eab1a320e38cb9355a8c9625847740d08d5164))

## [1.2.7](https://github.com/singh-sabha/www/compare/v1.2.6...v1.2.7) (2026-05-25)


### Bug Fixes

* remove dead code ([f8c1640](https://github.com/singh-sabha/www/commit/f8c16405656920d263fdc9e7c4ef0acc0f6266cd))

## [1.2.6](https://github.com/singh-sabha/www/compare/v1.2.5...v1.2.6) (2026-05-25)


### Bug Fixes

* remove GeoIP to prevent websocket promotion issues ([fbc35ce](https://github.com/singh-sabha/www/commit/fbc35ce431eebf9efb2d5a24390e54e949ba9ddd))

## [1.2.5](https://github.com/singh-sabha/www/compare/v1.2.4...v1.2.5) (2026-05-23)


### Bug Fixes

* `track_location` should be set to true in prod ([2dd7bab](https://github.com/singh-sabha/www/commit/2dd7bab2b1065d744b28c2f88d420fec8e318e19))

## [1.2.4](https://github.com/singh-sabha/www/compare/v1.2.3...v1.2.4) (2026-05-23)


### Bug Fixes

* do not track user location in dev environments ([fcb1748](https://github.com/singh-sabha/www/commit/fcb174864b8d7844d293ad717ea4685caea19fb2))

## [1.2.3](https://github.com/singh-sabha/www/compare/v1.2.2...v1.2.3) (2026-05-10)


### Bug Fixes

* output x-header information ([1b75159](https://github.com/singh-sabha/www/commit/1b7515981f0159f37921e8ac449fcc4bc4378f28))

## [1.2.2](https://github.com/singh-sabha/www/compare/v1.2.1...v1.2.2) (2026-05-10)


### Bug Fixes

* output geolocation information as logs ([02fc2c1](https://github.com/singh-sabha/www/commit/02fc2c1e8542902684d5b87d5171c085ef5fac88))

## [1.2.1](https://github.com/singh-sabha/www/compare/v1.2.0...v1.2.1) (2026-05-10)


### Bug Fixes

* filter instead of boolean logic overloading ([fad92a6](https://github.com/singh-sabha/www/commit/fad92a6d47cd1062d7aa1de101be67433297d765))
* should be using "success" instead of "200" ([9a72d5f](https://github.com/singh-sabha/www/commit/9a72d5f5bd2709ead94f3745ed79d46235eb1af8))

## [1.2.0](https://github.com/singh-sabha/www/compare/v1.1.0...v1.2.0) (2026-05-10)


### Features

* track user geolocation ([88c322c](https://github.com/singh-sabha/www/commit/88c322c07176e6b5769510b365da5ff0046316f2))

## [1.1.0](https://github.com/singh-sabha/www/compare/v1.0.0...v1.1.0) (2026-05-03)


### Features

* use local copy of fctimes article ([4194381](https://github.com/singh-sabha/www/commit/419438131c61fd2dfa7bcc578d72d92e8b129261))

## 1.0.0 (2026-05-03)


### Features

* use local copy of fctimes article ([4194381](https://github.com/singh-sabha/www/commit/419438131c61fd2dfa7bcc578d72d92e8b129261))

## 1.0.0 (2026-05-03)


### Features

* initial release ([f61596e](https://github.com/singh-sabha/www/commit/f61596eff3227924f6432449430568a884f548fd))
