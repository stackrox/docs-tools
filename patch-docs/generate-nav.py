#!/usr/bin/env python3
"""
This scripts reads the `_topic_map.yml` file of OpenShift docs
(https://github.com/openshift/openshift-docs/blob/rhacs-docs/_topic_map.yml), and translates it
to Antora's format, creating nav.adoc files in the respective module directories, along with an
antora.yml file in the docs root directory.
"""

import yaml
import sys

records = yaml.safe_load_all(sys.stdin.read())

root_config = {
    'name': 'rhacs',
    'title': 'Red Hat Advanced Cluster Security for Kubernetes',
    'version': 'latest',
    'nav': []
}


def print_topic_nav(topics, f, prefix=""):
    for t in topics:
        if 'Topics' in t:
            f.write(f"{prefix}* {t['Name']}\n")
            print_topic_nav(t['Topics'], f=f, prefix=prefix + "*")
        else:
            f.write(f"{prefix}* xref:{t['File']}.adoc[{t['Name']}]\n")


for record in records:
    dir = record['Dir']
    if dir == 'welcome':
        dir = 'ROOT'
    nav_path=f'modules/{dir}/nav.adoc'
    root_config['nav'].append(nav_path)
    with open(f'docs/{nav_path}', 'w') as f:
        if dir == 'ROOT':
            print_topic_nav(record['Topics'], f=f)
        else:
            f.write(f"* {record['Name']}\n")
            print_topic_nav(record['Topics'], f=f, prefix="*")

# Write the antora.yml config file.
with open('docs/antora.yml', 'w') as f:
    yaml.safe_dump(root_config, stream=f)
