### FILE BASED CATALOG FOR RED HAT CONNECTIVITY LINK COMPONENT OPERATORS
#### RHCL Operator, Authorino Operator, DNS Operator & Limitador Operator

How these catalogs were initially generated: 
Using the IIB provided index images that are created as part of the `OLM_CATALOG_INITALIZATION_BUNDLE_IMAGE` CVP Test

Copy the IIB base images for each OCP Version for each operator from their most recent CVP test logs.

Run the following command to generate a file based catalog for all operators in a given OCP Version \
```opm migrate --migrate-level="bundle-object-to-csv-metadata" $IIB_IMAGE_PULLSPEC catalogs-$OCP_VERSION -o yaml```

Copy the `catalog.yaml` file from the folder corresponding to the operator package you want, and commit it to your file based catalog repository.
