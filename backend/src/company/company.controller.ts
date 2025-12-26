import { Controller, Get, Put, Body, UseGuards } from '@nestjs/common';
import { CompanyService } from './company.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
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
  async updateCompany(@Body() updateCompanyDto: UpdateCompanyDto, @CurrentUser() user: any) {
    return this.companyService.updateCompany(user.companyId, updateCompanyDto);
  }
}

