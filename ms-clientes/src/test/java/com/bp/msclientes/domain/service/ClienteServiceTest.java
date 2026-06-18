package com.bp.msclientes.domain.service;

import com.bp.msclientes.domain.model.Cliente;
import com.bp.msclientes.domain.port.out.ClienteRepositoryPort;
import com.bp.msclientes.shared.exception.BusinessException;
import com.bp.msclientes.shared.exception.ClienteNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("ClienteService - Pruebas unitarias")
class ClienteServiceTest {

    @Mock
    private ClienteRepositoryPort repositoryPort;

    @InjectMocks
    private ClienteService clienteService;

    private Cliente clienteValido;

    @BeforeEach
    void setUp() {
        clienteValido = new Cliente(
                1L,
                "Jose Lema",
                "Masculino",
                30,
                "1234567890",
                "Otavalo sn y principal",
                "098254785",
                "CLI001",
                "1234",
                true
        );
    }

    @Test
    @DisplayName("Debe crear un cliente exitosamente")
    void debeCrearClienteExitosamente() {
        when(repositoryPort.existePorClienteId(anyString())).thenReturn(false);
        when(repositoryPort.guardar(any(Cliente.class))).thenReturn(clienteValido);

        Cliente resultado = clienteService.crear(clienteValido);

        assertThat(resultado).isNotNull();
        assertThat(resultado.getNombre()).isEqualTo("Jose Lema");
        verify(repositoryPort).guardar(any(Cliente.class));
    }

    @Test
    @DisplayName("Debe lanzar excepcion cuando clienteId ya existe")
    void debeLanzarExcepcionSiClienteIdDuplicado() {
        when(repositoryPort.existePorClienteId(anyString())).thenReturn(true);

        assertThatThrownBy(() -> clienteService.crear(clienteValido))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Ya existe un cliente con el clienteId");
    }

    @Test
    @DisplayName("Debe obtener cliente por ID exitosamente")
    void debeObtenerClientePorId() {
        when(repositoryPort.buscarPorId(Long.valueOf(1L)))
                .thenReturn(Optional.of(clienteValido));

        Cliente resultado = clienteService.obtenerPorId(Long.valueOf(1L));

        assertThat(resultado).isNotNull();
        assertThat(resultado.getNombre()).isEqualTo("Jose Lema");
    }

    @Test
    @DisplayName("Debe lanzar ClienteNotFoundException cuando no existe")
    void debeLanzarExcepcionSiClienteNoExiste() {
        when(repositoryPort.buscarPorId(Long.valueOf(99L)))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> clienteService.obtenerPorId(Long.valueOf(99L)))
                .isInstanceOf(ClienteNotFoundException.class)
                .hasMessageContaining("Cliente no encontrado con id: 99");
    }

    @Test
    @DisplayName("Debe eliminar cliente exitosamente")
    void debeEliminarClienteExitosamente() {
        when(repositoryPort.buscarPorId(Long.valueOf(1L)))
                .thenReturn(Optional.of(clienteValido));

        clienteService.eliminar(Long.valueOf(1L));

        verify(repositoryPort).eliminar(Long.valueOf(1L));
    }
}