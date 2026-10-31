package com.npay.server;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import java.time.Instant;
import java.util.List;

/** The JSON the API sends and receives. Field names go out in snake_case (application.properties). */
public final class Api {
    private Api() {}

    public record Account(String id, String owner, long balancePaise, String currency, Instant updatedAt) {}

    public record Payment(String id, String recipient, long amountPaise, long balanceAfterPaise, Instant createdAt) {}

    public record PaymentList(List<Payment> payments) {}

    public record CreatePayment(
            @NotBlank @Pattern(regexp = "[a-z0-9.]+@[a-z]+") String recipient,
            @Positive long amountPaise) {}

    public record Login(@NotBlank String username, @NotBlank String password) {}

    public record Refresh(String refreshToken) {}

    public record Tokens(String accessToken, String refreshToken, String tokenType, long expiresIn) {}

    public record Error(String code, String message) {}

    public record ErrorBody(Error error) {
        public static ErrorBody of(String code, String message) {
            return new ErrorBody(new Error(code, message));
        }
    }
}
