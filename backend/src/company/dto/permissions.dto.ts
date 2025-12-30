import { IsOptional, IsBoolean } from 'class-validator';
import { SimplifiedPermissions } from '../../database/schema';

/**
 * DTO for simplified permissions structure
 * Only 3 flags instead of 31+ granular permissions
 */
export class PermissionsDto implements SimplifiedPermissions {
  @IsOptional()
  @IsBoolean()
  canManageStructure?: boolean; // Create/edit teams, departments, add members

  @IsOptional()
  @IsBoolean()
  canApproveListings?: boolean; // Approve listings (up to maxApprovalAmount)

  @IsOptional()
  @IsBoolean()
  canAccessSettings?: boolean; // Access company settings
}
