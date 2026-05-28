# Protein Design Service Flows

This document maps each local Docker image to its build inputs, mounted runtime
assets, and expected output locations. Large model, license, database, and
workflow output files stay under `data/` and are not tracked by Git.

For a reader-facing graphical summary, see the project-level visual abstract:

![Nature Methods-style protein design workflow graphical abstract](assets/nature-methods-workflow-graphical-abstract.png)

The figure compresses the same operational structure described below into five
information states: inputs, design, validation, refinement, and ranked outputs.
The Mermaid diagrams in this document remain the exact source of path-level
details for each image.

## Foundry / RFD3 / MPNN

```mermaid
flowchart LR
    dockerfile["images/pd-foundry-gpu/Dockerfile"]
    image["pd-foundry-gpu:latest"]
    inputs["data/inputs"]
    checkpoints["data/foundry_checkpoints"]
    scripts["scripts"]
    shell["Compose profiles: foundry, design, rfd3, mpnn"]
    outputs["data/outputs"]

    dockerfile --> image
    image --> shell
    inputs --> shell
    checkpoints --> shell
    scripts --> shell
    shell --> outputs
```

## BindCraft

```mermaid
flowchart LR
    image["pd-bindcraft-gpu:installed"]
    models["data/bindcraft_models"]
    licenses["data/licenses"]
    inputs["data/inputs"]
    scripts["scripts"]
    shell["Compose profile: bindcraft"]
    outputs["data/outputs"]

    image --> shell
    models --> shell
    licenses --> shell
    inputs --> shell
    scripts --> shell
    shell --> outputs
```

## AlphaFold Multimer

```mermaid
flowchart LR
    dockerfile["images/pd-af2multimer-gpu/Dockerfile"]
    image["pd-af2multimer-gpu:fixed"]
    db["data/alphafold_db"]
    inputs["data/inputs"]
    scripts["scripts"]
    shell["Compose profiles: af2, multimer"]
    outputs["data/outputs"]

    dockerfile --> image
    image --> shell
    db --> shell
    inputs --> shell
    scripts --> shell
    shell --> outputs
```

## AlphaFold 3

```mermaid
flowchart LR
    source["data/src/alphafold3<br/>official AlphaFold 3 v3.0.2 source"]
    wheel["data/src/alphafold3/wheelhouse<br/>local nvidia-cublas-cu12 wheel"]
    image["pd-af3-gpu:v3.0.2"]
    models["data/alphafold3/models<br/>af3.bin.zst"]
    db["data/alphafold3/public_databases"]
    cache["data/alphafold3/jax_cache"]
    inputs["data/inputs and examples/af3"]
    shell["Compose profiles: af3, validate"]
    outputs["data/outputs"]

    source --> image
    wheel --> image
    image --> shell
    models --> shell
    db --> shell
    cache --> shell
    inputs --> shell
    shell --> outputs
```

AlphaFold 3 is independent from AlphaFold 2 Multimer in this project. The
`pd-af3-gpu:v3.0.2` image is built from the official AlphaFold 3 source under
`data/src/alphafold3`; it does not use `pd-af2multimer-gpu`, the AlphaFold 2
Multimer Dockerfile, or `data/alphafold_db`.

本项目中 AlphaFold 3 与 AlphaFold 2 Multimer 相互独立。`pd-af3-gpu:v3.0.2`
镜像来自 `data/src/alphafold3` 下的官方 AlphaFold 3 源码，不使用
`pd-af2multimer-gpu`、AlphaFold 2 Multimer Dockerfile 或 `data/alphafold_db`。

## Rosetta CPU Parallel

```mermaid
flowchart LR
    dockerfile["images/pd-rosetta-cpu-parallel/Dockerfile"]
    source["local rosetta_src build context"]
    image["pd-rosetta-cpu-parallel:latest"]
    db["data/rosetta_db"]
    licenses["data/licenses"]
    inputs["data/inputs"]
    scripts["scripts"]
    shell["Compose profiles: rosetta, post, rosetta-parallel"]
    outputs["data/outputs"]

    source --> dockerfile
    dockerfile --> image
    image --> shell
    db --> shell
    licenses --> shell
    inputs --> shell
    scripts --> shell
    shell --> outputs
```

## PepMimic

```mermaid
flowchart LR
    dockerfile["images/pd-pepmimic-gpu/Dockerfile"]
    image["pd-pepmimic-gpu:latest"]
    checkpoints["data/pepmimic_checkpoints"]
    licenses["data/licenses"]
    inputs["data/inputs"]
    scripts["scripts"]
    shell["Compose profile: pepmimic"]
    outputs["data/outputs"]

    dockerfile --> image
    image --> shell
    checkpoints --> shell
    licenses --> shell
    inputs --> shell
    scripts --> shell
    shell --> outputs
```

## RFpeptide / RFdiffusion Macrocycles

```mermaid
flowchart LR
    dockerfile["images/pd-rfpeptide-gpu/Dockerfile"]
    image["pd-rfpeptide-gpu:fixed"]
    models["data/rfpeptide_models"]
    inputs["data/inputs"]
    scripts["scripts"]
    shell["Compose profiles: rfpeptide, macrocycle"]
    outputs["data/outputs"]

    dockerfile --> image
    image --> shell
    models --> shell
    inputs --> shell
    scripts --> shell
    shell --> outputs
```

## Standalone Rosetta CPU Base

```mermaid
flowchart LR
    dockerfile["images/pd-rosetta-cpu/Dockerfile"]
    image["manual Rosetta CPU utility image"]
    scripts["optional mounted scripts"]
    workspace["/workspace"]

    dockerfile --> image
    image --> workspace
    scripts --> workspace
```
