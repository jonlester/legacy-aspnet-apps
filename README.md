# Legacy ASP.NET Apps

This repo will deploy an Azure VM (Windows Server 2008R2 + SQL) with several ASP.NET applications which were taken from older samples.  You can use these apps to test migration or modernization tools.

## Steps

Open Azure [Cloud Shell](https://portal.azure.com/#cloudshell/) and run the following commands.

Clone the Repository

```bash
git clone https://github.com/jonlester/legacy-aspnet-apps.git
cd legacy-aspnet-apps
```

Deploy the bicep template (provide your own password)

```bash
az deployment sub create \
    --name "LegacyApps" \
    --location "centralus" \
    --template-file ./main.bicep \
    --parameters vmAdminPassword={ password }
```

After the VM is created and the apps are configured, it will reboot.  Once it is started again, it is ready to use.

## Troubleshooting

You can reference the [steps to manually configure the apps](./docs/apps-manual-configuration.md) if necessary.  These instructions were taken from an old hands-on lab and implemented in the vm [initialization script](./scripts/post-config-win2k8r2-sql.ps1), but the doc may be useful if errors occur.

## Source Apps

All the zip files and database backups for the apps can be found as artifacts in [this release](https://github.com/jonlester/legacy-aspnet-apps/releases/tag/dummy-release), which exists purely for their storage.
