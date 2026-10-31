package com.npay.server;

import jakarta.validation.Valid;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** NPay's REST API: two resources, the account and its payments. */
@RestController
@Profile("!proxy")   // Lab 10: the proxy profile is a different program (InspectingProxy)
public class PaymentController {
    private final Bank bank;
    private final DemoMode mode;
    private final PushNotifier notifier;

    PaymentController(Bank bank, DemoMode mode, PushNotifier notifier) {
        this.bank = bank;
        this.mode = mode;
        this.notifier = notifier;
    }

    @GetMapping("/v1/account")
    Api.Account account() {
        return bank.account();
    }

    @GetMapping("/v1/payments")
    Api.PaymentList payments() {
        return new Api.PaymentList(bank.payments());
    }

    @PostMapping("/v1/payments")
    @ResponseStatus(HttpStatus.CREATED)
    Api.Payment pay(@RequestHeader(name = "Idempotency-Key", required = false) String key,
                    @Valid @RequestBody Api.CreatePayment body) throws InterruptedException {
        var payment = bank.pay(body, key);
        notifier.paymentSent(payment);   // Lab 6: "Payment sent" notification, once per payment
        mode.afterCharge();   // "lose" mode: the money moved, the answer arrives too late
        return payment;
    }
}
