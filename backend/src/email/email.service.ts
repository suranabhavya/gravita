import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private resend: Resend;
  private fromEmail: string;

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('RESEND_API_KEY');
    if (!apiKey) {
      throw new Error('RESEND_API_KEY is not configured in .env file');
    }
    
    if (!apiKey.startsWith('re_')) {
      console.warn('WARNING: RESEND_API_KEY should start with "re_". Please verify your API key from https://resend.com/api-keys');
    }
    
    this.resend = new Resend(apiKey);
    this.fromEmail = this.configService.get<string>('RESEND_FROM_EMAIL') || 'onboarding@resend.dev';
    
    if (!this.fromEmail.includes('@resend.dev') && !this.fromEmail.includes('@')) {
      console.warn('WARNING: RESEND_FROM_EMAIL should be either onboarding@resend.dev or a verified domain email');
    }
    
    const enableEmailSending = this.configService.get<string>('ENABLE_EMAIL_SENDING') === 'true';
    
    console.log(`EmailService initialized with fromEmail: ${this.fromEmail}`);
    console.log(`API Key configured: ${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 4)}`);
    console.log(`ENABLE_EMAIL_SENDING: ${enableEmailSending ? 'true (REAL EMAILS)' : 'false (CONSOLE LOGGING MODE)'}`);
    
    if (!enableEmailSending) {
      console.log('📝 OTP codes will be logged to console instead of sending emails');
    }
  }

  async sendOTPEmail(to: string, otp: string, userName: string): Promise<void> {
    console.log('\n[EmailService] sendOTPEmail called');
    console.log(`[EmailService] ENABLE_EMAIL_SENDING value: "${this.configService.get<string>('ENABLE_EMAIL_SENDING')}"`);
    
    const enableEmailSending = this.configService.get<string>('ENABLE_EMAIL_SENDING') === 'true';
    console.log(`[EmailService] enableEmailSending resolved to: ${enableEmailSending}`);
    
    if (!enableEmailSending) {
      console.log('\n' + '='.repeat(80));
      console.log('📧 OTP EMAIL (DEVELOPMENT MODE - NOT SENT)');
      console.log('='.repeat(80));
      console.log(`To: ${to}`);
      console.log(`User: ${userName}`);
      console.log(`OTP Code: ${otp}`);
      console.log(`Expires in: 10 minutes`);
      console.log('='.repeat(80));
      console.log('💡 To enable real email sending, set ENABLE_EMAIL_SENDING=true in .env');
      console.log('💡 For production, verify your domain at https://resend.com/domains');
      console.log('='.repeat(80) + '\n');
      return;
    }

    try {
      console.log(`[EmailService] Attempting to send OTP email to: ${to} from: ${this.fromEmail}`);
      console.log(`[EmailService] OTP code: ${otp}`);
      
      const emailData = {
        from: this.fromEmail,
        to: to,
        subject: 'Verify your Gravita account',
        html: `
          <!DOCTYPE html>
          <html>
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            </head>
            <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
              <div style="background: linear-gradient(135deg, #0d2818 0%, #1a4d2e 100%); padding: 30px; border-radius: 12px; text-align: center; margin-bottom: 30px;">
                <h1 style="color: #22c55e; margin: 0; font-size: 32px; font-weight: 800;">Gravita</h1>
                <p style="color: #ffffff; margin: 10px 0 0 0; font-size: 16px;">Recycling Marketplace</p>
              </div>
              
              <div style="background: #f9fafb; padding: 30px; border-radius: 12px; margin-bottom: 20px;">
                <h2 style="color: #0d2818; margin-top: 0;">Hello ${userName},</h2>
                <p style="color: #4b5563; font-size: 16px;">Thank you for creating your account on Gravita. Please verify your email address using the OTP below:</p>
                
                <div style="background: #ffffff; border: 2px solid #22c55e; border-radius: 8px; padding: 20px; margin: 30px 0; text-align: center;">
                  <p style="color: #6b7280; font-size: 14px; margin: 0 0 10px 0; text-transform: uppercase; letter-spacing: 1px;">Your Verification Code</p>
                  <p style="color: #0d2818; font-size: 36px; font-weight: 700; letter-spacing: 8px; margin: 0; font-family: 'Courier New', monospace;">${otp}</p>
                </div>
                
                <p style="color: #6b7280; font-size: 14px; margin: 20px 0 0 0;">This code will expire in 10 minutes.</p>
              </div>
              
              <p style="color: #9ca3af; font-size: 12px; text-align: center; margin-top: 30px;">
                If you didn't create an account on Gravita, please ignore this email.
              </p>
            </body>
          </html>
        `,
      };
      
      console.log(`[EmailService] Sending email with data:`, {
        from: emailData.from,
        to: emailData.to,
        subject: emailData.subject,
      });
      
      if (this.fromEmail === 'onboarding@resend.dev') {
        console.warn('[EmailService] WARNING: Using onboarding@resend.dev - emails can only be sent to the email address registered with your Resend account');
        console.warn('[EmailService] To send to any email, verify your domain at https://resend.com/domains');
      }
      
      const result = await this.resend.emails.send(emailData);
      
      console.log(`[EmailService] Resend API response:`, JSON.stringify(result, null, 2));

      if (result.error) {
        console.error('[EmailService] Resend API error:', result.error);
        
        if (result.error.statusCode === 401 || result.error.name === 'validation_error') {
          throw new Error(
            'Invalid Resend API key. Please:\n' +
            '1. Go to https://resend.com/api-keys\n' +
            '2. Create a new API key or verify your existing one\n' +
            '3. Update RESEND_API_KEY in your .env file\n' +
            '4. Restart your backend server'
          );
        }
        
        throw new Error(`Failed to send email: ${result.error.message || JSON.stringify(result.error)}`);
      }

      if (result.data) {
        console.log('[EmailService] OTP email sent successfully. Email ID:', result.data.id);
        console.log('[EmailService] Email will be delivered to:', to);
      } else {
        console.warn('[EmailService] Email sent but no data returned from Resend');
      }
    } catch (error) {
      console.error('Failed to send OTP email:', error);
      console.error('Error details:', error instanceof Error ? error.message : error);
      throw new Error(`Failed to send verification email: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}

