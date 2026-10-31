package com.npay.server;

/** Paise → "₹1,500.50" with Indian digit grouping (the app's src/money.ts does the same). */
final class Money {
    private Money() {}

    static String format(long paise) {
        String rupees = Long.toString(paise / 100);
        String last3 = rupees.length() > 3 ? rupees.substring(rupees.length() - 3) : rupees;
        String rest = rupees.length() > 3 ? rupees.substring(0, rupees.length() - 3) : "";
        StringBuilder grouped = new StringBuilder();
        for (int i = 0; i < rest.length(); i++) {
            if (i > 0 && (rest.length() - i) % 2 == 0) grouped.append(',');
            grouped.append(rest.charAt(i));
        }
        String head = grouped.isEmpty() ? last3 : grouped + "," + last3;
        return "₹" + head + "." + String.format("%02d", paise % 100);
    }
}
