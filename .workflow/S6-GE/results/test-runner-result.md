# S6-GE test-runner result

## Command 1

```
Select-String -Path scripts\practice_session.sh -Pattern 'targets those missing elements' | Measure-Object | Select-Object -ExpandProperty Count
```

- Count: `0`
- Expected: `0`
- Result: **PASS**

## Command 2

```
Select-String -Path scripts\demo_session_2.sh -Pattern 'MEMORY.md' | Measure-Object | Select-Object -ExpandProperty Count
```

- Count: `1`
- Expected: `>0`
- Result: **PASS**

## Summary

| Command | Count | Pass/Fail |
|---------|-------|-----------|
| 1 | 0 | PASS |
| 2 | 1 | PASS |
