using System.Globalization;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Lumo.Core;

/// <summary>Удобное чтение JSON-ответов сервера</summary>
public static class J
{
    public static JsonNode? Get(this JsonNode? n, string k) => (n as JsonObject)?[k];

    public static string? Str(this JsonNode? n, string k)
    {
        var v = n.Get(k);
        if (v == null) return null;
        if (v is JsonValue jv)
        {
            if (jv.TryGetValue<string>(out var s)) return s.Length == 0 ? null : s;
            if (jv.TryGetValue<JsonElement>(out var e))
            {
                if (e.ValueKind == JsonValueKind.Null) return null;
                if (e.ValueKind == JsonValueKind.String) { var t = e.GetString(); return string.IsNullOrEmpty(t) ? null : t; }
                return e.GetRawText();
            }
            return jv.ToJsonString();
        }
        return v.ToJsonString();
    }

    public static double? Dbl(this JsonNode? n, string k)
    {
        var v = n.Get(k);
        if (v is not JsonValue jv) return null;
        if (jv.TryGetValue<double>(out var d)) return d;
        if (jv.TryGetValue<long>(out var l)) return l;
        if (jv.TryGetValue<int>(out var i)) return i;
        if (jv.TryGetValue<JsonElement>(out var e))
        {
            if (e.ValueKind == JsonValueKind.Number && e.TryGetDouble(out var x)) return x;
            if (e.ValueKind == JsonValueKind.String && double.TryParse(e.GetString(), NumberStyles.Float, CultureInfo.InvariantCulture, out var y)) return y;
            return null;
        }
        if (jv.TryGetValue<string>(out var s) && double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out var z)) return z;
        return null;
    }

    public static int? Int(this JsonNode? n, string k) { var d = n.Dbl(k); return d == null ? null : (int)d.Value; }
    public static long? Long(this JsonNode? n, string k) { var d = n.Dbl(k); return d == null ? null : (long)d.Value; }

    public static bool Bool(this JsonNode? n, string k)
    {
        var v = n.Get(k);
        if (v is not JsonValue jv) return false;
        if (jv.TryGetValue<bool>(out var b)) return b;
        if (jv.TryGetValue<JsonElement>(out var e))
        {
            if (e.ValueKind == JsonValueKind.True) return true;
            if (e.ValueKind == JsonValueKind.Number) return e.TryGetInt32(out var i) && i == 1;
            if (e.ValueKind == JsonValueKind.String) return e.GetString() == "true";
            return false;
        }
        if (jv.TryGetValue<int>(out var n2)) return n2 == 1;
        return jv.TryGetValue<string>(out var s) && s == "true";
    }

    public static bool Has(this JsonNode? n, string k) { var v = n.Get(k); if (v == null) return false; return !(v is JsonValue jv && jv.TryGetValue<JsonElement>(out var e) && e.ValueKind == JsonValueKind.Null); }

    public static JsonObject Obj(this JsonNode? n, string k) => n.Get(k) as JsonObject ?? new JsonObject();
    public static JsonArray? Arr(this JsonNode? n, string k) => n.Get(k) as JsonArray;

    public static DateTimeOffset? Date(this JsonNode? n, string k) => Dates.Parse(n.Str(k));

    public static List<JsonObject> Objects(this JsonNode? n)
    {
        var r = new List<JsonObject>();
        if (n is JsonArray a) foreach (var x in a) if (x is JsonObject o) r.Add(o);
        return r;
    }

    public static JsonObject O(params (string k, object? v)[] p)
    {
        var o = new JsonObject();
        foreach (var (k, v) in p) o[k] = ToNode(v);
        return o;
    }

    public static JsonNode? ToNode(object? v) => v switch
    {
        null => null,
        JsonNode n => n.DeepClone(),
        string s => JsonValue.Create(s),
        bool b => JsonValue.Create(b),
        int i => JsonValue.Create(i),
        long l => JsonValue.Create(l),
        double d => JsonValue.Create(d),
        float f => JsonValue.Create(f),
        IEnumerable<string> ss => new JsonArray(ss.Select(x => (JsonNode?)JsonValue.Create(x)).ToArray()),
        IEnumerable<int> ii => new JsonArray(ii.Select(x => (JsonNode?)JsonValue.Create(x)).ToArray()),
        _ => JsonValue.Create(v.ToString()),
    };

    public static JsonObject Clone(this JsonObject o) => (JsonObject)o.DeepClone();
}

public static class Dates
{
    public static DateTimeOffset? Parse(string? s)
    {
        if (string.IsNullOrEmpty(s)) return null;
        if (DateTimeOffset.TryParse(s, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var d)) return d;
        return null;
    }

    public static string Iso(DateTimeOffset d) => d.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture);
}
