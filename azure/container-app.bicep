@description('Azure region')
param location string = resourceGroup().location

@description('Container Apps environment name')
param environmentName string

@description('Container app name')
param containerAppName string

@description('Container image from ACR or Docker Hub')
param containerImage string

@description('Must match container PORT env (default 80)')
param targetPort int = 80

@description('Azure Database for MySQL hostname')
param dbHost string

@description('Database name')
param dbName string = 'crud'

@description('Database user (Azure MySQL: user@servername)')
param dbUser string

@secure()
@description('Database password')
param dbPassword string

param registryServer string = ''
param registryUsername string = ''
@secure()
param registryPassword string = ''

resource environment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: environmentName
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
      }
      registries: !empty(registryServer) ? [
        {
          server: registryServer
          username: registryUsername
          passwordSecretRef: 'registry-password'
        }
      ] : []
      secrets: concat(
        [
          {
            name: 'db-host'
            value: dbHost
          }
          {
            name: 'db-user'
            value: dbUser
          }
          {
            name: 'db-password'
            value: dbPassword
          }
        ],
        !empty(registryServer) ? [
          {
            name: 'registry-password'
            value: registryPassword
          }
        ] : []
      )
    }
    template: {
      containers: [
        {
          name: 'php-crud'
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'PORT'
              value: string(targetPort)
            }
            {
              name: 'WEB_BIND'
              value: '0.0.0.0'
            }
            {
              name: 'DB_HOST'
              secretRef: 'db-host'
            }
            {
              name: 'DB_PORT'
              value: '3306'
            }
            {
              name: 'DB_NAME'
              value: dbName
            }
            {
              name: 'DB_USER'
              secretRef: 'db-user'
            }
            {
              name: 'DB_PASSWORD'
              secretRef: 'db-password'
            }
            {
              name: 'DB_SSL'
              value: 'true'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: targetPort
              }
              initialDelaySeconds: 10
              periodSeconds: 10
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health'
                port: targetPort
              }
              initialDelaySeconds: 5
              periodSeconds: 5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
