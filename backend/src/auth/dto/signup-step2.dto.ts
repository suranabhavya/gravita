import { IsString, IsEnum, IsOptional } from 'class-validator';

export class SignupStep2Dto {
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
}

