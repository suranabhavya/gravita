import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { db } from '../database';
import { invitations, companies, users, teams, roles } from '../database/schema';
import { eq, and, isNull, gt, or, sql } from 'drizzle-orm';

@Injectable()
export class InvitationService {
  constructor(private jwtService: JwtService) {}
  async validateInvitation(tokenOrCode: string) {
    if (!tokenOrCode || !tokenOrCode.trim()) {
      throw new BadRequestException('Token or invite code is required');
    }

    // Normalize the input (trim and uppercase for invite codes)
    const trimmed = tokenOrCode.trim();
    const normalizedCode = trimmed.toUpperCase();
    
    console.log('[InvitationService] Validating invitation:', {
      input: tokenOrCode,
      trimmed,
      normalized: normalizedCode,
    });

    // First, let's check if any invitations exist with this code (for debugging)
    const allInvitations = await db
      .select({
        id: invitations.id,
        email: invitations.email,
        inviteCode: invitations.inviteCode,
        token: invitations.token,
        status: invitations.status,
        expiresAt: invitations.expiresAt,
      })
      .from(invitations)
      .where(eq(invitations.status, 'pending'))
      .limit(10);
    
    console.log('[InvitationService] Recent pending invitations:', allInvitations.map(inv => ({
      email: inv.email,
      inviteCode: inv.inviteCode,
      expiresAt: inv.expiresAt,
      isExpired: new Date(inv.expiresAt) < new Date(),
    })));

    // Try to find by invite code specifically (for debugging)
    const codeMatches = await db
      .select()
      .from(invitations)
      .where(eq(invitations.inviteCode, normalizedCode))
      .limit(5);
    
    console.log('[InvitationService] Invitations matching code:', codeMatches.map(inv => ({
      id: inv.id,
      email: inv.email,
      inviteCode: inv.inviteCode,
      status: inv.status,
      expiresAt: inv.expiresAt,
      isExpired: new Date(inv.expiresAt) < new Date(),
    })));

    // Try to find by token or invite code
    // For invite codes, we need to match case-insensitively and handle the format
    const [invitation] = await db
      .select()
      .from(invitations)
      .where(
        and(
          or(
            eq(invitations.token, trimmed), // Token is case-sensitive
            eq(invitations.inviteCode, normalizedCode) // Invite code should be uppercase
          ),
          eq(invitations.status, 'pending'),
          gt(invitations.expiresAt, new Date()),
        ),
      )
      .limit(1);

    if (!invitation) {
      // More detailed error logging
      console.error('[InvitationService] Validation failed:', {
        input: tokenOrCode,
        trimmed,
        normalized: normalizedCode,
        timestamp: new Date().toISOString(),
        pendingInvitationsCount: allInvitations.length,
        sampleCodes: allInvitations.map(inv => inv.inviteCode).filter(Boolean),
      });
      throw new NotFoundException('Invalid or expired invitation. Please check your invite code and try again.');
    }

    console.log('[InvitationService] Found invitation:', {
      id: invitation.id,
      email: invitation.email,
      inviteCode: invitation.inviteCode,
    });

    // Get company details
    let company = null;
    try {
      const [companyData] = await db
        .select()
        .from(companies)
        .where(eq(companies.id, invitation.companyId))
        .limit(1);
      company = companyData;
    } catch (error) {
      console.error('[InvitationService] Error fetching company:', error);
    }

    // Get inviter details
    let inviter = null;
    try {
      const [inviterData] = await db
        .select({
          id: users.id,
          name: users.name,
          email: users.email,
        })
        .from(users)
        .where(eq(users.id, invitation.invitedByUserId))
        .limit(1);
      inviter = inviterData || null;
    } catch (error) {
      console.error('[InvitationService] Error fetching inviter:', error);
    }

    // Get team details if assigned
    let team = null;
    if (invitation.teamId) {
      const [teamData] = await db
        .select({
          id: teams.id,
          name: teams.name,
          location: teams.location,
        })
        .from(teams)
        .where(and(eq(teams.id, invitation.teamId), isNull(teams.deletedAt)))
        .limit(1);
      team = teamData;
    }

    // Get role details if assigned
    let role = null;
    if (invitation.roleId) {
      const [roleData] = await db
        .select({
          id: roles.id,
          name: roles.name,
          description: roles.description,
        })
        .from(roles)
        .where(eq(roles.id, invitation.roleId))
        .limit(1);
      role = roleData;
    }

    const response = {
      invitation: {
        id: invitation.id,
        email: invitation.email,
        expiresAt: invitation.expiresAt,
      },
      company: company
        ? {
            id: company.id,
            name: company.name,
            companyType: company.companyType,
            industry: company.industry,
          }
        : null,
      inviter: inviter,
      team,
      role,
    };

    console.log('[InvitationService] Returning validation response:', {
      invitationId: response.invitation.id,
      email: response.invitation.email,
      hasCompany: !!response.company,
      hasInviter: !!response.inviter,
      hasTeam: !!response.team,
      hasRole: !!response.role,
    });

    return response;
  }

