export const CustomIds = {
  start: "card:start",
  answer(submissionId: string, stage: string): string {
    return checkedCustomId(`card:answer:${submissionId}:${stage}`);
  },
  submit(submissionId: string): string {
    return `card:submit:${submissionId}`;
  },
  cancel(submissionId: string): string {
    return `card:cancel:${submissionId}`;
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

function checkedCustomId(value: string): string {
  if (value.length > 100) throw new Error("Schema field ID is too long for a Discord component");
  return value;
}

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
