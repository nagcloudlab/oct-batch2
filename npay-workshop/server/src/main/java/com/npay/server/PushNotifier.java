package com.npay.server;

import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Lab 6 · tells the user about a payment with a notification.
 *
 * Delivery: with a free Apple ID there is no APNs, so this runs `xcrun simctl push` to the booted iOS Simulator on
 * this Mac. With a paid account, this one method would instead POST the same payload to APNs
 * (https://api.sandbox.push.apple.com/3/device/<device token>), signed with the team's .p8 key (see lab6.md).
 */
@Component
public class PushNotifier {
    private final boolean enabled;
    private final String bundleId;
    private final Set<String> notified = new HashSet<>();   // each payment is announced once (retries reuse the id)

    PushNotifier(@Value("${npay.push.simulator:true}") boolean enabled,
                 @Value("${npay.push.bundle-id:com.npay.workshop}") String bundleId) {
        this.enabled = enabled;
        this.bundleId = bundleId;
    }

    /** Called by /admin/reset: payment ids start again at pay_101, so forget which ones were announced. */
    public void reset() {
        synchronized (notified) {
            notified.clear();
        }
    }

    public void paymentSent(Api.Payment p) {
        synchronized (notified) {
            if (!enabled || !notified.add(p.id())) {
                return;
            }
        }
        String payload = """
            {"aps":{"alert":{"title":"Payment sent","body":"%s to %s · balance %s"},"sound":"default"},\
            "payment":{"id":"%s","recipient":"%s","amount_paise":%d,"balance_after_paise":%d,"created_at":"%s"}}"""
            .formatted(Money.format(p.amountPaise()), p.recipient(), Money.format(p.balanceAfterPaise()),
                       p.id(), p.recipient(), p.amountPaise(), p.balanceAfterPaise(), p.createdAt());
        CompletableFuture.runAsync(() -> deliver(p.id(), payload));   // the payment's HTTP answer doesn't wait
    }

    private void deliver(String id, String payload) {
        try {
            Process process = new ProcessBuilder("xcrun", "simctl", "push", "booted", bundleId, "-")
                .redirectErrorStream(true).start();
            try (OutputStream in = process.getOutputStream()) {
                in.write(payload.getBytes(StandardCharsets.UTF_8));
            }
            String out = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
            System.out.println("   push " + id + " → Simulator: " + out);
        } catch (Exception e) {
            System.out.println("   push " + id + " failed: " + e.getMessage());
        }
    }
}
