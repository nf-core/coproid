Troubleshooting
===============

## Known issues

-   On Mac OS X, the nextflow log reporting (`-with-report`) may not work with Nextflow v0.31.1. This should be fixed in future Nextflow releases.
-   If the DNA damage levels are too low, mapDamage may crash.
-   If you run into the following error `CondaVerificationError: The package for openjdk located at...`, running `conda clean --all` might fix it
-   If you run into an error stating `Failed to create Conda environment`, please relaunch **coproID** with the flag `-resume`. It will restart just before it crashed without loosing any results. This error is due to a network communication problem that sometimes happens with the anaconda servers.

## Other issues

If you find a specific issue, please open an [issue](https://github.com/maxibor/coproid/issues) on [GitHub](https://github.com/maxibor/coproid/issues)
