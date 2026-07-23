# Add Bundle to File-Based Catalog

Add a new operator bundle to the file-based catalog by rendering it with OPM and inserting it into the correct catalog files with the specified upgrade path.

## Inputs

You need to collect the following from the user. If any were provided as arguments (`$ARGUMENTS`), use those and skip the corresponding question.

1. **Bundle image pullspec** — the full image reference (e.g. `registry.redhat.io/rhcl-1/rhcl-operator-bundle@sha256:...`)
2. **Target OCP versions** — which OCP version catalogs to add the bundle to (multi-select from the available versions under `catalog/`)
3. **Upgrade path** — which existing bundle version this new version `replaces`, and optionally which versions it `skips`

## Procedure

### Step 1: Get the bundle image

If not provided in `$ARGUMENTS`, ask the user for the bundle image pullspec.

### Step 2: Render the bundle with OPM

Run:
```
opm render <BUNDLE_IMAGE> --migrate-level=bundle-object-to-csv-metadata -o yaml
```

This produces the `olm.bundle` schema entry for the new bundle. Save the full output — it will be appended to the catalog file(s).

If the render fails, report the error and stop.

### Step 3: Extract metadata from the rendered content

From the rendered YAML output, extract:
- The **package name** (the `package:` field)
- The **bundle name** (the `name:` field, e.g. `rhcl-operator.v1.4.0`)
- The **version** (from the `olm.package` property value's `version` field)

### Step 4: Ask for target OCP versions

List the available OCP versions by checking which directories exist under `catalog/` (excluding `render/`, `output/`, and `*.Containerfile`).

For each OCP version, check whether the operator (by package name) already has a directory. Present this information to the user so they know which versions already carry the operator vs which would be new additions.

Use `AskUserQuestion` with `multiSelect: true` to let the user pick which OCP versions to target.

### Step 5: Ask for the upgrade path

For each selected OCP version, read the existing `catalog.yaml` for that operator (if it exists) and find the current channel entries. Show the user the existing entries in the `stable` (or default) channel.

Use `AskUserQuestion` to ask:
- Which existing version does this new bundle **replace**? (The `replaces` field — typically the latest version in the channel)
- Which versions (if any) should this new bundle **skip**? (The `skips` field — optional, comma-separated)

If all selected OCP versions have the same channel state, ask once. If they differ, ask per-version or per-group.

### Step 6: Update the catalog files

For each selected OCP version:

1. **If the operator directory does not exist**: create `catalog/<VERSION>/<OPERATOR>/catalog.yaml` with:
   - **Special case — `authorino-operator`**: Due to support arrangements, `authorino-operator` must carry the **full catalog history** (all channels, all bundles) in every OCP version. Copy the entire `catalog.yaml` from the nearest existing OCP version, then add the new channel entry and append the rendered bundle on top of that copy. Do NOT create a minimal catalog for authorino-operator.
   - **All other operators**: Create a minimal `catalog.yaml` with:
     - The `olm.package` entry (copy the icon and package name from an existing OCP version's catalog for this operator if available, otherwise derive from the rendered bundle)
     - The `olm.channel` entry with the new bundle as the sole entry
     - The rendered `olm.bundle` entry (from step 2), prefixed with `---`

2. **If the operator directory already exists**: edit the existing `catalog/<VERSION>/<OPERATOR>/catalog.yaml`:
   - **Add a new channel entry**: In the `olm.channel` document's `entries:` list, add a new entry with:
     - `name: <bundle-name>`
     - `replaces: <replaces-value>` (from step 5)
     - `skips:` list (from step 5, if any)
   - **Append the rendered bundle**: 
     - **CRITICAL**: Check if the file already ends with `---` on its own line
     - If it does NOT end with `---`, add `---` on a new line
     - If it DOES end with `---`, do NOT add another `---` (to prevent duplicate separators)
     - Then append the full rendered `olm.bundle` content

### Step 7: Validate

After all files are updated, run `opm validate catalog/<VERSION>` for each modified OCP version to verify the catalog is valid.

Report any validation errors. If validation passes, summarize what was done.

## Important notes

- Each document in `catalog.yaml` is separated by `---` on its own line
- **NEVER create consecutive `---` separators** — always check the end of the file before adding a separator
- The `olm.channel` entry uses the channel name from the existing catalog (usually `stable` or `preview`), not a hardcoded value
- The rendered bundle output from `opm render` is the complete `olm.bundle` document — use it as-is, do not modify its contents
- When adding to the channel entries list, maintain the existing order (oldest first) and add the new entry at the end
- The `replaces` field must reference an existing bundle name in the channel (e.g. `rhcl-operator.v1.3.4`), using the full `<package>.<version>` format
