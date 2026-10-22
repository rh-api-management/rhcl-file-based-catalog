# The base image is expected to contain
# /bin/opm (with serve subcommand) and /bin/grpc_health_probe
FROM registry.redhat.io/openshift5/ose-operator-registry-rhel9:v5.0

# Copy FBC root into image at /configs and pre-populate serve cache
ADD catalog/5.0 /configs
RUN ["/bin/opm", "serve", "/configs", "--cache-dir=/tmp/cache", "--cache-only"]

# Set FBC-specific label for the location of the FBC root directory
# in the image
LABEL operators.operatorframework.io.index.configs.v1=/configs

# Configure the entrypoint and command
ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs", "--cache-dir=/tmp/cache"]
