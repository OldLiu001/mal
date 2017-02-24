import { MalType } from "./types";

export function prStr(v: MalType, printReadably = true): string {
    switch (v.type) {
        case "list":
            return `(${v.list.map(v => prStr(v, printReadably)).join(" ")})`;
        case "vector":
            return `[${v.list.map(v => prStr(v, printReadably)).join(" ")}]`;
        case "hash-map":
            let result = "{";
            for (const [key, value] of v.entries()) {
                if (result !== "{") {
                    result += " ";
                }
                result += `${prStr(key, printReadably)} ${prStr(value, printReadably)}`;
            }
            result += "}";
            return result;
        case "number":
        case "symbol":
        case "boolean":
            return `${v.v}`;
        case "string":
            if (printReadably) {
                const str = v.v
                    .replace(/\\/g, "\\\\")
                    .replace(/"/g, '\\"')
                    .replace(/\n/g, "\\n");
                return `"${str}"`;
            } else {
                return v.v;
            }
        case "null":
            return "nil";
        case "keyword":
            return `:${v.v}`;
        case "function":
            return "#<function>";
        case "atom":
            return `(atom ${prStr(v.v, printReadably)})`;
    }
}
