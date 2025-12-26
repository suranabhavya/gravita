import { IsEmail, IsString, MinLength, IsOptional, IsPhoneNumber } from 'class-validator';

export class SignupStep1Dto {
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
}

