export const CustomIds = {
  start: "card:start",
  continue(submissionId: string, stage: string): string {
    return `card:continue:${submissionId}:${stage}`;
  },
  step(submissionId: string, stage: string): string {
    return `card:step:${submissionId}:${stage}`;
  },
  approve(submissionId: string): string {
    return `card:approve:${submissionId}`;
  },
  deny(submissionId: string): string {
    return `card:deny:${submissionId}`;
  },
  denial(submissionId: string): string {
    return `card:denial:${submissionId}`;
  },
};

export interface ParsedCustomId {
  action: string;
  submissionId?: string;
  stage?: string;
}

export function parseCustomId(value: string): ParsedCustomId | null {
  const [namespace, action, submissionId, stage] = value.split(":");
  if (namespace !== "card" || !action) return null;
  return {
    action,
    ...(submissionId ? { submissionId } : {}),
    ...(stage ? { stage } : {}),
  };
}
