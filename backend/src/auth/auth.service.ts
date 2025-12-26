import { Injectable, UnauthorizedException, ConflictException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { db } from '../database';
import { users, companies, roles, userRoles, invitations, emailVerifications } from '../database/schema';
import { eq, and, gt, isNull } from 'drizzle-orm';
import { SignupStep1Dto } from './dto/signup-step1.dto';
import { SignupStep2Dto } from './dto/signup-step2.dto';
import { SignupStep3Dto } from './dto/signup-step3.dto';
import { CompleteSignupDto } from './dto/complete-signup.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { LoginDto } from './dto/login.dto';
import { EmailService } from '../email/email.service';
import { randomUUID } from 'crypto';

@Injectable()
export class AuthService {
  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private emailService: EmailService,
  ) {}

  async login(loginDto: LoginDto) {
    const userResult = await db
      .select()
      .from(users)
      .where(eq(users.email, loginDto.email))
      .limit(1);

    if (userResult.length === 0) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const user = userResult[0];

    if (user.status !== 'active') {
      throw new UnauthorizedException('Account is not active. Please contact support.');
    }

    if (!user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(loginDto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    await db
      .update(users)
      .set({ lastLoginAt: new Date() })
      .where(eq(users.id, user.id));

    const payload = { sub: user.id, email: user.email, companyId: user.companyId };
    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        companyId: user.companyId,
      },
    };
  }

  async signupStep1(signupDto: SignupStep1Dto) {
    const existingUser = await db
      .select()
      .from(users)
      .where(eq(users.email, signupDto.email))
      .limit(1);

    if (existingUser.length > 0) {
      throw new ConflictException('User with this email already exists');
    }

    const passwordHash = await bcrypt.hash(signupDto.password, 10);
    const userId = randomUUID();
    const tempCompanyId = randomUUID();

    await db
      .insert(companies)
      .values({
        id: tempCompanyId,
        name: 'Temporary Company',
        companyType: 'supplier',
        status: 'active',
      });

    const [newUser] = await db
      .insert(users)
      .values({
        id: userId,
        email: signupDto.email,
        name: signupDto.name,
        phone: signupDto.phone,
        passwordHash,
        companyId: tempCompanyId,
        status: 'invited',
      })
      .returning();

    return {
      userId: newUser.id,
      email: newUser.email,
      name: newUser.name,
    };
  }

  async signupStep2(userId: string, companyDto: SignupStep2Dto) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new BadRequestException('User not found');
    }

    const [existingCompany] = await db
      .select()
      .from(companies)
      .where(eq(companies.id, user.companyId))
      .limit(1);

    if (!existingCompany || existingCompany.name !== 'Temporary Company') {
      throw new BadRequestException('Company already created for this user');
    }

    const [updatedCompany] = await db
      .update(companies)
      .set({
        name: companyDto.companyName,
        companyType: companyDto.companyType,
        industry: companyDto.industry,
        size: companyDto.size,
      })
      .where(eq(companies.id, user.companyId))
      .returning();

    const companyId = user.companyId;

    const [companyAdminRole] = await db
      .insert(roles)
      .values({
        companyId,
        name: 'Company Admin',
        description: 'Full access to company resources',
        isSystemRole: true,
        permissions: {
          listings: {
            create: true,
            edit_own: true,
            edit_any: true,
            delete: true,
            approve: true,
            max_approval_amount: 999999999,
          },
          team: {
            view_members: true,
            invite_members: true,
            remove_members: true,
            manage_team: true,
          },
          analytics: {
            view_own: true,
            view_own_team: true,
            view_department: true,
            view_company: true,
          },
          settings: {
            manage_company: true,
            manage_roles: true,
          },
        },
      })
      .returning();

    await db
      .insert(userRoles)
      .values({
        userId,
        roleId: companyAdminRole.id,
        scopeType: 'company',
        scopeId: companyId,
      });

    await db
      .update(users)
      .set({
        companyId,
        status: 'active',
      })
      .where(eq(users.id, userId));

    const payload = { sub: user.id, email: user.email, companyId };
    return {
      access_token: this.jwtService.sign(payload),
      company: {
        id: updatedCompany.id,
        name: updatedCompany.name,
        companyType: updatedCompany.companyType,
      },
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        companyId,
      },
    };
  }

  async signupStep3(userId: string, inviteDto: SignupStep3Dto) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user || !user.companyId) {
      throw new BadRequestException('User or company not found');
    }

    if (!inviteDto.memberEmails || inviteDto.memberEmails.length === 0) {
      return { message: 'No members to invite', invitations: [] };
    }

    const createdInvitations = [];
    for (const email of inviteDto.memberEmails) {
      const existingUser = await db
        .select()
        .from(users)
        .where(and(eq(users.email, email), eq(users.companyId, user.companyId)))
        .limit(1);

      if (existingUser.length > 0) {
        continue;
      }

      const token = randomUUID();
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7);

      const [invitation] = await db
        .insert(invitations)
        .values({
          companyId: user.companyId,
          email,
          invitedByUserId: userId,
          teamId: inviteDto.teamId,
          roleId: inviteDto.roleId,
          token,
          expiresAt,
          status: 'pending',
        })
        .returning();

      createdInvitations.push(invitation);
    }

    return {
      message: `Invited ${createdInvitations.length} members`,
      invitations: createdInvitations.map((inv) => ({ email: inv.email, token: inv.token })),
    };
  }

  async completeSignup(signupDto: CompleteSignupDto) {
    const existingUser = await db
      .select()
      .from(users)
      .where(eq(users.email, signupDto.email))
      .limit(1);

    if (existingUser.length > 0) {
      throw new ConflictException('User with this email already exists');
    }

    let otp: string;
    let userEmail: string;
    let userName: string;
    let signupResult: any;

    signupResult = await db.transaction(async (tx) => {
      const passwordHash = await bcrypt.hash(signupDto.password, 10);
      const userId = randomUUID();
      const companyId = randomUUID();

      const [newCompany] = await tx
        .insert(companies)
        .values({
          id: companyId,
          name: signupDto.companyName,
          companyType: signupDto.companyType,
          industry: signupDto.industry,
          size: signupDto.size,
          status: 'active',
        })
        .returning();

      const [newUser] = await tx
        .insert(users)
        .values({
          id: userId,
          email: signupDto.email,
          name: signupDto.name,
          phone: signupDto.phone,
          passwordHash,
          companyId,
          status: 'active',
        })
        .returning();

      const [companyAdminRole] = await tx
        .insert(roles)
        .values({
          companyId,
          name: 'Company Admin',
          description: 'Full access to company resources',
          isSystemRole: true,
          permissions: {
            listings: {
              create: true,
              edit_own: true,
              edit_any: true,
              delete: true,
              approve: true,
              max_approval_amount: 999999999,
            },
            team: {
              view_members: true,
              invite_members: true,
              remove_members: true,
              manage_team: true,
            },
            analytics: {
              view_own: true,
              view_own_team: true,
              view_department: true,
              view_company: true,
            },
            settings: {
              manage_company: true,
              manage_roles: true,
            },
          },
        })
        .returning();

      await tx
        .insert(userRoles)
        .values({
          userId,
          roleId: companyAdminRole.id,
          scopeType: 'company',
          scopeId: companyId,
        });

      const createdInvitations = [];
      if (signupDto.memberEmails && signupDto.memberEmails.length > 0) {
        for (const email of signupDto.memberEmails) {
          const existingUserInCompany = await tx
            .select()
            .from(users)
            .where(and(eq(users.email, email), eq(users.companyId, companyId)))
            .limit(1);

          if (existingUserInCompany.length > 0) {
            continue;
          }

          const token = randomUUID();
          const expiresAt = new Date();
          expiresAt.setDate(expiresAt.getDate() + 7);

          const [invitation] = await tx
            .insert(invitations)
            .values({
              companyId,
              email,
              invitedByUserId: userId,
              token,
              expiresAt,
              status: 'pending',
            })
            .returning();

          createdInvitations.push(invitation);
        }
      }

      otp = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + 10);
      userEmail = newUser.email;
      userName = newUser.name;

      await tx
        .insert(emailVerifications)
        .values({
          userId: newUser.id,
          email: newUser.email,
          otp,
          expiresAt,
        });

      return {
        userId: newUser.id,
        email: newUser.email,
        company: {
          id: newCompany.id,
          name: newCompany.name,
          companyType: newCompany.companyType,
        },
        user: {
          id: newUser.id,
          email: newUser.email,
          name: newUser.name,
          companyId,
        },
        invitations: createdInvitations.map((inv) => ({ email: inv.email, token: inv.token })),
      };
    });

    console.log(`\n[AuthService] ========== TRANSACTION COMPLETED ==========`);
    console.log(`[AuthService] User created: ${userEmail}`);
    console.log(`[AuthService] OTP generated: ${otp}`);
    console.log(`[AuthService] Now sending OTP email...`);

    try {
      console.log(`\n[AuthService] ========== SENDING OTP EMAIL ==========`);
      console.log(`[AuthService] User Email: ${userEmail}`);
      console.log(`[AuthService] User Name: ${userName}`);
      console.log(`[AuthService] OTP: ${otp}`);
      console.log(`[AuthService] Calling emailService.sendOTPEmail...`);
      
      await this.emailService.sendOTPEmail(userEmail, otp, userName);
      
      console.log(`[AuthService] OTP email process completed for: ${userEmail}`);
      console.log(`[AuthService] =========================================\n`);
    } catch (error) {
      console.error('\n[AuthService] ========== ERROR SENDING OTP ==========');
      console.error('[AuthService] Failed to send OTP email after signup:', error);
      console.error('[AuthService] Error stack:', error instanceof Error ? error.stack : 'No stack trace');
      console.error('[AuthService] =========================================\n');
      // Don't throw error - user is already created, just log it
      // In production, you might want to queue this for retry
    }

    return signupResult;
  }

  async verifyOtp(verifyOtpDto: VerifyOtpDto) {
    const [verification] = await db
      .select()
      .from(emailVerifications)
      .where(
        and(
          eq(emailVerifications.userId, verifyOtpDto.userId),
          eq(emailVerifications.otp, verifyOtpDto.otp),
          gt(emailVerifications.expiresAt, new Date()),
          isNull(emailVerifications.verifiedAt),
        ),
      )
      .limit(1);

    if (!verification) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    await db
      .update(emailVerifications)
      .set({ verifiedAt: new Date() })
      .where(eq(emailVerifications.id, verification.id));

    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, verifyOtpDto.userId))
      .limit(1);

    if (!user) {
      throw new BadRequestException('User not found');
    }

    await db
      .update(users)
      .set({ 
        emailVerified: true,
        updatedAt: new Date(),
      })
      .where(eq(users.id, verifyOtpDto.userId));

    const payload = { sub: user.id, email: user.email, companyId: user.companyId };
    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        companyId: user.companyId,
        emailVerified: true,
      },
    };
  }

  async resendOtp(userId: string) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new BadRequestException('User not found');
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10);

    await db
      .insert(emailVerifications)
      .values({
        userId: user.id,
        email: user.email,
        otp,
        expiresAt,
      });

    await this.emailService.sendOTPEmail(user.email, otp, user.name);

    return { message: 'OTP sent successfully' };
  }
}

