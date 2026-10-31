package com.npay.server;

import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

/** Demo controls, not part of the API: switch a failure mode, or start over at ₹25,000. */
@RestController
@Profile("!proxy")   // Lab 10: the proxy profile is a different program (InspectingProxy)
public class AdminController {
    private final Bank bank;
    private final DemoMode mode;
    private final Sessions sessions;
    private final PushNotifier notifier;

    AdminController(Bank bank, DemoMode mode, Sessions sessions, PushNotifier notifier) {
        this.notifier = notifier;
        this.bank = bank;
        this.mode = mode;
        this.sessions = sessions;
    }

    @PostMapping("/admin/expire")
    String expire() {
        sessions.expireAccess();
        System.out.println("-- every access token expired");
        return "access tokens expired\n";
    }

    @PostMapping("/admin/revoke")
    String revoke() {
        sessions.revokeAll();
        System.out.println("-- every session revoked");
        return "sessions revoked\n";
    }

    @PostMapping("/admin/reuse/{state}")
    String reuse(@PathVariable String state) {
        sessions.setReuseDetection("on".equals(state));
        System.out.println("-- reuse detection " + state);
        return "reuse detection " + state + "\n";
    }

    @PostMapping("/admin/mode/{name}")
    String mode(@PathVariable String name) {
        mode.set(DemoMode.Mode.valueOf(name.toUpperCase()));
        return "mode " + name + "\n";
    }

    @PostMapping("/admin/reset")
    String reset() {
        bank.reset();
        notifier.reset();
        sessions.revokeAll();
        sessions.setReuseDetection(false);
        mode.set(DemoMode.Mode.NORMAL);
        return "reset: ₹25,000, signed out\n";
    }
}
