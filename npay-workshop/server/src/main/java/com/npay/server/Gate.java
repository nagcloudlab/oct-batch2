package com.npay.server;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.Set;
import org.springframework.context.annotation.Profile;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/** Runs before every /v1 request: logs it, applies the demo mode, checks the access token. */
@Configuration
@Profile("!proxy")   // Lab 10: the proxy profile is a different program (InspectingProxy)
public class Gate implements HandlerInterceptor, WebMvcConfigurer {
    static final Set<String> OPEN = Set.of("/v1/login", "/v1/token", "/v1/logout");
    private final DemoMode mode;
    private final Sessions sessions;

    Gate(DemoMode mode, Sessions sessions) {
        this.mode = mode;
        this.sessions = sessions;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(this).addPathPatterns("/v1/**");
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String auth = request.getHeader("Authorization");
        String token = auth != null && auth.startsWith("Bearer ") ? auth.substring(7) : null;
        String key = request.getHeader("Idempotency-Key");
        System.out.println("-> " + request.getMethod() + " " + request.getRequestURI()
                + (token == null ? "" : "  Bearer " + Sessions.shortToken(token))
                + (key == null ? "" : "  Idempotency-Key: " + key.substring(0, 8) + "…"));
        // Lab 9: nothing from this API may be stored in a cache: token responses carry the refresh token, and the
        // app's HTTP layer (iOS URLCache, used by React Native's fetch) would otherwise write it to Library/Caches.
        response.setHeader("Cache-Control", "no-store");
        switch (mode.get()) {
            case SLOW -> Thread.sleep(8_000);
            case DOWN -> { return refuse(response, 503, "unavailable", "NPay is down for maintenance"); }
            default -> { }
        }
        if (OPEN.contains(request.getRequestURI())) {
            return true;
        }
        return switch (sessions.check(token)) {
            case VALID -> true;
            case EXPIRED -> refuse(response, 401, "token_expired", "Access token expired");
            case UNKNOWN -> refuse(response, 401, "unauthorized", "Missing or invalid token");
        };
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        System.out.println("<- " + response.getStatus());
    }

    private boolean refuse(HttpServletResponse response, int status, String code, String message) throws Exception {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"error\":{\"code\":\"" + code + "\",\"message\":\"" + message + "\"}}");
        System.out.println("<- " + status + " " + code);
        return false;
    }
}