  async acceptInvitation(tokenOrCode: string, userId: string) {
    // Normalize the code for lookup
    const trimmed = tokenOrCode.trim();
    const normalizedCode = trimmed.toUpperCase();

    const [invitation] = await db
      .select()
      .from(invitations)
      .where(
        and(
          or(
            eq(invitations.token, trimmed),
            eq(invitations.inviteCode, normalizedCode)
          ),
          eq(invitations.status, 'pending'),
          gt(invitations.expiresAt, new Date()),
        ),
      )
      .limit(1);

    if (!invitation) {
      throw new NotFoundException('Invalid or expired invitation');
    }

    // Verify the user's email matches the invitation
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.email.toLowerCase() !== invitation.email.toLowerCase()) {
      throw new BadRequestException('Email does not match invitation');
    }

    // Get the old company ID (might be temporary company)
    const oldCompanyId = user.companyId;

    // Use a transaction to ensure all updates happen atomically
    await db.transaction(async (tx) => {
      // 1. Update user's company to the invitation's company and apply permissions
      await tx
        .update(users)
        .set({
          companyId: invitation.companyId,
          status: 'active', // Change from 'invited' to 'active'
          permissions: invitation.permissions || {},
        })
        .where(eq(users.id, userId));

      // 2. Update invitation status
      await tx
        .update(invitations)
        .set({
          status: 'accepted',
          acceptedAt: new Date(),
        })
        .where(eq(invitations.id, invitation.id));

      // 3. Assign user to team if specified
      if (invitation.teamId) {
        const { teamMembers } = await import('../database/schema');
        await tx
          .insert(teamMembers)
          .values({
            teamId: invitation.teamId,
            userId: user.id,
          })
          .onConflictDoNothing();
      }

      // 4. Assign role if specified
      if (invitation.roleId) {
        const { userRoles } = await import('../database/schema');
        await tx
          .insert(userRoles)
          .values({
            userId: user.id,
            roleId: invitation.roleId,
            scopeType: invitation.teamId ? 'team' : 'company',
            scopeId: invitation.teamId || invitation.companyId,
          })
          .onConflictDoNothing();
      }

      // 5. Clean up temporary company if it exists and has no other users
      if (oldCompanyId && oldCompanyId !== invitation.companyId) {
        // Check if this is a temporary company (name is "Temporary Company")
        const [oldCompany] = await tx
          .select()
          .from(companies)
          .where(eq(companies.id, oldCompanyId))
          .limit(1);

        if (oldCompany && oldCompany.name === 'Temporary Company') {
          // Check if there are any other users in this company (excluding the current user)
          const otherUsers = await tx
            .select()
            .from(users)
            .where(
              and(
                eq(users.companyId, oldCompanyId),
                sql`${users.id} != ${userId}`
              )
            )
            .limit(1);

          // If no other users, soft delete the temporary company
          if (otherUsers.length === 0) {
            await tx
              .update(companies)
              .set({ deletedAt: new Date() })
              .where(eq(companies.id, oldCompanyId));
            
            console.log(`[InvitationService] Soft deleted temporary company: ${oldCompanyId}`);
          } else {
            console.log(`[InvitationService] Keeping temporary company ${oldCompanyId} - has other users`);
          }
        }
      }
    });

    // Get updated user to generate new JWT token with correct companyId
    const [updatedUser] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!updatedUser) {
      throw new NotFoundException('User not found after invitation acceptance');
    }

    // Generate new JWT token with updated companyId
    const payload = { 
      sub: updatedUser.id, 
      email: updatedUser.email, 
      companyId: updatedUser.companyId 
    };
    const newAccessToken = this.jwtService.sign(payload);

    console.log(`[InvitationService] Invitation accepted successfully:`, {
      userId,
      invitationId: invitation.id,
      companyId: invitation.companyId,
      teamId: invitation.teamId,
      roleId: invitation.roleId,
      newCompanyId: updatedUser.companyId,
    });

    return { 
      success: true, 
      invitation,
      access_token: newAccessToken,
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        name: updatedUser.name,
        companyId: updatedUser.companyId,
      },
    };
  }
}

