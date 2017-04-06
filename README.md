# Cartgrapher:

network diagram generator for `terraform`

# Requirement

- ruby
- graphviz
- AWS Simple Icons

# Setup

```shell-session
bundle install

// get AWS icon set from https://aws.amazon.com/jp/architecture/icons/
wget https://media.amazonwebservices.com/AWS-Design/Arch-Center/17.1.19_Update/AWS_Simple_Icons_EPS-SVG_v17.1.19.zip
unzip AWS_Simple_Icons_EPS-SVG_v17.1.19.zip *.png -x __MACOSX/* */GRAYSCALE/*
mv AWS_Simple_Icons_EPS-SVG_v17.1.19 terraform/aws_icons
```

# Usage

```shell-session
terraform state pull > test.json
cartgrapher test.json
open Cartgrapher.png
```


# future (or never)

- treats `AWS Subnet` and `AWS Security Group` more well (nesting GraphViz Cluster)
- supports customization (of `terraform/aws.yml`)
- documentation

# License

This software is released under the MIT License, see LICENSE.txt.
