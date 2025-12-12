# Concepts

In this section, we'll explore the core concepts of Light Services, which include **Arguments**, **Steps**, **Outputs**, **Context**, and **Errors**.

## Service Execution Flow

When you call `MyService.run(args)`, the following happens:

```
┌─────────────────────────────────────────────────────────────┐
│                      Service.run(args)                       │
├─────────────────────────────────────────────────────────────┤
│  1. Load default values for arguments and outputs            │
│  2. Validate argument types                                  │
├─────────────────────────────────────────────────────────────┤
│  3. Begin database transaction (if use_transactions: true)   │
│     ┌─────────────────────────────────────────────────────┐ │
│     │  4. Execute steps in order                          │ │
│     │     - Skip if condition (if:/unless:) not met       │ │
│     │     - Stop if errors.break? is true                 │ │
│     │     - Stop if done! was called                      │ │
│     ├─────────────────────────────────────────────────────┤ │
│     │  5. On error → Rollback transaction                 │ │
│     │     On success → Commit transaction                 │ │
│     └─────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  6. Run steps marked with always: true                       │
│  7. Validate output types (if success)                       │
│  8. Copy errors/warnings to parent service (if in context)   │
├─────────────────────────────────────────────────────────────┤
│  9. Return service instance                                  │
│     - service.success? / service.failed?                     │
│     - service.outputs / service.errors                       │
└─────────────────────────────────────────────────────────────┘
```

## Arguments

Arguments are the inputs provided to a service when it is invoked. They can be validated by type, assigned default values, and be designated as optional or required.

[Read more about arguments](arguments.md)

## Steps

Steps are the fundamental units of work within a service, representing each individual task a service performs. They can be executed conditionally, retried (this feature is currently in development), or skipped.

[Read more about steps](steps.md)

## Outputs

Outputs are the results produced by a service upon its completion. They can have default values and be validated by type.

[Read more about outputs](outputs.md)

## Context

Context refers to the shared state that passes between services in a service chain, enabling the transfer of arguments and error states from one service to another.

[Read more about context](context.md)

## Errors

Errors are exceptions that occur during the execution of a service. When an error occurs, the execution halts, and all services within the same context chain stop as well. Each service is wrapped in a database transaction; if an error arises, the transaction is rolled back, although this can be disabled if necessary.

[Read more about errors](errors.md)

