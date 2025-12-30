import { IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { PermissionsDto } from './permissions.dto';

export class UpdateUserPermissionsDto {
  @IsOptional()
  @ValidateNested()
  @Type(() => PermissionsDto)
  permissions?: PermissionsDto;
}

