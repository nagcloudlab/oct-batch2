package com.npay.server;

import org.springframework.stereotype.Component;

/** Failures to show in class, switched with POST /admin/mode/{name} (see server-mode.sh). */
@Component
public class DemoMode {
    public enum Mode { NORMAL, SLOW, DOWN, LOSE }

    private volatile Mode mode = Mode.NORMAL;

    public Mode get() { return mode; }

    public void set(Mode mode) {
        this.mode = mode;
        System.out.println("-- mode: " + mode.name().toLowerCase());
    }

    /** LOSE: answer the next payment only after the app has given up (once). */
    void afterCharge() throws InterruptedException {
        if (mode == Mode.LOSE) {
            set(Mode.NORMAL);
            System.out.println("   (charged; holding the response for 8 s)");
            Thread.sleep(8_000);
        }
    }
}
