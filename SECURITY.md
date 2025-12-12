# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of VaporHealthCheck seriously. If you believe you have found a security vulnerability, please report it to us as described below.

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to the maintainers or through GitHub's private security advisory feature:

1. Go to the repository's Security tab
2. Click "Report a vulnerability"
3. Fill out the advisory form with details about the vulnerability

### What to Include

Please include the following information in your report:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### What to Expect

- You should receive an acknowledgment within 48 hours
- We'll work with you to understand and validate the report
- We'll keep you informed about our progress toward a fix
- We'll credit you in the release notes (unless you prefer to remain anonymous)

## Security Best Practices

When using VaporHealthCheck in your application:

1. **Monitor Health Check Logs**: While the health check endpoint is unauthenticated by design, monitor its usage for unusual patterns
2. **Database Credentials**: Ensure database credentials are properly secured and not exposed
3. **Network Security**: Use appropriate firewall rules and network policies
4. **Keep Dependencies Updated**: Regularly update Vapor, Fluent, and other dependencies
5. **Rate Limiting**: Consider implementing rate limiting on the health check endpoint to prevent abuse

## Disclosure Policy

When we receive a security vulnerability report, we will:

1. Confirm the problem and determine affected versions
2. Audit code to find any similar problems
3. Prepare fixes for all supported versions
4. Release new versions as quickly as possible

Thank you for helping keep VaporHealthCheck and its users safe!
