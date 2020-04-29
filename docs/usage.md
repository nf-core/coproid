# Usage

## Introduction

Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

It is recommended to limit the Nextflow Java virtual machines memory. We recommend adding the following line to your environment (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/coproid --genome1 'GRCh37' --genome2 'CanFam3.1' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz' --krakendb 'path/to/minikraken_db' -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/coproid
```

### Reproducibility

It's a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/coproid releases page](https://github.com/nf-core/coproid/releases) and find the latest version number - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

## Main arguments

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Conda) - see below.

> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended.

* `docker`
  * A generic configuration profile to be used with [Docker](http://docker.com/)
  * Pulls software from dockerhub: [`nfcore/coproid`](http://hub.docker.com/r/nfcore/coproid/)
* `singularity`
  * A generic configuration profile to be used with [Singularity](http://singularity.lbl.gov/)
  * Pulls software from DockerHub: [`nfcore/coproid`](http://hub.docker.com/r/nfcore/coproid/)
* `conda`
  * Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker or Singularity.
  * A generic configuration profile to be used with [Conda](https://conda.io/docs/)
  * Pulls most software from [Bioconda](https://bioconda.github.io/)
* `test`
  * A profile with a complete configuration for automated testing
  * Includes links to test data so needs no other parameters

### `--reads`

Use this to specify the location of your input FastQ files. For example:

```bash
--reads 'path/to/data/sample_*_{1,2}.fastq'
```

Please note the following requirements:

1. The path must be enclosed in quotes
2. The path must have at least one `*` wildcard character
3. When using the pipeline with paired end data, the path must use `{1,2}` notation to specify read pairs.

If left unspecified, a default pattern is used: `data/*{1,2}.fastq.gz`

### `--single_end`

By default, the pipeline expects paired-end data. If you have single-end data, you need to specify `--single_end` on the command line when you launch the pipeline. A normal glob pattern, enclosed in quotation marks, can then be used for `--reads`. For example:

```bash
--single_end --reads '*.fastq'
```

It is not possible to run a mixture of single-end and paired-end files in one run.

### `--name1`

Name of the first candidate species. Example : `"Homo_sapiens"`

### `--name2`

Name of the second candidate species. Example : `"Canis_familiaris"`

### `--krakenDB`

Path to the directory containing the Kraken2 MiniKraken2_v2_8GB database files.
The MiniKraken2_v2_8GB database can be downloaded [here](https://ccb.jhu.edu/software/kraken2/dl/old/minikraken2_v2_8GB.tgz)

```bash
--krakendb "path/to/kraken2_db_dir"
```

## Reference genomes

The pipeline config files come bundled with paths to the illumina iGenomes reference index files. If running with docker or AWS, the configuration is set up to use the [AWS-iGenomes](https://ewels.github.io/AWS-iGenomes/) resource.

### `--fasta1`

Reference genome1 can be specified by using the full path to the genome fasta file. Must be provided if `--genome1` is not provided.

```bash
--fasta1 'path/to/fasta/reference1.fa'
```

### `--fasta2`

Reference genome2 can be specified by using the full path to the genome fasta file. Must be provided if `--genome2` is not provided.

```bash
--fasta2 'path/to/fasta/reference2.fa'
```

### `--genome1` (using iGenomes)

Alternatively, reference genomes can be specified using pre-index genomes available through the iGenomes service. Must be provided if `--fasta1` is not provided.  

There are 31 different species supported in the iGenomes references. To run the pipeline, you must specify which to use with the `--genome` flag.

You can find the keys to specify the genomes in the [iGenomes config file](https://github.com/nf-core/coproid/blob/master/conf/igenomes.config). Common genomes that are supported are:

* Human
  * `--genome GRCh37`
* Dog
  * `--genome CanFam3.1`

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

### `--genome2` (using iGenomes)

Name of iGenomes reference for candidate organism 2. Must be provided if `--fasta2` is not provided.  

```bash
--genome2 'CanFam3.1'
```

### `--igenomes_ignore`

Do not load `igenomes.config` when running the pipeline. You may choose this option if you observe clashes between custom parameters and those supplied in `igenomes.config`.

## Settings

### `--adna`

Specified if data is modern (false) or ancient DNA (true). Default = true

```bash
--adna true
```

or

```bash
--adna false
```

### `--phred`

Specifies the fastq quality encoding (33 | 64). Defaults to 33

```bash
--phred 33
```

or

```bash
--phred 64
```

### `--collapse`

Specifies if AdapterRemoval should merge the paired-end sequences or not. Default = true

```bash
--collapse true
```

or

```bash
--collapse false
```

### `--identity`

Identity threshold to retain read alignment. Default = 0.95

```bash
--identity 0.95
```

### `--pmdscore`

Minimum PMDscore to retain read alignment. Default = 3

```bash
--pmdscore 3
```

### `--library`

DNA preparation library type ( classic | UDGhalf). Default = classic

```bash
--library classic
```

or

```bash
--library UDGhalf
```

### `--bowtie`

Bowtie settings for sensivity (very-fast | very-sensitive). Default = very-sensitive

```bash
--bowtie very-fast
```

or

```bash
--bowtie very-sensitive
```

### `--minKraken`

Minimum number of Kraken hits per Taxonomy ID to report. Default = 50

```bash
--minKraken 50
```

### `--endo1`

Proportion of Endogenous DNA in organism 1 target microbiome. Must be between 0 and 1. Default = 0.01

```bash
--endo1 0.01
```

### `--endo2`

Proportion of Endogenous DNA in organism 2 target microbiome. Must be between 0 and 1. Default = 0.01

```bash
--endo2 0.01
```

### `sp_embed`

SourcePredict embedding algorithm. One of mds, tsne, umap. Default to mds from coproID version 1.1

```bash
--sp_embed mds
```

More information is available in the [Sourcepredict documentation](https://sourcepredict.readthedocs.io/en/latest/index.html)

### `sp_norm`

Sourcepredict normalization method. One of 'rle', 'gmpr', 'subsample'. Default = 'gmpr'

```bash
--sp_norm 'gmpr'
```

More informations are available in the [Sourcepredict documentation](https://sourcepredict.readthedocs.io/en/latest/index.html)

### `sp_neighbors`

Sourcepredict numbers of neighbors for KNN ML. Integer or all. Default = all

```bash
--sp_neighbors all
```

More informations are available in the [Sourcepredict documentation](https://sourcepredict.readthedocs.io/en/latest/index.html)

## Other coproID parameters

### `--name3`

Name of candidate species 3.

`--name3 Sus_scrofa`

### `--fasta3`

Reference genome3 can be specified by using the full path to the genome fasta file. Must be provided if `--genome3` is not provided.

```bash
--fasta3 'path/to/fasta/reference3.fa'
```

### `--genome3` (using iGenomes)

Name of iGenomes reference for candidate organism 3. Must be provided if `--fasta3` is not provided.  
See `--genome1` above for more details.

```bash
--genome3 'Sscrofa10.2'
```

### `--endo3`

Proportion of Endogenous DNA in organism 3 target microbiome. Must be between 0 and 1. Default = 0.01

```bash
--endo3 0.01
```

### `--index1`

Path to Bowtie2 pre-indexed genome candidate 1 Coprolite maker's genome

```bash
--index1 'path/to/bt_index/basename1'
```

### `--index2`

Path to Bowtie2 pre-indexed genome candidate 2 Coprolite maker's genome

```bash
--index2 'path/to/bt_index/basename2'
```

### `--index3`

Path to Bowtie2 pre-indexed genome candidate 3 Coprolite maker's genome

```bash
--index3 'path/to/bt_index/basename3'
```

## Job resources

### Automatic resubmission

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

### Custom resource requests

Wherever process-specific requirements are set in the pipeline, the default value can be changed by creating a custom config file. See the files hosted at [`nf-core/configs`](https://github.com/nf-core/configs/tree/master/conf) for examples.

If you are likely to be running `nf-core` pipelines regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter (see definition below). You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack).

## AWS Batch specific parameters

Running the pipeline on AWS Batch requires a couple of specific parameters to be set according to your AWS Batch configuration. Please use [`-profile awsbatch`](https://github.com/nf-core/configs/blob/master/conf/awsbatch.config) and then specify all of the following parameters.

### `--awsqueue`

The JobQueue that you intend to use on AWS Batch.

### `--awsregion`

The AWS region in which to run your job. Default is set to `eu-west-1` but can be adjusted to your needs.

### `--awscli`

The [AWS CLI](https://www.nextflow.io/docs/latest/awscloud.html#aws-cli-installation) path in your custom AMI. Default: `/home/ec2-user/miniconda/bin/aws`.

Please make sure to also set the `-w/--work-dir` and `--outdir` parameters to a S3 storage bucket of your choice - you'll get an error message notifying you if you didn't.

## Other command line parameters

### `--outdir`

The output directory where the results will be saved.

### `--email`

Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.

### `--email_on_fail`

This works exactly as with `--email`, except emails are only sent if the workflow is not successful.

### `--max_multiqc_email_size`

Threshold size for MultiQC report to be attached in notification email. If file generated by pipeline exceeds the threshold, it will not be attached (Default: 25MB).

### `-name`

Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

This is used in the MultiQC report (if not default) and in the summary HTML / e-mail (always).

**NB:** Single hyphen (core Nextflow option)

### `-resume`

Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

**NB:** Single hyphen (core Nextflow option)

### `-c`

Specify the path to a specific config file (this is a core NextFlow command).

**NB:** Single hyphen (core Nextflow option)

Note - you can use this to override pipeline defaults.

### `--custom_config_version`

Provide git commit id for custom Institutional configs hosted at `nf-core/configs`. This was implemented for reproducibility purposes. Default: `master`.

```bash
## Download and use config file with following git commid id
--custom_config_version d52db660777c4bf36546ddb188ec530c3ada1b96
```

### `--custom_config_base`

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

### `--max_memory`

Use to set a top-limit for the default memory requirement for each process.
Should be a string in the format integer-unit. eg. `--max_memory '8.GB'`

### `--max_time`

Use to set a top-limit for the default time requirement for each process.
Should be a string in the format integer-unit. eg. `--max_time '2.h'`

### `--max_cpus`

Use to set a top-limit for the default CPU requirement for each process.
Should be a string in the format integer-unit. eg. `--max_cpus 1`

### `--plaintext_email`

Set to receive plain-text e-mails instead of HTML formatted.

### `--monochrome_logs`

Set to disable colourful command line output and live life in monochrome.

### `--multiqc_config`

Specify a path to a custom MultiQC configuration file.
