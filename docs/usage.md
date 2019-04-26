<!-- vscode-markdown-toc -->
* [Table of contents](#Tableofcontents)
* [Introduction](#Introduction)
* [Running the pipeline](#Runningthepipeline)
	* [Updating the pipeline](#Updatingthepipeline)
	* [Reproducibility](#Reproducibility)
* [Main arguments](#Mainarguments)
	* [`-profile`](#-profile)
	* [`--reads`](#--reads)
	* [`--singleEnd`](#--singleEnd)
	* [`--name1`](#--name1)
	* [`--name2`](#--name2)
	* [`--krakenDB`](#--krakenDB)
* [Reference genomes](#Referencegenomes)
	* [`--genome1` (using iGenomes)](#--genome1usingiGenomes)
	* [`--fasta1`](#--fasta1)
	* [`--fasta2`](#--fasta2)
	* [`--genome2`](#--genome2)
	* [`--igenomesIgnore`](#--igenomesIgnore)
* [Settings](#Settings)
	* [`--adna`](#--adna)
	* [`--phred`](#--phred)
	* [`--collapse`](#--collapse)
	* [`--identity`](#--identity)
	* [`--pmdscore`](#--pmdscore)
	* [`--library`](#--library)
	* [`--bowtie`](#--bowtie)
	* [`--minKraken`](#--minKraken)
	* [`--endo1`](#--endo1)
	* [`--endo2`](#--endo2)
	* [`--endo3`](#--endo3)
* [Other coproID parameters](#OthercoproIDparameters)
	* [`--name3`](#--name3)
	* [`--fasta3`](#--fasta3)
	* [`--genome3`](#--genome3)
	* [`--index1`](#--index1)
	* [`--index2`](#--index2)
	* [`--index3`](#--index3)
* [Job resources](#Jobresources)
	* [Automatic resubmission](#Automaticresubmission)
	* [Custom resource requests](#Customresourcerequests)
* [AWS Batch specific parameters](#AWSBatchspecificparameters)
	* [`--awsqueue`](#--awsqueue)
	* [`--awsregion`](#--awsregion)
* [Other command line parameters](#Othercommandlineparameters)
	* [`--outdir`](#--outdir)
	* [`--email`](#--email)
	* [`-name`](#-name)
	* [`-resume`](#-resume)
	* [`-c`](#-c)
	* [`--custom_config_version`](#--custom_config_version)
	* [`--custom_config_base`](#--custom_config_base)
	* [`--max_memory`](#--max_memory)
	* [`--max_time`](#--max_time)
	* [`--max_cpus`](#--max_cpus)
	* [`--plaintext_email`](#--plaintext_email)
	* [`--monochrome_logs`](#--monochrome_logs)
	* [`--multiqc_config`](#--multiqc_config)

<!-- vscode-markdown-toc-config
	numbering=false
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc --># nf-core/coproid: Usage

## <a name='Tableofcontents'></a>Table of contents



## <a name='Introduction'></a>Introduction

Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

It is recommended to limit the Nextflow Java virtual machines memory. We recommend adding the following line to your environment (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

## <a name='Runningthepipeline'></a>Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/coproid --reads '*_R{1,2}.fastq.gz' --krakendb 'path/to/kraken_db' -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### <a name='Updatingthepipeline'></a>Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/coproid
```

### <a name='Reproducibility'></a>Reproducibility

It's a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/coproid releases page](https://github.com/nf-core/coproid/releases) and find the latest version number - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

## <a name='Mainarguments'></a>Main arguments

### <a name='-profile'></a>`-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments. Note that multiple profiles can be loaded, for example: `-profile docker` - the order of arguments is important!

If `-profile` is not specified at all the pipeline will be run locally and expects all software to be installed and available on the `PATH`.

-   `awsbatch`
    -   A generic configuration profile to be used with AWS Batch.
-   `conda`
    -   A generic configuration profile to be used with [conda](https://conda.io/docs/)
    -   Pulls most software from [Bioconda](https://bioconda.github.io/)
-   `docker`
    -   A generic configuration profile to be used with [Docker](http://docker.com/)
    -   Pulls software from dockerhub: [`nfcore/coproid`](http://hub.docker.com/r/nfcore/coproid/)
-   `singularity`
    -   A generic configuration profile to be used with [Singularity](http://singularity.lbl.gov/)
    -   Pulls software from DockerHub: [`nfcore/coproid`](http://hub.docker.com/r/nfcore/coproid/)
-   `test`
    -   A profile with a complete configuration for automated testing
    -   Includes links to test data so needs no other parameters

### <a name='--reads'></a>`--reads`

Use this to specify the location of your input FastQ files. For example:

```bash
--reads 'path/to/data/sample_*_{1,2}.fastq'
```

Please note the following requirements:

1.  The path must be enclosed in quotes
2.  The path must have at least one `*` wildcard character
3.  When using the pipeline with paired end data, the path must use `{1,2}` notation to specify read pairs.

If left unspecified, a default pattern is used: `data/*{1,2}.fastq.gz`

### <a name='--singleEnd'></a>`--singleEnd`

By default, the pipeline expects paired-end data. If you have single-end data, you need to specify `--singleEnd` on the command line when you launch the pipeline. A normal glob pattern, enclosed in quotation marks, can then be used for `--reads`. For example:

```bash
--singleEnd --reads '*.fastq'
```

It is not possible to run a mixture of single-end and paired-end files in one run.

### <a name='--name1'></a>`--name1`

Name of the first candidate species. Example : `"Homo_sapiens"`

### <a name='--name2'></a>`--name2`

Name of the second candidate species. Example : `"Canis_familiaris"`

### <a name='--krakenDB'></a>`--krakenDB`

Path to Path to Kraken2 MiniKraken2_v2_8GB Database. Can be downloaded [here](https://ccb.jhu.edu/software/kraken2/dl/old/minikraken2_v2_8GB.tgz)

## <a name='Referencegenomes'></a>Reference genomes

The pipeline config files come bundled with paths to the illumina iGenomes reference index files. If running with docker or AWS, the configuration is set up to use the [AWS-iGenomes](https://ewels.github.io/AWS-iGenomes/) resource.

### <a name='--genome1usingiGenomes'></a>`--genome1` (using iGenomes)

There are 31 different species supported in the iGenomes references. To run the pipeline, you must specify which to use with the `--genome` flag.

You can find the keys to specify the genomes in the [iGenomes config file](../conf/igenomes.config). Common genomes that are supported are:

-   Human
    -   `--genome GRCh37`
-   Dog
    -   `--genome CanFam3.1`

> There are numerous others - check the config file for more.

Note that you can use the same configuration setup to save sets of reference files for your own use, even if they are not part of the iGenomes resource. See the [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for instructions on where to save such a file.

The syntax for this reference configuration is as follows:

```groovy
params {
  // illumina iGenomes reference file paths
  genomes {
    'GRCh37' {
      fasta   = "${params.igenomes_base}/Homo_sapiens/Ensembl/GRCh37/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Homo_sapiens/Ensembl/GRCh37/Sequence/Bowtie2Index/genome"
    }
    'GRCm38' {
      fasta   = "${params.igenomes_base}/Mus_musculus/Ensembl/GRCm38/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Mus_musculus/Ensembl/GRCh37/Sequence/Bowtie2Index/genome"
    }
    'UMD3.1' {
      fasta   = "${params.igenomes_base}/Bos_taurus/Ensembl/UMD3.1/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Bos_taurus/Ensembl/UMD3.1/Sequence/Bowtie2Index/genome"
    }
    'CanFam3.1' {
      fasta   = "${params.igenomes_base}/Canis_familiaris/Ensembl/CanFam3.1/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Canis_familiaris/Ensembl/CanFam3.1/Sequence/Bowtie2Index/genome"
    }
    'EquCab2' {
      fasta   = "${params.igenomes_base}/Equus_caballus/Ensembl/EquCab2/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Equus_caballus/Ensembl/EquCab2/Sequence/Bowtie2Index/genome"
    }
    'Galgal4' {
      fasta   = "${params.igenomes_base}/Gallus_gallus/Ensembl/Galgal4/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Gallus_gallus/Ensembl/Galgal4/Sequence/Bowtie2Index/genome"
    }
    'Mmul_1' {
      fasta   = "${params.igenomes_base}/Macaca_mulatta/Ensembl/Mmul_1/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Macaca_mulatta/Ensembl/Mmul_1/Sequence/Bowtie2Index/genome"
    }
    'CHIMP2.1.4' {
      fasta   = "${params.igenomes_base}/Pan_troglodytes/Ensembl/CHIMP2.1.4/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Pan_troglodytes/Ensembl/CHIMP2.1.4/Sequence/Bowtie2Index/genome"
    }
    'Rnor_6.0' {
      fasta   = "${params.igenomes_base}/Rattus_norvegicus/Ensembl/Rnor_6.0/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Rattus_norvegicus/Ensembl/Rnor_6.0/Sequence/Bowtie2Index/genome"
    }
    'Sscrofa10.2' {
      fasta   = "${params.igenomes_base}/Sus_scrofa/Ensembl/Sscrofa10.2/Sequence/WholeGenomeFasta/genome.fa"
      bowtie2 = "${params.igenomes_base}/Sus_scrofa/Ensembl/Sscrofa10.2/Sequence/Bowtie2Index/genome"
    }
  }
}
```

### <a name='--fasta1'></a>`--fasta1`

If you prefer, you can specify the full path to your reference genome when you run the pipeline:

```bash
--fasta1 'path/to/fasta/reference.fa'
```

### <a name='--fasta2'></a>`--fasta2`

If you prefer, you can specify the full path to your reference genome when you run the pipeline:

```bash
--fasta2 'path/to/fasta/reference.fa'
```

### <a name='--genome2'></a>`--genome2` (using iGenomes)

Name of iGenomes reference for candidate organism 3. Must be provided if fasta2 is not provided

```bash
--genome2 'CanFam3.1'
```

### <a name='--igenomesIgnore'></a>`--igenomesIgnore`

Do not load `igenomes.config` when running the pipeline. You may choose this option if you observe clashes between custom parameters and those supplied in `igenomes.config`.

## <a name='Settings'></a>Settings

### <a name='--adna'></a>`--adna`

Specified if data is modern (false) or ancient DNA (true). Default = true

```bash
--adna true
```

or

```bash
--adna false
```

### <a name='--phred'></a>`--phred`

Specifies the fastq quality encoding (33 | 64). Defaults to 33

```bash
--phred 33
```

or

```bash
--phred 64
```

### <a name='--collapse'></a>`--collapse`

Specifies if AdapterRemoval should merge the paired-end sequences or not. Default = true

```bash
--collapse true
```

or

```bash
--collapse false
```

### <a name='--identity'></a>`--identity`

Identity threshold to retain read alignment. Default = 0.95

```bash
--identity 0.95
```

### <a name='--pmdscore'></a>`--pmdscore`

Minimum PMDscore to retain read alignment. Default = 3

```bash
--pmdscore 3
```

### <a name='--library'></a>`--library`

DNA preparation library type ( classic | UDGhalf). Default = classic

```bash
--library classic
```

or

```bash
--library UDGhalf
```

### <a name='--bowtie'></a>`--bowtie`

Bowtie settings for sensivity (very-fast | very-sensitive). Default = very-sensitive

```bash
--bowtie very-fast
```

or

```bash
--bowtie very-sensitive
```

### <a name='--minKraken'></a>`--minKraken`

Minimum number of Kraken hits per Taxonomy ID to report. Default = 50

```bash
--minKraken 50
```

### <a name='--endo1'></a>`--endo1`

Proportion of Endogenous DNA in organism 1 target microbiome. Must be between 0 and 1. Default = 0.01

```bash
--endo1 0.01
```

### <a name='--endo2'></a>`--endo2`

Proportion of Endogenous DNA in organism 2 target microbiome. Must be between 0 and 1. Default = 0.01

```bash
--endo2 0.01
```

### <a name='--endo3'></a>`--endo3`

Proportion of Endogenous DNA in organism 3 target microbiome. Must be between 0 and 1. Default = 0.01

```bash
--endo3 0.01
```

## <a name='OthercoproIDparameters'></a>Other coproID parameters

### <a name='--name3'></a>`--name3`

Name of candidate 1. Example: "Sus_scrofa"

### <a name='--fasta3'></a>`--fasta3`

Path to canidate organism 3 genome fasta file (must be surrounded with quotes). Must be provided if ### \`genome3 is not provided

```bash
--fasta3 'path/to/fasta/reference.fa'
```

### <a name='--genome3'></a>`--genome3` (using iGenomes)

Name of iGenomes reference for candidate organism 3. Must be provided if \`fasta3 is not provided

```bash
--genome3 'Sscrofa10.2'
```

### <a name='--index1'></a>`--index1`

Path to Bowtie2 index genome candidate 2 Coprolite maker's genome

```bash
--index1 'path/to/bt_index/basename*'
```

### <a name='--index2'></a>`--index2`

Path to Bowtie2 index genome candidate 2 Coprolite maker's genome

```bash
--index2 'path/to/bt_index/basename*'
```

### <a name='--index3'></a>`--index3`

Path to Bowtie2 index genome candidate 3 Coprolite maker's genome

```bash
--index3 'path/to/bt_index/basename*'
```

## <a name='Jobresources'></a>Job resources

### <a name='Automaticresubmission'></a>Automatic resubmission

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

### <a name='Customresourcerequests'></a>Custom resource requests

Wherever process-specific requirements are set in the pipeline, the default value can be changed by creating a custom config file. See the files hosted at [`nf-core/configs`](https://github.com/nf-core/configs/tree/master/conf) for examples.

If you are likely to be running `nf-core` pipelines regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter (see definition below). You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

If you have any questions or issues please send us a message on [Slack](https://nf-core-invite.herokuapp.com/).

## <a name='AWSBatchspecificparameters'></a>AWS Batch specific parameters

Running the pipeline on AWS Batch requires a couple of specific parameters to be set according to your AWS Batch configuration. Please use the `-awsbatch` profile and then specify all of the following parameters.

### <a name='--awsqueue'></a>`--awsqueue`

The JobQueue that you intend to use on AWS Batch.

### <a name='--awsregion'></a>`--awsregion`

The AWS region to run your job in. Default is set to `eu-west-1` but can be adjusted to your needs.

Please make sure to also set the `-w/--work-dir` and `--outdir` parameters to a S3 storage bucket of your choice - you'll get an error message notifying you if you didn't.

## <a name='Othercommandlineparameters'></a>Other command line parameters

### <a name='--outdir'></a>`--outdir`

The output directory where the results will be saved.

### <a name='--email'></a>`--email`

Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.

### <a name='-name'></a>`-name`

Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

This is used in the MultiQC report (if not default) and in the summary HTML / e-mail (always).

**NB:** Single hyphen (core Nextflow option)

### <a name='-resume'></a>`-resume`

Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

**NB:** Single hyphen (core Nextflow option)

### <a name='-c'></a>`-c`

Specify the path to a specific config file (this is a core NextFlow command).

**NB:** Single hyphen (core Nextflow option)

Note - you can use this to override pipeline defaults.

### <a name='--custom_config_version'></a>`--custom_config_version`

Provide git commit id for custom Institutional configs hosted at `nf-core/configs`. This was implemented for reproducibility purposes. Default is set to `master`.

```bash
## Download and use config file with following git commid id
--custom_config_version d52db660777c4bf36546ddb188ec530c3ada1b96
```

### <a name='--custom_config_base'></a>`--custom_config_base`

If you're running offline, nextflow will not be able to fetch the institutional config files
from the internet. If you don't need them, then this is not a problem. If you do need them,
you should download the files from the repo and tell nextflow where to find them with the
`custom_config_base` option. For example:

```bash
## Download and unzip the config files
cd /path/to/my/configs
wget https://github.com/nf-core/configs/archive/master.zip
unzip master.zip

## Run the pipeline
cd /path/to/my/data
nextflow run /path/to/pipeline/ --custom_config_base /path/to/my/configs/configs-master/
```

> Note that the nf-core/tools helper package has a `download` command to download all required pipeline
> files + singularity containers + institutional configs in one go for you, to make this process easier.

### <a name='--max_memory'></a>`--max_memory`

Use to set a top-limit for the default memory requirement for each process.
Should be a string in the format integer-unit. eg. `--max_memory '8.GB'`

### <a name='--max_time'></a>`--max_time`

Use to set a top-limit for the default time requirement for each process.
Should be a string in the format integer-unit. eg. `--max_time '2.h'`

### <a name='--max_cpus'></a>`--max_cpus`

Use to set a top-limit for the default CPU requirement for each process.
Should be a string in the format integer-unit. eg. `--max_cpus 1`

### <a name='--plaintext_email'></a>`--plaintext_email`

Set to receive plain-text e-mails instead of HTML formatted.

### <a name='--monochrome_logs'></a>`--monochrome_logs`

Set to disable colourful command line output and live life in monochrome.

### <a name='--multiqc_config'></a>`--multiqc_config`

Specify a path to a custom MultiQC configuration file.
