import { Injectable, NotFoundException } from '@nestjs/common';
import { db } from '../database';
import { companies, users, teams, departments, teamMembers, materialListings } from '../database/schema';
import { eq, and, isNull, sql, count } from 'drizzle-orm';
import { UpdateCompanyDto } from './dto/update-company.dto';

@Injectable()
export class CompanyService {
  async getCompany(companyId: string) {
    const [company] = await db
      .select()
      .from(companies)
      .where(and(eq(companies.id, companyId), isNull(companies.deletedAt)))
      .limit(1);

    if (!company) {
      throw new NotFoundException('Company not found');
    }

    // Get company stats
    const [stats] = await db
      .select({
        totalMembers: sql<number>`COUNT(DISTINCT ${users.id})::int`,
        unassignedMembers: sql<number>`COUNT(DISTINCT CASE WHEN NOT EXISTS (
          SELECT 1 FROM ${teamMembers} WHERE ${teamMembers.userId} = ${users.id}
        ) THEN ${users.id} END)::int`,
        totalTeams: sql<number>`COUNT(DISTINCT ${teams.id})::int`,
        totalDepartments: sql<number>`COUNT(DISTINCT ${departments.id})::int`,
      })
      .from(users)
      .leftJoin(teams, eq(teams.companyId, companyId))
      .leftJoin(departments, eq(departments.companyId, companyId))
      .where(and(eq(users.companyId, companyId), isNull(users.deletedAt), eq(users.status, 'active')));

    return {
      ...company,
      stats: {
        totalMembers: stats.totalMembers || 0,
        unassignedMembers: stats.unassignedMembers || 0,
        totalTeams: stats.totalTeams || 0,
        totalDepartments: stats.totalDepartments || 0,
      },
    };
  }

  async updateCompany(companyId: string, updateCompanyDto: UpdateCompanyDto) {
    const [company] = await db
      .select()
      .from(companies)
      .where(and(eq(companies.id, companyId), isNull(companies.deletedAt)))
      .limit(1);

    if (!company) {
      throw new NotFoundException('Company not found');
    }

    const [updatedCompany] = await db
      .update(companies)
      .set({
        name: updateCompanyDto.name,
        industry: updateCompanyDto.industry,
        size: updateCompanyDto.size,
        updatedAt: new Date(),
      })
      .where(eq(companies.id, companyId))
      .returning();

    return updatedCompany;
  }
}

