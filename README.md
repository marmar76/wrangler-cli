# Deploy with the Wrangler CLI container

Use this guide to deploy a Cloudflare Pages site or Worker with the prebuilt Docker Hub image. You do not need to build the image. The examples use `marmar76/wrangler-cli:latest`.

## What you need

- Docker installed on your computer or CI worker.
- Your site build output or Worker source and Wrangler configuration in a directory.
- A Cloudflare API token with only the permissions needed for the deployment.
- For Pages, your Pages project name.

## Deploy a Pages site

Build your site using your normal build process first. Then replace `./dist` with the output directory and `YOUR_PAGES_PROJECT` with the project name from Cloudflare:

```sh
docker run --rm \
  -e CLOUDFLARE_API_TOKEN \
  -v "$PWD:/app" -w /app \
  marmar76/wrangler-cli:latest \
  pages deploy ./dist --project-name YOUR_PAGES_PROJECT
```

Set `CLOUDFLARE_API_TOKEN` in your shell before running the command. Do not put the token directly in the command or commit it to source control. In CI, save it in the CI system's secret store and pass it into the container as an environment variable.

## Deploy from Jenkins

Start with the [Jenkinsfile example](https://github.com/marmar76/wrangler-cli/blob/main/Jenkinsfile.example). It builds an application and then deploys its output with Wrangler in the prebuilt container. Adjust the `environment` values and build command for your project:

- `WRANGLER_IMAGE`: Docker Hub image and tag. The sample uses `marmar76/wrangler-cli:latest`.
- `CLOUDFLARE_PAGES_PROJECT`: Pages project name.
- `CLOUDFLARE_TOKEN_CREDENTIAL`: Jenkins ID of a **Secret text** credential containing the API token.
- `BUILD_IMAGE`, `BUILD_OUTPUT_DIR`, and the build command: change these to match your app's build tools and output directory.

The sample uses `agent any`, so it does not require a particular Jenkins node label. The token is bound only for the deployment step. Restrict the token to the minimum Cloudflare permissions required.

## Deploy a Worker

Mount the directory containing your Worker source and Wrangler configuration, and use Wrangler's `deploy` command instead of the Pages deployment command. For example:

```sh
docker run --rm \
  -e CLOUDFLARE_API_TOKEN \
  -v "$PWD:/app" -w /app \
  marmar76/wrangler-cli:latest \
  deploy
```

Check your Wrangler configuration and Cloudflare account settings before deployment, and add any flags your project needs.

## Image notes

- The image's default command is `wrangler --help`; passing the arguments shown above runs a Wrangler command instead.
- The container runs Wrangler from `/app`. Mount your project there so Wrangler can read its configuration and files.
- This image is trimmed for CLI and deployment use. Its `workerd` executables are replaced with stubs, so local development commands such as `wrangler dev` that require `workerd` are not supported.
- The image installs `wrangler@latest` when built. For production CI, consider pinning an available image tag or digest.

## More information

- [Cloudflare Wrangler documentation](https://developers.cloudflare.com/workers/wrangler/)
- [Repository source and maintainer guide](https://github.com/marmar76/wrangler-cli), including the Dockerfile, build workflow, and [`README_MAKER.md`](https://github.com/marmar76/wrangler-cli/blob/main/README_MAKER.md).
