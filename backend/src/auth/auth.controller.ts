import { Controller, Post, Body, UseGuards, Get } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { SignupStep1Dto } from './dto/signup-step1.dto';
import { SignupStep2Dto } from './dto/signup-step2.dto';
import { SignupStep3Dto } from './dto/signup-step3.dto';
import { CompleteSignupDto } from './dto/complete-signup.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Post('signup/step1')
  async signupStep1(@Body() signupDto: SignupStep1Dto) {
    return this.authService.signupStep1(signupDto);
  }

  @Post('signup/step2')
  async signupStep2(@Body() body: { userId: string } & SignupStep2Dto) {
    const { userId, ...companyDto } = body;
    return this.authService.signupStep2(userId, companyDto);
  }

  @Post('signup/step3')
  async signupStep3(@Body() body: { userId: string } & SignupStep3Dto) {
    const { userId, ...inviteDto } = body;
    return this.authService.signupStep3(userId, inviteDto);
  }

  @Post('signup/complete')
  async completeSignup(@Body() signupDto: CompleteSignupDto) {
    console.log('[AuthController] completeSignup called with email:', signupDto.email);
    const result = await this.authService.completeSignup(signupDto);
    console.log('[AuthController] completeSignup completed, returning result');
    return result;
  }

  @Post('verify-otp')
  async verifyOtp(@Body() verifyOtpDto: VerifyOtpDto) {
    return this.authService.verifyOtp(verifyOtpDto);
  }

  @Post('resend-otp')
  async resendOtp(@Body() body: { userId: string }) {
    return this.authService.resendOtp(body.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getMe(@CurrentUser() user: any) {
    return { user };
  }
}

