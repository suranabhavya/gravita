# Invitation Flow Implementation Summary

## Overview
Complete invitation system with dual authentication methods:
1. **Magic Link Flow**: User clicks link in email → Deep link opens app → Auto-validates
2. **Manual Code Flow**: User enters invite code manually in app

## Backend Implementation

### Database Changes
- Added `inviteCode` field to `invitations` table (format: XXXX-XXXX)
- Added index on `inviteCode` for fast lookups

### New Files Created
1. **`backend/src/company/utils/invite-code-generator.ts`**
   - Generates human-readable 8-character codes (e.g., BT4X-9KM2)
   - Excludes confusing characters (0, O, I, 1)

2. **`backend/src/company/invitation.service.ts`**
   - `validateInvitation()` - Validates token or code, returns invitation details
   - `acceptInvitation()` - Accepts invitation and assigns user to team/role

3. **`backend/src/company/dto/validate-invitation.dto.ts`**
   - DTO for invitation validation requests

### Updated Files
1. **`backend/src/auth/auth.service.ts`**
   - Updated `signupStep3()` to generate both token and invite code
   - Automatically sends invitation email with both options

2. **`backend/src/email/email.service.ts`**
   - Added `sendInvitationEmail()` method
   - Email includes both magic link button and invite code
   - Beautiful HTML template with company branding

3. **`backend/src/company/invitation.controller.ts`**
   - Added public endpoints:
     - `POST /invitations/validate` - Validate invitation
     - `GET /invitations/validate/:tokenOrCode` - Validate via URL param
     - `POST /invitations/accept` - Accept invitation (requires auth)

## Frontend Implementation

### New Screens
1. **`frontend/lib/screens/auth/invite_code_page.dart`**
   - Manual code entry screen
   - Auto-formats code as XXXX-XXXX
   - Validates code and navigates to signup

2. **`frontend/lib/screens/auth/complete_invite_signup_page.dart`**
   - Unified signup completion screen
   - Shows invitation details (company, inviter, team)
   - Pre-fills email (read-only)
   - Collects name, phone, password
   - Handles OTP verification and invitation acceptance

### Updated Files
1. **`frontend/lib/screens/landing/landing_page.dart`**
   - Added "Join with Invite Code" button
   - Positioned below "Create New Company" button

2. **`frontend/lib/services/invitation_service.dart`**
   - Added `validateInvitation()` method
   - Added `acceptInvitation()` method

3. **`frontend/lib/screens/auth/otp_verification_page.dart`**
   - Added optional `onVerified` callback
   - Supports custom post-verification flow

4. **`frontend/lib/services/deep_link_service.dart`**
   - Deep link handling service
   - Routes magic links to signup flow

## Deep Linking Setup (Required for Production)

### Android Configuration
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="gravita"
        android:host="invite" />
</intent-filter>
```

### iOS Configuration
Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>gravita</string>
        </array>
    </dict>
</array>
```

### Flutter Package
Add to `pubspec.yaml`:
```yaml
dependencies:
  app_links: ^6.0.0  # For deep linking
```

Then update `main.dart` to handle app links on app startup.

## Email Template Features
- Company branding with gradient header
- Clear call-to-action button (magic link)
- Prominent invite code display
- Instructions for both methods
- Expiration date information

## Flow Diagram
```
ADMIN INVITES USER
        ↓
EMAIL SENT WITH:
├─ Magic Link (gravita://invite?token=xxx)
└─ Invite Code (BT4X-9KM2)
        ↓
┌──────┴──────┐
↓              ↓
FLOW A         FLOW B
(Magic Link)   (Manual Code)
        ↓              ↓
Deep link      User enters code
opens app      in app
        ↓              ↓
        └──────┬──────┘
               ↓
    Backend validates
               ↓
    Returns invitation details
               ↓
    Pre-filled signup form
               ↓
    User completes profile
               ↓
    OTP verification
               ↓
    Accept invitation
               ↓
    User logged in
```

## API Endpoints

### Public Endpoints
- `POST /invitations/validate` - Validate invitation
- `GET /invitations/validate/:tokenOrCode` - Validate via URL

### Protected Endpoints (Require JWT)
- `POST /invitations` - Send invitations
- `POST /invitations/accept` - Accept invitation

## Security Considerations
1. Invitations expire after 7 days
2. Invitation codes are unique and indexed
3. Email validation ensures user matches invitation
4. OTP verification required before account activation
5. Magic links use secure tokens (UUIDs)

## Testing
1. Test magic link flow by clicking email button
2. Test manual code entry with various formats
3. Test expired invitation handling
4. Test invalid code/token handling
5. Test email matching validation

