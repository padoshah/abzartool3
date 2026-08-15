# AbzarFile CI runner fix

- `AbzarFile-v1.0.0-source.zip`: complete source tree with the CI fixes.
- `CI-RUNNER-FIX.patch`: apply to the current `main` checkout with:

  `git am CI-RUNNER-FIX.patch`

The patch removes the ffigen byte-diff failure and pins Windows CI/release to `windows-2022`, which Flutter 3.29 recognizes.

ZIP SHA-256: `9698a6b53925491ca80ceebaa1bb93051d0ed0feeeb7ad3099e391a9eb686e7e`
