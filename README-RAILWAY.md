# Railway.app Deployment Guide for Invoice Payment Details Module

This guide explains how to deploy the Odoo 16 Invoice Payment Details module on Railway.app.

## Prerequisites

- A Railway.app account ([Sign up here](https://railway.app))
- Git installed on your local machine
- This module's code in a Git repository

## Files Included for Deployment

The following files have been created for Railway deployment:

- `Dockerfile` - Container configuration for Odoo 16
- `railway.json` - Railway-specific deployment configuration
- `odoo.conf` - Odoo server configuration template
- `railway-entrypoint.sh` - Startup script with database initialization
- `.dockerignore` - Files to exclude from Docker build

## Deployment Steps

### 1. Create a New Railway Project

1. Go to [Railway.app](https://railway.app) and log in
2. Click **"New Project"**
3. Select **"Deploy from GitHub repo"**
4. Connect your GitHub account if not already connected
5. Select the repository containing this module

### 2. Add PostgreSQL Database

1. In your Railway project, click **"+ New"**
2. Select **"Database"** → **"PostgreSQL"**
3. Railway will automatically create a PostgreSQL database
4. Note: Railway will automatically set database connection variables

### 3. Configure Environment Variables

In your Railway project, go to **Variables** and add the following:

#### Required Variables:

```bash
# Database Configuration (auto-populated if using Railway PostgreSQL)
DB_HOST=${{Postgres.PGHOST}}
DB_PORT=${{Postgres.PGPORT}}
DB_USER=${{Postgres.PGUSER}}
DB_PASSWORD=${{Postgres.PGPASSWORD}}
DB_NAME=${{Postgres.PGDATABASE}}

# Odoo Admin Password (set a strong password!)
ADMIN_PASSWORD=your-super-secret-admin-password

# Module Initialization (set to "true" on first deployment only)
INIT_DB=true
```

#### Optional Variables:

```bash
# Update module on restart (useful for updates)
UPDATE_MODULE=false

# Port (Railway auto-assigns, but you can specify)
PORT=8069
```

### 4. Deploy

1. Railway will automatically deploy when you push to your repository
2. First deployment will take 5-10 minutes
3. Monitor the deployment logs in Railway dashboard
4. Once deployed, Railway will provide a public URL

### 5. Access Your Odoo Instance

1. Click on the generated Railway URL (e.g., `https://your-app.railway.app`)
2. You should see the Odoo login page
3. Default credentials:
   - **Email**: `admin`
   - **Password**: The `ADMIN_PASSWORD` you set in environment variables
   - **Database**: Your `DB_NAME`

### 6. Activate the Module

After first login:

1. Go to **Apps** menu
2. Click **Update Apps List** (if needed)
3. Search for **"Invoice Payment Details"**
4. Click **Activate**

The module should now be installed and ready to use!

## Environment Variables Reference

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DB_HOST` | PostgreSQL host | Yes | Railway auto-fills |
| `DB_PORT` | PostgreSQL port | Yes | Railway auto-fills |
| `DB_USER` | PostgreSQL user | Yes | Railway auto-fills |
| `DB_PASSWORD` | PostgreSQL password | Yes | Railway auto-fills |
| `DB_NAME` | Database name | Yes | Railway auto-fills |
| `ADMIN_PASSWORD` | Odoo master admin password | Yes | - |
| `INIT_DB` | Initialize DB on startup | No | false |
| `UPDATE_MODULE` | Update module on startup | No | false |
| `PORT` | HTTP port | No | 8069 |

## Updating the Module

When you make changes to the module:

### Method 1: Automatic Update (Recommended)

1. Set environment variable: `UPDATE_MODULE=true`
2. Push your changes to Git
3. Railway will automatically rebuild and update
4. Set `UPDATE_MODULE=false` after successful update

### Method 2: Manual Update

1. Push changes to Git repository
2. Railway will rebuild automatically
3. Access Odoo and go to **Apps**
4. Find **Invoice Payment Details** and click **Upgrade**

## Troubleshooting

### Database Connection Issues

**Problem**: Can't connect to database

**Solution**:
- Verify PostgreSQL service is running in Railway
- Check that database environment variables are correctly set
- Look at deployment logs for specific error messages

### Module Not Appearing

**Problem**: Module doesn't show in Apps list

**Solution**:
- Ensure `INIT_DB=true` was set on first deployment
- Click "Update Apps List" in Odoo Apps menu
- Check deployment logs for errors during initialization

### Memory/Performance Issues

**Problem**: Odoo is slow or crashing

**Solution**:
- Upgrade your Railway plan for more resources
- Adjust worker settings in `odoo.conf`:
  ```ini
  workers = 2  # Reduce if low memory
  max_cron_threads = 1
  ```

### Can't Access After Deployment

**Problem**: Railway URL shows error

**Solution**:
- Check deployment logs for errors
- Verify the service is running (green status in Railway)
- Ensure port 8069 is exposed (check Dockerfile)
- Wait a few minutes - first deployment takes longer

### Database Already Exists Error

**Problem**: Error about database initialization

**Solution**:
- Set `INIT_DB=false` after first successful deployment
- The database only needs to be initialized once

## Railway CLI Commands

You can also use the Railway CLI for deployment:

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Link to project
railway link

# Deploy
railway up

# View logs
railway logs

# Open in browser
railway open
```

## Cost Estimation

Railway pricing (as of 2024):
- **Hobby Plan**: $5/month + usage
- **PostgreSQL**: Included in plan
- **Usage**: Based on compute time and resources

Estimated monthly cost for small deployment: $5-20

## Security Recommendations

1. **Strong Admin Password**: Use a complex password for `ADMIN_PASSWORD`
2. **Database Backups**: Enable Railway's backup feature
3. **Environment Variables**: Never commit passwords to Git
4. **HTTPS**: Railway provides HTTPS by default - always use it
5. **Access Control**: Configure Odoo user permissions properly
6. **Regular Updates**: Keep Odoo and the module updated

## Support and Documentation

- **Odoo Documentation**: [odoo.com/documentation/16.0](https://www.odoo.com/documentation/16.0/)
- **Railway Documentation**: [docs.railway.app](https://docs.railway.app/)
- **Module Issues**: Check the module's GitHub repository

## Advanced Configuration

### Custom Domain

1. In Railway, go to **Settings** → **Domains**
2. Add your custom domain
3. Configure DNS records as instructed by Railway

### Scaling

Edit `odoo.conf` to adjust workers based on your Railway plan:

```ini
# For higher tier Railway plans
workers = 4
max_cron_threads = 2
```

### Email Configuration

Add to environment variables:

```bash
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
EMAIL_USE_TLS=true
```

Then update `odoo.conf` to include email settings.

## Maintenance

### Regular Tasks

1. **Monitor Logs**: Check Railway logs regularly
2. **Database Backups**: Schedule regular backups
3. **Updates**: Keep module and Odoo updated
4. **Security**: Review access logs and user permissions

### Backup Strategy

Railway PostgreSQL backups:
1. Go to PostgreSQL service in Railway
2. Navigate to **Backups** tab
3. Enable automated backups
4. Download backups periodically

## Migration from Development

If migrating from local development:

1. Export your local database
2. Import to Railway PostgreSQL using `psql`
3. Deploy the application
4. Set `INIT_DB=false`
5. Restart the service

---

## Quick Start Checklist

- [ ] Create Railway account
- [ ] Create new project from GitHub repo
- [ ] Add PostgreSQL database
- [ ] Set required environment variables
- [ ] Set `INIT_DB=true` for first deployment
- [ ] Wait for deployment to complete
- [ ] Access Odoo via Railway URL
- [ ] Login with admin credentials
- [ ] Activate Invoice Payment Details module
- [ ] Set `INIT_DB=false` after successful setup
- [ ] Configure users and permissions
- [ ] Test the module functionality

---

**Need Help?** Check Railway's community forum or Odoo documentation for additional support.
