import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { DepartmentService } from './department.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { MoveTeamToDepartmentDto } from './dto/move-team-to-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';

@Controller('departments')
@UseGuards(JwtAuthGuard)
export class DepartmentController {
  constructor(private readonly departmentService: DepartmentService) {}

  @Get()
  async getCompanyDepartments(@CurrentUser() user: any) {
    return this.departmentService.getCompanyDepartments(user.companyId);
  }

  @Get(':id')
  async getDepartmentById(@Param('id') id: string, @CurrentUser() user: any) {
    return this.departmentService.getDepartmentById(id, user.companyId);
  }

  @Post()
  async createDepartment(@Body() createDepartmentDto: CreateDepartmentDto, @CurrentUser() user: any) {
    return this.departmentService.createDepartment(user.companyId, createDepartmentDto);
  }

  @Post(':id/teams/:teamId')
  async moveTeamToDepartment(
    @Param('id') id: string,
    @Param('teamId') teamId: string,
    @Body() moveTeamDto: MoveTeamToDepartmentDto,
    @CurrentUser() user: any,
  ) {
    return this.departmentService.moveTeamToDepartment(teamId, user.companyId, moveTeamDto);
  }

  @Delete(':id/teams/:teamId')
  async removeTeamFromDepartment(
    @Param('id') id: string,
    @Param('teamId') teamId: string,
    @CurrentUser() user: any,
  ) {
    return this.departmentService.removeTeamFromDepartment(teamId, user.companyId);
  }

  @Put(':id')
  async updateDepartment(
    @Param('id') id: string,
    @Body() updateDepartmentDto: UpdateDepartmentDto,
    @CurrentUser() user: any,
  ) {
    return this.departmentService.updateDepartment(id, user.companyId, updateDepartmentDto);
  }
}

