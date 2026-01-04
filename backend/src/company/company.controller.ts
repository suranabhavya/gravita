import { Controller, Get, Put, Body, UseGuards } from '@nestjs/common';
import { CompanyService } from './company.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard } from '../auth/guards/permission.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { RequirePermission } from '../auth/decorators/require-permission.decorator';
import { UpdateCompanyDto } from './dto/update-company.dto';

@Controller('company')
@UseGuards(JwtAuthGuard)
export class CompanyController {
  constructor(private readonly companyService: CompanyService) {}

  @Get()
  async getCompany(@CurrentUser() user: any) {
    return this.companyService.getCompany(user.companyId);
  }

  @Put()
  @UseGuards(PermissionGuard)
  @RequirePermission({ action: 'access_settings' })
  async updateCompany(@Body() updateCompanyDto: UpdateCompanyDto, @CurrentUser() user: any) {
    return this.companyService.updateCompany(user.companyId, updateCompanyDto);
  }
}

