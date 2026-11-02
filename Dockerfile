FROM oven/bun:alpine AS builder

RUN bun add -g wrangler@latest

# Remove heavy binaries only needed for local dev (wrangler dev) and unused optional deps
# Keep package structure intact but replace workerd binaries with stubs
RUN rm -rf /root/.bun/install/global/node_modules/@img \
           /root/.bun/install/global/node_modules/sharp \
    && find /root/.bun/install/global/node_modules/@cloudflare/workerd-*/bin -type f -exec sh -c 'echo "#!/bin/sh" > "$1" && chmod +x "$1"' _ {} \; \
    && find /root/.bun/install/global/node_modules/workerd/bin -type f -exec sh -c 'echo "#!/bin/sh" > "$1" && chmod +x "$1"' _ {} \;

FROM oven/bun:alpine

# Copy the trimmed wrangler install from builder
COPY --from=builder /root/.bun/install/global /root/.bun/install/global

# Create a symlink for the wrangler binary
RUN ln -s /root/.bun/install/global/node_modules/wrangler/bin/wrangler.js /usr/local/bin/wrangler \
    && chmod +x /usr/local/bin/wrangler

# Make the global install accessible to any user
RUN chmod 755 /root

# Create a world-writable working directory so any UID can use it
RUN mkdir -p /app && chmod 777 /app
WORKDIR /app

# Ensure wrangler can write config/logs for any user
ENV XDG_CONFIG_HOME=/tmp/.config

CMD ["wrangler", "--help"]
