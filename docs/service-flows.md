# Protein Design Service Flows

This document maps each local Docker image to its build inputs, mounted runtime
assets, and expected output locations. Large model, license, database, and
workflow output files stay under `data/` and are not tracked by Git.

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
