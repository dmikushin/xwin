# Use the official Rust image
FROM docker.io/library/rust:1.82.0-slim-bookworm

# Set environment variables
ENV NAME="xwin"
ENV TARGETS="x86_64-unknown-linux-musl"
#ENV TARGETS="x86_64-unknown-linux-musl aarch64-unknown-linux-musl"
ENV STRIP="llvm-strip"

RUN rustup target add x86_64-unknown-linux-musl
#RUN rustup target add aarch64-unknown-linux-musl

# Install necessary tools
RUN apt-get update && \
    apt-get install -y musl-tools llvm git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the source code into the container
COPY . /usr/src/xwin
WORKDIR /usr/src/xwin

# Fetch dependencies
RUN cargo fetch

# Build and package for each target
RUN set -e && \
    TAG=$(git describe --tags --abbrev=0) && \
    for TARGET in $TARGETS; do \
      echo "Building for target: $TARGET"; \
      cargo build --release --target "$TARGET"; \
      RELEASE_NAME="$NAME-$TAG-$TARGET"; \
      RELEASE_TAR="${RELEASE_NAME}.tar.gz"; \
      mkdir "$RELEASE_NAME"; \
      if [ -n "$STRIP" ]; then \
        $STRIP "target/$TARGET/release/$NAME"; \
      fi; \
      cp "target/$TARGET/release/$NAME" "$RELEASE_NAME/"; \
      cp README.md LICENSE-APACHE LICENSE-MIT "$RELEASE_NAME/"; \
      tar czvf "$RELEASE_TAR" "$RELEASE_NAME"; \
      rm -r "$RELEASE_NAME"; \
      echo -n "$(shasum -ba 256 "$RELEASE_TAR" | cut -d " " -f 1)" > "${RELEASE_TAR}.sha256"; \
    done

# Final message
CMD echo "Release packages created successfully."

