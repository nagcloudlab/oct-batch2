package com.npay.server;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

/** One account, kept in memory. synchronized: one payment at a time checks and deducts. */
@Service
public class Bank {
    static final long LIMIT_PAISE = 10_000_000;  // ₹1,00,000 per payment

    private long balancePaise;
    private Instant updatedAt;
    private final List<Api.Payment> payments = new ArrayList<>();
    private final Map<String, Api.Payment> byKey = new HashMap<>();
    private int nextId;

    private final long startPaise;   // ₹25,000 by default; the staging profile starts with ₹10,000

    public Bank(@Value("${npay.start-paise:2500000}") long startPaise) {
        this.startPaise = startPaise;
        reset();
    }

    public synchronized void reset() {
        balancePaise = startPaise;
        payments.clear();
        byKey.clear();
        nextId = 101;
        updatedAt = Instant.parse("2026-10-29T09:41:00Z");
        payments.add(new Api.Payment("pay_100", "meera@npay", 45_000, startPaise, Instant.parse("2026-10-28T18:30:00Z")));
    }

    public synchronized Api.Account account() {
        return new Api.Account("acc_asha", "Asha", balancePaise, "INR", updatedAt);
    }

    public synchronized List<Api.Payment> payments() {
        return payments.reversed();   // newest first
    }

    /** The same Idempotency-Key returns the first result: a retry never charges twice. */
    public synchronized Api.Payment pay(Api.CreatePayment body, String key) {
        if (key != null && byKey.containsKey(key)) {
            return byKey.get(key);
        }
        if (body.amountPaise() > LIMIT_PAISE) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_CONTENT, "over_limit", "One payment can be at most ₹1,00,000");
        }
        if (body.amountPaise() > balancePaise) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_CONTENT, "insufficient_funds", "Not enough balance");
        }
        balancePaise -= body.amountPaise();
        updatedAt = Instant.now().truncatedTo(ChronoUnit.SECONDS);   // "2026-10-29T17:01:18Z"
        var payment = new Api.Payment("pay_" + nextId++, body.recipient(), body.amountPaise(), balancePaise, updatedAt);
        payments.add(payment);
        if (key != null) {
            byKey.put(key, payment);
        }
        return payment;
    }
}
