# nf-core/coproid: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.0.0 - 12/05/2025

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
