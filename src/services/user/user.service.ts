import { UserRepository } from '../../database/repositories/user.repository';
import { SessionRepository } from '../../database/repositories/session.repository';
import type { UserTable } from '../../database/schema';

const userRepository = new UserRepository();
const sessionRepository = new SessionRepository();

class UserService {
  /**
   * Get user by ID
   */
  async getUserById(userId: string): Promise<UserTable | null> {
    const user = await userRepository.findById(userId);
    return user ?? null;
  }

  /**
   * Get user by email
   */
  async getUserByEmail(email: string): Promise<UserTable | null> {
    const user = await userRepository.findByEmail(email);
    return user ?? null;
  }

  /**
   * Get user's active sessions
   */
  async getUserSessions(userId: string) {
    return sessionRepository.getUserSessions(userId);
  }

  /**
   * Upsert user (create or update)
   */
  async upsertUser(user: {
    email: string;
    name: string | null;
    picture: string | null;
    provider: string;
    provider_id: string;
  }): Promise<UserTable> {
    return userRepository.upsertUser(user);
  }
}

export const userService = new UserService();



