import { IsEmail, IsOptional, IsArray } from 'class-validator';

export class SignupStep3Dto {
  @IsOptional()
  @IsArray()
  @IsEmail({}, { each: true })
  memberEmails?: string[];
}

