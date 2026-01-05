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
import { generateInviteCode } from '../company/utils/invite-code-generator';

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

    // Generate OTP for email verification
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10);

    // Store OTP in database
    await db
      .insert(emailVerifications)
      .values({
        userId: newUser.id,
        email: newUser.email,
        otp,
        expiresAt,
      });

    // Send OTP email
    try {
      console.log(`\n[AuthService] ========== SENDING OTP EMAIL (signupStep1) ==========`);
      console.log(`[AuthService] User Email: ${newUser.email}`);
      console.log(`[AuthService] User Name: ${newUser.name}`);
      console.log(`[AuthService] OTP: ${otp}`);
      console.log(`[AuthService] Calling emailService.sendOTPEmail...`);
      
      await this.emailService.sendOTPEmail(newUser.email, otp, newUser.name);
      
      console.log(`[AuthService] OTP email process completed for: ${newUser.email}`);
      console.log(`[AuthService] =========================================\n`);
    } catch (error) {
      console.error('\n[AuthService] ========== ERROR SENDING OTP (signupStep1) ==========');
      console.error('[AuthService] Failed to send OTP email:', error);
      console.error('[AuthService] Error stack:', error instanceof Error ? error.stack : 'No stack trace');
      console.error('[AuthService] =========================================\n');
      // Don't throw error - user is already created, just log it
    }

    return {
      user: {
        id: newUser.id,
        email: newUser.email,
        name: newUser.name,
        emailVerified: false,
      },
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
        roleType: 'admin',
        isSystemRole: true,
        permissions: {
          canManageStructure: true,
          canApproveListings: true,
          canAccessSettings: true,
        },
        maxApprovalAmount: '999999999', // Unlimited for admin
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

    // Find or create role if roleType is provided but roleId is not
    let finalRoleId = inviteDto.roleId;
    if (inviteDto.roleType && !finalRoleId) {
      // Try to find existing role with this type
      const [existingRole] = await db
        .select()
        .from(roles)
        .where(
          and(
            eq(roles.companyId, user.companyId),
            eq(roles.roleType, inviteDto.roleType),
            isNull(roles.deletedAt),
          ),
        )
        .limit(1);

      if (existingRole) {
        finalRoleId = existingRole.id;
      } else {
        // Create a new role with default permissions based on roleType
        const rolePermissions = {
          admin: {
            canManageStructure: true,
            canApproveListings: true,
            canAccessSettings: true,
          },
          manager: {
            canManageStructure: true,
            canApproveListings: true,
            canAccessSettings: false,
          },
          member: {
            canManageStructure: false,
            canApproveListings: false,
            canAccessSettings: false,
          },
          lead: {
            canManageStructure: true,
            canApproveListings: true,
            canAccessSettings: false,
          },
        };

        const roleNames = {
          admin: 'Company Admin',
          manager: 'Manager',
          lead: 'Team Lead',
          member: 'Team Member',
        };

        const maxAmounts = {
          admin: '999999999',
          manager: '500000',
          lead: '50000',
          member: '0',
        };

        const [newRole] = await db
          .insert(roles)
          .values({
            companyId: user.companyId,
            name: roleNames[inviteDto.roleType],
            description: `Default ${roleNames[inviteDto.roleType]} role`,
            roleType: inviteDto.roleType,
            permissions: rolePermissions[inviteDto.roleType],
            maxApprovalAmount: maxAmounts[inviteDto.roleType],
            isSystemRole: true,
          })
          .returning();

        finalRoleId = newRole.id;
      }
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

      // Check if there's already a pending invitation for this email
      const [existingInvitation] = await db
        .select()
        .from(invitations)
        .where(
          and(
            eq(invitations.companyId, user.companyId),
            eq(invitations.email, email),
            eq(invitations.status, 'pending'),
          ),
        )
        .limit(1);

      const token = randomUUID();
      const inviteCode = generateInviteCode();
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7);

      let invitation;
      if (existingInvitation) {
        // Update existing pending invitation with new details
        [invitation] = await db
          .update(invitations)
          .set({
            invitedByUserId: userId,
            teamId: inviteDto.teamId,
            roleId: finalRoleId,
            token,
            inviteCode,
            expiresAt,
          })
          .where(eq(invitations.id, existingInvitation.id))
          .returning();
      } else {
        // Create new invitation
        [invitation] = await db
          .insert(invitations)
          .values({
            companyId: user.companyId,
            email,
            invitedByUserId: userId,
            teamId: inviteDto.teamId,
            roleId: finalRoleId,
            token,
            inviteCode,
            expiresAt,
            status: 'pending',
          })
          .returning();
      }

      // Send invitation email
      try {
        const [company] = await db
          .select()
          .from(companies)
          .where(eq(companies.id, user.companyId))
          .limit(1);

        const [inviter] = await db
          .select()
          .from(users)
          .where(eq(users.id, userId))
          .limit(1);

        await this.emailService.sendInvitationEmail({
          to: email,
          companyName: company?.name || 'Your Company',
          inviterName: inviter?.name || 'Team Admin',
          inviteCode,
          token,
          expiresAt,
        });
      } catch (emailError) {
        console.error(`Failed to send invitation email to ${email}:`, emailError);
        // Don't fail the invitation creation if email fails
      }

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

      // Create all 4 system roles for the company
      const systemRoles = await tx
        .insert(roles)
        .values([
          {
            companyId,
            name: 'Company Admin',
            description: 'Full control over company',
            roleType: 'admin',
            isSystemRole: true,
            permissions: {
              canManageStructure: true,
              canApproveListings: true,
              canAccessSettings: true,
            },
            maxApprovalAmount: '999999999',
          },
          {
            companyId,
            name: 'Manager',
            description: 'Manages departments and approves listings',
            roleType: 'manager',
            isSystemRole: true,
            permissions: {
              canManageStructure: true,
              canApproveListings: true,
              canAccessSettings: false,
            },
            maxApprovalAmount: '500000',
          },
          {
            companyId,
            name: 'Team Lead',
            description: 'Leads a team and approves small listings',
            roleType: 'lead',
            isSystemRole: true,
            permissions: {
              canManageStructure: true,
              canApproveListings: true,
              canAccessSettings: false,
            },
            maxApprovalAmount: '50000',
          },
          {
            companyId,
            name: 'Team Member',
            description: 'Creates material listings',
            roleType: 'member',
            isSystemRole: true,
            permissions: {
              canManageStructure: false,
              canApproveListings: false,
              canAccessSettings: false,
            },
            maxApprovalAmount: '0',
          },
        ])
        .returning();

      // Assign admin role to the first user
      const companyAdminRole = systemRoles.find(r => r.roleType === 'admin')!;

      await tx
        .insert(userRoles)
        .values({
          userId,
          roleId: companyAdminRole.id,
          scopeType: 'company',
          scopeId: companyId,
        });

      // Helper function to find or create role by type
      const findOrCreateRole = async (roleType: 'admin' | 'manager' | 'lead' | 'member'): Promise<string> => {
        // Try to find existing role with this type
        const [existingRole] = await tx
          .select()
          .from(roles)
          .where(
            and(
              eq(roles.companyId, companyId),
              eq(roles.roleType, roleType),
              isNull(roles.deletedAt),
            ),
          )
          .limit(1);

        if (existingRole) {
          return existingRole.id;
        }

        // Create a new role with default permissions based on roleType
        const rolePermissions = {
          admin: {
            canManageStructure: true,
            canApproveListings: true,
            canAccessSettings: true,
          },
          manager: {
            canManageStructure: true,
            canApproveListings: true,
            canAccessSettings: false,
          },
          member: {
            canManageStructure: false,
            canApproveListings: false,
            canAccessSettings: false,
          },
          lead: {
            canManageStructure: true,
            canApproveListings: true,
            canAccessSettings: false,
          },
        };

        const roleNames = {
          admin: 'Company Admin',
          manager: 'Manager',
          lead: 'Team Lead',
          member: 'Team Member',
        };

        const maxAmounts = {
          admin: '999999999',
          manager: '500000',
          lead: '50000',
          member: '0',
        };

        const [newRole] = await tx
          .insert(roles)
          .values({
            companyId,
            name: roleNames[roleType],
            description: `Default ${roleNames[roleType]} role`,
            roleType: roleType,
            permissions: rolePermissions[roleType],
            maxApprovalAmount: maxAmounts[roleType],
            isSystemRole: true,
          })
          .returning();

        return newRole.id;
      };

      const createdInvitations = [];
      if (signupDto.memberEmails && signupDto.memberEmails.length > 0) {
        // Create a map of email to roleType
        const emailRoleMap = new Map<string, 'admin' | 'manager' | 'lead' | 'member'>();
        
        // If memberRoles is provided, use it; otherwise use roleType for all
        if (signupDto.memberRoles && signupDto.memberRoles.length > 0) {
          for (const memberRole of signupDto.memberRoles) {
            emailRoleMap.set(memberRole.email, memberRole.roleType);
          }
        } else if (signupDto.roleType) {
          // Fallback to single roleType for all emails
          for (const email of signupDto.memberEmails) {
            emailRoleMap.set(email, signupDto.roleType);
          }
        }

        for (const email of signupDto.memberEmails) {
          const existingUserInCompany = await tx
            .select()
            .from(users)
            .where(and(eq(users.email, email), eq(users.companyId, companyId)))
            .limit(1);

          if (existingUserInCompany.length > 0) {
            continue;
          }

          // Get role type for this email (default to 'member' if not specified)
          const emailRoleType = emailRoleMap.get(email) || 'member';
          const roleId = await findOrCreateRole(emailRoleType);

          const token = randomUUID();
          const inviteCode = generateInviteCode();
          const expiresAt = new Date();
          expiresAt.setDate(expiresAt.getDate() + 7);

          const [invitation] = await tx
            .insert(invitations)
            .values({
              companyId,
              email,
              invitedByUserId: userId,
              roleId: roleId,
              token,
              inviteCode,
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

