#!/usr/bin/env python3
# Python adapter for the coding test harness.
#   argv: <solution-file> <cases-file>
# Loads the candidate's solution as a module, calls the named top-level function
# for each case under a per-case wall-clock timeout (SIGALRM — portable on
# macOS/Linux, no GNU `timeout` needed), and prints ONE JSON object to stdout:
#   {"passed": N, "total": M, "cases": [...], "harness_error": <str|null>}
# Exit 0 iff passed == total and harness_error is null.
# The candidate's own stdout/stderr (debug prints) is captured to a sink so it
# can never corrupt the single-line JSON result emitted on the real stdout.
import sys, os, io, json, signal, contextlib, importlib.util

TIMEOUT_S = float(os.environ.get("SWE_CODING_TIMEOUT_S", "5"))
_REAL_STDOUT = sys.stdout


class _Timeout(Exception):
    pass


def _alarm(signum, frame):
    raise _Timeout()


def _norm(v):
    # Treat tuples and lists alike so a tuple return doesn't spuriously fail.
    if isinstance(v, (list, tuple)):
        return [_norm(x) for x in v]
    return v


def _canon(seq):
    return sorted(seq, key=lambda e: json.dumps(e, sort_keys=True, default=str))


def _eq(got, want, unordered):
    g, w = _norm(got), _norm(want)
    if unordered and isinstance(g, list) and isinstance(w, list):
        try:
            return _canon(g) == _canon(w)
        except Exception:
            return g == w
    return g == w


def _short(v):
    s = repr(v)
    return s if len(s) <= 300 else s[:297] + "..."


def _emit(passed, total, cases, harness_error):
    print(json.dumps({"passed": passed, "total": total,
                      "cases": cases, "harness_error": harness_error}),
          file=_REAL_STDOUT)


def main():
    if len(sys.argv) != 3:
        _emit(0, 0, [], "usage: python_runner.py <solution> <cases>")
        return 2
    sol_path, cases_path = sys.argv[1], sys.argv[2]
    try:
        with open(cases_path) as f:
            spec = json.load(f)
        fn_name = spec["function"]
        unordered = bool(spec.get("unordered", False))
        cases = spec["cases"]
    except Exception as e:
        _emit(0, 0, [], "bad cases file: " + str(e))
        return 2
    if not isinstance(cases, list):
        _emit(0, 0, [], "bad cases file: 'cases' must be a JSON array")
        return 2
    total = len(cases)
    # Install the timer BEFORE importing so a top-level hang (e.g. `while True`)
    # at module load is bounded too, not just the per-case calls.
    signal.signal(signal.SIGALRM, _alarm)
    sink = io.StringIO()
    try:
        signal.setitimer(signal.ITIMER_REAL, TIMEOUT_S)
        with contextlib.redirect_stdout(sink), contextlib.redirect_stderr(sink):
            spec_obj = importlib.util.spec_from_file_location("candidate_solution", sol_path)
            module = importlib.util.module_from_spec(spec_obj)
            spec_obj.loader.exec_module(module)
        signal.setitimer(signal.ITIMER_REAL, 0)
    except _Timeout:
        signal.setitimer(signal.ITIMER_REAL, 0)
        _emit(0, total, [], "solution hung at import (timed out after %ss)" % TIMEOUT_S)
        return 1
    except (Exception, SystemExit) as e:
        signal.setitimer(signal.ITIMER_REAL, 0)
        _emit(0, total, [], "could not load solution: " + (str(e).splitlines() or [""])[0])
        return 1
    fn = getattr(module, fn_name, None)
    if not callable(fn):
        _emit(0, total, [], "function '%s' not found in solution" % fn_name)
        return 1

    results, passed = [], 0
    for i, case in enumerate(cases):
        if not isinstance(case, dict):
            results.append({"i": i, "ok": False, "got": None, "want": None,
                            "error": "case is not a JSON object", "timed_out": False})
            continue
        args = case.get("args", [])
        want = case.get("expected")
        entry = {"i": i, "ok": False, "got": None, "want": _short(want),
                 "error": None, "timed_out": False}
        try:
            signal.setitimer(signal.ITIMER_REAL, TIMEOUT_S)
            with contextlib.redirect_stdout(sink), contextlib.redirect_stderr(sink):
                got = fn(*args)
            signal.setitimer(signal.ITIMER_REAL, 0)
            entry["got"] = _short(got)
            if _eq(got, want, unordered):
                entry["ok"] = True
                passed += 1
        except _Timeout:
            signal.setitimer(signal.ITIMER_REAL, 0)
            entry["timed_out"] = True
            entry["error"] = "timed out after %ss" % TIMEOUT_S
        except SystemExit as e:
            signal.setitimer(signal.ITIMER_REAL, 0)
            entry["error"] = "solution called sys.exit(%r)" % (e.code,)
        except Exception as e:
            signal.setitimer(signal.ITIMER_REAL, 0)
            entry["error"] = (type(e).__name__ + ": " + str(e)).splitlines()[0]
        results.append(entry)
    _emit(passed, total, results, None)
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
