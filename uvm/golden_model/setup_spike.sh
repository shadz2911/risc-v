#!/bin/bash
# One-command setup for the Spike golden model: init the submodule,
# apply the required debug-module patch (idempotent -- safe to re-run),
# and build. Run this instead of driving spike/configure/make by hand,
# especially after a fresh clone.
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "==> Initializing spike submodule"
git submodule update --init spike

cd spike

if grep -q "Patched out for this project" riscv/sim.cc; then
    echo "==> Debug-module patch already applied"
else
    echo "==> Applying debug-module patch"
    git apply "$REPO_ROOT/uvm/golden_model/patches/disable_debug_module.patch"
fi

mkdir -p build
cd build

if [ ! -f Makefile ]; then
    echo "==> Configuring spike"
    ../configure
fi

echo "==> Building spike (this can take a while the first time)"
make -j"$(nproc)"

echo "==> Done. Binary at spike/build/spike"
