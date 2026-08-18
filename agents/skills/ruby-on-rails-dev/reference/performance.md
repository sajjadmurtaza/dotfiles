# Rails performance and caching

Measure the request, query, job, or asset path before optimizing it. Retain a change only when the same measurement improves without correctness loss.

## Database first

- Count queries and inspect slow query shape before adding eager loading.
- Preserve a focused query-count or upper-bound regression assertion for repaired N+1 paths without pinning incidental exact SQL.
- Avoid unbounded relations, N+1 queries, repeated materialization, and Ruby filtering over database-sized data.
- Inspect execution plans and add indexes for evidenced access patterns.
- Use counter caches only when read savings justify write and backfill cost.

## Caching

- Give each cache explicit identity, ownership, expiry, and invalidation.
- Include tenant and authorization context in cache keys whenever output varies by scope; never let a shared fragment expose scoped data.
- Prefer Russian-doll fragment caching for server-rendered HTML when object timestamps model freshness.
- Cache IDs or primitive data, not Active Record instances.
- Measure hit rate, serialization cost, stampedes, and memory/storage growth.
- Confirm Solid Cache topology before assuming cache writes share or avoid an application transaction.

## Rails 8 assets and HTTP

- Propshaft fingerprints browser-ready assets; use bundling tools only when source transformation is actually needed.
- Preserve conditional GETs, compression, CDN/cache headers, and streaming behavior when changing response delivery.
- Thruster can provide HTTP/2 proxying, compression, caching, and X-Sendfile support in the generated production container; confirm the app's Dockerfile before relying on it.

Primary sources: [Caching with Rails](https://guides.rubyonrails.org/caching_with_rails.html), [Asset Pipeline](https://guides.rubyonrails.org/asset_pipeline.html), [Active Record Query Interface](https://guides.rubyonrails.org/active_record_querying.html), [Rails 8.0 Release Notes](https://guides.rubyonrails.org/8_0_release_notes.html).
