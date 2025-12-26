import { IsArray, IsEmail, IsOptional, IsUUID, ArrayMinSize } from 'class-validator';

export class InviteMembersDto {
  @IsArray()
  @ArrayMinSize(1)
  @IsEmail({}, { each: true })
  emails: string[];

  @IsOptional()
  @IsUUID('4')
  teamId?: string;

  @IsOptional()
  @IsUUID('4')
  roleId?: string;
}

