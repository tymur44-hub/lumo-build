using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Lumo.UI;

/// <summary>
/// Точка «не прослушано» у голосовых и кружков.
/// Входящее: горит, пока вы его не включили. Исходящее: горит, пока собеседник не прослушал.
/// Кто прослушал — хранится на сервере в meta.lb и приходит всем через обновление сообщения.
/// </summary>
public static class Listened
{
    static readonly HashSet<int> local = new(), sent = new();

    public static bool Unheard(Message m, bool mine)
    {
        if ((m.Kind != "voice" && m.Kind != "video_note") || m.Id <= 0) return false;
        var lb = (m.Meta["lb"] as JsonArray)?.Select(x => x?.ToString()).ToList() ?? new List<string?>();
        var me = Store.MyId; if (me == null) return false;
        if (mine)
        {
            var c = Store.Chat(m.ChatId);
            if (c != null && (c.IsSaved || (c.IsPrivate && c.PeerId == me))) return false;
            return lb.Count == 0;
        }
        return !local.Contains(m.Id) && !lb.Contains(me);
    }

    public static void Mark(Message m, bool mine, FrameworkElement? dot = null)
    {
        if (mine || m.Id <= 0 || !Unheard(m, false)) return;
        local.Add(m.Id);
        if (dot != null) dot.Visibility = Visibility.Collapsed;
        if (!sent.Add(m.Id)) return;
        _ = Task.Run(async () => { try { await Api.Rpc("lm_voice_listen", new JsonObject { ["p_msg"] = m.Id }); } catch { } });
    }

    public static Border Dot(bool mine, double size = 7) => new()
    {
        Width = size, Height = size, CornerRadius = new CornerRadius(size / 2),
        Background = mine ? T.White : T.Accent, VerticalAlignment = VerticalAlignment.Center,
    };
}
