# Generate technical manual data

Analyze the project completely and extract all real technical information to populate a professional technical manual. Do not invent anything. If something is not in the source code, write exactly: "No determinado desde el código fuente".

**Usage:**
- `/user:tech-manual` — analyze the current project

---

## Step 1 — Full exploration

Run these commands to discover all relevant files:

```bash
find . -type f \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" \
  -o -name "*.env*" -o -name "*.config*" -o -name "Dockerfile*" \
  -o -name "*.csproj" -o -name "*.sln" -o -name "*.toml" \
  -o -name "*.xml" -o -name "*.gradle" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -not -path "*/bin/*" -not -path "*/obj/*" -not -path "*/dist/*"

find . -type d \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -not -path "*/bin/*" -not -path "*/obj/*"
```

Read ALL files found before answering. Pay special attention to:
- Configuration files: `appsettings*.json`, `config.yaml`, `.env.example`, `settings.py`, `application.properties`
- All `package.json` / `*.csproj` / `requirements.txt` / `pom.xml`
- `docker-compose.yml` and all Dockerfiles
- Database migration files (`migrations/`, `flyway/`, `alembic/`)
- Data models/entities (`models/`, `entities/`, `schemas/`)
- Queue/exchange definitions (RabbitMQ, Kafka, SQS, etc.)
- Controllers, routes, endpoints
- DB seed or initial config files
- CI/CD configs (`.github/workflows/`, `.gitlab-ci.yml`, `azure-pipelines.yml`)
- `CLAUDE.md` if present — architecture and conventions defined there take precedence

---

## Step 2 — Identify all projects

This repository may have multiple projects. Identify EACH one:
- REST APIs, GraphQL, gRPC
- Consumers / Workers / Listeners (RabbitMQ, Kafka, SQS, etc.)
- Jobs / Scheduled tasks / Cron
- Frontends (web, mobile, admin panel)
- Shared libraries / SDKs
- Gateways / Proxies
- Notification services

---

## Step 3 — Output

Respond with ONLY the following JSON. No markdown, no text before or after, only the JSON:

