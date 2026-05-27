# CI/CD: GitHub Actions → ACR → Azure Container Apps

## Architecture

```text
GitHub (push main) → GitHub Actions → Build Docker image → Push to ACR → Update Container App
                                                              ↓
                                                    Azure MySQL (existing)
```

## Prerequisites (one-time in Azure)

1. **Resource group** (e.g. `rg-php-crud`)
2. **Azure Container Registry** (e.g. `myregistry.azurecr.io`)
3. **Container Apps Environment** (e.g. `my-container-env`)
4. **Container App** (e.g. `php-crud-app`) — deploy once with `container-app.bicep`
5. **Azure Database for MySQL** with database `crud` and user `user@server`

Enable ACR admin user (or use managed identity on the Container App):

```bash
az acr update --name myregistry --admin-enabled true
```

---

## Step 1: Create Azure MySQL + Container App (first deploy)

Edit `azure/container-app.parameters.json`, then:

```bash
az group create --name rg-php-crud --location eastus

az deployment group create \
  --resource-group rg-php-crud \
  --template-file azure/container-app.bicep \
  --parameters @azure/container-app.parameters.json
```

DB host, user, and password are injected from **GitHub Secrets** on every deploy (stored as Container App secrets). Allow Container App outbound IP on MySQL firewall.

---

## Step 2: GitHub OIDC federation (recommended)

### 2a. Create App Registration + Service Principal

```bash
az ad app create --display-name "github-php-crud-cicd"
# Note the appId (client ID)

az ad sp create --id <APP_ID>
# Note the object id of the SP

az role assignment create \
  --assignee <SP_OBJECT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-php-crud

az role assignment create \
  --assignee <SP_OBJECT_ID> \
  --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-php-crud/providers/Microsoft.ContainerRegistry/registries/myregistry
```

### 2b. Federated credential for GitHub

```bash
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<GITHUB_USER>/PHP-CRUD-app:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

Replace `<GITHUB_USER>/PHP-CRUD-app` with your repo (e.g. `ItsCosmas/PHP-CRUD-app`).

---

## Step 3: GitHub repository secrets

In **GitHub → Settings → Secrets and variables → Actions**, add:

| Secret | Example |
|--------|---------|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription GUID |
| `AZURE_RESOURCE_GROUP` | `rg-php-crud` |
| `ACR_NAME` | `myregistry` (name only, no `.azurecr.io`) |
| `ACR_LOGIN_SERVER` | `myregistry.azurecr.io` |
| `ACR_USERNAME` | ACR admin username |
| `ACR_PASSWORD` | ACR admin password |
| `CONTAINER_APP_NAME` | `php-crud-app` |
| `DB_HOST` | `crud-sql-server.mysql.database.azure.com` |
| `DB_USER` | `cruduser@crud-sql-server` |
| `DB_PASSWORD` | MySQL password |

Each deploy updates Container App secrets `db-host`, `db-user`, `db-password` and wires env vars via `secretref`.

---

## Step 4: Push to trigger CI/CD

```bash
git add .
git commit -m "Add Azure CI/CD workflow"
git push origin main
```

GitHub Actions will:

1. Build the Docker image
2. Push to ACR (`:latest` and `:<commit-sha>`)
3. Update the Container App to the new image

Monitor: **GitHub → Actions** tab.

---

## Manual deploy (without GitHub)

```bash
az acr login --name myregistry
docker build -t myregistry.azurecr.io/php-crud-app:latest .
docker push myregistry.azurecr.io/php-crud-app:latest

az containerapp update \
  --name php-crud-app \
  --resource-group rg-php-crud \
  --image myregistry.azurecr.io/php-crud-app:latest
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| ACR push denied | Add `AcrPush` role to the SP |
| Container App won't start | Check logs: `az containerapp logs show -n php-crud-app -g rg-php-crud` |
| DB connection error | Verify `DB_HOST`, `DB_USER@server`, firewall, `DB_SSL=true` |
| Health probe fails | Ensure `PORT=80` and `/health` returns `ok` |
| Build fails on `.env` | `.env` is not copied in Docker build; use Container App env vars |

---

## Local `.env` (VM / dev only)

```bash
cp .env.example .env
# edit values, then:
docker build -t php-crud-app .
docker run -d -p 80:80 --env-file .env php-crud-app
```
