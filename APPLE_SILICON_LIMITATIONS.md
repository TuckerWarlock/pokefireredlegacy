# pokefireredlegacy on Apple Silicon - Architecture Limitation

## The Problem

The pokefireredlegacy project includes **pre-compiled x86-64 Linux tools only** (specifically `poryscript`). This creates a compatibility issue on Apple Silicon:

```
Your M4 Mac (arm64)
        ↓
Apple container runtime (native arm64)
        ↓
aarch64/arm64 Linux container
        ↓
poryscript binary (x86-64 only) ❌ INCOMPATIBLE
```

## Why This Happens

- **poryscript** is a pre-compiled Go binary included in the repo
- It's compiled for x86-64 Linux architecture only
- No source code is provided to rebuild it for arm64
- The project appears to be Linux/x86-64 focused

## Your Options

### Option 1: Use the Official pokefirered Repository ⭐ Recommended

The official [pret/pokefirered](https://github.com/pret/pokefirered) may have better cross-platform support:

```bash
cd ~/Code
git clone https://github.com/pret/pokefirered.git
cd pokefirered
./container-build.sh firered modern
```

This is the most likely to work on Apple Silicon with containers.

---

### Option 2: Use a Linux x86-64 Container with Rosetta/QEMU

Apple container can emulate x86-64, but it's slower and requires additional setup:

```bash
# Requires QEMU or Rosetta support - check Apple container docs
container run --platform linux/amd64 ...
```

This would allow using the pre-built x86-64 tools, but:
- Significantly slower (cross-architecture emulation)
- Requires additional dependencies
- Not officially supported by Apple container

---

### Option 3: Use Docker Desktop on macOS

Docker Desktop has better x86-64 emulation via Rosetta:

```bash
# If you have Docker Desktop installed
./container-build.sh firered modern
```

The script auto-detects Docker if available. This may work better than Apple's native container runtime.

---

### Option 4: Use a Linux VM

Create a virtual Ubuntu x86-64 environment:

```bash
# Using UTM, VirtualBox, or Parallels
# Then clone the repo and run normally
```

Most reliable but requires more disk space.

---

### Option 5: Try to Rebuild Tools for arm64 (Advanced)

If poryscript source is available, rebuild it:

```bash
# Would need to find poryscript source code
# Then build inside the container
go build -o poryscript ./cmd/poryscript
```

This is complex and may not be feasible if source isn't available.

---

## What We Learned

The container build system we created is **working correctly**:
- ✅ Dockerfile builds successfully
- ✅ Container runs with correct dependencies
- ✅ Volume mounts work properly
- ✅ Architecture detection works

The limitation is **not with the build system** — it's a **project limitation** (pre-compiled x86-64 tools only).

## Next Steps

1. **Try the official pokefirered repo** — likely to work better on Apple Silicon
2. **If you must use pokefireredlegacy**, use Docker Desktop or a Linux VM
3. **Report the issue** to pokefireredlegacy maintainers if they claim ARM/Apple Silicon support

---

## For Reference

**Files created:**
- `container-build.sh` — Universal build wrapper (works with all container runtimes)
- `Dockerfile` — arm64 Ubuntu base image with dependencies
- `CONTAINER_BUILD.md` — Container build documentation

**Why arm64 Ubuntu base?**
- Apple container natively runs arm64/aarch64 — more efficient
- Dockerfile would fail with x86-64 base on native Apple container
- We correctly detected this and updated accordingly

The architecture check now properly diagnoses this issue rather than failing silently!
