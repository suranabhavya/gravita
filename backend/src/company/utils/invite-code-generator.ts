/**
 * Generates a short, human-readable invite code
 * Format: XXXX-XXXX (e.g., BT4X-9KM2)
 */
export function generateInviteCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluding confusing chars (0, O, I, 1)
  const segments = [4, 4]; // Two segments of 4 characters each
  
  const code = segments
    .map((length) => {
      let segment = '';
      for (let i = 0; i < length; i++) {
        segment += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      return segment;
    })
    .join('-');
  
  return code;
}

