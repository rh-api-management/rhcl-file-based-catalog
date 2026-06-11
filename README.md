### FILE BASED CATALOG FOR RED HAT CONNECTIVITY LINK COMPONENT OPERATORS
#### RHCL Operator, Authorino Operator, DNS Operator & Limitador Operator

How these catalogs were initially generated: 
Using the IIB provided index images that are created as part of the `OLM_CATALOG_INITALIZATION_BUNDLE_IMAGE` CVP Test

Copy the IIB base images for each OCP Version for each operator from their most recent CVP test logs.

Run the following command to generate a file based catalog for all operators in a given OCP Version \
```opm migrate --migrate-level="bundle-object-to-csv-metadata" $IIB_IMAGE_PULLSPEC catalogs-$OCP_VERSION -o yaml```

Copy the `catalog.yaml` file from the folder corresponding to the operator package you want, and commit it to your file based catalog repository.

#### Adding new bundles with Claude Code

This repository includes a Claude Code skill (`/add-bundle`) that automates adding operator bundles to the catalog. It handles rendering the bundle with OPM, updating channel entries, and validating the result.

**Usage:**
```
/add-bundle <BUNDLE_IMAGE_PULLSPEC> <OCP_VERSIONS> <UPGRADE_PATH>
```

**Examples:**
```
/add-bundle registry.redhat.io/rhcl-1/rhcl-operator-bundle@sha256:abc123 4.19-4.22 replaces 1.3.4, if no previous no upgrade path
/add-bundle registry.redhat.io/rhcl-1/dns-operator-bundle@sha256:def456 4.19, 4.20, 4.21 replaces previous if exists
```

The skill will:
1. Render the bundle image with `opm render --migrate-level=bundle-object-to-csv-metadata -o yaml`
2. Detect existing catalog state for each target OCP version
3. Add channel entries with the specified upgrade path (`replaces`/`skips`)
4. For new OCP versions without the operator, create a minimal catalog (exception: `authorino-operator` carries the full catalog history due to support arrangements)
5. Validate all modified catalogs with `opm validate`
