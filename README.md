# 🧩 Clúster MariaDB Galera con Alta Disponibilidad

## 📌 Descripción

Este laboratorio implementa un clúster de base de datos altamente disponible utilizando:

- **MariaDB Galera Cluster** — replicación síncrona entre nodos
- **HAProxy** — balanceo de carga entre los nodos de base de datos
- **Keepalived** — IP virtual con protocolo VRRP para failover
- **Terraform** — infraestructura como código (IaC)
- **Ansible** — configuración automática de todos los componentes

El sistema permite tolerancia a fallos y continuidad del servicio ante la caída de uno o más nodos del clúster.

---

## 🏗️ Arquitectura

```
                        ┌─────────────────────┐
                        │   IP Virtual VRRP   │
                        │  192.168.100.100    │
                        │     Keepalived      │
                        └────────┬────────────┘
                                 │
                        ┌────────▼────────────┐
                        │       HAProxy       │
                        │    Puerto: 3307     │
                        └──┬──────┬───────┬───┘
                           │      │       │
              ┌────────────▼┐ ┌───▼─────┐ ┌▼────────────┐
              │     db1     │ │   db2   │ │     db3     │
              │192.168.100.11│ │192.168.100.12│ │192.168.100.13│
              │  MariaDB    │ │ MariaDB │ │  MariaDB    │
              └─────────────┘ └─────────┘ └─────────────┘
                        ◄──── Galera Sync ────►
```

### Nodos de base de datos

| Nodo | IP              | Rol        |
|------|-----------------|------------|
| db1  | 192.168.100.11  | Galera Node |
| db2  | 192.168.100.12  | Galera Node |
| db3  | 192.168.100.13  | Galera Node |

### Red

| Recurso       | Valor               |
|---------------|---------------------|
| IP Virtual    | 192.168.100.100     |
| Puerto acceso | 3307 (HAProxy → MariaDB) |

---

## ⚙️ Requisitos

Antes de comenzar, asegúrate de contar con lo siguiente:

| Requisito | Versión / Detalle |
|-----------|-------------------|
| Terraform | ≥ 1.0 |
| Ansible   | Cualquier versión reciente |
| QEMU/KVM + libvirt | Instalado y habilitado |
| Clave SSH | Configurada en `~/.ssh/id_rsa` |
| Usuario en VMs | Con permisos `sudo` |

---

## 🚀 Despliegue

### 1. Inicializar Terraform

```bash
terraform init
```

### 2. Crear la infraestructura

```bash
terraform apply -auto-approve
```

### 3. Obtener inventario para Ansible

```bash
terraform output ansible_inventory_hint
```

> Copiar el resultado en el archivo `inventory.ini`.

### 4. Ejecutar el script limpia.sh para limpiar reglas ssh

```bash
chmod +x limpia.sh

./limpia.sh
```

### 5. Ejecutar configuración del clúster

```bash
ansible-playbook -i inventory.ini galera.yml
```

---

## 🧹 Limpieza del entorno

Para destruir toda la infraestructura creada:

```bash
terraform destroy -auto-approve
```

---
