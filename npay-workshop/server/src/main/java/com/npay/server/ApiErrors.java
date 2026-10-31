package com.npay.server;

import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/** Every error leaves the server in one shape: {"error": {"code": ..., "message": ...}}. */
@RestControllerAdvice
@Profile("!proxy")   // Lab 10: the proxy profile is a different program (InspectingProxy)
public class ApiErrors {

    @ExceptionHandler(ApiException.class)
    ResponseEntity<Api.ErrorBody> refused(ApiException e) {
        return ResponseEntity.status(e.status).body(Api.ErrorBody.of(e.code, e.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<Api.ErrorBody> invalid(MethodArgumentNotValidException e) {
        var field = e.getBindingResult().getFieldErrors().getFirst();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Api.ErrorBody.of("bad_request", field.getField() + " " + field.getDefaultMessage()));
    }
}
