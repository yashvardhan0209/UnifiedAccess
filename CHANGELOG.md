## 1.0.0

- Initial version.

## 1.0.1

- All country's phone number support added in `verifyPhoneNumber` method from `UnifiedAuthentication` make sure to pass phone number along with the country code. (eg:Phone Number(1234567890) & Country Code(+91) : +911234567890)

## 2.0.0

- Added testability support for social sign-in providers (Google, Apple, Facebook) and Firebase Cloud Messaging via injectable wrappers.
- 100% test coverage across all library source files (206/206 lines).
- Added automated CLI setup tool (`dart run unified_access:setup`) for Android and iOS platform configuration.

## 2.0.1

- Fixed example file naming for pub.dev package scoring.
- Applied `dart format` across all source files.
- Added `.pubignore` to exclude build artifacts from published package.
