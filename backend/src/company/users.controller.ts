import { Controller, Get, Param, UseGuards, Query } from '@nestjs/common';
import { UserService } from './user.service';
import { PermissionsService } from './permissions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

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
    const roleInfo = await this.permissionsService.getUserRoleInfo(id, user.companyId);
    const permissions = await this.permissionsService.getUserPermissions(id, user.companyId);
    return {
      ...userData,
      roleInfo,
      permissions,
    };
  }

  @Get(':id/permissions')
  async getUserPermissions(@Param('id') id: string, @CurrentUser() user: any) {
    const roleInfo = await this.permissionsService.getUserRoleInfo(id, user.companyId);
    const permissions = await this.permissionsService.getUserPermissions(id, user.companyId);
    return {
      roleInfo,
      permissions,
    };
  }

  // Note: updateUserPermissions removed - users now get permissions through roles only
  // Use role assignment endpoints instead
}

