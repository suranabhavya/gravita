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
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CreateTeamDto } from './dto/create-team.dto';
import { UpdateTeamDto } from './dto/update-team.dto';
import { AddTeamMembersDto } from './dto/add-team-members.dto';

@Controller('teams')
@UseGuards(JwtAuthGuard)
export class TeamController {
  constructor(private readonly teamService: TeamService) {}

  @Get()
  async getCompanyTeams(@CurrentUser() user: any) {
    return this.teamService.getCompanyTeams(user.companyId);
  }

  @Get(':id')
  async getTeamById(@Param('id') id: string, @CurrentUser() user: any) {
    return this.teamService.getTeamById(id, user.companyId);
  }

  @Post()
  async createTeam(@Body() createTeamDto: CreateTeamDto, @CurrentUser() user: any) {
    return this.teamService.createTeam(user.companyId, createTeamDto);
  }

  @Put(':id')
  async updateTeam(
    @Param('id') id: string,
    @Body() updateTeamDto: UpdateTeamDto,
    @CurrentUser() user: any,
  ) {
    return this.teamService.updateTeam(id, user.companyId, updateTeamDto);
  }

  @Post(':id/members')
  async addTeamMembers(
    @Param('id') id: string,
    @Body() addMembersDto: AddTeamMembersDto,
    @CurrentUser() user: any,
  ) {
    return this.teamService.addTeamMembers(id, user.companyId, addMembersDto);
  }

  @Delete(':id/members/:userId')
  async removeTeamMember(
    @Param('id') id: string,
    @Param('userId') userId: string,
    @CurrentUser() user: any,
  ) {
    return this.teamService.removeTeamMember(id, user.companyId, userId);
  }

  @Delete(':id')
  async dissolveTeam(@Param('id') id: string, @CurrentUser() user: any) {
    return this.teamService.dissolveTeam(id, user.companyId);
  }
}

