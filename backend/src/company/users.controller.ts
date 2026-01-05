import { Controller, Get, Param, UseGuards, Query, ForbiddenException, Post, Body } from '@nestjs/common';
import { UserService } from './user.service';
import { PermissionsService } from './permissions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard } from '../auth/guards/permission.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { RequirePermission } from '../auth/decorators/require-permission.decorator';
import { AssignRoleDto } from './dto/assign-role.dto';

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
    // Scope filtering will be handled in service layer
    return this.userService.getCompanyMembers(user.companyId, {
      search,
      teamId,
      roleId,
      requestingUserId: user.userId,
    });
  }

  @Get('stats')
  @UseGuards(PermissionGuard)
  @RequirePermission({ action: 'manage_structure' })
  async getCompanyStats(@CurrentUser() user: any) {
    return this.userService.getCompanyStats(user.companyId);
  }

  @Get('me/permission-context')
  async getMyPermissionContext(
    @Query('companyId') companyId: string,
    @CurrentUser() user: any,
  ) {
    // Automatically use the authenticated user's ID
    const context = await this.permissionsService.getUserPermissionContext(
      user.userId,
      companyId || user.companyId,
    );
    return context;
  }

  @Get(':id')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'user',
    getTargetId: (req) => req.params.id,
  })
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

  @Get(':id/permission-context')
  async getPermissionContext(
    @Param('id') id: string,
    @Query('companyId') companyId: string,
    @CurrentUser() user: any,
  ) {
    // If accessing another user's context, check if requester has permission
    if (id !== user.userId) {
      // Get requesting user's permission context to check their role
      const requestingUserContext = await this.permissionsService.getUserPermissionContext(
        user.userId,
        companyId || user.companyId,
      );

      // Only admins and managers can view other users' permission contexts
      if (requestingUserContext.roleType !== 'admin' && requestingUserContext.roleType !== 'manager') {
        throw new ForbiddenException('You do not have permission to view this user\'s context');
      }
    }

    const context = await this.permissionsService.getUserPermissionContext(
      id,
      companyId || user.companyId,
    );
    return context;
  }

  @Post('assign-role')
  @UseGuards(PermissionGuard)
  @RequirePermission({ action: 'manage_structure' })
  async assignRole(
    @Body() assignRoleDto: AssignRoleDto,
    @CurrentUser() user: any,
  ) {
    return this.userService.assignRole(
      assignRoleDto,
      user.companyId,
      user.userId,
    );
  }
}

