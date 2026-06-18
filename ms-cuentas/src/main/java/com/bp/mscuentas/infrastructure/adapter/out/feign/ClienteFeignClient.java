package com.bp.mscuentas.infrastructure.adapter.out.feign;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "ms-clientes", url = "${ms-clientes.url}")
public interface ClienteFeignClient {

    @GetMapping("/api/clientes/{id}")
    ClienteDTO obtenerClientePorId(@PathVariable Long id);

    @Getter
    @Setter
    @NoArgsConstructor
    class ClienteDTO {
        private Long id;
        private String clienteId;
        private String nombre;
        private String identificacion;
        private Boolean estado;
    }
}