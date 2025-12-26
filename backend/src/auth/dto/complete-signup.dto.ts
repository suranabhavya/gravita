import { IsEmail, IsString, MinLength, IsOptional, IsPhoneNumber, IsEnum, IsArray } from 'class-validator';

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
}

