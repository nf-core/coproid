#!/usr/bin/env python
from __future__ import print_function
from collections import OrderedDict
import re

regexes = {
    'nf-core/coproid': ['v_pipeline.txt', r"(\S+)"],
    'Nextflow': ['v_nextflow.txt', r"(\S+)"],
    'AdapterRemoval': ['v_adapterremoval.txt', r"AdapterRemoval ver\. (\S+)"],
    'Bedtools': ['v_bedtools.txt', r"bedtools\sv(\S+)"],
    'Bowtie2': ['v_bowtie2.txt', r"bowtie2-align-s\sversion\s(\S+)"],
    'FastQC': ['v_fastqc.txt', r"FastQC v(\S+)"],
    'Kraken2': ['v_kraken2.txt', r"Kraken\sversion\s(\S+)"],
    'MultiQC': ['v_multiqc.txt', r"multiqc, version (\S+)"],
    'Sourcepredict': ['v_sourcepredict.txt', r"SourcePredict\sv(\d*\.\d*)"],
    'Samtools': ['v_samtools.txt', r"samtools\s(\S+)"],
    'Python': ['v_python.txt', r'Python\s(\S+)']
}
results = OrderedDict()
results['nf-core/coproid'] = '<span style="color:#999999;\">N/A</span>'
results['Nextflow'] = '<span style="color:#999999;\">N/A</span>'
results['AdapterRemoval'] = '<span style="color:#999999;\">N/A</span>'
results['Bedtools'] = '<span style="color:#999999;\">N/A</span>'
results['Bowtie2'] = '<span style="color:#999999;\">N/A</span>'
results['FastQC'] = '<span style="color:#999999;\">N/A</span>'
results['Kraken2'] = '<span style="color:#999999;\">N/A</span>'
results['MultiQC'] = '<span style="color:#999999;\">N/A</span>'
results['Samtools'] = '<span style="color:#999999;\">N/A</span>'
results['Sourcepredict'] = '<span style="color:#999999;\">N/A</span>'

# Search each file using its regex
for k, v in regexes.items():
    try:
        with open(v[0]) as x:
            versions = x.read()
            match = re.search(v[1], versions)
            if match:
                results[k] = "v{}".format(match.group(1))
    except IOError:
        results[k] = False

# Remove software set to false in results
for k in list(results):
    if not results[k]:
        del(results[k])

# Dump to YAML
print('''
id: 'software_versions'
section_name: 'nf-core/coproid Software Versions'
section_href: 'https://github.com/nf-core/coproid'
plot_type: 'html'
description: 'are collected at run time from the software output.'
data: |
    <dl class="dl-horizontal">
''')
for k, v in results.items():
    print("        <dt>{}</dt><dd><samp>{}</samp></dd>".format(k, v))
print("    </dl>")

# Write out regexes as csv file:
with open('software_versions.csv', 'w') as f:
    for k, v in results.items():
        f.write("{}\t{}\n".format(k, v))
