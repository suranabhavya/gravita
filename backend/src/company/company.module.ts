import { Module } from '@nestjs/common';
import { CompanyController } from './company.controller';
import { TeamController } from './team.controller';
import { DepartmentController } from './department.controller';
import { UsersController } from './users.controller';
import { InvitationController } from './invitation.controller';
import { CompanyService } from './company.service';
import { TeamService } from './team.service';
import { DepartmentService } from './department.service';
import { UserService } from './user.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [
    CompanyController,
    TeamController,
    DepartmentController,
    UsersController,
    InvitationController,
  ],
  providers: [CompanyService, TeamService, DepartmentService, UserService],
  exports: [CompanyService, TeamService, DepartmentService, UserService],
})
export class CompanyModule {}

