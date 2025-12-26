import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { AuthService } from '../auth/auth.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { InviteMembersDto } from './dto/invite-members.dto';

@Controller('invitations')
@UseGuards(JwtAuthGuard)
export class InvitationController {
  constructor(private readonly authService: AuthService) {}

  @Post()
  async inviteMembers(@Body() inviteMembersDto: InviteMembersDto, @CurrentUser() user: any) {
    // Convert InviteMembersDto to SignupStep3Dto format
    const signupStep3Dto = {
      memberEmails: inviteMembersDto.emails,
      teamId: inviteMembersDto.teamId,
      roleId: inviteMembersDto.roleId,
    };

    return this.authService.signupStep3(user.id, signupStep3Dto);
  }
}

