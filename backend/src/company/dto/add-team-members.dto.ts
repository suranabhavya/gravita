import { IsArray, IsUUID, ArrayMinSize } from 'class-validator';

export class AddTeamMembersDto {
  @IsArray()
  @ArrayMinSize(1)
  @IsUUID('4', { each: true })
  userIds: string[];
}

