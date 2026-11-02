# Developing and maintaining the Wrangler CLI image

This repository packages Cloudflare's Wrangler command-line tool in a Docker image so CI jobs and other users can run Wrangler without installing it on the host. For instructions on using the published image to deploy a Pages site or Worker, see [`README.md`](README.md).

## What the Dockerfile does and why

The image is designed to provide Wrangler's deployment and account-management CLI while omitting some large components used for local Worker development. The Dockerfile is a multi-stage build:

1. **Install Wrangler in a builder stage.** `oven/bun:alpine` supplies Bun and its package tooling. `bun add -g wrangler@latest` installs Wrangler globally. This keeps the setup compact and lets Wrangler's package manager resolve its dependencies.
2. **Trim dependencies used for local development or optional image processing.** The build removes `@img` and `sharp`, and replaces executables inside Wrangler's `workerd` packages with small shell stubs. These packages are not needed for the intended CLI/deploy usage. Replacing the binaries rather than deleting their package paths helps preserve the dependency structure expected by Wrangler. The tradeoff is that commands requiring the local Workers runtime, especially `wrangler dev`, will not work in this image.
3. **Copy the prepared installation into a clean runtime stage.** Only the Bun global package installation is copied from the builder. This avoids carrying builder-stage files into the final image. The runtime is also `oven/bun:alpine`, which includes the Bun/Node-compatible runtime needed by Wrangler's JavaScript CLI.
4. **Expose the Wrangler executable.** A symlink at `/usr/local/bin/wrangler` points to Wrangler's installed JavaScript entry point, making `wrangler` available as a normal command.
5. **Allow flexible container users and project mounts.** `/root` is made traversable so other UIDs can reach the global installation. `/app` is created with broad write permissions and set as the working directory, allowing CI to mount a project there even when the container runs under a non-root UID. Wrangler's config location is directed to `/tmp` with `XDG_CONFIG_HOME=/tmp/.config` so it does not need to write configuration under the image's root home directory.
6. **Show help by default.** `CMD ["wrangler", "--help"]` gives an informative result when the image is run without arguments. Docker arguments can override this command, for example `docker run --rm IMAGE pages deploy ./dist --project-name NAME`.

The broad permissions on `/app` are intentional for arbitrary-UID CI compatibility. Avoid placing secrets or unrelated host data in that directory. If changing the permission model, verify the image still works with the non-root identities used by deployment pipelines.

## Build and smoke-test locally

```sh
docker build -t wrangler-cli:local .
docker run --rm wrangler-cli:local --version
docker run --rm wrangler-cli:local --help
```

To verify arbitrary-UID access on a Linux host:

```sh
docker run --rm --user 10001:10001 wrangler-cli:local --version
```

## Publish

The checked-in [`build.sh`](build.sh) runs Docker Buildx for `linux/amd64` and `linux/arm64` and **pushes** `marmar76/wrangler-cli:latest` to Docker Hub. It is a publishing action, not a local test. Run it only when publishing is intended and registry access is configured. A suitable Buildx builder may need native workers or emulation for both architectures.

The GitHub Actions workflow at [`.github/workflows/publish-image.yml`](.github/workflows/publish-image.yml) also builds and publishes this multi-platform image. It runs weekly, when the Dockerfile or workflow changes on `main`, or when manually dispatched. It installs `wrangler@latest` during every build, so the scheduled run refreshes the image as upstream Wrangler releases change. Configure these repository Actions secrets before enabling publishing:

- `DOCKERHUB_USERNAME`: Docker Hub account username.
- `DOCKERHUB_TOKEN`: Docker Hub access token with permission to push to `marmar76/wrangler-cli`.

The workflow uses GitHub's cache for build layers to make repeated refreshes quicker. It publishes the `latest` tag only; to publish versioned tags or inspect a candidate build before publishing, extend the tag and release strategy deliberately.

The Dockerfile currently installs `wrangler@latest`, so independent builds can resolve different Wrangler versions over time. Pin the Wrangler version and base-image tags/digests if reproducible builds are required, and update the documentation and smoke tests alongside that change.

## Repository files

- [`Dockerfile`](Dockerfile): multi-stage image definition described above.
- [`build.sh`](build.sh): multi-platform build-and-push command.
- [`Jenkinsfile.example`](Jenkinsfile.example): generic Jenkins example that uses the prebuilt image.
- [`README.md`](README.md): end-user deployment guide.
- [`AGENTS.md`](AGENTS.md): contributor and coding-agent guidance.
