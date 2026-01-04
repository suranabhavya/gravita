import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { DepartmentService } from './department.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard } from '../auth/guards/permission.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { RequirePermission } from '../auth/decorators/require-permission.decorator';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { MoveTeamToDepartmentDto } from './dto/move-team-to-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';

@Controller('departments')
@UseGuards(JwtAuthGuard)
export class DepartmentController {
  constructor(private readonly departmentService: DepartmentService) {}

  @Get()
  async getCompanyDepartments(@CurrentUser() user: any) {
    // Scope filtering will be handled in service layer
    return this.departmentService.getCompanyDepartments(user.companyId, user.userId);
  }

  @Get(':id')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'department',
    getTargetId: (req) => req.params.id,
  })
  async getDepartmentById(@Param('id') id: string, @CurrentUser() user: any) {
    return this.departmentService.getDepartmentById(id, user.companyId);
  }

  @Post()
  @UseGuards(PermissionGuard)
  @RequirePermission({ action: 'manage_structure' })
  async createDepartment(@Body() createDepartmentDto: CreateDepartmentDto, @CurrentUser() user: any) {
    return this.departmentService.createDepartment(user.companyId, createDepartmentDto);
  }

  @Post(':id/teams/:teamId')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'department',
    getTargetId: (req) => req.params.id,
  })
  async moveTeamToDepartment(
    @Param('id') id: string,
    @Param('teamId') teamId: string,
    @Body() moveTeamDto: MoveTeamToDepartmentDto,
    @CurrentUser() user: any,
  ) {
    return this.departmentService.moveTeamToDepartment(teamId, user.companyId, moveTeamDto);
  }

  @Delete(':id/teams/:teamId')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'department',
    getTargetId: (req) => req.params.id,
  })
  async removeTeamFromDepartment(
    @Param('id') id: string,
    @Param('teamId') teamId: string,
    @CurrentUser() user: any,
  ) {
    return this.departmentService.removeTeamFromDepartment(teamId, user.companyId);
  }

  @Put(':id')
  @UseGuards(PermissionGuard)
  @RequirePermission({
    action: 'manage_structure',
    targetType: 'department',
    getTargetId: (req) => req.params.id,
  })
  async updateDepartment(
    @Param('id') id: string,
    @Body() updateDepartmentDto: UpdateDepartmentDto,
    @CurrentUser() user: any,
  ) {
    return this.departmentService.updateDepartment(id, user.companyId, updateDepartmentDto);
  }

  @Post('from-teams')
  @UseGuards(PermissionGuard)
  @RequirePermission({ action: 'manage_structure' })
  async createDepartmentFromTeams(
    @Body() dto: {
      departmentName: string;
      description?: string;
      teamIds: string[];
      managerUserId?: string;
      parentDepartmentId?: string;
    },
    @CurrentUser() user: any,
  ) {
    return this.departmentService.createDepartmentFromTeams({
      companyId: user.companyId,
      createdByUserId: user.userId,
      ...dto,
    });
  }
}

