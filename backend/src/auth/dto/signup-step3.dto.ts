import { IsEmail, IsOptional, IsArray, IsUUID } from 'class-validator';

export class SignupStep3Dto {
  @IsOptional()
  @IsArray()
  @IsEmail({}, { each: true })
  memberEmails?: string[];

  @IsOptional()
  @IsUUID('4')
  teamId?: string;

  @IsOptional()
  @IsUUID('4')
  roleId?: string;
}

