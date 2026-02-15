# nf-core/coproid: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.0.1 - 06/02/2026

### `Changed`

- Fixed the Nextflow version badge to ≤24.10.5
- Added some extra information to the README about running the pipeline offline and on HPC with container restrictions
- Updated nf-core/tools to the latest version (by @jfy133)

### `Dependencies`

| Tool          | Old Version | New Version |
| ------------- | ----------- | ----------- |
| nf-core/tools | 3.2.0       | 3.5.2       |

## v2.0.0 - 22/05/2025

nf-core/coproid v2.0 is based on [nf-core](https://nf-co.re/) DSL2 template.
This release is a complete rewrite of the original nf-core/coproid pipeline, originally written in Nextflow DSL1. It also includes new features, and/or updated tools.

### Changed:

- DSL2 rewrite
- fastp replaced AdapterRemoval for read quality trimming/merging.
- sam2lca is now used for computing the endogenous host DNA quantity, instead of custom python scripts, allowing for handling more flexibly test host genomes.
- Pipeline reporting is now performed using Quarto, instead of Jupyter notebook
- Minor JSON schema updates

### New

- aDNA damage testing using PyDamage
- Interactive plots in report
- Unit testing of most modules in the pipeline.

### `Added`

### `Fixed`

### `Dependencies`

### `Deprecated`

## v1.1.1

### Fixed

- Fix [#37](https://github.com/nf-core/coproid/issues/37) with conda environment and docker container update

## v1.1.0

- Update mapped basepair count to be quicker and include it in report [#14](https://github.com/nf-core/coproid/pull/14)
- Remove outdated scripts [#14](https://github.com/nf-core/coproid/pull/14)
- Update logo to match font [#13](https://github.com/nf-core/coproid/pull/13)
- Update Sourcepredict to version 0.4 and reflect new parameters in coproID [#19](https://github.com/nf-core/coproid/pull/19) [e4afca7](https://github.com/nf-core/coproid/commit/e4afca7059c00ebbc753dd02d4aed3f3a1b3b7b8) [
  c2d4164](https://github.com/nf-core/coproid/pull/20/commits/c2d4164bf068ed4fc92d529470b0a3af3a69113a)
- Changed bedtools bamtofastq to samtools fastq [e4afca7](https://github.com/nf-core/coproid/commit/e4afca7059c00ebbc753dd02d4aed3f3a1b3b7b8)
- Fixed column names in report (`PC*` to `DIM*`) [e4afca7](https://github.com/nf-core/coproid/commit/63a6bc6998c240b77791916c243d538b2268b5d5)
- Update README to inlude Zenodo badge, Quick start, contributor section, and tools references. [9874ae8](https://github.com/nf-core/coproid/commit/9874ae87c88842d75c29088672aa81023408d4e7) [e85988b](https://github.com/nf-core/coproid/commit/e85988b883539aa51461e749bc14ec6563f62fc8)
- Update documentation [bedfdde](https://github.com/nf-core/coproid/commit/bedfddec8500adac8e0cb9cc8e0df2dc6a784f15)
- Update Nextflow minimum version to 19.04.0 [44999fd](https://github.com/nf-core/coproid/commit/44999fd4d38b21d53f970621dbf3587c044da8d1)
- Update travis for more recent nextflow requirements [1e3e454](https://github.com/nf-core/coproid/commit/1e3e454e72f1bc8eb43aaa1e5165981cb77a56dc)
- Adapt coproID to nf-core tools 1.8 release [#21](https://github.com/nf-core/coproid/pull/21)
- Add social preview image [#22](https://github.com/nf-core/coproid/pull/22)
- Fix Kraken2 segmentation error [#26](https://github.com/nf-core/coproid/pull/26)
- Update to nf-core tools 1.9 release, and doc for new version of sphinx [#27](https://github.com/nf-core/coproid/pull/27)

## v1.0.0 - 2019-04-26

Initial release of nf-core/coproid, created with the [nf-core](http://nf-co.re/) template.
Adapting [CoproID](https://github.com/maxibor/coproID/tree/dev) to nf-core template

### Improvements over [coproID version 0.6](https://github.com/maxibor/coproID/releases/tag/v0.6.0)

- Support for 3 organism comparison
- Adding [sourcepredict](https://github.com/maxibor/sourcepredict)
- Updating reports to have interactive plotting
- Updated to use Kraken2 instead of Kraken1
- Adding docker

### Adaptions to port to _nf-core_

- Major redefinition of the channels creation to adapt to iGenomes and profiles
- Added and adapted all the nf-core boilerplate code for support of configs and containers
- Improved documentation
