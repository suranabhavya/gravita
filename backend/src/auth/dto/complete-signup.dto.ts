import { IsEmail, IsString, MinLength, IsOptional, IsPhoneNumber, IsEnum, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class MemberRoleDto {
  @IsEmail()
  email: string;

  @IsEnum(['admin', 'manager', 'lead', 'member'])
  roleType: 'admin' | 'manager' | 'lead' | 'member';
}

export class CompleteSignupDto {
  @IsString()
  name: string;

  @IsEmail()
  email: string;

  @IsOptional()
  @IsPhoneNumber()
  phone?: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsString()
  companyName: string;

  @IsEnum(['supplier', 'recycler'])
  companyType: 'supplier' | 'recycler';

  @IsOptional()
  @IsString()
  industry?: string;

  @IsOptional()
  @IsString()
  size?: string;

  @IsOptional()
  @IsArray()
  @IsEmail({}, { each: true })
  memberEmails?: string[];

  @IsOptional()
  @IsEnum(['admin', 'manager', 'lead', 'member'])
  roleType?: 'admin' | 'manager' | 'lead' | 'member';

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MemberRoleDto)
  memberRoles?: MemberRoleDto[];
}

