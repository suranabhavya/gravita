import { SetMetadata } from '@nestjs/common';
import { RequirePermissionMetadata, REQUIRE_PERMISSION_KEY } from '../guards/permission.guard';

export const RequirePermission = (metadata: RequirePermissionMetadata) =>
  SetMetadata(REQUIRE_PERMISSION_KEY, metadata);


