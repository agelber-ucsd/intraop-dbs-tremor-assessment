# Creating the GitHub repository

After unzipping this folder locally:

```bash
cd dbs-tremor-spiral
git init
git add .
git commit -m "Initial DBS tremor spiral prototype"
```

Then create a new empty repository on GitHub and add the remote GitHub prints for you, usually:

```bash
git remote add origin https://github.com/<your-username>/<repo-name>.git
git branch -M main
git push -u origin main
```

Suggested repository names:

- `dbs-tremor-spiral`
- `intraop-dbs-tremor-assessment`
- `dbs-tremor-assessment-ipad`

Do not commit provisioning profiles, certificates, exported patient data, or protected health information.
