# Runnable Workflow Examples

These examples are host-side wrappers around the Compose services. Run them from
any directory; each script resolves the repository root, starts the matching
container, reads inputs from `data/inputs`, and writes outputs under
`data/outputs/examples`.

示例脚本在宿主机执行，通过 Docker Compose 进入对应容器。输入默认来自
`data/inputs`，输出默认写入 `data/outputs/examples`。

## Quick Validation / 快速验证

```bash
./scripts/smoke-test.sh all
```

## Examples / 示例

| Service / 服务 | Script / 脚本 | What it does / 作用 |
| --- | --- | --- |
| Foundry MPNN | `examples/foundry/run-mpnn-pdl1.sh` | Runs one ProteinMPNN batch on `data/inputs/PDL1.pdb`. |
| BindCraft | `examples/bindcraft/run-cd47-peptide.sh` | Runs the CD47 peptide binder example with a small tracked settings file. |
| AF2 Multimer | `examples/af2multimer/run-check-or-full.sh` | Checks JAX GPU by default; full AlphaFold run is gated by `RUN_FULL=1`. |
| Rosetta | `examples/rosetta/run-relax-pdl1.sh` | Runs one Rosetta relax trajectory on `data/inputs/PDL1.pdb`. |
| PepMimic | `examples/pepmimic/run-cd38-example.sh` | Runs PepMimic on its bundled CD38 example data and mounted checkpoint. |
| RFpeptide | `examples/rfpeptide/run-macrocycle-smoke.sh` | Runs a one-design RFdiffusion cyclic peptide example. |
| Confidence table | `examples/confidence/run-merge-srcr.sh` | Merges SRCR confidence JSON files into a ranked CSV. |

Some scientific runs are intentionally small but still GPU-heavy. Use the smoke
test first before starting full design jobs.

部分科学流程即使示例规模较小也会占用 GPU。建议先运行烟测，再启动完整设计任务。
