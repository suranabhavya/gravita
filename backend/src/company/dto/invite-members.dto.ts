import { IsArray, IsEmail, IsOptional, IsUUID, ArrayMinSize, IsObject, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { RolePermissions } from '../../database/schema';

export class PermissionsDto {
  @IsOptional()
  @IsObject()
  people?: {
    view_members?: boolean;
    invite_members?: boolean;
    edit_members?: boolean;
    remove_members?: boolean;
    view_all_profiles?: boolean;
  };

  @IsOptional()
  @IsObject()
  teams?: {
    view_teams?: boolean;
    create_teams?: boolean;
    edit_teams?: boolean;
    delete_teams?: boolean;
    manage_team_members?: boolean;
    assign_team_leads?: boolean;
  };

  @IsOptional()
  @IsObject()
  departments?: {
    view_departments?: boolean;
    create_departments?: boolean;
    edit_departments?: boolean;
    delete_departments?: boolean;
    move_departments?: boolean;
    assign_team_to_department?: boolean;
  };

  @IsOptional()
  @IsObject()
  listings?: {
    create?: boolean;
    edit_own?: boolean;
    edit_any?: boolean;
    delete?: boolean;
    approve?: boolean;
    view_all?: boolean;
    max_approval_amount?: number;
  };

  @IsOptional()
  @IsObject()
  analytics?: {
    view_own?: boolean;
    view_own_team?: boolean;
    view_department?: boolean;
    view_company?: boolean;
  };

  @IsOptional()
  @IsObject()
  settings?: {
    manage_company?: boolean;
    manage_roles?: boolean;
    manage_permissions?: boolean;
    view_settings?: boolean;
  };
}

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

  @IsOptional()
  @ValidateNested()
  @Type(() => PermissionsDto)
  permissions?: PermissionsDto;
}

