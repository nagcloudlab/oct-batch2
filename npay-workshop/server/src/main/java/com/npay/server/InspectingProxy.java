package com.npay.server;

import jakarta.servlet.http.HttpServletRequest;
import java.io.FileInputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.security.cert.CertificateFactory;
import java.util.List;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The attacker's side of the demo (profile "proxy", port 8444): an inspecting proxy, like Charles or mitmproxy.
 * The app's TLS ends here, so it reads everything, then forwards to the real server.
 * It only works on a device that trusts the proxy's root certificate, and only if the app doesn't pin.
 */
@RestController
@Profile("proxy")
public class InspectingProxy {
    private static final List<String> HEADERS = List.of("Authorization", "Content-Type", "Accept", "Idempotency-Key");
    private final HttpClient upstream;
    private final String target;

    InspectingProxy(@Value("${npay.upstream:https://localhost:8443}") String target,
                    @Value("${npay.upstream-ca:../certs/ca.crt}") String caFile) throws Exception {
        this.target = target;
        var trust = KeyStore.getInstance(KeyStore.getDefaultType());
        trust.load(null, null);
        try (var in = new FileInputStream(caFile)) {
            trust.setCertificateEntry("npay", CertificateFactory.getInstance("X.509").generateCertificate(in));
        }
        var tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(trust);
        var tls = SSLContext.getInstance("TLS");
        tls.init(null, tmf.getTrustManagers(), null);
        this.upstream = HttpClient.newBuilder().sslContext(tls).build();
    }

    @RequestMapping("/**")
    ResponseEntity<byte[]> forward(HttpServletRequest request, @RequestBody(required = false) byte[] body) throws Exception {
        System.out.println("PROXY sees  " + request.getMethod() + " " + request.getRequestURI());
        var out = HttpRequest.newBuilder(URI.create(target + request.getRequestURI()))
                .method(request.getMethod(), body == null ? HttpRequest.BodyPublishers.noBody() : HttpRequest.BodyPublishers.ofByteArray(body));
        for (String h : HEADERS) {
            String v = request.getHeader(h);
            if (v != null) {
                out.header(h, v);
                if (h.equals("Authorization")) System.out.println("            Authorization: " + v);
            }
        }
        if (body != null) System.out.println("            body: " + new String(body, StandardCharsets.UTF_8));
        var answer = upstream.send(out.build(), HttpResponse.BodyHandlers.ofByteArray());
        System.out.println("            answer " + answer.statusCode() + ": " + new String(answer.body(), StandardCharsets.UTF_8));
        return ResponseEntity.status(answer.statusCode()).contentType(MediaType.APPLICATION_JSON).body(answer.body());
    }
}
