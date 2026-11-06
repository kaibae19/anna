# checks — what Anna verifies

Every executable here is an `anna-checks` section named after the file. Read-only. Print one line per finding starting with
`OK `, `⚠ ` or `⛔ ` (⛔ = needs the user today: the morning run notifies on it), exit 0, finish within 60 s. A check that
fails to run is reported as ⚠ (unverified), never OK. Examples: the scaffold's `examples/checks/`.
Headless runs and the bot are allowed `anna-checks`, not the commands inside: when one is missing, add a check here.