```json
{
  "meta": {
    "nombre_solucion": "",
    "descripcion_una_linea": "",
    "version": "",
    "tipo_arquitectura": "Monolito | Microservicios | Modular monolith | etc",
    "repositorio": "",
    "lenguajes_principales": [],
    "fecha_analisis": ""
  },

  "proyectos": [
    {
      "id": "api-principal",
      "nombre": "",
      "tipo": "API REST | Consumer | Worker | Frontend | Scheduler | Library | Gateway",
      "descripcion": "",
      "ruta_en_repo": "",
      "framework": "",
      "puerto_defecto": "",
      "punto_entrada": "",
      "comando_dev": "",
      "comando_produccion": "",
      "responsabilidades": [],
      "dependencias_entre_proyectos": []
    }
  ],

  "descripcion_producto": {
    "proposito_detallado": "",
    "dominio_negocio": "",
    "actores_del_sistema": [
      {
        "rol": "",
        "descripcion": "",
        "como_se_autentica": ""
      }
    ]
  },

  "infraestructura_y_servicios": {
    "bases_de_datos": [
      {
        "motor": "",
        "version": "",
        "proposito": "",
        "nombre_bd_defecto": "",
        "connection_string_env_var": "",
        "connection_string_formato": "",
        "connection_string_ejemplo": "",
        "orm_libreria": "",
        "version_orm": "",
        "pool_conexiones": {
          "min": "",
          "max": "",
          "timeout_ms": ""
        },
        "notas_produccion": ""
      }
    ],
    "cache": [
      {
        "tecnologia": "",
        "version": "",
        "proposito": "",
        "connection_string_env_var": "",
        "connection_string_ejemplo": "",
        "ttl_defecto": "",
        "estrategia_eviccion": ""
      }
    ],
    "message_broker": [
      {
        "tecnologia": "",
        "version": "",
        "proposito": "",
        "connection_string_env_var": "",
        "connection_string_ejemplo": "",
        "exchanges": [
          {
            "nombre": "",
            "tipo": "direct | topic | fanout | headers",
            "durable": true,
            "proposito": ""
          }
        ],
        "queues": [
          {
            "nombre": "",
            "exchange": "",
            "routing_key": "",
            "durable": true,
            "dead_letter_queue": "",
            "prefetch": "",
            "proposito": "",
            "proyecto_producer": "",
            "proyecto_consumer": ""
          }
        ],
        "mensajes": [
          {
            "nombre": "",
            "cola": "",
            "estructura": "",
            "cuando_se_publica": ""
          }
        ]
      }
    ],
    "almacenamiento_archivos": [
      {
        "tecnologia": "",
        "proposito": "",
        "env_vars": [],
        "configuracion": ""
      }
    ],
    "servicios_externos": [
      {
        "nombre": "",
        "tipo": "",
        "proposito": "",
        "env_vars_requeridas": [
          {
            "variable": "",
            "requerida": true,
            "descripcion": "",
            "como_obtenerla": ""
          }
        ],
        "critico_para_arranque": true,
        "falla_gracefully": false,
        "notas": ""
      }
    ]
  },

  "configuracion": {
    "descripcion": "",
    "fuentes_config": [],
    "variables_entorno": [
      {
        "variable": "",
        "seccion": "",
        "tipo": "string | number | boolean | url | secret | connection-string | json",
        "requerida": true,
        "proyecto_que_la_usa": [],
        "descripcion": "",
        "valor_ejemplo": "",
        "valor_defecto": "",
        "validaciones": "",
        "notas": ""
      }
    ],
    "tabla_configuracion_bd": {
      "existe": false,
      "descripcion": "",
      "nombre_tabla": "",
      "campos": [
        {
          "campo_clave": "",
          "tipo_valor": "",
          "descripcion": "",
          "valor_defecto": "",
          "impacto": "",
          "requerido": true,
          "ejemplo": ""
        }
      ],
      "como_se_carga": "",
      "como_modificar": ""
    },
    "archivos_configuracion": [
      {
        "archivo": "",
        "ambiente": "",
        "secciones_importantes": [
          {
            "seccion": "",
            "campos_configurables": [
              {
                "campo": "",
                "tipo": "",
                "descripcion": "",
                "valor_defecto": "",
                "valores_posibles": []
              }
            ]
          }
        ]
      }
    ]
  },

  "modelo_datos": {
    "descripcion_general": "",
    "entidades": [
      {
        "nombre": "",
        "bd": "",
        "descripcion": "",
        "campos": [
          {
            "nombre": "",
            "tipo": "",
            "nullable": false,
            "pk": false,
            "fk": false,
            "referencia": "",
            "unico": false,
            "indexado": false,
            "descripcion": "",
            "valor_defecto": ""
          }
        ],
        "indices": [
          {
            "nombre": "",
            "campos": [],
            "tipo": "",
            "unico": false,
            "proposito": ""
          }
        ],
        "relaciones": [
          {
            "tipo": "OneToMany | ManyToOne | ManyToMany | OneToOne",
            "entidad_relacionada": "",
            "campo_fk": "",
            "on_delete": "CASCADE | SET NULL | RESTRICT",
            "descripcion": ""
          }
        ]
      }
    ],
    "migraciones": {
      "herramienta": "",
      "ubicacion": "",
      "comando_ejecutar": "",
      "comando_crear": "",
      "comando_revertir": "",
      "notas_produccion": ""
    },
    "seeds_datos_iniciales": {
      "existen": false,
      "ubicacion": "",
      "comando": "",
      "que_inserta": ""
    },
    "diagrama_er_mermaid": ""
  },

  "arquitectura": {
    "patron": "",
    "descripcion_tecnica": "",
    "flujo_request_principal": "",
    "diagrama_arquitectura_mermaid": "",
    "diagrama_flujo_autenticacion_mermaid": "",
    "diagrama_flujo_negocio_principal_mermaid": "",
    "diagrama_deployment_mermaid": ""
  },

  "apis": {
    "base_url_dev": "",
    "base_url_prod": "",
    "versionado": "",
    "autenticacion": "",
    "formato_error_estandar": "",
    "paginacion": "",
    "grupos": [
      {
        "nombre": "",
        "prefijo_ruta": "",
        "proyecto": "",
        "endpoints": [
          {
            "metodo": "GET | POST | PUT | PATCH | DELETE",
            "ruta": "",
            "nombre": "",
            "autenticacion_requerida": true,
            "roles_permitidos": [],
            "descripcion": "",
            "headers": [
              { "nombre": "", "valor": "", "requerido": true }
            ],
            "path_params": [
              { "nombre": "", "tipo": "", "descripcion": "" }
            ],
            "query_params": [
              { "nombre": "", "tipo": "", "requerido": false, "defecto": "", "descripcion": "" }
            ],
            "body": {
              "content_type": "application/json",
              "campos": [
                {
                  "nombre": "",
                  "tipo": "",
                  "requerido": true,
                  "descripcion": "",
                  "validaciones": ""
                }
              ],
              "ejemplo": ""
            },
            "respuesta_200": {
              "descripcion": "",
              "ejemplo": ""
            },
            "errores": [
              { "codigo": "", "cuando": "" }
            ]
          }
        ]
      }
    ]
  },

  "modulos": [
    {
      "nombre": "",
      "proyecto": "",
      "ruta_codigo": "",
      "descripcion": "",
      "entidades_que_maneja": [],
      "dependencias": [],
      "funcionalidades": [
        {
          "nombre": "",
          "descripcion": "",
          "reglas_negocio": [],
          "efectos_secundarios": []
        }
      ]
    }
  ],

  "requerimientos_sistema": {
    "hardware": [
      {
        "ambiente": "",
        "cpu": "",
        "ram": "",
        "disco": "",
        "red": ""
      }
    ],
    "software_servidor": [
      {
        "nombre": "",
        "version_minima": "",
        "version_recomendada": "",
        "notas": ""
      }
    ],
    "puertos_requeridos": [
      {
        "puerto": "",
        "protocolo": "TCP",
        "servicio": "",
        "proyecto": "",
        "expuesto_externamente": true
      }
    ],
    "navegadores": {
      "aplica": false,
      "compatibles": [],
      "resolucion_minima": "",
      "notas": ""
    }
  },

  "instalacion": {
    "prerequisitos": [
      {
        "herramienta": "",
        "version_minima": "",
        "verificacion": "",
        "url_instalacion": ""
      }
    ],
    "pasos_entorno_desarrollo": [
      {
        "numero": 1,
        "titulo": "",
        "descripcion": "",
        "comandos": [],
        "resultado_esperado": "",
        "posibles_errores": ""
      }
    ],
    "pasos_entorno_produccion": [
      {
        "numero": 1,
        "titulo": "",
        "descripcion": "",
        "comandos": [],
        "resultado_esperado": "",
        "posibles_errores": ""
      }
    ],
    "verificacion_instalacion": {
      "pasos": []
    }
  },

  "seguridad": {
    "autenticacion": {
      "mecanismo": "",
      "implementacion": "",
      "duracion_token": "",
      "refresh_token": {
        "existe": false,
        "duracion": "",
        "estrategia": ""
      }
    },
    "autorizacion": {
      "modelo": "RBAC | ABAC | ACL",
      "roles_del_sistema": [],
      "como_se_implementa": ""
    },
    "validacion_inputs": "",
    "encriptacion": "",
    "rate_limiting": {
      "existe": false,
      "configuracion": "",
      "env_var": ""
    },
    "cors": {
      "configurado": false,
      "origenes_permitidos": "",
      "notas": ""
    },
    "consideraciones_produccion": []
  },

  "despliegue": {
    "estrategia": "",
    "docker": {
      "usa_docker": false,
      "servicios": [
        {
          "nombre": "",
          "imagen": "",
          "build_context": "",
          "puertos": [],
          "env_vars": [],
          "volumes": [],
          "depends_on": [],
          "healthcheck": "",
          "descripcion": ""
        }
      ],
      "redes": [],
      "volumenes_persistentes": [],
      "comando_levantar_dev": "",
      "comando_levantar_prod": "",
      "comando_ver_logs": "",
      "comando_detener": ""
    },
    "ci_cd": {
      "herramienta": "",
      "ubicacion_config": "",
      "pipeline": [
        {
          "stage": "",
          "descripcion": "",
          "comando": ""
        }
      ]
    },
    "ambientes": [
      {
        "nombre": "",
        "rama_git": "",
        "url": "",
        "diferencias_config": ""
      }
    ]
  },

  "monitoreo_y_logs": {
    "logging": {
      "libreria": "",
      "nivel_defecto": "",
      "formato": "",
      "destino": "",
      "env_var_nivel": ""
    },
    "health_checks": [
      {
        "endpoint": "",
        "proyecto": "",
        "que_verifica": ""
      }
    ],
    "metricas": ""
  },

  "troubleshooting": [
    {
      "problema": "",
      "causa_probable": "",
      "solucion": "",
      "comandos_diagnostico": []
    }
  ],

  "recomendaciones": [
    {
      "categoria": "Seguridad | Performance | Escalabilidad | Mantenibilidad | Resiliencia",
      "prioridad": "Alta | Media | Baja",
      "descripcion": "",
      "justificacion": ""
    }
  ],

  "glosario": [
    {
      "termino": "",
      "definicion": ""
    }
  ]
}
```
