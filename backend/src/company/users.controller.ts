import { Controller, Get, Param, Put, Body, UseGuards, Query } from '@nestjs/common';
import { UserService } from './user.service';
import { PermissionsService } from './permissions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UpdateUserPermissionsDto } from './dto/update-user-permissions.dto';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(
    private readonly userService: UserService,
    private readonly permissionsService: PermissionsService,
  ) {}

  @Get('members')
  async getCompanyMembers(
    @CurrentUser() user: any,
    @Query('search') search?: string,
    @Query('teamId') teamId?: string,
    @Query('roleId') roleId?: string,
  ) {
    return this.userService.getCompanyMembers(user.companyId, {
      search,
      teamId,
      roleId,
    });
  }

  @Get('stats')
  async getCompanyStats(@CurrentUser() user: any) {
    return this.userService.getCompanyStats(user.companyId);
  }

  @Get(':id')
  async getUserById(@Param('id') id: string, @CurrentUser() user: any) {
    const userData = await this.userService.getUserById(id, user.companyId);
    const permissions = await this.permissionsService.getUserPermissions(id, user.companyId);
    return {
      ...userData,
      permissions,
    };
  }

  @Get(':id/permissions')
  async getUserPermissions(@Param('id') id: string, @CurrentUser() user: any) {
    return this.permissionsService.getUserPermissions(id, user.companyId);
  }

  @Put(':id/permissions')
  async updateUserPermissions(
    @Param('id') id: string,
    @Body() updateDto: UpdateUserPermissionsDto,
    @CurrentUser() user: any,
  ) {
    return this.permissionsService.updateUserPermissions(id, user.companyId, updateDto);
  }
}

