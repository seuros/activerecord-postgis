# Changelog

## [0.4.0](https://github.com/seuros/activerecord-postgis/compare/activerecord-postgis/v0.3.1...activerecord-postgis/v0.4.0) (2025-09-05)


### Features

* support rails 8.1 ([a127ad4](https://github.com/seuros/activerecord-postgis/commit/a127ad44a13d7340a53a8303c31071d89aaa9b2c))
* support rails 8.1 ([4dc0af5](https://github.com/seuros/activerecord-postgis/commit/4dc0af59bbe480b8bfc4d445b2899b4368fdc403))

## [0.3.1](https://github.com/seuros/activerecord-postgis/compare/activerecord-postgis/v0.3.0...activerecord-postgis/v0.3.1) (2025-07-21)


### Bug Fixes

* correct version file path in release-please config ([ae3b8ee](https://github.com/seuros/activerecord-postgis/commit/ae3b8ee28075e8993e11c859d3140b002e448b73))

## [0.3.0](https://github.com/seuros/activerecord-postgis/compare/activerecord-postgis/v0.2.0...activerecord-postgis/v0.3.0) (2025-07-21)


### Features

* add advanced Arel spatial functions and documentation ([9ed58af](https://github.com/seuros/activerecord-postgis/commit/9ed58afe178b85fe246a199b5227018c10fd3552))
* Add K-Nearest Neighbor (&lt;-&gt;) operator for blazing fast spatial searches ([6c7b1d9](https://github.com/seuros/activerecord-postgis/commit/6c7b1d9470870fdbabf65194aeef83004a241ea0))


### Bug Fixes

* add test helper ([ac60c3b](https://github.com/seuros/activerecord-postgis/commit/ac60c3bfdc68c20f75cc608ea5e1eace9fafd460))
* handle empty sql_type in joins gracefully with explicit fallback ([1a7ffa7](https://github.com/seuros/activerecord-postgis/commit/1a7ffa75a106335e089953706bb82f1b13fd0a26))
* install GEOS library in CI for RGeo spatial predicates ([#4](https://github.com/seuros/activerecord-postgis/issues/4)) ([de5945f](https://github.com/seuros/activerecord-postgis/commit/de5945f0a6d675ab8607deefe023ebb3e574a2ef))
* use consistent require style for test_helper in all test files ([a8f7472](https://github.com/seuros/activerecord-postgis/commit/a8f74723c5f62cfef1bdbdbafa3edd473f90edfa))

## [0.2.0](https://github.com/seuros/activerecord-postgis/compare/activerecord-postgis-v0.1.0...activerecord-postgis/v0.2.0) (2025-05-30)


### Features

* add geographic option to geometry types and initialize release workflow ([24661f0](https://github.com/seuros/activerecord-postgis/commit/24661f0c897fbc2a7dad7c0e25efa3688f839430))
* fix queries and import tests ([0127091](https://github.com/seuros/activerecord-postgis/commit/01270912259cee2c4c80bdf319daea169a1edefb))
