import { IsObject, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateUserPermissionsDto {
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => Object)
  permissions?: {
    people?: {
      view_members?: boolean;
      invite_members?: boolean;
      edit_members?: boolean;
      remove_members?: boolean;
      view_all_profiles?: boolean;
    };
    teams?: {
      view_teams?: boolean;
      create_teams?: boolean;
      edit_teams?: boolean;
      delete_teams?: boolean;
      manage_team_members?: boolean;
      assign_team_leads?: boolean;
    };
    departments?: {
      view_departments?: boolean;
      create_departments?: boolean;
      edit_departments?: boolean;
      delete_departments?: boolean;
      move_departments?: boolean;
      assign_team_to_department?: boolean;
    };
    listings?: {
      create?: boolean;
      edit_own?: boolean;
      edit_any?: boolean;
      delete?: boolean;
      approve?: boolean;
      view_all?: boolean;
      max_approval_amount?: number;
    };
    analytics?: {
      view_own?: boolean;
      view_own_team?: boolean;
      view_department?: boolean;
      view_company?: boolean;
    };
    settings?: {
      manage_company?: boolean;
      manage_roles?: boolean;
      manage_permissions?: boolean;
      view_settings?: boolean;
    };
  };
}

