# Dasai Mochi - Security Configuration Guide

This document outlines the security configuration and best practices for the Dasai Mochi project.

## Environment Variables Setup

### Quick Setup
1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Fill in your actual API keys and secrets in the `.env` file
3. Never commit the `.env` file to version control

### Required API Keys

#### Essential Services (Core Functionality)
- **OpenWeatherMap API** (Free)
  - Purpose: Weather functionality
  - Get it: https://openweathermap.org/api
  - Variable: `WEATHER_API_KEY`

#### Optional Services (Enhanced Features)

**AI & ML Services:**
- **OpenAI API** (Paid)
  - Purpose: AI chat and language processing
  - Get it: https://platform.openai.com/api-keys
  - Variable: `OPENAI_API_KEY`

**Cloud & Storage:**
- **Firebase** (Free tier available)
  - Purpose: Cloud storage, authentication, notifications
  - Get it: https://console.firebase.google.com/
  - Variables: `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, etc.

**Maps & Location:**
- **Google Maps API** (Free tier available)
  - Purpose: Location services and mapping
  - Get it: https://console.cloud.google.com/
  - Variable: `GOOGLE_MAPS_API_KEY`

**Music & Audio:**
- **Spotify API** (Free for non-commercial)
  - Purpose: Music streaming integration
  - Get it: https://developer.spotify.com/dashboard/
  - Variables: `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`

**Payment Services:**
- **Stripe** (Free for testing)
  - Purpose: Payment processing (if implementing premium features)
  - Get it: https://dashboard.stripe.com/apikeys
  - Variables: `STRIPE_PUBLISHABLE_KEY`, `STRIPE_SECRET_KEY`

## Security Best Practices

### 1. Environment Variables
- All sensitive data should be stored in environment variables
- Use different keys for development, staging, and production
- Never hardcode API keys or secrets in source code

### 2. File Exclusions
The following files are automatically excluded by `.gitignore`:
- `.env` files (all variations)
- API key files (`*key*.json`, `*secret*.json`)
- Certificate files (`*.p12`, `*.pem`, `*.keystore`, etc.)
- SSH keys and private keys
- Firebase configuration files
- Build artifacts and temporary files

### 3. Key Management
- **Rotate keys regularly**: Change API keys every 3-6 months
- **Use least privilege**: Only request necessary permissions
- **Monitor usage**: Check API usage for unusual activity
- **Separate environments**: Use different keys for dev/staging/production

### 4. ESP32 Security
For the ESP32 firmware component:
- Use encrypted communication (TLS/SSL)
- Implement secure pairing mechanisms
- Store sensitive data in encrypted flash
- Use hardware security features when available

## Development vs Production

### Development
- Use test/sandbox API keys where available
- Enable debug mode: `DEBUG_MODE=true`
- Use development database/storage
- Relaxed rate limiting

### Production
- Use production API keys
- Disable debug mode: `DEBUG_MODE=false`
- Use production database/storage
- Implement proper rate limiting
- Enable all security headers
- Use HTTPS everywhere

## Common Security Issues to Avoid

1. **Committing secrets to Git**
   - Solution: Use `.env` files and `.gitignore`

2. **Hardcoded API keys in code**
   - Solution: Always use environment variables

3. **Using production keys in development**
   - Solution: Separate keys for each environment

4. **Not rotating keys regularly**
   - Solution: Set calendar reminders to rotate keys

5. **Overly permissive API key scopes**
   - Solution: Use principle of least privilege

## Monitoring and Alerts

Set up monitoring for:
- API key usage anomalies
- Failed authentication attempts
- Unusual traffic patterns
- Error rate increases

## Emergency Procedures

If you suspect a key has been compromised:
1. **Immediately rotate** the affected API key
2. **Review logs** for suspicious activity
3. **Update the key** in all environments
4. **Monitor** for continued suspicious activity
5. **Document** the incident for future reference

## Support and Resources

- **OpenWeatherMap**: https://openweathermap.org/api
- **Firebase**: https://firebase.google.com/docs
- **OpenAI**: https://platform.openai.com/docs
- **Google Maps**: https://developers.google.com/maps
- **Stripe**: https://stripe.com/docs

## Contact

For security-related questions or to report vulnerabilities, please contact the development team.

---

**Remember:** Security is everyone's responsibility. When in doubt, err on the side of caution and ask for help.