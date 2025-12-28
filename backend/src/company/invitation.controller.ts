import { Controller, Post, Body, UseGuards, Get, Param } from '@nestjs/common';
import { AuthService } from '../auth/auth.service';
import { InvitationService } from './invitation.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { InviteMembersDto } from './dto/invite-members.dto';
import { ValidateInvitationDto } from './dto/validate-invitation.dto';

@Controller('invitations')
export class InvitationController {
  constructor(
    private readonly authService: AuthService,
    private readonly invitationService: InvitationService,
  ) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  async inviteMembers(@Body() inviteMembersDto: InviteMembersDto, @CurrentUser() user: any) {
    // Convert InviteMembersDto to SignupStep3Dto format
    const signupStep3Dto = {
      memberEmails: inviteMembersDto.emails,
      teamId: inviteMembersDto.teamId,
      roleId: inviteMembersDto.roleId,
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

