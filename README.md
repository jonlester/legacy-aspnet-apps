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
