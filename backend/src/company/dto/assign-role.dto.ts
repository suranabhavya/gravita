import { IsString, IsEnum, IsOptional, IsNumber, Min } from 'class-validator';

export enum RoleType {
  ADMIN = 'admin',
  MANAGER = 'manager',
  LEAD = 'lead',
  MEMBER = 'member',
}

export enum ScopeType {
  COMPANY = 'company',
  DEPARTMENT = 'department',
  TEAM = 'team',
}

export class AssignRoleDto {
  @IsString()
  userId: string;

  @IsEnum(RoleType)
  roleType: RoleType;

  @IsEnum(ScopeType)
  @IsOptional()
  scopeType?: ScopeType;

  @IsString()
  @IsOptional()
  scopeId?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  maxApprovalAmountOverride?: number;
}
