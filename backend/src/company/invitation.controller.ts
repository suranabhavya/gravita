import { Controller, Post, Body, UseGuards, Get, Param } from '@nestjs/common';
import { AuthService } from '../auth/auth.service';
import { InvitationService } from './invitation.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard } from '../auth/guards/permission.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { RequirePermission } from '../auth/decorators/require-permission.decorator';
import { InviteMembersDto } from './dto/invite-members.dto';
import { ValidateInvitationDto } from './dto/validate-invitation.dto';

@Controller('invitations')
export class InvitationController {
  constructor(
    private readonly authService: AuthService,
    private readonly invitationService: InvitationService,
  ) {}

  @Post()
  @UseGuards(JwtAuthGuard, PermissionGuard)
  @RequirePermission({ action: 'manage_structure' })
  async inviteMembers(@Body() inviteMembersDto: InviteMembersDto, @CurrentUser() user: any) {
    // If roleType is provided but not roleId, find or create the role
    let roleId = inviteMembersDto.roleId;
    
    if (inviteMembersDto.roleType && !roleId) {
      const { db } = await import('../database');
      const { roles } = await import('../database/schema');
      const { eq, and, isNull } = await import('drizzle-orm');
      
      // Try to find existing role with this type
      const [existingRole] = await db
        .select()
        .from(roles)
        .where(
          and(
            eq(roles.companyId, user.companyId),
            eq(roles.roleType, inviteMembersDto.roleType),
            isNull(roles.deletedAt),
          ),
        )
        .limit(1);
      
      if (existingRole) {
        roleId = existingRole.id;
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
            name: roleNames[inviteMembersDto.roleType],
            description: `Default ${roleNames[inviteMembersDto.roleType]} role`,
            roleType: inviteMembersDto.roleType,
            permissions: rolePermissions[inviteMembersDto.roleType],
            maxApprovalAmount: maxAmounts[inviteMembersDto.roleType],
            isSystemRole: true,
          })
          .returning();
        
        roleId = newRole.id;
      }
    }
    
    // Convert InviteMembersDto to SignupStep3Dto format
    const signupStep3Dto = {
      memberEmails: inviteMembersDto.emails,
      teamId: inviteMembersDto.teamId,
      roleId: roleId,
    };

    return this.authService.signupStep3(user.userId, signupStep3Dto);
  }

  @Post('validate')
  async validateInvitation(@Body() validateDto: ValidateInvitationDto) {
    try {
      console.log('[InvitationController] Received validation request:', {
        tokenOrCode: validateDto.tokenOrCode,
        length: validateDto.tokenOrCode?.length,
      });
      const result = await this.invitationService.validateInvitation(validateDto.tokenOrCode);
      console.log('[InvitationController] Validation successful, returning response');
      return result;
    } catch (error) {
      console.error('[InvitationController] Validation error:', error);
      throw error;
    }
  }

  @Get('validate/:tokenOrCode')
  async validateInvitationByParam(@Param('tokenOrCode') tokenOrCode: string) {
    return this.invitationService.validateInvitation(tokenOrCode);
  }

  @Post('accept')
  @UseGuards(JwtAuthGuard)
  async acceptInvitation(@Body() validateDto: ValidateInvitationDto, @CurrentUser() user: any) {
    return this.invitationService.acceptInvitation(validateDto.tokenOrCode, user.userId);
  }
}

