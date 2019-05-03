# nf-core/coproid: Changelog

## v1.0.1dev

Update logo to match font [#13](https://github.com/nf-core/coproid/pull/13)

## v1.0 - 2019-04-26

Initial release of nf-core/coproid, created with the [nf-core](http://nf-co.re/) template.
Adapting [CoproID](https://github.com/maxibor/coproID/tree/dev) to nf-core template

### Improvements over [coproID version 0.6](https://github.com/maxibor/coproID/releases/tag/v0.6.0)

-   Support for 3 organism comparison
-   Adding [sourcepredict](https://github.com/maxibor/sourcepredict)
-   Updating reports to have interactive plotting
-   Updated to use Kraken2 instead of Kraken1
-   Adding docker

### Adaptions to port to _nf-core_

-   Major redefinition of the channels creation to adapt to iGenomes and profiles
-   Added and adapted all the nf-core boilerplate code for support of configs and containers
-   Improved documentation
