# Repository guidance for contributors and coding agents

## Purpose

This repository builds and publishes a Docker image containing Cloudflare Wrangler CLI. Keep its documentation and examples generic so users can adapt them to their own projects and CI systems.

## Files and behavior

- `Dockerfile` installs the latest Wrangler release in a Bun Alpine image, removes optional image dependencies, and replaces `workerd` binaries with stubs to trim local development components. Do not claim that `wrangler dev` is supported by this trimmed image.
- `build.sh` and `.github/workflows/publish-image.yml` build Docker images for `linux/amd64` and `linux/arm64` and push `marmar76/wrangler-cli:latest`. Treat both as external publish actions. Do not run or dispatch them unless publishing is explicitly requested and authorized. The GitHub workflow uses repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`.
- `Jenkinsfile.example` is illustrative only. Keep it broadly reusable and do not include real credentials, private URLs, or organization-specific notifications. A configurable placeholder Pages project name and the published `marmar76/wrangler-cli:latest` image are intentional example values. Use Jenkins credentials binding for secrets.
- Keep the GitHub Actions build dependency-refreshing: it installs `wrangler@latest` and publishes the multi-platform image on its scheduled, manual, and selected source-change triggers.

## Change practices

- Read the relevant Dockerfile, script, and documentation before changing behavior. Preserve unrelated user changes.
- Prefer small, focused edits and explain runtime or compatibility consequences in `README.md`.
- Do not commit credentials, API tokens, webhook URLs, or generated deployment artifacts.
- Avoid claiming multi-platform builds pass based only on a build on one architecture. Verify each supported platform on a suitable Buildx builder when possible.
- Keep examples adaptable: use placeholders for project names, paths, and credential IDs when those values depend on the user's setup. Use the repository's published Docker Hub image in the Jenkins example.

## Verification

For documentation/example-only changes, check Markdown links and inspect the rendered text for project-specific leftovers or secrets. For Docker changes, run a local build and test `wrangler --version` and `wrangler --help` where the host architecture permits. Validate shell scripts with `bash -n`. Never push an image as part of verification unless explicitly requested.
