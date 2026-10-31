package com.npay.server;

import org.springframework.http.HttpStatus;

/** A refusal the client should show: an HTTP status plus a machine-readable code. */
public class ApiException extends RuntimeException {
    final HttpStatus status;
    final String code;

    ApiException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }
}
