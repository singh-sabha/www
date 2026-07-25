# Changelog

## [2.0.2](https://github.com/singh-sabha/www/compare/v2.0.1...v2.0.2) (2026-07-25)


### Bug Fixes

* spacing in notifications ([324622d](https://github.com/singh-sabha/www/commit/324622d157f8c3c11c31aaa469d8986eb8c220e1))

## [2.0.1](https://github.com/singh-sabha/www/compare/v2.0.0...v2.0.1) (2026-07-19)


### Bug Fixes

* improve badge contrast ([8a947a3](https://github.com/singh-sabha/www/commit/8a947a32848ed5b8afccbf2d3a757a341d8d1265))

## [2.0.0](https://github.com/singh-sabha/www/compare/v1.5.0...v2.0.0) (2026-07-19)


### ⚠ BREAKING CHANGES

* support drafts in the agentic workflow

### Features

* delete a draft and its associated events ([c95cbaf](https://github.com/singh-sabha/www/commit/c95cbaf9e7a082a8c82a58871be3d00e96ceba62))
* move away from using `ModalManager` for modal manipulation ([1f89f99](https://github.com/singh-sabha/www/commit/1f89f998e7a50789aba931e2aa2c487a4cb7ec8a))
* support drafts in the agentic workflow ([803edc6](https://github.com/singh-sabha/www/commit/803edc651619a03ded459956d1d25d1d7fcf946d))


### Bug Fixes

* add `assistant` path resolver function ([803edc6](https://github.com/singh-sabha/www/commit/803edc651619a03ded459956d1d25d1d7fcf946d))
* automatic width adjustments ([d04f7e8](https://github.com/singh-sabha/www/commit/d04f7e89d26cf36b8ff2a8f5044f367fbd0e5f3f))
* broken modal usage ([3bdd0c6](https://github.com/singh-sabha/www/commit/3bdd0c6115353a8b95b693aed127efe4e4165fc1))
* consider all events not just single day ([32568c1](https://github.com/singh-sabha/www/commit/32568c16b858f16192eea98b9c4af4f4481d5e11))
* dont change the view when setting the current date ([e9efa46](https://github.com/singh-sabha/www/commit/e9efa464dfe0dbb1eec5dfa278b6acc77f05f69c))
* filter out events that have a draft ([93eb97f](https://github.com/singh-sabha/www/commit/93eb97ff7b54a31441dec5b35d5f01a6538f9cc9))
* link tag was not rendering space ([7c48221](https://github.com/singh-sabha/www/commit/7c48221f6b63b3bb8928b9a2bc7203230ba52bfb))
* make wider ([1dfe76d](https://github.com/singh-sabha/www/commit/1dfe76d3eff9f91e541113b152df1312155df79e))
* no longer raising when an event is not found ([e3433a7](https://github.com/singh-sabha/www/commit/e3433a7269913fe2328cd3f6e3d5a0d4d5f99f14))
* remove inaccurate todo ([6fc44b7](https://github.com/singh-sabha/www/commit/6fc44b75adddf66469e04a9acd74e95a9f908de7))
* remove stubs ([ef6ccf5](https://github.com/singh-sabha/www/commit/ef6ccf557865ed8a42472dfc2849a94cab3cdb64))
* spacing ([5670a99](https://github.com/singh-sabha/www/commit/5670a99da7606451d565952b5a35a92432522848))
* traversing through buttons did not preserve query path ([10c72ab](https://github.com/singh-sabha/www/commit/10c72ab3364b7208adf186f80414661b9210e3a4))
* update design style ([1dfe76d](https://github.com/singh-sabha/www/commit/1dfe76d3eff9f91e541113b152df1312155df79e))


### Performance Improvements

* remove unused function ([cb6725d](https://github.com/singh-sabha/www/commit/cb6725da92ca67a61eb4f6a8919d7f74222645cc))

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
