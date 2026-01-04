import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PermissionsService, UserPermissionContext } from '../../company/permissions.service';

export const REQUIRE_PERMISSION_KEY = 'requirePermission';

export interface RequirePermissionMetadata {
  action: 'manage_structure' | 'approve_listing' | 'access_settings';
  targetType?: 'department' | 'team' | 'user' | 'listing';
  getTargetId?: (request: any) => string; // Function to extract target ID from request
}

@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private permissionsService: PermissionsService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const metadata = this.reflector.get<RequirePermissionMetadata>(
      REQUIRE_PERMISSION_KEY,
      context.getHandler(),
    );

    if (!metadata) {
      return true; // No permission requirement
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user; // Set by JWT guard

    if (!user || !user.userId || !user.companyId) {
      return false;
    }

    // Get user's permission context
    let permissionContext: UserPermissionContext;
    try {
      permissionContext = await this.permissionsService.getUserPermissionContext(
        user.userId,
        user.companyId,
      );
    } catch {
      return false;
    }

    // Store permission context in request for use in controllers
    request.permissionContext = permissionContext;

    const targetId = metadata.getTargetId ? metadata.getTargetId(request) : undefined;

    // Get listing amount if action is approve_listing
    let listingAmount: number | undefined;
    if (metadata.action === 'approve_listing' && request.body?.estimatedValue) {
      listingAmount = parseFloat(request.body.estimatedValue) || undefined;
    }

    return await this.permissionsService.canPerformAction(
      permissionContext,
      metadata.action,
      metadata.targetType,
      targetId,
      listingAmount,
    );
  }
}


