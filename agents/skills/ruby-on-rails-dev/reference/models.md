# Models and domain behavior

## Cohesion

- Keep persistence-backed rules close to the model that owns the state.
- Extract a plain Ruby object when a workflow coordinates multiple owners or an external boundary; give it one public operation.
- Use concerns only for a cohesive capability shared by multiple real consumers. Avoid concerns as bins for unrelated callbacks and methods.
- Prefer named scopes and relations that remain composable. Do not materialize database-sized collections to filter in Ruby.

## Invariants

- Pair user-facing validations with database constraints for invariants that every write path must preserve.
- Use transactions for multi-record invariants. Keep network calls and slow work outside the transaction.
- Make lifecycle transitions explicit and test invalid transitions.
- Use callbacks for local lifecycle consequences that always apply; prefer an explicit workflow call for cross-model or external side effects.

## Associations and queries

- Declare dependency behavior deliberately; destructive cascades need product and retention intent.
- Avoid default scopes that silently change every query.
- Use `inverse_of`, counter caches, strict loading, and touch propagation only after confirming their semantics and cost.
- Keep tenant/account scope in the query that loads the record.

## Serialization

- Pass stable IDs to jobs rather than Active Record objects or large payloads.
- Cache IDs or primitive values instead of live Active Record instances.
- Treat serialized columns as versioned data contracts once persisted.

Primary sources: [Active Record Basics](https://guides.rubyonrails.org/active_record_basics.html), [Associations](https://guides.rubyonrails.org/association_basics.html), [Validations](https://guides.rubyonrails.org/active_record_validations.html).
