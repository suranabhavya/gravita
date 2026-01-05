import { IsString, IsOptional, IsArray, ArrayMinSize } from 'class-validator';

export class GroupDepartmentsDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  managerId?: string;

  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  departmentIds: string[];
}
