import { IsString, IsOptional, IsUUID, IsArray, ArrayMinSize } from 'class-validator';

export class CreateTeamDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsArray()
  @ArrayMinSize(1)
  @IsUUID('4', { each: true })
  memberIds: string[];

  @IsOptional()
  @IsUUID('4')
  teamLeadId?: string;
}

