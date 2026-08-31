import os
d = "d:/_PubCodes/mal/impls/batch/"
for f in ["util.bat", "nsutil.bat", "step1_read_print.bat", "step2_eval.bat"]:
    p = os.path.join(d, f)
    b = open(p, "rb").read()
    # normalize to CRLF
    import re
    s = b.decode("utf-8")
    s = s.replace("\r\n", "\n").replace("\n", "\r\n")
    open(p, "wb").write(s.encode("utf-8"))
    nb = open(p, "rb").read()
    crlf = nb.count(b"\r\n"); lf = nb.count(b"\n") - crlf
    print(f, "CRLF=", crlf, "bareLF=", lf)