// Money is integer paise (₹1 = 100 paise), never floating-point rupees.

/** "1500.50" -> 150050; null when the text is not a valid amount. */
export function parsePaise(text: string): number | null {
  const m = /^(\d{1,9})(?:\.(\d{1,2}))?$/.exec(text.trim());
  if (!m) {
    return null;
  }
  const paise = Number(m[1]) * 100 + Number((m[2] ?? '').padEnd(2, '0'));
  return paise > 0 ? paise : null;
}

/** 2500000 -> "₹25,000.00" (Indian digit grouping). */
export function formatPaise(paise: number): string {
  const rupees = Math.floor(paise / 100).toString();
  const last3 = rupees.slice(-3);
  const rest = rupees.slice(0, -3).replace(/\B(?=(\d{2})+(?!\d))/g, ',');
  const grouped = rest ? `${rest},${last3}` : last3;
  return `₹${grouped}.${String(paise % 100).padStart(2, '0')}`;
}
