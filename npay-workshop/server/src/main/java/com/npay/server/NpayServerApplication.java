package com.npay.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;

/** The NPay demo backend: one account, signed in with tokens. Run: ./mvnw spring-boot:run -Dspring-boot.run.profiles=https */
@SpringBootApplication
public class NpayServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(NpayServerApplication.class, args);
    }

    @EventListener(ApplicationReadyEvent.class)
    void ready() {
        System.out.println("NPay server ready  (sign in: asha / npay-demo)");
    }
}
