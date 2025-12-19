# Security and Privacy Guidelines

## Data Privacy

This project handles financial transaction data which may contain sensitive information. Please follow these guidelines:

### Sensitive Data

**DO NOT commit to Git:**
- Real customer data (names, emails, addresses)
- Credit card numbers or payment details
- Database credentials or connection strings
- API keys or authentication tokens
- Personal identifiable information (PII)

### Data Handling

1. **Use synthetic data for development**: The project includes scripts to generate synthetic datasets
2. **Anonymize real data**: If using real data, ensure all PII is removed or anonymized
3. **Secure credentials**: Store database credentials in environment variables or secure config files (not in Git)
4. **Review before committing**: Always review files before committing to ensure no sensitive data is included

### Files to Exclude

The following are automatically excluded via `.gitignore`:
- `*.csv` files (except templates)
- `.env` files
- `credentials.json`
- `config.ini` with sensitive data
- Model files (may contain data patterns)

### Best Practices

1. **Use environment variables** for sensitive configuration:
   ```r
   db_password <- Sys.getenv("DB_PASSWORD")
   ```

2. **Use config files** that are not tracked:
   - Add `config.local.R` to `.gitignore`
   - Provide `config.example.R` as a template

3. **Review data exports**: Before exporting data for Tableau or other tools, ensure no sensitive fields are included

4. **Secure model files**: Trained models may contain patterns from training data - handle with care

## Reporting Security Issues

If you discover a security vulnerability, please:
1. **DO NOT** create a public issue
2. Email the maintainer directly
3. Include details about the vulnerability
4. Allow time for the issue to be addressed before public disclosure

## Compliance

When using this project in production:
- Ensure compliance with GDPR, CCPA, or other applicable regulations
- Implement proper data encryption
- Use secure database connections
- Implement access controls
- Regular security audits

## Data Retention

- Remove test data after development
- Follow data retention policies for production data
- Securely delete sensitive data when no longer needed


