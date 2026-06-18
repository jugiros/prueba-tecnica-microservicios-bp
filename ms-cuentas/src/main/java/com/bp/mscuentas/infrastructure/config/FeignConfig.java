package com.bp.mscuentas.infrastructure.config;

import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableFeignClients(basePackages = "com.bp.mscuentas.infrastructure.adapter.out.feign")
public class FeignConfig {
}