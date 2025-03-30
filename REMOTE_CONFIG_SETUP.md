# Remote Config Setup

This document explains how to set up Firebase Remote Config for local development of the DesiDine app.

## Important Files

- `remoteconfig.template.json`: This is the template file that is committed to the repository. It contains placeholders for sensitive information like API keys.
- `remoteconfig.template.dev.json`: This is your local development file that should contain your actual API keys. This file is ignored by Git to prevent exposing sensitive information.

## Setting Up for Development

1. Copy your API keys to `remoteconfig.template.dev.json`:
   - Open `remoteconfig.template.dev.json`
   - Replace `INSERT_YOUR_ACTUAL_OPENAI_API_KEY_HERE` with your actual OpenAI API key
   - Add any other API keys you want to use for development

2. When deploying Remote Config for local development, use:
   ```bash
   cp remoteconfig.template.dev.json remoteconfig.template.json
   firebase deploy --only remoteconfig
   ```

3. Before committing to Git, make sure to restore the placeholders:
   ```bash
   git checkout -- remoteconfig.template.json
   ```

## Security Considerations

- Never commit your actual API keys to the repository
- Always use placeholders in `remoteconfig.template.json`
- Keep your `remoteconfig.template.dev.json` file secure and do not share it

## Deploying to Production

For production deployments, use a CI/CD pipeline or a secure environment to deploy Remote Config with actual API keys. 