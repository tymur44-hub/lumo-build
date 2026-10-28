import sys, json
t = open(sys.argv[1]).read().split("\n", 1)
d = json.loads(t[1]) if len(t) > 1 else {}
print(d.get("exception"), d.get("termination"))
for th in d.get("threads", []):
    if th.get("triggered"):
        for fr in th["frames"][:25]:
            print(fr.get("symbol"), fr.get("sourceFile"), fr.get("sourceLine"))
