import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Query,
} from '@nestjs/common';
import { TeamService } from './team.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard } from '../auth/guards/permission.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { RequirePermission } from '../auth/decorators/require-permission.decorator';
import { CreateTeamDto } from './dto/create-team.dto';
import { UpdateTeamDto } from './dto/update-team.dto';
import { AddTeamMembersDto } from './dto/add-team-members.dto';

@Controller('teams')
@UseGuards(JwtAuthGuard)
export class TeamController {
  constructor(private readonly teamService: TeamService) {}

  @Get()
  async getCompanyTeams(@CurrentUser() user: any) {
    // Scope filtering will be handled in service layer
    return this.teamService.getCompanyTeams(user.companyId, user.userId);
  }

  @Get(':id')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'team',
    getTargetId: (req) => req.params.id,
  })
  async getTeamById(@Param('id') id: string, @CurrentUser() user: any) {
    return this.teamService.getTeamById(id, user.companyId);
  }

  @Post()
  @UseGuards(PermissionGuard)
  @RequirePermission({ action: 'manage_structure' })
  async createTeam(@Body() createTeamDto: CreateTeamDto, @CurrentUser() user: any) {
    return this.teamService.createTeam(user.companyId, createTeamDto);
  }

  @Put(':id')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'team',
    getTargetId: (req) => req.params.id,
  })
  async updateTeam(
    @Param('id') id: string,
    @Body() updateTeamDto: UpdateTeamDto,
    @CurrentUser() user: any,
  ) {
    return this.teamService.updateTeam(id, user.companyId, updateTeamDto);
  }

  @Post(':id/members')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'team',
    getTargetId: (req) => req.params.id,
  })
  async addTeamMembers(
    @Param('id') id: string,
    @Body() addMembersDto: AddTeamMembersDto,
    @CurrentUser() user: any,
  ) {
    return this.teamService.addTeamMembers(id, user.companyId, addMembersDto);
  }

  @Delete(':id/members/:userId')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'team',
    getTargetId: (req) => req.params.id,
  })
  async removeTeamMember(
    @Param('id') id: string,
    @Param('userId') userId: string,
    @CurrentUser() user: any,
  ) {
    return this.teamService.removeTeamMember(id, user.companyId, userId);
  }

  @Delete(':id')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'team',
    getTargetId: (req) => req.params.id,
  })
  async dissolveTeam(@Param('id') id: string, @CurrentUser() user: any) {
    return this.teamService.dissolveTeam(id, user.companyId);
  }

  @Get('unassigned-members')
  @UseGuards(PermissionGuard)
  @RequirePermission({ action: 'manage_structure' })
  async getUnassignedMembers(@CurrentUser() user: any) {
    return this.teamService.getUnassignedMembers(user.companyId);
  }

  @Post('from-members')
  @UseGuards(PermissionGuard)
  @RequirePermission({ action: 'manage_structure' })
  async createTeamFromMembers(
    @Body() dto: {
      teamName: string;
      location?: string;
      description?: string;
      memberUserIds: string[];
      teamLeadUserId?: string;
      teamLeadApprovalLimit?: number;
    },
    @CurrentUser() user: any,
  ) {
    return this.teamService.createTeamFromMembers({
      companyId: user.companyId,
      createdByUserId: user.userId,
      ...dto,
    });
  }
}

