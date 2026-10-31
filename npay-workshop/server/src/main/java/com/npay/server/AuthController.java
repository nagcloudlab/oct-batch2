package com.npay.server;

import jakarta.validation.Valid;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Signing in, refreshing, signing out. These calls carry no access token. */
@RestController
@Profile("!proxy")   // Lab 10: the proxy profile is a different program (InspectingProxy)
public class AuthController {
    private final Sessions sessions;

    AuthController(Sessions sessions) { this.sessions = sessions; }

    @PostMapping("/v1/login")
    Api.Tokens login(@Valid @RequestBody Api.Login body) {
        var tokens = sessions.login(body);   // never log the password
        System.out.println("   signed in " + body.username() + ": access " + Sessions.shortToken(tokens.accessToken())
                + " (" + tokens.expiresIn() + " s), refresh " + Sessions.shortToken(tokens.refreshToken()));
        return tokens;
    }

    @PostMapping("/v1/token")
    Api.Tokens refresh(@RequestBody Api.Refresh body) {
        var tokens = sessions.refresh(body.refreshToken());
        System.out.println("   refresh " + Sessions.shortToken(body.refreshToken()) + " spent; new access "
                + Sessions.shortToken(tokens.accessToken()) + ", refresh " + Sessions.shortToken(tokens.refreshToken()));
        return tokens;
    }

    @PostMapping("/v1/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void logout(@RequestBody Api.Refresh body,
                @RequestHeader(name = "Authorization", required = false) String authorization) {
        String access = authorization != null && authorization.startsWith("Bearer ") ? authorization.substring(7) : null;
        sessions.logout(body.refreshToken(), access);
        System.out.println("   signed out: refresh " + Sessions.shortToken(body.refreshToken()) + " revoked");
    }
}
