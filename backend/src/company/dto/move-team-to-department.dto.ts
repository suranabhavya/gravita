import { IsUUID } from 'class-validator';

export class MoveTeamToDepartmentDto {
  @IsUUID('4')
  departmentId: string;
}

