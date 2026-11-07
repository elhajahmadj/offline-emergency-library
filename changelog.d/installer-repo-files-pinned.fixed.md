- **Guides and helpers come from the same version as the installer.** An install run without a
  copy of the repo now downloads its guides, map viewer and helpers from the version that was
  current when it started, not one published hours later. These downloads retry a network
  blip, and a failed map viewer download is reported instead of saved as a broken page.
  Resolves #193. _[@EnragedAntelope](https://github.com/EnragedAntelope) - PR #206._
