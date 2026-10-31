package com.npay.server;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.Map;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

/**
 * Who is signed in: short-lived access tokens, and refresh tokens that work once (rotation).
 * Every token belongs to the session (family) its sign-in started. With reuse detection on, a refresh token
 * that comes back after it was spent ends that whole session: the thief's tokens and the owner's alike.
 */
@Service
public class Sessions {
    public enum Check { VALID, EXPIRED, UNKNOWN }

    private final Map<String, Instant> access = new HashMap<>();   // access token -> expiry
    private final Map<String, Integer> family = new HashMap<>();   // any token -> the session it belongs to
    private final Set<String> refresh = new HashSet<>();           // refresh tokens not yet used
    private final Set<String> spent = new HashSet<>();             // refresh tokens already used
    private int nextFamily = 1;
    private boolean reuseDetection = false;
    private final SecureRandom random = new SecureRandom();
    private final long accessSeconds;

    Sessions(@Value("${npay.access-seconds:60}") long accessSeconds) {
        this.accessSeconds = accessSeconds;
    }

    public synchronized Api.Tokens login(Api.Login body) {
        // demo account; a real server compares a salted password hash
        if (!"asha".equals(body.username()) || !"npay-demo".equals(body.password())) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "invalid_credentials", "Wrong username or password");
        }
        return issue(nextFamily++);
    }

    /** A refresh token works once: using it returns a new pair and spends the old one. */
    public synchronized Api.Tokens refresh(String token) {
        if (token != null && refresh.remove(token)) {
            spent.add(token);
            return issue(family.get(token));
        }
        if (reuseDetection && token != null && spent.contains(token)) {
            endFamily(family.get(token));
            System.out.println("-- reuse: " + shortToken(token) + " was already spent; session " + family.get(token) + " ended");
        }
        throw new ApiException(HttpStatus.UNAUTHORIZED, "invalid_grant", "Refresh token is not valid");
    }

    /** Demo: turn reuse detection on or off. */
    public synchronized void setReuseDetection(boolean on) {
        reuseDetection = on;
    }

    public synchronized void logout(String refreshToken, String accessToken) {
        refresh.remove(refreshToken);
        access.remove(accessToken);
    }

    public synchronized Check check(String token) {
        Instant expiry = token == null ? null : access.get(token);
        if (expiry == null) return Check.UNKNOWN;
        return Instant.now().isBefore(expiry) ? Check.VALID : Check.EXPIRED;
    }

    /** Demo: every access token expires now (refresh tokens still work). */
    public synchronized void expireAccess() {
        access.replaceAll((token, expiry) -> Instant.EPOCH);
    }

    /** Demo: every session ends; the app must sign in again. */
    public synchronized void revokeAll() {
        access.clear();
        refresh.clear();
        spent.clear();
        family.clear();
    }

    private void endFamily(int f) {
        access.keySet().removeIf(t -> family.get(t) == f);
        refresh.removeIf(t -> family.get(t) == f);
    }

    private Api.Tokens issue(int f) {
        String a = "at_" + hex(8), r = "rt_" + hex(12);
        access.put(a, Instant.now().plusSeconds(accessSeconds));
        refresh.add(r);
        family.put(a, f);
        family.put(r, f);
        return new Api.Tokens(a, r, "Bearer", accessSeconds);
    }

    private String hex(int bytes) {
        byte[] b = new byte[bytes];
        random.nextBytes(b);
        return HexFormat.of().formatHex(b);
    }

    static String shortToken(String t) {
        return t == null ? "none" : t.substring(0, Math.min(7, t.length())) + "…";
    }
}
