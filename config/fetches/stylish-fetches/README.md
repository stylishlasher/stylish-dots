# stylish-fetches (Rust)

Rust rewrite of the old unstable C fetches. These are manual-run 3D terminal toys, not auto-started on shell init.

## Binaries

- `keyfetch` - 3D key
- `treefetch` - 3D Christmas tree air freshener
- `tomatofetch` - 3D tomato
- `stoolfetch` - 3D stool
- `skeletonfetch` - 3D skeleton key

## Build

```bash
cargo build --release
```

## Usage

```bash
keyfetch --rotate horizontal
keyfetch --rotate vertical
keyfetch --rotate random
treefetch --rotate random --accent green
```

Options include `--color`, `--accent` (where supported), `--label-color`, `--rainbow`, `--speed`, `--size`, `--height`, `--rotate`, `--frames`, `--no-info`, `--no-color`.
