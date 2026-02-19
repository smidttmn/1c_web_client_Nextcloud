# one_c_web_client

**Integration of 1C:Enterprise with Nextcloud**

[![Nextcloud](https://img.shields.io/badge/Nextcloud-31--32-blue.svg)](https://nextcloud.com)
[![PHP](https://img.shields.io/badge/PHP-8.0+-blue.svg)](https://php.net)
[![License](https://img.shields.io/badge/License-AGPL%20v3-green.svg)](LICENSE)

## 📋 Description

Application for integrating 1C:Enterprise systems with Nextcloud. Allows users to open 1C databases directly in the Nextcloud interface through secure HTTPS connection.

## ✨ Features

- 🔐 Secure HTTPS connection to 1C servers
- 🎯 Easy database management through admin panel
- 📱 Responsive design for mobile devices
- 🔒 Content Security Policy (CSP) protection
- 🌐 Works from external networks
- 📊 Compatible with Nextcloud 31-32

## 🚀 Quick Start

### Installation

```bash
# Clone or download the app to Nextcloud apps directory
cd /path/to/nextcloud/apps/

# Extract the archive
tar -xzf one_c_web_client_deploy.tar.gz
mv nc1c one_c_web_client

# Set permissions
chown -R www-data:www-data one_c_web_client

# Install via OCC
sudo -u www-data php occ app:install one_c_web_client
sudo -u www-data php occ app:enable one_c_web_client
sudo -u www-data php occ maintenance:repair
```

### Configuration

1. Open Nextcloud as administrator
2. Go to: **Settings** → **Administration** → **1C WebClient**
3. Add 1C databases:
   - Name: `Accounting`
   - URL: `https://10.72.1.5/sgtbuh/`
4. Save settings

### Usage

1. Open 1C WebClient from Nextcloud menu
2. Click on database button
3. Accept certificate if prompted
4. 1C opens in iframe

## 📋 Requirements

- **Nextcloud:** Version 31-32
- **PHP:** 8.0 or higher
- **1C:** HTTPS required (self-signed certificates supported)
- **Network:** Nextcloud server must access 1C servers

## 🔧 Configuration

### CSP Settings

If your 1C servers are on different domains, edit:

`/apps/one_c_web_client/lib/Controller/PageController.php`

Add domains to `index()` method:

```php
$csp->addAllowedFrameDomain('https://1c.example.com');
$csp->addAllowedFrameDomain('https://10.72.1.5');
```

### HTTPS on 1C

1C servers must use HTTPS. For self-signed certificates:
- Open 1C directly in browser first
- Accept the certificate
- Then use through Nextcloud

## 📁 Structure

```
one_c_web_client/
├── appinfo/
│   ├── info.xml              # App metadata
│   └── routes.php            # Routes
├── lib/
│   ├── AppInfo/
│   │   └── Application.php   # Main class
│   ├── Controller/
│   │   ├── PageController.php
│   │   └── ConfigController.php
│   └── Settings/
│       ├── AdminSettings.php
│       └── AdminSection.php
├── templates/
│   ├── index.php             # Client page
│   └── admin_settings.php    # Admin settings
├── js/
│   └── index.js              # Client JavaScript
├── img/
│   └── app.svg               # App icon
└── l10n/
    └── ru.json               # Translations
```

## 🛠️ Troubleshooting

### Mixed Content Error

**Problem:** Browser blocks HTTP iframe on HTTPS page

**Solution:** Enable HTTPS on 1C server

### CSP Blocking

**Problem:** `Content Security Policy` error

**Solution:** Add domain to `PageController.php`:
```php
$csp->addAllowedFrameDomain('https://your-domain.com');
```

### Certificate Warning

**Problem:** Browser doesn't trust self-signed certificate

**Solution:** 
1. Open 1C directly in new tab
2. Accept certificate
3. Try again in Nextcloud

### App Not Showing

**Problem:** App not visible in Nextcloud

**Solution:**
```bash
sudo -u www-data php occ maintenance:repair
sudo -u www-data php occ app:disable one_c_web_client
sudo -u www-data php occ app:enable one_c_web_client
```

## 📖 Documentation

- `README_INSTALLATION.md` - Full installation guide
- `QUICK_START.md` - Quick start guide
- `PROJECT_HISTORY_COMPLETE.md` - Project history
- `GITHUB_PUBLISH_INSTRUCTION.md` - GitHub publishing guide

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Files | 120+ |
| Size | 112 KB |
| Version | 1.0.0 |
| License | AGPL v3 |
| Release | February 2026 |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the AGPL v3 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Nextcloud Team for the platform
- 1C:Enterprise for the integration API
- Community contributors

## 📞 Support

### Getting Help

- Check logs: `data/nextcloud.log`
- Check Apache logs: `/var/log/apache2/error.log`
- Browser console (F12)
- Documentation files

### Common Issues

**Q: Can I use HTTP instead of HTTPS?**  
A: No, modern browsers block Mixed Content.

**Q: Does it work with 1C Enterprise 8.3?**  
A: Yes, all 1C versions with web interface are supported.

**Q: Is internet access required?**  
A: No, the app works in local network.

## 🔗 Links

- [Nextcloud](https://nextcloud.com)
- [1C:Enterprise](https://www.1c.ru)
- [Documentation](https://docs.nextcloud.com)

---

**Version:** 1.0.0 | **Release Date:** February 2026  
**Developer:** Nextcloud Team | **License:** AGPL v3
