/**
 * Parses Indian-format income strings to integer rupees.
 * 
 * Examples:
 *   "20 lakh"  -> 2000000
 *   "20L"      -> 2000000
 *   "5 hazar"  -> 5000
 *   "5K"       -> 5000
 *   "1.5 cr"   -> 15000000
 *   "500000"   -> 500000
 */
export function parseIndianIncome(input: string | number): number | null {
  if (typeof input === 'number') {
    return Math.round(input);
  }

  const cleanInput = input.trim().toLowerCase().replace(/,/g, '');
  if (!cleanInput) return null;

  // Match digits with decimals and optional indian numeric units
  const match = cleanInput.match(/^(\d+(?:\.\d+)?)\s*(lakh|l|hazar|hazzar|hazaar|k|cr|crore)?$/);
  if (!match) return null;

  const number = parseFloat(match[1]);
  if (isNaN(number)) return null;

  const unit = match[2] || '';

  switch (unit) {
    case 'lakh':
    case 'l':
      return Math.round(number * 100000);
    case 'hazar':
    case 'hazzar':
    case 'hazaar':
    case 'k':
      return Math.round(number * 1000);
    case 'cr':
    case 'crore':
      return Math.round(number * 10000000);
    default:
      return Math.round(number);
  }
}

/**
 * Formats an integer rupee value into a readable Indian-style string (e.g., Lakhs, Crores).
 * 
 * Examples:
 *   2000000  -> "20 Lakh"
 *   5000     -> "5 Hazar"
 *   15500000 -> "1.55 Crore"
 */
export function formatIndianIncome(value: number, options?: { useEnglishK?: boolean }): string {
  if (!value || value <= 0) return '0';

  const formatDouble = (val: number): string => {
    if (Number.isInteger(val)) {
      return val.toString();
    }
    // Limit to 2 decimal places and trim trailing zeros
    return val.toFixed(2).replace(/\.?0+$/, '');
  };

  if (value >= 10000000) {
    return `${formatDouble(value / 10000000)} Crore`;
  } else if (value >= 100000) {
    return `${formatDouble(value / 100000)} Lakh`;
  } else if (value >= 1000) {
    const suffix = options?.useEnglishK ? 'K' : ' Hazar';
    return `${formatDouble(value / 1000)}${suffix}`;
  } else {
    return value.toString();
  }
}
